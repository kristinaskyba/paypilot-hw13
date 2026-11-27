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

**How it runs:** local run inside the perimeter (Ollama on my Mac) + CI `workflow_dispatch` with `deploy: skipped`

| Field | Value |
| --- | --- |
| How the release job is triggered | `workflow_dispatch` (`layer: release`) and `push` to branch `release`; never `pull_request` |
| Where `release` runs | locally inside the perimeter (Ollama `qwen3:8b`) + CI `eval-gate / release` → `deploy: skipped` |
| Command | `docker compose run --rm -e SET=l03 -e GATE=release -e JUDGE_BACKEND=ollama -e JUDGE_MODEL=qwen3:8b -e REPEAT=1 eval` |
| CI run (link, `deploy: skipped` when RED) | [run 46043073268](https://github.com/kristinaskyba/paypilot-hw13/actions/runs/46043073268): `release` failed (exit 1, no Ollama on the GitHub runner: 5 judge cases "ollama unreachable"), `deploy` skipped, `daily` skipped |
| `judge_model` in the release report | `qwen3:8b` (local tag) |
| Release job does not run on PRs | yes — every PR run shows `release: skipped` (PR #1, #2, #3) |
| No cloud-judge secrets in the `release` job | yes — `JUDGE_BACKEND: ollama`, no judge key; the only secret is the agent's key for the stand |

**Local release run report:**

| Field | Value |
| --- | --- |
| Where the run was done | my own Mac inside the perimeter (Ollama `qwen3:8b`, Apple M4 Pro) |
| Report | `reports/release/run-20261127T173348Z.json` |
| `set_hash` / `prompt_version` / `judge_model` | 98ca5238d7c8 / base.v1 / `qwen3:8b` |
| Result | 5/7 passed, 2 failed, exit 1; 88 s; agent $0.0051, judge $0 |
| Note | `REPEAT=1` (each release case once, not `runs: 5`) to keep the run short; a full release run is ~15–20 min |

**What the release layer found:**
- HUM-001: the judge failed the answer. The agent asked for the dispute reason instead of refusing the dispute.
- ORD-001: expected only `check_limits`, but the agent also called `get_account`. In an earlier CI run (#5, cancelled) it also called `quote_fx`, so the extra calls change from run to run.

The set_hash here (98ca5238d7c8) is different from daily (473130ffc685), because the hash covers only the cases in the chosen layer (7 release cases vs 36 daily).

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

*Reader: a developer who sees the red check and the grey "Merge" button. They have not read my ADRs and do not know what `set_hash` is.*

**System:** PayPilot · **Version:** v1 · **Mandate:** Ship it · **Author:** Kristina Nilsson · **Date:** 2026-11-27

```
GATE POLICY · PayPilot · v1 · mandate: Ship it
──────────────────────────────────────────────────────────────────
1  What blocks merge      daily layer: 36 rule-based cases (gate: daily), set l03,
                          GitHub-hosted runner; required check eval-gate / daily on main;
                          red = exit code ≠ 0
2  What blocks release    release layer: 7 cases (gate: release, judge + runs: 5),
                          local judge qwen3:8b (Ollama) inside the perimeter;
                          CI deploy needs: release → red release = no deploy
3  Cost gate              daily run machine.tokens_total ≤ 300k + 10 % (330k)
                          → under Ship it: blocks release, opens a ticket; never blocks merge
4  Thresholds not in gate coverage ≥ N % · judge average score · "zero red in all tests" · € per run
5  Who may bypass         the QA responsible for evals; only the daily layer, with a record;
                          the release layer is bypassed by no one (not CTO, not CEO)
6  How a bypass is logged label gate-override + issue: case · reason · who · until when ·
                          build report (eval-report link); no issue = not a bypass
7  What we traded         every PR waits ~3 min and costs ~$0.015; a check false alarm
                          (DIS-002-N) can block a correct PR ↔ D19-type regressions stop before merge
8  What we do not do      we don't move a case from daily to release, or edit sets/thresholds,
                          to make a PR green; no self-hosted runner on a public repo
9  When we revisit        new prompt_version or judge model/tag · DIS-002-N false alarm twice ·
                          more than 2 bypasses in a month
──────────────────────────────────────────────────────────────────
v1 — first version, accepted 2026-11-27 (no earlier version)
```

### Rows explained

| # | Row | My text |
| --- | --- | --- |
| 1 | What blocks merge | The daily layer: 36 rule-based cases from set l03 (`gate: daily`), run on a GitHub-hosted runner on every PR. The check `eval-gate / daily` is required on `main`; it is red when the eval command exits with a non-zero code. |
| 2 | What blocks release | The release layer: 7 cases (`gate: release`, judge cases with `runs: 5`), judged by the local `qwen3:8b` in Ollama inside the perimeter. In CI, `deploy` has `needs: release`, so a red release means no deploy. |
| 3 | Cost gate | Daily run `machine.tokens_total` ≤ 300k tokens + 10 % tolerance (330k). Today's daily runs used 268–284k. Under Ship it a red cost gate blocks the release and opens a ticket; it never blocks a merge. |
| 4 | Thresholds not in the gate | Coverage first, then judge average score, "zero red in all tests", € per run as a merge blocker (see the table below). |
| 5 | Who may bypass | The QA responsible for evals, only on the daily layer, and only with a record (row 6). The release layer is bypassed by no one, not the CTO, not the CEO. |
| 6 | How a bypass is logged | Label `gate-override` on the PR + an issue with 5 fields: case · reason · who · until when · build report (link to the `eval-report` artifact). A bypass without the issue is not a bypass, it is a policy violation. |
| 7 | What we traded | Every PR waits ~3 min and costs ~$0.015, and a false alarm of a check (DIS-002-N) can block a correct PR; in exchange, regressions like D19 are stopped before merge. |
| 8 | What we do not do | We don't move a case from daily to release, and we don't edit sets or thresholds, to make a PR green. We don't connect a self-hosted runner to a public repo. |
| 9 | When we revisit | A new `prompt_version`, a new judge model or tag, the DIS-002-N false alarm happening twice, or more than 2 bypasses in a month. |

### Thresholds that do not go into the gate

| Threshold people ask for | Why not in the gate | What instead |
| --- | --- | --- |
| Coverage ≥ N % | It measures lines that ran, not answers that were checked; with D19 all 33 unit tests passed | Cases tied to the dispute/FX engines (level 1) |
| Judge average score | It mixes cases, so one critical failure hides in a good average; the judge is noisy | A per-case judge verdict, in the release layer only |
| "Zero red in all tests" | Text-pattern cases can false-alarm (DIS-002-N matched `is eligible` in a correct answer) | Red blocks, but a known false alarm may be bypassed with a record |
| € per run as a merge blocker | Under Ship it, cost must not stop a correct fix | A separate cost gate (row 3) and a ticket |

### What the gate does not catch

| Regression or defect class | Why it is not caught | What we do about it |
| --- | --- | --- |
| A regression with no case in the set | The gate only checks the cases it has | Add a level-1 case when a new defect is found |
| Probabilistic defects (HUM-001, ORD-001) | They are only in the release layer, not in daily | A release run before every release |
| A wrong pattern in a `not_regex` case | DIS-002-N matched "status is eligible" in a correct answer | Fix the pattern in the next set version |

### Mandate line

**Mandate in force:** Ship it (Verta, set in L02)
**How the cost gate action would change under another mandate:** under Cut the cost, the cost gate would also block merge; under Zero regulatory risk, nobody could bypass, not even the daily layer.

### Bypass log

*Filled only if a bypass happened. A bypass missing any of the five fields is not recognised by the policy.*

| Date | Layer and case | Reason | Who · until when | Build report · issue |
| --- | --- | --- | --- | --- |
| 2026-11-27 | daily · DIS-002-N | 2nd false alarm: correct refusal, pattern matched "status is eligible"; docs-only PR; re-run instead of merging red | Kristina (QA for evals) · until the pattern is fixed | [run 46044191276](https://github.com/kristinaskyba/paypilot-hw13/actions/runs/46044191276) |

### Version history

| Version | What changed | Status | Why |
| --- | --- | --- | --- |
| v1 | First version | accepted | Based on today's runs (daily green, D19 red, release run with qwen3:8b) |

**Row 5 check:** reread it as the developer from Thursday. Is the question "so am I allowed or not?" still open? — no: on daily, only the QA responsible for evals may bypass, with label + issue; on release, nobody.
