#Requires -RunAsAdministrator

<#
	.DESCRIPTION
    This script is designed to run either with SCCM or directly on user context if the user can run the powershell in run as admin. This script enforce
    the file on demand only if the OS is a Windows 10 1709 or higher. The script will also runs only if a OneDrive account is configured correctly in the
    context where we run the script.
    Once pre-requisites are met, the script will:
    - Enforced file on demand (never succeed to find how to just enabled it)
    - Create a local folder under the context root OneDrive
    - Create a schedule task who will change the folder attribution on log in a 5 min random delay (OneDrive has to be connected to play with the attrib.exe)
    - Create a shortcut on the desktop to run the Schedule task on demand
	.EXAMPLE
    .\AutoPushCloud.ps1
	If pre-requisite are met will enforce file on demand, create a dedicated folder called _AutoPushCloud and create a schedule task who will change the file attribution on log...
	.NOTES
    Author: Scomnewbie

    THE SCRIPT IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
    FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
    WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
#>

Function New-WPFMessageBox {

    # For examples for use, see my blog:
    # https://smsagent.wordpress.com/2017/08/24/a-customisable-wpf-messagebox-for-powershell/
    
    # CHANGES
    # 2017-09-11 - Added some required assemblies in the dynamic parameters to avoid errors when run from the PS console host.
    
    # Define Parameters
    [CmdletBinding()]
    Param
    (
        # The popup Content
        [Parameter(Mandatory = $True, Position = 0)]
        [Object]$Content,

        # The window title
        [Parameter(Mandatory = $false, Position = 1)]
        [string]$Title,

        # The buttons to add
        [Parameter(Mandatory = $false, Position = 2)]
        [ValidateSet('OK', 'OK-Cancel', 'Abort-Retry-Ignore', 'Yes-No-Cancel', 'Yes-No', 'Retry-Cancel', 'Cancel-TryAgain-Continue', 'None')]
        [array]$ButtonType = 'OK',

        # The buttons to add
        [Parameter(Mandatory = $false, Position = 3)]
        [array]$CustomButtons,

        # Content font size
        [Parameter(Mandatory = $false, Position = 4)]
        [int]$ContentFontSize = 14,

        # Title font size
        [Parameter(Mandatory = $false, Position = 5)]
        [int]$TitleFontSize = 14,

        # BorderThickness
        [Parameter(Mandatory = $false, Position = 6)]
        [int]$BorderThickness = 0,

        # CornerRadius
        [Parameter(Mandatory = $false, Position = 7)]
        [int]$CornerRadius = 8,

        # ShadowDepth
        [Parameter(Mandatory = $false, Position = 8)]
        [int]$ShadowDepth = 3,

        # BlurRadius
        [Parameter(Mandatory = $false, Position = 9)]
        [int]$BlurRadius = 20,

        # WindowHost
        [Parameter(Mandatory = $false, Position = 10)]
        [object]$WindowHost,

        # Timeout in seconds,
        [Parameter(Mandatory = $false, Position = 11)]
        [int]$Timeout,

        # Code for Window Loaded event,
        [Parameter(Mandatory = $false, Position = 12)]
        [scriptblock]$OnLoaded,

        # Code for Window Closed event,
        [Parameter(Mandatory = $false, Position = 13)]
        [scriptblock]$OnClosed

    )

    # Dynamically Populated parameters
    DynamicParam {
        
        # Add assemblies for use in PS Console 
        Add-Type -AssemblyName System.Drawing, PresentationCore
        
        # ContentBackground
        $ContentBackground = 'ContentBackground'
        $AttributeCollection = New-Object System.Collections.ObjectModel.Collection[System.Attribute]
        $ParameterAttribute = New-Object System.Management.Automation.ParameterAttribute
        $ParameterAttribute.Mandatory = $False
        $AttributeCollection.Add($ParameterAttribute) 
        $RuntimeParameterDictionary = New-Object System.Management.Automation.RuntimeDefinedParameterDictionary
        $arrSet = [System.Drawing.Brushes] | Get-Member -Static -MemberType Property | Select -ExpandProperty Name 
        $ValidateSetAttribute = New-Object System.Management.Automation.ValidateSetAttribute($arrSet)    
        $AttributeCollection.Add($ValidateSetAttribute)
        $PSBoundParameters.ContentBackground = "White"
        $RuntimeParameter = New-Object System.Management.Automation.RuntimeDefinedParameter($ContentBackground, [string], $AttributeCollection)
        $RuntimeParameterDictionary.Add($ContentBackground, $RuntimeParameter)
        

        # FontFamily
        $FontFamily = 'FontFamily'
        $AttributeCollection = New-Object System.Collections.ObjectModel.Collection[System.Attribute]
        $ParameterAttribute = New-Object System.Management.Automation.ParameterAttribute
        $ParameterAttribute.Mandatory = $False
        $AttributeCollection.Add($ParameterAttribute)  
        $arrSet = [System.Drawing.FontFamily]::Families | Select -ExpandProperty Name 
        $ValidateSetAttribute = New-Object System.Management.Automation.ValidateSetAttribute($arrSet)
        $AttributeCollection.Add($ValidateSetAttribute)
        $RuntimeParameter = New-Object System.Management.Automation.RuntimeDefinedParameter($FontFamily, [string], $AttributeCollection)
        $RuntimeParameterDictionary.Add($FontFamily, $RuntimeParameter)
        $PSBoundParameters.FontFamily = "Segui"

        # TitleFontWeight
        $TitleFontWeight = 'TitleFontWeight'
        $AttributeCollection = New-Object System.Collections.ObjectModel.Collection[System.Attribute]
        $ParameterAttribute = New-Object System.Management.Automation.ParameterAttribute
        $ParameterAttribute.Mandatory = $False
        $AttributeCollection.Add($ParameterAttribute) 
        $arrSet = [System.Windows.FontWeights] | Get-Member -Static -MemberType Property | Select -ExpandProperty Name 
        $ValidateSetAttribute = New-Object System.Management.Automation.ValidateSetAttribute($arrSet)    
        $AttributeCollection.Add($ValidateSetAttribute)
        $PSBoundParameters.TitleFontWeight = "Normal"
        $RuntimeParameter = New-Object System.Management.Automation.RuntimeDefinedParameter($TitleFontWeight, [string], $AttributeCollection)
        $RuntimeParameterDictionary.Add($TitleFontWeight, $RuntimeParameter)

        # ContentFontWeight
        $ContentFontWeight = 'ContentFontWeight'
        $AttributeCollection = New-Object System.Collections.ObjectModel.Collection[System.Attribute]
        $ParameterAttribute = New-Object System.Management.Automation.ParameterAttribute
        $ParameterAttribute.Mandatory = $False
        $AttributeCollection.Add($ParameterAttribute) 
        $arrSet = [System.Windows.FontWeights] | Get-Member -Static -MemberType Property | Select -ExpandProperty Name 
        $ValidateSetAttribute = New-Object System.Management.Automation.ValidateSetAttribute($arrSet)    
        $AttributeCollection.Add($ValidateSetAttribute)
        $PSBoundParameters.ContentFontWeight = "Normal"
        $RuntimeParameter = New-Object System.Management.Automation.RuntimeDefinedParameter($ContentFontWeight, [string], $AttributeCollection)
        $RuntimeParameterDictionary.Add($ContentFontWeight, $RuntimeParameter)
        

        # ContentTextForeground
        $ContentTextForeground = 'ContentTextForeground'
        $AttributeCollection = New-Object System.Collections.ObjectModel.Collection[System.Attribute]
        $ParameterAttribute = New-Object System.Management.Automation.ParameterAttribute
        $ParameterAttribute.Mandatory = $False
        $AttributeCollection.Add($ParameterAttribute) 
        $arrSet = [System.Drawing.Brushes] | Get-Member -Static -MemberType Property | Select -ExpandProperty Name 
        $ValidateSetAttribute = New-Object System.Management.Automation.ValidateSetAttribute($arrSet)    
        $AttributeCollection.Add($ValidateSetAttribute)
        $PSBoundParameters.ContentTextForeground = "Black"
        $RuntimeParameter = New-Object System.Management.Automation.RuntimeDefinedParameter($ContentTextForeground, [string], $AttributeCollection)
        $RuntimeParameterDictionary.Add($ContentTextForeground, $RuntimeParameter)

        # TitleTextForeground
        $TitleTextForeground = 'TitleTextForeground'
        $AttributeCollection = New-Object System.Collections.ObjectModel.Collection[System.Attribute]
        $ParameterAttribute = New-Object System.Management.Automation.ParameterAttribute
        $ParameterAttribute.Mandatory = $False
        $AttributeCollection.Add($ParameterAttribute) 
        $arrSet = [System.Drawing.Brushes] | Get-Member -Static -MemberType Property | Select -ExpandProperty Name 
        $ValidateSetAttribute = New-Object System.Management.Automation.ValidateSetAttribute($arrSet)    
        $AttributeCollection.Add($ValidateSetAttribute)
        $PSBoundParameters.TitleTextForeground = "Black"
        $RuntimeParameter = New-Object System.Management.Automation.RuntimeDefinedParameter($TitleTextForeground, [string], $AttributeCollection)
        $RuntimeParameterDictionary.Add($TitleTextForeground, $RuntimeParameter)

        # BorderBrush
        $BorderBrush = 'BorderBrush'
        $AttributeCollection = New-Object System.Collections.ObjectModel.Collection[System.Attribute]
        $ParameterAttribute = New-Object System.Management.Automation.ParameterAttribute
        $ParameterAttribute.Mandatory = $False
        $AttributeCollection.Add($ParameterAttribute) 
        $arrSet = [System.Drawing.Brushes] | Get-Member -Static -MemberType Property | Select -ExpandProperty Name 
        $ValidateSetAttribute = New-Object System.Management.Automation.ValidateSetAttribute($arrSet)    
        $AttributeCollection.Add($ValidateSetAttribute)
        $PSBoundParameters.BorderBrush = "Black"
        $RuntimeParameter = New-Object System.Management.Automation.RuntimeDefinedParameter($BorderBrush, [string], $AttributeCollection)
        $RuntimeParameterDictionary.Add($BorderBrush, $RuntimeParameter)


        # TitleBackground
        $TitleBackground = 'TitleBackground'
        $AttributeCollection = New-Object System.Collections.ObjectModel.Collection[System.Attribute]
        $ParameterAttribute = New-Object System.Management.Automation.ParameterAttribute
        $ParameterAttribute.Mandatory = $False
        $AttributeCollection.Add($ParameterAttribute) 
        $arrSet = [System.Drawing.Brushes] | Get-Member -Static -MemberType Property | Select -ExpandProperty Name 
        $ValidateSetAttribute = New-Object System.Management.Automation.ValidateSetAttribute($arrSet)    
        $AttributeCollection.Add($ValidateSetAttribute)
        $PSBoundParameters.TitleBackground = "White"
        $RuntimeParameter = New-Object System.Management.Automation.RuntimeDefinedParameter($TitleBackground, [string], $AttributeCollection)
        $RuntimeParameterDictionary.Add($TitleBackground, $RuntimeParameter)

        # ButtonTextForeground
        $ButtonTextForeground = 'ButtonTextForeground'
        $AttributeCollection = New-Object System.Collections.ObjectModel.Collection[System.Attribute]
        $ParameterAttribute = New-Object System.Management.Automation.ParameterAttribute
        $ParameterAttribute.Mandatory = $False
        $AttributeCollection.Add($ParameterAttribute) 
        $arrSet = [System.Drawing.Brushes] | Get-Member -Static -MemberType Property | Select -ExpandProperty Name 
        $ValidateSetAttribute = New-Object System.Management.Automation.ValidateSetAttribute($arrSet)    
        $AttributeCollection.Add($ValidateSetAttribute)
        $PSBoundParameters.ButtonTextForeground = "Black"
        $RuntimeParameter = New-Object System.Management.Automation.RuntimeDefinedParameter($ButtonTextForeground, [string], $AttributeCollection)
        $RuntimeParameterDictionary.Add($ButtonTextForeground, $RuntimeParameter)

        # Sound
        $Sound = 'Sound'
        $AttributeCollection = New-Object System.Collections.ObjectModel.Collection[System.Attribute]
        $ParameterAttribute = New-Object System.Management.Automation.ParameterAttribute
        $ParameterAttribute.Mandatory = $False
        #$ParameterAttribute.Position = 14
        $AttributeCollection.Add($ParameterAttribute) 
        $arrSet = (Get-ChildItem "$env:SystemDrive\Windows\Media" -Filter Windows* | Select -ExpandProperty Name).Replace('.wav', '')
        $ValidateSetAttribute = New-Object System.Management.Automation.ValidateSetAttribute($arrSet)    
        $AttributeCollection.Add($ValidateSetAttribute)
        $RuntimeParameter = New-Object System.Management.Automation.RuntimeDefinedParameter($Sound, [string], $AttributeCollection)
        $RuntimeParameterDictionary.Add($Sound, $RuntimeParameter)

        return $RuntimeParameterDictionary
    }

    Begin {
        Add-Type -AssemblyName PresentationFramework
    }
    
    Process {

        # Define the XAML markup
        [XML]$Xaml = @"
<Window 
        xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
        x:Name="Window" Title="" SizeToContent="WidthAndHeight" WindowStartupLocation="CenterScreen" WindowStyle="None" ResizeMode="NoResize" AllowsTransparency="True" Background="Transparent" Opacity="1">
    <Window.Resources>
        <Style TargetType="{x:Type Button}">
            <Setter Property="Template">
                <Setter.Value>
                    <ControlTemplate TargetType="Button">
                        <Border>
                            <Grid Background="{TemplateBinding Background}">
                                <ContentPresenter />
                            </Grid>
                        </Border>
                    </ControlTemplate>
                </Setter.Value>
            </Setter>
        </Style>
    </Window.Resources>
    <Border x:Name="MainBorder" Margin="10" CornerRadius="$CornerRadius" BorderThickness="$BorderThickness" BorderBrush="$($PSBoundParameters.BorderBrush)" Padding="0" >
        <Border.Effect>
            <DropShadowEffect x:Name="DSE" Color="Black" Direction="270" BlurRadius="$BlurRadius" ShadowDepth="$ShadowDepth" Opacity="0.6" />
        </Border.Effect>
        <Border.Triggers>
            <EventTrigger RoutedEvent="Window.Loaded">
                <BeginStoryboard>
                    <Storyboard>
                        <DoubleAnimation Storyboard.TargetName="DSE" Storyboard.TargetProperty="ShadowDepth" From="0" To="$ShadowDepth" Duration="0:0:1" AutoReverse="False" />
                        <DoubleAnimation Storyboard.TargetName="DSE" Storyboard.TargetProperty="BlurRadius" From="0" To="$BlurRadius" Duration="0:0:1" AutoReverse="False" />
                    </Storyboard>
                </BeginStoryboard>
            </EventTrigger>
        </Border.Triggers>
        <Grid >
            <Border Name="Mask" CornerRadius="$CornerRadius" Background="$($PSBoundParameters.ContentBackground)" />
            <Grid x:Name="Grid" Background="$($PSBoundParameters.ContentBackground)">
                <Grid.OpacityMask>
                    <VisualBrush Visual="{Binding ElementName=Mask}"/>
                </Grid.OpacityMask>
                <StackPanel Name="StackPanel" >                   
                    <TextBox Name="TitleBar" IsReadOnly="True" IsHitTestVisible="False" Text="$Title" Padding="10" FontFamily="$($PSBoundParameters.FontFamily)" FontSize="$TitleFontSize" Foreground="$($PSBoundParameters.TitleTextForeground)" FontWeight="$($PSBoundParameters.TitleFontWeight)" Background="$($PSBoundParameters.TitleBackground)" HorizontalAlignment="Stretch" VerticalAlignment="Center" Width="Auto" HorizontalContentAlignment="Center" BorderThickness="0"/>
                    <DockPanel Name="ContentHost" Margin="0,10,0,10"  >
                    </DockPanel>
                    <DockPanel Name="ButtonHost" LastChildFill="False" HorizontalAlignment="Center" >
                    </DockPanel>
                </StackPanel>
            </Grid>
        </Grid>
    </Border>
</Window>
"@

        [XML]$ButtonXaml = @"
<Button xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation" xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml" Width="Auto" Height="30" FontFamily="Segui" FontSize="16" Background="Transparent" Foreground="White" BorderThickness="1" Margin="10" Padding="20,0,20,0" HorizontalAlignment="Right" Cursor="Hand"/>
"@

        [XML]$ButtonTextXaml = @"
<TextBlock xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation" xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml" FontFamily="$($PSBoundParameters.FontFamily)" FontSize="16" Background="Transparent" Foreground="$($PSBoundParameters.ButtonTextForeground)" Padding="20,5,20,5" HorizontalAlignment="Center" VerticalAlignment="Center"/>
"@

        [XML]$ContentTextXaml = @"
<TextBlock xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation" xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml" Text="$Content" Foreground="$($PSBoundParameters.ContentTextForeground)" DockPanel.Dock="Right" HorizontalAlignment="Center" VerticalAlignment="Center" FontFamily="$($PSBoundParameters.FontFamily)" FontSize="$ContentFontSize" FontWeight="$($PSBoundParameters.ContentFontWeight)" TextWrapping="Wrap" Height="Auto" MaxWidth="500" MinWidth="50" Padding="10"/>
"@

        # Load the window from XAML
        $Window = [Windows.Markup.XamlReader]::Load((New-Object -TypeName System.Xml.XmlNodeReader -ArgumentList $xaml))

        # Custom function to add a button
        Function Add-Button {
            Param($Content)
            $Button = [Windows.Markup.XamlReader]::Load((New-Object -TypeName System.Xml.XmlNodeReader -ArgumentList $ButtonXaml))
            $ButtonText = [Windows.Markup.XamlReader]::Load((New-Object -TypeName System.Xml.XmlNodeReader -ArgumentList $ButtonTextXaml))
            $ButtonText.Text = "$Content"
            $Button.Content = $ButtonText
            $Button.Add_MouseEnter( {
                    $This.Content.FontSize = "17"
                })
            $Button.Add_MouseLeave( {
                    $This.Content.FontSize = "16"
                })
            $Button.Add_Click( {
                    New-Variable -Name WPFMessageBoxOutput -Value $($This.Content.Text) -Option ReadOnly -Scope Script -Force
                    $Window.Close()
                })
            $Window.FindName('ButtonHost').AddChild($Button)
        }

        # Add buttons
        If ($ButtonType -eq "OK") {
            Add-Button -Content "OK"
        }

        If ($ButtonType -eq "OK-Cancel") {
            Add-Button -Content "OK"
            Add-Button -Content "Cancel"
        }

        If ($ButtonType -eq "Abort-Retry-Ignore") {
            Add-Button -Content "Abort"
            Add-Button -Content "Retry"
            Add-Button -Content "Ignore"
        }

        If ($ButtonType -eq "Yes-No-Cancel") {
            Add-Button -Content "Yes"
            Add-Button -Content "No"
            Add-Button -Content "Cancel"
        }

        If ($ButtonType -eq "Yes-No") {
            Add-Button -Content "Yes"
            Add-Button -Content "No"
        }

        If ($ButtonType -eq "Retry-Cancel") {
            Add-Button -Content "Retry"
            Add-Button -Content "Cancel"
        }

        If ($ButtonType -eq "Cancel-TryAgain-Continue") {
            Add-Button -Content "Cancel"
            Add-Button -Content "TryAgain"
            Add-Button -Content "Continue"
        }

        If ($ButtonType -eq "None" -and $CustomButtons) {
            Foreach ($CustomButton in $CustomButtons) {
                Add-Button -Content "$CustomButton"
            }
        }

        # Remove the title bar if no title is provided
        If ($Title -eq "") {
            $TitleBar = $Window.FindName('TitleBar')
            $Window.FindName('StackPanel').Children.Remove($TitleBar)
        }

        # Add the Content
        If ($Content -is [String]) {
            # Replace double quotes with single to avoid quote issues in strings
            If ($Content -match '"') {
                $Content = $Content.Replace('"', "'")
            }
        
            # Use a text box for a string value...
            $ContentTextBox = [Windows.Markup.XamlReader]::Load((New-Object -TypeName System.Xml.XmlNodeReader -ArgumentList $ContentTextXaml))
            $Window.FindName('ContentHost').AddChild($ContentTextBox)
        }
        Else {
            # ...or add a WPF element as a child
            Try {
                $Window.FindName('ContentHost').AddChild($Content) 
            }
            Catch {
                $_
            }        
        }

        # Enable window to move when dragged
        $Window.FindName('Grid').Add_MouseLeftButtonDown( {
                $Window.DragMove()
            })

        # Activate the window on loading
        If ($OnLoaded) {
            $Window.Add_Loaded( {
                    $This.Activate()
                    Invoke-Command $OnLoaded
                })
        }
        Else {
            $Window.Add_Loaded( {
                    $This.Activate()
                })
        }
    

        # Stop the dispatcher timer if exists
        If ($OnClosed) {
            $Window.Add_Closed( {
                    If ($DispatcherTimer) {
                        $DispatcherTimer.Stop()
                    }
                    Invoke-Command $OnClosed
                })
        }
        Else {
            $Window.Add_Closed( {
                    If ($DispatcherTimer) {
                        $DispatcherTimer.Stop()
                    }
                })
        }
    

        # If a window host is provided assign it as the owner
        If ($WindowHost) {
            $Window.Owner = $WindowHost
            $Window.WindowStartupLocation = "CenterOwner"
        }

        # If a timeout value is provided, use a dispatcher timer to close the window when timeout is reached
        If ($Timeout) {
            $Stopwatch = New-object System.Diagnostics.Stopwatch
            $TimerCode = {
                If ($Stopwatch.Elapsed.TotalSeconds -ge $Timeout) {
                    $Stopwatch.Stop()
                    $Window.Close()
                }
            }
            $DispatcherTimer = New-Object -TypeName System.Windows.Threading.DispatcherTimer
            $DispatcherTimer.Interval = [TimeSpan]::FromSeconds(1)
            $DispatcherTimer.Add_Tick($TimerCode)
            $Stopwatch.Start()
            $DispatcherTimer.Start()
        }

        # Play a sound
        If ($($PSBoundParameters.Sound)) {
            $SoundFile = "$env:SystemDrive\Windows\Media\$($PSBoundParameters.Sound).wav"
            $SoundPlayer = New-Object System.Media.SoundPlayer -ArgumentList $SoundFile
            $SoundPlayer.Add_LoadCompleted( {
                    $This.Play()
                    $This.Dispose()
                })
            $SoundPlayer.LoadAsync()
        }

        # Display the window
        $null = $window.Dispatcher.InvokeAsync{$window.ShowDialog()}.Wait()

    }
}

$Error.clear()
#For the try catch
$ErrorActionPreference = "stop"
$AutoPushCloudFolder = "_AutoPushCloud"
$AppInstallLog = Join-Path $env:temp "AutoPushCloud.txt"

#Let's create the logfile
New-Item -Path $AppInstallLog -ItemType file -Force| Out-Null 
if ($?) {
    Add-Content -Path $AppInstallLog -Value "Log file created successfully" 
}
else {
    break
}

#Test if Windows 10 1709 or more. If no STOP
$OSWMInfo = Get-WmiObject -Class Win32_OperatingSystem | Select-Object version, ProductType
$Productype = $OSWMInfo.ProductType
[version]$Version = $OSWMInfo.Version
[int]$Major = $Version.Major
[int]$Build = $Version.Build
 
#Is it a Workstation? 
if ($Productype = 1) {
    #Windows 10 only
    if ($Major -ge 10) {
        #Windows 1709 or more
        if ($Build -ge 16299) {
            #Is onedrive configured in the current profile
            $RegistryInfo = Get-ItemProperty -Path 'HKCU:\Software\Microsoft\OneDrive\Accounts\Business1\' -ErrorAction SilentlyContinue | Select-Object UserEmail, UserFolder
            [string]$TestODConfigured = $RegistryInfo.UserEmail
            [string]$UserFolderPath = $RegistryInfo.UserFolder

            #Those two values are mandatory and ScheduleTask module too. If one of them is empty, we stop the script
            $AreWeCool = $false
            if ($TestODConfigured -ne "") {
                if ([string]$UserFolderPath -ne "") {
                    #we have to import PSScheduledJob too because of the Randomdelay fail from MSFT on ScheduledTasks 
                    import-module ScheduledTasks, PSScheduledJob
                    if ($?) {
                        Add-Content -Path $AppInstallLog -Value "Information: Modules imported successfully"
                        #Check if the schedule task already exist
                        $ST = Get-ScheduledTask | Where-Object {$_.taskname -eq "AutoPushCloudOnDemand"}
                        if ($ST -eq $null) {
                            $AreWeCool = $true
                        }
                        else {
                            Add-Content -Path $AppInstallLog -Value "The schedule task called AutoPushCloudOnDemand already exist, let's remove it"
                            Get-ScheduledTask | Where-Object {$_.taskname -eq "AutoPushCloudOnDemand"} | Unregister-ScheduledTask -Confirm:$false
                            if ($?) {
                                $AreWeCool = $true
                            }
                            else {
                                Add-Content -Path $AppInstallLog -Value "Unable to remove the Schedule task AutoPushCloudOnDemand"
                                break
                            } 
                        }
                    }
                    else {
                        Add-Content -Path $AppInstallLog -Value "Unable to import the ScheduledTasks or PSScheduledJob, it's a prerequisite"
                    }
                }
                else {
                    Add-Content -Path $AppInstallLog -Value "The User OneDrive folder is not defined properly in the local OneDrive. Check HKCU:\Software\Microsoft\OneDrive\Accounts\Business1\UserFolder first"
                }
            }
            else {
                Add-Content -Path $AppInstallLog -Value "The User email profile is not defined properly in the local OneDrive. Check HKCU:\Software\Microsoft\OneDrive\Accounts\Business1\UserEmail first"
            }

            if ($AreWeCool) {
                #Let's enabled the files on demand through registry after the reboot https://getadmx.com/?Category=OneDrive&Policy=Microsoft.Policies.OneDriveNGSC::FilesOnDemandEnabled
                #Is the key already exist?
                if (Test-Path -Path 'HKLM:\SOFTWARE\Policies\Microsoft\Onedrive') {
                    try {
                        New-ItemProperty -Path 'HKLM:\SOFTWARE\Policies\Microsoft\OneDrive' -Name 'FilesOnDemandEnabled' -Value 1 -PropertyType DWORD -Force | Out-Null
                    }
                    catch [System.Security.SecurityException] {
                        Add-Content -Path $AppInstallLog -Value "Not enough rights to create the key named FilesOnDemandEnabled with the value of 1 under HKLM:\SOFTWARE\Policies\Microsoft\OneDrive"
                    }
                    catch { 
                        Add-Content -Path $AppInstallLog -Value "Unexpected error: Unable to create the key named FilesOnDemandEnabled with the value of 1 under HKLM:\SOFTWARE\Policies\Microsoft\OneDrive"
                    }
                    
                    
                }
                else {
                    #Let's create the key first
                    try {
                        New-Item 'HKLM:\SOFTWARE\Policies\Microsoft\OneDrive' -Force  | Out-Null
                    }
                    catch [System.Security.SecurityException] {
                        Add-Content -Path $AppInstallLog -Value "Not enough rights to create the key OneDrive under HKLM:\SOFTWARE\Policies\Microsoft\"
                    }
                    catch {
                        Add-Content -Path $AppInstallLog -Value "Unexpected error: Unable to create the key OneDrive under HKLM:\SOFTWARE\Policies\Microsoft\"
                    }
                    
                    #And then the regkey
                    try {
                        New-ItemProperty -Path 'HKLM:\SOFTWARE\Policies\Microsoft\OneDrive' -Name 'FilesOnDemandEnabled' -Value 1 -PropertyType DWORD -Force | Out-Null
                    }
                    catch [System.Security.SecurityException] {
                        Add-Content -Path $AppInstallLog -Value "Not enough rights to create the key named FilesOnDemandEnabled with the value of 1 under HKLM:\SOFTWARE\Policies\Microsoft\OneDrive"
                    }
                    catch {
                        Add-Content -Path $AppInstallLog -Value "Unexpected error: Unable to create the key named FilesOnDemandEnabled with the value of 1 under HKLM:\SOFTWARE\Policies\Microsoft\OneDrive"
                    }
                }#Regkey creation step

                #Let's now create the local folder under user's OneDrive
                #Should give something like C:\Users\user02\OneDrive - Répertoire par défaut\_AutoPushCloud
                $FullPathAutoPushCloudFolder = Join-Path $UserFolderPath $AutoPushCloudFolder
                if (Test-Path $FullPathAutoPushCloudFolder) {
                    Add-Content -Path $AppInstallLog -Value "Folder $FullPathAutoPushCloudFolder is already created, no need to recreate it"
                }
                else {
                    #Let's create the folder
                    try {
                        New-Item -Path $UserFolderPath -Name  $AutoPushCloudFolder -ItemType Directory -Force | Out-Null
                    }
                    
                    catch {
                        Add-Content -Path $AppInstallLog -Value "Unexpected error: Unable to create local folder called $AutoPushCloudFolder under $UserFolderPath"
                    }
                }#LocalFolder creation step

                #Let's now create the Schedule Task  
                try {
                    $action = New-ScheduledTaskAction -Execute 'Powershell.exe' -Argument '-NoProfile -WindowStyle Hidden -command "& {Set-Location $(join-path (Get-ItemProperty -Path HKCU:\Software\Microsoft\OneDrive\Accounts\Business1\ | Select-Object -ExpandProperty UserFolder) "_AutoPushCloud"); attrib.exe -p +u /s}"' 
                    $trigger = New-JobTrigger -AtLogOn -RandomDelay (new-Timespan -Minutes 5)
                    $settings = New-ScheduledTaskSettingsSet -ExecutionTimeLimit (New-TimeSpan -Minutes 10)
                    Register-ScheduledTask -Action $action -Trigger $trigger -Settings $settings -TaskName "AutoPushCloudOnDemand" -Description "This schedule task will on boot apply file on demand on the folder _AutoPushCloud" | Out-Null
                    if ($?) {
                        Add-Content -Path $AppInstallLog -Value "Information: Schedule task created successfully"
                                                
                        #Now let's create a shortcut on the desktop
                        try {
                            $Name = "AutoPushCloud"
                            $OutputDirectory = "$Home\Desktop"
                            $Target = "C:\Windows\System32\schtasks.exe"
                            $WindowStyle = 1
                            $Arguments = "/run /tn `"AutoPushCloudOnDemand`""
                                                        
                            [System.IO.FileInfo] $LinkFileName = [System.IO.Path]::ChangeExtension($Name, "lnk")
                            [System.IO.FileInfo] $LinkFile = [IO.Path]::Combine($OutputDirectory, $LinkFileName)
                                                        
                            $wshshell = New-Object -ComObject WScript.Shell
                            $shortCut = $wshShell.CreateShortCut($LinkFile) 
                            $shortCut.TargetPath = $Target
                            $shortCut.WindowStyle = $WindowStyle
                            $shortCut.Arguments = $Arguments
                            #Remove comment if you want another icon than the default one
                            #$MyFileName = "cloud.ico"
                            #$filebase = Join-Path $PSScriptRoot $MyFileName
                            #$shortCut.IconLocation = $filebase
                            $shortCut.Save()
                                                        
                            $tempFileName = [IO.Path]::GetRandomFileName()
                            $tempFile = [IO.FileInfo][IO.Path]::Combine($LinkFile.Directory, $tempFileName)
                                                                
                            $writer = new-object System.IO.FileStream $tempFile, ([System.IO.FileMode]::Create)
                            $reader = $LinkFile.OpenRead()
                                                                
                            while ($reader.Position -lt $reader.Length) {        
                                $byte = $reader.ReadByte()
                                if ($reader.Position -eq 22) {
                                    $byte = 34
                                }
                                $writer.WriteByte($byte)
                            }
                                                                
                            $reader.Close()
                            $writer.Close()
                                                                
                            $LinkFile.Delete()
                                                                
                            Rename-Item -Path $tempFile -NewName $LinkFile.Name
                                                        
                        }
                        catch {
                            Add-Content -Path $AppInstallLog -Value "Unexpected error: Unable to create a shortcut on the machine"
                        }

                        $InfoParams = @{
                            Title               = "INFORMATION"
                            TitleFontSize       = 20
                            TitleBackground     = 'LightSkyBlue'
                            TitleTextForeground = 'Black'
                        }
                        New-WPFMessageBox @InfoParams -Content "The OneDrive Auto Push Cloud on Demand will be configured after a reboot." 

                        #At this moment, OD is configured and SCCM is aware that the application is installed
                        #Send SCCM a soft reboot code
                        #[System.Environment]::Exit(3010)
                    }
                }
                
                catch {
                    Add-Content -Path $AppInstallLog -Value "Unexpected error: Unable to create the schedule task on the machine"
                }              
                
            }
            else {
                Add-Content -Path $AppInstallLog -Value "Unexpected error: User profile or User folder not defined correctly in registry check HKCU:\Software\Microsoft\OneDrive\Accounts\Business1\"
            }
        }
        else {
            Add-Content -Path $AppInstallLog -Value "This feature is available only starting 1709(16299), you're currently running build: $Build"
        }
    }
    else {
        Add-Content -Path $AppInstallLog -Value "This feature is not available on Windows 7 or Windows 8.1"
    }
}
else {
    Add-Content -Path $AppInstallLog -Value "This feature is only available on Windows 10 not servers"
}
