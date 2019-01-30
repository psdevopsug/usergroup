# Module: AutomatedLab
Install-Module AutomatedLab -AllowClobber;
New-LabSourcesFolder -DriveLetter C

$numberAttendees = 20
$subscription = throw "Fill this in!"
$location = 'UK West'

#region Lab Deployment
# Hyper-V or VMWare
New-LabDefinition -Name SCOTPSUG1810 -DefaultVirtualizationEngine Azure # Use Hyper-V, VMWare or Azure
Add-LabAzureSubscription -SubscriptionName JHPaaS -DefaultLocationName $location

Add-LabDomainDefinition -Name contoso.com -AdminUser Install -AdminPassword Somepass1
Set-LabInstallationCredential -Username Install -Password Somepass1
Add-LabIsoImageDefinition -Name SQLServer2017 -Path $labsources\ISOs\en_sql_server_2017_enterprise_x64_dvd_11293666.iso

$rdProps = @{
    RoleSize = 'Standard_D2_v2'
}

Add-LabMachineDefinition -Name DC01 -Memory 4GB -OperatingSystem 'Windows Server Datacenter' -DomainName contoso.com -Roles RootDC -AzureProperties $rdProps
$roles = @(
    Get-LabMachineRoleDefinition -Role CARoot
    Get-LabMachineRoleDefinition -Role SQLServer2017 -Properties @{Features = 'SQLEngine'}
)
Add-LabMachineDefinition -Name SQL01 -Memory 8GB -OperatingSystem 'Windows Server Datacenter' -DomainName contoso.com -Roles $roles -AzureProperties $rdProps
Add-LabMachineDefinition -Name RDGW -Memory 8GB -OperatingSystem 'Windows Server 2016 Datacenter (Desktop Experience)' -DomainName contoso.com -AzureProperties $rdProps
Add-LabMachineDefinition -Name RDCB -Memory 8GB -OperatingSystem 'Windows Server 2016 Datacenter (Desktop Experience)' -DomainName contoso.com -AzureProperties $rdProps
Add-LabMachineDefinition -Name RDS1 -Memory 8GB -OperatingSystem 'Windows Server 2016 Datacenter (Desktop Experience)' -DomainName contoso.com -AzureProperties  @{
    RoleSize = 'Standard_D32_v3' # 132GB RAM, 32vCPU
}

foreach ($i in $(1..$numberAttendees))
{
    $machineName = "STUDENT{0:d2}" -f $i
    $disk = Add-LabDiskDefinition -Name $("st{0:d2}hdd1" -f $i) -PassThru -DiskSizeInGb 20
    Add-LabMachineDefinition -Name $machineName -Memory 2GB -OperatingSystem 'Windows Server Datacenter' -DomainName contoso.com -AzureProperties $rdProps -DiskName $disk.Name
}

Install-Lab # Sets up the entire infrastructure
#endregion

#region Customization, RDS deployment
Enable-LabCertificateAutoenrollment -Computer
$rdCert = (Request-LabCertificate -Subject "CN=*.contoso.com" -SAN "*CN=$((Get-LabVm RDGW).AzureConnectionInfo.DnsName)",'CN=lab.janhendrikpeters.de' -TemplateName WebServer -ComputerName RDGW -PassThru).Thumbprint
Invoke-LabCommand RDGW -ScriptBlock {
    Export-PfxCertificate -Cert (get-childitem cert:\localmachine\my)[-1] -Force -ChainOption BuildChain -FilePath C:\cert.pfx -ProtectTo contoso\install
} -PassThru 

Request-LabCertificate -Subject "CN=*.contoso.com" -TemplateName WebServer -ComputerName (Get-LabVm | Where Name -like Student*)

# Invoke-LabCommand handels lab credentials automatically
Invoke-LabCommand -ComputerName DC01 -Variable (Get-Variable numberAttendees) -ScriptBlock {
    $users = foreach ($i in 1..$numberAttendees)
    {
        $uName = "Student{0:d2}" -f $i
        New-ADUser -SamAccountName $uName -Name $uName -Surname Stu -GivenName Dent -AccountPassword $('Somepass1' | ConvertTo-SecureString -AsPlain -Force) -Enabled $true -PassThru        
    }
}

Invoke-LabCommand -ComputerName (Get-LabVm | Where Name -like Student*) -ScriptBlock {
    $username = "contoso\Student{0}{1}" -f $ENV:ComputerName[-2,-1]
    Add-LocalGroupMember -Group 'Administrators' -Member $username
} -PassThru

Add-LWAzureLoadBalancedPort -Port 443 -ComputerName RDGW

Invoke-LabCommand -ComputerName (Get-LabVm | Where Name -like Student*) -ScriptBlock {
Install-PackageProvider -Name Nuget -Force
Install-Module xPSDesiredStateConfiguration -Force
@'    
    configuration PullServer1803 {
        Import-DscResource -ModuleName PSDesiredStateConfiguration -ModuleVersion 1.1
        Import-DscResource -ModuleName xPSDesiredStateConfiguration -ModuleVersion 8.4.0.0
    
        WindowsFeature DscSvc {
            Name   = 'Dsc-Service'
            Ensure = 'Present'
        }
    
        File PullServerDir {
            DestinationPath = 'C:\DscPull'
            Ensure = 'Present'
            Type = 'Directory'
            Force = $true
        }
    
        xDscWebService PSDSCPullServer {
            Ensure                       = 'Present'
            EndpointName                 = 'PSDSCPullServer'
            Port                         = 8080
            PhysicalPath                 = "$env:SystemDrive\inetpub\PSDSCPullServer"
            CertificateThumbPrint        = $(Get-ChildItem cert:\localmachine\my -SSl | Select -First 1).ThumbPrint
            ModulePath                   = "C:\DscPull\Modules"
            ConfigurationPath            = "C:\DscPull\Configuration"
            DatabasePath                 = "C:\DscPull"
            State                        = 'Started'
            RegistrationKeyPath          = "C:\DscPull"
            AcceptSelfSignedCertificates = $true
            UseSecurityBestPractices     = $true
            SqlProvider                  = $true
            SqlConnectionString          = "Provider=SQLOLEDB.1;Server=sql01.contoso.com;Database=$env:COMPUTERNAME;User ID=contoso\Install;Password=Somepass1;Initial Catalog=master;"
            DependsOn                    = '[File]PullServerDir', '[WindowsFeature]DscSvc'
        }
    
        File RegistrationKeyFile {
            Ensure          = 'Present'
            Type            = 'File'
            DestinationPath = "C:\DscPull\RegistrationKeys.txt"
            Contents        = (New-Guid).Guid
            DependsOn       = '[File]PullServerDir'
        }
    }

    PullServer1803
    Start-DscConfiguration -Wait -Verbose -Force -Path .\PullServer1803

    # Either let another machine register with the pull server
    # or call the API at least once to trigger table creation
    Invoke-WebRequest -Uri "http://$env:COMPUTERNAME.contoso.com:8080/PSDSCPullServer.svc" -UseBasicParsing

    # Verify by having a look at the existing tables
    $sqlConnection = New-Object -TypeName System.Data.Sql.SqlConnection
    $sqlConnection.ConnectionString = "Server=sql01.contoso.com;Database=$env:COMPUTERNAME;Trusted_Connection=yes"
    $sqlCommand = New-Object -TypeName System.Data.Sql.SqlCommand
    $sqlCommand.Connection = $sqlConnection
    $sqlCommand.CommandText = "SELECT * FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_TYPE='BASE TABLE'"
    $sqlConnection.Open()
    $sqlCommand.ExecuteReader()
    while ($reader.Read())
    {
        $reader
    }
    $sqlConnection.Close()
'@ | Set-Content -Path C:\PullServerSetup.ps1
}

Invoke-LabCommand -ComputerName (Get-LabVm | Where Name -like RDS*) -ScriptBLock {
iex ((New-Object System.Net.WebClient).DownloadString('https://chocolatey.org/install.ps1'))
choco install vscode /y
choco install vscode-powershell /y
choco install powershell-core /y
choco install git /y
Install-PackageProvider nuget -Force -Confirm:$false
Install-MOdule PowerShellGet -Force
} -PassThru

Restart-LabVm -ComputerName RDS1 -Wait
Invoke-LabCommand -ComputerName RDS1 -ScriptBlock {
choco install sql-server-management-studio /y
git clone https://github.com/nyanhp/dscworkshop C:\users\public\desktop\dscworkshop
}

Invoke-LabCommand -ComputerName rdgw -ScriptBlock {
param ($ExternalFqdn)
    New-NetFirewallRule -Proto TCP -LocalPort 5985 -Name "Firewall-GW-RDSH-TCP-In" -Description "Firewall-GW-RDSH-TCP-In" -DisplayName "Firewall-GW-RDSH-TCP-In" -Enabled True -Action Allow -Direction Inbound
    New-RDSessionDeployment -ConnectionBroker rdcb.contoso.com -SessionHost rds1.contoso.com -WebAccessServer rdgw.contoso.com -Verbose
    Add-RDServer -Server rds2.contoso.com -Role RDS-RD-SERVER -ConnectionBroker rdcb.contoso.com -GatewayExternalFqdn lab.janhendrikpeters.de -Verbose
    Add-RDServer -Server rds3.contoso.com -Role RDS-RD-SERVER -ConnectionBroker rdcb.contoso.com -GatewayExternalFqdn lab.janhendrikpeters.de -Verbose
    Add-RDServer -Server rdgw.contoso.com -Role RDS-GATEWAY -ConnectionBroker rdcb.contoso.com -GatewayExternalFqdn lab.janhendrikpeters.de -Verbose
    Add-RDServer -Server rdcb.contoso.com -Role RDS-LICENSING -ConnectionBroker rdcb.contoso.com -GatewayExternalFqdn lab.janhendrikpeters.de -Verbose
    New-RDSessionCollection -CollectionName IrnBru -CollectionDescription "Welcome to the Scottish PowerShell User Group Meetup Oct 18!" -SessionHost rds1.contoso.com -COnnectionBroker rdcb.contoso.com -PersonalUnmanaged

    # Install PowerShellGet in the recent version to prepare for next step
    Install-Module -Name PowerShellGet -Force
} -PassThru -Verbose

Remove-LabPSSession -ComputerName rdgw

Invoke-LabCommand -ComputerName rdgw -ScriptBlock {
    # Prepare for the installation of the RDS Web Client
    Install-Module -Name RDWebClientManagement -Force -AcceptLicense
    Install-RDWebClientPackage
    Export-PfxCertificate -Cert (get-item Cert:\LocalMachine\my\$rdCert) -Force -ChainOption BuildChain -FilePath C:\cert.pfx -ProtectTo contoso\install
    Import-RDWebClientBrokerCert C:\cert.pfx
    Publish-RDWebClientPackage -Type Production -Latest
} -PassThru -Verbose -Variable (Get-Variable rdCert)
