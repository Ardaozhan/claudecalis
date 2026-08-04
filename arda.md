# Bu Klasörde Ne Var? (Sade Anlatım)

Bu dosya, `claudecalis` klasöründeki her şeyin **ne işe yaradığını** günlük dille
anlatır. Teknik detay değil, "bu dosya niye burada" sorusunun cevabı.

---

## Önce Şunu Anla: İki Klasör Var

| Klasör | Ne | Benzetme |
|---|---|---|
| `~/claudecalis/` (burası) | Dosyaların **yazıldığı** yer | Mutfak — yemek burada pişer |
| `~/.claude/` | Dosyaların **çalıştığı** yer | Tabak — Claude yemeği buradan yer |

Claude Code, agent ve komutları **sadece `~/.claude/` altında arar.** Burada
yazdığın bir dosya, `install.ps1` çalıştırılana kadar hiçbir işe yaramaz.

> **En sık yapılan hata:** buradaki dosyayı düzenleyip `install.ps1`'i unutmak.
> Değişiklik yaptın sanırsın, Claude eski hâlini kullanmaya devam eder.

---

## Ana Dosyalar (klasörün kökünde)

| Dosya | Ne işe yarar |
|---|---|
| `CLAUDE.md` | **Claude'un bu projeyi tanıdığı dosya.** Her sohbet başında otomatik okunur. Klasör yapısı, kurallar ve daha önce yapılan hatalar burada yazılı — Claude aynı hataya iki kez düşmesin diye. |
| `README.md` | **İnsan için açıklama.** Yapının nasıl çalıştığını, neden böyle tasarlandığını anlatır. Claude bunu otomatik okumaz. |
| `arda.md` | Şu an okuduğun dosya. En sade özet. |
| `install.ps1` | **Kurulum scripti.** Buradaki dosyaları `~/.claude/` altına kopyalar. Üzerine yazacaksa önce yedek alır. `-DryRun` ile önce ne yapacağını gösterir, `-Uninstall` ile geri alır. |
| `validate.ps1` | **Denetçi script.** "Yazdığım şeyler bozuk mu?" sorusunu cevaplar. Bozuk bir agent dosyasını Claude Code sessizce yok sayar — hata vermez, o parça hiç çalışmaz. Bu script o sessizliği gürültüye çevirir. |
| `.gitattributes` | Satır sonu ayarı. Windows/Linux farkından doğan gereksiz değişiklik gürültüsünü engeller. |

---

## `agents/` — Alt Çalışanlar

Bir agent, **kendi ayrı odasında çalışan bir yardımcı.** Ona bir iş verirsin,
gidip yapar, sadece sonucu getirir. Odası ayrı olduğu için ana sohbeti
kalabalıklaştırmaz.

Dört tanesi bir **zincir** oluşturuyor:

```
spec-writer  →  impl-planner  →  test-first  →  (sen/Claude)  →  change-reviewer
"ne yapılacak"  "nasıl yapılacak"  "test yaz"    "kodu yaz"      "doğru mu oldu"
```

| Dosya | Görevi |
|---|---|
| `spec-writer.md` | Muğlak isteği ("şunu düzelt") net bir tanıma çevirir: ne yapılacak, ne yapılmayacak, hangi sorular açık. **Kod yazamaz.** |
| `impl-planner.md` | Tanımı sıralı adımlara böler: hangi dosya, hangi sırayla. **Kod yazamaz.** |
| `test-first.md` | Önce testleri yazar ve bu testlerin gerçekten başarısız olduğunu kanıtlar. Sonra kod yazılıp yeşile döndürülür. |
| `change-reviewer.md` | İş bitince denetler: istenen şey oldu mu, fazladan bir şey yapıldı mı. **Düzeltme yetkisi yok** — düzeltebilseydi kendi hatasını gizleyebilirdi. |
| `context-auditor.md` | Bağımsız. "Claude her sohbette ne kadar yer harcıyor?" sorusunu ölçer ve tablo döner. |

**Tasarımın püf noktası:** her agent'a sadece ihtiyacı kadar yetki verilmiş.
Spec yazarı kod yazamaz, denetçi düzeltme yapamaz. Bu kasıtlı.

---

## `commands/` — Kısayol Komutlar

Sohbette `/` ile çağırdığın hazır talimatlar.

| Dosya | Ne yapar |
|---|---|
| `feature.md` | `/feature <istek>` — yukarıdaki beş adımlı zinciri baştan sona yürütür. |
| `bootstrap.md` | `/bootstrap <repo>` — gerçek bir iş reposuna `CLAUDE.md` kurar. Dili ve komutları **koddan tespit eder**, tahmin etmez; bilemediğini sana sorar. |

---

## `skills/` — Yükleme Talimatı

Agent ayrı odada çalışan işçiyse, skill **masana konan el kitabı.** Normalde
sadece başlığı durur; konu geldiğinde içeriği açılır.

| Dosya | Ne yapar |
|---|---|
| `memory-hygiene/SKILL.md` | Bir bilginin nereye yazılacağına karar verir: `CLAUDE.md`'ye mi, ayrı bir not dosyasına mı, yoksa hiçbir yere mi. Yanlış yere yazılan bilgi ya kaybolur ya her sohbette boşuna yer kaplar. |

---

## `conventions/` — Dil Kılavuzları

Her dil için bir dosya. **İnsan için değil, agent için yazılmışlar.**

Çözdükleri sorun: agent'lar eskiden "bu proje herhalde npm kullanıyordur" diye
tahmin ediyordu. Yanlış tahmin pahalıya patlıyor — bozuk kurulum, çalışmayan
adım, ya da hiç çalıştırılmadığı hâlde "başarılı" görünen test.

| Dosya | Kapsadığı |
|---|---|
| `typescript.md` | TypeScript / JavaScript |
| `python.md` | Python |
| `java-kotlin.md` | Java ve Kotlin |
| `dotnet.md` | C# / .NET |
| `README.md` | Bu dosyaların neden var olduğu |

Her dosya üç soruyu cevaplıyor: **nasıl anlarım hangi dil olduğunu**, **hangi
komutlar geçerli**, **bu dilde en sık görülen sahte başarı ne**.

> Bunlar otomatik yüklenmez — agent gerektiğinde açıp okur. Yani yeni dil eklemek
> her sohbete ek yük bindirmez.

---

## `hooks/` — Zorlayıcı Katman

En önemli ayrım burada:

- `CLAUDE.md`'ye yazılan kural bir **tavsiyedir.** Claude genelde uyar ama
  unutabilir.
- Hook bir **kuraldır.** Claude'un kararına bağlı değil; sistem çalıştırır.

Üçü de bu projede **gerçekten yaşanmış** hatalara karşı yazıldı.

| Dosya | Ne yapar |
|---|---|
| `protect-installed-copies.ps1` | Kurulu kopyaya (`~/.claude/`) yazmayı **engeller.** Oraya yazarsan bir sonraki kurulumda silinir — emeğin çöpe gider. |
| `ensure-ps1-bom.ps1` | `.ps1` dosyalarına gizli bir işareti geri koyar. O işaret yoksa Windows PowerShell Türkçe karakterleri bozar ve dosya çalışmaz. |
| `validate-definition.ps1` | Yeni yazılan agent/skill/command dosyasının başlığını anında denetler, bozuksa uyarır. |

Nerede kayıtlı: `.claude/settings.json`.

---

## `tests/` — Otomatik Testler

48 test. "Yazdım, çalışıyordur" demek yerine gerçekten çalıştırıp kanıtlar.

| Dosya | Neyi test eder |
|---|---|
| `Uninstall.Tests.ps1` | Kaldırma işlemi doğru dosyaları siliyor mu, elle düzenlenmiş dosyayı koruyor mu (10 test) |
| `Hooks.Tests.ps1` | Üç hook söz verdiğini yapıyor mu (20 test) |
| `Validate.Tests.ps1` | Denetçi script gerçek hatayı yakalıyor, sahte alarm vermiyor mu (18 test) |

---

## `docs/` — Kanıt Arşivi

Agent koşularının **ham çıktıları.** Neden saklanıyor: bu projede dört kez
görüldü ki *yazılmış olmak çalışmak değildir.* Her parçanın en az bir gerçek koşu
kaydı burada duruyor.

| Dosya | Ne olmuş |
|---|---|
| `context-audit-2026-08-03.md` | İlk denetim — agent kendinden emin bir dille **yanlış** cevap verdi |
| `context-audit-2026-08-04.md` | İkinci denetim — eksik bilgi verildi, doğru cevap geldi (~11.000 token) |
| `pipeline-run-2026-08-03.md` | `/feature` zincirinin ilk uçtan uca koşusu |
| `bootstrap-run-2026-08-04.md` | `/bootstrap` gerçek bir repoda koştu, 2 gerçek kusur yakaladı |
| `convention-check-2026-08-04.md` | Agent'lar konvansiyon dosyalarını gerçekten okuyor mu — doğrulandı |

---

## `templates/` — Hazır Şablonlar

| Dosya | Ne için |
|---|---|
| `CLAUDE.md.template` | Yeni bir iş reposuna kopyalanacak boş şablon. Doldur, doldurmadığın bölümleri **sil**. |
| `README.md` | Doldururken uyulacak kural: az ve kesin > çok ve muğlak. Bu dosya her sohbette baştan sona okunur, her satırın bedeli var. |

---

## `global/` — Tüm Projelere Giden Ayarlar

Bu ikisi `~/.claude/` klasörünün **köküne** kurulur, yani her projede geçerli olur.

| Dosya | Ne |
|---|---|
| `CLAUDE.md` | Kişisel çalışma tercihlerin: Türkçe konuş, önce açıkla sonra yaz, emin değilsen tahmin etme. |
| `MINE.md` | **Hangi dosyayı sen yazdın** listesi. `~/.claude/` altındaki çoğu şey hazır paketten geliyor; bu liste seninkileri ayırır. |

Not: Kişisel notların (`memory/`) bu repoya girmez — paylaşılan bir klasöre
kişisel not konmaz.

---

## `.github/workflows/` — Otomatik Kontrol

| Dosya | Ne yapar |
|---|---|
| `validate.yml` | GitHub'a her gönderimde `validate.ps1`'i otomatik çalıştırır. Hata varsa uyarır. Windows üzerinde koşar — kontrollerden biri tam olarak Windows'a özgü bir davranışı koruduğu için başka yerde anlamsız olurdu. |

---

## Günlük Kullanım — Üç Adım

```powershell
# 1. Dosyayı burada düzenle (asla ~/.claude altında değil)

# 2. Kur
.\install.ps1

# 3. Denetle
.\validate.ps1
```

Kurulumdan sonra **Claude Code yeniden başlatılmalı** — yoksa eski hâli
kullanmaya devam eder.

---

## Bu Projede Öğrenilen İki Şey

**1. Yazılmış olmak çalışmak değildir.**
Burada dört kez kanıtlandı: `install.ps1` ilk çalıştırmada patladı,
`context-auditor` ilk denemede emin bir dille yanlış cevap verdi, `test-first`'ün
testleri yanlış sebepten kırmızıydı, `validate.ps1` kendi testinde çöktü.
Dördü de yazıldıklarında doğru görünüyordu.

**2. Alt çalışana ana sohbet hakkında soru sorulmaz.**
Agent kendi odasında çalışır; ana sohbette ne olduğunu **göremez.** Sorarsan
dosyalara bakıp tahmin yürütür ve emin bir dille yanılır. Göremeyeceği bilgiyi
ona baştan vermek gerekir.
