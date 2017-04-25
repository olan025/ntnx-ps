##########################################################
# vg-clonetotest.ps1
# Created By: Ryan Grendahl
# 4/5/2017
# Description: Designed to be used by Nutanix customers with ESXi using volume group cloning
# to quickly populate a test /dev SQL instance with cloned version of a production database
# 
##########################################################
#Environmentals - Set these for your environment
    $ntnx_cluster_ip = "172.16.10.96"
    $ntnx_cluster_data_ip = "172.16.10.97"
    $ntnx_user_name = "admin"
    $ntnx_user_password_clear = read-host -prompt "password"
    $ntnx_user_password = $ntnx_user_password_clear | ConvertTo-SecureString -AsPlainText -Force
    $ntnx_pd_name= "sql"
    $ntnx_vg_name = "vg_prodsql"
    $ntnx_vg_prefix = "test_"
    $vm_test = "TestSQL"
    $pd_clone_wait_seconds = 5

# Clear error variable
$error.clear()

Function Write-CustomOut ($Details)
	{
		$LogDate = Get-Date -Format T
		Write-Host "$($LogDate) $Details"
	}

# connection / plugin checks
Write-CustomOut "SCRIPT: Checking for NUTANIX powershell plugin" 
$ntnx_pssnapin_check = Get-PSSnapin | Where {$_.name -eq "NutanixCmdletsPssnapin"}
if(! $ntnx_pssnapin_check)
    {
        Write-CustomOut "SCRIPT: Adding Nutanix Powershell Plugin"    
        Add-PSSnapin NutanixCmdletsPssnapin
    }

# Disconnect any previous sessions
Write-CustomOut "SCRIPT: Checking for existing ntnx cluster connections to disconnect" 
if(! (get-ntnxcluster))
    {
        Write-CustomOut "iSCSI: Disconnecting existing ntnx cluster sessions" 
        Disconnect-NTNXCluster -Servers *
    }

# Connect to NTNX Cluster
Write-CustomOut "SCRIPT: Connecting NTNX cluster" 
connect-ntnxcluster -server $ntnx_cluster_ip -username $ntnx_user_name -password $ntnx_user_password -AcceptInvalidSSLCerts -forcedconnection
if($error)
    {
        Write-CustomOut "SCRIPT: An error occured connecting to $ntnx_cluster_ip, exiting";exit 
    }

# Grab Protection Domain
$ntnx_pd = get-ntnxprotectiondomain | Where {$_.name -ceq $ntnx_pd_name}
if(! $ntnx_pd)
    {
        Write-CustomOut "NTNX: Protection Domain $ntnx_pd_name NOT FOUND!";exit 
    }
Else
    {
        Write-CustomOut "NTNX: Protection Domain $ntnx_pd_name found" 
    }

# Grab Protection Domain Snapshot
$ntnx_pd_snaps = Get-NTNXProtectionDomainSnapshot -PdName $ntnx_pd.name
if(! $ntnx_pd_snaps)
    {
        Write-CustomOut "NTNX: Protection Domain $ntnx_pd_name snapshots NOT FOUND!";exit 
    }
Else
    {
        Write-CustomOut "NTNX: Protection Domain $ntnx_pd_name snapshot identified" 
    }

# Grab the UUID of the latest or only snapshot
if($ntnx_pd_snaps -is [system.array])
    {
        $pd_snap_recent_id = $ntnx_pd_snaps[0].snapshotid
    }
Else 
    {
        $pd_snap_recent_id = $ntnx_pd_snaps.snapshotid
    }

# Grab Volume Group Details UUID
$ntnx_vg = (Get-NTNXVolumeGroups | where {$_.name -ceq $ntnx_vg_name})
if($ntnx_vg -is [system.array])
    {
        Write-CustomOut "NTNX: Multiple Volume Groups with name $ntnx_vg_name found";exit 
    }
Else
    {
        Write-CustomOut "NTNX: Identified Volume Group $ntnx_vg_name to restore"
        $ntnx_vg_uuid = $ntnx_vg.uuid
    }

#Check if any existing VG available with with Prefix
    $ntnx_vg_current_check = get-ntnxvolumegroups | where {$_.name -match $ntnx_vg_prefix}
    if($ntnx_vg_current_check)
        {
            Write-CustomOut "ERROR: Existing volume group called $ntnx_vg_prefix found. Script not designed to run multiple yet";exit
        }

# Restore the protection domain to a new VG
    Restore-NTNXEntity -PdName $ntnx_pd_name -VolumeGroupUuids $ntnx_vg_uuid -VgNamePrefix $ntnx_vg_prefix -SnapshotId $pd_snap_recent_id

#give nutanix 5 seconds to clone your database
    Write-CustomOut "NTNX: Waiting $pd_clone_wait_seconds for clone to complete. (adjust this wait in parameters of script)" 
    start-sleep $pd_clone_wait_seconds

# Attach ISCSI Client to VG
# Grab the ip for the the localhost using Ethernet0 and IPv4 filters
    $vmip = (get-netipaddress | where {$_.InterfaceAlias -eq "Ethernet" -and $_.AddressFamily -eq "IPv4"}).IPAddress
    if(! $vmip)
        {
            Write-CustomOut "WINDOWS: No IP found for Ethernet0 using IPv4. I cannot set the client IP for the new VG without this";exit
        }
    Write-CustomOut "WINDOWS: Using $vmip as client initaitor IP" 

#Get Cloned VG details
    $ntnx_clonedvg_uuid = (Get-NTNXVolumeGroups | where {$_.name -ceq "$ntnx_vg_prefix" + "$ntnx_vg_name"}).uuid
    if(! $ntnx_clonedvg_uuid)
        {
            Write-CustomOut "NTNX: Cloned VG not found!";exit   
        }

#Add client to Cloned VG
    $error.clear()
    Write-CustomOut "NTNX: Adding $vmip to $ntnx_vg_name" 
    $body = "{""iscsi_client"":
    {
           ""client_address"": ""$vmip""
       },
       ""operation"": ""ATTACH""
       }"
    $url = "https://${ntnx_cluster_ip}:9440/PrismGateway/services/rest/v2.0/volume_groups/${ntnx_clonedvg_uuid}/open"
    $Header = @{"Authorization" = "Basic "+[System.Convert]::ToBase64String([System.Text.Encoding]::UTF8.GetBytes($ntnx_user_name+":"+$ntnx_user_password_clear ))}
    $out = Invoke-RestMethod -Uri $url -Headers $Header -Method Post -Body $body -ContentType application/json
    if($error)
        {
            Write-CustomOut "NTNX: Failed adding $vmip to $ntnx_vg_name on $ntnx_cluster_ip. You may have to increase the Wait variable.";exit
        }
    Else
        {
            Write-CustomOut "NTNX: Successfully added $vmip to $ntnx_vg_name on $ntnx_cluster_ip."
        }

    Write-CustomOut "NTNX: Disconnecting from all NTNX clusters" 
    Disconnect-NTNXCluster -Servers *

# commands in order of build
Write-CustomOut "iSCSI: Checking iSCSI initiator service status" 
if((get-service -Name MSiSCSI).Status -ne "Running")
    {
        Write-CustomOut "iSCSI: Setting ISCSI service to start automatically and starting service" 
        set-service -name MSiSCSI -StartupType Automatic
        start-service -name MSiSCS
    }


# Get-NetFirewallServiceFilter -Service msiscsi | get-netfirewallRule | select DisplayGroup,DisplayName,Enabled
# Add portal IP
if(! (get-iscsitargetportal -TargetPortalAddress $ntnx_cluster_data_ip))
    {
        Write-CustomOut "iSCSI: Registering new iSCSI target" 
        New-IscsiTargetPortal -TargetPortalAddress $ntnx_cluster_data_ip
    }
Else
    {
        Write-CustomOut "iSCSI: Existing iSCSI target referenced, refreshing target" 
        Update-IscsiTarget
    }


# get targets and connect devices
Write-CustomOut "iSCSI: Checking iSCSI Targets"
$iscsi_targets = get-iscsitarget
if($iscsi_targets | where {$_.IsConnected -eq $false})
    {
        Write-CustomOut "iSCSI: Connecting Targets"
        $iscsi_targets | connect-iscsitarget
    }

# Set disks online
Write-CustomOut "iSCSI: Checking for Offline or Readonly" 
$iscsi_session_disks = get-iscsisession | get-disk
if($iscsi_session_disks | where {$_.OperationalStatus -eq "Offline"})
    {
        Write-CustomOut "iSCSI: Offline devices being set online" 
        $iscsi_session_disks | get-disk | set-disk -IsOffline $false 
    }
if($iscsi_session_disks | where {$_.IsReadOnly -eq $true})
    {
        Write-CustomOut "iSCSI: Readonly devices being changed" 
        $iscsi_session_disks | get-disk | set-disk -IsReadonly $false
    }