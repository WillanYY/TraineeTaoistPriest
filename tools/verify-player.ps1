param([string]$Godot = 'D:/Steam/steamapps/common/Godot Engine/godot.windows.opt.tools.64.exe')
$ErrorActionPreference = 'Stop'
$projectRoot = Split-Path $PSScriptRoot -Parent
$logPath = Join-Path $env:TEMP ('taoist-player-' + [guid]::NewGuid().ToString('N') + '.log')
$process = Start-Process -FilePath $Godot -ArgumentList @('--headless','--audio-driver','Dummy','--path',('"' + $projectRoot + '"'),'--script','res://Tests/player_input_test.gd','--log-file',('"' + $logPath + '"')) -WindowStyle Hidden -Wait -PassThru
Get-Content -LiteralPath $logPath
exit $process.ExitCode
