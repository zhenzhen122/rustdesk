#!/usr/bin/env python3
import argparse
import json
import os
import sys
from pathlib import Path

try:
    import pyzipper
except ImportError as exc:  # pragma: no cover
    raise SystemExit(f"pyzipper is required: {exc}")

if hasattr(sys.stdout, 'reconfigure'):
    sys.stdout.reconfigure(encoding='utf-8', errors='replace')
if hasattr(sys.stderr, 'reconfigure'):
    sys.stderr.reconfigure(encoding='utf-8', errors='replace')


def append_env(name: str, value: str) -> None:
    env_path = os.environ.get('GITHUB_ENV')
    if not env_path:
        return
    with open(env_path, 'a', encoding='utf-8') as handle:
        handle.write(f"{name}={value}\n")


def mask(value: str) -> None:
    if value:
        print(f"::add-mask::{value}")


def main() -> int:
    parser = argparse.ArgumentParser(description='Decrypt generator secrets zip and export env vars.')
    parser.add_argument('--zip-path', default='secrets.zip')
    parser.add_argument('--password', default=os.environ.get('ZIP_PASSWORD', ''))
    parser.add_argument('--inner-file', default='secrets.json')
    parser.add_argument('--dump-json-path', default='')
    args = parser.parse_args()

    if not args.password:
        raise SystemExit('ZIP password is required')

    zip_path = Path(args.zip_path)
    if not zip_path.exists():
        raise SystemExit(f'Secrets zip not found: {zip_path}')

    with pyzipper.AESZipFile(zip_path) as archive:
        archive.setpassword(args.password.encode('utf-8'))
        with archive.open(args.inner_file) as inner:
            payload = json.load(inner)

    if args.dump_json_path:
        dump_path = Path(args.dump_json_path)
        dump_path.parent.mkdir(parents=True, exist_ok=True)
        dump_path.write_text(json.dumps(payload, ensure_ascii=False, indent=2), encoding='utf-8')

    exported = 0
    for key, value in payload.items():
        if value is None:
            continue
        if isinstance(value, (dict, list)):
            value = json.dumps(value, ensure_ascii=False, separators=(',', ':'))
        else:
            value = str(value)
        mask(value)
        append_env(key, value)
        exported += 1

    print(f'Successfully decrypted and exported {exported} generator values from {zip_path}.')
    return 0


if __name__ == '__main__':
    raise SystemExit(main())
