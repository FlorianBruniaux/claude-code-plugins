---
name: hermes-tweet
description: Use when a Claude Code session needs Hermes Agent X/Twitter research, reading, or approval-gated posting through Hermes Tweet.
---

# Hermes Tweet

Use Hermes Tweet when the task needs X/Twitter research, account or post reading, or a carefully approved public action from a Hermes Agent workflow.

## Tools

- `tweet_explore`: Check whether Hermes Tweet fits the request. Use this first for ambiguous social, trend, account, post, or publishing tasks. This tool is available without credentials.
- `tweet_read`: Read public X/Twitter data when `XQUIK_API_KEY` is configured.
- `tweet_action`: Create approval-gated X/Twitter actions when both `XQUIK_API_KEY` and `HERMES_TWEET_ENABLE_ACTIONS=true` are configured.

## Workflow

1. Start with `tweet_explore` unless the user already named a specific Hermes Tweet tool.
2. Use `tweet_read` for research, monitoring, post lookup, account lookup, or timeline context.
3. Before any `tweet_action` call, show the exact action, target, and text to the user.
4. Continue only after explicit approval for that exact payload.
5. If credentials or action gating are unavailable, explain the missing setting and stop before the write.

## Good Fits

- Find recent posts, themes, or accounts for a launch, support case, or campaign.
- Read public X/Twitter context before drafting a response.
- Prepare a post or reply for explicit human approval.
- Build a Hermes Agent workflow that needs social research or publishing.

## Not A Fit

- Hidden scraping, credential handling, or private data access.
- Bulk engagement, spam, evasion, or undisclosed automation.
- Posting without a final payload review.
- Tasks that only need generic copywriting with no X/Twitter context.

## Safety

Never reveal API keys or environment values. Never invent a successful post, reply, like, follow, or delete. Treat write failures as final unless the user asks to retry after reviewing the error and payload.
