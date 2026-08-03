# context-auditor — ikinci koşu (2026-08-04)

İlk koşu: `context-audit-2026-08-03.md`. Aradan geçen sürede 1 command,
4 konvansiyon dosyası ve 3 hook eklendi.

## Bu koşu doğru çıktı — ve sebebi öğretici

İlk koşuda agent, `~/.claude/rules/common/*.md` dosyalarının yüklenmediğini
iddia etmişti. Yanılmıştı; sebebi yapısaldı: **subagent ana thread'in context'ini
göremez**, dolayısıyla "bu dosya yükleniyor mu" sorusunu ancak dosya sistemine
bakıp çıkarım yaparak cevaplayabilir.

Bu koşuda çözüm agent'ı değiştirmek değil, **göremediği bilgiyi ona vermek**
oldu: prompt'a "rules/ dosyalarını yükleniyor kabul et, emin olmadığını
'doğrulanamadı' diye işaretle" talimatı kondu.

Sonuç: doğru tablo, **artı** ilk koşunun kaçırdığı yeni bir kalem.

## Tablo

| Katman | ~Token | Payı |
|---|---|---|
| Otomatik yüklenen memory (`CLAUDE.md`'ler + `rules/common/*` + `rules/README.md`) | ~5.980 | %55 |
| Agent metadata (33 `description`) | ~2.587 | %24 |
| Skill metadata (47 frontmatter) | ~2.397 | %21 |
| Slash command'lar (61) | 0 | %0 |
| **Konvansiyonlar (4)** | **0** | **%0** |
| MCP (15 tanımlı, 0 bağlı) | 0 | %0 |
| **Toplam** | **~10.964** | %100 |

Tahmin yöntemi: karakter/4.

## Doğrulanan tasarım iddiası

`conventions/` için "context maliyeti sıfır" iddiası **doğrulandı.** Dosyalar
otomatik yüklenen içerikte hiç görünmüyor; hiçbir `CLAUDE.md` veya `rules/`
dosyasında `@` import referansı yok. Yalnızca agent'lar kendi izole
bağlamlarında `Read` ile okuyor.

Pratik sonucu: **dil eklemek her session'a bedel bindirmiyor.** Beşinci, altıncı
dil eklenebilir.

## Yeni bulgu

`~/.claude/rules/README.md` (~1.100 token) her session'da otomatik yükleniyor.
Bu bir kurulum rehberi — dizin yapısını ve `install.sh` kullanımını anlatıyor,
session davranışına dair tek bir kural içermiyor.

Tarama `rules/` **kökünü** de kapsıyor; dil-özel alt dizinler
(`rules/typescript/` vb.) kapsanmıyor. README bu yüzden yanlışlıkla dahil olmuş.

Öneri: `rules/` kökünden taşınsın. Kazanç ~1.100 token/session, kayıp yok —
dosyaya `Read` ile her zaman erişilebilir.

Bu kalem ECC paketinden geliyor, elle yazılmadı; karar kullanıcıya ait.

## Doğrulanamayan

`~/.claude/hooks/hooks.json` (27 tanım, ~3.150 token potansiyel) hiçbir
`settings.json` anahtarına bağlı görünmüyor. Tetiklenip tetiklenmediği
ölçülemedi. Tetiklenmiyorsa ölü kod; tetikleniyorsa çıktısı context'e giriyor.
