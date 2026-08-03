---
description: Gerçek bir iş reposuna CLAUDE.md ve proje ayarlarını kurar. Dili ve komutları koddan tespit eder, tahmin etmez; belirleyemediğini kullanıcıya sorar.
argument-hint: [hedef repo yolu — boşsa mevcut dizin]
---

# Repo Kurulumu

Hedef: **$ARGUMENTS** (boşsa mevcut çalışma dizini)

Bir iş reposuna `CLAUDE.md` ve `.claude/settings.json` düşürürsün. Amaç, o repoda
çalışan her session'ın doğru komutları ve sınırları bilmesi.

## Kural

**Doldurulamayan bölüm silinir, boş bırakılmaz.** Boş başlık yanlış bilgiden
zararlıdır; model onu ciddiye alır ve olmayan bir yapıyı varsayar.

**Tahmin edilen hiçbir şey yazılmaz.** Bu dosyanın tek değeri doğru olması. Yanlış
bir test komutu, hiç komut olmamasından kötüdür.

## Adım 1 — Tespit

Hedef dizini oku. Şunları **dosyadan** belirle:

| Bakılacak | Ne öğrenilir |
|---|---|
| `package.json` + lock dosyası | Dil, paket yöneticisi (`pnpm-lock.yaml` → pnpm, `yarn.lock` → yarn, `package-lock.json` → npm) |
| `pyproject.toml` / `requirements.txt` | Python, ortam yöneticisi (`uv.lock`, `poetry.lock`) |
| `pom.xml` / `build.gradle*` | Java/Kotlin, Maven mi Gradle mı, wrapper var mı |
| `*.sln` / `*.csproj` | .NET, `<TargetFramework>` sürümü |
| `.github/workflows/*` | CI'ın gerçekte çalıştırdığı komutlar — **en güvenilir kaynak** |
| `README.md` | Kurulum ve çalıştırma talimatları |
| `Makefile` / `justfile` / `Taskfile.yml` | Takımın kullandığı gerçek komut adları |

İlgili konvansiyon dosyasını da oku: `~/.claude/conventions/<dil>.md`.

Karışık repolarda (birden fazla dil) hepsini yaz, hangisinin nerede olduğunu belirt.

Zaten bir `CLAUDE.md` varsa **üzerine yazma.** Oku, eksiklerini çıkar, kullanıcıya
"şunlar eklenebilir" diye sun.

## Adım 2 — Belirsizleri sor

Tespit edemediğin her şey için kullanıcıya sor. Tipik olarak koddan okunamayanlar:

- Dokunulmaması gereken dizinler (başka ekibin sahibi olduğu yerler)
- Bir işin "bitti" sayılma kriteri
- Yakında değişecek şeyler (göç planları, kaldırılacak bağımlılıklar)
- Yasaklar (prod'a bağlanma, `main`'e doğrudan commit, `.env` okuma)

**Sorularını tek seferde topla.** Adım adım sormak kullanıcıyı yorar.

Cevap alamadığın bölümü şablondan **sil**.

## Adım 3 — Yaz

`~/claudecalis/templates/CLAUDE.md.template` dosyasını temel al. Şablonun
başındaki açıklama bloğunu sil.

Boyut hedefi **150 satır.** Bu dosya her session'da tam olarak context'e yüklenir;
her satırın tekrar eden bir bedeli var. Aşarsan detayı ayrı dosyaya al ve
`@docs/mimari.md` şeklinde import et.

Yazma:
- Dizin ağacının tamamı — model zaten okuyabilir
- Bağımlılık listesi — `package.json` zaten var
- Geçmişte düzeltilmiş bug'lar — git history'de
- Genel kodlama tavsiyeleri — `~/.claude/rules/` altında

Yaz:
- Hangi komutun çalıştığı (özellikle npm mi pnpm mi)
- Dokunulmayacak yerler
- Kabul kriteri
- Koddan okunamayan bağlam

## Adım 4 — Proje ayarları

Hedefte `.claude/settings.json` yoksa oluştur. Sadece **o repoda gerçekten
kullanılan** salt-okunur komutları izin listesine ekle — izin listesi ne kadar
darsa o kadar iyidir.

```json
{
  "$schema": "https://json.schemastore.org/claude-code-settings.json",
  "permissions": {
    "allow": ["Bash(<tespit ettiğin test komutu>:*)"]
  }
}
```

Bu dosya git'e girer, yani takımın tamamını etkiler. Ne eklediğini kullanıcıya
**göster ve onay al.**

## Adım 5 — Doğrula

Yazdığın dosyadaki her komutu doğrula. **İki ayrı başarısızlık türü var ve
karıştırılmamalı:**

**A. Komut yanlış** — script `package.json`'da tanımlı değil, hedef dosya yok,
adı hatalı yazılmış. Bu bir kusurdur: düzelt ya da dosyadan çıkar.

**B. Ortam yetersiz** — komut doğru ama bu makinede çalıştırılamıyor: araç kurulu
değil (`pnpm`, `dotnet`, `gradle` yok), bağımlılıklar indirilmemiş, ağ yok.
Bu komutun kusuru değildir. **Silme.** Raporunda "çalıştırılarak doğrulanmadı"
diye işaretle ve sebebini yaz.

Bu ayrımı yapmazsan doğru komutları silersin. Gerçek bir vaka: hedef repo pnpm
kullanıyordu, komutlar CI tarafından zaten koşuluyordu, ama kurulum makinesinde
pnpm yoktu. "Çalıştıramadığını sil" kuralı harfiyen uygulansa altı doğru komut
birden silinecekti.

### Her zaman yapılabilen statik doğrulamalar

Araç kurulu olmasa bile bunlar kontrol edilir:

- Yazdığın her script adı proje tanım dosyasında (`package.json` → `scripts`,
  `pyproject.toml`, `*.csproj`) gerçekten var mı
- Script'in referans verdiği dosyalar mevcut mu — örneğin
  `tsc -p tsconfig.build.json` yazıyorsa o dosya repoda var mı
- CI workflow'unda geçen komutlarla yazdıkların çelişiyor mu
- `README` ile lock dosyası çelişiyor mu (lock dosyası kazanır)

Bu kontroller gerçek kusur bulur: yukarıdaki vakada `build` scriptinin var olmayan
bir `tsconfig.build.json` aradığı böyle ortaya çıktı.

### Raporlama

Kapanış tablosunda doğrulanan komut sayısını **iki ayrı sayı** olarak ver:
kaçı statik olarak doğrulandı, kaçı gerçekten çalıştırıldı. Çalıştırılmamış bir
komutu çalıştırılmış gibi gösterme.

## Kapanış

| Alan | Sonuç |
|---|---|
| Tespit edilen dil(ler) | |
| Paket yöneticisi | |
| Doğrulanan komut sayısı | |
| Kullanıcıya sorulan | |
| Silinen (doldurulamayan) bölüm | |
| Yazılan dosyalar | |

Sonra hatırlat: `CLAUDE.md` git'e girer ve takımla paylaşılır. Kişisel notlar
buraya değil, `memory/` altına yazılır — bkz. `memory-hygiene` skill'i.
