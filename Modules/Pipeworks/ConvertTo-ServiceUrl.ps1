﻿function ConvertTo-ServiceUrl
{
    <#
    .Synopsis
        Converts parameters into a full URL for a Pipeworks Service
    .Description
        Converts parameters into a full URL for a Pipeworks web service.  
        
        This allows you to easily call another a Pipeworks web service with a uniform URL.

        This can work because all Pipeworks services have a very uniform URL format:

        ServiceUrl/Command/?Command_Parameter1=Value&Command_Parameter2=Value
    #>
    
    param(
    [Parameter(Position=0,ValueFromPipelineByPropertyName=$true)]
    [Uri]
    $ServiceUrl,

    # The name of the command in the Pipeworks module.
    [Parameter(Mandatory=$true,Position=1,ValueFromPipelineByPropertyName=$true)]
    [string]
    $CommandName,

    # The name of the command in the Pipeworks module.
    [Parameter(Mandatory=$true,Position=2,ValueFromPipelineByPropertyName=$true)]
    [Alias('Parameters')]
    [Hashtable]    
    $Parameter,

    # If set, will get a URL to return the XML
    [switch]
    $AsXml

  
    )

    process {
        # Carry over the parameters 
        $actionUrl  = foreach ($kv in $Parameter.GetEnumerator()) {
            "${CommandName}_$($kv.Key)=$([Web.HttpUtility]::UrlEncode($kv.Value))"
        }

        $actionUrl  = "/${CommandName}/?" + ($actionUrl -join '&')


        if ($AsXml) {
            $actionUrl  += "&AsXml=true"
        }
        if ($ServiceUrl) {
            $actionUrl   = "$ServiceUrl".TrimEnd("/") + $actionUrl
        }

        $actionUrl
    }
}