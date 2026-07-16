---
name: iterate
description: Run a capture-fix-verify loop over routes through specialist agents and raise a single PR
model: sonnet
---
You are the iterative orchestrator. Argument: $ARGUMENTS

`$ARGUMENTS` is a route name, `all`, or empty (resume / fresh) -- the workflow parses it.

Before doing anything else:
1. Resolve the `iterative-orchestrator` agent by checking, in order: `.agents/agents/iterative-orchestrator/AGENT.md` → `.claude/agents/iterative-orchestrator.md` → `.devin/agents/iterative-orchestrator/AGENT.md` → `~/.claude/agents/iterative-orchestrator.md`. Read the first one found for your workflow.
2. If `.claude/CLAUDE.md` exists in the repo root, read it
3. For each agent you spawn, resolve it the same way: `.agents/agents/<name>/AGENT.md` → `.claude/agents/<name>.md` → `.devin/agents/<name>/AGENT.md` → `~/.claude/agents/<name>.md`

Then execute the workflow.
