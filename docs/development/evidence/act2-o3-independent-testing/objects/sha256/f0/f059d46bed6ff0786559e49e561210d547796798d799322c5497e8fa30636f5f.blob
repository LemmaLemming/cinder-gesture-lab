"""Four original lunar accents, drawn as deterministic native integer pixels.

Pillow only. References are read for hashes, never opened as drawing inputs.
Writes only the four PNGs, manifest and review sheet alongside this generator.
"""
from hashlib import sha256
import json
from pathlib import Path

from PIL import Image, ImageDraw, ImageFont

OUT = Path(__file__).resolve().parent
ROOT = OUT.parents[4]
PAL = {name: (gray, gray, gray, 255) for name, gray in [
    ("ink", 20), ("coal", 39), ("shade", 67), ("mid", 105),
    ("silver", 147), ("light", 193), ("white", 231),
]}
READY = "produced_pixels_not_runtime_bound_or_portrait_validated"


def canvas(w, h, opaque=False):
    image = Image.new("RGBA", (w, h), PAL["silver"] if opaque else (0, 0, 0, 0))
    return image, ImageDraw.Draw(image)


def poly(d, points, color):
    d.polygon(points, fill=PAL[color])


def rect(d, bounds, color):
    d.rectangle(bounds, fill=PAL[color])


def earth_globe():
    image, d = canvas(64, 64)
    d.ellipse((3, 3, 60, 60), fill=PAL["ink"])
    d.ellipse((5, 5, 58, 58), fill=PAL["mid"])
    # Offset lit disc and an irregular lower shadow suggest a painted globe.
    d.ellipse((6, 5, 53, 55), fill=PAL["silver"])
    poly(d, [(10,38),(17,48),(27,53),(39,52),(50,45),(48,52),
             (39,57),(27,57),(17,51),(11,44)], "shade")
    # Authored approximate continental silhouettes; no geographical accuracy claim.
    poly(d, [(13,15),(21,11),(24,12),(23,16),(27,18),(24,22),(19,22),
             (20,26),(17,28),(14,24),(11,23),(12,19)], "light")
    poly(d, [(20,29),(24,30),(27,35),(26,39),(23,41),(23,45),
             (20,49),(18,46),(19,39),(17,36)], "light")
    poly(d, [(30,14),(33,11),(40,11),(42,14),(48,15),(49,19),(53,21),
             (52,25),(48,24),(45,27),(41,25),(38,27),(34,24),(31,25),
             (29,21),(33,19),(30,17)], "white")
    poly(d, [(32,28),(38,27),(42,31),(44,35),(41,37),(39,44),(35,47),
             (32,44),(32,39),(29,36),(29,31)], "light")
    poly(d, [(47,42),(51,43),(53,47),(50,50),(46,49),(44,45)], "light")
    for pts in [[(15,16),(20,14),(20,17),(16,19)],
                [(20,31),(23,33),(24,38),(22,40)],
                [(35,29),(38,30),(40,34),(37,34)],
                [(36,16),(40,15),(44,17),(41,19)]]:
        poly(d, pts, "silver")
    for bounds in [(25,9,27,10),(42,28,43,29),(45,32,46,34),
                   (28,46,29,47),(13,31,14,32)]:
        rect(d, bounds, "light")
    # Sparse broken painted rim, never a pulsating or floor-warning circle.
    d.line([(9,18),(12,12),(19,8),(26,6)], fill=PAL["white"], width=1)
    d.line([(49,9),(54,16),(57,25)], fill=PAL["light"], width=1)
    return image


def human_star():
    image, d = canvas(64, 64)
    poly(d, [(31,2),(39,21),(61,23),(45,38),(51,61),
             (31,47),(11,60),(18,38),(2,23),(24,21)], "ink")
    poly(d, [(31,6),(37,23),(56,25),(42,37),(47,55),
             (31,43),(15,55),(21,37),(7,25),(26,23)], "light")
    poly(d, [(31,7),(32,23),(29,31),(26,24)], "white")
    poly(d, [(8,26),(28,27),(31,32),(22,34)], "white")
    poly(d, [(38,26),(55,25),(43,34),(34,33)], "white")
    poly(d, [(26,37),(29,43),(16,54),(22,40)], "white")
    poly(d, [(34,37),(39,41),(46,54),(33,44)], "silver")
    # An oval face, swept curls, ears and eyebrows distinguish the human from
    # a generic star icon or the masked Selenite family.
    d.ellipse((19,23,44,48), fill=PAL["ink"])
    d.ellipse((20,25,23,35), fill=PAL["silver"])
    d.ellipse((41,25,44,35), fill=PAL["silver"])
    poly(d, [(25,24),(32,22),(38,24),(41,29),(40,40),(35,45),
             (29,45),(24,41),(22,32)], "light")
    poly(d, [(25,27),(29,24),(33,24),(32,28),(28,31),(25,31)], "white")
    poly(d, [(35,29),(38,30),(39,36),(37,39),(35,38)], "silver")
    poly(d, [(21,31),(20,26),(23,22),(27,21),(31,22),(33,21),
             (38,23),(43,26),(43,33),(40,30),(38,26),(33,25),
             (30,27),(26,25),(23,29)], "coal")
    for bounds in [(23,25,25,26),(28,23,30,24),(34,24,36,25),(39,27,40,29)]:
        rect(d, bounds, "mid")
    d.line([(25,31),(28,30),(30,31)], fill=PAL["coal"], width=1)
    d.line([(34,31),(37,30),(39,31)], fill=PAL["coal"], width=1)
    rect(d, (25,33,29,34), "white")
    rect(d, (34,33,38,34), "white")
    rect(d, (27,33,28,34), "coal")
    rect(d, (35,33,36,34), "coal")
    d.line([(32,33),(31,37),(33,38)], fill=PAL["mid"], width=1)
    rect(d, (30,38,32,38), "white")
    d.line([(28,40),(30,42),(34,42),(37,40)], fill=PAL["coal"], width=1)
    rect(d, (30,41,34,41), "white")
    rect(d, (30,44,34,44), "silver")
    return image


def saturn_performer():
    image, d = canvas(80, 96)
    # Back half of the large inclined prop ring, followed by globe and costume.
    ring = [(4,73),(8,66),(24,58),(43,49),(63,41),(73,39),
            (75,42),(74,47),(65,56),(47,65),(27,75),(10,81),(4,79),(4,73)]
    d.line(ring, fill=PAL["ink"], width=6, joint="curve")
    d.line(ring, fill=PAL["light"], width=3, joint="curve")
    d.ellipse((13,35,70,92), fill=PAL["ink"])
    d.ellipse((15,37,68,90), fill=PAL["mid"])
    poly(d, [(24,43),(36,39),(49,40),(60,47),(64,54),(49,51),
             (33,53),(18,58),(18,52)], "silver")
    poly(d, [(17,69),(28,72),(39,78),(55,76),(66,70),(64,79),
             (56,85),(43,89),(30,86),(21,78)], "shade")
    for pts in [[(19,57),(26,54),(32,56),(28,60),(21,62)],
                [(50,43),(57,46),(61,51),(56,50)],
                [(43,82),(48,79),(56,79),(54,84),(47,86)]]:
        poly(d, pts, "light")
    # Seated pale-robed human: crown, broad beard, resting hands and folded knees.
    poly(d, [(28,29),(37,27),(46,31),(51,39),(57,43),(59,51),
             (52,56),(46,52),(29,53),(23,52),(19,46),(23,36)], "ink")
    poly(d, [(29,32),(37,31),(44,33),(48,41),(54,45),(55,50),
             (51,52),(44,47),(31,48),(25,50),(23,46),(26,37)], "light")
    poly(d, [(28,37),(32,34),(35,39),(32,49),(27,49),(29,43)], "white")
    poly(d, [(43,36),(46,41),(47,46),(45,50),(41,45)], "white")
    poly(d, [(24,50),(29,46),(37,46),(45,49),(53,48),(59,54),
             (62,69),(57,74),(56,82),(49,83),(47,76),(38,74),
             (32,81),(24,80),(23,74),(19,65),(20,57)], "ink")
    poly(d, [(25,52),(30,49),(37,49),(45,52),(52,51),(56,56),
             (59,68),(54,70),(52,79),(49,80),(46,73),(38,71),
             (31,78),(26,77),(26,72),(22,64),(23,57)], "light")
    for pts in [[(26,53),(29,52),(30,60),(27,68),(28,74),(26,73),(24,63)],
                [(34,50),(37,51),(39,56),(36,63),(33,68),(32,75),(29,76),(31,65),(35,57)],
                [(45,54),(49,53),(50,62),(55,67),(52,70),(47,65)],
                [(39,66),(43,64),(47,68),(48,75),(46,73),(43,70),(38,69)]]:
        poly(d, pts, "white")
    for pts in [[(31,52),(33,52),(34,59),(30,67),(30,73),(28,74),(29,65),(32,58)],
                [(43,53),(45,54),(43,62),(40,67),(37,67),(40,61)],
                [(53,56),(55,59),(56,66),(53,66),(52,61)]]:
        poly(d, pts, "mid")
    d.ellipse((22,44,28,48), fill=PAL["ink"])
    rect(d, (23,45,28,47), "light")
    d.ellipse((51,45,57,49), fill=PAL["ink"])
    rect(d, (52,46,56,48), "light")
    poly(d, [(29,20),(30,14),(35,12),(41,13),(45,19),(45,27),
             (41,34),(34,35),(28,28)], "coal")
    poly(d, [(32,18),(36,16),(40,18),(42,22),(41,27),(37,29),
             (32,27),(31,23)], "light")
    rect(d, (32,20,35,20), "coal")
    rect(d, (38,20,40,20), "coal")
    rect(d, (33,22,34,22), "ink")
    rect(d, (39,22,40,22), "ink")
    rect(d, (36,22,36,25), "white")
    poly(d, [(31,25),(34,27),(37,26),(40,25),(44,28),(45,35),
             (41,38),(39,44),(35,40),(31,37),(29,31)], "white")
    for pts in [[(31,29),(33,29),(34,35),(32,35)],
                [(37,30),(39,28),(39,36),(37,40),(36,37)],
                [(42,28),(44,30),(43,35),(41,36)]]:
        poly(d, pts, "silver")
    rect(d, (35,28,39,28), "coal")
    poly(d, [(29,17),(28,12),(29,8),(33,11),(36,5),(39,10),
             (44,8),(43,17)], "ink")
    poly(d, [(31,15),(31,11),(33,13),(36,9),(38,13),(42,11),(41,15)], "silver")
    rect(d, (31,15,41,16), "light")
    # Front ring crosses the seated robe, retaining a complete human-and-prop form.
    front = [(4,77),(12,78),(28,72),(47,63),(64,55),(75,47)]
    d.line(front, fill=PAL["ink"], width=7, joint="curve")
    d.line(front, fill=PAL["silver"], width=4, joint="curve")
    d.line([(5,76),(12,76),(28,70),(47,61),(63,53),(74,46)], fill=PAL["white"], width=1)
    return image


def painted_rock_surface():
    image, d = canvas(64, 64, opaque=True)
    # Fully opaque material, with no cutout edge or hidden holes in BoxMesh faces.
    for pts in [[(-7,-1),(2,-1),(9,10),(11,20),(18,29),(17,43),(25,57),
                 (26,65),(17,65),(12,52),(8,43),(9,31),(3,21),(2,12)],
                [(23,-1),(29,-1),(29,11),(35,23),(34,34),(43,46),(43,58),
                 (49,65),(39,65),(36,55),(37,47),(29,36),(29,25),(24,13)],
                [(50,-1),(58,-1),(55,12),(58,24),(55,36),(62,47),(68,56),
                 (68,65),(60,65),(56,54),(52,48),(50,38),(53,27),(50,14)]]:
        poly(d, pts, "white")
    for pts in [[(4,-1),(8,-1),(14,10),(16,23),(22,31),(22,44),(29,55),
                 (31,65),(26,65),(23,55),(17,44),(18,33),(12,24),(10,12)],
                [(30,-1),(34,-1),(35,12),(41,25),(40,37),(47,44),(49,58),
                 (54,65),(49,65),(45,58),(44,48),(36,39),(37,26),(31,14)],
                [(59,-1),(63,-1),(61,12),(64,25),(62,36),(67,45),(67,55),
                 (63,52),(57,39),(58,27),(56,14)]]:
        poly(d, pts, "mid")
    for pts in [[(11,-1),(14,-1),(18,14),(18,26),(25,37),(23,47),
                 (32,62),(32,65),(29,65),(21,53),(19,47),(21,37),(15,26),(15,13)],
                [(38,-1),(41,-1),(42,13),(47,23),(45,36),(52,47),
                 (53,58),(59,65),(55,65),(49,58),(49,48),(42,38),(43,24),(39,13)]]:
        poly(d, pts, "coal")
    # Broad chips/overlapping painted ledges, sparse instead of uniform dithering.
    for pts in [[(6,15),(11,17),(12,21),(8,20)], [(12,34),(16,35),(17,39),(13,38)],
                [(18,53),(22,56),(23,61),(20,59)], [(27,6),(30,7),(30,10),(27,10)],
                [(33,29),(37,32),(36,35),(32,32)], [(38,49),(42,50),(42,54),(38,53)],
                [(52,19),(56,20),(55,24),(52,23)], [(56,43),(60,45),(61,48),(58,47)]]:
        poly(d, pts, "light")
    for pts in [[(3,24),(7,26),(8,28),(3,27)], [(17,30),(21,32),(20,34),(16,32)],
                [(27,42),(31,44),(30,47),(26,45)], [(46,15),(49,17),(48,19),(45,17)],
                [(45,55),(49,57),(48,60),(44,58)]]:
        poly(d, pts, "shade")
    return image


SPECS = [
    ("earth_globe.png",earth_globe,(32,32),0.024,"centre_scenic_attachment","static_globe_component",["E08","P11","C19","O42"],["G09","G17","G24","A09","A10"],"celestial_globe_P11",False),
    ("human_star_performer.png",human_star,(32,32),0.020,"centre_scenic_attachment","static_human_face",["E08","P11","C15","O39"],["G09","G17","A10"],"human_faced_stars_C15",False),
    ("saturn_performer.png",saturn_performer,(40,96),0.024,"bottom_centre_scenic_composite","static_seated_performer",["E08","P11","C17","O41"],["G09","G17","G24","A09","F08"],"ringed_performer_C17",False),
    ("painted_rock_surface.png",painted_rock_surface,(32,32),0.024,"surface_uv_centre","opaque_static_surface",["E06","E07","P10","O34"],["G15","G17","G24"],"lunar_painted_rock_material",True),
]
SOURCE_PATHS = {
    "G09":"docs/concept-art/act1/characters/celestial-performers.png",
    "G15":"docs/concept-art/act1/props/lunar-grotto-and-court-modular-kit.png",
    "G17":"docs/concept-art/act1/environments/02-crater-gardens.png",
    "G24":"docs/concept-art/act1/gameplay/01-crater-gardens-gameplay.png",
    "A09":"docs/reference-library/act1/film-stills/a09.jpg",
    "A10":"docs/reference-library/act1/film-stills/a10.jpg",
    "F08":"docs/reference-library/act1/film-stills/f08.jpg",
}


def digest(path):
    return sha256(path.read_bytes()).hexdigest()


def review_sheet(images):
    sheet = Image.new("RGB", (760,665), (31,31,31))
    d = ImageDraw.Draw(sheet)
    font = ImageFont.load_default()
    d.text((16,12), "LUNAR ACCENTS / ORIGINAL NATIVE PIXELS / NEAREST 3x / UNBOUND", fill=(231,231,231),font=font)
    for (name,image),(x,y) in zip(images.items(),[(16,48),(232,48),(448,48),(16,350)]):
        w,h=image.size
        d.rectangle((x,y,x+w*3-1,y+h*3-1),fill=(89,89,89))
        d.rectangle((x+w*3//2,y,x+w*3-1,y+h*3-1),fill=(48,48,48))
        large=image.resize((w*3,h*3),Image.Resampling.NEAREST)
        sheet.paste(large,(x,y),large)
        d.text((x,y+h*3+4),name,fill=(231,231,231),font=font)
    d.text((232,366), "Opaque surface only: preserve the existing full BoxMesh.",fill=(193,193,193),font=font)
    d.text((232,387), "Celestial cutouts: friendly static scenery, no gameplay cue.",fill=(193,193,193),font=font)
    d.text((232,408), "Whole sprites need owner framing and portrait review.",fill=(193,193,193),font=font)
    sheet.save(OUT/"lunar_accents_contact_sheet.png")


def main():
    sources={key:{"id":key,"path":path,"sha256":digest(ROOT/path),
                  "kind":"generated_game_concept" if key.startswith("G") else ("1902_production_tableau_local_reference" if key.startswith("A") else "1902_film_frame_local_reference"),
                  "pixel_use":"none; visually inspected only"} for key,path in SOURCE_PATHS.items()}
    images,records={},[]
    for name,builder,pivot,scale,pivot_role,state,ids,refs,family,opaque in SPECS:
        image=builder()
        raw=image.tobytes()
        assert set(raw[3::4])==({255} if opaque else {0,255})
        assert all(r==g==b for r,g,b,a in zip(raw[0::4],raw[1::4],raw[2::4],raw[3::4]) if a)
        image.save(OUT/name)
        images[name]=image
        bounds=image.getchannel("A").getbbox()
        records.append({"id":"ACT1-LUNAR-ACCENT-"+name.removesuffix(".png").upper().replace("_","-"),
                        "file":name,"sha256":digest(OUT/name),"native_grid":list(image.size),
                        "pivot_pixels":list(pivot),"pivot_role":pivot_role,"pixel_size_tentative":scale,
                        "quad_world_size_tentative":[round(image.width*scale,6),round(image.height*scale,6)],
                        "opaque_extent_pixels_exclusive":list(bounds),"fully_opaque":opaque,
                        "role":"existing_boxmesh_surface" if opaque else "friendly_nonhostile_celestial_scenery",
                        "state":state,"reuse_family":family,"canonical_basis_ids":ids,
                        "source_provenance":[sources[key] for key in refs],"collision":"none; never replaces or rescales physics",
                        "occlusion":"ordinary scenic depth; keep full actor/source/landing/opening sightlines readable",
                        "cue":"none","damage":"none","clock_or_animation":"none; one static texture",
                        "runtime_readiness":READY,"authorship":"original hand-specified integer geometry; no reference pixels/crops/edits/tracing"})
    assert len({r["sha256"] for r in records})==4
    review_sheet(images)
    manifest={"schema_version":1,"family":"act1_lunar_celestial_accents_and_opaque_rock_surface",
              "created_date":"2026-10-08","first_level":"A1-L2","runtime_readiness":READY,
              "generator":"build_lunar_accents.py","generator_sha256":digest(Path(__file__)),
              "notes":"LUNAR_ACCENTS_NOTES.md","notes_sha256":digest(OUT/"LUNAR_ACCENTS_NOTES.md"),
              "palette":{k:list(v) for k,v in PAL.items()},"palette_basis":"existing seven launch/rusher/lunar object grays",
              "source_provenance":list(sources.values()),"source_records":[{"path":p,"sha256":digest(ROOT/p)} for p in [
                  "docs/concept-art/act1/generated-manifest.json","docs/reference-library/act1/commons-manifest.json",
                  "docs/reference-library/act1/research/entities.json","docs/reference-library/act1/objects-earth-and-dream.json"]],
              "assets":records,"preview":{"file":"lunar_accents_contact_sheet.png","sha256":digest(OUT/"lunar_accents_contact_sheet.png"),"role":"review_only_nearest3x_with_labels_and_background"},
              "limits":{"runtime_bound":False,"portrait_validated":False,"engine_jobs_run":False,
                        "earth":"O42/C19 globe component only; no new character/mythological identity and no complete bearer pose supplied",
                        "stars":"one anonymous C15 face-in-star figure, not C18 twin-star composition or an authenticated likeness/count arrangement",
                        "saturn":"C17 human-and-ring scenic composite; no scepter/weapon, hostile role or motion",
                        "surface":"fully opaque 64x64 material for existing full low BoxMesh; not a cutout, collision mask, floor/hazard texture or seamless atlas claim"}}
    (OUT/"lunar_accents_manifest.json").write_text(json.dumps(manifest,indent=2)+"\n")
    print("Produced three original hard-alpha celestial cutouts and one fully opaque 64x64 painted-rock material; unbound/unverified.")


if __name__=="__main__":
    main()
