# Generator Callback Protocol Skeleton

This document captures the workflow-side contract expected by the future
`rustdesk-api` generator backend.

## Encrypted secrets payload keys
The workflow skeleton expects the decrypted `secrets.json` payload to provide:

- `job_id`: backend job identifier
- `callback_token`: per-job callback token
- `status_callback_url`: POST callback for status updates
- `artifact_callback_url`: multipart upload callback for generated artifacts
- `platform`: target platform, currently `windows`
- `version`: RustDesk source tag or branch
- `server`
- `key`
- `apiServer`
- `custom`: rdgen-compatible base64-encoded custom payload
- `custom_modules` or `custom_modules_json`: selected module list
- `appname`
- `filename`

## Status callback body
`POST {status_callback_url}` with JSON:

```json
{
  "job_id": "cgj_xxx",
  "callback_token": "...",
  "status": "running",
  "progress": 20,
  "message": "模块清单校验完成",
  "github_run_id": "1234567890",
  "github_run_url": "https://github.com/.../actions/runs/..."
}
```

## Artifact callback body
`POST {artifact_callback_url}` with multipart form-data:

- `job_id`
- `callback_token`
- `platform`
- `filename`
- `sha256`
- `size`
- `file`

## Module resolver outputs
The workflow writes the following env vars after resolving module metadata:

- `GENERATOR_MODULE_KEYS`: comma-separated selected module keys in apply order
- `GENERATOR_MODULES_JSON`: full resolved module metadata JSON

The current skeleton keeps module metadata in `generator/modules/module-index.json`
and intentionally does not patch source files until dedicated patch/script bundles
are extracted from the accepted customization docs.
