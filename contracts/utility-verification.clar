;; utility-verification.clar
;; Validates energy providers and maintains their registration

(define-data-var contract-owner principal tx-sender)

;; Map to store verified utilities
(define-map verified-utilities principal {
  name: (string-utf8 100),
  active: bool,
  verification-date: uint
})

;; Check if caller is contract owner
(define-private (is-contract-owner)
  (is-eq tx-sender (var-get contract-owner))
)

;; Initialize contract
(define-public (initialize (new-owner principal))
  (begin
    (asserts! (is-contract-owner) (err u1))
    (ok (var-set contract-owner new-owner))
  )
)

;; Register a new utility
(define-public (register-utility (utility-address principal) (utility-name (string-utf8 100)))
  (begin
    (asserts! (is-contract-owner) (err u2))
    (asserts! (not (is-some (map-get? verified-utilities utility-address))) (err u3))
    (map-set verified-utilities utility-address {
      name: utility-name,
      active: true,
      verification-date: block-height
    })
    (ok true)
  )
)

;; Deactivate a utility
(define-public (deactivate-utility (utility-address principal))
  (begin
    (asserts! (is-contract-owner) (err u2))
    (asserts! (is-some (map-get? verified-utilities utility-address)) (err u4))
    (map-set verified-utilities utility-address (merge
      (unwrap! (map-get? verified-utilities utility-address) (err u4))
      { active: false }
    ))
    (ok true)
  )
)

;; Check if a utility is verified and active
(define-read-only (is-verified-utility (utility-address principal))
  (match (map-get? verified-utilities utility-address)
    utility-data (ok (get active utility-data))
    (err u4)
  )
)

;; Get utility information
(define-read-only (get-utility-info (utility-address principal))
  (map-get? verified-utilities utility-address)
)
