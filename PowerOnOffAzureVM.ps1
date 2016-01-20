#
# PowerOnOffAzureVM.ps1
# The purpose of this script is to start and shutdown Azure VMs hosting in the given Azure subscription
#
Function Set-SCCMAzureVM{
	Param(
		[Parameter(mandatory=$true)]
		[string] $azureAccount = "chunye@live.com",
		[Parameter(mandatory=$true)]
		[string[]] $targetVMs,
		[Parameter(mandatory=$true)]
		[ValidateSet("SM","RM")]
		[string] $azureServiceMode = "SM",
		[Parameter(mandatory=$true)]
		[ValidateSet("Stop","Start")]
		[string] $operateMode = "Stop"
	)
	 #Load Azure module
	 Import-Module Azure

	 # Check if Windows Azure Powershell module is avaiable 
	 if ((Get-Module -ListAvailable Azure) -eq $null) 
	 { 
			throw "Windows Azure Powershell not found! Please install from http://www.windowsazure.com/en-us/downloads/#cmd-line-tools" 
			exit
	 } 
	
	 if($azureServiceMode -eq "RM")
	 {
		 #Load Azure module
		 Import-Module AzureRM.Compute
		 
		 # Check if Windows AzureRM.Compute Powershell module is avaiable 
		 if ((Get-Module -ListAvailable AzureRM.Compute) -eq $null) 
		 { 
				throw "Windows Azure Powershell not found! Please install from http://www.windowsazure.com/en-us/downloads/#cmd-line-tools" 
				exit
		 } 
	 }

	if($azureServiceMode -eq "SM"){
			#Set azure credential
		    Add-AzureAccount
	        #Get the right Azure Subscription
			$subscription = Get-AzureSubscription | Where-Object {$_.DefaultAccount -eq $azureAccount}
			$tempServiceName = ""
			$tempPowerState = ""

			#Set azure subscription
			Set-AzureSubscription -SubscriptionId $subscription.SubscriptionId
		      #Enumerate target VMs
			  if($targetVMs -and ($targetVMs.Length -gt 0)){
				$allVMs = Get-AzureVM | Select-Object Name,ServiceName,PowerState

				foreach($targetVM in $targetVMs){			  
				  foreach($tempVM in $allVMs){
					  #Find the target VM by walking through all existing VMs. And then fetch out that VM's ServiceName and PowerState
					  if ($targetVM -eq $tempVM.Name){
						  $tempServiceName = $tempVM.ServiceName
						  $tempPowerState = $tempVM.PowerState

						  #Receive Starting a VM instruction
						  if($operateMode -eq "Start")
						  {
							  #Only when the target VM is in stopped state, a VM start operation will be triggered. 
							  #Otherwise it means that the target VM has been started already. No action is required.
							  if($tempPowerState -eq "Stopped"){
								Write-Host "Starting VM $targetVM..."
								$result = Get-AzureVM -ServiceName $tempServiceName -Name $targetVM | Start-AzureVM
								if($result -and $result.OperationStatus -eq 'Succeeded')
								{
									Write-Host "VM $targetVM is Started!" -ForegroundColor "Green"
								}else{
									Write-Error "Failed to start $targetVM. Please check." 
								}
							  }else{
								  Write-Host "VM $targetVM has been started already!"
							  }
						  }else{
							  #Receive Stopping a VM instruction
							  #Only when the target VM is in started state, a VM stop operation will be triggered. 
							  #Otherwise it means that the target VM has been stopped already. No action is required.
							  if($tempPowerState -eq "Started"){
								Write-Host "Stopping VM $targetVM..."
								$result = Get-AzureVM -ServiceName $tempServiceName -Name $targetVM | Stop-AzureVM -Force
								if($result -and $result.OperationStatus -eq 'Succeeded')
								{
									Write-Host "VM $targetVM is stopped!" -ForegroundColor "Green"
								}else{
									Write-Error "Failed to stop $targetVM. Please check." 
								}
							  }else{
								  Write-Host "VM $targetVM has been stopped already!"
							  }
						  }
						  break
					  }
				  }
			  }  
		  }
	}else{
		        #Set azure credential
		        Login-AzureRmAccount
		        
		        #Get the right Azure Subscription
			    #$context = Get-AzureRmContext | Where-Object {$_.Account -eq $azureAccount}
			    $tempServiceName = ""
			    $tempPowerState = ""
			  
		        #Set azure subscription
				#Set-AzureSubscription -SubscriptionId $context.SubscriptionId
	          
		       #Enumerate target VMs
			   if($targetVMs -and ($targetVMs.Length -gt 0)){
				$allVMs = Get-AzureRmVM | Select-Object Name,ResourceGroupName

				foreach($targetVM in $targetVMs){			  
				  foreach($tempVM in $allVMs){
					  #Find the target VM by walking through all existing VMs. And then fetch out that VM's ServiceName and PowerState
					  if ($targetVM -eq $tempVM.Name){
						  $tempServiceName = $tempVM.ResourceGroupName
						  $tempPowerState = Get-AzureRmVM -ResourceGroupName $tempServiceName -name $targetVM -Status `
						                       | select -ExpandProperty Statuses | ?{$_.Code -match "PowerState"} `
						                       | select -ExpandProperty DisplayStatus

						  #Receive Starting a VM instruction
						  if($operateMode -eq "Start")
						  {
							  #Only when the target VM is in stopped state, a VM start operation will be triggered. 
							  #Otherwise it means that the target VM has been started already. No action is required.
							  if($tempPowerState -match "VM deallocated"){
								Write-Host "Starting VM $targetVM..."
								$result = Get-AzureRmVM -ResourceGroupName $tempServiceName -Name $targetVM | Start-AzureRmVM
								if($result -and $result.Status -eq 'Succeeded')
								{
									Write-Host "VM $targetVM is Started!" -ForegroundColor "Green"
								}else{
									Write-Error "Failed to start $targetVM. Please check." 
								}
							  }else{
								  Write-Host "VM $targetVM has been started already!"
							  }
						  }else{
							  #Receive Stopping a VM instruction
							  #Only when the target VM is in started state, a VM stop operation will be triggered. 
							  #Otherwise it means that the target VM has been stopped already. No action is required.
							  if($tempPowerState -eq "VM running"){
								Write-Host "Stopping VM $targetVM..."
								$result = Get-AzureRmVM -ResourceGroupName $tempServiceName -Name $targetVM | Stop-AzureRmVM -Force
								if($result -and $result.Status -eq 'Succeeded')
								{
									Write-Host "VM $targetVM is stopped!" -ForegroundColor "Green"
								}else{
									Write-Error "Failed to stop $targetVM. Please check." 
								}
							  }else{
								  Write-Host "VM $targetVM has been stopped already!"
							  }
						  }
						  break
					  }
				  }
			  }  
		  }
	  }
}


#Scenario 1: Service Management VMs
<#
#$targetVMs = @(("ContosoDC","ContosoDC1982"),("ContosoCMCAS","ContosoSCCM"),("ContosoCMPRI","ContosoSCCM"),("ContosoCMPRI2","ContosoCMPRI2"),("win7test","kevinyetest"),("win10test","win10test-78tim30o"))
$targetVMs = @("ContosoDC","ContosoCMCAS","ContosoCMPRI","ContosoCMPRI2","win7test","win10test")
$azureAcct = "chunye@live.com"
$serviceMode = "SM"
#$opsMode = "Start"
#$opsMode = "Stop"

Set-SCCMAzureVM $azureAcct $targetVMs $serviceMode "Stop"
#Set-SCCMAzureVM $azureAcct $targetVMs $serviceMode "Start"
#>

#Scenario 2: Resource Management VMs
<#
#$targetVMs = @(("ContosoDC","ContosoDC1982"),("ContosoCMCAS","ContosoSCCM"),("ContosoCMPRI","ContosoSCCM"),("ContosoCMPRI2","ContosoCMPRI2"),("win7test","kevinyetest"),("win10test","win10test-78tim30o"))
$targetVMs = @("dc-vm")
$azureAcct = "kevinye@microsoft.com"
$serviceMode = "RM"
#$opsMode = "Start"
#$opsMode = "Stop"

Set-SCCMAzureVM $azureAcct $targetVMs $serviceMode "Stop"
#Set-SCCMAzureVM $azureAcct $targetVMs $serviceMode "Start"
#>