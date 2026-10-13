"""Seven original lunar theatre cutouts; no source pixels, edits or crops.

Python/Pillow only. Writes PNGs, manifest and review sheet in this directory.
All polygons are hand specified; no randomness, runtime clock or cue geometry.
"""
from hashlib import sha256
import json
from pathlib import Path

from PIL import Image, ImageDraw, ImageFont

OUT = Path(__file__).resolve().parent
ROOT = OUT.parents[4]
PAL = {
    "ink": (20, 20, 20, 255), "coal": (39, 39, 39, 255),
    "shade": (67, 67, 67, 255), "mid": (105, 105, 105, 255),
    "silver": (147, 147, 147, 255), "light": (193, 193, 193, 255),
    "white": (231, 231, 231, 255),
    "floor_low": (112, 112, 112, 255), "floor": (115, 115, 115, 255),
    "floor_soft": (119, 119, 119, 255), "floor_high": (123, 123, 123, 255),
}
READY = "produced_pixels_not_runtime_bound_or_portrait_validated"


def canvas(w, h):
    image = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    return image, ImageDraw.Draw(image)


def poly(draw, points, color):
    draw.polygon(points, fill=PAL[color])


def rect(draw, bounds, color):
    draw.rectangle(bounds, fill=PAL[color])


def rock_a():
    image, d = canvas(96, 56)
    poly(d, [(2,55),(5,42),(12,44),(10,34),(18,26),(23,30),(28,16),
             (35,22),(43,5),(48,11),(50,25),(57,18),(62,28),(65,21),
             (70,35),(76,29),(83,41),(89,40),(94,55)], "ink")
    poly(d, [(5,54),(10,43),(16,46),(15,35),(20,31),(24,35),(31,23),
             (36,29),(44,12),(46,23),(49,31),(57,23),(63,37),(67,30),
             (73,42),(77,35),(83,46),(88,45),(92,54)], "silver")
    # Broad irregular brush streaks follow each fold; not repeating triangles.
    for pts in [[(18,31),(20,32),(24,40),(22,50),(17,43)],
                [(29,24),(32,22),(35,34),(40,39),(39,49),(33,42)],
                [(43,12),(45,15),(43,30),(49,34),(50,44),(44,40),(40,31)],
                [(56,23),(59,28),(61,38),(66,43),(65,48),(59,42),(55,31)],
                [(76,36),(80,39),(81,47),(87,52),(78,50),(74,43)]]:
        poly(d, pts, "white")
    for pts in [[(8,46),(13,48),(14,54),(7,54)], [(24,37),(27,33),(29,45),(26,52),(23,46)],
                [(35,30),(38,29),(41,41),(39,50),(36,43)], [(50,30),(53,29),(55,40),(53,49),(50,44)],
                [(66,34),(69,36),(73,48),(69,54),(67,45)], [(85,47),(89,46),(91,54),(87,54)]]:
        poly(d, pts, "coal")
    poly(d, [(11,51),(19,50),(27,53),(36,50),(43,52),(51,50),(61,53),(70,51),(82,54),(88,53),(93,55),(3,55)], "mid")
    for x,y in [(14,48),(32,45),(44,45),(59,46),(73,48),(84,50)]:
        rect(d, (x,y,x+2,y+1), "light")
    # Chipped paint and offset ledges break up the large triangular rock faces.
    for pts in [[(18,37),(21,36),(23,40),(21,40)],
                [(32,29),(34,32),(33,37),(32,35)],
                [(44,20),(45,20),(45,25),(43,27)],
                [(46,35),(49,37),(48,39),(46,38)],
                [(58,32),(60,34),(60,38),(58,36)],
                [(76,42),(78,42),(79,46),(77,45)]]:
        poly(d, pts, "light")
    for pts in [[(20,43),(24,45),(23,46),(19,44)],
                [(34,39),(37,41),(36,43),(33,41)],
                [(43,31),(46,33),(45,35),(42,33)],
                [(59,39),(63,41),(62,43),(58,41)]]:
        poly(d, pts, "shade")
    return image


def rock_b():
    image, d = canvas(96, 56)
    poly(d, [(1,55),(6,44),(12,38),(15,42),(21,31),(27,35),(33,17),
             (38,21),(41,35),(46,27),(52,32),(61,14),(66,20),(69,31),
             (75,26),(82,38),(88,34),(94,47),(95,55)], "ink")
    poly(d, [(4,54),(13,42),(17,47),(24,36),(30,42),(34,23),(37,30),
             (41,42),(47,33),(53,39),(62,21),(65,29),(69,40),(75,32),
             (83,46),(88,40),(92,49),(93,54)], "silver")
    for pts in [[(12,42),(16,44),(18,50),(13,52),(9,48)], [(24,36),(26,38),(31,47),(26,50),(22,43)],
                [(34,23),(36,26),(35,37),(41,44),(40,50),(34,44),(31,36)],
                [(62,21),(64,24),(61,34),(68,42),(66,49),(60,43),(57,34)],
                [(75,32),(78,37),(78,43),(84,49),(81,52),(74,47),(71,40)]]:
        poly(d, pts, "white")
    for pts in [[(18,45),(21,43),(22,52),(17,54)], [(39,36),(42,34),(46,47),(43,53),(40,46)],
                [(48,36),(51,36),(55,48),(52,53),(49,46)], [(66,29),(69,33),(72,46),(69,52),(66,43)],
                [(86,43),(89,44),(92,54),(87,52)]]:
        poly(d, pts, "coal")
    poly(d, [(4,53),(13,52),(25,54),(32,50),(40,53),(49,51),(58,54),(70,51),(82,53),(94,55),(1,55)], "mid")
    for x,y in [(7,49),(27,46),(37,47),(53,48),(64,49),(80,49)]:
        rect(d, (x,y,x+3,y), "light")
    for pts in [[(34,31),(36,34),(35,39),(33,37)],
                [(62,27),(63,27),(63,32),(61,34)],
                [(62,38),(65,40),(64,43),(61,41)],
                [(74,39),(77,42),(77,46),(75,44)]]:
        poly(d, pts, "light")
    for pts in [[(24,41),(28,43),(27,45),(23,43)],
                [(35,41),(39,43),(38,45),(34,43)],
                [(59,35),(61,37),(60,39),(57,37)],
                [(75,46),(78,48),(77,50),(73,48)]]:
        poly(d, pts, "shade")
    return image


def floor_tile():
    image, d = canvas(64, 64)
    # A quiet overlay tile over the owner's continuous silver floor. Transparent
    # two-pixel surround is not a physical gap or a square outlined floor slab.
    rect(d, (2,2,61,61), "floor")
    for pts in [[(3,10),(13,8),(23,10),(24,12),(15,12),(5,13)],
                [(38,5),(49,7),(59,6),(61,8),(49,9),(40,8)],
                [(18,27),(26,25),(33,26),(36,28),(29,29),(21,29)],
                [(42,37),(53,34),(61,35),(61,37),(52,38),(45,40)],
                [(4,51),(15,50),(21,52),(18,54),(7,54)],
                [(32,56),(44,54),(55,55),(57,58),(43,58),(35,59)]]:
        poly(d, pts, "floor_soft")
    for bounds in [(8,19,12,20),(31,13,35,13),(49,22,54,23),(13,36,16,37),
                   (28,43,33,44),(7,59,10,59),(47,48,51,49)]:
        rect(d, bounds, "floor_low")
    for bounds in [(17,10,21,10),(26,27,29,27),(48,36,52,36),(11,52,14,52)]:
        rect(d, bounds, "floor_high")
    # No craters/rings, perimeter marks, arrows, stars, holes or warning graphics.
    return image


def capsule():
    image, d = canvas(128, 88)
    # Original broad 3/4 landed view of O09/O10/O36; intact closed rear disc.
    poly(d, [(23,17),(80,21),(97,26),(109,34),(120,45),(125,54),
             (122,64),(111,73),(94,78),(23,77)], "ink")
    poly(d, [(24,20),(79,24),(96,29),(107,37),(116,47),(122,54),
             (119,62),(109,70),(93,74),(24,74)], "silver")
    poly(d, [(25,21),(78,25),(94,29),(106,38),(113,46),(81,37),(27,34)], "light")
    poly(d, [(25,24),(54,26),(74,27),(92,32),(98,36),(71,32),(44,31),(26,29)], "white")
    poly(d, [(28,48),(62,52),(83,56),(108,56),(118,54),(117,64),
             (102,71),(83,72),(27,70)], "shade")
    poly(d, [(29,59),(61,62),(82,65),(104,64),(99,69),(81,70),(30,68)], "coal")
    # Three curved binding bands and sparse hand-placed rivets carry metal form.
    for x in (46,72,94):
        poly(d, [(x,23),(x+3,24),(x+5,37),(x+4,55),(x+1,74),(x-2,73),(x+1,54),(x+2,37)], "ink")
        d.line([(x+2,25),(x+4,38),(x+3,54),(x,71)], fill=PAL["light"], width=1)
        for y in (29,42,58,68):
            rect(d, (x+1,y,x+2,y+1), "silver")
    for x,y in [(34,38),(58,40),(82,43),(108,48),(36,57),(60,60),(84,62),(104,58)]:
        rect(d, (x,y,x+1,y+1), "coal")
        rect(d, (x,y,x,y), "light")
    d.ellipse((3,17,40,78), fill=PAL["ink"])
    d.ellipse((5,19,37,75), fill=PAL["light"])
    d.ellipse((8,23,34,72), fill=PAL["silver"])
    d.ellipse((11,28,31,66), fill=PAL["coal"])
    d.ellipse((13,30,29,64), fill=PAL["mid"])
    poly(d, [(14,32),(24,31),(27,40),(25,51),(18,58),(14,55)], "silver")
    rect(d, (23,43,28,46), "coal")
    rect(d, (25,44,28,44), "light")
    for x,y in [(20,23),(10,31),(7,44),(9,61),(20,70),(31,60),(34,43),(30,29)]:
        rect(d, (x,y,x+1,y+1), "coal")
        rect(d, (x,y,x,y), "white")
    # Broad uneven rock shoulders cradle the shell; no triangular landing fins.
    for pts in [[(5,87),(7,83),(13,83),(14,79),(19,80),(23,78),
                 (30,79),(33,82),(40,82),(45,87)],
                [(79,87),(81,83),(85,83),(87,80),(93,81),(98,79),
                 (105,80),(108,83),(114,83),(117,87)]]:
        poly(d, pts, "ink")
    poly(d, [(9,86),(10,85),(16,84),(17,81),(21,83),(25,81),
             (30,82),(32,85),(38,84),(41,86)], "silver")
    poly(d, [(83,86),(86,84),(89,82),(94,84),(99,81),(104,82),
             (108,85),(113,85),(114,86)], "silver")
    poly(d, [(17,82),(19,82),(20,85),(18,86),(15,85)], "white")
    poly(d, [(25,81),(27,82),(29,85),(25,84)], "light")
    poly(d, [(89,83),(92,84),(91,86),(87,85)], "white")
    poly(d, [(100,82),(102,83),(103,85),(100,85)], "light")
    for bounds in [(22,84,24,85),(32,85,34,86),(95,85,98,86),(106,84,107,85)]:
        rect(d, bounds, "coal")
    return image


def sleeper(d, x, y, reversed=False):
    # Anonymous O38 expedition costume scenery; no named likeness or loadout.
    face_x = x+40 if reversed else x+8
    poly(d, [(x,y+5),(x+12,y),(x+39,y+3),(x+51,y+10),(x+50,y+16),(x,y+16)], "ink")
    poly(d, [(x+2,y+6),(x+13,y+3),(x+37,y+5),(x+47,y+11),(x+46,y+14),(x+2,y+14)], "silver")
    poly(d, [(x+8,y+5),(x+13,y+4),(x+20,y+7),(x+32,y+6),(x+41,y+10),
             (x+37,y+12),(x+25,y+10),(x+16,y+11)], "light")
    for dx in (17,29,38):
        poly(d, [(x+dx,y+6),(x+dx+2,y+7),(x+dx-1,y+12),(x+dx-3,y+13)], "shade")
    d.ellipse((face_x-5,y-1,face_x+5,y+8), fill=PAL["light"])
    rect(d, (face_x-2,y+2,face_x+2,y+2), "coal")
    poly(d, [(face_x-4,y+5),(face_x,y+6),(face_x+5,y+4),(face_x+5,y+9),
             (face_x+1,y+12),(face_x-3,y+10)], "white")
    poly(d, [(face_x-7,y),(face_x-5,y-5),(face_x+4,y-5),(face_x+7,y),
             (face_x+8,y+2),(face_x-8,y+2)], "ink")
    rect(d, (face_x-4,y-4,face_x+3,y-3), "mid")


def camp():
    image, d = canvas(128, 80)
    # G17 cloth camp, folded into one static P11/O38 nonhostile vignette.
    for x in (16,58,110):
        rect(d, (x,23,x+2,67), "coal")
        rect(d, (x,23,x,64), "silver")
    poly(d, [(14,30),(53,9),(60,12),(69,19),(111,29),(109,51),(85,45),
             (64,40),(38,45),(14,51)], "ink")
    poly(d, [(16,30),(53,12),(59,16),(67,23),(108,30),(106,47),(82,41),
             (63,36),(39,41),(17,47)], "light")
    poly(d, [(18,32),(50,18),(52,21),(37,37),(19,42)], "white")
    poly(d, [(62,18),(69,25),(102,31),(87,34),(68,30)], "white")
    for pts in [[(53,15),(56,16),(53,34),(47,39),(46,34)],
                [(60,18),(63,22),(65,36),(61,35)], [(73,27),(78,29),(83,40),(79,39)],
                [(100,32),(103,32),(101,44),(96,42)]]:
        poly(d, pts, "mid")
    # Soft hanging canvas flaps and broad creases, without a decorative pulse.
    poly(d, [(18,45),(39,39),(46,42),(42,60),(33,64),(21,62)], "silver")
    poly(d, [(76,40),(86,43),(106,47),(104,64),(91,64),(83,57)], "light")
    for pts in [[(25,46),(29,44),(27,60),(24,60)], [(36,43),(39,42),(36,60),(33,62)],
                [(88,47),(92,48),(96,61),(93,63)], [(100,48),(103,49),(101,62),(98,62)]]:
        poly(d, pts, "mid")
    sleeper(d, 4, 63)
    sleeper(d, 69, 62, True)
    return image


def crescent():
    image, d = canvas(64, 112)
    poly(d, [(3,36),(7,57),(15,70),(25,78),(35,80),(47,74),(56,61),(61,34),
             (54,50),(44,61),(33,65),(23,62),(13,51)], "ink")
    poly(d, [(5,40),(9,57),(18,70),(26,75),(35,77),(46,72),(54,60),(58,44),
             (52,53),(43,64),(33,68),(23,65),(12,53)], "silver")
    poly(d, [(6,42),(10,56),(18,66),(26,71),(33,72),(41,69),(49,61),
             (53,58),(48,67),(40,73),(33,75),(23,71),(14,62)], "white")
    # Seated human performer and draped gown; C16 remains scenic, not attackable.
    poly(d, [(25,25),(31,24),(37,27),(43,38),(47,48),(40,57),(29,56),(22,45)], "ink")
    poly(d, [(26,27),(31,27),(36,30),(40,40),(43,47),(38,53),(30,53),(25,45)], "white")
    poly(d, [(25,32),(21,32),(17,23),(12,17),(9,18),(14,28),(18,37),(25,39)], "ink")
    poly(d, [(25,33),(22,34),(18,25),(12,20),(11,20),(16,29),(19,35),(25,37)], "light")
    poly(d, [(37,32),(41,34),(45,40),(53,43),(55,46),(51,48),(43,44),(37,40)], "ink")
    poly(d, [(38,34),(40,36),(44,42),(52,45),(52,46),(44,43),(38,39)], "light")
    poly(d, [(26,46),(32,49),(42,46),(48,56),(46,75),(41,84),(42,101),
             (37,111),(23,111),(21,103),(24,82),(19,64),(20,54)], "ink")
    poly(d, [(26,48),(32,52),(42,49),(45,57),(43,74),(38,83),(39,101),
             (35,108),(25,108),(24,102),(27,82),(22,64),(23,55)], "light")
    for pts in [[(26,51),(28,53),(26,66),(29,78),(27,91),(25,103),(25,83),(23,65)],
                [(36,53),(39,52),(37,66),(33,77),(32,104),(29,106),(30,78),(34,65)],
                [(41,54),(43,58),(40,73),(35,81),(36,98),(33,106),(33,82),(38,72)]]:
        poly(d, pts, "white")
    for pts in [[(29,54),(31,55),(30,65),(32,73),(29,87),(29,101),(27,103),(27,84),(30,73)],
                [(39,57),(41,56),(38,68),(35,74),(36,81),(33,91),(34,77),(33,73),(36,65)]]:
        poly(d, pts, "mid")
    poly(d, [(25,14),(28,9),(35,10),(39,15),(38,22),(34,27),(28,25),(25,20)], "ink")
    poly(d, [(28,14),(31,12),(35,14),(37,17),(35,23),(32,25),(28,22)], "light")
    rect(d, (29,17,31,17), "coal")
    rect(d, (33,21,35,21), "mid")
    rect(d, (28,13,30,14), "white")
    poly(d, [(26,15),(26,11),(29,7),(34,7),(38,12),(37,16),(34,12),(31,11),(28,15)], "coal")
    # A small sewn crown belongs to the costume, not the actionable cue family.
    poly(d, [(28,9),(28,5),(31,8),(33,3),(35,8),(38,6),(36,11)], "silver")
    rect(d, (30,9,35,10), "light")
    return image


def threshold():
    image, d = canvas(144, 96)
    poly(d, [(2,95),(4,71),(9,64),(6,53),(13,40),(17,33),(15,24),(27,20),
             (35,13),(48,17),(58,8),(73,5),(86,11),(97,8),(106,20),(117,22),
             (124,32),(133,33),(131,45),(139,58),(136,76),(142,95)], "ink")
    poly(d, [(5,95),(7,73),(13,66),(10,54),(17,42),(22,36),(21,28),(30,26),
             (38,20),(49,23),(61,14),(72,12),(85,17),(96,15),(103,25),(114,28),
             (119,37),(127,39),(125,47),(134,59),(131,77),(138,95)], "silver")
    for pts in [[(10,74),(16,70),(18,51),(25,44),(30,34),(25,35),(19,41),(13,54)],
                [(31,27),(38,23),(46,28),(54,25),(59,19),(66,16),(59,27),(48,34),(39,33)],
                [(70,15),(77,15),(87,23),(99,24),(101,30),(86,28),(77,22)],
                [(107,29),(113,31),(115,40),(125,45),(127,53),(119,49),(111,42)],
                [(128,60),(131,65),(126,76),(132,88),(133,94),(126,93),(121,79),(124,68)]]:
        poly(d, pts, "white")
    for pts in [[(18,62),(21,50),(29,45),(27,54),(25,72),(17,82)],
                [(33,29),(36,26),(41,33),(38,40),(32,44),(34,36)],
                [(62,17),(65,16),(68,25),(62,30),(59,27)], [(89,20),(94,19),(99,30),(97,37),(91,30)],
                [(116,45),(120,48),(123,60),(118,71),(115,65)], [(132,78),(136,77),(137,93),(132,93)]]:
        poly(d, pts, "coal")
    # Scalloped organic mouth; fully transparent aperture and floor baseline.
    opening = [(30,96),(32,59),(38,48),(45,44),(50,36),(61,35),(67,29),
               (78,30),(84,36),(94,37),(99,44),(108,48),(113,60),(114,96)]
    d.polygon(opening, fill=(0,0,0,0))
    # A few porous-edge creases, no spore pods, border pulse or court columns.
    for x,y,w,h in [(15,79,4,7),(22,37,4,6),(48,26,5,4),(109,35,4,5),(126,79,4,7)]:
        d.ellipse((x,y,x+w,y+h), fill=PAL["shade"])
        d.line([(x,y+1),(x+1,y+h-1)], fill=PAL["light"], width=1)
    return image


SPECS = [
    ("rock_flat_low_a.png",rock_a,(48,56),0.024,"grounded_scenic_edge",["E06","E07","P10","O34"],["G15","G17","G24","F07"],"static", "lunar_painted_rock_flats"),
    ("rock_flat_low_b.png",rock_b,(48,56),0.024,"grounded_scenic_edge",["E06","E07","P10","O34"],["G15","G17","G24","F07"],"static", "lunar_painted_rock_flats"),
    ("floor_silver_tile.png",floor_tile,(32,32),0.024,"ground_plane_overlay",["E06","E07","P10","O35"],["G15","G17","G24","F07"],"quiet_static", "lunar_quiet_silver_floor"),
    ("capsule_landed_closed.png",capsule,(64,88),0.028,"grounded_scenic_landmark",["E06","P10","O09","O10","O36"],["G14","G17","G24","F07"],"closed", "finless_capsule_O09"),
    ("camp_sleeping_tableau.png",camp,(64,80),0.026,"nonhostile_grounded_vignette",["E08","P11","O38"],["G17","F08"],"sleeping_static", "lunar_celestial_camp_P11"),
    ("crescent_performer.png",crescent,(32,112),0.026,"nonhostile_celestial_scenery",["E08","P11","C16","O40"],["G09","G17","G24","F08"],"seated_static", "celestial_crescent_C16"),
    ("grotto_threshold_open.png",threshold,(72,96),0.04,"open_scenic_threshold",["P10","P12","O34","O47","O48"],["G15","G17","F09"],"open", "lunar_grotto_scenic_edge"),
]
SOURCE_PATHS = {
    "G09":"docs/concept-art/act1/characters/celestial-performers.png",
    "G14":"docs/concept-art/act1/props/earth-launch-modular-kit.png",
    "G15":"docs/concept-art/act1/props/lunar-grotto-and-court-modular-kit.png",
    "G17":"docs/concept-art/act1/environments/02-crater-gardens.png",
    "G24":"docs/concept-art/act1/gameplay/01-crater-gardens-gameplay.png",
    "F07":"docs/reference-library/act1/film-stills/f07.jpg",
    "F08":"docs/reference-library/act1/film-stills/f08.jpg",
    "F09":"docs/reference-library/act1/film-stills/f09.jpg",
}


def digest(path):
    return sha256(path.read_bytes()).hexdigest()


def make_sheet(images):
    sheet = Image.new("RGB", (920,1030), (31,31,31))
    d = ImageDraw.Draw(sheet)
    font = ImageFont.load_default()
    d.text((16,12), "A1-L2 LUNAR THEATRE / ORIGINAL PIXELS / NEAREST 3x REVIEW / UNBOUND", fill=(231,231,231),font=font)
    positions = [(16,48),(324,48),(634,48),(16,280),(434,280),(16,610),(360,650)]
    for (name,image), (x,y) in zip(images.items(),positions):
        w,h = image.size
        d.rectangle((x,y,x+w*3-1,y+h*3-1),fill=(89,89,89))
        d.rectangle((x+w*3//2,y,x+w*3-1,y+h*3-1),fill=(48,48,48))
        preview = image.resize((w*3,h*3),Image.Resampling.NEAREST)
        sheet.paste(preview,(x,y),preview)
        d.text((x,y+h*3+4), name, fill=(231,231,231),font=font)
    sheet.save(OUT/"environment_contact_sheet.png")


def main():
    sources = {key:{"id":key,"path":path,"sha256":digest(ROOT/path),
                    "kind":"generated_game_concept" if key.startswith("G") else "1902_film_frame_local_reference",
                    "pixel_use":"none; visually inspected only"} for key,path in SOURCE_PATHS.items()}
    records, images = [], {}
    for name,builder,pivot,scale,role,ids,refs,state,family in SPECS:
        image = builder()
        raw = image.tobytes()
        assert set(raw[3::4]) == {0,255}
        assert all(r==g==b for r,g,b,a in zip(raw[0::4],raw[1::4],raw[2::4],raw[3::4]) if a)
        image.save(OUT/name)
        images[name] = image
        bounds = image.getchannel("A").getbbox()
        opaque_from_pivot = [round((bounds[0]-pivot[0])*scale,6),
                             round((pivot[1]-bounds[3])*scale,6),
                             round((bounds[2]-pivot[0])*scale,6),
                             round((pivot[1]-bounds[1])*scale,6)]
        records.append({"id":"ACT1-LUNAR-"+name.removesuffix(".png").upper().replace("_","-"),
                        "file":name,"sha256":digest(OUT/name),"native_grid":list(image.size),
                        "pivot_pixels":list(pivot),"pivot_role":"plane_centre" if role=="ground_plane_overlay" else "bottom_centre_scenic_anchor",
                        "pixel_size_tentative":scale,"quad_world_size_tentative":[round(image.width*scale,6),round(image.height*scale,6)],
                        "opaque_extent_pixels_exclusive":list(bounds),
                        "opaque_bounds_from_pivot_tentative":{"order":["left","bottom","right","top"],"values":opaque_from_pivot,"plane":"texture local X/up; floor overlay belongs on ground plane"},
                        "role":role,"state":state,"reuse_family":family,
                        "canonical_basis_ids":ids,"source_provenance":[sources[key] for key in refs],
                        "collision":"none; owner supplies verified physical floor/obstacles/contact geometry separately",
                        "occlusion":"ordinary scenic depth; owner must position beyond mandatory landing/attack sightlines",
                        "cue":"none; no actionable boundary, pulse, icon, hazard or bonus baked",
                        "clock_or_animation":"none; static texture only","runtime_readiness":READY,
                        "authorship":"original deterministic integer geometry; no source crops, edits, tracing or pixel samples"})
    assert len({rec["sha256"] for rec in records})==7
    make_sheet(images)
    manifest = {"schema_version":1,"family":"act1_lunar_theatre_environment","created_date":"2026-10-08",
                "first_level":"A1-L2","runtime_readiness":READY,"authorship":"original hand-specified Pillow pixel shapes",
                "generator":"build_environment_cutouts.py","generator_sha256":digest(Path(__file__)),
                "notes":"ENVIRONMENT_ART_NOTES.md","notes_sha256":digest(OUT/"ENVIRONMENT_ART_NOTES.md"),
                "palette":{k:list(v) for k,v in PAL.items()},"palette_basis":"seven launch/rusher object grays; four quiet floor grays112/115/119/123",
                "source_provenance":list(sources.values()),"source_records":[
                    {"path":p,"sha256":digest(ROOT/p)} for p in ["docs/concept-art/act1/generated-manifest.json","docs/reference-library/act1/commons-manifest.json","docs/reference-library/act1/research/entities.json","docs/reference-library/act1/objects-earth-and-dream.json","docs/reference-library/act1/objects-grotto-and-return.json"]],
                "assets":records,"preview":{"file":"environment_contact_sheet.png","sha256":digest(OUT/"environment_contact_sheet.png"),"role":"review_only_labels_and_background_nearest_3x"},
                "limits":{"runtime_bound":False,"portrait_validated":False,"engine_jobs_run":False,
                          "floor":"transparent-margin overlay on continuous base; not a seamless collision floor or outlined tile grid",
                          "threshold":"transparent mouth at baseline pixel x[30,115) exclusive, 85 pixels/tentative width3.40w; contact/traversal geometry remains owner responsibility",
                          "camp":"anonymous existing O38 sleepers; C16 celestial performer stays scenic and nonhostile",
                          "capsule":"closed 2D landed rendering of existing O09/O10/O36, not a new capsule type or hatch interaction"}}
    (OUT/"environment_manifest.json").write_text(json.dumps(manifest,indent=2)+"\n")
    print("Produced seven original hard-alpha lunar textures; runtime unbound, portrait unverified.")


if __name__=="__main__":
    main()
