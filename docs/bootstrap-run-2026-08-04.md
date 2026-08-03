# /bootstrap — ilk koşu (2026-08-04)

Komutun ilk gerçek çalıştırılması.

**Hedef:** gerçekçi bir TypeScript/Node reposu (scratchpad altında kurulan
`siparis-servisi` fixture'ı). Fixture kasten iki tuzak içeriyordu.

## Sonuç

| Alan | Sonuç |
|---|---|
| Tespit edilen dil | TypeScript 5.6 / Node 22 (ESM) |
| Paket yöneticisi | pnpm 9.7.0 |
| Komut doğrulama | 6/6 statik olarak doğrulandı, **0/6 çalıştırıldı** |
| Kullanıcıya sorulan | 3 soru, tek seferde |
| Yazılan | `CLAUDE.md` (61 satır), `.claude/settings.json` |

## Yakaladığı iki gerçek kusur

**1. README yanlış paket yöneticisini söylüyordu.**

`README.md` `npm install` diyordu. Ama repoda `pnpm-lock.yaml` vardı,
`package.json` içinde `packageManager: pnpm@9.7.0` alanı vardı ve CI workflow'u
`pnpm install --frozen-lockfile` çalıştırıyordu.

Konvansiyon dosyasının kuralı ("paket yöneticisini lock dosyasından belirle,
tahmin etme") burada tam olarak işe yaradı. README'ye güvenilseydi üretilen
`CLAUDE.md` yanlış olurdu ve o dosyaya bakan her session `npm install`
çalıştırıp `pnpm-lock.yaml` ile çakışan bir lock dosyası üretirdi.

**2. `build` scripti kırık.**

`package.json` içinde `"build": "tsc -p tsconfig.build.json"` yazıyordu ama
repoda `tsconfig.build.json` yoktu — sadece `tsconfig.json` vardı.

Bu, hiçbir komut çalıştırılmadan **statik olarak** yakalandı: script'in referans
verdiği dosyanın varlığı kontrol edilerek.

## Komutta bulunan kusur

Adım 5 şunu diyordu:

> Çalıştıramadığın komutu dosyada bırakma — ya düzelt ya sil.

Bu kural bu koşuda **yanlış sonuç üretecekti.** Komutlar doğruydu; CI onları
zaten çalıştırıyordu. Çalıştırılamamalarının sebebi kurulum makinesinde `pnpm`
olmaması ve `node_modules`'ün indirilmemiş olmasıydı.

Kurala harfiyen uyulsaydı **altı doğru komut birden silinecekti.**

İki başarısızlık türü karıştırılmıştı:

| Tür | Örnek | Ne yapılmalı |
|---|---|---|
| Komut yanlış | script tanımlı değil, hedef dosya yok | Düzelt ya da çıkar |
| Ortam yetersiz | araç kurulu değil, bağımlılık yok, ağ yok | **Bırak**, "doğrulanmadı" diye işaretle |

`commands/bootstrap.md` bu ayrımı yapacak şekilde güncellendi; ayrıca araç
kurulu olmasa bile yapılabilen statik doğrulamaların listesi eklendi ve kapanış
tablosunun doğrulanan komut sayısını **iki ayrı sayı** olarak vermesi zorunlu
kılındı.

## Ayrıca

Üretilen `.claude/settings.json`'da izin listesi joker karakter yerine tam
eşleşme kullanıyor:

```json
"allow": ["Bash(pnpm run test)", "Bash(pnpm run typecheck)", "Bash(pnpm run lint)"]
```

`Bash(pnpm run test:*)` yazılsaydı `pnpm run test:watch` de otomatik onaylanmış
olurdu — o ise sonlanmayan bir izleme process'i.
