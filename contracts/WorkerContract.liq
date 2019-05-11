type worker_storage = {
  farm: address,
  employee: address,
  daily_wage: tez,
  last_payday: timestamp,
};

contract WorkerContract = {
  type storage = worker_storage
  let%init storage = (farm: address, employee: address, daily_wage: tez) => {
    {
      farm,
      employee,
      daily_wage,
      last_payday: Current.time(),
    }
  };

  let%entry fund = (parameter: unit, storage) => ([], storage);

  let%entry pay_employee = (parameter: unit, storage) => {
      if ((Current.time() - storage.last_payday) > 86400) {
        Current.failwith("Must wait 24 hours to pay")
      };
      let storage = storage.last_payday = Current.time();
      ([], storage);
  };
};
