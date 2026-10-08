"""Rebuild the offline Act III research, art and level library.

Python's standard library is sufficient. Research JSON and the generation
manifest are the editable source records; generated exports never replace them.
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
DEST = ROOT / "docs/reference-library/act3"
ART_ROOT = ROOT / "docs/concept-art/act3"
RESEARCH = DEST / "research"
DATE = "2026-10-08"
CANON = {"novel_fact", "interpretation", "game_proposal"}


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
        if not isinstance(record, dict):
            raise ValueError(f"Every {kind} must be an object")
        identifier = str(record.get("id", "")).strip()
        if not identifier or identifier in result:
            raise ValueError(f"Missing or duplicate {kind} ID: {identifier!r}")
        record["id"] = identifier
        result[identifier] = record
    return result


def chapter_record(value) -> dict:
    if isinstance(value, str):
        return {"label": value, "book": "", "chapter": "", "title": "", "note": ""}
    if not isinstance(value, dict):
        raise ValueError(f"Chapter reference must be a string or object: {value!r}")
    result = dict(value)
    result.setdefault("book", value.get("part", ""))
    result.setdefault("chapter", value.get("number", ""))
    result.setdefault("title", value.get("chapter_title", ""))
    result.setdefault("note", value.get("notes", ""))
    result.setdefault("label", " · ".join(str(part) for part in (
        f"Book {result['book']}" if result["book"] else "",
        f"Chapter {result['chapter']}" if result["chapter"] else "",
        result["title"]) if part))
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
        raise ValueError(f"Artwork must be inside docs/concept-art/act3: {value}")
    return target


def dimensions(path: Path) -> tuple[int | None, int | None]:
    """Read PNG, GIF, JPEG and WebP dimensions without external dependencies."""
    with path.open("rb") as stream:
        header = stream.read(32)
        if header.startswith(b"\x89PNG\r\n\x1a\n") and len(header) >= 24:
            return struct.unpack(">II", header[16:24])
        if header[:6] in (b"GIF87a", b"GIF89a"):
            return struct.unpack("<HH", header[6:10])
        if header[:4] == b"RIFF" and header[8:12] == b"WEBP":
            if header[12:16] == b"VP8X" and len(header) >= 30:
                return 1 + int.from_bytes(header[24:27], "little"), 1 + int.from_bytes(header[27:30], "little")
            if header[12:16] == b"VP8L" and header[20:21] == b"\x2f":
                bits = int.from_bytes(header[21:25], "little")
                return (bits & 0x3FFF) + 1, ((bits >> 14) & 0x3FFF) + 1
            if header[12:16] == b"VP8 " and header[23:26] == b"\x9d\x01\x2a":
                width, height = struct.unpack("<HH", header[26:30])
                return width & 0x3FFF, height & 0x3FFF
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
                if length < 2:
                    break
                stream.seek(length - 2, 1)
    return None, None


def links(record: dict, field: str, index: dict, kind: str) -> list[str]:
    values = list(dict.fromkeys(as_list(record.get(field))))
    for value in values:
        if value not in index:
            raise ValueError(f"Unknown {kind} {value!r} on {record['id']} ({field})")
    record[field] = values
    return values


def normalize(sources: list, entities: list, artworks: list, levels: list, strict_art: bool) -> list[str]:
    warnings = []
    source_index, entity_index = unique(sources, "source"), unique(entities, "entity")
    art_index, level_index = unique(artworks, "artwork"), unique(levels, "level")
    all_ids = list(source_index) + list(entity_index) + list(art_index) + list(level_index)
    if len(all_ids) != len(set(all_ids)):
        raise ValueError("IDs must be unique across sources, entities, artworks and levels")
    if not sources or not entities:
        raise ValueError("Research must contain cited sources and entities")
    for source in sources:
        source.setdefault("title", source.get("name", source["id"]))
        source.setdefault("kind", source.get("source_type", "reference"))
        source.setdefault("accessed_date", source.get("accessed", DATE))
        source.setdefault("url", "")
        if source["url"] and not source["url"].startswith(("https://", "http://")):
            raise ValueError(f"Source {source['id']} has an unsupported URL")
    for entity in entities:
        entity.setdefault("title", entity.get("name", entity["id"]))
        entity.setdefault("name", entity["title"])
        entity.setdefault("category", "characters")
        if entity["category"] == "moods":
            entity["source_category"] = "moods"
            entity["category"] = "mood"
        entity.setdefault("subcategory", entity.get("entity_type", entity.get("type", "")))
        entity.setdefault("canon_status", "interpretation")
        if entity["canon_status"] not in CANON:
            raise ValueError(f"Unknown provenance on {entity['id']}: {entity['canon_status']}")
        entity.setdefault("description", "")
        entity.setdefault("game_adaptation", entity.get("act3_role", ""))
        entity.setdefault("notes", "")
        entity["tags"] = as_list(entity.get("tags"))
        links(entity, "source_ids", source_index, "source")
        links(entity, "related_entity_ids", entity_index, "entity")
        if entity.get("identity_parent_id") and entity["identity_parent_id"] not in entity_index:
            raise ValueError(f"Unknown identity parent on {entity['id']}")
        entity["chapter_refs"] = [chapter_record(ref) for ref in as_list(entity.get("chapter_refs"))]
        entity["artwork_ids"], entity["level_ids"] = [], []
        for chapter in entity["chapter_refs"]:
            if chapter.get("source_id") and chapter["source_id"] not in source_index:
                raise ValueError(f"Unknown chapter source on {entity['id']}")
        if entity["canon_status"] == "novel_fact" and not entity["source_ids"]:
            raise ValueError(f"Novel fact {entity['id']} has no source attribution")
    for artwork in artworks:
        artwork.setdefault("title", artwork.get("name", artwork["id"]))
        artwork.setdefault("category", "environments")
        artwork.setdefault("kind", "gameplay-mockup" if artwork["category"] == "gameplay" else "concept-sheet")
        for field in ("description", "notes", "prompt"):
            artwork.setdefault(field, "")
        artwork.setdefault("canon_status", "game_proposal")
        if artwork["canon_status"] != "game_proposal":
            raise ValueError(f"Generated concept art must be a game proposal: {artwork['id']}")
        artwork["tags"] = as_list(artwork.get("tags"))
        if "entity_ids" not in artwork:
            artwork["entity_ids"] = artwork.get("reference_ids", [])
        links(artwork, "entity_ids", entity_index, "entity")
        source_ids = as_list(artwork.get("source_ids"))
        for entity_id in artwork["entity_ids"]:
            entity = entity_index[entity_id]
            entity["artwork_ids"].append(artwork["id"])
            source_ids.extend(entity["source_ids"])
        artwork["source_ids"] = source_ids
        links(artwork, "source_ids", source_index, "source")
        path = resolve_art_path(artwork.get("local_path"))
        artwork["repo_path"] = path.relative_to(ROOT).as_posix() if path else None
        artwork["file_exists"] = bool(path and path.is_file())
        artwork["local_path"] = Path(os.path.relpath(path, DEST)).as_posix() if path else None
        artwork["manifest_status"] = artwork.get("status", "planned")
        artwork["status"] = artwork["manifest_status"]
        artwork["sha256"] = artwork["file_bytes"] = artwork["width"] = artwork["height"] = None
        if artwork["file_exists"]:
            artwork["sha256"] = hashlib.sha256(path.read_bytes()).hexdigest()
            artwork["file_bytes"] = path.stat().st_size
            artwork["width"], artwork["height"] = dimensions(path)
            if not artwork["width"] or not artwork["height"]:
                raise ValueError(f"Unsupported or invalid image: {artwork['repo_path']}")
            if artwork["manifest_status"] != "generated":
                artwork["status"] = "local_unconfirmed"
                warnings.append(f"Image {artwork['id']} exists but the manifest has not confirmed generation")
        else:
            artwork["status"] = "unavailable" if artwork["manifest_status"] == "generated" else artwork["manifest_status"]
            warnings.append(f"Image {artwork['id']} is unavailable: {artwork.get('repo_path') or 'no path'}")
        artwork["level_ids"] = []
        if strict_art and (not artwork["file_exists"] or artwork["status"] != "generated"):
            raise ValueError(f"Strict art check failed: {artwork['id']} ({artwork['status']})")
    for position, level in enumerate(levels):
        level.setdefault("title", level.get("name", level["id"]))
        level.setdefault("name", level["title"])
        level.setdefault("order", position + 1)
        level.setdefault("kind", "main")
        if level.get("parent_level_id") and level["parent_level_id"] not in level_index:
            raise ValueError(f"Unknown parent level on {level['id']}: {level['parent_level_id']}")
        level.setdefault("category", "levels")
        level.setdefault("canon_status", "game_proposal")
        level.setdefault("description", level.get("objective", ""))
        level["tags"] = as_list(level.get("tags"))
        level.setdefault("notes", "")
        level.setdefault("target_minutes", level.get("initial_budget_minutes"))
        if level["target_minutes"] is not None and (not isinstance(level["target_minutes"], (int, float)) or level["target_minutes"] <= 0):
            raise ValueError(f"Invalid target_minutes on {level['id']}")
        level["entity_ids"] = list(dict.fromkeys(as_list(level.get("entity_ids")) + as_list(level.get("enemy_ids")) + as_list(level.get("boss_ids"))))
        links(level, "entity_ids", entity_index, "entity")
        for field in ("enemy_ids", "boss_ids"):
            if field in level:
                links(level, field, entity_index, "entity")
        level["artwork_ids"] = list(dict.fromkeys(as_list(level.get("artwork_ids")) + [art["id"] for art in artworks if set(art["entity_ids"]) & set(level["entity_ids"])]))
        links(level, "artwork_ids", art_index, "artwork")
        linked_sources = as_list(level.get("source_ids"))
        for entity_id in level["entity_ids"]:
            entity_index[entity_id]["level_ids"].append(level["id"])
            linked_sources.extend(entity_index[entity_id]["source_ids"])
        level["source_ids"] = linked_sources
        links(level, "source_ids", source_index, "source")
        for artwork_id in level["artwork_ids"]:
            art_index[artwork_id]["level_ids"].append(level["id"])
        level["beats"] = as_list(level.get("beats"))
        previous_checkpoint = 0
        elapsed = 0
        for beat in level["beats"]:
            if not isinstance(beat, dict):
                raise ValueError(f"Every beat on {level['id']} must be an object")
            seconds = beat.get("seconds")
            if seconds is not None:
                if not isinstance(seconds, (int, float)) or seconds < 0:
                    raise ValueError(f"Invalid beat duration on {level['id']}")
                elapsed += seconds
            checkpoint = beat.get("checkpoint_elapsed_seconds")
            if checkpoint is not None:
                if not isinstance(checkpoint, (int, float)) or checkpoint < previous_checkpoint:
                    raise ValueError(f"Invalid checkpoint order on {level['id']}")
                previous_checkpoint = checkpoint
        level["beat_seconds"] = elapsed
        if elapsed and level["target_minutes"] and abs(elapsed - level["target_minutes"] * 60) > 1:
            warnings.append(f"Level {level['id']} beat durations total {elapsed / 60:g} minutes; target is {level['target_minutes']:g}")
    return warnings


def write_json(path: Path, payload):
    path.write_text(json.dumps(payload, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")


def write_csv(payload: dict):
    columns = ["id", "record_type", "title", "category", "subcategory", "kind", "canon_status", "description", "game_adaptation", "chapter_refs", "source_ids", "entity_ids", "artwork_ids", "level_ids", "tags", "notes", "local_path", "status", "file_exists", "sha256", "file_bytes", "width", "height", "target_minutes", "data_json"]
    with (DEST / "catalog.csv").open("w", newline="", encoding="utf-8") as output:
        writer = csv.DictWriter(output, fieldnames=columns, lineterminator="\n")
        writer.writeheader()
        for kind, records in (("entity", payload["entities"]), ("artwork", payload["artworks"]), ("level", payload["levels"])):
            for record in records:
                values = {**record, "record_type": kind, "data_json": record}
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
                related_entity_id TEXT NOT NULL REFERENCES entities(id),
                PRIMARY KEY(entity_id, related_entity_id));
            CREATE TABLE name_index (name TEXT NOT NULL, entity_id TEXT NOT NULL REFERENCES entities(id),
                identity_group_id TEXT, identity_parent_id TEXT REFERENCES entities(id), scope TEXT,
                data_json TEXT NOT NULL, PRIMARY KEY(name,entity_id));
            CREATE TABLE chapter_refs (id INTEGER PRIMARY KEY, entity_id TEXT NOT NULL REFERENCES entities(id),
                position INTEGER NOT NULL, label TEXT, book TEXT, chapter TEXT, title TEXT, note TEXT,
                source_id TEXT REFERENCES sources(id), data_json TEXT NOT NULL);
            CREATE TABLE novel_chapters (source_id TEXT NOT NULL REFERENCES sources(id), chapter INTEGER NOT NULL,
                title TEXT NOT NULL, url TEXT, words INTEGER, data_json TEXT NOT NULL,
                PRIMARY KEY(source_id, chapter));
            CREATE TABLE artworks (id TEXT PRIMARY KEY, title TEXT NOT NULL, category TEXT NOT NULL,
                kind TEXT NOT NULL, description TEXT, canon_status TEXT NOT NULL, local_path TEXT,
                repo_path TEXT, status TEXT NOT NULL, file_exists INTEGER NOT NULL CHECK(file_exists IN (0, 1)),
                sha256 TEXT, file_bytes INTEGER, width INTEGER, height INTEGER, prompt TEXT,
                notes TEXT, data_json TEXT NOT NULL);
            CREATE TABLE artwork_entities (artwork_id TEXT NOT NULL REFERENCES artworks(id),
                entity_id TEXT NOT NULL REFERENCES entities(id), PRIMARY KEY(artwork_id, entity_id));
            CREATE TABLE artwork_sources (artwork_id TEXT NOT NULL REFERENCES artworks(id),
                source_id TEXT NOT NULL REFERENCES sources(id), PRIMARY KEY(artwork_id, source_id));
            CREATE TABLE levels (id TEXT PRIMARY KEY, title TEXT NOT NULL, position INTEGER NOT NULL,
                target_minutes REAL CHECK(target_minutes > 0), objective TEXT, skill TEXT, mood TEXT,
                canon_status TEXT NOT NULL, kind TEXT NOT NULL, parent_level_id TEXT REFERENCES levels(id),
                data_json TEXT NOT NULL);
            CREATE TABLE level_entities (level_id TEXT NOT NULL REFERENCES levels(id),
                entity_id TEXT NOT NULL REFERENCES entities(id), PRIMARY KEY(level_id, entity_id));
            CREATE TABLE level_artworks (level_id TEXT NOT NULL REFERENCES levels(id),
                artwork_id TEXT NOT NULL REFERENCES artworks(id), PRIMARY KEY(level_id, artwork_id));
            CREATE TABLE level_sources (level_id TEXT NOT NULL REFERENCES levels(id),
                source_id TEXT NOT NULL REFERENCES sources(id), PRIMARY KEY(level_id, source_id));
            CREATE TABLE level_beats (id INTEGER PRIMARY KEY, level_id TEXT NOT NULL REFERENCES levels(id),
                position INTEGER NOT NULL, name TEXT, seconds REAL CHECK(seconds >= 0),
                checkpoint_elapsed_seconds REAL CHECK(checkpoint_elapsed_seconds >= 0), purpose TEXT,
                data_json TEXT NOT NULL);
            CREATE TABLE search_records (id TEXT PRIMARY KEY, record_type TEXT NOT NULL, title TEXT NOT NULL,
                category TEXT NOT NULL, canon_status TEXT NOT NULL, search_text TEXT NOT NULL);
            CREATE INDEX entities_category ON entities(category);
            CREATE INDEX entities_canon ON entities(canon_status);
            CREATE INDEX artworks_category ON artworks(category);
            CREATE INDEX chapters_entity ON chapter_refs(entity_id);
            CREATE INDEX beats_level ON level_beats(level_id);
        """)
        dump = lambda value: json.dumps(value, ensure_ascii=False)
        for key, value in payload.items():
            if key not in {"sources", "entities", "artworks", "levels", "chapters", "name_index"}:
                db.execute("INSERT INTO metadata VALUES (?, ?)", (key, dump(value)))
        for source in payload["sources"]:
            db.execute("INSERT INTO sources VALUES (?, ?, ?, ?, ?, ?)",
                       (source["id"], source["title"], source["url"], source["kind"], source["accessed_date"], dump(source)))
        for chapter in payload["chapters"]:
            db.execute("INSERT INTO novel_chapters VALUES (?,?,?,?,?,?)", (chapter["source_id"], chapter["chapter"], chapter["title"], chapter.get("url"), chapter.get("words"), dump(chapter)))
        for entity in payload["entities"]:
            db.execute("INSERT INTO entities VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)",
                       (entity["id"], entity["title"], entity["category"], entity["subcategory"], entity["canon_status"], entity["description"], entity["game_adaptation"], dump(entity["notes"]) if not isinstance(entity["notes"], str) else entity["notes"], dump(entity["tags"]), dump(entity)))
            for source_id in entity["source_ids"]:
                db.execute("INSERT INTO entity_sources VALUES (?, ?)", (entity["id"], source_id))
            for index, chapter in enumerate(entity["chapter_refs"]):
                db.execute("INSERT INTO chapter_refs (entity_id,position,label,book,chapter,title,note,source_id,data_json) VALUES (?,?,?,?,?,?,?,?,?)",
                           (entity["id"], index, chapter["label"], str(chapter["book"]), str(chapter["chapter"]), chapter["title"], chapter["note"], chapter.get("source_id"), dump(chapter)))
        for art in payload["artworks"]:
            db.execute("INSERT INTO artworks VALUES (?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?)",
                       (art["id"], art["title"], art["category"], art["kind"], art["description"], art["canon_status"], art["local_path"], art["repo_path"], art["status"], int(art["file_exists"]), art["sha256"], art["file_bytes"], art["width"], art["height"], art["prompt"], dump(art["notes"]) if not isinstance(art["notes"], str) else art["notes"], dump(art)))
            for entity_id in art["entity_ids"]:
                db.execute("INSERT INTO artwork_entities VALUES (?,?)", (art["id"], entity_id))
            for source_id in art["source_ids"]:
                db.execute("INSERT INTO artwork_sources VALUES (?,?)", (art["id"], source_id))
        for entity in payload["entities"]:
            for related_id in entity["related_entity_ids"]:
                db.execute("INSERT INTO entity_relations VALUES (?,?)", (entity["id"], related_id))
        for name in payload["name_index"]:
            db.execute("INSERT INTO name_index VALUES (?,?,?,?,?,?)", (name["name"], name["entity_id"], name.get("identity_group_id"), name.get("identity_parent_id"), name.get("scope", ""), dump(name)))
        for level in payload["levels"]:
            db.execute("INSERT INTO levels VALUES (?,?,?,?,?,?,?,?,?,?,?)", (level["id"], level["title"], level["order"], level["target_minutes"], level.get("objective", ""), level.get("skill", ""), level.get("mood", ""), level["canon_status"], level["kind"], level.get("parent_level_id"), dump(level)))
            for field, table in (("entity_ids", "level_entities"), ("artwork_ids", "level_artworks"), ("source_ids", "level_sources")):
                for identifier in level[field]:
                    db.execute(f"INSERT INTO {table} VALUES (?,?)", (level["id"], identifier))
            for position, beat in enumerate(level["beats"]):
                db.execute("INSERT INTO level_beats (level_id,position,name,seconds,checkpoint_elapsed_seconds,purpose,data_json) VALUES (?,?,?,?,?,?,?)", (level["id"], position, beat.get("name", ""), beat.get("seconds"), beat.get("checkpoint_elapsed_seconds"), beat.get("purpose", ""), dump(beat)))
        for kind, records in (("entity", payload["entities"]), ("artwork", payload["artworks"]), ("level", payload["levels"])):
            for record in records:
                db.execute("INSERT INTO search_records VALUES (?,?,?,?,?,?)", (record["id"], kind, record["title"], record["category"], record["canon_status"], dump({key: value for key, value in record.items() if key not in {"sha256", "prompt", "local_path", "repo_path"}})))
        fts = False
        try:
            db.execute("CREATE VIRTUAL TABLE search_fts USING fts5(id UNINDEXED, record_type UNINDEXED, title, search_text)")
            db.execute("INSERT INTO search_fts SELECT id,record_type,title,search_text FROM search_records")
            fts = True
        except sqlite3.OperationalError as error:
            if "no such module: fts5" not in str(error).lower():
                raise
        db.execute("INSERT INTO metadata VALUES (?,?)", ("full_text_search_available", dump(fts)))
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
    (DEST / "README.md").write_text(f'''# Act III — A Voyage to Arcturus

Open [index.html](index.html) for the searchable, offline story database, concept-art gallery and level plan. Keep `catalog-data.js` beside it. No install, server or internet connection is needed for the library; source publications open online.

This build contains **{counts['entities']} story/design records**, **{counts['sources']} cited sources**, **{counts['available_artworks']} available concept images**, and **{counts['main_levels']} main + {counts['optional_levels']} optional proposed levels**. The **{counts['gameplay_images']} game views** are illustrative gameplay concepts, not captures of an implemented Act III campaign.

The library labels **Novel fact**, **Interpretation**, and **Game proposal** separately. Source descriptions and chapter references summarize David Lindsay's 1920 novel; adaptation notes, bosses, invented forms, concrete appearances and generated art are proposals. See [research scope and limitations](research/RESEARCH.md) for the character-inventory boundary and edition notes.

## Files

- [JSON database](catalog.json): full research, art, level plan, joins, metadata and provenance.
- [CSV database](catalog.csv): entities, artworks and levels; arrays and full records are JSON inside cells.
- [SQLite database](library.sqlite): relational records, source and chapter joins, levels and beat/checkpoint tables. `search_records` always exists; `search_fts` is included when the Python SQLite runtime supports FTS5.
- [Research entities](research/entities.json), [source list](research/sources.json) and [level source](research/levels.json): editable inputs.
- [Novel chapter registry](research/chapters.json): chapter URLs and source IDs, also exported in JSON and SQLite.
- [Name and alias index](research/name-index.json): merged aliases, shared identities and group records, also exported in JSON and SQLite.
- [Research summary](research/RESEARCH.md) and [source notes](research/SOURCES.md).
- [Concept-art folder](../../concept-art/act3/README.md) and [generation manifest](../../concept-art/act3/generated-manifest.json).
- [Act III concept](../../ACT3_CONCEPT.md): experienced-player pacing and adaptation rationale.

## Rebuild

From the repository root:

```sh
python3 scripts/research/build_arcturus_library.py
python3 scripts/research/build_arcturus_library.py --strict-art
```

The default build retains planned or unavailable art and reports it truthfully. `--strict-art` requires every manifest image to exist, have readable image dimensions, and have `status: generated` confirmed in the source manifest. File existence alone never changes a planned record into generated art.

The builder validates IDs, source and entity links, level links, safe image paths, beat durations and checkpoint order; records file dimensions, byte sizes and SHA-256 hashes; and runs SQLite foreign-key and integrity checks. It uses only Python's standard library. Generated files can be rebuilt without changing the research inputs.

## Query examples

```sql
SELECT id, title FROM entities WHERE category = 'characters';
SELECT name, entity_id, identity_group_id, identity_parent_id FROM name_index ORDER BY name;
SELECT id, title, game_adaptation FROM entities WHERE category = 'bosses';
SELECT e.title, c.label FROM entities e JOIN chapter_refs c ON e.id = c.entity_id;
SELECT e.title, s.title, s.url FROM entities e JOIN entity_sources es ON e.id = es.entity_id JOIN sources s ON s.id = es.source_id;
SELECT a.title, e.title FROM artworks a JOIN artwork_entities ae ON a.id = ae.artwork_id JOIN entities e ON e.id = ae.entity_id;
SELECT l.title, b.name, b.seconds, b.checkpoint_elapsed_seconds FROM levels l JOIN level_beats b ON l.id = b.level_id ORDER BY l.position, b.position;
SELECT id, title FROM search_records WHERE lower(search_text) LIKE '%crystalman%';
SELECT id, title FROM search_fts WHERE search_fts MATCH 'Maskull';
```
''', encoding="utf-8")


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--strict-art", action="store_true", help="Require all listed artwork to be confirmed generated and locally available")
    args = parser.parse_args()
    sources, sources_meta = read_records(RESEARCH / "sources.json", "sources")
    entities, entities_meta = read_records(RESEARCH / "entities.json", "entities")
    chapters, _ = read_records(RESEARCH / "chapters.json", "chapters", required=False)
    name_index, _ = read_records(RESEARCH / "name-index.json", "names", required=False)
    levels, levels_meta = read_records(RESEARCH / "levels.json", "levels")
    for level in levels:
        level.setdefault("kind", "main")
    optional_levels = levels_meta.get("optional_levels", [])
    if not isinstance(optional_levels, list):
        raise ValueError("optional_levels must be an array")
    for level in optional_levels:
        level.setdefault("kind", "optional")
    levels += optional_levels
    artworks, artworks_meta = read_records(ART_ROOT / "generated-manifest.json", "artworks", required=args.strict_art)
    if args.strict_art and not artworks:
        raise ValueError("Strict art verification requires a nonempty generation manifest")
    if not levels:
        raise ValueError("Level source must contain proposed levels")
    warnings = normalize(sources, entities, artworks, levels, args.strict_art)
    entity_index = {entity["id"]: entity for entity in entities}
    name_pairs = set()
    for name in name_index:
        if not isinstance(name, dict) or not name.get("name") or name.get("entity_id") not in entity_index:
            raise ValueError(f"Invalid name index record: {name!r}")
        if name.get("identity_parent_id") and name["identity_parent_id"] not in entity_index:
            raise ValueError(f"Unknown identity parent on name index record: {name!r}")
        pair = (name["name"], name["entity_id"])
        if pair in name_pairs:
            raise ValueError(f"Duplicate name/entity pair in name index: {pair!r}")
        name_pairs.add(pair)
    source_index = {source["id"]: source for source in sources}
    chapter_index = {}
    for chapter in chapters:
        if not isinstance(chapter, dict) or not isinstance(chapter.get("chapter"), int) or chapter["chapter"] < 1:
            raise ValueError("Chapter registry entries must have positive integer chapter numbers")
        if chapter.get("source_id") not in source_index:
            raise ValueError(f"Unknown source on chapter registry record: {chapter}")
        key = (chapter["source_id"], chapter["chapter"])
        if key in chapter_index:
            raise ValueError(f"Duplicate chapter registry entry: {key}")
        chapter_index[key] = chapter
    for entity in entities:
        for ref in entity["chapter_refs"]:
            number = str(ref.get("chapter", ""))
            if not number:
                match = re.search(r"\b(?:chapter|ch\.?)\s*(\d+)\b", ref.get("label", ""), re.IGNORECASE)
                number = match.group(1) if match else ""
            if number.isdigit():
                source_id = ref.get("source_id") or next((sid for sid in entity["source_ids"] if (sid, int(number)) in chapter_index), None)
                chapter = chapter_index.get((source_id, int(number)))
                if chapter:
                    ref.setdefault("url", chapter.get("url", ""))
                    ref.setdefault("source_id", source_id)
                    if not ref["chapter"]:
                        ref["chapter"] = int(number)
                    if not ref["title"]:
                        ref["title"] = chapter["title"]
    counts = {"entities": len(entities), "sources": len(sources), "artworks": len(artworks), "levels": len(levels),
              "main_levels": sum(level["kind"] == "main" for level in levels),
              "optional_levels": sum(level["kind"] == "optional" for level in levels),
              "available_artworks": sum(art["file_exists"] for art in artworks),
              "generated_artworks": sum(art["status"] == "generated" and art["file_exists"] for art in artworks),
              "gameplay_images": sum(art["file_exists"] and art["category"] == "gameplay" for art in artworks),
              "target_minutes": sum(level.get("target_minutes") or 0 for level in levels),
              "main_target_minutes": sum(level.get("target_minutes") or 0 for level in levels if level["kind"] == "main"),
              "entity_categories": dict(Counter(entity["category"] for entity in entities)),
              "art_categories": dict(Counter(art["category"] for art in artworks)),
              "canon_status": dict(Counter(entity["canon_status"] for entity in entities))}
    payload = {"schema_version": 2, "title": "Act III — A Voyage to Arcturus",
               "novel": "A Voyage to Arcturus", "author": "David Lindsay", "publication_year": 1920,
               "research_date": DATE, "counts": counts, "entities": entities, "sources": sources,
               "artworks": artworks, "levels": levels, "chapters": chapters, "name_index": name_index, "source_metadata": sources_meta,
               "research_metadata": entities_meta, "art_metadata": artworks_meta,
               "level_metadata": levels_meta, "build_warnings": warnings}
    DEST.mkdir(parents=True, exist_ok=True)
    write_database(payload)
    write_json(DEST / "catalog.json", payload)
    (DEST / "catalog-data.js").write_text("window.ARCTURUS_LIBRARY = " + json.dumps(payload, ensure_ascii=False).replace("</", "<\\/") + ";\n", encoding="utf-8")
    write_csv(payload)
    write_readme(payload)
    print(json.dumps({"counts": counts, "warnings": warnings, "sqlite_integrity": "ok"}, ensure_ascii=False, indent=2))


if __name__ == "__main__":
    main()
