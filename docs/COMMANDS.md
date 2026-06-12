# Commands

Open Commands with `Option + Shift + Space`.

Commands is the fast place for reading, asking, copying, saving, opening, and fixing common problems.

For a fast path through the most useful commands, see [POWER_USER_GUIDE.md](POWER_USER_GUIDE.md).

## Fast Use

- Press `Return` to run the selected command.
- Press `Command + 1` through `Command + 9` to run one of the first nine shown commands.
- When Launch Recovery is active, press `Option + Shift + L` globally, or `Option + Command + R` inside Commands for the dedicated recovery quick run.
- If Launch Recovery is not active yet, `Option + Shift + L` auto-reroutes to the best available onboarding recovery command and shows a `Recovery Rerouted` cue.
- When search is empty in `All`, `Top Picks` shows context-aware next actions, can favor your pinned commands, can surface share actions like recap or card, and shows streak and milestone badges (`x3`, `x5`, ...).
- `Top Picks` now also shows a live launch-recovery confidence chip: `⌥⇧L Direct`, `⌥⇧L Reroute`, or `⌥⇧L Standby`.
- When the confidence chip is `⌥⇧L Direct`, `Top Picks` also shows `Press ⌥⇧L now` so you can trigger recovery immediately.
- `Top Picks` now also shows a six-open confidence trend chip (`Trend D·R·S`) so you can spot whether direct recovery is strengthening or if reroute/standby is taking over.
- `Top Picks` now also shows a launch-recovery confidence scorecard (`Confidence <score> · <tier>`) that blends trend plus direct streak (`current` + `best`) and promotes one-tap coach recovery when confidence is low.
- When confidence is `Watch` or `Critical`, the scorecard now shows an intervention queue (`Coach Step`, `Recovery Next`, plus best recovery follow-ups) so you can execute the right fix immediately.
- That intervention queue now adaptively reorders follow-up recovery actions using observed confidence impact from prior runs.
- Stale intervention impact scores now decay toward neutral across repeated opens so ordering stays recent instead of locking to old outcomes.
- During `Critical` confidence, stale impact scores decay on a faster cadence to clear outdated recovery priorities sooner.
- Neutral intervention outcomes now damp the score toward zero immediately so the ranking can recover from stale optimism/pessimism faster.
- Intervention impact score memory now persists across app relaunches, so launch-recovery ordering keeps learning between sessions.
- Intervention buttons in that queue now show a color-coded observed impact chip (`+N`/`-N`) whenever it is available.
- Intervention buttons now also include a freshness chip (`Recent` or `Stale`) so you can tell whether observed impact was validated recently.
- The launch-recovery scorecard now includes an `Intervention Trust` sparkline + delta, summarizing whether intervention ordering confidence is rising, stable, or slipping across recent opens.
- When reroute or standby dominates that trend, `Top Picks` now shows a `Coach` card with a one-tap corrective action (`Run Coach Step`) to restore direct recovery routing.
- When direct recovery returns after reroute/standby, `Top Picks` now emits a short `Direct Restored` pulse badge so you can confirm confidence rebound instantly.
- If the same `Coach` state persists across repeated opens, `Top Picks` now emits a short `Recovery Drift` pulse badge as an escalation cue.
- When confidence tier changes between opens, `Top Picks` now emits a short `Confidence Rising`, `Confidence Prime`, or `Confidence Drop` pulse badge so you can spot recovery direction shifts at a glance.
- When intervention trust swings sharply between opens, `Top Picks` now emits `Intervention Trust Rising`/`Intervention Trust Recovered` and `Intervention Trust Dip`/`Intervention Trust Alert` pulse badges so both rebounds and regressions are obvious.
- When intervention trust rebounds across consecutive opens, `Top Picks` now also shows a `Trust Momentum xN` badge to highlight sustained recovery streaks.
- When that trust rebound streak hits milestone tiers (`x3`, `x5`, `x10`, then every `+5`), `Top Picks` now flashes a short `Trust Momentum Milestone` pulse badge.
- When trust momentum is active while confidence is stable, `Top Picks` now shows a proactive `Trust Surge` card with a one-tap action to keep climbing to the next milestone.
- When intervention trust starts sliding before confidence drops tiers, `Top Picks` now shows a proactive `Trust Guard` card with one-tap trust-fix action routing.
- In `Settings -> Fame Ops`, you can enable `Launch recovery auto-coach` so repeated `Recovery Drift` cues auto-run the coach step with cooldown protection.
- In `Settings -> Fame Ops`, you can enable `Launch recovery auto Trust Surge` so `Trust Surge` plans that are 1 open from the next milestone can auto-run the selected momentum action with cooldown + optional daily cap protection.
- When `Trust Surge` is active, `Top Picks` now includes an inline `Auto Surge` status chip (`Off`, `Armed/Ready`, cooldown, or daily cap hit), an `Auto surged Xm ago` recency chip, an `Auto League` tier chip (`Starter`, `Rising`, `Elite`, `Legend`), an `Auto Streak xNd` badge for consecutive auto-run days, an `Auto Week N` badge for current weekly run volume, and short `Auto League ... Unlocked` promotion pulses when tier upgrades hit, plus an in-card `Enable Auto` quick action.
- When confidence does not need attention, `Top Picks` now also shows an `Auto Surge Engine` insight card (`Primed`, `Climbing`, `Podium Pace`, `Cooling`, `Capped`, or `Paused`) with compact today/week/streak scoreline telemetry.
- When confidence does not need attention, `Top Picks` now also shows an `Auto League` race card (`N points to Rising/Elite/Legend` or `Legend Locked`) so operators can track progression to the next league tier in real time, plus a compact `League Heat` / `League Holding` / `League Drift` momentum chip from recent weekly history.
- When `Legend` is active and league momentum flattens or slides, `Top Picks` now shows a proactive `Legend Defense` card plus a `Legend Decay Forecast` card (risk level + next defense window), emits short `Legend Risk Alert` / `Legend Defense Window Open` pulse badges when risk escalates or timing opens, and promotes the forecast-selected defense command to the first Top Pick while risk is `High` (with a short sticky carry-over across the next few opens), all with one-tap defense action routing (plus optional `Enable Auto`) to reduce silent tier slippage.
- During that sticky carry-over, `Top Picks` now shows a compact `Legend Hold N` badge so you can see remaining forced-promotion opens at a glance.
- In `Settings -> Fame Ops`, Auto Trust Surge now includes a configurable `Legend risk sticky Top Picks window` (how many opens the promoted defense action stays pinned after `Legend Risk Alert`), optional `Legend risk hold until recovered` (auto-extends that hold while the decay forecast remains active), and a persistent weekly `Auto League history` timeline with per-week score/tier snapshots, a latest tier-shift callout, and a rolling league momentum line.
- Use the category chips (`Core`, `Ask`, `Text`, `Saved`, `Open`, `Window`, `Settings`, `Support`) to narrow the list fast.
- Press `Control + 0` for `All`, or `Control + 1` through `Control + 8` to switch categories from the keyboard.
- Type `ask:`, `text:`, `saved:`, `open:`, `window:`, `settings:`, `support:`, or `core:` to scope search from the keyboard. Short aliases also work, such as `q:` for ask, `copy:`, `paste:`, or `calc:` for text tools, `perm:`, `grant:`, `checklist:`, or `onboarding:` for settings, `fix:`, `repair:`, `error:`, `blocked:`, `share:`, `social:`, or `post:` for support, `snip:`, `fav:`, `note:`, or `clip:` for saved items, `tile:` for window layouts, and `app:`, `file:`, `docs:`, or `site:` for app/file/web open actions.
- If a search misses, Commands now suggests trying shorter text or scope aliases (`q:`, `snip:`, `perm:`, `onboarding:`, `share:`, `fix:`, `copy:`, `calc:`, `file:`, `tile:`).
- Type a URL to open it.
- Type a URL with tracking params to copy a clean URL.
- Type a URL to copy it as a Markdown link.
- Type a path to open or reveal it in Finder.
- Type math like `2 + 3 * 4`, `what is 2 + 3 * 4?`, `sqrt(81)`, `calculate pi * 2`, `20% of 85`, `roi 1200 1000`, `margin 100 75`, `markup 125 100`, `cagr 100 121 2`, `breakeven 10000 50 30`, `runway 240000 12000`, `payback 900 75`, `ltvcac 1350 150`, `burnmultiple 120000 240000`, `nrr 1000 200 100 50`, `quickratio 120 30 50 10`, `magicnumber 250000 400000`, `rule40 35 10`, `ltv 75 18`, or `cac 12000 80` to copy the answer.
- Formula aliases also work, such as `gross margin 100 75`, `break even 10000 50 30`, `runway months 240000 12000`, `cac payback 900 75`, `payback period 900 75`, `ltv/cac 1350 150`, `burn multiple 120000 240000`, `net revenue retention 1000 200 100 50`, `quick ratio 120 30 50 10`, `magic number 250000 400000`, `rule of 40 35 10`, `customer acquisition cost 12000 80`, and `lifetime value 75 18`.
- Search `founder` to run `Copy Founder Command Presets`, `Use Founder Command Presets in Reader`, or `Paste Founder Command Presets` for a weekly KPI + growth-script bundle.
- Type units like `10 km to miles`, `convert 2 cups to ml`, or `what is 8 fl oz in ml?` to copy the conversion.
- Type times like `09:00 UTC to local`, `14:30 UTC+8 to UTC`, `09:15 UTC+5:30 to UTC-4`, `9 pm PST to EST`, or `timezone 9 pm PST to EST` to copy the time conversion.
- Type date math like `in 3 days`, `in 3d`, `in 2 business days`, `next business day`, `next business week`, `start of week`, `end of week`, `2w from now`, `this friday`, `monday`, `when is next monday?`, `start of quarter`, `end of quarter`, `start of year`, or `end of year` to copy the date result.
- Type colors like `#ff8800`, `rgb(255, 136, 0)`, or `hsl(32, 100%, 50%)` to copy HEX, RGB, and HSL.
- Type a question to ask the LLM when LLM is on.
- Search works with partial words, joined words, initials, small typos, pasted command names or ids, disabled reasons, and common aliases. For example, `rst` can find `Read Selected Text`, `assistant` can find `Ask Anything`, `tldr` can find `Summary`, `next steps` can find `Action Items`, `meeting minutes` can find `Notes`, `fix bug` can find `Code Help`, `launch announcement` can find `Launch`, `raycast` can find app launcher actions, `host` can find `Extract Domains Clipboard`, `blank lines` can find `Trim Lines Clipboard`, `duplicate lines` can find `Unique Lines Clipboard`, `tile left` can find `Window Left Half`, `cycle layout` can find `Window Cycle Layout`, `reverse layout` can find `Window Previous Layout`, `cycle profile focus` can find `Cycle Profile: Focus`, `next display` can find `Window Next Display`, `previous display` can find `Window Previous Display`, `wide right` can find `Window Right Two Thirds`, `top left corner` can find `Window Top Left Quarter`, `restore window` can find `Window Undo Last Move`, `rename snippet` can find `Edit Snippet`, `edit url` can find `Edit Link`, `setitngs` can find `Screen Recording Settings`, `accessiblity` can find `Accessibility Settings`, and `trust permission` can find `Accessibility Settings`.

## Read And Ask

- `Read Selected Text`
- `Read Clipboard Text`
- `Pick and Read`
- `Mark Screenshot`
- `Ask Anything`
- `Read Last Text`
- `Stop Speech`

Quick LLM actions use the current reader text or image first. If the reader is empty, they try selected text, then clipboard text. If neither has text, the app asks you to pick text from the screen.

Common quick actions:

- Summary
- Simple Explain
- Notes
- Action Items
- Rewrite
- Reply Draft
- Launch
- English Translation
- Mongolian Translation
- Code Help
- Questions
- Your saved prompts

## Text And Clipboard

- `Copy Selected as Quote`
- `Copy Clipboard as Quote`
- `Copy Text as Quote`
- `Copy Answer as Quote`
- `Copy Selected as Code Block`
- `Copy Clipboard as Code Block`
- `Copy Selected Pretty JSON`
- `Copy Selected Minified JSON`
- `Copy Selected Slug`
- `Copy Selected Snake Case`
- `Copy Selected Constant Case`
- `Copy Selected Camel Case`
- `Copy Selected Pascal Case`
- `Uppercase Selected`
- `Lowercase Selected`
- `Title Case Selected`
- `Single Space Selected`
- `Base64 Encode Selected`
- `Base64 Decode Selected`
- `Remove Terminal Colors Selected`
- `Trim Selected Lines`
- `Join Selected Lines`
- `Reverse Selected Lines`
- `Sort Selected Lines`
- `Unique Selected Lines`
- `Markdown Table Selected`
- `Clean CSV Selected`
- `Copy Selected as Checklist`
- `Copy Selected as Bullets`
- `Copy Selected as Numbered List`
- `Copy Selected Text Stats`
- `Markdown Checklist Clipboard`
- `Markdown Bullets Clipboard`
- `Markdown Numbered List Clipboard`
- `Markdown Table Clipboard`
- `Clean CSV Clipboard`
- `Copy Selected URL as Markdown Link`
- `Copy Clipboard URL as Markdown Link`
- `Paste Last Text`
- `Paste Answer`
- `Paste Full Result`

Paste commands need Accessibility permission. They restore your old clipboard after paste.

## URLs, Paths, Apps, And Folders

- `Open Selected URL`
- `Open Clipboard URL`
- `Search Selected Web`
- `Search Clipboard Web`
- `Copy Selected Clean URL`
- `Copy Selected URLs`
- `Copy Selected Domains`
- `Copy Selected Emails`
- `Open Selected Path`
- `Reveal Selected Path`
- `Open Clipboard Path`
- `Reveal Clipboard Path`
- `Save Selected as Link`
- `Refresh Apps`

Search an app name to open installed apps from `/Applications`, `/System/Applications`, or `~/Applications`.

Search `folder` to open Downloads, Documents, Desktop, Home, Applications, or Utilities in Finder.

## Snippets, Links, And History

- `Save Selected as Snippet`
- `Save Clipboard as Snippet`
- `Save Text as Snippet`
- `Save Answer as Snippet`
- `Copy Snippets`
- `Save Snippets`
- `Clear Snippets`
- `Pin Snippet`
- `Unpin Snippet`
- `Edit Snippet`
- `Save Selected as Link`
- `Save Clipboard as Link`
- `Copy Quick Links`
- `Save Quick Links`
- `Import Clipboard Links`
- `Clear Quick Links`
- `Pin Link`
- `Unpin Link`
- `Edit Link`
- `Copy Recent Items`
- `Save Recent Items`
- `Clear Recent Items`
- `Turn On Recent Items`
- `Turn Off Recent Items`
- `Turn On Clipboard History`
- `Turn Off Clipboard History`
- `Copy Clipboard History`
- `Save Clipboard History`
- `Clear Clipboard History`

Recent items, snippets, quick links, and clipboard history stay on this Mac. Pinned snippets and pinned links stay above normal items. Snippets and links can be renamed, and snippet text or saved link URLs can be edited later. Clipboard history is off by default.

Quick links export as Markdown links with the saved title as link text.
`Import Clipboard Links` saves every valid URL found in copied text as quick links.

## Window Commands

- `Window Left Half`
- `Window Right Half`
- `Window Top Left Quarter`
- `Window Top Right Quarter`
- `Window Bottom Left Quarter`
- `Window Bottom Right Quarter`
- `Window Left Third`
- `Window Center Third`
- `Window Right Third`
- `Window Left Two Thirds`
- `Window Right Two Thirds`
- `Window Top Half`
- `Window Bottom Half`
- `Window Maximize`
- `Window Center`
- `Window Cycle Layout`
- `Window Previous Layout`
- `Cycle Profile: Full`
- `Cycle Profile: Focus`
- `Window Undo Last Move`
- `Window Next Display`
- `Window Previous Display`

Window commands move the app you were using before Commands opened. They need Accessibility permission.
`Window Cycle Layout` rotates through common presets, so repeated runs quickly try multiple layouts.
`Window Previous Layout` runs the same cycle in reverse.
Cycle profiles change which presets the cycle commands use.

## Utilities

- `Copy UUID`
- `Copy ISO Date`
- `Copy Local ISO Date`
- `Copy Date Stamp`
- `Copy Date Time Stamp`
- `Copy UTC Date Time Stamp`
- `Copy Yesterday Date Stamp`
- `Copy Tomorrow Date Stamp`
- `Copy Week Start`
- `Copy Week End`
- `Copy Month Start`
- `Copy Month End`
- `Copy Quarter Start`
- `Copy Quarter End`
- `Copy Unix Time`
- `Copy Time Zone`
- `Copy UTC Offset`
- `Copy Strong Password`
- `Copy Secure Token`
- `Copy Hex Token`
- `Copy PIN Code`
- `URL Encode Clipboard`
- `URL Decode Clipboard`
- `Clean URL Clipboard`
- `Extract URLs Clipboard`
- `Extract Domains Clipboard`
- `Extract Emails Clipboard`
- `Base64 Encode Clipboard`
- `Base64 Decode Clipboard`
- `Pretty JSON Clipboard`
- `Minify JSON Clipboard`
- `Slugify Clipboard`
- `Snake Case Clipboard`
- `Constant Case Clipboard`
- `Camel Case Clipboard`
- `Pascal Case Clipboard`
- `Uppercase Clipboard`
- `Lowercase Clipboard`
- `Title Case Clipboard`
- `Single Space Clipboard`
- `Remove Terminal Colors Clipboard`
- `Trim Lines Clipboard`
- `Join Lines Clipboard`
- `Reverse Lines Clipboard`
- `Sort Lines Clipboard`
- `Unique Lines Clipboard`
- `Markdown Checklist Clipboard`
- `Markdown Bullets Clipboard`
- `Markdown Numbered List Clipboard`
- `Markdown Table Clipboard`
- `Clean CSV Clipboard`
- `Clipboard Text Stats`

Generated passwords and tokens are copied to the clipboard, but Fluid Reader skips its own copies when clipboard history is on.

## Settings And Privacy

- `Setup Checklist`
- `Turn On Launch at Login`
- `Turn Off Launch at Login`
- `Open Login Items Settings`
- `Pin Reader`
- `Unpin Reader`
- `Turn On Auto-Copy New Text`
- `Turn Off Auto-Copy New Text`
- `Turn On Auto-Paste Picked Text`
- `Turn Off Auto-Paste Picked Text`
- `Turn On Auto-Paste LLM Answers`
- `Turn Off Auto-Paste LLM Answers`
- `Turn On Top Picks Milestone Feedback`
- `Turn Off Top Picks Milestone Feedback`
- `Turn On LLM`
- `Turn Off LLM`
- `Screen Recording Settings`
- `Accessibility Settings`
- `Copy Settings Backup`
- `Restore Settings Backup`
- `Clear Local Reader Data`

`Clear Local Reader Data` clears current text, answer, image, recent items, snippets, quick links, clipboard history, command learning, and the activity log. It does not change settings or API keys.

## Help And OSS

- `Copy Support Info`
- `Copy Bug Report Draft`
- `Copy Issue Bundle`
- `Copy Troubleshooting Guide`
- `Copy Activity Log`
- `Clear Activity Log`
- `Copy Setup Guide`
- `Copy Win Recap`
- `Copy Win Recap Pack`
- `Copy Launch Kit`
- `Copy Experiment Board`
- `Copy Win Card`

`Copy Issue Bundle` is the easiest bug-report command. It includes support info plus the newest safe activity-log events. Use `Copy Activity Log` if you need the full safe log.
`Copy Setup Guide` includes a short share-ready post with live local usage counts you can paste to social apps.
`Copy Win Recap` copies only the short share-ready post and rotates between a few post styles.
`Copy Win Recap Pack` copies three share-ready recap variants in one block.
`Copy Launch Kit` copies a multi-channel creator pack with hooks, X + LinkedIn copy, launch blurb, a 7-day distribution sprint, KPI targets, demo script, and CTA variants.
`Copy Experiment Board` copies a ranked weekly experiment list with dynamic goals based on local saved items + safe events.
`Copy Win Card` copies a visual share card image with live local usage counts and sets it as the current image for `Save Last Image`.

See [TROUBLESHOOTING.md](TROUBLESHOOTING.md) for common permission, paste, OCR, and LLM fixes.

Support commands skip private reader content. They do not include API keys, selected text, answers, images, snippets, quick links, clipboard history, custom prompts, custom endpoints, or clipboard contents.
