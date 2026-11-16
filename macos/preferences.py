#!/usr/bin/env python3
"""Merge allowlisted preferences through defaults, preserving unrelated settings."""
import argparse
import base64
import json
import plistlib
import subprocess


def merge_preferences(current, selected):
    """Return a merged domain and the names of settings whose values differ."""
    desired = {
        key: base64.b64decode(value['data'])
        if isinstance(value, dict) and set(value) == {'data'} else value
        for key, value in selected.items()
    }
    changed = [key for key, value in desired.items() if current.get(key) != value]
    return {**current, **desired}, changed


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--payload', required=True)
    mode = parser.add_mutually_exclusive_group()
    mode.add_argument('--check', action='store_true')
    mode.add_argument('--capture', action='store_true')
    args = parser.parse_args()
    desired = json.loads(base64.b64decode(args.payload))
    changes = {}
    captured = {}
    for domain, selected in desired.items():
        result = subprocess.run(['/usr/bin/defaults', 'export', domain, '-'], capture_output=True)
        current = plistlib.loads(result.stdout) if result.returncode == 0 else {}
        if args.capture:
            captured[domain] = {
                key: {'data': base64.b64encode(current[key]).decode()}
                if isinstance(current[key], bytes) else current[key]
                for key in selected if key in current
            }
            continue
        merged, keys = merge_preferences(current, selected)
        if keys:
            changes[domain] = keys
            if not args.check:
                subprocess.run(
                    ['/usr/bin/defaults', 'import', domain, '-'],
                    input=plistlib.dumps(merged), check=True, stdout=subprocess.DEVNULL,
                )
    print(json.dumps(captured if args.capture else {'changed': bool(changes), 'keys': changes}))


if __name__ == '__main__':
    main()
