# Windows Scheduled Task Registration

Use the ScheduledTasks PowerShell module to create daily automation.

## Minimal working pattern

```powershell
$action    = New-ScheduledTaskAction -Execute 'python.exe' -Argument 'C:\MES\daily_mes_sync.py'
$trigger   = New-ScheduledTaskTrigger -Daily -At 6:00AM
$settings  = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries -StartWhenAvailable
$principal = New-ScheduledTaskPrincipal -UserId "$env:USERDOMAIN\$env:USERNAME" -LogonType InteractiveToken -RunLevel Highest

Register-ScheduledTask -TaskName 'MES_to_PBI_Daily_Sync' -Action $action -Trigger $trigger -Settings $settings -Principal $principal -Force
```

## Common pitfalls

- `param()` must be the very first line in a script. Comments or blank
  lines before it cause a parse error. Dot-sourcing (`.\script.ps1`)
  also breaks `param()`; run by full path instead.
- `-RunLevel Highest` is required on locked workstations. Without it, the
  task silently fails when the screen is locked.
- `& python ...` does not propagate Python's exit code when
  `$ErrorActionPreference = 'Stop'`. Set it to `'Continue'` or check
  `$LASTEXITCODE` explicitly.
- To run a PowerShell pipeline script as the action, the action execute
  should be `powershell.exe` and the argument should be:
  `-ExecutionPolicy Bypass -File "C:\MES\daily_pbi_pipeline.ps1"`
- Always run `Register-ScheduledTask` from an elevated PowerShell once to
  create the task. Subsequent runs use `-Force` to update.
