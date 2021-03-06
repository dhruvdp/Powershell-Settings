function Import-PSData
{
    <#
    .Synopsis
        Imports PSData sections
    .Description
        Imports files or strings containing PSData sections, and converts nested hashtables into nested PSObjects.
    .Example
        Get-Web -Url http://www.youtube.com/watch?v=xPRC3EDR_GU -AsMicrodata -ItemType http://schema.org/VideoObject | 
            Export-PSData .\PipeworksQuickstart.video.psd1
    .Example
        @{a="b";c=@{d="E"}} | 
            Import-PSData | 
            Select-Object -ExpandProperty c | 
            Select-Object -ExpandProperty D
    .Link
        Export-PSData
    #>
    
    [CmdletBinding(DefaultParameterSetName='FromFile')]  
    param(
    # A file containing PSData
    [Parameter(Mandatory=$true,
        Position=0,
        ParameterSetName='FromFile',
        ValueFromPipelineByPropertyName=$true)]
    [Alias('Fullname')]
    [string]$FilePath,
    
    # A string in data language mode.  
    [Parameter(Mandatory=$true,
        ParameterSetName='FromString',
        ValueFromPipeline=$true,
        ValueFromPipelineByPropertyName=$true)]
    [string]$DataString,

    # A compressed string
    [Parameter(Mandatory=$true,
        ParameterSetName='FromCompressedString',
        ValueFromPipeline=$true,
        ValueFromPipelineByPropertyName=$true)]
    [string]$CompressedString,
    
    # A hashtable
    [Parameter(Mandatory=$true,
        ParameterSetName='FromHashtable',
        ValueFromPipeline=$true,
        ValueFromPipelineByPropertyName=$true)]
    [Hashtable]$Hashtable,
    
    # Any commands allowed in the file, string, or compressedstring
    [Parameter(ParameterSetName='FromFile',
        ValueFromPipelineByPropertyName=$true)]
    [Parameter(ParameterSetName='FromCompressedString',
        ValueFromPipelineByPropertyName=$true)]
    [Parameter(ParameterSetName='FromHashtable',
        ValueFromPipelineByPropertyName=$true)]
    [string[]]$AllowCommand
    )
    
    process {
        if ($psCmdlet.ParameterSetName -eq 'FromFile') {
            foreach ($resolvedFile in $ExecutionContext.SessionState.Path.GetResolvedPSPathFromPSPath($FilePath)) {
                $DataString = [IO.File]::ReadAllText($resolvedFile)
            }
        } elseif ($psCmdlet.ParameterSetName -eq 'FromCompressedString') {
            try {
                $DataString = Expand-Data -CompressedData $CompressedString
            } catch {
            }
        }
        
        $supportedCommandSection = if ($allowCommand ){
            "-supportedCommand $($allowCommand -join ',')"  
        } else {
            ""
        }
        
        if ('FromFile', 'FromString' -contains $psCmdlet.ParameterSetName) {
        
        
            $dataScriptBlock = [ScriptBlock]::Create($DataString)
            $dataLanguageScriptBlock = [ScriptBlock]::Create("data $supportedCommandSection { $dataScriptBlock }")
            foreach ($result in (& $dataLanguageScriptBlock)) {
                if ($result -is [Hashtable]) {
                    Import-PSData -Hashtable $result 
                } else {
                    $result
                }     
            }
        }
        
        if ($psCmdlet.ParameterSetName -eq 'FromHashtable') {
            $Objectcopy = @{} + $Hashtable
            if ($Objectcopy.PSTypeName) {
                $ObjecttypeName = $Objectcopy.PSTypeName
                $Objectcopy.Remove('PSTypeName')
            }
            
            foreach ($kv in @($Objectcopy.GetEnumerator())) {
                if ($kv.Value -is [Hashtable]) {
                    $Objectcopy[$kv.Key] = Import-PSData -Hashtable $hashtable[$kv.Key]
                } elseif ($kv.Value -as [Hashtable[]]) {
                    $Objectcopy[$kv.Key] = foreach ($ht in $kv.Value) {
                        Import-PSData -Hashtable $ht
                    } 
                }
            }
            
            
            New-Object PSObject -Property $Objectcopy | 
                ForEach-Object {                
                    $_.pstypenames.clear()
                    foreach ($inTypeName in $ObjecttypeName) {
                        if (-not $inTypeName) {continue }
                        
                        $null = $_.pstypenames.add($inTypeName)
                    }
                    if (-not $_.pstypenames) {
                        $_.pstypenames.add('PropertyBag')
                    }
                    $_
                }
        }
        
        
        
    }
} 
