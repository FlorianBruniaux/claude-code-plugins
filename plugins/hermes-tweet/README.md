# hermes-tweet

Hermes Agent workflow skill for X/Twitter research, reading, and approval-gated posting through [Hermes Tweet](https://github.com/Xquik-dev/hermes-tweet).

## What's included

**Skills (1)**: hermes-tweet

**Tools covered**: `tweet_explore`, `tweet_read`, `tweet_action`

## Install

```bash
claude plugin install github:FlorianBruniaux/claude-code-plugins/plugins/hermes-tweet
```

## Quick start

```
Use Hermes Tweet to find recent X posts about the launch.
Use Hermes Tweet to draft a reply, then show the exact payload before posting.
```

## Configuration

- `XQUIK_API_KEY` enables read and action tools.
- `HERMES_TWEET_ENABLE_ACTIONS=true` is required before write actions are available.
- `tweet_explore` is the fit-check tool and does not require network credentials.

Use `tweet_action` only after the user approves the final text, target, and action payload.
