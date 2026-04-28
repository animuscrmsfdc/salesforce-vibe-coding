import sys
import json
import os
import re

try:
    d = json.load(sys.stdin)
except Exception:
    sys.exit(0)

f = d.get('tool_input', {}).get('file_path', '')
if not f or '/force-app/main/default/' not in f:
    sys.exit(0)

rel = f.split('/force-app/main/default/')[-1]
p = rel.split('/')

mt = None
mb = None

if p[0] == 'classes' and p[-1].endswith('.cls') and not p[-1].endswith('-meta.xml'):
    mt = 'ApexClass'
    mb = p[-1].removesuffix('.cls')
elif p[0] == 'triggers' and p[-1].endswith('.trigger'):
    mt = 'ApexTrigger'
    mb = p[-1].removesuffix('.trigger')
elif p[0] == 'objects' and len(p) == 2 and p[-1].endswith('.object-meta.xml'):
    mt = 'CustomObject'
    mb = p[-1].removesuffix('.object-meta.xml')
elif p[0] == 'objects' and len(p) == 4 and p[2] == 'fields' and p[-1].endswith('.field-meta.xml'):
    mt = 'CustomField'
    mb = p[1] + '.' + p[-1].removesuffix('.field-meta.xml')
elif p[0] == 'lwc' and len(p) >= 2:
    mt = 'LightningComponentBundle'
    mb = p[1]
elif p[0] == 'permissionsets' and p[-1].endswith('.permissionset-meta.xml'):
    mt = 'PermissionSet'
    mb = p[-1].removesuffix('.permissionset-meta.xml')
elif p[0] == 'validationRules' and p[-1].endswith('.validationRule-meta.xml'):
    mt = 'ValidationRule'
    mb = p[-1].removesuffix('.validationRule-meta.xml')

if not mt:
    sys.exit(0)

pkg = '/Users/david.sanchezcarmona/animuscrm/manifest/package.xml'
try:
    c = open(pkg).read()
except Exception:
    sys.exit(0)

if not re.search(r'<name>' + re.escape(mt) + r'</name>', c):
    print('[PKG] WARNING: ' + mt + ' has no <types> block in package.xml')
    sys.exit(0)

if re.search(r'<members>\*</members>\s*<name>' + re.escape(mt) + r'</name>', c):
    sys.exit(0)

if not re.search(r'<members>' + re.escape(mb) + r'</members>', c):
    print('[PKG] WARNING: ' + mt + '/' + mb + ' missing from package.xml')
    print('[PKG]   Add: <members>' + mb + '</members> under <name>' + mt + '</name>')
