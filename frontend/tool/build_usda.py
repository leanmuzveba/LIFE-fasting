"""Builds assets/foods/usda_sr_legacy.tsv from USDA FoodData Central SR Legacy.

Source (public domain, CC0): https://fdc.nal.usda.gov/download-datasets
  FoodData_Central_sr_legacy_food_csv_2018-04.zip

Usage: python tool/build_usda.py <path to unzipped csv folder>

Columns: fdc_id, name, then per-100 g nutrients (blank = unavailable) in the
order of NUTRIENTS, then portions as "label=grams" joined by "|".
"""
import csv
import os
import sys
from collections import defaultdict

# Order must match Nutrient in lib/domain/food.dart.
NUTRIENTS = [1008, 1003, 1005, 1004, 1079, 1087, 1089, 1092, 1093, 1162]
MAX_PORTIONS = 4

src = sys.argv[1]
out = os.path.join(os.path.dirname(__file__), '..', 'assets', 'foods', 'usda_sr_legacy.tsv')


def rows(name):
    with open(os.path.join(src, name), encoding='utf-8') as f:
        yield from csv.DictReader(f)


def num(v):
    s = f'{float(v):.2f}'.rstrip('0').rstrip('.')
    return s or '0'


units = {r['id']: r['name'] for r in rows('measure_unit.csv')}
wanted = {str(n): i for i, n in enumerate(NUTRIENTS)}
values = defaultdict(lambda: [''] * len(NUTRIENTS))
for r in rows('food_nutrient.csv'):
    i = wanted.get(r['nutrient_id'])
    if i is not None and r['amount'] != '':
        values[r['fdc_id']][i] = num(r['amount'])

portions = defaultdict(list)
for r in rows('food_portion.csv'):
    unit = units.get(r['measure_unit_id'], '')
    parts = [num(r['amount']) if r['amount'] else '1']
    if unit and unit != 'undetermined':
        parts.append(unit)
    if r['modifier']:
        parts.append(r['modifier'])
    label = ' '.join(parts).replace('|', '/').replace('=', '-').replace('\t', ' ')
    if r['gram_weight']:
        portions[r['fdc_id']].append((int(r['seq_num'] or 0), f'{label}={num(r["gram_weight"])}'))

os.makedirs(os.path.dirname(out), exist_ok=True)
count = 0
with open(out, 'w', encoding='utf-8', newline='\n') as f:
    for r in sorted(rows('food.csv'), key=lambda r: r['description'].lower()):
        fid = r['fdc_id']
        ps = '|'.join(p for _, p in sorted(portions[fid])[:MAX_PORTIONS])
        f.write('\t'.join([fid, r['description'].replace('\t', ' '), *values[fid], ps]) + '\n')
        count += 1
print(f'{count} foods -> {os.path.normpath(out)} ({os.path.getsize(out) // 1024} KB)')
