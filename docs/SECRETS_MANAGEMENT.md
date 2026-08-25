# Coach Max secrets management

This runbook defines the CMX-167 runtime secret boundary. Infisical is the
approved source of truth, while Coach Max consumes ordinary environment
variables through `backend/config.py`. Never put a secret value, access token,
customer identifier, private scan result, or provider screenshot in this file,
GitHub, application logs, shell history, or test output.

## Approved structure

Create one Infisical organization owned by BrownTD and one secret-management
project named `coach-max`. Create these environments and slugs:

| Environment | Slug | Purpose | Human access |
|---|---|---|---|
| `development` | `dev` | Local development and synthetic integration testing | BrownTD administrator |
| `staging` | `staging` | Preproduction validation with nonproduction provider accounts | BrownTD administrator; staging workload read-only |
| `production` | `prod` | Paid-pilot and production workloads | BrownTD administrator for approval; production workload read-only |

Store the current runtime contract at the environment root. Add folders later
only when separate services need distinct access; do not duplicate a shared
credential merely to create a folder layout. Customer-specific credentials must
eventually be deployment- or organization-scoped instead of shared globally.

## Current runtime contract

Names are stable interfaces. Secret values differ in every environment and must
be newly issued under BrownTD control. `Required` means the process must have the
name to start; optional providers fail only when that capability is invoked.

| Name | Classification | Required | Owner | Disposition |
|---|---|---:|---|---|
| `APP_ENV` | Server configuration | Yes | Operations | `development`, `staging`, or `production`; supplied by the runtime wrapper |
| `MONGO_URL` | Database credential/connection string | Yes | Operations | New least-privilege database user per environment |
| `DB_NAME` | Server configuration | Yes | Operations | Separate database per environment |
| `APP_BASE_URL` | Server configuration | Yes outside development | Operations | Explicit HTTPS application URL |
| `CORS_ORIGINS` | Server security policy | Yes outside development | Operations | Explicit comma-separated HTTPS origins; wildcard prohibited |
| `SUPER_ADMIN_EMAIL` | Server-only personal/configuration data | No | Identity owner | Temporary bootstrap setting; replace with governed platform-operator provisioning |
| `RESEND_API_KEY` | Email provider credential | No | Integrations owner | New restricted key per environment when email is enabled |
| `SENDER_EMAIL` | Server-only provider configuration | No | Integrations owner | Verified sender for the corresponding environment |
| `NOTIFICATION_EMAIL` | Server-only personal/configuration data | No | Operations | Environment-specific operational recipient |
| `EMERGENT_LLM_KEY` | Legacy AI credential | No | AI owner | Never migrate an inherited value; provision only a new temporary nonproduction value if legacy AI validation is unavoidable, then retire through AI replacement work |
| `THINKIFIC_API_KEY` | Retired integration credential | No | Integrations owner | Do not provision in new environments; remove with Thinkific retirement |
| `THINKIFIC_SUBDOMAIN` | Retired server configuration | No | Integrations owner | Leave unset in new environments |

Future provider work must add its provider-neutral name here before use. Expected
classes include identity client secrets, AI provider credentials, Resend/email,
Cloudflare Stream, PostHog server-side ingestion if adopted, billing/webhook
secrets, object storage, deployment credentials, and signing/encryption keys.
Frontend `REACT_APP_*` values are public build-time configuration and must never
hold any of those classes.

`PROJECT_TOKEN` is repository-governance automation, not an application runtime
secret. It remains in GitHub Actions until a separately tested Infisical-to-GitHub
sync replaces it without breaking Project automation.

## Access model

Use distinct identities for distinct trust boundaries:

- `coach-max-github-dev`, `coach-max-github-staging`, and
  `coach-max-github-production`: OIDC-authenticated GitHub Actions identities with
  read-only access to only their matching environment. Restrict the subject to
  `BrownTD/Coach-Max` and the matching GitHub Environment; avoid wildcard claims.
- One runtime identity per deployed environment. Prefer the deployment platform's
  native workload authentication. If unavailable, use Universal Auth with a
  short-lived client secret stored only in that platform's protected secret
  facility; it is the unavoidable bootstrap credential, never an app variable.
- Human administrators may create, replace, and revoke secrets. Human access is
  never shared with a workload, and production access should require MFA and an
  approval/review record.
- Development identities have no staging or production access. Staging identities
  have no production access. CI validation receives read-only access and cannot
  create or reveal secrets through artifacts.

In GitHub, create protected Environments named `dev`, `staging`, and `prod`.
Define `INFISICAL_IDENTITY_ID` and `INFISICAL_PROJECT_SLUG` as environment
**variables**, not secrets; both are non-secret identifiers. Do not store a
long-lived Infisical client secret in GitHub. The manual `Infisical Smoke Test`
workflow uses GitHub OIDC to obtain short-lived access.

## Local development

Install the Infisical CLI using its official package instructions, sign in as the
authorized human user, and run:

```bash
INFISICAL_PROJECT_ID=<non-secret-project-id> \
  ./scripts/run-with-infisical.sh development \
  uvicorn backend.server:app --reload
```

The project ID is not secret. Do not put a token in the command, run with shell
tracing, print the environment, or export Infisical data to a file. An ignored
`backend/.env` remains permitted for offline local work, but it must contain only
new development credentials and must never be copied into staging or production.

## Provisioning checklist

1. Create the organization, project, and three environments above.
2. Add the contract names with blank/synthetic development values first.
3. Issue a new least-privilege database user for each environment and record only
   provider-side evidence identifiers in the private administrative record.
4. Add optional provider credentials only when their feature is enabled. Do not
   add Thinkific credentials or inherited values from CMX-3.
5. Create environment-specific runtime machine identities with read-only access.
6. Create the three GitHub OIDC identities and restrict repository, environment,
   audience, and claims exactly.
7. Configure the non-secret GitHub Environment variables and required production
   reviewers, then run `Infisical Smoke Test` separately for each environment.
8. Start a clean nonproduction checkout with `run-with-infisical.sh`; remove its
   authenticated context and confirm configuration fails closed.
9. Replace one synthetic development value in Infisical and confirm the next
   process start consumes it without a source change or value appearing in logs.
10. Record date, operator, environment, identity, and provider confirmation IDs
    privately. Record only sanitized completion evidence in CMX-167.

## Rotation, revocation, and break glass

- Normal rotation: issue a second provider credential, store it in the matching
  Infisical environment, restart or redeploy consumers, validate service, then
  revoke the former credential. Roll back by restoring the previous reference
  only before revocation; never edit source code for rotation.
- Emergency revocation: disable the provider credential first, disable the
  affected Infisical identity, stop or isolate workloads if necessary, replace
  the value, redeploy, validate, and open a private incident record.
- Infisical bootstrap compromise: revoke the machine identity authentication
  method, rotate its bootstrap credential in the deployment platform, review
  Infisical audit events, then issue a new short-lived method.
- Break glass: BrownTD is the initial accountable owner. Use an MFA-protected human
  administrator only when workload access is unavailable. Record reason, scope,
  start/end time, actions, and revocation in the private administrative record.

Never place old and new values in tickets for comparison. Validation reports only
presence, successful authorization, denial, and sanitized provider evidence IDs.

## Downstream contract

Identity, AI, email, native LMS/video, analytics, billing, provisioning, and
deployment tickets must:

1. Add provider-neutral environment names and owners to this inventory.
2. Read them through `backend/config.py` or a later typed configuration module.
3. Keep provider SDKs out of configuration loading.
4. Keep every server-only name out of `frontend/.env.example` and public APIs.
5. Provision different values and least-privilege identities per environment.
6. Document rotation and failure behavior without values.

CMX-4 owns repository secret scanning and prevention policy. It should scan this
contract and examples but must not redefine Infisical environments, ownership, or
runtime delivery.

## References

- [Infisical CLI secret injection](https://infisical.com/docs/cli/commands/run)
- [Infisical machine identities](https://infisical.com/docs/documentation/platform/identities/machine-identities)
- [Infisical GitHub Actions OIDC integration](https://infisical.com/docs/integrations/cicd/githubactions)
- `docs/SECURITY_CONTAINMENT.md`
- `White_Labeling.md`
- `Repo_Status_2026-08-22.md`
