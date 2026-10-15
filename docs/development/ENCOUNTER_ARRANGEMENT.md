# Authored encounter arrangement metadata

Component **encounter-arrangement-1**, available in **campaign-shared-61**, is a pure helper for trusted versioned orders of existing units. It selects at a fresh encounter boundary and restores a retained recipe without consulting a changed menu preference. [Shared62 Court](ACT1_L4_DIFFICULTY.md) now consumes it at the actual combined-approach boundary; the helper alone remains pure. Campaign acceptance is21/24 after separately reviewed Spore Bloom registration. The original20-level difficulty audit remains its historical scope; Spore Bloom also reports no authored Challenge variant, which joins the separate implementation work.

The [source audit](evidence/difficulty-completion-gap/REPORT.md) identifies unfinished implementation required by `DIFFICULTY_DESIGN.md` Step3. At its20-level baseline, A1-L2 implements a Challenge finale order;19 accepted levels share Standard/Challenge arrangements. The four private unfinished optionals were outside that audit. Assisted numeric/budget effects already have consumers. The audit separately identifies a captured-player replay policy exception. This helper does not close the campaign implementation gap.

## Definition and API

`CinderEncounterArrangement.new(definition)` accepts exactly these fields:

| Field | Contract |
| --- | --- |
| `schema_version` | Integral1 under the existing snapshot codec convention. |
| `unit_ids` | Bounded nonempty array of unique, nonempty existing stable IDs. A unit can be an owner-defined encounter or attack segment. |
| `recipes` | Bounded nonempty array; each recipe has exactly `recipe_id`, `profile`, `order`. |
| `recipe_id` | Unique stable name with canonical positive `@vN`. Changed content gets a new version; old recipes remain retained. |
| `profile` | `assisted`, `standard` or `challenge`. |
| `order` | Complete unique permutation of the same inventory; no omitted, repeated, additional or foreign unit. |
| `current` | Exactly three profile keys, each naming a retained recipe of that profile. |

The constructor validates closed shapes before copying. `last_error` exposes invalid configuration or a failed operation; failed selection/restore returns an empty dictionary. `definition()` returns a detached deep copy. An instance's definition stays fixed.

At a fresh profile boundary, `select_fresh(profile)` returns a detached descriptor with exactly `schema_version`, `profile`, `recipe_id`, `order`. Persist the complete descriptor with the coherent encounter state. For active saves/checkpoints, `saved_error(descriptor)` and `restore(descriptor)` require its exact profile/order to match the retained recipe. Neither consults `current`, preferences, files or native world state. Changing current mappings affects future selections only. Removing or changing a retained recipe refuses its old save. JSON integral1.0 is accepted without rewriting the caller's representation. All returned dictionaries are defensive copies.

Definitions are trusted authored data, not historical publication certificates. A fabricated definition plus matching descriptor proves no history. Retain immutable source/version history and whole-level codec validation. The helper supplies no geometry, damage, timing, lease, safe-path, native-reference or process-priority authority.

## Consumer work and ownership

Each arrangement needs an authored player decision and an actual admission/segment consumer. A different string, generic reversal or Node construction order alone supplies no decision. Preserve reference geometry, HP, movement, controls, Standard/Challenge timing and reachable ordinary-primary/no-ammo opportunities. A rehearsal or fixed capture phase may explicitly retain its arrangement for a source-backed reason; absent policy is not implemented policy.

Act1 ACK `cc5be1d2-4990-43b4-8450-129e2a6767b2` permits named accepted primary-checkout roots/layouts/codecs and focused tests after review of a meaningful existing-kit decision. Current O2/O3, their evidence and pinned Base/native dependencies are excluded. Its registered checkout/branch/identity/custody remain unchanged. Act3 RESPONSE/ACK `a8e97f92-2ec4-4597-adab-d473c5ccb1d0` also permits the exact named accepted primary roots/data/three codecs/focused tests; current O2/O3 and common native/capture helpers remain excluded. Agent02 is human-inactive; availability authorizes no task or ownership takeover. [Original audit/request pins](evidence/difficulty-completion-gap/) retain their historical scope.

Consumers must retain legacy whole-level recipe identities, Save/Continue/Retry semantics and the saved profile during restoration. Run only affected focused checks and brief relevant portrait inspection. Existing Standard-focused acceptances remain; there is no new full-route, defeat-all, earned-exit or cross-act gate. The campaign requirement remains open until actual policy and consumers are implemented and verified.

## Evidence and limits

Necessary queued import and selected parser closed0. Native `python3 scripts/dev/dev.py test encounter_arrangement` closed clean **37/0**, with37 retained true rows, normal complete/success flags, empty first failure and exact report path/SHA/footer/source joins. It tests fresh selection, old saves after current-map changes, retained-recipe deletion/tamper refusal, JSON representation, defensive copies and malformed inputs. [Portable original evidence](evidence/encounter-arrangement/index.json) retains the source-only proposal separately from execution.

The first runner invocation refused exit2 before an engine started because Root's failed alias-anchor edit left no seal. That remains failed, separately from the corrected import/parser/native. Two publication-preparation ENOSPC attempts also remain failed. Root recovered only verified completed duplicate integration archives, then observed a larger externally unattributed free-space increase and passed a write/read/fsync probe before releasing the temporary worker launch hold.

Import's explicit observed map changed9→11 only through two genuine UID sidecars; parser/native retained11. This is not a global class/resource/dependency/UID census; editor import may change derived metadata outside that subset. The canonical runner owns and waits a direct child through the shared queue with180s after acquisition; no separate process-group claim.

These37 checks give no native encounter, level consumer, legacy whole-level codec, portrait, balance, performance/FPS, full-playthrough, mobile or release credit. Shared61 adds availability without migrating existing gameplay/save interfaces.
