# Post-root LEFT mutation review

Status: **OFFLINE, UNPARSED, UNEXECUTED**. No engine or live runtime/Git/catalogue/worker changes. This separate review leaves the three frozen draft folders unchanged. Its regression is a proposal for the integration owner's future native target, not a reported reproduction or performance result.

## Concrete compatibility defect

The reviewed candidate is `../authored-subtree-reuse-draft/authored_enemy_sequence.gd`, SHA256 `f711f0d8519f06d5d6c6b6ffcbde7e1f56f950ea555661920eea59f313e134f3`. `snapshot_error` performs its complete submitted root walk at line120, then calls virtual `_input_error`, `_resolve`, `_authored` and `_timeline` before the three comparisons at line133. The first `_resolve` happens inside `_input_error`; the second happens at line131. The supplied `DerivedOutputProbe` fixture already demonstrates supported subclass overrides of these methods.

A subclass stores the actual submitted Dictionary alias. During its second `_resolve` it first obtains the unchanged genuine `super._resolve` result, then erases saved `resolved_role["damage"]` and inserts `StringName("damage")` with the identical original value. Root validation had already accepted the original String key. The candidate's right operand is still closed and canonical, both dictionary sizes are unchanged, and its typed `for key: String in left` converts the original StringName key to a String. Content-compatible dictionary lookups recover both unchanged values. The candidate's right-only safety helper can therefore return true. The original public `exact_equal` first walks that LEFT branch, rejects its non-String key, and the surrounding original validator returns its existing derivation error.

The same distinction can be triggered immediately after `_authored` derives its RHS by replacing saved `inter_echo_gap_s`, or after `_timeline` derives its RHS by replacing saved `warning_from_s`. This uses ordinary virtual overrides and retained Dictionary aliases. It requires no reflection, catalogue changes, concurrency or fabricated native authority. The exact production `Authored.new()` Script has pure helper bodies, so its ordinary same-call path does not produce this mutation; the issue concerns the existing public validator's subclass compatibility.

## Engine evidence

Godot's installed `ed1daf0bf001b61586d9930840f2f1394092c079` dictionary uses `StringLikeVariantComparator`, whose cross-type rule compares String and StringName by their textual content. This is explicit native behavior. [Dictionary storage](https://github.com/godotengine/godot/blob/ed1daf0bf001b61586d9930840f2f1394092c079/core/variant/dictionary.cpp#L39-L44), [cross-type comparator](https://github.com/godotengine/godot/blob/ed1daf0bf001b61586d9930840f2f1394092c079/core/variant/variant.cpp#L3247-L3257).

The compiler emits an iterator conversion when required; bytecode then assigns each temporary dictionary key through typed conversion. StringName is convertible to String in the native strict-conversion rules. [For-loop compiler](https://github.com/godotengine/godot/blob/ed1daf0bf001b61586d9930840f2f1394092c079/modules/gdscript/gdscript_compiler.cpp#L1929), [iterator conversion](https://github.com/godotengine/godot/blob/ed1daf0bf001b61586d9930840f2f1394092c079/modules/gdscript/gdscript_byte_codegen.cpp#L1597-L1635), [String conversion](https://github.com/godotengine/godot/blob/ed1daf0bf001b61586d9930840f2f1394092c079/core/variant/variant.cpp#L559-L565).

These primary-source observations support the static counterexample. The attached native regression additionally checks the actual key type, lookup and typed iteration before the codec cases. It has not been parsed or run.

## Bounded RHS reasoning

A freshly safe finite RHS plus exact recursive value types, scalar bits and container sizes prevents a changed LEFT Object, cycle, nonfinite value or oversized replacement from matching that RHS. Recursion follows the finite RHS's shape, so a LEFT cycle eventually encounters a size/type mismatch before a matching infinite descent. Adding an unsafe extra dictionary key fails the size check. These observations do not repair the StringName key case: key type is erased by the typed iterator, and lookup uses native String-compatible equality. No wider acceptance defect from those other mutations is claimed.

Mutating an already-compared branch in a *later* virtual callback is a separate pre-existing behavior: even the original comparator does not revisit a previously compared branch. The regression intentionally mutates each tested branch immediately before its own comparison, so its rejection difference isolates this candidate's removed LEFT walk.

## Minimal repair recommendation

Derive an exact locally owned shared Script-identity predicate inside `snapshot_error`, before any virtual derivation calls. Only an instance of that exact native shared codec may use the three right-only helpers. Every derived Script follows the original three public `exact_equal` calls, in their original short-circuit order. This is an internal same-call selection, not a caller-supplied accepted flag or serialized token. An exact class Script resource comparison is preferable to a resource-path string or base-class-name assertion; its native fixture must demonstrate that the exact instance selects reuse and the legitimate subclass selects full comparison.

Keep each existing derivation at the same point. In particular, do not eagerly compute `_timeline` before earlier comparisons, and do not replace public `exact_equal` or weaken its key/budget rules. If exact native Script identity cannot be established confidently, retaining the original LEFT walk is the safe minimal alternative. Fixing only `_same_closed_exact`'s iterator would close the key coercion but would not establish the candidate's documented post-walk immutability premise for virtual subclasses.

## Guarded new candidate

`authored_enemy_sequence.gd` copies the reviewed candidate into this NEW folder and adds the locally derived `get_script() == CinderAuthoredEnemySequence` predicate immediately before `_input_error`. Each original short-circuit comparison then selects its original `exact_equal` when that predicate is false. The `_timeline` call stays inside the third comparison and only the selected conditional arm runs. All functions and bytes outside `snapshot_error` and the added private helper are identical to the original live base `7ffd8dd72d834b3b8f7bd06a6604f39e78c5a2b1a6f1e8db6fa97018de57f8b9`; `guarded-subtree-reuse.patch` is relative to that base.

The predicate uses the native Script resource, not a string path. Godot's compiler resolves a global class whose name matches the current outer class directly to its `main_script` resource constant. Thus this choice needs no self preload, runtime file load or ResourceLoader cache assumption. [Compiler self-class resolution](https://github.com/godotengine/godot/blob/ed1daf0bf001b61586d9930840f2f1394092c079/modules/gdscript/gdscript_compiler.cpp#L402-L432). This is source-based reasoning; the proposed native fixture must still parse and demonstrate exact-codec true and legitimate-subclass false at the actual canonical installed path.

There is no public predicate or proof token. Its local Boolean is captured before any virtual derivation and expires when this single validator call returns. A subclass that changes its Script in a later hook cannot upgrade that captured false decision. Every original public/standalone/binding/restore comparator body is unchanged. A simpler alternative remains the original live base itself: retaining all three public `exact_equal` calls makes no cost-saving claim and requires no domination assumption.

## Proposed regression and ownership

`authored_left_mutation_smoke.gd` inherits the existing real native seed arena helpers. Two independent genuine subclass readers compare the literal original ordering with the candidate. It covers all three post-walk StringName replacements, unchanged subclass positives, closed-but-different values, added unsafe keys, actual Object values, actual cycles and oversized replacement values. Fresh real writer controls verify rejection before commit and preservation of the original diagnostic. The existing legitimate `DerivedOutputProbe` malformed-RHS cases remain in this proposed target too. No hostile mutated graph is deep-copied or stringified; cleanup restores the original key/value and breaks the injected cycle.

The script extends/preloads the real canonical codec; it is not a renamed fake loader. A future run would require root to install its reviewed candidate through the normal authorized source boundary. No command or native target was launched here. `frozen-inputs-before.json` and the release manifest record all41 original frozen input files and exact unchanged membership/bytes after authoring.
