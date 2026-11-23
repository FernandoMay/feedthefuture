#!/usr/bin/env bash
# Stop the local validator, restart it with the current program, and run the unit tests.
# Usage: ./scripts/run-tests.sh   (prints the mocha summary at the end)
set -uo pipefail
cd "$(dirname "$0")/.."
export PATH="/Users/fmf/tools/solana-release/bin:/Users/fmf/tools/bin:/Users/fmf/tools/node/bin:$PATH"

# Kill any stray validators from previous runs.
pkill -f "solana-test-validator" 2>/dev/null || true
sleep 1

mkdir -p out/validator
rm -rf out/validator/ledger
solana-test-validator \
  --bpf-program B4Cx6Vkm2VKiTGd8hpgCPbCDR2FBxULvGNAwEmVc8j4p target/deploy/feed_the_future.so \
  --ledger out/validator/ledger \
  > out/validator.log 2>&1 &
VALIDATOR_PID=$!
echo "$VALIDATOR_PID" > out/validator.pid

HEALTHY=0
for i in $(seq 1 90); do
  if curl -s -m 2 -X POST http://127.0.0.1:8899 -H 'Content-Type: application/json' \
      -d '{"jsonrpc":"2.0","id":1,"method":"getHealth","params":[]}' | grep -q '"result"'; then
    echo "Validator healthy."
    HEALTHY=1
    break
  fi
  if ! kill -0 "$VALIDATOR_PID" 2>/dev/null; then
    echo "Validator died. See out/validator.log" >&2
    tail -20 out/validator.log >&2 || true
    exit 1
  fi
  sleep 2
done

if [[ "$HEALTHY" != "1" ]]; then
  echo "Validator did not become healthy. See out/validator.log" >&2
  tail -20 out/validator.log >&2 || true
  exit 1
fi

npm test > out/test_mocha.log 2>&1
RC=$?
kill "$VALIDATOR_PID" 2>/dev/null || true
pkill -f "solana-test-validator" 2>/dev/null || true
echo "exit=$RC"
grep -E "passing|failing|pending" out/test_mocha.log | tail -5 || true
exit $RC
