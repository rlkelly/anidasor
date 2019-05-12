// how much for a list of coffees purchased
type offers = {
   price: tez,
   coffees: list(nat),
};

type cup = {
   price: tez,
   coffee: nat,
};

type received = {
   amount: nat,
   unit_of_measurement: string,
};

type purchaser_storage = {
  owner: address,
  owner_key: key_hash,
  app_address: address,
  location: string,
  description: string,
  offers: map(nat, offers),
  offer_id: nat,
  received: map(nat, coffee),
  received_id: nat,
  cups: map(nat, cups),
  cup_id: nat,
};

contract Purchaser = {
  type storage = purchaser_storage
  let%init storage = (owner: address, owner_key: key_hash, app_address: address, location: string, description: string) => {
    if (amount < 0) {
      Current.failwith("invalid")
    };
    {
      owner,
      owner_key,
      app_address,
      location,
      description,
      offers: Map,
      offer_id: 0,
      received: Map,
      received_id: 0,
      cups: Map,
      cup_id: 0,
    };
  };

  let%entry create_cup = ((price: tez, coffee: nat), storage) => {
      let storage = storage.coffees = Map.add(storage.cup_id + 1, {price, coffee}, storage.coffees);
      let storage = storage.offer_id = storage.cup_id + 1;
      ([], storage);
  };

  let%entry create_offer = ((price: tez, coffees: list(nat)), storage) => {
      let storage = storage.offers = Map.add(storage.offer_id + 1, {price, coffees}, storage.coffees);
      let storage = storage.offer_id = storage.offer_id + 1;
      ([], storage);
  };

  let%entry receive_offer = ((amount: nat, unit_of_measurement: string), storage) => {
      let storage = storage.offers = Map.add(storage.offer_id + 1, {amount, unit_of_measurement}, storage.coffees);
      let storage = storage.offer_id = storage.offer_id + 1;
      ([], storage);
  };

  let%entry purchase_offer = (offer_id: nat, storage) => {
      let amt = Current.amount();
      let offer = switch(Map.find(offer_id, storage.offers)) {
          | None -> Current.failwith("offer doesn't exist")
          | Some(x) -> x
      };
      if (offer.price < amt) {
        Current.failwith("not enough funds to purchase");
      };

      let amount = Map.fold((((k, v), acc) => v.amount + acc),
          Map.map((k) => {
              let v = Map.get(k, storage.coffees);
              switch(v) {
                | None -> Current.failwith("invalid coffee")
                | Some(x) -> x
              };
            }, offer.coffees), 0);
      let unit_of_measurement = Map.fold((((k, v), acc)) => {
        if (acc != unit) {
            if (v.unit_of_measurement != acc) {
              Current.failwith("non-matching units");
            }
            v.unit_of_measurement;
        };
      },
          Map.map((k) => {
              let v = Map.get(k, storage.coffees);
              switch(v) {
                | None -> Current.failwith("invalid coffee")
                | Some(x) -> x
              };
            }, offer.coffees), unit);

      let t: option(Purchaser.instance) = Contract.at(Current.sender());
      let t = switch(t) {
        | None => Current.failwith()
        | Some(inst) => inst
      };
      let op1 = Contract.call(
        ~dest=t,
        ~amount=0tz,
        ~entry=receive_offer,
        ~parameter=(amount, unit_of_measurement));

      ([t], storage);
  };
};
