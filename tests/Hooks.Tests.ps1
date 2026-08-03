#
# Hooks.Tests.ps1
#
# hooks/ altindaki uc hook'un davranis testleri. Pester 3.4 sozdizimi.
#
# Hook'lar stdin'den JSON okuyup cikis kodu dondurur. Test bu sozlesmeyi
# dogrular: dogru durumda 0, engellenmesi gereken durumda 2.
#
# GUVENLIK: protect-installed-copies testleri $env:USERPROFILE'i TEMP altina
# yonlendirir, boylece "kurulu kopya" yolu gercek ~/.claude degil sahte bir
# dizin olur. Gercek kuruluma hicbir testte dokunulmaz.
#

$script:RepoRoot = Split-Path -Parent $PSScriptRoot
$script:HookDir  = Join-Path $script:RepoRoot "hooks"

$script:Protect  = Join-Path $script:HookDir "protect-installed-copies.ps1"
$script:Bom      = Join-Path $script:HookDir "ensure-ps1-bom.ps1"
$script:Definity = Join-Path $script:HookDir "validate-definition.ps1"

foreach ($H in @($script:Protect, $script:Bom, $script:Definity)) {
    if (-not (Test-Path $H)) { throw "Hook bulunamadi: $H" }
}

# Hook'u ayri bir process'te calistirir ve cikis kodunu dondurur.
# Ayri process sart: hook [Console]::In.ReadToEnd() ile stdin okuyor.
function Invoke-Hook {
    param(
        [string]$HookPath,
        [string]$FilePath,
        [switch]$NoPath
    )

    $Payload = if ($NoPath) { @{ tool_input = @{} } }
               else         { @{ tool_input = @{ file_path = $FilePath } } }

    $Json = $Payload | ConvertTo-Json -Compress

    # ErrorActionPreference yerel olarak gevsetilir. Sebep: PowerShell 5.1'de bir
    # NATIVE komutun (powershell.exe) stderr'ini yonlendirmek her satiri
    # NativeCommandError kaydina sarar; cagiranin tercihi "Stop" ise bu
    # sonlandirici hataya doner ve test, hook dogru calistigi halde patlar.
    #
    # Bu tam olarak yasandi: testler dogrudan calistirilinca 42/42 geciyordu,
    # validate.ps1 icinden (ki basinda ErrorActionPreference = "Stop" var)
    # calistirilinca stderr'e yazan 7 test kaliyordu.
    $Onceki = $ErrorActionPreference
    $ErrorActionPreference = 'Continue'
    try {
        $Json | powershell.exe -NoProfile -ExecutionPolicy Bypass -File $HookPath 2>$null | Out-Null
        return $LASTEXITCODE
    } finally {
        $ErrorActionPreference = $Onceki
    }
}

function New-TempRoot {
    $Path = Join-Path $env:TEMP ("hooks-test-" + [guid]::NewGuid().ToString())
    if ($Path -notlike (Join-Path $env:TEMP "*")) {
        throw "GUVENLIK DURDURMA: gecici kok TEMP altinda degil: $Path"
    }
    New-Item -ItemType Directory -Path $Path -Force | Out-Null
    return $Path
}

Describe "hooks/protect-installed-copies.ps1" {

    BeforeEach {
        $script:OriginalProfile = $env:USERPROFILE
        $script:TempRoot = New-TempRoot
        $script:FakeClaude = Join-Path $script:TempRoot ".claude"

        # Guard: sahte hedef gercek kuruluma esit olamaz
        if ($script:FakeClaude -ieq (Join-Path $script:OriginalProfile ".claude")) {
            throw "GUVENLIK DURDURMA: sahte hedef gercek .claude ile ayni"
        }

        New-Item -ItemType Directory -Path (Join-Path $script:FakeClaude "agents") -Force | Out-Null
        $env:USERPROFILE = $script:TempRoot
    }

    AfterEach {
        $env:USERPROFILE = $script:OriginalProfile
        if ($script:TempRoot -and (Test-Path $script:TempRoot)) {
            Remove-Item -LiteralPath $script:TempRoot -Recurse -Force -ErrorAction SilentlyContinue
        }
    }

    It "kurulu kopyaya yazmayi engeller (cikis kodu 2)" {
        $Target = Join-Path $script:FakeClaude "agents\spec-writer.md"
        (Invoke-Hook -HookPath $script:Protect -FilePath $Target) | Should Be 2
    }

    It "kurulu commands dizinini de korur" {
        $Target = Join-Path $script:FakeClaude "commands\feature.md"
        (Invoke-Hook -HookPath $script:Protect -FilePath $Target) | Should Be 2
    }

    It "kurulu skills dizinini de korur" {
        $Target = Join-Path $script:FakeClaude "skills\memory-hygiene\SKILL.md"
        (Invoke-Hook -HookPath $script:Protect -FilePath $Target) | Should Be 2
    }

    It "kaynak repodaki dosyaya dokunmaz (cikis kodu 0)" {
        $Target = Join-Path $script:RepoRoot "agents\spec-writer.md"
        (Invoke-Hook -HookPath $script:Protect -FilePath $Target) | Should Be 0
    }

    It "~/.claude altindaki korumasiz dosyaya izin verir" {
        # CLAUDE.md ve MINE.md korunan katmanlarin disinda; install.ps1 onlari uretmiyor.
        $Target = Join-Path $script:FakeClaude "CLAUDE.md"
        (Invoke-Hook -HookPath $script:Protect -FilePath $Target) | Should Be 0
    }

    It "yol icermeyen girdide isi engellemez" {
        (Invoke-Hook -HookPath $script:Protect -NoPath) | Should Be 0
    }
}

Describe "hooks/ensure-ps1-bom.ps1" {

    BeforeEach { $script:TempRoot = New-TempRoot }

    AfterEach {
        if ($script:TempRoot -and (Test-Path $script:TempRoot)) {
            Remove-Item -LiteralPath $script:TempRoot -Recurse -Force -ErrorAction SilentlyContinue
        }
    }

    It "BOM'suz .ps1 dosyasina BOM ekler" {
        $Ps1 = Join-Path $script:TempRoot "bomsuz.ps1"
        [System.IO.File]::WriteAllText($Ps1, "Write-Host 'merhaba'",
                                       (New-Object System.Text.UTF8Encoding $false))

        [System.IO.File]::ReadAllBytes($Ps1)[0] | Should Not Be 239

        (Invoke-Hook -HookPath $script:Bom -FilePath $Ps1) | Should Be 0

        [System.IO.File]::ReadAllBytes($Ps1)[0] | Should Be 239
    }

    It "BOM eklerken dosya icerigini bozmaz" {
        $Ps1 = Join-Path $script:TempRoot "icerik.ps1"
        $Metin = "# ustbilgi`r`nWrite-Host 'deger'`r`n"
        [System.IO.File]::WriteAllText($Ps1, $Metin, (New-Object System.Text.UTF8Encoding $false))

        Invoke-Hook -HookPath $script:Bom -FilePath $Ps1 | Out-Null

        $Sonra = Get-Content -LiteralPath $Ps1 -Raw -Encoding UTF8
        $Sonra.Contains("Write-Host 'deger'") | Should Be $true
        $Sonra.Contains("# ustbilgi")         | Should Be $true
    }

    It "BOM'u zaten olan dosyaya ikinci BOM eklemez" {
        $Ps1 = Join-Path $script:TempRoot "bomlu.ps1"
        [System.IO.File]::WriteAllText($Ps1, "Write-Host 'x'",
                                       (New-Object System.Text.UTF8Encoding $true))
        $Once = [System.IO.File]::ReadAllBytes($Ps1).Length

        Invoke-Hook -HookPath $script:Bom -FilePath $Ps1 | Out-Null

        [System.IO.File]::ReadAllBytes($Ps1).Length | Should Be $Once
    }

    It ".ps1 disindaki dosyaya dokunmaz" {
        $Md = Join-Path $script:TempRoot "belge.md"
        [System.IO.File]::WriteAllText($Md, "# baslik", (New-Object System.Text.UTF8Encoding $false))

        (Invoke-Hook -HookPath $script:Bom -FilePath $Md) | Should Be 0
        [System.IO.File]::ReadAllBytes($Md)[0] | Should Not Be 239
    }

    It "var olmayan dosyada hata vermez" {
        $Yok = Join-Path $script:TempRoot "hic-yok.ps1"
        (Invoke-Hook -HookPath $script:Bom -FilePath $Yok) | Should Be 0
    }
}

Describe "hooks/validate-definition.ps1" {

    BeforeEach {
        $script:TempRoot = New-TempRoot
        New-Item -ItemType Directory -Force -Path `
            (Join-Path $script:TempRoot "agents"),
            (Join-Path $script:TempRoot "commands"),
            (Join-Path $script:TempRoot "skills\iyi-skill") | Out-Null
    }

    AfterEach {
        if ($script:TempRoot -and (Test-Path $script:TempRoot)) {
            Remove-Item -LiteralPath $script:TempRoot -Recurse -Force -ErrorAction SilentlyContinue
        }
    }

    It "frontmatter'i olmayan agent tanimini yakalar" {
        $F = Join-Path $script:TempRoot "agents\bozuk.md"
        Set-Content -LiteralPath $F -Value "sadece govde" -Encoding UTF8
        (Invoke-Hook -HookPath $script:Definity -FilePath $F) | Should Be 2
    }

    It "kapanis --- satiri olmayan frontmatter'i yakalar" {
        $F = Join-Path $script:TempRoot "agents\kapanmamis.md"
        @"
---
name: kapanmamis
description: Kapanis tiresi olmayan bir frontmatter, gecerli sayilmamali.
"@ | Set-Content -LiteralPath $F -Encoding UTF8
        (Invoke-Hook -HookPath $script:Definity -FilePath $F) | Should Be 2
    }

    It "name ile dosya adi uyusmazligini yakalar" {
        $F = Join-Path $script:TempRoot "agents\isim-uyusmaz.md"
        @"
---
name: baska-isim
description: Aciklama yeterince uzun ama name alani dosya adiyla uyusmuyor.
---
"@ | Set-Content -LiteralPath $F -Encoding UTF8
        (Invoke-Hook -HookPath $script:Definity -FilePath $F) | Should Be 2
    }

    It "description eksikligini yakalar" {
        $F = Join-Path $script:TempRoot "agents\aciklamasiz.md"
        @"
---
name: aciklamasiz
---
"@ | Set-Content -LiteralPath $F -Encoding UTF8
        (Invoke-Hook -HookPath $script:Definity -FilePath $F) | Should Be 2
    }

    It "gecerli agent tanimini serbest birakir" {
        $F = Join-Path $script:TempRoot "agents\gecerli.md"
        @"
---
name: gecerli
description: Dogru yazilmis bir agent tanimi; name dosya adiyla birebir ayni.
---
Govde.
"@ | Set-Content -LiteralPath $F -Encoding UTF8
        (Invoke-Hook -HookPath $script:Definity -FilePath $F) | Should Be 0
    }

    It "skill tanimini dizin adina gore dogrular" {
        $F = Join-Path $script:TempRoot "skills\iyi-skill\SKILL.md"
        @"
---
name: iyi-skill
description: Dogru yazilmis bir skill tanimi; name dizin adiyla birebir ayni.
---
"@ | Set-Content -LiteralPath $F -Encoding UTF8
        (Invoke-Hook -HookPath $script:Definity -FilePath $F) | Should Be 0
    }

    It "command tanimindan name alani beklemez" {
        # Command'in adi dosya adidir; frontmatter'da name alani yoktur.
        $F = Join-Path $script:TempRoot "commands\komut.md"
        @"
---
description: Sadece description iceren gecerli bir command tanimi, name yok.
---
"@ | Set-Content -LiteralPath $F -Encoding UTF8
        (Invoke-Hook -HookPath $script:Definity -FilePath $F) | Should Be 0
    }

    It "tanim dosyasi olmayan markdown'a karismaz" {
        $F = Join-Path $script:TempRoot "README.md"
        Set-Content -LiteralPath $F -Value "sadece bir readme" -Encoding UTF8
        (Invoke-Hook -HookPath $script:Definity -FilePath $F) | Should Be 0
    }

    It "markdown olmayan dosyaya karismaz" {
        $F = Join-Path $script:TempRoot "agents\betik.ps1"
        Set-Content -LiteralPath $F -Value "Write-Host 'x'" -Encoding UTF8
        (Invoke-Hook -HookPath $script:Definity -FilePath $F) | Should Be 0
    }
}
