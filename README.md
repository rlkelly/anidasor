# anidasor


This is an app to create a supply chain for coffee purchasing.

An app architecture was built using Liquidity, a Tezos language with oCaml like syntax that compiles to Michelson (the Tezos VM).

The main contract is Anidasor, which contains factories for creating WorkerContracts, FundingRequests, Farms and Purchasers.  By creating contracts through the Anidasor contract, it allows all contracts to be owned by it, and creates constraints on updates in other contracts.

The contracts have contstraints on who can call and update based on the scenario.  For example, only a farm can change it's worker contract's workers, but the funds can only be unlocked daily to pay workers.  If the lender does not want to participate in the contract any more, they are released the remaining funds they are owed from the worker contract.
