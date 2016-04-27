$path = Split-Path $script:MyInvocation.MyCommand.Path
$dictionary = "$path\IsilonPlatformAddOn.csv"

#import prior IsilonPlatform Version first
Import-Module "$path\IsilonPlatformGenerator" -Force

#generate new IsilonPlatform
New-isiAPI -file "$path\Output\IsilonPlatformGet.ps1" -dictionary $dictionary -method Get -leading_api 2 -Verbose
New-isiAPI -file "$path\Output\IsilonPlatformRemove.ps1" -dictionary $dictionary -method Remove -leading_api 2 -Verbose
New-isiAPI -file "$path\Output\IsilonPlatformNew.ps1" -dictionary $dictionary -method New -leading_api 2 -Verbose
New-isiAPI -file "$path\Output\IsilonPlatformSet.ps1" -dictionary $dictionary -method Set -leading_api 2 -Verbose

# for new Isilon Versions generate a file containing the new API endpoints and manually smooth it
# finally append the content to the dictionary file
#New-isiAPICSV -file "$path\IsilonPlatformAddOn_new.csv" -fileToCompare $dictionary