extends SceneTree
## Focused changed-constructor qualification, not a route/novelty/transport test.
## Fresh profile input is declared TEST construction on otherwise actual Main.
## Only the immutable recorded Standard archive supplies legacy native history.
const Parent = preload("res://scripts/acts/act3/crystalman_level.gd")
const ParentCodec = preload("res://scripts/acts/act3/crystalman_parent_codec.gd")
const Difficulty = preload("res://scripts/combat/difficulty.gd")
const Exact = preload("res://scripts/campaign/exact_json.gd")
const Value = preload("res://scripts/campaign/snapshot_codec.gd")
const ROOM: String = "res://scenes/acts/act3/a3_l5_crystalman.tscn"
const ARCHIVE: String = "res://assets/acts/act3/evidence/A3-L5-shared57-native/runs/crystalman-c50-public-shared57-headless-session-native/session-archive/crystalman-c50-session-43080-316492648"
const MANIFEST_SHA: String = "7d57ad969ecc252b1cd9c20fb14207fc3f68379eb0949e42f0aa156e08780022"
const LEGACY_FILES: Dictionary = {
	"registry.native.json":{"bytes":13683,"sha256":"d67ec9607ae7b4a036eb978448f159d6b3e1a09552373f2c4ba5915daa23293c"},
	"seed.native.json":{"bytes":978010,"sha256":"ccc02c7d6e8a967a4c8a8ba7a7bea05a5a7d81cc8c5163042a8182757e87f900"},
	"session.native.json":{"bytes":1956885,"sha256":"293a1669f863798c07a64e20d755e111076ff40a39fbbf9f50369cdc2e824c19"}}

class PreferenceMain extends "res://scripts/game.gd":
	# Sole TEST override: an immutable initial factory input, then a future-input
	# mutation to prove the entered attempt does not reread that preference.
	var declared_profile: String = "standard"
	func get_difficulty_preference() -> String: return declared_profile

var _checks: int = 0
var _failures: int = 0
var _events: Array[Dictionary] = []
var _pre_ready: Dictionary = {}
var _hosts: Array[Node] = []
var _viewports: Dictionary = {}
var _rows: Array[Dictionary] = []
var _finishing: bool = false
var _legacy_only: bool = false

func _initialize() -> void:
	node_added.connect(_observe_added)
	_run.call_deferred()

func _run() -> void:
	create_timer(600.0,true,false,true).timeout.connect(_watchdog)
	root.size = Vector2i(340,736)
	root.content_scale_size = root.size
	root.content_scale_mode = Window.CONTENT_SCALE_MODE_CANVAS_ITEMS
	var args: PackedStringArray = OS.get_cmdline_user_args()
	_legacy_only = args.size() == 1 and args[0] == "--legacy-only"
	if not _expect(args.is_empty() or _legacy_only,"default focused format scope or exact --legacy-only selector"):
		await _finish(); return
	if _legacy_only:
		await _legacy_case()
		await _finish(); return
	_key_type_witness()
	_pure_selections()
	if _failures == 0:
		for profile: String in ["standard","assisted","challenge"]:
			if not await _fresh_case(profile): break
	if _failures == 0: await _legacy_case()
	await _finish()

func _pure_selections() -> void:
	for id: String in ["standard","assisted","challenge"]:
		var selected: Dictionary = ParentCodec.fresh_selection(id)
		var canonical: Dictionary = Difficulty.new().profile(id)
		if not _expect(ParentCodec.selection_error(selected).is_empty() and Value.keys_error(selected,["legacy","policy","profile"]).is_empty() and selected.legacy == false and selected.policy.size() == 4 and selected.profile.size() == 8 and _same(selected.profile,canonical) and _same(selected.policy.profile,canonical),"fresh pure selection retains one exact typed canonical full profile: "+id): return
		var expected_recipe: String = "challenge-west-inset-1" if id == "challenge" else "canonical-approach-1"
		_expect(selected.policy.recipe_id == expected_recipe,"one finite profile/recipe pairing: "+id)
	_expect(ParentCodec.fresh_selection("unsupported").is_empty(),"unknown fresh profile cannot configure an encounter")
	var good: Dictionary = ParentCodec.fresh_selection("challenge")
	var bad: Dictionary = good.duplicate(true)
	bad.policy.schema_version = true
	_selection_reject(bad,"Boolean policy version")
	bad = good.duplicate(true); bad.policy["extra"] = 1
	_selection_reject(bad,"extra policy key")
	bad = good.duplicate(true); bad.policy.erase("recipe_id")
	_selection_reject(bad,"missing policy key")
	bad = good.duplicate(true); bad.policy.profile = {"id":"challenge"}
	_selection_reject(bad,"ID-only profile")
	bad = good.duplicate(true); bad.profile.raw_damage_multiplier = 1
	_selection_reject(bad,"integer replacing native float profile field")
	bad = good.duplicate(true); bad.policy.profile.windup_multiplier = INF
	_selection_reject(bad,"nonfinite profile scalar")
	bad = good.duplicate(true); bad.policy.profile.name = "Challenge renamed"
	_selection_reject(bad,"noncanonical full profile")
	bad = good.duplicate(true); bad.policy.recipe_id = "canonical-approach-1"
	_selection_reject(bad,"canonical recipe under new Challenge")
	bad = good.duplicate(true); bad.profile = Difficulty.new().profile("standard")
	_selection_reject(bad,"selection/policy full-profile mismatch")

func _selection_reject(bad: Dictionary,label: String) -> void:
	var before: PackedByteArray = var_to_bytes(bad)
	var error: String = ParentCodec.selection_error(bad)
	_expect(not error.is_empty() and var_to_bytes(bad) == before,label+" rejects purely",error)

func _fresh_case(profile: String) -> bool:
	var host: PreferenceMain = PreferenceMain.new()
	host.declared_profile = profile
	host.level_scene_path = ROOM
	paused = false
	_add_host(host)
	var problem: String = "ordinary initial Camera/HUD not observed"
	for _frame: int in range(90):
		var room: CinderLevel = host.active_level
		if room != null:
			problem = String(room.call("candidate_presentation_error",host.camera,host.hud))
			if problem.is_empty(): break
		await process_frame
	host.open_bench()
	var level: CinderLevel = host.active_level
	if not _expect(level != null and host.player != null and paused and problem.is_empty() and String(level.get("last_configuration_error")).is_empty(),"actual fresh "+profile+" Parent/Player/Camera/HUD reaches a paused native boundary",problem): return false
	var saved: Dictionary = _pair(host)
	if not _expect(not saved.level.is_empty() and not saved.player.is_empty(),"actual full fresh parent and Player write",level.last_snapshot_error): return false
	var local: Dictionary = saved.level.local
	var selection: Dictionary = ParentCodec.fresh_selection(profile)
	var pre: Dictionary = _pre_ready.get(str(level.get_instance_id()),{})
	if not _expect(local.api_revision == "act3-crystalman-parent-local-2" and local.schema_version is int and local.schema_version == 2 and local.size() == 7 and local.approach_policy.size() == 4 and local.approach_policy.profile.size() == 8 and local.route.stage == 0 and local.current_unit.state.stage == 1,"new parent7/policy4/profile8 writes actual initial regular topology: "+profile): return false
	if not _expect(not pre.is_empty() and pre.child_not_ready and _same(pre.selection,selection) and _same(pre.rows,_expected_rows(profile)),"same canonical profile and whole selected rows frozen BEFORE actual Approach ready: "+profile): return false
	if not _expect(_same(local.current_unit.state.scheduler.profile,selection.profile) and local.current_unit.state.world.profile_id == profile and _same(level.call("crystalman_approach_constructor"),selection) and _same(level.call("crystalman_source_rows"),_expected_rows(profile)),"full native Scheduler/world/profile and complete selected map join: "+profile): return false
	var parsed: Dictionary = Exact.parse(Exact.stringify(saved))
	if not _expect(parsed.get("accepted",false) and _same(parsed.value,saved),"whole actual new pair survives typed ExactJSON roundtrip: "+profile): return false
	var codec = ParentCodec.new()
	var derived: Dictionary = codec.constructor_selection(local)
	if not _expect(codec.last_error.is_empty() and _same(derived,selection),"pure saved constructor joins actual native new packet: "+profile,codec.last_error): return false
	# Deliberately mutate only defensive returned dictionaries and TEST future input.
	var returned: Dictionary = level.call("crystalman_approach_constructor")
	returned.profile.name = "external mutation"
	returned.policy.profile.windup_multiplier = 999.0
	var external_rows: Dictionary = level.call("crystalman_source_rows")
	external_rows["l5-plain-echo"].fixed_knot_world[0] = 99.0
	external_rows["l5-plain-echo"].own_route_world[0].position[0] = 99.0
	derived.policy.recipe_id = "external mutation"
	host.declared_profile = "standard" if profile != "standard" else "challenge"
	if not _expect(_same(level.call("crystalman_approach_constructor"),selection) and _same(level.call("crystalman_source_rows"),_expected_rows(profile)) and _same(saved,_pair(host)) and _same(codec.constructor_selection(local),selection),"defensive policy/profile/whole rows ignore external mutation and later TEST preference: "+profile): return false
	if profile == "challenge":
		_new_negatives(host,saved)
		if _failures != 0: return false
		var context: Dictionary = _camera_context(host)
		if not await _quiet_candidate(saved,context,ROOM,profile,"new-"+profile): return false
	_rows.append({"kind":"fresh-native-new","profile":profile,"parent_stage":0,"approach_stage":1,"clock_s":saved.player.world_actions.clock_s,"legacy":false,"whole_pair_exactjson":true,"native_quiet_roundtrip":profile == "challenge"})
	return await _close_host(host)

func _new_negatives(host: PreferenceMain,saved: Dictionary) -> void:
	var bad: Dictionary = saved.duplicate(true)
	bad.level.local.schema_version = true
	_packet_reject(host,bad,"Boolean parent version")
	bad = saved.duplicate(true); bad.level.local.schema_version = 1
	_packet_reject(host,bad,"new API with old schema")
	bad = saved.duplicate(true); bad.level.local.api_revision = "act3-crystalman-parent-local-1"
	_packet_reject(host,bad,"legacy API carrying a seventh policy key")
	bad = saved.duplicate(true); bad.level.local.erase("approach_policy")
	_packet_reject(host,bad,"new API missing its retained policy")
	bad = saved.duplicate(true); bad.level.local.approach_policy.recipe_id = "unknown"
	_packet_reject(host,bad,"unknown serialized arrangement recipe")
	bad = saved.duplicate(true); bad.level.local.approach_policy.profile = {"id":saved.level.local.approach_policy.profile.id}
	_packet_reject(host,bad,"ID-only saved Approach policy profile")
	bad = saved.duplicate(true); bad.level.local.current_unit.state.scheduler.profile = Difficulty.new().profile("challenge" if saved.level.local.approach_policy.profile.id != "challenge" else "standard")
	_packet_reject(host,bad,"saved full Scheduler profile differs from retained policy")
	bad = saved.duplicate(true); bad.level.local.current_unit.state.world.profile_id = "unknown"
	_packet_reject(host,bad,"child world profile differs from actual canonical Scheduler")
	bad = saved.duplicate(true); bad.level.local.world.layout_sha256 = "0".repeat(64)
	_packet_reject(host,bad,"immutable base-world hash differs")

func _packet_reject(host: PreferenceMain,bad: Dictionary,label: String) -> void:
	var before: Dictionary = _custody(host)
	var input: String = Exact.stringify(bad)
	var before_wire: String = Exact.stringify(before)
	var before_native: PackedByteArray = var_to_bytes(before)
	var input_native: PackedByteArray = var_to_bytes(bad)
	var error: String = host.active_level.snapshot_error_with_player(bad.level,bad.player)
	var after: Dictionary = _custody(host)
	var after_wire: String = Exact.stringify(after)
	var after_input: String = Exact.stringify(bad)
	var after_native: PackedByteArray = var_to_bytes(after)
	var branches: Dictionary = {}
	for key: Variant in before:
		var left: String = Exact.stringify(before[key])
		var right: String = Exact.stringify(after.get(key))
		branches[str(key)] = {"before_type":typeof(before[key]),"after_type":typeof(after.get(key)),"before_wire_nonempty":not left.is_empty(),"after_wire_nonempty":not right.is_empty(),"before_wire_bytes":left.to_utf8_buffer().size(),"after_wire_bytes":right.to_utf8_buffer().size(),"wire_equal":not left.is_empty() and left == right,"native_equal":var_to_bytes(before[key]) == var_to_bytes(after.get(key))}
	var differences: Array[Dictionary] = []
	_typed_differences(before,after,"custody",differences,[4096],0)
	var diagnostic: Dictionary = {"label":label,"error":error,"error_nonempty":not error.is_empty(),"input_before_nonempty":not input.is_empty(),"input_after_nonempty":not after_input.is_empty(),"input_wire_equal":input == after_input,"input_native_equal":input_native == var_to_bytes(bad),"before_wire_nonempty":not before_wire.is_empty(),"after_wire_nonempty":not after_wire.is_empty(),"before_wire_bytes":before_wire.to_utf8_buffer().size(),"after_wire_bytes":after_wire.to_utf8_buffer().size(),"custody_wire_equal":not before_wire.is_empty() and before_wire == after_wire,"before_native_bytes":before_native.size(),"after_native_bytes":after_native.size(),"before_native_sha256":_bytes_sha(before_native),"after_native_sha256":_bytes_sha(after_native),"native_equal":before_native == after_native,"branches":branches,"typed_differences":differences,"before_transport_shape":_transport_shape(before),"after_transport_shape":_transport_shape(after)}
	print("L5_CONSTRUCTOR_REJECTION_DIAGNOSTIC "+JSON.stringify(diagnostic))
	# Retain all original error/input/whole-custody conjuncts. The explicit
	# nonempty input witness strengthens the formerly implicit serializer guard.
	_expect(not error.is_empty() and not input.is_empty() and input == after_input and _same(before,after),label+" rejects with whole donor/IDs/input/optics/events unchanged",error)

func _key_type_witness() -> void:
	# Pure local dictionaries only. Record this engine's actual key kinds rather
	# than attributing format-01's missing operands to an assumed StringName rule.
	var dotted: Dictionary = {}
	dotted.child = "native-id-text"
	var indexed: Dictionary = {}
	indexed["child"] = "native-id-text"
	var dot_key: Variant = dotted.keys()[0]
	var bracket_key: Variant = indexed.keys()[0]
	print("L5_CONSTRUCTOR_KEY_TYPE_DIAGNOSTIC "+JSON.stringify({"dot_key_type":typeof(dot_key),"dot_key_is_string":dot_key is String,"dot_key_is_string_name":dot_key is StringName,"bracket_key_type":typeof(bracket_key),"bracket_key_is_string":bracket_key is String,"dot_exact_nonempty":not Exact.stringify(dotted).is_empty(),"bracket_exact_nonempty":not Exact.stringify(indexed).is_empty(),"dot_native_hex":var_to_bytes(dotted).hex_encode(),"bracket_native_hex":var_to_bytes(indexed).hex_encode(),"original_failed_fixture_sha256":"b0f35b186eae557994bd0dc112eeba45986950b1074f629ed672d0ff7aa931f8"}))

func _transport_shape(value: Variant) -> Dictionary:
	var result: Dictionary = {"nodes":0,"max_depth":0,"lower_bound_bytes":0,"unsupported":[]}
	_transport_walk(value,"root",0,result)
	result["exact_max_depth"] = Exact.MAX_DEPTH
	result["exact_max_nodes"] = Exact.MAX_NODES
	result["exact_max_bytes"] = Exact.MAX_BYTES
	return result

func _transport_walk(value: Variant,path: String,depth: int,result: Dictionary) -> void:
	if result.nodes >= Exact.MAX_NODES or depth > Exact.MAX_DEPTH+1: return
	result.nodes += 1
	result.max_depth = maxi(result.max_depth,depth)
	result.lower_bound_bytes += 8
	var kind: int = typeof(value)
	if value is Dictionary:
		for key: Variant in value:
			if not key is String and result.unsupported.size() < 24: result.unsupported.append({"path":path,"key":str(key),"key_type":typeof(key),"reason":"ExactJSON requires String dictionary keys"})
			result.lower_bound_bytes += str(key).to_utf8_buffer().size()+5
			_transport_walk(value[key],path+"/"+str(key),depth+1,result)
	elif value is Array:
		for index: int in range(value.size()): _transport_walk(value[index],path+"/"+str(index),depth+1,result)
	elif value is String:
		result.lower_bound_bytes += value.to_utf8_buffer().size()+5
	elif kind not in [TYPE_NIL,TYPE_BOOL,TYPE_INT,TYPE_FLOAT] and result.unsupported.size() < 24:
		result.unsupported.append({"path":path,"value_type":kind,"reason":"unsupported native Variant"})
	elif value is float and not is_finite(value) and result.unsupported.size() < 24:
		result.unsupported.append({"path":path,"value_type":kind,"reason":"nonfinite float"})

func _typed_differences(left: Variant,right: Variant,path: String,rows: Array[Dictionary],budget: Array[int],depth: int) -> void:
	if rows.size() >= 24 or budget[0] <= 0 or depth > 64: return
	budget[0] -= 1
	if typeof(left) != typeof(right):
		rows.append({"path":path,"before_type":typeof(left),"after_type":typeof(right),"reason":"native type differs"}); return
	if left is Dictionary:
		if var_to_bytes(left.keys()) != var_to_bytes(right.keys()): rows.append({"path":path,"reason":"key order/types differ (order alone is diagnostic)","before_keys":str(left.keys()),"after_keys":str(right.keys())})
		for key: Variant in left:
			if not right.has(key): rows.append({"path":path+"/"+str(key),"reason":"key absent after validation"})
			else: _typed_differences(left[key],right[key],path+"/"+str(key),rows,budget,depth+1)
		for key: Variant in right:
			if not left.has(key) and rows.size() < 24: rows.append({"path":path+"/"+str(key),"reason":"key added after validation"})
	elif left is Array:
		if left.size() != right.size(): rows.append({"path":path,"reason":"array size differs","before_size":left.size(),"after_size":right.size()})
		for index: int in range(mini(left.size(),right.size())): _typed_differences(left[index],right[index],path+"/"+str(index),rows,budget,depth+1)
	elif var_to_bytes(left) != var_to_bytes(right) and rows.size() < 24:
		rows.append({"path":path,"reason":"exact native scalar differs","before":str(left),"after":str(right),"before_hex":var_to_bytes(left).hex_encode(),"after_hex":var_to_bytes(right).hex_encode()})

static func _bytes_sha(bytes: PackedByteArray) -> String:
	var context := HashingContext.new()
	if context.start(HashingContext.HASH_SHA256) != OK or context.update(bytes) != OK: return ""
	return context.finish().hex_encode()

func _legacy_case() -> bool:
	if not _expect(FileAccess.get_sha256(ARCHIVE.path_join("manifest.json")) == MANIFEST_SHA,"literal known Standard archive manifest is externally pinned"): return false
	var manifest: Variant = JSON.parse_string(FileAccess.get_file_as_string(ARCHIVE.path_join("manifest.json")))
	if not _expect(manifest is Dictionary and Value.keys_error(manifest,["schema_version","kind","test_only","producer_fixture_sha256","clock_s","public_flow_validation","test_context","files","source_pins"]).is_empty() and manifest.schema_version is float and manifest.schema_version == 1.0 and manifest.kind is String and manifest.kind == "c50-genuine-warning-seed-1" and manifest.test_only is bool and manifest.test_only == true and manifest.producer_fixture_sha256 is String and manifest.producer_fixture_sha256 == "87921f24de57c5988c855b96858f5abd84b300746677570e08354a4c5ef5ced2" and manifest.clock_s is float and is_finite(manifest.clock_s) and manifest.clock_s >= 0.0 and manifest.public_flow_validation is String and manifest.public_flow_validation == "pending; actual native runner closure is authoritative" and manifest.test_context is String and manifest.source_pins is Dictionary and manifest.files is Dictionary and Value.keys_error(manifest.files,LEGACY_FILES.keys()).is_empty(),"original externally pinned plain-JSON TEST manifest retains its exact fields and native JSON types"): return false
	for name: String in LEGACY_FILES:
		var receipt: Variant = manifest.files[name]
		var expected: Dictionary = LEGACY_FILES[name]
		# Plain JSON numbers decode as native floats. This metadata comparison is
		# exact float(expected integer), NOT an ExactJSON/native-payload coercion.
		var valid: bool = receipt is Dictionary and Value.keys_error(receipt,["bytes","sha256"]).is_empty() and receipt.get("bytes") is float and is_finite(receipt.bytes) and receipt.bytes == float(expected.bytes) and receipt.get("sha256") is String and receipt.sha256 == expected.sha256
		print("L5_CONSTRUCTOR_MANIFEST_RECEIPT_DIAGNOSTIC "+JSON.stringify({"file":name,"receipt_bytes_type":typeof(receipt.get("bytes")) if receipt is Dictionary else TYPE_NIL,"expected_bytes_type":typeof(expected.bytes),"exact_expected_float":float(expected.bytes),"actual_bytes":receipt.get("bytes") if receipt is Dictionary else null,"valid":valid}))
		if not _expect(valid,"original raw manifest receipt has exact native JSON float bytes and String SHA: "+name): return false
	var values: Dictionary = {}
	for name: String in LEGACY_FILES:
		var f: FileAccess = FileAccess.open(ARCHIVE.path_join(name),FileAccess.READ)
		if not _expect(f != null,"original archive member exists: "+name): return false
		var valid_size: bool = f.get_length() == LEGACY_FILES[name].bytes
		var text: String = f.get_as_text(); f.close()
		var decoded: Dictionary = Exact.parse(text)
		if not _expect(valid_size and text.sha256_text() == LEGACY_FILES[name].sha256 and decoded.get("accepted",false) and decoded.value is Dictionary,"original physical/native archive member is exact: "+name): return false
		values[name] = decoded.value
	var seed: Dictionary = values["seed.native.json"]
	var session: Dictionary = values["session.native.json"]
	var local: Dictionary = seed.level.local
	if not _expect(seed.paused and seed.shell.difficulty_at_entry == "standard" and _same(session.story.snapshot,seed) and _same(session.story.checkpoint,seed) and session.completed_main.size() == 14 and local.size() == 6 and not local.has("approach_policy") and local.api_revision == "act3-crystalman-parent-local-1" and local.schema_version == 1 and local.route.stage == 1 and local.current_unit.state.stage == 2 and local.current_unit.state.world.profile_id == "standard" and seed.level.progress.checkpoint_id == "crystalman-plain-entry","genuine legacy Standard warning/checkpoint retains literal six-key original format; TEST prefix is not earned campaign authority"): return false
	var codec = ParentCodec.new()
	var selected: Dictionary = codec.constructor_selection(local)
	if not _expect(not selected.is_empty() and selected.legacy == true and selected.policy.is_empty() and _same(selected.profile,Difficulty.new().profile("standard")),"legacy constructor reads genuine old full profile without promoting its writer",codec.last_error): return false
	# The old source hashes are immutable provenance. Current changed Parent/Codec/
	# Approach are intentionally NOT compared to the old writer's source hashes.
	_rows.append({"kind":"legacy-archive-format","manifest_sha256":MANIFEST_SHA,"profile":"standard","parent_stage":1,"approach_stage":2,"clock_s":seed.player.world_actions.clock_s,"raw_store":false,"scope":"four original native files; no oldChallenge/captured-phase/lateMAIN provenance"})
	return true

func _quiet_candidate(saved: Dictionary,context: Dictionary,scene: String,profile: String,label: String) -> bool:
	var donor: Dictionary = _all_host_custody()
	var receiver: PreferenceMain = PreferenceMain.new()
	receiver.declared_profile = "standard" if profile != "standard" else "challenge"
	receiver.level_scene_path = scene
	_add_host(receiver)
	paused = true # Main's ordinary fresh preview resumes synchronously; no yield.
	var preview: CinderLevel = receiver.active_level
	preview.exit_level()
	receiver.world.remove_child(preview)
	preview.free()
	var packed: PackedScene = load(scene) as PackedScene
	var candidate: CinderLevel = packed.instantiate() as CinderLevel
	receiver.world.add_child(candidate)
	receiver.active_level = candidate # This receiver's OWN raw recipient, no donor alias.
	var floor: CollisionShape3D = candidate.get("floor_collision") as CollisionShape3D
	if not _expect(floor != null and floor.shape is BoxShape3D and candidate.contract_error().is_empty(),"fresh raw recipient retains actual authored native floor",candidate.contract_error()): return false
	var registration_before: PackedByteArray = var_to_bytes([receiver.player.snapshot_state(),receiver.get_input_observation_state(),floor.global_transform,(floor.shape as BoxShape3D).size,floor.disabled])
	await process_frame
	var registration_after: PackedByteArray = var_to_bytes([receiver.player.snapshot_state(),receiver.get_input_observation_state(),floor.global_transform,(floor.shape as BoxShape3D).size,floor.disabled])
	var start_events: int = _events.size()
	var ok: bool = _expect(paused and registration_before == registration_after and receiver.player.get_world_3d() != (_hosts[0].get("player") as CinderPlayer).get_world_3d(),"fresh raw recipient floor registers paused without Player/input/native mutation: "+label)
	if ok: ok = _expect(candidate.enter_restore_candidate(receiver.player,receiver.fx,receiver,saved.level,saved.player),"fresh raw parent selects saved constructor before child ready: "+label,candidate.last_snapshot_error)
	if ok:
		var observed: Dictionary = _pre_ready.get(str(candidate.get_instance_id()),{})
		var selected: Dictionary = ParentCodec.new().constructor_selection(saved.level.local)
		ok = _expect(not observed.is_empty() and observed.child_not_ready and _same(observed.selection,selected) and _same(observed.rows,_expected_rows(profile)),"saved full profile and whole selected map precede fresh recipient Approach ready: "+label)
	if ok: ok = _expect(candidate.snapshot_error_with_player(saved.level,saved.player).is_empty() and receiver.player.restore_state(saved.player) and candidate.restore_state(saved.level),"actual Player then full native parent quiet restore: "+label,candidate.last_snapshot_error)
	if ok:
		# Literal saved native optical context, not a future fit, donor alias or
		# source/actor mutation. Candidate owns this actual Camera and canonical HUD.
		receiver.camera.global_transform = context.transform
		receiver.hud.update_status(receiver.player.hp,receiver.player.max_hp,receiver.player.shells,receiver.player.max_shells,0,candidate.objective_text)
		await process_frame
		var optical: String = candidate.restore_candidate_presentation_error(receiver.camera,receiver.hud)
		ok = _expect(optical.is_empty() and paused and _events.size() == start_events and _same(receiver.player.snapshot_state(),saved.player),"actual candidate Camera/HUD and all gameplay signals remain quiet: "+label,optical)
		if ok: ok = _expect(candidate.finish_restore_candidate() and _same(_pair(receiver),saved),"whole exact new policy/native pair recaptures with opposite TEST future preference: "+label,candidate.last_snapshot_error)
	var close_ok: bool = await _close_host(receiver)
	return _expect(_same(donor,_all_host_custody()),"candidate construction/restore/cleanup preserves installed donor pair/IDs/input/optics/events: "+label) and ok and close_ok

func _expected_rows(profile: String) -> Dictionary:
	var raw: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(Parent.LayoutPath))
	var result: Dictionary = {}
	for original: Dictionary in raw.sources:
		var row: Dictionary = original.duplicate(true)
		if row.kind == "echo":
			row["source_epoch_recipe"] = row.source_epoch
			row["definition_id"] = row.id+"/straight-return"
			row["definition_translation_world"] = row.fixed_knot_world.duplicate()
			row["slash_origin_world"] = row.fixed_knot_world.duplicate()
		if profile == "challenge" and row.id == "l5-plain-echo":
			for point: Dictionary in row.own_route_world:
				var position: Vector3 = Value.read_vector3(point.position)
				position.x = -3.0
				point.position = Value.vector3(position)
			for key: String in ["fixed_knot_world","definition_translation_world","slash_origin_world"]:
				var position: Vector3 = Value.read_vector3(row[key])
				position.x = -3.0
				row[key] = Value.vector3(position)
		result[row.id] = row
	return result

func _pair(host: Node) -> Dictionary:
	var level: CinderLevel = host.get("active_level") as CinderLevel
	var player: CinderPlayer = host.get("player") as CinderPlayer
	return {"player":player.snapshot_state(),"level":level.snapshot_state_for_presentation(host.get("camera"),host.get("hud"))}

func _camera_context(host: Node) -> Dictionary:
	var camera: Camera3D = host.get("camera") as Camera3D
	return {"transform":camera.global_transform}

func _add_host(host: Node) -> void:
	# Main also owns its normal inner world viewport. A separate OUTER native
	# viewport gives each canonical HUD its own actual 340x736 context as well.
	var view := SubViewport.new()
	view.size = Vector2i(340,736)
	view.own_world_3d = true
	view.render_target_update_mode = SubViewport.UPDATE_DISABLED
	root.add_child(view)
	_viewports[str(host.get_instance_id())] = view
	_hosts.append(host)
	view.add_child(host)

func _custody(host: Node) -> Dictionary:
	var level: CinderLevel = host.get("active_level") as CinderLevel
	var child: Node = level.get("current_unit") as Node
	var ids: Dictionary = {"main":str(host.get_instance_id()),"parent":str(level.get_instance_id()),"hero":str((host.get("player") as Node).get_instance_id()),"world":str(level.get_world_3d().get_instance_id()),"floor":str((level.get("floor_collision") as Node).get_instance_id()),"camera":str((host.get("camera") as Node).get_instance_id()),"hud":str((host.get("hud") as Node).get_instance_id())}
	if is_instance_valid(child):
		ids["child"] = str(child.get_instance_id())
		ids["scheduler"] = str((child.get("threat_scheduler") as Node).get_instance_id())
		for id: String in child.get("sources"): ids[id] = str((child.get("sources")[id] as Node).get_instance_id())
	var camera: Camera3D = host.get("camera") as Camera3D
	var hud: GameHUD = host.get("hud") as GameHUD
	var safe: Rect2 = hud.combat_safe_rect()
	return {"pair":_pair(host),"ids":ids,"input":var_to_bytes(host.call("get_input_observation_state")).hex_encode(),"camera":var_to_bytes([camera.global_transform,camera.size,camera.keep_aspect,camera.projection,camera.get_viewport().size]).hex_encode(),"hud_safe":[safe.position.x,safe.position.y,safe.size.x,safe.size.y],"event_count":_events.size()}

func _all_host_custody() -> Dictionary:
	var result: Dictionary = {}
	for host: Node in _hosts:
		if is_instance_valid(host): result[str(host.get_instance_id())] = _custody(host)
	return result

func _observe_added(node: Node) -> void:
	var owner: Node = node.get_parent()
	if node.get_script() == Parent.Approach and is_instance_valid(owner) and owner.has_method("crystalman_approach_constructor"):
		_pre_ready[str(owner.get_instance_id())] = {"child_not_ready":not node.is_node_ready(),"selection":owner.call("crystalman_approach_constructor"),"rows":owner.call("crystalman_source_rows")}
	for row: Dictionary in node.get_signal_list():
		if row.name in ["fired","died","action_resolved","world_action_executed","checkpoint_requested","completion_requested","contact_exit_requested","tether_severed","recording_joined","event_dispatched","hit_resolved"]:
			var callback: Callable = Callable(self,"_event"+str(row.args.size())).bind(str(node.get_instance_id()),String(row.name))
			if callback.is_valid(): node.connect(row.name,callback)

func _event0(owner: String,kind: String) -> void: _events.append({"owner":owner,"kind":kind})
func _event1(_a: Variant,owner: String,kind: String) -> void: _event0(owner,kind)
func _event2(_a: Variant,_b: Variant,owner: String,kind: String) -> void: _event0(owner,kind)
func _event3(_a: Variant,_b: Variant,_c: Variant,owner: String,kind: String) -> void: _event0(owner,kind)
func _event4(_a: Variant,_b: Variant,_c: Variant,_d: Variant,owner: String,kind: String) -> void: _event0(owner,kind)

func _close_host(host: Node) -> bool:
	paused = true
	if not is_instance_valid(host): return true
	var level: CinderLevel = host.get("active_level") as CinderLevel
	if is_instance_valid(level): level.exit_level()
	var refs: Array[WeakRef] = []
	var id: String = str(host.get_instance_id())
	var view: SubViewport = _viewports.get(id) as SubViewport
	_collect_refs(view if is_instance_valid(view) else host,refs)
	_hosts.erase(host)
	_viewports.erase(id)
	if is_instance_valid(view): view.queue_free()
	else: host.queue_free()
	for _frame: int in range(3): await process_frame
	return _expect(refs.all(func(ref: WeakRef) -> bool: return ref.get_ref() == null),"normal whole Main/Player/floor/source/cue cleanup releases native recipients")

func _collect_refs(node: Node,refs: Array[WeakRef]) -> void:
	refs.append(weakref(node))
	for child: Node in node.get_children(): _collect_refs(child,refs)

func _watchdog() -> void:
	if _finishing: return
	_expect(false,"600s host watchdog; no extra native/route credit")
	await _finish()

func _finish() -> void:
	if _finishing: return
	_finishing = true
	for host: Node in _hosts.duplicate(): await _close_host(host)
	var expected_rows: int = 1 if _legacy_only else 4
	print("L5_CONSTRUCTOR_RESULT "+JSON.stringify({"selector":"--legacy-only" if _legacy_only else "default","executed_scope":"legacy archive physical hashes/native format/pure constructor only" if _legacy_only else "three fresh profiles/changed negatives/one new native quiet restore/legacy format","checks":_checks,"failures":_failures,"cases":_rows,"expected_cases":expected_rows,"scope_complete":_failures == 0 and _rows.size() == expected_rows,"native_route_or_comparison_credit":false,"legacy_scope":"known four-file Standard warning only; format/preflight, no raw Store/new oldwriter/native legacy re-execution","untested":"later native capture/coda checkpoints, oldChallenge, public newMAINtransport, comparison/novelty/portrait; legacy-only does not rerun any new native portion"}))
	quit(0 if _failures == 0 else 1)

func _expect(ok: bool,label: String,detail: String = "") -> bool:
	_checks += 1
	print(("PASS " if ok else "FAIL ")+str(_checks)+" "+label+(": "+detail if not detail.is_empty() else ""))
	if not ok: _failures += 1
	return ok

static func _same(left: Variant,right: Variant) -> bool:
	var wire: String = Exact.stringify(left)
	return not wire.is_empty() and wire == Exact.stringify(right)
