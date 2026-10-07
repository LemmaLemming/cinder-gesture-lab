---
name: game-design-mechanics
description: Refine video game mechanics, learning curves, and progression into clear player decisions and small, testable prototypes. Use for game concepts, combat loops, unlock pacing, and rewards across repeated runs.
---

# Game Design Mechanics

Turn a game idea into rules players can understand, choices with consequences, and a prototype that can test the intended experience. Keep the user's platform, controls, perspective, and requested scope intact.

## Establish the loop

Identify the repeated decision: what the player sees, chooses, risks, and gains. Describe one playable cycle as **input → action → consequence → feedback → next decision**. If a mechanic has no consequence or changes no decision, question whether it belongs in the current prototype.

For controls, specify the coordinate origin, when an action commits, which state it reads, and how competing gestures resolve. Distinguish a swipe's threshold crossing from its final release; distinguish a first tap's immediate action from the second tap's follow-up. Describe zero-direction and reset behavior when relevant. Test the user's concrete example before adding assistance that changes their intended input.

Preserve specified action sequences literally. For example, “a tap slashes; the second tap adds a blast” describes one slash followed by one blast, unless the user also requests another slash. Label unspecified timing or fallback behavior as a proposal; retain existing behavior when refining an established implementation.

Compare weapons or abilities by the decisions they create: range, commitment, recovery, resource cost, positioning, and payoff. Similar reach can still support different roles. Tune variables together when one removes another's purpose; avoid recommending numerical upgrades before the base interaction is readable.

## Separate kinds of progress

Keep three states explicit:

- **Player mastery:** knowledge, timing, recognition, and execution retained by the human.
- **Attempt state:** power, resources, route, and consequences within the current session or run.
- **Persistent state:** abilities, options, information, access, or power retained across attempts.

When designing learning or persistent rewards, read [the two video summaries](references/progression-videos.md). They provide examples and tradeoffs, not universal prescriptions. Use only the parts that fit the brief.

Make a learning sequence from situations: introduce a rule in a readable encounter, let the player apply it, then combine or pressure it. Name the skill each encounter tests. Pause or recap where it helps the player perceive improvement. Unlock timing should have a purpose, such as limiting overload or opening a new choice.

For persistent rewards, specify the earning action, purchase or unlock, timing, benefit, what survives failure, and what the player sacrifices now. Check which behavior earns the fastest progress: the intended play, safe repetition, deliberate failure, or waiting. Treat a suspected exploit as a tuning question to test, not a reason to add an elaborate economy.

Ask what would improve on a repeat attempt with identical character stats. If only accumulated power produces improvement, decide whether that matches the intended experience. Prefer new tactical options when diversity is the goal; use power growth when that is the chosen promise. Neither is mandatory.

## Propose the smallest useful test

For a mechanics-only request, use a short arena or encounter before proposing a campaign, hub, skill tree, or loot economy. Keep future progression ideas clearly separate from authorized implementation.

Express each uncertain design choice as a hypothesis with observable evidence. For example: “After one demonstration, players can predict the next attack direction without trial-and-error taps.” Observe input mistakes separately from positioning or timing mistakes. Measure learning, repeated choices, and the reason for failure; completion alone cannot distinguish mastery from a stat advantage.

Return the concrete rules, the main tradeoff, and a bounded test appropriate to the task. Mark suggested tuning values as provisional. If implementing, verify the relevant gesture and gameplay behavior, and distinguish desktop simulation from real mobile-device validation.
