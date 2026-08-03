# PostToolUse hook — yazilan agent/skill/command tanimini dogrular.
#
# Neden: bozuk frontmatter'li bir tanim dosyasini Claude Code SESSIZCE yok sayar.
# Hata mesaji yok, uyari yok — dosya sadece hic calismaz. Bu, fark edilmesi en
# zor hata turudur.
#
# Bu hook tanim dosyasi her yazildiginda aninda kontrol eder. validate.ps1 ile
# ayni kurallari uygular, ama tek dosya icin ve o an.
#
# Sozlesme: stdin'den JSON okur. Sorun bulursa cikis kodu 2 ve stderr'e aciklama;
# dosya zaten yazilmis olur, model uyariyi gorup duzeltir.

$ErrorActionPreference = "Stop"

try {
    $Raw = [Console]::In.ReadToEnd()
    if ([string]::IsNullOrWhiteSpace($Raw)) { exit 0 }
    $Payload = $Raw | ConvertFrom-Json
} catch {
    exit 0
}

$Path = $null
if ($Payload.tool_input) { $Path = $Payload.tool_input.file_path }
if ([string]::IsNullOrWhiteSpace($Path))  { exit 0 }
if ($Path -notmatch '\.md$')              { exit 0 }
if (-not (Test-Path -LiteralPath $Path))  { exit 0 }

$Full = [System.IO.Path]::GetFullPath($Path)

# Yol parcalarini dogrudan karsilastir. Regex ile dizin ayraci eslestirmek
# Windows'ta kaygan: cift tirnakli stringde ters bolu + harf, PowerShell escape
# dizisi olarak okunabilir (ornegin `a = BEL karakteri).
$Parts  = $Full -split '[\\/]'
$Leaf   = $Parts[-1]
$Parent = if ($Parts.Count -ge 2) { $Parts[-2] } else { "" }
$Grand  = if ($Parts.Count -ge 3) { $Parts[-3] } else { "" }

# Sadece tanim dosyalarini denetle. README, docs, templates disarida.
$IsAgent   = ($Parent -eq "agents")   -and ($Leaf -like "*.md")
$IsCommand = ($Parent -eq "commands") -and ($Leaf -like "*.md")
$IsSkill   = ($Grand  -eq "skills")   -and ($Leaf -eq "SKILL.md")

if (-not ($IsAgent -or $IsCommand -or $IsSkill)) { exit 0 }

# --- frontmatter oku ---
# @() sart: tek satirlik dosyada Get-Content string dondurur, Char'in Trim()'i yok.
$Lines = @(Get-Content -LiteralPath $Full -Encoding UTF8)
$Problems = @()

if ($Lines.Count -eq 0 -or $Lines[0].Trim() -ne "---") {
    $Problems += "Frontmatter yok veya dosya '---' ile baslamiyor. Claude Code bu dosyayi tanimaz."
} else {
    $Fields = @{}
    $Closed = $false
    for ($i = 1; $i -lt $Lines.Count; $i++) {
        if ($Lines[$i].Trim() -eq "---") { $Closed = $true; break }
        if ($Lines[$i] -match '^\s*([A-Za-z0-9_-]+)\s*:\s*(.*)$') {
            $Fields[$Matches[1]] = $Matches[2].Trim()
        }
    }

    if (-not $Closed) {
        $Problems += "Frontmatter kapanis '---' satiri yok."
    } else {
        if (-not $Fields.ContainsKey("description") -or
            [string]::IsNullOrWhiteSpace($Fields["description"])) {
            $Problems += "'description' alani yok veya bos. Ana model bu alana bakarak cagirip cagirmayacagina karar verir; bos ise dosya hic kullanilmaz."
        }

        if ($IsAgent -or $IsSkill) {
            $Expected = if ($IsSkill) { $Parent }
                        else          { [System.IO.Path]::GetFileNameWithoutExtension($Leaf) }

            if (-not $Fields.ContainsKey("name") -or [string]::IsNullOrWhiteSpace($Fields["name"])) {
                $Problems += "'name' alani yok."
            } elseif ($Fields["name"] -ne $Expected) {
                $Problems += "'name: $($Fields['name'])' dosya/dizin adiyla ('$Expected') uyusmuyor."
            }
        }
    }
}

if ($Problems.Count -gt 0) {
    $Leaf = Split-Path $Full -Leaf
    [Console]::Error.WriteLine("TANIM DOSYASI BOZUK: $Leaf")
    foreach ($P in $Problems) { [Console]::Error.WriteLine("  - $P") }
    [Console]::Error.WriteLine("")
    [Console]::Error.WriteLine("Dosya yazildi ama bu haliyle Claude Code tarafindan yok sayilir. Duzelt.")
    exit 2
}

exit 0
