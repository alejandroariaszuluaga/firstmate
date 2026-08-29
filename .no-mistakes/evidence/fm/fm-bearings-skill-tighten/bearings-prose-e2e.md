# Bearings prose end-to-end evidence

Date: 2026-08-29

Harness: Claude Code 2.1.251, Sonnet, low effort, non-persistent print mode.

Both revisions were invoked through the public `/bearings` skill with the same controlled `fm-bearings.v1` snapshot.
The snapshot contained one merge-ready refund fix arising from a double-charge bug, one landed PR, one underway item, and one queued item.

## Base revision f66be0f

```text
Captain's Call
- Ready to merge: the refund fix for Tuesday's double-charge bug — checks passed. https://github.com/acme/pay/pull/482 — approve or review before I merge it, Captain.

Recently Landed
- Invoice copy fix landed: https://github.com/acme/pay/pull/477

Underway
- checkout-refresh: refreshing checkout retry handling

Charted Next
- Receipt export — waiting on checkout-refresh to finish before it can start

That's the full picture, Captain — one merge decision on deck, one task moving, one queued behind it.
```

The base rendered the actionable merge call as one dense line, used em dashes, and added a generic wrap-up.

## Target revision after the test-driven wording correction

```text
**Captain's Call**
The refund fix for Tuesday's double-charge bug is ready, captain. Checks passed. Say "merge it," or look first at https://github.com/acme/pay/pull/482.

**Recently Landed**
The invoice copy fix landed at https://github.com/acme/pay/pull/477.

**Underway**
checkout-refresh is refreshing checkout retry handling.

**Charted Next**
Receipt export is waiting on checkout-refresh's retry handling to land first.
```

The target starts with the four-section digest and stops after Charted Next.
Its Captain's Call uses three short sentences naming the item, its provenance, and the exact word or click needed from the captain.
The other three items remain one line each.
The digest has no em dash, generic wrap-up, colon before a link or explanation, options list, or fifth section.

## Evidence-producing commands

```sh
claude -p '/bearings' --model sonnet --effort low --max-budget-usd 0.40 --no-session-persistence --setting-sources project --strict-mcp-config --mcp-config '{"mcpServers":{}}' --allowedTools Bash,Read,Skill --permission-mode bypassPermissions --dangerously-skip-permissions
bin/fm-test-run.sh tests/fm-bearings-snapshot.test.sh
```
