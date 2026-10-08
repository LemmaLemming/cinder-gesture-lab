# Exact snapshot JSON transport

`exact-json-1` is a closed JSON-value transport implemented in [exact_json.gd](../../scripts/campaign/exact_json.gd). It preserves native finite binary64 bits, including signed zero and subnormal values, and distinguishes integers from floats. JSON remains the outer textual format; numerical payloads do not pass through decimal-to-float parsing.

```gdscript
const ExactJson = preload("res://scripts/campaign/exact_json.gd")
var encoded: String = ExactJson.stringify(pair)
if encoded.is_empty():
    return false
var decoded: Dictionary = ExactJson.parse(encoded)
if not decoded.accepted:
    return false
# Validate the complete decoded.value with the actual paused bindings before
# committing any actor, scheduler or local component.
```

The envelope declares `api_revision`, `schema_version: 1`, and one tagged tree. Null, boolean, string, integer, float64, array and dictionary nodes have closed shapes. Integers use canonical decimal strings; float64 uses the eight `PackedByteArray.encode_double` bytes as sixteen lowercase hex characters and decodes with `decode_double`. Dictionaries use sorted unique string-key pairs. Tags inside ordinary user strings/arrays retain their ordinary value. Parsing never constructs objects, resources or native Variants.

Limits: eight MiB of UTF-8 text, depth64,16384 entries per container,262144 decoded/encoded value nodes and integers within ±9007199254740991. A quote/escape-aware UTF-8 scan bounds raw JSON containers, depth and tokens before parser allocation; semantic tagged-tree budgets then enforce the tighter logical limits. Encoding checks an incremental minimum byte budget before allocating the whole tagged tree and checks actual bytes after escaping. Oversized integer text rejects before native conversion. Godot's nonstandard vertical-tab escape and representable raw C0 controls U+0001–U+001F are emitted as standard Unicode JSON escapes, preserving literal backslash-v and U+FFFD strings. Native Godot Strings do not represent U+0000. Unsupported/nonfinite source values return an empty encoding. Malformed, noncanonical, unsupported or over-budget parsed values return a rejection with a reason. This is transport validation; it does not prove snapshot authenticity, live binding identity, gameplay fairness or safe restore ordering. Consumer schema validators remain authoritative.

[SaveStore](../../scripts/campaign/save_store.gd) now writes format2 payloads through this helper. It keeps checksum verification, complete temporary generations, a verified prior-generation backup and sibling-rename publication. The file envelope is bounded at sixteen MiB plus1024 bytes for metadata after maximal JSON escaping; the embedded exact transport is bounded at eight MiB. Versions are validated by numeric type and numeric equality because Godot JSON parses version numbers as floats. Valid format1 files retain their historical decimal semantics; the next write upgrades without refilling resources or retiming simulation. A format1 file cannot recover the original bits lost before it was saved. Flush/rename checks are process-level evidence, not a power-loss durability proof.

## Inspected engine behavior

Act3's actual reservation starts at `0.09999999999999999`; full-precision decimal stringify followed by the installed JSON parser yields `0.1`, a difference of `1.3877787807814457e-17`. This is a real scalar-clock mismatch, separate from explicit Vector3 schema reconstruction. Exact transport preserves the clock; no clock epsilon or rounding is added.

The root inspected official source for the installed Godot4.7.2 `ed1daf0bf` build: [json.cpp](https://raw.githubusercontent.com/godotengine/godot/ed1daf0bf/core/io/json.cpp), numeric stringify lines91–97 and parse line374; [ustring.cpp](https://raw.githubusercontent.com/godotengine/godot/ed1daf0bf/core/string/ustring.cpp), fraction reconstruction lines2346–2367 and exponent application2415–2424. The decimal fraction's intermediate double rounds its mantissa before division, explaining this sample. This observation applies to the inspected build and sample; no claim is made that every decimal number is affected or that an upstream fix exists.

The SaveStore outer envelope and legacy decimal payload still use Godot's ordinary parser with their file/embedded byte bounds. The codec's structural scan protects the exact inner tagged payload; it is not a node-allocation bound on the outer or legacy parser.

## Focused verification

Run `python3 scripts/dev/dev.py test exact_json` through the canonical Godot queue. The fixture reproduces the six-tick clock issue, round-trips2048 seeded finite binary64 samples and nested native types, rejects malformed/nonclosed inputs, writes/reopens real version2 files, recovers exact backup clocks, reads/upgrades a valid format1 generation and rejects an invalid overwrite without replacing valid state. The directly affected persistence and campaign-shell suites verify coherent progression/retry/replay flows. Actual authored reservation/level restoration remains worker evidence after adoption. No human/native gameplay or whole-campaign claim follows from transport tests.
