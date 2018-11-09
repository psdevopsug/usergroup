<#
Modify or recreate the PartsUnlimitedService configuration after this comment.
Please leave the configuration name as it is.
Please name your configuration data $configDataProduction

As an administrator you received a configuration for a new application from the
development team to deploy the data tier. You are now tasked with adapting this
configuration so that:
a) hardcoded values are removed from the configuration
    - No hardcoded nodes
    - No hardcoded parameter values
    - optionally put the software installation for SQL into configuration data
      as well. Make it as generic as possible and as specific as necessary
b) The configuration can be transported from DEV to QA to PRD without modifications to
   the actual code.
c) Using credentials and domain accounts should be possible

There is a special construct that springs to mind here called configuration data. Build your
configuration for the PRD environment.

When you are done, you can execute Invoke-Pester .\Tests\DscWorkshop.Lab02.tests.ps1 -Tag Task01

For more information see Get-Help about_desired_state_configuration

If you are really stuck, take a look at Solutions\Lab2ConfigurationData.psd1
#>

Configuration PartsUnlimitedService
{
    Import-DscResource -ModuleName xActiveDirectory
    Import-DscResource -ModuleName PSDesiredStateConfiguration
    Import-DScResource -ModuleName SqlServerDsc

    node ('GLADC01')
    {
        # Domain config
        WindowsFeatureSet DCFeatures
        {
            Name   = 'RSAT-AD-Tools', 'AD-Domain-Services'
            Ensure = 'Present'
        }

        xADDomain PartsUnlimited
        {
            DomainName                    = 'partsunlimited.com'
            DomainAdministratorCredential = $null # How can we allow credentials and domain users?
            SafeModeAdministratorPassword = $Null
            DependsOn                     = '[WindowsFeatureSet]DCFeatures'
        }

        $groupDependencies = @()
        $users = 'alice', 'bob', 'charlie', 'don'
        foreach ( $user in $users)
        {
            $groupDependencies += "[xADUser]$user"
            xADUser $user
            {
                DependsOn  = '[xADDomain]PartsUnlimited'
                UserName   = $user
                DomainName = 'partsunlimited.com'
            }
        }

        xADGroup SQLAdmins
        {
            DependsOn  = $groupDependencies
            GroupName  = 'SQLAdmins'
            GroupScope = 'Global'
            Category   = 'Security'
            Members    = $users
        }
    }

    node GLADB01
    {
        #region Install prerequisites for SQL Server
        WindowsFeature 'NetFramework35'
        {
            Name   = 'NET-Framework-Core'
            Source = '\\fileserver.company.local\images$\Win2k12R2\Sources\Sxs' # Assumes built-in Everyone has read permission to the share and path.
            Ensure = 'Present'
        }

        WindowsFeature 'NetFramework45'
        {
            Name   = 'NET-Framework-45-Core'
            Ensure = 'Present'
        }
        #endregion Install prerequisites for SQL Server

        #region Install SQL Server Failover Cluster
        SqlSetup NamedInstanceNodeGLADB01
        {
            Action                     = 'InstallFailoverCluster'
            ForceReboot                = $false
            UpdateEnabled              = 'False'
            SourcePath                 = '\\fileserver.compant.local\images$\SQL2016RTM'
            SourceCredential           = $null

            InstanceName               = 'INST2016'
            Features                   = 'SQLENGINE'

            SQLCollation               = 'Finnish_Swedish_CI_AS'
            SQLSvcAccount              = $null # How can we allow credentials and domain users?
            SQLSysAdminAccounts        = 'PartsUnlimited\SQL Administrators'

            FailoverClusterNetworkName = 'TESTCLU01A'
            FailoverClusterIPAddress   = '192.168.0.46'
            FailoverClusterGroupName   = 'TESTCLU01A'

            PsDscRunAsCredential       = $null

            DependsOn                  = '[WindowsFeature]NetFramework35', '[WindowsFeature]NetFramework45'
        }
        #endregion
    }
    
    node GLADB02
    {
        #region Install prerequisites for SQL Server
        WindowsFeature 'NetFramework35'
        {
            Name   = 'NET-Framework-Core'
            Source = '\\fileserver.company.local\images$\Win2k12R2\Sources\Sxs' # Assumes built-in Everyone has read permission to the share and path.
            Ensure = 'Present'
        }

        WindowsFeature 'NetFramework45'
        {
            Name   = 'NET-Framework-45-Core'
            Ensure = 'Present'
        }
        #endregion Install prerequisites for SQL Server

        #region Install SQL Server Failover Cluster

        WaitForAll InstanceCreation
        {
            NodeName     = 'GLADB01'
            ResourceName = '[SqlSetup]NamedInstanceNodeGLADB01'
        }
        SqlSetup NamedInstanceNodeGLADB02
        {
            Action                     = 'AddNode'
            ForceReboot                = $false
            UpdateEnabled              = 'False'
            SourcePath                 = '\\fileserver.compant.local\images$\SQL2016RTM'
            SourceCredential           = $null # How can we allow credentials and domain users?

            InstanceName               = 'INST2016'
            Features                   = 'SQLENGINE'

            SQLSvcAccount              = $null # How can we allow credentials and domain users?

            FailoverClusterNetworkName = 'TESTCLU01A'

            PsDscRunAsCredential       = $null # How can we allow credentials and domain users?

            DependsOn                  = '[WindowsFeature]NetFramework35', '[WindowsFeature]NetFramework45', '[WaitForAll]InstanceCreation'
        }
        #endregion
    }
}

$configurationDataProduction = @{}

$configurationDirectory = Join-Path -Path $([IO.Path]::GetTempPath()) -ChildPath 'PartsUnlimitedServiceStudent'

PartsUnlimitedService -OutputPath $configurationDirectory #-ConfigurationData $configurationDataProduction