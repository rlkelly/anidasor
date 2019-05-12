// this is a factory for creating funding requests,
// farms, and worker contracts

type storage = {
  owner_key: key,
  owner: address,
  farms: set(address),
};

let%init storage = (owner_key: key) => {
  owner_key,
  owner: Current.sender(),
  farms: Map,
};

let%entry create_farm = ((
      farm_name: string,
      farm_location: string,
      farm_description: string,
    ),
    storage) => {

  let manager = Crypto.hash_key(storage.owner_key);
  let delegate = Some(manager);
  let spendable = true;
  let amount = Current.amount();

  let (c_op, c_addr) =
    Contract.create(
      ~manager,
      ~delegate,
      ~spendable,
      ~delegatable=true,
      ~amount,
      ~storage={owner: Current.source(), amount: 0, unit_of_measurement: "lbs", location: farm_location, description: farm_description, cost: 0tz},
      (contract Farm),
    );

  let storage = storage.farms = Set.add(c_addr, storage.farms);
  ([c_op], storage);
};

let%entry create_funding_request = ((
      // make list of valid farms
      amount_requested: tez,
      description: string,
      number_of_workers: nat,
    ),
    storage) => {

  // validate farm
  if (!Set.mem(Current.sender(), storage.farms)) {
       Current.failwith("not a valid farm")
  };

  let manager = Crypto.hash_key(storage.owner_key);
  let delegate = Some(manager);
  let spendable = true;
  let amount = Current.amount();

  let (c_op, c_addr) =
    Contract.create(
      ~manager,
      ~delegate,
      ~spendable,
      ~delegatable=true,
      ~amount,
      ~storage={farm: Current.sender(), amount_requested: amount_requested, description: description, number_of_workers: number_of_workers},
      (contract FundingRequest),
    );

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
};
