<#
Augthor:  Bryan Cafferky   2014-01-03

Purpose:  Define C# functions that can be called by PowerShell.

#>

$file = 'C:\Users\BryanCafferky\Documents\BI_UG\PowerShell\Examples\CS\ufn_basic_calc.cs'
$source = [System.IO.File]::ReadAllText($file)
Add-Type -TypeDefinition $source

# Example Calls:

# <#
[BasicTest]::Add(4, 3)
$basicTestObject = New-Object BasicTest 
$basicTestObject.Multiply(5, 2)
# #>