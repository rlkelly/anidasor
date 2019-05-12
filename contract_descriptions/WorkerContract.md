WorkerContract
--------------
"init contract with balance"


This is a contract to pay workers.  It is funded by a FundingRequest, and funds can only be withdraw once daily to the worker for their wage.  This allows a lender to provide funds to a farm, with the only risk being they receive returns on each sale directly, and the farm can only release the daily rate of funds to a worker once every 24 hours.

// balance
storage: [
  workers: {id: (address, amount)},
]

SetWorker(id, worker_address)
PayForDay(id) // only can execute once per day
