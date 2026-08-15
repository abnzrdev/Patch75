# Licensing classification

Patch75-owned source and educational content are licensed
`AGPL-3.0-only`; see the unmodified GNU AGPLv3 text in [`LICENSE`](../LICENSE).
That grant does not relicense third-party dependencies or user data.

## Current-tree classification

| Group | Classification | Evidence |
|---|---|---|
| Patch75 application source, tools, scripts, tests, CI, and project documentation | Patch75-owned → `AGPL-3.0-only` | Authored in the Patch75 repository; generated/upstream notices remain controlling where present. |
| `assets/data/problems/*.json`, `assets/data/index/all_problems.json`, and `assets/data/learning_metadata.json` | Patch75-owned → `AGPL-3.0-only` | Replaced in the public-readiness change with newly authored descriptions, examples, constraints, Python starters, deterministic fixtures, and learning guidance. Every problem record declares `source: Patch75`, `license: AGPL-3.0-only`, and `originalContent: true`. Existing IDs, slugs, short titles, topics, difficulty labels, and order were retained only as curriculum identifiers to preserve user progress. |
| `assets/branding/patch75.svg`, Android launcher vectors, and generated launcher/web PNGs | Patch75-owned → `AGPL-3.0-only` | The geometric P mark was created in the public-readiness change. PNG variants were mechanically rendered from that SVG with FFmpeg; they contain no third-party media. |
| Flutter platform scaffolding and generated registrants | Permissively licensed third-party and/or generated output | Preserve generated-file notices and Flutter's applicable BSD notices. |
| Flutter/Dart packages and Chaquopy/CPython runtime | Third-party dependencies | Their upstream licenses remain controlling. Release artifacts require notices from the exact resolved dependency graph. |
| User drafts, notes, progress, code, and imported materials | User-owned/private | Runtime data is not repository content and is never relicensed by Patch75. |

All old content-derived screenshots were removed. New screenshots may be added
only after being captured from the replacement problem pack.

## Similarity and provenance review

The replacement was compared locally with the removed baseline across each
record's prose, examples, constraints, starter code, and tests. A normalized
whole-record sequence comparison found a maximum ratio of `0.2862`; no record
reached the `0.35` manual-review threshold. This heuristic supports review but
is not a legal determination. The prior payload remains excluded from the
publication history rewrite scope.

## Remaining review boundary

No current bundled educational or presentation asset is marked unresolved.
Dependency notice generation must still be completed for a binary release.
Historical cojudge/LeetCode-derived and LeetCodeAnimation material remains a
publication blocker until reachable Git history is rewritten and re-audited.

## Publication gate

**CONTENT LICENSING CLEAR; HISTORY NOT YET CLEAR.** The current tree contains a
Patch75-authored replacement pack. Do not publish until the historical rewrite
and post-rewrite audit are complete.
