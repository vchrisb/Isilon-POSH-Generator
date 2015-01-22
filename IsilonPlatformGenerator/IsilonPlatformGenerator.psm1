# The MIT License
#
# Copyright (c) 2014 Christopher Banck.
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in
# all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
# THE SOFTWARE.

$ErrorActionPreference = "Stop"
#Set-StrictMode -Version Latest


function Get-isiAPIdirectory{
<#
.SYNOPSIS
    Get API directory
    
.DESCRIPTION
    Get API directory

.NOTES

#>

	[CmdletBinding()]
	
	param ()

    Begin{
        
    }
    Process{
        
        $ISIObject = Send-isiAPI -Method GET -Resource "/platform?describe&list"
        $ISIObject.directory

    }
    End{

    }
	
}

function Get-isiAPIdescription{
<#
.SYNOPSIS
    Get API directory description
    
.DESCRIPTION
    Get API directory description

.NOTES

#>

	[CmdletBinding()]
	
	param (
    [Parameter(Mandatory=$True,ValueFromPipelineByPropertyName=$False,ValueFromPipeline=$false,Position=0)][string]$directory,
    [switch]$plain,
    [switch]$child
    )

    Begin{
        
    }
    Process{
        if ($plain) {
            $ISIObject = Send-isiAPI -Method GET_JSON -Resource "$($directory)?describe"
            $ISIObject
        } elseif ($child) {
            $ISIObject = Send-isiAPI -Method GET -Resource "$($directory)?describe&json&list"
            $ISIObject.directory
        }else {
            $ISIObject = Send-isiAPI -Method GET -Resource "$($directory)?describe&json"
            $ISIObject
        }
        

    }
    End{

    }
	
}

function New-isiAPI{
<#
.SYNOPSIS
    Create Functions for directories
    
.DESCRIPTION
    Create Functions for directories

.NOTES

#>

	[CmdletBinding()]
	
	param (
        [Parameter(Mandatory=$True,ValueFromPipelineByPropertyName=$False,ValueFromPipeline=$False,Position=0)][string]$file,
        [Parameter(Mandatory=$True,ValueFromPipelineByPropertyName=$False,ValueFromPipeline=$False,Position=0)][string]$dictionary,
        [Parameter(Mandatory=$True,ValueFromPipelineByPropertyName=$False,ValueFromPipeline=$False,Position=0)][ValidateSet('Get','Remove','Set','New')][string]$method
    )

        if(Test-Path -Path $file){
            Remove-Item $file
        }

        $directory_list = Get-isiAPIdirectory
        $file_header =
'# The MIT License
#
# Copyright (c) 2014 Christopher Banck.
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in
# all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
# THE SOFTWARE.
Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

'
        Add-Content $file $file_header

        foreach ($item in $directory_list) {
            
            #skipp v2 fo now
            if($item -like '*/2/*'){
                Write-Host "$item skipped" -ForegroundColor Red
                continue
            }
            
            switch ($method){
                Get { New-isiAPIdirectoryGET -item $item -file $file -dictionary $dictionary }
                Remove { New-isiAPIdirectoryREMOVE -item $item -file $file -dictionary $dictionary }
                New { New-isiAPIdirectoryNEW -item $item -file $file -dictionary $dictionary }
                Set { New-isiAPIdirectorySET -item $item -file $file -dictionary $dictionary }
            }
        }

}

function New-isiAPIdirectoryGET{
<#
.SYNOPSIS
    Create Get Function for directory
    
.DESCRIPTION
    Create Get Function for directory

.NOTES

#>

	[CmdletBinding()]
	
	param (
        [Parameter(Mandatory=$True,ValueFromPipelineByPropertyName=$True,ValueFromPipeline=$True,Position=0)][string]$item,
        [Parameter(Mandatory=$True,ValueFromPipelineByPropertyName=$False,ValueFromPipeline=$False,Position=1)][string]$file,
        [Parameter(Mandatory=$True,ValueFromPipelineByPropertyName=$False,ValueFromPipeline=$False,Position=2)][string]$dictionary
    )

    Begin{
        $dictionary_item = Import-Csv -Path $dictionary -Delimiter ';' | where directory -eq $item
        $DataTypes_dict = @{ 'boolean' = 'bool'; 'integer' = 'int'; 'string' = 'string'; 'array' = 'array'}
        $Property_dict = @{ 'Get-isiSnapshotAliases' = 'aliases'; 'Get-isiAuthSettingsKrb5Domains' = 'domain'}
    }
    Process{

        $directory = $dictionary_item.directory_new
        $function_name = "Get-" + $dictionary_item.function_name

        $synopsis = $dictionary_item.synopsis
        $id_name = $dictionary_item.id_name
        $id_description = $dictionary_item.id_description
        $id2_name = $dictionary_item.id2_name
        $id2_description = $dictionary_item.id2_description
        
        $directory_description = Get-isiAPIdescription -directory $directory

        
        if (! $directory_description.GET_args) {
            return
        }
        Write-Host $item

        

##########        
########## GET
##########
    
### headers

        $function_header = "function $function_name{"

        $function_help_header = "<#`n.SYNOPSIS`n`tGet $synopsis`n`n.DESCRIPTION`n`t$($directory_description.GET_args.description)`n"

        $function_parameter_header = "`t[CmdletBinding("
        $function_body_header = "`tBegin{`n`t}`n`tProcess{`n"

        $function_body = ""
        $function_help_parameters = ""
        $function_parameter = ""
        $pos = 0

        if ($id_name) {
                $function_help_parameters += ".PARAMETER id`n`t$id_description ID`n`n"
                $function_parameter += "`t`t[Parameter(Mandatory=`$True,ValueFromPipelineByPropertyName=`$True,ValueFromPipeline=`$True,Position=$pos,ParameterSetName='ByID')][ValidateNotNullOrEmpty()][string]`$id,`n"               
                $function_help_parameters += ".PARAMETER name`n`t$id_description Name`n`n"
                $function_parameter += "`t`t[Parameter(Mandatory=`$True,ValueFromPipelineByPropertyName=`$True,ValueFromPipeline=`$True,Position=$pos,ParameterSetName='ByName')][ValidateNotNullOrEmpty()][string]`$name,`n"
                $function_parameter_header += "DefaultParametersetName='ByName'"
                $pos += 1
        }

        if ($id2_name) {
                $function_help_parameters += ".PARAMETER id2`n`t$id2_description ID`n`n"
                $function_parameter += "`t`t[Parameter(Mandatory=`$True,ValueFromPipelineByPropertyName=`$True,ValueFromPipeline=`$True,Position=$pos,ParameterSetName='ByID')][ValidateNotNullOrEmpty()][string]`$id2,`n"                
                $function_help_parameters += ".PARAMETER name2`n`t$id2_description Name`n`n"
                $function_parameter += "`t`t[Parameter(Mandatory=`$True,ValueFromPipelineByPropertyName=`$True,ValueFromPipeline=`$True,Position=$pos,ParameterSetName='ByName')][ValidateNotNullOrEmpty()][string]`$name2,`n"                
                $pos += 1
        }

        $function_parameter_header += ")]`n`t`tparam (`n"

        if ($directory_description.GET_args.properties) {
            
            $function_body += "`t`t`t`$queryArguments = @()`n"
            
            foreach ($i in ($directory_description.GET_args.properties | Get-Member -MemberType *Property).name){

                #create help parameters
                $function_help_parameters += ".PARAMETER $($i)`n`t$($directory_description.GET_args.properties.($i).description)`n"

                #create parameter option
                $function_parameter += "`t`t[Parameter(Mandatory=`$False,ValueFromPipelineByPropertyName=`$True,ValueFromPipeline=`$False,Position=$pos)][ValidateNotNullOrEmpty()]"
                
                #test for ValidateSet
                if ($directory_description.GET_args.properties.($i).enum){
                    $function_help_parameters += "`tValid inputs: $([String]::Join(',',$directory_description.GET_args.properties.($i).enum))`n"
                    $function_parameter += "[ValidateSet('$([String]::Join(''',''',$directory_description.GET_args.properties.($i).enum))')]"
                }

                $function_help_parameters += "`n"

                #add parameter
                $function_parameter += "[$($DataTypes_dict.Get_Item($directory_description.GET_args.properties.($i).type))]"
                $function_parameter += "`$$($i),`n"

                #create query argument
                $function_body += "`t`t`tif (`$$i){`n"
                $function_body += "`t`t`t`t`$queryArguments += '$i=' + `$$i`n"
                $function_body += "`t`t`t}`n"
                $pos += 1
            }

            #add resume token parameter
            if ($directory_description.GET_args.properties.resume) {

                $function_help_parameters += ".PARAMETER resumeToken`n`tIf using the parameter 'limit' enter a variable name without the dollar sign ($) to save the resume token`n`n"
                $function_parameter += "`t`t[Parameter(Mandatory=`$False,ValueFromPipelineByPropertyName=`$True,ValueFromPipeline=`$False,Position=$pos)][ValidateNotNullOrEmpty()][string]`$resumeToken,`n"                

                $pos += 1
            }
            
        }

        #add cluster parameter
        $function_parameter += "`t`t[Parameter(Mandatory=`$False,ValueFromPipelineByPropertyName=`$True,ValueFromPipeline=`$False,Position=$pos)][ValidateNotNullOrEmpty()][string]`$Cluster=`$isi_sessiondefault"
        $function_help_parameters +=  ".PARAMETER Cluster`n`tName of Isilon Cluster`n"

        #add footer
        $function_help_footer = ".NOTES`n`n#>"
        $function_parameter_footer = "`n`t`t)"
        
        if ($id_name) {
            $function_body += "`t`t`tif (`$id){`n`t`t`t`t`$param = `$id`n`t`t`t} else {`n`t`t`t`t`$param = `$name`n`t`t`t}`n"
            if ($id2_name) {
                $function_body += "`t`t`tif (`$id2){`n`t`t`t`t`$param2 = `$id2`n`t`t`t} else {`n`t`t`t`t`$param2 = `$name2`n`t`t`t}`n"
            }
        }

        #if no output schema return plain JSON
        if(! $directory_description.GET_output_schema){
            Write-Host "`tNo GET_output_schema fallback to JSON" -ForegroundColor Cyan
            $function_body += "`t`t`t`$ISIObject = Send-isiAPI -Method GET_JSON -Resource `"$directory`" -Cluster `$Cluster`n"
            $function_body += "`t`t`t`$ISIObject`n"

        }else{
            
            if ($directory_description.GET_args.properties){
                $function_body += "`t`t`tif (`$queryArguments) {`n"
                $function_body += "`t`t`t`t`$queryArguments = '?' + [String]::Join('&',`$queryArguments)`n"
                $function_body += "`t`t`t}`n" 
                $function_body += "`t`t`t`$ISIObject = Send-isiAPI -Method GET -Resource (`"$directory`" + `"`$queryArguments`") -Cluster `$Cluster`n"

            } else{
                $function_body += "`t`t`t`$ISIObject = Send-isiAPI -Method GET -Resource `"$directory`" -Cluster `$Cluster`n"

            }
            
            #remove total from output
            if ($directory_description.GET_output_schema.properties.total){
                #Write-Host "`tRemoved 'total' from GET_output_schema" -ForegroundColor Cyan
                $directory_description.GET_output_schema.properties.PSObject.Properties.Remove('total')
            }

            #remove count from output
            if ($directory_description.GET_output_schema.properties.count){
                #Write-Host "`tRemoved 'count' from GET_output_schema" -ForegroundColor Cyan
                $directory_description.GET_output_schema.properties.PSObject.Properties.Remove('count')
            }

            ##BUG misspelling of 'properties' as 'properites'
            if ($directory_description.GET_output_schema.properties) {
                $output_properties = $directory_description.GET_output_schema.properties | Get-Member -MemberType *Property
            }elseif ($directory_description.GET_output_schema.properites) {
                Write-Host "`tGET_output_schema.properties misspelled as properites" -ForegroundColor Cyan
                $output_properties = $directory_description.GET_output_schema.properites | Get-Member -MemberType *Property
            }

            #remove resume from output
            if ($output_properties.name -like '*resume*') {
                $directory_description.GET_output_schema.properties.PSObject.Properties.Remove('resume')
                $output_properties = $directory_description.GET_output_schema.properties | Get-Member -MemberType *Property
            }

            #return property directly if only one output property
            if (($output_properties).Count -eq 1) {

                #escape special characters in property
                if ($output_properties.name -like '*-*'){
                    $output_properties_name = "'$($output_properties.name)'"
                }else{
                    $output_properties_name = $output_properties.name
                }

                #BUG wrong GET_output_schema
                if ($Property_dict.ContainsKey("Get-isi$($function_name)")){
                    Write-Host "`tGET_output_schema.properties name misspelled or wrong" -ForegroundColor Cyan
                    $output_properties_name = $Property_dict.Get_Item("Get-isi$($function_name)")
                }
                $function_body += "`t`t`t`$ISIObject.$($output_properties_name)`n"

            } else {
                $function_body += "`t`t`t`$ISIObject`n"
            }

            # save resume token if necessary
            if ($directory_description.GET_args.properties.resume) {
                $function_body += "`t`t`tif (`$resumeToken -and `$ISIObject.resume){`n"
                $function_body += "`t`t`t`t`Set-Variable -Name `$resumeToken -scope global -Value `$(`$ISIObject.resume)`n"
                $function_body += "`t`t`t}`n"
            }
            
        }
        $function_body_footer = "`t}`n`tEnd{`n`t}"

        $function_footer = "}`n`nExport-ModuleMember -Function $function_name`n"
        
        Add-Content $file $function_header
        Add-Content $file $function_help_header
        Add-Content $file $function_help_parameters
        Add-Content $file $function_help_footer
        Add-Content $file ($function_parameter_header + $function_parameter + $function_parameter_footer)
        Add-Content $file ($function_body_header + $function_body + $function_body_footer)
        Add-Content $file $function_footer

    }
    End{

    }
	
}

function New-isiAPIdirectoryREMOVE{
<#
.SYNOPSIS
    Create Remove Function for directory
    
.DESCRIPTION
    Create Remove Function for directory

.NOTES

#>

	[CmdletBinding()]
	
	param (
        [Parameter(Mandatory=$True,ValueFromPipelineByPropertyName=$True,ValueFromPipeline=$True,Position=0)][string]$item,
        [Parameter(Mandatory=$True,ValueFromPipelineByPropertyName=$False,ValueFromPipeline=$False,Position=1)][string]$file,
        [Parameter(Mandatory=$True,ValueFromPipelineByPropertyName=$False,ValueFromPipeline=$False,Position=2)][string]$dictionary
    )

    Begin{
        $dictionary_item = Import-Csv -Path $dictionary -Delimiter ';' | where directory -eq $item
        $DataTypes_dict = @{ 'boolean' = 'bool'; 'integer' = 'int'; 'string' = 'string'; 'array' = 'array'}
        $properties_dict = @{'force' = 'enforce'}

    }
    Process{

        $directory = $dictionary_item.directory_new
        $function_name = "Remove-" + $dictionary_item.function_name
        $synopsis = $dictionary_item.synopsis
        $id_name = $dictionary_item.id_name
        $id_description = $dictionary_item.id_description
        $id2_name = $dictionary_item.id2_name
        $id2_description = $dictionary_item.id2_description
        
        $directory_description = Get-isiAPIdescription -directory $directory

        
        if (! $directory_description.DELETE_args) {
            return
        }
        Write-Host $item

        

##########        
########## REMOVE
##########
    
### headers

        $function_header = "function $function_name{"
        $function_help_header = "<#`n.SYNOPSIS`n`tGet $synopsis`n`n.DESCRIPTION`n`t$($directory_description.DELETE_args.description)`n"
        $function_parameter_header = "`t[CmdletBinding("
        $function_body_header = "`tBegin{`n`t}`n`tProcess{`n"

        $function_body = ""
        $function_help_parameters = ""
        $function_parameter = ""
        $pos = 0

        if ($id_name) {
                $function_help_parameters += ".PARAMETER id`n`t$id_description ID`n`n"
                $function_parameter += "`t`t[Parameter(Mandatory=`$True,ValueFromPipelineByPropertyName=`$True,ValueFromPipeline=`$True,Position=$pos,ParameterSetName='ByID')][ValidateNotNullOrEmpty()][string]`$id,`n"               
                $function_help_parameters += ".PARAMETER name`n`t$id_description Name`n`n"
                $function_parameter += "`t`t[Parameter(Mandatory=`$True,ValueFromPipelineByPropertyName=`$True,ValueFromPipeline=`$True,Position=$pos,ParameterSetName='ByName')][ValidateNotNullOrEmpty()][string]`$name,`n"
                $function_parameter_header += "DefaultParametersetName='ByName'"
                $pos += 1
        }

        if ($id2_name) {
                $function_help_parameters += ".PARAMETER id2`n`t$id2_description ID`n`n"
                $function_parameter += "`t`t[Parameter(Mandatory=`$True,ValueFromPipelineByPropertyName=`$True,ValueFromPipeline=`$True,Position=$pos,ParameterSetName='ByID')][ValidateNotNullOrEmpty()][string]`$id2,`n"                
                $function_help_parameters += ".PARAMETER name2`n`t$id2_description Name`n`n"
                $function_parameter += "`t`t[Parameter(Mandatory=`$True,ValueFromPipelineByPropertyName=`$True,ValueFromPipeline=`$True,Position=$pos,ParameterSetName='ByName')][ValidateNotNullOrEmpty()][string]`$name2,`n"                
                $pos += 1
        }

        $function_parameter_header += ")]`n`t`tparam (`n"

        if ($directory_description.DELETE_args.properties) {
            Write-Host "`tDELETE_args"
            $function_body += "`t`t`t`$queryArguments = @()`n"
            
            foreach ($i in ($directory_description.DELETE_args.properties | Get-Member -MemberType *Property).name){
                $parameter = $i
                #create help parameters
                if ($properties_dict.ContainsKey($i)){
                    $parameter = $properties_dict.Get_Item($i)
                }
                $function_help_parameters += ".PARAMETER $parameter`n`t$($directory_description.DELETE_args.properties.($i).description)`n"

                #create parameters
                $function_parameter += "`t`t[Parameter(Mandatory=`$False,ValueFromPipelineByPropertyName=`$True,ValueFromPipeline=`$False,Position=$pos)][ValidateNotNullOrEmpty()]"
                

                if ($directory_description.DELETE_args.properties.($i).enum){
                    $function_help_parameters += "`tValid inputs: $([String]::Join(',',$directory_description.DELETE_args.properties.($i).enum))`n"
                    $function_parameter += "[ValidateSet('$([String]::Join(''',''',$directory_description.DELETE_args.properties.($i).enum))')]"
                }

                $function_help_parameters += "`n"


                $function_parameter += "[$($DataTypes_dict.Get_Item($directory_description.DELETE_args.properties.($i).type))]"
                $function_parameter += "`$$($parameter),`n"

                $function_body += "`t`t`tif (`$$parameter){`n"
                $function_body += "`t`t`t`t`$queryArguments += '$i=' + `$$parameter`n"
                $function_body += "`t`t`t}`n"
                $pos += 1
            }        
            
        }
        $function_parameter += "`t`t[Parameter(Mandatory=`$False,ValueFromPipelineByPropertyName=`$False,ValueFromPipeline=`$False,Position=$pos)][switch]`$Force,`n"
        $function_help_parameters +=  ".PARAMETER Force`n`tForce deletion of object without prompt`n`n"
        $pos += 1
        $function_parameter += "`t`t[Parameter(Mandatory=`$False,ValueFromPipelineByPropertyName=`$True,ValueFromPipeline=`$False,Position=$pos)][ValidateNotNullOrEmpty()][string]`$Cluster=`$isi_sessiondefault"
        $function_help_parameters +=  ".PARAMETER Cluster`n`tName of Isilon Cluster`n"


        $function_help_footer = ".NOTES`n`n#>"

        $function_parameter_footer = "`n`n)"
        

        $function_body += "`t`t`tif (`$Force -or `$PSCmdlet.ShouldProcess(`"`$id`",'Remove-isiSMBShares')){`n"
          
            if ($directory_description.DELETE_args.properties){
                $function_body += "`t`t`t`tif (`$queryArguments) {`n"
                $function_body += "`t`t`t`t`t`$queryArguments = '?' + [String]::Join('&',`$queryArguments)`n"
                $function_body += "`t`t`t`t}`n" 
                $function_body += "`t`t`t`t`$ISIObject = Send-isiAPI -Method DELETE -Resource (`"$directory`" + `"`$queryArguments`") -Cluster `$Cluster`n"

            } else{
                $function_body += "`t`t`t`t`$ISIObject = Send-isiAPI -Method DELETE -Resource `"$directory`" -Cluster `$Cluster`n"

            }
            
        $function_body += "`t`t`t`t`$ISIObject`n"
        $function_body += "`t`t`t}`n"  
        $function_body_footer =
"    }
    End{
    }"

        $function_footer =
"}

Export-ModuleMember -Function $function_name`n"
        
        Add-Content $file $function_header
        Add-Content $file $function_help_header
        Add-Content $file $function_help_parameters
        Add-Content $file $function_help_footer
        Add-Content $file ($function_parameter_header + $function_parameter + $function_parameter_footer)
        Add-Content $file ($function_body_header + $function_body + $function_body_footer)
        Add-Content $file $function_footer

    }
    End{

    }
	
}

function New-isiAPIdirectoryNEW{
<#
.SYNOPSIS
    Create Function for directory
    
.DESCRIPTION
    Create Function for directory

.NOTES

#>

	[CmdletBinding()]
	
	param (
        [Parameter(Mandatory=$True,ValueFromPipelineByPropertyName=$True,ValueFromPipeline=$True,Position=0)][string]$item,
        [Parameter(Mandatory=$True,ValueFromPipelineByPropertyName=$False,ValueFromPipeline=$False,Position=1)][string]$file,
        [Parameter(Mandatory=$True,ValueFromPipelineByPropertyName=$False,ValueFromPipeline=$False,Position=2)][string]$dictionary
    )

    Begin{
        $dictionary_item = Import-Csv -Path $dictionary -Delimiter ';' | where directory -eq $item
        $DataTypes_dict = @{ 'boolean' = 'bool'; 'integer' = 'int'; 'string' = 'string'; 'array' = 'array'}
    }
    Process{

        $directory = $dictionary_item.directory_new
        $function_name = "New-" + $dictionary_item.function_name
        $synopsis = $dictionary_item.synopsis
        $id_name = $dictionary_item.id_name
        $id_description = $dictionary_item.id_description
        $id2_name = $dictionary_item.id2_name
        $id2_description = $dictionary_item.id2_description
        
        $directory_description = Get-isiAPIdescription -directory $directory

        
        if (! $directory_description.POST_args) {
            return
        }
        Write-Host $item

        

##########        
########## NEW
##########
    
### headers

        $function_header = "function $function_name{"

        $function_help_header =
"<#
.SYNOPSIS
    New $synopsis
    
.DESCRIPTION
    $($directory_description.POST_args.description)
"

        $function_parameter_header = "`t[CmdletBinding()]`n`t`tparam (`n"

        $function_body_header = "`tBegin{`n`t}`n`tProcess{`n"
        $function_body = "`t`t`t`$BoundParameters = `$PSBoundParameters`n"
        $function_body += "`t`t`t`$BoundParameters = `$BoundParameters.Remove('Cluster')`n"
        $function_help_parameters = ""
        $function_parameter = ""
        $pos = 0

        if ($id_name) {
                $function_help_parameters += ".PARAMETER id`n`t$id_description`n"

                $function_parameter += "`t`t[Parameter(Mandatory=`$True,ValueFromPipelineByPropertyName=`$True,ValueFromPipeline=`$True,Position=$pos,ParameterSetName='ByID')][ValidateNotNullOrEmpty()]"                
                $function_help_parameters += "`n"


                $function_parameter += "[string]"
                $function_parameter += "`$id,`n"
                $function_body += "`t`t`t`$BoundParameters = `$BoundParameters.Remove('id')`n"
                $pos += 1

        }

        if ($id2_name) {
                $function_help_parameters += ".PARAMETER id2`n`t$id2_description`n"

                $function_parameter += "`t`t[Parameter(Mandatory=`$True,ValueFromPipelineByPropertyName=`$True,ValueFromPipeline=`$True,Position=$pos,ParameterSetName='ByID')][ValidateNotNullOrEmpty()]"                
                $function_help_parameters += "`n"


                $function_parameter += "[string]"
                $function_parameter += "`$id2,`n"
                $function_body += "`t`t`t`$BoundParameters = `$BoundParameters.Remove('id2')`n"
                $pos += 1

        }

        if ($directory_description.POST_args.properties) {
            
            $function_body += "`t`t`t`$queryArguments = @()`n"
            
            foreach ($i in ($directory_description.POST_args.properties | Get-Member -MemberType *Property).name){
                #create help parameters
                $function_help_parameters += ".PARAMETER $($i)`n`t$($directory_description.POST_args.properties.($i).description)`n"

                $mandatory = 'False'
                ### MANDATORY
                if ($directory_description.POST_args.properties.($i).required -eq 'True'){
                    $mandatory = 'True'
                }

                #create parameters
                $function_parameter += "`t`t[Parameter(Mandatory=`$$mandatory,ValueFromPipelineByPropertyName=`$True,ValueFromPipeline=`$False,Position=$pos)][ValidateNotNullOrEmpty()]"
                

                if ($directory_description.POST_args.properties.($i).enum){
                    $function_help_parameters += "`tValid inputs: $([String]::Join(',',$directory_description.POST_args.properties.($i).enum))`n"
                    $function_parameter += "[ValidateSet('$([String]::Join(''',''',$directory_description.POST_args.properties.($i).enum))')]"
                }

                $function_help_parameters += "`n"

                $type = $DataTypes_dict.Get_Item($directory_description.POST_args.properties.($i).type)
                if (! $type) {
                    $type = 'object'
                }

                $function_parameter += "[$type]"
                $function_parameter += "`$$($i),`n"

                $function_body += "`t`t`tif (`$$i){`n"
                $function_body += "`t`t`t`t`$queryArguments += '$i=' + `$$i`n"
                $function_body += "`t`t`t`t`$BoundParameters = `$BoundParameters.Remove('`$$i')`n"
                $function_body += "`t`t`t}`n"
                $pos += 1
            }

            #add resume token parameter
            if ($directory_description.POST_args.properties.resume) {

                $function_help_parameters += ".PARAMETER resumeToken`n`tIf using the parameter 'limit' enter a variable name without the dollar sign ($) to save the resume token`n"

                $function_parameter += "`t`t[Parameter(Mandatory=`$False,ValueFromPipelineByPropertyName=`$True,ValueFromPipeline=`$False,Position=$pos)][ValidateNotNullOrEmpty()]"                
                $function_help_parameters += "`n"


                $function_parameter += "[string]"
                $function_parameter += "`$resumeToken,`n"
                $function_body += "`t`t`t`t`$BoundParameters = `$BoundParameters.Remove('`$$i')`n"
                $pos += 1
            }

            
            
        }

        if ($directory_description.POST_input_schema.properties) { 
           
            foreach ($i in ($directory_description.POST_input_schema.properties | Get-Member -MemberType *Property).name){
                #create help parameters
                $function_help_parameters += ".PARAMETER $($i)`n`t$($directory_description.POST_input_schema.properties.($i).description)`n"

                #create parameters

                $mandatory = 'False'
                ### MANDATORY
                if ($directory_description.POST_input_schema.properties.($i).required -eq 'True'){
                    $mandatory = 'True'
                }
                $function_parameter += "`t`t[Parameter(Mandatory=`$$mandatory,ValueFromPipelineByPropertyName=`$True,ValueFromPipeline=`$False,Position=$pos)][ValidateNotNullOrEmpty()]"
                

                if ($directory_description.POST_input_schema.properties.($i).enum){
                    $function_help_parameters += "`tValid inputs: $([String]::Join(',',$directory_description.POST_input_schema.properties.($i).enum))`n"
                    $function_parameter += "[ValidateSet('$([String]::Join(''',''',$directory_description.POST_input_schema.properties.($i).enum))')]"
                }

                $function_help_parameters += "`n"


                $type = $DataTypes_dict.Get_Item($directory_description.POST_input_schema.properties.($i).type)
                if (! $type) {
                    $type = 'object'
                }

                $function_parameter += "[$type]"
                $function_parameter += "`$$($i),`n"

                $pos += 1
            }
            
        }

        $function_parameter += "`t`t[Parameter(Mandatory=`$False,ValueFromPipelineByPropertyName=`$True,ValueFromPipeline=`$False,Position=$pos)][ValidateNotNullOrEmpty()][string]`$Cluster=`$isi_sessiondefault"
        $function_help_parameters +=  ".PARAMETER Cluster`n`tName of Isilon Cluster`n"

        $function_help_footer = ".NOTES`n`n#>"

        $function_parameter_footer = "`n`n)"
        
            
            if ($directory_description.POST_args.properties){
                $function_body += "`t`t`tif (`$queryArguments) {`n"
                $function_body += "`t`t`t`t`$queryArguments = '?' + [String]::Join('&',`$queryArguments)`n"
                $function_body += "`t`t`t}`n" 
                $function_body += "`t`t`t`$ISIObject = Send-isiAPI -Method POST -Resource (`"$directory`" + `"`$queryArguments`") -body (convertto-json -depth 40 `$BoundParameters) -Cluster `$Cluster`n"

            } else{
                $function_body += "`t`t`t`$ISIObject = Send-isiAPI -Method POST -Resource `"$directory`" -body (convertto-json -depth 40 `$BoundParameters) -Cluster `$Cluster`n"

            }
            
            #remove total
            if ($directory_description.POST_output_schema.properties.total){
                Write-Host "`tRemoved 'total' from POST_output_schema" -ForegroundColor Cyan
                $directory_description.POST_output_schema.properties.PSObject.Properties.Remove('total')
            }

            #remove count
            if ($directory_description.POST_output_schema.properties.count){
                Write-Host "`tRemoved 'count' from POST_output_schema" -ForegroundColor Cyan
                $directory_description.POST_output_schema.properties.PSObject.Properties.Remove('count')
            }

            #BUG misspelling of 'properties' as 'properites'
            if ($directory_description.POST_output_schema.properties) {
                $output_properties = $directory_description.POST_output_schema.properties | Get-Member -MemberType *Property
            }elseif ($directory_description.POST_output_schema.properites) {
                Write-Host "`tPOST_output_schema.properties misspelled as properites" -ForegroundColor Cyan
                $output_properties = $directory_description.POST_output_schema.properites | Get-Member -MemberType *Property
            }

            if ($output_properties.name -like '*resume*') {
                Write-Host "`tRemoved 'resume' from POST_output_schema because GET_args.properties does not include this property " -ForegroundColor Cyan
                $directory_description.POST_output_schema.properties.PSObject.Properties.Remove('resume')
                $output_properties = $directory_description.POST_output_schema.properties | Get-Member -MemberType *Property
            }

            #return property directly if only one output property
            if (($output_properties).Count -eq 1) {
                #Write-Host "`tonly one GET_output_schema.properties therefore returning the property directly" -ForegroundColor Cyan
                
                #escape special characters in property
                if ($output_properties.name -like '*-*'){
                    $output_properties_name = "'$($output_properties.name)'"
                }else{
                    $output_properties_name = $output_properties.name
                }


                $function_body += "`t`t`t`$ISIObject.$($output_properties_name)`n"
            } else {
                $function_body += "`t`t`t`$ISIObject`n"
            }

            # save resume token if necessary
            if ($directory_description.POST_args.properties.resume) {
                $function_body += "`t`t`tif (`$resumeToken -and `$ISIObject.resume){`n"
                $function_body += "`t`t`t`t`Set-Variable -Name `$resumeToken -scope global -Value `$(`$ISIObject.resume)`n"
                $function_body += "`t`t`t}`n"
            }
            
        
        $function_body_footer =
"    }
    End{
    }"

        $function_footer =
"}

Export-ModuleMember -Function $function_name`n"
        
        Add-Content $file $function_header
        Add-Content $file $function_help_header
        Add-Content $file $function_help_parameters
        Add-Content $file $function_help_footer
        Add-Content $file ($function_parameter_header + $function_parameter + $function_parameter_footer)
        Add-Content $file ($function_body_header + $function_body + $function_body_footer)
        Add-Content $file $function_footer

    }
    End{

    }
	
}

function New-isiAPIdirectorySET{
<#
.SYNOPSIS
    Create Function for directory
    
.DESCRIPTION
    Create Function for directory

.NOTES

#>

	[CmdletBinding()]
	
	param (
        [Parameter(Mandatory=$True,ValueFromPipelineByPropertyName=$True,ValueFromPipeline=$True,Position=0)][string]$item,
        [Parameter(Mandatory=$True,ValueFromPipelineByPropertyName=$False,ValueFromPipeline=$False,Position=1)][string]$file,
        [Parameter(Mandatory=$True,ValueFromPipelineByPropertyName=$False,ValueFromPipeline=$False,Position=2)][string]$dictionary
    )

    Begin{
        $dictionary_item = Import-Csv -Path $dictionary -Delimiter ';' | where directory -eq $item
        $DataTypes_dict = @{ 'boolean' = 'bool'; 'integer' = 'int'; 'string' = 'string'; 'array' = 'array'}
    }
    Process{

        $directory = $dictionary_item.directory_new
        $function_name = "Set-" + $dictionary_item.function_name
        $synopsis = $dictionary_item.synopsis
        $id_name = $dictionary_item.id_name
        $id_description = $dictionary_item.id_description
        $id2_name = $dictionary_item.id2_name
        $id2_description = $dictionary_item.id2_description
        
        $directory_description = Get-isiAPIdescription -directory $directory

        
        if (! $directory_description.PUT_args) {
            return
        }
        Write-Host $item

        

##########        
########## SET
##########
    
### headers

        $function_header = "function $function_name{"

        $function_help_header =
"<#
.SYNOPSIS
    Set $synopsis
    
.DESCRIPTION
    $($directory_description.PUT_args.description)
"

        $function_parameter_header = "`t[CmdletBinding()]`n`t`tparam (`n"

        $function_body_header = "`tBegin{`n`t}`n`tProcess{`n"
        $function_body = "`$BoundParameters = `$PSBoundParameters`n"
        $function_body += "`$BoundParameters = `$BoundParameters.Remove('Cluster')`n"

        $function_help_parameters = ""
        $function_parameter = ""
        $pos = 0

        if ($id_name) {
                $function_help_parameters += ".PARAMETER id`n`t$id_description`n"

                $function_parameter += "`t`t[Parameter(Mandatory=`$True,ValueFromPipelineByPropertyName=`$True,ValueFromPipeline=`$True,Position=$pos,ParameterSetName='ByID')][ValidateNotNullOrEmpty()]"                
                $function_help_parameters += "`n"


                $function_parameter += "[string]"
                $function_parameter += "`$id,`n"
                $function_body += "`$BoundParameters = `$BoundParameters.Remove('id')`n"
                $pos += 1

        }

        if ($id2_name) {
                $function_help_parameters += ".PARAMETER id2`n`t$id2_description`n"

                $function_parameter += "`t`t[Parameter(Mandatory=`$True,ValueFromPipelineByPropertyName=`$True,ValueFromPipeline=`$True,Position=$pos,ParameterSetName='ByID')][ValidateNotNullOrEmpty()]"                
                $function_help_parameters += "`n"


                $function_parameter += "[string]"
                $function_parameter += "`$id2,`n"
                $function_body += "`$BoundParameters = `$BoundParameters.Remove('id2')`n"
                $pos += 1

        }

        if ($directory_description.PUT_args.properties) {
            
            $function_body += "`t`t`t`$queryArguments = @()`n"
            
            foreach ($i in ($directory_description.PUT_args.properties | Get-Member -MemberType *Property).name){
                #create help parameters
                $function_help_parameters += ".PARAMETER $($i)`n`t$($directory_description.PUT_args.properties.($i).description)`n"

                #create parameters
                $function_parameter += "`t`t[Parameter(Mandatory=`$False,ValueFromPipelineByPropertyName=`$True,ValueFromPipeline=`$False,Position=$pos)][ValidateNotNullOrEmpty()]"
                

                if ($directory_description.PUT_args.properties.($i).enum){
                    $function_help_parameters += "`tValid inputs: $([String]::Join(',',$directory_description.PUT_args.properties.($i).enum))`n"
                    $function_parameter += "[ValidateSet('$([String]::Join(''',''',$directory_description.PUT_args.properties.($i).enum))')]"
                }

                $function_help_parameters += "`n"


                $function_parameter += "[$($DataTypes_dict.Get_Item($directory_description.PUT_args.properties.($i).type))]"
                $function_parameter += "`$$($i),`n"

                $function_body += "`t`t`tif (`$$i){`n"
                $function_body += "`t`t`t`t`$queryArguments += '$i=' + `$$i`n"
                $function_body += "`t`t`t`t`$BoundParameters = `$BoundParameters.Remove('`$$i')`n"
                $function_body += "`t`t`t}`n"
                $pos += 1
            }

            #add resume token parameter
            if ($directory_description.PUT_args.properties.resume) {

                $function_help_parameters += ".PARAMETER resumeToken`n`tIf using the parameter 'limit' enter a variable name without the dollar sign ($) to save the resume token`n"

                $function_parameter += "`t`t[Parameter(Mandatory=`$False,ValueFromPipelineByPropertyName=`$True,ValueFromPipeline=`$False,Position=$pos)][ValidateNotNullOrEmpty()]"                
                $function_help_parameters += "`n"

                $function_body += "`t`t`tif (`$resumeToken){`n"
                $function_body += "`t`t`t`t`$BoundParameters = `$BoundParameters.Remove('`$resumeToken')`n"
                $function_body += "`t`t`t}`n"

                $function_parameter += "[string]"
                $function_parameter += "`$resumeToken,`n"

                $pos += 1
            }

            
            
        }

        $function_parameter += "`t`t[Parameter(Mandatory=`$False,ValueFromPipelineByPropertyName=`$True,ValueFromPipeline=`$False,Position=$pos)][ValidateNotNullOrEmpty()][string]`$Cluster=`$isi_sessiondefault"
        $function_help_parameters +=  ".PARAMETER Cluster`n`tName of Isilon Cluster`n"

        $function_help_footer = ".NOTES`n`n#>"

        $function_parameter_footer = "`n`n)"
        


         
            if ($directory_description.PUT_args.properties){
                $function_body += "`t`t`tif (`$queryArguments) {`n"
                $function_body += "`t`t`t`t`$queryArguments = '?' + [String]::Join('&',`$queryArguments)`n"
                $function_body += "`t`t`t}`n" 
                $function_body += "`t`t`t`$ISIObject = Send-isiAPI -Method PUT -Resource (`"$directory`" + `"`$queryArguments`") -body (convertto-json -depth 40 `$BoundParameters) -Cluster `$Cluster`n"

            } else{
                $function_body += "`t`t`t`$ISIObject = Send-isiAPI -Method PUT -Resource `"$directory` -body (convertto-json -depth 40 `$BoundParameters) -Cluster `$Cluster`n"

            }
            
            #remove total
            if ($directory_description.PUT_input_schema.properties.total){
                #Write-Host "`tRemoved 'total' from GET_output_schema" -ForegroundColor Cyan
                $directory_description.PUT_input_schema.properties.PSObject.Properties.Remove('total')
            }

            #remove count
            if ($directory_description.PUT_input_schema.properties.count){
                #Write-Host "`tRemoved 'count' from GET_output_schema" -ForegroundColor Cyan
                $directory_description.PUT_input_schema.properties.PSObject.Properties.Remove('count')
            }

            #BUG misspelling of 'properties' as 'properites'
            if ($directory_description.PUT_input_schema.properties) {
                $output_properties = $directory_description.PUT_input_schema.properties | Get-Member -MemberType *Property
            }elseif ($directory_description.PUT_input_schema.properites) {
                Write-Host "`tPUT_input_schema.properties misspelled as properites" -ForegroundColor Cyan
                $output_properties = $directory_description.PUT_input_schema.properites | Get-Member -MemberType *Property
            }

            if ($output_properties.name -like '*resume*') {
                #Write-Host "`tRemoved 'resume' from GET_output_schema because GET_args.properties does not include this property " -ForegroundColor Cyan
                $directory_description.PUT_input_schema.properties.PSObject.Properties.Remove('resume')
                $output_properties = $directory_description.PUT_input_schema.properties | Get-Member -MemberType *Property
            }

            #return property directly if only one output property
            if (($output_properties).Count -eq 1) {
                #Write-Host "`tonly one GET_output_schema.properties therefore returning the property directly" -ForegroundColor Cyan
                
                #escape special characters in property
                if ($output_properties.name -like '*-*'){
                    $output_properties_name = "'$($output_properties.name)'"
                }else{
                    $output_properties_name = $output_properties.name
                }

                $function_body += "`t`t`t`$ISIObject.$($output_properties_name)`n"
            } else {
                $function_body += "`t`t`t`$ISIObject`n"
            }

            # save resume token if necessary
            if ($directory_description.PUT_args.properties.resume) {
                $function_body += "`t`t`tif (`$resumeToken -and `$ISIObject.resume){`n"
                $function_body += "`t`t`t`t`Set-Variable -Name `$resumeToken -scope global -Value `$(`$ISIObject.resume)`n"
                $function_body += "`t`t`t}`n"
            }
            
        
        $function_body_footer =
"    }
    End{
    }"

        $function_footer =
"}

Export-ModuleMember -Function $function_name`n"
        
        Add-Content $file $function_header
        Add-Content $file $function_help_header
        Add-Content $file $function_help_parameters
        Add-Content $file $function_help_footer
        Add-Content $file ($function_parameter_header + $function_parameter + $function_parameter_footer)
        Add-Content $file ($function_body_header + $function_body + $function_body_footer)
        Add-Content $file $function_footer

    }
    End{

    }
	
}

function Test-isiAPI{
<#
.SYNOPSIS
    Test Isilon POSH API
    
.DESCRIPTION
    Test Isilon POSH API

.NOTES

#>

	[CmdletBinding()]
	
	param (
    [Parameter(Mandatory=$True,ValueFromPipelineByPropertyName=$True,ValueFromPipeline=$True,Position=0)][string]$module,
    [Parameter(Mandatory=$False,ValueFromPipelineByPropertyName=$False,ValueFromPipeline=$False,Position=1)][string[]]$skip,
    [switch]$wait,
    [switch]$silent
    )
    foreach ($exported_command in ((Get-Module -Name $module).ExportedCommands.Values | select name)) {
        
        if ($skip -contains $exported_command.name) {
            Write-Host -NoNewLine "Skipping $($exported_command.name)`n" -foreground "red"
            continue
        }
        
        Write-Host -NoNewLine "Invoking $($exported_command.name)`n" -foreground "magenta"
        if ($wait){
            Write-Host -NoNewLine "Press any key to continue...`n`n"
            $null = $Host.UI.RawUI.ReadKey('NoEcho,IncludeKeyDown');
        }
        if ($silent) {
            Invoke-Expression $exported_command.name > $null
        }else {
            Invoke-Expression $exported_command.name
        }
    }

}

function New-isiAPICSV{
<#
.SYNOPSIS
    Create CSV for Directories
    
.DESCRIPTION
    Create CSV for Directories

.NOTES

#>

	[CmdletBinding()]
	
	param (
        [Parameter(Mandatory=$True,ValueFromPipelineByPropertyName=$False,ValueFromPipeline=$False,Position=0)][string]$file
    )

        if(Test-Path -Path $file){
            Remove-Item $file
        }

        $directory_list = Get-isiAPIdirectory
        $file_header = "directory;directory_new;describtion;function_name;synopsis;id_name;id_description;id2_name;id2_description"

        Add-Content $file $file_header

        foreach ($item in $directory_list) {

            if($item -like '*/2/*'){
                Write-Host "$item skipped" -ForegroundColor Red
                continue
            }

            New-isiAPIdirectoryCSV -item $item -file $file

        }

}

function New-isiAPIdirectoryCSV{
<#
.SYNOPSIS
    Create CSV Line for Directory
    
.DESCRIPTION
    Create CSV Line for Directory

.NOTES

#>

	[CmdletBinding()]
	
	param (
        [Parameter(Mandatory=$True,ValueFromPipelineByPropertyName=$True,ValueFromPipeline=$True,Position=0)][string]$item,
        [Parameter(Mandatory=$True,ValueFromPipelineByPropertyName=$False,ValueFromPipeline=$False,Position=1)][string]$file
    )

    Begin{

        $DataTypes_dict = @{ 'boolean' = 'bool'; 'integer' = 'int'; 'string' = 'string'; 'array' = 'array'}
        $Replace_dict = @{ 'Protocols' = ''; 'QuotaQuotas' = 'Quotas'; 'SnapshotSnapshots' = 'Snapshots'; 'JobJob' = 'Job'}
    }
    Process{
        $directory_origin = $item
        $directory = "/platform$($item)"     
        $directory_description = Get-isiAPIdescription -directory $directory

        $id_found = $False
        $id2_found = $False       

        if ($directory -match '^([\/\w*\-*]*\/)<(\w*)\+*>([\/\w*\-*]*\/*)<*(\w*-*\w*)\+*>*'){
            $id_name = $directory -replace '^([\/\w*\-*]*\/)<(\w*)\+*>([\/\w*\-*]*\/*)<*(\w*-*\w*)\+*>*','$2'
            $id2_name = $directory -replace '^([\/\w*\-*]*\/)<(\w*)\+*>([\/\w*\-*]*\/*)<*(\w*-*\w*)\+*>*','$4'
            $id_found = $True

            if($id2_name){
                $directory = $directory -replace '^([\/\w*\-*]*\/)<(\w*)\+*>([\/\w*\-*]*\/*)<*(\w*-*\w*)\+*>*','$1$id$3$id2'
                $item = $item -replace '^([\/\w*\-*]*\/)<(\w*)\+*>([\/\w*\-*]*\/*)<*(\w*-*\w*)\+*>*','$1X$2Y2'
                $id2_found = $True
            }else{
                $directory = $directory -replace '^([\/\w*\-*]*\/)<(\w*)\+*>','$1$id'
                $item = $item -replace '^([\/\w*\-*]*\/)<(\w*)\+*>','$1X'
            }
            $item = $item -replace '^([\/\w*\-*]*\/)<(\w*)\+*>','$1X'
            $item = $item -replace '(ies\/X)','y'
            $item = $item -replace '([^s])(s\/X)','$1'
            $item = $item -replace '(\/X)',''
            
        }


        $item_list = $item.Substring(3).Split('/') | ForEach-Object{ $_.Split('-')} | ForEach-Object {$_.substring(0,1).toupper() + $_.substring(1).tolower()}
        $function_name = [String]::Join('',$item_list)

        foreach ($replacement in $Replace_dict.Keys){
            if ($function_name -like "*$replacement*"){
                $function_name = $function_name.Replace($replacement,$Replace_dict.Get_Item($replacement))
            }
        }
        
        $synopsis = [String]::Join(' ',$item_list)
        if ($id_found){
            $id_description = "$($id_name.substring(0,1).toupper())$($id_name.substring(1).tolower()) ID"
        }
        if ($id2_found){
            $id2_description = "$($id2_name.substring(0,1).toupper())$($id2_name.substring(1).tolower()) ID"
        }

        Add-Content $file "$directory_origin;$directory;$($directory_description.GET_args.description);isi$function_name;$synopsis;$id_name;$id_description;$id2_name;$id2_description"

    }
    End{

    }
	
}

Export-ModuleMember -Function Get-isiAPIdirectoryGET
Export-ModuleMember -Function Get-isiAPIdirectoryREMOVE
Export-ModuleMember -Function Get-isiAPIdirectoryNEW
Export-ModuleMember -Function Get-isiAPIdirectorySET
Export-ModuleMember -Function New-isiAPIdirectoryCSV
Export-ModuleMember -Function Get-isiAPIdescription
Export-ModuleMember -Function New-isiAPI
Export-ModuleMember -Function New-isiAPICSV
Export-ModuleMember -Function New-isiAPIdirectory
Export-ModuleMember -Function Test-isiAPI
