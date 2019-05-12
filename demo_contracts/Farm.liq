type farm_storage = {
  owner: address,
  debt: key_hash,
  percent: nat,
  owed: nat,
  description: string,
  cost: tez,
  amount: int,
};

[@inline]
let check_sender = (req: address, error_string: string) => {
  if (Current.sender() != req) {
    Current.failwith(error_string);
  };
};

type storage = farm_storage
let%init storage = (owner: address, debt: key_hash, owed: nat, percent: nat, description: string, cost: tez, amount: int) => {
  if (amount < 0) {
    Current.failwith("invalid")
  };
  {
    owner,
    debt,
    owed,
    percent,
    description,
    cost,
    amount,
  }
};

let%entry change_storage_amount = ((change: int), storage) => {
    // check_sender(storage.owner, "only owner can modify");
    let storage = storage.amount = storage.amount + change;
    if (storage.amount < 0) {
      Current.failwith("invalid")
    };
    ([], storage);
};

let%entry change_description = ((change: string), storage) => {
    check_sender(storage.owner, "only owner can modify");
    let storage = storage.description = change;
    ([], storage);
};

let%entry purchase = (amount_to_purchase: nat, storage) => {
  let funds = Current.amount();
  if ((amount_to_purchase * storage.cost) < funds) {
    Current.failwith("Insufficient funds");
  };
  let storage = storage.amount = storage.amount - amount_to_purchase;
  let payout =
    switch ((Current.amount() * storage.percent) / 100p) {
    | Some(a, _) => a
    | None => failwith("division by 0 impossible")
  };
  let op = Account.transfer(storage.debt, payout);


  ([op], storage);
};
