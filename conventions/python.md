# Python konvansiyonları

> Bu dosya `test-first` ve `impl-planner` agent'ları tarafından okunur.

## Tespit

Repo kökünde şunlardan biri varsa geçerlidir: `pyproject.toml`,
`requirements.txt`, `setup.py`, `Pipfile`.

Ortam yöneticisini dosyadan belirle:

| Dosya / işaret | Araç |
|---|---|
| `uv.lock` | `uv` |
| `poetry.lock` | `poetry` |
| `Pipfile.lock` | `pipenv` |
| `requirements.txt` tek başına | `pip` + venv |

Sanal ortamın **etkin olup olmadığını** kontrol et. Etkin değilse komutları
`uv run` / `poetry run` ön ekiyle çalıştır; yoksa sistem Python'una paket
kurulur ve bu geri alınması can sıkıcı bir hatadır.

## Test framework'ü

| İşaret | Framework |
|---|---|
| `pytest` bağımlılığı, `conftest.py`, `pytest.ini`, `[tool.pytest]` | pytest |
| `test_*.py` + `unittest.TestCase` | unittest |

Yeni projede varsayılan **pytest**'tir.

## Komutlar

```
pytest                      # tüm testler
pytest path/to/test_x.py    # tek dosya
pytest -k "isim"            # isme göre filtre
pytest --cov=<paket>        # kapsam
ruff check .                # lint   (yoksa: flake8)
ruff format .               # format (yoksa: black .)
mypy <paket>                # tip kontrolü, varsa
```

`pyproject.toml` içinde `[tool.ruff]` veya `[tool.black]` yoksa formatlayıcıyı
kendiliğinden çalıştırma — projenin tercihi olmayabilir.

## Kırmızı test yazarken

- Test dosyası adı `test_*.py`, fonksiyon adı `test_*` olmalı; aksi halde pytest
  onu **hiç toplamaz** ve "0 test" görünür. Bu, sahte yeşilin en sık sebebidir.
- `assert` yeterlidir; pytest zaten ayrıntılı çıktı üretir.
- Parametrik durumlar için `@pytest.mark.parametrize` kullan, döngü içinde assert
  yazma — döngüde ilk hata kalanları gizler.
- Fixture'ları `conftest.py`'a koy, test dosyasına değil.

## Sık yapılan hata

Import hatasından patlayan testi "kırmızı" saymak. `ModuleNotFoundError` bir test
başarısızlığı değil, bozuk bir kurulumdur. Önce `pytest --collect-only` ile
testlerin toplanabildiğini doğrula.
