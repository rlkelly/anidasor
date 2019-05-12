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

[@inline]
let check_sender = (req: address, error_string: string) => {
  if (Current.sender() != req) {
    Current.failwith(string);
  };
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

  let%entry withdraw_funds = ((receiver: key_hash), storage) => {
      // allows the owner to withdraw all funds in contract
      check_sender(storage.owner, "only app can change app address");
      Account.transfer(receiver, Current.balance());
      ((), storage);
  };


  let%entry update_app_address = ((new_app: address), storage) => {
      check_sender(storage.app_address, "only app can change app address");
      let storage = storage.app_address = new_app;
      ((), storage);
  };

  let%entry change_storage_amount = ((change: int), storage) => {
      check_sender(storage.owner, "only owner can modify");
      let storage = storage.amount = storage.amount + change;
      if (storage.amount < 0) {
        Current.failwith("invalid")
      };
      ([], storage);
  };

  let%entry change_storage_unit = ((change: string), storage) => {
      check_sender(storage.owner, "only owner can modify");
      let storage = storage.unit_of_measurement = change;
      ([], storage);
  }

  let%entry change_location = ((change: string), storage) => {
      check_sender(storage.owner, "only owner can modify");
      let storage = storage.location = change;
      ([], storage);
  };

  let%entry change_description = ((change: string), storage) => {
      check_sender(storage.owner, "only owner can modify");
      let storage = storage.description = change;
      ([], storage);
  };

  let%entry create_funding_request = ((amount_requested: tez, description: string, number_of_workers: nat), storage) => {
    check_sender(storage.owner, "only owner can modify");

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
  };

  let%entry add_funding_request = ((funding_contract: address), storage) => {
      check_sender(storage.app_address, "only app can modify");
      let storage = storage.funding_requests = Set.add(funding_contract, storage.funding_requests);
      ([], storage);
  };

  let%entry add_worker_contract = ((worker_contract: address, percentage: nat), storage) => {
      switch(Map.get(Current.sender(), storage.funding_requests)) {
        | None => Current.failwith("only existing funding requests can add worker contracts")
        | Some(_) => ()
      };

      if ((storage.total_percentage + percentage) > 35) {
        Current.failwith("can not give more than 35% of earnings");
      };
      let storage = storage.worker_contracts = Set.add(worker_contract, storage.worker_contracts);
      storage.total_percentages = storage.total_percentage + percentage;
      ([], storage);
  };

  let%entry delete_debt = ((address: address), storage) => {
      // a contract can only be deleted by itself
      check_sender(address, "Only contract can erase self");
      let debt = switch(Map.find(address, storage.debts)) {
        | None => 0
        | Some(x) => x.payment_percentage
      };
      let storage = storage.debts = Map.remove(address, storage.debts);
      ([], storage);
  };

  let%entry add_debt = ((address: address, balance: tez, payment_percentage: nat, funding_contract: address), storage) => {
    // debt can only be added by funding contracts
    switch(Map.get(Current.sender(), storage.funding_requests)) {
        | None => Current.failwith("Only a funding request can add debt")
        | Some(_) => ()
    };
    let new_debt = {balance, payment_percentage, funding_contract};
    let storage = storage.debts = Map.add(address, new_debt, storage.debts);
    ([], storage);
  };

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
  };

  let%entry purchase = (amount_to_purchase, storage) => {
    if (amount_to_purchase > storage.amount) {
      Current.failwith("More that current supply");
    };
    let funds = Current.amount();
    if ((amount_to_purchase * storage.cost) < funds) {
      Current.failwith("Insufficient funds");
    };

    // pay lender and update worker contract to reflect how much has been paid back
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
      let op = Contract.call(
        ~dest=t.funding_contract,
        ~amount=amount_to_send,
        ~entry=pay_lender,
        ~parameter=unit);
    }, storage.debt);

    let debts = Map.map((receiver, t) => {
      let amount_to_send =
        switch ((Current.amount() * 100) / t.payment_percentage) {
        | Some(a, _) => a
        | None => failwith("division by 0 impossible")
      };
      t.balance = t.balance - amount_to_send;
    });

    let t: option(Purchaser.instance) = Contract.at(Current.sender());
    let t = switch(t) {
      | None => Current.failwith()
      | Some(inst) => inst
    };
    let op1 = Contract.call(
      ~dest=t,
      ~amount=0tz,
      ~entry=receive_offer,
      ~parameter=(amount_to_purchase, storage.unit_of_measurement));

    let storage = storage.debts = debts;
    (ops, storage);
  };

};
