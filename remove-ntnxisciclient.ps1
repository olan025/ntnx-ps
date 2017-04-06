$vmip = "Client_ip_address"

$body = "{""iscsi_client"":
{
       ""client_address"": ""$vmip""
   },
   ""operation"": ""DETACH""
   }"

$server = "Cluster_IP"
$username = "Cluster_user_name"
$password = "cluster_password"
$vguuid = "$volume_group_UUID"
$url = "https://${server}:9440/PrismGateway/services/rest/v2.0/volume_groups/${vguuid}/close"
$Header = @{"Authorization" = "Basic "+[System.Convert]::ToBase64String([System.Text.Encoding]::UTF8.GetBytes($username+":"+$password ))}
$out = Invoke-RestMethod -Uri $url -Headers $Header -Method Post -Body $body -ContentType application/json