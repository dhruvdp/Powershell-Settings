# Author:  Bryan Cafferky   2013-12-15
#
# Purpose:  Use a function that calls SAPI to convert text to speech.
#
# Fun using SAPI - the text to speech thing....    

#  Use the dot notation to get the function loaded into memory...
. C:\Users\BryanCafferky\Documents\BI_UG\PowerShell\Examples\function\ufn_say_it.ps1
. C:\Users\BryanCafferky\Documents\BI_UG\PowerShell\Examples\Function\ufn_Get_Winform_FileName.ps1

# Say what I tell you...
$speak = Read-Host "Enter what you want me to say: " 
ufn_say_it $speak

# I'm too lazy to read so...
Set-Location "C:\Users\BryanCafferky\Documents\BI_UG\PowerShell\Examples\"

$speak = dir
ufn_say_it $speak

" Four score and seven years ago our fathers brought forth on this continent, a new nation, conceived in Liberty, and dedicated to the proposition that all men are created equal.
Now we are engaged in a great civil war, testing whether that nation, or any nation so conceived and so dedicated, can long endure. We are met on a great battle-field of that war. We have come to dedicate a portion of that field, as a final resting place for those who here gave their lives that that nation might live. It is altogether fitting and proper that we should do this.
But, in a larger sense, we can not dedicate -- we can not consecrate -- we can not hallow -- this ground. The brave men, living and dead, who struggled here, have consecrated it, far above our poor power to add or detract. The world will little note, nor long remember what we say here, but it can never forget what they did here. It is for us the living, rather, to be dedicated here to the unfinished work which they who fought here have thus far so nobly advanced. It is rather for us to be here dedicated to the great task remaining before us -- that from these honored dead we take increased devotion to that cause for which they gave the last full measure of devotion -- that we here highly resolve that these dead shall not have died in vain -- that this nation, under God, shall have a new birth of freedom -- and that government of the people, by the people, for the people, shall not perish from the earth.

Abraham Lincoln
November 19, 1863"  > "C:\Users\BryanCafferky\Documents\BI_UG\PowerShell\getty.txt"

$speak = Get-Content C:\Users\BryanCafferky\Documents\BI_UG\PowerShell\getty.txt 
ufn_say_it $speak

# Select a file to be read.. 
 $infile = ufn_Get_Winform_FileName -initialDirectory "C:\Users\BryanCafferky\Documents\BI_UG\PowerShell\Examples\Data\Text"
 $say_stuff = Get-Content $infile
 ufn_say_it $say_stuff
 





