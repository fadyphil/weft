# Issue tracker: GitHub

Issues and specs for this repo live as GitHub issues in `fadyphil/weft`. Use the `gh` CLI for all operations.

The repo is public. File issues only into `fadyphil/weft`, never into an upstream parent.

## Conventions

- **Create an issue**: `gh issue create --title "..." --body "..."`. Use a heredoc for multi-line bodies.
- **Read an issue**: `gh issue view <number> --json number,title,body,labels,comments`.
- **List issues**: `gh issue list --state open --json number,title,body,labels,comments --jq '[.[] | {number, title, body, labels: [.labels[].name], comments: [.comments[].body]}]'` with appropriate `--label` and `--state` filters.
- **Parent link**: this repo runs `gh` 2.46, which predates native sub-issues. Put `Part of #<parent>` on the first line of the child body.
- **Blocking**: same version constraint. Put `Blocked by: #<n>, #<n>` on the first line of the child body. A ticket is unblocked when every blocker is closed.
- **Count open blockers**: `gh issue view <n> --json blockedBy --jq '[.blockedBy.nodes[] | select(.state == "OPEN")] | length'`, or count the `Blocked by:` line against `gh issue view <n> --json state`.
- **Comment on an issue**: `gh issue comment <number> --body "..."`
- **Apply / remove labels**: `gh issue edit <number> --add-label "..."` / `--remove-label "..."`
- **Close**: post the explanation with `gh issue comment <number> --body "..."`, then `gh issue close <number>`. On an already-closed issue, `gh issue close --comment` drops the comment and still exits 0.

Infer the repo from `git remote -v`; `gh` does this automatically when run inside a clone.

When `gh` reaches 2.94 or later, prefer the native form: `gh issue create --parent <n>`, `gh issue edit <n> --add-blocked-by <n>`. Do not use `gh api` to create sub-issues or dependency edges without Fady's approval (AGENTS.md §6).

## Pull requests as a triage surface

**PRs as a request surface: no.** _(Set to `yes` if this repo treats external PRs as feature requests; `/triage` reads this flag.)_

When set to `yes`, PRs run through the same labels and states as issues, using the `gh pr` equivalents:

- **Read a PR**: `gh pr view <number>`, then `gh pr view <number> --comments` (off a TTY, `--comments` prints only the comments, not the body), and `gh pr diff <number>` for the diff.
- **List external PRs for triage**: `gh api --paginate 'repos/{owner}/{repo}/pulls?state=open' --jq '.[] | select(.author_association | IN("OWNER","MEMBER","COLLABORATOR") | not) | {number, title, author: .user.login, author_association, labels: [.labels[].name]}'`.
- **Comment / label / close**: `gh pr comment`, `gh pr edit --add-label`/`--remove-label`, `gh pr close`.

GitHub shares one number space across issues and PRs, so a bare `#42` may be either: resolve with `gh pr view 42` and fall back to `gh issue view 42`.

## When a skill says "publish to the issue tracker"

Create a GitHub issue.

## When a skill says "fetch the relevant ticket"

Read it as in **Read an issue** above.

## Wayfinding

Deliberately omitted. `/wayfinder` is forbidden by AGENTS.md §4 and denied in `opencode.jsonc`. Do not add `wayfinder:*` labels, map issues, or `part of` task lists.
