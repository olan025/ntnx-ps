
#Pre-requisites 
#VM with VG created
#iSCSI initiators setup in both prod and test
#Protection domain created with snapshot schedule

#Restore VG to new vg
#add TestVM to access to test vg

#Variables
$ntn_xcluster = "10.21.9.37"
$ntnx_user_name = "admin"
$ntnx_user_password = ""
$ntnx_prot_domain_name= "ProdSQL"
$ntnx_vg_name = "ProdSQL_VG1"
$ntnx_vg_uuid = ("")
$ntnx_vg_prefix = "test_"
$ntnx_snap_uuid = (grab from snapshot object)
$vm_production = "ProdSQL"
$vm_test = "TestSQL"

#commands in order of build
#set-service -name MSiSCSI -StartupType Automatic
#start-service -name MSiSCSI
#Get-NetFirewallServiceFilter -Service msiscsi | get-netfirewallRule | select DisplayGroup,DisplayName,Enabled
#New-IscsiTargetPortal -TargetPortalAddress $ntnx_cluster
#get-iscsitarget
#get-scsiTarget | connect-iscsitarget
#get-iscsisession | get-disk | set-disk -IsOffline $false


#get-ntnxprotectiondomain -name $ntnx_prot_domain_name | get-ntnxprotectiondomainsnapshots
#get-ntnxprotectiondomainsnapshots
#$vol_group = get-ntnxvolumegroups | where {$_.name -eq $ntnx_vg_name}
#$vg_uuid = $vol_group.uuid
 
connect-ntnxcluster -server $ntnx_cluster -username $ntnx_user_name -password $ntnx_user_password -AcceptInvalidSSLCerts
$ntnx_prot_domain = get-ntnxprotectiondomain | Where {$_.name -eq $ntnx_prot_domain_name}

# Command to create a new VG from production snapshot from protection domain
Restore-NTNXEntity -PDName $ntnx_prot_domain_name -volumegroupuuids $ntnx_vg_uuid -vgnameprefix $ntnx_vg_prefix -snapshotid $ntnx_snap_uuid