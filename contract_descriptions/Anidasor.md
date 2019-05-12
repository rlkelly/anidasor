Anidasor
------------


This is the app contract.  It stores a variety of information about the state of the application.  It ensures that transactions are only made by authorized entities.

storage: [
  farmers: {}
  purchasers: {}
  worker_contracts: {}
  funding_requests: {}
]

methods:
```
CreateFarmer()
CreateCafe()
CreateDistributor()
CreateLender()
CreateFundingRequest() -> FundRequestContract
```

