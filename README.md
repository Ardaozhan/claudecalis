# claudecalis

Claude Code'un **memory** ve **context** yapılarının merkezi. İki işi var:
öğrenmek ve gerçek iş repolarına şablon sağlamak.

## Katmanlar

Claude Code'da bilgi dört ayrı yerde durur. Farkı bilmek işin özü:

| Katman | Yer | Ne zaman yüklenir | Ömrü |
|---|---|---|---|
| Kullanıcı memory | `~/.claude/CLAUDE.md` | Her session, tam | Kalıcı, tüm projeler |
| Proje memory | `<repo>/CLAUDE.md` | Her session, tam | Kalıcı, git'e girer |
| Dosya memory | `~/.claude/projects/<slug>/memory/*.md` | İhtiyaç halinde | Kalıcı, kişisel |
| Context | RAM | — | Session bitince gider |

Kritik ayrım: **memory hatırlama değildir.** Model hiçbir şey hatırlamaz. Memory,
her session başında context'e yeniden enjekte edilen dosyalardan ibarettir.

## Nerede Ne Var

Kaynak burada, **çalışan kopya `~/.claude/` altında.** Claude Code agent ve
command'ları sadece `~/.claude/` (ve repo içi `.claude/`) altında arar; bu repo
git'e giren kaynak, `~/.claude/` ise kurulmuş hâli.

```
claudecalis/            ← kaynak (düzenleme burada yapılır)
  agents/               →  ~/.claude/agents/
  commands/             →  ~/.claude/commands/
  skills/               →  ~/.claude/skills/
  templates/            →  kopyalanmaz; elle repolara düşürülür
  install.ps1           ← kopyalamayı yapan script
```

Kurulum:

```powershell
.\install.ps1 -DryRun    # ne yapacağını göster, dosyaya dokunma
.\install.ps1            # kur; farklı bir dosyanın üstüne yazacaksa önce yedekler
```

Script aynı içerikli dosyayı atlar, farklı olanı `~/.claude/backups/install-<tarih>/`
altına yedekler. Kurulumdan sonra **Claude Code yeniden başlatılmalı.**

> Not: `.ps1` dosyaları **BOM'lu UTF-8** kaydedilmeli. Windows PowerShell 5.1
> BOM görmezse dosyayı ANSI sanır, Türkçe karakterler ve `—` parse hatasına yol
> açar.

Elle yazılanların tam listesi: `~/.claude/MINE.md`.

## Neler Kuruldu

### Özellik hattı — dört agent + bir command

`/feature <istek>` şu zinciri yürütür:

```
spec-writer  →  impl-planner  →  test-first  →  [ana thread]  →  change-reviewer
ne yapılacak    nasıl yapılacak   kırmızı test     yeşile çevir      denetle
```

Tasarımın anlattığı üç şey:

**Yetki, role göre kısılır.** `spec-writer`, `impl-planner` ve `change-reviewer`
agent'larında `tools:` alanında Write/Edit **yok.** Spec yazarı kod yazamaz;
denetçi kendi bulduğu hatayı düzeltemez — düzeltebilseydi denetim anlamını
kaybederdi. Bir agent'a ihtiyacından fazla yetki verilmez.

**Agent'lar sözleşmeyle konuşur.** Her agent sabit bir çıktı bloğu üretir
(`## SPEC`, `## PLAN`, `## TESTLER`, `## DENETİM`) ve girdisi gelmediyse
çalışmayı reddeder — `impl-planner`'a SPEC verilmezse plan uydurmaz, durur.
Zincirde format serbestliği, sonraki halkanın girdisini bozar.

**Uygulama adımı kasten agent'a verilmez.** Zincirin 4. adımını ana thread yapar.
Sebebi: uygulama sırasında kullanıcıya soru sormak, ara sonuç göstermek ve yön
değiştirmek gerekir. Subagent bunu yapamaz — kendi context'inde başlar, biter ve
tek bir metin döner. Subagent'ın gücü de sınırı da aynı yerden gelir.

#### Neden hepsi `model: sonnet`

Beş agent da `model: sonnet` kullanır. Gerekçe: bu agent'ların işi **sınırlı ve
formatı sabit.** Her biri belli bir girdiyi belli bir bloğa çevirir; açık uçlu
mimari muhakeme yapmazlar — o iş ana thread'de kalır. Ayrıca `/feature`'ın her
çalışması 4 agent doğurur, yani maliyet her koşuda dörtle çarpılır.

Bu bir tercih, dogma değil. `spec-writer` veya `impl-planner` büyük ve belirsiz
işlerde yetersiz kalırsa o iki agent Opus'a çekilebilir; `test-first` ve
`change-reviewer` mekanik oldukları için sonnet'te kalmalı.

### `context-auditor` — subagent

Kurulumun context maliyetini ölçer.

Neden subagent: iş onlarca dosya okumayı gerektirir. Ana thread'de yapılsa context
dolardı. Subagent kendi context penceresinde çalışır, geriye sadece tabloyu döner.
Buna **context isolation** denir ve subagent'ların asıl varlık sebebidir.

İki tasarım kararı:
- `tools:` alanı `Read, Grep, Glob, Bash` ile sınırlı — Write/Edit **kasten** yok.
  Denetçi rapor verir, karar vermez. Agent'a ihtiyacından fazla yetki verme.
- `description:` alanı, ana modelin bu agent'ı ne zaman çağıracağına karar verdiği
  **tek** bilgidir. Kötü yazılmış description = hiç çağrılmayan agent.

### `memory-hygiene` — skill

Bir bilginin hangi katmana yazılacağına karar verir.

Skill'ler **progressive disclosure** ile çalışır: normalde sadece frontmatter'daki
`name` + `description` context'te durur (~50 token). Model konunun ilgili olduğuna
karar verirse gövde o an yüklenir. Bu yüzden 46 skill'e sahip olmak 46 dosyayı
context'te taşımak anlamına gelmez.

**Agent ile skill farkı:** agent ayrı bir context'te çalışan işçidir; skill ise
mevcut context'e yüklenen talimattır.

## Yeni Bir İş Reposuna Başlarken

```bash
cp ~/claudecalis/templates/CLAUDE.md.template <repo>/CLAUDE.md
```

Doldur, doldurmadığın bölümleri sil. Kurallar için `templates/README.md`.

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
