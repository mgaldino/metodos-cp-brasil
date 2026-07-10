# Independent Python review

No blocking findings. The implementation matches the intended rule.

## Medium — asymmetric identity conditions are not tested

The negative test changes the hash at both levels simultaneously ([test file](/Users/manoelgaldino/Documents/DCP/Papers/metodos_CP/scripts/test_integral_codex_batch_validation.py:181)). It does not prove that canonicalization is rejected when only one of these differs:

- Top-level `pid`
- Classification `pid`
- Top-level `input_text_hash`
- Classification `input_text_hash`

Add parameterized tests for these four asymmetric cases. Otherwise, a future regression checking only one level could pass the suite.

## Low — empty manifest identities are not fail-closed

The predicate uses `row.get()` ([runner](/Users/manoelgaldino/Documents/DCP/Papers/metodos_CP/scripts/25_run_credibility_prompt_v3_integral_codex_batch.py:273)), while validation skips comparisons when the manifest value is empty. Thus, empty `pid` or hash values could match empty response values and permit canonicalization. The frozen manifest presumably prevents this, but `load_manifest()` does not enforce non-empty identity fields. A manifest-integrity test would make that assumption auditable.

## Low — persistence behavior lacks integration coverage

Unit tests confirm the in-memory mutation, but not the complete `run_codex_for_row()` path. Add a test confirming that:

- Only `title` and `journal_title` change.
- Canonicalized values reach both saved processed outputs.
- The raw response remains unchanged.
- Nothing is persisted when either identity level differs.

## Confirmed behavior

The implementation requires literal equality of both identity fields at both levels, mutates only `title` and `journal_title`, validates before processed persistence, and retains the original raw-response file. `git diff --check` passed. Pytest could not run because the read-only environment had no writable temporary directory; no files were edited.