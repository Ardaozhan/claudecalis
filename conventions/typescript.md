# TypeScript / JavaScript konvansiyonları

> Bu dosya `test-first` ve `impl-planner` agent'ları tarafından okunur.
> Amaç: framework'ü **tahmin etmeyi bırakmak.**

## Tespit

Repo kökünde `package.json` varsa bu dosya geçerlidir.

Paket yöneticisini **lock dosyasından** belirle, tahmin etme:

| Lock dosyası | Yönetici |
|---|---|
| `pnpm-lock.yaml` | `pnpm` |
| `yarn.lock` | `yarn` |
| `package-lock.json` | `npm` |
| `bun.lockb` | `bun` |

Yanlış yöneticiyle kurulum yapmak lock dosyasını bozar ve takımın geri kalanını
etkiler. Lock dosyası yoksa kullanıcıya sor.

## Test framework'ü

`package.json` içindeki `devDependencies`'e bak:

| Bağımlılık | Framework | Test dosya deseni |
|---|---|---|
| `vitest` | Vitest | `*.test.ts`, `*.spec.ts` |
| `jest` | Jest | `*.test.ts`, `__tests__/` |
| `mocha` | Mocha | `test/*.spec.js` |
| `node:test` | Node yerleşik | `*.test.js` |
| `@playwright/test` | Playwright (E2E) | `e2e/*.spec.ts` |

Hiçbiri yoksa test altyapısı yok demektir. Kurmadan önce **kullanıcıya sor** —
framework seçimi geri dönülmesi pahalı bir karardır.

## Komutlar

Uydurma; `package.json` → `scripts` içinden oku. Tipik adlar:

```
<yönetici> test              # tüm testler
<yönetici> test -- <dosya>   # tek dosya  (npm'de -- şart, pnpm'de değil)
<yönetici> run typecheck     # veya: npx tsc --noEmit
<yönetici> run lint
<yönetici> run build
```

`scripts` içinde karşılığı olmayan bir komutu plana yazma.

## Kırmızı test yazarken

- Testi **davranışa** bağla, iç fonksiyon adına değil.
- `expect(...).toBe(...)` yerine anlamlı assertion seç; hata mesajı okunabilir olsun.
- Async testlerde `await` unutma — unutulan `await` testi yanlışlıkla yeşil gösterir.
  Bu, TS/JS'de en sık görülen sahte yeşildir.
- Vitest ve Jest API'leri benzer ama **aynı değil**: `vi.mock` ↔ `jest.mock`,
  `vi.fn()` ↔ `jest.fn()`. Mevcut dosyalardaki kullanımı taklit et.

## Tip kontrolü

`tsc --noEmit` testlerden **ayrı** bir kapıdır. Testler yeşil olabilir ama tipler
bozuk olabilir. Kabul kriterine ikisini de koy.

## Sık yapılan hata

`strict: false` olan bir projede `strict` varsayarak kod yazmak. `tsconfig.json`
okunmadan tip kararı verilmez.
