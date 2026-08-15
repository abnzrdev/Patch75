# Third-party boundaries

Patch75-owned code and educational content use `AGPL-3.0-only`. The license does
not alter the licenses of Flutter, Dart packages, Android components,
Chaquopy/CPython, generated platform files, or user-supplied material.

## Runtime and build dependencies

Material dependencies include Flutter, `re_editor`, `fsrs`, `archive`,
`crypto`, `share_plus`, and Chaquopy/CPython. Each retains its upstream license.
A binary release must generate and ship the notices required by the exact
locked dependency graph; `pubspec.lock` alone is not a notice bundle.

## Names referenced for attribution only

The private development history previously used data associated with cojudge,
LeetCode, the community curriculum commonly called Blind 75, and
MisterBooo/LeetCodeAnimation. Those names identify excluded historical sources;
they do not indicate endorsement, affiliation, or content included in the
current tree. No license from one project is assumed to cover third-party
problem material.

The legacy Dart package name and Android application ID still contain
`offline_leetcode_trainer`. They are technical compatibility identifiers,
retained so existing local drafts and progress continue to use the same app
storage. Patch75 is not an official LeetCode product and does not use that name
as its public product brand.

The current application distributes none of the former statements, examples,
constraints, starter code, official tests, learning metadata, animation media,
or content-derived screenshots. Those historical objects must be removed from
all public refs before publication.
