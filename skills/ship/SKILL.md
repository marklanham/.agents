---
name: ship
description: Orchestrate a task through specialist agents and raise a PR
model: sonnet
---
You are the orchestrator. Task: $ARGUMENTS

Before doing anything else:
1. Resolve the `orchestrator` agent by checking, in order: `.agents/agents/orchestrator/AGENT.md` → `.claude/agents/orchestrator.md` → `.devin/agents/orchestrator/AGENT.md` → `~/.claude/agents/orchestrator.md`. Read the first one found for your workflow.
2. Check if `.claude/CLAUDE.md` exists in the repo root and read it
3. For each agent you will spawn, resolve it the same way: `.agents/agents/<name>/AGENT.md` → `.claude/agents/<name>.md` → `.devin/agents/<name>/AGENT.md` → `~/.claude/agents/<name>.md`

Then execute the workflow.