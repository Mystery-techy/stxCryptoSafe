;; CryptoSafe - Digital Asset Custody Protocol
;; An advanced platform for securing STX and fungible tokens with trustee management

(define-data-var protocol-manager principal tx-sender)

;; Constants for validation
(define-constant MIN-CUSTODY-TERM u144) ;; Minimum 1 day (assuming 144 blocks per day)
(define-constant MAX-CUSTODY-TERM u52560) ;; Maximum 1 year
(define-constant MIN-TRUSTEE-WINDOW u144) ;; Minimum 1 day trustee window
(define-constant DEFAULT-TRUSTEE-WINDOW u4320) ;; Default 30 days trustee window

;; Trustee Status
(define-constant TRUSTEE-ACTIVE u1)
(define-constant TRUSTEE-STANDBY u2)
(define-constant TRUSTEE-INACTIVE u0)

;; Digital custody structure
(define-map custody-accounts
    { account-owner: principal }
    {
        secured-balance: uint,
        maturity-height: uint,
        custody-term: uint,
        trustee: (optional principal),
        trustee-status: uint,
        trustee-window: uint,
        last-access: uint,
        currency-type: (string-ascii 32)
    }
)

;; Error codes
(define-constant ERR-ACCESS-DENIED (err u100))
(define-constant ERR-ACCOUNT-NOT-FOUND (err u101))
(define-constant ERR-ACCOUNT-EXISTS (err u102))
(define-constant ERR-FUNDS-NOT-MATURE (err u103))
(define-constant ERR-TRUSTEE-WINDOW-EXPIRED (err u104))
(define-constant ERR-INSUFFICIENT-FUNDS (err u105))
(define-constant ERR-INVALID-TERM (err u106))
(define-constant ERR-EXTENSION-TOO-SHORT (err u107))
(define-constant ERR-INVALID-TRUSTEE (err u108))
(define-constant ERR-NO-TRUSTEE-SET (err u109))
(define-constant ERR-TRUSTEE-NOT-ACTIVE (err u110))

;; Read-only functions
(define-read-only (get-account-details (account-owner principal))
    (map-get? custody-accounts { account-owner: account-owner })
)

(define-read-only (is-mature (account-owner principal))
    (let (
        (account (unwrap! (get-account-details account-owner) false))
        (current-height stacks-block-height)
    )
    (>= current-height (get maturity-height account)))
)

(define-read-only (get-remaining-custody-time (account-owner principal))
    (let (
        (account (unwrap! (get-account-details account-owner) u0))
        (current-height stacks-block-height)
    )
    (if (>= current-height (get maturity-height account))
        u0
        (- (get maturity-height account) current-height)))
)

(define-read-only (can-trustee-withdraw (account-owner principal) (trustee principal))
    (let (
        (account (unwrap! (get-account-details account-owner) false))
        (current-height stacks-block-height)
        (trustee-deadline (+ (get maturity-height account) (get trustee-window account)))
        (dormant-period (- current-height (get last-access account)))
    )
    (and
        (is-eq (some trustee) (get trustee account))
        (is-eq (get trustee-status account) TRUSTEE-ACTIVE)
        (or 
            (>= current-height trustee-deadline)
            (>= dormant-period (get trustee-window account))
        )
    ))
)

;; Public functions
(define-public (open-custody-account (custody-term uint) (trustee (optional principal)) (trustee-window uint))
    (let (
        (maturity-height (+ stacks-block-height custody-term))
        (actual-trustee-window (if (< trustee-window MIN-TRUSTEE-WINDOW) 
                                DEFAULT-TRUSTEE-WINDOW 
                                trustee-window))
    )
    (asserts! (is-none (get-account-details tx-sender)) ERR-ACCOUNT-EXISTS)
    (asserts! (and (>= custody-term MIN-CUSTODY-TERM) (<= custody-term MAX-CUSTODY-TERM)) ERR-INVALID-TERM)
    
    (map-set custody-accounts
        { account-owner: tx-sender }
        {
            secured-balance: u0,
            maturity-height: maturity-height,
            custody-term: custody-term,
            trustee: trustee,
            trustee-status: (if (is-some trustee) TRUSTEE-ACTIVE TRUSTEE-INACTIVE),
            trustee-window: actual-trustee-window,
            last-access: stacks-block-height,
            currency-type: "STX"
        }
    )
    (ok true))
)

(define-public (extend-custody-term (additional-blocks uint))
    (let (
        (account (unwrap! (get-account-details tx-sender) ERR-ACCOUNT-NOT-FOUND))
        (current-height stacks-block-height)
        (new-maturity-height (+ (get maturity-height account) additional-blocks))
        (new-term (+ (get custody-term account) additional-blocks))
    )
    (asserts! (>= additional-blocks MIN-CUSTODY-TERM) ERR-EXTENSION-TOO-SHORT)
    (asserts! (<= new-term MAX-CUSTODY-TERM) ERR-INVALID-TERM)
    
    (map-set custody-accounts
        { account-owner: tx-sender }
        (merge account {
            maturity-height: new-maturity-height,
            custody-term: new-term,
            last-access: stacks-block-height
        })
    )
    (ok true))
)

(define-public (update-trustee (new-trustee (optional principal)))
    (let (
        (account (unwrap! (get-account-details tx-sender) ERR-ACCOUNT-NOT-FOUND))
    )
    (map-set custody-accounts
        { account-owner: tx-sender }
        (merge account {
            trustee: new-trustee,
            trustee-status: (if (is-some new-trustee) TRUSTEE-ACTIVE TRUSTEE-INACTIVE),
            last-access: stacks-block-height
        })
    )
    (ok true))
)

(define-public (secure-deposit (amount uint))
    (let (
        (account (unwrap! (get-account-details tx-sender) ERR-ACCOUNT-NOT-FOUND))
    )
    (try! (stx-transfer? amount tx-sender (as-contract tx-sender)))
    (map-set custody-accounts
        { account-owner: tx-sender }
        (merge account {
            secured-balance: (+ (get secured-balance account) amount),
            last-access: stacks-block-height
        })
    )
    (ok true))
)

(define-public (withdraw-funds (amount uint))
    (let (
        (account (unwrap! (get-account-details tx-sender) ERR-ACCOUNT-NOT-FOUND))
        (current-height stacks-block-height)
    )
    (asserts! (>= current-height (get maturity-height account)) ERR-FUNDS-NOT-MATURE)
    (asserts! (<= amount (get secured-balance account)) ERR-INSUFFICIENT-FUNDS)
    
    (try! (as-contract (stx-transfer? amount (as-contract tx-sender) tx-sender)))
    (map-set custody-accounts
        { account-owner: tx-sender }
        (merge account {
            secured-balance: (- (get secured-balance account) amount),
            last-access: stacks-block-height
        })
    )
    (ok true))
)

(define-public (trustee-withdrawal (account-owner principal))
    (let (
        (account (unwrap! (get-account-details account-owner) ERR-ACCOUNT-NOT-FOUND))
        (current-height stacks-block-height)
        (trustee-deadline (+ (get maturity-height account) (get trustee-window account)))
        (dormant-period (- current-height (get last-access account)))
    )
    ;; Verify trustee status and conditions
    (asserts! (is-some (get trustee account)) ERR-NO-TRUSTEE-SET)
    (asserts! (is-eq (some tx-sender) (get trustee account)) ERR-ACCESS-DENIED)
    (asserts! (is-eq (get trustee-status account) TRUSTEE-ACTIVE) ERR-TRUSTEE-NOT-ACTIVE)
    (asserts! (or 
        (>= current-height trustee-deadline)
        (>= dormant-period (get trustee-window account))
    ) ERR-FUNDS-NOT-MATURE)
    
    ;; Transfer funds and close account
    (try! (as-contract (stx-transfer? (get secured-balance account) (as-contract tx-sender) tx-sender)))
    (map-delete custody-accounts { account-owner: account-owner })
    (ok true))
)

(define-public (update-access)
    (let (
        (account (unwrap! (get-account-details tx-sender) ERR-ACCOUNT-NOT-FOUND))
    )
    (map-set custody-accounts
        { account-owner: tx-sender }
        (merge account { last-access: stacks-block-height })
    )
    (ok true))
)