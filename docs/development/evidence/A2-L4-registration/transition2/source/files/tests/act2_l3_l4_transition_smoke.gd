extends "res://tests/acts/act2/a2_l3_live_level_smoke.gd"
## Independent production L3 remainder -> registered L4 targeted fixture.
## Uses the ORIGINAL earned Heavy/Standard Boss15 complete Attempts artifact.
## The original prior campaign prefix/unlocks were TEST ONLY in its real-route
## producer. This test never reconstructs/changes that prefix, checkpoint or HP.
## The historical eight-kernel Boss fixture is not inherited/changed/weakened.
## Current shared37 compatibility is a NEW bounded native scope, not old-source
## equality. No previous route, full L4, extrema, art or human play claim.
## Real GUI Continue/Resume + inherited proof/navigation/observation; selected
## dash/primary requests are routed through actual viewport events here.
## --expected-l4-commit=<actual production Registry accepted commit> REQUIRED.

const TransitionExact: Script = preload("res://scripts/campaign/exact_json.gd")
const ORIGINAL_ARTIFACT: String = "res://docs/acts/act2/evidence/A2-L3/live-heavy-side-source-first/earned-boss-checkpoint.json"
const ORIGINAL_ARTIFACT_SHA: String = "d03d0c4408056811fa951691e511c39ab0cc6fb0119da63cbf4f8761524da5a0"
const ORIGINAL_BOSS_FIXTURE: String = "res://tests/acts/act2/a2_l3_boss_checkpoint_smoke.gd"
const ORIGINAL_BOSS_FIXTURE_SHA: String = "e20fa7967d9f500c0f54994d20ab4dbc5f20fd29f5a3773c4c2bc2cf3da2d76c"
const ACCEPTED_L3_COMMIT: String = "8ddce7cb5290cd36037033eb1edcb02a6015adfd"
const REGISTERED_L4_SCENE: String = "res://scenes/acts/act2/a2_l4.tscn"
const REGISTERED_L4_SCRIPT: String = "res://scripts/acts/act2/london_approaches.gd"
# Read-only git ls-tree/git show of ACCEPTED_L3_COMMIT generated these exact65
# production blobs (including metadata/UIDs, not65 separate gameplay scripts).
const ACCEPTED_PRODUCTION_SHA: Dictionary = {
	"assets/acts/act2/.gitkeep": "01ba4719c80b6fe911b091a7c05124b64eeece964e09c058ef8f9805daca546b",
	"assets/acts/act2/giant_foot_manifest.json": "8a5b391b4edd3eb3ce9f2194d7038aecea438cd7e17230e97d75ac706da15a18",
	"assets/acts/act2/heath_kit_manifest.json": "4af035d04396559b6961e9955b4006db22ca245d8b30fd000ebe2c86908ea470",
	"assets/acts/act2/horsell_layout_manifest.json": "cce00a3124449aa97116e14729353face70663225faa747cfd637e1968f6fcdd",
	"assets/acts/act2/ray_scout_manifest.json": "7ae18dbe2787ab9e7706cfface2aaa0b67ef74d09b4a575187967407cc7e870e",
	"assets/acts/act2/salvage_handler_manifest.json": "3562138e202836b73e99aa5fbfd6480ee624ba550b36f20f9683e2ddf426f831",
	"assets/acts/act2/scout_actor_manifest.json": "63c89ac70bae00aba7b18840b434663a615038131c89a20d409521dd43cc85ba",
	"assets/acts/act2/shaders/smoke_wisp.gdshader": "032e80de1c09dfde8604faa39d9ef1619d30c6287c7e8c6be7f7a66d6b242d95",
	"assets/acts/act2/shaders/smoke_wisp.gdshader.uid": "6d55fe4b5d049adcb892b37d32bc03e6e827c0ec315fb464d4723b2b602a9eaa",
	"assets/acts/act2/weybridge_kit_manifest.json": "7b56d7e6389378bcda0c7ff64009f984f8379afb30289ada7c28ec12a2049800",
	"scenes/acts/act2/.gitkeep": "01ba4719c80b6fe911b091a7c05124b64eeece964e09c058ef8f9805daca546b",
	"scenes/acts/act2/a2_l1.tscn": "586c9a3d44a270648aca44f2bdf0163bc37b1d0173ba2ed9303ea16827387478",
	"scenes/acts/act2/a2_l2.tscn": "34d8bb88e77dfecc11419fdd22aa92c1eae9732bfa5e965d04c8520b34cbdb6a",
	"scenes/acts/act2/a2_l3.tscn": "d4dbb7a42a75d6b017d46e406ae4c3a0a1063bc2abb3dffa25d7d0cceea5f32b",
	"scripts/acts/act2/.gitkeep": "01ba4719c80b6fe911b091a7c05124b64eeece964e09c058ef8f9805daca546b",
	"scripts/acts/act2/canister_tender_actor.gd": "c18a4b09ed55761de6f10cfa803d288718db480891ac1da97c9b5a5711e25c29",
	"scripts/acts/act2/canister_tender_actor.gd.uid": "e50fb36075bcc9792822853c3a491158799b99f909d0bbb4502ffb793138d9fe",
	"scripts/acts/act2/canister_tender_visual.gd": "d3b8dd7f41eb87808274e067a516efd98acddda838358a9e444dd65a53fb3633",
	"scripts/acts/act2/canister_tender_visual.gd.uid": "81591eeddc37433f047200257ca15b0a48a72dbf6a0fac58257d4dffd298ed2b",
	"scripts/acts/act2/giant_foot_visual.gd": "180a2c6658dc901c240cbd2f4ec84f1906d74211afeb30adb3f4f570d518622d",
	"scripts/acts/act2/giant_foot_visual.gd.uid": "05d4c2b350e091efe2622af7af1d91cdafe0245f2aba6ee9f470ea930014721b",
	"scripts/acts/act2/handling_machine_boss_actor.gd": "685308db29c7df0b117e6b4755406a42916c31f22cbd707f6b0c3f9afadc8964",
	"scripts/acts/act2/handling_machine_boss_actor.gd.uid": "36d4c1aaec4e44b10f7a350d48cdeb654063b920fa989fce733ea5618dcb8087",
	"scripts/acts/act2/handling_machine_boss_visual.gd": "0b41831e83ccd09ae8623dfb7a8388e91b1626ae2fb9216e56fb791188ae40d2",
	"scripts/acts/act2/handling_machine_boss_visual.gd.uid": "6b32830c1a3f026f0b6a65a5f56a3f9f16b2dc738d956de8a2e4dae307abdf07",
	"scripts/acts/act2/heath_kit.gd": "77768bc24573be2ce25f2255bf8ffa3adbcd363e00bdaf6125692c1cbf0bd4ac",
	"scripts/acts/act2/heath_kit.gd.uid": "d0db1c03dc92d953cba5d5e137acd7abbf217632e7b8c1fb089f4cf28782376a",
	"scripts/acts/act2/horsell_common.gd": "077dc406d6eda0392661279029b9a07d190be71d21fcb0903712d678ab2be643",
	"scripts/acts/act2/horsell_common.gd.uid": "30fe3f8c74259513eb856c2726ceb039515ccf22007eb987915a1059900a38ab",
	"scripts/acts/act2/horsell_sequence.gd": "fbe1457edcf7028ed3eff8ad5d1b7a453063f8ed5541356eaa251dcf3629d5c7",
	"scripts/acts/act2/horsell_sequence.gd.uid": "cbf64cdd7b3f96f892c57acf58e497961bb1404f2c3b2cc3fdfce06be2073b5e",
	"scripts/acts/act2/ray_scout_actor.gd": "dee72b851cb20b234a05552d07eae9cebd7490ee0fad12b3970da51eae132bb7",
	"scripts/acts/act2/ray_scout_actor.gd.uid": "bf1ca88edd2734508e088b870e58aee6607041d15a187df545363f3aa31a3147",
	"scripts/acts/act2/ray_scout_exchange.gd": "6d8e11a29254cad18947655d8e7470d7892b18e856e534859ae6211a897ae7e2",
	"scripts/acts/act2/ray_scout_exchange.gd.uid": "109bb1249494d294554492120b9bc6e3a56623ac93bb45f78273ad05eb56964d",
	"scripts/acts/act2/ray_scout_visual.gd": "dda58dd611044a434d25206a03ac1b2b5f73270373d613e3a2fcc7bb5539879a",
	"scripts/acts/act2/ray_scout_visual.gd.uid": "2c342d9add57fe98eea2c9557a971affdfed580ded30bda1edc59a5a9e4c8217",
	"scripts/acts/act2/ruined_house.gd": "728358c5e5864066bcc5eb4821f4e55a39561f9763962478e7338a5dea69baef",
	"scripts/acts/act2/ruined_house.gd.uid": "73577a2856e49858b67a173d6fba568f130d07f0eae901f3b04551710397545c",
	"scripts/acts/act2/ruined_house_bank_guard.gd": "758ead75f9b98ce5afd0ae90077113f40d410f172a2d1b4c3375c249076a3e83",
	"scripts/acts/act2/ruined_house_bank_guard.gd.uid": "953e0dac19032032a408309868eef135c14ac7de4b80bce851af1b06eb4ecd6d",
	"scripts/acts/act2/ruined_house_floor.gd": "a5da64bd225526174845cfbf0b2d33b21ccad40915544ec5b1359dc3a3ca2626",
	"scripts/acts/act2/ruined_house_floor.gd.uid": "f146f5816772a888143a25d92c7e157fa1a358ba387a5ccb0eb8ee1b94e8e339",
	"scripts/acts/act2/ruined_house_kit.gd": "19c694d6257856605f3b175a288ce611a3da2a9d916a1151ce4600512a7f3505",
	"scripts/acts/act2/ruined_house_kit.gd.uid": "cb5bc95e9659d9566daa53edb7d5cbab44fb65afa0fa3d0387b65220466c43b0",
	"scripts/acts/act2/ruined_house_sequence.gd": "f73c1d5ec34f6829100b2cec2c3a84cf1e1a2cc4501a892fef56f9fa001f5975",
	"scripts/acts/act2/ruined_house_sequence.gd.uid": "4fa2aa87083c6c8f45704cf17a6e5bcda9a291a246bf9dbc0793d9cbe8c495da",
	"scripts/acts/act2/ruined_house_smoke_rules.gd": "39009e7ee45ff0c849ed6e810c61034b352c509d7a51551fe36f320b3daa83db",
	"scripts/acts/act2/ruined_house_smoke_rules.gd.uid": "521b1dfa6419c1ecb3a44dc5c43915fae97f6262e610033c2d44e8b3cb3f163d",
	"scripts/acts/act2/ruined_house_snapshot_rules.gd": "a60586abbb5745aaa317842b862f5eb17d2b930437ea903a5eebd8ba5895cdfd",
	"scripts/acts/act2/ruined_house_snapshot_rules.gd.uid": "6b96fb5980969af07520c4e8b7c9876bec78674cc4e3a330309065fd1548052c",
	"scripts/acts/act2/salvage_handler_actor.gd": "42457249e8a30e2d28ad0d03017d16e2f5158092ad3531e528ccf6beb3f70d96",
	"scripts/acts/act2/salvage_handler_actor.gd.uid": "5113c91bd8fc2b39c66747b85bb636a306e91af322760edd9dd9f08a082a4bd9",
	"scripts/acts/act2/salvage_handler_visual.gd": "601b6713e01d7883d729729eb30c16ca80f23b22359e32ae6bc2ee4ff1ff08d2",
	"scripts/acts/act2/salvage_handler_visual.gd.uid": "1691399738950ffe35ec2dc47c25c3a68cfdbe9cf3cb7c9f569e3aa57cf5be60",
	"scripts/acts/act2/smoke_bank_visual.gd": "90d6fb068104381cce36790f9d6ab1c8ad36a63e22cc9c6f02f1c28d45d6f7f1",
	"scripts/acts/act2/smoke_bank_visual.gd.uid": "783937941adb618033848e271ea985342e1cf9b834d8b59eb76de43e6a9a6bc0",
	"scripts/acts/act2/weybridge.gd": "171680483795c75272d0d7e8b64a85c348d2b4b552acb92a2d3638febe694a2b",
	"scripts/acts/act2/weybridge.gd.uid": "0d8fba434b769a929e96d8c742cbec18b88dd7e0694cf0c39b50cd277c374f66",
	"scripts/acts/act2/weybridge_kit.gd": "3b045f0d501a69e76df0a80526371f9742b8cbf782e3d7e51247317c58953db2",
	"scripts/acts/act2/weybridge_kit.gd.uid": "d3ef8517c85dec515c5188d59fcf3a54428e3a54e7672955e858d8b5b9d3c841",
	"scripts/acts/act2/weybridge_scout_actor.gd": "7e90bfc541c467162a5a0b0afd6891e8aa6dda9835a4da05362e9301eed78916",
	"scripts/acts/act2/weybridge_scout_actor.gd.uid": "5989b7441d9204072dc29781966826bd710f010803cbab20d3779c67a424ea1a",
	"scripts/acts/act2/weybridge_sequence.gd": "d28de78224f6985c377a13f9a4d9874ac2766aeb9bc744efe9640ce05f8f7dfc",
	"scripts/acts/act2/weybridge_sequence.gd.uid": "7648b4184ac6c9b90dce41d1cafaa15458be3b762402a5319ee74cad343baaef",
}
# These three original producer hashes differ. Pin the independently published
# shared37 bytes for THIS new consumer test; never rewrite old provenance.
const COMPATIBLE_SHARED37_SHA: Dictionary = {
	"scripts/campaign/shell.gd": "01440e201b83334793cc0e607c7b2f1777d02833f6cdb2c539bad30bce9dd07a",
	"scripts/combat/smoke_bank.gd": "698a70275c438be088fe8abeb7a35083444879364a3acda3ae91194fe4c67ae9",
	"scripts/combat/threat_scheduler.gd": "9b11730b4041dfb73a20e97bda0c72854a89af1ab79809fb3d8449fec624ae79",
}
var _tr_root: String = ""
var _tr_expected_l4_commit: String = ""
var _tr_original: Dictionary = {}
var _tr_restore_watch: bool = false
var _tr_restore_events: Array[String] = []
var _tr_defeats: Array[String] = []
var _tr_completions: Array[String] = []
var _tr_exits: Array[String] = []
var _tr_exit_actor: Dictionary = {}
var _tr_exit_anchor := Vector2.ZERO
var _tr_old_refs: Array[Dictionary] = []
var _tr_finished: bool = false
var _tr_watchdog: TransitionWatchdog

# TEST ONLY observer: monotonic wall time checked on actual process frames.
# Never changes focus, pause, clocks, rendering policy or production actors.
class TransitionWatchdog:
	extends Node
	signal expired
	var deadline_ms: int
	var fired: bool = false
	func _init() -> void:
		process_mode = Node.PROCESS_MODE_ALWAYS
		deadline_ms = Time.get_ticks_msec() + 240000
	func _process(_delta: float) -> void:
		if not fired and Time.get_ticks_msec() >= deadline_ms:
			fired = true
			expired.emit()

func _run() -> void:
	_tr_root = "user://test-root-a2-l3-l4-transition-%d-%d/" % [OS.get_process_id(), Time.get_ticks_usec()]
	root.size = Vector2i(540, 1170)
	_canonical = FileAccess.get_file_as_string(Registry.DATA_PATH)
	_native_probe = NativeTickProbe.new()
	root.add_child(_native_probe)
	node_added.connect(_tr_observe_added)
	_tr_watchdog = TransitionWatchdog.new()
	_tr_watchdog.expired.connect(func() -> void:
		if not _tr_finished:
			_expect(false, "production remainder/transition exceeded its monotonic240s process-observed watchdog")
			print("Root transition TIMEOUT level=", _game.active_level.level_id if is_instance_valid(_game) and is_instance_valid(_game.active_level) else "none", " page=", _game.menu.page_name() if is_instance_valid(_game) else "none", " paused=", paused, "; no completion/cleanup credit")
			quit(1))
	root.add_child(_tr_watchdog)
	var before: int = _failures
	if not await _tr_route() and _failures == before: _expect(false, "production remainder/transition aborted without a recorded cause")
	await _tr_finish()

func _tr_finish() -> void:
	if _tr_finished: return
	_tr_finished = true
	await process_frame
	_tr_restore_watch = false
	if is_instance_valid(_game): _release_fixture_shell(_game)
	_game = null
	if is_instance_valid(_native_probe): _native_probe.free()
	if is_instance_valid(_tr_watchdog): _tr_watchdog.free()
	paused = false
	_expect(FileAccess.get_file_as_string(Registry.DATA_PATH) == _canonical and FileAccess.get_sha256(ORIGINAL_ARTIFACT) == ORIGINAL_ARTIFACT_SHA and FileAccess.get_sha256(ORIGINAL_BOSS_FIXTURE) == ORIGINAL_BOSS_FIXTURE_SHA, "production registry/original artifact/eight-kernel Boss fixture remain byte-exact")
	_expect(get_nodes_in_group("enemies").is_empty() and get_nodes_in_group("required_cues").is_empty(), "isolated restored/transitional worlds retire every target and required cue")
	_tr_cleanup()
	print("Root earned L3 remainder -> production L4: %d checks, %d failures; untouched original Boss15 Attempts/GUI Continue/native routed ordinary remainder/real contact/carry/retirement; no earlier route or L4 combat claim" % [_checks, _failures])
	quit(0 if _failures == 0 else 1)

func _tr_route() -> bool:
	if not _tr_read_original() or not _tr_production_identity(): return false
	var registry: CinderCampaignRegistry = Registry.new()
	var original_payload: Dictionary = _tr_original.attempts_payload
	var original_wire: String = TransitionExact.stringify(original_payload)
	var model: CinderCampaignAttempts = Attempts.new(registry)
	var store: CinderSaveStore = Store.new(_tr_root + "campaign.json")
	store.payload_validator = model.saved_payload_error
	if not _expect(not original_wire.is_empty() and model.state_error(original_payload).is_empty() and store.write_payload(original_payload) and TransitionExact.stringify(original_payload) == original_wire, "public format2 Store writes the untouched complete original Attempts payload, with no new seed or field replacement"): return false
	var disk: Variant = JSON.parse_string(FileAccess.get_file_as_string(_tr_root + "campaign.json"))
	if not _expect(disk is Dictionary and disk.get("format_version") == 2 and disk.get("payload_json") == original_wire, "isolated actual disk uses format2 exact original payload"): return false
	_loadout_name = "heavy"; _profile_id = "standard"
	if not _read_options() or not _expect(_loadout_name == "heavy" and _profile_id == "standard" and not _capture_live and not _road_only, "remainder fixes the original Heavy/Standard context without route/art selectors"): return false
	_game = Shell.new() as CinderCampaignShell
	if not _expect(_game.configure_runtime({}, _tr_root + "campaign.json", _tr_root + "settings.json", _tr_root + "preferences.json"), "actual Shell uses its production Registry and only PID-isolated save/settings paths"): return false
	root.add_child(_game)
	await _settle()
	if not _expect(paused and _game.menu.page_name() == "title" and _game.campaign_error.is_empty(), "fresh actual Title loads original earned story"): return false
	_tr_restore_watch = true
	if not await _tr_click("ContinueStoryButton"): return false
	_tr_restore_watch = false
	var expected: Dictionary = original_payload.story.snapshot
	if not _expect(_live() and paused and _game.menu.page_name() == "resume" and _game.active_level.scene_file_path == HOUSE_SCENE and _game.active_level.get_script() == HouseRoot, "real GUI Continue installs the accepted actual L3 source paused"): return false
	var actual: Dictionary = _game.capture_campaign_snapshot()
	if not _expect(not actual.is_empty() and _game.player.snapshot_error(actual.player).is_empty() and _game.active_level.snapshot_error_with_player(actual.level, actual.player).is_empty() and TransitionExact.stringify(actual) == TransitionExact.stringify(expected), "fresh whole Player/level/Scheduler/Smoke tuple exactly equals the original current saved unit"): return false
	if not _expect(TransitionExact.stringify(_game.attempts.state()) == original_wire and _tr_restore_events.is_empty(), "quiet original Continue neither edits complete Attempts/checkpoint nor publishes gameplay callbacks: " + str(_tr_restore_events)): return false
	await _settle()
	if not _expect(TransitionExact.stringify(_game.capture_campaign_snapshot()) == TransitionExact.stringify(expected), "held paused original unit retains exact input/camera/gear/resources/clocks"): return false
	_actors = _game.active_level.get("_actors").duplicate()
	_banks = _game.active_level.get("_clouds").duplicate()
	_boss_hp_observed = float(_actors.handling_machine.get("hp"))
	_tr_bind_current()
	if not await _tr_click("ResumeButton") or not _expect(not paused and _game.player.get_world_action_clock() >= float(expected.player.world_actions.clock_s), "actual GUI Resume consumes menu input and advances only the installed unit"): return false
	# SideTender is genuinely optional; this narrow direct-consumer case keeps
	# its actual native source alive unless a real ordinary cone also defeats it.
	# The inherited bot still escapes every current counterpart's actual proof.
	if not await _tr_finish_boss(): return false
	for tick: int in range(1200):
		if not _live(): return false
		if _game.active_level.is_completed(): break
		await _step()
	# Completion publication has a deferred Shell drain; inspect it only after
	# normal process frames settle the durable story operation.
	await _settle()
	if not _expect(_game.active_level.is_completed() and _state().beat == "clear" and _state().exit_open and _tr_completions == ["ruined-house-escape"] and _tr_exits.is_empty() and _tail_pending.is_empty(), "actual required Boss defeat/tails complete once before separate breakout contact"): return false
	if not _expect(_actors.handling_machine.get("hp") == 0.0 and _actors.handling_machine.get("max_hp") == 30.0 and _actors.handling_machine.get("boss_phase") == 2 and _game.attempts.state().completed_main == HOUSE_PREFIX + ["A2-L3"], "ordinary remainder earns actual L3 completion from the original15HP pool without new prior progress"): return false
	if not _expect(_game.request_pause_deferred(), "public whole-tick pause requested before the separate exit"): return false
	await _settle()
	var completed: Dictionary = _game.capture_campaign_snapshot()
	if not _expect(paused and not completed.is_empty() and completed.level.progress.completed and completed.level.progress.contact_exit_id.is_empty() and _game.player.snapshot_error(completed.player).is_empty() and _game.active_level.snapshot_error_with_player(completed.level, completed.player).is_empty(), "completed living original world remains a coherent paused unit before exit"): return false
	for action: Dictionary in _actions:
		if not _expect(action.kind != "blast" and action.equipment_ids == _loadout and Codec.same_values(action.resolved_stats, _expected_stats), "new actual actions use canonical retained Heavy gear/stats and no blast"): return false
	if not _expect(not _boss_hits.is_empty() and _boss_hits[0].before == 15.0 and _boss_hits.back().after == 0.0 and _tr_defeats.has("handling_machine"), "new actual ordinary primary independently consumes only the original remaining Boss pool"): return false
	_tr_collect_refs(_game.world)
	# The public Store backup after advance_story retains the immediately prior
	# exact final L3 exit unit, captured by Shell before constructing L4. Read
	# that real disk generation instead of querying native actors during free.
	if not await _tr_click("ResumeButton") or not await _dash_to_exit(): return false
	await _settle()
	if not _expect(_game.campaign_error.is_empty() and _game.active_level.level_id == "A2-L4" and _game.active_level.scene_file_path == REGISTERED_L4_SCENE and _game.active_level.get_script().resource_path == REGISTERED_L4_SCRIPT and paused and _game.menu.page_name() == "resume", "actual quiet breakout installs the registered production L4 at its normal Resume boundary"): return false
	var arrival: Dictionary = _game.capture_campaign_snapshot()
	var previous_store: CinderSaveStore = Store.new(_tr_root + "campaign.json.bak")
	var previous: Dictionary = previous_store.read_payload()
	if not _expect(not previous.is_empty() and previous.get("story") is Dictionary and previous.story.level_id == "A2-L3" and previous.story.snapshot.level_id == "A2-L3" and previous.story.snapshot.level.progress.completed and previous.story.snapshot.level.progress.contact_exit_id == "excavation-breakout" and TransitionExact.stringify(previous.story.checkpoint) == TransitionExact.stringify(_tr_original.checkpoint), "public previous disk generation retains the real final L3 exit tuple and unchanged original living checkpoint"): return false
	_tr_exit_actor = previous.story.snapshot.player
	_tr_exit_anchor = Vector2(previous.story.snapshot.shell.anchor_normalized[0], previous.story.snapshot.shell.anchor_normalized[1])
	if not _expect(not arrival.is_empty() and not _tr_exit_actor.is_empty() and _game.player.snapshot_error(arrival.player).is_empty() and _game.active_level.snapshot_error_with_player(arrival.level, arrival.player).is_empty(), "production L4 entry and actual prior disk exit receipt are coherent complete units"): return false
	if not _expect(arrival.player.resources.hp == _tr_exit_actor.resources.hp and arrival.player.resources.shells == _tr_exit_actor.resources.shells and arrival.player.clocks.reload_s == _tr_exit_actor.clocks.reload_s and arrival.equipment_ids == _tr_exit_actor.equipment, "actual story transition carries native HP/ammo/reload/static gear without a refill"): return false
	if not _expect(arrival.player.motion.position == Codec.vector3(_game.active_level.spawn_position()) and arrival.player.world_actions.clock_s == 0.0 and arrival.player.world_actions.sequence == 0 and arrival.level.local.scheduler.clock_s == 0.0 and arrival.level.local.sequence.stage_index == 0 and arrival.level.local.sequence.defeated_ids.is_empty() and not arrival.level.progress.completed and arrival.level.progress.contact_exit_id.is_empty(), "fresh L4 starts its coherent new clocks/encounter rather than replaying L3 history or claiming L4 completion"): return false
	var l4_actors: Dictionary = _game.active_level.get("_actors")
	if not _expect(l4_actors.size() == 9 and _game.active_level.get("_clouds").size() == 2 and _game.active_level.get("_mechanisms").size() == 4 and _game.player.presentation_id == "act2_survivor", "production entry contains all9 actual targets/2 banks/4 tools and retained Act2 shared actor presentation"): return false
	for actor: Node in l4_actors.values():
		if not _expect(actor.get("hp") == 30.0 and actor.get("max_hp") == 30.0, "fresh production source retains its authored initial HP30"): return false
	if not _expect(_tr_exits == ["excavation-breakout"] and _tr_completions == ["ruined-house-escape"] and _game.attempts.state().story.level_id == "A2-L4" and _game.attempts.state().completed_main == HOUSE_PREFIX + ["A2-L3"] and TransitionExact.stringify(_game.attempts.state().story.checkpoint) == TransitionExact.stringify(arrival) and TransitionExact.stringify(_game.attempts.active_snapshot()) == TransitionExact.stringify(arrival), "production story advances once and protects its genuine new living entry checkpoint"): return false
	var disk_store: CinderSaveStore = Store.new(_tr_root + "campaign.json")
	if not _expect(TransitionExact.stringify(disk_store.read_payload()) == TransitionExact.stringify(_game.attempts.state()), "actual transition disk contains the complete coherent new production story"): return false
	var required: Array = _game.active_level.call("camera_framing_points")
	# Idle entry can legitimately have no committed threat. Measure the actual
	# shared body/art/shadow corners as required, without inventing a warning.
	required.append_array(_game.player_camera_framing_points())
	if not _expect(not required.is_empty() and _game.camera_framing_error(required).is_empty() and _game.hud.combat_safe_rect().has_point(Vector2(0.5, 0.5)), "actual current camera/HUD contain the fresh required L4 entry union"): return false
	var objective: Label = _game.hud.find_child("ObjectiveLabel", true, false) as Label
	if not _expect(is_instance_valid(objective) and objective.text == _game.active_level.objective_text.to_upper() and arrival.shell.anchor_normalized == [_game.get_aim_anchor_normalized().x, _game.get_aim_anchor_normalized().y], "real L4 objective/current input anchor are installed, rather than old scene UI"): return false
	# New exit swipes legitimately changed the release anchor; fresh shell
	# copies that final native anchor while resetting only its observation log.
	if not _expect(arrival.shell.input_sequence == 0 and arrival.shell.last_input_observation.is_empty() and arrival.shell.anchor_normalized == [_tr_exit_anchor.x, _tr_exit_anchor.y], "new constructor retains last actual exit release anchor with fresh observation custody"): return false
	for record: Dictionary in _tr_old_refs:
		if not _expect(record.ref.get_ref() == null, "actual production transition retires old native subtree: " + record.label): return false
	return true

func _tr_read_original() -> bool:
	var selectors: int = 0
	for argument: String in OS.get_cmdline_user_args():
		if argument.begins_with("--expected-l4-commit="):
			selectors += 1; _tr_expected_l4_commit = argument.trim_prefix("--expected-l4-commit=")
	if not _expect(selectors == 1 and _tr_expected_l4_commit.length() == 40 and _tr_expected_l4_commit.is_valid_hex_number(false), "explicit exact production L4 commit is required"): return false
	if not _expect(FileAccess.get_sha256(ORIGINAL_ARTIFACT) == ORIGINAL_ARTIFACT_SHA and FileAccess.get_sha256(ORIGINAL_BOSS_FIXTURE) == ORIGINAL_BOSS_FIXTURE_SHA, "immutable original earned artifact and strict Boss fixture bytes match their reviewed pins"): return false
	var bytes: String = FileAccess.get_file_as_string(ORIGINAL_ARTIFACT)
	if not _expect(DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(_tr_root)) == OK, "create PID-isolated input/save directory"): return false
	var copy: FileAccess = FileAccess.open(_tr_root + "earned-input.json", FileAccess.WRITE)
	if not _expect(copy != null, "independent original byte copy can be created"): return false
	copy.store_string(bytes); copy.close()
	if not _expect(FileAccess.get_sha256(_tr_root + "earned-input.json") == ORIGINAL_ARTIFACT_SHA and FileAccess.get_file_as_string(_tr_root + "earned-input.json") == bytes, "copied input retains every original envelope/Attempts byte"): return false
	var decoded: Dictionary = TransitionExact.parse(FileAccess.get_file_as_string(_tr_root + "earned-input.json"))
	if not _expect(decoded.get("accepted", false) and decoded.get("value") is Dictionary, "original artifact uses strict bounded ExactJson types/bits"): return false
	_tr_original = decoded.value
	if not _expect(Codec.keys_error(_tr_original, ["api_revision", "scope", "level_id", "loadout", "profile", "source_sha256", "boundary_records", "boss_hits", "checkpoint", "attempts_payload"]).is_empty() and _tr_original.api_revision == "act2-earned-boss-checkpoint-1" and _tr_original.level_id == "A2-L3" and _tr_original.loadout == "heavy" and _tr_original.profile == "standard" and _tr_original.scope is String and _tr_original.source_sha256 is Dictionary and _tr_original.boundary_records is Array and _tr_original.boss_hits is Array and _tr_original.checkpoint is Dictionary and _tr_original.attempts_payload is Dictionary, "independent reader retains exact original real-route envelope/context"): return false
	var payload: Dictionary = _tr_original.attempts_payload
	if not _expect(payload.get("story") is Dictionary and payload.story.get("checkpoint") is Dictionary and payload.story.get("snapshot") is Dictionary and payload.get("side_attempt") == null and payload.completed_main == HOUSE_PREFIX and TransitionExact.stringify(payload.story.checkpoint) == TransitionExact.stringify(_tr_original.checkpoint), "complete untouched Attempts protects its original actual checkpoint and producer's disclosed TEST ONLY predecessor prefix"): return false
	var saved: Dictionary = payload.story.snapshot
	var checkpoint: Dictionary = _tr_original.checkpoint
	if not _expect(saved.level_id == "A2-L3" and saved.scene_path == HOUSE_SCENE and saved.paused == true and saved.equipment_ids == LOADOUTS.heavy and not saved.player.resources.dead and saved.player.resources.hp == 100.0 and saved.player.resources.shells == 2 and saved.level.local.profile_id == "standard", "real producer kept living100HP and naturally earned2shells; this consumer neither resets ammo nor claims current empty ammo"): return false
	var local: Dictionary = checkpoint.level.local
	if not _expect(local.targets.handling_machine.actor.hp == 15.0 and local.targets.handling_machine.actor.max_hp == 30.0 and local.targets.handling_machine.boss_phase == 2 and not local.targets.handling_machine.transition_pending and not local.boss_phase_pending and local.targets.side_tender.hp == 30.0 and local.sequence.stage_index == 7 and local.sequence.boss_phase == 2 and local.sequence.crossed_contacts == HOUSE_CONTACT_ORDER and local.sequence.defeated_ids.size() == 5 and checkpoint.level.progress.checkpoint_id == "handling-machine-phase-two" and not checkpoint.level.progress.completed and checkpoint.level.progress.contact_exit_id.is_empty(), "original actual15HP checkpoint retains only its five real defeats/three contacts and living optional source"): return false
	if not _expect(_tr_original.boundary_records.size() == 1 and _tr_original.boss_hits.size() == 1 and _tr_original.boundary_records[0].hp == 15.0 and _tr_original.boundary_records[0].transition_pending and _tr_original.boss_hits[0].before == 30.0 and _tr_original.boss_hits[0].after == 15.0 and _tr_original.boss_hits[0].source_id == "boss_place", "real original overkill/boundary witness remains verbatim"): return false
	return true

func _tr_production_identity() -> bool:
	var registry: CinderCampaignRegistry = Registry.new()
	if not _expect(registry.last_error.is_empty() and registry.entry("A2-L3").accepted_commit == ACCEPTED_L3_COMMIT and registry.entry("A2-L3").scene_path == HOUSE_SCENE and registry.entry("A2-L4").readiness == "accepted" and registry.entry("A2-L4").accepted_commit == _tr_expected_l4_commit and registry.entry("A2-L4").scene_path == REGISTERED_L4_SCENE and registry.scene_error("A2-L3").is_empty() and registry.scene_error("A2-L4").is_empty(), "real production Registry must contain accepted exact L3/L4 scenes/commits; no metadata override"): return false
	if not _expect(ACCEPTED_PRODUCTION_SHA.size() == 65, "reviewed accepted production custody includes exactly65 prior owned blobs"): return false
	for path: String in ACCEPTED_PRODUCTION_SHA:
		if not _expect(FileAccess.get_sha256("res://" + path) == ACCEPTED_PRODUCTION_SHA[path], "accepted L1/L2/L3 production/reuse bytes remain exact: " + path): return false
	for path: String in COMPATIBLE_SHARED37_SHA:
		if not _expect(FileAccess.get_sha256("res://" + path) == COMPATIBLE_SHARED37_SHA[path] and _tr_original.source_sha256.has(path) and _tr_original.source_sha256[path] != COMPATIBLE_SHARED37_SHA[path], "new consumer uses separately reviewed shared37 kernel while original producer hash stays unchanged: " + path): return false
	for path: String in ["scripts/acts/act2/ruined_house.gd", "scripts/acts/act2/ruined_house_smoke_rules.gd", "scripts/acts/act2/ruined_house_bank_guard.gd", "scripts/acts/act2/handling_machine_boss_actor.gd", "scripts/player.gd"]:
		if not _expect(_tr_original.source_sha256.get(path) == FileAccess.get_sha256("res://" + path), "five still-retained original gameplay kernels remain exact: " + path): return false
	print("Original artifact=", ORIGINAL_ARTIFACT_SHA, " accepted65=", ACCEPTED_L3_COMMIT, " current new compatibility=Shared37; no historical8kernel equality claim")
	return true

func _tr_bind_current() -> void:
	for actor: Node in _actors.values():
		actor.connect("defeated", func(id: String) -> void: _tr_defeats.append(id); _observe_defeat(id))
	_game.player.world_action_executed.connect(func(record: Dictionary) -> void: _actions.append(record.duplicate(true)); _observe_wall_path(record))
	_game.active_level.completion_requested.connect(func(_level: String, id: String) -> void: _tr_completions.append(id))
	_game.active_level.contact_exit_requested.connect(func(_level: String, id: String) -> void: _tr_exits.append(id))

func _tr_observe_added(node: Node) -> void:
	if node is CinderPlayer:
		node.connect("world_action_executed", func(_record: Dictionary) -> void:
			if _tr_restore_watch: _tr_restore_events.append("action"))
		node.connect("fired", func(kind: String) -> void:
			if _tr_restore_watch: _tr_restore_events.append("fired:" + kind))
		node.connect("died", func() -> void:
			if _tr_restore_watch: _tr_restore_events.append("death"))
	if node.has_signal("defeated"):
		node.connect("defeated", func(_id: String) -> void:
			if _tr_restore_watch: _tr_restore_events.append("defeat"))
	if node is CinderThreatScheduler:
		node.reservation_invalidated.connect(func(_id: String, _reason: String) -> void:
			if _tr_restore_watch: _tr_restore_events.append("reservation-invalidated"))
	if node is CinderLevel:
		node.checkpoint_requested.connect(func(_id: String, _point: String, _boundary: String) -> void:
			if _tr_restore_watch: _tr_restore_events.append("checkpoint"))
		node.completion_requested.connect(func(_id: String, _completion: String) -> void:
			if _tr_restore_watch: _tr_restore_events.append("completion"))
		node.contact_exit_requested.connect(func(_id: String, _exit: String) -> void:
			if _tr_restore_watch: _tr_restore_events.append("exit"))
	if node is Act2RayScoutExchange:
		node.state_changed.connect(func(_id: String, _state: Dictionary) -> void:
			if _tr_restore_watch: _tr_restore_events.append("ray-state"))
		node.hit_resolved.connect(func(_id: String, _hit: Dictionary) -> void:
			if _tr_restore_watch: _tr_restore_events.append("ray-hit"))
		node.scout_defeated.connect(func(_id: String) -> void:
			if _tr_restore_watch: _tr_restore_events.append("scout-defeat"))
	if node is CinderLaneMechanism:
		node.state_changed.connect(func(_state: Dictionary) -> void:
			if _tr_restore_watch: _tr_restore_events.append("tool-state"))
		node.connect("hit_resolved", func(_hero: String, _cycle: int, _result: Dictionary) -> void:
			if _tr_restore_watch: _tr_restore_events.append("tool-hit"))
	elif node.get_script() == SmokeBank:
		node.state_changed.connect(func(_state: Dictionary) -> void:
			if _tr_restore_watch: _tr_restore_events.append("bank-state"))
		node.connect("tick_resolved", func(_hero: String, _cycle: int, _result: Dictionary) -> void:
			if _tr_restore_watch: _tr_restore_events.append("bank-tick"))
	if node is CinderThreatCue:
		node.connect("state_changed", func(state: Dictionary) -> void:
			if _tr_restore_watch and state.get("phase") != "clear": _tr_restore_events.append("cue:" + String(state.get("phase"))))

func _tr_finish_boss() -> bool:
	# Reuse real inherited proof selection/preemption/navigation, but do not
	# demand a repeat of BOTH full-route Boss grammar cycles before consuming
	# this already-earned15HP opening. This is a remainder, not a grammar suite.
	for tick: int in range(2400):
		if not _live(): return _expect(false, "remaining actual Boss source stopped: " + _diagnostic())
		if float(_actors.handling_machine.get("hp")) <= 0.0:
			for settle_tick: int in range(4): await _step()
			return _expect(not _boss_hits.is_empty(), "Boss remainder was defeated by a newly observed actual recovering primary")
		var plan: Dictionary = _latest_actor_plan(["handling_machine"])
		if plan.is_empty(): plan = _latest_actor_plan(_state().active_ids)
		if not plan.is_empty():
			_used_proofs[plan.key] = true
			if not await _follow_proof(plan, plan.actor_id == "handling_machine"): return false
		elif tick % 90 == 0:
			var target: Node3D = _actors.handling_machine as Node3D
			var offset: Vector3 = _game.player.global_position - target.global_position
			offset.y = 0.0
			if offset.length() > 3.45 and not await _navigate_dash(target.global_position + offset.normalized() * 3.0): return false
		await _step()
	return _expect(false, "bounded native ordinary remainder could not reach the real Boss recovery: " + _diagnostic())

func _tr_click(name: String) -> bool:
	await _settle()
	var button: Button = _game.menu.find_child(name, true, false) as Button
	if not _expect(is_instance_valid(button) and button.is_visible_in_tree() and not button.disabled, "actual enabled menu button exists: " + name): return false
	var seen: Array[String] = []
	button.pressed.connect(func() -> void: seen.append(name))
	var point: Vector2 = button.get_global_rect().get_center()
	if not _expect(point.is_finite() and button.get_viewport().get_visible_rect().has_point(point), "actual GUI button center is inside native viewport: " + name): return false
	var ancestor: Node = button.get_parent()
	while ancestor != null:
		if ancestor is Control and (ancestor.clip_contents or ancestor is ScrollContainer):
			if not _expect(ancestor.get_global_rect().has_point(point), "actual GUI button center is inside every ancestor clip: " + name): return false
		ancestor = ancestor.get_parent()
	var motion := InputEventMouseMotion.new()
	motion.position = point; motion.global_position = point
	root.push_input(motion, true)
	var press := InputEventMouseButton.new()
	press.button_index = MOUSE_BUTTON_LEFT; press.position = point; press.global_position = point; press.pressed = true
	root.push_input(press, true)
	var release := press.duplicate() as InputEventMouseButton
	release.pressed = false
	root.push_input(release, true)
	await _settle()
	return _expect(seen == [name] and _game.campaign_error.is_empty(), "one actual GUI click settles once: " + name + " " + _game.campaign_error)

func _tr_collect_refs(node: Node) -> void:
	_tr_old_refs.append({"label": String(node.name), "ref": weakref(node)})
	for child: Node in node.get_children(): _tr_collect_refs(child)

func _tr_cleanup() -> void:
	if _tr_root.is_empty(): return
	for name: String in ["earned-input.json", "campaign.json", "campaign.json.bak", "settings.json", "settings.json.bak", "preferences.json", "preferences.json.bak"]:
		DirAccess.remove_absolute(ProjectSettings.globalize_path(_tr_root + name))
	DirAccess.remove_absolute(ProjectSettings.globalize_path(_tr_root))

# Original inherited proof semantics, with an actual native-input adapter.
func _follow_proof(plan: Dictionary, attack: bool) -> bool:
	var reservation: Dictionary = plan.reservation
	var trace_proof: bool = _road_only and _proof_diagnostics < 3
	if trace_proof:
		_proof_diagnostics += 1
		print("Road proof starts: clock=", _state().clock_s, " plan=", plan)
	var source: String = plan.source_id
	var role_key: String = "bank" if HouseSequence.TENDERS.has(plan.actor_id) else ("ray" if plan.actor_id == "apron_scout" else "tool")
	if not _expect(Codec.same_values(plan.resolved_role, _expected_roles[role_key]) and is_equal_approx(float(reservation.active_from_s) - float(reservation.lock_from_s), float(_expected_roles[role_key].lock_s)) and float(reservation.active_from_s) - float(reservation.lock_from_s) >= 1.1 - 0.00001 and plan.proof.uses_blast == false and plan.proof.uses_invulnerability == false, "actual %s proof retains shared resolved role/full1.10 lock and ordinary-primary response" % source): return false
	for segment: Dictionary in plan.proof.path:
		if segment.kind not in ["escape_dash", "positioning_dash", "ordinary_primary"]: continue
		if trace_proof: print("Road proof segment waiting: clock=", _state().clock_s, " segment=", segment)
		while _live() and float(_state().clock_s) + 0.00001 < float(segment.start_s):
			if not _plan_current(plan) or not _replacement_plan(plan, attack).is_empty(): return true
			await _step()
		if not _live(): return false
		if not _plan_current(plan) or not _replacement_plan(plan, attack).is_empty(): return true
		if segment.kind == "ordinary_primary":
			if not attack: continue
			var id: String = plan.actor_id
			var actor: Node3D = _actors[id] as Node3D
			var current: Dictionary = _state().exchanges[id]
			if trace_proof: print("Road primary reached: clock=", _state().clock_s, " phase=", current.phase)
			if float(actor.get("hp")) <= 0.0 or current.phase != "recovery": return true
			var direction: Vector3 = actor.global_position - _game.player.global_position
			direction.y = 0.0
			var hp_before: float = float(actor.get("hp"))
			var boss_phase_before: int = int(actor.get("boss_phase")) if id == "handling_machine" else 0
			var diagnostic: Dictionary = {"plan": plan, "hero_position": _game.player.global_position, "hero_response": _game.player.get_threat_response_state(), "range": _game.player.stats.primary_range, "distance": direction.length(), "actor_hp": hp_before, "actor_phase": actor.get("phase"), "current": current, "root": _state()}
			var hits: int = _tr_routed_primary(direction.normalized())
			if hits <= 0: print("Ruined House zero-hit primary actual pre-action diagnostic: ", diagnostic)
			if id == "handling_machine" and hits > 0:
				var hp_after: float = float(actor.get("hp"))
				_boss_hits.append({"before": hp_before, "after": hp_after, "phase": boss_phase_before, "damage": _game.player.stats.primary_damage, "source_id": source})
				_expect(hp_after < hp_before and (hp_after >= 15.0 if boss_phase_before == 1 else hp_after >= 0.0), "ordinary primary truly damages B02 without refill or crossing first-phase threshold")
			return _expect(hits > 0, "actual %s ordinary primary reaches recovering %s" % [_loadout_name, id])
		var direction: Vector3 = segment.to - segment.from
		direction.y = 0.0
		if not await _dash(direction.normalized(), false, plan, segment): return false
		if _proof_dash_abandoned:
			if trace_proof: print("Road proof dash abandoned: clock=", _state().clock_s, " segment=", segment, " current=", _plan_current(plan), " response=", _game.player.get_threat_response_state())
			return true
	return true

func _dash_to_exit() -> bool:
	for attempt: int in range(18):
		if _game.active_level.level_id != "A2-L3": return _expect(_game.active_level.level_id == "A2-L4" and _game.active_level.scene_file_path == REGISTERED_L4_SCENE, "only actual breakout navigation transitions to registered production L4")
		var region: Rect2 = HouseRoot.BREAKOUT
		if not await _navigate_dash(Vector3(region.get_center().x, 0, region.get_center().y), true): return false
		if _game.active_level.level_id != "A2-L3": return true
		if _dash_touches_region(_last_dash(), region):
			for frame: int in range(180):
				if _game.active_level.level_id != "A2-L3": return true
				await _step()
	return _expect(false, "actual breakout failed to transition: " + _diagnostic())

func _dash(direction: Vector3, allow_exit_transition: bool = false, proof_plan: Dictionary = {}, proof_segment: Dictionary = {}) -> bool:
	_proof_dash_abandoned = false
	var hero: CinderPlayer = _game.player
	var ready: bool = false
	for frame: int in range(180):
		if not _live(): return false
		if not proof_plan.is_empty() and not _proof_dash_current(proof_plan, proof_segment):
			_proof_dash_abandoned = true
			return true
		var response: Dictionary = hero.get_threat_response_state()
		if not paused and response.stable and float(response.dash_cooldown_left_s) <= 0.00001:
			ready = true
			break
		await _step()
	if not _expect(ready, "bot awaits unpaused stable shared actor and native dash cooldown"): return false
	if not proof_plan.is_empty() and not _proof_dash_current(proof_plan, proof_segment):
		_proof_dash_abandoned = true
		return true
	var before: int = _actions.size()
	if not _tr_routed_swipe(direction): return false
	for frame: int in range(180):
		for action: Dictionary in _actions.slice(before):
			if action.kind == "dash": return _expect(action.landing.is_finite() and action.landing.y > -0.05 and action.path.size() >= 2, "actual completed dash has supported sampled world landing")
		if not is_instance_valid(hero):
			if allow_exit_transition and _game.campaign_error.is_empty() and _game.active_level.level_id == "A2-L4" and _game.active_level.scene_file_path == REGISTERED_L4_SCENE:
				return _expect(true, "actual breakout may transition during a dash without fabricating its unfinished world-action record")
			break
		await _step()
	return _expect(false, "shared dash did not publish a completed world action")

func _screen_delta(direction: Vector3) -> Vector2:
	var right: Vector3 = _game.camera.global_basis.x
	var down: Vector3 = _game.camera.global_basis.z
	right.y = 0.0
	down.y = 0.0
	return Vector2(direction.dot(right.normalized()), direction.dot(down.normalized())) * 120.0

func _tr_routed_swipe(direction: Vector3) -> bool:
	var before: int = int(_game.get_input_observation_state().sequence)
	var start: Vector2 = Vector2(0.5, 0.60) * root.get_visible_rect().size
	var end: Vector2 = start + _screen_delta(direction)
	if not _expect(_game.screen_to_direction(end - start).is_equal_approx(direction.normalized()), "actual camera maps selected native dash to exact swipe direction"): return false
	var press := InputEventScreenTouch.new()
	press.index = 13; press.pressed = true; press.position = start
	root.push_input(press, true)
	var drag := InputEventScreenDrag.new()
	drag.index = 13; drag.position = end; drag.relative = end - start
	root.push_input(drag, true)
	var release := InputEventScreenTouch.new()
	release.index = 13; release.position = end
	root.push_input(release, true)
	var input: Dictionary = _game.get_input_observation_state()
	var dash: Dictionary = _game.player.get_committed_dash_state()
	return _expect(int(input.sequence) == before + 1 and input.last_observation.get("kind") == "swipe_release" and _game.get_aim_anchor_normalized() == release.position / _game.get_viewport().get_visible_rect().size and input.anchor_normalized == release.position / _game.get_viewport().get_visible_rect().size and input.last_observation.anchor_normalized == release.position / _game.get_viewport().get_visible_rect().size and input.last_observation.screen_position_normalized == release.position / _game.get_viewport().get_visible_rect().size and dash.get("active", false) and dash.direction.is_equal_approx(direction.normalized()), "real routed swipe commits shared dash and exact final-release anchor")

func _tr_routed_primary(direction: Vector3) -> int:
	var before: int = _actions.size()
	var input_before: int = int(_game.get_input_observation_state().sequence)
	var position: Vector2 = _game.get_aim_anchor() + _screen_delta(direction)
	if not _expect(_game.aim_direction(position).is_equal_approx(direction.normalized()), "actual first-tap aim derives from last swipe final release"): return 0
	var press := InputEventScreenTouch.new()
	press.index = 14; press.pressed = true; press.position = position
	root.push_input(press, true)
	var release := InputEventScreenTouch.new()
	release.index = 14; release.position = position
	root.push_input(release, true)
	var input: Dictionary = _game.get_input_observation_state()
	if not _expect(int(input.sequence) == input_before + 1 and input.last_observation.get("kind") == "primary_tap" and input.last_observation.get("accepted", false) and _actions.size() == before + 1 and _actions.back().kind == "primary", "real routed first tap immediately publishes one ordinary primary, no blast"): return 0
	return int(_actions.back().hits)

