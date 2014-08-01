<#
Author:  Bryan Cafferky  2013-01-03

Purpose:  Demonstrat a simple framework for calling C# functions from a PowerShell script/
#>

# First, call a POwerShell function that in turn defines the C# functions for your use.

. C:\Users\BryanCafferky\Documents\BI_UG\PowerShell\Examples\Function\ufn_csharp_functions.ps1

$basicTestObject = New-Object BasicTest 
$basicTestObject.Multiply(5, 2)