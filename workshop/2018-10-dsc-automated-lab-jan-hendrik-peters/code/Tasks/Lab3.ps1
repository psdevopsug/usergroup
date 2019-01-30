<#
Enter your code after the comment. Please name your configuration Task1.

Your developers have finished defining their service, it is now your turn
to onboard new systems to use DSC. Configurations should auto-correct themselves
and the systems need to restart if needed. New configurations should be pulled
not more than once per day.
You have configured a Pull Server with Azure Automation. Please onboard your
node (STUDENTxx) and pull the configuration "DscIsAwesome.localhost".

Ensure that the machine is configured for both reporting as well as configuration
download.

The pull server uses the following data:
URI: https://we-agentservice-prod-1.azure-automation.net/accounts/8de93ebe-e71f-45b0-8d1d-688e4e0951ea
Registration Key: <DISPLAYED ON SCREEN DURING WORKSHOP>

Pull the configuration after onboarding to complete the exercise.

You can test your solution by executing Invoke-Pester .\Tests\DscWorkshop.Lab03.tests.ps1 -Tag Task01 if you cannot access your
cloud workstation.
#>
