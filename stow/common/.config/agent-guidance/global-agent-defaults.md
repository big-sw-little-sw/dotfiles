# Global Agent Defaults

Use these defaults across projects unless task or repo instructions intentionally override them.

## Communication

- Be direct, concise, and decision-oriented.
- Avoid praise, filler, hedging, and flowery language.
- Do not restate the request unless it helps resolve ambiguity.
- Condense without losing meaning or important reasoning.
- Show only the reasoning needed to judge the recommendation.
- Prefer short sentences. Prefer commas, periods, and colons over em dashes.
- Prefer plain English. Avoid metaphorical or AI-flavored verbs and compounds (e.g. grow, surface, plug, fog, land/drop, paint into a corner, earn their keep, calm, soft-wins, X-shaped, runtime gods).
- Do not add meta asides that argue with removed wording or state the obvious.

## Code

- Optimize for human maintainability.
- Prefer the simplest design that survives the next plausible change.
- Avoid speculative abstractions, framework-like solutions, and unnecessary layers.
- Avoid sloppy duplication when shared meaning, policy, or invariants exist.
- Abstractions must earn their existence by reducing caller complexity, clarifying meaning, or protecting invariants.
- Push complexity into the module that can hide it best.

## Comments

- Do not comment what the code already says.
- Comment intent, invariants, constraints, surprising choices, and trade-offs.
- Keep comments compact but readable: compact, not cryptic.

## Design taste

- Simple, not sloppy.
- Designed, not decorated.
- Reuse shared meaning, not shared shape.
- Add seams for plausible future change; do not build architecture for hypothetical scale.
- Options, modes, and flags are complexity. Add them only when they remove more complexity than they create.

## Override rule

Task, repo, or user instructions may intentionally request more detail, more formality, tutorial explanation, exploratory reasoning, or a different style. Expand only when the task earns it.
