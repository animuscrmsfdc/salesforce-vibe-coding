import sys
import json
import subprocess
import os

try:
    d = json.load(sys.stdin)
except Exception:
    sys.exit(0)

f = d.get('tool_input', {}).get('file_path', '')
if not f or not (f.endswith('.cls') or f.endswith('.trigger')):
    sys.exit(0)
if '/force-app/' not in f:
    sys.exit(0)
if subprocess.run(['which', 'sf'], capture_output=True).returncode != 0:
    sys.exit(0)

ruleset = '/Users/david.sanchezcarmona/animuscrm/pmd-ruleset.xml'
try:
    r = subprocess.run(
        ['sf', 'scanner', 'run', '--engine', 'pmd',
         '--target', f, '--pmdconfig', ruleset, '--format', 'table'],
        capture_output=True, text=True, timeout=13
    )
except Exception:
    sys.exit(0)

if r.stdout.strip():
    print('[PMD] Violations in ' + os.path.basename(f) + ':')
    print(r.stdout)
else:
    print('[PMD] No violations in ' + os.path.basename(f))
