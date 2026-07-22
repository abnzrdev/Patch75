# FSRS review

Solving a problem creates one local FSRS card. The review queue groups overdue,
due, new, and upcoming cards. A timed attempt records runs, submits, hints,
custom tests, complexity answers, pause time, and the final result.

The user must rate every completed review: Again means forgotten, Hard means
recalled with substantial effort, Good means correct recall, and Easy means
effortless recall. The next interval preview is shown before saving. Desired
retention is configurable from 0.70 through 0.99 and defaults to 0.90.

Cards and immutable rating events stay in application storage. Import merges
events by stable ID and uses the newest card update for mutable FSRS state.
The implementation uses `fsrs` 2.0.1 (MIT license).
