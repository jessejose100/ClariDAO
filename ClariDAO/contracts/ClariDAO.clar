;; ClariDAO: On-Chain DAO Governance
;; This contract implements a decentralized autonomous organization with proposal and voting mechanisms

;; Define constants
(define-constant ERR-NOT-AUTHORIZED (err u100))
(define-constant ERR-PROPOSAL-DOES-NOT-EXIST (err u101))
(define-constant ERR-ALREADY-VOTED (err u102))
(define-constant ERR-VOTING-CLOSED (err u103))
(define-constant ERR-INSUFFICIENT-TOKEN-BALANCE (err u104))
(define-constant ERR-PROPOSAL-NOT-APPROVED (err u105))
(define-constant ERR-QUORUM-NOT-REACHED (err u106))
(define-constant VOTING_PERIOD_BLOCKS u144) ;; ~24 hours at 10 min block times

;; Define data variables
(define-data-var proposal-count uint u0)
(define-data-var dao-treasury uint u0)
(define-data-var token-name (string-ascii 32) "DAOTOKEN")
(define-data-var quorum-threshold uint u500) ;; 500 tokens needed for quorum
(define-data-var approval-threshold uint u667) ;; 66.7% majority required

;; Define data maps
(define-map token-balances principal uint)
(define-map proposals
  uint
  {
    title: (string-ascii 100),
    description: (string-utf8 500),
    proposer: principal,
    created-at-block: uint,
    for-votes: uint,
    against-votes: uint,
    status: (string-ascii 10),
    action-data: (optional (buff 1024)),
    execution-delay: uint
  }
)

(define-map votes
  { proposal-id: uint, voter: principal }
  { vote: bool, weight: uint }
)

;; Initialize contract
(define-public (initialize-dao)
  (begin
    (var-set proposal-count u0)
    (var-set dao-treasury u0)
    (ok true)
  )
)

;; Define the contract owner as a data variable
(define-data-var contract-owner principal tx-sender)

;; Token functions
(define-public (mint-tokens (amount uint) (recipient principal))
  (if (is-eq tx-sender (var-get contract-owner))
    (ok (map-set token-balances recipient (+ (default-to u0 (map-get? token-balances recipient)) amount)))
    ERR-NOT-AUTHORIZED
  )
)

(define-read-only (get-token-balance (account principal))
  (default-to u0 (map-get? token-balances account))
)

;; Proposal functions
(define-public (create-proposal (title (string-ascii 100)) (description (string-utf8 500)) (action-data (optional (buff 1024))) (execution-delay uint))
  (let 
    (
      (proposer-balance (default-to u0 (map-get? token-balances tx-sender)))
      (proposal-id (var-get proposal-count))
    )
    (if (>= proposer-balance u100)
      (begin
        (map-set proposals proposal-id {
          title: title,
          description: description,
          proposer: tx-sender,
          created-at-block: block-height,
          for-votes: u0,
          against-votes: u0,
          status: "active",
          action-data: action-data,
          execution-delay: execution-delay
        })
        (var-set proposal-count (+ proposal-id u1))
        (ok proposal-id)
      )
      ERR-INSUFFICIENT-TOKEN-BALANCE
    )
  )
)

(define-read-only (get-proposal (proposal-id uint))
  (map-get? proposals proposal-id)
)

;; Voting functions
(define-public (vote (proposal-id uint) (support bool))
  (let
    (
      (proposal (unwrap! (map-get? proposals proposal-id) ERR-PROPOSAL-DOES-NOT-EXIST))
      (voter-token-balance (default-to u0 (map-get? token-balances tx-sender)))
      (vote-key { proposal-id: proposal-id, voter: tx-sender })
      (voting-closed (> block-height (+ (get created-at-block proposal) VOTING_PERIOD_BLOCKS)))
    )
    (asserts! (not voting-closed) ERR-VOTING-CLOSED)
    (asserts! (is-none (map-get? votes vote-key)) ERR-ALREADY-VOTED)
    (asserts! (> voter-token-balance u0) ERR-INSUFFICIENT-TOKEN-BALANCE)
    
    (map-set votes vote-key { vote: support, weight: voter-token-balance })
    
    (if support
      (map-set proposals proposal-id 
        (merge proposal { for-votes: (+ (get for-votes proposal) voter-token-balance) }))
      (map-set proposals proposal-id 
        (merge proposal { against-votes: (+ (get against-votes proposal) voter-token-balance) }))
    )
    
    (ok true)
  )
)

;; This function finalizes a proposal after the voting period has ended
;; Determines if the proposal passed based on quorum and approval thresholds
(define-public (finalize-proposal (proposal-id uint))
  (let
    (
      (proposal (unwrap! (map-get? proposals proposal-id) ERR-PROPOSAL-DOES-NOT-EXIST))
      (for-votes (get for-votes proposal))
      (against-votes (get against-votes proposal))
      (total-votes (+ for-votes against-votes))
      (voting-closed (> block-height (+ (get created-at-block proposal) VOTING_PERIOD_BLOCKS)))
      (quorum-reached (>= total-votes (var-get quorum-threshold)))
      (approval-percent (if (is-eq total-votes u0) 
                          u0 
                          (/ (* for-votes u1000) total-votes)))
      (approved (>= approval-percent (var-get approval-threshold)))
    )
    
    (asserts! voting-closed ERR-VOTING-CLOSED)
    (asserts! quorum-reached ERR-QUORUM-NOT-REACHED)
    
    (if approved
      (map-set proposals proposal-id (merge proposal { status: "approved" }))
      (map-set proposals proposal-id (merge proposal { status: "rejected" }))
    )
    
    (ok true)
  )
)

;; Advanced feature: Delegated voting system with time-locked delegation
;; This allows token holders to delegate their voting power to others
;; with the ability to reclaim it after a specified timelock period

(define-map delegations
  principal
  {
    delegate-to: principal,
    amount: uint,
    locked-until-block: uint,
    active: bool
  }
)

(define-map delegate-received
  principal
  {
    total-delegated: uint,
    delegators: (list 50 principal)
  }
)

