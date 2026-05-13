# PiWeb Helper PS Module

PowerShell module for interacting with the ZEISS PiWeb REST API.

## Usage

### Retrieving Parts from PiWeb Server

```powershell
 $arguments = @{
    BaseUrl = "http://localhost:80"
    Entity = [EntityType]::Part
    ParameterList = @("PartPath")
    AuthenticationType = [AuthenticationType]::MicrosoftAccountAuth
}

$parts = Get-DataServiceRestObjects @arguments
```

Further information on using the PiWeb API can be found on the official site [here](https://zeiss-piweb.github.io/PiWeb-Api/general).

## License

[MIT](https://choosealicense.com/licenses/mit/)
