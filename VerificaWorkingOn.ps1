#requires -version 1.0

# -----------------------------------------------------------------------------
# Script: VerificaWorkingOn.ps1
# Version: 1.0
# Author: Victor Mendes
# Date: 26/07/2019
#
 
# -----------------------------------------------------------------------------

Function GetMessageBox{
	Param (
    [string]$Message,

    [ValidateSet("OkOnly","OkCancel","AbortRetryIgnore","YesNoCancel","YesNo","RetryCancel")]
    [string]$Button="OkOnly",

    [ValidateSet("Critical", "Question", "Exclamation", "Information")]
    [string]$Icon="Information",

    [string]$Title
    )

    Add-Type -AssemblyName "Microsoft.VisualBasic"
    $returnValue=[Microsoft.Visualbasic.Interaction]::Msgbox($message,"$button,$icon",$title)
}


if((get-process "TfsWorkingOn" -ea SilentlyContinue) -eq $Null){ 
		while(1 -eq 1){
        	GetMessageBox -Message "Seu Working-On ta funcionando demais?" -Title "Alerta!" -Icon "Question"
        	sleep -seconds 5
        }
}







