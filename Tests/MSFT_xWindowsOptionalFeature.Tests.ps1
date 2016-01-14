<# 
.summary
    Test suite for MSFT_xWindowsOptionalFeature.psm1
#>
[CmdletBinding()]
param()

Import-Module $PSScriptRoot\..\DSCResources\MSFT_xWindowsOptionalFeature\MSFT_xWindowsOptionalFeature.psm1

$ErrorActionPreference = 'stop'
Set-StrictMode -Version latest


function Suite.BeforeAll {
    # Remove any leftovers from previous test runs
    Suite.AfterAll 

}

function Suite.AfterAll {
    Remove-Module MSFT_xWindowsOptionalFeature
}

function Suite.BeforeEach {
}

try
{
    InModuleScope MSFT_xWindowsOptionalFeature {

    $testFeatureName = 'TestFeature';
    $fakeEnabledFeature = [PSCustomObject] @{ Name = $testFeatureName; State = 'Enabled'; }
    $fakeDisabledFeature = [PSCustomObject] @{ Name = $testFeatureName; State = 'Disabled'; }
        
    Describe 'Validates ConvertStateToEnsure method' {

        It 'Returns "Present" when state is "Enabled"' {
            ConvertStateToEnsure -State 'Enabled' | Should Be 'Present';
        }

        It 'Returns "Absent" when state is "Disabled"' {
            ConvertStateToEnsure -State 'Disabled' | Should Be 'Absent';
        }
    } #end Describe Validates ConvertStateToEnsure method

    Describe 'Validates ValidatePrerequisites method' {
        
        $fakeWindows7 = [PSCustomObject] @{ ProductType = 1; BuildNumber = 6000; }
        $fakeServer2008R2 = [PSCustomObject] @{ ProductType = 2; BuildNumber = 6000; }
        $fakeServer2012 = [PSCustomObject] @{ ProductType = 2; BuildNumber = 7000; }
        $fakeWindows81 = [PSCustomObject] @{ ProductType = 1; BuildNumber = 9600; }
        $fakeServer2012R2 = [PSCustomObject] @{ ProductType = 2; BuildNumber = 9600; }

        It 'Throws when server operating system is Server 2008 R2' {
            Mock Get-CimInstance -ParameterFilter { $ClassName -eq 'Win32_OperatingSystem' } -MockWith { return $fakeServer2008R2; }
            Mock Import-Module -ParameterFilter { $Name -eq 'Dism' } -MockWith { }

            { ValidatePrerequisites } | Should Throw;
        }

        It 'Throws when server operating system is Server 2012' {
            Mock Get-CimInstance -ParameterFilter { $ClassName -eq 'Win32_OperatingSystem' } -MockWith { return $fakeServer2012; }
            Mock Import-Module -ParameterFilter { $Name -eq 'Dism' } -MockWith { }

            { ValidatePrerequisites } | Should Throw;
        }

        It 'Throws when DISM module is not available' {
            Mock Import-Module -ParameterFilter { $Name -eq 'Dism' } -MockWith { Write-Error 'Cannot find module'; }

            { ValidatePrerequisites } | Should Throw;
        }

        It 'Does not throw when desktop operating system is Windows 7' {
            Mock Get-CimInstance -ParameterFilter { $ClassName -eq 'Win32_OperatingSystem' } -MockWith { return $fakeWindows7; }
            Mock Import-Module -ParameterFilter { $Name -eq 'Dism' } -MockWith { }

            { ValidatePrerequisites } | Should Not Throw;
        }

        It 'Does not throw when desktop operating system is Windows 8.1' {
            Mock Get-CimInstance -ParameterFilter { $ClassName -eq 'Win32_OperatingSystem' } -MockWith { return $fakeWindows81; }
            Mock Import-Module -ParameterFilter { $Name -eq 'Dism' } -MockWith { }

            { ValidatePrerequisites } | Should Not Throw;
        }

        It 'Does not throw when server operating system is Server 2012 R2' {
            Mock Get-CimInstance -ParameterFilter { $ClassName -eq 'Win32_OperatingSystem' } -MockWith { return $fakeServer2012R2; }
            Mock Import-Module -ParameterFilter { $Name -eq 'Dism' } -MockWith { }

            { ValidatePrerequisites } | Should Not Throw;
        }
    }

    Describe 'Validates Get-TargetResource method' {
        
        It 'Returns [System.Collections.Hashtable] object type' {
            Mock ValidatePrerequisites -MockWith { }
            Mock Dism\Get-WindowsOptionalFeature { $FeatureName -eq $testFeatureName } -MockWith { return $fakeEnabledFeature; }

            $targetResource = Get-TargetResource -Name $testFeatureName;

            $targetResource -is [System.Collections.Hashtable] | Should Be $true;
        }

        It 'Calls "ValidateProperties" method' {
            Mock ValidatePrerequisites -MockWith { }
            Mock Dism\Get-WindowsOptionalFeature { $FeatureName -eq $testFeatureName } -MockWith { return $fakeEnabledFeature; }

            $targetResource = Get-TargetResource -Name $testFeatureName;

            Assert-MockCalled Dism\Get-WindowsOptionalFeature -ParameterFilter { $FeatureName -eq $testFeatureName } -Scope It;
        }

        It 'Returns "Present" when optional feature is enabled' {
            Mock ValidatePrerequisites -MockWith { }
            Mock Dism\Get-WindowsOptionalFeature { $FeatureName -eq $testFeatureName } -MockWith { return $fakeEnabledFeature; }

            $targetResource = Get-TargetResource -Name $testFeatureName;

            $targetResource.Ensure | Should Be 'Present';
        }

        It 'Returns "Absent" when optional feature is enabled' {
            Mock ValidatePrerequisites -MockWith { }
            Mock Dism\Get-WindowsOptionalFeature { $FeatureName -eq $testFeatureName } -MockWith { return $fakeDisabledFeature; }

            $targetResource = Get-TargetResource -Name $testFeatureName;

            $targetResource.Ensure | Should Be 'Absent';
        }
      
    } #end Describe Validates Get-TargetResource method

    Describe 'Validates Test-TargetResource method' {

        It 'Returns a "[System.Boolean]" object type' {
            Mock ValidatePrerequisites -MockWith { }
            Mock Dism\Get-WindowsOptionalFeature { $FeatureName -eq $testFeatureName } -MockWith { return $fakeEnabledFeature; }

            $targetResource = Test-TargetResource -Name $testFeatureName;

            $targetResource -is [System.Boolean] | Should Be $true;
        }

        It 'Returns false when optional feature is not available and "Ensure" = "Present"' {
            Mock ValidatePrerequisites -MockWith { }
            Mock Dism\Get-WindowsOptionalFeature { $FeatureName -eq $testFeatureName } -MockWith { }

            $targetResource = Test-TargetResource -Name $testFeatureName -Ensure Present;

            $targetResource | Should Be $false;
        }
        
        It 'Returns false when optional feature is disabled and "Ensure" = "Present"' {
            Mock ValidatePrerequisites -MockWith { }
            Mock Dism\Get-WindowsOptionalFeature { $FeatureName -eq $testFeatureName } -MockWith { return $fakeDisabledFeature; }

            $targetResource = Test-TargetResource -Name $testFeatureName -Ensure Present;

            $targetResource | Should Be $false;
        }

        It 'Returns true when optional feature is enabled and "Ensure" = "Present"' {
            Mock ValidatePrerequisites -MockWith { }
            Mock Dism\Get-WindowsOptionalFeature { $FeatureName -eq $testFeatureName } -MockWith { return $fakeEnabledFeature; }

            $targetResource = Test-TargetResource -Name $testFeatureName -Ensure Present;

            $targetResource | Should Be $true;
        }

        It 'Returns true when optional feature is not available and "Ensure" = "Absent"' {
            Mock ValidatePrerequisites -MockWith { }
            Mock Dism\Get-WindowsOptionalFeature { $FeatureName -eq $testFeatureName } -MockWith { }

            $targetResource = Test-TargetResource -Name $testFeatureName -Ensure Absent;

            $targetResource | Should Be $true;
        }

        It 'Returns true when optional feature is disabled and "Ensure" = "Absent"' {
            Mock ValidatePrerequisites -MockWith { }
            Mock Dism\Get-WindowsOptionalFeature { $FeatureName -eq $testFeatureName } -MockWith { return $fakeDisabledFeature; }

            $targetResource = Test-TargetResource -Name $testFeatureName -Ensure Absent;

            $targetResource | Should Be $true;
        }

        It 'Returns false when optional feature is enabled and "Ensure" = "Absent"' {
            Mock ValidatePrerequisites -MockWith { }
            Mock Dism\Get-WindowsOptionalFeature { $FeatureName -eq $testFeatureName } -MockWith { return $fakeEnabledFeature; }

            $targetResource = Test-TargetResource -Name $testFeatureName -Ensure Absent;

            $targetResource | Should Be $false;
        }

    } #end Describe Validates Test-TargetResource method

    Describe 'Validates "Set-TargetResource" method' {
    <#
    if ($Ensure -eq 'Present')
    {
        if ($NoWindowsUpdateCheck)
        {
            $feature = Dism\Enable-WindowsOptionalFeature -FeatureName $Name -Online -LogLevel $DismLogLevel @PSBoundParameters -LimitAccess -NoRestart
        }
        else
        {
            $feature = Dism\Enable-WindowsOptionalFeature -FeatureName $Name -Online -LogLevel $DismLogLevel @PSBoundParameters -NoRestart
        }

        Write-Verbose ($LocalizedData.FeatureInstalled -f $Name)
    }
    #>
        It 'Calls "Enable-WindowsOptionalFeature" with default "NoRestart" when "Present"' {
            Mock ValidatePrerequisites -MockWith { }
            Mock Dism\Enable-WindowsOptionalFeature -ParameterFilter { $NoRestart -eq $true } -MockWith { }
            
            Set-TargetResource -Name $testFeatureName;

            Assert-MockCalled Dism\Enable-WindowsOptionalFeature -ParameterFilter { $NoRestart -eq $true } -Scope It
        }

        It 'Calls "Enable-WindowsOptionalFeature" with "Online" when "Present"' {
            Mock ValidatePrerequisites -MockWith { }
            Mock Dism\Enable-WindowsOptionalFeature -ParameterFilter { $Online -eq $true } -MockWith { }
            
            Set-TargetResource -Name $testFeatureName;

            Assert-MockCalled Dism\Enable-WindowsOptionalFeature -ParameterFilter { $Online -eq $true } -Scope It
        }

        It 'Calls "Enable-WindowsOptionalFeature" with default "WarningsInfo" logging level when "Present"' {
            Mock ValidatePrerequisites -MockWith { }
            Mock Dism\Enable-WindowsOptionalFeature -ParameterFilter { $LogLevel -eq 'WarningsInfo' } -MockWith { }
            
            Set-TargetResource -Name $testFeatureName

            Assert-MockCalled Dism\Enable-WindowsOptionalFeature -ParameterFilter { $LogLevel -eq 'WarningsInfo' } -Scope It
        }

        It 'Calls "Enable-WindowsOptionalFeature" with "Errors" logging level when "Present"' {
            Mock ValidatePrerequisites -MockWith { }
            Mock Dism\Enable-WindowsOptionalFeature -ParameterFilter { $LogLevel -eq 'Errors' } -MockWith { }
            
            Set-TargetResource -Name $testFeatureName -LogLevel ErrorsOnly

            Assert-MockCalled Dism\Enable-WindowsOptionalFeature -ParameterFilter { $LogLevel -eq 'Errors' } -Scope It
        }

        It 'Calls "Enable-WindowsOptionalFeature" with "Warnings" logging level when "Present"' {
            Mock ValidatePrerequisites -MockWith { }
            Mock Dism\Enable-WindowsOptionalFeature -ParameterFilter { $LogLevel -eq 'Warnings' } -MockWith { }
            
            Set-TargetResource -Name $testFeatureName -LogLevel ErrorsAndWarning

            Assert-MockCalled Dism\Enable-WindowsOptionalFeature -ParameterFilter { $LogLevel -eq 'Warnings' } -Scope It
        }
        
        It 'Calls "Enable-WindowsOptionalFeature" without "LimitAccess" by default when "Present"' {
            Mock ValidatePrerequisites -MockWith { }
            Mock Dism\Enable-WindowsOptionalFeature -ParameterFilter { $LimitAccess -eq $null } -MockWith { }

            Set-TargetResource -Name $testFeatureName

            Assert-MockCalled Dism\Enable-WindowsOptionalFeature -ParameterFilter  { $LimitAccess -eq $null } -Scope It
        }
        
        It 'Calls "Enable-WindowsOptionalFeature" with "LimitAccess" when NoWindowsUpdateCheck is specified' {
            Mock ValidatePrerequisites -MockWith { }
            Mock Dism\Enable-WindowsOptionalFeature -ParameterFilter { $LimitAccess -eq $true } -MockWith { }

            Set-TargetResource -Name $testFeatureName -NoWindowsUpdateCheck $true

            Assert-MockCalled Dism\Enable-WindowsOptionalFeature -ParameterFilter  { $LimitAccess -eq $true } -Scope It
        }

        It 'Calls "Disable-WindowsOptionalFeature" with default "WarningsInfo" logging level when "Absent"' {
            Mock ValidatePrerequisites -MockWith { }
            Mock Dism\Disable-WindowsOptionalFeature -ParameterFilter { $LogLevel -eq 'WarningsInfo' } -MockWith { }
            
            Set-TargetResource -Name $testFeatureName -Ensure Absent;

            Assert-MockCalled Dism\Disable-WindowsOptionalFeature -ParameterFilter { $LogLevel -eq 'WarningsInfo' } -Scope It
        }

        It 'Calls "Disable-WindowsOptionalFeature" with "NoRestart" when "Absent"' {
            Mock ValidatePrerequisites -MockWith { }
            Mock Dism\Disable-WindowsOptionalFeature -ParameterFilter { $NoRestart -eq $true } -MockWith { }

            Set-TargetResource -Name $testFeatureName -Ensure Absent;

            Assert-MockCalled Dism\Disable-WindowsOptionalFeature -ParameterFilter  { $NoRestart -eq $true } -Scope It
        }

        It 'Calls "Disable-WindowsOptionalFeature" with "Online" when "Absent"' {
            Mock ValidatePrerequisites -MockWith { }
            Mock Dism\Disable-WindowsOptionalFeature -ParameterFilter { $Online -eq $true } -MockWith { }
            
            Set-TargetResource -Name $testFeatureName -Ensure Absent;

            Assert-MockCalled Dism\Disable-WindowsOptionalFeature -ParameterFilter { $Online -eq $true } -Scope It
        }

        It 'Calls "Disable-WindowsOptionalFeature" with "Remove" when "Absent" and "RemoveFilesOnDisable"' {
            Mock ValidatePrerequisites -MockWith { }
            Mock Dism\Disable-WindowsOptionalFeature -ParameterFilter { $Remove -eq $true } -MockWith { }
            
            Set-TargetResource -Name $testFeatureName -Ensure Absent -RemoveFilesOnDisable $true;

            Assert-MockCalled Dism\Disable-WindowsOptionalFeature -ParameterFilter { $Remove -eq $true } -Scope It
        }
    }

    }
}
finally
{
    Suite.AfterAll
}

