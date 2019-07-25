#requires -version 2.0

# -----------------------------------------------------------------------------
# Script: Get-MessageBox.ps1
# Version: 1.0
# Author: Jeffery Hicks
#    http://jdhitsolutions.com/blog
#    http://twitter.com/JeffHicks
# Date: 3/3/2011
# Keywords:
# Comments:
#
# "Those who neglect to script are doomed to repeat their work."
#
#  ****************************************************************
#  * DO NOT USE IN A PRODUCTION ENVIRONMENT UNTIL YOU HAVE TESTED *
#  * THOROUGHLY IN A LAB ENVIRONMENT. USE AT YOUR OWN RISK.  IF   *
#  * YOU DO NOT UNDERSTAND WHAT THIS SCRIPT DOES OR HOW IT WORKS, *
#  * DO NOT USE IT OUTSIDE OF A SECURE, TEST SETTING.             *
#  ****************************************************************
# -----------------------------------------------------------------------------

Function Get-MessageBox {

<#
   .Synopsis
    Display a graphical message box.
    .Description
    This command will display a customizable graphical message box which you can use to 
    display messages or interact with the user of your script or function. The default
    settings are simply to display a message box with an informational message and an OK
    button. The message box will not write anything to the pipeline, unless you use the
    -Passthru parameter. This will allow the button click values to be written to the 
    pipeline.  See examples.
    
    The message box will NOT timeout. It requires the user to click a button in order to
    continue.
    .Parameter Message
    The text you wish to display. This must a string and must be less than 1024 characters.
    .Parameter Button
    The button set to display. The default is OKOnly. Possible values are:
    "OkOnly","OkCancel","AbortRetryIgnore","YesNoCancel","YesNo","RetryCancel"
    .Parameter Icon
    The icon to display in the message box. The default is Information. Other values are:
    "Critical", "Question", "Exclamation", "Information"
    .Parameter Title
    The text to display in the message box title bar. This is optional.
   .Example
    PS C:\> get-messagebox -Message (get-service wuauserv | out-string) -title "Windows Update"

    This will display a message box showing the status of the Windows Update service
    .Example
    PS C:\> $m="Hello $env:username `n It is now $(Get-Date)"
    PS C:\> Get-MessageBox -Message $m -Title "Greeting"

    The `n character will create a two line message box.
    .Example
    PS C:\> $rc=Get-Messagebox -message "Do you know what you're doing?" -icon "exclamation" -button "YesNoCancel" -title "Hey $env:username!!" -passthru
You can use code like this to "handle" the interaction.
Switch ($rc) {
 "Yes" {"I hope your resume is up to date."}
 "No" {"Wise move."}
 "cancel" {"When in doubt, punt."}
 Default {"nothing returned"}
}     
   .Notes
    NAME: Get-MessageBox
    AUTHOR: Jeffery Hicks
    VERSION: 1.0
    LASTEDIT: 03/03/201
    
    Learn more with a copy of Windows PowerShell 2.0: TFM (SAPIEN Press 2010)
    
   .Link
    http://jdhitsolutions.com/blog/2011/03/friday-fun-get-messagebox/
       
    .Inputs
    None
    
    .Outputs
    String if -Passthru is used.
#>

    Param (
    [Parameter(Position=0,Mandatory=$True,HelpMessage="Specify a display message")]
    [ValidateNotNullorEmpty()]
    [ValidateScript({$_.Length -le 1024})]
    [string]$Message,

    [ValidateSet("OkOnly","OkCancel","AbortRetryIgnore","YesNoCancel","YesNo","RetryCancel")]
    [string]$Button="OkOnly",

    [ValidateSet("Critical", "Question", "Exclamation", "Information")]
    [string]$Icon="Information",

    [string]$Title,
    [switch]$Passthru
    )
    
    #load the required .NET assembly
    Add-Type -AssemblyName "Microsoft.VisualBasic"     
    #Invoke the message box and save the value from any button clicks to a variable
    $returnValue=[Microsoft.Visualbasic.Interaction]::Msgbox($message,"$button,$icon",$title)

    #write return value if -Passthru is called
    if ($passthru)
    {
        Write-Output $returnValue
    }

} #end function

#define an optional alias
Set-Alias -name gmb -value Get-MessageBox