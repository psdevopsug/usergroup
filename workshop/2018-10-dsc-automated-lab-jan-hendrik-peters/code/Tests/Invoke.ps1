param
(
    [string]$Lab,

    [string]$Task
)

Invoke-Pester -Script "$PSScriptRoot\DscWorkshop.$Lab.tests.ps1" -Tag $Task