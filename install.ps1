# claudecalis kurulum scripti (Windows / PowerShell)
#
# Bu repodaki agent, skill ve command dosyalarını ~/.claude/ altına kopyalar.
# Mevcut dosyaların üzerine yazmadan önce yedek alır.
#
# Kullanım:
#   .\install.ps1              → kur
#   .\install.ps1 -DryRun      → ne yapacağını göster, dokunma

param(
    [switch]$DryRun
)

$ErrorActionPreference = "Stop"

$RepoRoot   = $PSScriptRoot
$ClaudeHome = Join-Path $env:USERPROFILE ".claude"
$Stamp      = Get-Date -Format "yyyyMMdd-HHmmss"
$BackupDir  = Join-Path $ClaudeHome "backups\install-$Stamp"

Write-Host "claudecalis kurulumu" -ForegroundColor Cyan
Write-Host "  Kaynak : $RepoRoot"
Write-Host "  Hedef  : $ClaudeHome"
if ($DryRun) { Write-Host "  MOD    : DRY RUN (hicbir dosya yazilmayacak)" -ForegroundColor Yellow }
Write-Host ""

if (-not (Test-Path $ClaudeHome)) {
    throw "~/.claude bulunamadi: $ClaudeHome — Claude Code kurulu mu?"
}

# Kopyalanacak katmanlar: repo alt dizini -> ~/.claude alt dizini
$Layers = @(
    @{ Source = "agents";   Target = "agents";   Pattern = "*.md" },
    @{ Source = "commands"; Target = "commands"; Pattern = "*.md" }
)

$Installed = 0
$BackedUp  = 0

foreach ($Layer in $Layers) {
    $SrcDir = Join-Path $RepoRoot $Layer.Source
    $DstDir = Join-Path $ClaudeHome $Layer.Target

    if (-not (Test-Path $SrcDir)) {
        Write-Host "  atlandi: $($Layer.Source)/ yok" -ForegroundColor DarkGray
        continue
    }

    if (-not (Test-Path $DstDir) -and -not $DryRun) {
        New-Item -ItemType Directory -Path $DstDir -Force | Out-Null
    }

    foreach ($File in Get-ChildItem -Path $SrcDir -Filter $Layer.Pattern -File) {
        $Dst = Join-Path $DstDir $File.Name

        if (Test-Path $Dst) {
            $SrcHash = (Get-FileHash $File.FullName -Algorithm SHA256).Hash
            $DstHash = (Get-FileHash $Dst -Algorithm SHA256).Hash
            if ($SrcHash -eq $DstHash) {
                Write-Host "  = $($Layer.Target)/$($File.Name)" -ForegroundColor DarkGray
                continue
            }
            if (-not $DryRun) {
                $BackupTarget = Join-Path $BackupDir $Layer.Target
                New-Item -ItemType Directory -Path $BackupTarget -Force | Out-Null
                Copy-Item $Dst (Join-Path $BackupTarget $File.Name) -Force
            }
            $BackedUp++
            Write-Host "  ~ $($Layer.Target)/$($File.Name) (yedeklendi)" -ForegroundColor Yellow
        } else {
            Write-Host "  + $($Layer.Target)/$($File.Name)" -ForegroundColor Green
        }

        if (-not $DryRun) { Copy-Item $File.FullName $Dst -Force }
        $Installed++
    }
}

# Skill'ler dizin yapisini korur: skills/<ad>/SKILL.md
$SkillSrc = Join-Path $RepoRoot "skills"
if (Test-Path $SkillSrc) {
    foreach ($SkillDir in Get-ChildItem -Path $SkillSrc -Directory) {
        $Src = Join-Path $SkillDir.FullName "SKILL.md"
        if (-not (Test-Path $Src)) {
            Write-Host "  ! skills/$($SkillDir.Name)/SKILL.md yok, atlandi" -ForegroundColor Red
            continue
        }
        $DstDir = Join-Path $ClaudeHome "skills\$($SkillDir.Name)"
        $Dst    = Join-Path $DstDir "SKILL.md"

        if (Test-Path $Dst) {
            $SrcHash = (Get-FileHash $Src -Algorithm SHA256).Hash
            $DstHash = (Get-FileHash $Dst -Algorithm SHA256).Hash
            if ($SrcHash -eq $DstHash) {
                Write-Host "  = skills/$($SkillDir.Name)/SKILL.md" -ForegroundColor DarkGray
                continue
            }
            if (-not $DryRun) {
                $BackupTarget = Join-Path $BackupDir "skills\$($SkillDir.Name)"
                New-Item -ItemType Directory -Path $BackupTarget -Force | Out-Null
                Copy-Item $Dst (Join-Path $BackupTarget "SKILL.md") -Force
            }
            $BackedUp++
            Write-Host "  ~ skills/$($SkillDir.Name)/SKILL.md (yedeklendi)" -ForegroundColor Yellow
        } else {
            Write-Host "  + skills/$($SkillDir.Name)/SKILL.md" -ForegroundColor Green
        }

        if (-not $DryRun) {
            New-Item -ItemType Directory -Path $DstDir -Force | Out-Null
            Copy-Item $Src $Dst -Force
        }
        $Installed++
    }
}

Write-Host ""
Write-Host "Kurulan/guncellenen : $Installed"
Write-Host "Yedeklenen          : $BackedUp"
if ($BackedUp -gt 0 -and -not $DryRun) { Write-Host "Yedek dizini        : $BackupDir" }
Write-Host ""

if ($DryRun) {
    Write-Host "DRY RUN bitti. Gercek kurulum icin -DryRun olmadan calistirin." -ForegroundColor Yellow
} else {
    Write-Host "Kurulum tamam. Yeni agent/skill'lerin taninmasi icin Claude Code'u yeniden baslatin." -ForegroundColor Cyan
}
