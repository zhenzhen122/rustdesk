#!/usr/bin/env python3
import argparse
import json
import os
import sys
from pathlib import Path
from urllib import request, error

if hasattr(sys.stdout, 'reconfigure'):
    sys.stdout.reconfigure(encoding='utf-8', errors='replace')
if hasattr(sys.stderr, 'reconfigure'):
    sys.stderr.reconfigure(encoding='utf-8', errors='replace')


def main() -> int:
    parser = argparse.ArgumentParser(description='Report generator job status back to rustdesk-api.')
    parser.add_argument('--url', default=os.environ.get('status_callback_url', ''))
    parser.add_argument('--job-id', default=os.environ.get('job_id', os.environ.get('task_uuid', '')))
    parser.add_argument('--token', default=os.environ.get('callback_token', ''))
    parser.add_argument('--status', required=True)
    parser.add_argument('--progress', type=int, default=-1)
    parser.add_argument('--stage', default='')
    parser.add_argument('--message', default='')
    parser.add_argument('--github-run-id', default=os.environ.get('GITHUB_RUN_ID', ''))
    parser.add_argument('--github-run-url', default='')
    parser.add_argument('--soft-fail', action='store_true')
    args = parser.parse_args()

    if not args.url:
        print('status callback url is empty, skip report')
        return 0

    run_url = args.github_run_url or (
        f"https://github.com/{os.environ.get('GITHUB_REPOSITORY', '')}/actions/runs/{os.environ.get('GITHUB_RUN_ID', '')}"
        if os.environ.get('GITHUB_REPOSITORY') and os.environ.get('GITHUB_RUN_ID') else ''
    )
    payload = {
        'job_id': args.job_id,
        'callback_token': args.token,
        'status': args.status,
        'message': args.message,
        'github_run_id': args.github_run_id,
        'github_run_url': run_url,
    }
    if args.progress >= 0:
        payload['progress'] = args.progress
    if args.stage:
        payload['stage'] = args.stage

    data = json.dumps(payload, ensure_ascii=False).encode('utf-8')
    req = request.Request(args.url, data=data, method='POST')
    req.add_header('Content-Type', 'application/json')
    try:
        with request.urlopen(req, timeout=30) as resp:
            body = resp.read().decode('utf-8', errors='ignore')
            print(f'status callback ok: {resp.status} {body}')
            return 0
    except Exception as exc:  # pragma: no cover
        print(f'status callback failed: {exc}', file=sys.stderr)
        return 0 if args.soft_fail else 1


if __name__ == '__main__':
    raise SystemExit(main())
