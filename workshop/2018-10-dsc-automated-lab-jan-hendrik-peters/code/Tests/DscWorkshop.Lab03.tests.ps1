Import-Module $PSScriptRoot\CommonFunctions.psm1

Describe 'Task 1 - LCM settings for pull server' {
    $ast = [scriptblock]::Create((Get-Content $PSScriptRoot\..\Tasks\Lab3.ps1 -raw)).Ast

    It 'Contains a configuration keyword' {
        $ast.Find( { $args[0].InstanceName.Value -eq 'Task1' -and $args[0] -is [System.Management.Automation.Language.ConfigurationDefinitionAst] }, $true) | 
            Should -Not -Be $null -Because 'You need to define a configuration with the name Task1'
    }

    $configuration = Get-LabConfiguration $ast Task1

    It 'Has a node element' {
        $configuration.FindAll( { $args[0].Value -eq 'node' -and $args[0] -is [System.Management.Automation.Language.StringConstantExpressionAst] }, $true) |
            Should -Not -Be $null -Because 'Unless you are using composite resources, a node element is mandatory.'
    }

    It 'Has a settings resource configured' {
        $nodeAst = Get-LabNode -Configuration $configuration
        Get-LabNodeResource -NodeAst $nodeAst -ResourceType Settings |
            Should -Not -Be $Null -Because 'The task requires a folder to be configured'
    }

    It 'Has a ConfigurationRepositoryWeb resource configured' {
        $nodeAst = Get-LabNode -Configuration $configuration
        Get-LabNodeResource -NodeAst $nodeAst -ResourceType ConfigurationRepositoryWeb |
            Should -Not -Be $Null -Because 'The task requires a folder to be configured'
    }

    It 'Has a ReportServerWeb resource configured' {
        $nodeAst = Get-LabNode -Configuration $configuration
        Get-LabNodeResource -NodeAst $nodeAst -ResourceType ReportServerWeb |
            Should -Not -Be $Null -Because 'The task requires a folder to be configured'
    }

    It 'Has the correct settings' {
        $nodeAst = Get-LabNode -Configuration $configuration
        $SettingsResource = Get-LabNodeResource -NodeAst $nodeAst -ResourceType Settings
        $table = $SettingsResource.Parent.Find( { $args[0] -is [System.Management.Automation.Language.HashtableAst] }, $true).SafeGetValue()
        $table.RebootNodeIfNeeded | Should -Be $true
        $table.RefreshMode | Should -Be 'Pull'
        $table.ConfigurationMode | Should -Be 'ApplyAndAutoCorrect'

        $confRepoResource = Get-LabNodeResource -NodeAst $nodeAst -ResourceType ConfigurationRepositoryWeb
        $confTable = $confRepoResource.Parent.Find( { $args[0] -is [System.Management.Automation.Language.HashtableAst] }, $true).SafeGetValue()
        $confTable.ServerURL | Should -Be 'https://we-agentservice-prod-1.azure-automation.net/accounts/8de93ebe-e71f-45b0-8d1d-688e4e0951ea'
        $confTable.ConfigurationNames | Should -Be 'DscIsAwesome'

        $reportingResource = Get-LabNodeResource -NodeAst $nodeAst -ResourceType ReportServerWeb
        $reportTable = $reportingResource.Parent.Find( { $args[0] -is [System.Management.Automation.Language.HashtableAst] }, $true).SafeGetValue()
        $reportTable.ServerURL | Should -Be 'https://we-agentservice-prod-1.azure-automation.net/accounts/8de93ebe-e71f-45b0-8d1d-688e4e0951ea'
    }
}