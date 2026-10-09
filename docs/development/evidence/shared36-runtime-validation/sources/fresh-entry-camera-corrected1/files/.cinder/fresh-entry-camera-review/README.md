# Fresh ordinary-entry native presentation draft

Status: **OFFLINE / UNPARSED / UNEXECUTED**. This folder is an isolated proposal,
not an installed interface, a native pass, or acceptance of an act level.

The exact Act1 request is `3d55e001-48af-4539-8733-c8b86aada6b8`. Ordinary
Shell construction copies the installed camera transform. Its four fresh paths
(begin, next main, optional/replay entry, replay restart) call `_capture` before
installation, while `_capture` asks the independently guarded live level writer
for a snapshot before deriving an actor focus. A displaced actual scene spawn
can therefore be clipped by the previous camera. The current installed HUD may
also have a different objective shape. Saved restoration already has a separate
post-quiet optical gate and is outside this change.

## Minimal seam and ordering

Only Level and Shell candidates change. Original Game, Player, HUD, camera math,
installed capture, pure saved validation, saved quiet restoration and its optical
gate are unchanged.

The additive opt-in virtual is:

```gdscript
func snapshot_state_for_presentation(camera: Camera3D, hud: GameHUD) -> Dictionary
```

The default delegates the existing `snapshot_state()`. An opted owner factors its
normal checked writer into a common method. Its explicit path selects these
actual camera/HUD arguments, while the installed path continues to use its real
current camera and installed HUD. Both retain all original mechanical and optical
checks. The supplied context is a native receiver, never an accepted stamp.
The owner must keep saved prevalidation mechanically pure and keep its original
post-quiet saved optical gate. No `busy` exemption or private flag change is added.

The private fresh helper:

1. Requires a paused, ready, hidden original constructor: own World3D, retained
   actual level/Player/effects bindings and Scripts, original native hierarchy,
   actual current Script-free camera with shared fixed projection/basis/width/
   depth/cull policy. It captures a nonempty exact actual Player packet.
2. Builds a canonical real GameHUD in a temporary native SubViewport at the
   installed outer HUD's actual integral pixel dimensions. It lays out the
   candidate's actual objective and current resources; it never swaps aliases or
   changes the donor HUD.
3. Measures the level's complete actual source/footprint/landing/opening corners
   plus the actual Player capsule, full billboard and foot-shadow bounds. It uses
   the existing context planner and its fixed width/basis and margins. Only an
   accepted plan writes the hidden candidate camera. The returned fresh Shell
   packet contains that exact focus.
4. Checks current native containment, invokes the opted writer, then independently
   calls the existing `level.snapshot_error(returned_snapshot)` outside its
   writer. It rereads native identities/Scripts, exact nonempty Player packet,
   exact bounded encoded corner lists, actual HUD pixels/objective/safe rectangle
   and planned current camera. It rechecks containment before returning.
5. Frees the temporary HUD on success or rejection. Existing callers dispose a
   rejected candidate, retain the specific error, and perform Attempt/disk commits
   and installation only after successful capture.

Corners are closed finite `Codec.vector3` arrays (at most 256 coordinates within
1024), compared through nonempty ExactJson strings. Native resource/Script checks
are current checks, not caches of authorization. Framing does not prove a safe
route, an attack admission, or current damage authority.

The hook is trusted owned code: **no mutation, emit, yield, reentry or alias swap**.
The before/after checks detect covered violations; they are not a general rollback
system for arbitrary hostile hooks. A failure disposes the candidate, never heals
its binding or installs it. This helper writes only the candidate camera and a
local Shell packet. It does not move an actor, replenish resources, alter clocks,
edit a captured pose, or mutate installed camera/focus/HUD/input/shake aliases.

The actual existing `exit` and `side` operations first call `_record_live(false)`.
That preceding legitimate write can persist an authored latched exit/old unit.
This proposal preserves it. “Unchanged disk on fresh-helper rejection” means the
helper's pre/post boundary; it does not claim a whole user operation rewinds its
previous deliberate durable write.

## Future native fixture, not evidence

`fresh_entry_level.gd` and four scene-authored fixed Box floors provide actual
spawns at Z=15, -15, 30 and 45. Each creates a real MeshInstance3D/BoxMesh source.
One source is genuinely 40m wide and cannot fit. No enemy, scheduler proof,
production registry change, physics pose seed or campaign progress prefix seed is
used. Test-only in-memory accepted metadata maps the four canonical IDs solely
for the isolated fixture. Source/rendering is not authored content acceptance.

`fresh_entry_camera_smoke.gd --original` runs against original live Shell and
Level. It asks for the expected correct behavior and records the actual current
native projection/capture error at the displaced spawn. It does not assert a
missing API; the only corrected-only private helper is called dynamically.

The corrected selector exercises public Journey Begin, completion/contact-driven
next main, optional entry and protected saved return, completed-level replay,
actual shared Player dash motion followed by paused replay restart, actual outer
540x1170 wrapped HUD shape, full body/quad/shadow/source bounds and immediate
installed focus correspondence. It checks a genuine oversized native Box refusal,
a test-only malformed returned writer envelope, exact unchanged donor/Attempt/disk
observations and temporary HUD cleanup. Finally it verifies the original saved
focus gate rejects a clipped saved camera without refitting and accepts the same
original valid save. Those negative helpers are scoped private transaction
observations; ordinary flow coverage uses public Shell/menu/level requests.

Native resources/actions are ordinary shared instances. The two dashes are public
Player actions, not human gesture playtesting. No focus override is used. Audio is
stopped and flushed after assertions; isolated user files and FPS/audio are restored.
No screenshot, portrait pixel review, performance or all-level acceptance is claimed.

Root must freeze the **actual current** complete native dependency graph before
running. The 13-input draft receipt is a static base receipt, not a native execution
receipt and not a superseded Scheduler kernel. The four source-reuse candidates
were adopted separately by root while this draft was written; none are copied or
treated as camera evidence here.

Proposed first reproduction through the canonical queue (root owns actual source
freeze, user-data permission and log preservation):

```sh
python3 scripts/dev/dev.py engine --headless --verbose --path '/Users/howardchen/Documents/ChatGPT/video game idea' --script res://.cinder/fresh-entry-camera-review/fresh_entry_camera_smoke.gd --log-file '/Users/howardchen/Documents/ChatGPT/video game idea/.cinder/fresh-entry-camera-original.log' -- --original
```

Only after the original job closes, root may adopt the narrow two-core diff and
queue the same fixture without `-- --original`, preserving every original failed
source/log receipt. Any directly affected additional test is root's decision. This
folder has never launched Godot, changed live source, edited a catalogue or run Git.

## Offline files

- `shell.original.gd`, `level.original.gd`: byte-exact actual base files.
- `shell.gd`, `level.gd`: complete candidates.
- `fresh-entry-camera.patch`: narrow unified diff only.
- `build_draft.py`: offline generator using preserved originals.
- `fresh_entry_camera_smoke.gd`, `fresh_entry_level.gd`, four `.tscn`: future native
  test inputs. All are still unparsed/unexecuted.
- `frozen-inputs-before.json`, `static-verification.json`, `manifest.json`:
  static source and scope receipts, never native proof.
