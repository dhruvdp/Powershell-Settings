#  Author:  Bryan Cafferky   2013-12-15
#
# Purpose:  Demo load a flat csv file into a SQL Server table on the fly.
#
#     

. C:\Users\BryanCafferky\Documents\BI_UG\PowerShell\Examples\Function\ufn_database_functions

$tablename = read-host "Enter name for table: "
$filepath = 'C:\Users\BryanCafferky\Documents\BI_UG\PowerShell\Examples\Data\infile.csv'
$conn = 'Server=localhost;Database=AdventureWorks;Trusted_Connection=True;'

ufn_load_file_into_table -verbose  $conn $tablename  $filepath  -isSQLServer -Drop
 