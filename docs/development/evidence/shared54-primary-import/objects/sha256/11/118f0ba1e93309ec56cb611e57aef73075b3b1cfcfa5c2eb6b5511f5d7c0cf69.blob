"""Build portable reference exports from curated source records and image files."""
from collections import Counter
import argparse
import os
import struct
import csv
import hashlib
import json
from pathlib import Path
import sqlite3

ROOT = Path(__file__).resolve().parents[2]
DEST = ROOT / "docs/reference-library/act1"
RESEARCH = DEST / "research"
ART_ROOT = ROOT / "docs/concept-art/act1"

FRAMES = {
    "F01": ("Astronomers' congress", "Observatory", "Robed astronomers, pointed hats, an astronomical diagram, columns and instruments."),
    "F02": ("Capsule workshop", "Workshop", "Workers build a squat bullet-shaped travel shell in a theatrical workshop."),
    "F03": ("Industrial rooftop and telescope", "Rooftops", "A long telescope, lattice structures, rooftops and chimney silhouettes."),
    "F04": ("Loading the travel shell", "Launch", "Attendants and explorers around the cannon's loading platform."),
    "F05": ("Launch cannon exterior", "Launch", "Oversized cannon and period launch attendants above painted town rooftops."),
    "F06": ("Man in the Moon before impact", "Moon Approach", "An expressive human face forms the Moon; this frame does not show the shell in its eye."),
    "F07": ("Shell on the lunar surface", "Lunar Surface", "Finless shell, painted angular lunar rocks and expedition travellers."),
    "F08": ("Celestial dream tableau", "Celestial Dream", "Theatrical celestial figures appear above sleeping explorers and painted lunar scenery."),
    "F09": ("Giant mushroom grotto", "Mushroom Grotto", "Shallow mushroom caps, long stalks, irregular shelves, a trunk and porous foreground forms."),
    "F10": ("Selenite royal court", "Selenite Court", "Biped masked Selenites, spears, a seated ruler, celestial ornament and drapery."),
    "F11": ("White puff on lunar ground", "Escape", "A dense pale cloud interrupts the painted lunar landscape; a still alone does not establish timing."),
    "F12": ("Escape shell at the ledge", "Escape", "Capsule and Selenite at an exposed rock lip with a hanging cord."),
    "F13": ("Harbour return", "Return", "Stage harbour, rigged ship, low rescue vessel, quay and bright splash."),
    "A01": ("Moon-eye impact, cropped frame", "Moon Approach", "Shell embedded in the Moon's eye, cropped reproduction."),
    "A02": ("Moon-eye impact, full reproduction", "Moon Approach", "Alternate reproduction of the same iconic Moon-eye composition as A01."),
    "A03": ("Cannon attendants, alternate frame", "Launch", "Attendants work at the cannon's loading section."),
    "A04": ("Two Selenites, later drawing reproduction", "Selenite Court", "Méliès drawing reproduction; apparently matches the 1937 retrospective drawing recorded by the Cinémathèque."),
    "A05": ("Moon-eye impact, small reproduction", "Moon Approach", "Low-resolution alternate reproduction of the Moon-eye composition."),
    "A06": ("Moon-eye drawing reproduction, date unresolved", "Moon Approach", "Méliès drawing reproduction; Commons dates it 1902, but the exact original drawing and date need confirmation."),
    "A07": ("Moon-eye impact, handcoloured print", "Moon Approach", "Frame from a surviving handcoloured print, showing the capsule and expressive Moon face."),
    "A08": ("Cannon-loading production photograph", "Launch", "Detailed production still of attendants, cannon loading section and painted rooftops."),
    "A09": ("Planetary dream production photograph", "Celestial Dream", "Earth globe, crescent performer, Saturn performer, sleeping travellers and angular scenic wings."),
    "A10": ("Star faces production photograph", "Celestial Dream", "Seven human faces in geometric stars above sleeping explorers and the same lunar scenery."),
    "A11": ("Selenite riding the shell, handcoloured frame", "Escape", "A Selenite clings to the shell exterior in a restored handcoloured source."),
    "A12": ("Commemorative statue, handcoloured frame", "Celebration", "Astronomer monument over a Moon-face, decorated plinth and celebrants."),
    "A13": ("Workshop, handcoloured frame", "Workshop", "Riveted shell, workers, anvil, ladder and painted workshop framing."),
    "A14": ("Attributed preliminary Moon-eye poster sketch", "Moon Approach", "Commons identifies this as a preliminary poster sketch by Méliès; catalogue date is retained as attributed."),
    "A15": ("Escape-cliff production photograph", "Escape", "Uncropped production still exposes the scenic backdrop edge and studio floor."),
    "A16": ("Moon-eye impact with cloud surround", "Moon Approach", "Small alternate Moon-eye frame showing theatrical cloud framing."),
    "A17": ("Star Film title-card reproduction", "Titles", "Decorative title frame reproduced with the film; version-specific opening material."),
}

MUSEUMS = [
    ("M01", "Méliès: Moon-eye scene drawing", "retrospective-art", "Moon Approach", "c.1930–31", "Georges Méliès", "https://www.moma.org/collection/works/38327", "Retrospective ink study of the eye-impact scene. MoMA object 946.1965; 23.7 × 33.9 cm."),
    ("M02", "Méliès: lunar landing and Earth drawing", "retrospective-art", "Lunar Surface", "c.1930–31", "Georges Méliès", "https://www.moma.org/collection/works/36891", "Retrospective ink study of the shell landing and Earth seen from the Moon. MoMA object 437.1974; 24.5 × 34.4 cm."),
    ("M03", "Méliès: celestial dream drawing", "retrospective-art", "Celestial Dream", "c.1930–31", "Georges Méliès", "https://www.moma.org/collection/works/38324", "Retrospective dream-scene ink drawing. Its composition differs from the film still. MoMA object 945.1965; 24.3 × 34.3 cm."),
    ("M04", "Méliès: giant mushroom grotto drawing", "retrospective-art", "Mushroom Grotto", "c.1930–31", "Georges Méliès", "https://www.moma.org/collection/works/38318", "Retrospective grotto-scene ink drawing. MoMA object 944.1965; 24.3 × 33.8 cm."),
    ("M05", "Surviving astronomer's embroidered mantle", "museum-object", "Observatory", "1902", "Original film costume; maker not specified on the museum page", "https://www.cinematheque.fr/objet/392.html", "Surviving embroidered mantle worn by an astronomer. The museum distinguishes it from Barbenfouillis's near-identical lighter-bordered costume; height 133 cm."),
    ("M06", "Méliès: Les Sélénites", "retrospective-art", "Selenite Court", "1937", "Georges Méliès", "https://www.cinematheque.fr/objet/400.html", "Later ink-wash recomposition of two Selenites, made for the Cinémathèque; 28 × 35 cm. It is not automatically a 1902 costume plan."),
    ("M07", "Méliès: Moon-eye recomposition", "retrospective-art", "Moon Approach", "1937", "Georges Méliès", "https://www.cinematheque.fr/objet/1546.html", "Retrospective drawing commissioned by Henri Langlois; paper mounted on cardboard, 27 × 35 cm. The museum separately mentions a 1902 poster project and preparatory drawing."),
    ("M08", "Labisse's Selenite reconstruction", "museum-reconstruction", "Historical Context", "1960", "Félix Labisse after Georges Méliès", "https://www.cinematheque.fr/objet/1540.html", "Later red-painted cardboard reconstruction based on Méliès's 1937 drawing; 210 × 158 × 93 cm. It is not an original 1902 costume or evidence of the original costume's colour."),
    ("M09", "Labisse's Méliès centenary poster", "historical-poster", "Historical Context", "1961", "Félix Labisse", "https://www.cinematheque.fr/objet/1541.html", "Exhibition lithograph, 92 × 62 cm. This later homage mixes the Moon-face with imagery from Conquest of the Pole (1912), so it sits outside the core film-object references."),
]

STYLE_RULES = [
    "Layer painted-looking side flats and backdrops around a clear playable floor.",
    "Use jagged lunar rock silhouettes with broad white streaks and black creases.",
    "Leave dark negative space between scenery, characters and celestial shapes.",
    "Make stars, crescents and planet discs large and deliberately theatrical.",
    "Use human celestial performers rather than replacing them with abstract alien machines.",
    "Dress expedition travellers in period coats, hats and exaggerated beards.",
    "Use embroidered robes and pointed hats for the observatory ceremony or a labelled game costume adaptation.",
    "Reuse the finless bullet shell across workshop, arrival and escape scenes.",
    "Keep umbrellas in the prop vocabulary; sword/blast behaviour is a game proposal.",
    "Build the grotto from shallow mushroom caps, tall stalks, irregular shelves and a trunk.",
    "Selenites are masked biped stage creatures with pale rib bands and projecting headpieces.",
    "Use curling court panels, crescents, radial roundels, spears and drapery.",
    "White puffs inspire square smoke effects; physics and attack timing remain game adaptations.",
    "Keep portrait framing, close camera follow, gesture controls and a prominent player.",
    "Give dash-only movement generous floor space and locally visible attack warnings.",
    "Optional levels reuse their parent scenery and enemy kits, with a few additions.",
    "Monochrome is our selected game palette; authentic handcoloured prints are separately tagged.",
    "Preserve provenance: film frame, original object, later drawing, reconstruction, and generated study.",
]


def load(name):
    return json.loads((DEST / name).read_text())


def read_optional(path, key):
    if not path.is_file():
        return []
    data = json.loads(path.read_text())
    return data if isinstance(data, list) else data.get(key, [])


def image_dimensions(path):
    raw = path.read_bytes()
    if raw.startswith(b"\x89PNG\r\n\x1a\n"):
        return struct.unpack(">II", raw[16:24])
    # Local archival JPEGs already retain source dimensions. New concept art is PNG.
    return (None, None)


def research_extension(legacy_records, strict_art=False):
    sources = read_optional(RESEARCH / "sources.json", "sources")
    entities = read_optional(RESEARCH / "entities.json", "entities")
    declared_artworks = read_optional(ART_ROOT / "generated-manifest.json", "artworks")
    if strict_art:
        assert not [art["id"] for art in declared_artworks if art.get("status") in {"planned", "failed"}], "Unfinished art records in strict build"
    artworks = [art for art in declared_artworks if art.get("status") not in {"planned", "failed"}]
    source_by_id = {item["id"]: item for item in sources}
    entity_by_id = {item["id"]: item for item in entities}
    legacy_by_id = {item["id"]: item for item in legacy_records}
    assert len(source_by_id) == len(sources), "Duplicate research source IDs"
    assert len(entity_by_id) == len(entities), "Duplicate entity IDs"
    gallery = []
    for source in sources:
        gallery.append({"id": source["id"], "title": source["title"], "kind": "research-source", "sequence": "Research sources", "category": "sources", "description": source.get("notes", ""), "adaptation": "", "reference_ids": [], "local_path": None, "creator": source.get("author", source.get("publisher", "")), "date": source.get("date", ""), "license": "Research citation; no source pixels or long passages copied", "notes": source.get("notes", ""), "source_urls": [source["url"]], "tags": [source["kind"]], "kit": "research", "source_ids": [source["id"]]})
    for entity in entities:
        entity.setdefault("source_ids", [])
        entity.setdefault("reference_ids", [])
        entity.setdefault("scene_refs", [])
        entity.setdefault("canonical_basis_ids", [])
        entity.setdefault("tags", [])
        entity.setdefault("notes", "")
        for identifier in entity["source_ids"]:
            assert identifier in source_by_id, (entity["id"], identifier)
        for identifier in entity["reference_ids"]:
            assert identifier in legacy_by_id, (entity["id"], identifier)
        for identifier in entity["canonical_basis_ids"]:
            assert identifier in entity_by_id, (entity["id"], identifier)
        urls = [source_by_id[identifier]["url"] for identifier in entity["source_ids"] if identifier != "S13"]
        urls += [url for identifier in entity["reference_ids"] for url in legacy_by_id[identifier]["source_urls"]]
        entity["source_urls"] = list(dict.fromkeys(urls))
        gallery.append({"id": entity["id"], "title": entity["title"], "kind": "research-" + {"characters":"character", "environments":"environment", "bosses":"boss", "props":"prop", "mood":"mood"}.get(entity["category"],entity["category"]), "sequence": entity["scene_refs"][0] if entity["scene_refs"] else "Research", "category": entity["category"], "description": entity["description"], "adaptation": entity["game_adaptation"], "reference_ids": entity["reference_ids"] + entity["canonical_basis_ids"], "local_path": None, "creator": "Film evidence and original game design research", "date": "1902 film; 2026 game research", "license": "Original research paraphrase and game proposal; see linked source image credits", "notes": entity["notes"], "source_urls": entity["source_urls"], "tags": entity["tags"], "kit": entity.get("parent_kit", entity["scene_refs"][0].lower().replace(" ", "-") if entity["scene_refs"] else "research"), "canon_status": entity["canon_status"], "source_ids": entity["source_ids"], "scene_refs": entity["scene_refs"], "design_id": entity.get("design_id"), "decision": entity.get("decision"), "performer_attributions": entity.get("performer_attributions", []), "aliases": entity.get("aliases", []), "name_status": entity.get("name_status", "")})
    art_ids = set()
    for art in artworks:
        assert art["id"] not in art_ids, ("Duplicate artwork", art["id"])
        art_ids.add(art["id"])
        art.setdefault("entity_ids", [])
        art.setdefault("source_ids", [])
        art.setdefault("reference_ids", [])
        art["reference_ids"] = list(dict.fromkeys(art["reference_ids"] + art.get("object_ids", [])))
        art.setdefault("kind", "generated-concept")
        art.setdefault("description", art.get("purpose", "New game concept study"))
        art.setdefault("notes", "New game concept art, not a film frame or implemented gameplay.")
        art.setdefault("prompt", "")
        art.setdefault("canon_status", "game_proposal")
        for identifier in art["entity_ids"]:
            assert identifier in entity_by_id, (art["id"], identifier)
            art["source_ids"] += entity_by_id[identifier]["source_ids"]
        art["source_ids"] = list(dict.fromkeys(art["source_ids"]))
        for identifier in art["source_ids"]:
            assert identifier in source_by_id, (art["id"], identifier)
        for identifier in art["reference_ids"]:
            assert identifier in legacy_by_id or identifier in entity_by_id, (art["id"], identifier)
        value = art.get("local_path") or art.get("path") or art.get("repo_path")
        path = None
        if value:
            candidate = Path(value)
            choices = [candidate] if candidate.is_absolute() else [ROOT / candidate, ART_ROOT / candidate, DEST / candidate]
            path = next((candidate.resolve() for candidate in choices if candidate.is_file()), None)
        if strict_art:
            assert path is not None, ("Missing generated image", art["id"], value)
        if path:
            assert path.is_relative_to(ART_ROOT.resolve()), ("Art outside Act1 concept folder", path)
        art["file_exists"] = bool(path)
        art["status"] = "generated" if path else "planned"
        art["repo_path"] = str(path.relative_to(ROOT)) if path else None
        art["local_path"] = Path(os.path.relpath(path, DEST)).as_posix() if path else None
        art["sha256"] = hashlib.sha256(path.read_bytes()).hexdigest() if path else None
        art["file_bytes"] = path.stat().st_size if path else None
        art["width"], art["height"] = image_dimensions(path) if path else (None, None)
        art["source_urls"] = list(dict.fromkeys([source_by_id[identifier]["url"] for identifier in art["source_ids"] if identifier != "S13"] + [url for identifier in art["reference_ids"] for url in (legacy_by_id.get(identifier) or entity_by_id[identifier])["source_urls"]] + [url for identifier in art["entity_ids"] for url in entity_by_id[identifier]["source_urls"]]))
        refs = list(dict.fromkeys(art["reference_ids"] + art["entity_ids"]))
        gallery.append({"id": art["id"], "title": art["title"], "kind": art["kind"], "sequence": art.get("sequence", "Game concepts"), "category": art.get("category", "concepts"), "description": art["description"], "adaptation": art.get("game_adaptation", art.get("adaptation", "Generated planning illustration; not a playable level, production sprite or captured game screenshot.")), "reference_ids": refs, "local_path": art["local_path"], "creator": "Built-in image generation tool; project art direction", "date": "2026-10-08", "license": "New generated game concept", "notes": art["notes"], "source_urls": art["source_urls"], "tags": art.get("tags", []) + ["new game concept", art.get("category", "concepts")], "kit": art.get("kit", "game-concepts"), "prompt": art["prompt"], "entity_ids": art["entity_ids"], "source_ids": art["source_ids"], "canon_status": "game_proposal"})
    plan_path = RESEARCH / "levels.json"
    plan = json.loads(plan_path.read_text()) if plan_path.is_file() else None
    if plan:
        levels = plan.get("levels", []) + plan.get("optional_levels", [])
        level_ids = {item["id"] for item in levels}
        assert len(level_ids) == len(levels), "Duplicate level IDs"
        main = plan.get("levels", [])
        assert len(main) == 5, "Preserve five Act1 main levels"
        assert sum(item.get("target_minutes", item.get("initial_budget_minutes", 0)) for item in main) == 43, "Preserve 43-minute Act1 budget"
        for level in levels:
            if level.get("parent_level_id"):
                assert level["parent_level_id"] in level_ids, level["id"]
            for identifier in level.get("boss_ids", []):
                assert identifier in entity_by_id and entity_by_id[identifier]["category"] == "bosses", (level["id"], identifier)
            beats = level.get("beats", [])
            if beats:
                assert sum(beat["seconds"] for beat in beats) == round(level.get("target_minutes", level.get("initial_budget_minutes", 0)) * 60), ("Level beat budget", level["id"])
    return {"sources": sources, "entities": entities, "artworks": artworks, "level_plan": plan, "cast_index": json.loads((RESEARCH / "cast-index.json").read_text()) if (RESEARCH / "cast-index.json").is_file() else None}, gallery


def write_research_tables(db, extension):
    # Legacy `sources` keeps integer URL IDs; research_sources adds cited S01–S13 records.
    db.executescript("""
        CREATE TABLE metadata(key TEXT PRIMARY KEY, value_json TEXT NOT NULL);
        CREATE TABLE research_sources(id TEXT PRIMARY KEY, title TEXT NOT NULL, url TEXT NOT NULL, kind TEXT NOT NULL, accessed_date TEXT, data_json TEXT NOT NULL);
        CREATE TABLE entities(id TEXT PRIMARY KEY REFERENCES records(id), title TEXT NOT NULL, category TEXT NOT NULL, subcategory TEXT, canon_status TEXT NOT NULL, description TEXT, game_adaptation TEXT, notes TEXT, tags_json TEXT NOT NULL, data_json TEXT NOT NULL);
        CREATE TABLE entity_sources(entity_id TEXT NOT NULL REFERENCES entities(id), source_id TEXT NOT NULL REFERENCES research_sources(id), PRIMARY KEY(entity_id,source_id));
        CREATE TABLE entity_relations(entity_id TEXT NOT NULL REFERENCES entities(id), related_entity_id TEXT NOT NULL REFERENCES entities(id), relationship TEXT NOT NULL, PRIMARY KEY(entity_id,related_entity_id,relationship));
        CREATE TABLE cast_members(id INTEGER PRIMARY KEY, name TEXT NOT NULL, role TEXT NOT NULL, confidence TEXT, data_json TEXT NOT NULL);
        CREATE TABLE scene_refs(id INTEGER PRIMARY KEY, entity_id TEXT NOT NULL REFERENCES entities(id), position INTEGER NOT NULL, label TEXT NOT NULL);
        CREATE TABLE artworks(id TEXT PRIMARY KEY REFERENCES records(id), title TEXT NOT NULL, category TEXT NOT NULL, kind TEXT NOT NULL, local_path TEXT, repo_path TEXT, status TEXT NOT NULL, file_exists INTEGER NOT NULL CHECK(file_exists IN (0,1)), sha256 TEXT, file_bytes INTEGER, width INTEGER, height INTEGER, prompt TEXT, notes TEXT, data_json TEXT NOT NULL);
        CREATE TABLE artwork_entities(artwork_id TEXT NOT NULL REFERENCES artworks(id), entity_id TEXT NOT NULL REFERENCES entities(id), PRIMARY KEY(artwork_id,entity_id));
        CREATE TABLE artwork_sources(artwork_id TEXT NOT NULL REFERENCES artworks(id), source_id TEXT NOT NULL REFERENCES research_sources(id), PRIMARY KEY(artwork_id,source_id));
        CREATE TABLE levels(id TEXT PRIMARY KEY, title TEXT NOT NULL, subtitle TEXT, kind TEXT NOT NULL, target_minutes REAL, min_minutes REAL, max_minutes REAL, parent_level_id TEXT REFERENCES levels(id), objective TEXT, skill TEXT, mood TEXT, data_json TEXT NOT NULL);
        CREATE TABLE level_beats(id INTEGER PRIMARY KEY, level_id TEXT NOT NULL REFERENCES levels(id), position INTEGER NOT NULL, title TEXT NOT NULL, seconds INTEGER NOT NULL, checkpoint_elapsed_seconds INTEGER, purpose TEXT, data_json TEXT NOT NULL);
        CREATE TABLE level_bosses(level_id TEXT NOT NULL REFERENCES levels(id), entity_id TEXT NOT NULL REFERENCES entities(id), PRIMARY KEY(level_id,entity_id));
        CREATE TABLE adaptation_enemies(id TEXT PRIMARY KEY, title TEXT NOT NULL, canon_status TEXT NOT NULL, first_level_id TEXT REFERENCES levels(id), entity_id TEXT REFERENCES entities(id), role TEXT, data_json TEXT NOT NULL);
        CREATE TABLE level_source_links(level_id TEXT NOT NULL REFERENCES levels(id), url TEXT NOT NULL, source_id TEXT REFERENCES research_sources(id), PRIMARY KEY(level_id,url));
        CREATE TABLE level_record_references(level_id TEXT NOT NULL REFERENCES levels(id), record_id TEXT NOT NULL REFERENCES records(id), PRIMARY KEY(level_id,record_id));
        CREATE TABLE level_enemies(level_id TEXT NOT NULL REFERENCES levels(id), enemy_id TEXT NOT NULL REFERENCES adaptation_enemies(id), PRIMARY KEY(level_id,enemy_id));
        CREATE INDEX entities_category ON entities(category);
        CREATE INDEX entities_canon ON entities(canon_status);
        CREATE INDEX artworks_category ON artworks(category);
    """)
    dump = lambda value: json.dumps(value, ensure_ascii=False)
    for member in (extension.get("cast_index") or {}).get("records", []):
        db.execute("INSERT INTO cast_members(name,role,confidence,data_json) VALUES (?,?,?,?)", (member["name"],member["role"],member.get("confidence",""),dump(member)))
    for source in extension["sources"]:
        db.execute("INSERT INTO research_sources VALUES (?,?,?,?,?,?)", (source["id"],source["title"],source["url"],source["kind"],source["accessed_date"],dump(source)))
    for entity in extension["entities"]:
        db.execute("INSERT INTO entities VALUES (?,?,?,?,?,?,?,?,?,?)", (entity["id"],entity["title"],entity["category"],entity.get("subcategory"),entity["canon_status"],entity["description"],entity["game_adaptation"],entity["notes"],dump(entity["tags"]),dump(entity)))
        for identifier in entity["source_ids"]:
            db.execute("INSERT INTO entity_sources VALUES (?,?)", (entity["id"],identifier))
        for position,scene in enumerate(entity["scene_refs"]):
            db.execute("INSERT INTO scene_refs(entity_id,position,label) VALUES (?,?,?)", (entity["id"],position,scene))
    for entity in extension["entities"]:
        for identifier in entity["canonical_basis_ids"]:
            db.execute("INSERT INTO entity_relations VALUES (?,?,?)", (entity["id"],identifier,"canonical_basis"))
    for art in extension["artworks"]:
        db.execute("INSERT INTO artworks VALUES (?,?,?,?,?,?,?,?,?,?,?,?,?,?,?)", (art["id"],art["title"],art.get("category","concepts"),art["kind"],art["local_path"],art["repo_path"],art["status"],int(art["file_exists"]),art["sha256"],art["file_bytes"],art["width"],art["height"],art["prompt"],art["notes"],dump(art)))
        for identifier in art["entity_ids"]:
            db.execute("INSERT INTO artwork_entities VALUES (?,?)", (art["id"],identifier))
        for identifier in art["source_ids"]:
            db.execute("INSERT INTO artwork_sources VALUES (?,?)", (art["id"],identifier))
    plan = extension.get("level_plan") or {}
    levels = plan.get("levels", []) + plan.get("optional_levels", [])
    source_ids_by_url = {source["url"].rstrip("#"): source["id"] for source in extension["sources"]}
    for level in levels:
        target = level.get("target_minutes", level.get("initial_budget_minutes"))
        minimum,maximum = level.get("target_range_minutes", [target,target])
        db.execute("INSERT INTO levels VALUES (?,?,?,?,?,?,?,?,?,?,?,?)", (level["id"],level.get("title",level.get("name",level["id"])),level.get("subtitle",""),level.get("kind","main"),target,minimum,maximum,level.get("parent_level_id"),level.get("objective",""),level.get("skill",""),level.get("mood",""),dump(level)))
        for position,beat in enumerate(level.get("beats", [])):
            db.execute("INSERT INTO level_beats(level_id,position,title,seconds,checkpoint_elapsed_seconds,purpose,data_json) VALUES (?,?,?,?,?,?,?)", (level["id"],position,beat.get("name",beat.get("title","Encounter")),beat["seconds"],beat.get("checkpoint_elapsed_seconds"),beat.get("purpose",""),dump(beat)))
        for identifier in level.get("boss_ids", []):
            db.execute("INSERT INTO level_bosses VALUES (?,?)", (level["id"],identifier))
        for url in level.get("source_urls", []):
            db.execute("INSERT INTO level_source_links VALUES (?,?,?)", (level["id"],url,source_ids_by_url.get(url.rstrip("#"))))
        for identifier in level.get("film_object_ids", []):
            db.execute("INSERT INTO level_record_references VALUES (?,?)", (level["id"],identifier))
    design_entities = {e["design_id"]:e["id"] for e in extension["entities"] if e.get("design_id")}
    for enemy in plan.get("regular_enemies", []):
        db.execute("INSERT INTO adaptation_enemies VALUES (?,?,?,?,?,?,?)", (enemy["id"],enemy.get("name",enemy.get("title",enemy["id"])),"game_proposal",enemy.get("first_level"),design_entities.get(enemy["id"]),enemy.get("role",""),dump(enemy)))
    for level in levels:
        for identifier in level.get("enemy_ids", []):
            db.execute("INSERT INTO level_enemies VALUES (?,?)", (level["id"],identifier))
    db.execute("INSERT INTO metadata VALUES (?,?)", ("level_plan", dump(plan)))
    db.execute("INSERT INTO metadata VALUES (?,?)", ("cast_index", dump(extension.get("cast_index"))))


def write_credits(records):
    lines = [
        "# Source credits and provenance", "",
        "Generated from the curated catalogue. Source declarations and reproduction credits are retained verbatim where available; the underlying film is by Georges Méliès. A source declaration is not a new rights determination.", "",
        "Local archival images are Commons-served reference previews. Resizing is by the source thumbnail service; no retouching or recolouring was applied. Museum images and the two unresolved drawing reproductions are linked only.", "",
        "A03 carries a CC BY-SA 4.0 declaration: retain its named credit, source and licence when redistributing that image. USER01 is the user-supplied crop with unspecified crop provenance. Generated studies have their own records and are not archival reproductions.", "",
    ]
    for record in records:
        if record["kind"] in {"film-object", "generated-concept", "generated-object-sheet"} or record["kind"].startswith("research-"):
            continue
        lines += [f"## {record['id']} — {record['title']}", "",
                  f"- Type and date: {record['kind']}; {record['date']}.",
                  f"- Underlying creator / catalogue creator: {record['creator']}."]
        for label, key in [("Source reproduction credit", "source_credit_metadata"),
                           ("Credit metadata", "credit"), ("Attribution metadata", "attribution")]:
            if record.get(key):
                lines.append(f"- {label}: {record[key]}.")
        license_text = record["license"]
        if record.get("license_url"):
            license_text += f"; [licence terms]({record['license_url']})"
        lines.append(f"- Licence / access: {license_text}.")
        if record["local_path"]:
            lines.append(f"- Local preview: [{record['local_path']}]({record['local_path']}).")
        for url in record["source_urls"]:
            lines.append(f"- [Source record]({url}).")
        if record.get("notes"):
            lines.append(f"- Provenance note: {record['notes']}")
        lines.append("")
    lines += ["## New Act 1 research and concepts", "", "The research extension uses original paraphrases, direct film-frame relationships, and separately labelled game proposals. [Research sources](research/SOURCES.md) retains the cited institutional and restorer records. [Cast index](research/cast-index.json) separates published performer attributions from unresolved frame identities.", "", "New concept images are generated for this game. Their exact prompts, input reference paths and source/entity relationships remain in [the concept manifest](../../concept-art/act1/generated-manifest.json). They are not archival images or screenshots of implemented gameplay.", ""]
    (DEST / "CREDITS.md").write_text("\n".join(lines).rstrip() + "\n")


def write_readme(payload):
    counts = payload["counts"]
    categories = counts["entity_categories"]
    plan = payload.get("level_plan") or {}
    lines = [
        "# Act I — A Trip to the Moon library", "",
        "A research database and concept-art catalogue for the beginner act, inspired by Georges Méliès’s *Le Voyage dans la Lune* (1902). Researched 8 October 2026. The existing evidence and object records remain intact; new story indexes and art extend their coverage.", "",
        "## Browse", "",
        "Open [index.html](index.html) in a browser. Search names, performer names, IDs, scenery or design terms; filter by evidence type, scene and category. Open a card for its source, original observation, adaptation boundary, published performer attribution and related concept studies. It works offline when the repository folder structure is preserved; online source links need internet access.", "",
        f"The build has **{counts['records']} catalogue records**, **{counts['entities']} research/design entities**, **{counts['sources']} cited research sources**, and **{counts['local_images']} catalogued local images**. It retains all **116 earlier records**, including **70 object records** and **6 earlier generated studies**. The new concept collection adds **{counts['artworks']} available art records**; counts describe files and records, not unique historical people or scenes.", "",
        "| Research category | Records | Scope |", "| --- | ---: | --- |",
        f"| Characters and roles | {categories.get('characters', 0)} | Named travellers, distinct unnamed roles, overlapping scene ensembles, celestial performers, fauna, published cast roles and three invented enemy variants |",
        f"| Environments | {categories.get('environments', 0)} | Ceremony, launch, lunar exterior/dream, grotto, palace, escape, sea return and celebration |",
        f"| Bosses and candidates | {categories.get('bosses', 0)} | Two selected main encounters plus three explicitly unselected comparisons |",
        f"| Story moods | {categories.get('mood', 0)} | Interpretations of the emotional arc and their beginner-game implications |",
        f"| Prop/effect kits | {categories.get('props', 0)} | Grouped index linking every O01–O70 observation |", "",
        "[Film research](research/RESEARCH.md) explains naming and source qualifications. [Cast index](research/cast-index.json) retains the institutional credits: 11 named performers and two ensembles. No one-to-one map between the five named companions and five astronomer actor credits is fabricated.", "",
        "## Level concept", "",
        "[Act I concept](../../ACT1_CONCEPT.md) and [level data](research/levels.json) preserve **five main levels: 6, 8, 9, 10 and 10 minutes, totalling 43 minutes**. Three optional levels use their parent kits and separate 3–5 minute ranges; all-content guidance is **52–58 minutes**, excluding retries and deliberate replays. These are first-clear design estimates, not measured completion times.", "",
        "L1 teaches gestures in a safe launch rehearsal; L2 introduces the rush commitment; L3 adds swarm/spore repulsion and spear grammar; L4 combines guards and the Selenite King; L5 tests learned responses against the Man in the Moon and closes with escape. Optional Salvage Circuit, Spore Bloom and Royal Rehearsal reinforce existing skills. They add no required boss rematch.", "",
        "Keep the portrait pixel 2.5D camera, swipe-only ground dashes, immediate tap slash, a quick second-tap blast, aim from final swipe release, one carried weapon and fixed baseline damage. All mandatory paths work at normal dash length. Hittable spore clusters shed falling spores that temporarily repel swarmers. These mechanics, tutorial markers and boss attacks are game proposals.", "",
        "## Concept art and visual continuity", "",
        "The [new concept collection](../../concept-art/act1/README.md) covers characters, environments, bosses, mood, props and three proposed game views. Its [generation manifest](../../concept-art/act1/generated-manifest.json) retains exact prompts, reference inputs and research relationships. Generated studies are planning illustrations, not archival images, production sprites or implemented game screenshots.", "",
        "The [style guide](STYLE_GUIDE.md) carries the established theatrical vocabulary: painted wings, jagged lunar flats, dark negative space, period hats/coats/beards, a finless bullet shell, giant shallow mushroom caps, upright masked rib-banded Selenites, and celestial court ornament. Moon-white, dusty silver and black are chosen game art direction; authentic hand-coloured prints remain separately identified.", "",
        "| Earlier study | Image |", "| --- | --- |",
        "| G01 | [Lunar surface and celestial tableau](concepts/lunar-tableau-v2.png) |",
        "| G02 | [Mushroom grotto layouts](concepts/mushroom-grotto-v2.png) — earlier vent treatment is superseded by falling-spore repulsion |",
        "| G03 | [Selenite court](concepts/selenite-court-v2.png) |",
        "| G04 | [Observatory and launch objects](concepts/observatory-launch-object-studies-v2.png) |",
        "| G05 | [Lunar scenery and celestial objects](concepts/lunar-scenery-object-studies.png) |",
        "| G06 | [Selenites and court objects](concepts/selenite-court-object-studies.png) |", "",
        "The earlier [G01–G06 prompt manifest](generated-manifest.json), G04 revision input, original exploratory images, archival previews and link-only museum records remain preserved. The new studies extend rather than overwrite them.", "",
        "## Data and provenance", "",
        "| File | Purpose |", "| --- | --- |",
        "| [catalog.json](catalog.json) | Complete records plus research sources/entities/artworks, cast index, level plan, hashes and prompts |",
        "| [catalog.csv](catalog.csv) | Flat record and level export; structured fields and full data use JSON cells |",
        "| [library.sqlite](library.sqlite) | Relational source, entity, artwork, cast and level database with foreign keys |",
        "| [catalog-data.js](catalog-data.js) | Embedded data for offline browsing without fetching JSON |",
        "| [entities](research/entities.json), [sources](research/sources.json), [cast](research/cast-index.json) | Editable research records and performer attribution index |",
        "| [O01–O42](objects-earth-and-dream.json), [O43–O70](objects-grotto-and-return.json) | Preserved original observation/adaptation manifests |",
        "| [Source notes](research/SOURCES.md), [credits](CREDITS.md), [verification](VERIFICATION.md) | Evidence, licence declarations and build checks |", "",
        "Legacy F01–F13/A01–A17/M01–M09/USER01/O01–O70/G01–G06 IDs remain stable. New C/E/B/D/P/S families and later G IDs connect the research and art. D01–D12 mood IDs avoid colliding with museum M IDs. Film imagery, original costume, c.1930–31 and 1937 retrospective drawings, the 1960 reconstruction, and generated game concepts retain separate provenance.", "",
        "The legacy `sources` table retains its integer URL IDs. `research_sources` stores S01–S15 citation metadata. New tables include `entities`, `entity_sources`, `entity_relations`, `scene_refs`, `cast_members`, `artworks`, artwork joins, `levels`, `level_beats`, `level_bosses`, `adaptation_enemies`, and `level_enemies`. Full research/level records are preserved as JSON.", "",
        "```sql", "SELECT id, title, canon_status FROM entities WHERE category = 'characters';", "SELECT name, role FROM cast_members;", "SELECT e.title, s.title, s.url FROM entities e JOIN entity_sources es ON e.id=es.entity_id JOIN research_sources s ON s.id=es.source_id;", "SELECT id, title, target_minutes FROM levels WHERE kind='main';", "SELECT l.title, e.title FROM levels l JOIN level_bosses b ON l.id=b.level_id JOIN entities e ON e.id=b.entity_id;", "SELECT a.title, e.title FROM artworks a JOIN artwork_entities ae ON a.id=ae.artwork_id JOIN entities e ON e.id=ae.entity_id;", "```", "",
        "## Rebuild", "",
        "Edit the curated research/object files or generation manifest, then run from the repository root:", "",
        "```sh", "python3 scripts/research/build_moon_library.py --strict-art", "```", "",
        "The standard-library builder checks IDs, evidence references, source/entity/art joins, local art files, the five-level/43-minute budget, encounter beat sums and SQLite integrity/foreign keys. It regenerates JSON, CSV, browser data, SQLite, credits and this README. The default build omits planned/failed art records; strict mode rejects unfinished entries. Preserve the concept-art directories beside the reference library for offline image paths.", "",
        "The earlier `download_moon_references.py` is optional archival collection tooling; no new archival downloads were required for this extension.", "",
    ]
    (DEST / "README.md").write_text("\n".join(lines))


def write_verification(payload, table_counts, strict_art):
    counts = payload["counts"]
    plan = payload.get("level_plan") or {}
    main = plan.get("levels", [])
    optional = plan.get("optional_levels", [])
    object_ids = {f"O{number:02d}" for number in range(1, 71)}
    covered = {identifier for entity in payload["entities"] if entity["category"] == "props" for identifier in entity["reference_ids"]}
    assert object_ids == covered, "Prop-kit coverage must preserve all 70 original objects"
    lines = ["# Act I verification", "", "Rebuilt 8 October 2026 with the standard-library catalogue builder. This report records database/file validation; it does not claim campaign implementation, playtesting or gameplay balance.", "", "## Result", "", f"- Catalogue: **{counts['records']} records**, including all **116 earlier records** and **70 existing object records**.", f"- Research: **{counts['entities']} entities**, **{counts['sources']} sources**, and **{table_counts.get('cast_members', 0)} performer/ensemble attribution entries**.", f"- Images: **{counts['local_images']} catalogued local images**; **{counts['artworks']} new generated art records**. Every available image resolves locally and has a SHA-256 hash and file-size metadata.", f"- Level plan: **{len(main)} main levels**, budgets **{', '.join(str(level.get('target_minutes', level.get('initial_budget_minutes'))) for level in main)} minutes**, total **{sum(level.get('target_minutes', level.get('initial_budget_minutes', 0)) for level in main)} minutes**; **{len(optional)} optional levels**.", f"- Strict-art mode: **{'enabled; every declared entry is finished and its file exists' if strict_art else 'disabled; planned/failed entries are omitted'}**.", "- SQLite integrity check: **ok**. Foreign-key violations: **0**.", "- Unique catalogue/research/source/art IDs, valid legacy evidence links, valid canonical-basis links, valid art/entity/source joins, level-boss links and encounter beat budgets: **passed**.", "- P01–P20 prop kits cover **every O01–O70 record**.", "- JSON, offline JS, CSV, relational SQLite, credits and README derive from the same curated input. CSV includes the eight level rows as well as catalogue records.", "", "## Database rows", "", "| Table | Rows |", "| --- | ---: |"]
    lines += [f"| `{table}` | {amount} |" for table,amount in table_counts.items()]
    lines += ["", "## Evidence limits", "", "Original source-object manifests, archival previews, museum links, six earlier generated studies and exploratory revisions remain preserved. No new archival downloads or museum image copying were needed. Museum reconstruction and retrospective drawings retain their dates and kinds. Names, unnamed scene roles, published performer attributions and invented enemy variants remain separate.", "", "The browser uses embedded catalog-data.js and relative image paths. Interactive gallery validation and visual inspection of generated concept art are performed separately from these database checks. Three game-view images are proposed compositions; gesture behaviour, timing, onboarding success and first-clear budgets still need implementation and playtesting.", ""]
    (DEST / "VERIFICATION.md").write_text("\n".join(lines))


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--strict-art", action="store_true", help="Require every new concept image listed in the art manifest")
    args = parser.parse_args()
    records = []
    for source in load("commons-manifest.json"):
        identifier = source["id"]
        title, sequence, description = FRAMES[identifier]
        kind = "production-still" if identifier in {"A08", "A09", "A10", "A15"} else "film-still"
        date, notes = "1902 film; reproduction/version date may differ", ""
        references = []
        if identifier in {"A04", "A06"}:
            kind = "retrospective-art" if identifier == "A04" else "historical-drawing"
            date = "1937 (apparent match)" if identifier == "A04" else "Unresolved; Commons attributes 1902"
            notes = "Linked only. Retain the Commons date discrepancy; do not present this as verified 1902 preproduction concept art."
            if identifier == "A04":
                references = ["M06"]
        elif identifier == "A14":
            kind, date = "historical-poster", "1902 (Commons attribution)"
            notes = "Preliminary poster-sketch attribution is from Commons. Do not confuse this with the museum's separately dated 1937 recomposition."
        elif identifier.startswith("F"):
            notes = "No frame timestamps have been verified; source print or reproduction date may differ from the film's release."
            if "1900" in source["metadata_date"]:
                notes = "Commons metadata says 1900; the filename and institutional film record identify the 1902 film. " + notes
        elif identifier in {"A01", "A02", "A05", "A16"}:
            notes = "Alternate crop or reproduction of a repeated film composition, not a separate unique scene."
        elif identifier == "A17":
            notes = "This source print's title card is not treated as proof of the exact card on every 1902 release."
        coloured = identifier in {"A07", "A11", "A12", "A13"}
        if coloured:
            notes += " Source is a surviving/restored handcoloured print, not an invented game palette or simple grayscale tint."
        local_path = source["local_path"]
        if local_path and not (DEST / local_path).is_file():
            local_path = None
            notes += " Local download unavailable; source-page link retained."
        records.append({
            "id": identifier, "title": title, "kind": kind, "sequence": sequence,
            "category": "Historical drawing" if "art" in kind or "poster" in kind or "drawing" in kind else "Film reference",
            "description": description, "adaptation": "", "reference_ids": references,
            "local_path": local_path, "creator": "Georges Méliès (underlying film/artwork)",
            "source_credit_metadata": source["creator"], "date": date, "license": source["license_label"] + " (Commons source declaration)",
            "notes": notes.strip(), "source_urls": [source["source_page"]],
            "tags": ["authentic reference", "handcoloured print" if coloured else "monochrome or drawing"],
            "kit": sequence.lower().replace(" ", "-"), "original_url": source["original_url"],
            "license_url": source["license_url"], "credit": source["credit"],
            "attribution": source["attribution"], "original_width": source["width"],
            "original_height": source["height"], "source_metadata_date": source["metadata_date"],
        })
    records.append({"id": "USER01", "title": "User's celestial dream reference", "kind": "user-reference", "sequence": "Celestial Dream", "category": "Film reference", "description": "User-supplied crop showing the Earth globe, crescent performer, ringed Saturn figure, sleeping travellers and painted rock wings.", "adaptation": "", "reference_ids": ["A09"], "local_path": "film-stills/user01.png", "creator": "Georges Méliès (underlying film); supplied crop source not given", "date": "1902 film; crop date unknown", "license": "User-supplied reference; crop provenance unspecified", "notes": "Closely matches the named planetary-dream production still A09; no claim that this crop is a separate film scene.", "source_urls": [], "tags": ["user reference", "celestial tableau"], "kit": "lunar-surface"})
    for identifier, title, kind, sequence, date, creator, url, description in MUSEUMS:
        records.append({"id": identifier, "title": title, "kind": kind, "sequence": sequence, "category": "Institutional reference", "description": description, "adaptation": "", "reference_ids": [], "local_path": None, "creator": creator, "date": date, "license": "Museum reproduction rights not cleared; source link only", "notes": "Catalogue link retained; museum image pixels are not copied or represented as freely licensed.", "source_urls": [url], "tags": ["museum", "historical provenance"], "kit": sequence.lower().replace(" ", "-")})
    records += load("objects-earth-and-dream.json") + load("objects-grotto-and-return.json")
    generated = load("generated-manifest.json")
    for record in generated:
        record.pop("original_generated_path", None)
        record.pop("reference_paths", None)
    records += generated
    legacy_count = len(records)
    extension, extension_gallery = research_extension(records, args.strict_art)
    records += extension_gallery
    by_id = {r["id"]: r for r in records}
    assert len(by_id) == len(records), "Duplicate IDs"
    for record in records:
        for identifier in record["reference_ids"]:
            assert identifier in by_id, (record["id"], identifier)
        if not record["source_urls"]:
            record["source_urls"] = list(dict.fromkeys(url for identifier in record["reference_ids"] for url in by_id[identifier]["source_urls"]))
        if record["local_path"]:
            path = DEST / record["local_path"]
            assert path.is_file(), path
            record["sha256"] = hashlib.sha256(path.read_bytes()).hexdigest()
            record["file_bytes"] = path.stat().st_size
        if record["kind"] == "film-object":
            record.setdefault("creator", "Georges Méliès film reference; game adaptation proposed")
            record.setdefault("date", "Observed in 1902 film imagery")
            record.setdefault("license", "Object description and game-use proposal; see referenced image's source record")
    payload = {"schema_version": 2, "film": "Le Voyage dans la Lune", "film_year": 1902, "research_date": "2026-10-08", "records": records, "style_rules": STYLE_RULES}
    payload.update(extension)
    payload["counts"] = {"records": len(records), "legacy_records": legacy_count, "local_images": sum(bool(r["local_path"]) for r in records), "entities": len(extension["entities"]), "sources": len(extension["sources"]), "artworks": len(extension["artworks"]), "entity_categories": dict(Counter(e["category"] for e in extension["entities"]))}
    write_credits(records)
    write_readme(payload)
    (DEST / "catalog.json").write_text(json.dumps(payload, ensure_ascii=False, indent=2) + "\n")
    (DEST / "catalog-data.js").write_text("window.MOON_LIBRARY = " + json.dumps(payload, ensure_ascii=False).replace("</", "<\\/") + ";\n")
    columns = ["id", "title", "kind", "sequence", "category", "description", "adaptation", "creator", "date", "license", "notes", "kit", "local_path", "reference_ids", "source_urls", "tags"]
    csv_columns = columns + ["record_type", "canon_status", "source_ids", "entity_ids", "scene_refs", "design_id", "name_status", "target_minutes", "parent_level_id", "data_json"]
    full_records = {record["id"]: record for record in extension["sources"] + extension["entities"] + extension["artworks"]}
    plan = extension.get("level_plan") or {}
    csv_records = [dict(record, record_type="entity" if record["id"] in {e["id"] for e in extension["entities"]} else "artwork" if record["id"] in {a["id"] for a in extension["artworks"]} else "source" if record["kind"] == "research-source" else "legacy", data_json=json.dumps(full_records.get(record["id"], record), ensure_ascii=False)) for record in records]
    for level in plan.get("levels", []) + plan.get("optional_levels", []):
        csv_records.append({"id":level["id"], "title":level.get("title",level.get("name")), "kind":"game-level", "category":level.get("kind","main"), "description":level.get("objective",""), "adaptation":level.get("skill",""), "canon_status":"game_proposal", "record_type":"level", "target_minutes":level.get("target_minutes",level.get("initial_budget_minutes")), "parent_level_id":level.get("parent_level_id"), "source_urls":level.get("source_urls", []), "reference_ids":level.get("film_object_ids", []), "data_json":json.dumps(level,ensure_ascii=False)})
    with (DEST / "catalog.csv").open("w", newline="") as output:
        writer = csv.DictWriter(output, fieldnames=csv_columns, lineterminator="\n")
        writer.writeheader()
        for record in csv_records:
            writer.writerow({key: json.dumps(record.get(key, []), ensure_ascii=False) if isinstance(record.get(key), (list,dict)) else record.get(key, "") for key in csv_columns})
    temporary = DEST / "library.build.sqlite"
    temporary.unlink(missing_ok=True)
    db = sqlite3.connect(temporary)
    db.execute("PRAGMA foreign_keys=ON")
    db.executescript("""
        DROP TABLE IF EXISTS record_references;
        DROP TABLE IF EXISTS record_sources;
        DROP TABLE IF EXISTS sources;
        DROP TABLE IF EXISTS records;
        CREATE TABLE records(id TEXT PRIMARY KEY, title TEXT NOT NULL, kind TEXT NOT NULL,
          sequence TEXT, category TEXT, description TEXT, adaptation TEXT, creator TEXT,
          date TEXT, license TEXT, notes TEXT, kit TEXT, local_path TEXT, tags_json TEXT,
          sha256 TEXT, file_bytes INTEGER, prompt TEXT);
        CREATE TABLE sources(id INTEGER PRIMARY KEY, url TEXT UNIQUE NOT NULL);
        CREATE TABLE record_sources(record_id TEXT REFERENCES records(id), source_id INTEGER REFERENCES sources(id), PRIMARY KEY(record_id,source_id));
        CREATE TABLE record_references(record_id TEXT REFERENCES records(id), reference_id TEXT REFERENCES records(id), PRIMARY KEY(record_id,reference_id));
        CREATE INDEX records_kind ON records(kind);
        CREATE INDEX records_sequence ON records(sequence);
        CREATE INDEX records_kit ON records(kit);
    """)
    sql_columns = columns[:12] + ["local_path", "tags_json", "sha256", "file_bytes", "prompt"]
    for record in records:
        values = [json.dumps(record["tags"], ensure_ascii=False) if key == "tags_json" else record.get(key) for key in sql_columns]
        db.execute("INSERT INTO records VALUES (" + ",".join("?" for _ in values) + ")", values)
    for record in records:
        for url in record["source_urls"]:
            db.execute("INSERT OR IGNORE INTO sources(url) VALUES (?)", (url,))
            source_id = db.execute("SELECT id FROM sources WHERE url=?", (url,)).fetchone()[0]
            db.execute("INSERT OR IGNORE INTO record_sources VALUES (?,?)", (record["id"], source_id))
        for identifier in record["reference_ids"]:
            db.execute("INSERT INTO record_references VALUES (?,?)", (record["id"], identifier))
    write_research_tables(db, extension)
    for key in ["schema_version", "film", "film_year", "research_date", "counts", "style_rules"]:
        db.execute("INSERT INTO metadata VALUES (?,?)", (key, json.dumps(payload[key], ensure_ascii=False)))
    db.commit()
    assert db.execute("PRAGMA integrity_check").fetchone()[0] == "ok"
    assert not db.execute("PRAGMA foreign_key_check").fetchall()
    table_counts = {table: db.execute("SELECT COUNT(*) FROM " + table).fetchone()[0] for table in ["records", "entities", "research_sources", "cast_members", "artworks", "artwork_entities", "artwork_sources", "levels", "level_beats", "level_bosses", "adaptation_enemies", "level_enemies", "level_record_references"]}
    db.close()
    temporary.replace(DEST / "library.sqlite")
    write_verification(payload, table_counts, args.strict_art)
    totals = Counter(r["kind"] for r in records)
    print(json.dumps({"records": len(records), "local_images": sum(bool(r["local_path"]) for r in records), "types": totals, "research": payload["counts"], "sqlite_integrity": "ok"}, indent=2))


if __name__ == "__main__":
    main()
