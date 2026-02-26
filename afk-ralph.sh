#!/bin/bash
# Ralph AFK (Away From Keyboard) with streaming output
# Loops autonomously inside a Docker sandbox, one task per iteration.
# Streams Claude's output in real-time so you can watch progress.
# Stops when PRD is complete or iteration cap is reached.
# Usage: ./afk-ralph.sh [max_iterations]

set -e

MAX_ITERATIONS=${1:-10}

# jq filter: extract streaming text from assistant messages
stream_text='select(.type == "assistant").message.content[]? | select(.type == "text").text // empty | gsub("\n"; "\r\n") | . + "\r\n\n"'

# jq filter: extract final result to check for completion
final_result='select(.type == "result").result // empty'

echo "Starting AFK Ralph (max $MAX_ITERATIONS iterations)..."

for ((i=1; i<=MAX_ITERATIONS; i++)); do
  tmpfile=$(mktemp)
  trap "rm -f $tmpfile" EXIT

  echo ""
  echo "=== Iteration $i / $MAX_ITERATIONS ==="
  echo ""

  docker sandbox run claude -- \
    --verbose \
    --print \
    --output-format stream-json \
    -p "@PRD.md @progress.txt \
1. Read the PRD and progress file. \
2. Find the next incomplete task and implement it. \
3. Run the test suite to verify your changes pass. \
4. Commit your changes with a descriptive message. \
5. Update progress.txt with what you did. \
6. If ALL tasks in the PRD are complete, output exactly: <promise>COMPLETE</promise> \
ONLY DO ONE TASK AT A TIME." \
  | grep --line-buffered '^{' \
  | tee "$tmpfile" \
  | jq --unbuffered -rj "$stream_text"

  # Check if all tasks are done
  result=$(jq -r "$final_result" "$tmpfile")

  if [[ "$result" == *"<promise>COMPLETE</promise>"* ]]; then
    echo ""
    echo "=== All PRD tasks complete after $i iterations! ==="
    exit 0
  fi
done

echo ""
echo "=== Reached iteration cap ($MAX_ITERATIONS). Review progress.txt for status. ==="
