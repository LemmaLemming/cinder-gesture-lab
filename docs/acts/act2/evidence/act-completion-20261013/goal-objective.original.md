PROMPT 2 — ACT 2 AGENT

You own the complete Act 2 of Cinder: The Invasion. Build all five main levels and three documented optional levels, sequentially, one complete playable level at a time.

CANONICAL INTEGRATION ROOT
/Users/howardchen/Documents/ChatGPT/video game idea

Read .cinder/agent-chat/cinder-campaign/run.json and the canonical docs/development/CAMPAIGN_MEMORY.md, SHARED_CONTRACT.md, and SHARED_PROGRESS.md before editing. Use your registered Act 2 checkout, codex/ branch, role, and owned paths. Two other act workers and the shared owner may be working on this computer. Never assume their files or engine sessions are yours.

If setup/baseline registration is absent, perform read-only preparation and request integration setup through the mailbox. Do not create a duplicate worker or edit contested shared files.

REQUIRED READING
Read applicable AGENTS instructions, README, the parallel development workflow/setup record, campaign concept, shared style/motion guidelines, and asset reuse guide.

Then read:
- docs/ACT2_CONCEPT.md
- docs/reference-library/act2/research/levels.json
- docs/concept-art/act2/README.md, including its adaptation boundaries
- Relevant category READMEs, generated manifest, research and source records.

Act 2’s adaptation boundaries are in its README; do not assume a separate adaptation-notes file exists. Read equipment guidelines/data, the equipment grid, and ability workflow before choosing playstyle or equipment opportunities.

LATEST USER OVERRIDE
An astronaut helmet is no longer mandatory. Protagonist headwear follows the selected act concept art through the shared character presentation system. Retain shared controls, stats, equipment slots, feet pivot, and collision. Do not replace the shared protagonist/controller with the novel’s narrator.

ACT ARC AND ORDER
Preserve:
curiosity and rupture → public retreat → industrial confinement → displacement → lonely suspense and uncertain relief.

Build:
1. A2-L1 Horsell Common
2. A2-L2 Weybridge and Shepperton
3. A2-L3 Black Smoke and the Ruined House
4. A2-L4 Red Weed and the London Approaches
5. A2-L5 Dead London and Regent’s Park
Then:
6. A2-O1 Cylinder Perimeter, parent A2-L1
7. A2-O2 Clear Air Circuit, parent A2-L3
8. A2-O3 Bleached Canal, parent A2-L4

Use canonical level IDs, objectives, teaching order, and selected bosses. Do not manufacture difficulty through permanent player growth, inflated health, extra bosses, or padded waves. Quiet travel and tableaux contribute to the act’s pacing.

ART AND SOURCE BOUNDARIES
Visually inspect the relevant boards. Realize oxidised cylinders, rivets, articulated joints, pistons, mirrors, canisters, heath/pines/scorched ground, Victorian ruins and varied witness costumes. Preserve rust-red/black/pale-ash identity instead of recoloring the lab or Moon kit.

Prefer handling-machine-boss-v2.png: five-legged low machinery and rounded tentacled Martian anatomy. The humanoid pilot in v1 is superseded. Three-legged fighting-machines and five-legged handling-machines remain distinct.

Teach Ray Scout, Salvage Handler, and Canister Tender in the documented order. L3 uses the selected Handling-Machine; L5 uses the Dying Fighting-Machine Sentry. Alternative boss boards do not authorize additions.

Keep continuous dry playable ground. No swimming, boat controls, jumping, climbing, pit descent, or mandatory narrow planks. Red weed is scenery/ecology. Human crowds remain outside necessary dash space; their beautiful designs can support nonhostile vignettes without becoming factions or escort objectives.

Smoke occupies its previewed bounded footprint and cannot create surprise unavoidable cages. Low joints, housings, and tool mounts must remain reachable by ordinary close-range primary attacks.

The finale’s bait reads the actual completed world-space dash landing, including collision shortening. This is distinct from the screen-space release endpoint used for aiming. The player opens a local escape route; microbes end the invasion.

After a functional greybox, continue into authored runtime scenery, actors, animations, and feedback. Track which concept-art features were realized, adapted, or deferred. Favor visual richness and faithful silhouettes over unnecessary stylistic uniformity, while keeping camera, gameplay, collision, and cue meanings intact.

OWNERSHIP AND SHARED CONTRACT
Own only scenes/acts/act2/, scripts/acts/act2/, assets/acts/act2/, data/campaign/act2/, and explicitly assigned tests.

Use CinderLevel, a reachable spawn, the shared shell, and explicit cleanup. Keep one shared player, camera, HUD, gesture recognizer, equipment resolver, scheduler, and save system. Request API extensions rather than copying shared systems.

Preserve portrait pixelated 2.5D; swipe-only ground dashes; exact aim from final swipe release toward tap; immediate primary followed by one nearby second-tap blast; deliberate dash stopping; and warning → lock → active → recovery. No joystick, jump, auto-aim, hotbar, or silent animation-driven timing changes.

EQUIPMENT, RESEARCH, AND COMMUNICATION
When deciding playstyle, query canonical equipment status and campaign-wide/level-specific ability status and availability through dev.py. Reuse IDs; reserve introductions atomically; distinguish creation claims from ability placements. Integration implements campaign-used shared gear. Record IDs, decisions, claim/use records, and truthful status in level evidence. Never overwrite canonical ledgers with branch copies.

Research relevant forums, YouTube footage, developer demonstrations, and official documentation when choosing production techniques or resolving a concrete problem. Record sources, what was actually inspected, useful observations, proposed applications, and local validation. Research must not silently redesign Cinder.

Use only the absolute mailbox registered in run.json. Write your own status and uniquely named outgoing messages; read integration responses and relevant other-agent updates. Continue independent same-level work while dependencies are pending.

MEMORY, ACCEPTANCE, AND COMPLETION
Maintain data/campaign/act2/ACT_MEMORY.md, PROGRESS.md, and levels/<LEVEL_ID>.md. Persist act coherence, reusable art families, source boundaries, shared API/baseline versions, objectives/checkpoints, equipment records, tests, portrait evidence, limitations, and the exact next task.

Reread durable campaign/act records, applicable source documents, previous handoff, and current mailbox at every new level and after context reset/compaction. Temporary chat is not the design archive.

Use dev.py for all Godot jobs; respect the single-engine queue and release the session when finished. Validate the actual portrait view, ordinary-primary/no-ammo/no-pickup viability, equipment extremes, warnings and safe landings, pause/resume, coherent checkpoints/retries, reset cleanup, and transitions.

Hand off each complete level for integration before advancing. Optional levels reuse parent kits with only documented small additions and never block main progression or grant permanent stat growth.

Complete all eight levels as tested desktop campaign content. Stop before mobile export and subsequent release work. Clearly distinguish implemented, tested, proposed, and untested.

TARGETED TESTING AND AUDIT POLICY — ALL FOUR AGENTS

This policy governs validation throughout the work. It replaces any interpretation that a failure, level handoff, or integration automatically requires rerunning every test or auditing the whole campaign.

1. DIAGNOSE BEFORE RUNNING MORE CHECKS
Save the failing command, first meaningful error, log path, checkout/revision, and relevant changes. Classify the failure as assertion/gameplay, script/resource/import, environment, or queued/held engine session. A queued job is not a gameplay failure. Inspect the changed code and its direct dependencies, then choose the smallest existing reproduction or supported test that covers the symptom. Reuse an adequate failing result rather than repeating it unchanged.

2. FIX AND RETEST THE AFFECTED BEHAVIOR
After a relevant fix, rerun the failing check and only directly affected regression checks. State which behavior each selected check covers. Do not rerun unrelated acts, art reviews, research, import passes, or shared suites simply because one check failed.

Use explicit supported suite names:
python3 scripts/dev/dev.py test mechanics
python3 scripts/dev/dev.py test equipment
python3 scripts/dev/dev.py test character_lab
python3 scripts/dev/dev.py test visual_effects
python3 scripts/dev/dev.py test level_contract
python3 scripts/dev/dev.py test world_actions

These commands are alternatives selected by the change, not a checklist to execute together. Check the suites available in the assigned checkout. For an owned level test:
python3 scripts/dev/dev.py engine --headless --path . --script <owned-level-test.gd>
Replace the placeholder with the real test path. Raw engine calls lack the named-suite error detector; inspect script/resource errors and explicit test results as well as the exit status.

A bare "dev.py test" defaults to ALL suites. "dev.py test all" and "dev.py check" are broad commands, never the default response to a failure. Run import only when new/moved resources or demonstrated stale imports require it. Keep all engine work in the shared queue and release previews promptly.

3. KEEP AUDITS SCOPED
Review the changed files and directly affected dependencies against the relevant requirements, selected concept art, ownership, and resource/state contracts. Audit the current encounter and modified assets instead of restarting a three-act design review.

Documentation changes need affected link/consistency checks. Cosmetic changes need the affected actual portrait view and asset/reference review. Gameplay changes need the affected behavior, warning/lock/active/recovery, reachable landing, primary-only/no-pickup viability, and relevant pause/retry checks. Required full-level acceptance still applies when that level is completed; it does not require retesting unrelated levels.

Do not claim tests establish art fidelity, human balance, or mobile performance.

4. BROADEN ONLY FOR A SPECIFIC REASON
Before broadening, record the shared dependency or invariant at risk, its affected consumers, and why narrower evidence is insufficient. Examples include controller/stat/level-contract changes, engine or project-setting changes, and symptoms across several subsystems. Run affected suites first; use a full suite only when this dependency analysis or an applicable explicit acceptance requirement justifies it.

Agent 4 may establish an unverified baseline once. An already verified applicable baseline is reused; a later failure alone does not invalidate every result. Act workers report shared faults to Agent 4 and preserve ownership boundaries. Handoffs and integrations require affected reruns, not automatic full-suite reruns.

5. PRESERVE REQUIRED DESIGN VALIDATION
Equipment/ability-related completion still requires:
python3 scripts/dev/dev.py ability validate
python3 scripts/dev/dev.py equipment validate
python3 scripts/design/validate_equipment.py
Also run the relevant runtime checks. These required canonical validators do not require every Godot suite.

Do not weaken assertions, delete failing checks, or loosen tolerances merely to get a pass. If the test itself is wrong, explain and verify the corrected expectation.

6. RECORD EVIDENCE AND MOVE ON
Record exact commands/results, scoped audit findings, tested revision/shared API baseline, portrait evidence, and remaining limitations in the appropriate level or shared progress file. Reuse earlier passes only while the relevant code, resources/data, dependencies, baseline/API, and pertinent settings remain applicable; state why reused results still apply.

Once the selected checks pass and no new issue remains, continue the next task. Do not repeat a successful check without relevant changes, new evidence, or a stated uncertainty. A timeout or repeated unchanged failure calls for diagnosis and a recorded blocker, not an expanding test loop or bypassing the engine queue.