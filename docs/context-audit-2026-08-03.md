# context-auditor — ilk koşu (2026-08-03)

Agent'ın ilk gerçek çalıştırılması. Sorulan soru: `~/.claude/rules/` altındaki
common kuralları ne kadar context yiyor?

---

## DÜZELTME — raporu okumadan önce oku

**Agent'ın ana bulgusu yanlış.** Rapor, `~/.claude/rules/common/*.md` dosyalarının
hiç yüklenmediğini ve payının %0 olduğunu söylüyor. Gerekçesi: hiçbir `CLAUDE.md`
içinde `@import` referansı yok, `hooks.json` / `settings.json` / `.claude.json`
içinde de yok.

Gerçek: **o dosyalar yükleniyor.** Ana thread'in context'inde session başında
"user's private global instructions for all projects" başlığıyla görünüyorlar.

Hatanın sebebi öğretici: **subagent ana thread'in context'ini göremez.** Kendi
penceresinde çalışır. Dosya sistemine bakıp "yükleniyor mu" sorusunu çıkarımla
cevaplamaya çalıştı ve mekanizmayı yanlış modelledi. Emin bir dille yanlış cevap
verdi.

Bunun iki dersi var:

1. Context isolation subagent'ın hem gücü hem körlüğüdür. Ana context hakkında
   soru sorulacaksa subagent yanlış araçtır — `/context` doğru araçtır.
2. Agent çıktısı doğrulanmadan kabul edilmez. Bu koşu, `change-reviewer`'ın
   "Güven: KESİN / MUHTEMEL" ayrımının neden gerekli olduğunu gösteriyor.

### Düzeltilmiş tablo

| Katman | ~Token | Payı |
|---|---|---|
| Agent metadata (33 `description`) | ~2.595 | %29 |
| `rules/common/` (9 dosya) | ~2.741 | %30 |
| Skill metadata (47 frontmatter) | ~2.409 | %27 |
| Proje `CLAUDE.md` | ~775 | %9 |
| Kullanıcı `CLAUDE.md` | ~475 | %5 |
| **Toplam** | **~9.000** | %100 |

Raporun geri kalanı — özellikle kırık `SessionStart` hook'u ve bağlı olmayan MCP
sunucuları bulguları — geçerli.

---

## Agent çıktısı (ham)

### 1. Tablo

| Katman | Dosya sayısı | ~Token (tahmini, char/4) | Payı |
|---|---|---|---|
| Memory — kullanıcı `~/.claude/CLAUDE.md` | 1 | ~475 | 7.6% |
| Memory — proje `claudecalis/CLAUDE.md` | 1 | ~775 | 12.4% |
| Memory — `~/.claude/rules/common/*.md` (**iddia edilen "otomatik yükleniyor", gerçekte YÜKLENMİYOR**) | 9 | **0 gerçek** (potansiyel ~2.741, hiç context'e girmiyor) | **0%** |
| Skill metadata (yalnız frontmatter, `~/.claude/skills/*/SKILL.md`) | 47 | ~2.409 | 38.5% |
| Agent metadata (yalnız `description`, `~/.claude/agents/*.md`) | 33 | ~2.595 | 41.5% |
| Slash command'lar (`~/.claude/commands/*.md`) — lazy, invoke edilmeden yüklenmiyor | 61 | 0 | 0% |
| MCP sunucuları — `mcp-configs/mcp-servers.json`'da 15 tanım var ama `~/.claude.json`'daki her `mcpServers` alanı `{}` | 0 aktif / 15 tanımlı | 0 | 0% |
| Hooks — context'e direkt girmez; `SessionStart` hook'u muhtemelen kırık | 27 hook tanımı | ölçülemedi | — |
| **TOPLAM (gerçekten otomatik yüklenen)** | | **~6.254** | **100%** |

Not: Token sayacı yok, karakter/4 tahmini kullanıldı. Skill body'leri (544.844
char), agent body'leri (152.344 char), command dosyaları (248.799 char) ve
dil-özel `rules/` alt dizinleri (95.361 char) toplama dahil edilmedi çünkü
ölçülebildiği kadarıyla lazy-load / hiç yüklenmeyen içerikler.

**Direkt sorunun cevabı:** `~/.claude/rules/common/*.md` (9 dosya, toplam 10.962
karakter ≈ 2.741 token) her session'a otomatik yüklenmiyor. Ne `~/.claude/CLAUDE.md`
ne `claudecalis/CLAUDE.md` içinde bu dosyalara `@` importu var (grep ile arandı,
bulunamadı), ne `hooks.json`, `settings.json`, `.claude.json` içinde bu klasöre
bir referans var. Payı: **%0**.

### 2. En Pahalı 5 Kalem

1. **`~/.claude/agents/*.md` (description toplamı, 33 dosya) — ~2.595 token.** En
   büyük gerçek kalem; global olduğu için tek proje bazında optimize edilmesi riskli.
2. **`~/.claude/skills/*/SKILL.md` (frontmatter toplamı, 47 dosya) — ~2.409 token.**
   Gövdeler lazy olduğu için asıl maliyet sadece isim+açıklama, makul bir bedel.
3. **`~/.claude/rules/common/*.md` — 0 token gerçek, ~2.741 token potansiyel.**
4. **`claudecalis/CLAUDE.md` — ~775 token.** Makul boyutta, gereksiz şişkinlik yok.
5. **`~/.claude/CLAUDE.md` — ~475 token.** En küçük ve en verimli kalem.

### 3. Somut Öneriler

> **[~2.7k token'lık yanlış varsayım, gerçek tasarruf 0]** `~/.claude/CLAUDE.md` ve
> `claudecalis/CLAUDE.md` içindeki "rules altındaki common kurallar otomatik
> yükleniyor" cümlesini düzelt (ya da gerçekten `@` import ekle).

> **[ölçülemedi, davranışsal risk]** `~/.claude/hooks/hooks.json`'daki `SessionStart`
> hook'unu canlı bir session açıp `/context` ile doğrula → `session-start.js`, var
> olmayan `~/.claude/scripts/lib/utils.js` ve `lib/package-manager.js` modüllerini
> `require` ediyor ve wrapper komut `run-with-flags.js`'i yanlış dizinde arıyor;
> muhtemelen her session'da sessizce fallback'e düşüyor.

> **[risk, şu an 0 token]** `~/.claude/mcp-configs/mcp-servers.json`'daki 15 sunucu
> tanımını bir projeye `.mcp.json` ile bağlamadan önce tek tek `/context` ile ölç →
> şu an hepsi kapalı; araç-zengin sunucular (playwright, filesystem, github) birkaç
> bin token'lık tool tanımı ekler ve toplamı 2-3 katına çıkarabilir.

> **[~2.4k token, global paylaşım — silme değil, kapsam sorusu]** 47 skill'in
> frontmatter'ı her repoda yükleniyor; `django-*`, `laravel-*`, `springboot-*` gibi
> 15+ tanesi bu repoda hiç tetiklenmeyecek. Global olduğu için silmek diğer
> projelerde kayıp demek — silme önerilmiyor.

> **[~2.6k token, global paylaşım — silme değil, kapsam sorusu]** Aynı mantık
> agent'lar için: cpp/go/java/kotlin/rust/python/typescript reviewer + build-resolver
> ikilileri (14 dosya) bu repoda hiç kullanılmıyor, ama diğer repolarda kullanılıyor.
