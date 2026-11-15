# Daily puzzle plan

Decided 2026-11-14.

## The plan

- **Everyone gets the same puzzle each day.** The server decides what "today" is, not the player's device.
- **The day changes at midnight Eastern time.** Use the time zone `America/New_York` (Python's `zoneinfo`), not a fixed "EST" offset. EST is UTC−5 only in winter; in summer the East Coast is on EDT (UTC−4). The named zone handles that switch, so the reset stays at 12:00 AM all year.
- **I pick which puzzle goes on which date.** Example: 12:00 AM 11/16/2026 → puzzle #39.
- **Difficulty ramps up through the week.** Easy early in the week, harder toward the end. 11/16/2026 is a Monday, a good first day.
- **No puzzle repeats.**

## Why

- Same puzzle for everyone means leaderboards and "did you get today's?" line up.
- The server deciding the date means nobody can see tomorrow's puzzle by changing their clock.
- Choosing puzzles by hand (instead of counting days since launch) gives me control over difficulty and lets me save special boards for contest days.
- LinkedIn's games work the same way, but they reset at midnight Pacific (3 AM Eastern).

## Time zones with `zoneinfo`

- `zoneinfo` is part of Python's standard library (3.9+), so there's nothing to install with uv. Import `ZoneInfo` from it.
- Create a time zone from its **IANA name**: `ZoneInfo("America/New_York")`. These are the standard "Region/City" names (`America/Los_Angeles`, `Europe/London`, ...).
- To get "today" in Eastern time: get the current time *in that zone* (pass the zone to `datetime.now(...)`), then take `.date()` of the result. That date is what I look up in the schedule.
- Don't use plain `datetime.now()` or `date.today()`. Those use the server's own clock and time zone, and a hosted server is often set to UTC. Midnight UTC is 7–8 PM Eastern, so the puzzle would change in the evening.
- Use the named zone, not a fixed offset like UTC−5. `zoneinfo` knows the daylight saving rules (EST UTC−5 in winter, EDT UTC−4 in summer) and switches on its own.
- Where the zone data comes from: on Linux, `zoneinfo` reads it from the operating system. Some minimal servers or Docker images don't have it, and `ZoneInfo("America/New_York")` fails. The fix is to add the `tzdata` package (`uv add tzdata`), which bundles the data.

## What I have right now

- `generate_puzzles.py` makes puzzles and writes `puzzles.json`.
- `puzzles.json` has 90 puzzles, grouped by difficulty:
  - #1–30 Easy
  - #31–60 Medium
  - #61–90 Hard
- `main.py` always serves puzzle #1, no matter the date.

90 puzzles is about 12–13 weeks. Generate more before they run out, and make sure new ones don't duplicate old ones (the generator only checks for duplicates within a single run).
2 days easy Mon/Tues
3 days medium Wed/Thurs/Fri
2 days Hard Sat/Sun

15 weekends which is a little bit under 4 months
30 hard
45 medium
30 easy
Need 105 puzzles

## Steps

1. **Store the schedule:** a list of date → puzzle number pairs. Each date can have only one puzzle, and each puzzle can be used only once.
   - Start: a JSON file or a `date` field on each puzzle.
   - Later: a SQLite table with a `date` column marked unique (I'll need a database for player stats anyway).
2. **Work out "today" on the server:** the current date in `America/New_York` (see "Time zones with `zoneinfo`" above).
3. **Look up today's puzzle** in the schedule.
4. **Add an endpoint** like `GET /puzzle/today` that returns the puzzle number, the grid and the solution. The game can show "Minidoku #39".
5. **Decide what happens if a date isn't scheduled** (I forgot to fill it in, or ran out). Return an error? Fall back to some puzzle? Don't let it crash.
6. **Plan the weekly difficulty pattern.** For example: Mon–Tue Easy, Wed–Thu Medium, Fri–Sun Hard. Pick a pattern and fill the schedule a few weeks ahead.

## Things to remember

- Run the server from inside `backend/` (`uv run fastapi dev main.py`). `puzzles.json` is opened with a relative path, so starting from anywhere else gives a FileNotFoundError.
- Streaks and stats (later) have to use this same midnight-Eastern day, or they won't agree with the puzzle schedule.
- Contest days (later): don't send the solution. The game submits the board and the server checks it.

## Undecided

- Exact difficulty pattern for each day of the week.
- When to switch from JSON to SQLite.
- How far ahead to schedule.


https://www.freecodecamp.org/news/work-with-sqlite-in-python-handbook/