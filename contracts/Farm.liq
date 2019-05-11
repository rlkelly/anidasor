type farm_storage = {
  owner: address,
  app_address: address,
  amount: int,
  unit_of_measurement: string,
  location: string,
  description: string,
  cost: tez,
  funding_requests: set(address),
  worker_contracts: set(address),
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

  let%entry add_worker_contract = ((worker_contract: address), storage) => {
      let storage = storage.worker_contracts = Set.add(worker_contract, storage.worker_contracts);
      ([], storage);
  }

  let%entry create_funding_request = ((amount_requested: tez, description: string, number_of_workers: nat), storage) => {
    let t: option(FundingRequestFactory.instance) = Contract.at(storage.app_address);
    let t = switch(t) {
      | None => Current.failwith()
      | Some(inst) => inst
    };
    let op = Contract.call(
      ~dest=t,
      ~amount=0tz,
      ~entry=create_funding_request,
      ~parameter=(amount_requested, description, number_of_workers));
    ([op], storage)
  }

  let%entry add_funding_request = ((funding_contract: address), storage) => {
      let storage = storage.funding_requests = Set.add(funding_contract, storage.funding_requests);
      ([], storage);
  }

};
