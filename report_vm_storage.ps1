# Set some variables
$vcsa_fqdn = "tmevcsa.sc0.nebulon.com"

# PowerCLI options
Set-PowerCLIConfiguration -InvalidCertificateAction Ignore -Confirm:$false | Out-Null
Set-PowerCLIConfiguration -DisplayDeprecationWarnings:$false -Confirm:$false | Out-Null
Set-PowerCLIConfiguration -DefaultVIServerMode Multiple -Confirm:$false | Out-Null

# logging helper
function Get-TimeStamp {
    return "[{0:MM/dd/yy} {0:HH:mm:ss}] " -f (Get-Date)
}

# Get PS credential object
$pscredential = get-credential -UserName "administrator@vsphere.local"

# Connect to vCenter
Write-Host "$(Get-TimeStamp) Connecting to vCenter $vcsa_fqdn..." -NoNewline
Connect-VIServer -Server $vcsa_fqdn -Credential $pscredential
Write-Host "Done" -ForegroundColor Green

ForEach ($Datacenter in (Get-Datacenter | Sort-Object -Property Name)) {
    ForEach ($Cluster in ($Datacenter | Get-Cluster | Sort-Object -Property Name)) {
      ForEach ($VM in ($Cluster | Get-VM | Sort-Object -Property Name)) {
        ForEach ($HardDisk in ($VM | Get-HardDisk | Sort-Object -Property Name)) {
          "" | Select-Object -Property @{N="VM";E={$VM.Name}},
            @{N="Datacenter";E={$Datacenter.name}},
            @{N="Cluster";E={$Cluster.Name}},
            @{N="Hard Disk";E={$HardDisk.Name}},
            @{N="Datastore";E={$HardDisk.FileName.Split("]")[0].TrimStart("[")}},
            @{N="VMDKpath";E={$HardDisk.FileName}}
        }
      }
    }
  }