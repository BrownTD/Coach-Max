# Coach Max Repository Agent Instructions

These instructions apply to the entire repository. Follow them for every Codex run that reads, plans, creates, edits, or validates Coach Max work.

## Authoritative project sources

Before changing issues, Project metadata, branches, pull requests, schedules, estimates, or release scope, read the applicable sections of:

- `docs/GITHUB_PROJECT_GOVERNANCE.md` for workflow, hierarchy, field definitions, labels, releases, and delivery policy.
- `Repo_Status_2026-08-22.md` for the repository assessment, cleanup evidence, risks, and remediation requirements.
- `White_Labeling.md` for the agreed product, licensing, tenancy, integration, and white-label implementation direction.

Use those documents as requirements sources. Do not silently weaken their security, quality, licensing, or MVP requirements.

## Non-negotiable Project protections

- Never add, remove, rename, filter, group, sort, reorder, duplicate, archive, or otherwise modify a GitHub Project view unless the user explicitly requests that exact view change.
- Never change issue dates, estimates, iteration, hierarchy, status, or other Project fields without verifying the resulting issue and Project state.
- Use the exact Project field names and exact option spelling. Inspect the current Project configuration when an option is uncertain; do not invent or normalize names.
- Treat Project fields as the planning source of truth and issues and pull requests as the delivery source of truth.
- Use GitHub Actions for persistent policy enforcement and Project synchronization. `AGENTS.md` guides agents but is not an enforcement substitute.
- After bulk issue mutations, verify every affected issue, native parent relationship, Project field value, and relevant workflow run. Report partial failures explicitly and retry only safe, idempotent operations.

## Issue hierarchy

Use this hierarchy:

```text
Epic
└── Feature
    ├── Task
    ├── Bug
    ├── Spike
    ├── Decision
    └── Documentation
```

- Epics are roots and have no parent.
- Features must normally have an Epic parent.
- Actionable leaf issues must normally have a Feature parent so all delivery work rolls up to an Epic.
- A small cross-cutting leaf may be attached directly to an Epic only when no honest Feature parent exists; document the reason in the issue.
- Each issue has at most one native parent. Establish the native GitHub parent/sub-issue relationship in addition to recording `Parent Issue` metadata.
- Do not create branches or implementation pull requests for Epics and normally do not create them for Features.
- Create branches for actionable leaf issues only.

## Scheduling and estimates

- Every scheduled actionable leaf must have `Iteration`, `Start Date`, and `Target Date` populated.
- A Backlog leaf may remain without iteration or dates until it is committed to a schedule.
- Epics and Features normally span multiple iterations. Leave their `Iteration` blank and use roadmap dates plus child progress unless the entire parent genuinely belongs to one iteration.
- Closed governance, automation, or documentation leaves retain the iteration and dates in which the work occurred.
- Query the current Project iteration configuration before scheduling. Do not rely on stale dates in prose documentation when the Project has been edited.
- Estimates represent focused human implementation and review time with GPT-5.6 Sol assistance. Fractional non-negative estimates are allowed.
- Preserve the complete approved MVP scope when compressing estimates. Never remove requirements or acceptance criteria merely to reduce an estimate.
- Split work when it cannot be independently reviewed or completed safely within the applicable iteration capacity.

## Every Coach Max issue field

Every applicable field must be filled. A field may remain blank only when the rules below explicitly make it inapplicable, derived, or automatically populated. Never omit a field merely because its value requires investigation.

### Native issue content and relationships

| Field | Population rule |
|---|---|
| Repository | Automatically `BrownTD/Coach-Max`; verify before every external write. |
| Issue number | Assigned by GitHub. Use it immediately to normalize the title and Ticket Key. |
| Title | Required. Exact format: `CMX-<issue-number>: <short outcome-oriented title>`. |
| State | Required. Open until acceptance criteria are complete; close through the linked final PR or an explicitly documented non-code resolution. |
| Body | Required. Use the content requirements below and include the Project metadata block for generated issues. |
| Assignees | Required when an owner is known. For scheduled solo delivery, assign `BrownTD`; leave blank only for genuinely unowned Backlog work. |
| Labels | Apply every relevant repository label. `launch-gate` and `security-sensitive` must follow the governance definitions; never use a label decoratively. |
| Milestone | Populate when a matching repository milestone is actively used; otherwise `Release` is the roadmap source of truth. |
| Parent issue | Required for every Feature and actionable leaf; omitted only for an Epic. Establish the native relationship, not just body text. |
| Sub-issues | Add all direct children to their native parent and verify the relationship. This is inapplicable to a leaf. |
| Linked branch | Required for actionable implementation leaves once development starts; exact name `CMX-<issue-number>`. |
| Linked pull request | Required for code or repository changes. The final PR body contains `Closes #<issue-number>`. |
| Dependencies | Required in the body. State blocking and blocked-by issues, external decisions, credentials, or `None`. |
| Source references | Required when work comes from an assessment, plan, decision, defect report, screenshot, log, or external requirement. Use stable links or repository paths. |

### Required issue-body sections

Every generated Task, Spike, Documentation, Feature, or Epic body must contain:

- `Objective`: the observable outcome.
- `Context`: why the work exists and what source requirement supports it.
- `Requirements`: detailed, testable checkboxes without reducing approved scope.
- `Acceptance criteria`: observable completion conditions.
- `Dependencies`: blockers, blocked work, external prerequisites, or `None`.
- `Out of scope`: explicit adjacent work excluded from this ticket.
- `Validation`: tests, commands, inspection, or evidence required before closure.
- `Parent`: parent number and title when applicable.
- `Source`: applicable repository documents, findings, decisions, or links.
- The hidden `coach-max-project` JSON metadata block for Project synchronization.

Bugs must additionally include observed behavior, expected behavior, reproducible steps, sanitized evidence when available, and a regression-test requirement. Decisions must additionally include the bounded decision question, constraints, options and tradeoffs, proposed or approved outcome, and consequences.

### Configured Project fields

| Project field | Population rule |
|---|---|
| Status | Required for every Project item. Use exactly `Backlog`, `Ready`, `In Progress`, `In Review`, `Ready to Merge`, `Blocked`, or `Done` according to governance and automation. |
| Ticket Key | Required and derived as `CMX-<issue-number>` by automation. Verify it after synchronization. |
| Issue Type | Required. Use exactly `Epic`, `Feature`, `Task`, `Bug`, `Spike`, `Decision`, or `Documentation`. |
| Phase | Required. Use exactly one configured option: `Phase 0` through `Phase 8`, or `Continuous`. |
| Workstream | Required. Use exactly `Architecture`, `Tenancy`, `Identity`, `AI`, `Integrations`, `White Label`, `Billing`, `Operations`, `QA/Security`, or `Documentation/Legal`. |
| Priority | Required. Use exactly `P0`, `P1`, `P2`, or `P3`. |
| Estimate | Required for actionable leaves. Use a non-negative number of focused GPT-5.6 Sol-assisted human hours; fractional values are allowed. For parents, omit it when child rollups represent the work unless governance establishes an explicit parent estimate. |
| Start Date | Required for scheduled actionable leaves. Populate parents only when roadmap dates are intentionally maintained for the parent. Use `YYYY-MM-DD`. |
| Target Date | Required for scheduled actionable leaves. Populate parents only when roadmap dates are intentionally maintained for the parent. Use `YYYY-MM-DD` and keep it on or after Start Date. |
| Iteration | Required for scheduled actionable leaves. Backlog leaves may be unassigned; Epics and Features normally remain unassigned. Use the exact current Project iteration title. |
| Release | Required for every roadmap issue. Use exactly `Foundation`, `Tenant Ready`, `Identity Ready`, `AI Ready`, `Integration Ready`, `Paid Pilot`, or `GA`. |
| Risk | Required. Use exactly `High`, `Medium`, or `Low` based on impact, not effort. |
| Team | Populate whenever a configured Team option owns the work. Inspect current options first. Leave blank only when no Team option applies; do not invent an option. |
| Quarter | Populate when quarter planning applies and an exact configured option exists. Derive it from the approved Target Date, then verify it. |
| Parent issue | Automatically reflects the native parent relationship. Verify it for every Feature and leaf. |
| Sub-issues progress | Automatically calculated for Epics and Features. Do not set it manually; verify it after hierarchy changes. |
| Repository | Automatically populated. Verify that the item belongs to `BrownTD/Coach-Max`. |
| Assignees | Mirrors the native issue assignees. Populate the native field when applicable. |
| Labels | Mirrors native labels. Populate the native field according to governance. |
| Milestone | Mirrors the native milestone when milestones are used. |
| Linked pull requests | Automatically reflects linked PRs. Ensure the PR body links or closes the correct issue. |

If GitHub adds another field to Project 7, treat it as part of this list: determine its definition and valid options, update this file and the governance document through a governed PR, and populate it whenever applicable.

### Generated-issue metadata

Use this exact shape, omitting only fields that are inapplicable under the rules above:

```html
<!-- coach-max-project -->
{"Issue Type":"Task","Phase":"Phase 1","Workstream":"Operations","Priority":"P1","Estimate":1.5,"Start Date":"2026-08-23","Target Date":"2026-08-25","Release":"Foundation","Risk":"Low","Iteration":"Iteration 1","Parent Issue":123}
<!-- end-coach-max-project -->
```

- Use JSON numbers, not strings, for `Estimate` and `Parent Issue`.
- Dates use ISO `YYYY-MM-DD`.
- Do not put unsupported or guessed option values in metadata.
- Project-native or computed fields may be absent from metadata, but must still be verified after synchronization.

## Ticket, branch, commit, and pull-request policy

- Create or identify the actionable issue before creating a branch.
- Branch name: exactly `CMX-<issue-number>`.
- Every commit subject begins exactly `CMX-<issue-number>:`.
- PR title begins exactly `CMX-<issue-number>:` and uses the issue's short title.
- Final PR body contains `Closes #<issue-number>`; partial PRs use `Related to #<issue-number>`.
- Never push directly to `main`.
- Use squash merge after required checks and review pass.
- Remote head branches are automatically deleted after merge; delete local merged branches separately after verifying the merge.

## Creation and verification sequence

For every generated issue:

1. Read the applicable source requirements and current Project configuration.
2. Select the correct Epic, Feature, Issue Type, phase, workstream, priority, release, risk, estimate, schedule, assignee, and labels.
3. Write detailed requirements, acceptance criteria, dependencies, out-of-scope boundaries, validation, and metadata.
4. Create the issue and normalize its `CMX-<number>` title if necessary.
5. Establish the native parent relationship.
6. Allow Project and hierarchy workflows to complete.
7. Verify every applicable field, iteration dates, parent, Project membership, Status, Ticket Key, and workflow conclusion.
8. Only then report the issue as successfully created.

For bulk creation, maintain an explicit expected-value matrix and compare every created issue against it. Do not infer success from one passing item.

## Repository cleanup and security

- Treat this public fork as security-sensitive. Never publish credentials, personal data, reusable tokens, exploitable secret values, or unsanitized logs.
- Before deleting a file, prove why it is unnecessary by checking references, build/runtime use, tests, deployment configuration, documentation value, licensing obligations, and white-label requirements.
- Separate generated artifacts, obsolete platform metadata, sensitive historical/test material, dead code, and retained product assets in the cleanup inventory.
- Make deletions through a scoped ticket and reviewable PR. Do not perform broad wildcard deletion or history rewriting without explicit approval.
- Preserve user-authored changes and unrelated work. If ownership or necessity is ambiguous, document it and request a decision rather than deleting it.
- After cleanup, run the relevant backend, frontend, automation, security, and documentation validation available in the repository.
