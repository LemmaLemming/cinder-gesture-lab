# Live equipment grid

Derived from the canonical catalogue, creation claims and ability introductions.
Benefits and costs below summarize provisional definitions; read the full JSON/specification for every condition.
Structural screening does not prove novelty or balance. Completion means catalogue integration.

| ID | Kind / slot | Name | Benefit / trigger | Risk / cost | Catalogue status | Creation ownership | Ability introductions |
| --- | --- | --- | --- | --- | --- | --- | --- |
| CLOTH-J0 | clothing / jacket | Standard Jacket | neutral | none | implemented_prototype_unplaytested | reuse existing | none recorded |
| CLOTH-J1 | clothing / jacket | Padded Jacket | armour +20%, attack speed -5% | slower attack recovery | implemented_prototype_unplaytested | reuse existing | none recorded |
| CLOTH-J2 | clothing / jacket | Duelist Jacket | damage +10%, max health -10% | less health capacity | implemented_prototype_unplaytested | reuse existing | none recorded |
| CLOTH-J3 | clothing / jacket | Frayed Jacket | max health -10%; Last Thread (PERK-02) | less health; remaining injured is dangerous | proposed_unplaytested | unclaimed shared work | none recorded |
| CLOTH-P0 | clothing / pants | Standard Pants | neutral | none | implemented_prototype_unplaytested | reuse existing | none recorded |
| CLOTH-P1 | clothing / pants | Reach Pants | attack range +5%, attack speed -5% | slower attack recovery | implemented_prototype_unplaytested | reuse existing | none recorded |
| CLOTH-P2 | clothing / pants | Cargo Pants | max health +10%, dash speed -5% | slower dash travel | implemented_prototype_unplaytested | reuse existing | none recorded |
| CLOTH-P3 | clothing / pants | Cadence Pants | damage -5%; Triple Cadence (PERK-01) | weaker first hits; misses or damage break sequence | proposed_unplaytested | unclaimed shared work | none recorded |
| CLOTH-S0 | clothing / shoes | Standard Shoes | neutral | none | implemented_prototype_unplaytested | reuse existing | none recorded |
| CLOTH-S1 | clothing / shoes | Burst Shoes | dash speed +10%, damage -5% | weaker attacks | implemented_prototype_unplaytested | reuse existing | none recorded |
| CLOTH-S2 | clothing / shoes | Longstep Shoes | dash distance +10%, dash speed -5% | slower travel and overshoot risk | implemented_prototype_unplaytested | reuse existing | none recorded |
| CLOTH-S3 | clothing / shoes | Armoured Stride Shoes | armour +5%, max health -10%; Armoured Stride (PERK-03) | less health; needs armour investment | proposed_unplaytested | unclaimed shared work | none recorded |
| WEAPON-01 | weapon / weapon | Balanced Edge | neutral | none | implemented_prototype_unplaytested | reuse existing | none recorded |
| WEAPON-02 | weapon / weapon | Quick Edge | damage -15%, attack speed +15%, attack range -5% | less damage per hit and shorter reach | implemented_prototype_unplaytested | reuse existing | none recorded |
| WEAPON-03 | weapon / weapon | Heavy Edge | damage +20%, attack speed -20%, attack range -10% | slower recovery and closer positioning | implemented_prototype_unplaytested | reuse existing | none recorded |
| WEAPON-04 | weapon / weapon | Long Edge | attack range +10%, attack speed -10%, damage -5% | slower and weaker hits | implemented_prototype_unplaytested | reuse existing | none recorded |
| PERK-01 | perk / equipped_perk | Triple Cadence | primary hit (3 landed actions; gap ≤1.2s) → damage +30% / third primary action | damage -5%; resets on primary miss, damage taken, gap timeout, weapon replacement, encounter end | proposed_unplaytested | unclaimed shared work | none recorded |
| PERK-02 | perk / equipped_perk | Last Thread | attack begin (health below 60%) → up to damage +20% / primary and followup | max health -10% | proposed_unplaytested | unclaimed shared work | none recorded |
| PERK-03 | perk / equipped_perk | Armoured Stride | dash begin (reads static gear snapshot) → up to dash speed +12% | max health -10% | proposed_unplaytested | unclaimed shared work | none recorded |
| PERK-04 | perk / equipped_perk | Counterstep | completed dash (dash begins inside locked threat footprint and ends outside before activation without taking its hit) → damage +15% / next primary action | damage -5%; expires after 1s; cooldown 3s; consumed on primary action begin | proposed_unplaytested | unclaimed shared work | none recorded |
| PERK-05 | perk / equipped_perk | Settled Reach | stationary after dash (still for 0.35s) → attack range +12% / next primary action | attack speed -5%; expires after 1s; consumed on primary action begin; resets on dash begin, damage taken | proposed_unplaytested | unclaimed shared work | none recorded |
| PERK-06 | perk / equipped_perk | Sweep Economy | primary hit (≥3 living enemies) → reload credit s +0.2s | damage -5%; cooldown 1.5s | proposed_unplaytested | unclaimed shared work | none recorded |
| PERK-07 | perk / equipped_perk | Empty Chamber | primary hit (0 starting shells) → reload credit s +0.15s | damage -5%; cooldown 1.15s | proposed_unplaytested | unclaimed shared work | none recorded |
| PERK-08 | perk / equipped_perk | Backtrack | completed dash (gap ≤1s; direction dot max -0.85) → knockback +12% / next primary action | dash speed -5%; expires after 0.6s; cooldown 2s; consumed on primary action begin | proposed_unplaytested | unclaimed shared work | none recorded |
| PERK-09 | perk / equipped_perk | Followthrough | followup hit (same target as immediately preceding primary; gap ≤0.28s) → knockback +10% / qualifying target | attack range -5% | proposed_unplaytested | unclaimed shared work | none recorded |
| PERK-10 | perk / equipped_perk | Recovery Seam | primary hit (target state explicit recovery) → damage +10% / qualifying target | damage -5%; cooldown 2s | proposed_unplaytested | unclaimed shared work | none recorded |
| PERK-11 | perk / equipped_perk | Reserve Stitch | damage taken (cross health below 40%) → armour +15% / future hits | max health -10%; expires after 2s; 1 use/encounter | proposed_unplaytested | unclaimed shared work | none recorded |
| PERK-12 | perk / equipped_perk | Release Valve | primary miss → dash speed +10% / next dash | damage -5%; expires after 0.6s; cooldown 4s; consumed on dash begin | proposed_unplaytested | unclaimed shared work | none recorded |
| PERK-13 | perk / equipped_perk | Precision Feed | primary hit (=1 living enemies) → reload credit s +0.1s | attack range -5%; cooldown 0.6s | proposed_unplaytested | unclaimed shared work | none recorded |
| PERK-14 | perk / equipped_perk | First Opening | primary hit (target has taken no prior direct player hit this encounter) → damage +15% / qualifying target | attack speed -5% | proposed_unplaytested | unclaimed shared work | none recorded |
| POWER-01 | powerup / mobility | Fleet Spark | dash speed +15%; 12 simulation seconds | expires on encounter end, death; replace same group | proposed_unplaytested | unclaimed shared work | none recorded |
| POWER-02 | powerup / mobility | Long Arc | dash distance +15%; 12 simulation seconds | expires on encounter end, death; replace same group | proposed_unplaytested | unclaimed shared work | none recorded |
| POWER-03 | powerup / combat | Keen Spark | damage +15%; 10 simulation seconds | expires on encounter end, death; replace same group | proposed_unplaytested | unclaimed shared work | none recorded |
| POWER-04 | powerup / combat | Quick Spark | attack speed +15%; 10 simulation seconds | expires on encounter end, death; replace same group | proposed_unplaytested | unclaimed shared work | none recorded |
| POWER-05 | powerup / combat | Guard Spark | armour +15%; 10 simulation seconds | expires on encounter end, death; replace same group | proposed_unplaytested | unclaimed shared work | none recorded |
| POWER-06 | powerup / combat | Orbit Cut | primary 360 degrees; 3 charges | primary: damage -20%; expires on encounter end, death; replace same group | proposed_unplaytested | unclaimed shared work | none recorded |
