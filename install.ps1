# claudecalis kurulum scripti (Windows / PowerShell)
#
# Bu repodaki agent, command, convention ve skill dosyalarını ~/.claude/ altına
# kopyalar. Mevcut dosyaların üzerine yazmadan önce yedek alır.
#
# Kopyalanan katmanlar $Layers dizisinde ve altındaki skills blogunda tanımlı.
# Yeni bir katman eklenirse validate.ps1'deki senkron kontrolü de guncellenmeli.
#
# Kullanım:
#   .\install.ps1                        → kur
#   .\install.ps1 -DryRun                → ne yapacağını göster, dokunma
#   .\install.ps1 -Uninstall             → kurduklarını geri kaldır
#   .\install.ps1 -Uninstall -DryRun     → ne kaldıracağını göster, dokunma
#
# Kaldırma yalnızca **bu repoda ismi bulunan** dosyaları hedefler. ~/.claude
# tarafında tarama yapılmaz; bu yüzden repodan gelmeyen dosyalar (ECC paketi
# gibi) hiçbir koşulda silinmez.

param(
    [switch]$DryRun,
    [switch]$Uninstall
)

$ErrorActionPreference = "Stop"

$RepoRoot   = $PSScriptRoot
$ClaudeHome = Join-Path $env:USERPROFILE ".claude"
$Stamp      = Get-Date -Format "yyyyMMdd-HHmmss"
$Mode       = if ($Uninstall) { "uninstall" } else { "install" }
$BackupDir  = Join-Path $ClaudeHome "backups\$Mode-$Stamp"

if ($Uninstall) {
    Write-Host "claudecalis kaldirma" -ForegroundColor Cyan
} else {
    Write-Host "claudecalis kurulumu" -ForegroundColor Cyan
}
Write-Host "  Kaynak : $RepoRoot"
Write-Host "  Hedef  : $ClaudeHome"
if ($DryRun) { Write-Host "  MOD    : DRY RUN (hicbir dosya yazilmayacak)" -ForegroundColor Yellow }
Write-Host ""

if (-not (Test-Path $ClaudeHome)) {
    throw "~/.claude bulunamadi: $ClaudeHome — Claude Code kurulu mu?"
}

# Kopyalanacak katmanlar: repo alt dizini -> ~/.claude alt dizini
$Layers = @(
    @{ Source = "agents";      Target = "agents";      Pattern = "*.md" },
    @{ Source = "commands";    Target = "commands";    Pattern = "*.md" },
    # Exclude: katmanin kendi dokumantasyonu kurulmaz. README bir konvansiyon
    # degil; ~/.claude/conventions/ altinda isi yok.
    @{ Source = "conventions"; Target = "conventions"; Pattern = "*.md"; Exclude = @("README.md") },

    # Kullanici seviyesi dosyalar dogrudan ~/.claude/ kokune gider.
    # Bunlar (CLAUDE.md, MINE.md) daha once versiyon kontrolu disindaydi ve
    # elle duzenleniyordu; artik diger her sey gibi kaynaktan kuruluyorlar.
    # NOT: memory/ BU AKISA DAHIL DEGIL. Kisisel notlar paylasilan bir repoya
    # girmez — bkz. templates/README.md.
    @{ Source = "global"; Target = "."; Pattern = "*.md"; Exclude = @("README.md") }
)

$SkillSrc = Join-Path $RepoRoot "skills"

if ($Uninstall) {

    $Removed   = 0
    $Skipped   = 0
    $Preserved = 0

    foreach ($Layer in $Layers) {
        $SrcDir = Join-Path $RepoRoot $Layer.Source
        $DstDir = Join-Path $ClaudeHome $Layer.Target

        if (-not (Test-Path $SrcDir)) {
            Write-Host "  atlandi: $($Layer.Source)/ yok" -ForegroundColor DarkGray
            continue
        }

        foreach ($File in Get-ChildItem -Path $SrcDir -Filter $Layer.Pattern -File) {
            if ($Layer.Exclude -and ($Layer.Exclude -contains $File.Name)) { continue }

            $Dst = Join-Path $DstDir $File.Name

            if (-not (Test-Path $Dst)) {
                Write-Host "  . $($Layer.Target)/$($File.Name) (atlandi, hedefte yok)" -ForegroundColor DarkGray
                $Skipped++
                continue
            }

            $SrcHash = (Get-FileHash $File.FullName -Algorithm SHA256).Hash
            $DstHash = (Get-FileHash $Dst -Algorithm SHA256).Hash
            if ($SrcHash -ne $DstHash) {
                Write-Host "  ! $($Layer.Target)/$($File.Name) (Korundu: elle degistirilmis)" -ForegroundColor Yellow
                $Preserved++
                continue
            }

            if ($DryRun) {
                Write-Host "  x $($Layer.Target)/$($File.Name) (silinecek)" -ForegroundColor Red
                $Removed++
                continue
            }

            $BackupTarget = Join-Path $BackupDir $Layer.Target
            New-Item -ItemType Directory -Path $BackupTarget -Force | Out-Null
            Copy-Item $Dst (Join-Path $BackupTarget $File.Name) -Force
            Remove-Item $Dst -Force

            Write-Host "  x $($Layer.Target)/$($File.Name) (silindi)" -ForegroundColor Red
            $Removed++
        }
    }

    if (Test-Path $SkillSrc) {
        foreach ($SkillDir in Get-ChildItem -Path $SkillSrc -Directory) {
            $Src = Join-Path $SkillDir.FullName "SKILL.md"
            if (-not (Test-Path $Src)) {
                Write-Host "  ! skills/$($SkillDir.Name)/SKILL.md yok, atlandi" -ForegroundColor Red
                continue
            }

            $DstSkillDir = Join-Path $ClaudeHome "skills\$($SkillDir.Name)"
            $Dst         = Join-Path $DstSkillDir "SKILL.md"

            if (-not (Test-Path $Dst)) {
                Write-Host "  . skills/$($SkillDir.Name)/SKILL.md (atlandi, hedefte yok)" -ForegroundColor DarkGray
                $Skipped++
                continue
            }

            $SrcHash = (Get-FileHash $Src -Algorithm SHA256).Hash
            $DstHash = (Get-FileHash $Dst -Algorithm SHA256).Hash
            if ($SrcHash -ne $DstHash) {
                Write-Host "  ! skills/$($SkillDir.Name)/SKILL.md (Korundu: elle degistirilmis)" -ForegroundColor Yellow
                $Preserved++
                continue
            }

            if ($DryRun) {
                Write-Host "  x skills/$($SkillDir.Name)/SKILL.md (silinecek)" -ForegroundColor Red
                $Removed++
                continue
            }

            $BackupTarget = Join-Path $BackupDir "skills\$($SkillDir.Name)"
            New-Item -ItemType Directory -Path $BackupTarget -Force | Out-Null
            Copy-Item $Dst (Join-Path $BackupTarget "SKILL.md") -Force
            Remove-Item $Dst -Force

            Write-Host "  x skills/$($SkillDir.Name)/SKILL.md (silindi)" -ForegroundColor Red
            $Removed++

            # Dizin GERCEKTEN bossa kaldir. Icinde baska dosya varsa dokunma —
            # o dosyalar bu repodan gelmiyor olabilir.
            $Leftover = @(Get-ChildItem -Path $DstSkillDir -Force)
            if ($Leftover.Count -eq 0) {
                Remove-Item $DstSkillDir -Force
                Write-Host "  x skills/$($SkillDir.Name)/ (bos dizin kaldirildi)" -ForegroundColor Red
            }
        }
    }

    Write-Host ""
    Write-Host "Silinen  : $Removed"
    Write-Host "Atlanan  : $Skipped"
    Write-Host "Korundu  : $Preserved"
    if ($Removed -gt 0 -and -not $DryRun) { Write-Host "Yedek dizini : $BackupDir" }
    Write-Host ""

    if ($DryRun) {
        Write-Host "DRY RUN bitti. Gercek kaldirma icin -DryRun olmadan calistirin." -ForegroundColor Yellow
    } else {
        Write-Host "Kaldirma tamam. Degisikligin yansimasi icin Claude Code'u yeniden baslatin." -ForegroundColor Cyan
    }

} else {

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
            if ($Layer.Exclude -and ($Layer.Exclude -contains $File.Name)) { continue }

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
}
