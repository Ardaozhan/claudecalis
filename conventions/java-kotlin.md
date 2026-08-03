# Java / Kotlin konvansiyonları

> Bu dosya `test-first` ve `impl-planner` agent'ları tarafından okunur.

## Tespit

| Dosya | Build aracı |
|---|---|
| `pom.xml` | Maven |
| `build.gradle` | Gradle (Groovy DSL) |
| `build.gradle.kts` | Gradle (Kotlin DSL) |

Wrapper varsa **wrapper kullanılır**: `./gradlew` / `gradlew.bat`, `./mvnw`.
Sistemdeki `gradle`/`mvn` farklı sürüm olabilir ve derleme sonucu değişir.

Windows'ta `gradlew.bat` ve `mvnw.cmd`; Bash tool'undan çağrılıyorsa `./gradlew`
de çalışır.

## Test framework'ü

| İşaret | Framework |
|---|---|
| `junit-jupiter` | JUnit 5 — `@Test`, `org.junit.jupiter.api` |
| `junit:junit:4` | JUnit 4 — `@Test`, `org.junit` (eski) |
| `kotest` | Kotest (Kotlin) — `StringSpec`, `FunSpec` |
| `mockk` | MockK (Kotlin mock) |
| `mockito` | Mockito (Java mock) |
| `testcontainers` | Entegrasyon testleri, Docker gerektirir |

JUnit 4 ile 5 API'leri **karışmaz**; import'lara bakarak hangisi olduğunu belirle.

## Komutlar

Gradle:
```
./gradlew test                          # tüm testler
./gradlew test --tests "*SinifAdi*"     # filtre
./gradlew build
./gradlew check                         # test + lint
./gradlew koverHtmlReport               # kapsam (Kover, Kotlin)
```

Maven:
```
./mvnw test
./mvnw -Dtest=SinifAdi test
./mvnw verify
```

## Dosya düzeni

```
src/main/java/...    veya  src/main/kotlin/...
src/test/java/...    veya  src/test/kotlin/...
```

Test dosyası, ürettiği sınıfın **paket yapısını aynen** takip eder. Farklı
pakete konan test, paket-özel (package-private) üyelere erişemez.

## Kırmızı test yazarken

- Sınıf adı `*Test` ile bitmeli; Gradle/Maven varsayılan deseni budur, aksi halde
  test **hiç çalıştırılmaz** ve "BUILD SUCCESSFUL" yanıltır.
- Spring Boot'ta `@SpringBootTest` tüm context'i ayağa kaldırır ve yavaştır.
  Tek katman test edilecekse `@WebMvcTest` / `@DataJpaTest` tercih edilir.
- Kotlin'de `internal` üyeler aynı modülden test edilebilir; farklı modülden
  edilemez.

## Sık yapılan hata

Gradle'ın test sonucunu önbelleğe almasını fark etmemek. Kod değişmediyse
`./gradlew test` testi **yeniden çalıştırmaz**, "UP-TO-DATE" der. Kırmızıyı
doğrulamak için `--rerun-tasks` ekle.
