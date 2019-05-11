type employee = {
  id: string;
  wallet: address;
  daily_pay_rate: tez;
  num_days: nat;
  title: string;
}

type farm = {
  owner: address;
  location: string;
  other: string;
  fund_requests: (string, int) map;
}

type cafe = {
  (*owner: address;*)
  balance: tez;
  location: string;
  name: string;
  other: string;
}

type coffee = {
  amount: tez;
  creator: address;
}

type storage = {
  farms : (address: farm) map;
  cafes: (address: cafe) map;
}

let%entry main
    (p : bool)
    storage =

  ([], storage)
