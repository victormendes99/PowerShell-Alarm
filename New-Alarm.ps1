#requires -version 2.0

<#
 -----------------------------------------------------------------------------
 Script: New-Alarm.ps1
 Version: 0.9
 Author: Jeffery Hicks
    http://jdhitsolutions.com/blog
    http://twitter.com/JeffHicks
    http://www.ScriptingGeek.com
 Date: 1/17/2012
 Keywords:
 Comments:

 "Those who forget to script are doomed to repeat their work."

  ****************************************************************
  * DO NOT USE IN A PRODUCTION ENVIRONMENT UNTIL YOU HAVE TESTED *
  * THOROUGHLY IN A LAB ENVIRONMENT. USE AT YOUR OWN RISK.  IF   *
  * YOU DO NOT UNDERSTAND WHAT THIS SCRIPT DOES OR HOW IT WORKS, *
  * DO NOT USE IT OUTSIDE OF A SECURE, TEST SETTING.             *
  ****************************************************************
 -----------------------------------------------------------------------------
 #>
 

Function New-Alarm {

<#
.SYNOPSIS
Create an time event.
.DESCRIPTION
This function will create a background job to execute a command at a given 
time. You must keep your PowerShell session open in order for the timed 
event to be processed. If you close your session, all your jobs will be 
removed and no alarm will ever happen.

The result for each job is an alarm summary.

PS C:\> receive-job 7 -keep

Initialization : . c:\scripts\get-messagebox.ps1
ActualTime     : 1/20/2012 8:47:07 AM
ScheduledTime  : 1/20/2012 8:47:06 AM
Command        : get-messagebox 'It is time for that thing' -title 'Alert!'
RunspaceId     : d3461b78-11ce-4c84-a8ab-9e3fcd482637

.PARAMETER Command
The command or PowerShell expression to execute at the given time. The 
default is Notepad.
.PARAMETER Alarm
The time to invoke the command, The default is 5 minutes from now. The
parameter has an alias of 'Time'.
.PARAMETER Seconds
Create an alarm for X number of seconds from now.
.PARAMETER Minutes
Create an alarm for X number of minutes from now.
.PARAMETER Hours
Create an alarm for X number of hours from now.
.PARAMETER InitializationScript
Any commands you want to run before your command executes such as importing modules or dot sourcing scripts.
.EXAMPLE
PS C:\> New-Alarm Calc
Start Calculator in 5 minutes
.EXAMPLE
PS C:\> new-alarm "get-process | out-file c:\work\noonprocs.txt" -alarm "12:00PM"
At 12:00PM run Get-Process and direct output to a text file.
.EXAMPLE
PS C:\> $s='$f=[system.io.path]::GetTempFilename(); "Hey! Are you paying attention??" > $f;start-process notepad $f -wait;del $f'
PS C:\> new-alarm $s -minutes 15 -verbose

The first command defines a command string, $s. This creates a 
temporary file, writes some text to it, displays it with Notepad and then 
deletes it. The second command creates a new alarm that will invoke 
the expression in 15 minutes.
.EXAMPLE
PS C:\> New-Alarm "get-messagebox 'It is time to do that thing' -title 'Wake Up!'" -alarm $((Get-Date).AddHours(1)) -initialization {. c:\scripts\show-msgbox.ps1}
Run the Get-MessageBox function in 60 minutes. This function must be 
loaded first by dot sourcing a script.
.EXAMPLE
PS C:\> New-Alarm "&'C:\Program Files\Microsoft Office\Office14\winword.exe'" -hours 6
Create an alarm to open Microsoft Word in 6 hours.
.EXAMPLE
PS C:\> Import-CSV c:\work\myalarms.csv | new-alarm
Import a CSV of alarm information and create alarm jobs. Use "" for empty initialization scripts.
.NOTES
NAME        :  New-Alarm
VERSION     :  0.9.8   
LAST UPDATED:  1/20/2012
AUTHOR      :  Jeffery Hicks
.LINK
http://jdhitsolutions.com/blog
.LINK
Start-Job
Receive-Job
Get-Date
.INPUTS
Strings
.OUTPUTS
Custom object
#>

[cmdletbinding(SupportsShouldProcess=$True,DefaultParameterSetName="Time")]

Param (
[Parameter(Position=0,ValueFromPipelineByPropertyName=$True)]
[ValidateNotNullorEmpty()]
[string]$Command="Notepad",
[Parameter(Position=1,ValueFromPipelineByPropertyName=$True,ParameterSetName="Time")]
[ValidateNotNullorEmpty()]
[Alias("time")]
[datetime]$Alarm=(Get-Date).AddMinutes(5),
[Parameter(ValueFromPipelineByPropertyName=$True,ParameterSetName="Seconds")]
[int]$Seconds,
[Parameter(ValueFromPipelineByPropertyName=$True,ParameterSetName="Minutes")]
[int]$Minutes,
[Parameter(ValueFromPipelineByPropertyName=$True,ParameterSetName="Hours")]
[int]$Hours,
[Parameter(ValueFromPipelineByPropertyName=$True)]
[Alias("init","is")]
[string]$InitializationScript
)

Process {

if ($seconds) {$Alarm=(Get-Date).AddSeconds($seconds)}
if ($minutes) {$Alarm=(Get-Date).AddMinutes($minutes)}
if ($Hours) {$Alarm=(Get-Date).AddHours($hours)}

Write-Verbose ("{0} Creating an alarm for {1} to execute {2}" -f (Get-Date),$Alarm,$Command)

#define a scriptblock that takes parameters. Parameters are validated in the
#function so we don't need to do it here.
$sbText=@"
    Param ([string]`$Command,[datetime]`$Alarm,[string]`$Init)
    
    #define a boolean flag
    `$Done=`$False
    
    #loop until the time is greater or equal to the alarm time
    #sleeping every 10 seconds
    do  {
        if ((get-date) -ge `$Alarm) {
          #run the command
          `$ActualTime=Get-Date
          Invoke-Expression `$Command
          #set the flag to True
          `$Done=`$True
          }
        else {
         sleep -Seconds 10
    }
    } while (-Not `$Done)
    
    #write an alarm summary object which can be retrieved with Receive-Job
    New-Object -TypeName PSObject -Property @{
      ScheduledTime=`$Alarm
      ActualTime=`$ActualTime
      Command=`$Command
      Initialization=`$Init
    }
"@

#append metadata to the scriptblock text so they can be parsed out with Get-Alarm
#to discover information for currently running alarm jobs

$meta=@"

#Alarm Command::$Command
#Alarm Time::$Alarm
#Alarm Init::$InitializationScript
#Alarm Created::$(Get-Date)

"@

#add meta data to scriptblock text
$sbText+=$meta

Write-Debug "Scriptblock text:"
Write-Debug $sbText
Write-Debug "Creating the scriptblock"

#create a scriptblock to use with Start-Job
$sb=$ExecutionContext.InvokeCommand.NewScriptBlock($sbText)

Try {
    If ($InitializationScript) {
        #turn $initializationscript into a script block
        $initsb=$ExecutionContext.InvokeCommand.NewScriptBlock($initializationscript)
        Write-Verbose ("{0} Using an initialization script: {1}" -f (Get-Date),$InitializationScript)
    }
    else {
        #no initialization command so create an empty scriptblock
        $initsb={}
    }
    
    #WhatIf
    if ($pscmdlet.ShouldProcess("$command at $Alarm")) {
        #create a background job
        Start-job -ScriptBlock $sb -ArgumentList @($Command,$Alarm,$InitializationScript) -ErrorAction "Stop" -InitializationScript $Initsb
        Write-Verbose ("{0} Alarm Created" -f (Get-Date))
    }
}

Catch {
    $msg="{0} Exception creating the alarm job. {1}" -f (Get-Date),$_.Exception.Message
    Write-Warning $msg
}
} #Process

} #end function