# -*- coding: utf-8 -*-
"""ROB RUN 汉化打包（v2）
用法: python build_pack.py <译文CSV> <输出目录> <官方bundle目录> <字库inbuild> <locales bundle>
说明: 把译文写入 6 个语言 StringTable；字库与 locales 用显式传入的成品文件（不再读死路径）。
"""
import csv, os, shutil, sys
import UnityPy

if len(sys.argv) < 6:
    sys.exit("usage: build_pack.py <csv> <out_dir> <official_bundle_dir> <font_inbuild> <locales_bundle>")

patch_file, out_dir, src_dir, font_inbuild, locales_bundle = sys.argv[1:6]
os.makedirs(out_dir, exist_ok=True)

patch = {}
with open(patch_file, encoding="utf-8-sig", newline="") as f:
    for r in csv.DictReader(f):
        patch[int(r["id"])] = r["zh"]
print("patch entries:", len(patch))

bundles = [
    "localization-string-tables-english(unitedstates)(en-us)_assets_all.bundle",
    "localization-string-tables-french(fr)_assets_all.bundle",
    "localization-string-tables-german(de)_assets_all.bundle",
    "localization-string-tables-portuguese(pt)_assets_all.bundle",
    "localization-string-tables-russian(russia)(ru-ru)_assets_all.bundle",
    "localization-string-tables-spanish(es)_assets_all.bundle",
]

total_rows = 0
for b in bundles:
    src = os.path.join(src_dir, b)
    if not os.path.exists(src):
        sys.exit("missing official bundle: " + src)
    env = UnityPy.load(src)
    n = 0
    rows = 0
    for obj in env.objects:
        if obj.type.name != "MonoBehaviour":
            continue
        t = obj.read_typetree()
        if "m_TableData" not in t:
            continue
        for item in t["m_TableData"]:
            rows += 1
            v = patch.get(int(item["m_Id"]))
            if v is not None:
                item["m_Localized"] = v.replace("\\n", "\n")
                n += 1
        obj.save_typetree(t)
    out = os.path.join(out_dir, b)
    with open(out, "wb") as f:
        f.write(env.file.save(packer="lz4"))
    total_rows += rows
    print("built %-58s rows=%d patched=%d size=%d" % (b[:58], rows, n, os.path.getsize(out)))

for name, srcfile in [("inbuild_assets_all.bundle", font_inbuild),
                      ("localization-locales_assets_all.bundle", locales_bundle)]:
    dst = os.path.join(out_dir, name)
    if not os.path.exists(srcfile):
        sys.exit("missing asset: " + srcfile)
    shutil.copy2(srcfile, dst)
    print("copied %-42s %d" % (name, os.path.getsize(dst)))

print("done ->", out_dir, "rows_total=", total_rows)
