#!/usr/bin/env python3
import argparse
import json
import os
from pathlib import Path


def append_env(name: str, value: str) -> None:
    env_path = os.environ.get('GITHUB_ENV')
    if not env_path:
        return
    with open(env_path, 'a', encoding='utf-8') as handle:
        handle.write(f"{name}={value}\n")


def load_modules(index_path: Path) -> dict:
    if not index_path.exists():
        raise SystemExit(f'Module index not found: {index_path}')
    return json.loads(index_path.read_text(encoding='utf-8'))


def parse_selected(raw: str) -> list[str]:
    if not raw:
        return []
    raw = raw.strip()
    if raw.startswith('['):
        return [str(x).strip() for x in json.loads(raw) if str(x).strip()]
    return [item.strip() for item in raw.split(',') if item.strip()]


def topo_sort(modules: dict[str, dict], selected: list[str]) -> list[str]:
    ordered: list[str] = []
    seen: set[str] = set()

    def visit(key: str) -> None:
        if key in seen:
            return
        seen.add(key)
        for dep in modules[key].get('dependencies', []):
            if dep in selected:
                visit(dep)
        ordered.append(key)

    for key in selected:
        visit(key)
    return ordered


def main() -> int:
    parser = argparse.ArgumentParser(description='Resolve client generator module metadata.')
    parser.add_argument('--index', default='generator/modules/module-index.json')
    parser.add_argument('--selected', default=os.environ.get('custom_modules_json', os.environ.get('custom_modules', '[]')))
    parser.add_argument('--platform', default=os.environ.get('platform', 'windows'))
    parser.add_argument('--strict', action='store_true')
    parser.add_argument('--output', default='')
    args = parser.parse_args()

    metadata = load_modules(Path(args.index))
    module_map = {item['module_key']: item for item in metadata.get('modules', [])}
    selected = parse_selected(args.selected)

    unknown = [key for key in selected if key not in module_map]
    if unknown:
        raise SystemExit(f'Unknown generator modules: {unknown}')

    for key in selected:
        item = module_map[key]
        if args.platform not in item.get('platforms', []):
            raise SystemExit(f'Module {key} is not supported on platform {args.platform}')
        for conflict in item.get('conflicts', []):
            if conflict in selected:
                raise SystemExit(f'Module {key} conflicts with {conflict}')
        for dep in item.get('dependencies', []):
            if dep not in selected:
                raise SystemExit(f'Module {key} requires dependency {dep}')
        if args.strict and item.get('implementation_status') != 'ready':
            raise SystemExit(f'Module {key} is not ready for strict mode')

    ordered = topo_sort(module_map, selected)
    resolved = {
        'platform': args.platform,
        'selected': ordered,
        'modules': [module_map[key] for key in ordered],
        'strict': args.strict,
    }
    resolved_json = json.dumps(resolved, ensure_ascii=False, separators=(',', ':'))
    append_env('GENERATOR_MODULES_JSON', resolved_json)
    append_env('GENERATOR_MODULE_KEYS', ','.join(ordered))
    if args.output:
        Path(args.output).write_text(json.dumps(resolved, ensure_ascii=False, indent=2), encoding='utf-8')
    if ordered:
        print(f'Resolved generator modules: {ordered}')
    else:
        print('No custom generator modules selected.')
    return 0


if __name__ == '__main__':
    raise SystemExit(main())
