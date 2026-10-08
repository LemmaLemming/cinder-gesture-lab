"""Build the offline Act II story database and concept-art catalogue.

Only Python's standard library is required. Curated research and the generation
manifest remain the source of truth; all exports can be rebuilt without a server.
"""
from __future__ import annotations

import argparse
from collections import Counter
import csv
import hashlib
import json
import os
from pathlib import Path
import re
import sqlite3
import struct

ROOT = Path(__file__).resolve().parents[2]
DEST = ROOT / "docs/reference-library/act2"
ART_ROOT = ROOT / "docs/concept-art/act2"
RESEARCH = DEST / "research"
DATE = "2026-10-08"


def read_records(path: Path, key: str, required: bool = True) -> tuple[list, dict]:
    if not path.exists():
        if required:
            raise ValueError(f"Required source is missing: {path.relative_to(ROOT)}")
        return [], {}
    payload = json.loads(path.read_text(encoding="utf-8"))
    if isinstance(payload, list):
        return payload, {}
    if isinstance(payload, dict):
        for field in (key, "records", "items"):
            if isinstance(payload.get(field), list):
                return payload[field], {k: v for k, v in payload.items() if k != field}
    raise ValueError(f"Expected an array or an object with {key}: {path}")


def as_list(value) -> list:
    if value is None or value == "":
        return []
    return value if isinstance(value, list) else [value]


def unique(records: list, kind: str) -> dict:
    result = {}
    for record in records:
        identifier = str(record.get("id", "")).strip()
        if not identifier or identifier in result:
            raise ValueError(f"Missing or duplicate {kind} ID: {identifier!r}")
        record["id"] = identifier
        result[identifier] = record
    return result


def chapter_record(value) -> dict:
    if isinstance(value, str):
        match = re.fullmatch(r"Book\s+([IVXLCDM]+|\d+),?\s+Chapter\s+(\d+):\s*(.*)", value)
        if match:
            return {"label": value, "book": match[1], "chapter": match[2], "title": match[3], "note": ""}
        return {"label": value, "book": "", "chapter": "", "title": "", "note": ""}
    if not isinstance(value, dict):
        return {"label": str(value), "book": "", "chapter": "", "title": "", "note": ""}
    result = dict(value)
    result.setdefault("book", value.get("part", ""))
    result.setdefault("chapter", value.get("number", ""))
    result.setdefault("title", value.get("chapter_title", ""))
    result.setdefault("note", value.get("notes", ""))
    if not result.get("label"):
        parts = [f"Book {result['book']}" if result["book"] else "",
                 f"Chapter {result['chapter']}" if result["chapter"] else "",
                 str(result["title"])]
        result["label"] = " · ".join(part for part in parts if part)
    return result


def resolve_art_path(value: str | None) -> Path | None:
    if not value:
        return None
    path = Path(value)
    if path.is_absolute():
        target = path.resolve()
    elif path.parts[0] == "docs":
        target = (ROOT / path).resolve()
    elif path.parts[0] == "..":
        target = (DEST / path).resolve()
    else:
        target = (ART_ROOT / path).resolve()
    if not target.is_relative_to(ART_ROOT.resolve()):
        raise ValueError(f"Artwork must be inside docs/concept-art/act2: {value}")
    return target


def dimensions(path: Path) -> tuple[int | None, int | None]:
    """Read common image dimensions without decoding or external dependencies."""
    with path.open("rb") as stream:
        header = stream.read(32)
        if header.startswith(b"\x89PNG\r\n\x1a\n") and len(header) >= 24:
            return struct.unpack(">II", header[16:24])
        if header[:6] in (b"GIF87a", b"GIF89a"):
            return struct.unpack("<HH", header[6:10])
        if header[:2] == b"\xff\xd8":
            stream.seek(2)
            while True:
                marker = stream.read(1)
                if not marker:
                    break
                if marker != b"\xff":
                    continue
                code = stream.read(1)
                while code == b"\xff":
                    code = stream.read(1)
                if code in (b"\xd8", b"\xd9"):
                    continue
                raw = stream.read(2)
                if len(raw) != 2:
                    break
                length = struct.unpack(">H", raw)[0]
                if code and code[0] in {0xC0, 0xC1, 0xC2, 0xC3, 0xC5, 0xC6, 0xC7, 0xC9, 0xCA, 0xCB, 0xCD, 0xCE, 0xCF}:
                    size = stream.read(5)
                    if len(size) == 5:
                        height, width = struct.unpack(">HH", size[1:])
                        return width, height
                stream.seek(max(0, length - 2), 1)
    return None, None


def normalize(sources: list, entities: list, artworks: list, strict_art: bool) -> list[str]:
    warnings = []
    sources_by_id = unique(sources, "source")
    entities_by_id = unique(entities, "entity")
    unique(artworks, "artwork")
    if not entities:
        raise ValueError("Research contains no entities; refusing to publish an empty database.")
    for source in sources:
        source.setdefault("title", source.get("name", source["id"]))
        source.setdefault("kind", source.get("source_type", "reference"))
        source.setdefault("accessed_date", source.get("accessed", DATE))
        source.setdefault("url", "")
    for entity in entities:
        entity.setdefault("title", entity.get("name", entity["id"]))
        entity.setdefault("name", entity["title"])
        entity.setdefault("category", "characters")
        entity.setdefault("subcategory", entity.get("entity_type", entity.get("type", "")))
        entity.setdefault("canon_status", "interpretation")
        entity.setdefault("description", "")
        entity.setdefault("game_adaptation", entity.get("act2_role", ""))
        entity.setdefault("notes", "")
        entity["tags"] = as_list(entity.get("tags"))
        entity["source_ids"] = list(dict.fromkeys(as_list(entity.get("source_ids"))))
        entity["chapter_refs"] = [chapter_record(ref) for ref in as_list(entity.get("chapter_refs"))]
        entity["artwork_ids"] = []
        entity["canonical_basis_ids"] = list(dict.fromkeys(as_list(entity.get("canonical_basis_ids"))))
        for basis_id in entity["canonical_basis_ids"]:
            if basis_id not in entities_by_id:
                raise ValueError(f"Unknown canonical basis {basis_id} on entity {entity['id']}")
        for source_id in entity["source_ids"]:
            if source_id not in sources_by_id:
                raise ValueError(f"Unknown source {source_id} on entity {entity['id']}")
        for chapter in entity["chapter_refs"]:
            if chapter.get("source_id") and chapter["source_id"] not in sources_by_id:
                raise ValueError(f"Unknown chapter source on entity {entity['id']}")
        if entity["canon_status"] == "novel_fact" and not entity["source_ids"]:
            raise ValueError(f"Novel fact {entity['id']} has no source attribution")
    for artwork in artworks:
        artwork.setdefault("title", artwork.get("name", artwork["id"]))
        artwork.setdefault("category", "environments")
        artwork.setdefault("kind", "gameplay-mockup" if artwork["category"] == "gameplay" else "concept-sheet")
        artwork.setdefault("description", "")
        artwork.setdefault("notes", "")
        artwork.setdefault("prompt", "")
        artwork.setdefault("canon_status", "game_proposal")
        artwork["entity_ids"] = list(dict.fromkeys(as_list(artwork.get("entity_ids", artwork.get("reference_ids")))))
        artwork["tags"] = as_list(artwork.get("tags"))
        linked_sources = []
        for entity_id in artwork["entity_ids"]:
            if entity_id not in entities_by_id:
                raise ValueError(f"Unknown entity {entity_id} on artwork {artwork['id']}")
            entity = entities_by_id[entity_id]
            entity["artwork_ids"].append(artwork["id"])
            linked_sources.extend(entity["source_ids"])
        artwork["source_ids"] = list(dict.fromkeys(as_list(artwork.get("source_ids")) + linked_sources))
        for source_id in artwork["source_ids"]:
            if source_id not in sources_by_id:
                raise ValueError(f"Unknown source {source_id} on artwork {artwork['id']}")
        path = resolve_art_path(artwork.get("local_path"))
        artwork["repo_path"] = path.relative_to(ROOT).as_posix() if path else None
        artwork["file_exists"] = bool(path and path.is_file())
        artwork["local_path"] = Path(os.path.relpath(path, DEST)).as_posix() if path else None
        artwork["status"] = "generated" if artwork["file_exists"] else artwork.get("status", "planned")
        artwork["sha256"] = None
        artwork["file_bytes"] = None
        artwork["width"] = None
        artwork["height"] = None
        if artwork["file_exists"]:
            artwork["sha256"] = hashlib.sha256(path.read_bytes()).hexdigest()
            artwork["file_bytes"] = path.stat().st_size
            artwork["width"], artwork["height"] = dimensions(path)
            if path.suffix.lower() == ".png" and not artwork["width"]:
                raise ValueError(f"Invalid PNG: {artwork['repo_path']}")
        else:
            message = f"Artwork {artwork['id']} is not available: {artwork.get('repo_path') or 'no path'}"
            if strict_art:
                raise ValueError(message)
            warnings.append(message)
    return warnings


def write_json(path: Path, payload):
    path.write_text(json.dumps(payload, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")


def load_level_plan(entities: list) -> dict | None:
    path = RESEARCH / "levels.json"
    if not path.exists():
        return None
    plan = json.loads(path.read_text(encoding="utf-8"))
    if not isinstance(plan, dict):
        raise ValueError("Level plan must be an object")
    main = as_list(plan.get("levels"))
    optional = as_list(plan.get("optional_levels"))
    by_id = unique(main + optional, "level")
    entity_ids = {entity["id"] for entity in entities}
    enemies = as_list(plan.get("regular_enemies"))
    enemy_ids = set(unique(enemies, "adaptation enemy"))
    for level in main + optional:
        if level.get("parent_level_id") and level["parent_level_id"] not in by_id:
            raise ValueError(f"Unknown parent level for {level['id']}")
        for boss_id in as_list(level.get("boss_ids")):
            if boss_id not in entity_ids:
                raise ValueError(f"Unknown boss {boss_id} in level {level['id']}")
        for enemy_id in as_list(level.get("enemy_ids")):
            if enemy_id not in enemy_ids:
                raise ValueError(f"Unknown enemy {enemy_id} in level {level['id']}")
        if level.get("beats"):
            duration = sum(beat["seconds"] for beat in level["beats"])
            if duration != level["target_minutes"] * 60:
                raise ValueError(f"Beat durations do not match {level['id']} target")
        if level.get("target_range_minutes"):
            minimum, maximum = level["target_range_minutes"]
            if not minimum <= level.get("initial_budget_minutes", minimum) <= maximum:
                raise ValueError(f"Optional budget is outside its range: {level['id']}")
    for enemy in enemies:
        if enemy.get("first_level") not in by_id:
            raise ValueError(f"Unknown first level for enemy {enemy['id']}")
    total = sum(level["target_minutes"] for level in main)
    if plan.get("main_first_clear_target_minutes", total) != total:
        raise ValueError("Main-level total does not match the declared pacing target")
    if plan.get("main_level_count", len(main)) != len(main) or plan.get("optional_level_count", len(optional)) != len(optional):
        raise ValueError("Declared level counts do not match the level plan")
    return plan


def write_csv(payload: dict):
    columns = ["id", "record_type", "title", "category", "subcategory", "kind", "canon_status", "description", "game_adaptation", "chapter_refs", "source_ids", "entity_ids", "artwork_ids", "design_id", "canonical_basis_ids", "tags", "notes", "local_path", "status", "file_exists", "sha256", "file_bytes", "width", "height"]
    with (DEST / "catalog.csv").open("w", newline="", encoding="utf-8") as output:
        writer = csv.DictWriter(output, fieldnames=columns, lineterminator="\n")
        writer.writeheader()
        for kind, records in (("entity", payload["entities"]), ("artwork", payload["artworks"])):
            for record in records:
                values = {**record, "record_type": kind}
                writer.writerow({key: json.dumps(values[key], ensure_ascii=False) if isinstance(values.get(key), (list, dict)) else values.get(key, "") for key in columns})


def write_database(payload: dict):
    temporary = DEST / "library.build.sqlite"
    temporary.unlink(missing_ok=True)
    db = sqlite3.connect(temporary)
    try:
        db.execute("PRAGMA foreign_keys = ON")
        db.executescript("""
            CREATE TABLE metadata (key TEXT PRIMARY KEY, value_json TEXT NOT NULL);
            CREATE TABLE sources (id TEXT PRIMARY KEY, title TEXT NOT NULL, url TEXT NOT NULL,
                kind TEXT NOT NULL, accessed_date TEXT, data_json TEXT NOT NULL);
            CREATE TABLE entities (id TEXT PRIMARY KEY, title TEXT NOT NULL, category TEXT NOT NULL,
                subcategory TEXT, canon_status TEXT NOT NULL, description TEXT,
                game_adaptation TEXT, notes TEXT, tags_json TEXT NOT NULL, data_json TEXT NOT NULL);
            CREATE TABLE entity_sources (entity_id TEXT NOT NULL REFERENCES entities(id),
                source_id TEXT NOT NULL REFERENCES sources(id), PRIMARY KEY(entity_id, source_id));
            CREATE TABLE entity_relations (entity_id TEXT NOT NULL REFERENCES entities(id),
                related_entity_id TEXT NOT NULL REFERENCES entities(id), relationship TEXT NOT NULL,
                PRIMARY KEY(entity_id, related_entity_id, relationship));
            CREATE TABLE chapter_refs (id INTEGER PRIMARY KEY, entity_id TEXT NOT NULL REFERENCES entities(id),
                position INTEGER NOT NULL, label TEXT, book TEXT, chapter TEXT, title TEXT, note TEXT,
                source_id TEXT REFERENCES sources(id), data_json TEXT NOT NULL);
            CREATE TABLE artworks (id TEXT PRIMARY KEY, title TEXT NOT NULL, category TEXT NOT NULL,
                kind TEXT NOT NULL, description TEXT, canon_status TEXT NOT NULL, local_path TEXT,
                repo_path TEXT, status TEXT NOT NULL, file_exists INTEGER NOT NULL CHECK(file_exists IN (0, 1)),
                sha256 TEXT, file_bytes INTEGER, width INTEGER, height INTEGER, prompt TEXT,
                notes TEXT, data_json TEXT NOT NULL);
            CREATE TABLE artwork_entities (artwork_id TEXT NOT NULL REFERENCES artworks(id),
                entity_id TEXT NOT NULL REFERENCES entities(id), PRIMARY KEY(artwork_id, entity_id));
            CREATE TABLE artwork_sources (artwork_id TEXT NOT NULL REFERENCES artworks(id),
                source_id TEXT NOT NULL REFERENCES sources(id), PRIMARY KEY(artwork_id, source_id));
            CREATE INDEX entities_category ON entities(category);
            CREATE INDEX entities_canon ON entities(canon_status);
            CREATE INDEX artworks_category ON artworks(category);
            CREATE INDEX chapters_entity ON chapter_refs(entity_id);
            CREATE TABLE levels (id TEXT PRIMARY KEY, title TEXT NOT NULL, subtitle TEXT, kind TEXT NOT NULL,
                target_minutes REAL, min_minutes REAL, max_minutes REAL,
                parent_level_id TEXT REFERENCES levels(id), objective TEXT, skill TEXT, mood TEXT,
                data_json TEXT NOT NULL);
            CREATE TABLE level_beats (id INTEGER PRIMARY KEY, level_id TEXT NOT NULL REFERENCES levels(id),
                position INTEGER NOT NULL, title TEXT NOT NULL, seconds INTEGER NOT NULL,
                checkpoint_elapsed_seconds INTEGER, purpose TEXT, data_json TEXT NOT NULL);
            CREATE TABLE level_bosses (level_id TEXT NOT NULL REFERENCES levels(id),
                entity_id TEXT NOT NULL REFERENCES entities(id), PRIMARY KEY(level_id, entity_id));
            CREATE TABLE adaptation_enemies (id TEXT PRIMARY KEY, title TEXT NOT NULL,
                canon_status TEXT NOT NULL, first_level_id TEXT REFERENCES levels(id),
                entity_id TEXT REFERENCES entities(id), role TEXT, data_json TEXT NOT NULL);
            CREATE TABLE level_enemies (level_id TEXT NOT NULL REFERENCES levels(id),
                enemy_id TEXT NOT NULL REFERENCES adaptation_enemies(id), PRIMARY KEY(level_id, enemy_id));
            CREATE TABLE level_source_links (level_id TEXT NOT NULL REFERENCES levels(id),
                url TEXT NOT NULL, source_id TEXT REFERENCES sources(id), PRIMARY KEY(level_id, url));
        """)
        dump = lambda value: json.dumps(value, ensure_ascii=False)
        for key, value in payload.items():
            if key not in {"sources", "entities", "artworks"}:
                db.execute("INSERT INTO metadata VALUES (?, ?)", (key, dump(value)))
        for source in payload["sources"]:
            db.execute("INSERT INTO sources VALUES (?, ?, ?, ?, ?, ?)",
                       (source["id"], source["title"], source["url"], source["kind"], source["accessed_date"], dump(source)))
        for entity in payload["entities"]:
            db.execute("INSERT INTO entities VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)",
                       (entity["id"], entity["title"], entity["category"], entity["subcategory"], entity["canon_status"], entity["description"], entity["game_adaptation"], entity["notes"], dump(entity["tags"]), dump(entity)))
            for source_id in entity["source_ids"]:
                db.execute("INSERT INTO entity_sources VALUES (?, ?)", (entity["id"], source_id))
            for index, chapter in enumerate(entity["chapter_refs"]):
                db.execute("INSERT INTO chapter_refs (entity_id,position,label,book,chapter,title,note,source_id,data_json) VALUES (?,?,?,?,?,?,?,?,?)",
                           (entity["id"], index, chapter["label"], str(chapter["book"]), str(chapter["chapter"]), chapter["title"], chapter["note"], chapter.get("source_id"), dump(chapter)))
        for entity in payload["entities"]:
            for basis_id in entity.get("canonical_basis_ids", []):
                db.execute("INSERT INTO entity_relations VALUES (?,?,?)", (entity["id"], basis_id, "canonical_basis"))
        for art in payload["artworks"]:
            db.execute("INSERT INTO artworks VALUES (?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?)",
                       (art["id"], art["title"], art["category"], art["kind"], art["description"], art["canon_status"], art["local_path"], art["repo_path"], art["status"], int(art["file_exists"]), art["sha256"], art["file_bytes"], art["width"], art["height"], art["prompt"], art["notes"], dump(art)))
            for entity_id in art["entity_ids"]:
                db.execute("INSERT INTO artwork_entities VALUES (?,?)", (art["id"], entity_id))
            for source_id in art["source_ids"]:
                db.execute("INSERT INTO artwork_sources VALUES (?,?)", (art["id"], source_id))
        plan = payload.get("level_plan") or {}
        levels = as_list(plan.get("levels")) + as_list(plan.get("optional_levels"))
        sources_by_url = {source["url"]: source["id"] for source in payload["sources"]}
        for level in levels:
            target = level.get("target_minutes", level.get("initial_budget_minutes"))
            minimum, maximum = level.get("target_range_minutes", [target, target])
            db.execute("INSERT INTO levels VALUES (?,?,?,?,?,?,?,?,?,?,?,?)",
                       (level["id"], level.get("title", level.get("name", level["id"])), level.get("subtitle", ""), level["kind"], target, minimum, maximum, level.get("parent_level_id"), level.get("objective", ""), level.get("skill", ""), level.get("mood", ""), dump(level)))
            for position, beat in enumerate(as_list(level.get("beats"))):
                db.execute("INSERT INTO level_beats (level_id,position,title,seconds,checkpoint_elapsed_seconds,purpose,data_json) VALUES (?,?,?,?,?,?,?)",
                           (level["id"], position, beat["name"], beat["seconds"], beat.get("checkpoint_elapsed_seconds"), beat.get("purpose", ""), dump(beat)))
            for boss_id in as_list(level.get("boss_ids")):
                db.execute("INSERT INTO level_bosses VALUES (?,?)", (level["id"], boss_id))
            for url in as_list(level.get("source_urls")):
                db.execute("INSERT INTO level_source_links VALUES (?,?,?)", (level["id"], url, sources_by_url.get(url)))
        entities_by_design_id = {entity["design_id"]: entity["id"] for entity in payload["entities"] if entity.get("design_id")}
        for enemy in as_list(plan.get("regular_enemies")):
            db.execute("INSERT INTO adaptation_enemies VALUES (?,?,?,?,?,?,?)",
                       (enemy["id"], enemy["name"], "game_proposal", enemy.get("first_level"), entities_by_design_id.get(enemy["id"]), enemy.get("role", ""), dump(enemy)))
        for level in levels:
            for enemy_id in as_list(level.get("enemy_ids")):
                db.execute("INSERT INTO level_enemies VALUES (?,?)", (level["id"], enemy_id))
        db.commit()
        violations = db.execute("PRAGMA foreign_key_check").fetchall()
        integrity = db.execute("PRAGMA integrity_check").fetchone()[0]
        if violations or integrity != "ok":
            raise ValueError(f"SQLite integrity failure: {violations}; {integrity}")
    except Exception:
        db.close()
        temporary.unlink(missing_ok=True)
        raise
    db.close()
    temporary.replace(DEST / "library.sqlite")


def write_readme(payload: dict):
    counts = payload["counts"]
    lines = ["# Act II — The War of the Worlds", "",
             "Open [index.html](index.html) for the offline, searchable story database and concept-art gallery. No server, install, or internet connection is needed to browse it. Source links open online.", "",
             f"This build contains **{counts['entities']} research/design entities**, **{counts['sources']} cited sources**, and **{counts['available_artworks']} available images** ({counts['artworks']} art records). The three gameplay images are proposed compositions, not screenshots of an implemented campaign.", "",
             "Research distinguishes **Novel fact**, **Interpretation**, and **Game proposal**. Chapter references describe the novel; adaptation notes explain the proposed gameplay. Boss sheets may compare unused candidates. Human characters do not automatically become enemies.", "",
             "## Files", "",
             "- [Research entities](research/entities.json) and [sources](research/sources.json): editable research sources.",
             "- [JSON](catalog.json): complete portable database with research, art, metadata, and provenance.",
             "- [CSV](catalog.csv): flat entity and artwork export; arrays are JSON inside CSV cells.",
             "- [SQLite](library.sqlite): relational database with foreign keys and full source-record JSON.",
             "- [Level plan](research/levels.json): main and optional level budgets, encounter beats, checkpoints, and boss/enemy assignments.",
             "- [Source credits](CREDITS.md): publication and generation provenance.",
             "- [Concept-art folder](../../concept-art/act2/README.md): category folders, prompts, and game views.",
             "- [Act II concept](../../ACT2_CONCEPT.md): proposed levels and experienced-player pacing.", "",
             "- [Verification](VERIFICATION.md): completed checks and the limit on browser visual inspection.", "",
             "## Rebuild", "",
             "From the repository root, run:", "", "```sh", "python3 scripts/research/build_invasion_library.py", "```", "",
             "Add `--strict-art` for a final delivery check: every image listed in the generation manifest must exist. Default builds retain planned image records and report missing files without counting them as available art.", "",
             "The builder validates unique IDs, source references, artwork-to-entity links, image paths and PNG headers; records SHA-256 hashes, sizes and dimensions; and runs SQLite foreign-key and integrity checks. It uses only Python's standard library.", "",
             "## SQLite examples", "", "```sql",
             "SELECT id, title FROM entities WHERE category = 'characters';",
             "SELECT id, title, game_adaptation FROM entities WHERE category = 'bosses';",
             "SELECT e.title, c.label FROM entities e JOIN chapter_refs c ON e.id = c.entity_id;",
             "SELECT a.title, e.title FROM artworks a JOIN artwork_entities ae ON a.id = ae.artwork_id JOIN entities e ON e.id = ae.entity_id;",
             "SELECT e.title, s.title, s.url FROM entities e JOIN entity_sources es ON e.id = es.entity_id JOIN sources s ON s.id = es.source_id;",
             "SELECT id, title, target_minutes FROM levels WHERE kind = 'main';",
             "SELECT l.title, e.title FROM levels l JOIN level_bosses b ON l.id = b.level_id JOIN entities e ON e.id = b.entity_id;",
             "```", ""]
    (DEST / "README.md").write_text("\n".join(lines), encoding="utf-8")
    credits = ["# Act II source credits and provenance", "",
               "The literary source is H. G. Wells's *The War of the Worlds* (1898). Chapter citations refer to that novel, with source editions recorded below. These records summarize observations and design proposals; they do not reproduce a modern adaptation's character designs or visual assets.", "",
               "Generated art is newly commissioned game concept work. It is not archival illustration, evidence of a historical production, or implemented gameplay. Original generation prompts and source relationships remain in the manifest and catalogue. No external reference-image pixels are embedded in this library.", ""]
    for source in payload["sources"]:
        credits += [f"## {source['id']} — {source['title']}", "",
                    f"- Source type: {source['kind']}.",
                    f"- Creator: {source.get('author', source.get('creator', 'See source publication'))}.",
                    f"- Publisher / institution: {source.get('publisher', 'See linked source')}.",
                    f"- Publication / edition date: {source.get('date', source.get('publication_date', 'See source'))}.",
                    f"- Accessed: {source['accessed_date']}."]
        if source.get("url"):
            credits.append(f"- [Source publication]({source['url']}).")
        if source.get("notes"):
            credits.append(f"- Note: {source['notes']}")
        credits.append("")
    credits += ["## Generated concept art", "", "Each artwork records its prompt, linked novel entities, source IDs, availability, and local SHA-256 hash in [catalog.json](catalog.json). The editable generation source is [generated-manifest.json](../../concept-art/act2/generated-manifest.json).", ""]
    for art in payload["artworks"]:
        availability = "available" if art["file_exists"] else "planned / unavailable"
        credits.append(f"- **{art['id']} — {art['title']}**: {art['category']}; {availability}; game proposal.")
    (DEST / "CREDITS.md").write_text("\n".join(credits), encoding="utf-8")


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--strict-art", action="store_true", help="Fail if any manifest image is unavailable")
    args = parser.parse_args()
    sources, sources_meta = read_records(RESEARCH / "sources.json", "sources")
    entities, entities_meta = read_records(RESEARCH / "entities.json", "entities")
    artworks, artworks_meta = read_records(ART_ROOT / "generated-manifest.json", "artworks", required=args.strict_art)
    if args.strict_art and not artworks:
        raise ValueError("Strict art verification requires a nonempty generation manifest.")
    warnings = normalize(sources, entities, artworks, args.strict_art)
    level_plan = load_level_plan(entities)
    all_ids = [record["id"] for record in sources + entities + artworks]
    if len(all_ids) != len(set(all_ids)):
        raise ValueError("IDs must be unique across sources, entities and artworks")
    counts = {"entities": len(entities), "sources": len(sources), "artworks": len(artworks),
              "available_artworks": sum(art["file_exists"] for art in artworks),
              "gameplay_images": sum(art["file_exists"] and art["category"] == "gameplay" for art in artworks),
              "entity_categories": dict(Counter(entity["category"] for entity in entities)),
              "art_categories": dict(Counter(art["category"] for art in artworks)),
              "canon_status": dict(Counter(entity["canon_status"] for entity in entities))}
    payload = {"schema_version": 1, "title": "Act II — The War of the Worlds",
               "novel": "The War of the Worlds", "author": "H. G. Wells", "publication_year": 1898,
               "research_date": DATE, "counts": counts, "entities": entities, "sources": sources,
               "artworks": artworks, "source_metadata": sources_meta, "research_metadata": entities_meta,
               "art_metadata": artworks_meta, "build_warnings": warnings}
    payload["level_plan"] = level_plan
    if level_plan:
        counts.update({"main_levels": len(level_plan.get("levels", [])),
                       "optional_levels": len(level_plan.get("optional_levels", [])),
                       "main_target_minutes": level_plan.get("main_first_clear_target_minutes")})
    DEST.mkdir(parents=True, exist_ok=True)
    write_database(payload)
    write_json(DEST / "catalog.json", payload)
    (DEST / "catalog-data.js").write_text("window.INVASION_LIBRARY = " + json.dumps(payload, ensure_ascii=False).replace("</", "<\\/") + ";\n", encoding="utf-8")
    write_csv(payload)
    write_readme(payload)
    print(json.dumps({"counts": counts, "warnings": warnings, "sqlite_integrity": "ok"}, ensure_ascii=False, indent=2))


if __name__ == "__main__":
    main()
