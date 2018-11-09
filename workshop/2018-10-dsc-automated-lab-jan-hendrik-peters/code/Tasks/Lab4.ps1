<#
Take a look at the following script in order to enable a pull server with native SQL reporting.

You have full administrative rights on your machine, StudentXX, in order to set the pull server up.
Assume that the module is already installed, you don't need to copy it over before pushing the config.

Remember to fill in the one detail that makes this one a secure pull server ;)
#>

configuration PullServer1803 {
    Import-DscResource -ModuleName PSDesiredStateConfiguration -ModuleVersion 1.1
    Import-DscResource -ModuleName xPSDesiredStateConfiguration -ModuleVersion 8.4.0.0

node $env:USERNAME
{
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
        # CertificateThumbPrint = 'AllowUnencryptedTraffic'
        CertificateThumbPrint        = throw 'FILL ME IN! Invoke-command to your machine, ie Student01 and grab the correct cert!'
        ModulePath                   = "C:\DscPull\Modules"
        ConfigurationPath            = "C:\DscPull\Configuration"
        DatabasePath                 = "C:\DscPull"
        State                        = 'Started'
        RegistrationKeyPath          = "C:\DscPull"
        AcceptSelfSignedCertificates = $true
        UseSecurityBestPractices     = $true

        # New with Windows 1803 and Server 2019
        # Before that: Local JetDB --> devices.edb
        # Or with a hack: devices.mdb with linked tables to a SQL instance
        # Enables HA with pull server: Load balancer and a couple of pull servers
        # accessing one SQL HA database
        SqlProvider                  = $true
        SqlConnectionString          = "Provider=SQLOLEDB.1;Server=sql01.contoso.com;Database=$env:USERNAME;User ID=contoso\Install;Password=Somepass1;Initial Catalog=master;"
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
}

PullServer1803
Start-DscConfiguration -Wait -Verbose -Force -Path .\PullServer1803

# Either let another machine register with the pull server
# or call the API at least once to trigger table creation
Invoke-WebRequest -Uri "https://$env:USERNAME.contoso.com:8080/PSDSCPullServer.svc" -UseBasicParsing

# Verify by having a look at the existing tables
$sqlConnection = New-Object -TypeName System.Data.SqlClient.SqlConnection
$sqlConnection.ConnectionString = "Server=sql01.contoso.com;Database=$env:USERNAME;Trusted_Connection=yes"
$sqlCommand = New-Object -TypeName System.Data.SqlClient.SqlCommand
$sqlCommand.Connection = $sqlConnection
$sqlCommand.CommandText = "SELECT * FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_TYPE='BASE TABLE'"
$sqlConnection.Open()
$reader = $sqlCommand.ExecuteReader()
while ($reader.Read())
{
    Write-Host "Found table $($reader['TABLE_NAME']) on SQL01!"
}
$sqlConnection.Close()