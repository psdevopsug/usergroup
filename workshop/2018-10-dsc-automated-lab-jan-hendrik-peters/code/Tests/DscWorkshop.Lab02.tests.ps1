Import-Module $PSScriptRoot\CommonFunctions.psm1

Describe 'Task 1 - Using configuration data' -Tag Task01 {
    #$student = [io.path]::GetFullPath('C:\Users\JHP\source\repos\dscworkshop\Tests\..\Tasks\Lab2.ps1')
    $student = [io.path]::GetFullPath("$PSScriptRoot\..\Tasks\Lab2.ps1")
    $reference = [io.path]::GetFullPath("$PSScriptRoot\..\Solutions\Lab2.solution.ps1")

    It 'Should be able to compile the configuration' {
        # Execute configuration in script
        # Compile reference, compare files.
        { $script:studentMofs = & $student } | Should -Not -Throw
        { $script:referenceMofs = & $reference } | Should -Not -Throw
    }

    It 'Should have compiled three configurations' {
        $script:studentMofs.Count | Should -BeExactly 3
    }

    foreach ($mofFile in $script:studentMofs)
    {
        $mofTable = $script:referenceMofs | Group-Object -AsHashTable -AsString -Property Name
        $referencePath = $mofTable[$mofFile.Name]

        It "$($mofFile.Name) should mirror an existing reference configuration" {
            Test-Path $referencePath | Should -Not -Be $false
        }

        It "$($mofFile.Name) should contain a couple of identity references (credentials)" {
            $(Get-Content -Path $mofFile.Fullname -Raw) -match 'instance of MSFT_Credential as \$MSFT_Credential\d*ref\s*\{\s*Password.*;\s*UserName.*;\s*\};' | Should -Be $true
        }

        It "$($mofFile.Name) should be the same as the reference configuration" {
            $refContent = $(Get-Content -Path $referencePath) -replace '.*GenerationDate.*' -replace 'ResourceID\s+=.*;' -replace 'SourceInfo\s+=.*;' -replace '\s*Password\s+=.*' -replace '\s*Username\s+=.'
            $studentContent = $(Get-Content -Path $mofFile.Fullname) -replace '.*GenerationDate.*' -replace 'ResourceID\s+=.*;' -replace 'SourceInfo\s+=.*;' -replace '\s*Password\s+=.*' -replace '\s*Username\s+=.'

            Compare-Object -ReferenceObject $refContent -DifferenceObject $studentContent -PassThru | Should -Be $null
        }
    }
}