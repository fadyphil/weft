# Security

What Weft protects, what it explicitly does not, and what only the owner may do. Limits are
stated as limits; a security doc that claims more than the code does is worse than none.

## 1. What Weft is not

- **No accounts.** There is no login, no email, no password, no user record. A device is an
  anonymous UUID persisted in secure local storage (FR-03).
- **No end-to-end encryption in v1.** Ops travel over TLS and are stored as plaintext JSONB
  in Postgres. The database operator can read document content. This is a deliberate cut for
  runway, recorded as a non-goal, not an oversight.
- **No rich text, no presence, no history.** Less surface, by design.

## 2. Threat model

| Threat | Position |
| --- | --- |
| Network observer | TLS in transit; terminated at Render. |
| Relay or database operator | Can read payloads. No E2EE v1. Documented, accepted. |
| Someone who obtains a room code | Can join the document. See §3. |
| Someone guessing a document ID | UUIDv4; not enumerable. Room-code lookup is by SHA-256 hash. |
| Malicious client flooding the relay | Frame and batch caps (`MAX_FRAME_BYTES`, `MAX_BATCH_OPS`), per-connection rate limit. |
| Payload leaking into logs or error reports | Metadata-only logging; Sentry scrubbing; checked by review. |
| Stolen laptop or backup | Backups are age-encrypted before they leave the machine. |
| Supply-chain package | `STACK.md` allowlist; nightly `govulncheck`; no unlisted dependency without an ADR. |

Document IDs and device IDs are not secrets. Room codes are.

## 3. Room code is a bearer secret

A room code is an **8-character Crockford base32** string, generated on the client, that
grants access to one document. Anyone holding it can join. There is no second factor, no
revocation, and no per-device allowlist.

- The relay stores only `SHA-256(code)`, never the code itself.
- QR encodes `weft://join?doc=<uuid>&code=<code>`.
- A wrong code returns a typed error, not a hint about whether the document exists.
- Sharing a code is sharing the document. Treat it like a password, because functionally it
  is one, without the protections a password has.

This limitation is stated here and must be stated in the app's pairing screen. It is the price
of no accounts, and it will be the first thing an E2EE layer replaces.

## 4. Transport

TLS everywhere in production: Render terminates TLS for the relay, Neon requires it for the
database. Staging runs plain HTTP on localhost inside Docker Compose, which is acceptable
because it never leaves the machine. Do not expose the staging Compose stack to a network you
do not control.

WebSocket messages are size-capped and batched-capped before they reach the database. The
relay never parses an op payload; it stores bytes it cannot interpret. That is a containment
property as much as a security one: a compromised relay can delay or duplicate operations,
but cannot author a valid one.

## 5. Logging and telemetry

Rule: **metadata only**. Allowed fields are `docId`, `deviceId`, `seq`, `opId`, and latency.
Never `payload`, never rendered text, never the room code, never a cursor's document content.

- Client events go to Sentry through `sentry_flutter`, with scrubbing enabled. A test error
  must arrive with no payload text (NFR-09).
- The relay logs through `log/slog` at `LOG_LEVEL`; production runs at `info`.
- Prometheus `/metrics` exposes counters and histograms — no identifiers beyond what is needed
  to operate.
- A future log line that would include a payload is a security bug, not a style issue.

## 6. Secrets

| Secret | Where it lives |
| --- | --- |
| `DATABASE_URL` (production) | GitHub secret, Render environment. Never in the repo. |
| `SENTRY_DSN` | Local: `--dart-define=SENTRY_DSN=...` from the owner's shell. CI: GitHub secret. |
| `AGE_RECIPIENT`, `RCLONE_GDRIVE_TOKEN` | GitHub secrets for the backup job. |
| Device UUID | Device secure storage. Not a secret in the cryptographic sense. |

No `.env` file is committed. If an example file is needed it is `.env.example`, and it
contains names only, never values.
`.env`, `*.key`, `*.pem`, `*.keystore`, `secrets/` and SSH keys are never read, written,
printed, or committed by an agent. A leaked secret is rotated first and discussed second.

## 7. Backups

Backups are encrypted before they leave the machine and are a **human-only** operation:

```bash
pg_dump "$DATABASE_URL" -Fc -f backup.dump
age -r "$AGE_RECIPIENT" -o backup.dump.age backup.dump
rclone copy backup.dump.age gdrive:weft-backups/
```

Restore is equally human-only, and it runs against staging, never production, except in a
declared incident. One real restore drill happens in M4 and is recorded as an ADR (OR-05).
An untested backup is a rumour.

Agents do not run `pg_dump`, `pg_restore`, `age`, `rclone`, `ssh`, `scp`, or `sudo`.

## 8. Dependencies and scanning

- `STACK.md` is the allowlist. An unlisted package needs an ADR before it appears in a
  manifest; `just drift` compares the manifests against STACK.
- Nightly: `govulncheck` for Go, `gitleaks` for committed secrets.
- Pre-commit: `gitleaks` on staged changes.
- Forbidden outright: CRDT libraries, analytics, push, background sync, Firebase/Supabase.

## 9. Reporting

Open a private security advisory through the repository's Security tab. Do not open a public
issue with reproduction steps. There is no bug bounty; there is a sincere thank-you.

## 10. Known gaps

- No E2EE: the operator can read documents.
- No account recovery: lose the device, lose the local document unless it syncs.
- No audit trail of who joined with a room code.
- No code revocation or rotation without changing the document.
- Free-tier production sleeps, so an attacker's timing and a user's are both noisy; do not
  read uptime data as evidence of anything.
