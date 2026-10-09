# Signature-safe same-call source validation draft

Status: **OFFLINE, UNPARSED AND UNEXECUTED GDScript**. No candidate has been installed. No Godot job, catalogue mutation, native correctness result or cost measurement belongs to this folder. Root must review the minimal patch, complete native verification and authorize any future catalogue-write interval before adoption.

This new folder supersedes the signature-breaking idea in the frozen `runtime-source-reuse-rebased35` folder. Every earlier artifact remains unchanged. Its scheduler base is the complete owner-guard35 source `c8240979…`, and its Authored base is the exact-Script guarded `0939da84…`. The patch changes no ordinary admission, managed journal, captured program, actor, renderer, geometry, profile values or saved schema.

## The compatibility correction

The earlier draft added optional arguments to virtual `_input_error` and `_resolve`, and public `snapshot_error` always passed those arguments. A legitimate existing subclass overrides the original seven/two-argument signatures. The installed GDScript analyzer does not allow its override to accept fewer arguments than its parent's newly enlarged range, and the altered dispatch can fail even when the additional value is null. Defaults do not preserve that compatibility.

The new candidate keeps **every original method signature and call arity**. Authored `snapshot_error`, `_input_error`, `configure`, `binding_error`, `restore_state`, `exact_equal` and the guarded `0939` comparison helper have byte-identical bodies. The only modified original Authored body is `_resolve(definition, profile_id)`: it still constructs a fresh Difficulty instance and resolves the same role in the same place. When an internally armed sink exists, it additionally copies that instance's parser receipt after the original resolution.

The original snapshot validator continues its root walk, locally captured native Script discriminator, virtual `_input_error` / `_resolve` / `_authored` calls and short-circuit timeline comparison in exactly the same order. Legitimate subclasses retain all original public comparisons and dispatch. No optional input, accepted flag or caller-owned collector is added to those methods.

## Supported one-call lifetime

The only supported production caller is the local `ReplayProgram.new()` inside **one** `Scheduler.authored_replay_source_error` invocation. Normal public Program/Authored restores never collect a source-guard receipt. The new underscore methods are internal implementation seams, not public admission APIs or APIs for retained Program readers.

1. Scheduler performs its original bounded program, actual source Script and complete-world preconditions.
2. Its fresh, exact-native Program creates a fresh, exact-native Authored codec. The internal factory refuses subclasses, prior wire, an armed sink or a retained receipt before any virtual call.
3. The factory arms its own temporary array field and calls the **original public `restore_state`**. The original successful validation still creates **two independent fresh Difficulty instances**. Each contributes a defensive parser-text receipt. No actual actor hook, callback or yield occurs inside these native pure codecs.
4. Immediately after that call, on success **or failure**, the factory detaches the sink. A failed restore clears the receipt and leaves no wire. Two missing, empty, unequal or unexpected receipts disable reuse. Only one copied parser dependency remains in this call's local codec.
5. Scheduler reads the original plan, invokes the actual source binding getter, rechecks owner lifetime/Script and source identity, performs the original staged/living/knot/stationarity checks, and freshly derives the actual native floor and collision descriptors. Their order and error messages are unchanged.
6. At the original binding boundary, the private consuming tail first clears its stored receipt, verifies exact typed equality of the current supplied program with its privately validated wire, original epoch/generation and detached native state, then performs a **fresh catalogue read**. It does not reuse a retained Difficulty/profile as new catalogue authority.
7. Only an exact dependency match permits omitting the duplicate pure role/timeline derivation. The original native definition encoding, profile/source and complete world comparison still execute. A changed wire, catalogue or unavailable receipt executes the original `binding_error`, including the original staged comparison and error ordering. A second use also full-validates. The local reader is discarded on return, including earlier world/source refusals.

All source getter, Script, HP/alive, fixed knot, floor, collision and native world reads remain at their original boundaries. The receipt contains no actor, Node, resource, native proof, lease, clock or authorization. It is neither exported in snapshots nor retained by Scheduler. It never grants admission. GDScript's underscore names are a convention rather than access control; integration must keep these internal methods confined to this exact local caller. Calling preparation and saving that reader across frames is outside the supported contract, even if a later pure fallback happens to validate the same data.

## Exact parser dependency and limits

Difficulty still opens the canonical file and passes **`FileAccess.get_as_text()`'s actual String** to `JSON.parse_string` without substituting a raw-byte parser. After successful catalogue construction, it privately stores a defensive UTF8 encoding of that actual parser String when it fits 65,536 bytes. Public profile/role methods and their diagnostics are unchanged. Larger accepted catalogues simply disable this optimization.

This is a **parser-text receipt**, not provenance for the original raw encoding. At the later binding boundary a bounded raw file read must equal that encoding. Missing, changed-length, short, oversized, BOM-bearing or normalized malformed-encoding bytes normally differ and run the old validator. If a getter replaces the file with exactly the normalized UTF8 text the original parser consumed, the parser input is unchanged; this does not establish byte identity with its previous pre-decoding source.

The draft intentionally preserves the native decoder's original BOM/UTF8/read-error behavior. A malformed-input job that prints native decoder diagnostics cannot be reported as a clean passing run. The planned BOM control compares the decisions rather than inventing whether the installed decoder accepts it. No atomicity against unrelated external file writers is claimed; the controlled fixture requires exclusive reader/writer ownership. There is no TTL, filesystem metadata shortcut, cross-frame cache or rewritten canonical catalogue.

The new Difficulty functions add a small parser-receipt copy and bounded file comparison. They cannot establish a net cost improvement. Only later actual measurements can do that.

## Future native controls

`source_reuse_smoke.gd` inherits the existing real authored actor arena. It uses the **actual exact shared Scheduler**, shared Player, real floor/world, real Playback-subclass HP/knot/renderer/cues and admitted program. It adds no proxy admission or fake saved source codec.

The new `OriginalSignatureProbe` declares precisely the old seven/two-argument overrides. Future parsing must prove that this subclass remains legal. Runtime assertions require one input call and two resolve calls on public validation/restore; an internal collection attempt on that subclass must refuse before dispatch. Fresh exact-native success/failure paths must detach their sink, and ordinary public restore must retain no source-guard receipt. The already separate guarded LEFT-mutation oracle remains relevant and is not claimed to run here.

Each future source-getter control compares the optimized source guard with a literal original source-guard body adapted only to test instance access. Planned cases:

- Unchanged native and staged source bindings; original pass retained.
- Real canonical damage/windup changes, unsupported catalogue schema, lexical whitespace, another profile's change and BOM bytes; exact decision/error parity. Lexically changed or unrelated-profile inputs must fall back and preserve the original pass.
- One-bit submitted action damage, generation, unsafe Object/cycle, actual source definition or staged source definition mutation; original rejection/error retained.
- One native floor dimension bit, and combined floor/catalogue mutation; the original earlier native-world error must win before binding.
- Consumed receipt followed by another check; the second check uses the full validator and leaves immutable wire unchanged.

The test preserves original catalogue bytes between cases and compares full actual Player/Scheduler/Playback packets, source HP/lifecycle/program, native poses, resource identities and observed callbacks. **Both before and after Exact JSON strings must be nonempty.** Diagnostic native object/resource IDs use closed decimal-string tags because those actual native IDs can exceed the codec's safe integer bound. Actual public snapshot contents remain unchanged; decimal tags cannot be used as restoration authority.

The future Python wrapper checks every reviewed artifact, candidate and fixture dependency, then backs up the actual catalogue. It is the only planned launcher and uses the canonical `dev.py` queue. Its `finally` restores exact original bytes, mode and hash even after ordinary test/engine failure. The fixture also restores between controls. Process termination that prevents Python `finally` still requires root to recover the retained backup before any other reader resumes. Neither wrapper nor fixture has been executed here. The future invocation is:

```
python3 .cinder/runtime-source-reuse-signature-safe/run_controlled_fixture.py --execute-reviewed-candidates
```

That flag is **not authorization**. Root must first review/install the candidate files and authorize the exclusive real catalogue-write interval. The wrapper cannot satisfy permissions by itself.

## Static release contents

Complete candidate and original files, a minimal unified patch, untouched catalogue backup, the new fixture/wrapper, frozen prior manifests and exact static receipts are included. `static-verification.json` checks original signatures/bodies, all scheduler bytes outside the one source-error method, the nine managed admission/registration functions and error constant, the ordinary/captured branches, and every retained old/live input hash. Python AST checks validate the generator/wrapper syntax only; they do not parse GDScript or execute engine code.

This folder has no production source publication, whole campaign, authored-level, route, portrait, balance, fairness or FPS claim. The native test may need narrowly repaired syntax after root authorizes its first actual run; that first failure must be retained separately from later evidence.
