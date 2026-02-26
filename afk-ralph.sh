#!/bin/bash
# AFK Ralph Loop for ImmoCRM AMSF Survey
# Usage: ./afk-ralph.sh <iterations>
set -e

if [ -z "$1" ]; then
  echo "Usage: $0 <iterations>"
  echo "Example: $0 33"
  exit 1
fi

echo "🔄 Starting AMSF Survey Ralph Loop for $1 iterations..."
echo ""

for ((i=1; i<=$1; i++)); do
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo "🔄 Iteration $i of $1"
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

  result=$(claude --dangerously-skip-permissions -p \
    "@CLAUDE.md @progress.txt @amsf_questions.csv \
    1. Read CLAUDE.md for project context and conventions. \
    2. Read progress.txt to see what's completed. \
    3. Find the next incomplete task (one single AMSF question). \
    4. Find that question in amsf_questions.csv for context and instructions. \
    5. Look up the field_id in questionnaire_structure.yml and check the XSD for expected type. \
    6. Find the existing method in app/models/survey/fields/. \
    7. Fix the method to compute real data instead of hardcoded/stubbed values. \
    8. Write a test for this specific field. \
    9. Run the test suite to verify everything passes. \
    10. If Arelle is available, generate XBRL and validate this field. \
    11. Commit with message format: [AMSF Qnum] Short description. \
    12. Update progress.txt: mark the task as complete with today's date. \
    ONLY WORK ON A SINGLE QUESTION. \
    If all tasks in progress.txt are complete, output <promise>COMPLETE</promise>.")

  echo "$result"
  echo ""

  if [[ "$result" == *"<promise>COMPLETE</promise>"* ]]; then
    echo "🎉 All 33 sections complete after $i iterations!"
    exit 0
  fi

  echo "✅ Iteration $i done. Sleeping 5s before next..."
  sleep 5
done

echo "🏁 Completed $1 iterations."
