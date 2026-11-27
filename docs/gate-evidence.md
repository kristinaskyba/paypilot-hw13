# CI Quality Gate — PayPilot: gate evidence (Part A)

**System:** PayPilot · **Date:** 2026-11-27 · **Mandate:** Ship it · **Author:** Kristina Nilsson
**Repository:** https://github.com/kristinaskyba/paypilot-hw13 · **Workflow:** `.github/workflows/eval-gate.yml` · **Stand profile:** `clean` · **`JUDGE_MODEL`:** `qwen3:8b` (my local judge from L10)

## Prediction before step 1

*Written and committed before any workflow change or run. "After the lab" is filled after step 6.*

| Prediction | Now | After the lab |
| --- | --- | --- |
| Workflow steps needed to reach a red PR on my own case | 5 | 6: workflow edit · secret · secret fix · merge `ci/eval-gate` · branch protection · D19 PR |
| Report fields that match between the local and the CI run | 6 | 5 + `elapsed` (allowed to differ); passed/failed differed by 1 (DIS-002-N false alarm) |

**Where the difference went (one sentence):** The extra step went to the environment: the secret was first saved with a line break at the end.

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

- **What I did myself:** set up the repo, the API secret and the branch protection on `main`; ran every command and both local runs (daily and release); installed Ollama and ran the release check with my own judge `qwen3:8b` (chosen in L10); opened, merged and closed all PRs; made the predictions and the gate decisions (the cost threshold, who may bypass, re-running and logging the false alarm instead of merging red).
- **What the assistant wrote:** Claude (Cowork) translated the template to English, suggested the two workflow edits (`L11_REPO` for my hw11 tests, judge `qwen3:8b`), helped read the CI logs (the line break in the secret, the DIS-002-N false alarm) and drafted the text of the evidence sections and the Gate Policy from my results.
- **How I reviewed it:** checked every number and link against the run logs and reports; no secrets in the workflow; the `DEFECTS: D19` line not in `main`; reread row 5 as the developer from Thursday.
- **What I rewrote or decided:** changed row 5 to "the QA responsible for evals"; decided to re-run and log the second DIS-002-N false alarm.

**Chain-readiness:**

| Check | Passes |
| --- | --- |
| The mentor can access the public repository and see the workflow, PRs and artifacts | yes |
| A PR with `DEFECTS: D19` gives a red required `daily` check in one run | yes |
| The `eval-report` artifact of that run carries the six fields | yes |
| Merging such a PR is unavailable | yes |

**Optional part:** not done.

**Attachments:** `.github/workflows/eval-gate.yml` · [D19 PR #2](https://github.com/kristinaskyba/paypilot-hw13/pull/2) · red report artifact `eval-report` ([run 46040318245](https://github.com/kristinaskyba/paypilot-hw13/actions/runs/46040318245)) · `reports/release/run-20261127T173348Z.json` · `docs/gate-policy.md`.
