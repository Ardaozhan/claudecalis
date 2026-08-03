---
name: memory-hygiene
description: Bir bilginin nereye yazılacağına karar verir — CLAUDE.md mi, memory dosyası mı, hiçbiri mi. Kullanıcı "bunu hatırla", "not al", "kaydet" dediğinde ya da kalıcı olması gereken bir bilgi ortaya çıktığında kullan. Ayrıca memory temizliği, çakışan notlar ve şişmiş CLAUDE.md dosyaları için de kullan.
---

# Memory Hijyeni

Kalıcı bilginin nereye yazılacağına dair karar prosedürü. Yanlış katmana yazılan
bilgi ya hiç okunmaz ya da her session'da boşuna token yakar.

## Karar Ağacı

Bilgi geldiğinde sırayla sor:

**1. Kod, git history veya mevcut dokümandan türetilebilir mi?**
→ Evet ise **yazma.** Model zaten okuyabilir. Buna örnek: dizin yapısı, hangi
kütüphanenin kullanıldığı, geçmişte düzeltilmiş bir bug.

**2. Sadece bu konuşma için mi geçerli?**
→ Evet ise **yazma.** "Şu an şu dosyayı düzenliyoruz" kalıcı bilgi değil.

**3. Takımdaki herkesin bilmesi gerekir mi?**
→ Evet ise **proje `CLAUDE.md`**. Git'e girer, paylaşılır.
   Örnek: "Bu repoda testler `pnpm test:unit` ile çalışır."

**4. Tüm projelerinde geçerli, sana özel bir tercih mi?**
→ Evet ise **`~/.claude/CLAUDE.md`**.
   Örnek: "Benimle Türkçe konuş."

**5. Sadece bu projeye özel, geçici veya kişisel bir bağlam mı?**
→ Evet ise **`memory/` dizini**, tek dosya = tek bilgi.
   Örnek: "Patron 2026-08-15'te agent yapısını denetleyecek."

Hiçbiri değilse yazma.

## Memory Dosyası Formatı

`~/.claude/projects/<proje-slug>/memory/<slug>.md`:

```markdown
---
name: kisa-kebab-slug
description: Tek satır özet — hangi durumda bu dosyanın açılacağına bu karar verir
metadata:
  type: user | feedback | project | reference
---

Bilginin kendisi. İlgili notlara [[baska-slug]] ile bağlan.
```

Tip seçimi:

| type | Ne için |
|---|---|
| `user` | Kullanıcının kim olduğu: rol, uzmanlık, tercih |
| `feedback` | Nasıl çalışman gerektiğine dair yönlendirme — **why** ve **how to apply** ekle |
| `project` | Devam eden iş, hedef, kısıt. Göreli tarihleri mutlak tarihe çevir |
| `reference` | Dış kaynak işaretçileri: URL, dashboard, ticket |

Yazdıktan sonra `MEMORY.md` dosyasına **tek satır** işaretçi ekle:

```
- [Başlık](dosya.md) — kancası
```

`MEMORY.md` bir indekstir. İçine asla memory içeriği yazma.

## Kaçınılacak Hatalar

**Şişmiş CLAUDE.md.** Her session'da tam olarak yüklenir. 200 satırı geçtiyse
ya çok detay var ya da `memory/`'ye ait şeyler oradadır. Bölerek `@import` kullan.

**Kopya notlar.** Yazmadan önce aynı bilgiyi kapsayan dosya var mı bak; varsa
yenisini açma, mevcudu güncelle.

**Göreli tarih.** "Gelecek hafta" yazma; altı ay sonra okunduğunda anlamsız.
"2026-08-10" yaz.

**Eskimiş not.** Memory yazıldığı andaki gerçeği yansıtır. Bir not dosya, fonksiyon
ya da flag adı veriyorsa, önermeden önce hâlâ var mı **doğrula**.

**Yanlış olduğu anlaşılan notu bırakmak.** Sil. Yanlış memory, memory olmamasından
kötüdür.

## Temizlik Turu

Periyodik olarak `memory/` dizinini gözden geçir:

1. Her dosyanın `description` alanı hâlâ içeriğini doğru anlatıyor mu?
2. Bahsedilen dosya/komut/flag'ler hâlâ mevcut mu?
3. `MEMORY.md` indeksinde karşılığı olmayan dosya var mı? Ya da tersi?
4. Aynı konuyu iki dosya birden anlatıyor mu? Birleştir.
5. Geçerliliği bitmiş `project` notları var mı? Sil.
