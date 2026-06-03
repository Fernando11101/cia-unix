function Run-Tool {
    param(
        [string]$Tool,
        [string[]]$Arguments
    )

    $Output = & ".\$Tool.exe" @Arguments 2>&1

    if ($LASTEXITCODE -ne 0) {
        Write-Host "$Tool failed with exit code $LASTEXITCODE"
        exit 1
    }

    return $Output
}

function Check-Decrypt {
    param(
        [string]$Name,
        [string]$Ext
    )

    if (Test-Path "$Name-decrypted.$Ext") {
        Write-Host "Decryption completed"
    }
    else {
        Write-Host "Decryption failed"
    }
}

function Remove-Cache {

    Write-Host "Removing cache..."

    Get-ChildItem *.ncch -ErrorAction SilentlyContinue |
        Remove-Item -Force

    Get-ChildItem '* (Game)-decrypted.cia' -ErrorAction SilentlyContinue |
    ForEach-Object {

        $Cci = $_.FullName -replace '\.cia$', '.cci'

        if (Test-Path $Cci) {
            Remove-Item $_.FullName -Force
        }
    }
}

function Gen-Args {
    param(
        [string]$Name,
        [int]$Count
    )

    $Args = @()

    for ($i = 0; $i -lt $Count; $i++) {

        $Ncch = "$Name.$i.ncch"

        if (Test-Path $Ncch) {

            $Args += "-i"
            $Args += "${Ncch}:${i}:${i}"
        }
    }

    return $Args
}

$Cias = Get-ChildItem *.cia -ErrorAction SilentlyContinue
$ThreeDS = Get-ChildItem *.3ds -ErrorAction SilentlyContinue

if (($Cias.Count -eq 0) -and ($ThreeDS.Count -eq 0)) {

    Write-Host "No CIA/3DS roms were found."

    exit 1
}

Get-ChildItem *.3ds -ErrorAction SilentlyContinue | ForEach-Object {

    if ($_.Name -match 'decrypted') {
        return
    }

    $Ds = $_.Name
    $Dsn = $_.BaseName

    Write-Host "Decrypting: $Ds"

    Run-Tool "ctrdecrypt" @($Ds)

    $Args = @(
        "-f", "cci",
        "-ignoresign",
        "-target", "p",
        "-o", "$Dsn-decrypted.3ds"
    )

    foreach ($Ncch in (Get-ChildItem "$Dsn*.ncch" -ErrorAction SilentlyContinue)) {

        switch ($Ncch.Name) {

            "$Dsn.Main.ncch"           { $i = 0 }
            "$Dsn.Manual.ncch"         { $i = 1 }
            "$Dsn.DownloadPlay.ncch"   { $i = 2 }
            "$Dsn.Partition4.ncch"     { $i = 3 }
            "$Dsn.Partition5.ncch"     { $i = 4 }
            "$Dsn.Partition6.ncch"     { $i = 5 }
            "$Dsn.N3DSUpdateData.ncch" { $i = 6 }
            "$Dsn.UpdateData.ncch"     { $i = 7 }
            default { continue }
        }

        $Args += "-i"
        $Args += "$($Ncch.Name):${i}:${i}"
    }

    Write-Host "Building decrypted 3DS..."

    Run-Tool "makerom" $Args

    Check-Decrypt "$Dsn" 3ds

    Remove-Cache
}

Get-ChildItem *.cia -ErrorAction SilentlyContinue | ForEach-Object {

    if ($_.Name -match 'decrypted') {
        return
    }

    $Cia = $_.Name
    $Cutn = $_.BaseName

    Write-Host "Decrypting: $Cia"

    $Content = Run-Tool "ctrtool" @(
        "--seeddb=seeddb.bin",
        $Cia
    )

    $TitleVersion = (
        ($Content | Select-String 'TitleVersion' | Select-Object -First 1).ToString() `
            -replace '.*\((\d+)\).*','$1'
    )

    if ($Content -match '0004000e') {

        Write-Host "CIA Type: Update"

        Run-Tool "ctrdecrypt" @($Cia)

        $Args = @(
            "-f", "cia",
            "-ignoresign",
            "-target", "p",
            "-ver", "$TitleVersion",
            "-o", "$Cutn (Update)-decrypted.cia"
        )

        $Count = (Get-ChildItem "$Cutn.*.ncch" -ErrorAction SilentlyContinue).Count

        $Args += Gen-Args $Cutn $Count

        Run-Tool "makerom" $Args

        Check-Decrypt "$Cutn (Update)" cia
    }
    elseif ($Content -match '0004008c') {

        Write-Host "CIA Type: DLC"

        Run-Tool "ctrdecrypt" @($Cia)

        $Args = @(
            "-f", "cia",
            "-dlc",
            "-ignoresign",
            "-target", "p",
            "-ver", "$TitleVersion",
            "-o", "$Cutn (DLC)-decrypted.cia"
        )

        $Count = (Get-ChildItem "$Cutn.*.ncch" -ErrorAction SilentlyContinue).Count

        $Args += Gen-Args $Cutn $Count

        Run-Tool "makerom" $Args

        Check-Decrypt "$Cutn (DLC)" cia
    }
    elseif ($Content -match '00040000') {

        Write-Host "CIA Type: Game"

        Run-Tool "ctrdecrypt" @($Cia)

        $Args = @(
            "-f", "cia",
            "-ignoresign",
            "-target", "p",
            "-ver", "$TitleVersion",
            "-o", "$Cutn (Game)-decrypted.cia"
        )

        $Count = (Get-ChildItem "$Cutn.*.ncch" -ErrorAction SilentlyContinue).Count

        $Args += Gen-Args $Cutn $Count

        Run-Tool "makerom" $Args

        Check-Decrypt "$Cutn (Game)" cia

        $Answer = Read-Host "Convert CIA to CCI? (y/n)"

        if ($Answer -match '^[Yy]$') {

            Write-Host "Building decrypted CCI..."

            Run-Tool "makerom" @(
                "-ciatocci",
                "$Cutn (Game)-decrypted.cia",
                "-o",
                "$Cutn (Game)-decrypted.cci"
            )

            Check-Decrypt "$Cutn (Game)" cci
        }
    }
    else {

        Write-Host "Unsupported CIA"
    }

    Remove-Cache
}

Read-Host "Press Enter to exit"
