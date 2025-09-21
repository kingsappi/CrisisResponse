
;; title: CrisisResponse
;; version: 1.0.0
;; summary: A rapid decision-making platform for emergency management and disaster response coordination
;; description: This contract enables emergency responders to create incidents, propose decisions, vote on responses, and coordinate resource allocation during crisis situations.

;; traits
;;

;; token definitions
;;

;; constants
;;

;; Error codes
(define-constant ERR-NOT-AUTHORIZED (err u100))
(define-constant ERR-INCIDENT-NOT-FOUND (err u101))
(define-constant ERR-DECISION-NOT-FOUND (err u102))
(define-constant ERR-ALREADY-VOTED (err u103))
(define-constant ERR-VOTING-CLOSED (err u104))
(define-constant ERR-INVALID-STATUS (err u105))
(define-constant ERR-INSUFFICIENT-RESOURCES (err u106))

;; Role constants
(define-constant ROLE-ADMIN u1)
(define-constant ROLE-COMMANDER u2)
(define-constant ROLE-RESPONDER u3)

;; Status constants
(define-constant STATUS-ACTIVE u1)
(define-constant STATUS-RESOLVED u2)
(define-constant STATUS-ESCALATED u3)

(define-constant DECISION-PENDING u1)
(define-constant DECISION-APPROVED u2)
(define-constant DECISION-REJECTED u3)

;; data vars
;;

(define-data-var contract-owner principal tx-sender)
(define-data-var incident-counter uint u0)
(define-data-var decision-counter uint u0)

;; data maps
;;

;; User roles mapping
(define-map user-roles principal uint)

;; Emergency incidents
(define-map incidents uint {
    title: (string-ascii 100),
    description: (string-ascii 500),
    severity: uint,
    status: uint,
    location: (string-ascii 100),
    reporter: principal,
    commander: (optional principal),
    created-at: uint,
    updated-at: uint
})

;; Decisions related to incidents
(define-map decisions uint {
    incident-id: uint,
    title: (string-ascii 100),
    description: (string-ascii 500),
    proposed-by: principal,
    status: uint,
    votes-for: uint,
    votes-against: uint,
    voting-deadline: uint,
    created-at: uint
})

;; Resource allocations
(define-map resource-allocations uint {
    incident-id: uint,
    resource-type: (string-ascii 50),
    quantity: uint,
    allocated-by: principal,
    allocated-at: uint
})

;; Voting records
(define-map votes { decision-id: uint, voter: principal } bool)

;; Resource inventory
(define-map resources (string-ascii 50) uint)

;; public functions
;;

;; Initialize contract with admin role for deployer
(define-public (initialize)
    (begin
        (map-set user-roles tx-sender ROLE-ADMIN)
        (ok true)
    )
)

;; Admin function to assign roles
(define-public (assign-role (user principal) (role uint))
    (begin
        (asserts! (is-eq (default-to u0 (map-get? user-roles tx-sender)) ROLE-ADMIN) ERR-NOT-AUTHORIZED)
        (asserts! (or (is-eq role ROLE-ADMIN) (is-eq role ROLE-COMMANDER) (is-eq role ROLE-RESPONDER)) ERR-INVALID-STATUS)
        (ok (map-set user-roles user role))
    )
)

;; Create a new emergency incident
(define-public (create-incident (title (string-ascii 100)) (description (string-ascii 500)) (severity uint) (location (string-ascii 100)))
    (let ((incident-id (+ (var-get incident-counter) u1)))
        (begin
            (asserts! (>= (default-to u0 (map-get? user-roles tx-sender)) ROLE-RESPONDER) ERR-NOT-AUTHORIZED)
            (map-set incidents incident-id {
                title: title,
                description: description,
                severity: severity,
                status: STATUS-ACTIVE,
                location: location,
                reporter: tx-sender,
                commander: none,
                created-at: block-height,
                updated-at: block-height
            })
            (var-set incident-counter incident-id)
            (ok incident-id)
        )
    )
)

;; Assign a commander to an incident
(define-public (assign-commander (incident-id uint) (commander principal))
    (let ((incident (unwrap! (map-get? incidents incident-id) ERR-INCIDENT-NOT-FOUND)))
        (begin
            (asserts! (is-eq (default-to u0 (map-get? user-roles tx-sender)) ROLE-ADMIN) ERR-NOT-AUTHORIZED)
            (asserts! (>= (default-to u0 (map-get? user-roles commander)) ROLE-COMMANDER) ERR-NOT-AUTHORIZED)
            (map-set incidents incident-id (merge incident {
                commander: (some commander),
                updated-at: block-height
            }))
            (ok true)
        )
    )
)

;; Update incident status
(define-public (update-incident-status (incident-id uint) (new-status uint))
    (let ((incident (unwrap! (map-get? incidents incident-id) ERR-INCIDENT-NOT-FOUND)))
        (begin
            (asserts! (or
                (is-eq (default-to u0 (map-get? user-roles tx-sender)) ROLE-ADMIN)
                (is-eq (some tx-sender) (get commander incident))
            ) ERR-NOT-AUTHORIZED)
            (asserts! (or (is-eq new-status STATUS-ACTIVE) (is-eq new-status STATUS-RESOLVED) (is-eq new-status STATUS-ESCALATED)) ERR-INVALID-STATUS)
            (map-set incidents incident-id (merge incident {
                status: new-status,
                updated-at: block-height
            }))
            (ok true)
        )
    )
)

;; Propose a decision for an incident
(define-public (propose-decision (incident-id uint) (title (string-ascii 100)) (description (string-ascii 500)) (voting-period uint))
    (let ((decision-id (+ (var-get decision-counter) u1)))
        (begin
            (asserts! (is-some (map-get? incidents incident-id)) ERR-INCIDENT-NOT-FOUND)
            (asserts! (>= (default-to u0 (map-get? user-roles tx-sender)) ROLE-COMMANDER) ERR-NOT-AUTHORIZED)
            (map-set decisions decision-id {
                incident-id: incident-id,
                title: title,
                description: description,
                proposed-by: tx-sender,
                status: DECISION-PENDING,
                votes-for: u0,
                votes-against: u0,
                voting-deadline: (+ block-height voting-period),
                created-at: block-height
            })
            (var-set decision-counter decision-id)
            (ok decision-id)
        )
    )
)

;; Vote on a decision
(define-public (vote-on-decision (decision-id uint) (vote bool))
    (let ((decision (unwrap! (map-get? decisions decision-id) ERR-DECISION-NOT-FOUND)))
        (begin
            (asserts! (>= (default-to u0 (map-get? user-roles tx-sender)) ROLE-RESPONDER) ERR-NOT-AUTHORIZED)
            (asserts! (< block-height (get voting-deadline decision)) ERR-VOTING-CLOSED)
            (asserts! (is-none (map-get? votes { decision-id: decision-id, voter: tx-sender })) ERR-ALREADY-VOTED)
            (map-set votes { decision-id: decision-id, voter: tx-sender } vote)
            (if vote
                (map-set decisions decision-id (merge decision { votes-for: (+ (get votes-for decision) u1) }))
                (map-set decisions decision-id (merge decision { votes-against: (+ (get votes-against decision) u1) }))
            )
            (ok true)
        )
    )
)

;; Finalize a decision
(define-public (finalize-decision (decision-id uint))
    (let ((decision (unwrap! (map-get? decisions decision-id) ERR-DECISION-NOT-FOUND)))
        (begin
            (asserts! (or
                (is-eq (default-to u0 (map-get? user-roles tx-sender)) ROLE-ADMIN)
                (is-eq tx-sender (get proposed-by decision))
            ) ERR-NOT-AUTHORIZED)
            (asserts! (>= block-height (get voting-deadline decision)) ERR-VOTING-CLOSED)
            (let ((new-status (if (> (get votes-for decision) (get votes-against decision)) DECISION-APPROVED DECISION-REJECTED)))
                (map-set decisions decision-id (merge decision { status: new-status }))
                (ok new-status)
            )
        )
    )
)

;; Allocate resources to an incident
(define-public (allocate-resources (incident-id uint) (resource-type (string-ascii 50)) (quantity uint))
    (begin
        (asserts! (is-some (map-get? incidents incident-id)) ERR-INCIDENT-NOT-FOUND)
        (asserts! (>= (default-to u0 (map-get? user-roles tx-sender)) ROLE-COMMANDER) ERR-NOT-AUTHORIZED)
        (let ((available (default-to u0 (map-get? resources resource-type))))
            (asserts! (>= available quantity) ERR-INSUFFICIENT-RESOURCES)
            (map-set resources resource-type (- available quantity))
            (map-set resource-allocations (+ (var-get decision-counter) u1) {
                incident-id: incident-id,
                resource-type: resource-type,
                quantity: quantity,
                allocated-by: tx-sender,
                allocated-at: block-height
            })
            (ok true)
        )
    )
)

;; Add resources to inventory (admin only)
(define-public (add-resources (resource-type (string-ascii 50)) (quantity uint))
    (begin
        (asserts! (is-eq (default-to u0 (map-get? user-roles tx-sender)) ROLE-ADMIN) ERR-NOT-AUTHORIZED)
        (let ((current (default-to u0 (map-get? resources resource-type))))
            (map-set resources resource-type (+ current quantity))
            (ok true)
        )
    )
)

;; read only functions
;;

;; Get user role
(define-read-only (get-user-role (user principal))
    (default-to u0 (map-get? user-roles user))
)

;; Get incident details
(define-read-only (get-incident (incident-id uint))
    (map-get? incidents incident-id)
)

;; Get decision details
(define-read-only (get-decision (decision-id uint))
    (map-get? decisions decision-id)
)

;; Get resource availability
(define-read-only (get-resource-availability (resource-type (string-ascii 50)))
    (default-to u0 (map-get? resources resource-type))
)

;; Check if user has voted on a decision
(define-read-only (has-voted (decision-id uint) (voter principal))
    (is-some (map-get? votes { decision-id: decision-id, voter: voter }))
)

;; Get vote for a specific voter and decision
(define-read-only (get-vote (decision-id uint) (voter principal))
    (map-get? votes { decision-id: decision-id, voter: voter })
)

;; Get current counters
(define-read-only (get-incident-counter)
    (var-get incident-counter)
)

(define-read-only (get-decision-counter)
    (var-get decision-counter)
)

;; private functions
;;

