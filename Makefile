export SET GATE CASE PROFILE DEFECTS JUDGE_MODEL JUDGE_BACKEND OLLAMA_URL GATE_MODE

.PHONY: eval dry-run compare test release
eval:
	docker compose run --rm eval

dry-run:
	docker compose run --rm eval --dry-run

compare:
	docker compose run --rm eval --compare $(A) $(B)

test:
	docker compose run --rm --entrypoint pytest eval tests -q

release:
	docker compose run --rm -e GATE=release -e JUDGE_BACKEND=ollama -e JUDGE_MODEL=qwen2.5:7b eval
