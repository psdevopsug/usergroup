<#
Enter your code after the comment. Please name your configuration Task1.

As an administrator, you are tasked with creating a configuration directory on a group of target servers.
Create a valid configuration that is able to create the directory 'C:\Temp\DscIs.Awesome'.

You can test your solution by executing Invoke-Pester .\Tests\DscWorkshop.Lab01.tests.ps1 -Tag Task01
#>

Invoke-Pester .\Tests\DscWorkshop.Lab01.tests.ps1 -Tag Task01

<#
Enter your code after the comment. Please name your configuration Task2.

As an administrator, you need to enable the RSAT-AD-Tools Feature on a server. If this has been successful,
you need to create a new forest called contoso.com.
If the machine is a valid domain controller, you need to ensure that the domain-local groups LG_UKGLA_SQL_Admins
and LG_UKEDI_SQL_Admins are always present and a member of the global group GG_UKALL_SQL_Admins.
You will need to find a way to provide credentials for domain accounts to your configuration.

Hint: You might need to discover DSC resource modules to find the necessary resources. Have a look
at Find-DscResource and Install-Module to progress...

You can test your solution by executing Invoke-Pester .\Tests\DscWorkshop.Lab01.tests.ps1 -Tag Task02
#>
Invoke-Pester .\Tests\DscWorkshop.Lab01.tests.ps1 -Tag Task02
