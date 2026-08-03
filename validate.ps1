# claudecalis dogrulama scripti (Windows / PowerShell)
#
# Yapinin kendi kendini denetlemesi. Bir agent/skill/command dosyasi bozuksa
# Claude Code bunu sessizce yok sayar — hata vermez, sadece o parca calismaz.
# Bu script o sessiz basarisizliklari gurultuye cevirir.
#
# Kullanim:
#   .\validate.ps1              → tam denetim (testler dahil)
#   .\validate.ps1 -SkipTests   → sadece statik kontroller (hizli)
#   .\validate.ps1 -Quiet       → sadece ozet ve sorunlar
#
# Cikis kodu: 0 = temiz, 1 = en az bir HATA var. UYARI cikis kodunu etkilemez.

param(
    [switch]$SkipTests,
    [switch]$Quiet
)

$ErrorActionPreference = "Stop"

$RepoRoot   = $PSScriptRoot
$ClaudeHome = Join-Path $env:USERPROFILE ".claude"

$script:Problems = @()

# Claude Code'un tanidigi tool adlari. Bilinmeyen bir ad yazim hatasi demektir
# ve o tool agent'a hic verilmez — sessiz yetki kaybi.
$KnownTools = @(
    "Read", "Write", "Edit", "Bash", "Grep", "Glob", "NotebookEdit",
    "WebFetch", "WebSearch", "Task", "TodoWrite", "Agent", "Skill"
)

$KnownModels = @("sonnet", "opus", "haiku", "fable", "inherit")

function Add-Problem {
    param(
        [ValidateSet("HATA", "UYARI")] [string]$Severity,
        [string]$File,
        [string]$Message
    )
    $script:Problems += [pscustomobject]@{
        Severity = $Severity
        File     = $File
        Message  = $Message
    }
}

function Write-Check {
    param([string]$Text)
    if (-not $Quiet) { Write-Host "  $Text" -ForegroundColor DarkGray }
}

# ---------------------------------------------------------------------------
# Frontmatter ayristirici
#
# Tam bir YAML parser degil; sadece "anahtar: deger" satirlarini okur. Agent ve
# skill frontmatter'lari bu kadar basit oldugu icin yeterli, ve harici bagimlilik
# getirmiyor.
# ---------------------------------------------------------------------------
function Read-Frontmatter {
    param([string]$Path)

    # @() sarmalayici sart: tek satirlik dosyada Get-Content dizi degil string
    # dondurur, $Lines[0] da bir Char olur ve Char'in Trim() metodu yoktur.
    $Lines = @(Get-Content -Path $Path -Encoding UTF8)
    if ($Lines.Count -eq 0 -or $Lines[0].Trim() -ne "---") { return $null }

    $Fields = @{}
    for ($i = 1; $i -lt $Lines.Count; $i++) {
        if ($Lines[$i].Trim() -eq "---") { return $Fields }
        if ($Lines[$i] -match '^\s*([A-Za-z0-9_-]+)\s*:\s*(.*)$') {
            $Fields[$Matches[1]] = $Matches[2].Trim()
        }
    }
    return $null   # kapanis --- bulunamadi
}

function Test-MarkdownDefinition {
    param(
        [string]$Path,
        [string]$Label,
        [string]$ExpectedName,   # bos ise name alani zorunlu degil
        [switch]$RequireName
    )

    $Fm = Read-Frontmatter -Path $Path
    if ($null -eq $Fm) {
        Add-Problem -Severity "HATA" -File $Label -Message "Frontmatter yok veya kapanis '---' eksik. Claude Code bu dosyayi tanimaz."
        return
    }

    if ($RequireName) {
        if (-not $Fm.ContainsKey("name") -or [string]::IsNullOrWhiteSpace($Fm["name"])) {
            Add-Problem -Severity "HATA" -File $Label -Message "'name' alani yok."
        } elseif ($ExpectedName -and $Fm["name"] -ne $ExpectedName) {
            Add-Problem -Severity "HATA" -File $Label -Message "'name: $($Fm['name'])' dosya/dizin adiyla ('$ExpectedName') uyusmuyor."
        }
    }

    if (-not $Fm.ContainsKey("description") -or [string]::IsNullOrWhiteSpace($Fm["description"])) {
        Add-Problem -Severity "HATA" -File $Label -Message "'description' alani yok. Ana model bu alana bakarak cagirip cagirmayacagina karar verir; bos ise dosya hic kullanilmaz."
        return
    }

    $Desc = $Fm["description"]
    if ($Desc.Length -lt 40) {
        Add-Problem -Severity "UYARI" -File $Label -Message "'description' cok kisa ($($Desc.Length) karakter). Ne zaman kullanilacagi anlasilmazsa model bu parcayi cagirmaz."
    }
    if ($Desc.Length -gt 600) {
        Add-Problem -Severity "UYARI" -File $Label -Message "'description' cok uzun ($($Desc.Length) karakter). Bu alan her session'da context'te durur."
    }

    if ($Fm.ContainsKey("tools")) {
        foreach ($Tool in ($Fm["tools"] -split ',')) {
            $T = $Tool.Trim()
            if ($T -and ($KnownTools -notcontains $T)) {
                Add-Problem -Severity "UYARI" -File $Label -Message "Bilinmeyen tool adi: '$T'. Yazim hatasiysa o tool agent'a hic verilmez."
            }
        }
    }

    if ($Fm.ContainsKey("model")) {
        $M = $Fm["model"]
        if ($KnownModels -notcontains $M -and $M -notmatch '^claude-') {
            Add-Problem -Severity "UYARI" -File $Label -Message "Taninmayan model: '$M'."
        }
    }
}

# ---------------------------------------------------------------------------

if (-not $Quiet) {
    Write-Host "claudecalis dogrulama" -ForegroundColor Cyan
    Write-Host "  Repo : $RepoRoot"
    Write-Host ""
}

# 1. Agent tanimlari
if (-not $Quiet) { Write-Host "Agent tanimlari" -ForegroundColor White }
$AgentDir = Join-Path $RepoRoot "agents"
if (Test-Path $AgentDir) {
    foreach ($File in Get-ChildItem -Path $AgentDir -Filter "*.md" -File) {
        Write-Check "agents/$($File.Name)"
        Test-MarkdownDefinition -Path $File.FullName `
                                -Label "agents/$($File.Name)" `
                                -ExpectedName $File.BaseName -RequireName
    }
}

# 2. Skill tanimlari
if (-not $Quiet) { Write-Host "Skill tanimlari" -ForegroundColor White }
$SkillDir = Join-Path $RepoRoot "skills"
if (Test-Path $SkillDir) {
    foreach ($Dir in Get-ChildItem -Path $SkillDir -Directory) {
        $Skill = Join-Path $Dir.FullName "SKILL.md"
        if (-not (Test-Path $Skill)) {
            Add-Problem -Severity "HATA" -File "skills/$($Dir.Name)/" -Message "SKILL.md yok. Skill dizini bu dosya olmadan anlamsiz."
            continue
        }
        Write-Check "skills/$($Dir.Name)/SKILL.md"
        Test-MarkdownDefinition -Path $Skill `
                                -Label "skills/$($Dir.Name)/SKILL.md" `
                                -ExpectedName $Dir.Name -RequireName
    }
}

# 3. Command tanimlari (name alani yok; dosya adi komut adidir)
if (-not $Quiet) { Write-Host "Command tanimlari" -ForegroundColor White }
$CmdDir = Join-Path $RepoRoot "commands"
if (Test-Path $CmdDir) {
    foreach ($File in Get-ChildItem -Path $CmdDir -Filter "*.md" -File) {
        Write-Check "commands/$($File.Name)"
        Test-MarkdownDefinition -Path $File.FullName -Label "commands/$($File.Name)"
    }
}

# 4. PowerShell dosyalari: BOM + sozdizimi
if (-not $Quiet) { Write-Host "PowerShell dosyalari" -ForegroundColor White }
foreach ($Ps1 in Get-ChildItem -Path $RepoRoot -Filter "*.ps1" -File -Recurse) {
    $Rel = $Ps1.FullName.Substring($RepoRoot.Length + 1)
    Write-Check $Rel

    $Bytes = [System.IO.File]::ReadAllBytes($Ps1.FullName)
    if ($Bytes.Length -lt 3 -or $Bytes[0] -ne 0xEF -or $Bytes[1] -ne 0xBB -or $Bytes[2] -ne 0xBF) {
        Add-Problem -Severity "HATA" -File $Rel -Message "BOM yok. Windows PowerShell 5.1 dosyayi ANSI sanar; Turkce karakter ve tire icerirse parse hatasi verir."
    }

    $ParseErrors = $null
    $null = [System.Management.Automation.PSParser]::Tokenize(
                (Get-Content -Raw -Encoding UTF8 $Ps1.FullName), [ref]$ParseErrors)
    if ($ParseErrors -and $ParseErrors.Count -gt 0) {
        Add-Problem -Severity "HATA" -File $Rel -Message "Sozdizimi hatasi: $($ParseErrors[0].Message)"
    }
}

# 5. Kaynak ile kurulu kopya senkron mu
#    En sik yapilan hata: repoda duzenleyip install.ps1 calistirmayi unutmak.
if (-not $Quiet) { Write-Host "Kaynak <-> kurulu kopya" -ForegroundColor White }
if (Test-Path $ClaudeHome) {
    $Pairs = @()

    # install.ps1'deki $Layers ile ayni liste. Yeni bir katman eklenirse iki
    # dosyada da guncellenmeli.
    foreach ($Layer in @("agents", "commands", "conventions", "global")) {
        $Dir = Join-Path $RepoRoot $Layer
        if (-not (Test-Path $Dir)) { continue }
        foreach ($F in Get-ChildItem -Path $Dir -Filter "*.md" -File -EA SilentlyContinue) {
            # install.ps1 katmanin kendi README'sini kurmuyor; senkron da beklenmez.
            if ($F.Name -eq "README.md") { continue }

            # global/ katmani ~/.claude kokune kuruluyor, alt dizine degil.
            $Dst = if ($Layer -eq "global") { Join-Path $ClaudeHome $F.Name }
                   else                     { Join-Path $ClaudeHome "$Layer\$($F.Name)" }

            $Pairs += @{
                Src   = $F.FullName
                Dst   = $Dst
                Label = "$Layer/$($F.Name)"
            }
        }
    }
    foreach ($D in Get-ChildItem -Path $SkillDir -Directory -EA SilentlyContinue) {
        $S = Join-Path $D.FullName "SKILL.md"
        if (Test-Path $S) {
            $Pairs += @{ Src = $S; Dst = Join-Path $ClaudeHome "skills\$($D.Name)\SKILL.md"; Label = "skills/$($D.Name)/SKILL.md" }
        }
    }

    foreach ($Pair in $Pairs) {
        if (-not (Test-Path $Pair.Dst)) {
            Add-Problem -Severity "UYARI" -File $Pair.Label -Message "Kurulu degil. '.\install.ps1' calistirilmali."
            continue
        }
        $SrcHash = (Get-FileHash $Pair.Src -Algorithm SHA256).Hash
        $DstHash = (Get-FileHash $Pair.Dst -Algorithm SHA256).Hash
        if ($SrcHash -ne $DstHash) {
            Add-Problem -Severity "UYARI" -File $Pair.Label -Message "Kurulu kopya kaynaktan farkli. '.\install.ps1' calistirilmali."
        }
    }
} else {
    Add-Problem -Severity "UYARI" -File "~/.claude" -Message "Bulunamadi; kurulum senkron kontrolu atlandi."
}

# 6. Hook butunlugu
#    Zorlayici katmanin kendisi korumasiz kalmasin: settings.json bozuksa ya da
#    bir hook script'i eksikse hook'lar SESSIZCE calismaz. Hata mesaji yok,
#    uyari yok — sadece koruma ortadan kalkar.
if (-not $Quiet) { Write-Host "Hook butunlugu" -ForegroundColor White }
$SettingsPath = Join-Path $RepoRoot ".claude\settings.json"
if (Test-Path $SettingsPath) {
    Write-Check ".claude/settings.json"

    $Settings = $null
    try {
        $Settings = Get-Content -LiteralPath $SettingsPath -Raw -Encoding UTF8 | ConvertFrom-Json
    } catch {
        Add-Problem -Severity "HATA" -File ".claude/settings.json" `
                    -Message "Gecerli JSON degil: $($_.Exception.Message)"
    }

    if ($Settings -and $Settings.hooks) {
        foreach ($EventName in $Settings.hooks.PSObject.Properties.Name) {
            foreach ($Matcher in $Settings.hooks.$EventName) {
                foreach ($Hook in $Matcher.hooks) {
                    if ($Hook.type -ne "command" -or -not $Hook.command) { continue }

                    if ($Hook.command -match '-File\s+"([^"]+)"') {
                        $HookPath = $Matches[1] -replace '\$CLAUDE_PROJECT_DIR', $RepoRoot
                        $HookPath = $HookPath -replace '/', '\'
                        if (Test-Path -LiteralPath $HookPath) {
                            Write-Check "  $EventName -> $(Split-Path $HookPath -Leaf)"
                        } else {
                            Add-Problem -Severity "HATA" -File ".claude/settings.json" `
                                        -Message "$EventName hook'unun script'i bulunamadi: $HookPath"
                        }
                    } else {
                        Add-Problem -Severity "UYARI" -File ".claude/settings.json" `
                                    -Message "$EventName hook komutundan script yolu cikarilamadi: $($Hook.command)"
                    }
                }
            }
        }
    }
}

# 7. Sizinti taramasi
#    Global guvenlik kurali "commit oncesi hardcoded secret olmayacak" diyor ama
#    bunu zorlayan bir sey yoktu.
#
#    DIKKAT: desenler parcali yazilmis ("AKIA" + "[0-9A-Z]{16}"). Sebep: tam
#    haliyle yazilsalardi bu dosyanin KENDISI her taramada eslesirdi.
$SecretPatterns = @(
    @{ Ad = "AWS erisim anahtari";    Desen = "AKIA" + "[0-9A-Z]{16}" },
    @{ Ad = "GitHub token";           Desen = "gh[pousr]" + "_[A-Za-z0-9]{36,}" },
    @{ Ad = "Anthropic API anahtari"; Desen = "sk-ant-" + "[A-Za-z0-9_-]{24,}" },
    @{ Ad = "Slack token";            Desen = "xox[baprs]" + "-[A-Za-z0-9-]{12,}" },
    @{ Ad = "Ozel anahtar blogu";     Desen = "-----BEGIN [A-Z ]*PRIVATE" + " KEY-----" }
)

$ScanExtensions = @(".md", ".ps1", ".psm1", ".json", ".yml", ".yaml",
                    ".ts", ".js", ".txt", ".xml", ".config", ".env")

if (-not $Quiet) { Write-Host "Sizinti taramasi" -ForegroundColor White }
$Scanned = 0
foreach ($File in Get-ChildItem -Path $RepoRoot -Recurse -File -Force -EA SilentlyContinue) {
    if ($File.FullName -like "*\.git\*") { continue }
    if ($ScanExtensions -notcontains $File.Extension.ToLower()) { continue }

    $Rel = $File.FullName.Substring($RepoRoot.Length + 1)
    $Scanned++

    $Text = Get-Content -LiteralPath $File.FullName -Raw -Encoding UTF8 -EA SilentlyContinue
    if (-not $Text) { continue }

    foreach ($P in $SecretPatterns) {
        if ($Text -cmatch $P.Desen) {
            Add-Problem -Severity "HATA" -File $Rel `
                        -Message "Sizinti suphesi ($($P.Ad)). Gercekse anahtari HEMEN iptal et; ornek/test verisiyse desene uymayan sahte bir deger kullan."
        }
    }
}
Write-Check "$Scanned dosya tarandi"

# 8. Testler
if (-not $SkipTests) {
    if (-not $Quiet) { Write-Host "Testler" -ForegroundColor White }
    $TestDir = Join-Path $RepoRoot "tests"
    if (Test-Path $TestDir) {
        if (Get-Module -ListAvailable -Name Pester) {
            $Result = Invoke-Pester -Script $TestDir -PassThru -Quiet
            Write-Check "$($Result.PassedCount)/$($Result.TotalCount) gecti"
            if ($Result.FailedCount -gt 0) {
                foreach ($T in ($Result.TestResult | Where-Object { -not $_.Passed })) {
                    Add-Problem -Severity "HATA" -File "tests/" -Message "Kalan test: $($T.Name)"
                }
            }
        } else {
            Add-Problem -Severity "UYARI" -File "tests/" -Message "Pester kurulu degil; testler calistirilamadi."
        }
    }
}

# ---------------------------------------------------------------------------
# Rapor
# ---------------------------------------------------------------------------
$ErrorCount   = @($script:Problems | Where-Object { $_.Severity -eq "HATA" }).Count
$WarningCount = @($script:Problems | Where-Object { $_.Severity -eq "UYARI" }).Count

Write-Host ""
if ($script:Problems.Count -gt 0) {
    foreach ($P in ($script:Problems | Sort-Object Severity, File)) {
        $Color = if ($P.Severity -eq "HATA") { "Red" } else { "Yellow" }
        Write-Host "  [$($P.Severity)] $($P.File)" -ForegroundColor $Color
        Write-Host "          $($P.Message)"
    }
    Write-Host ""
}

Write-Host "Hata  : $ErrorCount" -ForegroundColor $(if ($ErrorCount -gt 0) { "Red" } else { "Green" })
Write-Host "Uyari : $WarningCount" -ForegroundColor $(if ($WarningCount -gt 0) { "Yellow" } else { "Green" })
Write-Host ""

if ($ErrorCount -gt 0) {
    Write-Host "DOGRULAMA BASARISIZ" -ForegroundColor Red
    exit 1
} else {
    Write-Host "Dogrulama temiz." -ForegroundColor Cyan
    exit 0
}
