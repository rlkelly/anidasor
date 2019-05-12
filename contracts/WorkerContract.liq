type worker_storage = {
  farm: address,
  employee: key_hash,
  daily_wage: tez,
  last_payday: timestamp,
  lender: address,
  lender_key_hash: key_hash,
  original_loan: tezos,
  amount_earned: tezos,
  payback_amount: tezos,
};

contract WorkerContract = {
  type storage = worker_storage
  let%init storage = (farm: address, employee: key_hash, lender_key_hash: key_hash, daily_wage: tez, original_loan: tezos, payback_amount: tezos) => {
    {
      farm,
      employee,
      daily_wage,
      last_payday: Current.time(),
      lender,
      lender_key_hash,
      original_loan,
      amount_earned: 0,
      payback_amount,
    }
  };

  let%entry update_worker = (employee: key_hash, storage) => {
    let storage = storage.employee = employee;
    ([], storage);
  };

  let%entry fund = (parameter: unit, storage) => ([], storage);

  let%entry pay_lender = (unit, storage) => {
    if (Current.sender() != farm) {
      Current.failwith("only farm can increase earnings");
    };
    let storage.amount_earned = storage.amount_earned + Current.amount();
    let op = Account.transfer(lender_key_hash, Current.amount(), ());
    ([op], storage);
  };

  let%entry terminate_early = (parameter: unit, storage) => {
    // This will terminate loan early.  Lendor gets funds not already repaid.
    // The rest is returned to farm in case they repaid more than the loan balance already.
    let farm_instance: option(Farm.instance) = Contract.at(storage.farm);
    let farm_instance = switch(farm_instance) {
      | None => Current.failwith()
      | Some(inst) => inst
    };

    // if you don't want to follow through with contract
    if (Current.sender() != storage.lender) {
      Current.failwith("only lender can terminate early");
    };
    let payback = if (Current.balance() < (original_loan - amount_earned)) {
      Current.balance();
    } else {
      original_loan - amount_earned;
    }
    // TODO: return all funds and delete debt
    let op1 = Account.transfer(lender_key_hash, payback, ());
    let op2 = Contract.call(farm_instance, Current.balance() - payback, ());
    let op3 = Contract.call(
      ~dest=t.funding_contract,
      ~amount=amount_to_send,
      ~entry=delete_debt,
      ~parameter=Contract.address(Contract.self()));
    ([op1, op2, op3], storage);
  };

  let%entry completed = (parameter: unit, storage) => {
    // anyone can call this once it's done being paid
    let t: option(Farm.instance) = Contract.at(storage.farm);
    let t = switch(t) {
      | None => Current.failwith()
      | Some(inst) => inst
    };

    if (storage.amount_earned < storage.payback_amount) {
      Current.failwith("not done paying off");
    };
    let op = Contract.call(storage.farm, Current.balance(), ());
    ([op], storage);
  };

  let%entry pay_employee = (parameter: unit, storage) => {
      let t: option(Farm.instance) = Contract.at(storage.farm);
      let t = switch(t) {
        | None => Current.failwith()
        | Some(inst) => inst
      };

      if ((Current.time() - storage.last_payday) > 86400) {
        Current.failwith("Must wait 24 hours to pay")
      };
      if (Current.sender() != farm) {
        Current.failwith("only farm can pay employee");
      };
      let op = Account.transfer(storage.employee, daily_wage, ());
      let storage = storage.last_payday = Current.time();
      ([op], storage);
  };
};
