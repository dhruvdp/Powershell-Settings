@{
    Version = '0.8'
    Notes = @'
# Integrated with web.config app settings
'@    
},
@{
    Version = '0.9'
    Notes = @'
# Added Pages directory
* Default.ps1 or Default.html overide a default look and feel
* Created ConvertFrom-InlinePowerShell (to allow inline HTML syntax and easy .PS1 conversion)
* Made pages from a pages directory run in a module's context 
* Shared analytics and css style across site
'@    
},@{
    Version = '0.99' 
    Notes = @'    
# Incorporation of Other Web Technologies
## JQuery
* New-WebPage -UseJQuery will pull JQuery from a CDN
* New-WebPage -ContentDistributionNetwork (-CDN for short) will select JQuery CDN
* New-WebPage -JQueryVersion will select the JQueryVersion
* Use of JQuery can be specified in the Pipeworks manifest, and will be shared for the whole module
## JQueryUI    
* New-WebPage -UseJQueryUI will incorporate JQueryUI
* New-WebPage -JQueryUITheme will specify a JQuery theme.  To preview default themes, go to http://jqueryui.com/themeroller/
* Use of JQueryUI and theme can be specified in the Pipeworks manifest, and will be shared for the whole module
* New-Region has several options to enable creating JQueryUI -AsTab, -AsAccordian, -AsWidget, -AsPopup, -AsPopdown, -AsPopout, -AsResizable
* Write-Link has -Button, which makes items a JQueryUI button
## Microdata
* Formatters for http://schema.org/Product, http://schema.org/VideoObject, http://schemea.org/Article
* Get-Web -AsMicrodata can pull HTML5 microdata from sites
## OpenGraph
* Get-Web -OpenGraph can pull OpenGraph info from sites
## MetaData
* Get-Web -OpenGraph can pull MetaData from sites
## RSS
* Added -AsRss as an option to all commands
* Inclusion of Out-RssFeed and New-RssItem in integrated web commands
## Added Posts directory
* PSD1 files or pages that produce microdata (integrated default blog)
* JQueryUI makeover of module pages and command pages
'@        
},
@{
    Version = '1.0'
    Notes = @'
# Integration of Azure Table Storage Commands
* Get-AzureTable - List tables
* Search-AzureTable - Search tables
* Set-AzureTable - Set table content
* Remove-AzureTable - Remove azure table content
'@    
}, 
@{
    Version = '1.0.0.1'
    Notes = @'
# Bugfixing of Table Storage Commands
* Items with properties that collide with table info properties will see those properties remove and replaced with the table storage info.
* Set-AzureTable now takes values from the pipeline by property name, and follows parameter naming convention
* Set-AzureTable now SupportsShouldProcess
# Adding of Google Checkout integration
* Integrated CSS annotations for Google checkout into http://schema.org/Product
* New-WebPage -GoogleMerchantId loads the google checkout scripts
* New-WebPage -GoogleCheckoutCurrency sets the checkout currency (default USD)
# Added Version History
* And boy, are my fingers tired
'@  
}, @{
    Version = '1.0.0.2'
    Notes = @'
# A little more bugfixing of table storage commands
* Search-AzureTable can not page thru results and retreive tables larger than 1000 items
* Added a -BatchSize parameter to Search-AzureTable to control the returned number of objects per page (default 640)
'@    
}, @{
    Version = '1.0.0.3'
    Notes = @'
# Adding formatters
* http://schema.org/Event (with google checkout annotations)
* http://schema.org/ConactPoint 
* Module
* Walkthru
* Example
# Internal Changes to Table Storage
* Changed REST version from 2009-09-19 to 2011-08-18
* Changed REST header data from NetFX Version 1.0 to 2.0
* Enabled -Select for Search-AzureTable (aww yeah)
'@    
}, @{
    Version = '1.0.0.4'
    ChangeDate = '3/7/2012'
    Notes = @'
# Minor Bugfixing
* ConvertTo-CommandService fixes for built-in cmdlets
* ConvertTo-CommandService fix for -Download
* Subtle bug in ConvertTo-ModuleService that prevented .PS1 files ending in single line comments from generating correctly.
# Initial integration of Table capabilities into Module Services
*  ?Search / ?Id / ?Name handlers for modules with table information
* IndexBy to collect table contents for faster searching of large datasets
* Implementation of SimpleSearchTable
# Inclusion of Lightweight Local Interactive Server, PSNode
'@    
}, @{
    Version = '1.0.0.5'
    ChangeDate = '3/8/2012'
    Notes = @'
- Minor Bugfixing
-- Send-Email -AsJob now works
-- Start-PSNode now runs on V2 and V3
'@    
}, @{
    Version = '1.0.0.6'
    ChangeDate = '3/15/2012'
    Notes = @'
# JQueryUI, CSS, and other changes

* Support for JQueryUI Custom Themes built with ThemeRoller ( http://jqueryui.com/themeroller )

1. Go to ThemeRoller and make a theme
2. Download it
3. Copy/paste in the CSS and JS directories into your module
4. Use the JQueryUITheme 'Custom' in your Pipeworks manifest or with New-WebPage


This required another couple of generally nice things:


# New Special Directories
* JS/JavaScript or Culture/JS Culture/Javascript - Common Javascript files 
* CSS or Culture/CSS Culture/CSS - Common Css files 
* Asset or Culture/Asset or Resource  or Culture/Resource - Common Resources Files
* All of these directories include content recursively
* Made some changes to New-Webpage to support 'Custom'

# Table Changes
* Added TimesViewed auto-update to table storage processing:
* If there's a timesviewed property, every time a handler displays an item, it will update that property
* Tables now can use IndexBy, which backs up content into a SQL database for faster integrated searching

# DCRs (PowerShell Saturday)
* Added Version # to downloads
* Included SecureSettings cmdlets into Pipeworks

'@    
}, @{
    Version = '1.0.0.7'
    ChangeDate = '3/18/2012'
    Notes = @'
# New Commands
* Added Write-CRUD
# ConvertTo-ModuleService changes
* Support for nested content in Pages
* No longer attempting to fully rebuild the index of a changed table
'@
}, @{
    Version = '1.0.0.8'
    ChangeDate = '3/22/2012'
    Notes = @'
# Minor changes to Write-CRUD
* Adding -LargeField (to make some fields use 10 for |LinesForInput)
* Fixing Write-CRUD to prefer http://shouldbeonschema.org/Property when querying for schemas
* Adding Write-CRUD walkthru
# Bug fix for Asset directory
* Actually deploys Asset\Assets\Resources
# PrimaryPurpose -Blog implemented
* Rss Handler added
* Latest handler added
* Typename handler added
# Enabled PipeworksManifest.SecureSetting
* Uses Get-SecureSetting to move a list of encrypted settings into web.config

'@
}, @{
    Version = '1.0.0.9'
    ChangeDate = '3/22/2012'
    Notes = @'
# Adding ConvertFrom-Markdown
'@
}, @{
    Version = '1.0.10.0'
    ChangeDate = '3/23/2012'
    Notes = @'
# Write-Crud 
## Fixes
* Getting rid of some red if a custom field is generated before a type
## Improvements
* schemas with parameter values of Boolean will make [switch] parameters in Add and Update
* schemas with names like *date* will become [DateTime] parameters in Add and Update
* all items get an id parameter
# ConvertFrom-Markdown
* Closed off lists
# Misc.
* Rewrote Release Notes in Markdown
'@
}, @{
    Version = '1.0.1.1'
    ChangeDate = '3/26/2012'
    Notes = @'
# ConvertFrom-Markdown fixes 
* Fixed Links with copious help from XoN
# User System
* Finalized REST services for email-based login in module handler
* ConvertTo-CommandService -RequireLogin / -RequireAppKey
* Use Tracking of Cmdlets
# Write-Link Fixes
* Corrected url caption fixer
'@
}, @{
    Version = '1.0.1.2'
    ChangeDate = '3/29/2012'
    Notes = @'
# Markdown Integration
* Write-Crud and core handlers now convert strings without tags from markdown
# User System 
* No longer flash login
# Get-WebInput
* Fixed regression in ScriptBlock parameters
'@    
}, @{
    Version = '1.0.1.3'
    ChangeDate = '4/1/2012'
    Notes = @'
# Improvements in Table Storage Cmdlets
* Perf - Switched to an enumerator rather than keeping a collection
* Perf - Changed the way table items are excluded
* Perf - Changed the way that TimeStamp is converted into datetime
* Usability - Failures to fetch a specific item now tell which item
# Fixes in Unpacking Table Items
* Timestamps did not used to be datetimes, now that they are, the unpack handler has to check for exclusion slightly differently
# Show-WebObject
* Starting at a root of a tree of data in Azure, renders as HTML
* Introduced ObjectPages into PipeworksManifest
'@    
}, @{
    Version = '1.0.1.4'
    ChangeDate = '4/4/2012'
    Notes =@'
# User Authentication System
* Fixed redirection to jump back to a specific URL if set in session, and the home page (not the module page) otherwise
# New-Region
* Added -AsPopin
* Added -AsSlideshow
'@
}, @{
    Version = '1.0.2.0'
    ChangeDate = '4/10/2012'
    Notes =@'
# Significant refactoring of module service extensions
* -UseSchematic has replaced -PrimaryPurpose
* -UseSchematic is now modularized into files for each schematic
* -UseSchematic can stack, so multiple schematics can be used to build a site.

# Schematics Introduced
* Blog
* 
# New-Region
* Fixed -AsPopin / -AsSlideshow to be able to handle items with IDs
* Fixes to -Popout/Popdown

'@
}, @{
    Version = '1.0.2.1'
    ChangeDate = '4/17/2012'
    Notes = @'
# Fixes to user system
* Adding slight delays to session data propagates before a redirect happens
# Changes to Write-CRUD
* KeyType parameter allows for GUIDs, Hex Keys, Small Hex Keys, Sequential Keys, and Named Keys
* UserTable changes added
# Schematics Introduced:
* StagePage
# Miscellaneous
* Request-CommandInput automatically uses ConvertFrom-Markdown
'@
}, @{
    Version = '1.0.2.2'
    ChangeDate = '4/23/2012'
    Notes = @'
# Changes to Write-CRUD
* Markdown conversion is now optional
* UserTable changes more thoroughly enforced
# New Schematics Introduced
* SimpleSearch
* Dashboard

# Azure Publishing tools
* Publish-AzureService lets DNS information be embedded in a pipeworks manifest, and enables creation of highly complex Azure deployments simply by importing decorated modules.
* Switch-TestDeployment toggles changes to the hosts file to preview staging deployments
# Miscellaneous
* Request-CommandInput no longer uses tables
* .ezformat.ps1 files are automatically run on a module (if found) before anything happens

## Code cleanout of -PrimaryPurpose complete
'@
}, @{
    Version = '1.0.2.3'
    ChangeDate = '4/28/2012'
    Notes = @'
# Changes to Write-CRUD
* Name is no longer unique by default
* ReadCodePartition, ReadCodeCrossReferenceField, SortField, SortType added

# New region types
* -AsPortlet will show JQueryUI portlets

# Expand-Data fixes
* Corrected pipeline behavior

# Housecleaning
## ScriptCop fixing
* Add-AzureRole help
* OutputTypes in ConvertFrom-InlinePowerShell, ConvertTo-CommandService, ConvertTo-ModuleService, Expand-Data

# Initial AWS / EC2 Bits
'@
}, @{
    Version = '1.0.2.4'
    ChangeDate = '5/8/2012'
    Notes = @'
# Bugfixing
* New-RDPFile parameter fixes (-ComputerName instead of -Address)
* Wait-EC2 example changes
# Documentation
* Adding EC2 demo
'@
}, @{
    Version = '1.0.2.5'
    ChangeDate = '5/15/2012'
    Notes = @'
# New commands
* Out-Zip
* Get-Email
'@

}, @{
    Version = '1.0.2.6'
    ChangeDate = '5/25/2012'
    Notes = @'
# Intranet App Capabilities
* Get-Person function lets you lookup by AD info or by Membership Table
* ConvertTo-ModuleService -AsIntranetSet lets you use Windows authentication
* Changes to PSNode to handle Windows authentication
# UrlRewrite joy
* ConvertTo-ModuleService -AcceptanyUrl lets you accept any url (routed to AnyUrl.ps1 from Pages)
* Inventory Schematic routes items from a table into fake directories
'@
}, @{
    Version = '1.0.2.7'
    ChangeDate = '5/27/2012'
    Notes = @'
# Breaking Change
* Renamed the Inventory Schematic to a Gallery Schematic (the name was more approprtiate)
# Bugfixes related to UrlRewrite
* Correctly resolving linked items
# Changes to views
* BlogPosting Post URL now takes into account being loaded inside a virtual URL
* VideoObject view now centers content, and uses ThumbNailURL in place of Image
'@
}, @{
    Version = '1.0.2.8'
    ChangeDate = '5/31/2012'
    Notes =@'
# Installer for PSNode
* functions to open/close ports
* documentation on PSNode
* install function for PSNode
# Improvements to Table Storage Cmdlets
* Search-AzureTable now has -First, -Next, and a continuation capabilitity
'@
}, @{
    Version = '1.0.2.9'
    ChangeDate = '6/4/2012'
    Notes =@'
# PSData serializers
* Import-PSData
* Export-PSData
# Changes to Gallery schematic to support directories
'@
}, @{
    Version = '1.0.3.0'
    ChangeDate = '6/7/2012'
    Notes =@'
# Site redesign
# Inclusion of WolframAlpha command
'@
}, @{
    Version = '1.0.3.1'
    ChangeDate = '6/13/2012'
    Notes = @'
# Inclusion of Twilio Texting Commands
# Updates to Get-Web
* Support for Credentials
* Support for POST/PUT/DELETE
'@
}, @{
    Version = '1.0.3.2'
    ChangeDate = '6/25/2012'
    Notes = @'
# Bugfixing
## Write-AspNetScriptPage 

Fixing try/catch format
## ConvertTo-ModuleService

Most natural web types now fall thru "Pages" directory like HTML.

## New-Region

-*Margin parameters propagate to style if specified and not -FixedSize

# Inclusion of Twilio Phone Commands
'@
}, @{
    Version = '1.0.3.3'
    ChangeDate = '7/14/2012'
    Notes = @'
# Module Installer
## Added a simple install.cmd to auto install from a module.zip
## Added Shortcuts capability

# Get-WebInput now handles extracting info from a WPF control

# Get-Web improvements
## -AsJson parses json
## -Header sets headers
## -RequestBody sends content in the request body (overrides other paramters)


# Module Service Changes
## IMPORTANT DEFAULT CHANGE - RunspacePools are now used by default instead of Runspaces.  To use Runspaces, use -IsolateRunspace
## Starting Facebook Integration  

FacebookLogin=true  displays a facebook login if AppId is present
'@  
}, @{
    Version = '1.0.3.4'
    ChangeDate = '7/22/2012'
    Notes = @'
# Module Service Redesign
New, improved, more social, and login-sensitive



'@  
}, @{
    Version  = '1.0.3.5'
    ChangeDate = '7/29/2012'
    Notes = @'
# Bugfixing
* Typo bug in Get-WebInput for Hashtables (prevented @{} form from working)
# Write-Link minor improvements

'@
}, @{
    Version = '1.0.3.6'
    ChangeDate = '8/14/2012'
    Notes=  @'
# Facebook friendliness
- Facebook login now working 
# Radical Refactoring
- Command Services have been de-emphasized.  The core of command services has been brought into a module service in order to save on space.
- Confirm-Person helps validate users
- Invoke-WebCommand handles the core command handler needs
'@
}, @{
    Version = '1.0.3.7'
    ChangeDate = '8/22/2012'
    Notes = @'
# Finer Forms
- Using labels elements for all form inputs
- Making forms sparser
- Adding focus CSS
# Easier URLs
- /Command name now works without bloat
- /Row/Part also works
'@    
}, @{
    Version = '1.0.3.8'
    ChangeDate = '8/23/2012'
    Notes = @'
Bugfixing:
- Removing a bug that created an extra directory for modules that used a custom JQuery theme (this prevented open URL conventions from working)
- Making fall thru work for all files in Pages directory
Inclusion:
- Bringing in Resolve-Location (IP lookup and Geolocation)
- Formatter for http://schema.org/Place
'@    
, @{
    Version = '1.0.3.9'
    ChangeDate = '8/27/2012'
    Notes = @'
## Bugfixing:
* Lots of places of in New-Region ignored $style, and no do not
* Subtle bugs in the depth handling broke various restful url forms (i.e. Write-ScriptHTML/ didn't work but Write-ScriptHTML did)
* Various bugs left in DownloadProxy=true now fixed
# Finally, Help  Handlers!
* Cmd -? or Cmd/-? gets help!
* Help is interlinked!
* Examples are colorized!
* (Can you tell I'm exclited?)
'@
}, @{
    Version = '1.0.4.0'
    ChangeDate = '9/3/2012'
    Notes = @'
# ConvertFrom-Markdown improvements  
- Now with -ScriptAsPowerShell and -ConvertLink


## Local Experience Changes
* Fixes to enable working on alternate ports 
* Creation of a user record / ip / api key in the local case
### Minor Performance Improvements
* Cutting some vestigal code from ConvertTo-ModuleService
* Dodging the use of providers when possible to save a few cycles
* Performance improvements in path resolution 
### Code cleanup
* Removing various unfinished schematics to continue chopping down on deployment size
'@    
}, @{
    Version = '1.0.4.1'
    ChangeDate = '9/7/2012'
    Notes = @'
Minor Bugfixes for V3
- Get-Person -Local is now -IsLocalAccount
- Build now works on V3!
'@
}, @{
    Version = '1.0.4.2'
    ChangeDate = '9/11/2012'
    Notes = @'
# More Minor V3 stuff:
- Fix to formatters when running under .NET 4.0
'@
}, @{
    Version = '1.0.4.3'
    ChangeDate = '9/15/2012'
    Notes = @'
Aesthetic Changes:
* Branding Section now in place 
* Social Row now is followed by a cleared div, so it still floats right but leaves more space below
'@
}, @{
    Version = '1.0.4.4'
    ChangeDate = '9/19/2012'
    Notes = @'
Adding first drafts of some SQL commands

Fixing a bug in Get-SecureSetting (it was not working in web contexts due to a typo)
'@
}, @{
    Version = '1.0.4.5'
    ChangeDate = '9/19/2012'
    Notes = @'
* Updating SQL commands to handle spaces in column names
* Finalizing -AsGrid in New-Region (slightly modern UI look)
* Changing default look and feel of commands from popouts to grids.

'@
}, @{
    Version = '1.0.4.6'
    ChangeDate = '9/25/2012'
    Notes = @'
# Bugfixing
* Removing nested page structure inside of command handlers (html tags would embed another full html doc)
* Get-Person now returns http://schema.org/Person when querying Facebook

'@
}, @{
    Version = '1.0.4.7'
    ChangeDate = '9/27/2012'
    Notes = @'
* CommandGroup  now allows for a heirarchical view of commands on a page
* Automatically generated feeds for module topics / walkthrus

'@
}, @{
    Version = '1.0.4.8'
    ChangeDate = '10/8/2012'
    Notes = @'
# Implicit Calling
You can now dial into (or out ) a cmdlet.  If the Twilio parameters are discovered when interacting with a command, a phone experience for that command will be used.

# Aesthetic Changes
* Learn More and Download brought down into the main view 
* Login link added to commands that need it
* -Hidden commands (they do not show up on the front page, but the URLs work)
'@
}, @{
    Version = '1.0.4.9'
    ChangeDate = '10/9/2012'
    Notes = @'
Finally fully removing Command Services
'@
}

