$path = Split-Path $script:MyInvocation.MyCommand.Path
$dictionary = "$path\IsilonPlatformAddOn.csv"

#import prior IsilonPlatform Version first
Import-Module "$path\IsilonPlatformGenerator" -Force

#generate new IsilonPlatform

# for new Isilon Versions generate a file containing the new API endpoints and manually smooth it
# finally append the content to the dictionary file
#New-isiAPICSV -file "$path\IsilonPlatformAddOn_new.csv" -fileToCompare $dictionary