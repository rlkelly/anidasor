WorkerContract
--------------
"init contract with balance"

// balance
storage: [
  workers: {id: (address, amount)},
]

SetWorker(id, worker_address)
PayForDay(id) // only can execute once per day
