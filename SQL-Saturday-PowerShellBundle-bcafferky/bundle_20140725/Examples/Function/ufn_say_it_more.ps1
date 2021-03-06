
# Author:  Bryan Cafferky      Date:  2013-11-29
# 
# Purpose:  Speaks the input...
#
#

function ufn_say_it([string] $speakit)
{ 
#  Fun using SAPI - the text to speech thing....    

$speaker = new-object -com SAPI.SpVoice

$voiceList = $speaker.GetVoices()

$voiceDescList = @()

for ($i=0; $i -lt $voiceList.Count; $i++)
{
$voiceDescList += $voiceList.Item($i).GetDescription()
}

if ($voiceDescList -contains "LH Michelle")
{
$voiceMember = "Name=LH Michelle"
}
else
{
# This is the default voice if LH Michelle doesn't exist.

# This will probably be Microsoft Sam

$voiceMember = "Name=" + $voiceDescList[0]

}

$voiceToUse = $speaker.GetVoices($voiceMember)

# This sets the voice property on the COM object

$speaker.Voice = $voiceToUse.Item(1)

Read more: http://www.ehow.com/how_10073764_speak-different-voices-powershell.html#ixzz2nrEjjEAG


$speaker.Speak($speakit, 1) | out-null

}

# Example Call:
#                 ufn_say_it 'Good day to you!'  






