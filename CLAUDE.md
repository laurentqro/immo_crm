## Development Process — TDD Required (No Exceptions)

Follow the TDD skill at `skills/tdd/SKILL.md`:

1. **RED**: Write ONE failing test for the next behavior
2. **GREEN**: Write minimal code to make it pass  
3. **REFACTOR**: Clean up only when green

Vertical slices only. Never write implementation without a failing test first.
Never write multiple tests before implementing. One test → one impl → repeat.

If you catch yourself writing code without a red test, STOP and write the test first.

The project has a custom Arelle API server at `../arelle-api` (https://github.com/laurentqro/arelle-api). It validates XBRL instance documents against the AMSF/Strix taxonomy.

- Always use `params.expect` for strong parameters. Never use `params.require.permit`.
