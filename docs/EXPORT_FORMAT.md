# Progress export format

Exports use the `.olt.zip` suffix. `manifest.json` records schema version, app
version, UTC export time, origin device ID, size, and SHA-256 for every payload.
`data/state.json` contains the versioned application state. Optional private
materials use `materials/<problem-slug>/<material-id>.<extension>`.

Import rejects corrupt checksums, absolute paths, traversal, backslashes,
links, duplicate paths, more than 1000 entries, archives over 512 MiB, and
entries over 256 MiB. Replace restores the archive state; merge combines
problem data, deduplicates stable IDs, uses the newest available timestamp for
mutable records, and otherwise preserves a local conflict.

Before applying an import the app writes a complete state and materials backup
under its private application-support directory. Material writes and state
persistence are rolled back if import fails. Unknown archive schema versions
are rejected instead of guessed.
