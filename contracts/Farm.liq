type debt_payment = {
  balance: tez,
  payment_percentage: nat,
  funding_contract: address,
};

type farm_storage = {
  owner: address,
  debt: map(address, debt_payment),
  app_address: address,
  amount: int,
  unit_of_measurement: string,
  location: string,
  description: string,
  cost: tez,
  funding_requests: set(address),
  worker_contracts: set(address),
  total_percentages: nat,
};

contract Farm = {
  type storage = farm_storage
  let%init storage = (owner: address, app_address: address, amount: int, unit_of_measurement: string, location: string, description: string, cost: tez) => {
    if (amount < 0) {
      Current.failwith("invalid")
    };
    {
      owner,
      app_address,
      amount,
      unit_of_measurement,
      location,
      description,
      cost,
      total_percentages: 0,
    }
  };

  let%entry change_storage_amount = ((change: int), storage) => {
      let storage = storage.amount = storage.amount + change;
      if (storage.amount < 0) {
        Current.failwith("invalid")
      };
      ([], storage);
  }

  let%entry change_storage_unit = ((change: string), storage) => {
      let storage = storage.unit_of_measurement = change;
      ([], storage);
  }

  let%entry change_location = ((change: string), storage) => {
      let storage = storage.location = change;
      ([], storage);
  }

  let%entry change_description = ((change: string), storage) => {
      let storage = storage.description = change;
      ([], storage);
  }

  let%entry create_funding_request = ((amount_requested: tez, description: string, number_of_workers: nat), storage) => {
    // maybe the fundingfactory could be separate
    let t: option(App.instance) = Contract.at(storage.app_address);
    let t = switch(t) {
      | None => Current.failwith("can not find contract")
      | Some(inst) => inst
    };
    let op = Contract.call(
      ~dest=t,
      ~amount=0tz,
      ~entry=create_funding_request,
      ~parameter=(amount_requested, description, number_of_workers));
    ([op], storage);
  }

  let%entry add_funding_request = ((funding_contract: address), storage) => {
      if (Current.sender() != app_address) {
        Current.failwith("only the app can make funding requests");
      };
      let storage = storage.funding_requests = Set.add(funding_contract, storage.funding_requests);
      ([], storage);
  }

  let%entry add_worker_contract = ((worker_contract: address, percentage: nat), storage) => {
      if ((storage.total_percentage + percentage) > 35) {
        Current.failwith("can not give more than 35% of earnings");
      };
      switch(Map.get(Current.sender(), storage.funding_requests)) {
        | None => Current.failwith("only existing funding requests can add worker contracts")
        | Some(_) => ()
      };

      let storage = storage.worker_contracts = Set.add(worker_contract, storage.worker_contracts);
      storage.total_percentages = storage.total_percentage + percentage;
      ([], storage);
  }

  let%entry delete_debt = ((address: address), storage) => {
    // a contract can be deleted by itself
    if (Current.sender() != address) {
      Current.failwith("Only contract can erase self");
    };
    let debt = switch(Map.find(address, storage.debts)) {
      | None => 0
      | Some(x) => x.payment_percentage
    };
    let storage = storage.debts = Map.remove(address, storage.debts);
    ([], storage);
  }

  let%entry add_debt = ((address: address, balance: tez, payment_percentage: nat, funding_contract: address), storage) => {
    let new_debt = {balance, payment_percentage, funding_contract};
    let storage = storage.debts = Map.add(address, new_debt, storage.debts);
    ([], storage);
  }

  let%entry remove_empty_debtor = (address, storage) => {
    let payment_percent = switch(Map.find(address, storage.debts)) {
      | None => 0
      | Some(x) => {
        if (x.balance > 0) {
          Current.failwith("still owe them money")
        };
        x.payment_percentage;
      }
    };
    // free room for more payouts
    storage.total_percentage = storage.total_percentage - payment_percent;
    let storage = storage.debts = Map.remove(address, storage.debts);
    ([], storage);
  }

  let%entry purchase = (amount_to_purchase, storage) => {
    if (amount_to_purchase > storage.amount) {
      Current.failwith("More that current supply");
    };
    let funds = Current.amount();
    if ((amount_to_purchase * storage.cost) < funds) {
      Current.failwith("Insufficient funds");
    };

    storage.supply = storage.amount - amount_to_purchase;
    let ops = Map.map((receiver, t) => {
      let amount_to_send =
        switch ((Current.amount() * 100) / t.payment_percentage) {
        | Some(a, _) => a
        | None => failwith("division by 0 impossible")
      };
      if (amount_to_send > t.balance) {
        amount_to_send = t.balance;
      };
      let op = Contract.call(receiver, amount_to_send, ());
    }, storage.debt);

    let debts = Map.map((receiver, t) => {
      let amount_to_send =
        switch ((Current.amount() * 100) / t.payment_percentage) {
        | Some(a, _) => a
        | None => failwith("division by 0 impossible")
      };
      t.balance = t.balance - amount_to_send;
    });

    // update worker contract to reflect how much has been paid back
    let funding_ops = Map.map((receiver, t) => {
      let amount_to_send =
        switch ((Current.amount() * 100) / t.payment_percentage) {
        | Some(a, _) => a
        | None => failwith("division by 0 impossible")
      };
      Contract.call(
        ~dest=t.funding_contract,
        ~amount=0tz,
        ~entry=increase_earnings,
        ~parameter=amount_to_send);
    });

    let storage = storage.debts = debts;
    (ops, storage);
  };

};
