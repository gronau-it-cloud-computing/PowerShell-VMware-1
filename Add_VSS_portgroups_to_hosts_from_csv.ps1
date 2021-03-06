# =====================================================================================================
# 
# COMMENT: This script reads the contents from a CSV file and adds each portgroup to the 
#    given cluster of hosts. The CSV file must contain the following headers and corresponding values;
#    PG_Name,VLAN,vSwitch
#
# Changes:
#    Version 1.0 - Original - Theo Crithary
#
# =====================================================================================================

# Ask user for input
do {
	$csv = read-host -prompt "Enter full path to CSV file"
} while ($csv -eq "")

do {
	$vc = read-host -prompt "Enter the name of the vCenter to connect to"
} while ($vc -eq "")

do {
	$cluster = read-host -prompt "Enter the name of the cluster"
} while ($cluster -eq "")

# Import the csv data into an array
$data = Import-CSV $csv

# Get user login details
do {
	$cred = Get-Credential
} while ($cred -eq "")

Connect-VIServer -server $vc -Credential $cred

# Iterate through the array
foreach ($item in $data)
{
	# Get host info
	Get-Cluster -Name $cluster | Get-VMHost | % { 
		$hostId = $_.Id
		$hostName = $_.Name
	
		# Check if portgroup name has been supplied
		if ($item.PG_Name -eq "") {
			"No portgroup has been supplied"
		}
		# Check if already exists
		if (Get-VMHost -Id $hostId | Get-VirtualPortGroup | where {$_.Name -eq $item.PG_Name}) {
			"Portgroup already exists on host - $($hostName)" 
  		}
		
  		else {
    		"Adding $($item.PG_Name) to $($hostName).........."
			$vs = Get-VirtualSwitch -VMHost $hostName -Name $($item.vSwitch) 
			New-VirtualPortGroup -Name $($item.PG_Name) -VLanId $($item.VLAN) -VirtualSwitch $vs
			# Quick error check
			if ($?) {
				"Success!"
			}
			else {
    			"An error has occurred. Please check the logs for more information."
			}
  		}
	}
}

Disconnect-VIServer $vc -Confirm:$false