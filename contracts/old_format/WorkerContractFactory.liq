type storage = {
  owner_key: key,
  owner: address,
  workers: map(address, map(address, address)),
};

let%init storage = (owner_key: key) => {
  owner_key,
  owner: Current.sender(),
  workers: Map,
};

let%entry create_worker_contract = ((
      // make list of valid farms
      employee: address,
      daily_wage: tez,
    ),
    storage) => {

  // validate farm
  if (!Map.mem(Current.sender(), storage.workers)) {
       Current.failwith("not a valid farm")
  };

  switch(Map.find(Current.sender(), storage.workers)) {
      | None => ()
      | Some(workers) => {
        if ( Map.mem(employee, workers) ) {
          Current.failwith("worker already exists")
        }
      }
  };

  let manager = Crypto.hash_key(storage.owner_key);
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

  ([c_op], storage);
};
