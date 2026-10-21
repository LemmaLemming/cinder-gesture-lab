#!/usr/bin/env python3
"""Read final APK/PCK content and record focused publication evidence."""
from pathlib import Path
from datetime import datetime, timezone
import hashlib
import io
import json
import re
import struct
import zipfile

from PIL import Image, ImageChops, ImageStat

ROOT = Path(__file__).resolve().parents[2]
OUT = ROOT / ".cinder/final-publication-20261021/content-verification.json"
APK = ROOT / "exports/publication/Cinder-Android-debug.apk"
IOS = ROOT / "exports/ios"
JSON_PATHS = [
    "data/campaign/act1/a1_l3_difficulty_arrangements.json",
    "data/campaign/act1/a1_o2_difficulty_arrangements.json",
    "data/campaign/act2/a2_l1_difficulty_arrangements.json",
    "data/campaign/act2/a2_l2_difficulty_arrangements.json",
    "data/campaign/act2/a2_o3_difficulty_arrangements.json",
    "data/campaign/act3/a3_l1_encounters.json",
    "data/campaign/act3/a3_l2_encounters.json",
    "data/campaign/act3/a3_l3_difficulty.json",
    "data/campaign/act3/a3_o1_encounters.json",
    "data/campaign/act3/a3_o2_encounters.json",
    "data/campaign/act3/a3_o3_encounters.json",
    "data/campaign/act3/crystalman_layout.json",
    "data/campaign/act3/false_paradise_layout_candidate.json",
    "data/campaign/act3/mirror_sea_layout_candidate.json",
    "data/campaign/registry.json",
    "data/design/difficulty_profiles.json",
    "data/design/player_equipment.json",
]


def digest(data):
    return hashlib.sha256(data).hexdigest()


def read_pck(path):
    data = path.read_bytes()
    magic, version = struct.unpack_from("<II", data)
    assert magic == 0x43504447 and version == 4, (magic, version)
    base, directory = struct.unpack_from("<QQ", data, 24)
    count = struct.unpack_from("<I", data, directory)[0]
    position = directory + 4
    files = {}
    for _ in range(count):
        length = struct.unpack_from("<I", data, position)[0]
        position += 4
        name = data[position:position + length].rstrip(b"\0").decode()
        position += length
        offset, size = struct.unpack_from("<QQ", data, position)
        position += 16
        md5 = data[position:position + 16].hex()
        position += 16
        flags = struct.unpack_from("<I", data, position)[0]
        position += 4
        assert flags == 0 and base + offset + size <= directory, name
        content = data[base + offset:base + offset + size]
        assert hashlib.md5(content).hexdigest() == md5, name
        assert name not in files, name
        files[name] = content
    assert position == len(data), (position, len(data))
    return files, {"bytes": len(data), "sha256": digest(data),
                   "pck_version": version, "entries": count,
                   "all_offsets_and_md5_verified": True}


def check_files(files):
    registry = json.loads((ROOT / "data/campaign/registry.json").read_text())
    levels = []
    for level in registry["levels"]:
        scene = level["scene_path"].removeprefix("res://")
        remap = scene + ".remap"
        assert remap in files, remap
        match = re.search(rb'path="res://([^"]+)"', files[remap])
        assert match, remap
        compiled = match.group(1).decode()
        assert compiled in files and files[compiled], compiled
        levels.append({"id": level["id"], "scene": scene,
                       "compiled_scene": compiled,
                       "compiled_bytes": len(files[compiled])})
    assert len(levels) == 24, len(levels)
    jsons = []
    for name in JSON_PATHS:
        assert name in files, name
        current = (ROOT / name).read_bytes()
        assert files[name] == current, name
        jsons.append({"path": name, "bytes": len(current),
                      "sha256": digest(current), "identical_to_source": True})
    forbidden = [name for name in files if (
        name.startswith(("tests/", "docs/", "scripts/dev/", "scripts/art/",
                         "scripts/design/", "captures/", "exports/"))
        or "/evidence/" in name
        or name in ("data/design/ability_usage.json", "data/design/equipment_claims.json")
        or "codec_exact_reference" in name)]
    generated_icon_extras = [name for name in forbidden if name.startswith(
        "exports/ios/Cinder/Images.xcassets/") and name.endswith((".png", ".json"))]
    if generated_icon_extras:
        catalogue_root = IOS / "Cinder/Images.xcassets/AppIcon.appiconset"
        catalogue = json.loads((catalogue_root / "Contents.json").read_text())
        expected_generated = {
            "exports/ios/Cinder/Images.xcassets/AppIcon.appiconset/" + image["filename"]
            for image in catalogue["images"] if image.get("filename")
        }
        expected_generated.update({
            "exports/ios/Cinder/Images.xcassets/AppIcon.appiconset/Contents.json",
            "exports/ios/Cinder/Images.xcassets/SplashImage.imageset/Contents.json",
            "exports/ios/Cinder/Images.xcassets/SplashImage.imageset/splash@2x.png",
            "exports/ios/Cinder/Images.xcassets/SplashImage.imageset/splash@3x.png",
        })
        assert len(expected_generated) == 20
        assert set(generated_icon_extras) == expected_generated
        for name in generated_icon_extras:
            exported_file = IOS / name.removeprefix("exports/ios/")
            # Godot retains excluded generated assets as empty named placeholders.
            # Their MD5/offsets were verified by read_pck; no asset data is packed.
            assert files[name] == b"", name
            source_asset = exported_file.read_bytes()
            if name.endswith(".json"):
                metadata = json.loads(source_asset)
                assert set(metadata) == {"images", "info"}, name
            else:
                with Image.open(io.BytesIO(source_asset)) as image:
                    assert image.format == "PNG", name
                    image.verify()
    forbidden = [name for name in forbidden if name not in generated_icon_extras]
    nested = [name for name in files if name.startswith((
        "Cinder/", "Cinder.xcodeproj/", "Cinder.xcframework/", "MoltenVK.xcframework/",
        "libgodot_camera.", "exports/"))]
    icon = "assets/ui/app_icon/cinder_test_icon.png"
    assert icon in files and files[icon] == (ROOT / icon).read_bytes(), icon
    return {"registered_levels": levels, "all_24_registered_level_scenes_present": True,
            "runtime_json_files": jsons, "all_17_runtime_json_files_identical": True,
            "excluded_tests_evidence_authoring_ledgers_and_untracked_codec": not forbidden,
            "all_exclusion_checks_passed": not forbidden,
            "forbidden_entries": forbidden, "nested_generated_export_entries": nested,
            "nested_generated_export_entry_details": [{"path": name, "bytes": len(files[name]),
                "sha256": digest(files[name])} for name in nested],
            "generated_public_icon_extras_status": "Accepted packaging warning; exactly20 empty named placeholders for public icon/splash assets; zero content bytes" if generated_icon_extras else "None",
            "shared_icon_source_present_and_identical": True}


source_icon = Image.open(ROOT / "assets/ui/app_icon/cinder_test_icon.png").convert("RGB")


def icon_check(content, path):
    original = Image.open(io.BytesIO(content))
    image = original.convert("RGB")
    expected = source_icon.resize(image.size, Image.Resampling.LANCZOS)
    error = sum(ImageStat.Stat(ImageChops.difference(image, expected)).mean) / 3
    assert error < 0.1, (path, error)
    return {"path": path, "width": image.width, "height": image.height,
            "mode": original.mode, "mean_absolute_error_to_resized_shared_icon": round(error, 6),
            "shared_custom_icon_verified": True}


report = {"timestamp_utc": datetime.now(timezone.utc).isoformat(),
          "scope": "Focused distribution content checks; no physical device launch or full playthrough performed",
          "source_baseline": "2e64b75b0f7c94c63ce40f1073d1e436f28d2c93 with final mobile working changes"}
with zipfile.ZipFile(APK) as apk:
    assert apk.testzip() is None
    entries = apk.namelist()
    assert len(entries) == len(set(entries))
    assets = {name.removeprefix("assets/"): apk.read(name) for name in entries
              if name.startswith("assets/") and not name.endswith("/")}
    android_icons = [icon_check(apk.read(name), name) for name in entries
                     if name.startswith("res/mipmap") and name.endswith("/icon.webp")]
    assert len(android_icons) == 6, len(android_icons)
    report["android"] = {"path": str(APK.relative_to(ROOT)), "bytes": APK.stat().st_size,
                         "sha256": digest(APK.read_bytes()), "zip_entries": len(entries),
                         "all_zip_crc_verified": True, "duplicate_zip_paths": [],
                         "content": check_files(assets), "launcher_icons": android_icons}
ios_files, ios_pack = read_pck(IOS / "Cinder.pck")
catalogue = IOS / "Cinder/Images.xcassets/AppIcon.appiconset"
ios_icons = []
for item in json.loads((catalogue / "Contents.json").read_text())["images"]:
    name = item.get("filename")
    if not name:
        continue
    path = catalogue / name
    content = path.read_bytes()
    check = icon_check(content, str(path.relative_to(IOS)))
    assert check["mode"] == "RGB", check
    size = float(item["size"].split("x")[0]) * float(item.get("scale", "1x").removesuffix("x"))
    assert check["width"] == check["height"] == int(size), check
    ios_icons.append(check)
assert len(ios_icons) == 16, len(ios_icons)
report["ios"] = {"path": str((IOS / "Cinder.pck").relative_to(ROOT)), "pack": ios_pack,
                 "content": check_files(ios_files), "opaque_correctly_sized_app_icons": ios_icons}
nested = {platform: report[platform]["content"]["nested_generated_export_entries"]
          for platform in ("android", "ios")}
report["warnings"] = {"nested_generated_export_entries": nested} if any(nested.values()) else {}
report["status"] = ("FAIL" if any(report[p]["content"]["forbidden_entries"]
                                for p in ("android", "ios"))
                    else "PASS_WITH_WARNINGS" if report["warnings"] else "PASS")
OUT.write_text(json.dumps(report, indent=2) + "\n")
print(json.dumps({"status": report["status"], "android_bytes": report["android"]["bytes"],
                  "android_sha256": report["android"]["sha256"],
                  "ios_pck_bytes": ios_pack["bytes"], "ios_pck_sha256": ios_pack["sha256"],
                  "all_24_levels_and_17_jsons_in_both": True,
                  "nested_generated_export_entry_counts": {k: len(v) for k, v in nested.items()}}))
