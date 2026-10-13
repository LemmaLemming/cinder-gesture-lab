"""Original C30 pixel shapes. No reference image pixels are sampled or copied.

Run with the project's available Python/Pillow: python3 build_rusher_cutouts.py
Writes twelve 48x80 frames, the review contact sheet and rusher_manifest.json
in this directory only. RUSHER_ART_NOTES.md is a separately authored record.
"""
from hashlib import sha256
import json
import math
from pathlib import Path

from PIL import Image, ImageDraw, ImageFont

OUT = Path(__file__).resolve().parent
ROOT = OUT.parents[3]
SIZE = (48, 80)
PIVOT = (24, 80)
PIXEL_SIZE = 0.022  # Tentative; owner must inspect the actual portrait binding.
PAL = {
    "ink": (20, 20, 20, 255), "coal": (39, 39, 39, 255),
    "shade": (67, 67, 67, 255), "mid": (105, 105, 105, 255),
    "silver": (147, 147, 147, 255), "light": (193, 193, 193, 255),
    "white": (231, 231, 231, 255),
}
FACINGS = ("front", "side", "back")
POSES = ("standing", "crouch", "rush", "recovery")
PHASES = {
    "standing": ["idle"], "crouch": ["warning", "lock"],
    "rush": ["active"], "recovery": ["recovery"],
}
READINESS = "produced_pixels_not_bound_or_portrait_validated"

# Joint locations and widths are hand-authored for every facing/pose. The two
# toes stay on row79; the shared bottom-centre pivot never follows the costume.
FRONT = {
    "standing": {"head": (24, 25), "chest": (24, 41), "hip": (24, 58),
                 "arms": [((15, 41), (11, 51), (12, 62)), ((33, 41), (37, 51), (36, 62))],
                 "legs": [((20, 59), (18, 68), (17, 76)), ((28, 59), (30, 68), (31, 76))]},
    "crouch": {"head": (24, 38), "chest": (24, 50), "hip": (25, 62),
               "arms": [((15, 49), (10, 57), (17, 53)), ((33, 49), (38, 57), (31, 53))],
               "legs": [((20, 62), (12, 68), (17, 76)), ((29, 62), (36, 68), (31, 76))]},
    "rush": {"head": (23, 29), "chest": (24, 43), "hip": (26, 59),
             "arms": [((15, 42), (10, 48), (11, 39)), ((33, 42), (38, 49), (37, 39))],
             "legs": [((21, 59), (17, 67), (12, 76)), ((30, 59), (32, 67), (35, 76))]},
    "recovery": {"head": (27, 28), "chest": (26, 43), "hip": (24, 59),
                 "arms": [((17, 42), (11, 47), (7, 57)), ((35, 43), (39, 53), (43, 48))],
                 "legs": [((20, 59), (17, 68), (13, 76)), ((28, 59), (32, 68), (34, 76))]},
}
SIDE = {
    "standing": {"head": (25, 25), "chest": (24, 41), "hip": (24, 58),
                 "arms": [((22, 41), (20, 52), (21, 61)), ((27, 41), (30, 51), (30, 61))],
                 "legs": [((21, 59), (19, 68), (18, 76)), ((26, 59), (29, 68), (29, 76))]},
    "crouch": {"head": (27, 38), "chest": (23, 50), "hip": (19, 62),
               "arms": [((20, 50), (13, 57), (13, 63)), ((27, 49), (34, 51), (39, 45))],
               "legs": [((18, 62), (12, 69), (14, 76)), ((23, 62), (32, 66), (30, 76))]},
    "rush": {"head": (33, 30), "chest": (29, 44), "hip": (23, 58),
             "arms": [((26, 43), (16, 47), (9, 42)), ((31, 43), (38, 48), (43, 40))],
             "legs": [((20, 58), (12, 64), (8, 76)), ((26, 58), (35, 65), (35, 76))]},
    "recovery": {"head": (28, 29), "chest": (24, 43), "hip": (25, 59),
                 "arms": [((21, 43), (12, 51), (7, 54)), ((27, 43), (34, 49), (42, 48))],
                 "legs": [((22, 59), (17, 67), (15, 76)), ((28, 59), (33, 68), (33, 76))]},
}
BACK = {
    "standing": {"head": (24, 25), "chest": (24, 41), "hip": (24, 58),
                 "arms": [((15, 41), (10, 52), (11, 62)), ((33, 41), (38, 52), (37, 62))],
                 "legs": [((20, 59), (18, 68), (16, 76)), ((28, 59), (30, 68), (32, 76))]},
    "crouch": {"head": (24, 38), "chest": (24, 50), "hip": (24, 62),
               "arms": [((15, 49), (9, 56), (16, 54)), ((33, 49), (39, 56), (32, 54))],
               "legs": [((20, 62), (12, 69), (16, 76)), ((28, 62), (36, 69), (32, 76))]},
    "rush": {"head": (26, 30), "chest": (25, 43), "hip": (23, 59),
             "arms": [((16, 42), (9, 48), (7, 40)), ((34, 42), (40, 48), (41, 40))],
             "legs": [((19, 59), (15, 67), (12, 76)), ((27, 59), (31, 66), (36, 76))]},
    "recovery": {"head": (21, 29), "chest": (23, 43), "hip": (25, 59),
                 "arms": [((14, 42), (8, 51), (5, 47)), ((32, 43), (37, 48), (42, 57))],
                 "legs": [((21, 59), (17, 68), (13, 76)), ((29, 59), (32, 68), (35, 76))]},
}


def poly(draw, points, color):
    draw.polygon(points, fill=PAL[color])


def rect(draw, bounds, color):
    draw.rectangle(bounds, fill=PAL[color])


def segment(draw, start, end, width, color):
    """A sharp integer polygon; no antialias or resampling in runtime cells."""
    dx, dy = end[0] - start[0], end[1] - start[1]
    length = math.hypot(dx, dy)
    nx, ny = -dy / length * width / 2, dx / length * width / 2
    points = [(round(start[0] + nx), round(start[1] + ny)),
              (round(end[0] + nx), round(end[1] + ny)),
              (round(end[0] - nx), round(end[1] - ny)),
              (round(start[0] - nx), round(start[1] - ny))]
    poly(draw, points, color)


def band(draw, start, end, fraction, width, color="light"):
    x = round(start[0] + (end[0] - start[0]) * fraction)
    y = round(start[1] + (end[1] - start[1]) * fraction)
    dx, dy = end[0] - start[0], end[1] - start[1]
    length = math.hypot(dx, dy)
    nx, ny = -dy / length * width / 2, dx / length * width / 2
    draw.line([(round(x - nx), round(y - ny)),
               (round(x + nx), round(y + ny))], fill=PAL[color], width=2)


def limb(draw, joints, leg=False, far=False):
    a, b, c = joints
    segment(draw, a, b, 7 if leg else 6, "ink")
    segment(draw, b, c, 6 if leg else 5, "ink")
    segment(draw, a, b, 4 if leg else 3, "coal" if far else "shade")
    # Broad fabric fold and cuff rather than an evenly speckled surface.
    shifted = ((a[0] - 1, a[1] + 2), (b[0] - 1, b[1] - 2))
    segment(draw, *shifted, 2, "shade" if far else "mid")
    segment(draw, b, c, 3, "silver" if leg else ("coal" if far else "shade"))
    band(draw, a, b, 0.86, 5, "silver" if far else "white")
    band(draw, b, c, 0.70 if leg else 0.80, 4, "silver" if far else "light")
    if leg:
        # The same low baseline keeps every pose grounded without a baked shadow.
        x, y = c
        poly(draw, [(x - 3, y - 1), (x + 2, y - 1), (x + 5, 78),
                    (x + 5, 79), (x - 4, 79), (x - 4, 78)], "ink")
        poly(draw, [(x - 2, y), (x + 1, y), (x + 3, 77),
                    (x + 3, 78), (x - 3, 78)], "silver" if far else "light")
        rect(draw, (x - 2, 77, x, 77), "white" if not far else "silver")
    else:
        x, y = c
        poly(draw, [(x - 2, y - 1), (x + 2, y - 1), (x + 2, y + 4),
                    (x + 1, y + 6), (x - 2, y + 4)], "silver" if far else "light")
        rect(draw, (x - 1, y, x, y + 3), "light" if far else "white")
        rect(draw, (x + 2, y + 1, x + 3, y + 3), "silver")


def torso(draw, chest, hip, facing):
    x, y = chest
    hx, hy = hip
    narrow = facing == "side"
    half = 6 if narrow else 9
    poly(draw, [(x - half, y - 2), (x + half, y - 2),
                (hx + 7, hy - 2), (hx + 5, hy + 4),
                (hx - 6, hy + 4), (hx - 8, hy - 2)], "ink")
    poly(draw, [(x - half + 2, y), (x + half - 2, y),
                (hx + 5, hy - 3), (hx - 5, hy + 1)], "coal")
    poly(draw, [(x - half + 1, y + 2), (x - half + 4, y + 3),
                (hx - 3, hy - 5), (hx - 5, hy - 3)], "shade")
    # Deliberate diagonal clusters suggest stretched black stage cloth.
    poly(draw, [(hx + 2, hy - 7), (hx + 5, hy - 5),
                (hx + 4, hy - 1), (hx + 2, hy - 3)], "mid")
    rect(draw, (hx - 4, hy, hx + 4, hy + 1), "silver")
    rect(draw, (hx - 1, hy, hx + 1, hy + 2), "light")
    # Keep a full black cluster between pale ribs, including the shorter crouch
    # torso. Adjacent two-pixel bands must never merge into a white chest plate.
    offsets = (1, 5, 9) if hy - y <= 13 else (1, 5, 9, 13)
    for index, offset in enumerate(offsets):
        fraction = offset / (hy - y)
        cy = y + offset
        cx = round(x + (hx - x) * fraction)
        span = 6 - index // 2
        if narrow:
            poly(draw, [(cx - 3, cy), (cx + 4, cy - 1),
                        (cx + 5, cy + 1), (cx - 2, cy + 2)], "light")
            rect(draw, (cx - 2, cy, cx + 1, cy), "white")
        elif facing == "back":
            poly(draw, [(cx - span, cy), (cx - 1, cy + 1),
                        (cx - 1, cy + 2), (cx - span, cy + 1)], "silver")
            poly(draw, [(cx + 1, cy + 1), (cx + span, cy),
                        (cx + span, cy + 1), (cx + 1, cy + 2)], "light")
        else:
            poly(draw, [(cx - span, cy), (cx - 1, cy + 1),
                        (cx - 1, cy + 2), (cx - span, cy + 1)], "light")
            poly(draw, [(cx + 1, cy + 1), (cx + span, cy),
                        (cx + span, cy + 1), (cx + 1, cy + 2)], "white")
    draw.line([chest, (hx, hy - 2)], fill=PAL["silver" if facing == "back" else "light"], width=2)
    # Rib shapes are sewn paint/bands on intact fabric, not exposed skeleton.


def head(draw, centre, facing, pose):
    x, y = centre
    side = facing == "side"
    # A fitted hood bridges the mask to the shoulder; it is never a helmet visor.
    poly(draw, [(x - 5, y + 4), (x + 4, y + 4),
                (x + 5, y + 12), (x - 5, y + 12)], "ink")
    if side:
        roots = [(x - 3, y - 5), (x - 2, y - 6), (x, y - 6), (x + 1, y - 5), (x + 2, y - 4)]
        tips = [(x - 18, y - 14), (x - 13, y - 20), (x - 6, y - 24), (x + 1, y - 22), (x + 8, y - 17)]
    else:
        roots = [(x - 4, y - 5), (x - 2, y - 6), (x, y - 7), (x + 2, y - 6), (x + 4, y - 5)]
        tips = [(x - 15, y - 16), (x - 9, y - 23), (x, y - 25), (x + 9, y - 23), (x + 15, y - 16)]
    # Clear margins are deliberate: standing top is y1, crouch still has a fan.
    for root, tip in zip(roots, tips):
        tip = (max(2, min(45, tip[0])), max(2, tip[1]))
        draw.line([root, tip], fill=PAL["ink"], width=3)
        draw.line([root, tip], fill=PAL["silver" if facing == "back" else "light"], width=1)
        rect(draw, (tip[0] - 1, tip[1] - 1, tip[0] + 1, tip[1] + 1), "silver" if facing == "back" else "white")
    if facing == "back":
        poly(draw, [(x - 6, y - 6), (x + 5, y - 6), (x + 7, y - 1),
                    (x + 5, y + 7), (x, y + 10), (x - 5, y + 7), (x - 7, y - 1)], "ink")
        poly(draw, [(x - 4, y - 4), (x + 3, y - 4), (x + 5, y),
                    (x + 3, y + 5), (x - 3, y + 6), (x - 5, y)], "shade")
        poly(draw, [(x - 4, y - 3), (x - 2, y - 4), (x - 1, y + 4), (x - 3, y + 5)], "mid")
        draw.line([(x, y - 4), (x + 1, y + 7)], fill=PAL["coal"], width=2)
        rect(draw, (x - 4, y + 7, x + 4, y + 8), "silver")
    elif side:
        poly(draw, [(x - 5, y - 5), (x + 3, y - 6), (x + 7, y - 1),
                    (x + 6, y + 3), (x + 9, y + 5), (x + 5, y + 6),
                    (x + 3, y + 11), (x - 2, y + 8), (x - 5, y + 2)], "ink")
        poly(draw, [(x - 3, y - 4), (x + 2, y - 4), (x + 5, y - 1),
                    (x + 4, y + 3), (x + 7, y + 5), (x + 3, y + 5),
                    (x + 2, y + 9), (x - 1, y + 6), (x - 3, y + 1)], "light")
        rect(draw, (x - 1, y - 3, x + 2, y - 2), "white")
        draw.ellipse((x, y - 1, x + 4, y + 3), fill=PAL["ink"])
        rect(draw, (x + 1, y, x + 2, y + 1), "silver")
        rect(draw, (x + 3, y + 6, x + 5, y + 6), "coal")
        rect(draw, (x - 4, y + 1, x - 3, y + 4), "silver")
    else:
        poly(draw, [(x - 5, y - 6), (x + 4, y - 6), (x + 7, y - 2),
                    (x + 6, y + 5), (x + 3, y + 9), (x, y + 12),
                    (x - 3, y + 9), (x - 6, y + 5), (x - 7, y - 2)], "ink")
        poly(draw, [(x - 4, y - 4), (x + 3, y - 4), (x + 5, y - 1),
                    (x + 4, y + 5), (x + 2, y + 8), (x, y + 9),
                    (x - 2, y + 7), (x - 4, y + 4), (x - 5, y - 1)], "light")
        poly(draw, [(x - 3, y - 4), (x, y - 5), (x + 3, y - 4), (x + 1, y - 2), (x - 2, y - 2)], "white")
        for ex in (x - 3, x + 3):
            draw.ellipse((ex - 2, y - 1, ex + 2, y + 3), fill=PAL["ink"])
            rect(draw, (ex, y, ex, y + 1), "silver")
        poly(draw, [(x, y + 2), (x + 1, y + 5), (x - 1, y + 5)], "white")
        rect(draw, (x - 2, y + 7, x + 2, y + 7), "coal")
        rect(draw, (x - 1, y + 8, x + 1, y + 8), "silver")
    # No skull teeth, weapon, pulse, decorative warning boundary or particles.


def draw_frame(facing, pose):
    image = Image.new("RGBA", SIZE, (0, 0, 0, 0))
    draw = ImageDraw.Draw(image)
    spec = {"front": FRONT, "side": SIDE, "back": BACK}[facing][pose]
    # Explicit painter order preserves the two limbs and readable side overlap.
    for index in (0, 1):
        limb(draw, spec["legs"][index], leg=True, far=facing == "side" and index == 0)
    limb(draw, spec["arms"][0], far=facing == "side")
    torso(draw, spec["chest"], spec["hip"], facing)
    limb(draw, spec["arms"][1])
    for shoulder in (spec["arms"][0][0], spec["arms"][1][0]):
        sx, sy = shoulder
        poly(draw, [(sx - 3, sy - 3), (sx + 2, sy - 3),
                    (sx + 4, sy), (sx + 2, sy + 4), (sx - 3, sy + 3)], "ink")
        poly(draw, [(sx - 2, sy - 2), (sx + 1, sy - 2),
                    (sx + 2, sy), (sx, sy + 2), (sx - 2, sy + 2)], "silver" if facing == "back" else "mid")
        rect(draw, (sx - 2, sy - 2, sx, sy - 1), "light")
    head(draw, spec["head"], facing, pose)
    return image


def digest(path):
    return sha256(path.read_bytes()).hexdigest()


def source_records():
    paths = {
        "G10": "docs/concept-art/act1/characters/selenite-costumes-and-roles.png",
        "F10": "docs/reference-library/act1/film-stills/f10.jpg",
        "F11": "docs/reference-library/act1/film-stills/f11.jpg",
        "C30": "docs/reference-library/act1/research/entities.json",
    }
    kinds = {"G10": "generated_game_concept_not_runtime_atlas",
             "F10": "1902_film_frame_costume_reference",
             "F11": "1902_film_frame_stage_magic_context_not_pose_or_clock",
             "C30": "canonical_game_enemy_record_A1-E1"}
    records = [{"id": key, "path": path, "sha256": digest(ROOT / path),
                "source_kind": kinds[key], "pixel_use": "none; inspected reference only"}
               for key, path in paths.items()]
    entities = json.loads((ROOT / paths["C30"]).read_text())
    def find(value):
        if isinstance(value, dict):
            if value.get("id") == "C30":
                return value
            for child in value.values():
                found = find(child)
                if found is not None:
                    return found
        elif isinstance(value, list):
            for child in value:
                found = find(child)
                if found is not None:
                    return found
        return None
    record = find(entities)
    records[-1]["canonical_record_sha256"] = sha256(json.dumps(record, sort_keys=True, separators=(",", ":"), ensure_ascii=False).encode()).hexdigest()
    return records


def contact_sheet(frames):
    # Review only: nearest enlargement, labels and backgrounds never enter frames.
    sheet = Image.new("RGB", (680, 1490), (31, 31, 31))
    draw = ImageDraw.Draw(sheet)
    font = ImageFont.load_default()
    draw.text((16, 10), "C30 RUSH SELENITE / 48x80 native / nearest 4x review", fill=(231, 231, 231), font=font)
    for col, facing in enumerate(FACINGS):
        draw.text((26 + col * 224, 31), facing.upper() + (" (RIGHT)" if facing == "side" else ""), fill=(193, 193, 193), font=font)
        for row, pose in enumerate(POSES):
            left, top = 14 + col * 224, 55 + row * 354
            # Two quiet values reveal ink and pale mask without a baked floor.
            draw.rectangle((left, top, left + 191, top + 319), fill=(100, 100, 100))
            draw.rectangle((left + 96, top, left + 191, top + 319), fill=(48, 48, 48))
            image = frames[(facing, pose)].resize((192, 320), Image.Resampling.NEAREST)
            sheet.paste(image, (left, top), image)
            draw.text((left, top + 323), pose.upper() + " / " + ",".join(PHASES[pose]), fill=(231, 231, 231), font=font)
    sheet.save(OUT / "rusher_contact_sheet.png")


def main():
    frames = {}
    records = []
    sources = source_records()
    for facing in FACINGS:
        for pose in POSES:
            image = draw_frame(facing, pose)
            name = f"rusher_{facing}_{pose}.png"
            image.save(OUT / name)
            frames[(facing, pose)] = image
            bounds = image.getchannel("A").getbbox()
            # Runtime cells must stay transparent, hard edged, monochrome and unique.
            raw = image.tobytes()
            assert image.size == SIZE and set(raw[3::4]) == {0, 255}
            assert bounds[0] > 0 and bounds[1] > 0 and bounds[2] < 48 and bounds[3] == 80
            assert all(r == g == b for r, g, b, a in zip(raw[0::4], raw[1::4], raw[2::4], raw[3::4]) if a)
            records.append({
                "id": f"ACT1-C30-{facing.upper()}-{pose.upper()}", "file": name,
                "sha256": digest(OUT / name), "entity_id": "C30", "design_id": "A1-E1",
                "reuse_family": "act1_selenite_C30_rusher", "facing": facing,
                "side_direction": "screen_right" if facing == "side" else "not_applicable",
                "pose": pose, "shared_scheduler_phases": PHASES[pose],
                "native_grid": list(SIZE), "pixel_size_tentative": PIXEL_SIZE,
                "feet_pivot_pixels": list(PIVOT), "sprite_offset_pixels_if_centered": [0, 40],
                "opaque_extent_pixels_exclusive": list(bounds),
                "opaque_extent_relative_to_feet_world_tentative": {
                    "left": round((bounds[0] - PIVOT[0]) * PIXEL_SIZE, 6),
                    "right": round((bounds[2] - PIVOT[0]) * PIXEL_SIZE, 6),
                    "bottom": 0.0, "top": round((PIVOT[1] - bounds[1]) * PIXEL_SIZE, 6)},
                "collision": "none; existing actor retained capsule is authoritative",
                "occlusion": "ordinary actor depth; no baked shadow, floor, cue or particles",
                "duration": "not_applicable; static pose selected from public shared phase",
                "state_authority": "published scheduler/actor state only; no asset clock or motion",
                "source_provenance": sources,
                "authorship": "original hand-specified integer pixel polygons; no crop or source-pixel reuse",
                "runtime_readiness": READINESS,
            })
    assert len({record["sha256"] for record in records}) == 12
    contact_sheet(frames)
    manifest = {
        "schema_version": 1, "family": "act1_selenite_C30_rusher", "entity_id": "C30",
        "design_id": "A1-E1", "first_level": "A1-L2", "created_date": "2026-10-08",
        "authorship": "original project pixel art, deterministic hand-authored Pillow geometry",
        "generator": "build_rusher_cutouts.py", "generator_sha256": digest(Path(__file__)),
        "palette": {key: list(value) for key, value in PAL.items()},
        "palette_basis": "exact seven grayscale entries from assets/acts/act1/launch/build_cutouts.py",
        "palette_basis_sha256": digest(ROOT / "assets/acts/act1/launch/build_cutouts.py"),
        "source_provenance": sources, "runtime_readiness": READINESS,
        "binding_notes": "RUSHER_ART_NOTES.md", "binding_notes_sha256": digest(OUT / "RUSHER_ART_NOTES.md"),
        "assets": records,
        "preview": {"file": "rusher_contact_sheet.png", "sha256": digest(OUT / "rusher_contact_sheet.png"),
                    "role": "review_only_nearest_4x_labels_and_background; never a runtime atlas"},
        "production_checks": {"frames": 12, "all_unique": True, "native_size": list(SIZE),
                              "hard_alpha_only": True, "monochrome_only": True,
                              "shared_feet_pivot": list(PIVOT), "portrait_validated": False,
                              "runtime_bound": False, "engine_jobs_run": False},
    }
    (OUT / "rusher_manifest.json").write_text(json.dumps(manifest, indent=2) + "\n")
    print("Produced 12 original transparent 48x80 C30 frames and review sheet; runtime unbound.")


if __name__ == "__main__":
    main()
