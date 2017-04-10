

#commands in order of build
set-service -name MSiSCSI -StartupType Automatic
start-service -name MSiSCSI

Get-NetFirewallServiceFilter -Service msiscsi | get-netfirewallRule | select DisplayGroup,DisplayName,Enabled
# Add portal IP
New-IscsiTargetPortal -TargetPortalAddress $ntnx_cluster
# get targets and connect devices
get-iscsiTarget | connect-iscsitarget
# Set disks online
get-iscsisession | get-disk | set-disk -IsOffline $false
