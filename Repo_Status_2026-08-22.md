# Coach Max Repository Status

**Assessment date:** 2026-08-22  
**Repository:** `slewis-cmd/Coach-Max`  
**Local path:** `/Users/xxbrxwnn./prj_incubator/Coach-Max`  
**Analyzed commit:** `487a35750088b14911979a60905452659b4f5ea8` (`Auto-generated changes`)  
**Analyzed branch:** `dev` (same commit as local `main` and `origin/main` at assessment time)  
**Assessment type:** Static whole-repository review plus the offline validation possible from the clone

> Security note: this report intentionally does not reproduce any password, API key, database URI, session token, or other credential found during the review.

## Executive summary

Coach Max is a broad, working product prototype with significantly more functionality than its root README suggests. It combines cohort and curriculum management, multiple submission workflows, AI-assisted feedback, student coaching chat, progress analytics, gamification, email, audio, white-label branding, support, and Thinkific synchronization in one application.

The current repository should nevertheless be treated as **pre-production and not safe for a new production deployment without remediation**. Its product completeness is high, and the historical test artifacts show substantial feature-by-feature testing. Its production readiness is held back by critical secret hygiene issues, several concrete authorization/privacy gaps, unsigned webhook ingestion, public access to sensitive operational or generated content, unbounded uploads and AI-cost surfaces, a very large backend monolith, non-durable background work, and a clone that cannot be built or tested reproducibly without reconstructing a missing environment.

### Overall status

| Area | Rating | Assessment |
|---|---:|---|
| Product capability | 8/10 | Large and coherent feature set; core workflows appear implemented. |
| Architecture | 5/10 | Sensible stack and domain concepts, but backend boundaries are collapsed into one 8,336-line module. |
| Security and privacy | 2/10 | Critical credential/history exposure and multiple verified access-control/privacy defects. |
| Test evidence | 6/10 | 667 backend test functions and extensive stored reports, but no fresh runnable environment, no frontend test source, and no CI. |
| Reproducibility | 3/10 | No lockfile, environment template, container definition, setup automation, or CI workflow. |
| Operations and scalability | 4/10 | GridFS persistence and health hooks exist, but tasks are in-process, queries are capped/unpaginated, and indexes are absent. |
| Documentation | 3/10 | A detailed chronological PRD exists, but root/setup/API/operations documentation is missing or stale. |

**Release recommendation:** **No-go** until the P0 security and privacy items in this report are resolved and a clean deployment is rebuilt from rotated credentials.

## Scope and methodology

The review covered all 350 tracked files and the reachable Git history in the clone. It included:

- Repository structure, Git state, commit history, tracked artifacts, and ignore rules.
- Backend imports, models, helper functions, all 115 FastAPI route declarations, dependencies, role checks, ownership checks, MongoDB collection usage, file ingestion, AI calls, email generation, schedulers, diagnostics, and integrations.
- Frontend routing, authentication and branding contexts, pages/components, API access patterns, analytics scripts, build configuration, and dependency metadata.
- Product documentation, historical iteration reports, JUnit XML reports, test source, deployment metadata, sample uploads, and credential-related files.
- Offline parsing of every Python source file, JSON iteration report, and XML test report.
- Build/test attempts using only what the clone supplied.

This was not a live penetration test, database audit, cloud-configuration review, browser usability pass, or fresh end-to-end run. The clone has no installed Python test environment, no frontend dependencies, no package lockfile, and no local environment configuration. No production endpoint or database was exercised because many tests mutate shared data and the repository does not supply an isolated test stack.

## Repository inventory

### Size and composition

| Item | Count/size |
|---|---:|
| Tracked files | 350 |
| Tracked working-tree content | 9,823,048 bytes |
| Python files | 51 |
| Backend route declarations | 115 unique method/path pairs |
| Backend top-level module | 8,336 lines in `backend/server.py` |
| Backend test files | 47 |
| Backend test functions | 667 |
| Frontend source files | 106 |
| Frontend page/component code | Approximately 14,646 lines |
| Stored JSON iteration reports | 61 |
| Stored JUnit XML reports | 74 |
| Committed upload artifacts | 26: 23 PDF, 2 MP3, 1 DOCX |

### Top-level structure

```text
Coach-Max/
├── backend/
│   ├── server.py                 # Entire FastAPI app, domain logic, integrations, scheduler
│   ├── requirements.txt          # Fully pinned environment-style dependency list
│   ├── tests/                    # 47 predominantly integration/regression test modules
│   └── uploads/                  # 26 committed documents/audio files
├── frontend/
│   ├── src/
│   │   ├── pages/                # 24 routed product pages plus a legacy student page
│   │   ├── components/           # Domain components and Shadcn/Radix primitives
│   │   ├── context/              # Auth and branding state
│   │   └── lib, hooks, utils/
│   ├── public/index.html         # External scripts and PostHog configuration
│   ├── package.json              # React/CRA/CRACO dependencies; no lockfile
│   └── craco.config.js
├── memory/
│   ├── PRD.md                    # 810-line chronological product/change log
│   └── test_credentials.md       # Contains real test credentials; must not be tracked
├── test_reports/                 # Historical JSON and JUnit artifacts
├── .emergent/                    # Emergent platform metadata and cron support files
├── README.md                     # One-line placeholder
├── auth_testing.md               # Direct Mongo session-seeding playbook
└── test_result.md                # Testing-agent template with no current status payload
```

### Missing standard project assets

The repository has no:

- `LICENSE`.
- Root setup or operational README.
- `.env.example`, backend environment template, or frontend environment template.
- `Dockerfile`, Compose stack, Makefile, or equivalent reproducible local bootstrap.
- `pyproject.toml`, `pytest.ini`, `setup.cfg`, or backend package metadata.
- `yarn.lock`, `package-lock.json`, or other frontend dependency lockfile.
- `.github/workflows` or other visible CI pipeline.
- Frontend unit/integration test source (`*.test.*` or `*.spec.*`).
- Database schema migration framework or explicit index creation.

## Product capability assessment

The code implements the following major domains.

### Identity and access

- Emergent-managed Google OAuth session exchange.
- Cookie, Bearer header, and query-string token lookup.
- Student, instructor, and super-admin roles.
- First-user and configured-email super-admin promotion.
- Instructor invite/promotion/revocation.
- Cohort invitation codes, direct student addition, CSV import, and invite-all email.
- Long-lived email magic links.
- English/Spanish student language preference.

### Cohorts, curriculum, and content

- Cohort CRUD, multiple instructors, student membership, configurable week count, and self-paced auto-send mode.
- Manual release/unrelease of weeks.
- Knowledge-base materials by week and course-wide/global resources.
- Shared material library, duplication, cohort assignment/unassignment, download, and text preview.
- PDF, DOCX, spreadsheet, video, audio, and questionnaire handling across relevant flows.
- Video upload or external URL, background transcription, ffmpeg audio extraction, and Whisper integration.
- Google Drive folder links.
- Four seeded assignment types, custom assignments, per-week embedded milestones, final capstones, per-milestone context documents, file-extension overrides, and questionnaires.
- Shared rubric and assignment-template libraries with author/admin edit controls for those two libraries.

### Submission and feedback workflow

- Legacy material-based and newer assignment/milestone-based submission paths.
- Stable direct-submit URLs suitable for Thinkific links.
- Student submit/resubmit and instructor submit-on-behalf.
- GridFS-backed persistent file storage with legacy disk fallback.
- Multi-stage text extraction: PyPDF2, pdfplumber, Tesseract OCR, GPT vision fallback, DOCX, XLS/XLSX, and CSV.
- GPT-5.2 review prompts with cumulative prior-work context, global resources, same-milestone revisions, format-aware language, and progress scoring.
- Human-in-the-loop draft/edit/send workflow and optional automatic send.
- Feedback email, PDF export, TTS generation/cache, and audio playback.

### Student and instructor experience

- Assignment-oriented student dashboard and a retained legacy week-oriented dashboard.
- Instructor dashboard, cohort detail, submissions queue, progress analytics, and notification counts.
- Coach Max multi-turn tutoring chat after feedback, with persisted history and course/submission context.
- Coach Max cohort insights and weekly digest.
- Venture Path progress-score gamification and configurable module names/icons.
- White-label app/persona/colors/logo/favicon/email/system-prompt settings.
- Platform support chatbot, escalation tickets, and super-admin ticket management.

### Thinkific integration

- Course, chapter, enrollment, and progress reads.
- Student synchronization into cohorts.
- Manual progress refresh.
- Webhook processing for enrollment progress and lesson completion.

The feature set is substantial and generally follows a coherent learning workflow. The primary concern is no longer missing product surface; it is whether the existing surface can be operated safely and maintained reliably.

## Architecture and data flow

### Runtime architecture

```text
React 19 + CRA/CRACO
    │  Axios/fetch + Bearer token from localStorage
    ▼
FastAPI /api router
    ├── MongoDB document collections
    ├── MongoDB GridFS for uploads/audio
    ├── Emergent Auth session exchange
    ├── Emergent/OpenAI GPT-5.2, Whisper, and TTS
    ├── Resend email
    ├── Thinkific public API + webhook receiver
    └── In-process background tasks and weekly scheduler
```

### Main submission flow

1. A student resolves a public stable assignment/material link.
2. Authentication and cohort enrollment are enforced on the submit POST.
3. The uploaded file is read fully into memory and stored in GridFS; questionnaires are stored directly.
4. A detached `asyncio.create_task` transcribes media and/or generates AI review content.
5. Feedback is stored as a draft or sent automatically depending on cohort configuration.
6. An instructor can review/edit/send; the student receives email and can use Coach Max chat.
7. Progress analytics and Venture Path scoring derive from stored submissions and parsed score lines.

### MongoDB collections referenced

| Collection | Primary purpose |
|---|---|
| `users` | Identity, role, language, Thinkific mapping |
| `user_sessions` | OAuth sessions and magic-link bearer tokens |
| `cohorts` | Instructor/student membership and cohort settings |
| `materials` | Cohort and library learning content |
| `assignments` | Assignment definitions with embedded milestones |
| `assignment_templates` | Reusable assignment blueprints |
| `submissions` | Student attempts, feedback, score, file/transcript references |
| `tutor_chats` | Coach Max question/response history |
| `rubrics` | Shared reusable feedback instructions |
| `audio_cache` | TTS metadata and GridFS references |
| `platform_settings` | Branding and Venture Path overrides |
| `support_tickets` | Escalated support transcripts |
| `thinkific_progress` | Enrollment progress snapshots |
| `thinkific_events` | Lesson-completion events |

No unique, compound, or TTL indexes are created in application code. This is a correctness and scalability concern for user email, session token, domain IDs, cohort membership, submission lookup, chat lookup, and expiring sessions.

## Backend assessment

### Strengths

- The domain behavior is explicit and readable despite its size.
- Authorization helpers (`get_current_user`, `require_instructor`, `require_super_admin`, and `is_cohort_manager`) provide a useful foundation.
- Most cohort CRUD, submission access, analytics, and file download paths perform role plus cohort/owner checks.
- GridFS migration avoids the original ephemeral-disk data-loss problem.
- Text extraction has thoughtful fallbacks and avoids feeding binary garbage to the LLM.
- Input validation exists for questionnaire shape, rubric lengths, file extensions, Drive URL schemes, and selected settings.
- Legacy/new data coexistence is handled deliberately, with regression coverage around both paths.
- Exceptions from many optional services are logged and some email paths degrade gracefully.

### Structural weaknesses

- `backend/server.py` contains the application factory, configuration, models, repository queries, authorization, 115 routes, file processing, prompt construction, HTML email, PDF export, integrations, migrations, and scheduler in 8,336 lines.
- The module has 188 functions, 18 classes, 65 generic `except Exception` handlers, and several extremely large functions. The largest include `submit_on_behalf` (279 lines), `export_feedback_pdf` (256), `_run_auto_ai_review_for_submission` (241), `submit_homework` (234), and `review_submission` (230).
- Importing the module requires `MONGO_URL` and `DB_NAME` immediately. Configuration errors prevent even isolated helper imports unless callers manufacture environment state.
- Twenty-five endpoints parse raw `request.json()` payloads rather than typed Pydantic request models. Route declarations define no `response_model`, so OpenAPI contracts and output validation are weak.
- Pydantic `.dict()` and `.model_dump()` are mixed, and several list fields use literal `[]` defaults. Pydantic currently copies mutable defaults, but `default_factory=list` is clearer and safer.
- Business rules, prompts, HTML, and persistence mutations are tightly coupled, making small changes risky and unit testing difficult.

### Reliability and performance concerns

- All uploads are read fully into process memory. Only Whisper has a 25 MB downstream limit; general documents, CSVs, and video uploads have no application-level request/file cap.
- CPU-heavy PDF parsing, OCR, rendering, and spreadsheet work can run in async request paths. `_vision_extract_pdf_text` starts a thread and then performs a blocking `join(timeout=120)` from the active flow.
- Detached `asyncio.create_task` jobs are used for review, transcription, TTS-related work, digest generation, and startup scheduling. They have no durable queue, retry policy, idempotency lease, monitoring record, or shutdown drain. A restart can silently lose work.
- Every application worker starts the infinite weekly digest scheduler. A multi-worker or multi-instance deployment can send duplicate digests.
- The startup migration only fetches up to 100 cohorts, so larger installations can remain partially migrated.
- Many reads use fixed `to_list(100/200/500/1000/5000)` caps with no pagination or truncation metadata.
- Several analytics and dashboard flows perform repeated queries inside cohort/student/week loops, creating N+1 behavior as data grows.
- Session expiration is checked in application code, but there is no MongoDB TTL index or cleanup process.
- The `/api/health` response does not verify MongoDB, GridFS, AI, or Thinkific reachability, yet returns `healthy`.

## Frontend assessment

### Strengths

- Routes are organized into domain pages, with reusable components extracted for materials, cohort tabs, submissions, rubrics, and student homework tracks.
- React context centralizes authentication state and white-label branding.
- The Axios interceptor consistently attaches the stored Bearer token.
- React's normal rendering path escapes displayed user content; no `dangerouslySetInnerHTML` use was found.
- External links opened from React generally use `noopener`/`noreferrer`.
- Shadcn/Radix primitives provide a consistent component and accessibility baseline.

### Weaknesses

- There is no frontend test source and no CI-enforced lint/test/build script beyond CRA defaults.
- `AssignmentsTab.js` is 955 lines; several pages remain 400–623 lines. UI state, data fetching, dialogs, and mutations are often combined.
- API calls are spread across pages/components through repeated `API_URL` constants. There is no typed API layer, consistent error model, request cancellation, cache/query library, or centralized authorization handling.
- `ProtectedRoute` checks only authentication. Role-sensitive routes rely on each page to redirect or tolerate a 403, which already produces a documented flash-of-error issue for students visiting `/admin/venture-path`.
- Session tokens live in `localStorage`, so any successful XSS or compromised third-party script can take over the account.
- The old `StudentDashboard.js` and `/api/student/dashboard` implementation remain, but `/dashboard` now routes students to `StudentAssignmentsDashboard`. This doubles concepts and raises regression/documentation cost.
- `RoleSelection` is effectively unreachable for normal new accounts because the backend immediately assigns `student`; its copy and historical PRD still describe a role-selection onboarding flow.
- The landing page still displays a 2024 copyright and the static HTML title/description are Emergent defaults before runtime branding replaces the title.
- `frontend/public/index.html` loads an Emergent script and initializes PostHog session recording directly. Privacy controls, consent, input masking rules, retention, and environment gating are not documented in this repo.
- The project uses React 19 through a Create React App/react-scripts 5 toolchain and CRACO. This may work, but the absence of a lockfile makes compatibility non-deterministic.

## Security and privacy findings

### Critical

#### SEC-01 — Live secrets and personal data are present in tracked content or reachable history

Evidence:

- `memory/test_credentials.md` is tracked and contains a real Google-authenticated super-admin email and plaintext password.
- Git history contains nine revisions of `backend/.env`, with non-empty `MONGO_URL`, `EMERGENT_LLM_KEY`, `RESEND_API_KEY`, `THINKIFIC_API_KEY`, sender/notification addresses, and other deployment values.
- Git history also contains `frontend/.env` revisions.
- The repository commits 26 uploaded PDFs/DOCX/MP3 files whose names indicate course/student/submission content.
- Historical test reports contain real deployment URLs, identities, seeded session-token procedures, and operational database details.

Impact:

- Anyone with repository/history access may gain database, AI, email, Thinkific, or administrator access.
- Student educational records and intellectual property may be exposed through source distribution.
- Removing a file only from the current branch does not remove it from Git history or existing clones.

Required action:

1. Assume every historical secret is compromised; rotate MongoDB, Emergent/OpenAI, Resend, Thinkific, Google/test-account credentials, and invalidate all sessions/magic tokens.
2. Remove credentials, uploads, and sensitive reports from the current tree.
3. Rewrite repository history with an approved history-cleaning process, coordinate force-push/clone replacement, and verify forks/caches.
4. Move test credentials to a secrets manager and use synthetic data only.
5. Add automated secret scanning and pre-commit/CI enforcement.

### High

#### SEC-02 — Any instructor can read and analyze another cohort's Coach Max conversations

`GET /api/cohorts/{cohort_id}/coach-max-report` and `POST /api/cohorts/{cohort_id}/coach-max-report/generate` require an instructor role but do not call `is_cohort_manager`. A caller who knows or obtains another cohort ID can retrieve student names, raw questions, AI responses, timestamps, and generated analysis for that cohort.

This is a verified broken object-level authorization defect in `backend/server.py:7593` and `backend/server.py:7675`. Add cohort-manager authorization before any related query, and add negative cross-cohort tests for both endpoints.

#### SEC-03 — Any instructor can modify another cohort's milestone context documents

The context-document upload/delete routes check only that the user is an instructor or super admin. They load the assignment but never load its cohort and verify `is_cohort_manager` (`backend/server.py:3277` and `backend/server.py:3325`). Any instructor with an assignment/milestone ID can replace or remove another cohort's AI source context, changing future feedback.

These routes also leave orphaned GridFS blobs when replacing/removing context documents. Enforce cohort ownership and delete the old GridFS object transactionally or through a cleanup job.

#### SEC-04 — Thinkific webhook requests are unsigned

`POST /api/webhooks/thinkific` accepts arbitrary JSON with no HMAC/signature, timestamp, replay, source, or shared-secret verification. An attacker can falsify enrollment progress and insert lesson-completion events.

Verify Thinkific's supported signature scheme using the raw request body, reject stale/replayed messages, and add a unique event/idempotency key. If the integration cannot sign webhooks, place it behind a gateway-held secret and strict allowlist.

#### SEC-05 — Magic links are reusable 30-day account sessions exposed in URLs

Magic links are stored in `user_sessions` as full bearer sessions and returned unchanged by `/api/auth/magic-link`; despite the word “consume,” they are not invalidated after use. They live for up to 30 days and appear in `?auth=` page URLs.

The frontend's third-party Emergent and PostHog scripts load before React removes the query parameter. Analytics, browser history, proxy logs, screenshots, support tools, or referrers may capture a token capable of account takeover.

Use a one-time, short-lived, hashed magic-link nonce. Atomically exchange it for a separate session, invalidate it on first use, and remove it server-side from any redirect URL. Do not initialize analytics until sensitive parameters are stripped.

#### SEC-06 — Sensitive audio and diagnostics have public access paths

- `GET /api/audio/{filename}` is unauthenticated and serves generated feedback/chat audio. Filenames are opaque but are bearer-like URLs, and committed examples disclose naming structure.
- `GET /api/debug/submission/{submission_id}` is public and exposes submission, material, cohort, week, and status metadata.
- `GET /api/health` publicly reveals the sender email and the prefix of the Resend API key.
- Public branding returns `ai_system_prompt` because the endpoint exposes the full settings object used by the frontend.

Require appropriate user/cohort authorization for audio, delete the debug route in production, remove all secret prefixes/config details from health responses, and separate public branding fields from server-only prompt configuration.

#### SEC-07 — Third-party session recording is enabled on an education platform without visible safeguards

PostHog session recording and cross-origin iframe recording are initialized in `frontend/public/index.html`; an additional remote Emergent script is loaded globally. The repo contains no consent flow, masking configuration, privacy policy linkage, environment switch, data-processing documentation, or evidence that student submissions, chats, feedback, emails, names, and tokens cannot be recorded.

Disable session recording until a privacy/FERPA review is complete. If retained, explicitly mask all inputs and sensitive DOM regions, disable URL/query capture, gate it by environment and consent, document retention/residency, and confirm contractual data-processing terms.

#### SEC-08 — No upload, request-rate, or AI-cost controls

Authenticated users can submit arbitrarily large files that are read fully into memory. AI review, support chat, tutoring, vision extraction, transcription, TTS, insights, emails, and global digest triggers have no visible application rate limit, quota, concurrency limit, or cost budget. Any instructor can trigger the all-cohort weekly digest.

Enforce gateway and application body limits, per-format limits, MIME/magic-byte validation, rate limits, per-user quotas, AI concurrency budgets, and super-admin-only global operations.

### Medium

#### SEC-09 — Shared material-library mutation lacks author/admin controls

Rubrics and assignment templates correctly limit update/delete to author or super admin. Library materials do not: any instructor can replace, delete, or retrigger transcription for any shared library item. Confirm the intended trust model; otherwise apply the same author/admin policy and expose `can_edit`.

#### SEC-10 — Email HTML interpolates unescaped user and AI content

Support transcripts, student names, cohort/material titles, feedback, AI summaries, and student questions are inserted into HTML email strings without consistent escaping. This permits markup injection and deceptive links in support/digest/feedback emails. Escape all untrusted values and generate HTML through a template system with auto-escaping.

#### SEC-11 — Invitation links trust the request `Origin` header

Several invitation flows use the caller-provided `Origin` header to build email links, falling back to a hard-coded Emergent preview URL. A direct API client can supply a hostile origin and cause the platform to email a phishing link. Always use one validated server-side `APP_BASE_URL`.

#### SEC-12 — Broad token transport and storage increase leakage impact

`get_current_user` accepts cookies, Authorization headers, and `?token=` query strings. The frontend stores tokens in `localStorage`. Query tokens can leak through logs/history, while localStorage is readable by any same-origin script. Migrate to Secure, HttpOnly, SameSite cookies where the deployment topology permits, or use short-lived access tokens plus rotation and a narrowly scoped download-ticket mechanism.

#### SEC-13 — CORS defaults to every origin

`CORS_ORIGINS` defaults to `*`, with all methods and headers allowed. Bearer authentication prevents classic credentialed CORS by itself, but this unnecessarily broad policy expands browser-accessible attack surface and makes future cookie changes dangerous. Require an explicit production origin allowlist and fail closed when it is absent.

#### SEC-14 — Internal exception text is returned to clients

AI review, TTS, and insight endpoints include `str(e)` in HTTP 500 responses. Provider messages can reveal implementation, request, account, or configuration details. Log a correlation ID server-side and return a stable public error.

### Privacy/compliance observations

- Student submissions, feedback, chat questions, support transcripts, names, and course context are stored and/or sent to MongoDB, Emergent/OpenAI, Resend, PostHog, and Thinkific.
- There is no visible retention schedule, data deletion/export flow, consent record, subprocessors document, privacy policy integration, or tenant boundary beyond cohort IDs.
- Weekly digest emails quote raw student questions across every cohort to a hard-coded recipient.
- TTS cache and GridFS content have no expiration or lifecycle policy.
- Cohort/submission deletion is not documented as a complete subject-data erasure mechanism across chats, audio, events, reports, email, analytics, and third parties.

Before use with real student records, perform a formal privacy/FERPA review and document data flow, legal basis/consent, retention, deletion, access logging, incident response, and vendor agreements.

## Data integrity and authorization observations

- No database unique indexes protect `users.email`, `user_sessions.session_token`, public IDs, invite codes, or assignment/submission natural keys. Application-level checks can race.
- First-user super-admin assignment uses `count_documents({}) == 0`; concurrent first sign-ins can race without a database-enforced bootstrap lock.
- Sessions are stored as plaintext bearer values. A database read compromise immediately becomes account compromise.
- Cohort delete and submission delete perform manual cascades. Without transactions, partial failure can leave records or GridFS objects inconsistent.
- Several update flows delete the old GridFS file before the new upload/database update succeeds, risking data loss on a mid-operation failure.
- Public IDs use truncated UUID hex in several domains. They are reasonably difficult to guess for normal use, but authorization must never depend on opacity.
- Library and template behavior reflects an organization-wide singleton deployment, not strong multi-tenancy. White-label settings are also global.

## Integration and operational assessment

### AI services

The product uses `emergentintegrations` for GPT-5.2, Whisper, and TTS. Prompts are detailed and curriculum-aware, but model/provider names are hard-coded throughout the monolith. There is no provider abstraction, request telemetry, token/cost accounting, content-safety layer, retry/backoff strategy, or circuit breaker visible in the repo.

Student-provided documents and text are embedded in prompts. Prompt injection from documents is not explicitly isolated from system instructions, and AI output is sometimes used directly in emails or stored as authoritative progress feedback. Add explicit untrusted-content delimiters, output schemas/validation, abuse monitoring, and human review for consequential outputs.

### Email

Resend is configured globally. Failures are usually logged and swallowed, which avoids breaking core requests but can leave users unaware that a notification was not delivered. There is no delivery-status persistence, retry queue, suppression handling, or webhook processing. The sender has a hard-coded fallback and the digest recipient is hard-coded.

### Thinkific

Read/sync endpoints are straightforward, but organization-wide course/enrollment endpoints are available to any instructor, even though cohort operations otherwise scope instructors. This may expose all Thinkific enrollment data to instructors outside their assigned cohorts. Confirm the intended policy and consider super-admin-only global listing.

### Deployment portability

`APP_BASE_URL` attempts to read `/app/frontend/.env` directly and falls back to a specific preview deployment. Invite flows separately trust the HTTP Origin header. This couples the app to the Emergent filesystem/runtime and can send incorrect links in other environments.

The `.emergent` metadata documents a platform image, but it is not a complete infrastructure definition. MongoDB, secrets, worker count, reverse proxy, TLS, storage backup, restore, logging, monitoring, alerting, and rollback are not reproducible from this repository.

## Testing and validation status

### Fresh checks performed for this assessment

| Check | Result |
|---|---|
| Parse all 51 Python files with `ast.parse` | Pass; zero syntax failures |
| Parse all 61 JSON iteration reports | Pass |
| Parse all 74 JUnit XML files | Pass |
| `git diff --check` before report creation | Pass |
| Duplicate FastAPI method/path declarations | None among 115 declarations |
| Frontend production build | Not runnable: `craco: command not found` because dependencies are absent |
| Backend pytest invocation | Not runnable: `No module named pytest` |
| Live API/database/browser tests | Deliberately not run; isolated test infrastructure is not provided |

### Historical evidence

- The repository has 667 backend `test_*` functions across 47 files.
- The 74 stored XML files represent 2,151 historical test executions, including 38 failures and 4 skips across the entire iterative history. Failures in this aggregate are expected to include issues later fixed; it is not a current-suite result.
- Recent named XML artifacts inspected for Venture Path, module overrides, video materials, GridFS, submission preview, submission types, super admin, downloads, material library, and related flows record zero failures.
- Iteration 61 reports 14/14 new backend checks and successful manual/Playwright UI verification for Venture Path module overrides, with one minor role-redirect toast issue.

### Test quality limitations

- Most backend tests are environment-coupled integration/regression scripts using `requests`, direct MongoDB access, seeded sessions, and a configured live/preview backend. They are not hermetic by default.
- Some tests import `server.py`, which immediately requires database environment variables and a large third-party dependency set.
- Test reports describe manual or Playwright frontend checks, but the repository contains no Playwright configuration/spec source or React unit tests.
- There is no single documented command for a clean full-suite run and no CI proof tied to commit `487a357`.
- Historical XML/JSON artifacts are useful evidence, but they can become stale and may contain operational data. CI artifacts should live outside Git with retention controls.

The correct present-tense conclusion is: **source syntax and report integrity pass; current runtime behavior is unverified from this clone**.

## Dependency and supply-chain assessment

### Backend

`backend/requirements.txt` pins 138 packages, mixing runtime, development, testing, cloud, AI, data-science, and transitive dependencies. Direct application imports cover a much smaller set. This environment snapshot increases image size, patch workload, resolver conflict risk, and vulnerability surface.

Separate runtime and development dependencies, declare only direct requirements, generate a deterministic lock with hashes, and automate vulnerability/license scanning. External system dependencies such as ffmpeg, Tesseract, and cron must also be versioned in infrastructure.

### Frontend

`package.json` uses semver ranges and a remote tarball dependency, but no lockfile exists. Two installs can therefore resolve different dependency trees. The HTML also loads remote JavaScript at runtime outside the npm build.

Commit the correct package-manager lockfile, use frozen installs in CI, pin/audit remote runtime scripts, add a restrictive Content Security Policy, and document the purpose/owner of analytics and Emergent tooling.

No online vulnerability database/audit was run during this review; package vulnerability status is therefore unknown rather than clean.

## Documentation status and drift

- Root `README.md` is only `# Here are your Instructions`; it does not identify the product or explain setup, architecture, environment, tests, or deployment.
- `frontend/README.md` is the uncustomized Create React App template.
- `memory/PRD.md` is valuable as a chronological delivery log, but it contains duplicated or superseded states. For example, the later assignment-dashboard implementation coexists with an earlier “NOT YET STARTED” section.
- The PRD's original 12-week schema differs from current configurable/default 14-week behavior.
- `.emergent/summary.txt` says the super-admin feature is in progress even though it is implemented and tested in current source.
- `test_result.md` contains only a testing-agent protocol/template, not a current repository status.
- Source comments and models retain some legacy terminology (`readiness_score`, material homework, instructor/student-only role comments) alongside current concepts.

Create a concise current-state product specification, an architecture decision record for the legacy/new submission transition, an API/deployment guide, and a generated changelog separate from the PRD.

## Maintainability priorities

### Recommended backend boundaries

Split `server.py` incrementally without behavior changes:

```text
backend/app/
├── main.py
├── config.py
├── db.py
├── auth/
├── cohorts/
├── materials/
├── assignments/
├── submissions/
├── coaching/
├── analytics/
├── support/
├── integrations/
│   ├── ai.py
│   ├── email.py
│   └── thinkific.py
├── workers/
└── common/
```

Move authorization into reusable resource-level policies rather than repeating manual checks. Add typed request/response schemas, repository/service layers, transactional cleanup patterns, and centralized error handling.

### Recommended frontend boundaries

- Create one configured API client and domain-specific API modules/hooks.
- Add explicit role-aware route guards while keeping backend checks authoritative.
- Split `AssignmentsTab`, `DirectSubmit`, `MaterialLibrary`, and large dashboards by stateful workflow.
- Remove or feature-flag legacy `StudentDashboard` after a migration decision.
- Add an error boundary, loading/error conventions, and request cancellation.
- Establish React Testing Library for components and Playwright/Cypress specs for high-value flows.

## Prioritized remediation plan

### P0 — Immediate containment before further production use

1. Rotate all credentials found in history/current docs and revoke every existing app session/magic link.
2. Remove the real credential document, committed uploads, and sensitive reports; rewrite Git history and replace affected clones.
3. Add cohort-manager checks to both Coach Max insight routes and both milestone context-document routes.
4. Verify Thinkific webhook signatures and replay protection, or disable the webhook until verification exists.
5. Authenticate/authorize audio downloads; remove the public debug route and secret/config details from health/public branding.
6. Disable PostHog session recording and third-party page capture until the token/privacy review is complete.
7. Add strict upload limits and gateway/application rate limits for AI, TTS, transcription, support, email, and digest actions.

### P1 — One-week production hardening

1. Implement one-time hashed magic-link exchange and stop accepting general session tokens in query strings.
2. Define explicit CORS origins, a Content Security Policy, security headers, and trusted-host/proxy configuration.
3. Escape all HTML email content and stop deriving email links from request headers.
4. Add author/admin rules to shared library mutations or document the intentionally trusted instructor model.
5. Create unique/compound/TTL MongoDB indexes and an idempotent migration system.
6. Commit environment templates, a frontend lockfile, deterministic Python dependencies, and a local Mongo/test bootstrap.
7. Add CI for secret scan, Python static checks, backend unit/integration suites, frontend lint/tests/build, dependency audit, and artifact publication.
8. Add security regression tests for cross-cohort access, webhook forgery, public audio/debug, magic-link replay, upload limits, and instructor data scope.

### P2 — Reliability and maintainability

1. Decompose `server.py` along domain boundaries.
2. Move AI review, transcription, TTS, email, and digest work to a durable queue with retries, idempotency, and observability.
3. Use a singleton scheduled job or external scheduler instead of one loop per web worker.
4. Add pagination, query/index profiling, bulk fetches, and explicit truncation metadata.
5. Add structured logs, correlation IDs, metrics, tracing, audit events, alerting, and a real readiness check.
6. Define data retention/deletion/export workflows and GridFS/audio orphan cleanup.
7. Consolidate legacy and assignment-based student flows and update current-state documentation.

### P3 — Product and platform polish

1. Complete accessibility and responsive-browser testing.
2. Make branding comprehensive, including metadata, email footer, digest recipient, landing copy, and year.
3. Add admin-visible job/delivery status for review, transcription, TTS, and email.
4. Add provider/model configuration, budgets, fallbacks, and per-tenant usage reporting.
5. Add backup/restore drills, retention policy, disaster recovery, and rollback documentation.

## Production release gate

Do not call the application production-ready until all of the following are true:

- [ ] All exposed credentials are rotated and Git history is cleaned.
- [ ] No real student/submission artifacts remain in source control.
- [ ] Cross-cohort authorization defects are fixed and covered by negative tests.
- [ ] Webhooks are authenticated and replay-safe.
- [ ] Magic links are one-time, short-lived, and not observable by analytics.
- [ ] Sensitive audio, prompts, debug data, and health details require correct access or are removed.
- [ ] Analytics/session recording has approved privacy controls and consent.
- [ ] Upload size/type controls, rate limits, and AI cost limits are enforced.
- [ ] A fresh clone can install, build, migrate, start, and run all tests from documented commands.
- [ ] CI passes backend tests, frontend tests/build, secret scan, and dependency checks at the release commit.
- [ ] MongoDB indexes, backups, retention, and cleanup are defined and tested.
- [ ] Background jobs are durable and weekly scheduling is singleton-safe.
- [ ] Monitoring, audit logs, alerting, and incident procedures are operational.

## Final assessment

Coach Max demonstrates strong product iteration and a thoughtful education workflow. The current source contains credible solutions to difficult problems—persistent file handling, cumulative AI context, multiple submission modalities, human review, direct Thinkific links, and progress visualization. The extensive regression history is a meaningful asset.

The same rapid iteration has accumulated production debt around security boundaries, secret handling, runtime reproducibility, data lifecycle, and architectural separation. The repository is best classified as a **feature-complete late prototype / internal beta that needs a focused hardening cycle**, not a production-ready system. Addressing the P0 and P1 items would materially change that assessment; feature expansion should pause until those gates are met.
