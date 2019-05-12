App
------------

storage: [
  farmers: {}
  cafes: {}
  distributors: {}
  lenders: {}
]

CreateFarmer()
CreateCafe()
CreateDistributor()
CreateLender()

employee {
    id string
    daily_pay_rate mutez
    num_days int
    title string
}

CreateFundingRequest([employee]) -> FundRequestContract
