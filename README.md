# TestKit

A speckit-style toolkit for **integration testing** a feature spec. Like speckit,
TestKit ships as **Copilot CLI agent files** (`.github/agents/*.agent.md`) — the
same artifact speckit installs for the CLI. Each stage is a `/`-invokable agent;
the stages chain through declared **handoffs** (not a controller), with **files as
the contract** between them. The artifacts, not conversation memory, carry state
forward — which keeps each run deterministic across different specs.

## Install into a project

TestKit is just files Copilot CLI reads, so installing means copying the agents
and the `.testkit/` scaffold into your project root.

**Remote (no clone):**

```powershell
# PowerShell
irm https://raw.githubusercontent.com/drandx/testkit/main/install.ps1 | iex
```

```bash
# bash
curl -fsSL https://raw.githubusercontent.com/drandx/testkit/main/install.sh | bash
```

**From a clone:**

```bash
git clone https://github.com/drandx/testkit
./testkit/install.ps1 -Target /path/to/your-project      # or install.sh --target ...
```

Re-running is safe — existing files are skipped unless you pass `-Force` /
`--force`. The file list lives in `.testkit/manifest.txt` (single source of truth
for both installers). After installing, open the project in Copilot CLI and run
`/testkit.scenarios <spec-dir>`.

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
6. **The constitution is authority.** `.testkit/memory/constitution.md` holds the
   MUST principles; each agent loads it and treats a violation as CRITICAL. Rules
    1–5 above are enforced there, not just described here.

## Enforcement mechanics

- **`tools:` scoping** in each agent's frontmatter enforces posture at the
  platform level, not just in prose: Scenarios/Clarify get `read, search, edit`
  (no `execute`); Discovery/Run add `execute`; the front door is `read`-only.
- **`check-prerequisites.ps1`** is each stage's first step — it resolves the
  feature directory and asserts the required upstream artifacts exist, so a stage
  fails fast instead of running on missing input.

## Caveat: handoffs on the CLI

`handoffs:` is documented primarily for VS Code, and Copilot CLI support has been
in flux (see github/copilot-cli#1195). If your CLI build ignores handoffs, the
chain still works — invoke each stage manually (`/testkit.clarify <spec-dir>`,
etc.); the file contract makes the stages composable either way.

## Layout

```
.github/agents/          testkit (front door) + four stage agents (Copilot CLI agent files)
.testkit/memory/         constitution.md (non-negotiable principles)
.testkit/templates/      artifact templates (the contract)
.testkit/scripts/powershell/  check-prerequisites.ps1 + _template.ps1
```

## Roles at a glance

| Agent | Owns | Interactive | Produces | Hands off to |
|-------|------|-------------|----------|--------------|
| testkit | front door | only to ask for spec dir | — | scenarios |
| scenarios | what to test | no | test_cases.csv | clarify |
| clarify | intent / oracles | **yes** | test-memory.md | discover |
| discover | capability / scripts | no | tools-report.md, scripts/*.ps1 | run (gated) |
| run | execution | no | test-results.md | — (terminal) |

## Using it on a real project & giving feedback

The fastest improvement loop while TestKit is young:

1. Install into a real repo (above) and run the pipeline on one real feature.
2. The artifacts it produces — `test_cases.csv`, `test-memory.md`,
   `tools-report.md`, `test-results.md` — **are** the feedback. They are small,
   diffable, and committed to your repo, so when a stage gets something wrong the
   evidence is right there in the file.
3. Capture what went wrong against the stage that owns it (see the table) — e.g.
   "Discovery validated a tool no scenario used" is a Principle III violation in
   `testkit.discover.agent.md`. Tightening the agent prompt or the constitution is
   usually the fix.
4. Open an issue on `drandx/testkit` (or paste the offending artifact back into a
   session) and we iterate on that one agent file. Because each agent is isolated
   and the contract is files, changes are low-blast-radius.

### Versioning the install

`install.*` pin a `-Ref`/`--ref` (default `main`). Tag releases (`v0.1`, …) so a
project can pin a known-good TestKit and upgrade deliberately by re-running the
installer with `-Force` against a new ref.
