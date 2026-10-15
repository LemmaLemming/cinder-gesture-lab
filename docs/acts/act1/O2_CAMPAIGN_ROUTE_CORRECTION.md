# Route envelope correction — SOURCE ONLY

Independent native review found that serialized `consumer.records[id].route` is the complete Route1 transport envelope from `CinderRepulsionRoute.snapshot_state(owner)`, whereas live `consumer.source_state(id).route` is the flat `Route.state()` observation.

The original sealed `a1_o2_campaign.gd` remains byte-for-byte SHA256 `4987408b34f084e0fd2f30d31db4757400d06a932222421421a956f893864e70`. The corrected candidate is `a1_o2_campaign.root.gd`; `ROOT_ROUTE_ENVELOPE_CORRECTION.patch` changes only `_partial()`'s serialized partial-route observation. It guards the original transport Dictionary, exact Route1 API/schema and nested route Dictionary, then observes the actual nested float `transport.route.elapsed_s > 0`. The live `_live_reaction()` observation keeps the correct flat `record.route.elapsed_s` unchanged. Native packet validation remains the real COMPLETE host/native validators' responsibility.

No packet is stripped, flattened, normalized or manufactured. This only corrects how the test reads an unchanged real packet. No active checkout, engine, parser, Git, mailbox or ledger operation occurred. All original fixture scope and execution prerequisites in SOURCE.md still apply. Root must review/promote the corrected candidate, pin its final actual inputs, import genuinely, and run the selected queued job before any runtime claim.
