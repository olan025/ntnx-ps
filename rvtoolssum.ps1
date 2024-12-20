$master_report = @()
#modifythis line for the vCenter instance name
$vcenter = "<vCenterName>"
$vCenter_vinfo_file =  (ls *vInfo* ).Name
$vcenter_hwInfo_file = (ls *tabvHost*).Name
$vCenter_vInfo_data = ipcsv $vCenter_vInfo_File
$vcenter_hwInfo_data = ipcsv $vcenter_hwInfo_file

$clusters = $vCenter_vinfo_data | select Cluster -Unique

Foreach($cluster in $clusters)
{
    $cluster_vms = $vCenter_vInfo_data | where {$_.Cluster -eq $cluster.cluster}
    $vcpus = ($cluster_vms | Measure-Object -Property "CPUs" -Sum).Sum
    $vProvMB = (($cluster_vms | Measure-Object -Property "Provisioned MiB" -Sum).Sum/1000)
    $vInUseMB = (($cluster_vms | Measure-Object -Property "In Use MiB" -Sum).Sum/1000)
    $vMemory = (($cluster_vms | Measure-Object -Property "Memory" -Sum).Sum/1000)
    echo $cluster.Cluster
    echo $cluster_vms.count
    echo "vCPUS $vCpus"
    echo "vRAM $vMemory"
    echo "vInUseGB $vInUseMB"
    echo "vProvGB $vProvMB"


    $cluster_hw = $vcenter_hwInfo_data | where {$_.cluster -eq $cluster.cluster}
    $cluster_cores = ($cluster_hw | Measure-Object -Property "# Cores" -Sum).sum
    echo "Cluster cores $cluster_cores"
    echo "Hosts:" $cluster_hw.count
                

    $row = "" | Select vCenter, Cluster, vCPUs, vRAM, vPROVGB, vInUseGB, HWCores, Hosts
        $row.vCenter = $vCenter
        $row.Cluster = $cluster.cluster
        $row.vCPUs = $vcpus
        $row.vRAM = $vMemory
        $row.vProvGB = $vProvMB
        $row.vInUseGB = $vInUseMB
        $row.HWCores = $cluster_cores
        $row.Hosts = $cluster_hw.count

    $master_report += $row
}



$master_report | epcsv .\export-$vcenter.csv -NoTypeInformation
