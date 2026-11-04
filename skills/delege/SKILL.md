---
name: delege
description: İşi Codex veya Antigravity (agy) CLI'ına devretmeye karar verir ve doğru komutla, güvenli kapsamla çalıştırır. Kullanıcı "Codex'e yaptır", "agy'ye ver", "token maliyetini düşür", "delege et" dediğinde ya da büyük, iyi tanımlı bir kod/tarama işi ana context'i kirleteceğinde kullan. Küçük işlerde devretme.
---

# Delege

Claude orkestra şefidir; Codex ve Antigravity (`agy`) iş dağıtılan araçlardır.
Amaç ana context'i ve Claude kotasını korumak. **Yalnız abonelikle çalış:** API
anahtarı veya kullanım başına ücret gerektiren yol yasak.

Aşağıdaki komutlar 2026-11-04/05'te bu makinede (Windows 11, Codex 0.166.0,
agy 1.3.2) doğrudan denenip doğrulandı. Sürüm değişirse yeniden dene.

## Varsayılanlar (kullanıcı model belirtmedikçe)

Kullanıcı 2026-11-05'te belirledi; komutla doğrulandı.

| Araç | Model |
|---|---|
| Codex | `gpt-6.1-terra` (`-m gpt-6.1-terra`) |
| Claude subagent | `haiku` (Agent çağrısında `model: haiku` açıkça yaz, "miras al" bırakma) |
| agy | `gemini-3.8-flash-medium` (`--model gemini-3.8-flash-medium`) |

- Kullanıcı başka model söylerse onu kullan. `agy models` ve
  `~/.codex/models_cache.json` geçerli adları listeler.
- agy'de Gemini 3.8 Flash'ın `low`/`medium`/`high` varyantları var; kullanıcı
  belirtmediği için `medium` seçildi. Daha zor işte `high` dene.
- **Bu araçlarla İngilizce konuş.** Codex, agy ve subagent prompt'larını
  İngilizce yaz. Kullanıcıyla Türkçe konuşmaya devam et.

## Devretmeden önce sor

1. **İş küçük mü?** (tek dosya, birkaç satır) → kendin yap. Prompt yazmak, sonucu
   okumak ve doğrulamak da token harcar.
2. **Spec net mi?** Codex'in kalitesi spesifikasyonun kalitesiyle sınırlıdır.
   Belirsiz işi devretme, önce netleştir.
3. **Ara katman gerekli mi?** Denemede haiku subagent iki komut için ~77k token
   harcadı; Codex'in kendi işi ~10k idi. Komutu **doğrudan kendin çalıştır**,
   çıktıyı filtrele. Subagent'ı yalnız gerçekten büyük, bağlam kirleten işte kullan.

## İş bölümü

| İş | Kime |
|---|---|
| Mimari, spec, entegrasyon, son karar, doğrulama | Claude |
| Net spec'li uygulama, test yazma, refactor | Codex |
| Görsel üretim | Codex (`arda` agent'ı) |
| Geniş okuma, özetleme, ham veri ayıklama | agy |

## Codex

```powershell
codex exec --skip-git-repo-check -s workspace-write -m gpt-6.1-terra -C "<dir>" "<task in English>"
```

- Salt okuma için `-s read-only`. Yazılacak klasörü `-C` ile sabitle.
- Çıktıya `hook:` satırları karışır; sonucu ve `tokens used` satırını **çıktının
  sonundan** oku.
- Codex'te `-i` prompt'u yutar; görsel eklerken `--` kullan.
- Testi **çalışma klasörünün içinden** çalıştır (`Push-Location <dir>`). Dışarıdan
  çalıştırmak proje klasörüne `.pytest_cache` bırakır.

## agy (Antigravity)

```powershell
agy --mode plan --print-timeout 120s --model gemini-3.8-flash-medium --settings <settings.json> -p "<task in English>"
```

Dosya okutacaksan oturuma özel kuralı settings dosyasına yaz (kalıcı ayara yazma):

```json
{"permissions":{"allow":["read_file(C:\\tam\\yol\\dosya.md)"]}}
```

- Kuralsız `read_file` headless modda otomatik reddedilir; **çıkış kodu yine 0**
  ve çıktı boş kalır. Başarıyı çıkış koduyla değil **çıktı metniyle** ölç;
  `no output produced` görürsen başarısız say.
- `read_file(<yol>)` kuralı `--settings` ile çalıştı. `command(...)` kuralı aynı
  yolla çalışmamıştı (2026-11-04 gözlemi, neden bilinmiyor; 11-05'te yeniden
  denenmedi). `read_file` kuralının kapsam sınırı test edilmedi.
- `--print-timeout` dolarsa cevap kaybolur. Uzun işi gruplara böl, kısa sınır koy.
- `--dangerously-skip-permissions`: **yalnız kullanıcının açık izniyle**, kısa ve
  dar işte. Ajana yasak uç noktaları ve "engelle karşılaşırsan dur, dolanma"
  kuralını prompt'ta yaz. (Denemede tam izinli agy YouTube iç uç noktalarını
  dolanmaya çalıştı.)
- Gemini CLI ücretsiz hesapta çalışmıyor (`IneligibleTierError`); kullanma.
- Paralel agy'yi durdurmak engellenebilir. Başlamadan süre sınırı koy.

## Doğrulama (zorunlu)

Devredilen işin "bitti" demesi kanıt değildir.

- Kod: dosyaları oku, testi kendin çalıştır.
- Özet: kaynağı kendin oku, her maddeyi karşılaştır; uydurma var mı bak.
- Toplu işe başlamadan **tek örnekte** yöntemin çalıştığını doğrula.
- Alt ajanın "tamamlandı" bildirimi final rapor olmayabilir (`waiting on its own
  background work` ara bildirimdir). Gerçek durumu dosya ve süreçten kontrol et.

## Kota

`limit` skill'i Claude ve Codex kotasını gösterir ama `~/.claude/.credentials.json`
içindeki OAuth belirtecine dokunur. **Çalıştırmadan önce kullanıcıdan onay al.**
Pencere dolmak üzereyse bekle, haftalık doluysa diğer havuza ver, ikisi de
doluysa devretme.

Ayrıntılı gözlemler: ikinci beyin `knowledge/concepts/orkestrasyon-gotchas.md`.
