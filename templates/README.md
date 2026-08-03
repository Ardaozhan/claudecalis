# Şablonlar

Gerçek iş repolarına düşürülecek hazır dosyalar.

## `CLAUDE.md.template`

Yeni bir projeye başlarken:

```bash
cp ~/claudecalis/templates/CLAUDE.md.template <repo>/CLAUDE.md
```

Sonra doldur ve **doldurmadığın bölümleri sil.**

### Doldururken Kural

**Az ve kesin > çok ve muğlak.** Bu dosya her session'da tam olarak context'e
yüklenir; her satırın bedeli var.

Şunları **yazma** — model zaten koddan okuyabilir:
- Dizin ağacının tamamı
- `package.json` içindeki bağımlılık listesi
- Geçmişte düzeltilmiş bug'lar
- Genel kodlama tavsiyeleri ("temiz kod yaz" gibi)

Şunları **yaz** — koddan okunamaz:
- Hangi komutun çalıştığı (özellikle npm mi pnpm mi)
- Dokunulmaması gereken yerler
- İşin "bitti" sayılma kriteri
- Yakında değişecek şeyler

### Boyut Hedefi

150 satırı geçtiyse böl: detayları ayrı dosyaya al, `CLAUDE.md` içinden
`@docs/mimari.md` şeklinde import et. Import edilen dosya da yüklenir, ama
düzeni korumuş olursun.

### Takım Kullanımı

`CLAUDE.md` git'e girer, herkes aynı dosyayı kullanır. Kişisel notların
(`memory/`) buraya karışmamalı — onlar sana özeldir ve paylaşılmaz.
