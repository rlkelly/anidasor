contract FundingRequest = {
  type storage = {
    owner_key: key,
    owner: address,
    farms: set(address),
  };

  let%init storage = (owner_key: key) => {
    owner_key,
    owner: Current.sender(),
  };

  let%entry create_funding_contract = ((
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
    let spendable = false;
    let amount = Current.amount();

    let (c_op, c_addr) =
      Contract.create(
        ~manager,
        ~delegate,
        ~spendable,
        ~delegatable=false,
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
      ~entry=add_worker_contract,
      ~parameter=c_addr);

    ([c_op, op], storage);
  };
};
