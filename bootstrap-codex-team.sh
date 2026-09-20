#!/usr/bin/env bash
set -euo pipefail

# Codex six-agent project harness installer.
# Usage: bash bootstrap-codex-team.sh [--target DIR] [--force]

target="."
force=0

while (($#)); do
  case "$1" in
    --target) target="${2:?--target requires a directory}"; shift 2 ;;
    --force) force=1; shift ;;
    -h|--help)
      sed -n '2,4p' "$0"
      exit 0
      ;;
    *) printf 'Unknown option: %s\n' "$1" >&2; exit 2 ;;
  esac
done

mkdir -p "$target"
target="$(cd "$target" && pwd)"

files=(
  "AGENTS.md"
  ".codex/agents/planner.toml"
  ".codex/agents/architect.toml"
  ".codex/agents/backend.toml"
  ".codex/agents/frontend.toml"
  ".codex/agents/tester.toml"
  ".codex/agents/reviewer.toml"
  ".agents/skills/requirements-to-spec/SKILL.md"
  ".agents/skills/api-contract/SKILL.md"
  ".agents/skills/fastapi-feature/SKILL.md"
  ".agents/skills/react-feature/SKILL.md"
  ".agents/skills/test-gate/SKILL.md"
  ".agents/skills/code-review/SKILL.md"
)

if ((force == 0)); then
  conflicts=()
  for file in "${files[@]}"; do
    [[ -e "$target/$file" ]] && conflicts+=("$file")
  done
  if ((${#conflicts[@]})); then
    printf 'Stopped: these files already exist in %s:\n' "$target" >&2
    printf '  %s\n' "${conflicts[@]}" >&2
    printf 'Re-run with --force only if replacing them is intended.\n' >&2
    exit 1
  fi
fi

for file in "${files[@]}"; do
  mkdir -p "$(dirname "$target/$file")"
done

cat > "$target/AGENTS.md" <<'EOF'
# Project Agent Instructions

## Goal

Deliver production-quality full-stack changes through explicit planning, stable contracts, implementation, verification, and independent review.

## Orchestration

For a non-trivial feature:

1. Ask `planner` to turn the request into requirements, acceptance criteria, impact, and an implementation sequence.
2. Ask `architect` to inspect the repository and define the smallest viable design and stable contracts.
3. Reconcile conflicts and unresolved decisions before implementation.
4. Freeze API, data, and ownership contracts.
5. Run `backend` and `frontend` in parallel only when their file ownership is disjoint and the contracts are stable.
6. Ask `tester` to validate acceptance criteria and add appropriate tests.
7. Ask `reviewer` for an independent read-only review.
8. Route findings back to the owning implementer, re-run affected verification, and integrate the result.

For a localized bug fix, use the smallest useful subset: investigate, assign the owning implementer, then run `tester` and `reviewer` when risk justifies it.

The main agent owns decomposition, contract approval, conflict resolution, integration, and the final decision. Preserve user changes and repository conventions.

## Ownership

- `planner`: requirements and plan; read-only.
- `architect`: boundaries and contracts; read-only.
- `backend`: owns `backend/**`; may change backend tests.
- `frontend`: owns `frontend/**`; may change frontend tests.
- `tester`: owns test code; reports production defects to the parent.
- `reviewer`: independent read-only review; reports findings without fixing them.

If the repository uses different directories, infer ownership from its existing structure before delegation. Never assign two agents to edit the same files concurrently.

## Handoff contract

Every subagent returns:

- outcome: what it discovered or changed;
- files: affected paths, or `none`;
- verification: exact commands and results;
- risks: remaining uncertainty or regression risk;
- decisions: choices required from the parent, or `none`.

## Completion gate

A change is complete when all applicable acceptance criteria are met, contracts remain consistent, relevant checks pass, integration behavior is verified, and no unresolved critical reviewer finding remains. The final response must distinguish verified facts from unverified assumptions.
EOF

cat > "$target/.codex/agents/planner.toml" <<'EOF'
name = "planner"
description = "Analyzes non-trivial requests into requirements, acceptance criteria, impact, risks, and an implementation sequence before coding."
model_reasoning_effort = "high"
sandbox_mode = "read-only"

developer_instructions = """
Inspect the repository before planning. Separate explicit requirements from assumptions. Produce: requirements, current-system impact, acceptance criteria, implementation sequence, edge cases, risks, and unresolved decisions. Stay at the product and delivery-plan level; leave module boundaries and interfaces to the architect. Do not modify files. End with the project handoff contract from AGENTS.md.
"""
EOF

cat > "$target/.codex/agents/architect.toml" <<'EOF'
name = "architect"
description = "Defines minimal architecture, module boundaries, API/data contracts, failure behavior, and parallel-work boundaries before implementation."
model_reasoning_effort = "high"
sandbox_mode = "read-only"

developer_instructions = """
Inspect existing architecture and analogous features first. Design the smallest change that satisfies approved requirements. Specify module ownership, request/response and error contracts, domain/data changes, compatibility, failure handling, and which contracts must be stable before parallel work. Prefer repository patterns over new abstractions. Do not modify files. End with the project handoff contract from AGENTS.md.
"""
EOF

cat > "$target/.codex/agents/backend.toml" <<'EOF'
name = "backend"
description = "Implements approved backend work, especially Python, FastAPI, Pydantic, persistence, workers, and backend tests."
model_reasoning_effort = "medium"
sandbox_mode = "workspace-write"

developer_instructions = """
Implement only the approved backend scope and follow existing repository patterns. Keep domain logic out of transport handlers. Preserve approved API/data contracts; escalate contract changes to the parent. Own backend files and backend tests, and avoid frontend files. Add focused tests for changed behavior. Run the relevant tests, lint, and type checks that the repository provides. End with the project handoff contract from AGENTS.md.
"""
EOF

cat > "$target/.codex/agents/frontend.toml" <<'EOF'
name = "frontend"
description = "Implements approved React and TypeScript UI work against stable contracts and the existing design system."
model_reasoning_effort = "medium"
sandbox_mode = "workspace-write"

developer_instructions = """
Implement only the approved frontend scope. Follow the established design system, state patterns, accessibility conventions, and architect-approved API contract. Preserve existing UX unless the request changes it. Own frontend files and frontend tests, and avoid backend files. Run relevant tests, type checks, lint, and build. End with the project handoff contract from AGENTS.md.
"""
EOF

cat > "$target/.codex/agents/tester.toml" <<'EOF'
name = "tester"
description = "Independently validates acceptance criteria, edge cases, regressions, failure paths, and frontend/backend integration."
model_reasoning_effort = "medium"
sandbox_mode = "workspace-write"

developer_instructions = """
Validate implementation against explicit acceptance criteria. Reproduce defects and identify the responsible component. You may create or update test code, but report production-code defects to the parent rather than silently fixing them. Cover relevant unit, integration, API, UI, edge, and failure behavior without duplicating low-value tests. Report exact commands and results. End with the project handoff contract from AGENTS.md.
"""
EOF

cat > "$target/.codex/agents/reviewer.toml" <<'EOF'
name = "reviewer"
description = "Performs an independent read-only final review for correctness, security, integrity, concurrency, regressions, and missing tests."
model_reasoning_effort = "high"
sandbox_mode = "read-only"

developer_instructions = """
Review the completed diff and its surrounding code independently. Prioritize correctness, requirement violations, security, data integrity, concurrency, error handling, compatibility, regressions, missing tests, and unjustified complexity. Ignore cosmetic preferences unless they create material risk. For every finding provide severity, file or symbol, concrete failure scenario, evidence, and recommended direction. If there are no meaningful findings, say so explicitly. Do not modify files. End with the project handoff contract from AGENTS.md.
"""
EOF

cat > "$target/.agents/skills/requirements-to-spec/SKILL.md" <<'EOF'
---
name: requirements-to-spec
description: Convert a feature request or PRD into repository-grounded requirements, acceptance criteria, impact, risks, and an executable implementation plan before coding.
---

# Requirements to Spec

1. Inspect the request and the closest existing behavior in the repository.
2. Separate stated requirements, inferred constraints, assumptions, and open decisions.
3. Define testable acceptance criteria, including meaningful failure and edge behavior.
4. Identify affected components, dependencies, migrations, compatibility, and rollout risk.
5. Order implementation so contracts stabilize before dependent work begins.

Complete when every stated requirement maps to at least one acceptance criterion and each affected component has an owner or an explicit unresolved decision.
EOF

cat > "$target/.agents/skills/api-contract/SKILL.md" <<'EOF'
---
name: api-contract
description: Design or revise frontend/backend, service, or data contracts before independent implementations begin.
---

# API Contract

Inspect analogous contracts first. Define only the boundary needed by the approved requirements:

- operation and endpoint or callable interface;
- input fields, types, validation, and defaults;
- success output and observable side effects;
- error taxonomy, status mapping, and retry/idempotency behavior;
- authorization and compatibility constraints;
- ownership and generated/shared type strategy.

Complete when backend, frontend, and tests can implement independently without inventing boundary behavior.
EOF

cat > "$target/.agents/skills/fastapi-feature/SKILL.md" <<'EOF'
---
name: fastapi-feature
description: Implement a FastAPI backend feature using the repository's established layering, schemas, persistence, worker, and test conventions.
---

# FastAPI Feature

1. Find the closest analogous feature and reuse its structure.
2. Confirm the approved contract and affected domain boundary.
3. Implement business behavior in the repository's application/domain layer.
4. Add or update schemas, persistence, integrations, and routes at their existing boundaries.
5. Add focused unit and integration tests for success, validation, and material failure paths.
6. Run configured backend tests, lint, and type checks.

Complete when changed behavior is verified and every contract deviation has been escalated rather than silently introduced.
EOF

cat > "$target/.agents/skills/react-feature/SKILL.md" <<'EOF'
---
name: react-feature
description: Implement a React and TypeScript feature against an approved API contract and the repository's existing UI and testing conventions.
---

# React Feature

1. Find analogous screens, components, hooks, and data access.
2. Confirm the approved contract and all loading, empty, success, and error states.
3. Reuse design-system components and established state patterns.
4. Implement accessible interaction and responsive behavior appropriate to the existing product.
5. Add focused component or integration tests for changed behavior.
6. Run configured tests, type checks, lint, and build.

Complete when every acceptance state is represented and the implementation invents no server behavior.
EOF

cat > "$target/.agents/skills/test-gate/SKILL.md" <<'EOF'
---
name: test-gate
description: Verify a completed change against acceptance criteria and regression risk, adding test code while keeping production fixes with the owning implementer.
---

# Test Gate

Build a requirement-to-test matrix. Run the narrowest deterministic checks first, then the integration checks needed for cross-boundary behavior. Cover success, validation, permission, edge, and failure paths in proportion to risk. When a defect appears, preserve a reproduction and report expected versus actual behavior to the owner.

Complete when every applicable acceptance criterion has evidence, every executed command has a recorded result, and any untested risk is explicit.
EOF

cat > "$target/.agents/skills/code-review/SKILL.md" <<'EOF'
---
name: code-review
description: Review a completed change for material correctness, security, integrity, concurrency, compatibility, regression, and test-coverage problems.
---

# Code Review

Read the request, acceptance criteria, diff, and relevant surrounding code. Trace observable behavior and failure paths rather than reviewing style in isolation. Rank findings as critical, high, medium, or low. Each finding must name a location, describe a concrete failure scenario, provide evidence, and suggest a direction without implementing it.

Complete when every changed boundary and material invariant has been considered and all findings are actionable; explicitly report when no meaningful issue is found.
EOF

printf 'Installed Codex team harness in %s\n' "$target"
printf 'Created %d files. Start Codex in that project and request the workflow in AGENTS.md.\n' "${#files[@]}"
