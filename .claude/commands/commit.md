---
model: haiku
---

Analyze all modified and untracked files, group them logically, and create one or more conventional commits.

### Conventional Commits

**Format:** `<type>(<scope>): <description>`

#### Types

- feat: new feature
- fix: bug fix
- docs: documentation
- style: formatting, missing semicolons, etc.
- refactor: code change that neither fixes a bug nor adds a feature
- test: adding or correcting tests
- chore: maintenance tasks
- ci: continuous integration changes
- revert: reverts a previous commit

#### Scopes

Use one of these fixed scopes. Omit the scope only when a change spans too many areas to pick one.

| Scope | Covers |
|---|---|
| `terminal` | Floating terminal lifecycle (`terminal.lua`) |
| `config` | Configuration and defaults (`config.lua`) |
| `send` | Sending selections/references (`send.lua`) |
| `notify` | Notification handling (`notify.lua`) |
| `health` | Checkhealth provider (`health.lua`) |
| `types` | LuaCATS type definitions (`types.lua`) |
| `commands` | User commands in `plugin/claude.lua` |
| `hooks` | Shell hook script (`scripts/nvim-notify.sh`) |
| `tests` | Test files, helpers, and screenshots |
| `ci` | GitHub Actions workflows |
| `docs` | README, CLAUDE.md, and other documentation |
| `deps` | Rockspec, dependencies |

### Workflow

1. Run `git status` to see overall repository state. If there are no changes (staged or unstaged), exit.
2. Run `git diff` and `git diff --stat` to analyze all unstaged changes.
3. Run `git diff --staged` and `git diff --stat --staged` to analyze already staged changes.
4. Run `git log --oneline -10` to review recent commit patterns.
5. Group the changed files logically by scope/purpose. If all changes belong to the same logical unit, make a single commit. If changes span multiple unrelated scopes, split them into separate commits (e.g., a test change and a terminal feature change should be two commits).
6. For each logical group, in order:
   a. Stage only the files for that group with `git add <file1> <file2> ...`
   b. Write a concise commit message (72 chars max for first line). Include a body if the changes are complex.
   c. Create the commit.
7. After all commits, run `git log --oneline -5` to confirm the result.
