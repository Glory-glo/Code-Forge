;; Code Forge - Decentralized Software Development with Quality Assurance
;; A platform for managing software development projects with built-in QA processes

;; Constants
(define-constant contract-owner tx-sender)
(define-constant err-owner-only (err u100))
(define-constant err-not-found (err u101))
(define-constant err-unauthorized (err u102))
(define-constant err-invalid-status (err u103))
(define-constant err-insufficient-payment (err u104))
(define-constant err-project-completed (err u105))

;; Data Variables
(define-data-var next-project-id uint u1)
(define-data-var platform-fee-percentage uint u5) ;; 5% platform fee

;; Project Status Types
(define-constant status-open u0)
(define-constant status-in-progress u1)
(define-constant status-under-review u2)
(define-constant status-revision-needed u3)
(define-constant status-completed u4)
(define-constant status-cancelled u5)

;; Data Maps
(define-map projects
  { project-id: uint }
  {
    client: principal,
    developer: (optional principal),
    qa-reviewer: (optional principal),
    title: (string-ascii 100),
    description: (string-ascii 500),
    budget: uint,
    status: uint,
    created-at: uint,
    deadline: uint,
    client-satisfaction: (optional uint), ;; 1-5 rating
    qa-score: (optional uint) ;; 1-5 rating
  }
)

(define-map project-milestones
  { project-id: uint, milestone-id: uint }
  {
    description: (string-ascii 200),
    payment-amount: uint,
    completed: bool,
    qa-approved: bool
  }
)

(define-map developer-profiles
  { developer: principal }
  {
    reputation-score: uint,
    completed-projects: uint,
    average-rating: uint,
    is-verified: bool
  }
)

(define-map qa-reviewer-profiles
  { reviewer: principal }
  {
    reputation-score: uint,
    reviews-completed: uint,
    average-accuracy: uint,
    is-verified: bool
  }
)

(define-map project-applications
  { project-id: uint, applicant: principal }
  {
    proposal: (string-ascii 300),
    proposed-timeline: uint,
    applied-at: uint
  }
)

;; Helper Functions
(define-private (is-valid-status (status uint))
  (and (>= status status-open) (<= status status-cancelled))
)

;; Public Functions

;; Create a new project
(define-public (create-project 
  (title (string-ascii 100))
  (description (string-ascii 500))
  (budget uint)
  (deadline uint))
  (let
    ((project-id (var-get next-project-id)))
    (try! (stx-transfer? budget tx-sender (as-contract tx-sender)))
    (map-set projects
      { project-id: project-id }
      {
        client: tx-sender,
        developer: none,
        qa-reviewer: none,
        title: title,
        description: description,
        budget: budget,
        status: status-open,
        created-at: stacks-block-height,
        deadline: deadline,
        client-satisfaction: none,
        qa-score: none
      }
    )
    (var-set next-project-id (+ project-id u1))
    (ok project-id)
  )
)

;; Apply to work on a project
(define-public (apply-to-project 
  (project-id uint)
  (proposal (string-ascii 300))
  (proposed-timeline uint))
  (let
    ((project-data (unwrap! (map-get? projects { project-id: project-id }) err-not-found)))
    (asserts! (is-eq (get status project-data) status-open) err-invalid-status)
    (map-set project-applications
      { project-id: project-id, applicant: tx-sender }
      {
        proposal: proposal,
        proposed-timeline: proposed-timeline,
        applied-at: stacks-block-height
      }
    )
    (ok true)
  )
)

;; Assign developer to project
(define-public (assign-developer (project-id uint) (developer principal))
  (let
    ((project-data (unwrap! (map-get? projects { project-id: project-id }) err-not-found)))
    (asserts! (is-eq tx-sender (get client project-data)) err-unauthorized)
    (asserts! (is-eq (get status project-data) status-open) err-invalid-status)
    (map-set projects
      { project-id: project-id }
      (merge project-data { 
        developer: (some developer),
        status: status-in-progress
      })
    )
    (ok true)
  )
)

;; Assign QA reviewer to project
(define-public (assign-qa-reviewer (project-id uint) (reviewer principal))
  (let
    ((project-data (unwrap! (map-get? projects { project-id: project-id }) err-not-found)))
    (asserts! (is-eq tx-sender (get client project-data)) err-unauthorized)
    (map-set projects
      { project-id: project-id }
      (merge project-data { qa-reviewer: (some reviewer) })
    )
    (ok true)
  )
)

;; Submit work for review
(define-public (submit-for-review (project-id uint))
  (let
    ((project-data (unwrap! (map-get? projects { project-id: project-id }) err-not-found)))
    (asserts! (is-eq tx-sender (unwrap! (get developer project-data) err-unauthorized)) err-unauthorized)
    (asserts! (is-eq (get status project-data) status-in-progress) err-invalid-status)
    (map-set projects
      { project-id: project-id }
      (merge project-data { status: status-under-review })
    )
    (ok true)
  )
)

;; QA Review - Approve or Request Revision
(define-public (qa-review (project-id uint) (approved bool) (qa-score uint))
  (let
    ((project-data (unwrap! (map-get? projects { project-id: project-id }) err-not-found)))
    (asserts! (is-eq tx-sender (unwrap! (get qa-reviewer project-data) err-unauthorized)) err-unauthorized)
    (asserts! (is-eq (get status project-data) status-under-review) err-invalid-status)
    (asserts! (and (>= qa-score u1) (<= qa-score u5)) err-invalid-status)
    (map-set projects
      { project-id: project-id }
      (merge project-data { 
        status: (if approved status-completed status-revision-needed),
        qa-score: (some qa-score)
      })
    )
    (ok true)
  )
)

;; Client accepts work and releases payment
(define-public (accept-and-pay (project-id uint) (client-rating uint))
  (let
    ((project-data (unwrap! (map-get? projects { project-id: project-id }) err-not-found))
     (developer (unwrap! (get developer project-data) err-not-found))
     (qa-reviewer (unwrap! (get qa-reviewer project-data) err-not-found))
     (budget (get budget project-data))
     (platform-fee (/ (* budget (var-get platform-fee-percentage)) u100))
     (developer-payment (- budget platform-fee))
     (qa-payment (/ platform-fee u2))) ;; QA gets half of platform fee
    
    (asserts! (is-eq tx-sender (get client project-data)) err-unauthorized)
    (asserts! (is-eq (get status project-data) status-completed) err-invalid-status)
    (asserts! (and (>= client-rating u1) (<= client-rating u5)) err-invalid-status)
    
    ;; Transfer payments
    (try! (as-contract (stx-transfer? developer-payment tx-sender developer)))
    (try! (as-contract (stx-transfer? qa-payment tx-sender qa-reviewer)))
    
    ;; Update project status
    (map-set projects
      { project-id: project-id }
      (merge project-data { 
        status: status-completed,
        client-satisfaction: (some client-rating)
      })
    )
    
    ;; Update developer reputation
    (update-developer-reputation developer client-rating)
    
    ;; Update QA reviewer reputation  
    (update-qa-reputation qa-reviewer (default-to u5 (get qa-score project-data)))
    
    (ok true)
  )
)

;; Cancel project (only by client before assignment)
(define-public (cancel-project (project-id uint))
  (let
    ((project-data (unwrap! (map-get? projects { project-id: project-id }) err-not-found)))
    (asserts! (is-eq tx-sender (get client project-data)) err-unauthorized)
    (asserts! (is-eq (get status project-data) status-open) err-invalid-status)
    
    ;; Refund client
    (try! (as-contract (stx-transfer? (get budget project-data) tx-sender (get client project-data))))
    
    (map-set projects
      { project-id: project-id }
      (merge project-data { status: status-cancelled })
    )
    (ok true)
  )
)

;; Private helper functions for reputation updates
(define-private (update-developer-reputation (developer principal) (rating uint))
  (let
    ((profile (default-to 
      { reputation-score: u0, completed-projects: u0, average-rating: u0, is-verified: false }
      (map-get? developer-profiles { developer: developer })))
     (new-completed (+ (get completed-projects profile) u1))
     (new-avg-rating (/ (+ (* (get average-rating profile) (get completed-projects profile)) rating) new-completed)))
    
    (map-set developer-profiles
      { developer: developer }
      (merge profile {
        completed-projects: new-completed,
        average-rating: new-avg-rating,
        reputation-score: (+ (get reputation-score profile) (* rating u10))
      })
    )
  )
)

(define-private (update-qa-reputation (reviewer principal) (accuracy uint))
  (let
    ((profile (default-to 
      { reputation-score: u0, reviews-completed: u0, average-accuracy: u0, is-verified: false }
      (map-get? qa-reviewer-profiles { reviewer: reviewer })))
     (new-reviews (+ (get reviews-completed profile) u1))
     (new-avg-accuracy (/ (+ (* (get average-accuracy profile) (get reviews-completed profile)) accuracy) new-reviews)))
    
    (map-set qa-reviewer-profiles
      { reviewer: reviewer }
      (merge profile {
        reviews-completed: new-reviews,
        average-accuracy: new-avg-accuracy,
        reputation-score: (+ (get reputation-score profile) (* accuracy u5))
      })
    )
  )
)

;; Read-only functions

(define-read-only (get-project (project-id uint))
  (map-get? projects { project-id: project-id })
)

(define-read-only (get-developer-profile (developer principal))
  (map-get? developer-profiles { developer: developer })
)

(define-read-only (get-qa-profile (reviewer principal))
  (map-get? qa-reviewer-profiles { reviewer: reviewer })
)

(define-read-only (get-project-application (project-id uint) (applicant principal))
  (map-get? project-applications { project-id: project-id, applicant: applicant })
)

(define-read-only (get-next-project-id)
  (var-get next-project-id)
)

;; Admin functions (only contract owner)

(define-public (set-platform-fee (new-fee uint))
  (begin
    (asserts! (is-eq tx-sender contract-owner) err-owner-only)
    (asserts! (<= new-fee u20) err-invalid-status) ;; Max 20% fee
    (var-set platform-fee-percentage new-fee)
    (ok true)
  )
)

(define-public (verify-developer (developer principal))
  (let
    ((profile (unwrap! (map-get? developer-profiles { developer: developer }) err-not-found)))
    (asserts! (is-eq tx-sender contract-owner) err-owner-only)
    (map-set developer-profiles
      { developer: developer }
      (merge profile { is-verified: true })
    )
    (ok true)
  )
)

(define-public (verify-qa-reviewer (reviewer principal))
  (let
    ((profile (unwrap! (map-get? qa-reviewer-profiles { reviewer: reviewer }) err-not-found)))
    (asserts! (is-eq tx-sender contract-owner) err-owner-only)
    (map-set qa-reviewer-profiles
      { reviewer: reviewer }
      (merge profile { is-verified: true })
    )
    (ok true)
  )
)