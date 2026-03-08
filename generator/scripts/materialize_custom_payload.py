#!/usr/bin/env python3
import argparse
import base64
import json
import os
from pathlib import Path


def main() -> int:
    parser = argparse.ArgumentParser(description='Materialize rdgen custom payload into custom_.txt')
    parser.add_argument('--payload', default=os.environ.get('custom', ''))
    parser.add_argument('--output', required=True)
    args = parser.parse_args()

    output = Path(args.output)
    output.parent.mkdir(parents=True, exist_ok=True)
    if not args.payload:
        output.write_text('{}', encoding='utf-8')
        print(f'No custom payload provided, wrote empty JSON to {output}.')
        return 0

    decoded = base64.b64decode(args.payload.encode('utf-8')).decode('utf-8')
    # normalize JSON formatting for debugability while preserving data
    parsed = json.loads(decoded)
    output.write_text(json.dumps(parsed, ensure_ascii=False, indent=2), encoding='utf-8')
    print(f'Wrote custom payload to {output}.')
    return 0


if __name__ == '__main__':
    raise SystemExit(main())
