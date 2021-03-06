function Write-Host
{
    <#
    .ForwardHelpTargetName Write-Host
    .ForwardHelpCategory Cmdlet
    #>

    [CmdletBinding()]
    [OutputType([Nullable])]
    param(
    [Parameter(Position=0, ValueFromPipeline=$true, ValueFromRemainingArguments=$true)]
    [System.Object]
    ${Object},

    [Switch]
    ${NoNewline},

    [System.Object]
    ${Separator},

    [System.ConsoleColor]
    ${ForegroundColor},

    [System.ConsoleColor]
    ${BackgroundColor},
    
    [Switch]
    $AsHtml,
    
    # If set, will not transform the output in any other way.  If this is not set, the content is
    [Switch]
    $Simple)

    process {
        if ($AsHtml -or ($request -and $response) -or $host.Name -eq 'Default Host') {
            # Write as HTML
            $objectHtml = $Object
            
            $styleChunk = if ($ForegroundColor -or $backgroundColor)  {
                if ($ForegroundColor -and $backgroundcolor) {
                    " style='color:${ForeGroundColor};background=${BackgroundColor}'"
                } else {
                    if ($ForegroundColor) {
                        " style='color:${ForeGroundColor}'"
                    } else {
                        " style='background=${BackgroundColor}'"
                    }
                }
            } else {
                ""
            }
            $tag = "span"
            "<${tag}${styleChunk}>${ObjectHtml}</${tag}>$(if (-not $NoNewLine) {'<br/>'})"
        } else {
            Microsoft.PowerShell.Utility\Write-Host @psboundParameters
        }
    }
} 
