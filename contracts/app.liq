// this is a factory for creating contracts
// it ensures that all contracts are owned by this top level contract

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

contract App = {
  let%entry change_app_contract = (new_app: address, farm_address: address) => {
    if (Current.sender() != owner) {
      Current.failwith("only owner can update farms");
    };
    let t: option(Farm.instance) = Contract.at(farm_address);
    let t = switch(t) {
      | None => Current.failwith()
      | Some(inst) => inst
    };
    let op = Contract.call(
      ~dest=t,
      ~amount=0tz,
      ~entry=update_app_address,
      ~parameter=new_app);
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

    let (create_farm_op, create_farm_addr) =
      Contract.create(
        ~manager,
        ~delegate,
        ~spendable,
        ~delegatable=true,
        ~amount,
        ~storage={owner: Current.source(), amount: 0, unit_of_measurement: "lbs", location: farm_location, description: farm_description, cost: 0tz},
        (contract Farm),
      );

    let storage = storage.farms = Set.add(create_farm_addr, storage.farms);
    ([create_farm_op], storage);
  };

  let%entry create_purchaser = ((
        owner: address,
        owner_key: key_hash,
        location: string, description: string
      ),
      storage) => {

    let manager = Crypto.hash_key(storage.owner_key);
    let delegate = Some(manager);
    let spendable = true;
    let amount = Current.amount();

    let (create_farm_op, create_farm_addr) =
      Contract.create(
        ~manager,
        ~delegate,
        ~spendable,
        ~delegatable=true,
        ~amount,
        ~storage={owner: Current.source(), owner_key: key_hash, app_address: Contract.at(Current.self()), location, description},
        (contract Farm),
      );

    let storage = storage.farms = Set.add(create_farm_addr, storage.farms);
    ([create_farm_op], storage);
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

    let (create_funding_op, create_funding_addr) =
      Contract.create(
        ~manager,
        ~delegate,
        ~spendable,
        ~delegatable=true,
        ~amount,
        ~storage={farm: Current.sender(), amount_requested: amount_requested, description: description, number_of_workers: number_of_workers},
        (contract FundingRequest),
      );

    let t: option(Farm.instance) = Contract.at(Current.sender());
    let t = switch(t) {
      | None => Current.failwith()
      | Some(inst) => inst
    };
    let op = Contract.call(
      ~dest=t,
      ~amount=0tz,
      ~entry=add_funding_request,
      ~parameter=create_funding_addr);

    ([create_funding_op, op], storage);
  };
};
