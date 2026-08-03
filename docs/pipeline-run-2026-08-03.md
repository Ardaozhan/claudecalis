# /feature hattı — ilk uçtan uca koşu (2026-08-03)

Dört agent'lık zincirin ilk gerçek çalıştırılması.

**İş:** `install.ps1`'e `-Uninstall` anahtarı eklemek.

| Adım | Agent | Sonuç |
|---|---|---|
| 1 | `spec-writer` | 9 kabul kriteri, 3 açık soru |
| 2 | `impl-planner` | 5 adım, 9/9 kriter eşlendi |
| 3 | `test-first` | 10 test, 9 kırmızı + 1 beklenen yeşil |
| 4 | ana thread | `install.ps1` + test yardımcı fonksiyonu |
| 5 | `change-reviewer` | **ŞARTLI GEÇTİ** — fonksiyonel bulgu yok |

Son test durumu: **10/10 yeşil.**

---

## Hattın işe yaradığı üç an

### 1. Açık sorular gerçekten durdurdu

`spec-writer` üç soru bıraktı: boş kalan skill dizini silinsin mi, elle
değiştirilmiş dosya silinsin mi, onay istemi olsun mu. Hat bunları kullanıcıya
sordu ve cevap gelmeden ilerlemedi.

Üçünün de cevabı davranışı değiştirdi. Varsayımla ilerlense üçü de yanlış
tarafa düşebilirdi — özellikle "elle değiştirilmiş dosyayı silme" kararı, veri
kaybı ile veri koruma arasındaki fark.

### 2. Denetim, uygulayanın kendi commit hatasını buldu

`change-reviewer` iki kapsam taşması buldu ve ikisi de doğruydu: alakasız bir
dokümantasyon dosyası özellik commit'ine karışmıştı ve PLAN'ın durma noktası
aşılmıştı. Fonksiyonel bulgu yoktu, ama denetçi "GEÇTİ" demek yerine
"ŞARTLI GEÇTİ" dedi.

Denetçide Write/Edit yetkisi olmaması burada işe yaradı: bulguyu bildirdi,
düzeltmeyi kullanıcının kararına bıraktı.

### 3. En önemlisi — hatalı test yakalandı

`test-first` 10 test yazdı, 9'unun kırmızı olduğunu raporladı ve kendi kalite
kuralı gereği "kırmızılık sebebi doğru mu" kontrolünü yaptığını, sebebin
"feature eksik" olduğunu, import/typo hatası olmadığını **açıkça yazdı.**

Yanılmıştı.

Testler şu satır yüzünden kırmızıydı:

```powershell
& $script:InstallScriptPath @Arguments      # $Arguments bir string[]
```

PowerShell'de **dizi splatlaması named switch bağlamaz.** Değerler positional
argümana dönüşüp `$args`'a düşer, `[switch]$Uninstall` `$false` kalır. Yani
anahtar hiç geçirilmiyordu — mükemmel bir uygulama bile bu testleri geçemezdi.

Deneysel kanıt:

```
1) dizi splat  (& script @a)                 : DryRun=False Uninstall=False args=-Uninstall,-DryRun
2) dogrudan    (& script -Uninstall -DryRun) : DryRun=True  Uninstall=True  args=
```

Uygulama tamamlandıktan sonra testler hâlâ kırmızıydı. `feature.md`'nin
"testleri değiştirme, dur ve kullanıcıya söyle" kuralı burada tetiklendi.
Testler sessizce "düzeltilip" yeşile çevrilseydi, hiçbir şeyi korumayan bir
test takımı elde edilirdi.

Düzeltme hashtable splatlaması: `$Splat[$Arg.TrimStart('-')] = $true`.

---

## Öğrenilen

**Agent çıktısı doğrulanmadan kabul edilmez.** Bu koşuda iki agent da emin bir
dille yanlış bir şey söyledi:

- `test-first`: "kırmızılık sebebi doğru" → değildi
- `context-auditor` (ayrı koşu): "rules yüklenmiyor" → yükleniyordu

İkisi de dikkatli, gerekçeli ve yanlıştı. Zincirin değeri tam olarak burada:
her halka bir öncekini denetleyecek biçimde konumlanmış.
