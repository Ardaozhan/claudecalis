# claudecalis — Claude Code Merkezi

## Bu Proje Nedir

Ürün kodu barındırmayan **çift amaçlı** bir klasör:

1. **Öğrenme laboratuvarı** — Claude Code'un memory/context/agent yapılarını
   uygulayarak öğrenmek
2. **Şablon kaynağı** — gerçek iş repolarına düşürülecek dosyaların tutulduğu yer

Burası **kaynak repo.** Agent/skill/command dosyaları burada yazılır, `install.ps1`
ile `~/.claude/` altına kopyalanır — Claude Code onları sadece orada arar.

## Yapı

```
claudecalis/
├── CLAUDE.md                  ← bu dosya: proje seviyesi memory
├── README.md                  ← yapının açıklaması (insan için)
├── install.ps1                ← agents/ commands/ skills/ → ~/.claude/
├── validate.ps1               ← yapının kendi denetimi (CI'ın çalıştırdığı)
├── agents/
│   ├── spec-writer.md         ← özellik hattı 1/4
│   ├── impl-planner.md        ← özellik hattı 2/4
│   ├── test-first.md          ← özellik hattı 3/4
│   ├── change-reviewer.md     ← özellik hattı 4/4
│   └── context-auditor.md     ← bağımsız: context maliyeti denetçisi
├── commands/
│   ├── feature.md             ← /feature — hattı yürüten command
│   └── bootstrap.md           ← /bootstrap — iş reposuna CLAUDE.md kurar
├── conventions/               ← dil başına: tespit, komutlar, sahte yeşiller
│   ├── typescript.md  python.md  java-kotlin.md  dotnet.md
│   └── README.md
├── hooks/                     ← zorlayıcı katman (.claude/settings.json'a kayıtlı)
│   ├── protect-installed-copies.ps1   (PreToolUse)
│   ├── ensure-ps1-bom.ps1             (PostToolUse)
│   ├── validate-definition.ps1        (PostToolUse)
│   └── README.md
├── .github/workflows/
│   └── validate.yml           ← CI: windows-latest üzerinde validate.ps1
├── skills/
│   └── memory-hygiene/SKILL.md
├── templates/
│   ├── CLAUDE.md.template     ← gerçek repolara düşürülecek şablon
│   └── README.md              ← şablon doldurma kuralları
├── tests/                     ← Pester 3.4, toplam 48 test
│   ├── Uninstall.Tests.ps1    (10)  install.ps1 -Uninstall davranışı
│   ├── Hooks.Tests.ps1        (20)  üç hook'un sözleşmesi
│   └── Validate.Tests.ps1     (18)  hata/uyarı ayrımı, hook bütünlüğü, sızıntı
├── docs/                      ← agent koşularının ham çıktıları (kanıt)
│   ├── README.md
│   ├── context-audit-2026-08-03.md
│   └── pipeline-run-2026-08-03.md
└── .claude/settings.json      ← proje seviyesi ayarlar
```

Dört dizinin dört farklı ömrü var:

| Dizin | `~/.claude/`'a kurulur mu | Neden |
|---|---|---|
| `agents/` `commands/` `skills/` | **Evet** | Claude Code onları sadece orada arar |
| `conventions/` | **Evet** | Agent'lar her repoda çalışıyor; burada kalsa görünmezlerdi |
| `hooks/` | Hayır | `.claude/settings.json` mutlak yolla çağırıyor (proje seviyesinde deneniyor) |
| `templates/` | Hayır | Gerçek iş repolarına elle kopyalanır |
| `tests/` | Hayır | Sadece bu reponun kendi doğrulaması |
| `docs/` | Hayır | İnsan için kanıt arşivi |

`conventions/` context'e otomatik **yüklenmez** — agent onları `Read` ile okur.
Yani dil eklemek her session'a bedel bindirmez.

## Kurallar

- **Hazır paket kodu buraya girmez.** ECC'den gelenler `~/.claude/` altında kalır
  ve `~/.claude/MINE.md` ile ayrıştırılır.
- Elle yazılan agent/skill/command **burada** yazılır, `install.ps1` ile kurulur,
  `MINE.md`'ye satır eklenir. `~/.claude/` altındaki kopya elle düzenlenmez —
  bir sonraki kurulumda üzerine yazılır.
- Bir commit tek bir işi anlatır. Dokümantasyon değişikliği özellik commit'ine
  karıştırılmaz — `change-reviewer` bunu bulgu olarak işaretliyor.

## PowerShell Tuzakları

Bu repoda ikisi de yaşandı, ikisi de saatler yedi:

- `.ps1` dosyaları **BOM'lu UTF-8** kaydedilir. Windows PowerShell 5.1 BOM'suz
  dosyayı ANSI sanar; `—` ve Türkçe karakterler parse hatası verir. Write/Edit
  araçları BOM yazmaz — düzenledikten sonra BOM'u geri koy.
- Script'e switch geçirirken **hashtable splatlaması** kullan. Dizi splatlaması
  (`& $script @stringArray`) named parametre bağlamaz; değerler positional
  argümana dönüşüp `$args`'a düşer ve switch sessizce `$false` kalır. Hata
  vermez — bu yüzden fark edilmesi zordur.
- Bir **native komutun** (`powershell.exe`, `git`, `dotnet`) stderr'ini
  yönlendirirken (`2>$null`, `2>&1`) çağıranın `$ErrorActionPreference`
  değerine dikkat et. PowerShell 5.1 her stderr satırını `NativeCommandError`
  kaydına sarar; tercih `Stop` ise bu sonlandırıcı hataya döner ve komut doğru
  çalıştığı hâlde kod patlar. Böyle bir çağrıyı yapan fonksiyon, tercihi
  **kendi içinde** `Continue`'ya çekip `finally` ile geri koymalı — çağıranın
  ayarına güvenme.
- Tek satırlık dosyada `Get-Content` dizi değil **string** döndürür; `$Lines[0]`
  bir `Char` olur ve `Trim()` metodu yoktur. `@(...)` ile sarmala.
- Yeni bir kavram öğrenildiğinde onu gösteren **en küçük** örnek eklenir. Örnek
  büyürse ayrı bir projeye taşınır.
- Her değişiklik commit'lenir. Bir commit tek bir işi anlatır.

## Deney Yaparken

1. Değişikliği yap
2. `/clear` ile temiz bir session aç (yoksa eski context sonucu kirletir)
3. Davranışı gözle
4. Sonucu `memory/` altına not düş

## Bilinen Durum

- 2026-08-03'te sıfırdan kuruldu, aynı gün git'e alındı.
- **Her parça en az bir kez gerçekten çalıştırıldı.** Kanıtlar `docs/` altında.
  - `/feature` hattı uçtan uca koştu (`install.ps1 -Uninstall` işiyle) → ŞARTLI GEÇTİ
  - `context-auditor` iki kez koştu
  - `/bootstrap` gerçekçi bir TS reposunda koştu; yanlış README ve kırık build
    scriptini yakaladı
  - Hook'lar canlı tetiklenerek doğrulandı (BOM eklendi, yazma engellendi)
- **Context maliyeti ölçüldü: ~11.000 token.** Dağılım: memory + `rules/` %55,
  agent metadata %24, skill metadata %21. `conventions/` ve command'lar %0 —
  otomatik yüklenmiyorlar.
- Açık kalan iyileştirme: `~/.claude/rules/README.md` (~1.100 token) her session'da
  yükleniyor ama sadece kurulum rehberi; davranış kuralı içermiyor. `rules/`
  kökünden taşınırsa kazanç net.

## Bu Repoda Öğrenilen İki Kural

**Yazılmış olmak çalışmak değildir.** Bu repoda dört kez kanıtlandı: `install.ps1`
ilk çalıştırmada parse hatasıyla patladı; `context-auditor` ilk koşusunda emin bir
dille yanlış cevap verdi; `test-first`'ün yazdığı testler yanlış sebepten kırmızıydı;
`validate.ps1` kendi negatif testinde çöktü. Dördü de yazıldıklarında doğru
görünüyordu.

**Subagent'a ana context hakkında soru sorulmaz.** Kendi penceresinde çalışır,
ana thread'in context'ini göremez. `context-auditor` ilk koşusunda "bu dosyalar
yüklenmiyor" dedi çünkü dosya sistemine bakıp çıkarım yapmak zorundaydı. İkinci
koşuda göremediği bilgi kendisine verildi ve doğru cevap verdi — üstelik ilk
koşunun kaçırdığı bir kalemi de buldu.
