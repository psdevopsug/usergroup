# This is one of the many different ways of generating configuration data for a specific environment.
# You could e.g. specify the domain name for the element with NodeName * instead
# In this case, the entire configuration data for PRD is contained in this file
@{
    AllNodes = @(
        @{
            NodeName                    = '*'
            PSDSCAllowPlaintextPassword = $true
            PSDSCAllowDomainUser        = $true
        }
        @{
            NodeName = 'GLADC01'
            Role     = 'DomainController'
        }
        @{
            NodeName      = 'GLADB01'
            Role          = 'SQLServer'
            ClusterMember = 'Primary'
        }
        @{
            NodeName      = 'GLADB02'
            Role          = 'SQLServer'
            ClusterMember = 'Additional'
        }
    )

    Roles    = @(
        @{
            Role                          = 'DomainController'
            DomainAdministratorCredential = New-Object -TypeName pscredential('partsunlimited\Administrator', ('Somepass1' | ConvertTo-SecureString -AsPlainText -Force))
            SafeModeAdministratorPassword = New-Object -TypeName pscredential('partsunlimited\Administrator', ('Somepass1' | ConvertTo-SecureString -AsPlainText -Force))
            FeaturesToInstall             = @(
                'RSAT-AD-Tools'
                'AD-Domain-Services'
            )
            DomainName                    = 'partsunlimited.com' # Good candidate to move to its own key
            UsersToCreate                 = @( # Move users and groups to the domain key
                @{
                    # Using a hashtable for each user allows you to assign more
                    # than just the samaccountname from your configuration data
                    UserName = 'alice'
                }
                @{
                    UserName = 'bob'
                }
                @{
                    UserName = 'charlie'
                }
                @{
                    UserName = 'don'
                }
            )
            GroupsToCreate                = @(
                @{
                    GroupName  = 'SQLAdmins'
                    GroupScope = 'Global'
                    Category   = 'Security'
                    Members    = 'alice', 'bob', 'charlie', 'don'
                }
            )
        }
        @{
            Role              = 'SQLServer'
            SqlSource         = '\\fileserver.compant.local\images$\SQL2016RTM'
            Collation         = 'Finnish_Swedish_CI_AS'
            SourceCredential  = New-Object -TypeName pscredential('partsunlimited\Administrator', ('Somepass1' | ConvertTo-SecureString -AsPlainText -Force))
            SqlSvcCredential  = New-Object -TypeName pscredential('partsunlimited\Administrator', ('Somepass1' | ConvertTo-SecureString -AsPlainText -Force))
            RunAsCredential   = New-Object -TypeName pscredential('partsunlimited\Administrator', ('Somepass1' | ConvertTo-SecureString -AsPlainText -Force))
            SqlFeatures       = 'SQLEngine'
            InstanceName      = 'INST2016'
            FeaturesToInstall = @(
                @{
                    Name   = 'NET-Framework-Core'
                    Source = '\\fileserver.company.local\images$\Win2k12R2\Sources\Sxs'
                }
                @{
                    Name = 'NET-Framework-45-Core'
                }
            )
            Cluster           = @{
                NetworkName = 'TESTCLU01A'
                IPAddress   = '192.168.0.46'
                GroupName   = 'TESTCLU01A'
            }
        }
    )
}