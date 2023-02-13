# Set some variables
$vcsa_fqdn = "tmevcsa.sc0.nebulon.com"
$vcenter_user = "Administrator@vsphere.local"
$vcenter_pass = "Nebulon123!"
$vcenter_cluster = "HPE-Diskless"
$server_config_file = "./config/hpe_config_3node.json"
$network_config_file = "./config/network.json"
$vswitch_to_configure = "vSwitch0"

# PowerCLI options
Set-PowerCLIConfiguration -InvalidCertificateAction Ignore -Confirm:$false | Out-Null
Set-PowerCLIConfiguration -DisplayDeprecationWarnings:$false -Confirm:$false | Out-Null
Set-PowerCLIConfiguration -DefaultVIServerMode Multiple -Confirm:$false | Out-Null

# logging helper
function Get-TimeStamp {
    return "[{0:MM/dd/yy} {0:HH:mm:ss}] " -f (Get-Date)
}

Write-Host "$(Get-TimeStamp)Reading server configuration file..." -NoNewline
$server_config = (Get-Content -Path $server_config_file | ConvertFrom-Json -AsHashtable)
Write-Host "Done" -ForegroundColor Green

Write-Host "$(Get-TimeStamp)Reading network configuration file..." -NoNewline
$network_config = (Get-Content -Path $network_config_file | ConvertFrom-Json -AsHashtable)
Write-Host "Done" -ForegroundColor Green

# Connect to the system
Write-Host "$(Get-TimeStamp) Connecting to vCenter $vcsa_fqdn"
Connect-VIServer $vcsa_fqdn -Username $vcenter_user -Password $vcenter_pass

# Get a list of ESXi hosts to work with
Write-Host "$(Get-TimeStamp) Getting list of ESXi servers in cluster $vcenter_cluster"
$VMhosts = Get-Cluster -Name $vcenter_cluster | Get-VMHost | Sort-Object

# Loop through the ESXi hosts and create the required port groups on a standard switch
foreach ($VMhost in $VMhosts){
    Write-Host "$(Get-TimeStamp)Creating portgroups on host $($VMhost.Name)"

    # Manangement portgroup for vmk0
    Write-Host "$(Get-TimeStamp)Creating management portgroup on host $($VMhost.Name)..." -NoNewline
    $VMhost | Get-VirtualSwitch -name $vswitch_to_configure | `
    New-VirtualPortGroup -name $network_config.management_pg.name `
    -VLanId $network_config.management_pg.vlan
    Write-Host "Done" -ForegroundColor Green

    # vMotion portgroup for vmk1
    Write-Host "$(Get-TimeStamp)Creating vmotion portgroup on host $($VMhost.Name)..." -NoNewline
    $VMhost | Get-VirtualSwitch -name $vswitch_to_configure | `
    New-VirtualPortGroup -name $network_config.vmotion_pg.name `
    -VLanId $network_config.vmotion_pg.vlan
    Write-Host "Done" -ForegroundColor Green
}



