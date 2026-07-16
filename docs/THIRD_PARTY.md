# Third-Party Sources

## cojudge/cojudge

- Repository: https://github.com/cojudge/cojudge
- Inspected revision: `d8736f2c53f74e4e08dde25d38f4f0586302dd02`
- License: MIT, copyright 2025 cojudge.
- Use: Blind 75 ordering, normalized problem metadata/statements/examples,
  starter code, tests, and reference behavior for the Docker judge.
- Redistribution: permitted with the copyright and permission notice. The
  project preserves source URLs and includes the upstream license alongside
  generated data attribution.
- Caveat: upstream states that some tests and reference markers were
  AI-assisted and human-reviewed; imported cases remain covered by local tests.

## MisterBooo/LeetCodeAnimation

- Repository: https://github.com/MisterBooo/LeetCodeAnimation
- Inspected revision: `e853d7a5a893292b9d4636c78c080daf11552c81`
- License: no LICENSE file or license grant was present at inspection time.
- Use: manifest metadata only for ID/slug/title matching and local checkout path
  discovery.
- Redistribution: not authorized. GIFs, images, articles, translated text, and
  preview media are not committed or packaged. Users may point the importer at
  their ignored local checkout; the app records attribution and availability.
- Revisit only after the copyright holder publishes an explicit compatible
  license or grants written permission.

## Flutter packages and Android runtime

- Flutter/Dart: BSD-3-Clause; application framework and standard libraries.
- `re_editor` 0.10.0: MIT; editable cross-platform code editor with line
  numbers and keyboard editing.
- `re_highlight`: BSD-3-Clause; Python syntax highlighting used by
  `re_editor`.
- `path_provider`: BSD-3-Clause; application-support directory discovery.
- Chaquopy 17.0 with Python 3.11: MIT; Android embedded CPython. Minimum Android API 24 and AGP
  7.3–9.2. It is an execution runtime, not a secure hostile-code sandbox.

Package versions and transitive notices are regenerated from `pubspec.lock`
and Gradle dependency output before release.
