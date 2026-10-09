# Idle menu application notifications

Shared37 checks for a valid installed `active_level` before application-paused or application-focus-out notifications enqueue the existing Shell pause request. Title, Journey and Settings have no simulation to pause. A living or dead installed level follows the same input consumption, native pause barrier, live capture, protected checkpoint and persistence flow as before. Preview delegation and window-close handling are unchanged. There is no new public API, save schema or actor behavior.

The focused selector is `--focus-notifications-only` on `tests/campaign_shell_smoke.gd`, submitted through the canonical `python3 scripts/dev/dev.py engine` queue. The test calls both actual native Node notification paths on each of the three idle pages and checks the immediate queue and drained page. It compares Attempts, settings, Shell state, store generation, isolated disk bytes and input state. Two real living fixture worlds retain injured Player/enemy state and a spent supply through pause and disk capture. Real Viewport touch events verify held input is consumed and a later release does not become an attack. A real enemy strike supplies the fatal case; dead Resume retains its original Retry message and resources. The default test flow reconstructs byte for byte from Shared36 after removing only the added selector/constants/helpers.

Three separate original scopes are retained in [the portable archive](evidence/shared37-idle-menu-notifications/index.json):

| Scope | Result | Qualification |
| --- | --- | --- |
| Original focused reproduction, unchanged Shared36 Shell | 53 checks, 18 failures; exit 1 | Idle notifications enqueue pause and change the page. Some later failures cascade from the first page change. A receipt mismatch alone does not prove disk or Attempts corruption. Living and fatal controls pass. |
| Same focused fixture, active-level guard | 53 checks, 0 failures; exit 0 | No Script, Parse, ERROR or WARNING diagnostics. |
| Directly affected default Shell fixture | 52 checks, 0 failures; exit 0 | Original default flow, no selector; no Script, Parse, ERROR or WARNING diagnostics. |

Each job froze 92 source/resource files before submission and verified them again at closure. All three dynamically selected campaign fixture scenes were explicit seeds. The manifests also retain the actual registry, project entry, local engine configuration and job driver. These are bounded explicit/literal subsets, not complete Godot import or global-class dependency graphs. Their five missing literal references are comment/example placeholders, capture directories and the dynamic scene prefix; the actual three scene files are retained. Later archive and documentation generation does not widen the original execution scope.

The tests use synthetic native application notifications and real test-only fixture actors. They do not establish actual macOS focus behavior, the cause of Act2's historical Title failure, the cause of Act3's isolated Game portrait pause, authored-level acceptance, portrait readability or performance. Only this changed behavior and its directly affected default fixture were rerun. Existing UID bytes are unchanged; no import or remint was needed.
