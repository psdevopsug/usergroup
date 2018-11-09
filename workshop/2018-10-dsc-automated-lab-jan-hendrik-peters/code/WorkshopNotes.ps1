#region DSC intro

# Components of DSC

# Configuration - contains nodes and resource
configuration LocalConfig
{

    # Optional: Node element
    # Can be added manually, should be generated automatically if possible
    node localhost
    {
        # Mandatory: Some resources
        File someFile
        {
            DestinationPath = 'D:\scotpsug'
            Type            = 'File'
            Contents        = 'Will stay that way.' # Contents will be staying the same if auto-corrected
            # SourcePath --> To copy file/folder structures 
        }
    }
}
Get-DscResource File -Syntax -ErrorAction SilentlyContinue

# Compile a configuration
LocalConfig # PowerShell will compile a MOF file (Done by the module PSDesiredStateConfiguration)
psedit .\LocalConfig\localhost.mof

# Resources - Built-in vs Community
Get-DscResource -Module PSDesiredStateConfiguration

# Community resources - github.com/powershell/DSCResources
# HQRM High quality resource modules:
# Modules with high test coverage (Pester + codecov.io)
# Documentation, Examples

# Experimental/Beta resources: xActiveDirectory
# Prefix x: Experimental, some will be transferred to the HQRM standards
# Prefix c: Community, cISCSI -> Now integrated into StorageDsc

# Using custom resources in Configurations
configuration DomainDeployment
{
    param
    (
        [pscredential]
        $someCred
    )
    # optionally: Module Version to compile the configuration with
    # Ensures compatibility in case an update breaks things
    # Updated DSC Resource MOdule --> Necessity of tests in dev, qa, prod
    # This module is needed on all target nodes, e.g. COpy-Item -ToSession (No additional SMB port ;))
    Import-DscResource -ModuleName xActiveDirectory -ModuleVersion 2.20.0.0

    xADDomain firstDomain
    {
        DomainName                    = 'contoso.com'
        DomainAdministratorCredential = $someCred # to query existing domains, NOT the domain administrators password after deployment
        SafemodeAdministratorPassword = $someCred # Necessary
    }
}
# Configurations can - like function - accept parameters
DomainDeployment -someCred contoso\install

# Security in DSC - Encrypting your credentials
# Using plaintext credentials needs to be allowed first
# You should use certificates instead ;)
configuration WithCredentialsPlain
{
    Import-DscResource -ModuleName PSDesiredStateConfiguration

    # $AllNodes, can be filtered with Where-Object or .Where()
    node $AllNodes.NodeName # Or use configuration data and the automatic variable $Allnodes
    {
        File copyFromShare
        {
            SourcePath      = '\\dc01\someShare'
            DestinationPath = 'C:\MirroredContents'
            Credential      = $ConfigurationData.Credential # Automatic variable containing the entire hashtable
            #PSDSCRunAsCredential = $null # Automatic property, executes entire resource script as this user
        }
    }
}

# Where Method: Split, First
(Get-ChildItem -File).Where( {-not $_.ReadOnly})
$large, $small = (Get-Process).Where( {$_.WS -gt 150MB}, 'Split') # Split the result set
(Get-Process).Where( {$_.WS -gt 150MB}, 'First') # grab the first element

# Configuration data might change depending on the environment
# Configuration script should not change, and only adapt to the dat
$configuration = @{ # Large hashtable with configuration data
    AllNodes   = @( # Key AllNodes -> maps to $AllNodes in the configuration
        @{
            NodeName                    = '*'
            PSDSCAllowPlaintextPassword = $true # In order to really allow plaintext creds
        }
        @{
            NodeName = 'localhost' # Mandatory key, all other keys are up to you
            Role     = 'DC' # Used in many examples on the internet
        }
    )

    Credential = New-Object pscredential -argumentlist 'userName', ('password' | ConvertTo-SecureString -asplaintext -force)
}

WithCredentialsPlain -ConfigurationData $configuration # Compilation works
psedit .\WithCredentialsPlain\localhost.mof

# modules: CMS (Cryptographic Message Syntax, WMF5), ProtectedData (Gallery-download, PSv4+)
# Use Certificates to encrypt data to recipients

# You can script in Configurations
# Any scripting inside the configuration only happens on the build system
# Only the resource modules need to be present on the nodes themselve
configuration conf
{
    File f
    {
        Credential      = Get-KPEntry something # Or any other cmdlet to retrieve encrypted data from some store
        DestinationPath = 'C:\temp'
    }
}

# Built-in with WMF5
# Requires DocumentEncryption certificates from an internal PKI
# On the build system: Requires access to the public key
# All Target nodes: Requires access to the private key
# First Challenge: Rolling out certificates ;)
Get-ChildItem Cert:\localmachine\my -DocumentEncryption
Protect-CmsMessage -Content 'hello' -To 'CN=SomeNode'

# Once certs are rolled out: Use the thumbprint and certificate file
# in the configuration data
# Pull server, build system, need the exported public keys
Export-Certificate -FilePath D:\somenode.cer -Cert (Get-item cert:\localmachine\my\8BC6360E7695AE5E28BB6218D318A0D8C19D4321)
$configuration = @{ # Large hashtable with configuration data
    AllNodes   = @( # Key AllNodes -> maps to $AllNodes in the configuration
        @{
            NodeName                    = '*'
            PSDSCAllowPlaintextPassword = $true # In order to really allow plaintext creds
        }
        @{
            NodeName        = 'SomeNode' # Mandatory key, all other keys are up to you
            Role            = 'DC' # Used in many examples on the internet
            CertificateFile = 'D:\somenode.cer' # In order to encrypt data to nodes, specifiy the certificate
        }
    )

    Credential = New-Object pscredential -argumentlist 'userName', ('password' | ConvertTo-SecureString -asplaintext -force)
}

# You can use Self-signed certs, however a PKI is recommended
# Unless certificates can be externally sources (i.e. bought)
# DocumentEncryption cert
WithCredentialsPlain -ConfigurationData $configuration
psedit .\WithCredentialsPlain\somenode.mof

Unprotect-CmsMessage

# Configuration Data to extract any hardcoded values
# from a configuration
$conf = @{
    Dev = @{
        DomainName = 'dev.contoso.com'
        AllNodes   = @(
            @{
                NodeName = 'DEVDB01'
                Role     = 'DB'
            }
        )
        Roles      = @(
            @{
                Role              = 'DB'
                FeaturesToInstall = @(
                    'FeatureA'
                    'FeatureB'
                )
            }
        )
    }
}

# Essential to be able to scale up the node configuration generation
# Otherwise scripting each single node is too time consuming
$conf.DEV # Data that is passed when in the dev environment
$conf.Dev.Nodes # Array of hashtables
$conf.Dev.Roles | Where Role -eq 'DB' # In the configuration: Lookup on node's role

configuration WithConfigData
{
    $AllNodes.Where( {$_.Role -eq 'DB'}).NodeName # Grab all nodes with a specific role
    {
        # Automatic variable $Node points to each individual node
        # You might want to add the environment to the node as well
        $roleData = $ConfigurationData.Roles | Where Role -eq $Node.Role
        foreach ($feature in $roleData.FeaturesToInstall)
        {
            WindowsFeature $feature
            {
                Name = $feature
            }
        }
    }
}

# Generates one MOF file, DEVDB01, with the contents
# grabbed from the configuration data
WithConfigData -ConfigurationData $conf.Dev # Parameter expects a Hashtable
$conf.Dev.AllNodes.Where( {$_.Role -eq 'DB'}).NodeName

#endregion

#region Push

# Active deployment to a number of target nodes
configuration conf
{
    File f
    {
        DestinationPath = 'D:\itworks'
        Type = 'File'
        Contents = 'It really works...'
    }
}
conf

# All discovered MOF files will be used, CIM sessions will be used here
# CIM Remoting is used (WSMan, Port 5985)
Start-DscConfiguration -Verbose -Wait -Path .\conf -FOrce # Apply all configuration from directory
Start-DscConfiguration -UseExisting -Wait -Verbose
Set-Content D:\itworks -Value 'something else'
Test-DscConfiguration # Works locally or remotely
Test-DscConfiguration -Detailed

# WMF5: Use the reference config
# Any custom resources need to be present on the target nodes
# No other changes are made
$sessions = New-CimSession -ComputerName POSHDC1,POSHDC2,POSHFS1 -Credential contoso\install
Test-DscConfiguration -ReferenceConfiguration .\conf\localhost.mof -CimSession $sessions

# Configuration documents
# Pending: Ready to be applied, currently configuring
# Current: The currently (fully) applied config
# Previous: In PUSH mode: Roll back to this is possible
gci C:\windows\system32\configuration -Filter *.mof

configuration conf
{
    File f
    {
        DestinationPath = 'D:\itworks'
        Type = 'File'
        Contents = 'It does not work...'
    }
}
conf
Start-DscConfiguration .\conf -wait

# Users are complaining, things are breaking down
Restore-DscConfiguration -Verbose # Restore previous.mof
Get-DscConfiguration
Get-Content D:\itworks

# Initiate a PUSH to one or more target nodes

#endregion

#region Pull

# One central repository for configurations, Modules and reporting
# Usually: IIS, also possible: SMB share
# With a pull server set up, you need to configure the LCM
[dsclocalconfigurationmanager()]
configuration lcmSettings
{
    node localhost
    {
        Settings # Settings-element does not have a name and is unique per conf
        {
            ConfigurationMode = 'ApplyAndAutoCorrect' # Default: ApplyAndMonitor
            ConfigurationModeFrequencyMins = 600 # Default: 15 minutes, lowest setting

            RefreshMode = 'Pull' # Automatically pull config, requires pull server config
            RefreshFrequencyMins = 150 # 30 minutes, lowest setting
        }

        ConfigurationRepositoryWeb AzureDsc
        {
            ServerURL = 'https://we-agentservice-prod-1.azure-automation.net/accounts/8de93ebe-e71f-45b0-8d1d-688e4e0951ea'
            # RegistrationKey is used once only to onboard a new node
            RegistrationKey = 'SomePresharedKey' # Located on the pull server
            # With WMF4: ConfigurationId instead of multiple names
            ConfigurationNames = 'DscIsAwesome.localhost'
        }
    }
}
lcmSettings # Generates meta.mof for node onboarding
psedit .\lcmSettings\localhost.meta.mof # Needs to be pushed to clients or integrated into installation image

Set-DscLocalConfigurationManager -Path .\lcmsettings -Verbose
Update-DScConfiguration -Verbose -Wait # Will configure the node with the Configuration from the pull server

# Pull Server Creation
# WindowsFeature DSC-Service, xDscWebService --> Configuration of pull server

#endregion

#region Advanced DSC - Configuration Data
# Clone the repo (or fork and clone it) to get started
# Requires some knowledge of DSC and its possibilities
# Presented as a workshop at PSConf18
git clone https://github.com/automatedlab/dscworkshop

#endregion