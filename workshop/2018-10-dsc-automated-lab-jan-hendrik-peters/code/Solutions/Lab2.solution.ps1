<#
Enter your code after the comment. Please name your configuration Task1.

As an administrator you received a configuration for a new application from the
development team to deploy the data tier. You are now tasked with adapting this
configuration so that:
a) hardcoded values are removed from the configuration
    - No hardcoded nodes
    - No hardcoded parameter values
b) The configuration can be transported from DEV to QA to PRD without modifications
c) Using credentials and domain accounts is possible

There is a special construct that springs to mind here called configuration data. Build your
configuration for the PRD environment.

When you are done, you can execute Invoke-Pester .\Tests -Tag Task03

For more information see Get-Help about_desired_state_configuration

If you are really stuck, take a look at Solutions\Lab2ConfigurationData.psd1
#>
Configuration PartsUnlimitedService
{
    Import-DscResource -ModuleName xActiveDirectory
    Import-DscResource -ModuleName PSDesiredStateConfiguration
    Import-DScResource -ModuleName SqlServerDsc

    node $AllNodes.Where( {$_.Role -eq 'DomainController'}).NodeName
    {
        $roleSpecific = $configurationData.Roles.Where( {$_.Role -eq 'DomainController'})
        # Domain config
        WindowsFeatureSet DCFeatures
        {
            Name   = $roleSpecific.FeaturesToInstall
            Ensure = 'Present'
        }

        xADDomain PartsUnlimited
        {
            DomainName                    = $roleSpecific.DomainName
            DomainAdministratorCredential = $roleSpecific.DomainAdministratorCredential
            SafeModeAdministratorPassword = $roleSpecific.SafeModeAdministratorPassword
            DependsOn                     = '[WindowsFeatureSet]DCFeatures'
        }

        $groupDependencies = @()

        foreach ( $user in $roleSpecific.UsersToCreate)
        {
            $groupDependencies += "[xADUser]$($user.UserName)"
            xADUser $user.UserName
            {
                DependsOn  = '[xADDomain]PartsUnlimited'
                UserName   = $user.UserName
                DomainName = $roleSpecific.DomainName
            }
        }

        foreach ($group in $roleSpecific.GroupsToCreate)
        {
            xADGroup $group.GroupName
            {
                DependsOn  = $groupDependencies
                GroupName  = $group.GroupName
                GroupScope = $group.GroupScope
                Category   = $group.Category
                Members    = $group.Members
            }
        }
    }

    node $AllNodes.Where( {$_.Role -eq 'SQLServer' -and $_.ClusterMember -eq 'Primary'}).NodeName
    {
        $roleSpecific = $configurationData.Roles.Where( {$_.Role -eq 'SQLServer'})

        $featureDeps = @()
        foreach ($feature in $rolespecific.FeaturesToInstall)
        {
            $featureDeps += "[WindowsFeature]$($feature.Name)"
            if ($feature.Source)
            {
                WindowsFeature $feature.Name
                {
                    Name   = $feature.Name
                    Source = $feature.Source
                    Ensure = 'Present'
                }
            }
            else
            {
                WindowsFeature $feature.Name
                {
                    Name   = $feature.Name
                    Ensure = 'Present'
                }
            }
        }

        SqlSetup "NamedInstance$Node"
        {
            Action                     = 'InstallFailoverCluster'
            ForceReboot                = $false
            UpdateEnabled              = 'False'
            SourcePath                 = $roleSpecific.SqlSource
            SourceCredential           = $roleSpecific.SourceCredential

            InstanceName               = $roleSpecific.InstanceName
            Features                   = $roleSpecific.SqlFeatures

            SQLCollation               = $roleSpecific.Collation
            SQLSvcAccount              = $roleSpecific.SqlSvcCredential
            SQLSysAdminAccounts        = 'PartsUnlimited\SQL Administrators'

            FailoverClusterNetworkName = $roleSpecific.Cluster.NetworkName
            FailoverClusterIPAddress   = $roleSpecific.Cluster.IPAddress
            FailoverClusterGroupName   = $roleSpecific.Cluster.GroupName

            PsDscRunAsCredential       = $roleSpecific.RunAsCredential

            DependsOn                  = $featureDeps
        }
    }

    node $AllNodes.Where( {$_.Role -eq 'SQLServer' -and $_.ClusterMember -eq 'Additional'}).NodeName
    {
        $roleSpecific = $configurationData.Roles.Where( {$_.Role -eq 'SQLServer'})

        $featureDeps = @()
        foreach ($feature in $rolespecific.FeaturesToInstall)
        {
            $featureDeps += "[WindowsFeature]$($feature.Name)"
            if ($feature.Source)
            {
                WindowsFeature $feature.Name
                {
                    Name   = $feature.Name
                    Source = $feature.Source
                    Ensure = 'Present'
                }
            }
            else
            {
                WindowsFeature $feature.Name
                {
                    Name   = $feature.Name
                    Ensure = 'Present'
                }
            }            
        }

        WaitForAll InstanceCreation
        {
            NodeName     = $AllNodes.Where( {$_.Role -eq 'SQLServer' -and $_.ClusterMember -eq 'Primary'}).NodeName
            ResourceName = "[SqlSetup]NamedInstanceNode$($AllNodes.Where({$_.Role -eq 'SQLServer' -and $_.ClusterMember -eq 'Primary'}).NodeName)"
        }

        SqlSetup "NamedInstance$Node"
        {
            Action                     = 'AddNode'
            ForceReboot                = $false
            UpdateEnabled              = 'False'
            SourcePath                 = $roleSpecific.SqlSource
            SourceCredential           = $roleSpecific.SourceCredential

            InstanceName               = $roleSpecific.InstanceName
            Features                   = $roleSpecific.SqlFeatures

            SQLSvcAccount              = $roleSpecific.SqlSvcCredential

            FailoverClusterNetworkName = $roleSpecific.Cluster.NetworkName

            PsDscRunAsCredential       = $roleSpecific.RunAsCredential

            DependsOn                  = $featureDeps + '[WaitForAll]InstanceCreation'
        }
    }
}

# Examine the contents of Lab2ConfigurationData.psd1
# Import-LocalizedData is usually used to import a bunch of strings depending the the current culture. In this case, we
# use it as a convenience way to import hashtables from files
Import-LocalizedData -BaseDirectory $PSScriptRoot -BindingVariable configurationDataProduction -FileName Lab2Configurationdata.psd1 -SupportedCommand New-Object, ConvertTo-SecureString

$configurationDirectory = Join-Path -Path $([IO.Path]::GetTempPath()) -ChildPath 'PartsUnlimitedService'

# Try building the configuration!
PartsUnlimitedService -ConfigurationData $configurationDataProduction -Verbose -OutputPath $configurationDirectory