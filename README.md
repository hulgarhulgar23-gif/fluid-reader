# Fluid Reader

[Website](https://hulgarhulgar23-gif.github.io/fluid-reader/) ·
[Download](https://github.com/hulgarhulgar23-gif/fluid-reader/releases/latest) ·
[Power User Guide](docs/POWER_USER_GUIDE.md)

Fluid Reader is a small macOS menu-bar app. Press `Option + Shift + Space` for Commands, or `Option + Shift + R` to draw around any screen content and read the text it finds.

## Project Snapshot

- Local-first by default: screen capture stays on the Mac, OCR uses Apple Vision, speech uses macOS voices, and AI is optional.
- Real shipped app: there is a public [website](https://hulgarhulgar23-gif.github.io/fluid-reader/), a downloadable macOS [release](https://github.com/hulgarhulgar23-gif/fluid-reader/releases/latest), and a Homebrew cask install path.
- Maintained in public: the repo is MIT-licensed and includes [CONTRIBUTING.md](CONTRIBUTING.md), [SECURITY.md](SECURITY.md), [SUPPORT.md](SUPPORT.md), and [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md).
- Release and maintainer work are checked in CI on macOS, including `swift test`, docs checks, release packaging checks, public release safety checks, and open-source readiness checks.

The default mode is local:

- Screen capture stays on the Mac.
- OCR uses Apple Vision.
- Speech uses the macOS voices.
- LLM support is off until the user turns it on.

## Install

Download the latest `FluidReader.zip` from
[Releases](https://github.com/hulgarhulgar23-gif/fluid-reader/releases),
unzip it, and move `FluidReader.app` to `/Applications`.

Or install with Homebrew:

```sh
brew install --cask hulgarhulgar23-gif/fluidreader/fluid-reader
```

### First launch on macOS

Current builds are not yet notarized by Apple, so the first launch needs one
extra step: right-click (or Control-click) `FluidReader.app`, choose **Open**,
then click **Open** in the dialog. macOS remembers the choice; later launches
are normal. See `docs/RELEASE_SIGNING.md` for the notarized-release plan.

To check for new versions later, use **Check for Updates** in the menu-bar
menu. The app never checks in the background.

## Build

```sh
swift build -c release
```

To make a small `.app` bundle:

```sh
zsh scripts/build_app.sh
```

The app will be at:

```text
.build/FluidReader.app
```

To make a small zip for sharing:

```sh
zsh scripts/package_app.sh
```

The zip will be at:

```text
.build/FluidReader.zip
```

To check build, package size, and launch:

```sh
zsh scripts/verify_release.sh
```

## Use

1. Open `FluidReader.app`.
2. Allow Screen Recording when macOS asks.
3. Press `Option + Shift + Space` to open Commands.
4. Run `Pick and Read` or press `Option + Shift + R`.
5. Draw a freehand shape around the content, then release to read it.

When onboarding recovery is active, press `Option + Shift + L` for `Launch Recovery Next` from anywhere.
Inside Commands, the same recovery route is also available with `Option + Command + R` (and `Command + 1` from Top Picks as fallback).
If no fresh launch-recovery route is active, `Option + Shift + L` now auto-reroutes to the best available onboarding recovery command and shows a `Recovery Rerouted` cue.
In Commands `Top Picks`, a live confidence chip now previews launch-recovery behavior (`⌥⇧L Direct`, `⌥⇧L Reroute`, or `⌥⇧L Standby`).
When that confidence chip is `⌥⇧L Direct`, Top Picks also shows a `Press ⌥⇧L now` cue so you can fire the recovery run immediately.
Top Picks now also tracks the last six palette opens with a compact `Trend D·R·S` chip so operators can see whether direct runs are improving, reroutes are carrying, or standby is dominant.
Top Picks now also surfaces a `Confidence <score> · <tier>` scorecard signal that blends readiness trend plus direct streak (`current` + `best`) and promotes a one-tap coach step when confidence drops.
When confidence is low (`Watch`/`Critical`), the scorecard now surfaces an intervention queue (`Coach Step`, `Recovery Next`, and best follow-up actions) so operators can recover routing without searching.
Those follow-up interventions now adapt their ordering based on observed confidence impact from prior runs.
If an intervention score goes stale across repeated opens, it now decays back toward neutral so fresh outcomes drive ordering.
When confidence is `Critical`, stale intervention scores decay faster so outdated recovery bias clears sooner.
When an intervention runs but confidence barely moves, the score now dampens toward neutral immediately to avoid sticky overconfidence.
Intervention impact score memory now persists across app relaunches, so recovery ordering keeps learning between sessions.
When an intervention has recorded impact, the queue button now shows a color-coded live score chip (`+N`/`-N`) directly in the card.
That same intervention chip now also marks score freshness (`Recent` vs `Stale`) so operators know whether impact confidence is still current.
Top Picks now also shows an `Intervention Trust` micro-trend (with sparkline and delta) so teams can see whether recovery ordering intelligence is getting more reliable or drifting.
When reroute or standby dominates that trend, Top Picks now surfaces a `Coach` card with a one-tap recovery step to help restore `⌥⇧L Direct`.
When direct routing returns after reroute/standby, Top Picks now flashes a short `Direct Restored` pulse so the confidence rebound is visible immediately.
If that coach keeps repeating across consecutive opens, Top Picks now flashes a brief `Recovery Drift` pulse badge to make prolonged confidence decay impossible to miss.
When the confidence tier shifts between opens, Top Picks now emits a short `Confidence Rising`, `Confidence Prime`, or `Confidence Drop` pulse so trend direction changes are immediately visible.
When intervention trust swings hard between opens, Top Picks now emits `Intervention Trust Rising`/`Intervention Trust Recovered` and `Intervention Trust Dip`/`Intervention Trust Alert` pulses so both rebounds and regressions are visible immediately.
When trust rebounds across consecutive opens, Top Picks now also shows a `Trust Momentum xN` badge so hot recovery streaks are impossible to miss.
When that rebound streak hits milestones (`x3`, `x5`, `x10`, then every `+5`), Top Picks now flashes a short `Trust Momentum Milestone` pulse so recovery wins feel immediate.
When trust momentum is active and confidence is stable, Top Picks now surfaces a proactive `Trust Surge` card with a one-tap next step to compound toward the next momentum milestone.
When trust starts sliding before confidence fully degrades, Top Picks now also surfaces a proactive `Trust Guard` card with one-tap recovery action routing.
In `Settings -> Fame Ops`, you can opt into `Launch recovery auto-coach` so repeated `Recovery Drift` cues auto-run the active coach step with a configurable cooldown.
In `Settings -> Fame Ops`, you can also enable `Launch recovery auto Trust Surge` so 1-open-to-milestone `Trust Surge` setups auto-run the selected momentum step with cooldown + optional daily cap protection.
When `Trust Surge` is active, Top Picks now shows an in-row `Auto Surge` status chip (`Off`, `Armed/Ready`, cooldown, or daily cap hit), an `Auto surged Xm ago` recency chip, an `Auto League` tier chip (`Starter`, `Rising`, `Elite`, `Legend`), an `Auto Streak xNd` badge for consecutive auto-run days, and an `Auto Week N` badge for current weekly run volume, plus short `Auto League ... Unlocked` promotion pulses when tier upgrades land and a one-tap `Enable Auto` control directly inside the Trust Surge card.
When confidence does not need attention, Top Picks now also shows an `Auto Surge Engine` insight card (`Primed`, `Climbing`, `Podium Pace`, `Cooling`, `Capped`, or `Paused`) with compact today/week/streak telemetry so teams can read momentum at a glance.
When confidence does not need attention, Top Picks now also shows an `Auto League` race card (`N points to Rising/Elite/Legend` or `Legend Locked`) so teams can see real-time progression to the next league tier, plus a compact `League Heat` / `League Holding` / `League Drift` momentum chip based on recent weekly history.
When Legend is active and weekly momentum turns flat or down, Top Picks now surfaces a proactive `Legend Defense` card plus a `Legend Decay Forecast` card (risk level + next defense window), emits short `Legend Risk Alert` / `Legend Defense Window Open` pulse badges when risk escalates or timing opens, and now promotes the forecast-selected defense command to the front of Top Picks while risk is `High` (then keeps that promotion sticky for a few opens), with one-tap recovery action routing and optional `Enable Auto` so tier slippage is harder to miss.
While that sticky carry-over is active, Top Picks now shows a `Legend Hold N` badge so operators can see exactly how many opens remain before the forced promotion expires.
In `Settings -> Fame Ops`, Auto Trust Surge now also includes a configurable `Legend risk sticky Top Picks window` (how many opens the promoted defense action stays pinned after `Legend Risk Alert`) plus optional `Legend risk hold until recovered` (auto-extends that hold while the decay forecast remains active), and a persistent weekly `Auto League history` timeline with per-week score/tier snapshots, a latest tier-shift signal, and a rolling league momentum readout.

Open the menu-bar item for reader controls, setup checklist, and Fame exports (`Copy Win Recap`, `Copy Launch Kit`, `Copy Fame Board`, `Copy Fame Sprint`, `Run Fame Sprint`, `Run Fame Sprint + Save Snapshot`, `Run Weekly Fame Rollup`, `Run Daily Fame Mission`, `Run Fame Command Center`, `Run Fame Breakthrough Forecast`, `Run Fame War Room`, `Run Daily Fame Checkpoint`, `Run Fame Narrative Lab`, `Run Fame Spotlight Pack`, `Run Fame Launch Day Script`, `Run Fame Launch Countdown`, `Run Fame Pulse Nudge`, `Open Fame Snapshot Folder`, `Copy Fame Pack`, `Copy Founder Presets`, `Save Fame Pack`, `Copy Win Card Image`).

`Run Weekly Fame Rollup` reads the snapshot ledger and produces a score trend plus top experiment recommendations for the next week.
`Run Daily Fame Mission` turns the same ledger into a 3-hour route with command stack, must-ship alert, and a saved mission artifact for operator handoffs.
`Run Fame Command Center` generates a 72h operator brief, saves it to FameSnapshots, and copies it for rapid execution.
`Run Fame Breakthrough Forecast` projects conservative/base/upside 7-day score trajectories, estimates next stage ETA, saves the forecast, and copies it for fast founder alignment.
`Run Daily Fame Checkpoint` generates a day-over-day KPI delta brief, saves it to FameSnapshots, and copies it for immediate execution.
`Run Fame Narrative Lab` generates three publish-ready narrative routes (each with X + LinkedIn + reply openers), saves the lab artifact, and copies it for same-day distribution.
`Run Fame Spotlight Pack` converts current pulse + route signals into a multi-channel spotlight set (X primary/follow-up, LinkedIn, partner DM, checklist draft, and reply ladder), saves it to FameSnapshots, and copies it.
`Run Fame Launch Day Script` converts the same live route + pulse signals into a timed 180-minute launch timeline with ready-to-post copy blocks and operator checklist steps, then saves and copies it.
`Run Fame Launch Countdown` reads the latest launch script and generates a real-time timeline status with the exact next action to ship now, then saves and copies it.
`Run Launch Rescue Burst` is a one-command launch triage bundle: it refreshes launch countdown, saves a fresh next-move handoff, saves a recovery checklist, and copies a ready-to-post draft pack (or the handoff fallback) for immediate operator execution.
`Run Fame Pulse Nudge` checks streak health and days-since-snapshot, then issues a must-ship alert with an immediate action block.
`Run Next Move + Copy Draft Pack` now outputs channel-ready `X`, `Bluesky`, `LinkedIn`, and `Checklist` blocks plus follow-up and A/B/C hook variants, with a risk + momentum-aware recommended first hook per channel and a 60-minute publishing cadence plan, then auto-saves the draft pack artifact for reuse.
`Open Latest Next Move Draft Pack` opens the most recent saved draft-pack artifact so operators can repost or remix without regenerating.
`Copy Launch Now Sequence` copies one launch-ready block with the recommended 0-15m cadence step plus the next two channel drafts so operators can post continuously without context switching.
`Copy Post Cadence Now` copies only the first cadence post text (no metadata) for instant publishing.
`Copy Latest X Draft`, `Copy Latest Bluesky Draft`, and `Copy Latest LinkedIn Draft` let operators grab a single channel post in one tap from the latest next-move handoff.
`Copy First Cadence Step` copies the exact recommended 0-15m post block (channel + draft + next cadence beat) from the latest next-move handoff.
`Run Fame Sprint + Save Snapshot` now also auto-generates and saves both Daily Checkpoint and Pulse Nudge artifacts after each snapshot.
In `Settings -> Fame Ops`, you can disable auto-pulse entirely or keep it on in quiet mode, mute launch threshold alerts while keeping launch badges active, toggle launch health transition pulses on/off, enable/disable pressure-streak auto rescue, opt into launch-recovery auto-coach, and tune cooldowns for launch health pulses, pressure auto rescue (`No cooldown` = every eligible streak event), escalation auto bundle, launch rescue auto-burst, and launch-recovery auto-coach.
When pulse risk reaches High/Critical, Command Palette Top Picks surfaces a `Fame Pulse Alert` card that jumps straight into recovery.
In the same High/Critical pulse state, Top Picks now also prioritizes `Copy Launch Now Sequence`, `Copy Post Cadence Now`, `Copy First Cadence Step`, and one-tap `Copy Next-Move X/Bluesky/LinkedIn Draft` actions so posting can start immediately without opening the full pack.
When a launch countdown exists, Command Palette Top Picks also surfaces a pinned `Launch Countdown` card with urgency scoring (`Prep/Ready/Live/Hot/High/Critical`) plus the exact `Next action now` step, refreshed each time you open Commands.
When a launch countdown exists, Command Palette Top Picks also surfaces a `Launch Health` card (`Ready`, `Watch`, `Risk`) that now includes pulse readiness/suppression, same-day transition counts, and a compact `today vs 7-day avg` delta signal plus a momentum tag (`Signal Pressure`, `Signal Recovery`, or `Signal Baseline`). During `Watch` states, `Signal Pressure` now proactively routes one-tap recovery to `Run Launch Rescue Burst`.
If launch pressure persists for multiple days (`Pressure streak 2d+`), Fluid Reader now auto-runs rescue burst autopilot (while launch status is `Watch`/`Risk`), with on/off and cooldown controls in `Settings -> Fame Ops` (`No cooldown` runs every eligible streak event), so operators always have a fresh launch triage snapshot ready.
Launch health now raises a low-noise transition pulse only on `Watch -> Risk` (escalation) and `Risk -> Ready` (recovery), with configurable cooldown in `Settings -> Fame Ops`.
If launch threshold alerts are muted while countdown urgency reaches High/Critical, Command Palette Top Picks prioritizes an `Unmute Threshold Alerts` rescue card so operators can re-enable HUD/flash alerts in one tap.
Use `Snooze Threshold Alerts` presets (`10m`, `30m`, `60m`) in Fame menu or Commands to mute launch HUD/flash alerts temporarily; alerts auto-unmute when the snooze window ends.
Use `Smart Snooze (Recommended)` to auto-pick a snooze window from live launch urgency (`10m` for High/Critical, `30m` for Live/Hot, `60m` for Prep/Ready).
When a launch snooze is about to end (<=5m) during Ready/Live/Hot urgency, Command Palette Top Picks surfaces an `Unmute` reminder card plus an adjacent `Extend Snooze` card with urgency-mapped minutes so operators can react in one tap.
The near-expiry reminder is intentionally low-noise: it surfaces once per snooze window, then resurfaces only if launch urgency worsens.
The `Fame` submenu now mirrors that suppression logic with a live `Launch Snooze Reminder` status line (`Armed`, `Suppressed`, `Waiting`, or `Inactive`) so operators can trust when reminder cards will or will not appear, and when actionable it now runs the fastest next move directly (`Click: Extend ...` in launch window states, `Click: Unmute now` when urgency is High/Critical) with explicit quick-action confirmation feedback plus a short anti-spam cooldown on repeated identical taps (including a live in-line `Cooldown Xs` badge countdown and a subtle ready pulse when cooldown ends).
Reminder copy now includes explicit `Why now` context so operators can see the trigger condition at a glance.
`Run Fame Next Move` now chooses and runs the best immediate command for the current pulse + scorecard state (including auto-routing to `Run Fame Spotlight Pack` when momentum is exceptional and risk is low, or `Run Fame Breakthrough Forecast` when momentum is strong), auto-saves and copies a founder handoff markdown artifact, and the Fame menu shows the currently selected move in-line.
`Run Fame War Room` now generates a founder launch-control brief in-app from the latest saved next-move handoff, saves it to FameSnapshots, and copies it for immediate posting/ops handoff (run `Run Fame Next Move` first if no handoff exists yet).
For async sharing, `zsh scripts/generate_founder_fame_next_move_draft_pack.sh --next-move-handoff docs/campaigns/<week>-founder-fame-next-move-handoff.md --out docs/campaigns/<week>-founder-fame-next-move-draft-pack.md` produces ready-to-paste `X`, `LinkedIn`, and checklist copy blocks.
For operator execution, `zsh scripts/generate_founder_fame_war_room.sh --command-center docs/campaigns/<week>-founder-fame-command-center.md --next-move-handoff docs/campaigns/<week>-founder-fame-next-move-handoff.md --next-move-draft-pack docs/campaigns/<week>-founder-fame-next-move-draft-pack.md --out docs/campaigns/<week>-founder-fame-war-room.md` creates a one-sheet run brief.
Use `Open Latest Next Move Handoff` to reopen founder artifacts for rapid checklist posting.
Use `Open Latest Narrative Lab` to reopen the latest route board + channel drafts.
Use `Open Latest Spotlight Pack` to reopen the latest publish-ready spotlight copy set.
Use `Open Latest Launch Day Script` to reopen the latest timed launch execution script.
Use `Open Latest Launch Countdown` to reopen the latest real-time launch step tracker.
Use `Open Latest Launch Rescue Burst` to reopen the latest triage bundle with launch status, next move, and recovery checklist outputs.
The menu bar icon now reflects both pulse risk and launch urgency (prep/live/hot/high/critical), and still escalates to warning symbols for High/Critical pulse risk.
Crossing launch thresholds (into Live, Hot, High, or Critical; plus recovery from High/Critical) now triggers an in-app launch alert pulse with HUD + status flash so operators do not miss critical moments.
When launch urgency escalates into `High` or `Critical`, Fluid Reader now auto-saves a `Launch Rescue Burst` (cooldown-protected, configurable in `Settings -> Fame Ops`) so operators always have a fresh triage bundle ready without manual setup.
Command Palette now includes a live `Launch Rescue Auto` status card (`Enable`, `Run Now`, or `Cooldown Xm`) so operators can instantly enable automation, force a fresh rescue burst, or open the latest saved burst during cooldown.
Fame now has a compact `Launch Control` submenu that groups launch alert, rescue automation, threshold-alert toggles/snooze controls, and fastest launch recovery actions in one place.
Inside `Fame -> Launch Control`, the live `Launch Rescue Auto: ...` row lets operators enable automation, run a fresh rescue burst when ready, or open the latest burst while cooldown is active.
Inside `Fame -> Launch Control`, the live `Launch Health: ...` row (`Ready`, `Watch`, `Risk`) now also shows pulse suppression/readiness, same-day `Watch -> Risk` and `Risk -> Ready` transition counts, quick trend signal (`Improving ↑`, `Worsening ↓`, or `Steady →`), `today vs 7-day avg` deltas, a momentum tag (`Signal Pressure`, `Signal Recovery`, or `Signal Baseline`), and a `Pressure streak Nd` badge when pressure is persistent, while still running the exact `Click:` action in one tap (including proactive rescue routing on pressure spikes during `Watch`).
`Copy Launch Control Brief` (in `Fame -> Launch Control` and Commands) snapshots live launch alert, rescue automation, threshold-alert state, launch health pulse readiness/cooldown, same-day launch-health transition counts, trend, and `today vs 7-day avg` deltas into one copy-ready handoff.
`Run Launch Control Brief` refreshes launch countdown (when a launch script exists), then saves, copies, and opens the latest launch-ops snapshot in one step.
Use `Open Latest Launch Control Brief` to reopen the newest saved launch-ops snapshot.
The `Fame` submenu now shows a live `Pulse Risk: ...` line plus streak/lead detail (click the risk line to run the best next move: escalation nudge, recovery sprint, or pulse nudge).
The same `Fame` submenu now also shows a live `Launch Alert: ...` urgency line that runs `Run Fame Launch Countdown` when clicked.

## Feel

The app has small built-in sounds and haptic taps for pick, draw, capture, scan, and success. They are made in code, so there are no large audio files. You can turn them off or change the sound level in Settings.

The `Hit` slider controls how strong the reward moment feels. Higher values add a little more lift to sound, haptics, glow, and the success HUD.

The sound `Style` picker gives three generated palettes: `Soft`, `Glass`, and `Jackpot`.

The menu bar has a `Feel` submenu for quick tuning.

Inside `Feel`, use `Sound Style` to switch styles quickly and then run `Preview Feel`.

Use `Compare Styles` from the menu bar to hear `Soft`, `Glass`, and `Jackpot` back to back. It restores the old style after the comparison.

The `Hit Level` submenu gives quick presets: `Calm`, `Bright`, and `Max`.

Use `Big Win Preview` from the menu bar to switch to `Jackpot + Max` and play the strongest full preview.

Use `Preview Feel` from the menu bar, or `Test Full Feel` in Settings, to hear and see the full tap, scan, capture, and success loop without taking a screen pick.

A small floating HUD appears after capture, so local mode still gives a clear reward moment even when the reader window is hidden. While the app reads, the HUD shows three small moving reels. On success, they land into a three-symbol win with a short sparkle burst and a slightly longer hold.

The menu-bar icon flashes during pick, scan, success, and error states. The lasso also has a soft glow and moving glints while the user draws. The overlay fades in and out quickly, so capture and cancel do not feel abrupt.

## Speed

Fluid Reader is native Swift and has no bundled sound files. The release app is meant to stay small and fast to build. Run this check any time:

All sound styles are cached at launch, so style switching, comparison, and Big Win previews do not need to generate sound data during the interaction.

The app also warms the audio path with a silent generated sound at launch, which helps the first real tap feel instant.

The picker animation runs only while the overlay is open. Its lasso path is cached between point changes, so moving glints and glow do less work per frame.

```sh
zsh scripts/check_fast.sh
```

## Optional LLM

LLM is off by default. To use it, open Settings, turn on LLM, and add an OpenAI API key. The app can then ask about the selected text and image. Cloud voice for LLM answers is also optional, and its voice style can be changed in Settings.

## Founder & Growth Docs

See [docs/FOUNDER_FAME_UPLIFT_TRACKER.md](docs/FOUNDER_FAME_UPLIFT_TRACKER.md) for adaptive outcome uplift multipliers.
See [docs/FOUNDER_FAME_WEIGHT_PROFILE.md](docs/FOUNDER_FAME_WEIGHT_PROFILE.md) for signal weighting by recent outcomes.
See [docs/FOUNDER_FAME_MOMENTUM_BRIEF.md](docs/FOUNDER_FAME_MOMENTUM_BRIEF.md) for 48-hour founder readiness briefs.
See [docs/FOUNDER_FIRST48H_POST_PACK.md](docs/FOUNDER_FIRST48H_POST_PACK.md) for Day 0/Day 2 posting packs.
See [docs/FOUNDER_FAME_OPPORTUNITY_RADAR.md](docs/FOUNDER_FAME_OPPORTUNITY_RADAR.md) for ranked founder bets.
See [docs/FOUNDER_FAME_EXECUTION_SPRINT.md](docs/FOUNDER_FAME_EXECUTION_SPRINT.md) for day-by-day execution boards.
See [docs/FOUNDER_FAME_EXECUTION_SCORECARD.md](docs/FOUNDER_FAME_EXECUTION_SCORECARD.md) for readiness scoring.
See [docs/FOUNDER_FAME_RISK_RESPONSE_PLAN.md](docs/FOUNDER_FAME_RISK_RESPONSE_PLAN.md) for mitigation routing.
See [docs/FOUNDER_FAME_ESCALATION_QUEUE.md](docs/FOUNDER_FAME_ESCALATION_QUEUE.md) for owner-routed escalations.
See [docs/FOUNDER_FAME_COMMAND_CENTER.md](docs/FOUNDER_FAME_COMMAND_CENTER.md) for daily founder control sheets.
See [docs/FOUNDER_FAME_WAR_ROOM.md](docs/FOUNDER_FAME_WAR_ROOM.md) for one-sheet launch control and draft execution.
See [docs/FOUNDER_FAME_SPOTLIGHT_PACK.md](docs/FOUNDER_FAME_SPOTLIGHT_PACK.md) for spotlight drafts and reply ladders.
See [docs/FOUNDER_FAME_BREAKOUT_PLAN.md](docs/FOUNDER_FAME_BREAKOUT_PLAN.md) for 7-day breakout cadence planning.
See [docs/FOUNDER_FAME_EXCEPTIONAL_LOOP.md](docs/FOUNDER_FAME_EXCEPTIONAL_LOOP.md) for a 72-hour operator loop from live ledger signals.
See [docs/FOUNDER_FAME_OUTREACH_SPRINT.md](docs/FOUNDER_FAME_OUTREACH_SPRINT.md) for creator and guesting outreach execution.
See [docs/FOUNDER_FAME_PROOF_LOOP.md](docs/FOUNDER_FAME_PROOF_LOOP.md) for 72-hour proof loops.
See [docs/FOUNDER_FAME_KPI_SNAPSHOT.md](docs/FOUNDER_FAME_KPI_SNAPSHOT.md) for KPI-first founder standups.
See [docs/FOUNDER_FAME_VELOCITY_SCOREBOARD.md](docs/FOUNDER_FAME_VELOCITY_SCOREBOARD.md) for founder velocity scoring and priority moves.
See [docs/FOUNDER_FAME_NARRATIVE_LAB.md](docs/FOUNDER_FAME_NARRATIVE_LAB.md) for narrative routes and distribution calendars.
