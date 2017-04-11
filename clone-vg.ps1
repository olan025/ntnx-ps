##########################################################
# vg-clonetotest.ps1
# Created By: Ryan Grendahl
# 4/5/2017
# Description: Designed to be used by Nutanix customers with ESXi using volume group cloning
# to quickly populate a test /dev SQL instance with cloned version of a production database
# 
##########################################################
#Environmentals - Set these for your environment
$ntnx_cluster_ip = "10.21.9.37"
$ntnx_cluster_data_ip = "10.21.9.38"
$ntnx_user_name = "admin"
$ntnx_user_password_clear = "xTreme7452!"
$ntnx_user_password = $ntnx_user_password_clear | ConvertTo-SecureString -AsPlainText -Force
$ntnx_pd_name= "ProdSQL"
$ntnx_vg_name = "ProdSQL_VG1"
$ntnx_vg_prefix = "test_"
$vm_test = "TestSQL"

# connection / plugin checks
$ntnx_pssnapin_check = Get-PSSnapin | Where {$_.name -eq "NutanixCmdletsPssnapin"}
if(! $ntnx_pssnapin_check)
    {Add-PSSnapin NutanixCmdletsPssnapin}
Disconnect-NTNXCluster -Servers *
connect-ntnxcluster -server $ntnx_cluster_ip -username $ntnx_user_name -password $ntnx_user_password -AcceptInvalidSSLCerts


# Grab PD Details
$ntnx_pd = get-ntnxprotectiondomain | Where {$_.name -ceq $ntnx_pd_name} # Changed the condition to check the VG to match the exact name "Case sensitive". Nutanix allows to create multiple entity with same name
$ntnx_pd_snaps = Get-NTNXProtectionDomainSnapshot -PdName $ntnx_pd.name

#Grab VG Details
$ntnx_vg = (Get-NTNXVolumeGroups | where {$_.name -ceq $ntnx_vg_name})
$ntnx_vg_uuid = $ntnx_vg.uuid

#Check if any existing VG available with with Prefix
$ntnx_vg_current_check = get-ntnxvolumegroups | where {$_.name -match $ntnx_vg_prefix}
if($ntnx_vg_current_check){echo "Existing one found"}
$pd_snap_recent_id = $ntnx_pd_snaps[0].snapshotid

# Restore the protection domain to a new VG
Restore-NTNXEntity -PdName $ntnx_pd_name -VolumeGroupUuids $ntnx_vg_uuid -VgNamePrefix $ntnx_vg_prefix -SnapshotId $pd_snap_recent_id

# Attach ISCSI Client to VG
# Grab the ip for the the localhost using Ethernet0 and IPv4 filters
$vmip = (get-netipaddress | where {$_.InterfaceAlias -eq "Ethernet0" -and $_.AddressFamily -eq "IPv4"}).IPAddress
#Get Cloned VG details
$ntnx_clonedvg_uuid = (Get-NTNXVolumeGroups | where {$_.name -ceq "$ntnx_vg_prefix" + "$ntnx_vg_name"}).uuid
#Add client to Cloned VG
$body = "{""iscsi_client"":
{
       ""client_address"": ""$vmip""
   },
   ""operation"": ""ATTACH""
   }"
$url = "https://${ntnx_cluster_ip}:9440/PrismGateway/services/rest/v2.0/volume_groups/${ntnx_clonedvg_uuid}/open"
$Header = @{"Authorization" = "Basic "+[System.Convert]::ToBase64String([System.Text.Encoding]::UTF8.GetBytes($ntnx_user_name+":"+$ntnx_user_password_clear ))}
$out = Invoke-RestMethod -Uri $url -Headers $Header -Method Post -Body $body -ContentType application/json

Disconnect-NTNXCluster -Servers *

#commands in order of build
set-service -name MSiSCSI -StartupType Automatic
start-service -name MSiSCSI

Get-NetFirewallServiceFilter -Service msiscsi | get-netfirewallRule | select DisplayGroup,DisplayName,Enabled
# Add portal IP
New-IscsiTargetPortal -TargetPortalAddress $ntnx_cluster_data_ip
# get targets and connect devices
get-iscsiTarget | connect-iscsitarget
# Set disks online
get-iscsisession | get-disk | set-disk -IsOffline $false 
get-iscsisession | get-disk | set-disk -IsReadonly $false