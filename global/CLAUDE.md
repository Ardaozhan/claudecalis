# Kullanıcı Seviyesi Talimatlar

Bu dosya her projede yüklenir. Proje-özel bilgiler buraya DEĞİL, ilgili projenin
kendi `CLAUDE.md` dosyasına yazılır.

## Dil

- Benimle **Türkçe** konuş. Kod, commit mesajları, değişken adları ve dosya
  içerikleri İngilizce kalsın.
- Teknik terimleri çevirme: "context window", "subagent", "hook" olduğu gibi kalsın.

## Çalıştığım Teknolojiler

TypeScript/JavaScript, Python, Java/Kotlin, C#/.NET — çok dilli bir ortamdayım.
Dil-özel kurallar `~/.claude/rules/<dil>/` altında; genel kurallar
`~/.claude/rules/common/` altında ve otomatik yükleniyor.

Yeni bir repoya girdiğinde önce hangi dil olduğunu tespit et, ilgili rules setine
göre davran. Karışık repolarda dosya bazında karar ver.

## Çalışma Tarzım

- **Önce açıkla, sonra yaz.** Büyük bir değişikliğe girişmeden önce ne yapacağını
  bir-iki cümleyle söyle.
- Bir şeyi neden öyle yaptığını belirt. Öğrenme aşamasındayım; sessizce doğru
  cevap vermek yerine gerekçeyi göster.
- Emin olmadığın yerde tahmin etme, "bilmiyorum" veya "kontrol edeyim" de.

## Context Disiplini

- Çok dosya taraması gerektiren işleri **subagent'a** ver, ana context'i kirletme.
- Bir tool çıktısı çok büyükse önce filtrele (`head`, `grep`, `--json` gibi),
  sonra oku.
- Kalıcı olması gereken bilgiyi konuşmada bırakma — `memory-hygiene` skill'indeki
  karar ağacına göre doğru katmana yaz.
- **Subagent ana thread'in context'ini göremez.** Ona "şu an context'te ne var",
  "bu dosya yükleniyor mu" gibi sorular sorma; dosya sistemine bakıp tahmin
  yürütür ve emin bir dille yanılır. Göremediği bilgiyi prompt'a koy, ya da
  soruyu `/context` ile kendin cevapla.
- Agent çıktısını doğrulamadan kabul etme. Gerekçeli ve kendinden emin bir rapor
  yanlış olabilir.

## Kurulum Sahipliği

`~/.claude/` altındaki çoğu şey **ECC hazır paketinden** geliyor; elle yazılmadı.
Elle yazılanların listesi `~/.claude/MINE.md` dosyasında.

Yeni bir agent, skill veya command elle yazıldığında `MINE.md` güncellenir.

## Yeni Projeye Başlarken

Gerçek bir iş reposunda çalışmaya başlarken projenin kendi `CLAUDE.md` dosyası
olmalı. Şablon: `~/claudecalis/templates/CLAUDE.md.template`
