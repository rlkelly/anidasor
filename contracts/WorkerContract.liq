type worker_storage = {
  farm: address,
  employee: address,
  daily_wage: tez,
  last_payday: timestamp,
  lender: address,
  original_loan: tezos,
  amount_earned: tezos,
  payback_amount: tezos,
};

contract WorkerContract = {
  type storage = worker_storage
  let%init storage = (farm: address, employee: address, daily_wage: tez, original_loan: tezos, payback_amount: tezos) => {
    {
      farm,
      employee,
      daily_wage,
      last_payday: Current.time(),
      lender,
      original_loan,
      amount_earned: 0,
      payback_amount,
    }
  };

  let%entry update_worker = (employee: address, storage) => {
    let storage = storage.employee = employee;
    ([], storage);
  };

  let%entry fund = (parameter: unit, storage) => ([], storage);
  let%entry pay_lender = (unit, storage) => {
    if (Current.sender() != farm) {
      Current.failwith("only farm can increase earnings");
    };
    let storage.amount_earned = storage.amount_earned + Current.amount();
    let op = Contract.call(receiver, Current.amount(), ());
    ([op], storage);
  }

  let%entry terminate_early = (parameter: unit, storage) => {
    if (Current.sender() != storage.lender) {
      Current.failwith("only lender can terminate early");
    };
    let op = Contract.call(storage.lender, daily_wage, ());
    ([op], storage);
  }

  let%entry completed = (parameter: unit, storage) => {
    // anyone can call this once it's done being paid
    if (storage.amount_earned < storage.payback_amount) {
      Current.failwith("not done paying off")
    }
    let op = Contract.call(storage.farm, Current.balance(), ());
    ([op], storage);
  }

  let%entry pay_employee = (parameter: unit, storage) => {
      if ((Current.time() - storage.last_payday) > 86400) {
        Current.failwith("Must wait 24 hours to pay")
      };
      if (Current.sender() != farm) {
        Current.failwith("only farm can pay employee");
      };
      let op = Contract.call(storage.employee, daily_wage, ());
      let storage = storage.last_payday = Current.time();
      ([op], storage);
  };
};
