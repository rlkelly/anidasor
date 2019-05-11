type storage = {
  owner_key: key,
  farms: map(string, address),
};

let%init storage = (owner_key: key) => {
  owner_key,
  farms: Map,
};

let%entry create_farm = ((
      farm_name: string,
      farm_location: string,
      farm_description: string,
    ),
    storage) => {

  switch(Map.find(farm_name, storage.farms)) {
      | None => ()
      | Some(_) => {
        Current.failwith("farm already exists")
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
      ~storage={owner: Current.source(), amount: 0, unit_of_measurement: "lbs", location: farm_location, description: farm_description, cost: 0tz},
      (contract Farm),
    );

  let storage = storage.farms = Map.add(farm_name, c_addr, storage.farms);
  ([c_op], storage);
};
