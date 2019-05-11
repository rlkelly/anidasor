type funding_request = {
  owner: address
  amount_requested: tez,
  description: string,
  number_of_workers: nat,
};

contract FundingRequest = {
  type storage = funding_request
  let%init storage = (owner: address, amount: tez, description: string, number_of_workers: nat) => {
    if (amount < 0) {
      Current.failwith("invalid")
    };
    if (number_of_workers < 0) {
      Current.failwith("invalid")
    };
    {
      owner,
      amount_requested,
      description,
      number_of_workers,
    }
  };

  let%entry fund_request = ((), storage) => {
    if (Current.amount() < amount_requested) {
      Current.failwith("Not enough funds")
    }

    switch(Map.find(Current.sender(), storage.workers)) {
        | None => ()
        | Some(workers) => {
          if ( Map.mem(employee, workers) ) {
            Current.failwith("worker already exists")
          }
        }
    };

    let manager = Crypto.hash_key(storage..);
    let delegate = Some(manager);
    let spendable = false;
    let amount = Current.amount();

    let (c_op, c_addr) =
      Contract.create(
        ~manager,
        ~delegate,
        ~spendable,
        ~delegatable=false,
        ~amount,
        ~storage={farm: Current.sender(), employee, daily_wage, last_payday: Current.time()},
        (contract WorkerContract),
      );

    let storage = storage.workers = switch(Map.find(Current.sender(), storage.workers)) {
        | None => Map.add(Current.sender(), Map.add(employee, c_addr, Map), storage.workers)
        | Some(workers) => {
            let farm_workers = Map.add(employee, c_addr, workers)
            Map.add(Current.sender(), farm_workers, storage.workers)
        }
    };
    let t: option(Farm.instance) = Contract.at(owner);
    let t = switch(t) {
      | None => Current.failwith()
      | Some(inst) => inst
    };
    let op = Contract.call(
      ~dest=t,
      ~amount=0tz,
      ~entry=add_funding_request,
      ~parameter=c_addr);

    ([c_op, op], storage);
  }

  let%entry change_description = ((change: string), storage) => {
      let storage = storage.description = change;
      ([], storage);
  }
};
