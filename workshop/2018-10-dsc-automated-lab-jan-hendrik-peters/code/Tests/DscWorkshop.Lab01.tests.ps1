Import-Module $PSScriptRoot\CommonFunctions.psm1

Describe 'Task 1 - designing a configuration' -Tag 'Task01' {
    $ast = [scriptblock]::Create((Get-Content $PSScriptRoot\..\Tasks\Lab1.ps1 -raw)).Ast

    $fileInput = @{
        DestinationPath = 'C:\Temp\DscIs.Awesome'
        Type            = 'Directory'
    }

    It 'Contains a configuration keyword' {
        $ast.Find( { $args[0].InstanceName.Value -eq 'Task1' -and $args[0] -is [System.Management.Automation.Language.ConfigurationDefinitionAst] }, $true) | 
            Should -Not -Be $null -Because 'You need to define a configuration with the name Task1'
    }

    $configuration = Get-LabConfiguration $ast Task1

    It 'Imports the DSC Resource PSDesiredStateConfiguration' {
        
        $importCmd = $configuration.Body.ScriptBlock.Find( { $args[0].Value -eq 'Import-DscResource' -and $args[0] -is [System.Management.Automation.Language.StringConstantExpressionAst] }, $true)
        $importCmd.Parent.CommandElements.Value -contains 'PSDesiredStateConfiguration' |
            Should -Be $true -Because 'It is best practice to import PSDesiredStateConfiguration, even though it is not mandatory'
    }

    It 'Has a node element' {
        $configuration.FindAll( { $args[0].Value -eq 'node' -and $args[0] -is [System.Management.Automation.Language.StringConstantExpressionAst] }, $true) |
            Should -Not -Be $null -Because 'Unless you are using composite resources, a node element is mandatory.'
    }

    It 'Has a File resource configured' {
        $nodeAst = Get-LabNode -Configuration $configuration
        Get-LabNodeResource -NodeAst $nodeAst -ResourceType File |
            Should -Not -Be $Null -Because 'The task requires a folder to be configured'
    }

    It 'Has the correct settings for the file resource' {
        $nodeAst = Get-LabNode -Configuration $configuration
        $fileResource = Get-LabNodeResource -NodeAst $nodeAst -ResourceType File
        $table = $fileResource.Parent.Find( { $args[0] -is [System.Management.Automation.Language.HashtableAst] }, $true).SafeGetValue()
        Compare-HashTable -DifferenceObject $table -ReferenceObject $fileInput |
            Should -Be $null -Because 'The task requires you to create a directory called C:\Temp\DscIs.Awesome'
    }
}

Describe 'Task 2 - custom resources' -Tag 'Task02' {
    $ast = [scriptblock]::Create((Get-Content $PSScriptRoot\..\Tasks\Lab1.ps1 -raw)).Ast

    It 'Contains a configuration keyword' {
        Get-LabConfiguration $ast Task2 | Should -Not -Be $null
    }

    $configuration = Get-LabConfiguration $ast Task2
    It 'Imports the DSC Resources PSDesiredStateConfiguration and xActiveDirectory' {
        $importCmds = Get-LabImportedCommand -Configuration $configuration

        $importCmds -contains 'PSDesiredStateConfiguration' | Should -Be $true
        $importCmds -contains 'xActiveDirectory' | Should -Be $true
    }

    It 'Has a node element' {
        Get-LabNode $configuration | Should -Not -Be $null
    }

    Context 'Resources' {
        $configuration = Get-LabConfiguration $ast Task2
        It 'Has a WindowsFeature resource configured' {            
            $nodeAst = Get-LabNode -Configuration $configuration
            Get-LabNodeResource -NodeAst $nodeAst -ResourceType WindowsFeature | Should -Not -Be $Null
        }

        It 'Has a xADDomain resource configured' {
            $nodeAst = Get-LabNode -Configuration $configuration
            Get-LabNodeResource -NodeAst $nodeAst -ResourceType xADDomain | Should -Not -Be $Null
        }

        It 'Has three xADGroup resources configured' {
            $nodeAst = Get-LabNode -Configuration $configuration
            (Get-LabNodeResource -NodeAst $nodeAst -ResourceType xADGroup -FindAll).Count | Should -Be 3
        }
    }

    It 'Enables the correct windows feature' {
        $nodeAst = Get-LabNode -Configuration $configuration
        $feature = Get-LabNodeResource -NodeAst $nodeAst -ResourceType WindowsFeature
        $table = $feature.Parent.Find( { $args[0] -is [System.Management.Automation.Language.HashtableAst] }, $true).SafeGetValue()
        $table.Name | Should -Be 'RSAT-AD-Tools'
    }

    It 'Has configured a dependency between feature and domain deployment' {
        $nodeAst = Get-LabNode -Configuration $configuration
        $feature = Get-LabNodeResource -NodeAst $nodeAst -ResourceType WindowsFeature
        $domain = Get-LabNodeResource -NodeAst $nodeAst -ResourceType xADDomain
        $dependencyName = $feature.Parent.CommandElements[1].Value
        $dependency = ($domain.Parent.Find( { $args[0] -is [System.Management.Automation.Language.HashtableAst] }, $true).KeyValuePairs | Where {$_.Item1.Value -eq 'DependsOn'}).Item2.Extent.Text

        $dependency | Should -Be "'[WindowsFeature]$dependencyName'"
    }

    $configuration = Get-LabConfiguration $ast Task2
    $nodeAst = Get-LabNode -Configuration $configuration
    $groupsAst = Get-LabNodeResource -NodeAst $nodeAst -ResourceType xADGroup -FindAll
    $local, $global = $groupsAst.Parent.Find( { $args[0] -is [System.Management.Automation.Language.HashtableAst]}, $true).Where( {$_.KeyValuePairs.Item2.Extent.Text -clike '*DomainLocal*'}, 'Split')

    $groupsToCompare = @(
        'LG_UKGLA_SQL_Admins'
        'LG_UKEDI_SQL_Admins'
    )

    It 'Has configured a dependency between domain-local and global groups' {        
        $local.Count | Should -Be 2
        $global.Count | Should -Be 1

        $globalDepends = $global.Parent.CommandElements.KeyValuePairs.Where( {$_.Item1.Value -eq 'DependsOn'}).Item2.Extent.Text

        foreach ($lgroup in $local)
        {
            $name = $lgroup.Parent.CommandElements[1].Value
            $globalDepends -match "\[xADGroup\]$name" | Should -Be $true
        }
    }

    It 'Has configured the correct groups' {
        $local.KeyValuePairs.Where( {$_.Item1.Value -eq 'GroupName'}).Item2.Extent.Text -replace "'" | Should -Be $groupsToCompare
    }

    It 'Has configured the membership of the global group like a boss' {
        ($global.KeyValuePairs.Where( {$_.Item1.Value -eq 'Members'}).Item2.Extent.Text -replace "'") -split ', ' | Should -Be $groupsToCompare
    }
}