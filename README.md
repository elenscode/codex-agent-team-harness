# Codex Agent Team Harness

A one-file installer for a practical six-agent Codex development team.

It installs a supervisor-oriented workflow that moves through planning, contract design, parallel implementation, testing, and independent review.

## Team

| Agent | Responsibility | Access |
| --- | --- | --- |
| `planner` | Requirements, acceptance criteria, impact, sequence | Read-only |
| `architect` | Architecture, boundaries, API/data contracts | Read-only |
| `backend` | Backend implementation and tests | Workspace write |
| `frontend` | Frontend implementation and tests | Workspace write |
| `tester` | Independent validation and test code | Workspace write |
| `reviewer` | Correctness, security, regression review | Read-only |

The installer also adds one focused skill for each role and a root `AGENTS.md` that defines orchestration, ownership, handoffs, and completion gates.

## Install

Download or clone this repository, then run the installer from the target project:

```bash
bash /path/to/codex-agent-team-harness/bootstrap-codex-team.sh
```

Or specify the project explicitly:

```bash
bash bootstrap-codex-team.sh --target /path/to/my-project
```

The installer stops if any managed file already exists. Review the files first and use `--force` only when replacement is intentional:

```bash
bash bootstrap-codex-team.sh --target /path/to/my-project --force
```

## Generated structure

```text
my-project/
├── AGENTS.md
├── .codex/
│   └── agents/
│       ├── planner.toml
│       ├── architect.toml
│       ├── backend.toml
│       ├── frontend.toml
│       ├── tester.toml
│       └── reviewer.toml
└── .agents/
    └── skills/
        ├── requirements-to-spec/SKILL.md
        ├── api-contract/SKILL.md
        ├── fastapi-feature/SKILL.md
        ├── react-feature/SKILL.md
        ├── test-gate/SKILL.md
        └── code-review/SKILL.md
```

## Suggested prompt

```text
Analyze this feature with planner and architect first.
After the contracts are stable, run backend and frontend in parallel.
Then validate it with tester and perform a final independent review with reviewer.
```

Use only the agents needed for smaller changes. The root instructions explicitly avoid concurrent edits to the same files.

## Requirements

- Bash 4 or later
- Codex with project agents and skills support

## License

MIT
