


# claudecalis

Claude Code'un **memory** ve **context** yapılarını uygulayarak öğrenmek için
kurulmuş bir laboratuvar. Ürün kodu yok; her dosya bir kavramı gösteriyor.

## Katmanlar

Claude Code'da bilgi dört ayrı yerde durur. Farkı bilmek işin özü:

| Katman | Yer | Ne zaman yüklenir | Ömrü |
|---|---|---|---|
| Kullanıcı memory | `~/.claude/CLAUDE.md` | Her session, tam | Kalıcı |
| Proje memory | `./CLAUDE.md` | Her session, tam | Kalıcı, git'e girer |
| Dosya memory | `~/.claude/projects/<slug>/memory/*.md` | İhtiyaç halinde | Kalıcı, kişisel |
| Context | RAM | — | Session bitince gider |

Kritik ayrım: **memory hatırlama değildir.** Model hiçbir şey hatırlamaz. Memory,
her session başında context'e yeniden enjekte edilen dosyalardan ibarettir.

## Bu Repodaki Örnekler

### `.claude/agents/context-auditor.md`

Bir **subagent** örneği. Kurulumun context maliyetini ölçer.

Neden subagent: iş onlarca dosya okumayı gerektirir. Ana thread'de yapılsa
context dolardı. Subagent kendi context penceresinde çalışır, geriye sadece
tabloyu döner. Buna **context isolation** denir ve subagent'ların asıl varlık
sebebidir.

Dikkat edilecek iki nokta:
- `tools:` alanı `Read, Grep, Glob, Bash` ile sınırlı — Write/Edit **kasten** yok.
  Denetçi rapor verir, karar vermez.
- `description:` alanı ana modelin bu agent'ı ne zaman çağıracağına karar verdiği
  **tek** bilgidir. Kötü yazılmış description = hiç çağrılmayan agent.

### `.claude/skills/memory-hygiene/SKILL.md`

Bir **skill** örneği. Bir bilginin hangi katmana yazılacağına karar verir.

Skill'ler **progressive disclosure** ile çalışır: normalde sadece frontmatter'daki
`name` + `description` context'te durur (~50 token). Model konunun ilgili olduğuna
karar verirse gövde o an yüklenir. Bu yüzden 46 skill'e sahip olmak 46 dosyayı
context'te taşımak anlamına gelmez.

Agent ile skill farkı: **agent ayrı bir context'te çalışan işçidir; skill ise
mevcut context'e yüklenen talimattır.**

## Deney Disiplini

1. Değişikliği yap
2. `/clear` ile temiz session aç — eski context sonucu kirletir
3. Davranışı gözle
4. Sonucu `memory/` altına not düş

## Faydalı Komutlar

| Komut | Ne yapar |
|---|---|
| `/memory` | Memory dosyalarını düzenler |
| `/context` | Context'i ne dolduruyor, gösterir |
| `/compact` | Konuşmayı özetleyip sıkıştırır |
| `/clear` | Context'i tamamen siler |
| `/init` | Projeye `CLAUDE.md` üretir |
| `/agents` | Agent'ları listeler ve düzenler |
