(define-fungible-token oil-future-token)

(define-constant contract-owner tx-sender)
(define-constant err-owner-only (err u100))
(define-constant err-not-found (err u101))
(define-constant err-insufficient-balance (err u102))
(define-constant err-contract-expired (err u103))
(define-constant err-contract-not-expired (err u104))
(define-constant err-insufficient-payment (err u105))
(define-constant err-invalid-amount (err u106))
(define-constant err-unauthorized (err u107))

(define-data-var contract-active bool true)
(define-data-var oil-price-usd uint u75000)
(define-data-var contract-expiry uint u0)
(define-data-var total-contracts uint u0)
(define-data-var settlement-price uint u0)
(define-data-var min-investment uint u100000)

(define-map futures-contracts
  uint
  {
    owner: principal,
    amount: uint,
    strike-price: uint,
    expiry-block: uint,
    settled: bool
  }
)

(define-map user-positions
  principal
  {
    total-invested: uint,
    active-contracts: uint,
    total-returns: uint
  }
)

(define-map price-history
  uint
  {
    price: uint,
    timestamp: uint
  }
)

(define-read-only (get-contract-info)
  {
    active: (var-get contract-active),
    oil-price: (var-get oil-price-usd),
    expiry: (var-get contract-expiry),
    total-contracts: (var-get total-contracts),
    min-investment: (var-get min-investment)
  }
)

(define-read-only (get-futures-contract (contract-id uint))
  (map-get? futures-contracts contract-id)
)

(define-read-only (get-user-position (user principal))
  (default-to
    {total-invested: u0, active-contracts: u0, total-returns: u0}
    (map-get? user-positions user)
  )
)

(define-read-only (get-token-balance (user principal))
  (ft-get-balance oil-future-token user)
)

(define-read-only (get-current-oil-price)
  (var-get oil-price-usd)
)

(define-read-only (get-price-history (height uint))
  (map-get? price-history height)
)

(define-read-only (calculate-contract-value (contract-id uint))
  (match (map-get? futures-contracts contract-id)
    contract-data
    (let
      (
        (current-price (var-get oil-price-usd))
        (strike-price (get strike-price contract-data))
        (amount (get amount contract-data))
      )
      (if (> current-price strike-price)
        (ok (* amount (- current-price strike-price)))
        (ok u0)
      )
    )
    (err err-not-found)
  )
)

(define-public (initialize-contract (expiry-blocks uint))
  (begin
    (asserts! (is-eq tx-sender contract-owner) err-owner-only)
    (var-set contract-expiry (+ stacks-block-height expiry-blocks))
    (ok true)
  )
)

(define-public (update-oil-price (new-price uint))
  (begin
    (asserts! (is-eq tx-sender contract-owner) err-owner-only)
    (asserts! (var-get contract-active) err-contract-expired)
    (var-set oil-price-usd new-price)
    (map-set price-history stacks-block-height {price: new-price, timestamp: stacks-block-height})
    (ok true)
  )
)

(define-public (create-futures-contract (amount uint) (strike-price uint))
  (let
    (
      (contract-id (+ (var-get total-contracts) u1))
      (user-pos (get-user-position tx-sender))
      (investment-cost (* amount strike-price))
    )
    (asserts! (var-get contract-active) err-contract-expired)
    (asserts! (> amount u0) err-invalid-amount)
    (asserts! (>= investment-cost (var-get min-investment)) err-insufficient-payment)
    (asserts! (>= (stx-get-balance tx-sender) investment-cost) err-insufficient-balance)
    
    (try! (stx-transfer? investment-cost tx-sender (as-contract tx-sender)))
    (try! (ft-mint? oil-future-token amount tx-sender))
    
    (map-set futures-contracts contract-id
      {
        owner: tx-sender,
        amount: amount,
        strike-price: strike-price,
        expiry-block: (var-get contract-expiry),
        settled: false
      }
    )
    
    (map-set user-positions tx-sender
      {
        total-invested: (+ (get total-invested user-pos) investment-cost),
        active-contracts: (+ (get active-contracts user-pos) u1),
        total-returns: (get total-returns user-pos)
      }
    )
    
    (var-set total-contracts contract-id)
    (ok contract-id)
  )
)

(define-public (transfer-contract (contract-id uint) (recipient principal))
  (match (map-get? futures-contracts contract-id)
    contract-data
    (begin
      (asserts! (is-eq tx-sender (get owner contract-data)) err-unauthorized)
      (asserts! (not (get settled contract-data)) err-contract-expired)
      
      (try! (ft-transfer? oil-future-token (get amount contract-data) tx-sender recipient))
      
      (map-set futures-contracts contract-id
        (merge contract-data {owner: recipient})
      )
      
      (let
        (
          (sender-pos (get-user-position tx-sender))
          (recipient-pos (get-user-position recipient))
        )
        (map-set user-positions tx-sender
          (merge sender-pos {active-contracts: (- (get active-contracts sender-pos) u1)})
        )
        (map-set user-positions recipient
          (merge recipient-pos {active-contracts: (+ (get active-contracts recipient-pos) u1)})
        )
      )
      
      (ok true)
    )
    (err u101)
  )
)

(define-public (settle-contract (contract-id uint))
  (match (map-get? futures-contracts contract-id)
    contract-data
    (let
      (
        (owner (get owner contract-data))
        (amount (get amount contract-data))
        (strike-price (get strike-price contract-data))
        (current-price (var-get oil-price-usd))
        (is-expired (>= stacks-block-height (get expiry-block contract-data)))
        (profit (if (> current-price strike-price) 
                   (* amount (- current-price strike-price))
                   u0))
        (user-pos (get-user-position owner))
      )
      (asserts! is-expired err-contract-not-expired)
      (asserts! (not (get settled contract-data)) err-contract-expired)
      
      (try! (ft-burn? oil-future-token amount owner))
      
      (if (> profit u0)
        (begin
          (try! (as-contract (stx-transfer? profit tx-sender owner)))
          true
        )
        true
      )
      
      (map-set futures-contracts contract-id
        (merge contract-data {settled: true})
      )
      
      (map-set user-positions owner
        (merge user-pos 
          {
            active-contracts: (- (get active-contracts user-pos) u1),
            total-returns: (+ (get total-returns user-pos) profit)
          }
        )
      )
      
      (ok profit)
    )
    (err u101)
  )
)

(define-public (emergency-shutdown)
  (begin
    (asserts! (is-eq tx-sender contract-owner) err-owner-only)
    (var-set contract-active false)
    (ok true)
  )
)

(define-public (set-minimum-investment (new-min uint))
  (begin
    (asserts! (is-eq tx-sender contract-owner) err-owner-only)
    (var-set min-investment new-min)
    (ok true)
  )
)

(define-public (bulk-settle-expired)
  (let
    (
      (current-block stacks-block-height)
      (expiry (var-get contract-expiry))
    )
    (asserts! (>= current-block expiry) err-contract-not-expired)
    (var-set settlement-price (var-get oil-price-usd))
    (ok (var-get settlement-price))
  )
)

(define-read-only (get-settlement-info)
  {
    settlement-price: (var-get settlement-price),
    is-settlement-active: (>= stacks-block-height (var-get contract-expiry))
  }
)
