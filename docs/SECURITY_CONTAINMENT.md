# Security containment and credential rotation

This runbook is the sanitized operational record for CMX-3. Never add a secret,
token, password, connection string, learner artifact, private scan report, or
provider response to this file, an issue, a pull request, or a commit.

## Repository containment performed

- Removed tracked credential and direct session-seeding notes.
- Removed tracked uploads, learner submissions, generated audio, and historical
  JSON/JUnit reports from the current tree.
- Replaced hard-coded operational email identities with deployment configuration
  and synthetic `example.test` test identities.
- Added source-controlled environment templates containing no secret values.
- Added ignore rules for environment files, credential exports, runtime uploads,
  generated reports, and local security-testing notes.
- Added `scripts/verify-sensitive-artifacts.py` to verify that prohibited artifact
  classes are not tracked. Permanent automated secret scanning is owned by CMX-4.

## Sanitized scan record

On 2026-08-24, Gitleaks 8.30.1 scanned the complete Git history with all detected
values fully redacted. It reported 28 candidates across two detector classes and
17 paths. The candidates included historical environment configuration, local
authentication-testing notes, generated test reports, and code/test identifiers
that require manual false-positive review. Before cleanup, a working-tree scan
reported 19 candidates across 11 paths. Store the unredacted report only in the
approved private incident record; do not commit it.

After current-tree containment, the same redacted working-tree scan reported seven
candidates across three source/test files. Manual review confirmed all seven are
non-secret assignment identifiers or explanatory schema text. This disposition
does not create a permanent allowlist; CMX-4 must encode narrowly scoped scanner
configuration and regression coverage.

After every containment change, run:

```bash
python3 scripts/verify-sensitive-artifacts.py
gitleaks dir --redact=100 --no-banner .
gitleaks git --redact=100 --no-banner --log-opts=--all .
```

The history scan will continue to find removed material until the coordinated
history rewrite is completed. A detector hit is not automatically a live secret;
review it privately and record only its credential class and disposition here.

## Rotation and revocation ledger

Complete this table without secret values. Put provider confirmation IDs,
timestamps, screenshots, and named operator evidence in the private incident
record, then record only its reference below.

| Credential or access class | Required action | Public status | Private evidence reference |
|---|---|---|---|
| MongoDB users and connection strings | Never reuse upstream values. Create a new least-privilege BrownTD-owned database credential through CMX-167 before deployment. | Not applicable to rotation: never owned, copied, deployed, or reused by BrownTD. | Owner attestation on 2026-08-24; Issue #3 |
| AI provider credentials | Never reuse upstream values. Create a new provider credential only after the replacement AI integration defines its secret contract. | Not applicable to rotation: never owned, copied, deployed, or reused by BrownTD. | Owner attestation on 2026-08-24; Issue #3 |
| Resend/email credentials | Never reuse upstream values. Create a new restricted credential and verified sender through CMX-167 only when email is enabled. | Not applicable to rotation: never owned, copied, deployed, or reused by BrownTD. | Owner attestation on 2026-08-24; Issue #3 |
| Thinkific credentials | Do not create or migrate a credential. Leave the legacy configuration unset and remove it with the approved Thinkific retirement work. | Not applicable to rotation: never owned, copied, deployed, or reused by BrownTD. | Owner attestation on 2026-08-24; Issue #3 |
| Identity, test, and deployment credentials | Never reuse upstream values. Issue new provider/runtime credentials through CMX-167 and use ephemeral synthetic test sessions. | Not applicable to rotation: never owned, copied, deployed, or reused by BrownTD. | Owner attestation on 2026-08-24; Issue #3 |
| GitHub Project automation credential | Retain the newly issued BrownTD token in the repository Actions secret store; never expose it to application runtime or source control. | Newly issued by BrownTD and not sourced from repository history. | Repository Actions secret configuration; value intentionally not recorded |

BrownTD cannot revoke credentials owned by the upstream repository operator. The
owner attested on 2026-08-24 that this fork has never been deployed with inherited
credentials and has never connected to the original MongoDB database. New
BrownTD-owned credentials will be issued and stored under CMX-167. Historical
upstream values remain permanently disclosed and must never be reused.

## Session and magic-link invalidation

Coach Max stores both login sessions and magic-link sessions in the
`user_sessions` collection. The owner attested on 2026-08-24 that BrownTD has never
deployed this fork and has never connected it to the original database. BrownTD
therefore has no inherited sessions or magic links to invalidate, and this gate is
not applicable to the containment incident.

For a future incident involving a deployed BrownTD database, an authorized
operator must invalidate every existing record during a communicated maintenance
window:

```javascript
db.user_sessions.deleteMany({})
```

Then verify that an old browser session and a previously issued magic link both
fail, while a newly authenticated session works. Record counts, timestamp,
environment, operator, and test evidence privately; do not record any token.

## Coordinated history rewrite

History rewriting is destructive and affects commit hashes, signatures, open pull
requests, branches, tags, forks, and existing clones. Perform it only after this
containment PR is merged, the owner attestation and not-applicable dispositions
above are recorded, all contributors are notified, and a maintenance window is
approved.

Use a new mirror clone of `BrownTD/Coach-Max`, follow GitHub's current
[sensitive-data removal procedure](https://docs.github.com/en/authentication/keeping-your-account-and-data-secure/removing-sensitive-data-from-a-repository),
and remove these historical paths from every ref:

- `backend/.env`
- `frontend/.env`
- `auth_testing.md`
- `memory/test_credentials.md`
- `backend/uploads/`
- `test_reports/`

Before force-pushing, inspect `git-filter-repo`'s changed-ref and first-changed-
commit reports privately, rescan the mirror, and obtain explicit approval for the
exact `BrownTD/Coach-Max` remote and all refs. The default-branch ruleset may need
a temporary, time-bounded administrative bypass. Restore protections immediately
afterward, rescan GitHub, and have every local clone re-cloned or carefully cleaned
so a merge cannot reintroduce the old history.

If sensitive objects remain in pull-request refs or caches, follow GitHub's process
to provide the sanitized repository identity, affected-PR count, and first changed
commit information to GitHub Support. Never publish that incident evidence.

### BrownTD rewrite execution record

The BrownTD-controlled rewrite was completed on 2026-08-24 using
`git-filter-repo` 2.47.0 from a fresh mirror:

- Rewrote 234 of 235 commits across six branch refs and no tags.
- Removed the approved environment files, credential/session notes, runtime
  uploads, learner artifacts, generated reports, and historical hard-coded test
  session values.
- Preserved the current `main` tree exactly; only commit identities and historical
  content changed.
- Temporarily disabled repository ruleset `21224290` for the force-push window and
  verified that its complete configuration was restored exactly with enforcement
  active immediately afterward.
- Verified all six remote branch tips against the audited mirror.
- Replaced the local clone and permanently removed the stale clone after the fresh
  clone passed the tracked-artifact policy and redacted full-history scan.
- Confirmed no prohibited historical paths remain in the fresh clone. The seven
  remaining detector candidates are the previously reviewed non-secret assignment
  identifiers and explanatory schema text.

GitHub retains nine read-only `refs/pull/*/head` references for already-merged pull
requests. They cannot be updated by a repository force-push. GitHub Support should
be given repository `BrownTD/Coach-Max`, affected pull-request count `9`, and first
changed commit `e737ab2dac277704019f4f4332af95682ad89030` so it can determine which
server-side references and caches can be dereferenced or purged. No secret value
is required in the public issue or support-request description.

## Public fork and clone limitation

Rewriting `BrownTD/Coach-Max` cannot alter `slewis-cmd/Coach-Max`, another user's
fork, an existing clone, cached content, or any third-party copy. Coordinate with
repositories under your control, request removal from owners where appropriate,
and treat all credential values that ever appeared publicly as permanently
disclosed. Revocation—not history rewriting—is the security boundary.

## Closure evidence

CMX-3 may close only after all of the following are true:

- [x] Every credential class has a verified BrownTD disposition; historical
  upstream credentials were never owned, copied, deployed, or reused.
- [x] Session and magic-link invalidation is not applicable because no inherited
  database or deployment was ever used.
- [x] The current tree passes the artifact policy and a redacted secret scan.
- [x] The `BrownTD/Coach-Max` history rewrite and post-rewrite scan are complete.
- [ ] GitHub Support follow-up is complete when required for cached or PR refs.
- [x] The controlled local clone is clean and uncontrolled upstream/fork copies are
  documented as residual exposure outside BrownTD's control.
- [ ] The final public issue comment lists only credential classes, dates,
  disposition, and private evidence references—never values.
