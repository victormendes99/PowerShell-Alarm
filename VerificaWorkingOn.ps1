
if((get-process "TfsWorkingOn" -ea SilentlyContinue) -eq $Null){ 
        echo "Not Running"
        Get-MessageBox "Seu Working-On está ligado!" -title "Alert!"
        Start-Sleep -seconds 10
}

else{ 
    echo "Running"
    Get-MessageBox "Seu Working-On está ligado!" -title "Alert!"
    Start-Sleep -seconds 10
 }