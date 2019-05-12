Buyer/Seller
------------

A buyer/seller is someone that buys and sells coffee.  When they buy coffee, it's added to their store of coffee.  They can create offers that consists of the coffees they own.

struct coffee {
  amount
  creator  
}

struct offers {
  amount
  coffees: list(coffee)
}

storage: [
  products: [coffee],
  offers: [offers],
]

BuyOffer()
CreateSellOffer(amount)
