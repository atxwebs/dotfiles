Your job is to iteratively improve the files (or project) specified by the user, following any additional instructions they provide.

Follow this loop:
1. Spawn a subagent to review all code and documentation in scope. Identify issues that are realistically broken, outdated, inconsistent, inefficient, or unsafe. If the user gives instructions, focus only on those areas.
2. Evaluate the findings and discard low-value or irrelevant suggestions.
3. Apply improvements to code, documentation, and tests as needed. Verify all tests pass.
4. If the review produces many useful suggestions, repeat the process; otherwise, stop when remaining suggestions are mostly minor nitpicks.

Batch changes together in a single response as much as possible.
