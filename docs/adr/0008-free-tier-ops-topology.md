# ADR-0008: Free-tier operations topology (Render + Neon)

- Status: proposed
- Date: 2026-11-13
- Deciders: Fady Philip

> **Proposed, not accepted.** This records the intended topology before it exists. It is
> accepted when issue #7 has deployed it and `/health` answers from a public URL. Accepting
> a topology that was never deployed would make this document a plan wearing a decision's
> clothes.

## Context

The budget is $0/month (NFR-08). There is no domain, no paid database, and no always-on
home server. The relay still needs a public HTTPS endpoint that two phones can reach, plus a
Postgres instance that survives idle periods.

OR-07 demands cold-start honesty: free compute sleeps, and the README must say so rather
than pretending otherwise.

## Decision

- **Compute:** Render free web service running the distroless relay image. Spins down after
  15 minutes idle, ~1 minute cold start, 750 instance-hours/month.
- **Database:** Neon free Postgres. 0.5 GB, 100 compute-hours/month, autosuspends after 5
  minutes.
- **Keep-alive and monitoring:** a single UptimeRobot monitor pinging `/health` every 5
  minutes. One ping serves two purposes — it detects downtime and it keeps the instance
  inside its monthly hours.
- **Staging:** Docker Compose on the Dell, running only while developing.
- **Distribution:** APK via GitHub Releases on a `v*` tag. No Play Store.

## Alternatives considered

- **Render Postgres** — rejected: the free tier expires after 30 days, which would take the
  production database down mid-project.
- **Fly.io or Railway** — rejected: require a payment method, which breaks the $0 constraint.
- **Always-on home server** — rejected by OR-01, and it fails the moment the owner leaves.
- **Supabase** — rejected by the dependency policy.

## Consequences

- Cold starts are a documented design constraint, not a defect. The client retries with
  backoff and shows SYNCING.
- UptimeRobot pinging every 5 minutes must stay inside 750 instance-hours. A shorter
  interval would burn the allowance; a longer one would let the instance sleep.
- The live URL may lapse during military service. That is acceptable because the durable
  evidence is the repo, the recorded demo, and the README — not the endpoint.

## Evidence

- To be filled at issue #7: public `/health` response, UptimeRobot monitor state, Neon
  migration state.
