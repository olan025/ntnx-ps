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
$ntnx_vg_prefix = "test_"
$vm_test = "TestSQL"

# Set disks offline
get-iscsisession | get-disk | set-disk -IsOffline $true

# Disconnect targets
get-iscsiTarget | disconnect-iscsitarget -Confirm:$false

# Remove portal IP
remove-IscsiTargetPortal -TargetPortalAddress $ntnx_cluster_data_ip -Confirm:$false


# connection / plugin checks
$ntnx_pssnapin_check = Get-PSSnapin | Where {$_.name -eq "NutanixCmdletsPssnapin"}
if(! $ntnx_pssnapin_check)
    {Add-PSSnapin NutanixCmdletsPssnapin}
Disconnect-NTNXCluster -Servers *
connect-ntnxcluster -server $ntnx_cluster_ip -username $ntnx_user_name -password $ntnx_user_password -AcceptInvalidSSLCerts

# Attach ISCSI Client to VG
# Grab the ip for the the localhost using Ethernet0 and IPv4 filters
$vmip = (get-netipaddress | where {$_.InterfaceAlias -eq "Ethernet" -and $_.AddressFamily -eq "IPv4"}).IPAddress
#Get Cloned VG details
$ntnx_clonedvg_uuid = (Get-NTNXVolumeGroups | where {$_.name -ceq "$ntnx_vg_prefix" + "$ntnx_vg_name"}).uuid
#Add client to Cloned VG
$body = "{""iscsi_client"":
{
       ""client_address"": ""$vmip""
   },
   ""operation"": ""ATTACH""
   }"
$url = "https://${ntnx_cluster_ip}:9440/PrismGateway/services/rest/v2.0/volume_groups/${ntnx_clonedvg_uuid}/close"
$Header = @{"Authorization" = "Basic "+[System.Convert]::ToBase64String([System.Text.Encoding]::UTF8.GetBytes($ntnx_user_name+":"+$ntnx_user_password_clear ))}
$out = Invoke-RestMethod -Uri $url -Headers $Header -Method Post -Body $body -ContentType application/json


#Check if any existing VG available with with Prefix
$ntnx_test_vg = get-ntnxvolumegroups | where {$_.name -match $ntnx_vg_prefix}
Delete-NTNXVolumeGroup -Uuid ($ntnx_test_vg.uuid)


Disconnect-NTNXCluster -Servers *
