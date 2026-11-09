---
name: hafta
description: Arda'nın haftalık planı (C:\Users\ardao\claude\takip). Haftayı planlar, bugünün işlerini gösterir, gün sonu durumu işler, haftayı kapatır. Kullanıcı "/hafta", "haftayı planla", "bugün ne yapıyorum", "bugünün işleri", "günü kapat", "haftayı kapat" dediğinde ya da bir oturumda hangi işe öncelik verileceği sorulduğunda kullan.
---

# Hafta

Data lives in `C:\Users\ardao\claude\takip`. **Read `FORMAT.md` there before
writing anything**; Kokpit parses these files and breaks on format drift.
Talk to Arda in Turkish. Task text is Turkish.

Current week file: `weeks/<ISO year>-W<ISO week, 2 digits>.md`. Compute it, never
guess: `py -3 -c "import datetime as d;y,w,_=d.date.today().isocalendar();print(f'{y}-W{w:02d}')"`.

## Modes

Pick from the user's words; with bare `/hafta` show **bugün**.

### planla (new week, usually Monday or Sunday evening)

1. Read: previous week file (open `[ ]` tasks), `deadlines.md`, `backlog.md`,
   vault `🔮 850-Companion/Threads.md` ("Sonraki adım" of each active thread).
2. Ask Arda only what files cannot tell: this week's lessons/exams/fixed
   commitments, personal goals, days he is busy.
3. Draft: 3-5 goals; 2-4 tasks per day; deadlines in the next 14 days pulled
   forward with buffer; leave at least one day light. Carry unfinished tasks:
   mark the old line `[>]`, add a fresh `[ ]` line in the new week.
4. Show the draft, apply Arda's corrections, then write the file.

### bugün (default)

Read the current week file, show today's section plus overdue `[ ]` tasks from
earlier days and deadlines within 7 days. Suggest which task to start with and
why (deadline first, then goals). Do not edit files in this mode.

### kapat (end of day)

Ask what got done. Mark `[x]` / `[-]`; move unfinished tasks to a later day
(`[>]` on the old line, new `[ ]` line on the target day). Never delete lines.

### haftayı kapat

Fill `## Değerlendirme`: done / planned count per area, what slipped and why
(from Arda), one adjustment for next week. Then run **planla** if asked.

If this is the last week of the month, also offer a rule review with Arda:
read vault `🔮 850-Companion/Kurallar.md` and `Kurallar-Detay.md`, propose
merges/removals for rules that are duplicated, obsolete or enforced by a hook,
and check the hook context still fits (no `[truncated` in SessionStart output).
Apply only what Arda approves, via `beyin.py note-edit`.

## Rules

- Never mark a task done without Arda saying so or a verifiable result
  (commit, file, test run).
- Project status changes go to vault Threads, not the week file.
- New task outside the week → `backlog.md`. New dated item → `deadlines.md`
  (keep sorted).
- After editing, validate: every task line matches
  `^- \[( |x|>|-)\] .+ #(proje|okul|topluluk|kisisel)( @[a-z0-9-]+)?$`
  and the week has the 9 headings in order.
