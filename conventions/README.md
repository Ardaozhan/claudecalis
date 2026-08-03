# Konvansiyonlar

Dil başına bir dosya. `impl-planner` ve `test-first` agent'ları tarafından
**okunur** — insan için değil, agent için yazılmışlardır.

## Çözdükleri problem

Bu agent'lar her repoda çalışıyor ve daha önce framework'ü, paket yöneticisini
ve test komutunu **tahmin ediyorlardı.** Tahmin ucuz değil:

- Yanlış paket yöneticisiyle kurulum lock dosyasını bozar, takımın geri kalanını
  etkiler.
- Var olmayan bir `npm script`'i plana yazılırsa adım çalıştırılamaz.
- Yanlış adlandırılmış bir test dosyası hiç toplanmaz; "0 failed" görünür ve
  kırmızı sanılan şey aslında hiç çalışmamıştır.

Her dosya bu üçünü kapatıyor: **nasıl tespit edilir, hangi komutlar geçerlidir,
o dilde en sık görülen sahte yeşil nedir.**

## Dosyalar

| Dosya | Tetikleyen |
|---|---|
| `typescript.md` | `package.json` |
| `python.md` | `pyproject.toml`, `requirements.txt`, `setup.py` |
| `java-kotlin.md` | `pom.xml`, `build.gradle`, `build.gradle.kts` |
| `dotnet.md` | `*.sln`, `*.csproj` |

## Nereye kurulur

`install.ps1` bunları `~/.claude/conventions/` altına kopyalar — agent'lar her
repoda çalıştığı için global olmaları gerekir. Bu repoda kalsalardı gerçek iş
repolarında görünmezlerdi.

Context maliyeti **sıfır**: agent bunları `Read` ile okur, otomatik yüklenmezler.
Yani dosya eklemek her session'a bedel bindirmez.

## Yeni dil eklerken

1. `conventions/<dil>.md` yaz. Üç bölüm zorunlu: **Tespit**, **Komutlar**,
   **Sık yapılan hata**.
2. `agents/test-first.md` ve `agents/impl-planner.md` içindeki tabloya satır ekle.
3. `.\install.ps1` çalıştır.

## Yazım kuralı

Genel tavsiye yazma. "Temiz kod yaz" bir konvansiyon değildir. Buraya yalnızca
**bu dilde yanlış yapılabilecek ve maliyeti olan** şeyler girer.
