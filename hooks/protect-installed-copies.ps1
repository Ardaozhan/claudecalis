# PreToolUse hook — kurulu kopyalari elle duzenlemeyi engeller.
#
# Neden: agent/skill/command dosyalarinin iki kopyasi var. Kaynak bu repoda,
# kurulu kopya ~/.claude/ altinda. Kurulu kopya elle duzenlenirse bir sonraki
# install.ps1 kosusunda sessizce uzerine yazilir ve emek kaybolur.
#
# CLAUDE.md bunu zaten kural olarak yaziyor. Bu hook o kurali ZORUNLU kilar.
#
# Sozlesme: stdin'den JSON okur. Engellemek icin cikis kodu 2 ve stderr'e
# gerekce yazar; stderr metni modele geri verilir.

$ErrorActionPreference = "Stop"

try {
    $Raw = [Console]::In.ReadToEnd()
    if ([string]::IsNullOrWhiteSpace($Raw)) { exit 0 }
    # $Payload — $Input DEGIL: $input PowerShell'in otomatik pipeline degiskeni,
    # uzerine yazmak beklenmedik davranisa yol acar.
    $Payload = $Raw | ConvertFrom-Json
} catch {
    # Hook girdisi okunamadiysa isi engelleme — hook, calismanin onune gecmemeli.
    exit 0
}

$Path = $null
if ($Payload.tool_input) { $Path = $Payload.tool_input.file_path }
if ([string]::IsNullOrWhiteSpace($Path)) { exit 0 }

try { $Path = [System.IO.Path]::GetFullPath($Path) } catch { exit 0 }

$ClaudeHome = Join-Path $env:USERPROFILE ".claude"

# install.ps1'in $Layers dizisiyle ayni liste. Yeni bir katman eklenirse buraya
# da eklenmeli — yoksa o katman korumasiz kalir.
$GuardedDirs = @("agents", "commands", "skills", "conventions") |
                   ForEach-Object { [System.IO.Path]::GetFullPath((Join-Path $ClaudeHome $_)) }

# ~/.claude kokune kurulan tek tek dosyalar (global katmani).
$GuardedFiles = @("CLAUDE.md", "MINE.md") |
                    ForEach-Object { [System.IO.Path]::GetFullPath((Join-Path $ClaudeHome $_)) }

$Engellendi = $false

foreach ($Dir in $GuardedDirs) {
    if ($Path.StartsWith($Dir + [System.IO.Path]::DirectorySeparatorChar,
                         [System.StringComparison]::OrdinalIgnoreCase)) {
        $Engellendi = $true
        break
    }
}

if (-not $Engellendi) {
    foreach ($File in $GuardedFiles) {
        if ($Path.Equals($File, [System.StringComparison]::OrdinalIgnoreCase)) {
            $Engellendi = $true
            break
        }
    }
}

if ($Engellendi) {
    $Leaf = Split-Path $Path -Leaf
    [Console]::Error.WriteLine(@"
ENGELLENDI: '$Path' kurulu bir kopya, kaynak degil.

Bu dosya install.ps1 tarafindan uretiliyor. Buraya yazilan her sey bir sonraki
kurulumda sessizce kaybolur.

Yapilmasi gereken:
  1. Kaynagi duzenle: <repo>/agents|commands|conventions|skills|global/ altinda $Leaf
  2. .\install.ps1 -DryRun ile ne olacagini gor
  3. .\install.ps1 ile kur
"@)
    exit 2
}

exit 0
