"""Build portable reference exports from curated source records and image files."""
from collections import Counter
import csv
import hashlib
import json
from pathlib import Path
import sqlite3

ROOT = Path(__file__).resolve().parents[2]
DEST = ROOT / "docs/reference-library/act1"

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


def write_credits(records):
    lines = [
        "# Source credits and provenance", "",
        "Generated from the curated catalogue. Source declarations and reproduction credits are retained verbatim where available; the underlying film is by Georges Méliès. A source declaration is not a new rights determination.", "",
        "Local archival images are Commons-served reference previews. Resizing is by the source thumbnail service; no retouching or recolouring was applied. Museum images and the two unresolved drawing reproductions are linked only.", "",
        "A03 carries a CC BY-SA 4.0 declaration: retain its named credit, source and licence when redistributing that image. USER01 is the user-supplied crop with unspecified crop provenance. Generated studies have their own records and are not archival reproductions.", "",
    ]
    for record in records:
        if record["kind"] in {"film-object", "generated-concept", "generated-object-sheet"}:
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
    (DEST / "CREDITS.md").write_text("\n".join(lines).rstrip() + "\n")


def main():
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
    payload = {"schema_version": 1, "film": "Le Voyage dans la Lune", "film_year": 1902, "research_date": "2026-10-08", "records": records, "style_rules": STYLE_RULES}
    write_credits(records)
    (DEST / "catalog.json").write_text(json.dumps(payload, ensure_ascii=False, indent=2) + "\n")
    (DEST / "catalog-data.js").write_text("window.MOON_LIBRARY = " + json.dumps(payload, ensure_ascii=False).replace("</", "<\\/") + ";\n")
    columns = ["id", "title", "kind", "sequence", "category", "description", "adaptation", "creator", "date", "license", "notes", "kit", "local_path", "reference_ids", "source_urls", "tags"]
    with (DEST / "catalog.csv").open("w", newline="") as output:
        writer = csv.DictWriter(output, fieldnames=columns, lineterminator="\n")
        writer.writeheader()
        for record in records:
            writer.writerow({key: json.dumps(record.get(key, []), ensure_ascii=False) if isinstance(record.get(key), list) else record.get(key, "") for key in columns})
    temporary = DEST / "library.build.sqlite"
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
    db.commit()
    assert db.execute("PRAGMA integrity_check").fetchone()[0] == "ok"
    assert not db.execute("PRAGMA foreign_key_check").fetchall()
    db.close()
    temporary.replace(DEST / "library.sqlite")
    totals = Counter(r["kind"] for r in records)
    print(json.dumps({"records": len(records), "local_images": sum(bool(r["local_path"]) for r in records), "types": totals}, indent=2))


if __name__ == "__main__":
    main()
