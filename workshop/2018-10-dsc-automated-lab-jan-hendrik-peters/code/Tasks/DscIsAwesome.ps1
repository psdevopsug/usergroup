configuration DscIsAwesome
{
    param(
        [Parameter(Mandatory = $true)]
        [ValidateNotNullorEmpty()]
        [PSCredential]
        $Credential
    )

    Import-DscResource -ModuleName PsDscResources -ModuleVersion 2.9.0.0
    Import-DscResource -Modulename ComputerManagementDsc -ModuleVersion 5.2.0.0
    Import-DscResource -ModuleName PackageManagement -ModuleVersion 1.1.7.2
    Import-DscResource -ModuleName StorageDsc -ModuleVersion 4.1.0.0

    node localhost
    {
        Disk SecondHdd
        {
            DiskId      = 2
            DriveLetter = 'X'
            DiskIdType  = 'Number'
        }

        File PolarisScript
        {
            SourcePath      = '\\automatedlabsourceshcmyd.file.core.windows.net\labsources\ScotPsug\RunPolaris.ps1'
            Credential      = $Credential
            DestinationPath = 'X:\WebContent\RunPolaris.ps1'
            Type            = 'File'
            Ensure          = 'Present'
            MatchSource     = $true
        }

        PackageManagement polaris
        {
            Name         = 'Polaris'
            ProviderName = 'PowerShellGet'
            Source       = 'PSGallery'
            Ensure       = 'Present'
        }

        ScheduledTask polarisservice
        {
            DependsOn        = '[File]PolarisScript', '[PackageManagement]polaris'
            TaskName         = 'RunPolarisRun'
            Description      = 'Runs the Polaris REST endpoint'
            ActionExecutable = 'powershell.exe'
            ActionArguments  = '-File "X:\WebContent\RunPolaris.ps1'
            Ensure           = 'Present'
            Enable           = $true
            ScheduleType     = 'AtStartup'
        }

        Script StartPolaris
        {
            DependsOn = '[ScheduledTask]polarisservice'
            GetScript  = {}
            TestScript = { (Get-ScheduledTask -TaskName Polaris -ErrorAction SilentlyContinue).State -eq 'Running'}
            SetScript  = { Start-ScheduledTask -TaskName Polaris}
        }
    }
}
