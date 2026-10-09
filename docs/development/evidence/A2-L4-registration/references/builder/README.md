# A2-L4 root archive builder proposal

Source-only proposal. Original runtime bytes are checked in their archived receipt, not against later live runtime files (such as an independently updated dev target map). The builder has not been executed, and this directory is not the portable evidence archive. It starts with `.gdignore`. It changes no runtime, worker content, original receipts, Git state or engine process.

The intended new destination is `docs/development/evidence/A2-L4-registration`. The builder refuses an existing destination. It validates everything before creating a temporary output, then copies original bytes, verifies complete output membership and renames the completed directory into place. It removes only its own temporary output on failure.

Run selection is explicit:

- `import1`: original 321-source freeze, submission, observed closure and independent full native/wrapper logs. Import only. Include the original mistaken UID expectation and its separate correction.
- `registration1`: original 322-source freeze, submission, observed closure and independent full native/wrapper logs. Actual root production registration, 243/0 in its own bounded scope.
- `transition2`: original 349-source freeze and failed 5/1, exit1 native/wrapper/submission/closure. Native user-directory refusal and system CA diagnostic occurred before artifact/save setup. No route or cleanup credit.
- `transition3`: separately captured original349 and submission. Its separately observed closure is exit0, 1375/0. Complete independent native/wrapper496-byte streams and the original349 are required. This pass never replaces the failed transition2 scope.
- `unused-transition1`: qualified original349 source freeze and qualification, without a submission, native run or result. Included by default; `--omit-unused` omits its source tree while retaining the original context qualification.

Copy the exact candidate-selection/content-import/supplement receipts, canonical HANDOFF9d5a and supplement RESPONSEed4d, validation text outputs, independent original missing28 report, preimport UID receipt and postimport correction. Nine generated UID files are copied into a separately labeled after-import metadata directory. They never enter the original321-source manifest.

The authoritative owned pack remains at `docs/acts/act2/evidence/A2-L4`. The builder verifies its 8,181 inventoried artifacts and two explicitly excluded inventory documents, and copies only four inventory/index documents as reference receipts. It does not duplicate the approximately450MB owned pack or relabel its historical failed/incomplete/clean executions and Shared32/34/35/36 attribution as Shared37 runs. Actual original membership, timestamps and comments remain unchanged.

All selected closures are now available. Root may execute after review:

```sh
python3 .cinder/a2-l4-root-archive-draft/build_archive.py --preflight-only
python3 .cinder/a2-l4-root-archive-draft/build_archive.py
```

The first command is read-only. Both refuse a missing closure before opening any possibly active log. No engine or Git command is used. Output is labeled `closed_originals_packaged_pending_independent_review`; packaging is not production acceptance.

## Minimum original receipt schema

Each source manifest requires `files:[{path,archived_path,bytes,sha256}]`, the exact selected source count, and no physical archive members beyond those files plus original `manifest.json`/`.gdignore`. Original source paths join exactly to `files/<path>`. Literal/dynamic/import coverage limits remain in the manifest and index.

Each submission requires its original `argv`, candidate and source-manifest SHA. Each closure requires nonempty `closed_at`, integer `observed_parent_exit_code`, matching `source_count`/source-manifest SHA, `all_original_copies_exact:true`, `original_current_drift:[]`, its bounded `checks`/`failures` (both null for import), and `logs.native`/`logs.wrapper` with original `path`/`bytes`/`sha256`. A qualification is read from `scope` or the original `classification`; neither is rewritten. Native and wrapper filenames must match the selected run prefix. Their complete bytes are copied separately even when identical.

Clean functional closures require a matching printed result and no script/parse/compile/error/warning/leak marker in either complete log. Failed scopes retain their diagnostics and original qualification. No combined check total is an acceptance claim. A missing/malformed receipt, member, byte/hash join, duplicate destination or drift causes refusal before final output.

`expected_inputs.json` pins31 known immutable metadata/reference inputs, including the now-observed transition3 closure. Both independent log hashes come from their respective unchanged closures. No import4 or transition-test UID is backfilled. `manifest.json` describes this proposal's own files, not engine execution. The Python source is syntax-checked only; the builder's validation/copy path is unexecuted until root selects it.
