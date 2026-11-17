param([string]$Godot = 'D:/Steam/steamapps/common/Godot Engine/godot.windows.opt.tools.64.exe')
$ErrorActionPreference = 'Stop'
$projectRoot = Split-Path $PSScriptRoot -Parent
foreach ($suite in @('player_input_test','dodge_rules_test','dodge_input_test','melee_rules_test','melee_input_test','feedback_test','talisman_input_test','climb_input_test','movement_intent_test')) {
$logPath = Join-Path $env:TEMP ('taoist-player-' + [guid]::NewGuid().ToString('N') + '.log')
$process = Start-Process -FilePath $Godot -ArgumentList @('--headless','--audio-driver','Dummy','--path',('"' + $projectRoot + '"'),'--script',('res://Tests/' + $suite + '.gd'),'--log-file',('"' + $logPath + '"')) -WindowStyle Hidden -Wait -PassThru
Get-Content -LiteralPath $logPath
if ($process.ExitCode -ne 0) { exit $process.ExitCode }
}
exit 0
