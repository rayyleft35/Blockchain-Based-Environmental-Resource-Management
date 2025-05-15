;; Resource Verification Contract
;; Validates natural assets on the blockchain

(define-data-var admin principal tx-sender)

;; Resource data structure
(define-map resources
  { resource-id: uint }
  {
    name: (string-utf8 100),
    location: (string-utf8 100),
    resource-type: (string-utf8 50),
    verified: bool,
    verifier: principal,
    timestamp: uint
  }
)

;; Verified resources counter
(define-data-var resource-count uint u0)

;; Register a new resource
(define-public (register-resource (name (string-utf8 100)) (location (string-utf8 100)) (resource-type (string-utf8 50)))
  (let ((resource-id (var-get resource-count)))
    (begin
      (map-set resources
        { resource-id: resource-id }
        {
          name: name,
          location: location,
          resource-type: resource-type,
          verified: false,
          verifier: tx-sender,
          timestamp: block-height
        }
      )
      (var-set resource-count (+ resource-id u1))
      (ok resource-id)
    )
  )
)

;; Verify a resource (only authorized verifiers)
(define-public (verify-resource (resource-id uint))
  (let ((resource (unwrap! (map-get? resources { resource-id: resource-id }) (err u404))))
    (begin
      (asserts! (is-authorized-verifier tx-sender) (err u403))
      (map-set resources
        { resource-id: resource-id }
        (merge resource { verified: true, verifier: tx-sender, timestamp: block-height })
      )
      (ok true)
    )
  )
)

;; Check if a principal is authorized to verify resources
(define-private (is-authorized-verifier (verifier principal))
  (is-eq verifier (var-get admin))
)

;; Get resource details
(define-read-only (get-resource (resource-id uint))
  (map-get? resources { resource-id: resource-id })
)

;; Set a new admin
(define-public (set-admin (new-admin principal))
  (begin
    (asserts! (is-eq tx-sender (var-get admin)) (err u403))
    (var-set admin new-admin)
    (ok true)
  )
)
