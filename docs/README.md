# Kanıtlar

Agent koşularının çıktıları burada saklanır.

Sebebi: bir agent'ın **yazılmış olması çalıştığı anlamına gelmez.** Bu kurulumda
bunu bir kez yaşadık — `install.ps1` yazılmıştı, hiç çalıştırılmamıştı ve ilk
denemede parse hatasıyla patladı. O yüzden her agent'ın en az bir gerçek koşu
çıktısı burada durur.

## Dosyalar

| Dosya | Ne | Tarih |
|---|---|---|
| `context-audit-2026-08-03.md` | `context-auditor` ilk koşu — hatalı çıktı + düzeltme notu | 2026-08-03 |
| `pipeline-run-2026-08-03.md` | `/feature` hattının ilk uçtan uca koşusu — 5 adım, ŞARTLI GEÇTİ | 2026-08-03 |
| `context-audit-2026-08-04.md` | `context-auditor` ikinci koşu — doğru çıktı, ~11k token | 2026-08-04 |
| `bootstrap-run-2026-08-04.md` | `/bootstrap` ilk koşu — 2 gerçek kusur yakaladı, komutun kendi kusuru bulundu | 2026-08-04 |
| `convention-check-2026-08-04.md` | Agent'ların konvansiyon dosyalarını gerçekten okuduğunun doğrulanması | 2026-08-04 |

## Kapsanan parçalar

| Parça | Kanıt |
|---|---|
| `/feature` hattı (4 agent) | `pipeline-run-2026-08-03.md` |
| `context-auditor` | iki ayrı koşu dosyası |
| `/bootstrap` | `bootstrap-run-2026-08-04.md` |
| `change-reviewer` (bağımsız denetim) | `pipeline-run` + 2026-08-04 tutarlılık denetimi |
| Hook'lar | canlı tetiklendi; `tests/Hooks.Tests.ps1` (20 test) |
| `install.ps1 -Uninstall` | gerçek kurulumda koştu; ECC'nin 134 dosyası el değmedi |
| `validate.ps1` | `tests/Validate.Tests.ps1` (12 test) |

## Kural

Çıktıyı **olduğu gibi** kaydet. Düzeltme, kısaltma, güzelleştirme yok — kanıtın
değeri ham olmasından gelir. Yorum eklemek gerekiyorsa dosyanın başına ayrı bir
bölüm aç, agent çıktısına karışma.

Dosya adı: `<agent-adı>-<YYYY-MM-DD>.md`
