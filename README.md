# TestKit

A speckit-style toolkit for **integration testing** a feature spec. Like speckit,
TestKit ships as **Copilot CLI agent files** (`.github/agents/*.agent.md`) — the
same artifact speckit installs for the CLI. Each stage is a `/`-invokable agent;
the stages chain through declared **handoffs** (not a controller), with **files as
the contract** between them. The artifacts, not conversation memory, carry state
forward — which keeps each run deterministic across different specs.

## Entry point

The workflow starts by invoking the first stage directly:

```
/testkit.scenarios <spec-dir>
```

`/testkit` is an optional **front door** that explains the flow and hands off to
`scenarios` — a discoverability entry, not an orchestrator. Like speckit, there is
no controller agent; the pipeline is the handoff chain.

## Pipeline (advances via handoffs)

```
/testkit.scenarios  →  <spec>/test_cases.csv        analyze spec → terse scenarios
        │  handoff: Clarify Manual Test Procedure
/testkit.clarify    →  <spec>/test-memory.md         INTERACTIVE: how a human runs each test
        │  handoff: Discover Tools & Generate Scripts
/testkit.discover   →  <spec>/tools-report.md         validate tools (scoped!) + write .ps1 per step
        │  <spec>/scripts/*.ps1
        │  handoff: Run Test Scenarios  (not auto-sent; BLOCKED scenarios stop here)
/testkit.run        →  <spec>/test-results.md         execute, judge against oracles
```

## Design rules (these exist to prevent known failure modes)

1. **Files are the contract.** Each command reads the prior file and writes the
   next. Behavior cannot silently diverge between two specs because the schema is
   fixed even when content differs.
2. **Tool needs derive from scenarios, never from conversation.** `tools_required`
   in `test-memory.md` lists only tools a scenario actually invokes, and Discovery
   validates *exactly* that union. This is the fix for "got stuck running tools
   that weren't even needed."
3. **Only one stage talks to the user.** Clarify owns *intent*; Discovery owns
   *capability* and is non-interactive. A question from Discovery or Run is a
   defect to report upstream, not a prompt to the user.
4. **Sequencing is owned by handoff edges, not a controller.** Each agent declares
   its downstream `handoffs:` — one source of truth. There is no orchestrator to
   drift from. Parallelism lives *within* Discovery (probe tools) and Run
   (independent scenarios), never across stages.
5. **Scripts mirror manual steps 1:1.** One `.ps1` per manual action, runnable
   standalone, no cleverness.

## Layout

```
.github/agents/          testkit (front door) + four stage agents (Copilot CLI agent files)
.testkit/templates/      artifact templates (the contract)
.testkit/scripts/powershell/  _template.ps1 for per-step scripts
```

## Roles at a glance

| Agent | Owns | Interactive | Produces | Hands off to |
|-------|------|-------------|----------|--------------|
| testkit | front door | only to ask for spec dir | — | scenarios |
| scenarios | what to test | no | test_cases.csv | clarify |
| clarify | intent / oracles | **yes** | test-memory.md | discover |
| discover | capability / scripts | no | tools-report.md, scripts/*.ps1 | run (gated) |
| run | execution | no | test-results.md | — (terminal) |
