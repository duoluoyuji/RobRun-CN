import csv, os, shutil, sys
import UnityPy
ROOT = r"F:\RobRun_汉化接手"
SRC = r"E:\SteamLibrary\steamapps\common\Rob Run\ROB RUN_Data\StreamingAssets\aa\StandaloneWindows64"
FONT_SRC = os.path.join(ROOT, "04_交付", "files")
LOCALES_SRC = os.path.join(ROOT, "04_交付", "files", "localization-locales_assets_all.bundle")

patch_file = sys.argv[1]
out_dir = sys.argv[2]
os.makedirs(out_dir, exist_ok=True)
patch = {int(r["id"]): r["zh"] for r in csv.DictReader(open(patch_file, encoding="utf-8-sig"))}
print("patch", len(patch))

bundles = [
    "localization-string-tables-english(unitedstates)(en-us)_assets_all.bundle",
    "localization-string-tables-french(fr)_assets_all.bundle",
    "localization-string-tables-german(de)_assets_all.bundle",
    "localization-string-tables-portuguese(pt)_assets_all.bundle",
    "localization-string-tables-russian(russia)(ru-ru)_assets_all.bundle",
    "localization-string-tables-spanish(es)_assets_all.bundle",
]
for b in bundles:
    env = UnityPy.load(os.path.join(SRC, b))
    n = 0
    for obj in env.objects:
        if obj.type.name != "MonoBehaviour": continue
        t = obj.read_typetree()
        if "m_TableData" not in t: continue
        for item in t["m_TableData"]:
            v = patch.get(int(item["m_Id"]))
            if v is not None:
                item["m_Localized"] = v; n += 1
        obj.save_typetree(t)
    with open(os.path.join(out_dir, b), "wb") as f:
        f.write(env.file.save(packer="lz4"))
    print("built", b[:46], n)

for extra in ("inbuild_assets_all.bundle", "localization-locales_assets_all.bundle"):
    target = os.path.join(out_dir, extra)
    if os.path.exists(target):
        print("preserving existing", extra)
        continue
    src = os.path.join(FONT_SRC, extra)
    if os.path.exists(src):
        shutil.copy2(src, target)
print("done ->", out_dir)
