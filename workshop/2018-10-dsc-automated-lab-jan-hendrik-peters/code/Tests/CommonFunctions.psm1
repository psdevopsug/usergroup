function Compare-Hashtable
{
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [Hashtable]$ReferenceObject,
    
        [Parameter(Mandatory = $true)]
        [Hashtable]$DifferenceObject		
    )
    
    $ReferenceObject.Keys | ForEach-Object {
        if ($ReferenceObject.ContainsKey($_) -and !$DifferenceObject.ContainsKey($_))
        {
            [PSCustomObject] @{
                Key           = $_
                SideIndicator = '<='
                Reference     = $ReferenceObject[$_]
                Difference    = $null
            }
        }
        
        if (!$ReferenceObject.ContainsKey($_) -and $DifferenceObject.ContainsKey($_))
        {
            [PSCustomObject] @{
                Key           = $_
                SideIndicator = '=>'
                Reference     = $null
                Difference    = $DifferenceObject[$_]
            }
        }

        if (($ReferenceObject.ContainsKey($_) -and $DifferenceObject.ContainsKey($_)) -and ($ReferenceObject[$_] -ne $DifferenceObject[$_]))
        {
            [PSCustomObject] @{
                Key           = $_
                SideIndicator = '!='
                Reference     = $ReferenceObject[$_]
                Difference    = $DifferenceObject[$_]
            }
        }
    } 
}

function Get-LabConfiguration
{
    param
    (
        [System.Management.Automation.Language.Ast]
        $Ast,

        [String]
        $Task
    )

    $ast.Find( {$args[0].InstanceName.Value -eq $Task -and $args[0] -is [System.Management.Automation.Language.ConfigurationDefinitionAst] }, $true)
}

function Get-LabNode
{
    param
    (
        $Configuration
    )

    $node = $Configuration.Find( { $args[0].Value -eq 'node' -and $args[0] -is [System.Management.Automation.Language.StringConstantExpressionAst] }, $true)
    $node.Parent.CommandElements | Where-Object {$_.StaticType.FullName -eq 'System.Management.Automation.ScriptBlock'}
}

function Get-LabNodeResource
{
    param
    (
        $NodeAst,

        $ResourceType,

        [switch]$FindAll
    )

    if ($FindAll)
    {
        return ($NodeAst.FindAll( { $args[0].Value -eq $ResourceType -and $args[0] -is [System.Management.Automation.Language.StringConstantExpressionAst] }, $true))
    }
    
    $NodeAst.Find( { $args[0].Value -eq $ResourceType -and $args[0] -is [System.Management.Automation.Language.StringConstantExpressionAst] }, $true)
}

function Get-LabImportedCommand
{
    param
    (
        $Configuration
    )

    $importCmds = $Configuration.Body.ScriptBlock.FindAll( { $args[0].Value -eq 'Import-DscResource' -and $args[0] -is [System.Management.Automation.Language.StringConstantExpressionAst] }, $true)

    $importCmds.Parent.CommandElements.Value
}