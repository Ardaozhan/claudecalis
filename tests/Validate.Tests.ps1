#
# Validate.Tests.ps1
#
# validate.ps1'in negatif testleri. Pester 3.4 sozdizimi.
#
# Hic basarisiz olmayan bir dogrulayici ise yaramaz. Bu takim, validate.ps1'in
# her hata turunu GERCEKTEN yakaladigini ve uyarilari hatadan ayirdigini
# kanitlar. CI dogrudan bu ayrima guveniyor: HATA -> cikis kodu 1, UYARI -> 0.
#
# Yontem: validate.ps1 gecici bir sahte repoya kopyalanir ($PSScriptRoot o dizine
# isaret eder) ve kasten bozuk dosyalarla calistirilir. Gercek repo hic
# degistirilmez.
#

$script:RepoRoot    = Split-Path -Parent $PSScriptRoot
$script:ValidateSrc = Join-Path $script:RepoRoot "validate.ps1"

if (-not (Test-Path $script:ValidateSrc)) {
    throw "validate.ps1 bulunamadi: $script:ValidateSrc"
}

# Sahte repo kurar: validate.ps1 + gecerli birer agent/skill/command.
# Testler bunun uzerine bozuk dosya ekleyerek calisir.
function New-FakeRepo {
    $Root = Join-Path $env:TEMP ("validate-test-" + [guid]::NewGuid().ToString())
    if ($Root -notlike (Join-Path $env:TEMP "*")) {
        throw "GUVENLIK DURDURMA: gecici kok TEMP altinda degil: $Root"
    }

    New-Item -ItemType Directory -Force -Path `
        (Join-Path $Root "agents"),
        (Join-Path $Root "commands"),
        (Join-Path $Root "skills\ornek-skill") | Out-Null

    Copy-Item -LiteralPath $script:ValidateSrc -Destination (Join-Path $Root "validate.ps1")

    @"
---
name: ornek-agent
description: Gecerli bir agent tanimi. Bu aciklama routing icin yeterince uzun ve ne zaman kullanilacagini anlatiyor.
tools: Read, Grep, Glob
model: sonnet
---
Govde.
"@ | Set-Content -LiteralPath (Join-Path $Root "agents\ornek-agent.md") -Encoding UTF8

    @"
---
name: ornek-skill
description: Gecerli bir skill tanimi. Aciklama yeterince uzun ve hangi durumda yuklenecegini anlatiyor.
---
Govde.
"@ | Set-Content -LiteralPath (Join-Path $Root "skills\ornek-skill\SKILL.md") -Encoding UTF8

    @"
---
description: Gecerli bir command tanimi. Aciklamasi yeterince uzun ve ne yaptigini net anlatiyor.
---
Govde.
"@ | Set-Content -LiteralPath (Join-Path $Root "commands\ornek-komut.md") -Encoding UTF8

    return $Root
}

# validate.ps1'i ayri process'te calistirir.
# Ayri process sart: script sonunda 'exit' cagiriyor, ayni process'te
# calistirilirsa Pester oturumunu da sonlandirirdi.
function Invoke-Validate {
    param([string]$RepoPath)

    $Script = Join-Path $RepoPath "validate.ps1"

    # ErrorActionPreference yerel olarak gevsetilir: native komut stderr'ini
    # yonlendirmek PowerShell 5.1'de NativeCommandError uretir ve cagiranin
    # tercihi "Stop" ise sonlandirici hataya doner. Bkz. Hooks.Tests.ps1.
    $Onceki = $ErrorActionPreference
    $ErrorActionPreference = 'Continue'
    try {
        $Output = & powershell.exe -NoProfile -ExecutionPolicy Bypass `
                      -File $Script -SkipTests -Quiet 2>&1 | Out-String
        return @{ Output = $Output; ExitCode = $LASTEXITCODE }
    } finally {
        $ErrorActionPreference = $Onceki
    }
}

Describe "validate.ps1" {

    BeforeEach {
        $script:OriginalProfile = $env:USERPROFILE
        $script:Repo = New-FakeRepo
        # Kurulu kopya senkron kontrolu gercek ~/.claude'a bakmasin diye
        # USERPROFILE gecici dizine yonlendirilir. Sonuc: sadece UYARI uretir.
        $env:USERPROFILE = $script:Repo
    }

    AfterEach {
        $env:USERPROFILE = $script:OriginalProfile
        if ($script:Repo -and (Test-Path $script:Repo)) {
            Remove-Item -LiteralPath $script:Repo -Recurse -Force -ErrorAction SilentlyContinue
        }
    }

    Context "temiz repo" {

        It "hatasiz repoda cikis kodu 0 doner" {
            $R = Invoke-Validate -RepoPath $script:Repo
            $R.ExitCode | Should Be 0
        }
    }

    Context "HATA seviyesi: cikis kodunu 1 yapar" {

        It "frontmatter'i olmayan agent tanimini yakalar" {
            Set-Content -LiteralPath (Join-Path $script:Repo "agents\bozuk.md") `
                        -Value "sadece govde, frontmatter yok" -Encoding UTF8

            $R = Invoke-Validate -RepoPath $script:Repo
            $R.ExitCode | Should Be 1
            $R.Output   | Should Match "Frontmatter yok"
        }

        It "name ile dosya adi uyusmazligini yakalar" {
            @"
---
name: bambaska
description: Aciklama yeterince uzun ama name alani dosya adiyla uyusmuyor.
---
"@ | Set-Content -LiteralPath (Join-Path $script:Repo "agents\uyusmaz.md") -Encoding UTF8

            $R = Invoke-Validate -RepoPath $script:Repo
            $R.ExitCode | Should Be 1
            $R.Output   | Should Match "uyusmuyor"
        }

        It "description eksikligini yakalar" {
            @"
---
name: aciklamasiz
---
"@ | Set-Content -LiteralPath (Join-Path $script:Repo "agents\aciklamasiz.md") -Encoding UTF8

            $R = Invoke-Validate -RepoPath $script:Repo
            $R.ExitCode | Should Be 1
            $R.Output   | Should Match "description"
        }

        It "SKILL.md icermeyen skill dizinini yakalar" {
            New-Item -ItemType Directory -Force `
                     -Path (Join-Path $script:Repo "skills\bos-skill") | Out-Null

            $R = Invoke-Validate -RepoPath $script:Repo
            $R.ExitCode | Should Be 1
            $R.Output   | Should Match "SKILL.md yok"
        }

        It "BOM'suz .ps1 dosyasini yakalar" {
            [System.IO.File]::WriteAllText(
                (Join-Path $script:Repo "bomsuz.ps1"),
                "Write-Host 'gecerli sozdizimi ama BOM yok'",
                (New-Object System.Text.UTF8Encoding $false))

            $R = Invoke-Validate -RepoPath $script:Repo
            $R.ExitCode | Should Be 1
            $R.Output   | Should Match "BOM yok"
        }

        It "sozdizimi hatali .ps1 dosyasini yakalar" {
            [System.IO.File]::WriteAllText(
                (Join-Path $script:Repo "hatali.ps1"),
                "if (`$true) { Write-Host `"kapanmamis string",
                (New-Object System.Text.UTF8Encoding $true))

            $R = Invoke-Validate -RepoPath $script:Repo
            $R.ExitCode | Should Be 1
            $R.Output   | Should Match "Sozdizimi hatasi"
        }
    }

    Context "UYARI seviyesi: cikis kodunu etkilemez" {

        It "cok kisa description uyari uretir ama basarisiz olmaz" {
            @"
---
name: kisa-aciklama
description: Kisa.
---
"@ | Set-Content -LiteralPath (Join-Path $script:Repo "agents\kisa-aciklama.md") -Encoding UTF8

            $R = Invoke-Validate -RepoPath $script:Repo
            $R.Output   | Should Match "cok kisa"
            $R.ExitCode | Should Be 0
        }

        It "bilinmeyen tool adi uyari uretir ama basarisiz olmaz" {
            @"
---
name: tuhaf-tool
description: Gecerli bir tanim ama tools alaninda var olmayan bir arac adi geciyor.
tools: Read, Yazmaca
---
"@ | Set-Content -LiteralPath (Join-Path $script:Repo "agents\tuhaf-tool.md") -Encoding UTF8

            $R = Invoke-Validate -RepoPath $script:Repo
            $R.Output   | Should Match "Bilinmeyen tool"
            $R.ExitCode | Should Be 0
        }

        It "taninmayan model adi uyari uretir ama basarisiz olmaz" {
            @"
---
name: tuhaf-model
description: Gecerli bir tanim ama model alaninda taninmayan bir deger var.
model: gpt-5
---
"@ | Set-Content -LiteralPath (Join-Path $script:Repo "agents\tuhaf-model.md") -Encoding UTF8

            $R = Invoke-Validate -RepoPath $script:Repo
            $R.Output   | Should Match "Taninmayan model"
            $R.ExitCode | Should Be 0
        }

        It "kurulu olmayan tanim uyari uretir ama basarisiz olmaz" {
            # USERPROFILE gecici dizine bakiyor; orada .claude yok.
            $R = Invoke-Validate -RepoPath $script:Repo
            $R.Output   | Should Match "Bulunamadi"
            $R.ExitCode | Should Be 0
        }
    }

    Context "birden fazla sorun" {

        It "hem hata hem uyari varken cikis kodu 1 olur" {
            Set-Content -LiteralPath (Join-Path $script:Repo "agents\bozuk.md") `
                        -Value "frontmatter yok" -Encoding UTF8
            @"
---
name: kisa2
description: Kisa.
---
"@ | Set-Content -LiteralPath (Join-Path $script:Repo "agents\kisa2.md") -Encoding UTF8

            $R = Invoke-Validate -RepoPath $script:Repo
            $R.Output   | Should Match "cok kisa"
            $R.Output   | Should Match "Frontmatter yok"
            $R.ExitCode | Should Be 1
        }
    }
}
