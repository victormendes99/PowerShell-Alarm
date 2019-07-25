$ServiceName = 'AsyncDispatcherService'

 

while (1 -eq 1)
{
    $arrService = Get-Service -Name $ServiceName
    write-host $arrService.status
    Start-Sleep -seconds 5
    if ($arrService.Status -eq 'Running')
    {
        Write-Host 'Service is now Running'
    }else
    {
        Write-Host 'Service not is now Running'
    }

 

}