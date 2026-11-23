#!/usr/bin/env bash
# Start a local solana-test-validator preloaded with the Feed the Future program.
# Usage: ./scripts/start-validator.sh [--stop]
set -euo pipefail
export PATH="/Users/fmf/tools/solana-release/bin:/Users/fmf/tools/bin:/Users/fmf/tools/node/bin:$PATH"
cd "$(dirname "$0")/.."

PROGRAM_ID="B4Cx6Vkm2VKiTGd8hpgCPbCDR2FBxULvGNAwEmVc8j4p"

if [[ "${1:-}" == "--stop" ]]; then
  if [[ -f out/validator.pid ]]; then
    kill "$(cat out/validator.pid)" 2>/dev/null || true
    rm -f out/validator.pid
    echo "Validator stopped."
  fi
  exit 0
fi

if [[ -f out/validator.pid ]] && kill -0 "$(cat out/validator.pid)" 2>/dev/null; then
  echo "Validator already running (pid $(cat out/validator.pid))."
  exit 0
fi

mkdir -p out/validator
solana-test-validator \
  --bpf-program "$PROGRAM_ID" target/deploy/feed_the_future.so \
  --ledger out/validator/ledger \
  > out/validator.log 2>&1 &
VALIDATOR_PID=$!
echo "$VALIDATOR_PID" > out/validator.pid
echo "Validator PID: $VALIDATOR_PID (log: out/validator.log)"

for i in $(seq 1 90); do
  if curl -s -X POST http://127.0.0.1:8899 -H 'Content-Type: application/json' \
      -d '{"jsonrpc":"2.0","id":1,"method":"getHealth","params":[]}' | grep -q '"result"'; then
    echo "Validator healthy."
    exit 0
  fi
  if ! kill -0 "$VALIDATOR_PID" 2>/dev/null; then
    echo "Validator died. See out/validator.log" >&2
    tail -20 out/validator.log >&2 || true
    exit 1
  fi
  sleep 1
done
echo "Validator did not become healthy in 90s. See out/validator.log" >&2
tail -20 out/validator.log >&2 || true
exit 1
