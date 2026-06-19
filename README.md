# TestKit

A speckit-style toolkit for **integration testing** a feature spec. Like speckit,
TestKit ships as **Copilot CLI agent files** (`.github/agents/*.agent.md`) — the
same artifact speckit installs for the CLI. Each stage is a `/`-invokable agent;
the orchestrator delegates to them in sequence, with **files as the contract**
between stages. The artifacts, not conversation memory, carry
state forward — which keeps each run deterministic across different specs.

## Pipeline

```
/testkit.scenarios  →  <spec>/test_cases.csv        analyze spec → terse scenarios
        │
/testkit.clarify    →  <spec>/test-memory.md         INTERACTIVE: how a human runs each test
        │
/testkit.discover   →  <spec>/tools-report.md         validate tools (scoped!) + write .ps1 per step
        │              <spec>/scripts/*.ps1
        │
/testkit.run        →  <spec>/test-results.md         execute, judge against oracles
```

`/testkit.orchestrate` drives all four and verifies each artifact before the next
stage.

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
4. **The pipeline is sequential.** Parallelism lives *within* Discovery (probe
   tools) and Run (independent scenarios) — not across stages.
5. **Scripts mirror manual steps 1:1.** One `.ps1` per manual action, runnable
   standalone, no cleverness.

## Layout

```
.github/agents/          the four stage agents + orchestrator (Copilot CLI agent files)
.testkit/templates/      artifact templates (the contract)
.testkit/scripts/powershell/  _template.ps1 for per-step scripts
```

## Roles at a glance

| Command | Owns | Interactive | Produces |
|---------|------|-------------|----------|
| scenarios | what to test | no | test_cases.csv |
| clarify | intent / oracles | **yes** | test-memory.md |
| discover | capability / scripts | no | tools-report.md, scripts/*.ps1 |
| run | execution | no | test-results.md |
| orchestrate | sequencing | only via clarify | — |
