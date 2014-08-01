param([switch]$clean)

#region PowerShell tools
. $psScriptRoot\Get-FunctionFromScript.ps1
. $psScriptRoot\Write-PowerShellHashtable.ps1
. $psScriptRoot\Import-PSData.ps1
. $psScriptRoot\Export-PSData.ps1

#endregion

#region Pipeworks General Tools 
. $psScriptRoot\Get-Web.ps1
. $psScriptRoot\Get-PipeworksManifest.ps1
. $psScriptRoot\New-PipeworksManifest.ps1
#endregion


#region Login System Commands
. $psScriptRoot\Get-Person.ps1
. $psScriptRoot\Join-Website.ps1
. $psScriptRoot\Confirm-Person.ps1
. $psScriptRoot\Add-Interaction.ps1
#endregion

#region Core Web Commands
. $psScriptRoot\Invoke-WebCommand.ps1

. $psScriptRoot\ConvertFrom-Markdown.ps1
. $psScriptRoot\Compress-Data.ps1
. $psScriptRoot\Expand-Data.ps1
. $psScriptRoot\Get-Walkthru.ps1
. $psScriptRoot\Get-WebConfigurationSetting.ps1
. $psScriptRoot\Get-WebInput.ps1
. $psScriptRoot\New-Region.ps1
. $psScriptRoot\New-RssItem.ps1
. $psScriptRoot\New-WebPage.ps1
. $psScriptRoot\Out-HTML.ps1                                                                                                                                                      
. $psScriptRoot\Out-RSSFeed.ps1
. $psScriptRoot\Request-CommandInput.ps1

. $psScriptRoot\Send-Email.ps1
. $psScriptRoot\Write-WalkthruHtml.ps1
. $psScriptRoot\Write-Ajax.ps1
. $psScriptRoot\Write-Css.ps1
. $psScriptRoot\Write-Host.ps1
. $psScriptRoot\Write-Link.ps1
. $psScriptRoot\Write-ScriptHtml.ps1 
#endregion Core Web Commands

#region ASP & HTML code Generators
. $psScriptRoot\ConvertFrom-InlinePowerShell.ps1
# . $psScriptRoot\ConvertTo-CommandService.ps1
. $psScriptRoot\ConvertTo-ModuleService.ps1
. $psScriptRoot\Write-AspNetScriptPage.ps1
#endregion

#region Mini Servers and their deploy tools
. $psScriptRoot\Start-PSNode.ps1
. $psScriptRoot\Open-Port.ps1
. $psScriptRoot\Close-Port.ps1
. $psScriptRoot\Install-PSNode.ps1
#endregion Mini Servers and their deploy tools

#region Daemons

. $psScriptRoot\Out-Daemon.ps1
. $psScriptRoot\Remove-Daemon.ps1
. $psScriptRoot\Watch-Daemon.ps1

#endregion Daemons


#region Azure Tools
. $psScriptRoot\Add-AzureRole.ps1
. $psScriptRoot\Add-AzureLocalResource.ps1
. $psScriptRoot\Add-AzureSetting.ps1
. $psScriptRoot\Add-AzureStartupTask.ps1
. $psScriptRoot\Add-AzureWebSite.ps1

. $psScriptRoot\New-AzureServiceDefinition.ps1

. $psScriptRoot\Out-AzureService.ps1

. $psScriptRoot\Publish-AzureService.ps1


. $psScriptRoot\Get-Blob.ps1
. $psScriptRoot\Import-Blob.ps1
. $psScriptRoot\Export-Blob.ps1
. $psScriptRoot\Remove-Blob.ps1
#endregion Azure Tools



. $psScriptRoot\Get-Email.ps1

. $psScriptRoot\Send-TextMessage.ps1
. $psScriptRoot\Get-TextMessage.ps1
. $psScriptRoot\Get-PhoneCall.ps1
. $psScriptRoot\Send-PhoneCall.ps1


. $psScriptRoot\Out-Zip.ps1
. $psScriptRoot\Expand-Zip.ps1


#region Storage Tools

. $psScriptRoot\Write-CRUD.ps1
. $psScriptRoot\Show-WebObject.ps1

#endregion Storage Tools

#region SQL Tools
. $psScriptRoot\Select-SQL.ps1
. $psScriptRoot\Add-SQLTable.ps1
. $psScriptRoot\Get-SQLTable.ps1
. $psScriptRoot\Update-SQL.ps1
. $psScriptRoot\Remove-SQL.ps1
. $psScriptRoot\New-SQLDatabase.ps1
. $psScriptRoot\Copy-Sql.ps1
#endregion SQL Tools

#region Secure Scripting Tools
. $psScriptRoot\Add-SecureSetting.ps1
. $psScriptRoot\Get-SecureSetting.ps1
. $psScriptRoot\Remove-SecureSetting.ps1
#endregion Secure Scripting Tools


#region FTP Tools
. $psScriptRoot\Get-FTP.ps1
. $psScriptRoot\Push-FTP.ps1
#endregion FTP Tools

#region Deployment Tools
. $psScriptRoot\Add-Deployment.ps1
. $psScriptRoot\Get-Deployment.ps1
. $psScriptRoot\Import-Deployment.ps1
. $psScriptRoot\Switch-TestDeployment.ps1

. $psScriptRoot\Publish-Deployment.ps1
. $psScriptRoot\Push-Deployment.ps1
. $psScriptRoot\Remove-Deployment.ps1
. $psScriptRoot\Wait-Deployment.ps1
#endregion Deployment Tools

#region Kitchen Sink
. $psScriptRoot\Get-Paid.ps1
. $psScriptRoot\Get-Bootstrapped.ps1
. $psScriptRoot\Get-Hash.ps1
. $psScriptRoot\Get-Translation.ps1

. $psScriptRoot\Find-Factual.ps1
. $psScriptRoot\Invoke-Office365.ps1
. $pSScriptRoot\New-RDPFile.ps1
. $pSScriptRoot\Start-At.ps1
. $psScriptRoot\Resolve-Location.ps1


. $psScriptRoot\Search-WolframAlpha.ps1
. $psScriptRoot\Search-Engine.ps1


. $psScriptRoot\Start-MapReduce.ps1


. $psScriptRoot\Use-Schematic.ps1
. $psScriptRoot\ConvertTo-ServiceUrl.ps1
. $psScriptRoot\Publish-WebService.ps1

. $psScriptRoot\test-w3c.ps1

. $psScriptRoot\Get-WebTemplateEditableRegion.ps1


. $psScriptRoot\Select-WMI.ps1
. $psScriptRoot\Update-WMI.ps1

. $psScriptRoot\Use-Less.ps1
#endregion Kitchn Sink



#region Initialize Shared Data
$script:FunctionsInEveryRunspace = 'ConvertFrom-Markdown', 'Confirm-Person', 'Get-Person', 'Get-Web', 'Get-PipeworksManifest', 'Get-WebConfigurationSetting', 'Get-FunctionFromScript', 'Get-Walkthru', 
    'Get-WebInput', 'New-RssItem', 'Invoke-WebCommand', 'Out-RssFeed', 'Request-CommandInput', 'New-Region', 'New-WebPage', 'Out-Html', 
    'Write-Css', 'Write-Host', 'Write-Link', 'Write-ScriptHTML', 'Write-WalkthruHTML', 'Write-PowerShellHashtable', 'Compress-Data', 
    'Expand-Data', 'Import-PSData', 'Export-PSData', 'ConvertTo-ServiceUrl', 'Get-SecureSetting', 'Search-Engine', 'Get-Hash'

#endregion
Add-Type -AssemblyName System.Web, System.Xml.Linq

$linq = [Reflection.Assembly]::LoadWithPartialName("System.Linq")
#region Compile or Import Azure Table Storage Cmdlets
$dllPath = "$psScriptRoot\AzureTableStorage.CLR$($psVersionTable.CLRVersion).dll"
$m = if ($Clean -or (-not (Test-Path $dllPath))){
    $files = Get-ChildItem $psScriptRoot\CSharp -Filter *Azure*.cs
    $fileContents = foreach ($f in $files) {
        [IO.File]::ReadAllText($f.Fullname)
    }
    
    $languageVersion = @{Language='CSharpVersion3'}
    if ($psVersionTable.CLRVersion -ge '4.0') {
        $languageVersion = @{}
    }


    if ($clean) {
        $languageVersion.OutputAssembly = "$dllPath" 
    }
    $linqLocation = [System.Linq.IQueryable].Assembly.Location
    $xlinqLocation = [System.Xml.Linq.XNamespace].Assembly.Location


    $systemWebLocation = Add-Type -AssemblyName System.Web -PassThru | Select-Object -ExpandProperty Assembly -Unique | Select-Object -ExpandProperty Location -Unique
    $refs = 
        if ($pslanguageTable.CLRVersion -lt '4.0') {
            'System.Xml', 'System.Net', $xlinqLocation,([Management.Automation.Languageprimitives].Assembly.Location), $systemWebLocation  -ne '' | Select-Object -Unique
        } else {
            'System.Xml', 'System.Net', $linqLocation, $xlinqLocation,([Management.Automation.Languageprimitives].Assembly.Location), $systemWebLocation  -ne '' | Select-Object -Unique
        }
    

    
    $m = Add-Type @languageVersion -ReferencedAssemblies $refs -TypeDefinition "
$($fileContents -join ([Environment]::NewLine))
" -PassThru | 
    Select-Object -ExpandProperty Assembly |
    Import-Module -PassThru
    if ($compilationIssues) { 
        $compilationIssues | Out-String | Write-Debug
    }
} else {
    Import-Module $dllPath -PassThru
}
#endregion

#region EC2
if (-not ('Amazon.Runtime.BasicAWSCredentials' -as [type])) {
    "$env:ProgramFiles", "${env:ProgramFiles(x86)}" -ne "" | 
        Get-ChildItem -Filter 'AWS SDK for .NET' | 
        Get-ChildItem -Filter 'bin'  |
        Get-ChildItem -Filter *.dll |
        Select-Object -First 1 |
        Import-Module -Name  {$_.Fullname } 
}

$clientTypes = 'Amazon.Route53.AmazonRoute53Client',
    'Amazon.ElasticMapReduce.AmazonElasticMapReduceClient',
    'Amazon.CloudFront.AmazonCloudFrontClient',
    'Amazon.ElasticLoadBalancing.AmazonElasticLoadBalancingClient',
    'Amazon.SimpleNotificationService.AmazonSimpleNotificationServiceClient',
    'Amazon.EC2.AmazonEC2Client',
    'Amazon.SimpleDB.AmazonSimpleDBClient',
    'Amazon.ElasticBeanstalk.AmazonElasticBeanstalkClient',
    'Amazon.DynamoDB.AmazonDynamoDBClient',
    'Amazon.IdentityManagement.AmazonIdentityManagementServiceClient',
    'Amazon.AutoScaling.AmazonAutoScalingClient',
    'Amazon.SQS.AmazonSQSClient',
    'Amazon.CloudFormation.AmazonCloudFormationClient',
    'Amazon.S3.AmazonS3Client' -as [type[]] 
    
$script:AmazonAccessKeySettingName = 'AwsAccessKeyId'
$script:AmazonSecretAccessKeySettingName = 'AmazonSecretAccessKey'

$script:AmazonAccessKey  = Get-SecureSetting -Name $script:AmazonAccessKeySettingName -ValueOnly

$script:AmazonSecretAccessKey = Get-SecureSetting -Name $script:AmazonSecretAccessKeySettingName  -ValueOnly


if ($script:AmazonAccessKey  -and $script:AmazonSecretAccessKey -and ('Amazon.Runtime.BasicAWSCredentials' -as [type])) {
    $script:AwsCredential = New-Object Amazon.Runtime.BasicAWSCredentials  $script:AmazonAccessKey, $script:AmazonSecretAccessKey
}


if ($script:AwsCredential) {
    $script:AwsConnections = $clientTypes | 
        ForEach-Object -Begin {
            $Connections = @{}
        } -process {
            
            $connections[$_.Name.Replace('Amazon', '').Replace('Client','')] = 
                New-Object $_.Fullname $script:AwsCredential.GetCredentials().AccessKey, $script:AwsCredential.GetCredentials().ClearSecretKey
            
        } -end {
            New-Object PSObject -Property $connections
        }
}

. $psScriptRoot\Set-AwsConnectionInfo.ps1

if ($script:AwsConnections) {


. $psScriptRoot\Add-EC2.ps1
. $psScriptRoot\Get-EC2.ps1
. $psScriptRoot\Reset-EC2.ps1

. $psScriptRoot\Get-Ami.ps1

. $psScriptRoot\Get-EC2InstancePassword.ps1

. $psScriptRoot\Get-EC2AvailabilityZone.ps1
. $psScriptRoot\Get-EC2SecurityGroup.ps1
. $psScriptRoot\Get-EC2KeyPair.ps1

. $psScriptRoot\Open-EC2Port.ps1

. $psScriptRoot\Remove-EC2.ps1
. $psScriptRoot\Remove-EC2KeyPair.ps1
. $psScriptRoot\Remove-EC2SecurityGroup.ps1

. $psScriptRoot\Enable-EC2Remoting.ps1

. $psScriptRoot\Wait-EC2.ps1

. $psScriptRoot\Connect-EC2.ps1

. $psScriptRoot\Invoke-EC2.ps1
} else {
    
}


Set-Alias cms ConvertTo-ModuleService
Set-Alias paz Publish-AzureService
Set-Alias pws Publish-WebService
Set-Alias Publish-WebSite Publish-WebServce
Set-Alias ieo365 Invoke-Office365 
Set-Alias wasp Write-AspDotNetScriptPage
Set-Alias psnode Start-PSNode
Set-Alias ohtml Out-HTML
Set-Alias markdown ConvertFrom-Markdown
Set-Alias gweb Get-Web
Set-Alias sql Select-SQL
Set-Alias iwc Invoke-WebCommand
Set-Alias impsd1 Import-PSData
Set-Alias expsd1 Export-PSData
Set-Alias imblob Import-Blob
Set-Alias exblob Export-Blob
Set-Alias text Send-TextMessage
Set-Alias txt Send-TextMessage
Set-Alias call Send-PhoneCall

Set-Alias gblob Get-Blob
Set-Alias rmblob Remove-Blob

Set-Alias Remove-Service -Value Remove-Daemon


Export-ModuleMember -Function * -Alias * -Cmdlet *


#endregion
