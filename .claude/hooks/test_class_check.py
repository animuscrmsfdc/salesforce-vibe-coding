import sys
import json
import os
import re

try:
    d = json.load(sys.stdin)
except Exception:
    sys.exit(0)

f = d.get('tool_input', {}).get('file_path', '')
if not f or '/force-app/main/default/classes/' not in f:
    sys.exit(0)

b = os.path.basename(f)
if not b.endswith('.cls') or b.endswith('-meta.xml'):
    sys.exit(0)

n = b.removesuffix('.cls')
if re.search(r'(Test|_test|_Test)$', n) or n.startswith('Test'):
    sys.exit(0)

classes_dir = os.path.dirname(f)
candidates = [n + 'Test.cls', n + '_Test.cls', n + '_test.cls']

if any(os.path.exists(os.path.join(classes_dir, c)) for c in candidates):
    sys.exit(0)

print('[TEST] WARNING: No test class found for ' + b)
print('[TEST]   Expected one of: ' + ', '.join(candidates))
