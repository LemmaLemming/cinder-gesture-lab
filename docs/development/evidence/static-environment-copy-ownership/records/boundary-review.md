# Independent source-boundary review

Reviewer: `/root/runtime_cost_reduction/runtime_guard_boundary_review`, bounded source inspection only. No engine, timing, production edits or bank census.

The reviewer confirmed fresh collider lists, row dictionaries and shape rows at Route516/532/543–548, fresh `_shape_data` dictionaries and point arrays at615–634, fresh `_transform` / Codec vector arrays at637–638/23–24, and fresh floor rows flattening Rect2 at401/433. Native floor handles occur only in `regions`, excluded from the returned signature. The ProjectSettings engine field at552 is the sole foreign nested container origin found.

The review requires any foreign-container detachment to remain after successful `_floor_plan`, at the existing return boundary, using the already sampled value. The proposed selector preserves the literal original full-copy return for that Array/Dictionary case and transfers only the otherwise fresh trees. It never performs another getter/validation. Runtime equivalence is untested.

Separately, the reviewer found no safe removal of repeated native validation: `_binding_error` invokes bindings/response/Scheduler callbacks; response/control/profile checks surround actual callbacks; codec checks surround independent decoder callbacks; the final native-boundary check follows virtual Protocol accessors. Prior success cannot authorize skipping them.

Final exact-hunk follow-up: the same reviewer inspected patch `818f807f78a5f9966ece664165faa7fcc6b2d084bc62a123ac7eed6481b37e5e` and confirmed that the Array/Dictionary branch retains literal original full-copy behavior, while the scalar branch returns fresh unexposed trees. The selector follows successful floor validation and reads only the sampled local value; no concrete source issue was found. This was patch inspection only, with no edits or engine checks.
