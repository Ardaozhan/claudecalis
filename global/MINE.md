# Kendi Yazdıklarım

`~/.claude/` altındaki çoğu şey **ECC (Everything Claude Code)** hazır paketinden
geliyor. Bu dosya, o paketten gelmeyen — **elle yazılmış** — dosyaları listeler.

Sahiplik ayrımı konumla değil bu manifestle yapılır, çünkü elle yazılanların da
her repoda çalışması gerekiyor.

## Elle Yazılanlar

Kaynağı `~/claudecalis/` reposudur; `~/.claude/` altındaki kopyalar
`install.ps1` ile üretilir. **Düzenleme repoda yapılır, sonra tekrar kurulur.**

| Kurulu kopya | Kaynağı (repoda) | Ne |
|---|---|---|
| `~/.claude/CLAUDE.md` | `global/CLAUDE.md` | Kullanıcı seviyesi talimatlar |
| `~/.claude/MINE.md` | `global/MINE.md` | Bu dosya |
| `~/.claude/agents/spec-writer.md` | `agents/` | Özellik hattı 1/4 — istek → SPEC |
| `~/.claude/agents/impl-planner.md` | `agents/` | Özellik hattı 2/4 — SPEC → PLAN |
| `~/.claude/agents/test-first.md` | `agents/` | Özellik hattı 3/4 — PLAN → kırmızı testler |
| `~/.claude/agents/change-reviewer.md` | `agents/` | Özellik hattı 4/4 — değişiklik denetimi |
| `~/.claude/agents/context-auditor.md` | `agents/` | Kurulum context maliyeti denetçisi |
| `~/.claude/agents/arda.md` | `agents/` | Türkçe grafik tasarım uzmanı — Codex Arda'nın Claude karşılığı, üretimi `codex exec` ile yaptırır |
| `~/.claude/commands/feature.md` | `commands/` | `/feature` — özellik hattı |
| `~/.claude/commands/bootstrap.md` | `commands/` | `/bootstrap` — iş reposu kurulumu |
| `~/.claude/conventions/*.md` | `conventions/` | Dil konvansiyonları (TS, Python, Java/Kotlin, .NET) |
| `~/.claude/skills/memory-hygiene/SKILL.md` | `skills/` | Bilgi hangi katmana yazılır kararı |
| `~/.claude/skills/delege/SKILL.md` | `skills/` | Codex / Antigravity (agy) delegasyonu — ne zaman, hangi komutla, nasıl doğrulanır |

Hepsi 2026-08-03'te yazıldı. `CLAUDE.md` ve `MINE.md` 2026-08-04'te versiyon
kontrolüne alındı — o güne kadar elle düzenleniyorlardı ve tek yedeksiz
parçalardı.

**Kurulu kopyalar hook ile korunuyor.** `protect-installed-copies`, yukarıdaki
yolların hepsine Write/Edit ile yazmayı engeller. Düzenleme kaynakta yapılır.

Ayrıca `~/claudecalis/hooks/` altında üç hook var ama bunlar `~/.claude/` altına
**kurulmuyor** — `claudecalis/.claude/settings.json` üzerinden yalnızca o repoda
çalışıyorlar. Olgunlaşınca `~/.claude/settings.json`'a taşınacaklar.

`memory/` bu akışın **dışında.** Kişisel notlar paylaşılan bir repoya girmez;
elle düzenlenirler ve versiyonlanmazlar.

## ECC'den Gelenler (elle yazılmadı)

- `~/.claude/agents/` — yukarıdaki 5 agent hariç 28 agent
- `~/.claude/skills/` — yukarıdaki `memory-hygiene` hariç 46 skill
- `~/.claude/commands/` — yukarıdaki `feature` hariç 60 slash command
- `~/.claude/rules/` — common + 12 dile özel kural seti
- `~/.claude/hooks/hooks.json` — PreToolUse / PostToolUse hook'ları

## Bakım

Yeni bir agent/skill/command elle yazıldığında **buraya satır eklenir.** Bu
manifest güncel tutulmazsa hiçbir işe yaramaz.

Akış:

```
~/claudecalis/<katman>/<ad>.md yaz     ← agents, commands, conventions, skills, global
  → .\validate.ps1 -SkipTests   (tanım geçerli mi)
  → .\install.ps1 -DryRun       (ne olacağını gör)
  → .\install.ps1               (kur, gerekirse yedekle)
  → global/MINE.md'ye satır ekle
  → Claude Code'u yeniden başlat
```

`~/.claude/` altındaki kopyayı düzenlemeye çalışırsan hook engeller ve seni
kaynağa yönlendirir.

## Repo dışı veri: `~/.claude/arda/`

Arda tek ajan çalışır (7 uzmanlı ekip token maliyeti ve düşük getiri nedeniyle
2026-11-04'te kaldırıldı). Akışın özü `agents/arda.md` içine gömülü. Bu klasörde
yalnız isteğe bağlı okunanlar var: `CODEX-URETIM.md` (codex exec yöntemi),
`DESIGN.md` (zor yaratıcı işler), `REFERENCE.md` + `corpus/behance/` (~9.7 MB).
`memory/` gibi **install akışının dışında**: kişisel veri, paylaşılan repoya
girmez, elle yönetilir. Orijinaller `C:\Users\ardao\ÖZGE\ozge-next\` ve Codex
tarafında duruyor, silinmedi.
