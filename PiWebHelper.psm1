using module .\Enums\PiWebHelper.AuthenticationType.psm1
using module .\Classes\PiWebHelper.WellKnownKeys.psm1

function ConvertTo-Utc([string]$DateTimeString) { 
    try { 
        $dt = [datetime]::Parse($DateTimeString, [cultureinfo]::CurrentCulture)
        return $dt.ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ss.fffZ") 
    } catch { 
        return $null
    } 
}

function ConvertTo-DateTime([string]$DateTimeString) {
    try {
        $dt = [datetime]::Parse($DateTimeString, [cultureinfo]::CurrentCulture)
        return $dt.ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ss") 
    } catch {
        return $null
    }
}

function New-QueryFilter {
    param (
        [Parameter(Mandatory = $true)]
        [PSCustomObject]$Entity,

        [Parameter(Mandatory = $true)]
        [string[]]$ParameterList
    )

    $result = @{}

    foreach ($parameter in $ParameterList) {
        if ($Entity.PSObject.Properties.Name -contains $parameter) {
            $value = $Entity.$parameter

            $utcValue = ConvertTo-Utc $value
            if ($null -ne $utcValue) {
                $value = $utcValue
            }

            $key = if ($parameter -match '^K(.+)') {
                $Matches[1]
            } else {
                $parameter
            }

            $result[$key] = $value
        }
    }
    
    return $result
}

function Get-DataServiceRestObjects {
    param(
        [Parameter(Mandatory = $true)]
        [string]$BaseUrl,

        [Parameter(Mandatory = $true)]
        [AuthenticationType]$AuthenticationType,

        [Parameter(Mandatory = $true)]
        [PSCustomObject]$Entity, 

        [Parameter(Mandatory = $true)]
        [string[]]$ParameterList
    )

    $filter = New-QueryFilter -Entity $Entity -ParameterList $ParameterList
    $uriBuilder = [System.UriBuilder]::new("$($BaseUrl)/dataServiceRest/$($Entity.Type)s")
    
    $params = @()
    $searchParts = @()

    foreach ($key in $filter.Keys) {
        if ($key -is [int] -and [int]$key -eq [WellKnownKeys]::Measurement::Time) {
            $searchParts += "$($key)=[$($filter[$key])]"
        }
        else {
            $encodedValue = [System.Uri]::EscapeDataString([string]$filter[$key])
            $params += "$key=$encodedValue"
        }
    }

    if ($searchParts.Count -gt 0) {
        $searchCondition = ($searchParts -join '+')
        $encodedSearch = [System.Uri]::EscapeDataString($searchCondition)
        $params += "searchCondition=$encodedSearch"
    }

    $uriBuilder.Query = ($params -join '&')

    try {
        $headers = New-WebRequestHeaders $BaseUrl $AuthenticationType
        $response = Invoke-WebRequest -Method Get -Uri $uriBuilder.Uri -Headers $headers
        $entities = $response.Content | ConvertFrom-Json
        return $entities
    }
    catch {
        throw "Error fetching $($Entity)s: $_"
    }
}

function Get-RawDataInformations {
    param(
        [Parameter(Mandatory = $true)]
        [string]$BaseUrl,

        [Parameter(Mandatory = $true)]
        [AuthenticationType]$AuthenticationType,

        [Parameter(Mandatory = $true)]
        [PSCustomObject]$Entity,

        [Parameter(Mandatory = $true)]
        [string[]]$ParameterList
    )

    $filter = New-QueryFilter -Entity $Entity -ParameterList $ParameterList
    $uriBuilder = [System.UriBuilder]::new("$($BaseUrl)/rawDataServiceRest/rawDataInformation/$($Entity.Type)")
    $query = [System.Web.HttpUtility]::ParseQueryString("")
    $query["uuids"] = "{$($Entity.Uuid)}"
    foreach ($key in $Filter.Keys) {
        $query[$key] = $Filter[$key]
    }
    $uriBuilder.Query = $query.ToString()

    try {
        $headers = New-WebRequestHeaders $BaseUrl $AuthenticationType
        $response = Invoke-WebRequest -Method Get -Uri $uriBuilder.Uri -Headers $headers
        $rawDataInformations = $response.Content | ConvertFrom-Json
        return $rawDataInformations
    }
    catch {
        throw "Error fetching raw data information for $($Entity) with UUID $($Uuid): $_"
    }
}

function Get-RawDataObject {
    param(
        [Parameter(Mandatory = $true)]
        [string]$BaseUrl, 

        [Parameter(Mandatory = $true)]
        [AuthenticationType]$AuthenticationType,

        [Parameter(Mandatory = $true)]
        [PSCustomObject]$RawDataInformation
    )

    $uri = [System.Uri]::new("$($BaseUrl)/rawDataServiceRest/rawData/$($RawDataInformation.target.entity)/$($RawDataInformation.target.uuid)/$($RawDataInformation.key)")

    try {
        $headers = New-WebRequestHeaders $BaseUrl $AuthenticationType
        $response = Invoke-WebRequest -Method Get -Uri $uri -Headers $headers
        return $response
    }
    catch {
        throw "Error fetching raw data for $($Entity) with UUID $($Uuid) and Key $($Key): $_"
    }
}

function New-WebRequestHeaders([string]$BaseUrl, [AuthenticationType]$AuthenticationType) {
    $headers = @{
        "Content-Type" = "application/json"
    }

    if ($AuthenticationType -eq [AuthenticationType]::MicrosoftAccountAuth)
    {
        $token = Get-PiWebToken $BaseUrl
        $headers["Authorization"] = "Bearer $($token.access_token)"
    }

    return $headers
}

Export-ModuleMember -Function New-QueryFilter, Get-DataServiceRestObjects, Get-RawDataInformations, Get-RawDataObject