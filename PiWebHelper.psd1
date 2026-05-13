New-ModuleManifest -Path "PiWebHelper.psd1" `
    -RootModule "PiWebHelper.psm1" `
    -ModuleVersion "1.0.0" `
    -Author "Dogan Suetcue" `
    -Description "Helper module for PiWeb API interactions" `
    -NestedModules @(
        "PiWebHelper.AuthenticationType.psm1",
        "PiWebHelper.EntityType.psm1",
        "PiWebHelper.WellKnownKeys.psm1"
    )