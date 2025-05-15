;; Allocation Contract
;; Manages sustainable distribution of resources

(define-data-var admin principal tx-sender)

;; Allocation data structure
(define-map allocations
  { allocation-id: uint }
  {
    resource-id: uint,
    recipient: principal,
    amount: uint,
    start-block: uint,
    end-block: uint,
    active: bool
  }
)

;; Allocation counter
(define-data-var allocation-count uint u0)

;; Resource quotas
(define-map resource-quotas
  { resource-id: uint }
  { max-allocation: uint, allocated: uint }
)

;; Create a new allocation
(define-public (create-allocation (resource-id uint) (recipient principal) (amount uint) (duration uint))
  (let (
    (allocation-id (var-get allocation-count))
    (quota (default-to { max-allocation: u0, allocated: u0 } (map-get? resource-quotas { resource-id: resource-id })))
  )
    (begin
      (asserts! (is-eq tx-sender (var-get admin)) (err u403))
      (asserts! (<= (+ (get allocated quota) amount) (get max-allocation quota)) (err u401))

      (map-set allocations
        { allocation-id: allocation-id }
        {
          resource-id: resource-id,
          recipient: recipient,
          amount: amount,
          start-block: block-height,
          end-block: (+ block-height duration),
          active: true
        }
      )

      (map-set resource-quotas
        { resource-id: resource-id }
        { max-allocation: (get max-allocation quota), allocated: (+ (get allocated quota) amount) }
      )

      (var-set allocation-count (+ allocation-id u1))
      (ok allocation-id)
    )
  )
)

;; Set resource quota
(define-public (set-resource-quota (resource-id uint) (max-allocation uint))
  (begin
    (asserts! (is-eq tx-sender (var-get admin)) (err u403))
    (map-set resource-quotas
      { resource-id: resource-id }
      { max-allocation: max-allocation, allocated: u0 }
    )
    (ok true)
  )
)

;; End an allocation
(define-public (end-allocation (allocation-id uint))
  (let (
    (allocation (unwrap! (map-get? allocations { allocation-id: allocation-id }) (err u404)))
    (quota (default-to { max-allocation: u0, allocated: u0 }
            (map-get? resource-quotas { resource-id: (get resource-id allocation) })))
  )
    (begin
      (asserts! (or (is-eq tx-sender (var-get admin)) (is-eq tx-sender (get recipient allocation))) (err u403))
      (asserts! (get active allocation) (err u400))

      (map-set allocations
        { allocation-id: allocation-id }
        (merge allocation { active: false, end-block: block-height })
      )

      (map-set resource-quotas
        { resource-id: (get resource-id allocation) }
        {
          max-allocation: (get max-allocation quota),
          allocated: (- (get allocated quota) (get amount allocation))
        }
      )

      (ok true)
    )
  )
)

;; Get allocation details
(define-read-only (get-allocation (allocation-id uint))
  (map-get? allocations { allocation-id: allocation-id })
)

;; Set a new admin
(define-public (set-admin (new-admin principal))
  (begin
    (asserts! (is-eq tx-sender (var-get admin)) (err u403))
    (var-set admin new-admin)
    (ok true)
  )
)
