;; Conservation Initiative Contract
;; Tracks preservation efforts

(define-data-var admin principal tx-sender)

;; Initiative data structure
(define-map initiatives
  { initiative-id: uint }
  {
    name: (string-utf8 100),
    description: (string-utf8 500),
    location: (string-utf8 100),
    creator: principal,
    start-block: uint,
    end-block: uint,
    target-goal: uint,
    current-progress: uint,
    active: bool
  }
)

;; Initiative counter
(define-data-var initiative-count uint u0)

;; Create a new conservation initiative
(define-public (create-initiative
  (name (string-utf8 100))
  (description (string-utf8 500))
  (location (string-utf8 100))
  (duration uint)
  (target-goal uint)
)
  (let ((initiative-id (var-get initiative-count)))
    (begin
      (map-set initiatives
        { initiative-id: initiative-id }
        {
          name: name,
          description: description,
          location: location,
          creator: tx-sender,
          start-block: block-height,
          end-block: (+ block-height duration),
          target-goal: target-goal,
          current-progress: u0,
          active: true
        }
      )
      (var-set initiative-count (+ initiative-id u1))
      (ok initiative-id)
    )
  )
)

;; Update initiative progress
(define-public (update-progress (initiative-id uint) (progress-amount uint))
  (let ((initiative (unwrap! (map-get? initiatives { initiative-id: initiative-id }) (err u404))))
    (begin
      (asserts! (or (is-eq tx-sender (var-get admin)) (is-eq tx-sender (get creator initiative))) (err u403))
      (asserts! (get active initiative) (err u400))

      (map-set initiatives
        { initiative-id: initiative-id }
        (merge initiative {
          current-progress: (+ (get current-progress initiative) progress-amount)
        })
      )

      (ok true)
    )
  )
)

;; Complete an initiative
(define-public (complete-initiative (initiative-id uint))
  (let ((initiative (unwrap! (map-get? initiatives { initiative-id: initiative-id }) (err u404))))
    (begin
      (asserts! (or (is-eq tx-sender (var-get admin)) (is-eq tx-sender (get creator initiative))) (err u403))
      (asserts! (get active initiative) (err u400))
      (asserts! (>= (get current-progress initiative) (get target-goal initiative)) (err u401))

      (map-set initiatives
        { initiative-id: initiative-id }
        (merge initiative {
          active: false,
          end-block: block-height
        })
      )

      (ok true)
    )
  )
)

;; Get initiative details
(define-read-only (get-initiative (initiative-id uint))
  (map-get? initiatives { initiative-id: initiative-id })
)

;; Set a new admin
(define-public (set-admin (new-admin principal))
  (begin
    (asserts! (is-eq tx-sender (var-get admin)) (err u403))
    (var-set admin new-admin)
    (ok true)
  )
)
