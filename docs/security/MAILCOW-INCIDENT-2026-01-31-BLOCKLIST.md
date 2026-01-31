# Mailcow Access Incident: Home IP Blocked (2026-01-31)

## Summary
Home IP 31.10.147.220 was unable to reach mail/web ports (80/443/143/993). TCP SYNs from the IP reached the server, but SYN-ACKs were not sent. Investigation showed explicit drops in Mailcow firewall chains (iptables MAILCOW) and nftables blocklist set. Removing those entries restored access (pending client retest).

## Timeline (2026-01-31 CET)
- 10:55–11:20: User reports timeouts to ports 80/443/143/993 from home IP; VPN/3G works.
- 11:10: Server checks show fail2ban active only for sshd; no UFW; default iptables ACCEPT.
- 11:12: tcpdump shows SYNs arriving from 31.10.147.220 and no SYN-ACK leaving server.
- 11:12–11:15: iptables shows Mailcow chain; nftables ruleset has `table inet blocklist`.
- 11:20: Explicit drop found for 31.10.147.220 in iptables MAILCOW and nft `bad_ips` set.
- 11:30+: Attempts to delete rule show it is already removed; current nft blocklist contains only other IPs.

## Evidence
- `iptables`:
  - Found earlier: `-A MAILCOW -s 31.10.147.220/32 -j DROP`
  - Now: `iptables -S MAILCOW | grep 31.10.147.220` -> no matches
- `nft`:
  - Found earlier: `ip saddr 31.10.147.220 drop` in `table inet blocklist` set
  - Now: `nft list set inet blocklist bad_ips` contains only `62.60.130.248`, `205.210.31.238`
- tcpdump showed SYNs from 31.10.147.220 without SYN-ACK responses (server-side drop).

## Root Cause (Most Likely)
Mailcow netfilter/container blocklist inserted the home IP into:
- `iptables` chain `MAILCOW`, and
- `nft` set `inet blocklist bad_ips`.

## Resolution
- Removed 31.10.147.220 from blocklists (already absent at time of last checks).
- Verified that neither iptables MAILCOW chain nor nft bad_ips set includes 31.10.147.220.

## Prevention / Follow‑ups
1. Identify which service re-adds IPs to MAILCOW/nft blocklists.
   - Likely Mailcow netfilter container.
2. Add home IP 31.10.147.220 to appropriate whitelist in Mailcow netfilter config.
3. Verify from home network after whitelist is in place.

## Notes / Commands Used
- `sudo iptables -S MAILCOW`
- `sudo iptables -S | rg -n "MAILCOW|31.10.147.220"`
- `sudo nft list ruleset | rg -n "blocklist|bad_ips|31.10.147.220"`
- `sudo nft list set inet blocklist bad_ips`
- `tcpdump -n -i any 'tcp port 80 or tcp port 443 or tcp port 143 or tcp port 993'`

## Open Items
- Need root access to inspect Mailcow netfilter container mounts/logs to find whitelist file and blocklist source.

## Netfilter Container Evidence (mailcowdockerized-netfilter-mailcow-1)
Logs show repeated failed SMTP/IMAP auth attempts from 31.10.147.220 leading to a timed ban:
- 2026-01-30 16:57:56–16:58:19: multiple auth failures for `milorad.stevanovic@inlock.ai` (password mismatch / SASL PLAIN auth failed)
- 2026-01-30 16:58:19: `CRIT: Banning 31.10.147.220/32 for 166 minutes`
- 2026-01-30 19:45:03: `INFO: Unbanning 31.10.147.220/32`

This confirms Mailcow netfilter auto-banned the home IP due to failed authentication attempts.

Container mounts:
- `mailcowdockerized-netfilter-mailcow-1` only bind-mounts `/lib/modules` (read-only), so its ban list is not stored via bind-mounted config on the host. Bans are applied directly to iptables/nft sets at runtime.
