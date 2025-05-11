;; consumer-registration.clar
;; Records participating energy users

(define-data-var contract-owner principal tx-sender)
(define-data-var utility-verification-contract principal tx-sender)

;; Map to store registered consumers
(define-map registered-consumers principal {
  name: (string-utf8 100),
  energy-capacity: uint,
  flexibility-level: uint,
  active: bool,
  registration-date: uint
})

;; Check if caller is contract owner
(define-private (is-contract-owner)
  (is-eq tx-sender (var-get contract-owner))
)

;; Initialize contract
(define-public (initialize (new-owner principal) (utility-contract principal))
  (begin
    (asserts! (is-contract-owner) (err u1))
    (var-set contract-owner new-owner)
    (var-set utility-verification-contract utility-contract)
    (ok true)
  )
)

;; Register a new consumer
(define-public (register-consumer (consumer-name (string-utf8 100)) (energy-capacity uint) (flexibility-level uint))
  (begin
    (asserts! (not (is-some (map-get? registered-consumers tx-sender))) (err u2))
    (map-set registered-consumers tx-sender {
      name: consumer-name,
      energy-capacity: energy-capacity,
      flexibility-level: flexibility-level,
      active: true,
      registration-date: block-height
    })
    (ok true)
  )
)

;; Update consumer information
(define-public (update-consumer-info (energy-capacity uint) (flexibility-level uint))
  (begin
    (asserts! (is-some (map-get? registered-consumers tx-sender)) (err u3))
    (map-set registered-consumers tx-sender (merge
      (unwrap! (map-get? registered-consumers tx-sender) (err u3))
      {
        energy-capacity: energy-capacity,
        flexibility-level: flexibility-level
      }
    ))
    (ok true)
  )
)

;; Deactivate a consumer
(define-public (deactivate-consumer)
  (begin
    (asserts! (is-some (map-get? registered-consumers tx-sender)) (err u3))
    (map-set registered-consumers tx-sender (merge
      (unwrap! (map-get? registered-consumers tx-sender) (err u3))
      { active: false }
    ))
    (ok true)
  )
)

;; Admin can deactivate any consumer
(define-public (admin-deactivate-consumer (consumer-address principal))
  (begin
    (asserts! (is-contract-owner) (err u1))
    (asserts! (is-some (map-get? registered-consumers consumer-address)) (err u3))
    (map-set registered-consumers consumer-address (merge
      (unwrap! (map-get? registered-consumers consumer-address) (err u3))
      { active: false }
    ))
    (ok true)
  )
)

;; Check if a consumer is registered and active
(define-read-only (is-active-consumer (consumer-address principal))
  (match (map-get? registered-consumers consumer-address)
    consumer-data (ok (get active consumer-data))
    (err u3)
  )
)

;; Get consumer information
(define-read-only (get-consumer-info (consumer-address principal))
  (map-get? registered-consumers consumer-address)
)
