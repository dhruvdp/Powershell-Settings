function Use-Win8Schematic
{
    <#
    .Synopsis
        Builds a web application according to a schematic
    .Description
        Use-Schematic builds a web application according to a schematic.
        
        Web applications should not be incredibly unique: they should be built according to simple schematics.        
    .Notes
    
        When ConvertTo-ModuleService is run with -UseSchematic, if a directory is found beneath either Pipeworks 
        or the published module's Schematics directory with the name Use-Schematic.ps1 and containing a function 
        Use-Schematic, then that function will be called in order to generate any pages found in the schematic.
        
        The schematic function should accept a hashtable of parameters, which will come from the appropriately named 
        section of the pipeworks manifest
        (for instance, if -UseSchematic Blog was passed, the Blog section of the Pipeworks manifest would be used for the parameters).
        
        It should return a hashtable containing the content of the pages.  Content can either be static HTML or .PSPAGE                
    #>
    [OutputType([Hashtable])]
    param(
    # Any parameters for the schematic
    [Parameter()][Hashtable]$Parameter,
    
    # The pipeworks manifest, which is used to validate common parameters
    [Parameter(Mandatory=$true)][Hashtable]$Manifest,
    
    # The directory the schemtic is being deployed to
    [Parameter(Mandatory=$true)][string]$DeploymentDirectory,
    
    # The directory the schematic is being deployed from
    [Parameter(Mandatory=$true)][string]$InputDirectory  
    )
    
    begin {
$newcsProject =
{
param([string]$Name, [GUID]$guid, [Hashtable]$Assets, [string[]]$AdditionalFiles)



$files = ("App.xaml.cs", "Common.cs", "Common\StandardStyles.xaml", "FailPage.xaml", "FailPage.xaml.cs", "PipeworksData.cs", "ItemsPage.xaml", "ItemsPage.Xaml.cs", "SplitPage.xaml", "SplitPage.xaml.cs", "Properties\AssemblyInfo.cs") + $AdditionalFiles |
    Select-Object -Unique

$compile = 
    foreach ($f in $files) {
        if ($f -like "*.xaml.cs") {
@"
    <Compile Include="$f">
      <DependentUpon>$($f -ireplace "\.cs", "")</DependentUpon>
    </Compile>
"@            
        } elseif ($f -like "*.cs") {
@"
    <Compile Include="$f" />
"@
        }
    }

$includePages = 
    foreach ($f in $files) {
        if ($f -like "*.xaml" -and $f -ne 'App.Xaml') {
@"
<Page Include="$f">
    <SubType>Designer</SubType>
    <Generator>MSBuild:Compile</Generator>
</Page>
"@
        } else {
        }
    } 

$assetsChunk = 
    foreach ($kv in ($assets.GetEnumerator() | Sort-Object Key -Descending)) {
        "<Content Include='Assets\$($kv.Key)' />" + [Environment]::NewLine
    
}

@"
<?xml version="1.0" encoding="utf-8"?>
<Project ToolsVersion="4.0" DefaultTargets="Build" xmlns="http://schemas.microsoft.com/developer/msbuild/2003">
  <Import Project="`$(MSBuildExtensionsPath)\`$(MSBuildToolsVersion)\Microsoft.Common.props" Condition="Exists('`$(MSBuildExtensionsPath)\`$(MSBuildToolsVersion)\Microsoft.Common.props')" />
  <PropertyGroup>
    <Configuration Condition=" '`$(Configuration)' == '' ">Debug</Configuration>
    <Platform Condition=" '`$(Platform)' == '' ">AnyCPU</Platform>
    <ProjectGuid>$guid</ProjectGuid>
    <OutputType>AppContainerExe</OutputType>
    <AppDesignerFolder>Properties</AppDesignerFolder>
    <RootNamespace>PipeworksApp</RootNamespace>
    <AssemblyName>$Name</AssemblyName>
    <DefaultLanguage>en-US</DefaultLanguage>
    <FileAlignment>512</FileAlignment>
    <ProjectTypeGuids>{BC8A1FFA-BEE3-4634-8014-F334798102B3};{FAE04EC0-301F-11D3-BF4B-00C04F79EFBC}</ProjectTypeGuids>
  </PropertyGroup>
  <PropertyGroup Condition=" '`$(Configuration)|`$(Platform)' == 'Debug|AnyCPU' ">
    <PlatformTarget>AnyCPU</PlatformTarget>
    <DebugSymbols>true</DebugSymbols>
    <DebugType>full</DebugType>
    <Optimize>false</Optimize>
    <OutputPath>bin\Debug\</OutputPath>
    <DefineConstants>DEBUG;TRACE;NETFX_CORE</DefineConstants>
    <ErrorReport>prompt</ErrorReport>
    <WarningLevel>4</WarningLevel>
  </PropertyGroup>
  <PropertyGroup Condition=" '`$(Configuration)|`$(Platform)' == 'Release|AnyCPU' ">
    <PlatformTarget>AnyCPU</PlatformTarget>
    <DebugType>pdbonly</DebugType>
    <Optimize>true</Optimize>
    <OutputPath>bin\Release\</OutputPath>
    <DefineConstants>TRACE;NETFX_CORE</DefineConstants>
    <ErrorReport>prompt</ErrorReport>
    <WarningLevel>4</WarningLevel>
  </PropertyGroup>
  <ItemGroup>
    <!-- A reference to the entire .Net Framework and Windows SDK are automatically included -->
    <SDKReference Include="MSAdvertisingXaml, Version=6.1">
      <Name>Microsoft Advertising SDK for Windows 8 %28Xaml%29</Name>
    </SDKReference>
  </ItemGroup>
  <ItemGroup>
    $($compile -join ([Environment]::NewLine))
    
  </ItemGroup>
  <ItemGroup>
    <AppxManifest Include="Package.appxmanifest">
      <SubType>Designer</SubType>
    </AppxManifest>
  </ItemGroup>
  <ItemGroup>
    $assetsChunk 
    
    $($includePages -join ([Environment]::NewLine))
  </ItemGroup>
  <ItemGroup>
    <ApplicationDefinition Include="App.xaml">
      <Generator>MSBuild:Compile</Generator>
      <SubType>Designer</SubType>
    </ApplicationDefinition>
  </ItemGroup>
  <PropertyGroup Condition=" '`$(VisualStudioVersion)' == '' or '`$(VisualStudioVersion)' &lt; '11.0' ">
    <VisualStudioVersion>11.0</VisualStudioVersion>
  </PropertyGroup>
  <Import Project="`$(MSBuildExtensionsPath)\Microsoft\WindowsXaml\v`$(VisualStudioVersion)\Microsoft.Windows.UI.Xaml.CSharp.targets" />
  <!-- To modify your build process, add your task inside one of the targets below and uncomment it. 
       Other similar extension points exist, see Microsoft.Common.targets.
  <Target Name="BeforeBuild">
  </Target>
  <Target Name="AfterBuild">
  </Target>
  -->
</Project>
"@
}


$appXaml = { 
@"
<Application
    x:Class="PipeworksApp.App"
    xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
    xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
    xmlns:local="using:PipeworksApp">

    <Application.Resources>
        <ResourceDictionary>

            <ResourceDictionary.MergedDictionaries>

                <!-- 
                    Styles that define common aspects of the platform look and feel
                    Required by Visual Studio project and item templates
                 -->
                <ResourceDictionary Source="Common/StandardStyles.xaml"/>
                
<!-- Custom styles -->
                <ResourceDictionary>
                    <SolidColorBrush x:Key="WindowsBlogBackgroundBrush" Color="#FF0A2562"/>
                    <SolidColorBrush x:Key="TheForegroundColor" Color="#FF012456"/>
                    <SolidColorBrush x:Key="TheBackgroundColor" Color="#FFFAFAFA"/>
                    <Style x:Key="WindowsBlogLayoutRootStyle" TargetType="Panel" BasedOn="{StaticResource LayoutRootStyle}">
                        <Setter Property="Background" Value="{StaticResource WindowsBlogBackgroundBrush}"/>
                    </Style>

                    <local:PipeworksDataSource x:Key="feedDataSource" />
                    
                </ResourceDictionary>
            </ResourceDictionary.MergedDictionaries>
        </ResourceDictionary>
    </Application.Resources>
</Application>
"@
}

$appXamlCodeBehind = {
@"
using System;
using System.Collections.Generic;
using Windows.ApplicationModel;
using Windows.ApplicationModel.Activation;
using Windows.Data.Xml.Dom;
using Windows.System;
using Windows.UI.ApplicationSettings;
using Windows.UI.Notifications;
using Windows.UI.Popups;
using Windows.UI.Xaml;
using Windows.UI.Xaml.Controls;


namespace PipeworksApp
{
    /// <summary>
    /// Provides application-specific behavior to supplement the default Application class.
    /// </summary>
    sealed partial class App : Application
    {
        TileUpdater tileUpdater = TileUpdateManager.CreateTileUpdaterForApplication();
        /// <summary>
        /// Initializes the singleton application object.  This is the first line of authored code
        /// executed, and as such is the logical equivalent of main() or WinMain().
        /// </summary>
        public App()
        {
            this.InitializeComponent();
            this.Suspending += OnSuspending;
            this.Resuming += App_Resuming;
        }

        void App_Resuming(object sender, object e)
        {
            
        }

        protected async override void OnFileActivated(FileActivatedEventArgs args)
        {
 	 
        }

        protected async override void OnActivated(IActivatedEventArgs args)
        {
 	        
        }


        protected async override void OnWindowCreated(WindowCreatedEventArgs args)
        {
 	        base.OnWindowCreated(args);
        }

        

        /// <summary>
        /// Invoked when the application is launched normally by the end user.  Other entry points
        /// will be used when the application is launched to open a specific file, to display
        /// search results, and so forth.
        /// </summary>
        /// <param name="args">Details about the launch request and process.</param>
        protected async override void OnLaunched(LaunchActivatedEventArgs args)
        {
            

            if (args.PreviousExecutionState == ApplicationExecutionState.Running)
            {
                Window.Current.Activate();
                return;
            }
            tileUpdater.Clear();
            tileUpdater.EnableNotificationQueue(true);

            SettingsPane.GetForCurrentView().CommandsRequested += App_CommandsRequested;

            var rootFrame = new Frame();
            PipeworksApp.Common.SuspensionManager.RegisterFrame(rootFrame, "AppFrame");

            PipeworksDataSource feedDataSource = (PipeworksDataSource)App.Current.Resources["feedDataSource"];
            if (feedDataSource != null)
            {
                if (feedDataSource.PipeworksData.Count == 0)
                {
                    try
                    {
                        
                        await feedDataSource.GetModulesAsync();


                        if (feedDataSource.BlogItems.Count != null && feedDataSource.BlogItems.Count > 0)
                        {
                            int tileCount = 0;
                            foreach (PipeworksBlogItem bi  in feedDataSource.BlogItems) {
                                if (tileCount >= 5) { break; }
                                tileCount++;
                                string escapedTitle = bi.Name.Replace("&", "&amp;").Replace("<", "&lt;").Replace(">", "&gt;").Replace("\"", "&quot;").Replace("'", "&apos;");
                                /*
                                if (escapedTitle.Length > 32)
                                {
                                    escapedTitle = escapedTitle.Substring(0, 32);
                                }*/
                                XmlDocument tileXml = TileUpdateManager.GetTemplateContent(TileTemplateType.TileWideText01);
                                XmlElement textElement = (XmlElement)tileXml.GetElementsByTagName("text")[0];
                                textElement.AppendChild(tileXml.CreateTextNode(bi.Name));

                                string tileDOM = @"
<tile>
  <visual>
    <binding template=""TileWideText09"">
      <text id='1'> </text>
      <text id='2'>" + escapedTitle + @"</text>
    </binding>
    <binding template=""TileSquareText04"">
      <text id='1'>" + escapedTitle + @"</text>
    </binding>
  </visual>
</tile>
";

                                XmlDocument tileDoc = new XmlDocument();
                                tileDoc.LoadXml(tileDOM);
                                // create a tile notification
                                TileNotification tile = new TileNotification(tileDoc);
                                
                                tileUpdater.Update(tile);

                                //TileUpdateManager.CreateTileUpdaterForApplication().StartPeriodicUpdate
                                // send the notification to the app's application tile
                               // TileUpdateManager.CreateTileUpdaterForApplication().Update(tile);

                                // send the notification
                                //TileUpdateManager.CreateTileUpdaterForApplication().Update(tileContent.CreateNotification());

                                
                            }
                        }
                    }
                    catch (Exception ex)
                    {
                        // Show error
                        rootFrame.Navigate(typeof(FailPage), ex.ToString());
                    }
                }
            }

            
            if (args.PreviousExecutionState == ApplicationExecutionState.Terminated)
            {
                //TODO: Load state from previously suspended application

                // Restore the saved session state only when appropriate
                await PipeworksApp.Common.SuspensionManager.RestoreAsync();
            }

            // Create a Frame to act navigation context and navigate to the first page
            //var rootFrame = new Frame();
            if (rootFrame.Content == null)
            {
                if (!rootFrame.Navigate(typeof(ItemsPage)))
                {
                    throw new Exception("Failed to create initial page");
                }
            }

            // Place the frame in the current Window and ensure that it is active
            Window.Current.Content = rootFrame;
            Window.Current.Activate();
            
            
        }

        

        void App_CommandsRequested(SettingsPane sender, SettingsPaneCommandsRequestedEventArgs args)
        {
            args.Request.ApplicationCommands.Add(new SettingsCommand("privacypolciy", "Privacy Policy", showPrivacyPolicy)); 
        }

        private async void showPrivacyPolicy(IUICommand command)
        {
            PipeworksDataSource feedDataSource = (PipeworksDataSource)App.Current.Resources["feedDataSource"];
            if (feedDataSource != null)
            {
                Launcher.LaunchUriAsync(
                    new Uri(feedDataSource.ServiceUrl.ToString() + "?ShowPrivacyPolicy=true")
                );
            }
        }

        /// <summary>
        /// Invoked when application execution is being suspended.  Application state is saved
        /// without knowing whether the application will be terminated or resumed with the contents
        /// of memory still intact.
        /// </summary>
        /// <param name="sender">The source of the suspend request.</param>
        /// <param name="e">Details about the suspend request.</param>
        private async void OnSuspending(object sender, SuspendingEventArgs e)
        {
            var deferral = e.SuspendingOperation.GetDeferral();
            //TODO: Save application state and stop any background activity
            await PipeworksApp.Common.SuspensionManager.SaveAsync();
            deferral.Complete();
        }
    }
}
"@
}

$commonCs = {
@"
using System;
using System.Collections.Generic;
using System.IO;
using System.Linq;
using System.Runtime.Serialization;
using System.Threading.Tasks;
using Windows.Devices.Sensors;
using Windows.Foundation.Collections;
using Windows.Storage;
using Windows.Storage.Streams;
using Windows.System;
using Windows.UI.Core;
using Windows.UI.ViewManagement;
using Windows.UI.Xaml;
using Windows.UI.Xaml.Controls;
using Windows.UI.Xaml.Data;
using Windows.UI.Xaml.Navigation;


namespace PipeworksApp.Common
{
    /// <summary>
    /// Value converter that translates true to false and vice versa.
    /// </summary>
    public sealed class BooleanNegationConverter : IValueConverter
    {
        public object Convert(object value, Type targetType, object parameter, string language)
        {
            return !(value is bool && (bool)value);
        }

        public object ConvertBack(object value, Type targetType, object parameter, string language)
        {
            return !(value is bool && (bool)value);
        }
    }


    /// <summary>
    /// Value converter that translates true to <see cref="Visibility.Visible"/> and false to
    /// <see cref="Visibility.Collapsed"/>.
    /// </summary>
    public sealed class BooleanToVisibilityConverter : IValueConverter
    {
        public object Convert(object value, Type targetType, object parameter, string language)
        {
            return (value is bool && (bool)value) ? Visibility.Visible : Visibility.Collapsed;
        }

        public object ConvertBack(object value, Type targetType, object parameter, string language)
        {
            return value is Visibility && (Visibility)value == Visibility.Visible;
        }
    }


    /// <summary>
    /// Typical implementation of Page that provides several important conveniences:
    /// <list type="bullet">
    /// <item>
    /// <description>Application view state to visual state mapping</description>
    /// </item>
    /// <item>
    /// <description>GoBack, GoForward, and GoHome event handlers</description>
    /// </item>
    /// <item>
    /// <description>Mouse and keyboard shortcuts for navigation</description>
    /// </item>
    /// <item>
    /// <description>State management for navigation and process lifetime management</description>
    /// </item>
    /// <item>
    /// <description>A default view model</description>
    /// </item>
    /// </list>
    /// </summary>
    [Windows.Foundation.Metadata.WebHostHidden]
    public class LayoutAwarePage : Page
    {
        /// <summary>
        /// Identifies the <see cref="DefaultViewModel"/> dependency property.
        /// </summary>
        public static readonly DependencyProperty DefaultViewModelProperty =
            DependencyProperty.Register("DefaultViewModel", typeof(IObservableMap<String, Object>),
            typeof(LayoutAwarePage), null);

        private List<Control> _layoutAwareControls;

        protected Accelerometer theAccelerometer;
        protected LightSensor theLightSensor;
        protected Gyrometer theGyrometer;
        protected Inclinometer theIncliometer;
        protected Compass theCompass;
        protected OrientationSensor theOrientationSensor;
        protected SimpleOrientationSensor theSimpleOrientationSensor;


        /// <summary>
        /// Initializes a new instance of the <see cref="LayoutAwarePage"/> class.
        /// </summary>
        public LayoutAwarePage()
        {
            if (Windows.ApplicationModel.DesignMode.DesignModeEnabled) return;

            theAccelerometer = Accelerometer.GetDefault();
            theLightSensor = LightSensor.GetDefault();
            theGyrometer = Gyrometer.GetDefault();
            theIncliometer = Inclinometer.GetDefault();
            theCompass = Compass.GetDefault();
            theOrientationSensor = OrientationSensor.GetDefault();
            theSimpleOrientationSensor = SimpleOrientationSensor.GetDefault();

            // Create an empty default view model
            this.DefaultViewModel = new ObservableDictionary<String, Object>();

            // When this page is part of the visual tree make two changes:
            // 1) Map application view state to visual state for the page
            // 2) Handle keyboard and mouse navigation requests
            this.Loaded += (sender, e) =>
            {
                this.StartLayoutUpdates(sender, e);

                // Keyboard and mouse navigation only apply when occupying the entire window
                if (this.ActualHeight == Window.Current.Bounds.Height &&
                    this.ActualWidth == Window.Current.Bounds.Width)
                {
                    // Listen to the window directly so focus isn't required
                    Window.Current.CoreWindow.Dispatcher.AcceleratorKeyActivated +=
                        CoreDispatcher_AcceleratorKeyActivated;
                    Window.Current.CoreWindow.PointerPressed +=
                        this.CoreWindow_PointerPressed;
                }
            };

            // Undo the same changes when the page is no longer visible
            this.Unloaded += (sender, e) =>
            {
                this.StopLayoutUpdates(sender, e);
                Window.Current.CoreWindow.Dispatcher.AcceleratorKeyActivated -=
                    CoreDispatcher_AcceleratorKeyActivated;
                Window.Current.CoreWindow.PointerPressed -=
                    this.CoreWindow_PointerPressed;
            };
        }

        /// <summary>
        /// An implementation of <see cref="IObservableMap&lt;String, Object&gt;"/> designed to be
        /// used as a trivial view model.
        /// </summary>
        protected IObservableMap<String, Object> DefaultViewModel
        {
            get
            {
                return this.GetValue(DefaultViewModelProperty) as IObservableMap<String, Object>;
            }

            set
            {
                this.SetValue(DefaultViewModelProperty, value);
            }
        }

        #region Navigation support

        /// <summary>
        /// Invoked as an event handler to navigate backward in the page's associated
        /// <see cref="Frame"/> until it reaches the top of the navigation stack.
        /// </summary>
        /// <param name="sender">Instance that triggered the event.</param>
        /// <param name="e">Event data describing the conditions that led to the event.</param>
        protected virtual void GoHome(object sender, RoutedEventArgs e)
        {
            // Use the navigation frame to return to the topmost page
            if (this.Frame != null)
            {
                while (this.Frame.CanGoBack) this.Frame.GoBack();
            }
        }

        /// <summary>
        /// Invoked as an event handler to navigate backward in the navigation stack
        /// associated with this page's <see cref="Frame"/>.
        /// </summary>
        /// <param name="sender">Instance that triggered the event.</param>
        /// <param name="e">Event data describing the conditions that led to the
        /// event.</param>
        protected virtual void GoBack(object sender, RoutedEventArgs e)
        {
            // Use the navigation frame to return to the previous page
            if (this.Frame != null && this.Frame.CanGoBack) this.Frame.GoBack();
        }

        /// <summary>
        /// Invoked as an event handler to navigate forward in the navigation stack
        /// associated with this page's <see cref="Frame"/>.
        /// </summary>
        /// <param name="sender">Instance that triggered the event.</param>
        /// <param name="e">Event data describing the conditions that led to the
        /// event.</param>
        protected virtual void GoForward(object sender, RoutedEventArgs e)
        {
            // Use the navigation frame to move to the next page
            if (this.Frame != null && this.Frame.CanGoForward) this.Frame.GoForward();
        }

        /// <summary>
        /// Invoked on every keystroke, including system keys such as Alt key combinations, when
        /// this page is active and occupies the entire window.  Used to detect keyboard navigation
        /// between pages even when the page itself doesn't have focus.
        /// </summary>
        /// <param name="sender">Instance that triggered the event.</param>
        /// <param name="args">Event data describing the conditions that led to the event.</param>
        private void CoreDispatcher_AcceleratorKeyActivated(CoreDispatcher sender,
            AcceleratorKeyEventArgs args)
        {
            var virtualKey = args.VirtualKey;

            // Only investigate further when Left, Right, or the dedicated Previous or Next keys
            // are pressed
            if (args.Handled) { return; }



            if ((args.EventType == CoreAcceleratorKeyEventType.SystemKeyDown ||
                args.EventType == CoreAcceleratorKeyEventType.KeyDown) &&
                (virtualKey == VirtualKey.Left || virtualKey == VirtualKey.Right ||
                (int)virtualKey == 166 || (int)virtualKey == 167))
            {
                var coreWindow = Window.Current.CoreWindow;
                var downState = CoreVirtualKeyStates.Down;
                bool menuKey = (coreWindow.GetKeyState(VirtualKey.Menu) & downState) == downState;
                bool controlKey = (coreWindow.GetKeyState(VirtualKey.Control) & downState) == downState;
                bool shiftKey = (coreWindow.GetKeyState(VirtualKey.Shift) & downState) == downState;
                bool noModifiers = !menuKey && !controlKey && !shiftKey;
                bool onlyAlt = menuKey && !controlKey && !shiftKey;

                if (((int)virtualKey == 166 && noModifiers) ||
                    (virtualKey == VirtualKey.Left && onlyAlt) ||
                    virtualKey == VirtualKey.Back)
                {
                    // When the previous key or Alt+Left are pressed navigate back
                    args.Handled = true;
                    this.GoBack(this, new RoutedEventArgs());
                }
                else if (((int)virtualKey == 167 && noModifiers) ||
                    (virtualKey == VirtualKey.Right && onlyAlt))
                {
                    // When the next key or Alt+Right are pressed navigate forward
                    args.Handled = true;
                    this.GoForward(this, new RoutedEventArgs());
                }
            }
        }

        /// <summary>
        /// Invoked on every mouse click, touch screen tap, or equivalent interaction when this
        /// page is active and occupies the entire window.  Used to detect browser-style next and
        /// previous mouse button clicks to navigate between pages.
        /// </summary>
        /// <param name="sender">Instance that triggered the event.</param>
        /// <param name="args">Event data describing the conditions that led to the event.</param>
        private void CoreWindow_PointerPressed(CoreWindow sender,
            PointerEventArgs args)
        {
            var properties = args.CurrentPoint.Properties;

            // Ignore button chords with the left, right, and middle buttons
            if (properties.IsLeftButtonPressed || properties.IsRightButtonPressed ||
                properties.IsMiddleButtonPressed) return;

            // If back or foward are pressed (but not both) navigate appropriately
            bool backPressed = properties.IsXButton1Pressed;
            bool forwardPressed = properties.IsXButton2Pressed;
            if (backPressed ^ forwardPressed)
            {
                args.Handled = true;
                if (backPressed) this.GoBack(this, new RoutedEventArgs());
                if (forwardPressed) this.GoForward(this, new RoutedEventArgs());
            }
        }

        #endregion

        #region Visual state switching

        /// <summary>
        /// Invoked as an event handler, typically on the <see cref="FrameworkElement.Loaded"/>
        /// event of a <see cref="Control"/> within the page, to indicate that the sender should
        /// start receiving visual state management changes that correspond to application view
        /// state changes.
        /// </summary>
        /// <param name="sender">Instance of <see cref="Control"/> that supports visual state
        /// management corresponding to view states.</param>
        /// <param name="e">Event data that describes how the request was made.</param>
        /// <remarks>The current view state will immediately be used to set the corresponding
        /// visual state when layout updates are requested.  A corresponding
        /// <see cref="FrameworkElement.Unloaded"/> event handler connected to
        /// <see cref="StopLayoutUpdates"/> is strongly encouraged.  Instances of
        /// <see cref="LayoutAwarePage"/> automatically invoke these handlers in their Loaded and
        /// Unloaded events.</remarks>
        /// <seealso cref="DetermineVisualState"/>
        /// <seealso cref="InvalidateVisualState"/>
        public void StartLayoutUpdates(object sender, RoutedEventArgs e)
        {
            var control = sender as Control;
            if (control == null) return;
            if (this._layoutAwareControls == null)
            {
                // Start listening to view state changes when there are controls interested in updates
                Window.Current.SizeChanged += this.WindowSizeChanged;
                this._layoutAwareControls = new List<Control>();
            }
            this._layoutAwareControls.Add(control);

            // Set the initial visual state of the control
            VisualStateManager.GoToState(control, DetermineVisualState(ApplicationView.Value), false);
        }

        private void WindowSizeChanged(object sender, WindowSizeChangedEventArgs e)
        {
            this.InvalidateVisualState();
        }

        /// <summary>
        /// Invoked as an event handler, typically on the <see cref="FrameworkElement.Unloaded"/>
        /// event of a <see cref="Control"/>, to indicate that the sender should start receiving
        /// visual state management changes that correspond to application view state changes.
        /// </summary>
        /// <param name="sender">Instance of <see cref="Control"/> that supports visual state
        /// management corresponding to view states.</param>
        /// <param name="e">Event data that describes how the request was made.</param>
        /// <remarks>The current view state will immediately be used to set the corresponding
        /// visual state when layout updates are requested.</remarks>
        /// <seealso cref="StartLayoutUpdates"/>
        public void StopLayoutUpdates(object sender, RoutedEventArgs e)
        {
            var control = sender as Control;
            if (control == null || this._layoutAwareControls == null) return;
            this._layoutAwareControls.Remove(control);
            if (this._layoutAwareControls.Count == 0)
            {
                // Stop listening to view state changes when no controls are interested in updates
                this._layoutAwareControls = null;
                Window.Current.SizeChanged -= this.WindowSizeChanged;
            }
        }

        /// <summary>
        /// Translates <see cref="ApplicationViewState"/> values into strings for visual state
        /// management within the page.  The default implementation uses the names of enum values.
        /// Subclasses may override this method to control the mapping scheme used.
        /// </summary>
        /// <param name="viewState">View state for which a visual state is desired.</param>
        /// <returns>Visual state name used to drive the
        /// <see cref="VisualStateManager"/></returns>
        /// <seealso cref="InvalidateVisualState"/>
        protected virtual string DetermineVisualState(ApplicationViewState viewState)
        {
            return viewState.ToString();
        }

        /// <summary>
        /// Updates all controls that are listening for visual state changes with the correct
        /// visual state.
        /// </summary>
        /// <remarks>
        /// Typically used in conjunction with overriding <see cref="DetermineVisualState"/> to
        /// signal that a different value may be returned even though the view state has not
        /// changed.
        /// </remarks>
        public void InvalidateVisualState()
        {
            if (this._layoutAwareControls != null)
            {
                string visualState = DetermineVisualState(ApplicationView.Value);
                foreach (var layoutAwareControl in this._layoutAwareControls)
                {
                    VisualStateManager.GoToState(layoutAwareControl, visualState, false);
                }
            }
        }

        #endregion

        #region Process lifetime management

        private String _pageKey;

        /// <summary>
        /// Invoked when this page is about to be displayed in a Frame.
        /// </summary>
        /// <param name="e">Event data that describes how this page was reached.  The Parameter
        /// property provides the group to be displayed.</param>
        protected override void OnNavigatedTo(NavigationEventArgs e)
        {
            // Returning to a cached page through navigation shouldn't trigger state loading
            if (this._pageKey != null) return;

            var frameState = SuspensionManager.SessionStateForFrame(this.Frame);
            this._pageKey = "Page-" + this.Frame.BackStackDepth;

            if (e.NavigationMode == NavigationMode.New)
            {
                // Clear existing state for forward navigation when adding a new page to the
                // navigation stack
                var nextPageKey = this._pageKey;
                int nextPageIndex = this.Frame.BackStackDepth;
                while (frameState.Remove(nextPageKey))
                {
                    nextPageIndex++;
                    nextPageKey = "Page-" + nextPageIndex;
                }

                // Pass the navigation parameter to the new page
                this.LoadState(e.Parameter, null);
            }
            else
            {
                // Pass the navigation parameter and preserved page state to the page, using
                // the same strategy for loading suspended state and recreating pages discarded
                // from cache
                this.LoadState(e.Parameter, (Dictionary<String, Object>)frameState[this._pageKey]);
            }
        }

        /// <summary>
        /// Invoked when this page will no longer be displayed in a Frame.
        /// </summary>
        /// <param name="e">Event data that describes how this page was reached.  The Parameter
        /// property provides the group to be displayed.</param>
        protected override void OnNavigatedFrom(NavigationEventArgs e)
        {
            var frameState = SuspensionManager.SessionStateForFrame(this.Frame);
            var pageState = new Dictionary<String, Object>();
            this.SaveState(pageState);
            frameState[_pageKey] = pageState;
        }

        /// <summary>
        /// Populates the page with content passed during navigation.  Any saved state is also
        /// provided when recreating a page from a prior session.
        /// </summary>
        /// <param name="navigationParameter">The parameter value passed to
        /// <see cref="Frame.Navigate(Type, Object)"/> when this page was initially requested.
        /// </param>
        /// <param name="pageState">A dictionary of state preserved by this page during an earlier
        /// session.  This will be null the first time a page is visited.</param>
        protected virtual void LoadState(Object navigationParameter, Dictionary<String, Object> pageState)
        {
        }

        /// <summary>
        /// Preserves state associated with this page in case the application is suspended or the
        /// page is discarded from the navigation cache.  Values must conform to the serialization
        /// requirements of <see cref="SuspensionManager.SessionState"/>.
        /// </summary>
        /// <param name="pageState">An empty dictionary to be populated with serializable state.</param>
        protected virtual void SaveState(Dictionary<String, Object> pageState)
        {
        }

        #endregion

        /// <summary>
        /// Implementation of IObservableMap that supports reentrancy for use as a default view
        /// model.
        /// </summary>
        private class ObservableDictionary<K, V> : IObservableMap<K, V>
        {
            private class ObservableDictionaryChangedEventArgs : IMapChangedEventArgs<K>
            {
                public ObservableDictionaryChangedEventArgs(CollectionChange change, K key)
                {
                    this.CollectionChange = change;
                    this.Key = key;
                }

                public CollectionChange CollectionChange { get; private set; }
                public K Key { get; private set; }
            }

            private Dictionary<K, V> _dictionary = new Dictionary<K, V>();
            public event MapChangedEventHandler<K, V> MapChanged;

            private void InvokeMapChanged(CollectionChange change, K key)
            {
                var eventHandler = MapChanged;
                if (eventHandler != null)
                {
                    eventHandler(this, new ObservableDictionaryChangedEventArgs(CollectionChange.ItemInserted, key));
                }
            }

            public void Add(K key, V value)
            {
                this._dictionary.Add(key, value);
                this.InvokeMapChanged(CollectionChange.ItemInserted, key);
            }

            public void Add(KeyValuePair<K, V> item)
            {
                this.Add(item.Key, item.Value);
            }

            public bool Remove(K key)
            {
                if (this._dictionary.Remove(key))
                {
                    this.InvokeMapChanged(CollectionChange.ItemRemoved, key);
                    return true;
                }
                return false;
            }

            public bool Remove(KeyValuePair<K, V> item)
            {
                V currentValue;
                if (this._dictionary.TryGetValue(item.Key, out currentValue) &&
                    Object.Equals(item.Value, currentValue) && this._dictionary.Remove(item.Key))
                {
                    this.InvokeMapChanged(CollectionChange.ItemRemoved, item.Key);
                    return true;
                }
                return false;
            }

            public V this[K key]
            {
                get
                {
                    return this._dictionary[key];
                }
                set
                {
                    this._dictionary[key] = value;
                    this.InvokeMapChanged(CollectionChange.ItemChanged, key);
                }
            }

            public void Clear()
            {
                var priorKeys = this._dictionary.Keys.ToArray();
                this._dictionary.Clear();
                foreach (var key in priorKeys)
                {
                    this.InvokeMapChanged(CollectionChange.ItemRemoved, key);
                }
            }

            public ICollection<K> Keys
            {
                get { return this._dictionary.Keys; }
            }

            public bool ContainsKey(K key)
            {
                return this._dictionary.ContainsKey(key);
            }

            public bool TryGetValue(K key, out V value)
            {
                return this._dictionary.TryGetValue(key, out value);
            }

            public ICollection<V> Values
            {
                get { return this._dictionary.Values; }
            }

            public bool Contains(KeyValuePair<K, V> item)
            {
                return this._dictionary.Contains(item);
            }

            public int Count
            {
                get { return this._dictionary.Count; }
            }

            public bool IsReadOnly
            {
                get { return false; }
            }

            public IEnumerator<KeyValuePair<K, V>> GetEnumerator()
            {
                return this._dictionary.GetEnumerator();
            }

            System.Collections.IEnumerator System.Collections.IEnumerable.GetEnumerator()
            {
                return this._dictionary.GetEnumerator();
            }

            public void CopyTo(KeyValuePair<K, V>[] array, int arrayIndex)
            {
                int arraySize = array.Length;
                foreach (var pair in this._dictionary)
                {
                    if (arrayIndex >= arraySize) break;
                    array[arrayIndex++] = pair;
                }
            }
        }
    }

    /// <summary>
    /// SuspensionManager captures global session state to simplify process lifetime management
    /// for an application.  Note that session state will be automatically cleared under a variety
    /// of conditions and should only be used to store information that would be convenient to
    /// carry across sessions, but that should be disacarded when an application crashes or is
    /// upgraded.
    /// </summary>
    internal sealed class SuspensionManager
    {
        private static Dictionary<string, object> _sessionState = new Dictionary<string, object>();
        private static List<Type> _knownTypes = new List<Type>();
        private const string sessionStateFilename = "_sessionState.xml";

        /// <summary>
        /// Provides access to global session state for the current session.  This state is
        /// serialized by <see cref="SaveAsync"/> and restored by
        /// <see cref="RestoreAsync"/>, so values must be serializable by
        /// <see cref="DataContractSerializer"/> and should be as compact as possible.  Strings
        /// and other self-contained data types are strongly recommended.
        /// </summary>
        public static Dictionary<string, object> SessionState
        {
            get { return _sessionState; }
        }

        /// <summary>
        /// List of custom types provided to the <see cref="DataContractSerializer"/> when
        /// reading and writing session state.  Initially empty, additional types may be
        /// added to customize the serialization process.
        /// </summary>
        public static List<Type> KnownTypes
        {
            get { return _knownTypes; }
        }

        /// <summary>
        /// Save the current <see cref="SessionState"/>.  Any <see cref="Frame"/> instances
        /// registered with <see cref="RegisterFrame"/> will also preserve their current
        /// navigation stack, which in turn gives their active <see cref="Page"/> an opportunity
        /// to save its state.
        /// </summary>
        /// <returns>An asynchronous task that reflects when session state has been saved.</returns>
        public static async Task SaveAsync()
        {
            // Save the navigation state for all registered frames
            foreach (var weakFrameReference in _registeredFrames)
            {
                Frame frame;
                if (weakFrameReference.TryGetTarget(out frame))
                {
                    SaveFrameNavigationState(frame);
                }
            }

            // Serialize the session state synchronously to avoid asynchronous access to shared
            // state
            MemoryStream sessionData = new MemoryStream();
            DataContractSerializer serializer = new DataContractSerializer(typeof(Dictionary<string, object>), _knownTypes);
            serializer.WriteObject(sessionData, _sessionState);

            // Get an output stream for the SessionState file and write the state asynchronously
            StorageFile file = await ApplicationData.Current.LocalFolder.CreateFileAsync(sessionStateFilename, CreationCollisionOption.ReplaceExisting);
            using (Stream fileStream = await file.OpenStreamForWriteAsync())
            {
                sessionData.Seek(0, SeekOrigin.Begin);
                await sessionData.CopyToAsync(fileStream);
                await fileStream.FlushAsync();
            }
        }

        /// <summary>
        /// Restores previously saved <see cref="SessionState"/>.  Any <see cref="Frame"/> instances
        /// registered with <see cref="RegisterFrame"/> will also restore their prior navigation
        /// state, which in turn gives their active <see cref="Page"/> an opportunity restore its
        /// state.
        /// </summary>
        /// <returns>An asynchronous task that reflects when session state has been read.  The
        /// content of <see cref="SessionState"/> should not be relied upon until this task
        /// completes.</returns>
        public static async Task RestoreAsync()
        {
            _sessionState = new Dictionary<String, Object>();

            // Get the input stream for the SessionState file
            StorageFile file = await ApplicationData.Current.LocalFolder.GetFileAsync(sessionStateFilename);
            using (IInputStream inStream = await file.OpenSequentialReadAsync())
            {
                // Deserialize the Session State
                DataContractSerializer serializer = new DataContractSerializer(typeof(Dictionary<string, object>), _knownTypes);
                _sessionState = (Dictionary<string, object>)serializer.ReadObject(inStream.AsStreamForRead());
            }

            // Restore any registered frames to their saved state
            foreach (var weakFrameReference in _registeredFrames)
            {
                Frame frame;
                if (weakFrameReference.TryGetTarget(out frame))
                {
                    frame.ClearValue(FrameSessionStateProperty);
                    RestoreFrameNavigationState(frame);
                }
            }
        }

        private static DependencyProperty FrameSessionStateKeyProperty =
            DependencyProperty.RegisterAttached("_FrameSessionStateKey", typeof(String), typeof(SuspensionManager), null);
        private static DependencyProperty FrameSessionStateProperty =
            DependencyProperty.RegisterAttached("_FrameSessionState", typeof(Dictionary<String, Object>), typeof(SuspensionManager), null);
        private static List<WeakReference<Frame>> _registeredFrames = new List<WeakReference<Frame>>();

        /// <summary>
        /// Registers a <see cref="Frame"/> instance to allow its navigation history to be saved to
        /// and restored from <see cref="SessionState"/>.  Frames should be registered once
        /// immediately after creation if they will participate in session state management.  Upon
        /// registration if state has already been restored for the specified key
        /// the navigation history will immediately be restored.  Subsequent invocations of
        /// <see cref="RestoreAsync"/> will also restore navigation history.
        /// </summary>
        /// <param name="frame">An instance whose navigation history should be managed by
        /// <see cref="SuspensionManager"/></param>
        /// <param name="sessionStateKey">A unique key into <see cref="SessionState"/> used to
        /// store navigation-related information.</param>
        public static void RegisterFrame(Frame frame, String sessionStateKey)
        {
            if (frame.GetValue(FrameSessionStateKeyProperty) != null)
            {
                throw new InvalidOperationException("Frames can only be registered to one session state key");
            }

            if (frame.GetValue(FrameSessionStateProperty) != null)
            {
                throw new InvalidOperationException("Frames must be either be registered before accessing frame session state, or not registered at all");
            }

            // Use a dependency property to associate the session key with a frame, and keep a list of frames whose
            // navigation state should be managed
            frame.SetValue(FrameSessionStateKeyProperty, sessionStateKey);
            _registeredFrames.Add(new WeakReference<Frame>(frame));

            // Check to see if navigation state can be restored
            RestoreFrameNavigationState(frame);
        }

        /// <summary>
        /// Disassociates a <see cref="Frame"/> previously registered by <see cref="RegisterFrame"/>
        /// from <see cref="SessionState"/>.  Any navigation state previously captured will be
        /// removed.
        /// </summary>
        /// <param name="frame">An instance whose navigation history should no longer be
        /// managed.</param>
        public static void UnregisterFrame(Frame frame)
        {
            // Remove session state and remove the frame from the list of frames whose navigation
            // state will be saved (along with any weak references that are no longer reachable)
            SessionState.Remove((String)frame.GetValue(FrameSessionStateKeyProperty));
            _registeredFrames.RemoveAll((weakFrameReference) =>
            {
                Frame testFrame;
                return !weakFrameReference.TryGetTarget(out testFrame) || testFrame == frame;
            });
        }

        /// <summary>
        /// Provides storage for session state associated with the specified <see cref="Frame"/>.
        /// Frames that have been previously registered with <see cref="RegisterFrame"/> have
        /// their session state saved and restored automatically as a part of the global
        /// <see cref="SessionState"/>.  Frames that are not registered have transient state
        /// that can still be useful when restoring pages that have been discarded from the
        /// navigation cache.
        /// </summary>
        /// <remarks>Apps may choose to rely on <see cref="LayoutAwarePage"/> to manage
        /// page-specific state instead of working with frame session state directly.</remarks>
        /// <param name="frame">The instance for which session state is desired.</param>
        /// <returns>A collection of state subject to the same serialization mechanism as
        /// <see cref="SessionState"/>.</returns>
        public static Dictionary<String, Object> SessionStateForFrame(Frame frame)
        {
            var frameState = (Dictionary<String, Object>)frame.GetValue(FrameSessionStateProperty);

            if (frameState == null)
            {
                var frameSessionKey = (String)frame.GetValue(FrameSessionStateKeyProperty);
                if (frameSessionKey != null)
                {
                    // Registered frames reflect the corresponding session state
                    if (!_sessionState.ContainsKey(frameSessionKey))
                    {
                        _sessionState[frameSessionKey] = new Dictionary<String, Object>();
                    }
                    frameState = (Dictionary<String, Object>)_sessionState[frameSessionKey];
                }
                else
                {
                    // Frames that aren't registered have transient state
                    frameState = new Dictionary<String, Object>();
                }
                frame.SetValue(FrameSessionStateProperty, frameState);
            }
            return frameState;
        }

        private static void RestoreFrameNavigationState(Frame frame)
        {
            var frameState = SessionStateForFrame(frame);
            if (frameState.ContainsKey("Navigation"))
            {
                frame.SetNavigationState((String)frameState["Navigation"]);
            }
        }

        private static void SaveFrameNavigationState(Frame frame)
        {
            var frameState = SessionStateForFrame(frame);
            frameState["Navigation"] = frame.GetNavigationState();
        }
    }
}


"@
}

$failPage = {
@"
<Page
    x:Class="PipeworksApp.FailPage"
    xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
    xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
    xmlns:local="using:PipeworksApp"
    xmlns:d="http://schemas.microsoft.com/expression/blend/2008"
    xmlns:mc="http://schemas.openxmlformats.org/markup-compatibility/2006"
    mc:Ignorable="d">

    <Grid Background="{StaticResource ApplicationPageBackgroundThemeBrush}">
        <Grid.RowDefinitions>
            <RowDefinition Height="80" />
            <RowDefinition Height="80" />
            <RowDefinition Height="1*" />
            <RowDefinition Height="1*" />
            <RowDefinition Height="80" />
        </Grid.RowDefinitions>
        <Grid.ColumnDefinitions>
            <ColumnDefinition Width="80" />
            <ColumnDefinition Width="1*" />
            <ColumnDefinition Width="1*" />
            <ColumnDefinition Width="80" />
        </Grid.ColumnDefinitions>
        <TextBlock FontSize="72" Foreground="#e90000" Grid.Column="1" Grid.Row="1" Grid.ColumnSpan="2">
            It's not you, it's me.
        </TextBlock>
        <TextBlock FontSize="48" Foreground="#e90000" Grid.Column="1" Grid.ColumnSpan="2" Grid.Row="2" HorizontalAlignment="Right" TextWrapping="Wrap">
            I didn't expeect this to happen, really.  But something went wrong.  An unexepected problem came up, and now I'm all broken up.                        
        </TextBlock>

        <TextBlock FontSize="48" Foreground="#e90000" Grid.Column="1" Grid.ColumnSpan="2" Grid.Row="2" VerticalAlignment="Bottom" TextWrapping="Wrap">
            This is all I know:
        </TextBlock>
        <TextBlock FontSize="36" Foreground="#e90000" Grid.Column="1" Grid.ColumnSpan="2" Grid.Row="3" Margin="20 20 20 20" x:Name="errorTextHolder" TextWrapping="Wrap"></TextBlock>
    </Grid>
</Page>
"@
}


$failPageCodeBehind = {
@"
using System;
using System.Collections.Generic;
using System.IO;
using System.Linq;
using Windows.Foundation;
using Windows.Foundation.Collections;
using Windows.UI.Xaml;
using Windows.UI.Xaml.Controls;
using Windows.UI.Xaml.Controls.Primitives;
using Windows.UI.Xaml.Data;
using Windows.UI.Xaml.Input;
using Windows.UI.Xaml.Media;
using Windows.UI.Xaml.Navigation;

// The Blank Page item template is documented at http://go.microsoft.com/fwlink/?LinkId=234238

namespace PipeworksApp
{
    /// <summary>
    /// An empty page that can be used on its own or navigated to within a Frame.
    /// </summary>
    public sealed partial class FailPage : Page
    {
        public FailPage()
        {
            this.InitializeComponent();
        }

        /// <summary>
        /// Invoked when this page is about to be displayed in a Frame.
        /// </summary>
        /// <param name="e">Event data that describes how this page was reached.  The Parameter
        /// property is typically used to configure the page.</param>
        protected override void OnNavigatedTo(NavigationEventArgs e)
        {
            if (e.Parameter is Exception)
            {
                Exception ex = e.Parameter as Exception;
                this.errorTextHolder.Text = ex.Message;
            }
            if (e.Parameter is string)
            {
                this.errorTextHolder.Text = e.Parameter as string;
            }
        }
    }
}

"@
}


$itemsPageXaml = {
@"


<common:LayoutAwarePage
    x:Name="pageRoot"
    x:Class="PipeworksApp.ItemsPage"
    DataContext="{Binding DefaultViewModel, RelativeSource={RelativeSource Self}}"
    IsTabStop="false"
    xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
    xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
    xmlns:local="using:PipeworksApp"
    xmlns:common="using:PipeworksApp.Common"
    xmlns:d="http://schemas.microsoft.com/expression/blend/2008"
    xmlns:mc="http://schemas.openxmlformats.org/markup-compatibility/2006"
    xmlns:UI="using:Microsoft.Advertising.WinRT.UI"

    mc:Ignorable="d">

    <Page.Resources>
        <!-- light blue -->
        <SolidColorBrush x:Key="BlockBackgroundBrush" Color="#FF557EB9"/>

        <!-- Grid Styles -->
        <Style x:Key="GridTitleTextStyle" TargetType="TextBlock" BasedOn="{StaticResource BasicTextStyle}">
            <Setter Property="FontSize" Value="26.667"/>
            <Setter Property="Margin" Value="12,0,12,2"/>
        </Style>

        <Style x:Key="GridDescriptionTextStyle" TargetType="TextBlock" BasedOn="{StaticResource BasicTextStyle}">
            <Setter Property="VerticalAlignment" Value="Bottom"/>
            <Setter Property="Margin" Value="12,0,12,60"/>
        </Style>

        <DataTemplate x:Key="DefaultGridItemTemplate">
            <Grid HorizontalAlignment="Left" Width="250" Height="250">
                <Grid.RowDefinitions>
                    
                    <RowDefinition Height="2*" />
                    <RowDefinition Height="1*" />                    
                </Grid.RowDefinitions>
                <Border BorderThickness="3" BorderBrush="{Binding ForegroundColor}" Grid.RowSpan="3" CornerRadius="6"/>

                <Rectangle Fill="{Binding ForegroundColor}" Grid.Row="1" Grid.RowSpan="2" HorizontalAlignment="Stretch" Margin="2"/>
                <TextBlock Text="{Binding Name}" Foreground="{Binding ForegroundColor}" FontSize="20" Margin="12,12,12,14" TextWrapping="Wrap" Grid.Row="0" />
                
            </Grid>
        </DataTemplate>

        <!-- Used in Snapped view -->
        <DataTemplate x:Key="NarrowListItemTemplate">
            <Grid Height="80" >
                <Grid.ColumnDefinitions>
                    <ColumnDefinition Width="1*"/>
                    
                </Grid.ColumnDefinitions>
                <Border BorderThickness="3" BorderBrush="{Binding ForegroundColor}" Grid.ColumnSpan="2" CornerRadius="6"/>
                <TextBlock Text="{Binding Name}" MaxHeight="56" Foreground="{Binding ForegroundColor}" Grid.ColumnSpan="2" Margin="25 0 25 0" HorizontalAlignment="Stretch" VerticalAlignment="Center" FontSize="24"/>                
            </Grid>
        </DataTemplate>

        <!-- Collection of items displayed by this page -->
        <CollectionViewSource
            x:Name="itemsViewSource"
            Source="{Binding Items}"/>

        <!-- TODO: Delete this line if the key AppName is declared in App.xaml -->
        
    </Page.Resources>

    <!--
        This grid acts as a root panel for the page that defines two rows:
        * Row 0 contains the back button and page title
        * Row 1 contains the rest of the page layout
    -->
    <Grid x:Name="MainGrid" Background="{Binding Background}">
        <Grid.RowDefinitions>
            <RowDefinition Height="140"/>
            <RowDefinition Height="*"/>
            <RowDefinition Height="Auto" />
        </Grid.RowDefinitions>

        
        <!-- Back button and page title -->
        <Grid>
            <Grid.ColumnDefinitions>
                <ColumnDefinition Width="Auto"/>
                <ColumnDefinition Width="*"/>
            </Grid.ColumnDefinitions>
            <Button x:Name="backButton" Click="GoBack" IsEnabled="{Binding Frame.CanGoBack, ElementName=pageRoot}" Style="{StaticResource BackButtonStyle}" Grid.Row="1" Grid.RowSpan="2">
                <Grid>
                    
                    <TextBlock Text="&#xE071;" FontFamily="Segoe UI Symbol" FontSize="38" Foreground="{Binding Foreground}"></TextBlock>
                </Grid>
                
                
            </Button>
            
            <Grid Grid.Column="1">
                
                <Grid.ColumnDefinitions>
                    <ColumnDefinition Width="Auto" MaxWidth="150" />
                    <ColumnDefinition Width="*" />                    
                </Grid.ColumnDefinitions>
                <Image Source="Assets/squaretile.png" MaxWidth="125" MaxHeight="125" Grid.Column="0" Margin="15 0 15 0" />
                <Grid Grid.Column="1" >
                    <Grid.RowDefinitions>
                        <RowDefinition Height="Auto" />
                        <RowDefinition Height="Auto" />
                    </Grid.RowDefinitions>
                    <Grid.ColumnDefinitions>
                        <ColumnDefinition Width="1*" />
                        <ColumnDefinition Width="Auto" />    
                    </Grid.ColumnDefinitions>
                    <TextBlock x:Name="pageTitle" Grid.Row="0" Text="{Binding Name}" Style="{StaticResource PageHeaderTextStyle}" Margin="0 25 0 5" Foreground="{Binding Foreground}" VerticalAlignment="Center"/>
                    <TextBlock x:Name="pageDescription" Grid.Row="1" Text="{Binding Description}" TextWrapping="Wrap" Style="{StaticResource PageSubheaderTextStyle}" Margin="6 6 0 0" Foreground="{Binding Foreground}" VerticalAlignment="Center" Grid.RowSpan="2"/>
                    <Button Grid.Column="1" Grid.RowSpan="2" Click="Button_Click_1" x:Name="FacebookLoginStatus" IsEnabled="False" Visibility="Collapsed">
                        <Button.Content>
                            <StackPanel>
                                <Image Source="Assets/f_logo.png" MaxWidth="75" MaxHeight="75"/>
                                <TextBlock Foreground="{Binding Foreground}">My Profile</TextBlock>
                            </StackPanel>
                        </Button.Content>
                    </Button>
                    
                </Grid>
                
            </Grid>                  
            
        </Grid>

        <!-- Horizontal scrolling grid used in most view states -->
        <GridView
            x:Name="itemGridView"
            AutomationProperties.AutomationId="ItemsGridView"
            AutomationProperties.Name="Items"
            Grid.Row="1"
            Margin="0,-4,0,0"
            Padding="116,0,116,46"
            ItemsSource="{Binding Source={StaticResource itemsViewSource}}"
            ItemTemplate="{StaticResource DefaultGridItemTemplate}"
            SelectionMode="None" 
            IsItemClickEnabled="True" 
            ItemClick="ItemView_ItemClick"/>

        <!-- Vertical scrolling list only used when snapped -->
        <ListView
            x:Name="itemListView"
            AutomationProperties.AutomationId="ItemsListView"
            AutomationProperties.Name="Items"
            Grid.Row="1"
            Visibility="Collapsed"
            Margin="0,-10,0,0"
            Padding="10,0,0,60"
            ItemsSource="{Binding Source={StaticResource itemsViewSource}}"
            ItemTemplate="{StaticResource NarrowListItemTemplate}" 
            SelectionMode="None" 
            IsItemClickEnabled="True" 
            ItemClick="ItemView_ItemClick"/>

        <WebView Visibility="Collapsed" Grid.Row="1" x:Name="ProfileWebView"></WebView>

        <Grid Visibility="Collapsed" Grid.Row="2" Grid.Column="1" x:Name="itemsPageAdHolder">
            <UI:AdControl x:Name="itemsPageAdControl" Visibility="Collapsed" IsAutoRefreshEnabled="True" Width="728" Height="90">

            </UI:AdControl>
        </Grid>
        
        
        <VisualStateManager.VisualStateGroups>

            <!-- Visual states reflect the application's view state -->
            <VisualStateGroup x:Name="ApplicationViewStates">
                <VisualState x:Name="FullScreenLandscape"/>
                <VisualState x:Name="Filled"/>

                <!-- The entire page respects the narrower 100-pixel margin convention for portrait -->
                <VisualState x:Name="FullScreenPortrait">
                    <Storyboard>
                        <ObjectAnimationUsingKeyFrames Storyboard.TargetName="itemGridView" Storyboard.TargetProperty="Padding">
                            <DiscreteObjectKeyFrame KeyTime="0" Value="96,0,86,56"/>
                        </ObjectAnimationUsingKeyFrames>

                        <ObjectAnimationUsingKeyFrames Storyboard.TargetName="pageDescription" Storyboard.TargetProperty="Visibility">
                            <DiscreteObjectKeyFrame KeyTime="0" Value="Visible"/>
                        </ObjectAnimationUsingKeyFrames>

                    </Storyboard>
                </VisualState>

                <!--
                    The back button and title have different styles when snapped, and the list representation is substituted
                    for the grid displayed in all other view states
                -->
                <VisualState x:Name="Snapped">
                    <Storyboard>
                        <ObjectAnimationUsingKeyFrames Storyboard.TargetName="pageTitle" Storyboard.TargetProperty="Style">
                            <DiscreteObjectKeyFrame KeyTime="0" Value="{StaticResource SnappedPageHeaderTextStyle}"/>
                        </ObjectAnimationUsingKeyFrames>

                        <ObjectAnimationUsingKeyFrames Storyboard.TargetName="pageDescription" Storyboard.TargetProperty="Visibility">
                            <DiscreteObjectKeyFrame KeyTime="0" Value="Collapsed"/>
                        </ObjectAnimationUsingKeyFrames>
                        <ObjectAnimationUsingKeyFrames Storyboard.TargetName="itemListView" Storyboard.TargetProperty="Visibility">
                            <DiscreteObjectKeyFrame KeyTime="0" Value="Visible"/>
                        </ObjectAnimationUsingKeyFrames>
                        <ObjectAnimationUsingKeyFrames Storyboard.TargetName="itemGridView" Storyboard.TargetProperty="Visibility">
                            <DiscreteObjectKeyFrame KeyTime="0" Value="Collapsed"/>
                        </ObjectAnimationUsingKeyFrames>
                    </Storyboard>
                </VisualState>
            </VisualStateGroup>
        </VisualStateManager.VisualStateGroups>
    </Grid>
</common:LayoutAwarePage>
"@
}

$itemsPageCodeBehind = {
@"

using System;
using System.Collections.Generic;
using System.Globalization;
using System.IO;
using System.Linq;
using Windows.Devices.Sensors;
using Windows.Foundation;
using Windows.Foundation.Collections;
using Windows.UI;
using Windows.UI.Core;
using Windows.UI.Xaml;
using Windows.UI.Xaml.Controls;
using Windows.UI.Xaml.Controls.Primitives;
using Windows.UI.Xaml.Data;
using Windows.UI.Xaml.Input;
using Windows.UI.Xaml.Media;
using Windows.UI.Xaml.Navigation;

// The Items Page item template is documented at http://go.microsoft.com/fwlink/?LinkId=234233

namespace PipeworksApp
{
    /// <summary>
    /// A page that displays a collection of item previews.  In the Split Application this page
    /// is used to display and select one of the available groups.
    /// </summary>
    public sealed partial class ItemsPage : PipeworksApp.Common.LayoutAwarePage
    {
        public ItemsPage()
        {
            this.InitializeComponent();
        }

        /// <summary>
        /// Populates the page with content passed during navigation.  Any saved state is also
        /// provided when recreating a page from a prior session.
        /// </summary>
        /// <param name="navigationParameter">The parameter value passed to
        /// <see cref="Frame.Navigate(Type, Object)"/> when this page was initially requested.
        /// </param>
        /// <param name="pageState">A dictionary of state preserved by this page during an earlier
        /// session.  This will be null the first time a page is visited.</param>
        protected override void LoadState(Object navigationParameter, Dictionary<String, Object> pageState)
        {
            // TODO: Assign a bindable collection of items to this.DefaultViewModel["Items"]            
            PipeworksDataSource feedDataSource = (PipeworksDataSource)App.Current.Resources["feedDataSource"];

            if (feedDataSource != null)
            {
                this.DefaultViewModel["Items"] = feedDataSource.Items;
                this.DefaultViewModel["Name"] = feedDataSource.Name;
                this.DefaultViewModel["Description"] = feedDataSource.Description;
                this.DefaultViewModel["ServiceUrl"] = feedDataSource.ServiceUrl;
                this.DefaultViewModel["Data"] = feedDataSource;
                if (feedDataSource.Logo != null)
                {
                    this.DefaultViewModel["Logo"] = feedDataSource.Logo;
                    this.pageTitle.Visibility = Windows.UI.Xaml.Visibility.Collapsed;
                }
                else
                {
                    this.pageTitle.Visibility = Windows.UI.Xaml.Visibility.Visible;
                    
                }


                if (!String.IsNullOrEmpty(feedDataSource.FacebookAppId))
                {
                    this.DefaultViewModel["FacebookAppId"] = feedDataSource.FacebookAppId;
                }

                if (!String.IsNullOrEmpty(feedDataSource.FacebookScope))
                {
                    this.DefaultViewModel["FacebookScope"] = feedDataSource.FacebookScope;
                }

                if (feedDataSource.PubCenterID != null && feedDataSource.BottomAdUnit != null)
                {
                    // Display advertising section

                    this.itemsPageAdControl.Margin = new Thickness(12);
                    this.itemsPageAdControl.ApplicationId = feedDataSource.PubCenterID;
                    this.itemsPageAdControl.AdUnitId = feedDataSource.BottomAdUnit;
                    this.itemsPageAdControl.Visibility = Visibility.Visible;
                    this.itemsPageAdHolder.Visibility = Visibility.Visible;
                    App.Current.Resources["PubCenterID"] = feedDataSource.PubCenterID;
                    App.Current.Resources["AdUnitID"] = feedDataSource.BottomAdUnit;
                }

                
                // this.Resources["ForegroundColor"] = feedDataSource.ForegroundColor; 
                this.DefaultViewModel["Background"] = feedDataSource.BackgroundColor;
                this.DefaultViewModel["Foreground"] = feedDataSource.ForegroundColor;
                //this.DefaultViewModel["PrimaryColor"] = feedDataSource.ForegroundColor;


                if (feedDataSource.CommandTrigger.ContainsKey("Shake") && theAccelerometer != null)
                {
                    foreach (var cmdTrigger in feedDataSource.CommandTrigger)
                    {
                        if ((String.Compare(cmdTrigger.Key, "Shake", StringComparison.CurrentCultureIgnoreCase) == 0))
                        {
                            if (theAccelerometer != null)
                            {
                                theAccelerometer.Shaken += new TypedEventHandler<Accelerometer, AccelerometerShakenEventArgs>(acceleromter_Shaken);
                            }
                            
                        }
                    }
                    
                }


                
                // this.MainGrid.Background = new SolidColorBrush(
                var solid = new SolidColorBrush();
                string trimmedColor = feedDataSource.BackgroundColor.TrimStart('#');
                char[] bgColorChars = trimmedColor.ToCharArray();
                Color bgActual = new Color();
                bgActual.R = (Byte)((Byte.Parse(bgColorChars[0].ToString(), NumberStyles.HexNumber, CultureInfo.CurrentUICulture) * 16) + (Byte.Parse(bgColorChars[1].ToString(), NumberStyles.HexNumber, CultureInfo.CurrentUICulture)));
                bgActual.G = (Byte)((Byte.Parse(bgColorChars[2].ToString(), NumberStyles.HexNumber, CultureInfo.CurrentUICulture) * 16) + (Byte.Parse(bgColorChars[3].ToString(), NumberStyles.HexNumber, CultureInfo.CurrentUICulture)));
                bgActual.B = (Byte)((Byte.Parse(bgColorChars[4].ToString(), NumberStyles.HexNumber, CultureInfo.CurrentUICulture) * 16) + (Byte.Parse(bgColorChars[5].ToString(), NumberStyles.HexNumber, CultureInfo.CurrentUICulture)));
                bgActual.A = 255;
                solid.Color = bgActual;
                trimmedColor = feedDataSource.ForegroundColor.TrimStart('#');
                char[] fgColorChars = trimmedColor.ToCharArray();
                Color fgActual = new Color();
                fgActual.R = (Byte)((Byte.Parse(fgColorChars[0].ToString(), NumberStyles.HexNumber, CultureInfo.CurrentUICulture) * 16) + (Byte.Parse(fgColorChars[1].ToString(), NumberStyles.HexNumber, CultureInfo.CurrentUICulture)));
                fgActual.G = (Byte)((Byte.Parse(fgColorChars[2].ToString(), NumberStyles.HexNumber, CultureInfo.CurrentUICulture) * 16) + (Byte.Parse(fgColorChars[3].ToString(), NumberStyles.HexNumber, CultureInfo.CurrentUICulture)));
                fgActual.B = (Byte)((Byte.Parse(fgColorChars[4].ToString(), NumberStyles.HexNumber, CultureInfo.CurrentUICulture) * 16) + (Byte.Parse(fgColorChars[5].ToString(), NumberStyles.HexNumber, CultureInfo.CurrentUICulture)));
                fgActual.A = 255;
                this.Resources["BackgroundColor"] = new SolidColorBrush(bgActual);
                this.Resources["ForegroundColor"] = new SolidColorBrush(fgActual);

                SolidColorBrush comboBoxBackgroundBrush = App.Current.Resources["ComboBoxItemSelectedBackgroundThemeBrush"] as SolidColorBrush;
                comboBoxBackgroundBrush.Color = bgActual;
                App.Current.Resources["ComboBoxItemSelectedBackgroundThemeBrush"] = new SolidColorBrush(bgActual);
                App.Current.Resources["ComboBoxPopupBackgroundThemeBrush"] = new SolidColorBrush(bgActual);
                App.Current.Resources["ComboBoxBackgroundThemeBrush"] = new SolidColorBrush(bgActual); 
                App.Current.Resources["ComboBoxSelectedPointerOverBackgroundThemeBrush"] = new SolidColorBrush(bgActual);
                App.Current.Resources["DefaultTextForegroundThemeBrush"] = new SolidColorBrush(fgActual);
                App.Current.Resources["RadioButtonBorderThemeBrush"] = new SolidColorBrush(fgActual);
                App.Current.Resources["RadioButtonPressedBorderThemeBrush"] = new SolidColorBrush(fgActual);
                App.Current.Resources["RadioButtonDisabledBorderThemeBrush"] = new SolidColorBrush(fgActual);
                App.Current.Resources["RadioButtonContentForegroundThemeBrush"] = new SolidColorBrush(fgActual);
                App.Current.Resources["RadioButtonBackgroundThemeBrush"] = new SolidColorBrush(bgActual);
                App.Current.Resources["RadioButtonForegroundThemeBrush"] = new SolidColorBrush(fgActual);
                App.Current.Resources["TheBackgroundColor"] = new SolidColorBrush(bgActual);
                App.Current.Resources["TheForegroundColor"] = new SolidColorBrush(fgActual);
                App.Current.Resources["ButtonBorderThemeBrush"] = new SolidColorBrush(fgActual);
                App.Current.Resources["TextBoxBorderThemeBrush"] = new SolidColorBrush(fgActual);
                App.Current.Resources["TextBoxForegroundThemeBrush"] = new SolidColorBrush(fgActual);
                App.Current.Resources["TextBoxDisabledForegroundThemeBrush"] = new SolidColorBrush(fgActual);
                App.Current.Resources["TextBlockForegroundThemeBrush"] = new SolidColorBrush(fgActual);
                App.Current.Resources["TextBoxBackgroundThemeBrush"] = new SolidColorBrush(bgActual);
                App.Current.Resources["TextBoxButtonForegroundThemeBrush"] = new SolidColorBrush(fgActual);
                App.Current.Resources["BorderBackgroundThemeBrush"] = new SolidColorBrush(bgActual);
                App.Current.Resources["BorderForegroundThemeBrush"] = new SolidColorBrush(fgActual);
                App.Current.Resources["ApplicationForegroundThemeBrush"] = new SolidColorBrush(fgActual);
                App.Current.Resources["ButtonForegroundThemeBrush"] = new SolidColorBrush(fgActual);
                App.Current.Resources["ButtonBackgroundThemeBrush"] = new SolidColorBrush(fgActual);
                SolidColorBrush comboBoxPointerBrush = App.Current.Resources["ComboBoxItemSelectedPointerOverBackgroundThemeBrush"] as SolidColorBrush;
                comboBoxPointerBrush.Color = bgActual;
                App.Current.Resources["ComboBoxItemSelectedPointerOverBackgroundThemeBrush"] = new SolidColorBrush(bgActual);                 

                SolidColorBrush comboBoxForegroundBrush = App.Current.Resources["ComboBoxItemSelectedForegroundThemeBrush"] as SolidColorBrush;
                
                comboBoxForegroundBrush.Color = fgActual;
                App.Current.Resources["ComboBoxItemSelectedForegroundThemeBrush"] = new SolidColorBrush(fgActual); ;
                App.Current.Resources["ComboBoxFocusedBackgroundThemeBrush"] = new SolidColorBrush(fgActual); ;
                App.Current.Resources["ComboBoxPointerOverBackgroundThemeBrush"] = new SolidColorBrush(fgActual);
                App.Current.Resources["ComboBoxFocusedForegroundThemeBrush"] = new SolidColorBrush(bgActual);
                App.Current.Resources["ComboBoxArrowForegroundThemeBrush"] = new SolidColorBrush(fgActual);
                App.Current.Resources["ComboBoxPressedHighlightThemeBrush"] = new SolidColorBrush(fgActual);
                App.Current.Resources["ComboBoxItemPressedBackgroundThemeBrush"] = new SolidColorBrush(bgActual); 
                App.Current.Resources["BackgroundColor"] = new SolidColorBrush(bgActual);
                App.Current.Resources["ForegroundColor"] = new SolidColorBrush(fgActual);
                //this.MainGrid.Background = solid;
                //this.pageTitle.Foreground = new SolidColorBrush(fgActual);
                //this.pageDescription.Foreground = new SolidColorBrush(fgActual);

                this.DefaultViewModel["CopyrightNotice"] = feedDataSource.Copyright + " " +feedDataSource.Company;
            }
        }

        async void acceleromter_Shaken(Accelerometer sender, AccelerometerShakenEventArgs args)
        {

            await Dispatcher.RunAsync(CoreDispatcherPriority.Normal, () =>
            {
                PipeworksDataSource pds = PipeworksDataSource.GetDatasource();
                foreach (var cmdTrigger in pds.CommandTrigger)
                {
                    if (String.Compare(cmdTrigger.Key, "Shake", StringComparison.OrdinalIgnoreCase) == 0)
                    {
                        this.Frame.Navigate(typeof(SplitPage), cmdTrigger.Value);
                    }
                }
            });
            
            
        }

        private void ItemView_ItemClick(object sender, ItemClickEventArgs e)
        {
            // Navigate to the split page, configuring the new page
            // by passing the title of the clicked item as a navigation parameter
            
            if (e.ClickedItem != null)
            {
                string title = ((PipeworksItem)e.ClickedItem).Name;
                
                   this.Frame.Navigate(typeof(SplitPage), title);
//                }
                
            }
        }

        private async void Button_Click_1(object sender, RoutedEventArgs e)
        {
            //this.itemGridView.Visibility = Windows.UI.Xaml.Visibility.Collapsed;
            //this.itemListView.Visibility = Windows.UI.Xaml.Visibility.Collapsed;
            this.Frame.Navigate(typeof(SplitPage), "Me");
            //string serviceUrl = this.DefaultViewModel["ServiceUrl"].ToString();
            //string facebookAppId = this.DefaultViewModel["FacebookAppId"].ToString();
            //string facebookScope = this.DefaultViewModel["FacebookScope"].ToString();
            //PipeworksDataSource feedDataSource = (PipeworksDataSource)App.Current.Resources["feedDataSource"];
            //string accessToken = await feedDataSource.GetFacebookAccessToken(facebookAppId, serviceUrl, facebookScope);
        }
    }
}

"@
}

$pipeworksDataModel = {
    param(
        $PipeworksUrl = "http://powershellpipeworks.com/",
        $DefaultManifest,
        $Fittings
    )

if (-not $DefaultManifest) {
    $DefaultManifest = Get-Web "$PipeworksUrl/?-GetManifest"
}

$pdm = 
@"
using System;
using System.Collections.Generic;
using System.Collections.ObjectModel;
using System.ComponentModel;
using System.IO;
using System.Linq;
using System.Net;
using System.Runtime.CompilerServices;
using System.Text;
using System.Text.RegularExpressions;
using System.Threading.Tasks;
using Windows.Data.Xml.Dom;
using Windows.Foundation;
using Windows.Globalization.DateTimeFormatting;
using Windows.Networking.Connectivity;
using Windows.Security.Authentication.OnlineId;
using Windows.Security.Authentication.Web;
using Windows.Storage;

namespace PipeworksApp
{

    /// <summary>
    /// Implementation of <see cref="INotifyPropertyChanged"/> to simplify models.
    /// </summary>
    [Windows.Foundation.Metadata.WebHostHidden]
    public abstract class BindableBase : INotifyPropertyChanged
    {
        /// <summary>
        /// Multicast event for property change notifications.
        /// </summary>
        public event PropertyChangedEventHandler PropertyChanged;

        /// <summary>
        /// Checks if a property already matches a desired value.  Sets the property and
        /// notifies listeners only when necessary.
        /// </summary>
        /// <typeparam name="T">Type of the property.</typeparam>
        /// <param name="storage">Reference to a property with both getter and setter.</param>
        /// <param name="value">Desired value for the property.</param>
        /// <param name="propertyName">Name of the property used to notify listeners.  This
        /// value is optional and can be provided automatically when invoked from compilers that
        /// support CallerMemberName.</param>
        /// <returns>True if the value was changed, false if the existing value matched the
        /// desired value.</returns>
        protected bool SetProperty<T>(ref T storage, T value, [CallerMemberName] String propertyName = null)
        {
            if (object.Equals(storage, value)) return false;

            storage = value;
            this.OnPropertyChanged(propertyName);
            return true;
        }

        /// <summary>
        /// Notifies listeners that a property value has changed.
        /// </summary>
        /// <param name="propertyName">Name of the property used to notify listeners.  This
        /// value is optional and can be provided automatically when invoked from compilers
        /// that support <see cref="CallerMemberNameAttribute"/>.</param>
        protected void OnPropertyChanged([CallerMemberName] string propertyName = null)
        {
            var eventHandler = this.PropertyChanged;
            if (eventHandler != null)
            {
                eventHandler(this, new PropertyChangedEventArgs(propertyName));
            }
        }
    }

    public class PipeworksData
    {
        public string Name { get; set; }
        public string Description { get; set; }
        public string Company { get; set; }
        public string Version { get; set; }
        public string DirectDownload { get; set; }
        public string ForegroundColor { get; set; }
        public string SecondaryColor { get; set; }
        public string BackgroundColor { get; set; }
        public string Copyright { get; set; }
        public string Author { get; set; }
        public string FacebookAppId { get; set; }
        public string FacebookScope { get; set; }

        public bool CanLogin { get; set; }

        public Uri Logo { get; set; }
        public Uri ServiceUrl { get; set; } 
        public string Xml { get; set; } 

        private List<PipeworksItem> _Items = new List<PipeworksItem>();
        public List<PipeworksItem> Items
        {
            get
            {
                return this._Items;
            }
        }

        private Dictionary<string, PipeworksItem> _ItemsByName = new Dictionary<string, PipeworksItem>(StringComparer.CurrentCultureIgnoreCase);
        public Dictionary<string, PipeworksItem> ItemsByName
        {
            get
            {
                return this._ItemsByName;
            }
        }
    }


    public class PipeworksCommand : PipeworksItem
    {
        public bool RequiresLogin { get; set; }
        public string RealName { get; set; } 
        public bool Hidden { get; set; }
        public bool RunWithoutInput;
        public string RedirectTo { get; set; }
        public TimeSpan RedirectIn { get; set; } 
    }

    public class PipeworksCommandGroup : PipeworksItem
    {
        public string[] CommandName { get; set; }
        public PipeworksCommand[] Commands { get; set; } 
    }

    public class PipeworksTopicGroup : PipeworksItem
    {
        public string[] TopicName { get; set; }
        public PipeworksTopic[] Topics { get; set; } 
    }



    public class PipeworksTopic : PipeworksItem
    {
        
    }

    public class PipeworksWalkthruStep : PipeworksItem
    {
        public string Script { get; set; }
        public string Explanation { get; set; } 
        public string Video { get ; set; } 
    }

    public class PipeworksWalkthru : PipeworksTopic
    {
        private List<PipeworksWalkthruStep> _Steps = new List<PipeworksWalkthruStep>();
        public List<PipeworksWalkthruStep> Steps
        {
            get
            {
                return this._Steps;
            }
        }
        
    }

    public class PipeworksItem
    {
        public string Name { get; set; }
        public string Author { get; set; }
        public string Content { get; set; }
        public DateTime PubDate { get; set; }
        public Uri Url { get; set; }
        public string BackgroundColor { get; set; }
        public string ForegroundColor { get; set; } 
    }

    public class PipeworksBlogItem : PipeworksItem
    {
    }

    public class PipeworksBlog : PipeworksItem
    {
        private List<PipeworksBlogItem> _Items = new List<PipeworksBlogItem>();
        public List<PipeworksBlogItem> Items
        {
            get
            {
                return this._Items;
            }
        }

    }

    // FeedDataSource
    // Holds a collection of blog feeds (FeedData), and contains methods needed to
    // retreive the feeds.
    public class PipeworksDataSource
    {
        //private static FeedDataSource _feedDataSource = new FeedDataSource();

        private ObservableCollection<PipeworksData> _PipeworksData = new ObservableCollection<PipeworksData>();
        public ObservableCollection<PipeworksData> PipeworksData
        {
            get
            {
                return this._PipeworksData;
            }
        }

        private List<PipeworksItem> _Items = new List<PipeworksItem>();
        public List<PipeworksItem> Items
        {
            get
            {
                return this._Items;
            }
        }


        public async Task<List<PipeworksBlogItem>> GetRssFeedAsync(string rssUrl)
        {
            string fullmoduleUriString = rssUrl;
            string result = String.Empty;
            var req = HttpWebRequest.CreateHttp(fullmoduleUriString);
            WebResponse response = await req.GetResponseAsync();

            Stream responseStream = response.GetResponseStream();

            using (StreamReader reader = new StreamReader(responseStream))
            {
                result = reader.ReadToEnd();
                
            }
            response.Dispose();

            StorageFile manifestXmlFile = await Windows.Storage.ApplicationData.Current.LocalFolder.CreateFileAsync("LatestFeed.xml", CreationCollisionOption.ReplaceExisting);
            await FileIO.WriteTextAsync(manifestXmlFile, result);
            StorageFile moduleUriFile = await Windows.Storage.ApplicationData.Current.LocalFolder.CreateFileAsync("LatestFeedUrl.txt", CreationCollisionOption.ReplaceExisting);
            await FileIO.WriteTextAsync(moduleUriFile, rssUrl);


            Task<List<PipeworksBlogItem>> returnDataTask =
                ParseRssAsync(result, new Uri(rssUrl));

            List<PipeworksBlogItem> returnData = await returnDataTask;
            foreach (PipeworksBlogItem bi in returnData) {
                this.BlogItems.Add(bi);
            }
            

            
            

            return returnData;

        }

        public async Task GetModulesAsync()
        {
            ConnectionProfile profile = NetworkInformation.GetInternetConnectionProfile();
            Uri moduleDefaultUri = new Uri("$pipeworksUrl");
            PipeworksData item;
            Task<PipeworksData> pipeworksInfo;
            if (profile == null)
            {
                try
                {
                    StorageFile manifestXmlFile = await ApplicationData.Current.LocalFolder.GetFileAsync("ModuleManifest.xml");
                    string manifestXml = await FileIO.ReadTextAsync(manifestXmlFile);
                    StorageFile moduleUriFile = await ApplicationData.Current.LocalFolder.GetFileAsync("ModuleUri.txt");
                    string moduleUri = await FileIO.ReadTextAsync(moduleUriFile);
                    pipeworksInfo = ParseModuleXmlAsync(manifestXml, new Uri(moduleUri));
                }
                catch
                {
                    string manifestXml = @"DEFAULT_MANIFEST_XML";
                    pipeworksInfo = ParseModuleXmlAsync(manifestXml, moduleDefaultUri);
                }
            }
            else
            {
                pipeworksInfo  =
                    GetModuleAsync(moduleDefaultUri.ToString());




                
    
            }

            item = (await pipeworksInfo);
            
            
            this.Xml = item.Xml;
            this.Name = item.Name;
            this.Logo = item.Logo;
            this.Version = item.Version;
            this.DirectDownload = item.DirectDownload;
            this.Description = item.Description;
            this.ForegroundColor = item.ForegroundColor;
            this.SecondaryColor = item.SecondaryColor;
            this.BackgroundColor = item.BackgroundColor;
            this.Copyright = item.Copyright;
            this.Company = item.Company;
            this.Author = item.Author;
            this.ServiceUrl = item.ServiceUrl;
            this.FacebookScope = item.FacebookScope;
            this.FacebookAppId = item.FacebookAppId;
        


            foreach (var itemToCopy in item.Items)
            {
                this.Items.Add(itemToCopy);
            }
            


        }

        public string DefaultModuleManifest { get; set; }
        public string CachedRSSFeed { get; set; } 
        
        public bool CanLogin { get; set; }
        public bool CurrentlyLoggedIn { get; set; }
        public Uri ServiceUrl { get; set; } 
        public string Name { get; set; }
        public string Description { get; set; }
        public string Company { get; set; }
        public string Version { get; set; }
        public string DirectDownload { get; set; }
        public Uri Logo { get; set; }
        public string ForegroundColor { get; set; }
        public string SecondaryColor { get; set; }
        public string BackgroundColor { get; set; }
        public string Copyright { get; set; }
        public string Author { get; set; }
        public string Xml { get; set; }

        public string RssFeed { get; set; }

        private List<PipeworksBlogItem> _BlogItems = new List<PipeworksBlogItem>();
        public List<PipeworksBlogItem> BlogItems
        {
            get
            {
                return this._BlogItems;
            }
        }


        public PipeworksBlog Blog { get; set; }

        private List<PipeworksBlog> _Feeds = new List<PipeworksBlog>();
        public List<PipeworksBlog> Feeds
        {
            get
            {
                return this._Feeds;
            }
        }


        public string PubCenterID { get; set; }
        public string BottomAdUnit { get; set; }
        

        public string FacebookAppId { get; set; }
        public string FacebookScope { get; set; }
        
        public string CurrentLiveIDAccessToken { get; set; }
        public string LiveLoginScope { get; set; } 


        public string CurrentFacebookAccessToken { get; set; }
        public DateTime FacebookAccessTokenAquiredAt { get; set; }
        public DateTime FacebookAccessTokenExpiresdAt { get; set; }


        private Dictionary<string, PipeworksCommand> commandTrigger = new Dictionary<string, PipeworksCommand>(StringComparer.CurrentCultureIgnoreCase);
        public Dictionary<string, PipeworksCommand> CommandTrigger
        {
            get
            {
                return this.commandTrigger;
            }
        }

        private Dictionary<string, PipeworksItem> _ItemsByName = new Dictionary<string, PipeworksItem>(StringComparer.CurrentCultureIgnoreCase);
        public Dictionary<string, PipeworksItem> ItemsByName
        {
            get
            {
                return this._ItemsByName;
            }
        }

        private async Task<List<PipeworksBlogItem>> ParseRssAsync(string feedXml, Uri feedUri)
        {
            XmlDocument rssDoc = new XmlDocument();
            rssDoc.LoadXml(feedXml);
            List<PipeworksBlogItem> returnItems = new List<PipeworksBlogItem>();
            foreach (var item in rssDoc.SelectNodes("//item"))
            {
                PipeworksBlogItem newItem = new PipeworksBlogItem();
                newItem.Name = item.SelectSingleNode("title").InnerText;
                newItem.ForegroundColor = this.ForegroundColor;
                newItem.BackgroundColor = this.BackgroundColor;
                newItem.Content = item.SelectSingleNode("description").InnerText;
                var pubDate = item.SelectSingleNode("pubDate");
                if (pubDate != null)
                {
                    try
                    {
                        newItem.PubDate = DateTime.Parse(pubDate.InnerText);
                    }
                    catch
                    {
                    }
                }
                returnItems.Add(newItem);
            }
            return returnItems;
        }

        private async Task<PipeworksData> ParseModuleXmlAsync(string moduleXml, Uri fullUri)
        {

            string result = moduleXml;
            XmlDocument xDoc = new XmlDocument();
            xDoc.LoadXml(moduleXml);
            
            PipeworksData returnData = new PipeworksData();
            returnData.Xml = result;

            var nameNode = xDoc.SelectSingleNode("ModuleManifest/Name");


            returnData.Name = nameNode.InnerText;


            var logoNode = xDoc.SelectSingleNode("ModuleManifest/Logo");

            if (logoNode != null)
            {
                returnData.Logo = new Uri(fullUri.Scheme + "://" + fullUri.Authority + ":" + fullUri.Port.ToString() + logoNode.InnerText.Trim().Trim("\n\r".ToCharArray()).Trim());
            }


            var blogNode = xDoc.SelectSingleNode("ModuleManifest/Blog");
            if (blogNode != null)
            {
                PipeworksBlog blog = new PipeworksBlog();
                
                this.RssFeed = blogNode.SelectSingleNode("Feed").InnerText;
                blog.Name = blogNode.SelectSingleNode("Name").InnerText;
                blog.Url = new Uri(this.RssFeed);
                this.Blog = blog;
                try
                {
                    List<PipeworksBlogItem> blogItems = await GetRssFeedAsync(this.RssFeed);
                    blog.Items.Clear();
                    foreach (PipeworksBlogItem pbi in blogItems)
                    {
                        blog.Items.Add(pbi);
                    }
                }
                catch
                {
                }
            }

            List<string> displayOrder = new List<string>();
            Dictionary<string, PipeworksItem> displayItems = new Dictionary<string, PipeworksItem>(StringComparer.CurrentCultureIgnoreCase);
            Dictionary<string, PipeworksItem> itemByRealName = new Dictionary<string, PipeworksItem>(StringComparer.CurrentCultureIgnoreCase);
            string urlString = fullUri.ToString();
            urlString = urlString.Replace("?-GetManifest", "");
            returnData.ServiceUrl = new Uri(urlString);

            var facebookNode = xDoc.SelectSingleNode("ModuleManifest/Facebook");
            if (facebookNode != null) {
                var fbAppId = facebookNode.SelectSingleNode("AppId");
                returnData.FacebookAppId = fbAppId.InnerText;
                var fbScope = facebookNode.SelectSingleNode("Scope");
                returnData.FacebookScope= fbScope.InnerText;
            }


            var downloadNode = xDoc.SelectSingleNode("ModuleManifest/DirectDownload");
            if (downloadNode != null)
            {
                returnData.DirectDownload = downloadNode.InnerText;
            }

            bool loginIsRequired = false;


            var companyNameNode = xDoc.SelectSingleNode("ModuleManifest/Company");
            if (companyNameNode != null)
            {
                returnData.Company = companyNameNode.InnerText;
            }

            var descriptionNode = xDoc.SelectSingleNode("ModuleManifest/Description");
            if (descriptionNode != null)
            {
                returnData.Description = descriptionNode.InnerText;
            }


            var styleNode = xDoc.SelectSingleNode("ModuleManifest/Style");

            if (styleNode != null)
            {
                var foreGroundNode = styleNode.SelectSingleNode("Foreground");
                if (foreGroundNode != null)
                {
                    returnData.ForegroundColor = foreGroundNode.InnerText;
                }
                else
                {
                    returnData.ForegroundColor = "#012456";
                }
                var backgroundNode = styleNode.SelectSingleNode("Background");

                if (backgroundNode != null)
                {
                    returnData.BackgroundColor = backgroundNode.InnerText;
                }
                else
                {
                    returnData.BackgroundColor = "#fafafa";
                }

            }
            else
            {
                returnData.ForegroundColor = "#012456";
                returnData.BackgroundColor = "#fafafa";
            }

            var copyrightNode = xDoc.SelectSingleNode("ModuleManifest/Copyright");
            if (copyrightNode != null)
            {
                returnData.Copyright = "Copyright " + copyrightNode.InnerText;
            }
            else
            {
                returnData.Copyright = "Copyright " + DateTime.Now.Year.ToString();
            }


            Dictionary<string, PipeworksItem> processedItems = new Dictionary<string, PipeworksItem>(StringComparer.OrdinalIgnoreCase);


            var topicGroups = xDoc.SelectSingleNode("ModuleManifest/TopicGroups");
            if (topicGroups != null)
            {

                //
                var topicGroupList = topicGroups.SelectNodes("TopicGroup");
                var topicGroupNumber = 0;
                PipeworksTopicGroup[] topicGroupArray = new PipeworksTopicGroup[topicGroupList.Count];

                foreach (var topicGroupInfo in topicGroups.SelectNodes("TopicGroup"))
                {

                    PipeworksTopicGroup topicGroup = new PipeworksTopicGroup();
                    topicGroup.Name = topicGroupInfo.SelectSingleNode("Name").InnerText.Trim().Trim("\n\r".ToCharArray()).Trim();


                    var topicList = topicGroupInfo.SelectNodes("Topic");

                    string[] topicListArray = new string[topicList.Count];
                    PipeworksTopic[] topicArray = new PipeworksTopic[topicList.Count];
                    int topicNodeNumber = 0;
                    foreach (var topicNode in topicList)
                    {
                        PipeworksTopic newTopic = new PipeworksTopic();
                        topicListArray[topicNodeNumber] = topicNode.InnerText.Trim().Trim("\n\r".ToCharArray()).Trim();
                        newTopic.Name = topicListArray[topicNodeNumber];
                        topicArray[topicNodeNumber] = newTopic;
                        processedItems[topicListArray[topicNodeNumber]] = topicArray[topicNodeNumber];
                        topicNodeNumber++;
                    }
                    topicGroup.TopicName = topicListArray;
                    topicGroup.Topics = topicArray;
                    topicGroupArray[topicGroupNumber] = topicGroup;
                    if (String.IsNullOrEmpty(topicGroup.ForegroundColor))
                    {
                        topicGroup.ForegroundColor = returnData.ForegroundColor;
                    }
                    if (String.IsNullOrEmpty(topicGroup.BackgroundColor))
                    {
                        topicGroup.BackgroundColor = returnData.BackgroundColor;
                    }
                    topicGroupNumber++;
                    returnData.Items.Add(topicGroup);
                    displayOrder.Add(topicGroup.Name);
                    displayItems[topicGroup.Name] = topicGroup;
                }



            }

            var commandGroups = xDoc.SelectSingleNode("ModuleManifest/CommandGroups");
            if (commandGroups != null)
            {


                var commandGroupList = commandGroups.SelectNodes("CommandGroup");
                var commandGroupNumber = 0;
                PipeworksCommandGroup[] commandGroupArray = new PipeworksCommandGroup[commandGroupList.Count];

                foreach (var commandGroupInfo in commandGroupList)
                {

                    PipeworksCommandGroup commandGroup = new PipeworksCommandGroup();
                    commandGroup.Name = commandGroupInfo.SelectSingleNode("Name").InnerText.Trim().Trim("\n\r".ToCharArray()).Trim();


                    var commandList = commandGroupInfo.SelectNodes("Command");

                    string[] commandListArray = new string[commandList.Count];
                    PipeworksCommand[] commandArray = new PipeworksCommand[commandList.Count];
                    int commandNodeNumber = 0;
                    foreach (var commandNode in commandList)
                    {
                        PipeworksCommand newCommnad = new PipeworksCommand();
                        commandListArray[commandNodeNumber] = commandNode.InnerText.Trim().Trim("\n\r".ToCharArray()).Trim(); ;
                        newCommnad.Name = commandListArray[commandNodeNumber];
                        commandArray[commandNodeNumber] = newCommnad;
                        processedItems[commandListArray[commandNodeNumber]] = commandArray[commandNodeNumber];
                        commandNodeNumber++;
                    }
                    commandGroup.CommandName = commandListArray;
                    commandGroup.Commands = commandArray;
                    commandGroupArray[commandGroupNumber] = commandGroup;
                    commandGroupNumber++;
                    if (String.IsNullOrEmpty(commandGroup.ForegroundColor))
                    {
                        commandGroup.ForegroundColor = returnData.ForegroundColor;
                    }
                    if (String.IsNullOrEmpty(commandGroup.BackgroundColor))
                    {
                        commandGroup.BackgroundColor = returnData.BackgroundColor;
                    }
                    displayOrder.Add(commandGroup.Name);
                    displayItems[commandGroup.Name] = commandGroup;
                    returnData.Items.Add(commandGroup);
                }



            }



            var webCommands = xDoc.SelectSingleNode("ModuleManifest/WebCommand");
            if (webCommands != null)
            {
                foreach (var webCommand in webCommands.SelectNodes("Command"))
                {
                    PipeworksCommand commandInfo = new PipeworksCommand();
                    foreach (var cmdAttribute in webCommand.Attributes)
                    {
                        if (cmdAttribute.LocalName.ToString() == "Name")
                        {
                            commandInfo.Name = cmdAttribute.NodeValue.ToString();
                        } else if (cmdAttribute.LocalName.ToString() == "RealName")
                        {
                            commandInfo.RealName = cmdAttribute.NodeValue.ToString();
                        }
                        else if (cmdAttribute.LocalName.ToString() == "RequireLogin")
                        {
                            commandInfo.RequiresLogin = true;
                            loginIsRequired = true;
                        }
                        else if (cmdAttribute.LocalName.ToString() == "Hidden")
                        {
                            commandInfo.Hidden = true;
                        }
                        else if (cmdAttribute.LocalName.ToString() == "Url")
                        {
                            string uriPath = cmdAttribute.NodeValue.ToString();
                            /*if (Regex.Match(uriPath, "/.+\\..+") != null) {
                                
                            } else {
                                
                            }*/
                            commandInfo.Url = new Uri(uriPath + "?Snug=true");
                            
                        }
                        else if (cmdAttribute.LocalName.ToString() == "RunWithoutInput")
                        {
                            commandInfo.RunWithoutInput = true;
                        }
                        else if (cmdAttribute.LocalName.ToString() == "RedirectTo")
                        {
                            commandInfo.RedirectTo = cmdAttribute.NodeValue.ToString();
                        }

                        else if (cmdAttribute.LocalName.ToString() == "RedirectIn")
                        {
                            commandInfo.RedirectIn = TimeSpan.Parse(cmdAttribute.NodeValue.ToString());
                        }


                    }
                    if (String.IsNullOrEmpty(commandInfo.ForegroundColor))
                    {
                        commandInfo.ForegroundColor = returnData.ForegroundColor;
                    }
                    if (String.IsNullOrEmpty(commandInfo.BackgroundColor))
                    {
                        commandInfo.BackgroundColor = returnData.BackgroundColor;
                    }
                    displayItems[commandInfo.Name] = commandInfo;
                    itemByRealName[commandInfo.RealName] = commandInfo;
                    if (commandInfo.Hidden && !commandInfo.RequiresLogin)
                    {

                        continue;
                    }
                    
                    
                    if (!processedItems.ContainsKey(commandInfo.RealName))
                    {
                        if (commandInfo.Hidden && !commandInfo.RequiresLogin)
                        {

                            continue;
                        }
                    

                        displayOrder.Add(commandInfo.Name);
                        
                        //returnData.Items.Add(commandInfo);
                    }
                    else
                    {
                        PipeworksCommand cmd = processedItems[commandInfo.RealName] as PipeworksCommand;
                        if (cmd != null)
                        {
                            cmd.Name = commandInfo.Name;
                            cmd.Url = commandInfo.Url;

                        }
                        PipeworksCommandGroup matchingGroup = null;
                        foreach (PipeworksItem item in returnData.Items)
                        {
                            if (item is PipeworksCommandGroup)
                            {
                                (item as PipeworksCommandGroup).CommandName.Contains(cmd.Name, StringComparer.OrdinalIgnoreCase);
                                matchingGroup = (item as PipeworksCommandGroup);
                                break;
                            }
                        }

                        if (matchingGroup != null)
                        {
                            PipeworksCommand[] newTopicList = new PipeworksCommand[matchingGroup.CommandName.Length];
                            for (int topicCount = 0; topicCount < matchingGroup.CommandName.Length; topicCount++)
                            {
                                if (String.Compare(matchingGroup.CommandName[topicCount], cmd.Name, StringComparison.CurrentCultureIgnoreCase) == 0)
                                {
                                    newTopicList[topicCount] = cmd;
                                }
                                else
                                {
                                    newTopicList[topicCount] = matchingGroup.Commands[topicCount];
                                }

                            }
                        }
                    }

                }
            }

            PipeworksTopicGroup moreAbout = new PipeworksTopicGroup();
            moreAbout.Name = "More About " + returnData.Name;
            PipeworksTopicGroup walkthrus = new PipeworksTopicGroup();
            walkthrus.Name = "Walkthrus";
            var aboutNode = xDoc.SelectSingleNode("ModuleManifest/About");
            List<PipeworksTopic> moreTopics = new List<PipeworksTopic>();
            List<PipeworksWalkthru> moreWalkthrus = new List<PipeworksWalkthru>();
            if (aboutNode != null)
            {
                foreach (var aboutTopic in aboutNode.SelectNodes("Topic"))
                {
                    PipeworksTopic pipeworksTopic = new PipeworksTopic();
                    pipeworksTopic.Name = aboutTopic.SelectSingleNode("Name").InnerText.Trim("\n\r".ToCharArray()).Trim();
                    pipeworksTopic.Content = aboutTopic.SelectSingleNode("Content").InnerText.Trim("\n\r".ToCharArray()).Trim();
                    if (String.IsNullOrEmpty(pipeworksTopic.ForegroundColor))
                    {
                        pipeworksTopic.ForegroundColor = returnData.ForegroundColor;
                    }
                    if (String.IsNullOrEmpty(pipeworksTopic.BackgroundColor))
                    {
                        pipeworksTopic.BackgroundColor = returnData.BackgroundColor;
                    }

                    displayItems[pipeworksTopic.Name] = pipeworksTopic;
                    if (!processedItems.ContainsKey(pipeworksTopic.Name))
                    {
                        moreTopics.Add(pipeworksTopic);

                        //returnData.Items.Add(pipeworksTopic);
                    }
                    else
                    {
                        PipeworksTopic topic = processedItems[pipeworksTopic.Name] as PipeworksTopic;
                        if (topic != null)
                        {
                            topic.Name = pipeworksTopic.Name;
                            topic.Content = pipeworksTopic.Content;
                            topic.Author = returnData.Author;
                        }
                        PipeworksTopicGroup matchingGroup = null;
                        foreach (PipeworksItem item in returnData.Items)
                        {
                            if (item is PipeworksTopicGroup)
                            {
                                (item as PipeworksTopicGroup).TopicName.Contains(topic.Name, StringComparer.OrdinalIgnoreCase);
                                matchingGroup = (item as PipeworksTopicGroup);
                                break;
                            }
                        }

                        if (matchingGroup != null)
                        {
                            PipeworksTopic[] newTopicList = new PipeworksTopic[matchingGroup.Topics.Length];
                            for (int topicCount = 0; topicCount < matchingGroup.Topics.Length; topicCount++)
                            {
                                if (String.Compare(matchingGroup.TopicName[topicCount], topic.Name, StringComparison.CurrentCultureIgnoreCase) == 0)
                                {
                                    newTopicList[topicCount] = topic;
                                }
                                else
                                {
                                    newTopicList[topicCount] = matchingGroup.Topics[topicCount];
                                }

                            }
                        }
                    }
                }


                foreach (var walkthruNode in aboutNode.SelectNodes("Walkthru"))
                {
                    PipeworksWalkthru pipeworksTopic = new PipeworksWalkthru();
                    pipeworksTopic.Name = walkthruNode.SelectSingleNode("Name").InnerText.Trim("\n\r".ToCharArray()).Trim();
                    //pipeworksTopic.Content = walkthruNode.SelectSingleNode("Content").InnerText.Trim("\n\r".ToCharArray()).Trim();
                    StringBuilder walkthruStringBuilder = new StringBuilder();
                    int walkthruStepNumber = 0;
                    foreach (var walkthruStepNode in walkthruNode.SelectNodes("Step"))
                    {
                        walkthruStepNumber++;
                        PipeworksWalkthruStep step = new PipeworksWalkthruStep();
                        walkthruStringBuilder.Append("<h2>");
                        walkthruStringBuilder.Append(walkthruStepNumber);
                        walkthruStringBuilder.Append("</h2>");
                        step.Script = walkthruStepNode.SelectSingleNode("Script").InnerText.Trim("\n\r".ToCharArray()).Trim();
                        step.Explanation = walkthruStepNode.SelectSingleNode("Explanation").InnerText.Trim("\n\r".ToCharArray()).Trim();
                        var videoNode = walkthruStepNode.SelectSingleNode("Video");
                        if (videoNode != null)
                        {
                            step.Video = videoNode.InnerText.Trim("\n\r".ToCharArray()).Trim();

                            Uri videoUri = new Uri(step.Video);
                            if (videoUri.Query.StartsWith("?v="))
                            {
                                string youTubeVideoId = videoUri.Query.Substring(3);
                                walkthruStringBuilder.Append(@"
<div style='margin-left:16%;margin-right:16%;'>
<iframe width='902' height='506' frameborder='0' allowfullscreen src=""http://www.youtube.com/embed/" + youTubeVideoId + @""">
</iframe>
</div>

");
                            }
                        }
                        else
                        {
                            walkthruStringBuilder.Append("<h4>");
                            walkthruStringBuilder.Append(step.Explanation);
                            walkthruStringBuilder.Append("</h4>");
                            walkthruStringBuilder.Append(step.Script);
                        }
                        walkthruStringBuilder.Append("<BR/><HR/><BR/>");


                        pipeworksTopic.Steps.Add(step);

                    }
                    pipeworksTopic.Content = walkthruStringBuilder.ToString();
                    
                    if (String.IsNullOrEmpty(pipeworksTopic.ForegroundColor))
                    {
                        pipeworksTopic.ForegroundColor = returnData.ForegroundColor;
                    }
                    if (String.IsNullOrEmpty(pipeworksTopic.BackgroundColor))
                    {
                        pipeworksTopic.BackgroundColor = returnData.BackgroundColor;
                    }

                    displayItems[pipeworksTopic.Name] = pipeworksTopic;
                    if (!processedItems.ContainsKey(pipeworksTopic.Name))
                    {
                        moreWalkthrus.Add(pipeworksTopic);
                        
                    }
                    else 
                    {

                        PipeworksTopicGroup matchingGroup = null;
                        foreach (PipeworksItem item in returnData.Items)
                        {
                            if (item is PipeworksTopicGroup)
                            {
                                (item as PipeworksTopicGroup).TopicName.Contains(pipeworksTopic.Name, StringComparer.OrdinalIgnoreCase);
                                matchingGroup = (item as PipeworksTopicGroup);
                                break;
                            }
                        }

                        if (matchingGroup != null)
                        {
                            PipeworksTopic[] newTopicList = new PipeworksTopic[matchingGroup.Topics.Length];
                            for (int topicCount = 0; topicCount < matchingGroup.Topics.Length; topicCount++)
                            {
                                if (String.Compare(matchingGroup.TopicName[topicCount], pipeworksTopic.Name, StringComparison.CurrentCultureIgnoreCase) == 0)
                                {
                                    newTopicList[topicCount] = pipeworksTopic;
                                }
                                else
                                {
                                    newTopicList[topicCount] = matchingGroup.Topics[topicCount];
                                }

                            }
                        }
                    }
                }
            }



            returnData.CanLogin = loginIsRequired;
            returnData.Items.Clear();

            foreach (string displayItemName in displayOrder)
            {
                if (displayItems[displayItemName] != null)
                {
                    PipeworksItem item = displayItems[displayItemName];
                    item.BackgroundColor = returnData.BackgroundColor;
                    item.ForegroundColor = returnData.ForegroundColor;
                    if (item is PipeworksCommandGroup)
                    {
                        List<PipeworksCommand> cmdList = new List<PipeworksCommand>();

                        foreach (string cmdName in (item as PipeworksCommandGroup).CommandName) {
                            if (displayItems.ContainsKey(cmdName))
                            {
                                PipeworksCommand cmdInfo = displayItems[cmdName] as PipeworksCommand;
                                cmdInfo.BackgroundColor = returnData.BackgroundColor;
                                cmdInfo.ForegroundColor = returnData.ForegroundColor;
                                if (cmdInfo != null) {
                                    if (cmdInfo.Hidden && cmdInfo.RequiresLogin)
                                    {
                                        cmdList.Add(cmdInfo);
                                    }
                                    else if (!cmdInfo.Hidden) 
                                    {
                                        cmdList.Add(cmdInfo);
                                    }
                                }



                            }
                            else if (itemByRealName.ContainsKey(cmdName))
                            {
                                PipeworksCommand cmdInfo = itemByRealName[cmdName] as PipeworksCommand;
                                cmdInfo.BackgroundColor = returnData.BackgroundColor;
                                cmdInfo.ForegroundColor = returnData.ForegroundColor;
                                if (cmdInfo != null)
                                {
                                    if (cmdInfo.Hidden && cmdInfo.RequiresLogin)
                                    {
                                        cmdList.Add(cmdInfo);
                                    }
                                    else if (!cmdInfo.Hidden)
                                    {
                                        cmdList.Add(cmdInfo);
                                    }
                                }


                            }
                            
                        }
                        PipeworksCommandGroup group = (item as PipeworksCommandGroup);
                        group.Commands = cmdList.ToArray();
                        displayItems[displayItemName] = group;

                    }

                    if (item is PipeworksTopicGroup)
                    {
                        List<PipeworksTopic> topicList = new List<PipeworksTopic>();
                        foreach (string topicName in (item as PipeworksTopicGroup).TopicName) {
                            if (displayItems.ContainsKey(topicName))
                            {
                                PipeworksTopic topic = (displayItems[topicName] as PipeworksTopic);
                                topic.ForegroundColor = returnData.ForegroundColor;
                                topic.BackgroundColor = returnData.BackgroundColor;
                                topicList.Add((displayItems[topicName] as PipeworksTopic));
                            }
                            
                        }

                        PipeworksTopicGroup group = (item as PipeworksTopicGroup);
                        group.Topics = topicList.ToArray();
                        displayItems[displayItemName] = group;
                    }



                    returnData.Items.Add(displayItems[displayItemName]);
                }
            }

            if (this.Blog != null)
            {
                this.Blog.ForegroundColor = returnData.ForegroundColor;
                this.Blog.BackgroundColor = returnData.BackgroundColor;

                foreach (PipeworksBlogItem bi in this.Blog.Items)
                {
                    bi.ForegroundColor = returnData.ForegroundColor;
                    bi.BackgroundColor = returnData.BackgroundColor;
                }
                displayItems[this.Blog.Name] = this.Blog;
                returnData.Items.Add(this.Blog);
            }

            returnData.ItemsByName.Clear();

            foreach (KeyValuePair<string, PipeworksItem> kvp in displayItems)
            {
                returnData.ItemsByName[kvp.Key] = kvp.Value;
            };

            if (moreTopics.Count > 0)
            {
                moreAbout.Topics = moreTopics.ToArray();
                moreAbout.BackgroundColor = returnData.BackgroundColor;
                moreAbout.ForegroundColor = returnData.ForegroundColor;
                returnData.Items.Add(moreAbout);
            }
            if (moreWalkthrus.Count > 0)
            {
                walkthrus.Topics =  moreWalkthrus.ToArray();
                walkthrus.BackgroundColor = returnData.BackgroundColor;
                walkthrus.ForegroundColor = returnData.ForegroundColor;

                returnData.Items.Add(walkthrus);
            } 
            

            var allCommands = xDoc.SelectSingleNode("ModuleManifest/AllCommands");
            if (allCommands != null && !String.IsNullOrEmpty(returnData.DirectDownload))
            {

            }


            var commandsWithTriggers = xDoc.SelectSingleNode("ModuleManifest/CommandTriggers");
            if (commandsWithTriggers != null)
            {
                foreach (var triggerNode in commandsWithTriggers.SelectNodes("CommandTrigger"))
                {
                    string trigger = triggerNode.SelectSingleNode("Trigger").InnerText.Trim();
                    string commandName = triggerNode.SelectSingleNode("Command").InnerText.Trim();
                    PipeworksCommand realCommand = null;
                    if (itemByRealName.ContainsKey(commandName))
                    {
                        realCommand = itemByRealName[commandName] as PipeworksCommand;
                    }

                    if (realCommand != null)
                    {
                        this.CommandTrigger[trigger] = realCommand;
                    }

                }
            }
            var pubCenter = xDoc.SelectSingleNode("ModuleManifest/PubCenter");

            if (pubCenter != null)
            {
                var appId = pubCenter.SelectSingleNode("ApplicationID");
                var bottomAdSlot = pubCenter.SelectSingleNode("BottomAdUnit");

                if (appId != null && bottomAdSlot != null)
                {
                    this.PubCenterID = appId.InnerText.Trim();
                    this.BottomAdUnit = bottomAdSlot.InnerText.Trim();
                }

            }


            return returnData;
        }




        public async Task<string> GetLiveIDAccessToken(string liveLoginScope)
        {
            if (String.IsNullOrEmpty(liveLoginScope))
            {
                liveLoginScope = "wl.basic wl.emails wl.birthday";

            }
            var targetArray = new List<OnlineIdServiceTicketRequest>();
            targetArray.Add(new OnlineIdServiceTicketRequest(liveLoginScope, "DELEGATION"));
            OnlineIdAuthenticator _authenticator = new OnlineIdAuthenticator();

            try
            {
                var result = await _authenticator.AuthenticateUserAsync(targetArray, CredentialPromptType.PromptIfNeeded);
                if (result.Tickets[0].Value != string.Empty)
                {
                    // DebugPrint("Signed in.");

                    // NeedsToGetTicket = false;
                    this.CurrentLiveIDAccessToken = result.Tickets[0].Value;
                    return result.Tickets[0].Value;
                }
                else
                {
                    // errors are to be handled here.
                    // DebugPrint("Unable to get the ticket. Error: " + result.Tickets[0].ErrorCode.ToString());
                }
            }
            catch (System.OperationCanceledException)
            {
                // errors are to be handled here.
                // DebugPrint("Operation canceled.");

            }
            catch (System.Exception ex)
            {
                // errors are to be handled here.
                // DebugPrint("Unable to get the ticket. Exception: " + ex.Message);
            }
            return null;
        }

        public async Task<string> GetFacebookAccessToken(string facebookClientId, string facebookCallbackUrl, string facebookLoginScope)
        {
            if (!String.IsNullOrEmpty(CurrentFacebookAccessToken))
            {
                if (DateTime.Now > FacebookAccessTokenExpiresdAt)
                {
                    FacebookAccessTokenExpiresdAt = DateTime.MinValue;
                    FacebookAccessTokenAquiredAt = DateTime.MinValue;
                    CurrentFacebookAccessToken = null;
                }
                else
                {
                    return CurrentFacebookAccessToken;
                }
            }
            try
            {
                String FacebookURL = "https://www.facebook.com/dialog/oauth?client_id=" + Uri.EscapeDataString(facebookClientId) + "&redirect_uri=" + Uri.EscapeDataString(facebookCallbackUrl) + "&scope=" + facebookLoginScope + "&display=popup&response_type=token";

                System.Uri StartUri = new Uri(FacebookURL);
                System.Uri EndUri = new Uri(facebookCallbackUrl);

                //   DebugPrint("Navigating to: " + FacebookURL);


                WebAuthenticationResult WebAuthenticationResult = await WebAuthenticationBroker.AuthenticateAsync(
                                                        WebAuthenticationOptions.None,
                                                        StartUri,
                                                        EndUri);

                
                if (WebAuthenticationResult.ResponseStatus == WebAuthenticationStatus.Success)
                {
                    //OutputToken(WebAuthenticationResult.ResponseData.ToString());
                    string responseString = WebAuthenticationResult.ResponseData.ToString();
                    responseString = responseString.Substring(responseString.IndexOf("#") + 1);
                    WwwFormUrlDecoder decoder = new WwwFormUrlDecoder(responseString);
                    CurrentFacebookAccessToken = decoder[0].Value;
                    FacebookAccessTokenAquiredAt = DateTime.Now;
                    FacebookAccessTokenExpiresdAt = FacebookAccessTokenAquiredAt.AddSeconds(int.Parse(decoder[1].Value));

                    return CurrentFacebookAccessToken;
                }
                else if (WebAuthenticationResult.ResponseStatus == WebAuthenticationStatus.ErrorHttp)
                {
                    //OutputToken("HTTP Error returned by AuthenticateAsync() : " + WebAuthenticationResult.ResponseErrorDetail.ToString());
                }
                else
                {
                    //OutputToken("Error returned by AuthenticateAsync() : " + WebAuthenticationResult.ResponseStatus.ToString());
                }
            }
            catch (Exception Error)
            {
                //
                // Bad Parameter, SSL/TLS Errors and Network Unavailable errors are to be handled here.
                //
                // DebugPrint(Error.ToString());
            }
            return null;
        }
        private async Task<PipeworksData> GetModuleAsync(string moduleUriString)
        {
            string fullmoduleUriString = moduleUriString.TrimEnd('/') + "/" + "Module.ashx?-GetManifest";
            string result = String.Empty;
            var req = HttpWebRequest.CreateHttp(fullmoduleUriString);
            WebResponse response = await req.GetResponseAsync();

            Stream responseStream = response.GetResponseStream();

            using (StreamReader reader = new StreamReader(responseStream))
            {
                result = reader.ReadToEnd();
            }
            response.Dispose();

            StorageFile manifestXmlFile = await Windows.Storage.ApplicationData.Current.LocalFolder.CreateFileAsync("ModuleManifest.xml", CreationCollisionOption.ReplaceExisting);
            await FileIO.WriteTextAsync(manifestXmlFile, result);
            StorageFile moduleUriFile = await Windows.Storage.ApplicationData.Current.LocalFolder.CreateFileAsync("ModuleUri.txt", CreationCollisionOption.ReplaceExisting);
            await FileIO.WriteTextAsync(moduleUriFile, fullmoduleUriString);


            Task<PipeworksData> returnDataTask =
                ParseModuleXmlAsync(result, new Uri(fullmoduleUriString));

            PipeworksData returnData = await returnDataTask;

            return returnData;

            
            
                
            

            

            










        }

        public static PipeworksDataSource GetDatasource()
        {
            
            
            var _feedDataSource = App.Current.Resources["feedDataSource"] as PipeworksDataSource;


            return _feedDataSource;
        }

        public static PipeworksItem GetPipeworksItem(string title)
        {


            
            // Simple linear search is acceptable for small data sets
            var _feedDataSource = App.Current.Resources["feedDataSource"] as PipeworksDataSource;

            //var matches = _feedDataSource.Items.Where((feed) => feed.Name.Equals(title));
            //if (matches.Count() == 1) return matches.First();

                

            foreach (PipeworksItem item in _feedDataSource.Items)
            {
                if (String.Compare(item.Name, title, StringComparison.CurrentCultureIgnoreCase) == 0)
                {
                    return item;
                }

                if (item is PipeworksCommandGroup)
                {
                    foreach (PipeworksCommand cmd in (item as PipeworksCommandGroup).Commands)
                    {
                        if (String.Compare(cmd.Name, title, StringComparison.CurrentCultureIgnoreCase) == 0)
                        {
                            return cmd;
                        }
                    }
                }

                if (item is PipeworksTopicGroup)
                {
                    foreach (PipeworksTopic topic in (item as PipeworksTopicGroup).Topics)
                    {
                        if (String.Compare(topic.Name, title, StringComparison.CurrentCultureIgnoreCase) == 0)
                        {
                            return topic;
                        }
                    }
                }
                
            }


            return null;
        }



        public static PipeworksItem GetItem(string uniqueId)
        {
            // Simple linear search is acceptable for small data sets
            var _feedDataSource = App.Current.Resources["feedDataSource"] as PipeworksDataSource;
            var _feeds = _feedDataSource.PipeworksData;

            var matches = _feedDataSource.PipeworksData.SelectMany(group => group.Items).Where((item) => item.Name.Equals(uniqueId));
            if (matches.Count() == 1) return matches.First();
            return null;
        }
    }

    public class DateConverter : Windows.UI.Xaml.Data.IValueConverter
    {
        public object Convert(object value, Type targetType, object parameter, string culture)
        {
            if (value == null)
                throw new ArgumentNullException("value", "Value cannot be null.");

            if (!typeof(DateTime).Equals(value.GetType()))
                throw new ArgumentException("Value must be of type DateTime.", "value");

            DateTime dt = (DateTime)value;

            if (parameter == null)
            {
                // Date "7/27/2011 9:30:59 AM" returns "7/27/2011"
                return DateTimeFormatter.ShortDate.Format(dt);
            }
            else if ((string)parameter == "day")
            {
                // Date "7/27/2011 9:30:59 AM" returns "27"
                DateTimeFormatter dateFormatter = new DateTimeFormatter("{day.integer(2)}");
                return dateFormatter.Format(dt);
            }
            else if ((string)parameter == "month")
            {
                // Date "7/27/2011 9:30:59 AM" returns "JUL"
                DateTimeFormatter dateFormatter = new DateTimeFormatter("{month.abbreviated(3)}");
                return dateFormatter.Format(dt).ToUpper();
            }
            else if ((string)parameter == "year")
            {
                // Date "7/27/2011 9:30:59 AM" returns "2011"
                DateTimeFormatter dateFormatter = new DateTimeFormatter("{year.full}");
                return dateFormatter.Format(dt);
            }
            else
            {
                // Requested format is unknown. Return in the original format.
                return dt.ToString();
            }
        }

        public object ConvertBack(object value, Type targetType, object parameter, string culture)
        {
            string strValue = value as string;
            DateTime resultDateTime;
            if (DateTime.TryParse(strValue, out resultDateTime))
            {
                return resultDateTime;
            }
            return Windows.UI.Xaml.DependencyProperty.UnsetValue;
        }

        //Insert Additional Fittings Here


    }
}
"@
if ($fittings) {
    $pdm = $pdm.Replace("//Insert Additional Fittings Here", $Fittings)
}

if ($defaultManifest) {
    $pdm = $pdm.Replace("DEFAULT_MANIFEST_XML", $DefaultManifest.Replace('"', '""'))
}
$pdm
}

$standardStyles = {
@"

<ResourceDictionary
    xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
    xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml">

    <!-- Non-brush values that vary across themes -->
    
    <ResourceDictionary.ThemeDictionaries>
        <ResourceDictionary x:Key="Default">
            <x:String x:Key="BackButtonGlyph">&#xE071;</x:String>
            <x:String x:Key="BackButtonSnappedGlyph">&#xE0BA;</x:String>
            <SolidColorBrush x:Key="ComboBoxItemSelectedBackgroundThemeBrush" Color="Yellow" />
            <SolidColorBrush x:Key="ComboBoxItemSelectedForegroundThemeBrush" Color="Black" />
            <SolidColorBrush x:Key="ComboBoxItemSelectedPointerOverBackgroundThemeBrush" Color="Black" />
        </ResourceDictionary>
        
        

        <ResourceDictionary x:Key="HighContrast">
            <x:String x:Key="BackButtonGlyph">&#xE0A6;</x:String>
            <x:String x:Key="BackButtonSnappedGlyph">&#xE0C4;</x:String>
        </ResourceDictionary>
    </ResourceDictionary.ThemeDictionaries>

    <!-- RichTextBlock styles -->

    <Style x:Key="BasicRichTextStyle" TargetType="RichTextBlock">
        <Setter Property="Foreground" Value="{StaticResource ApplicationForegroundThemeBrush}"/>
        <Setter Property="FontSize" Value="{StaticResource ControlContentThemeFontSize}"/>
        <Setter Property="FontFamily" Value="{StaticResource ContentControlThemeFontFamily}"/>
        <Setter Property="TextTrimming" Value="WordEllipsis"/>
        <Setter Property="TextWrapping" Value="Wrap"/>
        <Setter Property="Typography.StylisticSet20" Value="True"/>
        <Setter Property="Typography.DiscretionaryLigatures" Value="True"/>
        <Setter Property="Typography.CaseSensitiveForms" Value="True"/>
    </Style>

    <Style x:Key="BaselineRichTextStyle" TargetType="RichTextBlock" BasedOn="{StaticResource BasicRichTextStyle}">
        <Setter Property="LineHeight" Value="20"/>
        <Setter Property="LineStackingStrategy" Value="BlockLineHeight"/>
        <!-- Properly align text along its baseline -->
        <Setter Property="RenderTransform">
            <Setter.Value>
                <TranslateTransform X="-1" Y="4"/>
            </Setter.Value>
        </Setter>
    </Style>

    <Style x:Key="ItemRichTextStyle" TargetType="RichTextBlock" BasedOn="{StaticResource BaselineRichTextStyle}"/>

    <Style x:Key="BodyRichTextStyle" TargetType="RichTextBlock" BasedOn="{StaticResource BaselineRichTextStyle}">
        <Setter Property="FontWeight" Value="SemiLight"/>
    </Style>

    <!-- TextBlock styles -->

    <Style x:Key="BasicTextStyle" TargetType="TextBlock">
        <Setter Property="Foreground" Value="{StaticResource ApplicationForegroundThemeBrush}"/>
        <Setter Property="FontSize" Value="{StaticResource ControlContentThemeFontSize}"/>
        <Setter Property="FontFamily" Value="{StaticResource ContentControlThemeFontFamily}"/>
        <Setter Property="TextTrimming" Value="WordEllipsis"/>
        <Setter Property="TextWrapping" Value="Wrap"/>
        <Setter Property="Typography.StylisticSet20" Value="True"/>
        <Setter Property="Typography.DiscretionaryLigatures" Value="True"/>
        <Setter Property="Typography.CaseSensitiveForms" Value="True"/>
    </Style>

    <Style x:Key="BaselineTextStyle" TargetType="TextBlock" BasedOn="{StaticResource BasicTextStyle}">
        <Setter Property="LineHeight" Value="20"/>
        <Setter Property="LineStackingStrategy" Value="BlockLineHeight"/>
        <!-- Properly align text along its baseline -->
        <Setter Property="RenderTransform">
            <Setter.Value>
                <TranslateTransform X="-1" Y="4"/>
            </Setter.Value>
        </Setter>
    </Style>

    <Style x:Key="HeaderTextStyle" TargetType="TextBlock" BasedOn="{StaticResource BaselineTextStyle}">
        <Setter Property="FontSize" Value="56"/>
        <Setter Property="FontWeight" Value="Light"/>
        <Setter Property="LineHeight" Value="40"/>
        <Setter Property="RenderTransform">
            <Setter.Value>
                <TranslateTransform X="-2" Y="8"/>
            </Setter.Value>
        </Setter>
    </Style>

    <Style x:Key="SubheaderTextStyle" TargetType="TextBlock" BasedOn="{StaticResource BaselineTextStyle}">
        <Setter Property="FontSize" Value="26.667"/>
        <Setter Property="FontWeight" Value="Light"/>
        <Setter Property="LineHeight" Value="30"/>
        <Setter Property="RenderTransform">
            <Setter.Value>
                <TranslateTransform X="-1" Y="6"/>
            </Setter.Value>
        </Setter>
    </Style>

    <Style x:Key="TitleTextStyle" TargetType="TextBlock" BasedOn="{StaticResource BaselineTextStyle}">
        <Setter Property="FontWeight" Value="SemiBold"/>
    </Style>

    <Style x:Key="ItemTextStyle" TargetType="TextBlock" BasedOn="{StaticResource BaselineTextStyle}"/>

    <Style x:Key="BodyTextStyle" TargetType="TextBlock" BasedOn="{StaticResource BaselineTextStyle}">
        <Setter Property="FontWeight" Value="SemiLight"/>
    </Style>

    <Style x:Key="CaptionTextStyle" TargetType="TextBlock" BasedOn="{StaticResource BaselineTextStyle}">
        <Setter Property="FontSize" Value="12"/>
        <Setter Property="Foreground" Value="{StaticResource ApplicationSecondaryForegroundThemeBrush}"/>
    </Style>

    <!-- Button styles -->

    <!--
        TextButtonStyle is used to style a Button using subheader-styled text with no other adornment.  This
        style is used in the GroupedItemsPage as a group header and in the FileOpenPickerPage for triggering
        commands.
    -->
    <Style x:Key="TextButtonStyle" TargetType="Button">
        <Setter Property="MinWidth" Value="0"/>
        <Setter Property="MinHeight" Value="0"/>
        <Setter Property="Template">
            <Setter.Value>
                <ControlTemplate TargetType="Button">
                    <Grid Background="Transparent">
                        <TextBlock
                            x:Name="Text"
                            Text="{TemplateBinding Content}"
                            Margin="3,-7,3,10"
                            TextWrapping="NoWrap"
                            Style="{StaticResource SubheaderTextStyle}"/>
                        <Rectangle
                            x:Name="FocusVisualWhite"
                            IsHitTestVisible="False"
                            Stroke="{StaticResource FocusVisualWhiteStrokeThemeBrush}"
                            StrokeEndLineCap="Square"
                            StrokeDashArray="1,1"
                            Opacity="0"
                            StrokeDashOffset="1.5"/>
                        <Rectangle
                            x:Name="FocusVisualBlack"
                            IsHitTestVisible="False"
                            Stroke="{StaticResource FocusVisualBlackStrokeThemeBrush}"
                            StrokeEndLineCap="Square"
                            StrokeDashArray="1,1"
                            Opacity="0"
                            StrokeDashOffset="0.5"/>

                        <VisualStateManager.VisualStateGroups>
                            <VisualStateGroup x:Name="CommonStates">
                                <VisualState x:Name="Normal"/>
                                <VisualState x:Name="PointerOver">
                                    <Storyboard>
                                        <ObjectAnimationUsingKeyFrames Storyboard.TargetName="Text" Storyboard.TargetProperty="Foreground">
                                            <DiscreteObjectKeyFrame KeyTime="0" Value="{StaticResource ApplicationPointerOverForegroundThemeBrush}"/>
                                        </ObjectAnimationUsingKeyFrames>
                                    </Storyboard>
                                </VisualState>
                                <VisualState x:Name="Pressed">
                                    <Storyboard>
                                        <ObjectAnimationUsingKeyFrames Storyboard.TargetName="Text" Storyboard.TargetProperty="Foreground">
                                            <DiscreteObjectKeyFrame KeyTime="0" Value="{StaticResource ApplicationPressedForegroundThemeBrush}"/>
                                        </ObjectAnimationUsingKeyFrames>
                                    </Storyboard>
                                </VisualState>
                                <VisualState x:Name="Disabled">
                                    <Storyboard>
                                        <ObjectAnimationUsingKeyFrames Storyboard.TargetName="Text" Storyboard.TargetProperty="Foreground">
                                            <DiscreteObjectKeyFrame KeyTime="0" Value="{StaticResource ButtonDisabledForegroundThemeBrush}"/>
                                        </ObjectAnimationUsingKeyFrames>
                                    </Storyboard>
                                </VisualState>
                            </VisualStateGroup>
                            <VisualStateGroup x:Name="FocusStates">
                                <VisualState x:Name="Focused">
                                    <Storyboard>
                                        <DoubleAnimation Duration="0" To="1" Storyboard.TargetName="FocusVisualWhite" Storyboard.TargetProperty="Opacity"/>
                                        <DoubleAnimation Duration="0" To="1" Storyboard.TargetName="FocusVisualBlack" Storyboard.TargetProperty="Opacity"/>
                                    </Storyboard>
                                </VisualState>
                                <VisualState x:Name="Unfocused"/>
                            </VisualStateGroup>
                        </VisualStateManager.VisualStateGroups>
                    </Grid>
                </ControlTemplate>
            </Setter.Value>
        </Setter>
    </Style>

    <!--
        TextRadioButtonStyle is used to style a RadioButton using subheader-styled text with no other adornment.
        This style is used in the SearchResultsPage to allow selection among filters.
    -->

    <Style x:Key="TextRadioButtonStyle" TargetType="RadioButton">
        <Setter Property="MinWidth" Value="0"/>
        <Setter Property="MinHeight" Value="0"/>
        <Setter Property="Margin" Value="0,0,30,0"/>
        <Setter Property="Template">
            <Setter.Value>
                <ControlTemplate TargetType="RadioButton">
                    <Grid Background="Transparent">
                        <TextBlock
                            x:Name="Text"
                            Text="{TemplateBinding Content}"
                            Margin="3,-7,3,10"
                            TextWrapping="NoWrap"
                            Style="{StaticResource SubheaderTextStyle}"/>
                        <Rectangle
                            x:Name="FocusVisualWhite"
                            IsHitTestVisible="False"
                            Stroke="{StaticResource FocusVisualWhiteStrokeThemeBrush}"
                            StrokeEndLineCap="Square"
                            StrokeDashArray="1,1"
                            Opacity="0"
                            StrokeDashOffset="1.5"/>
                        <Rectangle
                            x:Name="FocusVisualBlack"
                            IsHitTestVisible="False"
                            Stroke="{StaticResource FocusVisualBlackStrokeThemeBrush}"
                            StrokeEndLineCap="Square"
                            StrokeDashArray="1,1"
                            Opacity="0"
                            StrokeDashOffset="0.5"/>

                        <VisualStateManager.VisualStateGroups>
                            <VisualStateGroup x:Name="CommonStates">
                                <VisualState x:Name="Normal"/>
                                <VisualState x:Name="PointerOver">
                                    <Storyboard>
                                        <ObjectAnimationUsingKeyFrames Storyboard.TargetName="Text" Storyboard.TargetProperty="Foreground">
                                            <DiscreteObjectKeyFrame KeyTime="0" Value="{StaticResource ApplicationPointerOverForegroundThemeBrush}"/>
                                        </ObjectAnimationUsingKeyFrames>
                                    </Storyboard>
                                </VisualState>
                                <VisualState x:Name="Pressed">
                                    <Storyboard>
                                        <ObjectAnimationUsingKeyFrames Storyboard.TargetName="Text" Storyboard.TargetProperty="Foreground">
                                            <DiscreteObjectKeyFrame KeyTime="0" Value="{StaticResource ApplicationPressedForegroundThemeBrush}"/>
                                        </ObjectAnimationUsingKeyFrames>
                                    </Storyboard>
                                </VisualState>
                                <VisualState x:Name="Disabled">
                                    <Storyboard>
                                        <ObjectAnimationUsingKeyFrames Storyboard.TargetName="Text" Storyboard.TargetProperty="Foreground">
                                            <DiscreteObjectKeyFrame KeyTime="0" Value="{StaticResource ButtonDisabledForegroundThemeBrush}"/>
                                        </ObjectAnimationUsingKeyFrames>
                                    </Storyboard>
                                </VisualState>
                            </VisualStateGroup>
                            <VisualStateGroup x:Name="FocusStates">
                                <VisualState x:Name="Focused">
                                    <Storyboard>
                                        <DoubleAnimation Duration="0" To="1" Storyboard.TargetName="FocusVisualWhite" Storyboard.TargetProperty="Opacity"/>
                                        <DoubleAnimation Duration="0" To="1" Storyboard.TargetName="FocusVisualBlack" Storyboard.TargetProperty="Opacity"/>
                                    </Storyboard>
                                </VisualState>
                                <VisualState x:Name="Unfocused"/>
                            </VisualStateGroup>
                            <VisualStateGroup x:Name="CheckStates">
                                <VisualState x:Name="Checked"/>
                                <VisualState x:Name="Unchecked">
                                    <Storyboard>
                                        <ObjectAnimationUsingKeyFrames Storyboard.TargetName="Text" Storyboard.TargetProperty="Foreground">
                                            <DiscreteObjectKeyFrame KeyTime="0" Value="{StaticResource ApplicationSecondaryForegroundThemeBrush}"/>
                                        </ObjectAnimationUsingKeyFrames>
                                    </Storyboard>
                                </VisualState>
                                <VisualState x:Name="Indeterminate"/>
                            </VisualStateGroup>
                        </VisualStateManager.VisualStateGroups>
                    </Grid>
                </ControlTemplate>
            </Setter.Value>
        </Setter>
    </Style>

    <!--
        AppBarButtonStyle is used to style a Button for use in an App Bar.  Content will be centered and should fit within
        the 40-pixel radius glyph provided.  16-point Segoe UI Symbol is used for content text to simplify the use of glyphs
        from that font.  AutomationProperties.Name is used for the text below the glyph.
    -->
    <Style x:Key="AppBarButtonStyle" TargetType="Button">
        <Setter Property="Foreground" Value="{StaticResource AppBarItemForegroundThemeBrush}"/>
        <Setter Property="VerticalAlignment" Value="Stretch"/>
        <Setter Property="FontFamily" Value="Segoe UI Symbol"/>
        <Setter Property="FontWeight" Value="Normal"/>
        <Setter Property="FontSize" Value="20"/>
        <Setter Property="AutomationProperties.ItemType" Value="App Bar Button"/>
        <Setter Property="Template">
            <Setter.Value>
                <ControlTemplate TargetType="Button">
                    <Grid x:Name="RootGrid" Width="100" Background="Transparent">
                        <StackPanel VerticalAlignment="Top" Margin="0,12,0,11">
                            <Grid Width="40" Height="40" Margin="0,0,0,5" HorizontalAlignment="Center">
                                <TextBlock x:Name="BackgroundGlyph" Text="&#xE0A8;" FontFamily="Segoe UI Symbol" FontSize="53.333" Margin="-4,-19,0,0" Foreground="{StaticResource AppBarItemBackgroundThemeBrush}"/>
                                <TextBlock x:Name="OutlineGlyph" Text="&#xE0A7;" FontFamily="Segoe UI Symbol" FontSize="53.333" Margin="-4,-19,0,0"/>
                                <ContentPresenter x:Name="Content" HorizontalAlignment="Center" Margin="-1,-1,0,0" VerticalAlignment="Center"/>
                            </Grid>
                            <TextBlock
                                x:Name="TextLabel"
                                Text="{TemplateBinding AutomationProperties.Name}"
                                Foreground="{StaticResource AppBarItemForegroundThemeBrush}"
                                Margin="0,0,2,0"
                                FontSize="12"
                                TextAlignment="Center"
                                Width="88"
                                MaxHeight="32"
                                TextTrimming="WordEllipsis"
                                Style="{StaticResource BasicTextStyle}"/>
                        </StackPanel>
                        <Rectangle
                                x:Name="FocusVisualWhite"
                                IsHitTestVisible="False"
                                Stroke="{StaticResource FocusVisualWhiteStrokeThemeBrush}"
                                StrokeEndLineCap="Square"
                                StrokeDashArray="1,1"
                                Opacity="0"
                                StrokeDashOffset="1.5"/>
                        <Rectangle
                                x:Name="FocusVisualBlack"
                                IsHitTestVisible="False"
                                Stroke="{StaticResource FocusVisualBlackStrokeThemeBrush}"
                                StrokeEndLineCap="Square"
                                StrokeDashArray="1,1"
                                Opacity="0"
                                StrokeDashOffset="0.5"/>

                        <VisualStateManager.VisualStateGroups>
                            <VisualStateGroup x:Name="ApplicationViewStates">
                                <VisualState x:Name="FullScreenLandscape"/>
                                <VisualState x:Name="Filled"/>
                                <VisualState x:Name="FullScreenPortrait">
                                    <Storyboard>
                                        <ObjectAnimationUsingKeyFrames Storyboard.TargetName="TextLabel" Storyboard.TargetProperty="Visibility">
                                            <DiscreteObjectKeyFrame KeyTime="0" Value="Collapsed"/>
                                        </ObjectAnimationUsingKeyFrames>
                                        <ObjectAnimationUsingKeyFrames Storyboard.TargetName="RootGrid" Storyboard.TargetProperty="Width">
                                            <DiscreteObjectKeyFrame KeyTime="0" Value="60"/>
                                        </ObjectAnimationUsingKeyFrames>
                                    </Storyboard>
                                </VisualState>
                                <VisualState x:Name="Snapped">
                                    <Storyboard>
                                        <ObjectAnimationUsingKeyFrames Storyboard.TargetName="TextLabel" Storyboard.TargetProperty="Visibility">
                                            <DiscreteObjectKeyFrame KeyTime="0" Value="Collapsed"/>
                                        </ObjectAnimationUsingKeyFrames>
                                        <ObjectAnimationUsingKeyFrames Storyboard.TargetName="RootGrid" Storyboard.TargetProperty="Width">
                                            <DiscreteObjectKeyFrame KeyTime="0" Value="60"/>
                                        </ObjectAnimationUsingKeyFrames>
                                    </Storyboard>
                                </VisualState>
                            </VisualStateGroup>
                            <VisualStateGroup x:Name="CommonStates">
                                <VisualState x:Name="Normal"/>
                                <VisualState x:Name="PointerOver">
                                    <Storyboard>
                                        <ObjectAnimationUsingKeyFrames Storyboard.TargetName="BackgroundGlyph" Storyboard.TargetProperty="Foreground">
                                            <DiscreteObjectKeyFrame KeyTime="0" Value="{StaticResource AppBarItemPointerOverBackgroundThemeBrush}"/>
                                        </ObjectAnimationUsingKeyFrames>
                                        <ObjectAnimationUsingKeyFrames Storyboard.TargetName="Content" Storyboard.TargetProperty="Foreground">
                                            <DiscreteObjectKeyFrame KeyTime="0" Value="{StaticResource AppBarItemPointerOverForegroundThemeBrush}"/>
                                        </ObjectAnimationUsingKeyFrames>
                                    </Storyboard>
                                </VisualState>
                                <VisualState x:Name="Pressed">
                                    <Storyboard>
                                        <ObjectAnimationUsingKeyFrames Storyboard.TargetName="OutlineGlyph" Storyboard.TargetProperty="Foreground">
                                            <DiscreteObjectKeyFrame KeyTime="0" Value="{StaticResource AppBarItemForegroundThemeBrush}"/>
                                        </ObjectAnimationUsingKeyFrames>
                                        <ObjectAnimationUsingKeyFrames Storyboard.TargetName="BackgroundGlyph" Storyboard.TargetProperty="Foreground">
                                            <DiscreteObjectKeyFrame KeyTime="0" Value="{StaticResource AppBarItemForegroundThemeBrush}"/>
                                        </ObjectAnimationUsingKeyFrames>
                                        <ObjectAnimationUsingKeyFrames Storyboard.TargetName="Content" Storyboard.TargetProperty="Foreground">
                                            <DiscreteObjectKeyFrame KeyTime="0" Value="{StaticResource AppBarItemPressedForegroundThemeBrush}"/>
                                        </ObjectAnimationUsingKeyFrames>
                                    </Storyboard>
                                </VisualState>
                                <VisualState x:Name="Disabled">
                                    <Storyboard>
                                        <ObjectAnimationUsingKeyFrames Storyboard.TargetName="OutlineGlyph" Storyboard.TargetProperty="Foreground">
                                            <DiscreteObjectKeyFrame KeyTime="0" Value="{StaticResource AppBarItemDisabledForegroundThemeBrush}"/>
                                        </ObjectAnimationUsingKeyFrames>
                                        <ObjectAnimationUsingKeyFrames Storyboard.TargetName="Content" Storyboard.TargetProperty="Foreground">
                                            <DiscreteObjectKeyFrame KeyTime="0" Value="{StaticResource AppBarItemDisabledForegroundThemeBrush}"/>
                                        </ObjectAnimationUsingKeyFrames>
                                        <ObjectAnimationUsingKeyFrames Storyboard.TargetName="TextLabel" Storyboard.TargetProperty="Foreground">
                                            <DiscreteObjectKeyFrame KeyTime="0" Value="{StaticResource AppBarItemDisabledForegroundThemeBrush}"/>
                                        </ObjectAnimationUsingKeyFrames>
                                    </Storyboard>
                                </VisualState>
                            </VisualStateGroup>
                            <VisualStateGroup x:Name="FocusStates">
                                <VisualState x:Name="Focused">
                                    <Storyboard>
                                        <DoubleAnimation
                                                Storyboard.TargetName="FocusVisualWhite"
                                                Storyboard.TargetProperty="Opacity"
                                                To="1"
                                                Duration="0"/>
                                        <DoubleAnimation
                                                Storyboard.TargetName="FocusVisualBlack"
                                                Storyboard.TargetProperty="Opacity"
                                                To="1"
                                                Duration="0"/>
                                    </Storyboard>
                                </VisualState>
                                <VisualState x:Name="Unfocused" />
                                <VisualState x:Name="PointerFocused" />
                            </VisualStateGroup>
                        </VisualStateManager.VisualStateGroups>
                    </Grid>
                </ControlTemplate>
            </Setter.Value>
        </Setter>
    </Style>

    <!-- Standard App Bar buttons -->
  
    <Style x:Key="SkipBackAppBarButtonStyle" TargetType="Button" BasedOn="{StaticResource AppBarButtonStyle}">
        <Setter Property="AutomationProperties.AutomationId" Value="SkipBackAppBarButton"/>
        <Setter Property="AutomationProperties.Name" Value="Skip Back"/>
        <Setter Property="Content" Value="&#xE100;"/>
    </Style>
    <Style x:Key="SkipAheadAppBarButtonStyle" TargetType="Button" BasedOn="{StaticResource AppBarButtonStyle}">
        <Setter Property="AutomationProperties.AutomationId" Value="SkipAheadAppBarButton"/>
        <Setter Property="AutomationProperties.Name" Value="Skip Ahead"/>
        <Setter Property="Content" Value="&#xE101;"/>
    </Style>
    <Style x:Key="PlayAppBarButtonStyle" TargetType="Button" BasedOn="{StaticResource AppBarButtonStyle}">
        <Setter Property="AutomationProperties.AutomationId" Value="PlayAppBarButton"/>
        <Setter Property="AutomationProperties.Name" Value="Play"/>
        <Setter Property="Content" Value="&#xE102;"/>
    </Style>
    <Style x:Key="PauseAppBarButtonStyle" TargetType="Button" BasedOn="{StaticResource AppBarButtonStyle}">
        <Setter Property="AutomationProperties.AutomationId" Value="PauseAppBarButton"/>
        <Setter Property="AutomationProperties.Name" Value="Pause"/>
        <Setter Property="Content" Value="&#xE103;"/>
    </Style>
    <Style x:Key="EditAppBarButtonStyle" TargetType="Button" BasedOn="{StaticResource AppBarButtonStyle}">
        <Setter Property="AutomationProperties.AutomationId" Value="EditAppBarButton"/>
        <Setter Property="AutomationProperties.Name" Value="Edit"/>
        <Setter Property="Content" Value="&#xE104;"/>
    </Style>
    <Style x:Key="SaveAppBarButtonStyle" TargetType="Button" BasedOn="{StaticResource AppBarButtonStyle}">
        <Setter Property="AutomationProperties.AutomationId" Value="SaveAppBarButton"/>
        <Setter Property="AutomationProperties.Name" Value="Save"/>
        <Setter Property="Content" Value="&#xE105;"/>
    </Style>
    <Style x:Key="DeleteAppBarButtonStyle" TargetType="Button" BasedOn="{StaticResource AppBarButtonStyle}">
        <Setter Property="AutomationProperties.AutomationId" Value="DeleteAppBarButton"/>
        <Setter Property="AutomationProperties.Name" Value="Delete"/>
        <Setter Property="Content" Value="&#xE106;"/>
    </Style>
    <Style x:Key="DiscardAppBarButtonStyle" TargetType="Button" BasedOn="{StaticResource AppBarButtonStyle}">
        <Setter Property="AutomationProperties.AutomationId" Value="DiscardAppBarButton"/>
        <Setter Property="AutomationProperties.Name" Value="Discard"/>
        <Setter Property="Content" Value="&#xE107;"/>
    </Style>
    <Style x:Key="RemoveAppBarButtonStyle" TargetType="Button" BasedOn="{StaticResource AppBarButtonStyle}">
        <Setter Property="AutomationProperties.AutomationId" Value="RemoveAppBarButton"/>
        <Setter Property="AutomationProperties.Name" Value="Remove"/>
        <Setter Property="Content" Value="&#xE108;"/>
    </Style>
    <Style x:Key="AddAppBarButtonStyle" TargetType="Button" BasedOn="{StaticResource AppBarButtonStyle}">
        <Setter Property="AutomationProperties.AutomationId" Value="AddAppBarButton"/>
        <Setter Property="AutomationProperties.Name" Value="Add"/>
        <Setter Property="Content" Value="&#xE109;"/>
    </Style>
    <Style x:Key="NoAppBarButtonStyle" TargetType="Button" BasedOn="{StaticResource AppBarButtonStyle}">
        <Setter Property="AutomationProperties.AutomationId" Value="NoAppBarButton"/>
        <Setter Property="AutomationProperties.Name" Value="No"/>
        <Setter Property="Content" Value="&#xE10A;"/>
    </Style>
    <Style x:Key="YesAppBarButtonStyle" TargetType="Button" BasedOn="{StaticResource AppBarButtonStyle}">
        <Setter Property="AutomationProperties.AutomationId" Value="YesAppBarButton"/>
        <Setter Property="AutomationProperties.Name" Value="Yes"/>
        <Setter Property="Content" Value="&#xE10B;"/>
    </Style>
    <Style x:Key="MoreAppBarButtonStyle" TargetType="Button" BasedOn="{StaticResource AppBarButtonStyle}">
        <Setter Property="AutomationProperties.AutomationId" Value="MoreAppBarButton"/>
        <Setter Property="AutomationProperties.Name" Value="More"/>
        <Setter Property="Content" Value="&#xE10C;"/>
    </Style>
    <Style x:Key="RedoAppBarButtonStyle" TargetType="Button" BasedOn="{StaticResource AppBarButtonStyle}">
        <Setter Property="AutomationProperties.AutomationId" Value="RedoAppBarButton"/>
        <Setter Property="AutomationProperties.Name" Value="Redo"/>
        <Setter Property="Content" Value="&#xE10D;"/>
    </Style>
    <Style x:Key="UndoAppBarButtonStyle" TargetType="Button" BasedOn="{StaticResource AppBarButtonStyle}">
        <Setter Property="AutomationProperties.AutomationId" Value="UndoAppBarButton"/>
        <Setter Property="AutomationProperties.Name" Value="Undo"/>
        <Setter Property="Content" Value="&#xE10E;"/>
    </Style>
    <Style x:Key="HomeAppBarButtonStyle" TargetType="Button" BasedOn="{StaticResource AppBarButtonStyle}">
        <Setter Property="AutomationProperties.AutomationId" Value="HomeAppBarButton"/>
        <Setter Property="AutomationProperties.Name" Value="Home"/>
        <Setter Property="Content" Value="&#xE10F;"/>
    </Style>
    <Style x:Key="OutAppBarButtonStyle" TargetType="Button" BasedOn="{StaticResource AppBarButtonStyle}">
        <Setter Property="AutomationProperties.AutomationId" Value="OutAppBarButton"/>
        <Setter Property="AutomationProperties.Name" Value="Out"/>
        <Setter Property="Content" Value="&#xE110;"/>
    </Style>
    <Style x:Key="NextAppBarButtonStyle" TargetType="Button" BasedOn="{StaticResource AppBarButtonStyle}">
        <Setter Property="AutomationProperties.AutomationId" Value="NextAppBarButton"/>
        <Setter Property="AutomationProperties.Name" Value="Next"/>
        <Setter Property="Content" Value="&#xE111;"/>
    </Style>
    <Style x:Key="PreviousAppBarButtonStyle" TargetType="Button" BasedOn="{StaticResource AppBarButtonStyle}">
        <Setter Property="AutomationProperties.AutomationId" Value="PreviousAppBarButton"/>
        <Setter Property="AutomationProperties.Name" Value="Previous"/>
        <Setter Property="Content" Value="&#xE112;"/>
    </Style>
    <Style x:Key="FavoriteAppBarButtonStyle" TargetType="Button" BasedOn="{StaticResource AppBarButtonStyle}">
        <Setter Property="AutomationProperties.AutomationId" Value="FavoriteAppBarButton"/>
        <Setter Property="AutomationProperties.Name" Value="Favorite"/>
        <Setter Property="Content" Value="&#xE113;"/>
    </Style>
    <Style x:Key="PhotoAppBarButtonStyle" TargetType="Button" BasedOn="{StaticResource AppBarButtonStyle}">
        <Setter Property="AutomationProperties.AutomationId" Value="PhotoAppBarButton"/>
        <Setter Property="AutomationProperties.Name" Value="Photo"/>
        <Setter Property="Content" Value="&#xE114;"/>
    </Style>
    <Style x:Key="SettingsAppBarButtonStyle" TargetType="Button" BasedOn="{StaticResource AppBarButtonStyle}">
        <Setter Property="AutomationProperties.AutomationId" Value="SettingsAppBarButton"/>
        <Setter Property="AutomationProperties.Name" Value="Settings"/>
        <Setter Property="Content" Value="&#xE115;"/>
    </Style>
    <Style x:Key="VideoAppBarButtonStyle" TargetType="Button" BasedOn="{StaticResource AppBarButtonStyle}">
        <Setter Property="AutomationProperties.AutomationId" Value="VideoAppBarButton"/>
        <Setter Property="AutomationProperties.Name" Value="Video"/>
        <Setter Property="Content" Value="&#xE116;"/>
    </Style>
    <Style x:Key="RefreshAppBarButtonStyle" TargetType="Button" BasedOn="{StaticResource AppBarButtonStyle}">
        <Setter Property="AutomationProperties.AutomationId" Value="RefreshAppBarButton"/>
        <Setter Property="AutomationProperties.Name" Value="Refresh"/>
        <Setter Property="Content" Value="&#xE117;"/>
    </Style>
    <Style x:Key="DownloadAppBarButtonStyle" TargetType="Button" BasedOn="{StaticResource AppBarButtonStyle}">
        <Setter Property="AutomationProperties.AutomationId" Value="DownloadAppBarButton"/>
        <Setter Property="AutomationProperties.Name" Value="Download"/>
        <Setter Property="Content" Value="&#xE118;"/>
    </Style>
    <Style x:Key="MailAppBarButtonStyle" TargetType="Button" BasedOn="{StaticResource AppBarButtonStyle}">
        <Setter Property="AutomationProperties.AutomationId" Value="MailAppBarButton"/>
        <Setter Property="AutomationProperties.Name" Value="Mail"/>
        <Setter Property="Content" Value="&#xE119;"/>
    </Style>
    <Style x:Key="SearchAppBarButtonStyle" TargetType="Button" BasedOn="{StaticResource AppBarButtonStyle}">
        <Setter Property="AutomationProperties.AutomationId" Value="SearchAppBarButton"/>
        <Setter Property="AutomationProperties.Name" Value="Search"/>
        <Setter Property="Content" Value="&#xE11A;"/>
    </Style>
    <Style x:Key="HelpAppBarButtonStyle" TargetType="Button" BasedOn="{StaticResource AppBarButtonStyle}">
        <Setter Property="AutomationProperties.AutomationId" Value="HelpAppBarButton"/>
        <Setter Property="AutomationProperties.Name" Value="Help"/>
        <Setter Property="Content" Value="&#xE11B;"/>
    </Style>
    <Style x:Key="UploadAppBarButtonStyle" TargetType="Button" BasedOn="{StaticResource AppBarButtonStyle}">
        <Setter Property="AutomationProperties.AutomationId" Value="UploadAppBarButton"/>
        <Setter Property="AutomationProperties.Name" Value="Upload"/>
        <Setter Property="Content" Value="&#xE11C;"/>
    </Style>
    <Style x:Key="PinAppBarButtonStyle" TargetType="Button" BasedOn="{StaticResource AppBarButtonStyle}">
        <Setter Property="AutomationProperties.AutomationId" Value="PinAppBarButton"/>
        <Setter Property="AutomationProperties.Name" Value="Pin"/>
        <Setter Property="Content" Value="&#xE141;"/>
    </Style>
    <Style x:Key="UnpinAppBarButtonStyle" TargetType="Button" BasedOn="{StaticResource AppBarButtonStyle}">
        <Setter Property="AutomationProperties.AutomationId" Value="UnpinAppBarButton"/>
        <Setter Property="AutomationProperties.Name" Value="Unpin"/>
        <Setter Property="Content" Value="&#xE196;"/>
    </Style>

    <!-- Title area styles -->

    <Style x:Key="PageHeaderTextStyle" TargetType="TextBlock" BasedOn="{StaticResource HeaderTextStyle}">
        <Setter Property="TextWrapping" Value="NoWrap"/>
        <Setter Property="VerticalAlignment" Value="Bottom"/>
        <Setter Property="Margin" Value="0,0,30,40"/>
    </Style>

    <Style x:Key="PageSubheaderTextStyle" TargetType="TextBlock" BasedOn="{StaticResource SubheaderTextStyle}">
        <Setter Property="TextWrapping" Value="NoWrap"/>
        <Setter Property="VerticalAlignment" Value="Bottom"/>
        <Setter Property="Margin" Value="0,0,0,40"/>
    </Style>

    <Style x:Key="SnappedPageHeaderTextStyle" TargetType="TextBlock" BasedOn="{StaticResource PageSubheaderTextStyle}">
        <Setter Property="Margin" Value="0,0,18,40"/>
    </Style>

    <!--
        BackButtonStyle is used to style a Button for use in the title area of a page.  Margins appropriate for
        the conventional page layout are included as part of the style.
    -->
    <Style x:Key="BackButtonStyle" TargetType="Button">
        <Setter Property="MinWidth" Value="0"/>
        <Setter Property="Width" Value="48"/>
        <Setter Property="Height" Value="48"/>
        <Setter Property="Margin" Value="36,0,36,36"/>
        <Setter Property="VerticalAlignment" Value="Bottom"/>
        <Setter Property="FontFamily" Value="Segoe UI Symbol"/>
        <Setter Property="FontWeight" Value="Normal"/>
        <Setter Property="FontSize" Value="56"/>
        <Setter Property="AutomationProperties.AutomationId" Value="BackButton"/>
        <Setter Property="AutomationProperties.Name" Value="Back"/>
        <Setter Property="AutomationProperties.ItemType" Value="Navigation Button"/>
        <Setter Property="Template">
            <Setter.Value>
                <ControlTemplate TargetType="Button">
                    <Grid x:Name="RootGrid">
                        <Grid Margin="-1,-16,0,0">
                            <TextBlock x:Name="BackgroundGlyph" Text="&#xE0A8;" Foreground="{StaticResource BackButtonBackgroundThemeBrush}"/>
                            <TextBlock x:Name="NormalGlyph" Text="{StaticResource BackButtonGlyph}" Foreground="{StaticResource BackButtonForegroundThemeBrush}"/>
                            <TextBlock x:Name="ArrowGlyph" Text="&#xE0A6;" Foreground="{StaticResource BackButtonPressedForegroundThemeBrush}" Opacity="0"/>
                        </Grid>
                        <Rectangle
                            x:Name="FocusVisualWhite"
                            IsHitTestVisible="False"
                            Stroke="{StaticResource FocusVisualWhiteStrokeThemeBrush}"
                            StrokeEndLineCap="Square"
                            StrokeDashArray="1,1"
                            Opacity="0"
                            StrokeDashOffset="1.5"/>
                        <Rectangle
                            x:Name="FocusVisualBlack"
                            IsHitTestVisible="False"
                            Stroke="{StaticResource FocusVisualBlackStrokeThemeBrush}"
                            StrokeEndLineCap="Square"
                            StrokeDashArray="1,1"
                            Opacity="0"
                            StrokeDashOffset="0.5"/>

                        <VisualStateManager.VisualStateGroups>
                            <VisualStateGroup x:Name="CommonStates">
                                <VisualState x:Name="Normal" />
                                <VisualState x:Name="PointerOver">
                                    <Storyboard>
                                        <ObjectAnimationUsingKeyFrames Storyboard.TargetName="BackgroundGlyph" Storyboard.TargetProperty="Foreground">
                                            <DiscreteObjectKeyFrame KeyTime="0" Value="{StaticResource BackButtonPointerOverBackgroundThemeBrush}"/>
                                        </ObjectAnimationUsingKeyFrames>
                                        <ObjectAnimationUsingKeyFrames Storyboard.TargetName="NormalGlyph" Storyboard.TargetProperty="Foreground">
                                            <DiscreteObjectKeyFrame KeyTime="0" Value="{StaticResource BackButtonPointerOverForegroundThemeBrush}"/>
                                        </ObjectAnimationUsingKeyFrames>
                                    </Storyboard>
                                </VisualState>
                                <VisualState x:Name="Pressed">
                                    <Storyboard>
                                        <ObjectAnimationUsingKeyFrames Storyboard.TargetName="BackgroundGlyph" Storyboard.TargetProperty="Foreground">
                                            <DiscreteObjectKeyFrame KeyTime="0" Value="{StaticResource BackButtonForegroundThemeBrush}"/>
                                        </ObjectAnimationUsingKeyFrames>
                                        <DoubleAnimation
                                            Storyboard.TargetName="ArrowGlyph"
                                            Storyboard.TargetProperty="Opacity"
                                            To="1"
                                            Duration="0"/>
                                        <DoubleAnimation
                                            Storyboard.TargetName="NormalGlyph"
                                            Storyboard.TargetProperty="Opacity"
                                            To="0"
                                            Duration="0"/>
                                    </Storyboard>
                                </VisualState>
                                <VisualState x:Name="Disabled">
                                    <Storyboard>
                                        <ObjectAnimationUsingKeyFrames Storyboard.TargetName="RootGrid" Storyboard.TargetProperty="Visibility">
                                            <DiscreteObjectKeyFrame KeyTime="0" Value="Collapsed"/>
                                        </ObjectAnimationUsingKeyFrames>
                                    </Storyboard>
                                </VisualState>
                            </VisualStateGroup>
                            <VisualStateGroup x:Name="FocusStates">
                                <VisualState x:Name="Focused">
                                    <Storyboard>
                                        <DoubleAnimation
                                            Storyboard.TargetName="FocusVisualWhite"
                                            Storyboard.TargetProperty="Opacity"
                                            To="1"
                                            Duration="0"/>
                                        <DoubleAnimation
                                            Storyboard.TargetName="FocusVisualBlack"
                                            Storyboard.TargetProperty="Opacity"
                                            To="1"
                                            Duration="0"/>
                                    </Storyboard>
                                </VisualState>
                                <VisualState x:Name="Unfocused" />
                                <VisualState x:Name="PointerFocused" />
                            </VisualStateGroup>
                        </VisualStateManager.VisualStateGroups>
                    </Grid>
                </ControlTemplate>
            </Setter.Value>
        </Setter>
    </Style>

    <!--
        PortraitBackButtonStyle is used to style a Button for use in the title area of a portrait page.  Margins appropriate
        for the conventional page layout are included as part of the style.
    -->
    <Style x:Key="PortraitBackButtonStyle" TargetType="Button" BasedOn="{StaticResource BackButtonStyle}">
        <Setter Property="Margin" Value="26,0,26,36"/>
    </Style>

    <!--
        SnappedBackButtonStyle is used to style a Button for use in the title area of a snapped page.  Margins appropriate
        for the conventional page layout are included as part of the style.
        
        The obvious duplication here is necessary as the glyphs used in snapped are not merely smaller versions of the same
        glyph but are actually distinct.
    -->
    <Style x:Key="SnappedBackButtonStyle" TargetType="Button">
        <Setter Property="MinWidth" Value="0"/>
        <Setter Property="Margin" Value="20,0,0,0"/>
        <Setter Property="VerticalAlignment" Value="Bottom"/>
        <Setter Property="FontFamily" Value="Segoe UI Symbol"/>
        <Setter Property="FontWeight" Value="Normal"/>
        <Setter Property="FontSize" Value="26.66667"/>
        <Setter Property="AutomationProperties.AutomationId" Value="BackButton"/>
        <Setter Property="AutomationProperties.Name" Value="Back"/>
        <Setter Property="AutomationProperties.ItemType" Value="Navigation Button"/>
        <Setter Property="Template">
            <Setter.Value>
                <ControlTemplate TargetType="Button">
                    <Grid x:Name="RootGrid" Width="36" Height="36" Margin="-3,0,7,33">
                        <Grid Margin="-1,-1,0,0">
                            <TextBlock x:Name="BackgroundGlyph" Text="&#xE0D4;" Foreground="{StaticResource BackButtonBackgroundThemeBrush}"/>
                            <TextBlock x:Name="NormalGlyph" Text="{StaticResource BackButtonSnappedGlyph}" Foreground="{StaticResource BackButtonForegroundThemeBrush}"/>
                            <TextBlock x:Name="ArrowGlyph" Text="&#xE0C4;" Foreground="{StaticResource BackButtonPressedForegroundThemeBrush}" Opacity="0"/>
                        </Grid>
                        <Rectangle
                            x:Name="FocusVisualWhite"
                            IsHitTestVisible="False"
                            Stroke="{StaticResource FocusVisualWhiteStrokeThemeBrush}"
                            StrokeEndLineCap="Square"
                            StrokeDashArray="1,1"
                            Opacity="0"
                            StrokeDashOffset="1.5"/>
                        <Rectangle
                            x:Name="FocusVisualBlack"
                            IsHitTestVisible="False"
                            Stroke="{StaticResource FocusVisualBlackStrokeThemeBrush}"
                            StrokeEndLineCap="Square"
                            StrokeDashArray="1,1"
                            Opacity="0"
                            StrokeDashOffset="0.5"/>

                        <VisualStateManager.VisualStateGroups>
                            <VisualStateGroup x:Name="CommonStates">
                                <VisualState x:Name="Normal" />
                                <VisualState x:Name="PointerOver">
                                    <Storyboard>
                                        <ObjectAnimationUsingKeyFrames Storyboard.TargetName="BackgroundGlyph" Storyboard.TargetProperty="Foreground">
                                            <DiscreteObjectKeyFrame KeyTime="0" Value="{StaticResource BackButtonPointerOverBackgroundThemeBrush}"/>
                                        </ObjectAnimationUsingKeyFrames>
                                        <ObjectAnimationUsingKeyFrames Storyboard.TargetName="NormalGlyph" Storyboard.TargetProperty="Foreground">
                                            <DiscreteObjectKeyFrame KeyTime="0" Value="{StaticResource BackButtonPointerOverForegroundThemeBrush}"/>
                                        </ObjectAnimationUsingKeyFrames>
                                    </Storyboard>
                                </VisualState>
                                <VisualState x:Name="Pressed">
                                    <Storyboard>
                                        <ObjectAnimationUsingKeyFrames Storyboard.TargetName="BackgroundGlyph" Storyboard.TargetProperty="Foreground">
                                            <DiscreteObjectKeyFrame KeyTime="0" Value="{StaticResource BackButtonForegroundThemeBrush}"/>
                                        </ObjectAnimationUsingKeyFrames>
                                        <DoubleAnimation
                                            Storyboard.TargetName="ArrowGlyph"
                                            Storyboard.TargetProperty="Opacity"
                                            To="1"
                                            Duration="0"/>
                                        <DoubleAnimation
                                            Storyboard.TargetName="NormalGlyph"
                                            Storyboard.TargetProperty="Opacity"
                                            To="0"
                                            Duration="0"/>
                                    </Storyboard>
                                </VisualState>
                                <VisualState x:Name="Disabled">
                                    <Storyboard>
                                        <ObjectAnimationUsingKeyFrames Storyboard.TargetName="RootGrid" Storyboard.TargetProperty="Visibility">
                                            <DiscreteObjectKeyFrame KeyTime="0" Value="Collapsed"/>
                                        </ObjectAnimationUsingKeyFrames>
                                    </Storyboard>
                                </VisualState>
                            </VisualStateGroup>
                            <VisualStateGroup x:Name="FocusStates">
                                <VisualState x:Name="Focused">
                                    <Storyboard>
                                        <DoubleAnimation
                                            Storyboard.TargetName="FocusVisualWhite"
                                            Storyboard.TargetProperty="Opacity"
                                            To="1"
                                            Duration="0"/>
                                        <DoubleAnimation
                                            Storyboard.TargetName="FocusVisualBlack"
                                            Storyboard.TargetProperty="Opacity"
                                            To="1"
                                            Duration="0"/>
                                    </Storyboard>
                                </VisualState>
                                <VisualState x:Name="Unfocused" />
                                <VisualState x:Name="PointerFocused" />
                            </VisualStateGroup>
                        </VisualStateManager.VisualStateGroups>
                    </Grid>
                </ControlTemplate>
            </Setter.Value>
        </Setter>
    </Style>

    <!-- Item templates -->

    <!-- Grid-appropriate 250 pixel square item template as seen in the GroupedItemsPage and ItemsPage -->
    <DataTemplate x:Key="Standard250x250ItemTemplate">
        <Grid HorizontalAlignment="Left" Width="250" Height="250">
            <Border Background="{StaticResource ListViewItemPlaceholderBackgroundThemeBrush}">
                <Image Source="{Binding Image}" Stretch="UniformToFill"/>
            </Border>
            <StackPanel VerticalAlignment="Bottom" Background="{StaticResource ListViewItemOverlayBackgroundThemeBrush}">
                <TextBlock Text="{Binding Title}" Foreground="{StaticResource ListViewItemOverlayForegroundThemeBrush}" Style="{StaticResource TitleTextStyle}" Height="60" Margin="15,0,15,0"/>
                <TextBlock Text="{Binding Subtitle}" Foreground="{StaticResource ListViewItemOverlaySecondaryForegroundThemeBrush}" Style="{StaticResource CaptionTextStyle}" TextWrapping="NoWrap" Margin="15,0,15,10"/>
            </StackPanel>
        </Grid>
    </DataTemplate>

    <!-- Grid-appropriate 500 by 130 pixel item template as seen in the GroupDetailPage -->
    <DataTemplate x:Key="Standard500x130ItemTemplate">
        <Grid Height="110" Width="480" Margin="10">
            <Grid.ColumnDefinitions>
                <ColumnDefinition Width="Auto"/>
                <ColumnDefinition Width="*"/>
            </Grid.ColumnDefinitions>
            <Border Background="{StaticResource ListViewItemPlaceholderBackgroundThemeBrush}" Width="110" Height="110">
                <Image Source="{Binding Image}" Stretch="UniformToFill"/>
            </Border>
            <StackPanel Grid.Column="1" VerticalAlignment="Top" Margin="10,0,0,0">
                <TextBlock Text="{Binding Title}" Style="{StaticResource TitleTextStyle}" TextWrapping="NoWrap"/>
                <TextBlock Text="{Binding Subtitle}" Style="{StaticResource CaptionTextStyle}" TextWrapping="NoWrap"/>
                <TextBlock Text="{Binding Description}" Style="{StaticResource BodyTextStyle}" MaxHeight="60"/>
            </StackPanel>
        </Grid>
    </DataTemplate>

    <!-- List-appropriate 130 pixel high item template as seen in the SplitPage -->
    <DataTemplate x:Key="Standard130ItemTemplate">
        <Grid Height="110" Margin="6">
            <Grid.ColumnDefinitions>
                <ColumnDefinition Width="Auto"/>
                <ColumnDefinition Width="*"/>
            </Grid.ColumnDefinitions>
            <Border Background="{StaticResource ListViewItemPlaceholderBackgroundThemeBrush}" Width="110" Height="110">
                <Image Source="{Binding Image}" Stretch="UniformToFill"/>
            </Border>
            <StackPanel Grid.Column="1" VerticalAlignment="Top" Margin="10,0,0,0">
                <TextBlock Text="{Binding Title}" Style="{StaticResource TitleTextStyle}" TextWrapping="NoWrap"/>
                <TextBlock Text="{Binding Subtitle}" Style="{StaticResource CaptionTextStyle}" TextWrapping="NoWrap"/>
                <TextBlock Text="{Binding Description}" Style="{StaticResource BodyTextStyle}" MaxHeight="60"/>
            </StackPanel>
        </Grid>
    </DataTemplate>

    <!--
        List-appropriate 80 pixel high item template as seen in the SplitPage when Filled, and
        the following pages when snapped: GroupedItemsPage, GroupDetailPage, and ItemsPage
    -->
    <DataTemplate x:Key="Standard80ItemTemplate">
        <Grid Margin="6">
            <Grid.ColumnDefinitions>
                <ColumnDefinition Width="Auto"/>
                <ColumnDefinition Width="*"/>
            </Grid.ColumnDefinitions>
            <Border Background="{StaticResource ListViewItemPlaceholderBackgroundThemeBrush}" Width="60" Height="60">
                <Image Source="{Binding Image}" Stretch="UniformToFill"/>
            </Border>
            <StackPanel Grid.Column="1" Margin="10,0,0,0">
                <TextBlock Text="{Binding Title}" Style="{StaticResource ItemTextStyle}" MaxHeight="40"/>
                <TextBlock Text="{Binding Subtitle}" Style="{StaticResource CaptionTextStyle}" TextWrapping="NoWrap"/>
            </StackPanel>
        </Grid>
    </DataTemplate>

    <!-- Grid-appropriate 300 by 70 pixel item template as seen in the SearchResultsPage -->
    <DataTemplate x:Key="StandardSmallIcon300x70ItemTemplate">
        <Grid Width="294" Margin="6">
            <Grid.ColumnDefinitions>
                <ColumnDefinition Width="Auto"/>
                <ColumnDefinition Width="*"/>
            </Grid.ColumnDefinitions>
            <Border Background="{StaticResource ListViewItemPlaceholderBackgroundThemeBrush}" Margin="0,0,0,10" Width="40" Height="40">
                <Image Source="{Binding Image}" Stretch="UniformToFill"/>
            </Border>
            <StackPanel Grid.Column="1" Margin="10,-10,0,0">
                <TextBlock Text="{Binding Title}" Style="{StaticResource BodyTextStyle}" TextWrapping="NoWrap"/>
                <TextBlock Text="{Binding Subtitle}" Style="{StaticResource BodyTextStyle}" Foreground="{StaticResource ApplicationSecondaryForegroundThemeBrush}" TextWrapping="NoWrap"/>
                <TextBlock Text="{Binding Description}" Style="{StaticResource BodyTextStyle}" Foreground="{StaticResource ApplicationSecondaryForegroundThemeBrush}" TextWrapping="NoWrap"/>
            </StackPanel>
        </Grid>
    </DataTemplate>

    <!-- List-appropriate 70 pixel high item template as seen in the SearchResultsPage when Snapped -->
    <DataTemplate x:Key="StandardSmallIcon70ItemTemplate">
        <Grid Margin="6">
            <Grid.ColumnDefinitions>
                <ColumnDefinition Width="Auto"/>
                <ColumnDefinition Width="*"/>
            </Grid.ColumnDefinitions>
            <Border Background="{StaticResource ListViewItemPlaceholderBackgroundThemeBrush}" Margin="0,0,0,10" Width="40" Height="40">
                <Image Source="{Binding Image}" Stretch="UniformToFill"/>
            </Border>
            <StackPanel Grid.Column="1" Margin="10,-10,0,0">
                <TextBlock Text="{Binding Title}" Style="{StaticResource BodyTextStyle}" TextWrapping="NoWrap"/>
                <TextBlock Text="{Binding Subtitle}" Style="{StaticResource BodyTextStyle}" Foreground="{StaticResource ApplicationSecondaryForegroundThemeBrush}" TextWrapping="NoWrap"/>
                <TextBlock Text="{Binding Description}" Style="{StaticResource BodyTextStyle}" Foreground="{StaticResource ApplicationSecondaryForegroundThemeBrush}" TextWrapping="NoWrap"/>
            </StackPanel>
        </Grid>
    </DataTemplate>

  <!--
      190x130 pixel item template for displaying file previews as seen in the FileOpenPickerPage
      Includes an elaborate tooltip to display title and description text
  -->
  <DataTemplate x:Key="StandardFileWithTooltip190x130ItemTemplate">
        <Grid>
            <Grid Background="{StaticResource ListViewItemPlaceholderBackgroundThemeBrush}">
                <Image
                    Source="{Binding Image}"
                    Width="190"
                    Height="130"
                    HorizontalAlignment="Center"
                    VerticalAlignment="Center"
                    Stretch="Uniform"/>
            </Grid>
            <ToolTipService.Placement>Mouse</ToolTipService.Placement>
            <ToolTipService.ToolTip>
                <ToolTip>
                    <ToolTip.Style>
                        <Style TargetType="ToolTip">
                            <Setter Property="BorderBrush" Value="{StaticResource ToolTipBackgroundThemeBrush}" />
                            <Setter Property="Padding" Value="0" />
                        </Style>
                    </ToolTip.Style>

                    <Grid Background="{StaticResource ApplicationPageBackgroundThemeBrush}">
                        <Grid.ColumnDefinitions>
                            <ColumnDefinition Width="Auto"/>
                            <ColumnDefinition Width="*"/>
                        </Grid.ColumnDefinitions>

                        <Grid Background="{StaticResource ListViewItemPlaceholderBackgroundThemeBrush}" Margin="20">
                            <Image
                                Source="{Binding Image}"
                                Width="160"
                                Height="160"
                                HorizontalAlignment="Center"
                                VerticalAlignment="Center"
                                Stretch="Uniform"/>
                        </Grid>
                        <StackPanel Width="200" Grid.Column="1" Margin="0,20,20,20">
                            <TextBlock Text="{Binding Title}" TextWrapping="NoWrap" Style="{StaticResource BodyTextStyle}"/>
                            <TextBlock Text="{Binding Description}" MaxHeight="140" Foreground="{StaticResource ApplicationSecondaryForegroundThemeBrush}" Style="{StaticResource BodyTextStyle}"/>
                        </StackPanel>
                    </Grid>   
                </ToolTip>                
            </ToolTipService.ToolTip>
        </Grid>
    </DataTemplate>

    <!-- ScrollViewer styles -->

    <Style x:Key="HorizontalScrollViewerStyle" TargetType="ScrollViewer">
        <Setter Property="HorizontalScrollBarVisibility" Value="Auto"/>
        <Setter Property="VerticalScrollBarVisibility" Value="Disabled"/>
        <Setter Property="ScrollViewer.HorizontalScrollMode" Value="Enabled" />
        <Setter Property="ScrollViewer.VerticalScrollMode" Value="Disabled" />
        <Setter Property="ScrollViewer.ZoomMode" Value="Disabled" />
    </Style>

    <Style x:Key="VerticalScrollViewerStyle" TargetType="ScrollViewer">
        <Setter Property="HorizontalScrollBarVisibility" Value="Disabled"/>
        <Setter Property="VerticalScrollBarVisibility" Value="Auto"/>
        <Setter Property="ScrollViewer.HorizontalScrollMode" Value="Disabled" />
        <Setter Property="ScrollViewer.VerticalScrollMode" Value="Enabled" />
        <Setter Property="ScrollViewer.ZoomMode" Value="Disabled" />
    </Style>

    <!-- Page layout roots typically use entrance animations and a theme-appropriate background color -->

    <Style x:Key="LayoutRootStyle" TargetType="Panel">
        <Setter Property="Background" Value="{StaticResource ApplicationPageBackgroundThemeBrush}"/>
        <Setter Property="ChildrenTransitions">
            <Setter.Value>
                <TransitionCollection>
                    <EntranceThemeTransition/>
                </TransitionCollection>
            </Setter.Value>
        </Setter>
    </Style>
</ResourceDictionary>

"@
}


$splitPageXaml = {
@"
<common:LayoutAwarePage
    x:Name="pageRoot"
    x:Class="PipeworksApp.SplitPage"
    DataContext="{Binding DefaultViewModel, RelativeSource={RelativeSource Self}}"
    IsTabStop="false"
    xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
    xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
    xmlns:local="using:PipeworksApp"
    xmlns:common="using:PipeworksApp.Common"
    xmlns:d="http://schemas.microsoft.com/expression/blend/2008"
    xmlns:mc="http://schemas.openxmlformats.org/markup-compatibility/2006"
    xmlns:UI="using:Microsoft.Advertising.WinRT.UI"
    mc:Ignorable="d">

    <Page.Resources>

        <!-- Collection of items displayed by this page -->
        <CollectionViewSource
            x:Name="itemsViewSource"
            Source="{Binding Items}"/>

        <Storyboard x:Name="PopInStoryboard">
            <PopInThemeAnimation  Storyboard.TargetName="contentViewBorder" 
                              FromHorizontalOffset="400"/>
        </Storyboard>

        <Style x:Key="WebViewAppBarButtonStyle" TargetType="Button" 
           BasedOn="{StaticResource AppBarButtonStyle}">
            <Setter Property="AutomationProperties.AutomationId" Value="WebViewAppBarButton"/>
            <Setter Property="AutomationProperties.Name" Value="View Web Page"/>
            <Setter Property="Content" Value="&#xE12B;"/>
        </Style>

        <!-- green -->
        <SolidColorBrush x:Key="BlockBackgroundBrush" Color="#FF6BBD46"/>

        <DataTemplate x:Key="DefaultListItemTemplate">
                
                <StackPanel Grid.Column="1"  HorizontalAlignment="Left" Margin="12,8,0,0">
                    <TextBlock Text="{Binding Name}" FontSize="26.667" TextWrapping="Wrap"
                           MaxHeight="72" Foreground="{Binding ForegroundColor}"  />
                    <TextBlock Text="{Binding Author}" FontSize="18.667" />
                </StackPanel>
            
        </DataTemplate>

        <!-- Used in Filled and Snapped views -->
        <DataTemplate x:Key="NarrowListItemTemplate">
            <Grid Height="80">
                <Grid.ColumnDefinitions>
                    <ColumnDefinition Width="Auto"/>
                    <ColumnDefinition Width="*"/>
                </Grid.ColumnDefinitions>
                <Border BorderBrush="{Binding ForegroundColor}" Width="80" Height="80"/>                
                <StackPanel Grid.Column="1" HorizontalAlignment="Left" Margin="12,8,0,0">
                    <TextBlock Text="{Binding Name}" MaxHeight="56" Foreground="{Binding ForegroundColor}" TextWrapping="Wrap"/>
                    <TextBlock Text="{Binding Author}" FontSize="12" />
                </StackPanel>
            </Grid>
        </DataTemplate>
    </Page.Resources>

    <Page.TopAppBar>
        <AppBar Padding="10,0,10,10" Opened="Top_AppBar_Opened" Closed="Top_Appbar_Closed" Background="{StaticResource TheBackgroundColor}" Opacity=".7">
            <StackPanel HorizontalAlignment="Right" Orientation="Horizontal">
                <Button Click="SaveDocument" x:Name="savePage" BorderBrush="{StaticResource TheForegroundColor}" Background="{StaticResource TheBackgroundColor}">
                    <StackPanel>
                        <TextBlock Text="&#xE105;" FontFamily="Segoe UI Symbol" FontWeight="SemiBold" FontSize="19" Padding="8" Foreground="{StaticResource TheForegroundColor}" ></TextBlock>
                    </StackPanel>
                </Button>

                <Button Click="CopyToClipboard" x:Name="clipboard" BorderBrush="{StaticResource TheForegroundColor}" Background="{StaticResource TheBackgroundColor}">
                    <StackPanel>
                        <TextBlock Text="&#xE16C;" FontFamily="Segoe UI Symbol" FontSize="19" FontWeight="Light" Padding="8" Foreground="{StaticResource TheForegroundColor}" ></TextBlock>
                    </StackPanel>
                </Button>
                
                <Button Click="ViewInWebPage" IsEnabled="False" x:Name="viewInPageButton" BorderBrush="{StaticResource TheForegroundColor}" Background="{StaticResource TheBackgroundColor}">
                    <StackPanel>
                        <TextBlock Text="&#xE143;" FontFamily="Segoe UI Symbol" FontWeight="SemiBold" FontSize="19" Padding="8" Foreground="{StaticResource TheForegroundColor}"></TextBlock>                        
                    </StackPanel>
                    
                </Button>

                <Button Click="GoHome" x:Name="homeCharmButton" BorderBrush="{StaticResource TheForegroundColor}" Background="{StaticResource TheBackgroundColor}">
                    <StackPanel>
                        <TextBlock Text="&#xE10F;" FontFamily="Segoe UI Symbol" FontWeight="SemiBold" FontSize="19" Padding="8" Foreground="{StaticResource TheForegroundColor}" ></TextBlock>
                    </StackPanel>
                </Button>
                
                
                
            </StackPanel>
        </AppBar>
    </Page.TopAppBar>
    <Page.BottomAppBar >
        <AppBar Padding="10,0,10,0" Opened="Top_AppBar_Opened" Closed="Top_Appbar_Closed" Background="{StaticResource TheBackgroundColor}" Opacity=".7">
            <Grid>
                <Grid.ColumnDefinitions>
                    <ColumnDefinition Width="Auto" />
                    <ColumnDefinition Width="1*" />
                    <ColumnDefinition Width="Auto" />
                </Grid.ColumnDefinitions>
                                
                <TextBlock Margin="10" FontSize="22" VerticalAlignment="Center" Foreground="{StaticResource TheForegroundColor}">Location</TextBlock>
                <TextBox Grid.Column="1" Margin="10" x:Name="Command"></TextBox>
                <Button x:Name="RunCommand" Margin="10" FontSize="22" VerticalAlignment="Center" FontWeight="SemiBold" Grid.Column="2" Click="RunCommand_Click_1" Foreground="{StaticResource TheForegroundColor}" BorderBrush="{StaticResource TheForegroundColor}">Go</Button>
            </Grid>
        </AppBar>
    </Page.BottomAppBar>
        
    <!--
        This grid acts as a root panel for the page that defines two rows:
        * Row 0 contains the back button and page title
        * Row 1 contains the rest of the page layout
    -->
    <Grid x:Name="SplitGrid" Background="{Binding Background}">
        <Grid.RowDefinitions>
            <RowDefinition Height="140"/>
            <RowDefinition Height="Auto" />
            <RowDefinition Height="1*" MinHeight="400" />
            <RowDefinition Height="Auto" />
        </Grid.RowDefinitions>
        <Grid.ColumnDefinitions>
            <ColumnDefinition x:Name="primaryColumn" Width="Auto"/>
            <ColumnDefinition Width="*"/>
        </Grid.ColumnDefinitions>

        <!-- Back button and page title -->
        <Grid x:Name="titlePanel" Grid.ColumnSpan="2">
            <Grid.ColumnDefinitions>
                <ColumnDefinition Width="Auto"/>
                <ColumnDefinition Width="*"/>
                <ColumnDefinition Width="Auto" />
            </Grid.ColumnDefinitions>
            <Button
                x:Name="backButton"
                Click="GoHome"
                IsEnabled="{Binding DefaultViewModel.CanGoBack, ElementName=pageRoot}"
                Margin="15 0 15 0" 
                BorderThickness="0"
                Background="{Binding Background}"
                Foreground="{Binding Foreground}" >
                <Grid>
                    <Grid.ColumnDefinitions>
                        <ColumnDefinition Width="Auto" />
                        <ColumnDefinition Width="Auto" />
                    </Grid.ColumnDefinitions>
                    <TextBlock Text="&#xE071;" FontFamily="Segoe UI Symbol" FontSize="38" Foreground="{Binding Foreground}" x:Name="backButtonSymbol" Grid.Column="0"></TextBlock>
                    <Image Source="Assets/squaretile.png" MaxWidth="125" MaxHeight="125" Grid.Column="1" x:Name="backButtonLogo" />
                    
                </Grid>

            </Button>
            <TextBlock x:Name="pageTitle" Grid.Column="1" Text="{Binding Name}" Style="{StaticResource PageHeaderTextStyle}" Foreground="{Binding Foreground}"/>
            <Button Grid.Column="3" x:Name="FacebookLoginStatus" IsEnabled="False" Visibility="Collapsed" Click="Facebook_Profile_Click" BorderBrush="{StaticResource TheForegroundColor}">
                <Button.Content>
                    <StackPanel>
                        
                        <TextBlock Foreground="{Binding Foreground}">My Account</TextBlock>
                    </StackPanel>
                </Button.Content>
            </Button>

        </Grid>

        <!-- Vertical scrolling item list -->
        <ComboBox 
            x:Name="itemListView"
            AutomationProperties.AutomationId="ItemsListView"
            AutomationProperties.Name="Items"
            Grid.Row="1" Grid.Column="1"
            Foreground="{Binding Foreground}"
            Padding="60,0,0,30"
            ItemsSource="{Binding Source={StaticResource itemsViewSource}}"
            DropDownOpened="itemListView_DropDownOpened_1"
            DropDownClosed="itemListView_DropDownClosed_1"  
            SelectionChanged="ItemListView_SelectionChanged"
            ItemTemplate="{StaticResource DefaultListItemTemplate}" />

        <!-- Details for selected item -->
        <ScrollViewer
            x:Name="itemDetail"
            AutomationProperties.AutomationId="ItemDetailScrollViewer"
            Grid.Column="1"
            Grid.Row="2"
            Padding="70,0,70,0"
            DataContext="{Binding SelectedItem, ElementName=itemListView}"
            Style="{StaticResource VerticalScrollViewerStyle}">

            <Grid x:Name="itemDetailGrid">
                <Grid.RowDefinitions>
                    <RowDefinition Height="Auto"/>
                    <RowDefinition Height="*"/>
                </Grid.RowDefinitions>

                <TextBlock x:Name="itemTitle" Text="{Binding Name}" Foreground="{StaticResource TheForegroundColor}" Style="{StaticResource SubheaderTextStyle}">
                    <TextBlock.Transitions>
                        <TransitionCollection>
                            <ContentThemeTransition />
                        </TransitionCollection>
                    </TextBlock.Transitions>
                </TextBlock>

                <Border x:Name="contentViewBorder" BorderBrush="Gray" BorderThickness="0" 
                        Grid.Row="1">
                    <Grid>
                        <Grid.RowDefinitions>
                            <RowDefinition Height="Auto" />
                            <RowDefinition Height="1*" />
                        </Grid.RowDefinitions>
                        <StackPanel Orientation="Vertical" Visibility="Collapsed" x:Name="loadingPage" Grid.Row="0">
                            <TextBlock Foreground="{StaticResource TheForegroundColor}">Loading Page</TextBlock>
                            <ProgressRing Width="125" Height="125" IsActive="True" x:Name="loadingRing" Foreground="{StaticResource TheForegroundColor}"/>
                        </StackPanel>
                        <StackPanel Orientation="Horizontal" Visibility="Collapsed" x:Name="ItemOptions">
                            <Button x:Name="runScriptButton" Visibility="Collapsed" Foreground="{StaticResource TheForegroundColor}" Click="runScript" BorderBrush="Transparent">Run Script</Button>
                            <Button x:Name="copyScriptButton" Visibility="Collapsed" Foreground="{StaticResource TheForegroundColor}" Click="CopyToClipboard" BorderBrush="Transparent">
                                <StackPanel>
                                    <TextBlock Text="&#xE16C;" FontFamily="Segoe UI Symbol" FontSize="19" FontWeight="Light" Padding="8" Foreground="{StaticResource TheForegroundColor}"  />
                                    <TextBlock Foreground="{StaticResource TheForegroundColor}">Copy Content</TextBlock>
                                </StackPanel>
                            </Button>
                            <Button x:Name="viewInWebPageButton" Visibility="Collapsed" Foreground="{StaticResource TheForegroundColor}" Click="ViewInWebPage" BorderBrush="Transparent">
                                <StackPanel>
                                    <TextBlock Text="&#xE143;" FontFamily="Segoe UI Symbol" FontSize="19" FontWeight="Light" Padding="8" Foreground="{StaticResource TheForegroundColor}"  />
                                    <TextBlock Foreground="{StaticResource TheForegroundColor}">View In Browser</TextBlock>
                                </StackPanel>
                            </Button>

                        </StackPanel>
                        <Grid x:Name="inputGrid" Background="Transparent" Visibility="Collapsed" Grid.Row="1"></Grid>
                        <Button x:Name="snappedContentViewPreview" Visibility="Collapsed" Grid.Row="1">
                            
                        </Button>
                        <WebView x:Name="contentView" ScrollViewer.VerticalScrollMode="Enabled"  LoadCompleted="loadCompleted" Grid.Row="1"/>
                        
                        <Rectangle x:Name="contentViewBrushRect" Visibility="Collapsed" Grid.Row="1" />
                        <StackPanel Orientation="Horizontal" x:Name="loginButtonPanel" HorizontalAlignment="Center" VerticalAlignment="Center" Grid.Row="1"  >
                            <Button x:Name="liveLoginButton" Visibility="Collapsed" Click="loginToLive_Click" BorderBrush="Transparent">
                                <Button.Content>
                                    <Grid>
                                        <Grid.RowDefinitions>
                                            <RowDefinition />
                                            <RowDefinition Height="Auto"/>
                                        </Grid.RowDefinitions>
                                        <TextBlock Text="&#xE125;" FontFamily="Segoe UI Symbol" FontSize="72" Foreground="{StaticResource TheForegroundColor}" HorizontalAlignment="Center" MaxHeight="75"/>
                                        <!-- <Image Source="Assets/User.png" MaxWidth="75" MaxHeight="75"/>-->
                                        <TextBlock Grid.Row="1" x:Name="loginWithMSAccountText" Margin="12" Foreground="{StaticResource TheForegroundColor}" HorizontalAlignment="Center">Login with Microsoft Account</TextBlock>
                                    </Grid>
                                </Button.Content>
                            </Button>

                            <Button x:Name="facebookLoginButton" Visibility="Collapsed" Click="loginToFacebook_Click"  Grid.Row="1" BorderBrush="Transparent">
                                <Button.Content>
                                    <Grid>
                                        <Grid.RowDefinitions>
                                            <RowDefinition />
                                            <RowDefinition Height="Auto"/>
                                        </Grid.RowDefinitions>
                                        <Image Source="Assets/f_logo.png" MaxWidth="75" HorizontalAlignment="Center"/>
                                        <TextBlock x:Name="loginWithFacebookAccountText" Margin="12" Foreground="{StaticResource TheForegroundColor}" HorizontalAlignment="Center" Grid.Row="1">Login with Facebook</TextBlock>
                                    </Grid>
                                </Button.Content>
                            </Button>
                        </StackPanel>
                        <Rectangle x:Name="contentViewRect" Grid.Row="1"/>
                    </Grid>
                </Border>
            </Grid>
        </ScrollViewer>

        <Grid Visibility="Collapsed" Grid.Row="3" Grid.Column="1" x:Name="splitPageAdHolder">
            <UI:AdControl x:Name="splitPageAdControl" Visibility="Collapsed" IsAutoRefreshEnabled="True" Width="728" Height="90">

            </UI:AdControl>
        </Grid>


        <VisualStateManager.VisualStateGroups>

            <!-- Visual states reflect the application's view state -->
            <VisualStateGroup x:Name="ApplicationViewStates">
                <VisualState x:Name="FullScreenLandscapeOrWide"/>

                <!-- Filled uses a simpler list format in a narrower column -->
                <VisualState x:Name="FilledOrNarrow">
                    <Storyboard>
                    </Storyboard>
                </VisualState>

                <!--
                    The page respects the narrower 100-pixel margin convention for portrait, and the page
                    initially hides details to show only the list of items
                -->
                <VisualState x:Name="FullScreenPortrait">
                    <Storyboard>
                        
                    </Storyboard>
                </VisualState>

                <!--
                    When an item is selected in portrait the details display requires more extensive changes:
                     * Hide the master list and the column is was in
                     * Move item details down a row to make room for the title
                     * Move the title directly above the details
                     * Adjust margins and padding for details
                 -->
                <VisualState x:Name="FullScreenPortrait_Detail">
                    <Storyboard>
                    </Storyboard>
                </VisualState>

                <!--
                    The back button and title have different styles when snapped, and the page
                    initially hides details to show only the list of items
                -->
                <VisualState x:Name="Snapped">
                    <Storyboard>
                        <ObjectAnimationUsingKeyFrames Storyboard.TargetName="backButton" Storyboard.TargetProperty="Style">
                            <DiscreteObjectKeyFrame KeyTime="0" Value="{StaticResource SnappedBackButtonStyle}"/>
                        </ObjectAnimationUsingKeyFrames>
                        <ObjectAnimationUsingKeyFrames Storyboard.TargetName="pageTitle" Storyboard.TargetProperty="Style">
                            <DiscreteObjectKeyFrame KeyTime="0" Value="{StaticResource SnappedPageHeaderTextStyle}"/>
                        </ObjectAnimationUsingKeyFrames>

                        <ObjectAnimationUsingKeyFrames Storyboard.TargetName="itemDetail" Storyboard.TargetProperty="Visibility">
                            <DiscreteObjectKeyFrame KeyTime="0" Value="Collapsed"/>
                        </ObjectAnimationUsingKeyFrames>
                        <ObjectAnimationUsingKeyFrames Storyboard.TargetName="itemListView" Storyboard.TargetProperty="ItemTemplate">
                            <DiscreteObjectKeyFrame KeyTime="0" Value="{StaticResource NarrowListItemTemplate}"/>
                        </ObjectAnimationUsingKeyFrames>
                        <ObjectAnimationUsingKeyFrames Storyboard.TargetName="itemListView" Storyboard.TargetProperty="Padding">
                            <DiscreteObjectKeyFrame KeyTime="0" Value="20,0,0,0"/>
                        </ObjectAnimationUsingKeyFrames>
                    </Storyboard>
                </VisualState>

                <!--
                    When snapped and an item is selected the details display requires more extensive changes:
                     * Hide the master list and the column is was in
                     * Move item details down a row to make room for the title
                     * Move the title directly above the details
                     * Adjust margins and padding for details
                     * Use a different font for title and subtitle
                     * Adjust margins below subtitle
                 -->
                <VisualState x:Name="Snapped_Detail">
                    <Storyboard>
                        <ObjectAnimationUsingKeyFrames Storyboard.TargetName="backButton" Storyboard.TargetProperty="Style">
                            <DiscreteObjectKeyFrame KeyTime="0" Value="{StaticResource SnappedBackButtonStyle}"/>
                        </ObjectAnimationUsingKeyFrames>
                        <ObjectAnimationUsingKeyFrames Storyboard.TargetName="pageTitle" Storyboard.TargetProperty="Style">
                            <DiscreteObjectKeyFrame KeyTime="0" Value="{StaticResource SnappedPageHeaderTextStyle}"/>
                        </ObjectAnimationUsingKeyFrames>

                        
                        <ObjectAnimationUsingKeyFrames Storyboard.TargetName="itemListView" Storyboard.TargetProperty="Visibility">
                            <DiscreteObjectKeyFrame KeyTime="0" Value="Collapsed"/>
                        </ObjectAnimationUsingKeyFrames>
                        <ObjectAnimationUsingKeyFrames Storyboard.TargetName="itemDetail" Storyboard.TargetProperty="(Grid.Row)">
                            <DiscreteObjectKeyFrame KeyTime="0" Value="1"/>
                        </ObjectAnimationUsingKeyFrames>
                        <ObjectAnimationUsingKeyFrames Storyboard.TargetName="itemDetail" Storyboard.TargetProperty="(Grid.RowSpan)">
                            <DiscreteObjectKeyFrame KeyTime="0" Value="1"/>
                        </ObjectAnimationUsingKeyFrames>
                        <ObjectAnimationUsingKeyFrames Storyboard.TargetName="titlePanel" Storyboard.TargetProperty="(Grid.Column)">
                            <DiscreteObjectKeyFrame KeyTime="0" Value="1"/>
                        </ObjectAnimationUsingKeyFrames>
                        <!--<ObjectAnimationUsingKeyFrames Storyboard.TargetName="itemDetailTitlePanel" Storyboard.TargetProperty="(Grid.Row)">
                            <DiscreteObjectKeyFrame KeyTime="0" Value="0"/>
                        </ObjectAnimationUsingKeyFrames>
                        <ObjectAnimationUsingKeyFrames Storyboard.TargetName="itemDetailTitlePanel" Storyboard.TargetProperty="(Grid.Column)">
                            <DiscreteObjectKeyFrame KeyTime="0" Value="0"/>
                        </ObjectAnimationUsingKeyFrames>-->
                        <ObjectAnimationUsingKeyFrames Storyboard.TargetName="itemDetail" Storyboard.TargetProperty="Padding">
                            <DiscreteObjectKeyFrame KeyTime="0" Value="20,0,20,0"/>
                        </ObjectAnimationUsingKeyFrames>
                        <ObjectAnimationUsingKeyFrames Storyboard.TargetName="itemDetailGrid" Storyboard.TargetProperty="Margin">
                            <DiscreteObjectKeyFrame KeyTime="0" Value="0,0,0,60"/>
                        </ObjectAnimationUsingKeyFrames>
                        <ObjectAnimationUsingKeyFrames Storyboard.TargetName="itemTitle" Storyboard.TargetProperty="Style">
                            <DiscreteObjectKeyFrame KeyTime="0" Value="{StaticResource TitleTextStyle}"/>
                        </ObjectAnimationUsingKeyFrames>
                        <ObjectAnimationUsingKeyFrames Storyboard.TargetName="itemTitle" Storyboard.TargetProperty="Margin">
                            <DiscreteObjectKeyFrame KeyTime="0" Value="0"/>
                        </ObjectAnimationUsingKeyFrames>
                        <!--<ObjectAnimationUsingKeyFrames Storyboard.TargetName="itemSubtitle" Storyboard.TargetProperty="Style">
                            <DiscreteObjectKeyFrame KeyTime="0" Value="{StaticResource CaptionTextStyle}"/>
                        </ObjectAnimationUsingKeyFrames>-->
                    </Storyboard>
                </VisualState>
            </VisualStateGroup>
        </VisualStateManager.VisualStateGroups>
    </Grid>
</common:LayoutAwarePage>


"@
}

$splitPageXamlCs = {
@'
using System;
using System.Collections.Generic;
using System.IO;
using System.Net;
using System.Text.RegularExpressions;
using Windows.ApplicationModel.DataTransfer;
using Windows.Storage;
using Windows.Storage.Pickers;
using Windows.System;
using Windows.UI;
using Windows.UI.Core;
using Windows.UI.Popups;
using Windows.UI.ViewManagement;
using Windows.UI.Xaml;
using Windows.UI.Xaml.Controls;
using Windows.UI.Xaml.Controls.Primitives;
using Windows.UI.Xaml.Markup;
using Windows.UI.Xaml.Media;
using Windows.UI.Xaml.Navigation;

// The Split Page item template is documented at http://go.microsoft.com/fwlink/?LinkId=234234

namespace PipeworksApp
{
    /// <summary>
    /// A page that displays a group title, a list of items within the group, and details for
    /// the currently selected item.
    /// </summary>
    public sealed partial class SplitPage : PipeworksApp.Common.LayoutAwarePage
    {
        public SplitPage()
        {
            this.InitializeComponent();
            this.contentView.AllowedScriptNotifyUris = WebView.AnyScriptNotifyUri;
            this.contentView.NavigationFailed += contentView_NavigationFailed;
            this.ApplicationViewStates.CurrentStateChanging += ApplicationViewStates_CurrentStateChanging;   
        }

        void contentView_NavigationFailed(object sender, WebViewNavigationFailedEventArgs e)
        {
            
        }

        WebViewBrush lastWebView = null;


        void ApplicationViewStates_CurrentStateChanging(object sender, VisualStateChangedEventArgs e)
        {
            string stateName = e.NewState.Name;
            string otherStateName = stateName;

            /*if (stateName.StartsWith("Snapped_"))
            {
                // switching to snapped, create the preview button
                if (lastWebView != null)
                {
                    this.snappedContentViewPreview.Foreground = lastWebView;
                    ScaleTransform st = new ScaleTransform();
                    st.ScaleX = .25;
                    st.ScaleY = .25;
                    this.snappedContentViewPreview.RenderTransform = st;
                }
                else
                {
                }
                

                this.contentView.Visibility = Visibility.Collapsed;
                this.snappedContentViewPreview.Visibility = Visibility.Visible;
                
            }
            else
            {
                // switching out of snapped, restore

            }*/
        }



        private IEnumerable<UIElement> getChildControl(UIElement control)
        {
            

            Queue<DependencyObject> controlQueue = new Queue<DependencyObject>();
            controlQueue.Enqueue(control);

            while (controlQueue.Count > 0)
            {
                UIElement parent = controlQueue.Peek() as UIElement;
                if (parent == null)
                {
                    controlQueue.Dequeue();
                    continue;
                }
                else
                {
                    yield return (controlQueue.Dequeue() as UIElement); 
                }

                int childCount = VisualTreeHelper.GetChildrenCount(parent);

                if (childCount > 0)
                {
                    for (int innerI = 0; innerI < childCount; innerI++)
                    {
                        var child = VisualTreeHelper.GetChild(parent, innerI);
                        object content = null;
                        try
                        {
                            content = child.GetValue(ContentControl.ContentProperty);
                        }
                        catch
                        {
                        }
                        
                        if (content != null && (content is UIElement)) 
                        {
                            controlQueue.Enqueue((content as UIElement));
                        }
                        else
                        {
                            controlQueue.Enqueue(child);
                        }
                        
                    }

                    
                } 

                
            }

        }

        private void createCommandElement(string xaml)
        {
            try
            {
                Color fgColor = (App.Current.Resources["TheBackgroundColor"] as SolidColorBrush).Color;
                string fgColorString = String.Empty;
                string fixedResult = Regex.Replace(xaml, "<TextBlock ", ("<TextBlock Foreground='{Binding ForegroundColor}' "));
                fixedResult = Regex.Replace(fixedResult, "<CheckBox ", ("<CheckBox Foreground='{Binding ForegroundColor}' "));
                fixedResult = Regex.Replace(fixedResult, "<RadioButton ", ("<RadioButton Foreground='{Binding ForegroundColor}' "));

                PipeworksCommand currentCommand = App.Current.Resources["CurrentCommand"] as PipeworksCommand;
                string cmdShortName = currentCommand.RealName.Replace("-", "") + "_Invoke";
                fixedResult = Regex.Replace(fixedResult, cmdShortName, cmdShortName, RegexOptions.IgnoreCase);


                var outputObject = XamlReader.Load(fixedResult);

                UIElement outputUI = outputObject as UIElement;


                this.inputGrid.Children.Clear();
                var child = VisualTreeHelper.GetChild(outputUI, 0);
                UIElement grandChild = null;
                if (child != null)
                {
                    //(child as ScrollViewer).Background = new SolidColorBrush(Colors.Black);
                    //(child as ScrollViewer).Foreground = new SolidColorBrush(Colors.Azure);
                    grandChild = (child as ContentControl).Content as UIElement;
                    //(grandChild as StackPanel).Background = new SolidColorBrush(Colors.Black);

                }





                this.loadingPage.Visibility = Windows.UI.Xaml.Visibility.Collapsed;
                this.contentView.Visibility = Windows.UI.Xaml.Visibility.Collapsed;

                Color bgColor = (App.Current.Resources["TheBackgroundColor"] as SolidColorBrush).Color;



                this.inputGrid.Children.Add(outputUI);

                var invoke = (grandChild as StackPanel).FindName(cmdShortName);

                if (invoke is Button)
                {
                    (invoke as Button).Click += SplitPage_Click;
                }
                this.inputGrid.Visibility = Windows.UI.Xaml.Visibility.Visible;
            }
            catch
            {

            }
        }

        private async void handleWebResponse(IAsyncResult result)
        {

            object outputObject = null;
            await Dispatcher.RunAsync(CoreDispatcherPriority.Normal, () =>
            {
                string webResult;
                WebResponse response = (App.Current.Resources["CurrentWebRequest"] as HttpWebRequest).EndGetResponse(result);
                
                Stream responseStream = response.GetResponseStream();

                using (StreamReader reader = new StreamReader(responseStream))
                {
                    webResult = reader.ReadToEnd();
                }

                App.Current.Resources["CurrentWebResultString"] = webResult;

                createCommandElement(webResult);

                
                response.Dispose();    
            });
            
            
            
        }

        void SplitPage_Click(object sender, RoutedEventArgs e)
        {
            
        }

        
        #region Page state management

        /// <summary>
        /// Populates the page with content passed during navigation.  Any saved state is also
        /// provided when recreating a page from a prior session.
        /// </summary>
        /// <param name="navigationParameter">The parameter value passed to
        /// <see cref="Frame.Navigate(Type, Object)"/> when this page was initially requested.
        /// </param>
        /// <param name="pageState">A dictionary of state preserved by this page during an earlier
        /// session.  This will be null the first time a page is visited.</param>
        protected override void LoadState(Object navigationParameter, Dictionary<String, Object> pageState)
        {
            Windows.UI.ViewManagement.ApplicationView.TryUnsnap();
            // Run the PopInThemeAnimation 
            Windows.UI.Xaml.Media.Animation.Storyboard sb =
                this.FindName("PopInStoryboard") as Windows.UI.Xaml.Media.Animation.Storyboard;
            
            if (sb != null) sb.Begin();
            //this.SplitGrid.Background = App.Current.Resources["BackgroundColor"] as Brush;
            //this.backButton.Foreground = App.Current.Resources["ForegroundColor"] as Brush;
            //this.backButton.BorderBrush = App.Current.Resources["ForegroundColor"] as Brush;
            //this.backButton.Background = App.Current.Resources["BackgroundColor"] as Brush;
            
            // TODO: Assign a bindable group to this.DefaultViewModel["Group"]
            // TODO: Assign a collection of bindable items to this.DefaultViewModel["Items"]
            PipeworksItem pipeworksItem = null;
            string feedTitle = null;
            if (navigationParameter is PipeworksItem)
            {
                pipeworksItem = navigationParameter as PipeworksItem;
            }
            else if (navigationParameter is string)
            {
                feedTitle = (string)navigationParameter;
                if (pageState != null && pageState.ContainsKey("Title"))
                {
                    feedTitle = (string)pageState["Title"];
                }
                pipeworksItem = PipeworksDataSource.GetPipeworksItem(feedTitle);
            }

            





            
            if (App.Current.Resources.ContainsKey("PubCenterID") && App.Current.Resources.ContainsKey("AdUnitID"))
            {
                this.splitPageAdHolder.Margin = new Thickness(12);
                this.splitPageAdHolder.Visibility = Visibility.Visible;
                try
                {
                    this.splitPageAdControl.AdUnitId = App.Current.Resources["AdUnitID"] as string;
                    this.splitPageAdControl.ApplicationId = App.Current.Resources["PubCenterID"] as string;
                }
                catch
                {
                }
                this.splitPageAdControl.Visibility = Visibility.Visible;
                this.splitPageAdHolder.Visibility = Visibility.Visible;
            }
            

            PipeworksDataSource dataSource = PipeworksDataSource.GetDatasource();
            if (dataSource.Logo != null)
            {
                this.DefaultViewModel["Logo"] = dataSource.Logo;
            }

            SolidColorBrush solidBrush = new SolidColorBrush();

            
            //this.loadingRing.Foreground = solidBrush;



            
            if (pipeworksItem != null)
            {
                this.DefaultViewModel["Feed"] = pipeworksItem;
                this.DefaultViewModel["Name"] = pipeworksItem.Name;
                this.DefaultViewModel["Background"] = pipeworksItem.BackgroundColor;
                this.DefaultViewModel["Foreground"] = pipeworksItem.ForegroundColor;
                this.DefaultViewModel["PipeworksItem"] = pipeworksItem;
                if (pipeworksItem is PipeworksTopic)
                {
                    PipeworksTopic topic = pipeworksItem as PipeworksTopic;
                    List<PipeworksItem> pil = new List<PipeworksItem>();
                    pil.Add(pipeworksItem);
                    this.DefaultViewModel["Items"] = pil;
                }

                if (pipeworksItem is PipeworksBlog)
                {
                    this.DefaultViewModel["Items"] = (pipeworksItem as PipeworksBlog).Items;
                }

                if (pipeworksItem is PipeworksTopicGroup)
                {
                    
                    
                    this.DefaultViewModel["Items"] = (pipeworksItem as PipeworksTopicGroup).Topics;
                }

                if (pipeworksItem is PipeworksCommandGroup)
                {


                    this.DefaultViewModel["Items"] = (pipeworksItem as PipeworksCommandGroup).Commands;
                }

                if (pipeworksItem is PipeworksCommand)
                {
                    PipeworksCommand cmd = pipeworksItem as PipeworksCommand;
                    List<PipeworksItem> pil = new List<PipeworksItem>();
                    pil.Add(pipeworksItem);
                    this.DefaultViewModel["Items"] = pil;
                }
                //backButton.Foreground = new SolidColorBrush(pipeworksItem.ForegroundColor);
                //backButton.Background = new SolidColorBrush(pipeworksItem.BackgroundColor);
                //Object glyph = this.FindName("BackgroundGlyph");
                
                //this.itemListView.Template.SetValue
                //this.DefaultViewModel["Items"] = pipeworksItem;
            }
            else if (feedTitle == "Me")
            {
                // Show the profile in the web view
                this.DefaultViewModel["Name"] = String.Empty;
                this.DefaultViewModel["Background"] = dataSource.BackgroundColor;
                this.DefaultViewModel["Foreground"] = dataSource.ForegroundColor;
                // this.contentView.Visibility = Visibility.Visible;
                this.loadingPage.Visibility = Visibility.Visible;
                this.contentView.Navigate(new Uri(dataSource.ServiceUrl + "?-Me"));
            }

            if (pageState == null)
            {
                // When this is a new page, select the first item automatically unless logical page
                // navigation is being used (see the logical page navigation #region below.)
                if (!this.UsingLogicalPageNavigation() && this.itemsViewSource.View != null)
                {
                    this.itemsViewSource.View.MoveCurrentToFirst();
                }
                else
                {
                    //this.itemsViewSource.View.MoveCurrentToPosition(-1);
                }
            }
            else
            {
                // Restore the previously saved state associated with this page
                if (pageState.ContainsKey("SelectedItem") && this.itemsViewSource.View != null)
                {
                    // TODO: Invoke this.itemsViewSource.View.MoveCurrentTo() with the selected
                    //       item as specified by the value of pageState["SelectedItem"]

                    string itemTitle = (string)pageState["SelectedItem"];
                    PipeworksItem selectedItem = PipeworksDataSource.GetItem(itemTitle);
                    this.itemsViewSource.View.MoveCurrentTo(selectedItem);
                }
            }
        }

        /// <summary>
        /// Preserves state associated with this page in case the application is suspended or the
        /// page is discarded from the navigation cache.  Values must conform to the serialization
        /// requirements of <see cref="SuspensionManager.SessionState"/>.
        /// </summary>
        /// <param name="pageState">An empty dictionary to be populated with serializable state.</param>
        protected override void SaveState(Dictionary<String, Object> pageState)
        {
            if (this.itemsViewSource.View != null)
            {
                var selectedItem = this.itemsViewSource.View.CurrentItem;
                // TODO: Derive a serializable navigation parameter and assign it to
                //       pageState["SelectedItem"]
                if (selectedItem != null)
                {
                    string itemTitle = ((PipeworksItem)selectedItem).Name;
                    pageState["SelectedItem"] = itemTitle;
                }


                // Save page title
                PipeworksItem feedData = this.DefaultViewModel["Feed"] as PipeworksItem;
                pageState["Title"] = feedData.Name;
            }
        }

        #endregion

        #region Logical page navigation

        // Visual state management typically reflects the four application view states directly
        // (full screen landscape and portrait plus snapped and filled views.)  The split page is
        // designed so that the snapped and portrait view states each have two distinct sub-states:
        // either the item list or the details are displayed, but not both at the same time.
        //
        // This is all implemented with a single physical page that can represent two logical
        // pages.  The code below achieves this goal without making the user aware of the
        // distinction.

        /// <summary>
        /// Invoked to determine whether the page should act as one logical page or two.
        /// </summary>
        /// <param name="viewState">The view state for which the question is being posed, or null
        /// for the current view state.  This parameter is optional with null as the default
        /// value.</param>
        /// <returns>True when the view state in question is portrait or snapped, false
        /// otherwise.</returns>
        private bool UsingLogicalPageNavigation(ApplicationViewState? viewState = null)
        {
            if (viewState == null) viewState = ApplicationView.Value;
            return viewState == ApplicationViewState.FullScreenPortrait ||
                viewState == ApplicationViewState.Snapped;
        }

        CookieContainer sessionContaineer;

        

        /// <summary>
        /// Invoked when an item within the list is selected.
        /// </summary>
        /// <param name="sender">The GridView (or ListView when the application is Snapped)
        /// displaying the selected item.</param>
        /// <param name="e">Event data that describes how the selection was changed.</param>
        async void ItemListView_SelectionChanged(object sender, SelectionChangedEventArgs e)
        {
            // Invalidate the view state when logical page navigation is in effect, as a change
            // in selection may cause a corresponding change in the current logical page.  When
            // an item is selected this has the effect of changing from displaying the item list
            // to showing the selected item's details.  When the selection is cleared this has the
            // opposite effect.
            if (this.UsingLogicalPageNavigation()) this.InvalidateVisualState();
            Windows.UI.ViewManagement.ApplicationView.TryUnsnap();
            // Add this code to populate the web view
            //  with the content of the selected blog post.
            Selector list = sender as Selector;
            PipeworksItem selectedItem = list.SelectedItem as PipeworksItem;
            PipeworksDataSource dataSource = PipeworksDataSource.GetDatasource();
            if (selectedItem != null && !String.IsNullOrEmpty(selectedItem.Name))
            {
                PipeworksItem pipeworksItem = PipeworksDataSource.GetPipeworksItem(selectedItem.Name);
            }
            
            PipeworksDataSource feedDataSource = PipeworksDataSource.GetDatasource();
            string baseUrl = feedDataSource.ServiceUrl.ToString();
            baseUrl = baseUrl.Substring(0, baseUrl.LastIndexOf("/")).TrimEnd('/');
            if (selectedItem != null && ! String.IsNullOrEmpty(selectedItem.Content))
            {
                SolidColorBrush fg = Application.Current.Resources["TheForegroundColor"] as SolidColorBrush;
                SolidColorBrush bg = Application.Current.Resources["TheBackgroundColor"] as SolidColorBrush;
                string hexfg = "#" + fg.Color.R.ToString("x2") + fg.Color.G.ToString("x2") + fg.Color.B.ToString("x2");
                string hexbg = "#" + bg.Color.R.ToString("x2") + bg.Color.G.ToString("x2") + bg.Color.B.ToString("x2");

                string fullContent = @"
<html>
<head>
<style type='text/css'>
    body {
        color : " + hexfg + @";
        background-color : " + hexbg + @";
        font-family : Segoe UI;
        font-size : 1.66em;
    }    
    a {
        color : " + hexfg + @"
    }
    a:hover {
        text-decoration : none;
        letter-spacing : 1.1px
    }
</style>
</head>
<body>
" + Environment.NewLine + selectedItem.Content + Environment.NewLine + "</body></html>"; 

                
                
                // Make / Relative links relative to the serviceURL directory with a little bix of Regex Magic.  Also, apply ?snug=true

                string replacement = @"href=""" + baseUrl.TrimEnd('/') + @"/$1" + @"/?snug=true""";
                


                fullContent = Regex.Replace(fullContent, @"href=[""']/([^""']{1,})/[""']", replacement, RegexOptions.IgnoreCase);
                fullContent = Regex.Replace(fullContent, @"href=[""']/([^""']{1,})[""']", replacement, RegexOptions.IgnoreCase);
                this.contentView.NavigateToString(fullContent);
                string sUrl = dataSource.ServiceUrl.ToString();
                
            }
            else if (selectedItem != null && selectedItem.Url != null) 
            {
                if (selectedItem is PipeworksCommand)
                {
                    
                    PipeworksCommand commandInfo = selectedItem as PipeworksCommand;
                    if (App.Current.Resources.ContainsKey("CurrentCommand"))
                    {
                        PipeworksCommand currentCommand = App.Current.Resources["CurrentCommand"] as PipeworksCommand;

                        if (currentCommand.RealName == (selectedItem as PipeworksCommand).RealName &&
                            App.Current.Resources.ContainsKey("CurrentWebRequest"))
                        {
                            HttpWebRequest currentRequest = App.Current.Resources["CurrentWebRequest"] as HttpWebRequest;
                            if (currentRequest.RequestUri.ToString().Contains(currentCommand.RealName))
                            {
                                string webResult = (string)App.Current.Resources["CurrentWebResultString"];
                                // We're already here.  Recreate the output and call it good.
                                createCommandElement(webResult);
                                return;
                            }                            
                        }

                        
                        
                    }
                    App.Current.Resources["CurrentCommand"] = commandInfo;
                    if (commandInfo.RequiresLogin)
                    {
                        if (String.IsNullOrEmpty(feedDataSource.CurrentFacebookAccessToken) && String.IsNullOrEmpty(feedDataSource.CurrentLiveIDAccessToken))
                        {
                            this.contentView.Visibility = Visibility.Collapsed;
                            if (!String.IsNullOrEmpty(feedDataSource.FacebookAppId))
                            {
                                this.facebookLoginButton.Visibility = Visibility.Visible;
                            }
                            
                            this.loginButtonPanel.Visibility = Visibility.Visible;
                            this.liveLoginButton.Visibility = Visibility.Visible;
                            
                        }                        
                        else if (! String.IsNullOrEmpty(feedDataSource.CurrentLiveIDAccessToken))
                        {
                            string loginScope = feedDataSource.LiveLoginScope;
                            string accessToken = await feedDataSource.GetLiveIDAccessToken(loginScope);


                            string newUrl = selectedItem.Url.ToString();

                            string findStr = "/" + commandInfo.RealName + "/";
                            int cmdNameIndex = newUrl.IndexOf(findStr, StringComparison.CurrentCultureIgnoreCase);

                            if (cmdNameIndex >= 0)
                            {
                                newUrl = newUrl.Substring(0, cmdNameIndex) + "/";
                            }
                            if (newUrl.Contains("?"))
                            {
                                newUrl = newUrl + "&LiveIDConfirmed=true&accesstoken=" + feedDataSource.CurrentLiveIDAccessToken + "&ReturnTo=" + Uri.EscapeDataString(newUrl + commandInfo.RealName + "/?Snug=true");
                            }
                            else
                            {
                                newUrl = newUrl + "?LiveIDConfirmed=true&accesstoken=" + feedDataSource.CurrentLiveIDAccessToken + "&ReturnTo=" + Uri.EscapeDataString(newUrl + commandInfo.RealName + "/?Snug=true"); ;
                            }
                            
                            
                            this.loadingPage.Visibility = Visibility.Visible;
                            this.contentView.Visibility = Visibility.Collapsed;
                            this.contentView.Navigate(new Uri(newUrl));
                            this.facebookLoginButton.Visibility = Visibility.Collapsed;
                            this.loginButtonPanel.Visibility = Visibility.Collapsed;
                            
                            this.FacebookLoginStatus.IsEnabled = true;

                        } else {
                            string newUrl = selectedItem.Url.ToString();
                            string findStr = "/" + commandInfo.RealName + "/";
                            int cmdNameIndex = newUrl.IndexOf(findStr,StringComparison.CurrentCultureIgnoreCase);

                            

                            if (cmdNameIndex >= 0)
                            {
                                newUrl = newUrl.Substring(0, cmdNameIndex) + "/";
                            }
                            if (newUrl.Contains("?"))
                            {
                                newUrl = newUrl + "&FacebookConfirmed=true&accesstoken=" + feedDataSource.CurrentFacebookAccessToken + "&ReturnTo=" + Uri.EscapeDataString(newUrl + commandInfo.RealName + "/?Snug=true");
                            }
                            else
                            {
                                newUrl = newUrl + "?FacebookConfirmed=true&accesstoken=" + feedDataSource.CurrentFacebookAccessToken + "&ReturnTo=" + Uri.EscapeDataString(newUrl + commandInfo.RealName + "/?Snug=true"); ;
                            }

                            
                            
                            this.loadingPage.Visibility = Visibility.Visible;
                            this.contentView.Visibility = Visibility.Collapsed;
                            this.contentView.Navigate(new Uri(newUrl));
                            this.facebookLoginButton.Visibility = Visibility.Collapsed;
                            this.liveLoginButton.Visibility = Visibility.Collapsed;
                            

                            
                        }
                        
                        //this.facebookLoginButton.Resources["FacebookAppId"] = pip
                    }
                    else
                    {
                        this.loadingPage.Visibility = Visibility.Visible;
                        this.contentView.Visibility = Visibility.Collapsed;


                        //App.Current.Resources["CurrentWebRequest"] = WebRequest.CreateHttp(selectedItem.Url + "&Platform=WPF");
                        //HttpWebRequest currentWebRequest = App.Current.Resources["CurrentWebRequest"] as HttpWebRequest;
                        //currentWebRequest.BeginGetResponse(handleWebResponse, null);
                        this.contentView.Navigate(selectedItem.Url);
                        
                        this.facebookLoginButton.Visibility = Visibility.Collapsed;
                        this.liveLoginButton.Visibility = Visibility.Collapsed;
                    }
                }
                else
                {
                    this.loadingPage.Visibility = Visibility.Visible;
                    this.contentView.Visibility = Visibility.Collapsed;
                    this.contentView.Navigate(selectedItem.Url);
                }
                
            }

            if (this.itemListView.Items.Count == 1)
            {
                this.itemListView.Visibility = Windows.UI.Xaml.Visibility.Collapsed;
                this.itemTitle.Visibility = Windows.UI.Xaml.Visibility.Visible;
            }
            else
            {
                this.itemListView.Visibility = Windows.UI.Xaml.Visibility.Visible;
                this.itemTitle.Visibility = Windows.UI.Xaml.Visibility.Collapsed;
            }
        }

        

        /// <summary>
        /// Invoked when the page's back button is pressed.
        /// </summary>
        /// <param name="sender">The back button instance.</param>
        /// <param name="e">Event data that describes how the back button was clicked.</param>
        protected override void GoBack(object sender, RoutedEventArgs e)
        {
            Frame rootFrame = Window.Current.Content as Frame;
            if (!rootFrame.Navigate(typeof(ItemsPage)))
            {
            }

            /*
            if (this.UsingLogicalPageNavigation() && itemListView.SelectedItem != null)
            {
                // When logical page navigation is in effect and there's a selected item that
                // item's details are currently displayed.  Clearing the selection will return to
                // the item list.  From the user's point of view this is a logical backward
                // navigation.
                this.itemListView.SelectedItem = null;
            }
            else
            {
                // When logical page navigation is not in effect, or when there is no selected
                // item, use the default back button behavior.
                base.GoBack(sender, e);
            }*/
        }

        protected override void GoHome(object sender, RoutedEventArgs e)
        {
            Frame rootFrame = Window.Current.Content as Frame;
            if (!rootFrame.Navigate(typeof(ItemsPage)))
            {
            }
            base.GoHome(sender, e);
        }

        async void ViewInWebPage(object sender, RoutedEventArgs e)
        {
            string safeUrl = this.currentUrl.ToString().Replace("Snug=true", "");
            await Launcher.LaunchUriAsync(
                new Uri(safeUrl)
            );
            
        }

        

        /// <summary>
        /// Invoked to determine the name of the visual state that corresponds to an application
        /// view state.
        /// </summary>
        /// <param name="viewState">The view state for which the question is being posed.</param>
        /// <returns>The name of the desired visual state.  This is the same as the name of the
        /// view state except when there is a selected item in portrait and snapped views where
        /// this additional logical page is represented by adding a suffix of _Detail.</returns>
        protected override string DetermineVisualState(ApplicationViewState viewState)
        {            
            // Update the back button's enabled state when the view state changes
            var logicalPageBack = this.UsingLogicalPageNavigation(viewState) && this.itemListView.SelectedItem != null;
            var physicalPageBack = this.Frame != null && this.Frame.CanGoBack;
            this.DefaultViewModel["CanGoBack"] = logicalPageBack || physicalPageBack;

            // Determine visual states for landscape layouts based not on the view state, but
            // on the width of the window.  This page has one layout that is appropriate for
            // 1366 virtual pixels or wider, and another for narrower displays or when a snapped
            // application reduces the horizontal space available to less than 1366.
            if (viewState == ApplicationViewState.Filled ||
                viewState == ApplicationViewState.FullScreenLandscape)
            {
                var windowWidth = Window.Current.Bounds.Width;
                if (windowWidth >= 1366) return "FullScreenLandscapeOrWide";
                return "FilledOrNarrow";
            }

            

            // When in portrait or snapped start with the default visual state name, then add a
            // suffix when viewing details instead of the list
            var defaultStateName = base.DetermineVisualState(viewState);
            return logicalPageBack ? defaultStateName + "_Detail" : defaultStateName;
        }

        #endregion

        Uri currentUrl;

        string scriptsWithinPage;
        string currentHtml;
        private void loadCompleted(object sender, NavigationEventArgs e)
        {
            scriptsWithinPage = String.Empty;
            currentUrl = e.Uri;
            PipeworksDataSource feedDataSource = PipeworksDataSource.GetDatasource();
            lastWebView = new WebViewBrush();
            lastWebView.SourceName = "contentView";
            lastWebView.Redraw();

            if (currentUrl != null && String.Compare(currentUrl.DnsSafeHost, feedDataSource.ServiceUrl.DnsSafeHost, StringComparison.OrdinalIgnoreCase) != 0)
            {
                this.ItemOptions.Visibility = Windows.UI.Xaml.Visibility.Visible;
                this.viewInWebPageButton.Visibility = Visibility.Visible;
            }
            else
            {
                this.viewInWebPageButton.Visibility = Visibility.Collapsed;
            }
            
            
            string html = this.contentView.InvokeScript("eval", new string[] {"document.documentElement.outerHTML;"});
            string realLocation = this.contentView.InvokeScript("eval", new string[] { "location.href" });

            if (!String.IsNullOrEmpty(realLocation))
            {
                currentUrl = new Uri(realLocation);
            }

            if (!String.IsNullOrEmpty(html))
            {
                currentHtml = html;
                // See if there's a script in there, so we can give the option of running it.
                /*
                 * 
                 Optimize365 = 
[regex]::Match(, "<pre class='PowerShellColorizedScript' style='font-family:Consolas'>([\s\S]{1,})</pre>", "Multiline, Ignorecase")
Optimize365.Value -replace "<[^>]*>", ""* 
                 */

                MatchCollection matches = Regex.Matches(html, "<pre[^>]*>([\\s\\S]{1,})</pre>", RegexOptions.Multiline | RegexOptions.IgnoreCase);
                if (matches.Count > 0) {
                    foreach (Match match in matches) {
                        string tagLess =Regex.Replace(match.Value, "<[^>]*>", "");
                        scriptsWithinPage += tagLess;
                    }
                }
            }

            if (!string.IsNullOrEmpty(scriptsWithinPage))
            {
                this.ItemOptions.Visibility = Windows.UI.Xaml.Visibility.Visible;
                //this.runScriptButton.Visibility = Windows.UI.Xaml.Visibility.Visible;
                this.copyScriptButton.Visibility = Windows.UI.Xaml.Visibility.Visible;
            }
            else
            {
                
                this.copyScriptButton.Visibility = Windows.UI.Xaml.Visibility.Collapsed;
            }

            
            this.viewInPageButton.IsEnabled = true;


            if (currentUrl.ToString().Contains("Platform="))
            {
                // this.contentView.InvokeScript("document.innerHTML", new string[] { });

            }


            // string invokeScriptResult = this.contentView.InvokeScript("document.innerHTML", new string[] { });
            this.contentView.Visibility = Visibility.Visible;
            this.loadingPage.Visibility = Visibility.Collapsed;    
            
            // (new MessageDialog(e.Uri.ToString())).ShowAsync();

        }

        private void itemListView_DropDownOpened_1(object sender, object e)
        {
            itemDetail.Visibility = Windows.UI.Xaml.Visibility.Collapsed;

        }

        private void itemListView_DropDownClosed_1(object sender, object e)
        {
            itemDetail.Visibility = Windows.UI.Xaml.Visibility.Visible;
        }

        private async void loginToLive_Click(object sender, RoutedEventArgs e)
        {
            PipeworksDataSource feedDataSource = PipeworksDataSource.GetDatasource();
            //string serviceUrl = feedDataSource.ServiceUrl.ToString();


            //string facebookAppId = feedDataSource.FacebookAppId;
            
            string loginScope = feedDataSource.LiveLoginScope;

            string accessToken = await feedDataSource.GetLiveIDAccessToken(loginScope);

            PipeworksItem selectedItem = this.itemListView.SelectedItem as PipeworksItem;

            if (selectedItem == null) { return; }
            PipeworksCommand commandInfo = selectedItem as PipeworksCommand;
            if (commandInfo == null) { return; }
            string newUrl = selectedItem.Url.ToString();

            string findStr = "/" + commandInfo.RealName + "/";
            int cmdNameIndex = newUrl.IndexOf(findStr, StringComparison.CurrentCultureIgnoreCase);

            if (cmdNameIndex >= 0)
            {
                newUrl = newUrl.Substring(0, cmdNameIndex) + "/";
            }
            if (newUrl.Contains("?"))
            {
                newUrl = newUrl + "&LiveIDConfirmed=true&accesstoken=" + feedDataSource.CurrentLiveIDAccessToken + "&ReturnTo=" + Uri.EscapeDataString(newUrl + commandInfo.RealName + "/?Snug=true");
            }
            else
            {
                newUrl = newUrl + "?LiveIDConfirmed=true&accesstoken=" + feedDataSource.CurrentLiveIDAccessToken + "&ReturnTo=" + Uri.EscapeDataString(newUrl + commandInfo.RealName + "/?Snug=true"); ;
            }
            this.loadingPage.Visibility = Visibility.Visible;
            this.contentView.Navigate(new Uri(newUrl));
            this.facebookLoginButton.Visibility = Visibility.Collapsed;
            this.loginButtonPanel.Visibility = Visibility.Collapsed;
            
            this.FacebookLoginStatus.IsEnabled = true;

        }

        private async void loginToFacebook_Click(object sender, RoutedEventArgs e)
        {
            PipeworksDataSource feedDataSource = PipeworksDataSource.GetDatasource();
            string serviceUrl = feedDataSource.ServiceUrl.ToString();


            string facebookAppId = feedDataSource.FacebookAppId;
            string facebookScope = feedDataSource.FacebookScope;
            
            string accessToken = await feedDataSource.GetFacebookAccessToken(facebookAppId, serviceUrl, facebookScope);

            PipeworksItem selectedItem = this.itemListView.SelectedItem as PipeworksItem;
            
            if (selectedItem == null) { return; }
            PipeworksCommand commandInfo = selectedItem as PipeworksCommand;
            if (commandInfo == null) { return; } 
            string newUrl = selectedItem.Url.ToString();
            
            string findStr = "/" + commandInfo.RealName + "/";
            int cmdNameIndex = newUrl.IndexOf(findStr, StringComparison.CurrentCultureIgnoreCase);

            if (cmdNameIndex >= 0)
            {
                newUrl = newUrl.Substring(0, cmdNameIndex) + "/" ;
            }
            if (newUrl.Contains("?"))
            {
                newUrl = newUrl + "&FacebookConfirmed=true&accesstoken=" + feedDataSource.CurrentFacebookAccessToken + "&ReturnTo=" + Uri.EscapeDataString(newUrl + commandInfo.RealName + "/?Snug=true");
            }
            else
            {
                newUrl = newUrl + "?FacebookConfirmed=true&accesstoken=" + feedDataSource.CurrentFacebookAccessToken + "&ReturnTo=" + Uri.EscapeDataString(newUrl + commandInfo.RealName + "/?Snug=true"); ;
            }
            this.loadingPage.Visibility = Visibility.Visible;
            this.contentView.Navigate(new Uri(newUrl));
            this.facebookLoginButton.Visibility = Visibility.Collapsed;            
            this.FacebookLoginStatus.IsEnabled = true;
            this.loginButtonPanel.Visibility = Visibility.Collapsed;
            



        }

        private async void Facebook_Profile_Click(object sender, RoutedEventArgs e)
        {
            
            //this.itemGridView.Visibility = Windows.UI.Xaml.Visibility.Collapsed;
            //this.itemListView.Visibility = Windows.UI.Xaml.Visibility.Collapsed;
            PipeworksDataSource feedDataSource = PipeworksDataSource.GetDatasource();
            this.loadingPage.Visibility = Visibility.Visible;
            this.contentView.Navigate(new Uri(feedDataSource.ServiceUrl.ToString() + "?-Me"));
            //string serviceUrl = this.DefaultViewModel["ServiceUrl"].ToString();
            //string facebookAppId = this.DefaultViewModel["FacebookAppId"].ToString();
            //string facebookScope = this.DefaultViewModel["FacebookScope"].ToString();
            
            //string accessToken = await feedDataSource.GetFacebookAccessToken(facebookAppId, serviceUrl, facebookScope);
        }

        private void RunCommand_Click_1(object sender, RoutedEventArgs e)
        {
            if (!this.Command.Text.StartsWith("/"))
            {
                (new MessageDialog("Location must be within the current site (it must start with /)", "whoops")).ShowAsync();
                return;
            }

            //this.contentView.Visibility = Visibility.Visible;
            this.loginButtonPanel.Visibility = Visibility.Collapsed;


            PipeworksDataSource feedDataSource = PipeworksDataSource.GetDatasource();
            string baseUrl = feedDataSource.ServiceUrl.AbsoluteUri.Substring(0, feedDataSource.ServiceUrl.ToString().IndexOf(feedDataSource.ServiceUrl.LocalPath));

            string newUrl = baseUrl + this.Command.Text;

            this.loadingPage.Visibility = Visibility.Visible;
            this.contentView.Navigate(new Uri(newUrl));


        }

        private void Top_AppBar_Opened(object sender, object e)
        {
            //this.contentView.Visibility = Visibility.Collapsed;
            switchWebView(false);
        }

        private void Top_Appbar_Closed(object sender, object e)
        {
            //this.contentView.Visibility = Visibility.Visible;
            switchWebView(true);
        }


        private void switchWebView(bool back)
        {
            if (!back)
            {
                WebViewBrush brush = new WebViewBrush();
                brush.SourceName = "contentView";
                brush.Redraw();


                this.contentView.Visibility = Visibility.Collapsed;
                this.splitPageAdHolder.Tag = this.splitPageAdHolder.Visibility;
                this.splitPageAdHolder.Visibility = Visibility.Collapsed;
                this.contentViewBrushRect.Fill = brush;
                this.contentViewBrushRect.Visibility = Visibility.Visible;
            }
            else
            {
                this.contentView.Visibility = Visibility.Visible;
                this.contentViewBrushRect.Visibility = Visibility.Collapsed;
                if (this.splitPageAdHolder.Tag != null)
                {
                    this.splitPageAdHolder.Visibility = (Visibility)(this.splitPageAdHolder.Tag);
                    
                }
                
            }
        }

        private async void CopyToClipboard(object sender, RoutedEventArgs e)
        {
            if (!String.IsNullOrEmpty(scriptsWithinPage))
            {
                DataPackage dp = new DataPackage();
                dp.SetText(scriptsWithinPage);
                Clipboard.SetContent(dp);
            }
            else if (! String.IsNullOrEmpty(currentHtml))
            {
                DataPackage dp = new DataPackage();
                dp.SetHtmlFormat(currentHtml);
                dp.SetText(currentHtml);
                Clipboard.SetContent(dp);
            }
        }

        private async void SaveDocument(object sender, RoutedEventArgs e)
        {
            if (!String.IsNullOrEmpty(scriptsWithinPage) || ! String.IsNullOrEmpty(currentHtml))
            {
                FileSavePicker picker;
                picker = new FileSavePicker();


                if (!String.IsNullOrEmpty(scriptsWithinPage))
                {
                    picker.FileTypeChoices.Add("PowerShell Script", new List<string>(new string[] { ".ps1" }));
                    picker.FileTypeChoices.Add("HTML files", new List<string>(new string[] { ".html", ".htm" }));
                }
                else
                {
                    picker.FileTypeChoices.Add("HTML files", new List<string>(new string[] { ".html", ".htm" }));
                }
                var picked = await picker.PickSaveFileAsync();
                if (picked != null)
                {
                    if (picked.Path.EndsWith(".ps1"))
                    {
                        await FileIO.WriteTextAsync(picked, scriptsWithinPage);
                    }
                    else
                    {
                        await FileIO.WriteTextAsync(picked, currentHtml);
                    }
                    
                }

            }


        }

        private async void runScript(object sender, RoutedEventArgs e)
        {
            
            StorageFile ps1File = await Windows.Storage.DownloadsFolder.CreateFileAsync("lastScript.ps1", CreationCollisionOption.GenerateUniqueName);
            await FileIO.WriteTextAsync(ps1File, scriptsWithinPage);


            string batchCmd = "powershell.exe -noexit -executionpolicy bypass -file " + ps1File.Path;


            StorageFile cmdFile = await Windows.Storage.DownloadsFolder.CreateFileAsync("lastScript.cmd", CreationCollisionOption.GenerateUniqueName);
            await FileIO.WriteTextAsync(cmdFile, batchCmd);


            
            await Launcher.LaunchFileAsync(ps1File);
        }
    }
}
'@

}

$appXManifest = {
param($IdName, $PublisherCN, $version, $displayName, $publisher, $description, $bgcolor, $fgTextColor)
@"
<?xml version="1.0" encoding="utf-8"?>
<Package xmlns="http://schemas.microsoft.com/appx/2010/manifest">
  <Identity Name="$IdName" Publisher="$PublisherCN" Version="$Version"/> 
  <Properties>
    <DisplayName>$([Security.SecurityElement]::Escape($DisplayName))</DisplayName>
    <PublisherDisplayName>$([Security.SecurityElement]::Escape($publisher))</PublisherDisplayName>
    <Logo>Assets\storeLogo.png</Logo>
    <Description>$([Security.SecurityElement]::Escape($Description))</Description>
  </Properties>
  <Prerequisites>
    <OSMinVersion>6.2.1</OSMinVersion>
    <OSMaxVersionTested>6.2.1</OSMaxVersionTested>
  </Prerequisites>
  <Resources>
    <Resource Language="x-generate" />
  </Resources>
  <Applications>
    <Application Id="App" Executable="$DisplayName.exe" EntryPoint="PipeworksApp.App">
      <VisualElements DisplayName="$DisplayName" Logo="Assets\squareTile.png" SmallLogo="Assets\smallTile.png" Description="$([Web.HttpUtility]::HtmlAttributeEncode($description))" ForegroundText="$fgTextColor" BackgroundColor="$bgcolor">
        <DefaultTile ShowName="noLogos" ShortName="$DisplayName" WideLogo="Assets\wideTile.png" />
        <SplashScreen Image="Assets\splash.png" BackgroundColor="$bgcolor" />
      </VisualElements>
    </Application>
  </Applications>
  <Capabilities>
    <Capability Name="internetClient" />
  </Capabilities>
</Package>
"@
}


$assemblyInfoCs = { param($name, $Publisher)
@"
using System.Reflection;
using System.Runtime.CompilerServices;
using System.Runtime.InteropServices;

// General Information about an assembly is controlled through the following 
// set of attributes. Change these attribute values to modify the information
// associated with an assembly.
[assembly: AssemblyTitle("$Name")]
[assembly: AssemblyDescription("")]
[assembly: AssemblyConfiguration("")]
[assembly: AssemblyCompany("$Publisher")]
[assembly: AssemblyProduct("")]
[assembly: AssemblyCopyright("Copyright ©  All rights reserved")]
[assembly: AssemblyTrademark("")]
[assembly: AssemblyCulture("")]

// Version information for an assembly consists of the following four values:
//
//      Major Version
//      Minor Version 
//      Build Number
//      Revision
//
// You can specify all the values or you can default the Build and Revision Numbers 
// by using the '*' as shown below:
// [assembly: AssemblyVersion("1.0.*")]
[assembly: AssemblyVersion("1.0.0.0")]
[assembly: AssemblyFileVersion("1.0.0.0")]
[assembly: ComVisible(false)]
"@
}


$fbLogo64 = "iVBORw0KGgoAAAANSUhEUgAAAIwAAACMCAMAAACZHrEMAAAAWlBMVEUAAAA7W5k7W5k7W5k7W5k7W5mSpMfb4exthbRIZqA+Xpt1jLjR2ef///+drczO1uY7W5lshLNHZZ/z9fmFmb9UcKa2wtnn6/Kpt9JgeqyRo8Z4jrnCzN/a4Oyzuvb+AAAABnRSTlMAv2DPIO/41WVhAAABTElEQVR42u3c2WrDMBRFUQ9JG7e9GuzEdqb//82SFkpLhElCkE5h7y9YL4L7olNdaupQuLqpvlu1QaB29WVZB4nWF00bRGqrqgkyNVWtg6mrIBQYMGDAgAEDpjAmbt3ofxqdczHuSmD2zlsqnx3THyYzk8D0bjATwcTJTAUz22JjRkzvbTmXD9OfTQfjTQczmw4mmhBmEsI4E8JMQpitCWFOdkvHLJjebipmwRyVMLMlG07uT3kuPZ+kbMvcwIMl2ocymPQ7FsLshDBDKISJCYwHAwYMGDBgwIDRxnh7IA8GzJ2NShgHBsydHZQwEQyY/4wJYDJjZv+rs103+Os4yMGAAQMGDBgwYMCAAQMGDBgwEpi37hm9JzAf3WIpTLd5Ri8JzOtmMTBgwIABAwYMGDBgMmD4rw3m8aTGcKRmgpQGlKSmpbRGt6TmyD4BW3thMbMGyXwAAAAASUVORK5CYII="

    }
    
    process {           
        


        $pubCenterInfo = if ($Manifest.PubCenter) {
            $Manifest.PubCenter
        } else {
        
            $null
        }

        $win8Identity = if ($Parameter.Identity) {
            $Parameter.Identity                
        } else {
            $null
        }


        $win8Url = $Parameter.ServiceUrl
        
        
        
        $guid = if ($module.Guid -and $module.Guid -ne "00000000-0000-0000-0000-000000000000") {
            $module.Guid
        } else {
            [GUID]::NewGuid()
        }
        

        $publisher = 
            if ($module.CompanyName) {
                $module.CompanyName
            } elseif ($module.Author) {
                $module.Author
            }

        $displayName= 
            if ($Parameter.DisplayName) {
                $Parameter.DisplayName
            } else {
                $module.Name
            }

        $asmName = if ($Parameter.AssemblyName) {
            $Parameter.AssemblyName
        } else {
            $module.Name
        }
        
        $publisher = if ($Parameter.Publisher) {
            $Parameter.Publisher
        } elseif ($Module.CompanyName) {
            $Module.CompanyName
        } else {
            $null    
        }

        if (-not $publisher) {
            Write-Error "All Win8 apps must have a publisher. Either add a CompanyName to the module manifest, or add the Publisher field to the Win8 section of the Pipeworks manifest"    
            return
        }


        $description = if ($Parameter.Description) {
            $Parameter.Description
        } elseif ($module.Description) {
            $module.Description
        } else {
            $null    
        }
        
        if (-not $description ) {
            Write-Error "All Win8 apps must have a description. Either add one to the module manifest, or add it to the Win8 section of the Pipeworks manifest"    
            return
        }


        if (-not $parameter.Assets) {
            Write-Error "No assets found.  
Please create assets with the following names and recommended resolutions:
splash.png  - 620x300
squaretile.png - 150x150
smalltile.png - 30x30
storelogo.png - 50x50
widetile.png - 310x150
"
            return
        } 
        

        $bgColor = if ($Manifest.Style.Body.'background-color') {
            $Manifest.Style.Body.'background-color'
        } else {
            "#FAFAFA"
        }
        

        $fgTextColor = if ($parameter.LightForegroundText) {
            "light"
        } else {
            "dark"
        }

        $appxMan = & $appXManifest $win8Identity.Name $win8Identity.Publisher $win8Identity.Version  $displayName $publisher $description $bgColor $fgTextColor

        if ($outputDirectory -notlike "$home\*\Projects\*") {
            $outputDirectory = Join-Path $outputDirectory "Win8"
        } else {
            
        }


        $null = New-Item "$outputDirectory" -ItemType Directory -Force
        
        $null = New-Item "$outputDirectory\Common" -ItemType Directory -Force
        
        $null = New-Item "$outputDirectory\Properties" -ItemType Directory -Force

        $null = New-Item "$outputDirectory\Assets" -ItemType Directory -Force


        $appXMan | Set-Content "$outputDirectory\Package.appxmanifest" 

        $fbLogoBytes = [Convert]::FromBase64String($fbLogo64)

        [IO.File]::WriteAllBytes("$inputDirectory\Assets\f_logo.png", $fbLogoBytes)
        $parameter.Assets += @{"f_logo.png" = "/f_logo.png" }
        foreach ($assetInfo in $Parameter.Assets.GetEnumerator()) {
            $inputPath = Join-Path "$InputDirectory\Assets" $assetInfo.Value

            if (Test-Path  $inputPath) {
                $assetBytes = [IO.File]::ReadAllBytes($inputPath)
                [IO.File]::WriteAllBytes("$outputDirectory\Assets\$($assetInfo.Key)", $assetBytes)
            }

        }


        $csAndXamlFiles = Get-ChildItem "$InputDirectory\Win8" -ErrorAction SilentlyContinue | 
            Where-Object { $_.Extension -eq '.xaml' -or $_.Extension -eq '.cs' } 
        

        $csAndXamlFiles = foreach ($csAndXam in $csAndXamlFiles) {
            $csAndXam.Name
            Copy-Item $csAndXam.FullName -Destination "$outputDirectory\$($csAndXam.Name)" -Force
        }
        $csProject = & $newcsProject $displayName $guid $Parameter.Assets $csAndXamlFiles

        $csProject = [xml]$csProject
        $csProject.Save("$outputDirectory\$($module.Name).csproj") 
        


        


        if (Test-Path "$InputDirectory\Win8\App.Xaml") {
            Get-Content "$InputDirectory\Win8\App.Xaml"|
                Set-Content "$outputDirectory\App.xaml"      
        } else {
            & $appXaml |
                Set-Content "$outputDirectory\App.xaml"

        }

        
        if (Test-Path "$InputDirectory\Win8\App.Xaml.cs") {
            Get-Content "$InputDirectory\Win8\App.Xaml.cs"|
                Set-Content "$outputDirectory\App.xaml.cs"      
        } else {
            & $appXamlCodeBehind |
                Set-Content "$outputDirectory\App.xaml.cs"
        }

        if (Test-Path "$InputDirectory\Win8\Common.cs") {
            Get-Content "$InputDirectory\Win8\Common.cs"|
                Set-Content "$outputDirectory\Common.cs"      
        } else {
        & $commonCs |
            Set-Content "$outputDirectory\Common.cs"
        }


        if (Test-Path "$InputDirectory\Win8\FailPage.xaml") {
            Get-Content "$InputDirectory\Win8\FailPage.xaml"|
                Set-Content "$outputDirectory\FailPage.xaml"      
        } else {
            & $failPage |
                Set-Content "$outputDirectory\FailPage.xaml"
        }
        if (Test-Path "$InputDirectory\Win8\FailPage.xaml.cs") {
            Get-Content "$InputDirectory\Win8\FailPage.xaml.cs"|
                Set-Content "$outputDirectory\FailPage.xaml.cs"      
        } else {
            & $failPageCodeBehind |
                Set-Content "$outputDirectory\FailPage.xaml.cs"
        }

        if (Test-Path "$InputDirectory\Win8\ItemsPage.xaml") {
            Get-Content "$InputDirectory\Win8\ItemsPage.xaml"|
                Set-Content "$outputDirectory\ItemsPage.xaml"      
        } else {
        & $itemsPageXaml |
            Set-Content "$outputDirectory\ItemsPage.xaml"
        }

        if (Test-Path "$InputDirectory\Win8\ItemsPage.xaml.cs") {
            Get-Content "$InputDirectory\Win8\ItemsPage.xaml.cs"|
                Set-Content "$outputDirectory\ItemsPage.xaml.cs"      
        } else {
            & $itemsPageCodeBehind  |
                Set-Content "$outputDirectory\ItemsPage.xaml.cs"
        }


        if (Test-Path "$InputDirectory\Win8\Common\StandardStyles.xaml") {
            Get-Content "$InputDirectory\Win8\Common\StandardStyles.xaml" |
                Set-Content "$outputDirectory\Common\StandardStyles.xaml"
        } else {
            & $standardStyles |
                Set-Content "$outputDirectory\Common\StandardStyles.xaml"
        }

        

        & $assemblyInfoCs $($Module.Name) $publisher |
            Set-Content "$outputDirectory\Properties\AssemblyInfo.cs"
        
        if (Test-Path "$InputDirectory\SplitPage.xaml") {
            Get-Content "$InputDirectory\SplitPage.xaml" |
                Set-Content "$outputDirectory\SplitPage.xaml"
        } else {
            & $splitPageXaml |
                Set-Content "$outputDirectory\SplitPage.xaml"
        }
        
        if (Test-Path "$InputDirectory\SplitPage.xaml.cs") {
            Get-Content "$InputDirectory\SplitPage.xaml.cs" |
                Set-Content "$outputDirectory\SplitPage.xaml.cs"
        } else {
            & $splitPageXamlCs |
                Set-Content "$outputDirectory\SplitPage.xaml.cs"
        }
        


        & $pipeworksDataModel $win8Url  |
            Set-Content "$outputDirectory\PipeworksData.cs"
            
        $null = $asmName


        Push-Location $outputDirectory

        $compiler = 
            dir C:\Windows\Microsoft.NET\Framework\v$('' + $PSVersionTable.CLRVersion.Major + '.' + $PSVersionTable.CLRVersion.Minor + '.' + $PSVersionTable.CLRVersion.Build) -Filter csc.exe


        $devEnv = ${env:ProgramFiles(x86)}, $env:ProgramFiles  -ne ""  | Get-ChildItem -Filter "Microsoft Visual Studio 11.0\Common7\IDE\devenv.exe"

        
        $compilerOutput = & $devenv.FullName "$outputDirectory\$($module.Name).csproj" /Deploy Release 
        $null = $null

        Pop-Location
    }

    end {
        @{}
#        $NewPages
    }
} 