# Contributing to Coach Max

Coach Max uses GitHub issues and Project 7 as the source of truth for product work. Read [GitHub Project Governance](docs/GITHUB_PROJECT_GOVERNANCE.md) before starting a change.

## One-time local setup

Enable the repository's versioned Git hooks:

```bash
git config core.hooksPath .githooks
```

The commit-message hook applies the ticket convention to `CMX-*` branches.

## Start work

1. Select a leaf issue in `Ready`.
2. Confirm that its requirements, acceptance criteria, dependencies, estimate, and release fields are complete.
3. Create the ticket branch from `main`:

   ```bash
   ./scripts/start-ticket.sh CMX-142
   ```

4. Commit using the same ticket key:

   ```bash
   git commit -m "CMX-142: Add OIDC provider adapter"
   ```

5. Push the exact branch name:

   ```bash
   git push --set-upstream origin CMX-142
   ```

6. Open a pull request titled `CMX-142: <short summary>`.
7. Keep `Closes #142` in the PR body.
8. Resolve failed checks and review comments before squash merging.

## Pull-request expectations

- Keep one primary issue per pull request.
- Check every acceptance criterion or explain why it is not applicable.
- Include tests proportional to the change.
- Document configuration, data migration, security, and operational effects.
- Do not commit credentials, API keys, customer data, or local environment files.
- Use `Related to #142` for a non-final partial PR; only the final PR closes the issue.

## Protected branches

`main` requires pull requests and linear history, restricts deletion, and blocks force pushes. The required `ticket-policy` check verifies the relationship among the issue, branch, commits, and pull request.
