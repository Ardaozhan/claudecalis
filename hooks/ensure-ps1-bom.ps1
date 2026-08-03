# PostToolUse hook — yazilan .ps1 dosyalarina BOM'u geri koyar.
#
# Neden: Windows PowerShell 5.1, BOM gormedigi .ps1 dosyasini UTF-8 degil ANSI
# sanar. Turkce karakter veya em dash iceren bir script parse hatasiyla patlar.
# Write/Edit araclari BOM yazmaz.
#
# Bu repoda ayni hata iki kez yasandi. CLAUDE.md "duzenledikten sonra BOM'u geri
# koy" diyor — bu hook o adimi hatirlamak zorunda kalmaktan kurtarir.
#
# Sozlesme: stdin'den JSON okur, dosyayi duzeltir, cikis kodu 0. Isi engellemez.

$ErrorActionPreference = "Stop"

try {
    $Raw = [Console]::In.ReadToEnd()
    if ([string]::IsNullOrWhiteSpace($Raw)) { exit 0 }
    # $Payload — $Input DEGIL: $input PowerShell'in otomatik pipeline degiskeni.
    $Payload = $Raw | ConvertFrom-Json
} catch {
    exit 0
}

$Path = $null
if ($Payload.tool_input) { $Path = $Payload.tool_input.file_path }
if ([string]::IsNullOrWhiteSpace($Path)) { exit 0 }
if ($Path -notmatch '\.ps1$')           { exit 0 }
if (-not (Test-Path -LiteralPath $Path)) { exit 0 }

try {
    $Bytes = [System.IO.File]::ReadAllBytes($Path)
    $HasBom = ($Bytes.Length -ge 3 -and
               $Bytes[0] -eq 0xEF -and $Bytes[1] -eq 0xBB -and $Bytes[2] -eq 0xBF)

    if (-not $HasBom) {
        $Text = Get-Content -LiteralPath $Path -Raw -Encoding UTF8
        [System.IO.File]::WriteAllText($Path, $Text, (New-Object System.Text.UTF8Encoding $true))
        Write-Output "hook: $(Split-Path $Path -Leaf) dosyasina UTF-8 BOM eklendi (PowerShell 5.1 icin gerekli)."
    }
} catch {
    # Duzeltilemediyse sessiz kal; validate.ps1 zaten yakalayacak.
    exit 0
}

exit 0
