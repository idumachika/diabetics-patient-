
;; title: care-team
;; version:
;; summary: A smart contract for managing care teams in the diabetic-patient app
;; description: This contract allows patients to confirm their care team consisting of doctors, dietitians, and nurses.

;; Define constants
(define-constant ERR_INSUFFICIENT_FUNDS (err u100))
(define-constant ERR_TRANSFER_FAILED (err u101))
(define-constant ERR_UNAUTHORIZED (err u102))
(define-constant ERR_ALREADY_VERIFIED (err u103))
(define-constant ERR_LOAN_ACTIVE (err u104))
(define-constant ERR_NO_ACTIVE_LOAN (err u105))

;; Define data variables
(define-data-var total-liquidity uint u0)
(define-data-var governance-address principal tx-sender)

;; Define data maps
(define-map balances principal uint)
(define-map verified-diabetics principal bool)
(define-map loans
  principal
  {
    amount: uint,
    due-date: uint,
    interest-rate: uint,
    paid-amount: uint
  }
)

;; Public function to deposit liquidity
(define-public (deposit-liquidity (amount uint))
    (let
        (
            (sender tx-sender)
            (current-balance (default-to u0 (map-get? balances sender)))
        )
        (asserts! (>= (stx-get-balance sender) amount) ERR_INSUFFICIENT_FUNDS)
        (try! (stx-transfer? amount sender (as-contract tx-sender)))
        (map-set balances sender (+ current-balance amount))
        (var-set total-liquidity (+ (var-get total-liquidity) amount))
        (ok true)
    )
)

;; Public function to withdraw liquidity
(define-public (withdraw-liquidity (amount uint))
    (let
        (
            (sender tx-sender)
            (current-balance (default-to u0 (map-get? balances sender)))
        )
        (asserts! (>= current-balance amount) ERR_INSUFFICIENT_FUNDS)
        (try! (as-contract (stx-transfer? amount tx-sender sender)))
        (map-set balances sender (- current-balance amount))
        (var-set total-liquidity (- (var-get total-liquidity) amount))
        (ok true)
    )
)

;; Public function to verify a diabetic patient
(define-public (verify-diabetic (patient principal))
    (begin
        (asserts! (is-eq tx-sender (var-get governance-address)) ERR_UNAUTHORIZED)
        (asserts! (is-none (map-get? verified-diabetics patient)) ERR_ALREADY_VERIFIED)
        (map-set verified-diabetics patient true)
        (ok true)
    )
)

;; Public function to request a loan
(define-public (request-loan (amount uint) (duration uint))
    (let
        (
            (sender tx-sender)
            (is-verified (default-to false (map-get? verified-diabetics sender)))
            (current-loan (map-get? loans sender))
        )
        (asserts! is-verified ERR_UNAUTHORIZED)
        (asserts! (is-none current-loan) ERR_LOAN_ACTIVE)
        (asserts! (<= amount (var-get total-liquidity)) ERR_INSUFFICIENT_FUNDS)
        (try! (as-contract (stx-transfer? amount tx-sender sender)))
        (map-set loans sender {
            amount: amount,
            due-date: (+ block-height duration),
            interest-rate: u5, ;; 5% interest rate
            paid-amount: u0
        })
        (var-set total-liquidity (- (var-get total-liquidity) amount))
        (ok true)
    )
)

;; Public function to repay a loan
(define-public (repay-loan (amount uint))
    (let
        (
            (sender tx-sender)
            (loan (unwrap! (map-get? loans sender) ERR_NO_ACTIVE_LOAN))
            (total-due (+ (get amount loan) (* (get amount loan) (get interest-rate loan) u1)))
            (new-paid-amount (+ (get paid-amount loan) amount))
        )
        (try! (stx-transfer? amount sender (as-contract tx-sender)))
        (if (>= new-paid-amount total-due)
            (begin
                (map-delete loans sender)
                (var-set total-liquidity (+ (var-get total-liquidity) total-due))
            )
            (map-set loans sender (merge loan { paid-amount: new-paid-amount }))
        )
        (ok true)
    )
)

;; Public function to change governance address
(define-public (change-governance (new-address principal))
    (begin
        (asserts! (is-eq tx-sender (var-get governance-address)) ERR_UNAUTHORIZED)
        (var-set governance-address new-address)
        (ok true)
    )
)

;; Read-only function to get user balance
(define-read-only (get-balance (user principal))
    (default-to u0 (map-get? balances user))
)

;; Read-only function to get total liquidity
(define-read-only (get-total-liquidity)
    (var-get total-liquidity)
)

;; Read-only function to check if a user is a verified diabetic
(define-read-only (is-verified-diabetic (user principal))
    (default-to false (map-get? verified-diabetics user))
)

;; Read-only function to get loan details
(define-read-only (get-loan-details (user principal))
    (map-get? loans user)
)


