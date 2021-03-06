function Start-PSNode
{
    <#
    .Synopsis
        Starts a lightweight local server
    .Description
        Starts a lightweight local server that uses the HttpListener class to create a simple server.  
        
        This server is unlike the Pipeworks in ASP.NET in many interesting ways:
        
        - Unlike Pipeworks within ASP.NET which lets each user have their own runspace, PSNode puts all users in the same runspace.  
        This makes it faster, and means all people connected share a lot of the same information (for better and worse).  
        Additionally, this runspace does not contain any modules, but can load any modules you have.
        - Unlike Pipeworks within ASP.NET, which runs in an Application Pool as the context of that restricted user, PSNode is always running as you and under and administrative account.
        This means a lot.  On the good side, it means you can do things ASP.NET cannot, like popping up a window on the desktop.  On the darker side, it means that if you allow arbitrary code execution in what you put up on PSNode, you have an endpoint that can do anything to a box in the context of the current user.
        - Unlike Pipeworks within ASP.NET, PSNode runs in any .exe
        This also means a lot.  
        PSNode may run within any process, and, because it is running in a process, certain components that require a permission associated with an interactive process will execute in PSNode and not in Pipeworks under ASP.NET    
    
    
        PSNode was inspired by a presentation from Bruce Payette at the PowerShell Deep Dive @ TEC2011 in Frankfurt, Germany
    .Example
        Start-PSNode -Server http://localhost:9097/ -Command {
            "Hello World"
        }
    .Example
        Start-PSNode -Server http://localhost:9092/ -AuthenticationType IntegratedWindowsAuthentication -Command {
            "Hello $($User.Identity.Name)"
        }    
    #>
    [OutputType([Management.Automation.Job])]    
    param(
    # The server url, ie. http://localhost:9090/
    [Parameter(Mandatory=$true,ValueFromPipelineByPropertyName=$true)]
    [string]$Server,
    
    # The command to run within the server
    [Parameter(Mandatory=$true,ValueFromPipelineByPropertyName=$true)]   
    [ScriptBlock]$Command,
    
    # The authentication type
    [Net.AuthenticationSchemes]
    $AuthenticationType = "Anonymous", 
    
    # If set, will not return
    [Switch]$DoNotReturn,

    [Switch]$AsService
    )

    begin {
        $ll = @()
        $lc  = @()

        $definePSNode = {
        Add-Type -IgnoreWarnings @'
using System;
using System.Collections.Generic;
using System.Text;
using System.Net;
using System.Management.Automation;
using System.Management.Automation.Runspaces;
using System.Threading;
using System.Security.Principal;

public class PSNode
{
    RunspacePool Pool
    {
        get
        {
            if (_pool == null)
            {
                InitialSessionState iss = InitialSessionState.CreateDefault();
                //Embed
                _pool = RunspaceFactory.CreateRunspacePool(iss);
                _pool.ThreadOptions = PSThreadOptions.ReuseThread;
                _pool.ApartmentState = System.Threading.ApartmentState.STA;
		        _pool.SetMaxRunspaces(7);                
                _pool.Open();
            }
            return _pool;
        }
    }
    RunspacePool _pool;
    ScriptBlock action;
    
    private PSNode(ScriptBlock command)
    {
        WindowsIdentity current = System.Security.Principal.WindowsIdentity.GetCurrent();
        WindowsPrincipal principal = new WindowsPrincipal(current);
        if (!principal.IsInRole(WindowsBuiltInRole.Administrator))
        {
            throw new UnauthorizedAccessException();
        }

        this.action = command;        
    }
    
    
        
    public static AsyncCallback GetCallback(ScriptBlock action)
    {
        PSNode instance = new PSNode(action);
        
        return new AsyncCallback(instance.ListenerCallback);
    }

    public void ListenerCallback(IAsyncResult result)
    {
        try
        {
            HttpListener listener = (HttpListener)result.AsyncState;

            // Call EndGetContext to complete the asynchronous operation.        
            HttpListenerContext context = listener.EndGetContext(result);
            HttpListenerRequest request = context.Request;

            // Obtain a response object.
            HttpListenerResponse response = context.Response;

            string responseString = "";
            using (
                PowerShell command = PowerShell.Create()
                                            .AddScript(action.ToString(), false)
                                                .AddArgument(request)
                                                    .AddArgument(response)
                                                        .AddArgument(context)
                                                            .AddArgument(context.User)
            )
            {
                command.RunspacePool = Pool;
                
                int offset = 0;

                try
                {
                    foreach (PSObject psObject in command.Invoke<PSObject>())
                    {
                        if (psObject.BaseObject == null) { continue; }
                        byte[] buffer = System.Text.Encoding.UTF8.GetBytes(psObject.ToString());
                        response.OutputStream.Write(buffer, offset, buffer.Length);
                        offset += buffer.Length;
                    }                    
                }
                catch (Exception ex)
                {
                    byte[] buffer = System.Text.Encoding.UTF8.GetBytes(ex.Message);
                    response.StatusCode = 500;
                    response.OutputStream.Write(buffer, offset, buffer.Length);
                    offset += buffer.Length;
                }
                finally
                {
                    response.Close();
                }
            }
        }
        catch (Exception e)
        {
        }
    }


}
'@    
}
        $FunctionsInEveryRunspace = 'ConvertFrom-Markdown', 'Confirm-Person', 'Get-Person', 'Get-Web', 'Get-PipeworksManifest', 'Get-WebConfigurationSetting', 'Get-FunctionFromScript', 'Get-Walkthru', 
    'Get-WebInput', 'New-RssItem', 'Invoke-WebCommand', 'Out-RssFeed', 'Request-CommandInput', 'New-Region', 'New-WebPage', 'Out-Html', 
    'Write-Css', 'Write-Host', 'Write-Link', 'Write-ScriptHTML', 'Write-WalkthruHTML', 'Write-PowerShellHashtable', 'Compress-Data', 
    'Expand-Data', 'Import-PSData', 'Export-PSData', 'ConvertTo-ServiceUrl', 'Get-SecureSetting', 'Search-Engine', 'Get-Hash'

        $embedSection = Get-Command -Module Pipeworks -Name $FunctionsInEveryRunspace -CommandType Function | 
        ForEach-Object {
        $func = $_;  
@"
        byte[] base64$($func.Name.Replace('-', '')) = Convert.FromBase64String("$([Convert]::ToBase64String([Text.Encoding]::Unicode.GetBytes($func.Definition.ToString())))");
        string $($func.Name.Replace('-', ''))definition = Encoding.Unicode.GetString(base64$($func.Name.Replace('-', '')));
        SessionStateFunctionEntry $($func.Name.Replace('-',''))Command = new SessionStateFunctionEntry("$($func.Name)", $($func.Name.Replace('-', ''))definition);
        iss.Commands.Add($($func.Name.Replace('-',''))Command);
"@ }
        $embedSection  = $embedSection  -join ([Environment]::NewLine)
        $definePSNode = [ScriptBlock]::Create($definePSNode.ToString().Replace("//Embed", $embedSection))
        
    }

    process {
        $listeners = [Net.NetworkInformation.IPGLobalProperties]::GetIPGlobalProperties().GetActiveTcpListeners()       
        $port = ([uri]"$("$Server".Replace("*", "localhost"))").Port
        $activeListener = $listeners | Where-Object { $_.Port -eq $port }

        if ($activeListener) {
            Write-Error "Port $Port occupied"
            return
        }
        $listenerLocation = $server
        if ($listenerLocation -notlike "*/") {
            $listenerLocation += "/"
        }
        $ListenerCommand = $command
        
        $ll += $listenerLocation
        $lc += $listenerCommand
    } 

    end {
        $StartTime  =Get-Date
        
        $node = for ($i = 0; $i -lt $ll.Count; $i++) {
            $listenerLocation = $ll[$i]
            $listenerCommand = $lc[$i]
            
            $fullScript = "" + {
param($listenerLocation, $listenerCommand, $AuthenticationType) 
            } + (@(
$FunctionsInEveryRunspace = 'ConvertFrom-Markdown', 'Confirm-Person', 'Get-Person', 'Get-Web', 'Get-PipeworksManifest', 'Get-WebConfigurationSetting', 'Get-FunctionFromScript', 'Get-Walkthru', 
    'Get-WebInput', 'New-RssItem', 'Invoke-WebCommand', 'Out-RssFeed', 'Request-CommandInput', 'New-Region', 'New-WebPage', 'Out-Html', 
    'Write-Css', 'Write-Host', 'Write-Link', 'Write-ScriptHTML', 'Write-WalkthruHTML', 'Write-PowerShellHashtable', 'Compress-Data', 
    'Expand-Data', 'Import-PSData', 'Export-PSData', 'ConvertTo-ServiceUrl', 'Get-SecureSetting', 'Search-Engine', 'Get-Hash'            
    Get-Command -Name $FunctionsInEveryRunspace -CommandType Function | 
        ForEach-Object {
"
function $($_.Name) 
{
    $($_.Definition)
}
"        
        }


            ) -join ([Environment]::NewLine)) + {
                # Create a listener and add the prefixes.
                $listener = New-Object System.Net.HttpListener
                $listener.AuthenticationSchemes =$AuthenticationType
                $listener.Prefixes.Add($ListenerLocation);

                # Start the listener to begin listening for requests.
                $listener.Start();
                $callBack = [PSNode]::GetCallback(
                    [ScriptBLock]::create('param($request, $response, $context, $user)
                    $inPsNode = $true
                    if (-not $functionsRegistered) { 
                        $null = New-Module -Name Pipeworks { 
                    ' + (@(
$FunctionsInEveryRunspace = 'ConvertFrom-Markdown', 'Confirm-Person', 'Get-Person', 'Get-Web', 'Get-PipeworksManifest', 'Get-WebConfigurationSetting', 'Get-FunctionFromScript', 'Get-Walkthru', 
    'Get-WebInput', 'New-RssItem', 'Invoke-WebCommand', 'Out-RssFeed', 'Request-CommandInput', 'New-Region', 'New-WebPage', 'Out-Html', 
    'Write-Css', 'Write-Host', 'Write-Link', 'Write-ScriptHTML', 'Write-WalkthruHTML', 'Write-PowerShellHashtable', 'Compress-Data', 
    'Expand-Data', 'Import-PSData', 'Export-PSData', 'ConvertTo-ServiceUrl', 'Get-SecureSetting', 'Search-Engine', 'Get-Hash'            
    Get-Command -Name $FunctionsInEveryRunspace -CommandType Function | 
        ForEach-Object {
"
function $($_.Name) 
{
    $($_.Definition)
}
"        
        }


            ) -join ([Environment]::NewLine)) +'

                        }
                        $functionsRegistered = $true
                        
                    }
                    
                    
                    
                    
                    if ("$($request.QueryString)") {        
                        $query = ([uri]$request.RawUrl -split "/")[-1]                
                        $query.TrimStart("?") -split "&" |
                            ForEach-Object -Begin {
                                $requestParams = @{}
                            } -Process { 
                                $key, $value = $_ -split "="
                                $requestParams[[Web.HttpUtility]::UrlDecode($key)] = [Web.HttpUtility]::UrlDecode($value)
                            } -End {
                                $request | 
                                    Add-Member NoteProperty Params $RequestParams -Force 
                            }                                
                    }
                ' + $ListenerCommand)) 

                if (-not $callback) { return } 

                while (1)
                {
                    $result = $listener.BeginGetContext($callback, $listener);    
                    if (-not $result) { break } 
                    $null = $result.AsyncWaitHandle.WaitOne();    
                }

                $listener.Close()  
                $listener.Dispose()          
            
            }


            $fullScript = [ScriptBLock]::Create($fullScript)

            $fullBase = "$((('' + 
        $definePSNode + 
        [Environment]::newline +
        "
`$scriptArgs = @(
@'
$listenerLocation
'@, @'
$listenerCommand
'@, '$AuthenticationType'
)
& { $FullScript } @scriptArgs")))"
            $fullBase64 = [Convert]::ToBase64String([Text.Encoding]::Unicode.getbytes($fullBase))

            $compressedBase64 = Compress-Data -String $fullBase



            if ($asService) {
            

$serviceCode = @"
using System;
using System.ServiceProcess;
using System.Threading;
using System.ComponentModel;
using System.Configuration.Install;
using System.Management.Automation;
using System.Text;
 
public class PSNodeService : ServiceBase
{
   
   public PSNodeService()
   {
      this.ServiceName = "PSNode$Port";
      this.CanStop = true;
      this.CanPauseAndContinue = false;
      this.AutoLog = true;
   }

   PowerShell psNodeCommand;
   IAsyncResult operation;
   
 
   protected override void OnStart(string [] args)
   {
      byte[] byteArr = Convert.FromBase64String("$fullBase64");
      
      string powerShellScript = Encoding.Unicode.GetString(byteArr);

      psNodeCommand =PowerShell.Create();
      psNodeCommand.AddScript(powerShellScript, false);
      operation = psNodeCommand.BeginInvoke();
      psNodeCommand.Streams.Error.DataAdded+=new EventHandler<DataAddedEventArgs>(Error_DataAdded);
   }

   void Error_DataAdded(object sender, DataAddedEventArgs e) {
        System.Diagnostics.Process process = System.Diagnostics.Process.GetCurrentProcess();

        PSDataCollection<ErrorRecord> collection = sender as PSDataCollection<ErrorRecord>;
        ErrorRecord err = collection[e.Index];

        string errOut = System.DateTime.Now.ToString("o") + " " + err.Exception.Message + Environment.NewLine;

        System.IO.File.AppendAllText(process.MainModule.FileName.Replace(".exe", "") + ".error.out",errOut);
   }
 
   protected override void OnStop()
   {
      psNodeCommand.BeginStop(StopDone, null);
   }

   public void StopDone(IAsyncResult result) {
   
   }
 
   public static void Main()
   {
      System.ServiceProcess.ServiceBase.Run(new PSNodeService());
   }

    
}
"@
            $servicePath = 
                if (-not $PSBoundParameters.ServicePath) {
                    $psNodeRoot = Join-Path $env:APPDATA "PSNodeServices"
                    if (-not (Test-Path $psNodeRoot)) {
                        $null = New-Item -ItemType Directory -Path $psNodeRoot -Force
                    }
                    "$(Join-Path $psNodeRoot "PSNode-Port$port.exe")"                    
                } else {
                    $servicePath
                }
            
                $svcExists = Get-WmiObject -Class Win32_Service -Filter "Name = 'PSNode$Port'"
                if ($svcExists) {
                    Stop-Service -Name "PSNode$Port"
                    $null = $svcExists.Delete()
                    
                }
                #
                Add-Type -TypeDefinition $serviceCode -ReferencedAssemblies System.Management.Automation, System.ServiceProcess, System.Configuration.Install -OutputAssembly $servicePath -OutputType WindowsApplication

                if ($svcExists) {
                    Start-Service -Name "PSNode$port"
                } else {
                                    
                    $newService = New-Service -Name "PSNode$Port" -DisplayName "PSNode - Running on Port $port" -BinaryPathName $servicePath -StartupType Automatic

                    $svcExists = Get-WmiObject -Class Win32_Service -Filter "Name = 'PSNode$Port'"
                    if ($svcExists) {
                        $null = $svcExists.StartService()
                    }
                }

            } else {
                $jobScriptBlock = "
function Expand-Data
{
    $((Get-Command -Name Expand-Data).Definition)
}

`$scriptToRun = 
Expand-Data -CompressedData @'
$compressedBase64
'@

& ([ScriptBlock]::Create(`$scriptToRun))
"
                $jobScriptBlock = [ScriptBlock]::Create($jobScriptBlock)
                Start-Job -Name $listenerLocation -ScriptBlock $jobScriptBlock
            }

            
        }
         
        
        if ($DoNotReturn) {
            do {
                Write-Progress "Pipeworks PSNode Running on $ListenerLocation" "Since $StartTime" 
                $node | Receive-Job
                Start-Sleep -Seconds 1 
            } while(1)
            return   
        }        
        
        
        $node
        

    }

} 
