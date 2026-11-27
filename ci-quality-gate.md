# CI Quality Gate — PayPilot

> **How this file works.** Two parts. At the end, Part A becomes `docs/gate-evidence.md` (reader: mentor) and Part B becomes `docs/gate-policy.md` (reader: the developer who sees the red check and the grey "Merge" button).
> Lab: sections 1–4 of Part A and a draft of Part B. HW: finish Part B and section 5. Every row backed by a link to a run, PR, artifact or command output. An empty cell is better than an invented value. If a threshold had to change, keep the old policy version as `superseded`.

---

# Part A. Gate evidence → `docs/gate-evidence.md`

**System:** PayPilot · **Date:** 2026-11-27 · **Mandate:** Ship it · **Author:** Kristina Nilsson
**Repository:** https://github.com/kristinaskyba/paypilot-hw13 · **Workflow:** `.github/workflows/eval-gate.yml` · **Stand profile:** `clean` · **`JUDGE_MODEL`:** `qwen3:8b` (my local judge from L10)

## Prediction before step 1

*Written and committed before any workflow change or run. "After the lab" is filled after step 6.*

| Prediction | Now | After the lab |
| --- | --- | --- |
| Workflow steps needed to reach a red PR on my own case | 5 | |
| Report fields that match between the local and the CI run | 6 | |

**Where the difference went (one sentence):**

---

## 1. Smoke and daily layer

*Lab: steps 1 (smoke on PR) and 2 (daily layer) · HW: stage 1 · Criteria 2 "Integration by exit code" and 3 "Two layers by the `gate` field".*

| Check | Link / evidence | Result |
| --- | --- | --- |
| Smoke: `docker compose run --rm eval --dry-run` on PR is green | [run 46036136000, attempt 1](https://github.com/kristinaskyba/paypilot-hw13/actions/runs/46036136000), PR [#1](https://github.com/kristinaskyba/paypilot-hw13/pull/1) | yes |
| What `--dry-run` printed (cases / calls) | 36 cases `l03` (36 daily, 0 release), 36 agent calls, 0 judge; unit tests 6 manual + 27 generated; "nothing called" | — |
| Provider secret (`ANTHROPIC_API_KEY`) added to the repository | — | yes |
| Full daily run `SET=l03 GATE=daily` green, exit code 0 | [run 46036136000, attempt 3](https://github.com/kristinaskyba/paypilot-hw13/actions/runs/46036136000): 36/36, exit 0 | yes |
| No `continue-on-error` and no `\|\| true` on the eval step | `run: docker compose run --rm -e SET -e GATE -e PROFILE -e DEFECTS eval` | yes |
| No cases with `runs: 5` or `assertion: judge` in the daily job | `--dry-run`: 0 release cases, 0 judge calls | yes |
| PR `ci/eval-gate` merged into `main` before step 4 | [PR #1](https://github.com/kristinaskyba/paypilot-hw13/pull/1) | yes |

**`env` block of the daily job:**

```yaml
env:
  GATE: daily
  PROFILE: clean
  DEFECTS: ""
```

**If the job was red without red cases — what was fixed:** Two environment reds before the first green run. (1) No secret yet: the stand used the mock model, 15 text cases failed. (2) The secret had a line break at the end: `anthropic api reachable [FAIL] Illegal header value b'***\n'`. I saved the secret again without the line break. I fixed the environment; I did not change the set or the thresholds.

---

## 2. Local vs CI run

*Lab: step 3 (report as artifact) · HW: stage 1 · Criterion 4 "The build report carries six fields". Compare with the local run `docker compose run --rm -e SET=l03 -e GATE=daily -e PROFILE=clean eval`.*

| Field | Local run | CI run | Match? |
| --- | --- | --- | --- |
| Record file | `reports/run-20261127T170133Z.json` | artifact `eval-report` (`run-20261127T165516Z.json`), [run 46036136000](https://github.com/kristinaskyba/paypilot-hw13/actions/runs/46036136000) | — |
| `prompt_version` | base.v1 | base.v1 | yes |
| `set_hash` | 473130ffc685 | 473130ffc685 | yes |
| `profile` | clean | clean | yes |
| `judge_model` | `not-used` | `not-used` | yes |
| `rubric_version` | `rubric.v1` | `rubric.v1` | yes |
| `elapsed` | 130.7 s | 113.9 s | differs (allowed) |
| passed / failed | 35 / 1 (DIS-002-N), exit 1 | 36 / 0, exit 0 | no — one case |

Also the same in both: 36 calls, unit tests 6 manual + 27 generated (my hw11 tests), cost ~$0.015.

**Which field differed and why (one sentence):** Only `elapsed` (allowed); the five version fields match, so it is the same run.

**If `set_hash` and `prompt_version` match but the result does not — what I found:** The difference is not the environment. DIS-002-N failed locally on the pattern `is eligible`, but the agent's answer was correct: it refused the dispute ("the 60-day window … closed") and then said "the transaction status is eligible". The check matched that unrelated phrase. This is a false alarm of the check, and it depends on the model's wording in each run (runs: 1). It goes into the Gate Policy as a known weakness.

---

## 3. Red PR

*Lab: step 4 (one line in a PR) · HW: stage 2 · Criterion 1 "Gate against my own dataset". After the step, remove the `DEFECTS: D19` line.*

| Field | Value |
| --- | --- |
| Account and repository visibility | Free · public |
| Branch protection on `main`: check `eval-gate / daily` required | yes (classic rule, required check `daily`) |
| "Do not allow bypassing the above settings" enabled | yes |
| PR branch created from `main` (after merging `ci/eval-gate`) | yes (`test/d19`) |
| Where `DEFECTS: "D19"` was added | `env` block of the `daily` job in `.github/workflows/eval-gate.yml` |
| PR (link, status "closed, not merged") | [PR #2](https://github.com/kristinaskyba/paypilot-hw13/pull/2) — closed, not merged |
| "Merge" button unavailable (PR blocked) | yes — `eval-gate / daily` Required, Failing |
| Report artifact of the red run | `eval-report` ([run 46040318245](https://github.com/kristinaskyba/paypilot-hw13/actions/runs/46040318245)): profile `clean+D19`, 34/36, exit 1 |
| The `DEFECTS: D19` line did not reach `main` | yes |

**Red cases from the report:**

| Case ID | Condition | `expected` / `got` | Oracle, level, `gate` |
| --- | --- | --- | --- |
| `DIS-006` (`TX-0402`, `CUS-0004`) | duplicate charge on day 63, window 60 days (D19 makes it 90) | `eligible=False` / `eligible=True` | `engine:disputes`, 1, `daily` |
| `DIS-002-N` (`TX-0402`) | same transaction, the agent's answer to the customer | must not offer a dispute / "you can still dispute" | `engine` (pattern), 4, `daily` |

**Why unit tests are green but the gate is red (one sentence):** The unit tests (6 + 27 passed) check the code's functions one by one, while the gate runs the agent end to end against the dispute engine's answer, and only that shows the tool saying "eligible" for a 63-day-old transaction.

---

## 4. Release layer inside the perimeter

*Lab: step 5 (release layer) · HW: stage 3 · Criteria 3 "Two layers by the `gate` field" and 6 "Judge perimeter".*

**How it runs:** local run inside the perimeter (Ollama) + CI `workflow_dispatch` with `deploy: skipped`

| Field | Value |
| --- | --- |
| How the release job is triggered | `workflow_dispatch` (`layer: release`) and `push` to branch `release` |
| Where `release` runs | locally inside the perimeter (Ollama) + CI `eval-gate / release` → `deploy: skipped` |
| Command | `docker compose run --rm -e SET=l03 -e GATE=release -e JUDGE_BACKEND=ollama -e JUDGE_MODEL=qwen3:8b eval` |
| CI run (link, `deploy: skipped` when RED) | |
| `judge_model` in the release report | `qwen3:8b` (local tag) |
| Release job does not run on PRs | yes / no |
| No cloud-judge secrets in the `release` job | yes / no |

**Local release run report:**

| Field | Value |
| --- | --- |
| Where the run was done | my own machine inside the perimeter (Ollama `qwen3:8b`) |
| Report (`reports/release/run-<…>.json`) | |
| `set_hash` / `prompt_version` / `judge_model` in the report | / / `qwen3:8b` |

---

## 5. AI declaration and chain-readiness

*HW: stage 5 · Criteria 7 "Chain-readiness" and 8 "AI declaration".*

**AI declaration** *(all three parts required)*:

- what the assistant wrote in the workflow or policy:
- by which criteria I reviewed it:
- what I rewrote:

**Chain-readiness:**

| Check | Passes |
| --- | --- |
| The mentor can access the public repository and see the workflow, PRs and artifacts | yes / no |
| A PR with `DEFECTS: D19` gives a red required `daily` check in one run | yes / no |
| The `eval-report` artifact of that run carries the six fields | yes / no |
| Merging such a PR is unavailable | yes / no |

**Optional part:** `cost` job added: yes / no · cost of the daily layer per week: · price of one team hour on a red build: · generalised Gate Policy `gate-policy.template.md`: yes / no

**Attachments:** `.github/workflows/eval-gate.yml` · link to the D19 PR · red report artifact · release report · `docs/gate-policy.md`.

---

# Part B. Gate Policy → `docs/gate-policy.md`

## 6. Gate Policy

*Lab: step 6 (draft) · HW: stage 4 · Criterion 5 "Gate Policy". Reader: a developer who sees the red check and the grey "Merge" button. They have not read my ADRs and do not know what `set_hash` is.*

**System:** PayPilot · **Version:** v<N> · **Mandate:** Ship it · **Author:** Kristina Nilsson · **Date:**

```
GATE POLICY · PayPilot · v<N> · mandate: Ship it
──────────────────────────────────────────────────────────────────
1  What blocks merge      <layer, gate, runner>
2  What blocks release    <layer, gate, runner, JUDGE_MODEL>
3  Cost gate              <machine.tokens_total ≤ budget + tolerance>
                          → <action on red, by mandate>
4  Thresholds not in gate coverage · <…> · <…>
5  Who may bypass         <role>; only <layer>;
                          <layer> is bypassed by no one
6  How a bypass is logged <label> + issue: <5 fields>;
                          build report attached
7  What we traded         <…> ↔ <…>
8  What we do not do      <…>
9  When we revisit        <condition> · <condition> · <condition>
──────────────────────────────────────────────────────────────────
<version history: v0 — superseded by v1, why>
```

### Rows explained

| # | Row | My text | Hint |
| --- | --- | --- | --- |
| 1 | What blocks merge | | rule-based layer, `gate: daily`, GitHub-hosted (`eval-gate / daily`) |
| 2 | What blocks release | | judge-based layer, `gate: release`, local `qwen3:8b` |
| 3 | Cost gate | | run's `machine.tokens_total` ≤ run budget + tolerance; under Ship it blocks release and opens a ticket |
| 4 | Thresholds not in the gate | | at least three; coverage first |
| 5 | Who may bypass | | the right is written per layer; empty for `release` |
| 6 | How a bypass is logged | | 5 fields: `case · reason · who · until when · build report` |
| 7 | What we traded | | what became slower or more expensive because of the gate? |
| 8 | What we do not do | | e.g. we don't change a case's `gate` for speed without a record |
| 9 | When we revisit | | which change in prompt, judge or bypass statistics brings us back to the policy? |

### Thresholds that do not go into the gate

| Threshold people ask for | Why not in the gate | What instead |
| --- | --- | --- |
| Coverage ≥ N % | | |
| | | |
| | | |

### What the gate does not catch

| Regression or defect class | Why it is not caught | What we do about it |
| --- | --- | --- |
| | | |

### Mandate line

**Mandate in force:** Ship it (Verta, set in L02)
**How the cost gate action would change under another mandate:**

### Bypass log

*Filled only if a bypass happened. A bypass missing any of the five fields is not recognised by the policy.*

| Date | Layer and case | Reason | Who · until when | Build report · issue |
| --- | --- | --- | --- | --- |
| | daily · | | · | · |

### Version history

| Version | What changed | Status | Why |
| --- | --- | --- | --- |
| v0 | | | |
| v1 | | accepted | |

**Row 5 check:** reread it as the developer from Thursday. Is the question "so am I allowed or not?" still open? — yes / no
