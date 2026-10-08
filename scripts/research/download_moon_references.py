"""Collect individually sourced still images; never download the film itself."""
from html import unescape
import json
from pathlib import Path
import re
from time import sleep
from urllib.parse import urlencode, quote, urlparse
from urllib.error import HTTPError
from urllib.request import Request, urlopen

ROOT = Path(__file__).resolve().parents[2]
DEST = ROOT / "docs/reference-library/act1"
API = "https://commons.wikimedia.org/w/api.php"
AGENT = "CinderReferenceResearch/1.0 (personal game design reference archive)"


def get_json(params):
    params.update(format="json", formatversion="2")
    request = Request(API + "?" + urlencode(params), headers={"User-Agent": AGENT})
    with urlopen(request, timeout=35) as response:
        return json.load(response)


def plain(value):
    return re.sub(r"\s+", " ", unescape(re.sub(r"<[^>]*>", " ", value or ""))).strip()


def main():
    (DEST / "film-stills").mkdir(parents=True, exist_ok=True)
    result = get_json({"action": "query", "list": "categorymembers",
                       "cmtitle": "Category:Le voyage dans la lune (film screenshots)",
                       "cmtype": "file", "cmlimit": "100"})
    titles = [entry["title"] for entry in result["query"]["categorymembers"]]
    titles += ["File:" + name for name in [
        "Méliès Trip to the Moon cannon still.jpg",
        "Méliès Trip to the Moon planets still.jpg",
        "Méliès Trip to the Moon stars still.jpg",
        "Voyage dans la Lune cliff still.jpg",
        "Le voyage dans la lune drawing.jpg",
        "Le Voyage dans la Lune Selenite drawing.jpg",
        "Voyage dans la Lune affiche.jpg",
    ]]
    pages = get_json({"action": "query", "titles": "|".join(titles),
                      "prop": "imageinfo", "iiprop": "url|size|sha1|extmetadata",
                      "iiurlwidth": "500"})["query"]["pages"]
    small_titles = [p["title"] for p in pages if p.get("imageinfo", [{}])[0].get("width", 1000) <= 500]
    if small_titles:
        small_pages = get_json({"action": "query", "titles": "|".join(small_titles),
                               "prop": "imageinfo", "iiprop": "url|size|sha1|extmetadata",
                               "iiurlwidth": "250"})["query"]["pages"]
        by_title = {p["title"]: p for p in small_pages}
        pages = [by_title.get(p["title"], p) for p in pages]
    records = []
    archive_index = 0
    for page in sorted(pages, key=lambda p: p["title"]):
        if "imageinfo" not in page:
            print("Missing image metadata:", page["title"], flush=True)
            continue
        info = page["imageinfo"][0]
        meta = info.get("extmetadata", {})
        def field(name):
            return plain(meta.get(name, {}).get("value", ""))
        numbered = re.search(r"\(1902\) (\d\d)\.jpg$", page["title"])
        if numbered:
            identifier = "F" + numbered.group(1)
        else:
            archive_index += 1
            identifier = f"A{archive_index:02d}"
        extension = Path(urlparse(info["url"]).path).suffix.lower()
        local_path = "film-stills/" + identifier.lower() + extension
        # Later historical drawings have distinct provenance/rights ambiguity.
        # Keep their source records but do not copy them into the repository.
        link_only = "drawing" in page["title"].lower()
        record = {
            "id": identifier, "title": page["title"][5:], "record_type": "archive-image",
            "source_page": info.get("descriptionurl", "https://commons.wikimedia.org/wiki/" + quote(page["title"])),
            "original_url": info["url"], "download_url": info.get("thumburl", info["url"]),
            "width": info["width"], "height": info["height"],
            "bytes": info["size"], "sha1": info.get("sha1", ""),
            "creator": field("Artist"), "description": field("ImageDescription"),
            "metadata_date": field("DateTimeOriginal"), "license_label": field("LicenseShortName"),
            "license_url": field("LicenseUrl"), "copyrighted_metadata": field("Copyrighted"),
            "credit": field("Credit"), "attribution": field("Attribution"),
            "local_path": None if link_only else local_path, "access": "link-only" if link_only else "local",
            "retrieved_date": "2026-10-08", "raw_metadata": meta,
        }
        records.append(record)
    def download(record):
        if not record["local_path"]:
            return record["id"] + ": source record only"
        target = DEST / record["local_path"]
        legacy = next(target.parent.glob(target.stem + ".org*"), None)
        if legacy and not target.exists():
            legacy.rename(target)
        if target.exists():
            return record["id"] + ": already present"
        request = Request(record["download_url"], headers={"User-Agent": AGENT})
        with urlopen(request, timeout=35) as response:
            content = response.read(8_000_001)
        if len(content) > 8_000_000:
            raise ValueError("Unexpectedly large still: " + record["id"])
        target.write_bytes(content)
        return f'{record["id"]}: {len(content):,} bytes'
    manifest = DEST / "commons-manifest.json"
    manifest.write_text(json.dumps(records, ensure_ascii=False, indent=2) + "\n")
    for record in records:
        try:
            print(download(record), flush=True)
        except (HTTPError, OSError) as error:
            record["download_error"] = str(error)
            print(record["id"] + ": " + str(error), flush=True)
            if isinstance(error, HTTPError) and error.code == 429:
                # Respect server throttling: stop this run, preserve source records.
                break
        sleep(1)
    (DEST / "commons-manifest.json").write_text(json.dumps(records, ensure_ascii=False, indent=2) + "\n")
    print(f"Saved metadata for {len(records)} archive images.", flush=True)


if __name__ == "__main__":
    main()
