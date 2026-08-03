# Kanıtlar

Agent koşularının çıktıları burada saklanır.

Sebebi: bir agent'ın **yazılmış olması çalıştığı anlamına gelmez.** Bu kurulumda
bunu bir kez yaşadık — `install.ps1` yazılmıştı, hiç çalıştırılmamıştı ve ilk
denemede parse hatasıyla patladı. O yüzden her agent'ın en az bir gerçek koşu
çıktısı burada durur.

## Dosyalar

| Dosya | Ne | Tarih |
|---|---|---|
| `context-audit-2026-08-03.md` | `context-auditor` ilk koşu — kurulumun token maliyeti | 2026-08-03 |

## Kural

Çıktıyı **olduğu gibi** kaydet. Düzeltme, kısaltma, güzelleştirme yok — kanıtın
değeri ham olmasından gelir. Yorum eklemek gerekiyorsa dosyanın başına ayrı bir
bölüm aç, agent çıktısına karışma.

Dosya adı: `<agent-adı>-<YYYY-MM-DD>.md`
