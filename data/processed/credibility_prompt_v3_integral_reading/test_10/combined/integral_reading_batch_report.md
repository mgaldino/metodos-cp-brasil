# Integral reading batch report

Generated at: 2026-06-04T18:22:24.543209+00:00

## Counts

- Manifest articles: 10
- Complete classifications: 10
- Reading logs: 10
- Missing classifications: 0
- Failed files: 0

## Missing PIDs

_None._

## Integrity rule

A PID is counted as complete only when both a reading log and a valid classification JSON exist.
The batch runner rejects complete classifications without `full_body_read == true`, without section summaries, or without required schema fields.
