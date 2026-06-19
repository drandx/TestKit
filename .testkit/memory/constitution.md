# TestKit Constitution

> Non-negotiable principles for the TestKit integration-testing workflow. Every
> agent treats a violation of a MUST as **CRITICAL** — it halts the stage and is
> reported, never silently worked around. Changing a principle requires editing
> this file explicitly, not reinterpreting it mid-run.

## I. Observable oracles (MUST)

Every scenario MUST have an observable pass/fail oracle — a status, record state,
message, HTTP code, or row count. A scenario whose expected result is vague
("works correctly") is a CRITICAL defect for TestKit Scenarios to fix.

## II. Files are the contract — committed artifacts only (MUST)

Each stage MUST read its inputs from the committed artifact and write its output
to the next artifact. State MUST NOT be carried forward only in conversation.
The artifact schema is fixed even when content differs across specs.

Generated working files (scripts, queue payloads, SQL, scratch) MUST be written
to `.testkit/work/<feature>/` and are gitignored — they are never committed.
They are mechanically re-derived from the committed artifacts and may be
re-generated at any time by re-running the producing stage.

## III. Scenario-scoped tools (MUST)

A tool MUST appear in `tools_required` only if a scenario's procedure invokes it,
and Discovery MUST validate exactly that union — never a superset. Provisioning a
tool no scenario exercises is a CRITICAL violation. (This is the rule that exists
specifically to stop "stuck running tools that weren't even needed.")

## IV. One interactive stage (MUST)

Only TestKit Clarify may ask the user questions. A question raised by Scenarios,
Discovery, or Run is a defect to report upstream, not a prompt to relay.

## V. Scripts are honest and minimal (MUST)

Each script does ONE manual step, mirrors the user's manual action, and exits 0
only on the oracle's success signal. A script MUST NOT be edited to force a test
to pass; a wrong script means the scenario FAILS and the defect is recorded.

## VI. Gate on blocked (MUST)

If any required tool is unreachable, its scenarios are BLOCKED. The workflow MUST
NOT execute past Discovery while any scenario is BLOCKED. Blocked is reported as
blocked — never silently dropped and never counted as a failure.

## VII. Faithful reporting (MUST)

Results MUST reflect reality: a failure carries its output, a skip is reported as
blocked with its reason, and a pass is asserted only when the oracle is met.

## VIII. Decisions are recorded (MUST)

Every stage MUST record the choices it made in the `Decision Log` of the artifact
it writes — questions asked and answered, assumptions taken, ambiguities resolved,
and why anything was marked BLOCKED or FAILED. The log is append-only: a prior
entry is never rewritten. A decision that lives only in conversation is a Principle
II violation. (Scenarios records its log in the `test_cases.decisions.md` companion
because its primary artifact is a CSV.)
