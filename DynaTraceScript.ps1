#DynaTrace Alert Integration With SolarWinds
#Created By Chen Ashkenazi, Oct 2021.
#The Script uses REST API to access Dynatrace for Open "Problems" and then stores it in a json file on the SW server.
#Then the script formatting this file and goes over each problem in a loop
#By going over the problems, the script generates a SolarWinds Alert file from template with the relavnt information 
#The alert checks if there is existing alert with the same problem ID in the database before importing it.
#
#
add-type @"
    using System.Net;
    using System.Security.Cryptography.X509Certificates;
    public class TrustAllCertsPolicy : ICertificatePolicy {
        public bool CheckValidationResult(
            ServicePoint srvPoint, X509Certificate certificate,
            WebRequest request, int certificateProblem) {
            return true;
        }
    }
"@
[System.Net.ServicePointManager]::CertificatePolicy = New-Object TrustAllCertsPolicy

#SWIS Connection

$username = ''
$password = ''
$server = 'localhost' 
$swis = Connect-Swis -UserName $username -Password $password -IgnoreSslErrors

#REST API Access Info
$Array = @()
$endpointUri = ""

#Access Parameters

$params = @{
Uri = $endpointUri
Headers = @{Authorization=("Api-Token {0}" -f $base64AuthInfo)}
Method = 'Get'
ContentType = 'application/json'
}

#Getting REST response, formatting and automatic create alert to SolarWinds


$restResponse = (Invoke-RestMethod @params).problems | ConvertTo-Json | Set-Content C:\SolarWindsScripts\dyna.json
$json = Get-Content -Raw -Path C:\SolarWindsScripts\dyna.json | ConvertFrom-Json

foreach ($i in $json){
	$currentID = $i.displayId
	$imp = $i.impactLevel
	$subject = $i.title
	$con = Get-Content C:\SolarWindsScripts\AlertTemplate\DynaTrace+Problem+xxxxxx.xml
	$con | % { $_.Replace("DynaTrace Problem xxxxxx", "DynaTrace Problem $currentID")} | Set-Content C:\SolarWindsScripts\CreatedAlerts\$currentID.xml
	$con1 = Get-Content C:\SolarWindsScripts\CreatedAlerts\$currentID.xml
	$con1 | % { $_.Replace("RPLCMSG", $currentID) } | Set-Content C:\SolarWindsScripts\CreatedAlerts\$currentID.xml
	$con2 = Get-Content C:\SolarWindsScripts\CreatedAlerts\$currentID.xml
	$con2 | % { $_.Replace("SMSTEXT", "Dynatrace Alert - $subject, $imp - $currentID ") } | Set-Content C:\SolarWindsScripts\CreatedAlerts\$currentID.xml
	$con3 = Get-Content C:\SolarWindsScripts\CreatedAlerts\$currentID.xml
	$con3 | % { $_.Replace("LOGTEXT", "Problem $currentID opened") } | Set-Content C:\SolarWindsScripts\CreatedAlerts\$currentID.xml
	$con4 = Get-Content C:\SolarWindsScripts\CreatedAlerts\$currentID.xml
	$con4 | % { $_.Replace("SRESETTEXT", "Dynatrace Alert Resolved - $subject, $imp - $currentID") } | Set-Content C:\SolarWindsScripts\CreatedAlerts\$currentID.xml
	$con5 = Get-Content C:\SolarWindsScripts\CreatedAlerts\$currentID.xml
	$con5 | % { $_.Replace("LRESETTEXT", "Problem $currentID closed") } | Set-Content C:\SolarWindsScripts\CreatedAlerts\$currentID.xml
	$AlertXml = Get-Content C:\SolarWindsScripts\CreatedAlerts\$currentID.xml -Raw
	$idSWQL = "%$currentID%"
	$checkAlert = Get-SwisData $swis 'SELECT Name From Orion.AlertConfigurations WHERE Name like @v' @{ v= $idSWQL }
	If ($checkAlert){
	write-host "Alert already exist in SolarWinds Database, ignoring import."
	}
	Else{
	write-host "Importing Alert for $currentID..."
	Invoke-SwisVerb $swis Orion.AlertConfigurations Import @($AlertXml)
	write-host "Import Completed succesfully"
	}	
	}

Write-Host "Message :" (Invoke-RestMethod @params).problems | ConvertTo-Json
Write-Host "Statistic: 1"
