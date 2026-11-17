[CmdletBinding()]
param(
    [switch]$Server,
    [string]$GamePath,
    [switch]$Uninstall,
    [switch]$Yes,
    [string]$Source,
    [string]$Repo = 'Indaclouds/modheim',
    [string]$Branch = 'main'
)

$BepInExId = 'denikson-BepInExPack_Valheim'
$StateFileName = 'modheim-installed.txt'
$ApiBase = 'https://thunderstore.io/api/experimental/package'
$script:PackageInfo = @{}
$Orange = 250, 190, 135
$Green = 165, 225, 170

function Write-Color([string]$Text, [int[]]$Rgb, [switch]$NoNewline) {
    $esc = [char]27
    Write-Host "$esc[38;2;$($Rgb -join ';')m$Text$esc[0m" -NoNewline:$NoNewline
}

function Show-Banner {
    $helmet = @'
⠀⠀⢀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⡀⠀⠀
⠀⢠⣿⡆⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢰⣿⡄⠀
⠀⣿⣿⣇⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⣸⣿⣿⠀
⠀⣿⣿⣿⣦⡀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢀⣴⣿⣿⣿⠀
⠀⢹⣿⣿⣿⣿⣦⡀⠀⠀⠀⠀⠀⢠⣴⣦⡄⠀⠀⠀⠀⠀⢀⣴⣿⣿⣿⣿⡏⠀
⠀⠀⢿⣿⣿⡿⠋⣠⡶⠀⣠⣴⡆⠠⢤⡤⠄⢰⣦⣄⠀⢶⣄⠙⢿⣿⣿⡿⠀⠀
⠀⠀⠈⢿⠋⣠⡾⠋⣠⣾⣿⣿⡇⢰⣤⣤⡆⢸⣿⣿⣷⣄⠙⢷⣄⠙⡿⠁⠀⠀
⠀⠀⠀⠀⣴⠏⢠⣾⣿⣿⣿⣿⡇⠸⠿⠿⠇⢸⣿⣿⣿⣿⣷⡄⠹⣦⠀⠀⠀⠀
⠀⠀⠀⠀⠀⣰⣿⣿⣿⣿⣿⣿⡇⠀⠒⠒⠀⢸⣿⣿⣿⣿⣿⣿⣆⠀⠀⠀⠀⠀
⠀⠀⠀⠀⢰⣿⣿⣿⣿⣿⣿⣿⡇⢸⣿⣿⡇⢸⣿⣿⣿⣿⣿⣿⣿⡆⠀⠀⠀⠀
⠀⠀⠀⠀⠛⠛⠛⠛⠛⠛⠛⠛⠃⠈⣉⣉⠁⠘⠛⠛⠛⠛⠛⠛⠛⠛⠀⠀⠀⠀
⠀⠀⠀⠀⢿⠀⠾⣿⠷⠀⣿⣿⡇⢀⣉⣉⡀⢸⣿⣿⠀⠾⣿⠷⠀⡿⠀⠀⠀⠀
⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠻⠟⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
'@ -split "`r?`n"
    $letters = @{
        M = @(' __  __ ', '|  \/  |', '| |\/| |', '|_|  |_|')
        O = @('  ___  ', ' / _ \ ', '| (_) |', ' \___/ ')
        D = @(' ___  ', '|   \ ', '| |) |', '|___/ ')
        H = @(' _  _ ', '| || |', '| __ |', '|_||_|')
        E = @(' ___ ', '| __|', '| _| ', '|___|')
        I = @(' ___ ', '|_ _|', ' | | ', '|___|')
    }
    Write-Host ''
    foreach ($line in $helmet) { Write-Color "            $line" $Orange }
    Write-Host ''
    foreach ($row in 0..3) {
        $line = ('M', 'O', 'D', 'H', 'E', 'I', 'M' | ForEach-Object { $letters[$_][$row] }) -join ' '
        Write-Color "   $line" $Green
    }
    Write-Host ''
    Write-Host '   Nos mods Valheim, en une seule commande.' -ForegroundColor Gray
}

function Write-Step([string]$Text) {
    Write-Host ''
    Write-Color "  » $Text" $Green
}

function Write-Info([string]$Text) { Write-Host "    $Text" -ForegroundColor Gray }

function Read-YesNo([string]$Question, [bool]$Default = $true) {
    if ($Yes) { return $Default }
    $hint = if ($Default) { '[O/n]' } else { '[o/N]' }
    while ($true) {
        Write-Host "    $Question $hint " -NoNewline -ForegroundColor White
        $answer = "$(Read-Host)".Trim().ToLowerInvariant()
        if (-not $answer) { return $Default }
        if ($answer -in 'o', 'oui', 'y', 'yes') { return $true }
        if ($answer -in 'n', 'non', 'no') { return $false }
    }
}

function Get-DisplayName($Mod) {
    if ($Mod.Id -eq $BepInExId) { return 'BepInEx' }
    return $Mod.Name -replace '_', ' '
}

function Write-ModLine($Mod) {
    Write-Color '    • ' $Orange -NoNewline
    Write-Host (Get-DisplayName $Mod) -NoNewline -ForegroundColor White
    Write-Host " $($Mod.Version)" -ForegroundColor DarkGray
}

function Write-ProgressRow([int]$Done, [int]$Total, [string]$Label, [switch]$Finished) {
    $width = 24
    $filled = [int][Math]::Round($width * $Done / $Total)
    Write-Host "`r    " -NoNewline
    Write-Color ([string][char]0x2588 * $filled) $Green -NoNewline
    Write-Host ([string][char]0x2591 * ($width - $filled)) -NoNewline -ForegroundColor DarkGray
    Write-Host "  $Label" -NoNewline
    if ($Finished) { Write-Color '  OK' $Green }
}

function Get-SteamLibraries {
    $libraries = New-Object System.Collections.Generic.List[string]
    $steam = (Get-ItemProperty 'HKCU:\Software\Valve\Steam' -ErrorAction SilentlyContinue).SteamPath
    if (-not $steam) {
        $steam = (Get-ItemProperty 'HKLM:\SOFTWARE\WOW6432Node\Valve\Steam' -ErrorAction SilentlyContinue).InstallPath
    }
    if (-not $steam) { return $libraries }
    $libraries.Add(($steam -replace '/', '\'))
    $vdf = Join-Path $steam 'steamapps\libraryfolders.vdf'
    if (Test-Path $vdf) {
        foreach ($match in [regex]::Matches((Get-Content $vdf -Raw), '"path"\s+"([^"]+)"')) {
            $path = $match.Groups[1].Value -replace '\\\\', '\'
            if (-not ($libraries -contains $path)) { $libraries.Add($path) }
        }
    }
    return $libraries
}

function Find-GameFolder([bool]$ForServer) {
    if ($ForServer) { $folder = 'Valheim dedicated server'; $exe = 'valheim_server.exe' }
    else { $folder = 'Valheim'; $exe = 'valheim.exe' }

    if ($GamePath) {
        if (-not (Test-Path (Join-Path $GamePath $exe))) {
            throw "$exe introuvable dans '$GamePath'."
        }
        return (Resolve-Path $GamePath).Path
    }
    foreach ($library in Get-SteamLibraries) {
        $candidate = Join-Path $library "steamapps\common\$folder"
        if (Test-Path (Join-Path $candidate $exe)) { return $candidate }
    }
    throw "'$folder' introuvable dans Steam. Relance avec -GamePath `"<dossier contenant $exe>`"."
}

function Get-PackSource {
    if ($Source) { return (Resolve-Path $Source).Path }
    if ($PSCommandPath) {
        $local = Split-Path -Parent $PSCommandPath
        if (Test-Path (Join-Path $local 'modlist.txt')) { return $local }
    }

    $work = Join-Path $env:TEMP 'modheim\repo'
    if (Test-Path $work) { Remove-Item $work -Recurse -Force }
    New-Item -ItemType Directory -Force $work | Out-Null
    $zip = Join-Path $work 'repo.zip'
    Invoke-WebRequest "https://github.com/$Repo/archive/refs/heads/$Branch.zip" -OutFile $zip -UseBasicParsing
    [IO.Compression.ZipFile]::ExtractToDirectory($zip, $work)
    $root = Get-ChildItem $work -Directory | Select-Object -First 1
    if (-not $root -or -not (Test-Path (Join-Path $root.FullName 'modlist.txt'))) {
        throw "modlist.txt introuvable dans $Repo ($Branch)."
    }
    return $root.FullName
}

function ConvertTo-PackageRef([string]$Text) {
    $parts = $Text.Split('-')
    if ($parts.Count -ne 3 -or $parts[2] -notmatch '^\d+\.\d+\.\d+$') {
        throw "Ligne invalide dans modlist.txt : '$Text' (format attendu : Auteur-NomDuMod-1.2.3)."
    }
    return [pscustomobject]@{ Id = "$($parts[0])-$($parts[1])"; Namespace = $parts[0]; Name = $parts[1]; Version = $parts[2] }
}

function Read-ModList([string]$File) {
    $sections = @{}
    $section = 'commun'
    foreach ($raw in Get-Content $File -Encoding UTF8) {
        $line = ($raw -replace '#.*$', '').Trim()
        if (-not $line) { continue }
        if ($line -match '^\[(.+)\]$') { $section = $Matches[1].Trim().ToLowerInvariant(); continue }
        if (-not $sections.ContainsKey($section)) { $sections[$section] = @() }
        $sections[$section] += ConvertTo-PackageRef $line
    }
    return $sections
}

function Get-Section($Sections, [string]$Name) {
    if ($Sections.ContainsKey($Name)) { return $Sections[$Name] }
    return @()
}

function Get-PackageInfo($Mod) {
    $key = "$($Mod.Id)-$($Mod.Version)"
    if (-not $script:PackageInfo.ContainsKey($key)) {
        try {
            $response = Invoke-WebRequest "$ApiBase/$($Mod.Namespace)/$($Mod.Name)/$($Mod.Version)/" -UseBasicParsing
            $script:PackageInfo[$key] = [Text.Encoding]::UTF8.GetString($response.RawContentStream.ToArray()) | ConvertFrom-Json
        } catch {
            throw "$($Mod.Id) $($Mod.Version) introuvable sur Thunderstore (vérifie le nom et la version dans modlist.txt)."
        }
    }
    return $script:PackageInfo[$key]
}

function Resolve-Dependencies($Mods) {
    $versions = [ordered]@{}
    $pinned = @{}
    foreach ($mod in $Mods) { $versions[$mod.Id] = $mod.Version; $pinned[$mod.Id] = $true }
    $queue = New-Object System.Collections.Generic.Queue[object]
    foreach ($mod in $Mods) { $queue.Enqueue($mod) }

    while ($queue.Count -gt 0) {
        $mod = $queue.Dequeue()
        foreach ($depText in (Get-PackageInfo $mod).dependencies) {
            $dep = ConvertTo-PackageRef $depText
            if (-not $versions.Contains($dep.Id)) {
                $versions[$dep.Id] = $dep.Version
                $queue.Enqueue($dep)
            } elseif (-not $pinned[$dep.Id] -and [version]$dep.Version -gt [version]$versions[$dep.Id]) {
                $versions[$dep.Id] = $dep.Version
                $queue.Enqueue($dep)
            }
        }
    }
    $resolved = New-Object System.Collections.Generic.List[object]
    foreach ($id in $versions.Keys) { $resolved.Add((ConvertTo-PackageRef "$id-$($versions[$id])")) }
    $bepinex = @($resolved | Where-Object Id -eq $BepInExId)
    return @($bepinex) + @($resolved | Where-Object Id -ne $BepInExId)
}

function Get-PackageZip($Mod) {
    $cache = Join-Path $env:TEMP 'modheim\cache'
    New-Item -ItemType Directory -Force $cache | Out-Null
    $zip = Join-Path $cache "$($Mod.Id)-$($Mod.Version).zip"
    if (-not (Test-Path $zip)) {
        $partial = "$zip.part"
        Invoke-WebRequest "https://thunderstore.io/package/download/$($Mod.Namespace)/$($Mod.Name)/$($Mod.Version)/" -OutFile $partial -UseBasicParsing
        Move-Item $partial $zip -Force
    }
    return $zip
}

function Get-EntryTarget([string]$Entry, $Mod, [string]$GameDir) {
    $rel = $Entry -replace '\\', '/'
    if ($rel -match '(^|/)\.\.(/|$)' -or $rel.StartsWith('/')) { return $null }
    $bepinex = Join-Path $GameDir 'BepInEx'

    if ($Mod.Id -eq $BepInExId) {
        if ($rel -notmatch '^BepInExPack_Valheim/(.+)$') { return $null }
        return Join-Path $GameDir $Matches[1]
    }

    $rel = $rel -replace '^BepInEx/', ''
    $first, $rest = $rel.Split('/', 2)
    switch ($first.ToLowerInvariant()) {
        'plugins'  { return Join-Path $bepinex "plugins\$($Mod.Id)\$rest" }
        'patchers' { return Join-Path $bepinex "patchers\$($Mod.Id)\$rest" }
        'config'   {
            $target = Join-Path $bepinex "config\$rest"
            if (Test-Path $target) { return $null }
            return $target
        }
        'core'     { return $null }
        default    { return Join-Path $bepinex "plugins\$($Mod.Id)\$rel" }
    }
}

function Install-PackageZip([string]$Zip, $Mod, [string]$GameDir) {
    $archive = [IO.Compression.ZipFile]::OpenRead($Zip)
    try {
        foreach ($entry in $archive.Entries) {
            if (-not $entry.Name) { continue }
            $target = Get-EntryTarget $entry.FullName $Mod $GameDir
            if (-not $target) { continue }
            New-Item -ItemType Directory -Force (Split-Path -Parent $target) | Out-Null
            [IO.Compression.ZipFileExtensions]::ExtractToFile($entry, $target, $true)
        }
    } finally {
        $archive.Dispose()
    }
}

function Disable-BepInExConsole([string]$GameDir) {
    $cfg = Join-Path $GameDir 'BepInEx\config\BepInEx.cfg'
    if (-not (Test-Path $cfg)) { return }
    $section = ''
    $lines = foreach ($line in Get-Content $cfg) {
        if ($line -match '^\[(.+)\]$') { $section = $Matches[1] }
        if ($section -eq 'Logging.Console' -and $line -match '^Enabled\s*=') { 'Enabled = false' } else { $line }
    }
    [IO.File]::WriteAllLines($cfg, [string[]]$lines)
}

function Remove-PreviousMods([string]$GameDir) {
    $state = Join-Path $GameDir "BepInEx\$StateFileName"
    if (-not (Test-Path $state)) { return }
    foreach ($id in Get-Content $state) {
        if (-not $id.Trim()) { continue }
        foreach ($kind in 'plugins', 'patchers') {
            $folder = Join-Path $GameDir "BepInEx\$kind\$($id.Trim())"
            if (Test-Path $folder) { Remove-Item $folder -Recurse -Force }
        }
    }
}

function Uninstall-Modheim([string]$GameDir) {
    Write-Step 'Désinstallation'
    if (-not (Read-YesNo 'Retirer BepInEx et tous les mods pour revenir au jeu d''origine ?')) {
        Write-Info 'Annulé : rien n''a été modifié.'
        return
    }
    $loaderFiles = 'winhttp.dll', 'doorstop_config.ini', '.doorstop_version', 'changelog.txt', 'doorstop_libs',
                   'start_game_bepinex.sh', 'start_server_bepinex.sh', 'BepInEx'
    foreach ($name in $loaderFiles) {
        $path = Join-Path $GameDir $name
        if (Test-Path $path) { Remove-Item $path -Recurse -Force }
    }
    Write-Host ''
    Write-Color '  Terminé : le jeu est revenu à son état d''origine.' $Green
}

function Invoke-Main {
    $ErrorActionPreference = 'Stop'
    $ProgressPreference = 'SilentlyContinue'
    [Net.ServicePointManager]::SecurityProtocol = [Net.ServicePointManager]::SecurityProtocol -bor [Net.SecurityProtocolType]::Tls12
    Add-Type -AssemblyName System.IO.Compression.FileSystem

    Show-Banner

    $gameDir = Find-GameFolder $Server.IsPresent
    $what = if ($Server) { 'Serveur' } else { 'Valheim' }
    Write-Step "$what trouvé"
    Write-Info $gameDir

    $process = if ($Server) { 'valheim_server' } else { 'valheim' }
    $running = Get-Process $process -ErrorAction SilentlyContinue |
               Where-Object { $_.Path -and $_.Path.StartsWith($gameDir, [StringComparison]::OrdinalIgnoreCase) }
    if ($running) { throw "$what est ouvert : ferme-le, puis relance la commande." }

    if ($Uninstall) { Uninstall-Modheim $gameDir; return }

    Write-Step 'Récupération de la liste des mods'
    $packSource = Get-PackSource
    $sections = Read-ModList (Join-Path $packSource 'modlist.txt')
    $side = if ($Server) { 'serveur' } else { 'joueurs' }
    $listed = @(Get-Section $sections 'commun') + @(Get-Section $sections $side)
    $final = @(Resolve-Dependencies $listed)
    if (-not ($final | Where-Object Id -eq $BepInExId)) { throw "$BepInExId manque dans modlist.txt." }
    Write-Info 'Liste à jour, vérifiée sur Thunderstore.'

    Write-Step 'La liste des mods actuellement :'
    foreach ($mod in $final) { Write-ModLine $mod }
    Write-Host ''
    Write-Host "  Pour plus d'infos, voir le README du repo : https://github.com/$Repo" -ForegroundColor Gray
    Write-Host ''

    if (-not (Read-YesNo 'Installer ces mods ?')) {
        Write-Host ''
        Write-Host '  Installation annulée : rien n''a été modifié.' -ForegroundColor Yellow
        Write-Host ''
        return
    }

    Write-Step 'Installation'
    Remove-PreviousMods $gameDir
    $count = $final.Count
    for ($i = 0; $i -lt $count; $i++) {
        $mod = $final[$i]
        $label = ('{0}/{1}  {2} {3}' -f ($i + 1), $count, (Get-DisplayName $mod), $mod.Version).PadRight(48)
        Write-ProgressRow $i $count $label
        Install-PackageZip (Get-PackageZip $mod) $mod $gameDir
        Write-ProgressRow ($i + 1) $count $label -Finished
    }

    Disable-BepInExConsole $gameDir

    $configSource = Join-Path $packSource 'config'
    $configFiles = @(Get-ChildItem $configSource -Recurse -File -ErrorAction SilentlyContinue |
                     Where-Object Name -ne '.gitkeep')
    if ($configFiles.Count -gt 0) {
        Write-Info "Réglages partagés appliqués ($($configFiles.Count) fichier(s))."
        foreach ($file in $configFiles) {
            $target = Join-Path $gameDir ('BepInEx\config' + $file.FullName.Substring($configSource.Length))
            New-Item -ItemType Directory -Force (Split-Path -Parent $target) | Out-Null
            Copy-Item $file.FullName $target -Force
        }
    }

    $final | Where-Object Id -ne $BepInExId | ForEach-Object Id |
        Set-Content (Join-Path $gameDir "BepInEx\$StateFileName") -Encoding ASCII

    Write-Host ''
    Write-Color "  Terminé : $count mods installés." $Green
    if ($Server) { Write-Host '  Démarre le serveur comme d''habitude (start_headless_server.bat).' }
    else { Write-Host '  Lance Valheim depuis Steam comme d''habitude : les mods se chargent tout seuls.' }
    Write-Host '  Pour mettre à jour plus tard, relance simplement la même commande.' -ForegroundColor Gray
    Write-Host ''
}

try {
    Invoke-Main
} catch {
    Write-Host ''
    Write-Host "  Erreur : $($_.Exception.Message)" -ForegroundColor Red
    Write-Host ''
}
