# Generator Skeleton

This directory contains the workflow skeleton and module metadata for the
RustDesk client generator that will be orchestrated by `rustdesk-api`.

## Included now
- `modules/module-index.json`: source-of-truth module metadata consumed by the workflow.
- `scripts/decrypt_generator_secrets.py`: decrypts the encrypted zip payload and exports env vars.
- `scripts/resolve_generator_modules.py`: validates selected module keys against metadata.
- `scripts/report_job_status.py`: posts generator status updates back to `rustdesk-api`.
- `scripts/upload_artifact_callback.py`: uploads generated artifacts back to `rustdesk-api`.

## Important note
This is intentionally a workflow skeleton. It defines the protocol, metadata,
and callback shape without mutating current checked-in `src/` or `flutter/`
source files in this working tree.

The accepted client customizations are represented as module metadata only for
now. Before the generator is production-ready, each module still needs an
idempotent patch/script bundle extracted from the accepted implementation docs.
