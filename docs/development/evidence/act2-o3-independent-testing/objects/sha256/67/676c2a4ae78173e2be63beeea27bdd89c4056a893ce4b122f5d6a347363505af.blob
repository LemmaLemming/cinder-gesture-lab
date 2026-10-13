#!/usr/bin/env python3
"""Original C31/C32 pixel geometry. References are inspected, never sampled.

Each pose is a static drawing at a common floor pivot. Nothing here specifies
movement, cue geometry, damage, animation time or spore state.
"""
from pathlib import Path
import hashlib
import json
from PIL import Image, ImageDraw, ImageFont

HERE = Path(__file__).resolve().parent
ROOT = HERE.parents[4]
PALETTE = {
    "ink": (20, 20, 20, 255), "coal": (39, 39, 39, 255),
    "shade": (67, 67, 67, 255), "mid": (105, 105, 105, 255),
    "silver": (147, 147, 147, 255), "light": (193, 193, 193, 255),
    "white": (231, 231, 231, 255),
}
POSES = ("standing", "warning", "lock", "active", "recovery")
FACINGS = ("front", "side", "back")
PHASES = {"standing": ["clear", "idle"], "warning": ["warning"],
          "lock": ["lock"], "active": ["active"], "recovery": ["recovery"]}
ROLES = {
    "swarm": {"entity_id": "C31", "design_id": "A1-E2", "basis_id": "C20", "width": 48,
              "family": "act1_grotto_selenite_C31_swarm"},
    "guard": {"entity_id": "C32", "design_id": "A1-E3", "basis_id": "C22", "width": 80,
              "family": "act1_grotto_selenite_C32_spear_guard"},
}


def sha(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()


def rect(d, box, color):
    d.rectangle(box, fill=PALETTE[color])


def poly(d, points, color, outline=None):
    d.polygon(points, fill=PALETTE[color])
    if outline:
        d.line(points + [points[0]], fill=PALETTE[outline], width=1)


def limb(d, points, width=5):
    # Dark theatrical cloth with one broad silver fold, never noise/dithering.
    d.line(points, fill=PALETTE["ink"], width=width + 2)
    d.line(points, fill=PALETTE["coal"], width=width)
    d.line([(x - 1, y) for x, y in points], fill=PALETTE["mid"], width=1)


def band(d, point, horizontal=True):
    x, y = point
    rect(d, (x - 3, y - 1, x + 3, y + 1) if horizontal else
         (x - 1, y - 3, x + 1, y + 3), "light")
    rect(d, (x - 2, y - 1, x + 1, y - 1), "white")


def hand(d, point):
    x, y = point
    poly(d, [(x - 2, y - 2), (x + 2, y - 2), (x + 3, y + 2),
             (x + 1, y + 3), (x - 2, y + 1)], "light", "ink")
    rect(d, (x - 1, y - 1, x, y + 1), "white")


def boot(d, x, y=79, direction=1):
    poly(d, [(x - 3, y - 5), (x + 1, y - 5),
             (x + 4 * direction, y - 2), (x + 4 * direction, y),
             (x - 4, y)], "light", "ink")
    rect(d, (x - 2, y - 4, x, y - 2), "white")


def mask(d, cx, cy, facing, small=False, lean=0):
    half = 5 if small else 6
    # Projecting rods echo the stage headpiece, without a radial cue boundary.
    if facing == "side":
        tips = [(cx - 17, cy - 12), (cx - 14, cy - 20),
                (cx - 7, cy - 24), (cx, cy - 21), (cx + 5, cy - 17)]
    else:
        height = 18 if small else 26
        tips = [(cx - 17, cy - height + 8), (cx - 10, cy - height + 2),
                (cx - 1, cy - height), (cx + 8, cy - height + 3),
                (cx + 16, cy - height + 9)]
    for tip in tips:
        d.line([(cx + lean, cy - 5), tip], fill=PALETTE["ink"], width=3)
        d.line([(cx + lean, cy - 5), tip], fill=PALETTE["silver"], width=2)
        d.line([(cx + lean, cy - 5), tip], fill=PALETTE["light"], width=1)
        rect(d, (tip[0] - 1, tip[1] - 1, tip[0] + 1, tip[1] + 1), "white")
    if facing == "side":
        points = [(cx - half, cy - 5), (cx + 2, cy - 6), (cx + half + 1, cy - 2),
                  (cx + half + 3, cy + 2), (cx + half, cy + 3),
                  (cx + 3, cy + 9), (cx - 3, cy + 6)]
    else:
        points = [(cx - half, cy - 4), (cx - 3, cy - 6), (cx + 3, cy - 6),
                  (cx + half, cy - 3), (cx + half - 1, cy + 4),
                  (cx + 2, cy + 10), (cx - 2, cy + 10), (cx - half + 1, cy + 4)]
    poly(d, points, "shade" if facing == "back" else "light", "ink")
    if facing == "back":
        rect(d, (cx - 3, cy - 3, cx + 3, cy + 4), "coal")
        d.line([(cx - 3, cy + 2), (cx, cy + 7), (cx + 3, cy + 2)],
               fill=PALETTE["silver"], width=1)
    elif facing == "side":
        rect(d, (cx + 1, cy - 1, cx + 4, cy + 2), "ink")
        rect(d, (cx + 2, cy, cx + 2, cy), "white")
        d.line([(cx + 3, cy + 5), (cx + 6, cy + 5)], fill=PALETTE["ink"], width=1)
        d.line([(cx - 3, cy - 3), (cx - 3, cy + 3)], fill=PALETTE["white"], width=1)
    else:
        rect(d, (cx - 4, cy - 1, cx - 1, cy + 2), "ink")
        rect(d, (cx + 1, cy - 1, cx + 4, cy + 2), "ink")
        rect(d, (cx - 3, cy, cx - 3, cy), "white")
        rect(d, (cx + 2, cy, cx + 2, cy), "white")
        d.line([(cx, cy + 1), (cx - 1, cy + 5), (cx + 1, cy + 5)], fill=PALETTE["shade"], width=1)
        rect(d, (cx - 2, cy + 7, cx + 2, cy + 7), "ink")


def torso(d, cx, top, bottom, facing, small=False, lean=0):
    width = 6 if small else 8
    poly(d, [(cx - width, top), (cx + width - 1, top),
             (cx + width - 3 + lean, bottom - 3), (cx + lean, bottom),
             (cx - width + 3 + lean, bottom - 3)], "coal", "ink")
    d.line([(cx - width + 1, top + 2), (cx - width + 3 + lean, bottom - 4)],
           fill=PALETTE["mid"], width=2)
    # Hand-set ribs curve into the spine. Broad interrupted strips remain cloth.
    for y in range(top + 2, bottom - 3, 3):
        taper = 1 if y > bottom - 9 else 0
        if facing == "side":
            d.line([(cx - 3 + lean, y), (cx + width - 2 + lean, y + 1)], fill=PALETTE["light"], width=2)
            rect(d, (cx - 3 + lean, y, cx - 1 + lean, y), "white")
        else:
            d.line([(cx - width + 1 + taper + lean, y), (cx - 1 + lean, y + 1),
                    (cx + width - 2 - taper + lean, y)], fill=PALETTE["light"], width=2)
            rect(d, (cx - width + 2 + taper + lean, y, cx - 3 + lean, y), "white")
    d.line([(cx + lean, top + 1), (cx + lean, bottom - 2)], fill=PALETTE["white"], width=2)
    poly(d, [(cx - 4 + lean, bottom - 2), (cx + 4 + lean, bottom - 2),
             (cx + 2 + lean, bottom + 2), (cx - 2 + lean, bottom + 2)], "silver", "ink")


def draw_swarm(facing, pose):
    im = Image.new("RGBA", (48, 80), (0, 0, 0, 0)); d = ImageDraw.Draw(im)
    cx = 24 if facing != "side" else 26
    cy = {"standing": 31, "warning": 39, "lock": 35, "active": 35, "recovery": 32}[pose]
    top = cy + 10; bottom = 60 if pose == "warning" else 58
    lean = 2 if pose == "active" else 0
    # Every frame has an actual planted boot at y79. The bent leg is cosmetic.
    knees = ((cx - 8, 67), (cx + 7, 66)) if pose in ("warning", "lock") else ((cx - 5, 66), (cx + 4, 66))
    feet = (cx - 9, cx + 8) if pose in ("warning", "active") else (cx - 6, cx + 6)
    if pose == "active": knees = ((cx - 11, 69), (cx + 9, 63)); feet = (cx - 12, cx + 9)
    for hip, knee, foot in zip([(cx - 3, bottom), (cx + 3, bottom)], knees, feet):
        limb(d, [hip, knee, (foot, 75)], 4); band(d, knee); band(d, (foot, 73)); boot(d, foot)
    torso(d, cx, top, bottom, facing, True, lean)
    shoulders = [(cx - 6, top + 1), (cx + 5, top + 1)]
    if pose == "warning": elbows = [(cx - 10, 49), (cx + 11, 48)]; hands = [(cx - 13, 40), (cx + 13, 39)]
    elif pose == "lock": elbows = [(cx - 12, 49), (cx + 10, 47)]; hands = [(cx - 15, 49), (cx + 14, 46)]
    elif pose == "active": elbows = [(cx - 8, 50), (cx + 11, 46)]; hands = [(cx - 12, 54), (cx + 16, 45)]
    elif pose == "recovery": elbows = [(cx - 10, 51), (cx + 9, 51)]; hands = [(cx - 11, 59), (cx + 9, 59)]
    else: elbows = [(cx - 9, 49), (cx + 8, 49)]; hands = [(cx - 10, 58), (cx + 9, 58)]
    for shoulder, elbow, wrist in zip(shoulders, elbows, hands):
        limb(d, [shoulder, elbow, wrist], 4); band(d, elbow); hand(d, wrist)
        rect(d, (shoulder[0] - 2, shoulder[1] - 1, shoulder[0] + 2, shoulder[1] + 2), "shade")
        rect(d, (shoulder[0] - 1, shoulder[1] - 1, shoulder[0], shoulder[1]), "silver")
    mask(d, cx + lean, cy, facing, True, lean)
    return im


def spear(d, pose, facing):
    # Entire prop is in the actor drawing; no separate physics/attack object.
    ends = {"standing": ((22, 64), (65, 21), (77, 8)),
            "warning": ((21, 60), (64, 17), (76, 3)),
            "lock": ((19, 57), (62, 46), (77, 41)),
            "active": ((18, 48), (62, 48), (78, 48)),
            "recovery": ((23, 57), (63, 63), (77, 66))}
    tail, neck, tip = ends[pose]
    d.line([tail, neck, tip], fill=PALETTE["ink"], width=5)
    d.line([tail, neck], fill=PALETTE["silver"], width=3)
    d.line([(tail[0], tail[1] - 1), (neck[0], neck[1] - 1)], fill=PALETTE["white"], width=1)
    dx, dy = tip[0] - neck[0], tip[1] - neck[1]
    # Broad theatrical arrowhead, not a needle or firearm.
    ax, ay = (-dy, dx)
    denom = max(abs(ax), abs(ay)); ax, ay = round(ax * 8 / denom), round(ay * 8 / denom)
    poly(d, [(neck[0] + ax, neck[1] + ay), tip,
             (neck[0] - ax, neck[1] - ay), (neck[0] - 2, neck[1] + 2)], "light", "ink")
    poly(d, [neck, tip, (neck[0] - ax + 1, neck[1] - ay + 1)], "white")
    d.line([neck, tip], fill=PALETTE["silver"], width=1)
    d.line([(neck[0] - 2, neck[1] + 1), (neck[0] + 2, neck[1] - 1)], fill=PALETTE["ink"], width=2)


def draw_guard(facing, pose):
    im = Image.new("RGBA", (80, 80), (0, 0, 0, 0)); d = ImageDraw.Draw(im)
    cx = 40 if facing != "side" else 37
    cy = {"standing": 29, "warning": 32, "lock": 32, "active": 31, "recovery": 28}[pose]
    top, bottom = cy + 11, 60
    wide = pose in ("warning", "lock", "active")
    feet = (cx - 13, cx + 13) if wide else (cx - 8, cx + 8)
    knees = ((cx - 10, 69), (cx + 9, 69)) if wide else ((cx - 6, 68), (cx + 5, 68))
    for hip, knee, foot in zip([(cx - 4, bottom), (cx + 4, bottom)], knees, feet):
        limb(d, [hip, knee, (foot, 75)], 5); band(d, knee); band(d, (foot, 73)); boot(d, foot)
    torso(d, cx, top, bottom, facing)
    mask(d, cx + (3 if facing == "side" else 0), cy, facing)
    if pose == "standing": elbows = [(cx - 12, 52), (cx + 12, 45)]; hands = [(31, 55), (54, 35)]
    elif pose == "warning": elbows = [(cx - 13, 48), (cx + 11, 42)]; hands = [(31, 50), (54, 31)]
    elif pose == "lock": elbows = [(cx - 12, 53), (cx + 12, 50)]; hands = [(31, 54), (55, 48)]
    elif pose == "active": elbows = [(cx - 10, 48), (cx + 11, 47)]; hands = [(34, 48), (56, 48)]
    else: elbows = [(cx - 12, 53), (cx + 10, 54)]; hands = [(32, 59), (55, 62)]
    for shoulder, elbow, wrist in zip([(cx - 8, top), (cx + 7, top)], elbows, hands):
        limb(d, [shoulder, elbow, wrist], 5); band(d, elbow)
        poly(d, [(shoulder[0] - 3, shoulder[1] - 2), (shoulder[0] + 2, shoulder[1] - 2),
                 (shoulder[0] + 3, shoulder[1] + 3), (shoulder[0] - 3, shoulder[1] + 3)], "shade", "ink")
        rect(d, (shoulder[0] - 2, shoulder[1] - 1, shoulder[0], shoulder[1]), "silver")
    spear(d, pose, facing)
    for wrist in hands: hand(d, wrist)
    return im


def main():
    provenance = []
    for ref_id, rel, kind in [
        ("G10", "docs/concept-art/act1/characters/selenite-costumes-and-roles.png", "generated_concept_costume_and_role_board"),
        ("G15", "docs/concept-art/act1/props/lunar-grotto-and-court-modular-kit.png", "generated_concept_theatrical_material_and_harmless_repulsion_reference"),
        ("F10", "docs/reference-library/act1/film-stills/f10.jpg", "1902_film_frame_upright_costume_and_oversized_spear_basis"),
    ]:
        provenance.append({"id": ref_id, "path": rel, "sha256": sha(ROOT / rel),
                           "kind": kind, "pixel_use": "none; actual image inspected, no crop/edit/source pixel reuse"})
    entity_path = ROOT / "docs/reference-library/act1/research/entities.json"
    entities = json.loads(entity_path.read_text())
    def records(o):
        if isinstance(o, dict):
            if o.get("id") in ("C31", "C32"): yield o
            for v in o.values(): yield from records(v)
        elif isinstance(o, list):
            for v in o: yield from records(v)
    canonical = {v["id"]: hashlib.sha256(json.dumps(v, sort_keys=True, ensure_ascii=False, separators=(",", ":")).encode()).hexdigest() for v in records(entities)}
    assets = []
    sheet = Image.new("RGB", (5 * 250, 6 * 270), (65, 65, 65)); sd = ImageDraw.Draw(sheet)
    for role_index, (role, meta) in enumerate(ROLES.items()):
        for facing_index, facing in enumerate(FACINGS):
            for pose_index, pose in enumerate(POSES):
                im = (draw_swarm if role == "swarm" else draw_guard)(facing, pose)
                path = HERE / f"{role}_{facing}_{pose}.png"; im.save(path)
                opaque = im.getchannel("A").getbbox(); width = meta["width"]
                assert opaque and set(im.getchannel("A").tobytes()).issubset({0, 255})
                assert opaque[3] == 80, (path.name, opaque)
                assets.append({"id": f"ACT1-{meta['entity_id']}-{facing.upper()}-{pose.upper()}",
                    "file": "selenites/" + path.name, "sha256": sha(path), **meta,
                    "facing": facing, "side_authorship": "right facing authored; left reflected by leaf only" if facing == "side" else "explicit authored orientation",
                    "pose": pose, "native_phases": PHASES[pose], "native_grid": [width, 80],
                    "pixel_size_provisional": 0.022, "feet_pivot_pixels": [width // 2, 80],
                    "sprite_offset_centered_pixels": [0, 40], "opaque_bounds_exclusive_pixels": list(opaque),
                    "opaque_bounds_from_pivot_world_provisional": [(opaque[0] - width / 2) * .022, (80 - opaque[3]) * .022, (opaque[2] - width / 2) * .022, (80 - opaque[1]) * .022],
                    "collision": "none; retained shared-motion actor capsule is authoritative",
                    "occlusion": "ordinary depth; no cue, shadow, field, particles or source marker baked",
                    "timing": "not_applicable; static native-phase selection with no asset clock",
                    "source_ids": ["G10", "G15", "F10"], "canonical_basis_ids": [meta["basis_id"]],
                    "canonical_record_sha256": canonical[meta["entity_id"]],
                    "readiness": "produced_pixels_and_clockless_leaf_unbound_not_portrait_validated"})
                x, y = pose_index * 250, (role_index * 3 + facing_index) * 270
                sd.text((x + 8, y + 5), f"{meta['entity_id']} {facing} / {pose}", fill=(231, 231, 231))
                big = im.resize((width * 3, 240), Image.Resampling.NEAREST)
                sheet.paste(big, (x + (250 - width * 3) // 2, y + 25), big)
    sheet.save(HERE / "selenite_contact_sheet.png")
    manifest = {"schema_version": 1, "first_level": "A1-L3", "created_date": "2026-10-09",
        "authorship": "original deterministic hand-authored Pillow integer geometry; no source pixels",
        "generator": "selenites/build_selenite_cutouts.py", "generator_sha256": sha(Path(__file__)),
        "palette": {k: list(v) for k, v in PALETTE.items()},
        "palette_basis": "existing Act1 launch/C30 seven-tone grayscale family",
        "palette_basis_sha256": sha(ROOT / "assets/acts/act1/launch/build_cutouts.py"),
        "source_provenance": provenance,
        "canonical_entities_path": "docs/reference-library/act1/research/entities.json",
        "canonical_entities_sha256": sha(entity_path),
        "notes": {"file": "selenites/SELENITE_ART_NOTES.md", "sha256": sha(HERE / "SELENITE_ART_NOTES.md")},
        "presentation_leaf": {"file": "scripts/acts/act1/mushroom_selenite_art.gd", "sha256": sha(ROOT / "scripts/acts/act1/mushroom_selenite_art.gd"), "binding": "configure(role_id) before add; set_pose(native_phase,actual_world_facing,actual_camera)"},
        "readiness": "produced_pixels_and_clockless_leaf_unbound_not_portrait_validated",
        "spore_connection": "none; future recoil/retreat/regroup assets and shared protocol remain separate",
        "actor_transform": "identity art leaf; source feet remain fixed at native actor origin",
        "preview": {"file": "selenites/selenite_contact_sheet.png", "sha256": sha(HERE / "selenite_contact_sheet.png"), "runtime": False},
        "assets": assets}
    (HERE.parent / "selenite_manifest.json").write_text(json.dumps(manifest, indent=2) + "\n")
    print(f"Produced {len(assets)} frames; manifest sha256 {sha(HERE.parent / 'selenite_manifest.json')}")


if __name__ == "__main__":
    main()
