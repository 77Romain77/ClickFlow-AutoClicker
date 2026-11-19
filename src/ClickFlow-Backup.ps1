param(
    [Parameter(Mandatory=$true)][ValidateSet('Export','Import')][string]$Mode,
    [Parameter(Mandatory=$true)][string]$Archive,
    [Parameter(Mandatory=$true)][string]$Settings,
    [Parameter(Mandatory=$true)][string]$Profiles,
    [Parameter(Mandatory=$true)][string]$Work
)
$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName System.IO.Compression
Add-Type -AssemblyName System.IO.Compression.FileSystem
New-Item -ItemType Directory -Force -Path $Work | Out-Null
$payload = Join-Path $Work 'payload'
New-Item -ItemType Directory -Force -Path $payload | Out-Null
$profilesOut = Join-Path $payload 'profiles'
New-Item -ItemType Directory -Force -Path $profilesOut | Out-Null
$marker = Join-Path $payload 'ClickFlowBackup.txt'
if ($Mode -eq 'Export') {
    if (!(Test-Path -LiteralPath $Settings -PathType Leaf)) { throw 'settings.ini introuvable' }
    Copy-Item -LiteralPath $Settings -Destination (Join-Path $payload 'settings.ini')
    $files = @(Get-ChildItem -LiteralPath $Profiles -File -Filter 'profile-*.ini')
    if ($files.Count -lt 1 -or $files.Count -gt 200) { throw 'Nombre de profils invalide' }
    foreach ($file in $files) {
        if ($file.Name -notmatch '^profile-[1-9][0-9]{0,8}\.ini$' -or
            $file.Length -gt 65536 -or ($file.Attributes -band [IO.FileAttributes]::ReparsePoint)) {
            throw ('Profil non sûr : ' + $file.Name)
        }
        Copy-Item -LiteralPath $file.FullName -Destination (Join-Path $profilesOut $file.Name)
    }
    [IO.File]::WriteAllText($marker, 'CLICKFLOW-BACKUP-1')
    $tmpZip = $Archive + '.partial.zip'
    if (Test-Path -LiteralPath $tmpZip) { Remove-Item -LiteralPath $tmpZip -Force }
    try {
        Compress-Archive -Path (Join-Path $payload '*') -DestinationPath $tmpZip -Force
        if (!(Test-Path -LiteralPath $tmpZip)) { throw 'Archive non produite' }
        Move-Item -LiteralPath $tmpZip -Destination $Archive -Force
    } finally {
        if (Test-Path -LiteralPath $tmpZip) { Remove-Item -LiteralPath $tmpZip -Force }
    }
} else {
    if (!(Test-Path -LiteralPath $Archive -PathType Leaf)) { throw 'Archive introuvable' }
    if ((Get-Item -LiteralPath $Archive).Length -gt 20971520) { throw 'Archive trop volumineuse' }
    $zip = [IO.Compression.ZipFile]::OpenRead($Archive)
    try {
        $seen = [Collections.Generic.HashSet[string]]::new([StringComparer]::OrdinalIgnoreCase)
        $total = [long]0
        $count = 0
        foreach ($entry in $zip.Entries) {
            $name = $entry.FullName.Replace('\','/')
            if ($name -eq 'profiles/') { continue }
            if ($name -cnotmatch '^(settings\.ini|ClickFlowBackup\.txt|profiles/profile-[1-9][0-9]{0,8}\.ini)$' -or
                $name -match '\.\.' -or $entry.Length -gt 131072) {
                throw ('Entrée non autorisée dans l''archive : ' + $name)
            }
            if (!$seen.Add($name)) { throw ('Doublon dans l''archive : ' + $name) }
            $count++
            $total += $entry.Length
            if ($count -gt 202 -or $total -gt 10485760) {
                throw 'Archive contenant trop de données'
            }
        }
        if (!$seen.Contains('settings.ini') -or !$seen.Contains('ClickFlowBackup.txt') -or $count -lt 3) {
            throw 'Sauvegarde incomplète ou mauvais format'
        }
        [IO.Compression.ZipFileExtensions]::ExtractToDirectory($zip, $payload)
    } finally {
        $zip.Dispose()
    }
    if ([IO.File]::ReadAllText($marker).Trim() -ne 'CLICKFLOW-BACKUP-1') {
        throw 'Signature de sauvegarde invalide'
    }
    $settingsText = [IO.File]::ReadAllText((Join-Path $payload 'settings.ini'))
    if (!$settingsText.Contains('[Profiles]')) { throw 'settings.ini invalide' }
    $files = @(Get-ChildItem -LiteralPath $profilesOut -File -Filter 'profile-*.ini')
    if ($files.Count -eq 0) { throw 'Aucun profil dans la sauvegarde' }
    foreach ($file in $files) {
        $content = [IO.File]::ReadAllText($file.FullName)
        if (!$content.Contains('[ClickFlowProfile]') -or !$content.Contains('[Settings]')) {
            throw ('Profil invalide : ' + $file.Name)
        }
    }
}
