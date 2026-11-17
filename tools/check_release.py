# -*- coding: utf-8 -*-
"""出包前守门校验。任一项失败 -> 退出码 1，禁止出包。
用法: python check_release.py <译文CSV> <官方表CSV> <字体inbuild> <out_pack_dir>
"""
import csv, os, re, sys, collections
import UnityPy

if len(sys.argv) < 5:
    sys.exit("usage: check_release.py <dict.csv> <official.csv> <font_inbuild> <pack_dir>")
dict_csv, off_csv, font_bundle, pack_dir = sys.argv[1:5]
fails = []
warns = []

def load_dict(p):
    d = {}
    with open(p, encoding="utf-8-sig", newline="") as f:
        for r in csv.DictReader(f):
            d[r["id"].strip()] = r.get("zh", "")
    return d

off = {}
with open(off_csv, encoding="utf-8-sig", newline="") as f:
    for r in csv.DictReader(f):
        off[r["id"].strip()] = (r["table"], r["en"])
d = load_dict(dict_csv)
print("dict:", len(d), "official:", len(off))

# 1. 覆盖
missing = [i for i in off if i not in d]
extra = [i for i in d if i not in off]
if missing: fails.append("缺少 %d 条官方词条: %s" % (len(missing), missing[:5]))
if extra: warns.append("多出 %d 条非官方 ID: %s" % (len(extra), extra[:5]))

# 2. 占位符
NUM = re.compile(r"\{(\d+)")
def args(s): return sorted(set(int(m) for m in NUM.findall(s)))
bad_args = []
bad_plural = []
for i, zh in d.items():
    if i not in off: continue
    en = off[i][1]
    ea, za = args(en), args(zh)
    if any(x > (max(ea) if ea else -1) for x in za): bad_args.append(i)
    if en.count(":plural") != zh.count(":plural"): bad_plural.append(i)
if bad_args: fails.append("参数越界 %d 条: %s" % (len(bad_args), bad_args[:5]))
if bad_plural: fails.append("plural 段数不一致 %d 条: %s" % (len(bad_plural), bad_plural[:5]))

# 3. 富文本标签数量
TAG = re.compile(r"<[^>]+>")
# 规则：译文必须包含原文的全部标签（多重集包含），允许额外高亮。
# 注：{n:cond:...|...} 与 {n:...|...} 分支写法本身开闭不成对，因此不做开闭平衡检查。
bad_tag = []
extra_tag = []
for i, zh in d.items():
    if i not in off: continue
    en_c, zh_c = collections.Counter(TAG.findall(off[i][1])), collections.Counter(TAG.findall(zh))
    if en_c - zh_c:
        bad_tag.append(i)
    elif zh_c - en_c:
        extra_tag.append(i)
if bad_tag: fails.append("富文本标签缺失/不平衡 %d 条: %s" % (len(bad_tag), bad_tag[:8]))
if extra_tag: warns.append("额外高亮 %d 条（无副作用）: %s" % (len(extra_tag), extra_tag[:8]))

# 4. 批注残留
NOTE = re.compile(r"(句意|^翻译[:：]|待译|TODO|备注[:：])", re.M)
bad_note = [i for i, zh in d.items() if NOTE.search(zh)]
if bad_note: fails.append("批注残留 %d 条: %s" % (len(bad_note), bad_note[:5]))

# 5. 缺字
chars = set()
for zh in d.values():
    chars |= {c for c in zh if "\u4e00" <= c <= "\u9fff"}
env = UnityPy.load(font_bundle)
font_chars = set()
for obj in env.objects:
    if obj.type.name != "MonoBehaviour": continue
    t = obj.read_typetree()
    if t.get("m_Name") != "TT_Bluescreens SDF": continue
    font_chars = {chr(c["m_Unicode"]) for c in t["m_CharacterTable"]}
    break
miss_glyph = sorted(chars - font_chars)
if miss_glyph: fails.append("字库缺 %d 字: %s" % (len(miss_glyph), "".join(miss_glyph[:20])))
print("CJK chars in dict: %d, font covers: %d" % (len(chars), len(font_chars)))

# 6. 包内行数
if os.path.isdir(pack_dir):
    en_b = os.path.join(pack_dir, "localization-string-tables-english(unitedstates)(en-us)_assets_all.bundle")
    if os.path.exists(en_b):
        env2 = UnityPy.load(en_b)
        rows = 0
        for obj in env2.objects:
            if obj.type.name != "MonoBehaviour": continue
            t = obj.read_typetree()
            if "m_TableData" in t: rows += len(t["m_TableData"])
        if rows != len(off):
            fails.append("包内行数 %d != 官方 %d" % (rows, len(off)))
        else:
            print("pack rows:", rows, "== official")
    else:
        warns.append("pack 目录里没有英文语言表，跳过行数校验")

print()
for w in warns: print("[WARN]", w)
for f_ in fails: print("[FAIL]", f_)
if fails:
    print("RESULT: FAIL")
    sys.exit(1)
print("RESULT: PASS")
