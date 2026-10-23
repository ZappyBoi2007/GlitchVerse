param([string]$Godot = 'C:\Tools\Godot\Godot.exe')
$ErrorActionPreference = 'Stop'
$projectRoot = Split-Path -Parent $PSScriptRoot
if (-not (Test-Path -LiteralPath $Godot)) { throw "Godot executable not found: $Godot" }
$logDirectory = Join-Path $projectRoot '.godot\audit-validation'
New-Item -ItemType Directory -Path $logDirectory -Force | Out-Null

function Invoke-GodotCheck([string]$Name, [string[]]$ExtraArguments) {
    $stdout = Join-Path $logDirectory "$Name.out.log"
    $stderr = Join-Path $logDirectory "$Name.err.log"
    # Windows GUI executables require an explicitly waited process and captured stderr.
    $arguments = @('--headless', '--path', ('"' + $projectRoot + '"')) + $ExtraArguments
    $process = Start-Process -FilePath $Godot -ArgumentList $arguments -WindowStyle Hidden -PassThru -RedirectStandardOutput $stdout -RedirectStandardError $stderr
    if (-not $process.WaitForExit(30000)) {
        Stop-Process -Id $process.Id
        throw "$Name exceeded 30 seconds"
    }
    $output = (Get-Content -LiteralPath $stdout,$stderr -Raw) -join "`n"
    if ($process.ExitCode -ne 0 -or $output -match '(?m)^(SCRIPT ERROR|ERROR|FAIL:)') {
        Write-Output $output
        throw "$Name failed (exit $($process.ExitCode))"
    }
    Write-Output "PASS $Name (exit $($process.ExitCode))"
    if ($Name -eq 'integration') { Write-Output $output.Trim() }
}

Invoke-GodotCheck 'import' @('--editor', '--quit')
$scriptFiles = Get-ChildItem -LiteralPath $projectRoot -Filter '*.gd' -Recurse -File | Where-Object { $_.FullName -notlike '*\.godot\*' -and $_.FullName -notlike '*\.git\*' }
foreach ($scriptFile in $scriptFiles) {
    $relative = [System.IO.Path]::GetRelativePath($projectRoot, $scriptFile.FullName).Replace('\', '/')
    $checkName = 'parse-' + $relative.Replace('/', '-').Replace('.', '-')
    Invoke-GodotCheck $checkName @('--check-only', '--script', ('"res://' + $relative + '"'))
}
Invoke-GodotCheck 'main' @('--quit-after', '300')
Invoke-GodotCheck 'integration' @('--script', 'res://tests/integration_checks.gd')
& git -C $projectRoot diff --check
if ($LASTEXITCODE -ne 0) { throw 'git diff --check failed' }
Write-Output "PASS git diff --check. Logs: $logDirectory"
