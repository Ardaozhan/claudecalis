# C# / .NET konvansiyonları

> Bu dosya `test-first` ve `impl-planner` agent'ları tarafından okunur.

## Tespit

`*.sln`, `*.csproj` veya `global.json` varsa geçerlidir.

Hedef sürümü `<TargetFramework>` etiketinden oku (`net8.0`, `net9.0`, …).
Sürüm, kullanılabilecek dil özelliklerini belirler — varsayma.

## Test framework'ü

`*.Tests.csproj` içindeki `PackageReference`'lara bak:

| Paket | Framework | Test niteliği |
|---|---|---|
| `xunit` | xUnit | `[Fact]`, `[Theory]` |
| `NUnit` | NUnit | `[Test]`, `[TestCase]` |
| `MSTest.TestFramework` | MSTest | `[TestMethod]` |
| `Moq` / `NSubstitute` | Mock kütüphanesi | — |
| `FluentAssertions` | Assertion stili | `.Should()` |

Yeni projede yaygın varsayılan **xUnit**'tir.

## Komutlar

```
dotnet test                                   # tüm testler
dotnet test --filter "FullyQualifiedName~Ad"  # filtre
dotnet build
dotnet format --verify-no-changes             # format kontrolü
dotnet test --collect:"XPlat Code Coverage"   # kapsam
```

Çözüm dosyası birden fazla test projesi içeriyorsa `dotnet test <proje.csproj>`
ile daralt; tümünü çalıştırmak gereksiz yavaştır.

## Dosya düzeni

```
src/<Proje>/            ürün kodu
tests/<Proje>.Tests/    testler
```

Test projesi, test ettiği projeye `ProjectReference` ile bağlanır. Bağlantı
yoksa test derlenmez.

## Kırmızı test yazarken

- `[Fact]` niteliği unutulan metot **hiç çalıştırılmaz** ve test sayısı sessizce
  eksik kalır. Kırmızı beklerken "0 failed" görüyorsan önce bunu kontrol et.
- `async` testler `Task` döndürmeli. `async void` test yazılırsa framework onu
  bekleyemez; hata yutulur ve test yanlışlıkla geçer.
- `IDisposable` / `IAsyncLifetime` ile kurulum-temizlik yap; statik durum
  testler arasında sızar.

## Sık yapılan hata

`dotnet test`'in önce derlediğini unutmak. Derleme hatası varsa çıktı test
başarısızlığı gibi görünür ama değildir — `dotnet build` ile ayırt et.
