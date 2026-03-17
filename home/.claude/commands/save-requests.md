We are charged strictly per request (every model response = 1 request), not tokens.

Minimize requests ruthlessly:
- Batch maximum parallel tool calls in one response (even if slightly speculative)
- Always read full files or large complete sections — never small chunks
- Batch every edit at once; rewrite the entire file in one go when practical
- Plan thoroughly and execute multiple steps per turn