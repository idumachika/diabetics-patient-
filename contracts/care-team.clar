
;; title: care-team
;; version:
;; summary: A smart contract for managing care teams in the diabetic-patient app
;; description: This contract allows patients to confirm their care team consisting of doctors, dietitians, and nurses.

(define-trait care-provider-trait
  (
    (get-details (uint) (response (tuple (name (string-ascii 32)) (experience uint)) uint))
  )
)

(define-constant care-team-token-id 1)
(define-non-fungible-token care-team-membership uint)

(define-constant min-team-size 4)
(define-constant max-team-size 10)

(define-data-var care-team-count uint u0)

;; Correct the care-team-info definition to a map, not a data-var
(define-map care-team-info
  {team-id: uint}
  (tuple (team-name (string-ascii 32)) (doctor principal) (team-size uint)))

(define-map team-members
  {team-id: uint}
  {member-name: (string-ascii 32), role: (string-ascii 32), experience: uint})

(define-public (create-team (team-id uint) (team-name (string-ascii 32)) (doctor principal))
  (begin
    (if (is-some (map-get? care-team-info {team-id: team-id}))
      (err u100)
      (begin
        (map-insert care-team-info {team-id: team-id} {team-name: team-name, doctor: doctor, team-size: u0})
        (var-set care-team-count (+ (var-get care-team-count) u1))
        (ok true)
      )
    )
  )
)

(define-public (add-member (team-id uint) (member-name (string-ascii 32)) (role (string-ascii 32)) (experience uint))
  (begin
    (if (is-valid-role role)
      (begin
        (map-insert team-members {team-id: team-id} {member-name: member-name, role: role, experience: experience})
        (ok true)
      )
      (err u101)
    )
  )
)

(define-read-only (get-team-info (team-id uint))
  (match (map-get? care-team-info {team-id: team-id})
    team-info (ok team-info)
    (err u404)))

(define-private (is-valid-role (role (string-ascii 32)))
  (or
    (is-eq role "Doctor")
    (is-eq role "Nurse")
    (is-eq role "Dietician")
    (is-eq role "Public Health Personnel")
  )
)


