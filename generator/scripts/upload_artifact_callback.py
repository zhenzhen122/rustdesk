#!/usr/bin/env python3
import argparse
import hashlib
import mimetypes
import os
import sys
from pathlib import Path
from urllib import error, request

if hasattr(sys.stdout, 'reconfigure'):
    sys.stdout.reconfigure(encoding='utf-8', errors='replace')
if hasattr(sys.stderr, 'reconfigure'):
    sys.stderr.reconfigure(encoding='utf-8', errors='replace')

BOUNDARY = '----RustDeskClientGeneratorBoundary7MA4YWxkTrZu0gW'


def multipart_body(fields: list[tuple[str, str]], files: list[tuple[str, Path]]) -> bytes:
    lines: list[bytes] = []
    for key, value in fields:
        lines.extend([
            f'--{BOUNDARY}'.encode(),
            f'Content-Disposition: form-data; name="{key}"'.encode(),
            b'',
            value.encode('utf-8'),
        ])
    for key, file_path in files:
        mime_type = mimetypes.guess_type(file_path.name)[0] or 'application/octet-stream'
        lines.extend([
            f'--{BOUNDARY}'.encode(),
            f'Content-Disposition: form-data; name="{key}"; filename="{file_path.name}"'.encode(),
            f'Content-Type: {mime_type}'.encode(),
            b'',
            file_path.read_bytes(),
        ])
    lines.append(f'--{BOUNDARY}--'.encode())
    lines.append(b'')
    return b'\r\n'.join(lines)


def sha256sum(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open('rb') as handle:
        for chunk in iter(lambda: handle.read(1024 * 1024), b''):
            digest.update(chunk)
    return digest.hexdigest()


def main() -> int:
    parser = argparse.ArgumentParser(description='Upload generated artifact back to rustdesk-api callback endpoint.')
    parser.add_argument('--url', default=os.environ.get('artifact_callback_url', ''))
    parser.add_argument('--job-id', default=os.environ.get('job_id', os.environ.get('task_uuid', '')))
    parser.add_argument('--token', default=os.environ.get('callback_token', ''))
    parser.add_argument('--platform', default=os.environ.get('platform', 'windows'))
    parser.add_argument('--file', required=True)
    parser.add_argument('--display-label', default='')
    parser.add_argument('--soft-fail', action='store_true')
    args = parser.parse_args()

    if not args.url:
        print('artifact callback url is empty, skip upload')
        return 0

    file_path = Path(args.file)
    if not file_path.exists():
        raise SystemExit(f'artifact file not found: {file_path}')

    fields = [
        ('job_id', args.job_id),
        ('callback_token', args.token),
        ('platform', args.platform),
        ('filename', file_path.name),
        ('sha256', sha256sum(file_path)),
        ('size', str(file_path.stat().st_size)),
    ]
    if args.display_label:
        fields.append(('display_label', args.display_label))
    body = multipart_body(fields, [('file', file_path)])
    req = request.Request(args.url, data=body, method='POST')
    req.add_header('Content-Type', f'multipart/form-data; boundary={BOUNDARY}')
    try:
        with request.urlopen(req, timeout=120) as resp:
            print(f'artifact callback ok: {resp.status}')
            return 0
    except Exception as exc:  # pragma: no cover
        print(f'artifact callback failed: {exc}', file=sys.stderr)
        return 0 if args.soft_fail else 1


if __name__ == '__main__':
    raise SystemExit(main())
