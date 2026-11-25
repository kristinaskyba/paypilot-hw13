# PayPilot Eval Gate Kit (L13)

Кіт лабораторної L13 («Quality gate у GitHub Actions») поверх контуру оцінювання PayPilot (`run_eval.py`).

## Швидкий старт локально

Поруч із цим каталогом мають лежати:
- `../paypilot-stand` (`sergeytkachenko/paypilot-stand-shared`, коміт `74f1995`)
- `../l11` (`sergeytkachenko/paypilot-l11-eval` із вашими тестами або тестами з `tests_l11_reference/`)

```bash
cp .env.example .env
docker compose run --rm --entrypoint pytest eval tests -q
docker compose run --rm eval --dry-run
docker compose run --rm -e SET=l03 -e GATE=daily -e PROFILE=clean eval
docker compose run --rm -e SET=l03 -e GATE=daily -e PROFILE=clean -e DEFECTS=D19 eval
```

На macOS / Linux можна також використовувати `Makefile`: `make dry-run`, `make eval SET=l03`, `make compare A=... B=...`.

## Структура та інтеграція в CI

- `.github/workflows/eval-gate.yml` — двошаровий workflow (`daily` на PR, `release` на `workflow_dispatch` / `push` у `release`, залежний `deploy`).
- `scripts/ci_bootstrap_stand.sh` — піднімає стенд і тести L11 у GitHub Actions.
- `reports/run-*.json` та `reports/traces/` — звіти прогонів із шістьма полями порівнянності (`prompt_version`, `set_hash`, `profile`, `judge_model`, `rubric_version`, `elapsed`) і трейсами кейсів.
- `evals/gate_reference/` — запасний еталонний пакет (`report-green.json`, `report-red.json`, `report-release.json`, `eval-gate.yml`, `gate-policy.reference.md`).
- `ci-quality-gate.template.md` — шаблон артефакту L13 (Частина A → `docs/gate-evidence.md`, Частина B → `docs/gate-policy.md`).

## Release-шар і права доступу

На безкоштовному тарифі GitHub захист гілки працює в публічному репозиторії. З міркувань безпеки не підключайте `self-hosted` runner до публічного репозиторію: релізний прогін із локальним суддею (`JUDGE_BACKEND=ollama JUDGE_MODEL=qwen2.5:7b`) виконуйте локально в периметрі (`make release`), а в публічному CI використовуйте `workflow_dispatch` (`layer=release`) із залежним job'ом `deploy` (`needs: release`). У приватному репозиторії організації `release` запускається на `runs-on: self-hosted`.
