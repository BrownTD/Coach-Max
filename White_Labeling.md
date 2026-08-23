# Coach Max White-Label Product Implementation Plan

**Created:** 2026-08-22  
**Target product:** Managed, white-label Coach Max platform for licensed organizational customers  
**Recommended commercial model:** One-time onboarding fee plus annual subscription, included usage allowances, and paid add-ons  
**Initial deployment model:** Dedicated deployment and database per organization, designed from the beginning for eventual shared multi-tenancy

## 1. Objective

Transform the existing Coach Max application from a single-organization Emergent-hosted product into a repeatable, vendor-managed white-label platform that other organizations can license, configure, and operate under their own brand.

The resulting product should allow an organization to:

- Use its own name, domain, logo, colors, AI persona, terminology, and email identity.
- Create administrators, instructors, students, cohorts, assignments, templates, and rubrics.
- Operate independently with isolated data and credentials.
- Use Coach Max with or without Thinkific.
- Connect its own Thinkific site through an approved authorization flow.
- Receive continuous security, compatibility, and product updates.
- Select an AI/data option appropriate to its contractual and privacy requirements.
- View usage, plan limits, job status, and integration health.
- Export or delete its data according to an explicit retention policy.

The initial product should be sold as a hosted service. A self-hosted or perpetual-license edition should be treated as a future enterprise offering, not the default launch model.

## 2. Product and commercial decisions

### 2.1 Recommended offer

Sell a twelve-month license to a managed, white-label deployment with:

- A one-time implementation/onboarding fee.
- An annual platform subscription.
- A defined active-learner allowance.
- Included AI, transcription, and audio credits.
- Metered overages or credit top-ups.
- Standard maintenance and product updates included.
- Optional Thinkific, SSO, custom-domain, dedicated-infrastructure, and premium-support add-ons.

The license grants the customer a right to use the service during the subscription term. It does not transfer source ownership or responsibility for operating the platform.

### 2.2 Recommended billing unit

Use **active learners** as the primary capacity metric rather than total user accounts.

Suggested definition:

> An active learner is a student enrolled in at least one active cohort during the applicable billing period.

Supporting metrics should include:

- Active instructors.
- Active cohorts.
- AI-reviewed submissions.
- Coach Max questions.
- Vision/OCR document reviews.
- Transcription minutes.
- TTS/audio minutes.
- Email volume.
- Stored file volume.

Do not offer unlimited AI usage. Plans should include an understandable allowance, while the system tracks actual provider cost internally.

### 2.3 Suggested plan structure

| Capability | Launch | Professional | Enterprise |
|---|---|---|---|
| Intended customer | Small program | Established organization | Large or regulated organization |
| Branding | One brand | Full white label | Full white label and multiple brands if needed |
| Domain | Platform subdomain | Custom domain | Custom domain and advanced routing |
| Thinkific | Optional add-on | Included or add-on | Included with advanced support |
| AI allowance | Standard | Expanded | Contracted/custom |
| Deployment | Managed dedicated or shared-ready | Managed dedicated | Dedicated environment/database |
| Identity | Google/email | Google/Microsoft/OIDC | SAML/OIDC, domain controls, optional SCIM |
| Reporting | Standard | Advanced | Advanced plus export/audit access |
| Support | Standard | Priority | SLA and named support contact |
| Data controls | Standard retention | Configurable retention | Contractual retention/residency options |

Final prices and included allowances must be validated through pilot sales and observed unit economics.

### 2.4 Updates and release policy

For hosted customers:

- Security fixes are mandatory and included.
- Thinkific, identity-provider, browser, and AI compatibility updates are included.
- Bug fixes and standard product improvements are included.
- Premium modules are purchased and activated through entitlements rather than downloaded.
- Customer-specific development is scoped and billed separately.
- Database migrations are operated by the product team.
- Customers may choose an approved maintenance window or release channel, but cannot remain indefinitely on unsupported versions.

Do not build a downloadable paid-update store for the hosted edition. It would create version fragmentation and make integration, security, migration, and support work considerably harder.

## 3. Target architecture

### 3.1 Initial deployment topology

The fastest credible path is one managed application deployment per customer:

```text
Customer domain
    │
    ▼
Dedicated Coach Max web/API deployment
    ├── Dedicated MongoDB database and GridFS bucket
    ├── Customer-specific identity configuration
    ├── Customer-specific Thinkific connection
    ├── Customer-specific email domain/configuration
    ├── Customer-specific branding and policies
    ├── Vendor-managed or customer-owned AI connection
    └── Privacy-safe analytics configuration
```

This matches the current application's global platform-settings and shared-library assumptions while providing strong organizational isolation.

### 3.2 Future shared-SaaS topology

Even though the first version is dedicated per organization, add an explicit `organization_id` boundary now. This prevents another expensive redesign if the product later moves to a shared application/database model.

```text
Shared control plane
    ├── Organizations and subscriptions
    ├── Provisioning and domains
    ├── Entitlements and usage
    ├── Release management
    └── Support/operations

Tenant runtime
    ├── Organization context
    ├── Scoped users and data
    ├── Scoped integration credentials
    ├── Scoped branding and policies
    └── Scoped audit and usage records
```

### 3.3 Required domain boundaries

Refactor the backend incrementally into these domains:

```text
backend/app/
├── main.py
├── config.py
├── database.py
├── organizations/
├── identity/
├── cohorts/
├── materials/
├── assignments/
├── submissions/
├── coaching/
├── analytics/
├── integrations/
│   ├── ai/
│   ├── lms/
│   ├── email/
│   └── product_analytics/
├── billing/
├── audit/
├── jobs/
└── common/
```

The existing `backend/server.py` should remain behaviorally stable while routes and services are moved one domain at a time.

## 4. Organization and tenant model

### 4.1 New core records

Add the following data structures:

#### `organizations`

```text
organization_id
legal_name
display_name
slug
status: provisioning | trial | active | suspended | cancelled
deployment_mode: dedicated | shared
default_timezone
default_language
support_email
created_at
updated_at
```

#### `organization_memberships`

```text
membership_id
organization_id
user_id
role: organization_owner | organization_admin | instructor | student
status: invited | active | suspended
created_at
updated_at
```

#### `organization_settings`

```text
organization_id
branding
terminology
email_settings
ai_policy
retention_policy
feature_settings
default_cohort_settings
```

#### `domains`

```text
domain_id
organization_id
hostname
verification_status
certificate_status
is_primary
```

#### `integration_connections`

```text
connection_id
organization_id
provider
status
encrypted_credentials_reference
scopes
external_account_id
last_sync_at
last_error
created_at
updated_at
```

#### `subscriptions`

```text
subscription_id
organization_id
plan_id
status
term_start
term_end
billing_customer_id
renewal_type
```

#### `entitlements`

```text
organization_id
feature_key
limit
enabled
effective_from
effective_until
```

#### `usage_events`

```text
usage_event_id
organization_id
metric
quantity
source_record_id
provider_cost_estimate
occurred_at
idempotency_key
```

#### `audit_events`

```text
audit_event_id
organization_id
actor_user_id
action
resource_type
resource_id
metadata
ip_address
occurred_at
```

### 4.2 Scope existing collections

Add `organization_id` to:

- Users or organization memberships.
- Cohorts.
- Materials and library materials.
- Assignments and assignment templates.
- Rubrics.
- Submissions.
- Tutor chats.
- Audio cache.
- Support tickets.
- Thinkific progress/events.
- Platform/branding settings.

All database repository functions must require organization context. Queries by public ID alone should be prohibited at the repository/service boundary.

### 4.3 Role separation

Replace the overloaded `super_admin` concept with:

- **Platform operator:** Internal product-team access across deployments and organizations, tightly audited.
- **Organization owner:** Customer contract/primary administrator.
- **Organization admin:** Manages customer settings, instructors, integrations, and cohorts.
- **Instructor:** Manages assigned cohorts and reviews student work.
- **Student:** Accesses enrolled cohorts and their own submissions/feedback.

Platform-operator access should not be represented as an ordinary customer role and should require stronger authentication and audit controls.

## 5. White-label configuration

The existing branding system is a useful starting point but must become organization-scoped.

### 5.1 Branding settings

- Organization display name.
- Product name.
- AI persona name.
- Logo, favicon, and email logo.
- Primary/secondary/accent colors.
- Typography selection from an approved set.
- Login and landing-page copy.
- Email sender name and verified sending domain.
- Support contact and help URL.
- Privacy policy, terms, accessibility, and legal URLs.
- Custom domain.
- Default language and supported languages.
- Organization-specific terminology such as cohort/program/module/instructor.

### 5.2 AI policy settings

- AI persona/system instructions.
- Feedback tone and response structure.
- Enabled AI capabilities.
- Instructor review required versus automatic send.
- Allowed models/provider profile.
- Per-user and per-organization usage limits.
- Document vision permission.
- Audio transcription permission.
- TTS permission.
- Data-retention mode.
- Human escalation behavior.

### 5.3 Configuration rules

- Server-only settings, prompts, keys, and policies must never be returned from public branding endpoints.
- Branding assets must be validated and stored in controlled storage.
- Color and content settings need validation and safe defaults.
- Every email, PDF, browser title, support message, and generated link must use the organization configuration.
- Hard-coded Boost Pad, Coach Max, preview-domain, digest-recipient, and sender values must be removed from application logic.

## 6. Replace Emergent authentication

### 6.1 Target identity architecture

Introduce an identity-provider adapter based on standard OAuth 2.0/OpenID Connect concepts:

```text
IdentityProvider
├── authorize()
├── exchange_code()
├── refresh_session()
├── revoke_session()
├── get_user_profile()
└── validate_token()
```

The initial implementation should support:

- Google login.
- Microsoft login if target customers require it.
- Email invitation and secure one-time sign-in.
- OIDC/SAML for enterprise customers.
- Organization-domain restrictions.
- Organization-specific identity configuration.

### 6.2 Session model

- Use Secure, HttpOnly, SameSite cookies for browser sessions when deployment topology permits.
- Store session/refresh secrets hashed or encrypted, not as immediately reusable plaintext.
- Do not accept general session tokens through query strings.
- Use short-lived, single-use, atomically consumed invitation/magic-link nonces.
- Rotate sessions after authentication and privilege changes.
- Add organization and role claims to server-resolved request context.
- Support platform-wide revocation and per-user session revocation.

### 6.3 Authorization implementation

Create centralized policies:

```text
require_platform_operator
require_organization_member
require_organization_admin
require_instructor
require_cohort_manager
require_student_owner
```

Each route should resolve the resource and enforce organization plus resource-level access before performing queries or mutations.

### 6.4 Authentication acceptance criteria

- No runtime request depends on Emergent authentication endpoints.
- New users can join only through an approved organization flow.
- A user can belong to multiple organizations with separate roles.
- Organization administrators cannot access another organization's data.
- Platform-operator access is strongly authenticated and audited.
- Invitation and passwordless links are one-time and expire quickly.
- Authentication tests cover login, logout, expiry, revocation, role changes, cross-organization denial, and domain restrictions.

## 7. Replace Emergent AI services

### 7.1 AI provider abstraction

Create an internal interface instead of importing `emergentintegrations` throughout domain code:

```text
AIProvider
├── generate_feedback()
├── answer_tutor_question()
├── generate_insights()
├── transcribe_audio()
├── synthesize_speech()
├── extract_document_vision()
└── health_check()
```

Implement a direct OpenAI provider first, with the ability to add customer-owned or alternative providers later.

### 7.2 Credential models

Support two commercial modes:

#### Vendor-managed AI

- The platform owns provider credentials.
- Usage is metered by organization.
- Provider keys never reach the browser.
- The subscription includes an allowance and overage policy.
- Separate provider projects or equivalent controls should be used where practical.

#### Customer-owned AI

- Available as an enterprise option.
- Customer provides credentials through a secure secrets flow.
- Secrets are encrypted and referenced, never returned through normal APIs.
- Provider billing belongs to the customer.
- The platform still records feature usage for entitlement and support purposes.

### 7.3 AI request controls

- Record organization, feature, model, token/minute count, latency, result status, and cost estimate.
- Enforce organization and user budgets before requests.
- Use timeouts, retry rules, circuit breakers, and concurrency limits.
- Make background requests idempotent.
- Validate structured outputs before storing them.
- Delimit student documents and messages as untrusted content in prompts.
- Preserve instructor review for consequential feedback unless the organization explicitly enables automatic send.
- Provide a clear customer-facing explanation of provider data handling and retention.

### 7.4 AI acceptance criteria

- No production code imports Emergent AI libraries.
- Every AI request produces one idempotent usage event.
- Monthly limits and overages can be enforced per organization.
- Failed jobs are retried safely and visible to administrators.
- Vendor-managed and customer-owned credentials pass the same contract tests.
- Provider/model changes do not require changes to submission-domain routes.

OpenAI's official documentation should be used when finalizing data controls and customer commitments: [OpenAI API data controls](https://developers.openai.com/api/docs/guides/your-data).

## 8. Thinkific integration

Thinkific should be an optional LMS connector. Coach Max must operate standalone when no LMS is connected.

### 8.1 Connector abstraction

```text
LMSConnector
├── connect()
├── disconnect()
├── validate_connection()
├── list_courses()
├── list_enrollments()
├── sync_students()
├── refresh_progress()
├── register_webhooks()
├── remove_webhooks()
└── process_event()
```

Implement:

- `StandaloneConnector` for manual/CSV operation.
- `ThinkificConnector` for connected customers.
- A stable interface for future Canvas, Moodle, Kajabi, or other connectors.

### 8.2 Pilot/private integration

For early private customers, support a customer-generated Thinkific API access token and subdomain if permitted by the customer's plan and use case.

Requirements:

- Customer enters the token through a secure server-side form.
- Credentials are encrypted and scoped to the organization.
- Connection health and expiry are visible to the organization admin.
- The UI supports credential replacement without developer involvement.
- Synchronization is explicit, observable, and idempotent.

Thinkific describes API access tokens as appropriate for private or one-off integrations: [Thinkific API access tokens](https://support.thinkific.com/hc/en-us/articles/360052415534-How-to-Create-API-Access-Tokens).

### 8.3 Scalable/public integration

For a distributable Thinkific app:

1. Ask for the customer's Thinkific subdomain.
2. Redirect the organization admin through Thinkific OAuth.
3. Exchange the authorization code server-side.
4. Encrypt and store tokens under the organization connection.
5. Request only the scopes required for courses, users, enrollments, progress, and webhooks.
6. Register organization-specific webhooks.
7. Map external site, course, enrollment, and user identifiers to the organization.
8. Refresh credentials securely.
9. Remove webhooks and revoke/disable the connection on uninstall.
10. Stop synchronization without disabling standalone Coach Max functionality.

References:

- [Thinkific OAuth](https://developers.thinkific.com/api/oauth/)
- [Thinkific app scopes and information security](https://support.thinkific.com/hc/en-us/articles/4791175034647-Apps-and-Information-Security)

### 8.4 Webhook handling

- Authenticate webhook deliveries using the mechanism supported by the finalized Thinkific app configuration.
- Use organization-specific connection/webhook identifiers.
- Persist delivery IDs and reject replays.
- Validate event type and schema.
- Treat payloads as notifications and re-fetch canonical data when appropriate.
- Process events through a durable queue.
- Expose delivery failures and last successful event time.
- Ensure one organization's event cannot resolve to another organization's users or courses.

### 8.5 Thinkific acceptance criteria

- An organization admin can connect and disconnect without developer access.
- Credentials are never global environment variables.
- Two organizations can connect different Thinkific sites without data crossover.
- Uninstall immediately stops access and webhook processing.
- Resynchronization is idempotent.
- The application remains usable without Thinkific.

## 9. PostHog and product analytics

PostHog should be configurable and privacy-safe, not hard-coded into the HTML.

### 9.1 Recommended launch configuration

- Use event analytics only.
- Disable session replay by default.
- Do not capture document content, feedback, Coach Max conversations, support transcripts, student names, or email addresses.
- Use privacy-preserving user identifiers.
- Attach `organization_id`, plan, role, and deployment version to approved operational/product events.
- Strip query strings and sensitive URL fragments before analytics initialization.
- Load analytics only after consent where required.
- Allow analytics to be disabled per organization.

### 9.2 Analytics ownership options

Support one or more of:

- Vendor-owned PostHog project with strict event schema and tenant filtering.
- Separate PostHog project per customer.
- Customer-owned PostHog project key.
- No analytics for enterprise customers.

The PostHog client key should be configuration, not committed directly in `index.html`.

### 9.3 Event taxonomy

Approved examples:

```text
organization_onboarding_completed
integration_connected
integration_sync_completed
integration_sync_failed
cohort_created
instructor_invited
assignment_published
submission_received
ai_review_completed
ai_review_failed
feedback_sent
support_ticket_created
usage_limit_warning
```

Prohibited properties include student answers, uploaded text, chat content, raw feedback, credentials, and authentication tokens.

### 9.4 Session replay policy

If session replay is introduced later:

- Require an approved privacy assessment.
- Mask all inputs and displayed text by default.
- Exclude submission, feedback, chat, progress, identity, support, and admin-sensitive screens.
- Redact all query strings.
- Publish retention and access policies.
- Audit which employees can view recordings.

PostHog notes that ordinary page text is not masked by default and that page URLs/query strings require explicit redaction: [PostHog session replay privacy controls](https://posthog.com/docs/session-replay/privacy).

## 10. Email and communications

Create an `EmailProvider` abstraction and organization-specific email configuration.

Requirements:

- Vendor-managed Resend account for standard plans.
- Verified sending domain or approved platform subdomain per organization.
- Optional customer-owned provider for enterprise customers.
- Organization branding and support details in every message.
- Auto-escaped email templates.
- Persisted delivery request/status records.
- Retry queue for transient failures.
- Bounce, complaint, and suppression handling.
- Organization-configurable notification recipients.
- No hard-coded digest recipient.
- User notification preferences where appropriate.

Track email usage as a billable/operational metric even if it is not initially exposed as an overage.

## 11. Onboarding and organization administration

### 11.1 Provisioning workflow

```text
Signed contract or checkout
    → Create subscription/customer
    → Create organization record
    → Provision deployment/database/secrets
    → Configure domain and TLS
    → Invite organization owner
    → Complete branding wizard
    → Verify email domain
    → Connect identity provider
    → Connect Thinkific or choose standalone
    → Import curriculum/users
    → Configure AI policy and allowance
    → Run readiness checks
    → Launch pilot cohort
```

### 11.2 Onboarding wizard

The organization owner should be guided through:

1. Organization profile.
2. Branding and terminology.
3. Domain setup.
4. Email setup.
5. Administrator and instructor invitations.
6. Thinkific connection or standalone selection.
7. Course/cohort mapping.
8. Curriculum, assignment-template, and rubric import.
9. AI policy and feedback approval mode.
10. Data retention and privacy settings.
11. Test student and sample submission.
12. Launch-readiness review.

### 11.3 Admin console

Organization administrators need pages for:

- Subscription and plan usage.
- Members and roles.
- Branding/domain status.
- Integration connections and sync health.
- AI usage and limits.
- Email-domain/delivery health.
- Background-job status.
- Audit log.
- Data export and retention controls.
- Support and escalation.
- Release channel/version information.

## 12. Entitlements, metering, and billing

### 12.1 Entitlement service

Features should be controlled server-side through entitlements, not hidden only in the UI.

Example feature keys:

```text
thinkific_connector
custom_domain
custom_email_domain
ai_review
coach_chat
vision_extraction
audio_transcription
tts_feedback
auto_send_feedback
advanced_analytics
assignment_templates
api_access
sso
audit_export
dedicated_deployment
customer_owned_ai
```

### 12.2 Usage ledger

Every billable operation should write exactly one idempotent usage event. Provider calls should not be made if the applicable entitlement is disabled or the hard limit is exhausted.

Required views:

- Current billing-period usage.
- Included allowance.
- Remaining allowance.
- Soft-limit warnings.
- Hard-limit behavior.
- Estimated overage.
- Provider cost versus customer revenue.

### 12.3 Billing behavior

- Prefer annual B2B contracts, billed annually or quarterly.
- Support a limited paid pilot that converts to an annual agreement.
- Charge onboarding separately from subscription.
- Include predictable allowances.
- Notify organization admins before overage thresholds.
- Provide configurable hard caps where feasible.
- Suspend premium consumption safely without deleting customer data.
- Keep infrastructure and AI gross margin visible internally per organization.

### 12.4 Premium modules

Premium capabilities should be activated through subscription changes and entitlement updates. They should not require customers to download code.

Examples:

- Thinkific integration.
- Advanced Coach Max insights.
- SSO.
- Dedicated infrastructure.
- Additional brands.
- Extended retention.
- Custom reporting.
- Customer-owned AI.

## 13. Background jobs and operations

Replace detached in-process tasks and per-worker scheduling with durable infrastructure.

### 13.1 Required job types

- AI feedback generation.
- Document vision extraction.
- Audio/video transcription.
- TTS generation.
- Email delivery.
- Thinkific synchronization.
- Webhook processing.
- Weekly digest generation.
- Data export/deletion.
- GridFS orphan cleanup.
- Usage aggregation and invoice preparation.

### 13.2 Job requirements

- Durable queue.
- Idempotency key.
- Organization context.
- Explicit retry policy.
- Dead-letter/failure state.
- Customer-visible status where relevant.
- Structured logs and trace/correlation IDs.
- Concurrency and rate limits.
- Cancellation when an organization is suspended or disconnected.

### 13.3 Operational capabilities

- Health, readiness, and dependency checks.
- Central logs and alerts.
- Per-organization audit trail.
- Backups and restore drills.
- Deployment rollback.
- Database migration status.
- Provider outage handling.
- Usage/cost anomaly alerts.
- Domain/certificate renewal monitoring.
- Integration-token expiry monitoring.

## 14. Release and update system

### 14.1 Versioning

- Use semantic or date-based release versions consistently.
- Record the application and database-schema version for every deployment.
- Maintain release notes and migration notes.
- Tag production releases in Git.
- Produce reproducible build artifacts from CI.

### 14.2 Release channels

- `pilot`: earliest customer validation.
- `stable`: default supported production channel.
- `enterprise-stable`: optional delayed channel for contracted change controls.

### 14.3 Deployment behavior

- Automated pre-deployment backup/check.
- Forward and rollback migration plan.
- Staged rollout to internal/demo, pilot, then production customers.
- Automated smoke tests after deployment.
- Roll back automatically or manually on failed health checks.
- Customer-visible maintenance notice for disruptive changes.

### 14.4 Support policy

- Define the currently supported release range.
- Mandatory security/integration updates may override normal scheduling.
- Customer customizations must be configuration or supported extensions, not forks.
- Avoid maintaining customer-specific source branches.

## 15. Testing strategy

### 15.1 Test layers

#### Unit tests

- Organization scoping.
- Entitlement rules.
- Usage calculations.
- Prompt/output transformations.
- Connector mappings.
- Retention rules.

#### Integration tests

- Identity provider.
- MongoDB/GridFS.
- AI provider contract.
- Thinkific OAuth/sync/webhook lifecycle.
- Email provider.
- Billing provider.
- Queue workers.

#### End-to-end tests

- Organization provisioning.
- Owner onboarding.
- White-label domain and branding.
- Instructor/student invitations.
- Thinkific connection and sync.
- Assignment submission through feedback delivery.
- Usage limit and overage behavior.
- Cross-organization denial.
- Upgrade/migration and rollback.
- Organization cancellation/export/deletion.

### 15.2 Required tenant-isolation tests

For every organization-owned resource:

- Organization A can access its resource.
- Organization B receives a denial even with a valid ID from A.
- Platform operators require explicit audited access.
- Background jobs cannot resolve records outside their organization.
- Webhooks cannot cross tenant boundaries.
- Analytics and support exports contain only the selected organization.

### 15.3 CI release gate

A release cannot ship unless CI passes:

- Secret scan.
- Dependency and license scan.
- Python lint/type/static checks.
- Backend unit and integration tests.
- Frontend lint, unit tests, and production build.
- End-to-end critical-path tests.
- Tenant-isolation suite.
- Database migration tests.
- Infrastructure validation.
- Build artifact signing/checksum generation.

## 16. Documentation and legal deliverables

### Customer-facing

- Product overview and plan comparison.
- Organization-owner onboarding guide.
- Instructor and student guides.
- Thinkific connection guide.
- Data-processing and AI disclosure.
- Privacy policy and Terms of Service.
- Support policy and SLA where applicable.
- Release/update policy.
- Data export/deletion procedure.
- Subprocessor list.

### Internal

- Architecture and data-flow diagrams.
- Environment and secret inventory.
- Deployment/provisioning runbook.
- Incident-response plan.
- Backup/restore runbook.
- Customer offboarding runbook.
- Integration troubleshooting guides.
- AI usage and cost model.
- Support escalation matrix.

### Commercial/IP

- Confirm ownership and commercialization rights for all code and generated assets.
- Add a software bill of materials.
- Review and record third-party dependency licenses.
- Replace or properly license external imagery and fonts.
- Define the customer license agreement.
- Define onboarding statement of work templates.
- Define DPA, SLA, acceptable-use, and AI-specific contract terms.

## 17. Implementation phases

The phases below are ordered by dependency. Feature expansion should pause until the platform foundations are in place.

### Phase 0 — Product decisions and baseline

Deliverables:

- Approve hosted annual-subscription model.
- Define initial customer profile and active-learner metric.
- Define dedicated-deployment baseline.
- Inventory current integrations, costs, and data flows.
- Freeze and tag a known application baseline.
- Create architecture decision records for tenancy, identity, AI, billing, and deployment.
- Establish reproducible local development and CI.

Exit criteria:

- The product, commercial, and deployment models are documented and approved.
- A fresh clone can build and run automated tests.
- The initial pilot scope is fixed.

### Phase 1 — Organization boundary and configuration

Deliverables:

- Organizations, memberships, domains, settings, integrations, subscriptions, entitlements, usage, and audit models.
- `organization_id` added to existing resources.
- Organization context middleware/dependency.
- Central resource-level authorization policies.
- Organization-scoped branding and server-only AI policy.
- Removal of hard-coded branding, URLs, recipients, and global integration credentials.

Exit criteria:

- Two seeded organizations can operate without data crossover.
- Tenant-isolation tests cover all existing resource domains.
- A deployment can be fully branded through configuration.

### Phase 2 — Identity replacement

Deliverables:

- Standard identity-provider adapter.
- Google/email flow and enterprise-ready OIDC/SAML boundary.
- Organization invitations and memberships.
- Secure session and one-time-link implementation.
- Platform-operator separation and audit.

Exit criteria:

- Emergent authentication is removed.
- Organization onboarding and role management work end to end.
- Session and cross-organization security tests pass.

### Phase 3 — AI replacement and metering

Deliverables:

- Direct AI provider adapter.
- Feedback, tutor, vision, transcription, TTS, and insights migrated.
- Usage ledger and organization budgets.
- Vendor-managed AI mode.
- Optional customer-owned AI credential mode.
- Durable AI job processing.

Exit criteria:

- Emergent AI services are removed.
- All AI workflows retain functional parity.
- Usage and cost are attributable to an organization.
- Limits and failure handling are verified.

### Phase 4 — Integration productization

Deliverables:

- LMS connector interface and standalone connector.
- Thinkific private-token pilot connection.
- Thinkific OAuth application path.
- Secure webhook and sync processing.
- Email provider abstraction and verified-domain workflow.
- Configurable, event-only PostHog integration with replay disabled.

Exit criteria:

- Organizations connect/disconnect integrations without engineering access.
- Integration credentials are tenant-scoped and encrypted.
- Standalone operation works without Thinkific or PostHog.

### Phase 5 — Onboarding, plans, and billing

Deliverables:

- Organization-owner onboarding wizard.
- Subscription, plan, and entitlement enforcement.
- Usage dashboard and warnings.
- Billing/customer integration.
- Paid pilot conversion flow.
- Premium add-on activation.

Exit criteria:

- A new organization can progress from contract/checkout to pilot without manual database changes.
- Limits are enforced server-side.
- Usage and expected invoice inputs reconcile.

### Phase 6 — Operations and managed updates

Deliverables:

- Deployment provisioning automation.
- Durable workers and singleton scheduling.
- Release channels and migration automation.
- Health/readiness, monitoring, alerts, and audit.
- Backup, restore, rollback, and offboarding workflows.
- Support runbooks and administrator job visibility.

Exit criteria:

- A new dedicated customer environment can be provisioned repeatably.
- Upgrade and rollback are tested on production-like data.
- Provider/job failures are observable and recoverable.

### Phase 7 — Pilot program

Run two or three design-partner organizations through:

- Contract and onboarding.
- Branding and domain setup.
- Identity setup.
- Thinkific or standalone setup.
- Curriculum migration.
- Instructor training.
- A real pilot cohort.
- Usage/margin review.
- Support-volume review.
- Renewal and willingness-to-pay interview.

Exit criteria:

- At least one full cohort completes the submission-to-feedback lifecycle.
- No tenant-isolation incident occurs.
- Unit economics and support effort are understood.
- Pricing and onboarding scope are revised from observed data.
- Customers confirm measurable value and renewal intent.

### Phase 8 — General availability

Deliverables:

- Final plan/pricing pages.
- Standard contract, DPA, SLA, and onboarding SOW.
- Customer documentation and support portal.
- Production release process.
- Sales demo and trial/pilot environment.
- Capacity and incident planning.

Exit criteria:

- All launch gates in Section 19 pass.
- Provisioning and onboarding can be repeated without bespoke engineering.
- Support, billing, renewals, and offboarding have assigned owners.

## 18. Initial engineering backlog

### P0 — Foundation

- Create organization and membership models.
- Add organization request context.
- Add tenant-scoped repositories and isolation tests.
- Move branding to organization settings.
- Create environment/configuration system.
- Replace hard-coded URLs, names, senders, and recipients.
- Establish lockfiles, test environment, and CI.

### P1 — Provider decoupling

- Define identity-provider interface.
- Define AI-provider interface.
- Define LMS-connector interface.
- Define email-provider interface.
- Define analytics-provider interface.
- Move existing integration calls behind adapters.

### P2 — Commercial controls

- Add plan and entitlement service.
- Add usage-event ledger.
- Add organization-admin usage dashboard.
- Implement subscription lifecycle states.
- Add billing integration and overage handling.

### P3 — Product onboarding

- Build provisioning workflow.
- Build organization onboarding wizard.
- Build domain/email verification.
- Build integration health pages.
- Build sample-cohort/readiness test.

### P4 — Operations

- Add durable job queue/workers.
- Add release/migration automation.
- Add monitoring, audit, backup, restore, and rollback.
- Add organization export, retention, deletion, and offboarding.

## 19. Launch gates

The white-label product is ready for paid pilot only when:

- [ ] Customer data and credentials are isolated by organization/deployment.
- [ ] The application contains no Emergent auth or AI runtime dependency.
- [ ] Standard identity login, invitation, logout, expiry, and revocation work.
- [ ] Direct AI functionality covers review, chat, vision, transcription, insights, and TTS.
- [ ] AI usage is metered and enforceable per organization.
- [ ] All branding and generated links come from organization configuration.
- [ ] Thinkific is optional and credentials are organization-scoped.
- [ ] PostHog replay is disabled and event capture follows an approved schema.
- [ ] Email domains, templates, delivery tracking, and organization branding work.
- [ ] Provisioning does not require manual database edits.
- [ ] Plans and entitlements are enforced server-side.
- [ ] Background jobs are durable, observable, and idempotent.
- [ ] CI proves build, tests, migrations, tenant isolation, and production bundle.
- [ ] Backup, restore, upgrade, rollback, export, and offboarding are tested.
- [ ] Customer agreements, privacy disclosures, subprocessor list, and support policy are ready.

General availability additionally requires:

- [ ] Successful design-partner cohort completion.
- [ ] Validated pricing and AI/infrastructure margins.
- [ ] Repeatable customer onboarding.
- [ ] Defined release/support ownership.
- [ ] Monitoring and incident-response coverage.
- [ ] Renewal intent from pilot customers.

## 20. Major risks and mitigations

| Risk | Mitigation |
|---|---|
| Customer-specific source forks | Make customization configuration-driven; prohibit unsupported forks. |
| AI cost volatility | Meter every call, include allowances, set limits, support provider/model configuration. |
| Dedicated-deployment overhead | Automate provisioning, configuration, migrations, monitoring, and releases. |
| Thinkific API/app changes | Isolate behind a connector, include compatibility updates, monitor health/changelog. |
| Identity-provider lock-in | Use standard OIDC/SAML concepts behind an adapter. |
| Cross-organization exposure | Organization-scoped repositories, authorization policies, and exhaustive isolation tests. |
| Version fragmentation | Managed release channels and a defined support window; no customer source branches. |
| Difficult onboarding | Wizard, templates, migration tools, readiness checks, and standardized SOW. |
| Unprofitable usage | Active-learner pricing plus AI credits, overages, and per-tenant cost reporting. |
| Privacy objections | Optional analytics, no replay by default, configurable retention, clear subprocessors and DPA. |
| Integration outage | Standalone core product, durable jobs, retries, health indicators, and graceful degradation. |

## 21. Success metrics

Track:

- Time from signed agreement to operational organization.
- Percentage of onboarding completed without engineering intervention.
- Instructor activation and weekly active instructors.
- Active learners and submission completion.
- Median submission-to-feedback time.
- AI review failure/retry rate.
- Thinkific synchronization success rate.
- Email delivery success rate.
- Support tickets per organization and active learner.
- Infrastructure and AI cost per active learner.
- Gross margin per organization.
- Pilot-to-annual conversion.
- Renewal and expansion rate.
- Deployment upgrade success and rollback rate.
- Security/privacy incidents and cross-tenant test failures.

## 22. Recommended immediate next actions

1. Approve the dedicated managed white-label model and annual subscription structure.
2. Identify two or three potential design-partner organizations and document their requirements.
3. Define the initial active-learner allowance and AI credit vocabulary.
4. Create architecture decisions for organization tenancy, identity provider, direct AI provider, billing provider, job queue, and deployment platform.
5. Establish a reproducible build/test/CI baseline before refactoring.
6. Implement the organization boundary and isolation tests first.
7. Replace Emergent authentication.
8. Replace Emergent AI services and introduce usage metering.
9. Productize Thinkific, email, and analytics connections.
10. Build onboarding, entitlements, provisioning, and managed releases.
11. Launch a tightly controlled paid pilot before committing to shared multi-tenancy.

## Final recommendation

Coach Max should launch as a **managed annual-subscription white-label product with a one-time onboarding fee**, not as a one-time downloadable platform purchase.

Dedicated customer deployments provide the fastest path from the existing architecture to credible organizational licensing. Adding an organization boundary now preserves the option to consolidate deployments into a shared SaaS platform later. Emergent authentication and AI should be replaced through standards-based provider adapters, while Thinkific, PostHog, email, and future integrations should become optional, organization-scoped connectors.

The commercial and technical strategy should remain aligned: recurring operating costs are covered by recurring revenue; usage-heavy services are metered; standard updates are centrally managed and included; premium capabilities are activated through entitlements; and bespoke customer needs are delivered through configuration or paid services rather than customer-specific forks.
