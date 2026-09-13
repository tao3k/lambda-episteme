"""Generate compact native POO catalog from official NODIS source snapshots.
Authoring only: python tools/import-nasa-catalog.py SOURCES_DIRECTORY OUTPUT.ss
Requires BeautifulSoup; neither compilation nor Scheme execution uses Python.
"""
import sys, re, json, hashlib
from pathlib import Path
from bs4 import BeautifulSoup
source, output = map(Path, sys.argv[1:])
q = lambda s: json.dumps(s, ensure_ascii=False)
bodies = {}
for chapter in range(2, 6):
    active = None
    section = None
    for node in BeautifulSoup((source/f'chapter{chapter}.html').read_text(), 'html.parser').find_all(['p','h1','h2','h3','h4']):
        text = node.get_text(' ', strip=True)
        if re.match(r'^\d+\.\d+', text) or node.name.startswith('h'):
            active = None
        ids = re.findall(r'\[SWE-(\d+)\]', text)
        heading = re.match(r'(\d+\.\d+(?:\.\d+)*)\s', text)
        if heading: section = heading[1]
        if ids and ('shall' in text):
            assert len(ids) == 1 and ids[0] not in bodies
            active = dict(section=section, page=f'Chapter{chapter}', parts=[text], notes=[])
            bodies[ids[0]] = active
        elif active and text:
            # Keep normative subparagraphs distinct from explanatory prose.
            if re.match(r'^(?:[a-z]\.|\(\d+\))\s', text): active['parts'].append(text)
            else: active['notes'].append(text)
soup = BeautifulSoup((source/'appendix-c.html').read_text(), 'html.parser')
tables = [t for t in soup.find_all('table') if 'SWE' in t.get_text() and len(t.find_all('tr')) > 30]
assert len(tables) == 1
matrix = {}
for tr in tables[0].find_all('tr'):
    cols = [c.get_text(' ', strip=True) for c in tr.find_all(['td','th'], recursive=False)]
    if len(cols)>1 and re.fullmatch(r'\d{3}',cols[1]):
        assert len(cols)==12 and cols[1] not in matrix
        assert all(cols[i] in ('','X') for i in (4,5,6,7,8,11))
        assert cols[1] in bodies and bodies[cols[1]]['section']==cols[0]
        matrix[cols[1]]=cols
assert len(bodies)==130 and len(matrix)==100
assert {k for k,v in bodies.items() if v['page']!='Chapter2'}==set(matrix)
lines=[';;; Generated from official NODIS HTML; do not hand edit.',
 '(import :poo-flow/src/module-system/contribution/interface)',
 '(export nasa-requirement-catalog nasa-catalog-source-digests)',
 '(def nasa-catalog-source-digests', '  (.o']
for name in ['chapter2','chapter3','chapter4','chapter5','chapter6','appendix-c']:
    lines.append('    '+name+': '+q(hashlib.sha256((source/(name+'.html')).read_bytes()).hexdigest()))
lines += ['  ))', ''';;; One macro expansion for the whole catalog; rows remain ordinary Scheme data.
(def (catalog-row->object row)
  (let* ((id (list-ref row 0)) (section-value (list-ref row 1))
         (page (list-ref row 2)) (excerpt (list-ref row 3))
         (parts (list-ref row 4)) (notes (list-ref row 5))
         (matrix (list-ref row 6))
         (value (.o identity: id standard: "nasa/npr-7150.2d"
                    section: section-value source-url: (string-append
                      "https://nodis3.gsfc.nasa.gov/displayDir.cfm?Internal_ID=N_PR_7150_002D_&page_name=" page)
                    source-excerpt: excerpt source-parts: parts source-notes: notes
                    text-coverage: 'normative-paragraphs
                    assessment: 'not-evaluated modality: 'shall)))
    (let (with-matrix
          (if matrix
            (.o (:: @ value)
                class-matrix: (.o a: (list-ref matrix 0) b: (list-ref matrix 1)
                                 c: (list-ref matrix 2) d: (list-ref matrix 3)
                                 e: (list-ref matrix 4) f: (list-ref matrix 5))
                authority-a-e: (list-ref matrix 6) authority-f: (list-ref matrix 7))
            (.o (:: @ value) applicability: 'requirement-text)))
      (cond ((equal? id "SWE-013") (.o (:: @ with-matrix) topic: 'lifecycle-planning))
            ((equal? id "SWE-034") (.o (:: @ with-matrix) topic: 'acceptance-criteria))
            ((equal? id "SWE-052") (.o (:: @ with-matrix) topic: 'bidirectional-traceability))
            (else with-matrix)))))
(def nasa-requirement-catalog
  (map catalog-row->object
    '(''']
for id, body in bodies.items():
    cols=matrix.get(id)
    m='('+' '.join('invoked' if cols[i]=='X' else 'not-invoked' for i in (4,5,6,7,8,11))+' '+q(cols[3])+' '+q(cols[10])+')' if cols else '#f'
    strings=lambda values:'('+' '.join(map(q,values))+')'
    lines.append('      ('+' '.join([q('SWE-'+id),q(body['section']),q(body['page']),q(cols[2] if cols else body['parts'][0]),strings(body['parts']),strings(body['notes']),m])+')')
lines+=['    )))']
output.write_text('\n'.join(lines)+'\n')
print(f'{len(bodies)} requirements, {sum(len(v["parts"]) for v in bodies.values())} normative paragraphs, {len(matrix)} matrix rows')
