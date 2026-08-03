# Hook'lar

Kuralı **zorlayan** katman.

`CLAUDE.md`'ye yazılan bir kural tavsiyedir — model çoğu zaman uyar, ama uymak
zorunda değildir ve unutabilir. Hook'u harness çalıştırır; modelin kararına
bağlı değildir. Bu ayrım, kurulumun en önemli tasarım farkıdır.

Bu üç hook rastgele seçilmedi; üçü de bu repoda **gerçekten yaşanmış** hataları
hedefliyor.

## Kayıtlı hook'lar

| Dosya | Olay | Ne yapar | Çıkış kodu |
|---|---|---|---|
| `protect-installed-copies.ps1` | PreToolUse (Write\|Edit) | Kurulu kopyaya yazmayı **engeller** | 2 = engelle |
| `ensure-ps1-bom.ps1` | PostToolUse (Write\|Edit) | `.ps1` dosyasına eksik BOM'u geri koyar | 0 = sessiz düzeltme |
| `validate-definition.ps1` | PostToolUse (Write\|Edit) | Yazılan agent/skill/command frontmatter'ını denetler | 2 = modele uyarı |

Kayıt yeri: `.claude/settings.json` → `hooks`.

## Neden bu üçü

**`protect-installed-copies`** — Aynı dosyanın iki kopyası var: kaynak bu repoda,
kurulu kopya `~/.claude/` altında. Kurulu kopya elle düzenlenirse bir sonraki
`install.ps1` koşusu onu sessizce ezer. `CLAUDE.md` bunu kural olarak yazıyordu;
artık teknik olarak mümkün değil.

Korunanlar `install.ps1`'in `$Layers` dizisiyle aynı listedir:

| Korunan | Tür |
|---|---|
| `~/.claude/agents/**` | dizin |
| `~/.claude/commands/**` | dizin |
| `~/.claude/conventions/**` | dizin |
| `~/.claude/skills/**` | dizin |
| `~/.claude/CLAUDE.md` | tek dosya (kök) |
| `~/.claude/MINE.md` | tek dosya (kök) |

Korunmayanlar: `~/.claude/projects/**/memory/` (kişisel notlar, kurulmuyor) ve
`~/.claude/settings.json`. Kök dosya eşleşmesi **tam yol** karşılaştırmasıdır;
`~/.claude/projects/x/CLAUDE.md` engellenmez.

**Yeni bir katman eklendiğinde bu hook da güncellenmeli** — yoksa o katman
korumasız kalır. Bu bir kez oldu: `conventions/` eklendiğinde hook'a
eklenmemişti.

**`ensure-ps1-bom`** — Windows PowerShell 5.1, BOM görmediği `.ps1` dosyasını
ANSI sanar ve Türkçe karakterde parse hatası verir. Bu hata bu repoda **iki kez**
yaşandı. Write/Edit araçları BOM yazmaz, yani her düzenlemeden sonra elle
eklemek gerekiyordu. Artık gerekmiyor.

**`validate-definition`** — Bozuk frontmatter'lı bir tanım dosyasını Claude Code
**sessizce yok sayar.** Hata yok, uyarı yok; dosya sadece hiç çalışmaz. Fark
edilmesi en zor hata türü budur.

## Çıkış kodu sözleşmesi

| Kod | Anlamı |
|---|---|
| `0` | Devam et. stdout transcript'te görünür |
| `2` | PreToolUse'da **işlemi engelle**; PostToolUse'da modele uyarı ver. stderr metni modele iletilir |
| diğer | Hata olarak loglanır, iş durmaz |

Tasarım kuralı: **hook, çalışmanın önüne geçmemeli.** Üç script de girdiyi
okuyamazsa, yol bulamazsa veya beklenmedik bir durumla karşılaşırsa `exit 0`
ile sessizce çekilir. Bozuk bir hook'un işi durdurması, hiç hook olmamasından
kötüdür.

## Bilinen sınır

`protect-installed-copies` yalnızca **Write ve Edit tool'larını** yakalar.
Kabuktan yapılan yazma (`Bash`, `PowerShell` tool'ları üzerinden
`Copy-Item`, `Set-Content`, `>` yönlendirmesi) bu hook'un kapsamı dışında ve
kurulu kopyayı değiştirebilir.

Bilinçli bir tercih: kabuk komutlarını güvenilir biçimde ayrıştırmak, komut
metninden hedef yolu çıkarmayı gerektirir ve bu kaçınılmaz olarak hem yanlış
engellemelere hem de kolayca atlatılan bir filtreye yol açar. Hook'un işi
**kazayla yapılan** düzenlemeyi durdurmak; kararlı bir atlatmayı engellemek
değil.

Kaynak ↔ kurulu kopya farkı yine de yakalanır: `validate.ps1` hash karşılaştırması
yapıp uyarı verir.

## Test

`tests/Hooks.Tests.ps1` — 20 test, `validate.ps1` ve CI tarafından koşuluyor.

Hook'lar stdin'den JSON okur, yani `powershell.exe -File` ile doğrudan
sınanabilirler:

```powershell
$Json = @{ tool_input = @{ file_path = "C:\Users\<ad>\.claude\agents\x.md" } } |
        ConvertTo-Json -Compress
$Json | powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\hooks\protect-installed-copies.ps1
$LASTEXITCODE   # 2 bekleniyor
```

Yedi senaryonun tamamı bu yöntemle doğrulandı: engelleme, serbest bırakma,
yol içermeyen girdi, BOM ekleme, üç ayrı frontmatter durumu.

## Değişiklik sonrası

Claude Code hook tanımlarını **session başında** okur. `settings.json`
değiştirildikten sonra yeniden başlatılmalı; aksi halde eski tanımlar geçerli
kalır.
