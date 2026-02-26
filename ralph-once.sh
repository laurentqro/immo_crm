#!/bin/bash
# Ralph HITL (Human-in-the-Loop) with streaming output
# Runs one task from PRD.md, commits, updates progress.txt, then stops for review.
# Usage: ./ralph-once.sh

set -e

# jq filter: extract streaming text from assistant messages
stream_text='select(.type == "assistant").message.content[]? | select(.type == "text").text // empty | gsub("\n"; "\r\n") | . + "\r\n\n"'

claude --permission-mode acceptEdits \
  --print \
  --output-format stream-json \
  -p "@PRD.md @progress.txt \
1. Read the PRD and progress file. \
2. Find the next incomplete task and implement it. \
3. Run the test suite to verify your changes pass. \
4. Commit your changes with a descriptive message. \
5. Update progress.txt with what you did. \
ONLY DO ONE TASK AT A TIME." \
| grep --line-buffered '^{' \
| jq --unbuffered -rj "$stream_text"
