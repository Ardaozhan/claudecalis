---
description: Bir özellik isteğini spec → plan → test → uygulama → denetim hattından geçirir
argument-hint: <özellik isteği>
---

# Özellik Hattı

İstek: **$ARGUMENTS**

Aşağıdaki hattı sırayla yürüt. Her adımda bir agent çalışır ve çıktısı bir
sonraki adımın girdisi olur. **Adım atlama.**

```
1 spec-writer  →  2 impl-planner  →  3 test-first  →  4 SEN  →  5 change-reviewer
   ne yapılacak     nasıl yapılacak    kırmızı test     yeşile çevir   denetle
```

## Adım 1 — Spesifikasyon

`spec-writer` agent'ını çağır, isteği ilet.

Dönen SPEC bloğundaki **"Açık Sorular"** boş değilse **DUR.** Soruları kullanıcıya
sor, cevap almadan devam etme. Varsayımla ilerlemek bu hattın en pahalı hatasıdır.

SPEC'i kullanıcıya göster ve onay al.

## Adım 2 — Plan

`impl-planner` agent'ını çağır, SPEC bloğunu **tam olarak** ilet.

Agent "bu SPEC bölünmeli" derse **DUR**, bölme önerisini kullanıcıya sun.

PLAN'ı kullanıcıya göster ve onay al.

## Adım 3 — Kırmızı Testler

`test-first` agent'ını çağır, PLAN ve SPEC kriterlerini ilet.

Rapordaki testlerin gerçekten **kırmızı** olduğunu doğrula. "ÇALIŞTIRILAMADI"
dönenler varsa önce onu çöz — kırmızılığı doğrulanmamış testle ilerleme.

## Adım 4 — Uygulama (bunu SEN yaparsın)

Bu adımı agent'a verme. Sebebi: uygulama sırasında kullanıcıyla konuşman,
karar sorman ve ara sonuç göstermen gerekir. Agent bunu yapamaz.

Kurallar:
- PLAN'daki adımları **sırayla** uygula
- Her adım sonunda o adımın "Doğrulama" sütunundaki kontrolü çalıştır
- Testleri **değiştirme.** Test yanlışsa dur ve kullanıcıya söyle
- PLAN'da olmayan bir şey yapma. Gerekiyorsa dur ve PLAN'ı güncelle

## Adım 5 — Denetim

`change-reviewer` agent'ını çağır, SPEC bloğunu ve değişiklik özetini ilet.

Karar **GEÇMEDİ** ise: bulguları düzelt, adım 5'i tekrarla.
Karar **ŞARTLI GEÇTİ** ise: şartları kullanıcıya göster, kararı ona bırak.

## Kapanış

Kullanıcıya şu özeti ver:

| Adım | Sonuç |
|---|---|
| Spec | <kriter sayısı> |
| Plan | <adım sayısı> |
| Test | <kaç test, durum> |
| Uygulama | <dokunulan dosya sayısı> |
| Denetim | <karar> |

Sonra sor: kalıcı olması gereken bir şey öğrenildi mi? Öğrenildiyse
`memory-hygiene` skill'indeki karar ağacına göre doğru katmana yaz.

## Ne Zaman Bu Hattı Kullanma

Küçük işler için bu hat **fazladır.** Şunlarda doğrudan çalış:

- Tek satırlık düzeltmeler
- Yazım/format düzeltmeleri
- Kullanıcının tam olarak ne istediğini zaten söylediği net işler

Hat, **belirsizliğin pahalı olduğu** işler için vardır. Belirsizlik yoksa
maliyeti karşılığını vermez.
