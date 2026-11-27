# CI Quality Gate — PayPilot: Gate Policy (Part B)

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
