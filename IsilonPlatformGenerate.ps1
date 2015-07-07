$path = Split-Path $script:MyInvocation.MyCommand.Path
$dictionary = "$path\IsilonPlatformAddOn.csv"
#Import-Module "$path\IsilonPlatform" -Force
#Import-Module "$path\SSLValidation" -Force
Import-Module "$path\IsilonPlatformGenerator" -Force

New-isiAPI -file "$path\Output\IsilonPlatformGet.ps1" -dictionary $dictionary -method Get
New-isiAPI -file "$path\Output\IsilonPlatformRemove.ps1" -dictionary $dictionary -method Remove
New-isiAPI -file "$path\Output\IsilonPlatformNew.ps1" -dictionary $dictionary -method New
New-isiAPI -file "$path\Output\IsilonPlatformSet.ps1" -dictionary $dictionary -method Set

