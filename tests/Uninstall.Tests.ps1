#
# Uninstall.Tests.ps1
#
# install.ps1 icin henuz yazilmamis "-Uninstall" anahtarinin RED testleri.
# Pester 3.4.0 sozdizimi kullanilir (Describe/Context/It, "Should Be" stili -
# bkz. Get-Module -ListAvailable Pester).
#
# GUVENLIK KISITI:
# Bu testler ASLA gercek C:\Users\ardao\.claude dizinine dokunmaz. Her test
# $env:USERPROFILE degiskenini TEMP altinda bir kerelik gecici bir dizine
# yonlendirir, install.ps1'i o gecici hedefe karsi calistirir ve sonunda eski
# degerine geri koyar. Her testin basinda ayrica bir guvenlik guard'i vardir:
# hesaplanan sahte hedef gercek .claude yoluna esitse veya TEMP altinda
# degilse test kendini "throw" ile durdurur.
#
# ONEMLI BULGU (bkz. rapor):
# install.ps1 bilinmeyen bir named parametre ("-Uninstall") ile cagrildiginda
# PowerShell 5.1 hata FIRLATMIYOR; parametre sessizce yok sayilip script normal
# "install" akisiyla calisiyor. Bu yuzden asagidaki testler "cagri patlar mi"
# diye degil, dogrudan GOZLENEN DAVRANISA (dosya silinmis mi, konsol ciktisi
# ne diyor) bakarak KIRMIZI'yi kanitliyor.

$script:RepoRoot          = Split-Path -Parent $PSScriptRoot
$script:InstallScriptPath = Join-Path $script:RepoRoot "install.ps1"
$script:RepoAgentsDir     = Join-Path $script:RepoRoot "agents"
$script:RepoCommandsDir   = Join-Path $script:RepoRoot "commands"
$script:RepoSkillsDir     = Join-Path $script:RepoRoot "skills"
$script:RealClaudeHome    = "C:\Users\ardao\.claude"

if (-not (Test-Path $script:InstallScriptPath)) {
    throw "install.ps1 bulunamadi: $script:InstallScriptPath"
}

function New-UninstallTestFixture {
    $script:OriginalUserProfile = $env:USERPROFILE

    $Guid = [guid]::NewGuid().ToString()
    $script:TempRoot = Join-Path $env:TEMP ("claudecalis-uninstall-" + $Guid)

    # GUVENLIK GUARD #1: gecici kok gercekten TEMP altinda olmali
    if ($script:TempRoot -notlike (Join-Path $env:TEMP "*")) {
        throw "GUVENLIK DURDURMA: gecici kok TEMP altinda degil: $($script:TempRoot)"
    }

    New-Item -ItemType Directory -Path $script:TempRoot -Force | Out-Null

    $script:FakeClaudeHome = Join-Path $script:TempRoot ".claude"

    # GUVENLIK GUARD #2: sahte hedef gercek .claude dizinine ESIT OLAMAZ
    if ($script:FakeClaudeHome -ieq $script:RealClaudeHome) {
        throw "GUVENLIK DURDURMA: sahte hedef gercek .claude dizinine esit: $($script:FakeClaudeHome)"
    }

    # GUVENLIK GUARD #3: sahte hedef TEMP altinda olmali
    if ($script:FakeClaudeHome -notlike (Join-Path $env:TEMP "*")) {
        throw "GUVENLIK DURDURMA: sahte hedef TEMP altinda degil: $($script:FakeClaudeHome)"
    }

    New-Item -ItemType Directory -Path (Join-Path $script:FakeClaudeHome "agents")   -Force | Out-Null
    New-Item -ItemType Directory -Path (Join-Path $script:FakeClaudeHome "commands") -Force | Out-Null
    New-Item -ItemType Directory -Path (Join-Path $script:FakeClaudeHome "skills")   -Force | Out-Null

    $env:USERPROFILE = $script:TempRoot
}

function Remove-UninstallTestFixture {
    $env:USERPROFILE = $script:OriginalUserProfile

    if ($script:TempRoot -and ($script:TempRoot -like (Join-Path $env:TEMP "*")) -and (Test-Path $script:TempRoot)) {
        Remove-Item -Path $script:TempRoot -Recurse -Force -ErrorAction SilentlyContinue
    }
}

function Copy-RepoAgentToFake {
    param([string]$Name)
    Copy-Item -Path (Join-Path $script:RepoAgentsDir $Name) `
              -Destination (Join-Path $script:FakeClaudeHome "agents\$Name") -Force
}

function Copy-RepoCommandToFake {
    param([string]$Name)
    Copy-Item -Path (Join-Path $script:RepoCommandsDir $Name) `
              -Destination (Join-Path $script:FakeClaudeHome "commands\$Name") -Force
}

function Copy-RepoSkillToFake {
    param([string]$Name)
    $DstDir = Join-Path $script:FakeClaudeHome "skills\$Name"
    New-Item -ItemType Directory -Path $DstDir -Force | Out-Null
    Copy-Item -Path (Join-Path $script:RepoSkillsDir "$Name\SKILL.md") `
              -Destination (Join-Path $DstDir "SKILL.md") -Force
}

function Invoke-InstallUnderTest {
    param([string[]]$Arguments = @())

    # DIKKAT: dizi splatlamasi (@Arguments, $Arguments bir string[] iken) named
    # switch parametrelerini BAGLAMAZ. PowerShell degerleri positional arguman
    # olarak gecirir, $args'a duserler ve [switch]$Uninstall False kalir.
    # Dogru yol hashtable splatlamasidir. Bu hata bir kez yasandi ve 9 testin
    # yanlis sebepten kirmizi gorunmesine yol acti.
    $Splat = @{}
    foreach ($Arg in $Arguments) { $Splat[$Arg.TrimStart('-')] = $true }

    $CapturedOutput = ""
    $CaughtError = $null
    try {
        $CapturedOutput = (& $script:InstallScriptPath @Splat *>&1 | Out-String)
    } catch {
        $CaughtError = $_
    }
    return @{ Output = $CapturedOutput; Error = $CaughtError }
}

Describe "install.ps1 -Uninstall" {

    BeforeEach {
        New-UninstallTestFixture
    }

    AfterEach {
        Remove-UninstallTestFixture
    }

    It "Kriter 1: -Uninstall verilmeden calisirsa mevcut kurulum davranisi degismeden surer" {
        # NOT: Bu kriter -Uninstall'i degil, onun YOKLUGUNU test ediyor.
        # -Uninstall gecirilmedigi icin script zaten degismemis eski akisi
        # calistirir; bu yuzden bu testin BEKLENEN sonucu simdiden YESIL'dir.
        # Ayrintili aciklama: raporun "Calistirma" bolumune bakiniz.
        $Result = Invoke-InstallUnderTest -Arguments @()

        $AgentFile   = Join-Path $script:FakeClaudeHome "agents\change-reviewer.md"
        $CommandFile = Join-Path $script:FakeClaudeHome "commands\feature.md"
        $SkillFile   = Join-Path $script:FakeClaudeHome "skills\memory-hygiene\SKILL.md"

        (Test-Path $AgentFile)   | Should Be $true
        (Test-Path $CommandFile) | Should Be $true
        (Test-Path $SkillFile)   | Should Be $true
    }

    It "Kriter 2 ve 6: -Uninstall ile agents katmanindaki eslesen dosya silinir, repoda karsiligi olmayan dosyaya dokunulmaz" {
        Copy-RepoAgentToFake -Name "change-reviewer.md"

        $ExtraFile = Join-Path $script:FakeClaudeHome "agents\ecc-agent.md"
        Set-Content -Path $ExtraFile -Value "ECC agent, repoda karsiligi yok" -Encoding UTF8

        Invoke-InstallUnderTest -Arguments @("-Uninstall") | Out-Null

        $DeletedFile = Join-Path $script:FakeClaudeHome "agents\change-reviewer.md"

        # Kriter 2: repo ile eslesen dosya silinmis olmali
        (Test-Path $DeletedFile) | Should Be $false

        # Kriter 6: repoda karsiligi olmayan dosyaya dokunulmamis olmali
        (Test-Path $ExtraFile) | Should Be $true
    }

    It "Kriter 3: -Uninstall ile commands katmanindaki eslesen dosya silinir" {
        Copy-RepoCommandToFake -Name "feature.md"

        Invoke-InstallUnderTest -Arguments @("-Uninstall") | Out-Null

        $DeletedFile = Join-Path $script:FakeClaudeHome "commands\feature.md"
        (Test-Path $DeletedFile) | Should Be $false
    }

    It "Kriter 4: -Uninstall ile skills SKILL.md silinir ve bos kalan skill dizini kaldirilir" {
        Copy-RepoSkillToFake -Name "memory-hygiene"

        Invoke-InstallUnderTest -Arguments @("-Uninstall") | Out-Null

        $SkillFile = Join-Path $script:FakeClaudeHome "skills\memory-hygiene\SKILL.md"
        $SkillDir  = Join-Path $script:FakeClaudeHome "skills\memory-hygiene"

        (Test-Path $SkillFile) | Should Be $false
        (Test-Path $SkillDir)  | Should Be $false
    }

    It "Ek davranis (skills): SKILL.md disinda dosya olan skill dizinine dokunulmaz" {
        Copy-RepoSkillToFake -Name "memory-hygiene"

        $ExtraSkillFile = Join-Path $script:FakeClaudeHome "skills\memory-hygiene\notes.txt"
        Set-Content -Path $ExtraSkillFile -Value "baska dosya" -Encoding UTF8

        Invoke-InstallUnderTest -Arguments @("-Uninstall") | Out-Null

        $SkillFile = Join-Path $script:FakeClaudeHome "skills\memory-hygiene\SKILL.md"
        $SkillDir  = Join-Path $script:FakeClaudeHome "skills\memory-hygiene"

        (Test-Path $SkillFile)      | Should Be $false
        (Test-Path $ExtraSkillFile) | Should Be $true
        (Test-Path $SkillDir)       | Should Be $true
    }

    It "Kriter 5: -Uninstall -DryRun hicbir dosyayi silmez veya yedeklemez, sadece listeler" {
        Copy-RepoAgentToFake -Name "change-reviewer.md"

        $Result = Invoke-InstallUnderTest -Arguments @("-Uninstall", "-DryRun")

        $TargetFile = Join-Path $script:FakeClaudeHome "agents\change-reviewer.md"
        (Test-Path $TargetFile) | Should Be $true

        $BackupPattern = Join-Path $script:FakeClaudeHome "backups\uninstall-*"
        @(Get-Item -Path $BackupPattern -ErrorAction SilentlyContinue).Count | Should Be 0

        # DRY RUN modunda "silinecek" listesi konsola basilmasi bekleniyor.
        $Result.Output | Should Match "silinecek"
    }

    It "Kriter 7: hedefte dosya yoksa hata firlatilmaz, atlandi olarak raporlanir" {
        # agents/commands/skills altinda bilerek hicbir dosya olusturulmadi;
        # tum hedef dosyalar 'yok' senaryosunu temsil ediyor.
        $Result = Invoke-InstallUnderTest -Arguments @("-Uninstall")

        $Result.Error | Should Be $null
        $Result.Output | Should Match "atlandi"
    }

    It "Kriter 8: silinen dosya backups\uninstall-<tarih>\ altina goreli yolla kopyalanir" {
        Copy-RepoAgentToFake -Name "change-reviewer.md"

        Invoke-InstallUnderTest -Arguments @("-Uninstall") | Out-Null

        $BackupPattern = Join-Path $script:FakeClaudeHome "backups\uninstall-*\agents\change-reviewer.md"
        $Found = Get-Item -Path $BackupPattern -ErrorAction SilentlyContinue
        $Found | Should Not BeNullOrEmpty
    }

    It "Kriter 9: calisma sonunda Silinen ve Atlanan sayilari konsola yazdirilir" {
        Copy-RepoAgentToFake -Name "change-reviewer.md"

        $Result = Invoke-InstallUnderTest -Arguments @("-Uninstall")

        $Result.Output | Should Match "Silinen"
        $Result.Output | Should Match "Atlanan"
    }

    It "Ek davranis (hash uyusmazligi): hedef icerik repodan farkliysa silinmez, Korundu sayacina eklenir" {
        Copy-RepoCommandToFake -Name "feature.md"
        $TargetFile = Join-Path $script:FakeClaudeHome "commands\feature.md"
        Set-Content -Path $TargetFile -Value "farkli icerik, hash uyusmayacak" -Encoding UTF8 -Force

        $Result = Invoke-InstallUnderTest -Arguments @("-Uninstall")

        (Test-Path $TargetFile) | Should Be $true
        $Result.Output | Should Match "Korundu"
    }
}
