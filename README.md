# anidasor aba

This mean "Hope is Here" in a local dialect of ghana, Twi.


This is an app to create a supply chain for coffee purchasing, and for lendors to lend money to pay workers.  They will only be able to use these funds to pay workers, will receive a percent of all purchases from the coffee farm automatically, and can cancel their contract if they lose confidence in the farm they are supporting.

An app architecture was built using Liquidity, a Tezos language with oCaml like syntax that compiles to Michelson (the Tezos VM).

The main contract is Anidasor, which contains factories for creating WorkerContracts, FundingRequests, Farms and Purchasers.  By creating contracts through the Anidasor contract, it allows all contracts to be owned by it, and creates constraints on updates in other contracts.

The contracts have contstraints on who can call and update based on the scenario.  For example, only a farm can change it's worker contract's workers, but the funds can only be unlocked daily to pay workers.  If the lender does not want to participate in the contract any more, they are released the remaining funds they are owed from the worker contract.




DEPLOYMENT
==========

This would be deployed as a single contract, because the Anidasor contract is a factory that is used to build all other contracts.  When a contract is created through the Anidasor contract, the owner of the contract is dually Anidasor and the creator.  So there are functions that can only be called by the Farm that created the contract, and their are functions that can only be called by the Anidasor contract.
