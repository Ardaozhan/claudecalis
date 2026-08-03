# Konvansiyon okuma doğrulaması (2026-08-04)

**Sınanan iddia:** `conventions/` dosyaları eklendi ve `test-first` ile
`impl-planner` agent'larına "önce konvansiyonu oku" talimatı yazıldı. Ama
agent'ın bunu **gerçekten yapıp yapmadığı** hiç doğrulanmamıştı.

## Yöntem

`test-first` agent'ı, `/bootstrap` testinde kurulan TypeScript fixture'ında
küçük bir işe koşuldu (bir indirim fonksiyonu için kırmızı testler). Rapor
formatına zorunlu bir bölüm eklendi:

```
### Konvansiyon Kontrolü
- Hangi konvansiyon dosyasını okumaya çalıştın (tam yol):
- Okuyabildin mi (evet/hayır):
- Okuduysan, oradan aldığın ve davranışını DEĞİŞTİREN üç somut bilgi:
- Okuyamadıysan hata neydi:
```

"Okudum" demesi yeterli sayılmadı; **davranışını değiştiren** üç somut bilgi
istendi. Okumadan bu bölüm doldurulamaz.

## Sonuç: doğrulandı

Okunan dosya: `C:\Users\ardao\.claude\conventions\typescript.md`

Davranışı değiştiren üç nokta:

**1. `npm` kullanmayı reddetti.** Testleri çalıştırmak için bağımlılık kurması
gerekiyordu. Makinede `npm` vardı, `pnpm` yoktu. Konvansiyondaki "paket
yöneticisini lock dosyasından belirle" ve "yanlış yöneticiyle kurulum lock
dosyasını bozar" kuralları nedeniyle `npm install` çalıştırmadı ve testleri
çalıştıramadığını raporladı.

Bu tam olarak konvansiyonun var olma sebebi: kolay yol (`npm install`) mevcuttu
ve zararlıydı.

**2. Yeni test dosyası icat etmedi.** Konvansiyondaki framework tespit tablosunu
(`vitest` → `*.test.ts`) kullanıp mevcut `tests/hesap.test.ts` dosyasına ekleme
yaptı.

**3. Vitest API'sini taklit etti.** Konvansiyondaki "Vitest ve Jest API'leri
benzer ama aynı değil; mevcut dosyalardaki kullanımı taklit et" kuralına uydu.

## Yan bulgu: dürüstlük kuralı da çalıştı

Agent testleri çalıştıramadı ve **"KIRMIZI" demedi** — "ÇALIŞTIRILAMADI" yazıp
sebebini belirtti, ayrıca kırmızı olacaklarının statik gerekçesini
(`indirimliTutar` export'u yok) ayrıca sundu.

Bu, aynı agent'ın 2026-08-03 koşusunda **yanıldığı** noktaydı: o zaman
kırmızılığın sebebini doğruladığını iddia etmiş ama yanılmıştı
(bkz. `pipeline-run-2026-08-03.md`). Aynı kural bu kez doğru uygulandı.

## Çıkarım

Konvansiyon mekanizması çalışıyor ve maliyeti sıfır
(bkz. `context-audit-2026-08-04.md`). Yeni dil eklemek güvenli.
