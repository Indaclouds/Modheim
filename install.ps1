[CmdletBinding()]
param(
    [switch]$Server,
    [string]$GamePath,
    [switch]$Uninstall,
    [switch]$Yes,
    [string]$Source,
    [string]$Pack,
    [string]$Repo = 'Indaclouds/Modheim',
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
    if (-not [Console]::IsInputRedirected) {
        Write-Host "    $Question $hint " -NoNewline -ForegroundColor White
        while ($true) {
            $key = [Console]::ReadKey($true)
            $answer = $null
            if ($key.Key -eq 'Enter') { $answer = $Default }
            elseif ("$($key.KeyChar)".ToLowerInvariant() -in 'o', 'y') { $answer = $true }
            elseif ("$($key.KeyChar)".ToLowerInvariant() -eq 'n') { $answer = $false }
            if ($null -ne $answer) {
                Write-Host $(if ($answer) { 'oui' } else { 'non' }) -ForegroundColor Gray
                return $answer
            }
        }
    }
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

function Write-ModLine($Mod, [string]$Status) {
    Write-Color '    • ' $Orange -NoNewline
    Write-Host (Get-DisplayName $Mod) -NoNewline -ForegroundColor White
    Write-Host " $($Mod.Version)" -NoNewline -ForegroundColor DarkGray
    switch -Wildcard ($Status) {
        ''            { Write-Host '' }
        'nouveau'     { Write-Color '  (nouveau)' $Green }
        'mise à jour*' { Write-Color "  ($Status)" $Orange }
        default       { Write-Host "  ($Status)" -ForegroundColor DarkGray }
    }
}

function Show-CheckList($Labels, $Notes, [bool[]]$Checked) {
    $count = $Labels.Count
    $state = [bool[]]$Checked.Clone()
    if ($Yes) { return $state }

    if ([Console]::IsInputRedirected) {
        while ($true) {
            for ($i = 0; $i -lt $count; $i++) {
                $box = if ($state[$i]) { '[x]' } else { '[ ]' }
                Write-Host ('    {0,2}. {1} {2}{3}' -f ($i + 1), $box, $Labels[$i], $Notes[$i])
            }
            Write-Host '    Numéros à cocher ou décocher (séparés par des espaces), Entrée pour valider : ' -NoNewline
            $answer = "$(Read-Host)".Trim()
            if (-not $answer) { return $state }
            foreach ($token in $answer -split '[\s,;]+') {
                $number = 0
                if ([int]::TryParse($token, [ref]$number) -and $number -ge 1 -and $number -le $count) {
                    $state[$number - 1] = -not $state[$number - 1]
                }
            }
        }
    }

    Write-Host '    ↑/↓ se déplacer · Espace cocher · A tout cocher/décocher · Entrée valider · Échap annuler' -ForegroundColor DarkGray
    for ($i = 0; $i -lt $count; $i++) { Write-Host '' }
    $top = [Console]::CursorTop - $count
    $width = [Math]::Max(20, [Console]::WindowWidth - 1)
    $index = 0
    try {
        [Console]::CursorVisible = $false
        while ($true) {
            for ($i = 0; $i -lt $count; $i++) {
                [Console]::SetCursorPosition(0, $top + $i)
                Write-Host (' ' * $width) -NoNewline
                [Console]::SetCursorPosition(0, $top + $i)
                if ($i -eq $index) { Write-Color '  › ' $Orange -NoNewline } else { Write-Host '    ' -NoNewline }
                if ($state[$i]) { Write-Color '[x] ' $Green -NoNewline } else { Write-Host '[ ] ' -NoNewline -ForegroundColor DarkGray }
                $color = if ($i -eq $index) { 'White' } else { 'Gray' }
                Write-Host $Labels[$i] -NoNewline -ForegroundColor $color
                Write-Host $Notes[$i] -NoNewline -ForegroundColor DarkGray
            }
            $key = [Console]::ReadKey($true)
            switch ($key.Key) {
                'UpArrow'   { $index = ($index - 1 + $count) % $count }
                'DownArrow' { $index = ($index + 1) % $count }
                'Spacebar'  { $state[$index] = -not $state[$index] }
                'A' {
                    $value = $state -contains $false
                    for ($i = 0; $i -lt $count; $i++) { $state[$i] = $value }
                }
                'Enter'  { return $state }
                'Escape' { return $null }
            }
        }
    } finally {
        [Console]::SetCursorPosition(0, $top + $count)
        [Console]::CursorVisible = $true
        Write-Host ''
    }
}

function Read-MenuChoice([string[]]$Options) {
    if ($Yes) { return 1 }
    for ($i = 0; $i -lt $Options.Count; $i++) {
        Write-Color "    $($i + 1). " $Orange -NoNewline
        Write-Host $Options[$i] -ForegroundColor White
    }
    if (-not [Console]::IsInputRedirected) {
        Write-Host "    Ton choix [1-$($Options.Count)] (Entrée = 1) " -NoNewline -ForegroundColor White
        while ($true) {
            $key = [Console]::ReadKey($true)
            $number = 0
            if ($key.Key -eq 'Enter') { $number = 1 }
            else { [void][int]::TryParse("$($key.KeyChar)", [ref]$number) }
            if ($number -ge 1 -and $number -le $Options.Count) {
                Write-Host $number -ForegroundColor Gray
                return $number
            }
        }
    }
    while ($true) {
        Write-Host "    Ton choix [1-$($Options.Count)] (Entrée = 1) " -NoNewline -ForegroundColor White
        $answer = "$(Read-Host)".Trim()
        if (-not $answer) { return 1 }
        $number = 0
        if ([int]::TryParse($answer, [ref]$number) -and $number -ge 1 -and $number -le $Options.Count) { return $number }
    }
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

function Invoke-ThunderstoreRequest([string]$Uri, [string]$OutFile, [string]$What) {
    for ($attempt = 1; $attempt -le 4; $attempt++) {
        try {
            if ($OutFile) { return Invoke-WebRequest $Uri -OutFile $OutFile -UseBasicParsing }
            return Invoke-WebRequest $Uri -UseBasicParsing
        } catch {
            $status = 0
            if ($_.Exception.Response) { $status = [int]$_.Exception.Response.StatusCode }
            if ($status -eq 404) { throw "$What introuvable sur Thunderstore (vérifie le nom et la version dans modlist.txt)." }
            if ($attempt -eq 4) { throw "Thunderstore ne répond pas pour $What. Réessaie dans une minute." }
            Start-Sleep -Seconds (5 * $attempt)
        }
    }
}

function Get-PackageInfo($Mod) {
    $key = "$($Mod.Id)-$($Mod.Version)"
    if (-not $script:PackageInfo.ContainsKey($key)) {
        $response = Invoke-ThunderstoreRequest "$ApiBase/$($Mod.Namespace)/$($Mod.Name)/$($Mod.Version)/" $null "$($Mod.Id) $($Mod.Version)"
        $script:PackageInfo[$key] = [Text.Encoding]::UTF8.GetString($response.RawContentStream.ToArray()) | ConvertFrom-Json
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
        [void](Invoke-ThunderstoreRequest "https://thunderstore.io/package/download/$($Mod.Namespace)/$($Mod.Name)/$($Mod.Version)/" $partial "$($Mod.Id) $($Mod.Version)")
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

function Copy-SharedConfigs([string]$PackSource, [string]$GameDir) {
    $configSource = Join-Path $PackSource 'config'
    $configFiles = @(Get-ChildItem $configSource -Recurse -File -ErrorAction SilentlyContinue |
                     Where-Object Name -ne '.gitkeep')
    foreach ($file in $configFiles) {
        $target = Join-Path $GameDir ('BepInEx\config' + $file.FullName.Substring($configSource.Length))
        New-Item -ItemType Directory -Force (Split-Path -Parent $target) | Out-Null
        Copy-Item $file.FullName $target -Force
    }
    return $configFiles.Count
}

function New-ServerPack([string]$OutFile) {
    Write-Step 'Préparation du pack serveur (sans BepInEx)'
    $packSource = Get-PackSource
    $sections = Read-ModList (Join-Path $packSource 'modlist.txt')
    $mods = @(Resolve-Dependencies (@(Get-Section $sections 'commun') + @(Get-Section $sections 'serveur')) |
              Where-Object Id -ne $BepInExId)

    $stage = Join-Path $env:TEMP 'modheim\pack'
    if (Test-Path $stage) { Remove-Item $stage -Recurse -Force }
    New-Item -ItemType Directory -Force $stage | Out-Null
    foreach ($mod in $mods) {
        Write-ModLine $mod
        Install-PackageZip (Get-PackageZip $mod) $mod $stage
    }
    $configCount = Copy-SharedConfigs $packSource $stage

    $target = $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath($OutFile)
    if (Test-Path $target) { Remove-Item $target -Force }
    [IO.Compression.ZipFile]::CreateFromDirectory($stage, $target)
    Write-Host ''
    Write-Color "  Pack prêt : $target ($($mods.Count) mods, $configCount fichier(s) de réglages)" $Green
    Write-Host ''
}

function Get-InstalledMods([string]$GameDir) {
    $installed = [ordered]@{}
    $state = Join-Path $GameDir "BepInEx\$StateFileName"
    if (-not (Test-Path $state)) { return $installed }
    foreach ($line in Get-Content $state) {
        $parts = $line.Trim() -split '\s+'
        if (-not $parts[0]) { continue }
        $installed[$parts[0]] = if ($parts.Count -gt 1) { $parts[1] } else { '' }
    }
    return $installed
}

function Save-InstalledMods([string]$GameDir, $Installed) {
    $lines = foreach ($id in $Installed.Keys) { "$id $($Installed[$id])".Trim() }
    Set-Content (Join-Path $GameDir "BepInEx\$StateFileName") ([string[]]$lines) -Encoding ASCII
}

function Get-ModStatus($Mod, $Installed) {
    if ($Mod.Id -eq $BepInExId) { return '' }
    if (-not $Installed.Contains($Mod.Id)) { return 'nouveau' }
    $current = $Installed[$Mod.Id]
    if ($current -and $current -ne $Mod.Version) { return "mise à jour $current → $($Mod.Version)" }
    return 'installé'
}

function Remove-ModFolders([string]$GameDir, [string]$Id) {
    foreach ($kind in 'plugins', 'patchers') {
        $folder = Join-Path $GameDir "BepInEx\$kind\$Id"
        if (Test-Path $folder) { Remove-Item $folder -Recurse -Force }
    }
}

function Remove-PreviousMods([string]$GameDir) {
    foreach ($id in (Get-InstalledMods $GameDir).Keys) { Remove-ModFolders $GameDir $id }
}

function Select-ModSet($Listed, $Installed, [string[]]$RequiredIds) {
    Write-Step 'Choix des mods'
    Write-Info 'Les mods décochés seront retirés s''ils sont installés.'
    $mods = @($Listed | Where-Object Id -ne $BepInExId)
    $labels = @($mods | ForEach-Object { "$(Get-DisplayName $_) $($_.Version)" })
    $notes = @($mods | ForEach-Object {
        $note = ''
        $status = Get-ModStatus $_ $Installed
        if ($status) { $note += "  ($status)" }
        if ($RequiredIds -contains $_.Id) { $note += '  · requis pour le serveur' }
        $note
    })
    $result = Show-CheckList $labels $notes ([bool[]]@($mods | ForEach-Object { $true }))
    if ($null -eq $result) { return $null }
    $selected = @($Listed | Where-Object Id -eq $BepInExId)
    for ($i = 0; $i -lt $mods.Count; $i++) { if (@($result)[$i]) { $selected += $mods[$i] } }

    $selectedIds = @($selected | ForEach-Object Id)
    $final = @(Resolve-Dependencies $selected)
    $extra = @($final | Where-Object { $selectedIds -notcontains $_.Id })
    if ($extra.Count -gt 0) {
        foreach ($dep in $extra) {
            $listedDep = $Listed | Where-Object Id -eq $dep.Id | Select-Object -First 1
            if ($listedDep) { $selected += $listedDep } else { $selected += $dep }
            Write-Info "$(Get-DisplayName $dep) ajouté : un mod choisi en a besoin."
        }
        $final = @(Resolve-Dependencies $selected)
    }

    $finalIds = @($final | ForEach-Object Id)
    $missing = @($Listed | Where-Object { $RequiredIds -contains $_.Id -and $finalIds -notcontains $_.Id })
    if ($missing.Count -gt 0) {
        Write-Host ''
        Write-Color '    Attention : ces mods sont requis pour jouer sur le serveur.' $Orange
        Write-Color '    Sans eux, la connexion peut être refusée ou le jeu incohérent :' $Orange
        foreach ($mod in $missing) { Write-Host "      - $(Get-DisplayName $mod)" -ForegroundColor White }
        if (-not (Read-YesNo 'Continuer quand même ?' $false)) { return $null }
    }
    return $final
}

function Remove-ChosenMods([string]$GameDir, $Known) {
    Write-Step 'Suppression de mods'
    $installed = Get-InstalledMods $GameDir
    if ($installed.Count -eq 0) {
        Write-Info 'Aucun mod Modheim n''est installé ici.'
        return
    }
    if (Read-YesNo 'Tout retirer (BepInEx compris) pour revenir au jeu d''origine ?' $false) {
        Remove-Everything $GameDir
        return
    }

    Write-Host ''
    Write-Info 'Coche les mods à supprimer.'
    $ids = @($installed.Keys)
    $labels = @($ids | ForEach-Object { (($_ -split '-', 2)[-1]) -replace '_', ' ' })
    $notes = @($ids | ForEach-Object { if ($installed[$_]) { " $($installed[$_])" } else { '' } })
    $result = Show-CheckList $labels $notes ([bool[]]@($ids | ForEach-Object { $false }))
    if ($null -eq $result) {
        Write-Info 'Annulé : rien n''a été modifié.'
        return
    }
    $toRemove = @()
    for ($i = 0; $i -lt $ids.Count; $i++) { if (@($result)[$i]) { $toRemove += $ids[$i] } }
    if ($toRemove.Count -eq 0) {
        Write-Info 'Rien à supprimer : aucun mod n''a été modifié.'
        return
    }

    foreach ($id in @($installed.Keys)) {
        if ($toRemove -contains $id) { continue }
        $mod = $Known | Where-Object Id -eq $id | Select-Object -First 1
        if (-not $mod) { continue }
        foreach ($depText in (Get-PackageInfo $mod).dependencies) {
            $depId = (ConvertTo-PackageRef $depText).Id
            if ($toRemove -contains $depId) {
                $toRemove = @($toRemove | Where-Object { $_ -ne $depId })
                Write-Info "$((($depId -split '-', 2)[-1]) -replace '_', ' ') est gardé : $(Get-DisplayName $mod) en a besoin."
            }
        }
    }

    foreach ($id in $toRemove) {
        Remove-ModFolders $GameDir $id
        $installed.Remove($id)
    }
    Save-InstalledMods $GameDir $installed
    Write-Host ''
    Write-Color "  Terminé : $($toRemove.Count) mod(s) supprimé(s)." $Green
    Write-Host '  Pour les remettre, relance la même commande.' -ForegroundColor Gray
    Write-Host ''
}

function Uninstall-Modheim([string]$GameDir) {
    Write-Step 'Désinstallation'
    if (-not (Read-YesNo 'Retirer BepInEx et tous les mods pour revenir au jeu d''origine ?')) {
        Write-Info 'Annulé : rien n''a été modifié.'
        return
    }
    Remove-Everything $GameDir
}

function Remove-Everything([string]$GameDir) {
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

    if ($Pack) { New-ServerPack $Pack; return }

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

    $installed = Get-InstalledMods $gameDir
    Write-Step 'La liste des mods actuellement :'
    foreach ($mod in $final) { Write-ModLine $mod (Get-ModStatus $mod $installed) }
    Write-Host ''
    Write-Host "  Pour plus d'infos, voir le README du repo : https://github.com/$Repo" -ForegroundColor Gray

    Write-Step 'Que veux-tu faire ?'
    $choice = Read-MenuChoice @(
        'Tout installer / mettre à jour (recommandé)',
        'Choisir les mods à installer',
        'Supprimer des mods',
        'Quitter sans rien changer'
    )
    if ($choice -eq 3) { Remove-ChosenMods $gameDir $final; return }
    if ($choice -eq 4) {
        Write-Host ''
        Write-Host '  Rien n''a été modifié.' -ForegroundColor Yellow
        Write-Host ''
        return
    }
    if ($choice -eq 2) {
        $requiredIds = @(@(Get-Section $sections 'commun') + @(Get-Section $sections 'serveur') | ForEach-Object Id)
        $final = Select-ModSet $listed $installed $requiredIds
        if (-not $final) {
            Write-Host ''
            Write-Host '  Installation annulée : rien n''a été modifié.' -ForegroundColor Yellow
            Write-Host ''
            return
        }
        $final = @($final)
        $removed = @($installed.Keys | Where-Object { @($final | ForEach-Object Id) -notcontains $_ })
        Write-Step 'Récapitulatif'
        Write-Info "$($final.Count) mods à installer ou mettre à jour."
        if ($removed.Count -gt 0) { Write-Info "$($removed.Count) mod(s) retiré(s) : $((@($removed | ForEach-Object { (($_ -split '-', 2)[-1]) -replace '_', ' ' })) -join ', ')" }
        if (-not (Read-YesNo 'On y va ?')) {
            Write-Host ''
            Write-Host '  Installation annulée : rien n''a été modifié.' -ForegroundColor Yellow
            Write-Host ''
            return
        }
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

    $configCount = Copy-SharedConfigs $packSource $gameDir
    if ($configCount -gt 0) { Write-Info "Réglages partagés appliqués ($configCount fichier(s))." }

    $newState = [ordered]@{}
    foreach ($mod in @($final | Where-Object Id -ne $BepInExId)) { $newState[$mod.Id] = $mod.Version }
    Save-InstalledMods $gameDir $newState

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
