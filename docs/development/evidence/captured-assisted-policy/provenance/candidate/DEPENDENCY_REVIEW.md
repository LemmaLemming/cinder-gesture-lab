# Bounded original dependency check

Only these named original sources were searched for fixed1.3/3.5 or captured API2 constraints: crystalman_recorded_frame_art.gd, replay_capture_gate.gd, replay_witness.gd, replay_footprint.gd, replay_sequence.gd, crystalman_parent_codec.gd, crystalman_phase_policy.gd. No global dependency scan occurred.

- FrameArt recipes bind exact Sequence hash and original captured slots, using the generic Sequence reader; no original1.3/3.5 recipe is hardcoded. New outer timing changes its legitimate Sequence hash without changing artwork/records. Its code remains untouched.
- Gate independently regenerates Sequence from the actual complete capture and explicit six-key outer recipe (prepare138–159; validator409–420). Generic positive bounded timing validation accepts either retained old or new canonical recipe. No Gate source edit needed.
- Sequence125–151 keeps original captured event records/routes, shifts the outer offset and preserves original action durations/order/gap. No new Sequence API/data mutation is required.
- Witness uses plan.authored.warning_s at real lock and checks original recognition budget; it does not resolve damage or mandate fixed1.3/3.5. All existing actor/world/floor/geometry/full-response guards remain.
- Projection binds exact Sequence digest, native world/floor and original event geometry. It neither scales damage nor assumes fixed outer timing. Original code unchanged.
- Whole parent local1 validates actual current CapturePhase script/capacity then delegates native_state_error (52–62), with exact whole quiet recapture119–127. It has no captured API2-only discriminator. No parent edit inferred.
- Closed spent phase receipts remain the original exact keys and opaque sequence/projection/retirement hashes. No receipt/history rewrite or new rule field is introduced. This does not create a claim of historical policy provenance beyond the existing receipt contract.

The only old fixed recipe/API2 validator is the authorized captured codec. It now dispatches exact legacy2 or new3 and derives recipe from the validated **saved unit**, independently of recipient mode. Original framed/native/cue/floor/body/quiet/custody checks remain. No genuine dependency requiring another parent/rules/Act3 source edit was found by this bounded source review; queued parser/native checks remain unexecuted.
