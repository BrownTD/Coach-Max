# Coach Max GitHub Project Governance

- **Effective date:** 2026-08-23
- **Project:** [Coach Max Productization Roadmap](https://github.com/users/BrownTD/projects/7)
- **Repository:** `BrownTD/Coach-Max`
- **Ticket prefix:** `CMX`
- **Default branch:** `main`
- **Iteration cadence:** 14 days beginning 2026-08-31
- **Planning capacity:** 6 development hours per week

## Purpose

This document defines the shared vocabulary, release plan, and engineering workflow for turning Coach Max into a managed, licensable white-label product. GitHub Project views are different presentations of the same work items; Project fields are the source of truth for planning, while issues and pull requests are the source of truth for delivery.

## Status definitions

| Status | Definition |
|---|---|
| Backlog | Valid work that has been captured but is not yet scheduled. Requirements or estimates may still need refinement. |
| Ready | Fully scoped, acceptance criteria are defined, dependencies are resolved, and development can begin. |
| In Progress | Active implementation, investigation, design, or documentation work is underway. |
| In Review | A pull request or deliverable is ready for validation and is awaiting checks or review. |
| Ready to Merge | Required checks have passed, acceptance criteria have been validated, and the pull request can be merged. |
| Blocked | Work cannot proceed because of an unresolved dependency, decision, credential, external provider, or technical obstacle. |
| Done | Acceptance criteria are satisfied, required tests and documentation are complete, the change is merged, and the issue is closed. |

For one contributor, the work-in-progress limit is one `In Progress` issue. `In Review` should also normally contain no more than one issue.

## Issue type definitions

| Issue Type | Definition | Development branch |
|---|---|---|
| Epic | A phase- or release-level outcome containing multiple features or tasks. | No |
| Feature | A customer or platform capability that may require multiple implementation tasks. | Normally no |
| Task | A specific, independently verifiable unit of implementation work. | Yes |
| Bug | Existing behavior that differs from intended behavior and needs a reproducible correction. | Yes |
| Spike | Time-boxed research or prototyping used to reduce uncertainty. Production delivery is out of scope unless explicitly stated. | Yes |
| Decision | A product, commercial, architecture, provider, or operational choice with documented alternatives and rationale. | Only when an ADR or code change is required |
| Documentation | Customer, developer, operational, support, or legal documentation work. | Yes |

Security is a cross-cutting concern, not an issue type. Use `security-sensitive` on the applicable issue type, and never publish exploitable details in a public repository.

## Issue hierarchy policy

GitHub's native parent/sub-issue relationship is the source of truth for work breakdown:

```text
Epic
├── Feature
│   ├── Task
│   ├── Bug
│   ├── Spike
│   ├── Decision
│   └── Documentation
├── Decision
└── Standalone leaf work
```

- Epics are hierarchy roots and do not declare a parent.
- Features are direct children of an Epic.
- Tasks, Bugs, Spikes, Decisions, and Documentation normally belong to a Feature, but small cross-cutting items may belong directly to an Epic.
- An issue has one current parent. Changing `Parent Issue` intentionally reparents the issue.
- Only actionable leaf issues receive development branches and pull requests.
- Closing child issues updates GitHub's `Sub-issues progress`; Epic closure remains an explicit product decision.
- Project views should expose the built-in `Parent issue` and `Sub-issues progress` fields rather than custom replacements.

The `Issue Hierarchy` workflow reads `Parent Issue` from issue-form headings or the hidden Project metadata block. It accepts hierarchy changes only for repository-owner issues or actors with write-level access, validates the allowed Issue Type relationship, and synchronizes through GitHub's native sub-issue API. Repeated synchronization is idempotent.

## Workstream definitions

| Workstream | Definition |
|---|---|
| Architecture | Core system design, domain boundaries, technical decisions, major refactoring, and platform foundations. |
| Tenancy | Organizations, memberships, tenant context, isolation, domains, configuration, auditing, and tenant-scoped data. |
| Identity | Authentication, authorization, sessions, invitations, roles, OIDC, SAML boundaries, and operator separation. |
| AI | AI provider abstraction, prompts, feedback, vision, transcription, TTS, metering, budgets, safety, and provider failures. |
| Integrations | Managed video, PostHog, email, webhooks, provider interfaces, content migration, usage, and third-party credentials. |
| White Label | Branding, domains, terminology, organization configuration, email identity, AI persona, and administration. |
| Billing | Subscriptions, plans, entitlements, usage tracking, invoices, overages, credits, and premium add-ons. |
| Operations | CI/CD, deployment, jobs, monitoring, alerts, backups, restore, upgrades, rollback, offboarding, and support tooling. |
| QA / Security | Automated tests, tenant-isolation validation, threat remediation, privacy controls, security gates, and release verification. |
| Documentation/Legal | Customer documentation, developer guidance, runbooks, contracts, licensing, DPA, SLA, and onboarding materials. |

## Release definitions

| Release | Definition |
|---|---|
| Foundation | Product decisions, architecture baseline, reproducible development environment, CI, and the initial commercial model. |
| Tenant Ready | Organization boundaries, isolation, configuration, branding, domains, memberships, and tenant authorization are operational. |
| Identity Ready | Emergent authentication has been replaced and organization identity, sessions, invitations, and roles work end to end. |
| AI Ready | Emergent AI services have been replaced, core workflows retain parity, and organization usage can be measured and limited. |
| Integration Ready | The Equip-derived native LMS, managed video, PostHog, email, and other launch services operate through tenant-scoped boundaries. |
| Paid Pilot | Onboarding, pilot-critical billing and operations, and a constrained production deployment are ready for design-partner use. |
| GA | All launch gates pass and provisioning, upgrades, billing, support, renewals, and offboarding are repeatable. |

## Risk definitions

Risk measures potential impact on security, data integrity, delivery, cost, or the next release. It does not measure implementation effort.

| Risk | Definition |
|---|---|
| High | Likely or severe impact on security, tenant isolation, data integrity, contractual obligations, cost, or a release target. An explicit mitigation is required. |
| Medium | Credible impact that can be managed through testing, monitoring, contingency planning, or a known fallback. Review during iteration planning. |
| Low | Limited and understood impact with a straightforward implementation or fallback. Normal testing and review are sufficient. |

## Priority definitions

| Priority | Definition |
|---|---|
| P0 | Security, data-integrity, build, or release blocker. |
| P1 | Required for the current implementation phase. |
| P2 | Required before Paid Pilot or GA but not required for the current phase. |
| P3 | Enhancement or post-launch refinement. |

## Required labels

| Label | Color | Use |
|---|---|---|
| `launch-gate` | `B60205` | A non-negotiable condition for the release selected in the issue's `Release` field. |
| `security-sensitive` | `D73A4A` | An issue containing non-public security remediation or threat information. Use only in a private repository. |

The `Launch Gates` view filters on `label:launch-gate`. The `Release` field distinguishes Paid Pilot gates from GA gates.

## Hard-target release schedule

**GA is fixed at January 1, 2027.** Starting August 31, 2026 at six development hours per week provides approximately 105 focused development hours. AI-assisted implementation is a core delivery assumption: use AI for code drafting, mechanical refactoring, test generation, documentation, and issue maintenance, while retaining human review for architecture, security, data isolation, provider behavior, and release acceptance.

The operating constraint is:

> The deadline and security/quality launch gates are fixed; feature scope is variable.

This schedule delivers a minimum licensable white-label v1 using dedicated customer deployments. It does not attempt to finish every long-term capability described in `White_Labeling.md` before GA.

### Release targets

| Release | Minimum outcome | Hours | Target date |
|---|---|---:|---:|
| Foundation | Reproducible build/test baseline, critical decisions, provider inventory, and enforceable GitHub delivery controls. | 12 | 2026-09-14 |
| Tenant Ready | Dedicated-deployment organization configuration, branding, scoped credentials, and removal of material hard-coded customer values. | 18 | 2026-10-05 |
| Identity Ready | Emergent authentication replaced for the launch flows, secure sessions, roles, and organization access checks. | 12 | 2026-10-19 |
| AI Ready | Launch-critical AI workflows use a direct provider adapter with limits, attribution, and failure handling. | 12 | 2026-11-02 |
| Integration Ready | The pinned Equip baseline is deverticalized into a native LMS; paid course content and managed video are protected; tenant-scoped email and privacy-conscious PostHog events work for the launch configuration. | 12 | 2026-11-16 |
| Paid Pilot | One design partner can be provisioned, branded, trained, supported, backed up, and operated using documented manual runbooks. | 12 | 2026-12-01 |
| GA | Launch gates, regression tests, security review, deployment/rollback validation, customer documentation, licensing terms, and release hardening pass. | 27 | 2027-01-01 |
| **Total** | **Minimum licensable dedicated-deployment v1** | **105** | **2027-01-01** |

### Iteration plan

| Iteration | Dates | Capacity | Primary focus |
|---|---|---:|---|
| 1 | 2026-08-31 to 2026-09-13 | 12 hours | Foundation and repeatable baseline |
| 2 | 2026-09-14 to 2026-09-27 | 12 hours | Dedicated tenant configuration and branding |
| 3 | 2026-09-28 to 2026-10-11 | 12 hours | Tenant boundary completion and identity replacement |
| 4 | 2026-10-12 to 2026-10-25 | 12 hours | Identity completion and direct AI provider foundation |
| 5 | 2026-10-26 to 2026-11-08 | 12 hours | AI parity and launch-critical integrations |
| 6 | 2026-11-09 to 2026-11-22 | 12 hours | Integration completion and pilot onboarding |
| 7 | 2026-11-23 to 2026-12-06 | 12 hours | Paid pilot, defects, operating runbooks, and backup validation |
| 8 | 2026-12-07 to 2026-12-20 | 12 hours | Regression, security, release, and customer documentation |
| Launch buffer | 2026-12-21 to 2027-01-01 | 9 hours | P0/P1 defects and final launch-gate evidence only |

Plan at most 8-10 of the 12 nominal hours in each full iteration. The remaining capacity absorbs review, integration surprises, and defects. Any issue estimated above eight hours must be split before it enters `Ready`.

### Explicitly deferred from the January 1 v1

- Shared-database multi-tenancy; v1 uses a dedicated deployment and database per customer.
- Multiple brands within one customer deployment.
- Thinkific OAuth, continuous synchronization, and marketplace distribution; v1 may use an operator-assisted import from a supported customer export but has no Thinkific runtime dependency.
- Feature-for-feature Thinkific parity, advanced certificates, live classrooms, commerce storefronts, and broad SCORM/xAPI support.
- Customer-owned AI credentials and multi-provider selection; v1 uses the approved vendor-managed provider.
- Enterprise SAML and advanced identity-provider administration beyond the launch authentication flow.
- Self-service checkout, automated invoicing, and complex usage overages; v1 uses contracts and manual billing operations.
- Fully self-service customer onboarding and environment provisioning; v1 uses an operator-run checklist and scripts.
- Downloadable, perpetual, or customer-operated editions.
- Advanced analytics, session replay, and nonessential reporting.
- Non-launch-critical feature expansion or visual redesign.

Deferred scope becomes post-GA roadmap work. It must not be reintroduced into a pre-GA iteration unless an equal or larger item is removed.

### Non-negotiable January 1 gates

- No known P0 issue is open.
- Launch authentication and authorization tests pass.
- Dedicated customer data and credentials are isolated from other deployments.
- Secrets are not committed or exposed to the browser.
- Critical AI and integration failures are bounded, observable, and recoverable.
- Build, deployment, backup, restore, and rollback procedures are verified.
- The submission-to-feedback critical path passes end to end.
- Customer onboarding, support, data handling, and offboarding responsibilities are documented.
- Licensing terms, privacy commitments, and third-party service responsibilities are explicit.

If a gate fails, functionality is removed or the release is narrowed; the gate is not waived.

## Ticket and delivery policy

For issue `#142`:

```text
Ticket key:  CMX-142
Issue title: CMX-142: Replace Emergent authentication
Branch:      CMX-142
PR title:    CMX-142: Replace Emergent authentication
Commit:      CMX-142: Add OIDC provider adapter
```

Rules:

- One actionable issue maps to one working branch and one primary pull request.
- Branch names are exactly `CMX-<issue number>`.
- Every commit subject begins with the identical ticket key and a colon.
- The PR title begins with the identical ticket key and a colon.
- The PR body contains `Closes #<issue number>`.
- Earlier partial PRs use `Related to #<issue number>`; only the final PR closes the issue.
- Epics and parent features do not normally receive branches.
- Direct pushes to `main` are prohibited.
- Pull requests are squash-merged and head branches are deleted after merge.

## Automated state transitions

```text
Issue created                    -> Backlog
Issue scheduled and refined      -> Ready
CMX branch created               -> In Progress
Draft PR opened                  -> In Progress
PR marked ready                  -> In Review
Ticket policy succeeds           -> Ready to Merge
Changes requested                -> In Progress
PR merged / issue closed         -> Done
Issue reopened                   -> Backlog
```

The GitHub connector is used for interactive issue, branch, commit, and PR work. GitHub Actions provide persistent Project synchronization because Project operations are not exposed by the installed connector.

## Launch gates

An issue is a launch gate when failure to complete it makes the selected release unsafe, non-compliant, operationally unsupported, or commercially unusable. Launch gates must have:

- The `launch-gate` label.
- `Release` set to `Paid Pilot` or `GA`.
- Measurable acceptance criteria.
- Validation evidence before closure.
- No unresolved P0 or High-risk dependency.

## Project field metadata for generated issues

Issues generated through automation may include this hidden block. The Project workflow uses it to populate fields without exposing Project write tools to the interactive connector.

```html
<!-- coach-max-project -->
{"Issue Type":"Task","Phase":"Phase 1","Workstream":"Tenancy","Priority":"P1","Estimate":5,"Start Date":"2026-09-06","Target Date":"2026-09-19","Release":"Tenant Ready","Risk":"High","Iteration":"Iteration 2","Parent Issue":142}
<!-- end-coach-max-project -->
```

Field and option names must match the GitHub Project exactly.

Editing this metadata automatically refreshes the Project item without changing
its current Status. `Estimate` is a non-negative number and may be fractional
when the value represents focused human oversight for AI-assisted delivery.
