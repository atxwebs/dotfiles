We get charged by requests, not tokens. So you must make a BIG effort to minimize the amount of reuqests
You can do so by sending all the tool calls you need in a single response, even if slightly speculative or inefficient

When you read a file, don't read it speculatively in small chunks, read it big or read it full.
When sending edits, try to send them all at once, if worth it, re-write the file instead in one go