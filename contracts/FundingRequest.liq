type funding_request = {
  farm: address
  amount_requested: tez,
  payback_amount: tez,
  description: string,
  payback_percentage: nat,
};

contract FundingRequest = {
  type storage = funding_request
  let%init storage = (farm: address, amount_requested: tez, payback_percentage: tez, description: string, payback_ratio: nat) => {
    if ((payback_ratio < 0) or (amount < 0)) {
      Current.failwith("invalid")
    };
    {
      farm,
      amount_requested,
      payback_amount,
      description,
      payback_percentage,
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
        ~storage={farm, employee, daily_wage, last_payday: Current.time(), lendor: Current.sender(), original_loan: amount_requested, payback_amount},
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
    let op1 = Contract.call(
      ~dest=t,
      ~amount=0tz,
      ~entry=add_worker_contract,
      ~parameter=(c_addr, storage.payback_percentage));

    let op2 = Contract.call(
      ~dest=t,
      ~amount=0tz,
      ~entry=add_debt,
      ~parameter=(Current.sender(), payback_amount, payback_percentage, c_addr));

    ([c_op, op1, op2], storage);
  };

  let%entry change_description = ((change: string), storage) => {
      let storage = storage.description = change;
      ([], storage);
  };
};
