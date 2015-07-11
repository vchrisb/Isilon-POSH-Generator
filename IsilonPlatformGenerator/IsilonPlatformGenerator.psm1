# The MIT License
#
# Copyright (c) 2015 Christopher Banck.
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
        [Parameter(Mandatory=$True,ValueFromPipelineByPropertyName=$False,ValueFromPipeline=$False,Position=0)][ValidateSet('Get','Remove','Set','New', 'List')][string]$method
    )

        if(Test-Path -Path $file){
            Remove-Item $file
        }

        $directory_list = Get-isiAPIdirectory
        $onefs_build = (Send-isiAPI -Method GET -Resource "/platform/1/cluster/config").onefs_version.build

        $file_header =
'# The MIT License
#
# Copyright (c) 2015 Christopher Banck.
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

'
$file_header += "#Build using Isilon OneFS build: $onefs_build`n"
$file_header += '
Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

'

        Add-Content $file $file_header

        foreach ($item in $directory_list) {
            
            <#skipp v2 fo now
            if($item -like '/2/*'){
                Write-Host "$item skipped" -ForegroundColor Red
                continue
            }
            #>
            switch ($method){
                Get { New-isiAPIdirectoryGET -item $item -file $file -dictionary $dictionary }
                Remove { New-isiAPIdirectoryREMOVE -item $item -file $file -dictionary $dictionary }
                New { New-isiAPIdirectoryNEW -item $item -file $file -dictionary $dictionary }
                Set { New-isiAPIdirectorySET -item $item -file $file -dictionary $dictionary }
                List {
                        $directory_description = Get-isiAPIdescription -directory "/platform$item"
                        Write-Host "$item`n`t" -NoNewline
                        if ($directory_description.GET_args){Write-Host "GET " -NoNewline}
                        if ($directory_description.POST_args){Write-Host "POST " -NoNewline}
                        if ($directory_description.PUT_args){Write-Host "PUT " -NoNewline}
                        if ($directory_description.DELETE_args){Write-Host "DELETE " -NoNewline}
                        Write-Host "`n" -NoNewline
                
                }
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
        $Property_dict = @{ 'Get-isiSnapshotAliases' = 'aliases'; 'Get-isiAuthSettingsKrb5Domains' = 'domain'; 'Get-isiFilesystemAccessTime' = 'access_time'}
    }
    Process{

        $directory = $dictionary_item.directory_new
        $function_name = "Get-" + $dictionary_item.function_name
        $synopsis = $dictionary_item.synopsis
        $parameter1 = $dictionary_item.parameter1_name
        $parameter1_description = $dictionary_item.parameter1_description
        $parameter2 = $dictionary_item.parameter2_name
        $parameter2_description = $dictionary_item.parameter2_description
        
        $directory_description = Get-isiAPIdescription -directory $directory

        
        if (! $directory_description.GET_args) {
            return
        }
        Write-Host "$item - Get $synopsis"

        

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

        if ($parameter1) {
                $function_help_parameters += ".PARAMETER $($dictionary_item.parameter1a)`n`t$parameter1_description $($dictionary_item.parameter1a)`n`n"
                $function_parameter += "`t`t[Parameter(Mandatory=`$True,ValueFromPipelineByPropertyName=`$True,ValueFromPipeline=`$True,Position=$pos,ParameterSetName='ByID')][ValidateNotNullOrEmpty()][string]`$$($dictionary_item.parameter1a),`n"               
                if ($dictionary_item.parameter1b){
                    $function_help_parameters += ".PARAMETER $($dictionary_item.parameter1b)`n`t$parameter1_description $($dictionary_item.parameter1b)`n`n"
                    $function_parameter += "`t`t[Parameter(Mandatory=`$True,ValueFromPipelineByPropertyName=`$True,ValueFromPipeline=`$True,Position=$pos,ParameterSetName='ByName')][ValidateNotNullOrEmpty()][string]`$$($dictionary_item.parameter1b),`n"
                }
                $function_parameter_header += "DefaultParametersetName='ByID'"
                $pos += 1
        }

        if ($parameter2) {
                $function_help_parameters += ".PARAMETER $($dictionary_item.parameter2a)`n`t$id2_description $($dictionary_item.parameter2a)`n`n"
                $function_parameter += "`t`t[Parameter(Mandatory=`$True,ValueFromPipelineByPropertyName=`$True,ValueFromPipeline=`$True,Position=$pos,ParameterSetName='ByID')][ValidateNotNullOrEmpty()][string]`$$($dictionary_item.parameter2a),`n"                
                if ($dictionary_item.parameter2b){
                    $function_help_parameters += ".PARAMETER $($dictionary_item.parameter2b)`n`t$id2_description $($dictionary_item.parameter2b)`n`n"
                    $function_parameter += "`t`t[Parameter(Mandatory=`$True,ValueFromPipelineByPropertyName=`$True,ValueFromPipeline=`$True,Position=$pos,ParameterSetName='ByName')][ValidateNotNullOrEmpty()][string]`$$($dictionary_item.parameter2b),`n"                
                }
                $pos += 1
        }

        $function_parameter_header += ")]`n`t`tparam (`n"

        if ($directory_description.GET_args.properties) {
            
            $function_body += "`t`t`t`$queryArguments = @()`n"
            
            foreach ($i in ($directory_description.GET_args.properties | Get-Member -MemberType *Property).name){

                #create help parameters
                $function_help_parameters += ".PARAMETER $($i)`n`t$($directory_description.GET_args.properties.($i).description)`n"

                $mandatory = 'False'
                ### MANDATORY
                if ($directory_description.GET_args.properties.($i).required -eq 'True'){
                    $mandatory = 'True'
                }

                #create parameter option
                $function_parameter += "`t`t[Parameter(Mandatory=`$$mandatory,ValueFromPipelineByPropertyName=`$True,ValueFromPipeline=`$False,Position=$pos)][ValidateNotNullOrEmpty()]"
                
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
        $function_parameter += "`t`t[Parameter(Mandatory=`$False,ValueFromPipelineByPropertyName=`$True,ValueFromPipeline=`$False,Position=$pos)][ValidateNotNullOrEmpty()][string]`$Cluster"
        $function_help_parameters +=  ".PARAMETER Cluster`n`tName of Isilon Cluster`n"

        #add footer
        $function_help_footer = ".NOTES`n`n#>"
        $function_parameter_footer = "`n`t`t)"
        
        if ($parameter1) {
            if ($dictionary_item.parameter1b) {
                $function_body += "`t`t`tif (`$psBoundParameters.ContainsKey('$($dictionary_item.parameter1a)')){`n`t`t`t`t`$parameter1 = `$$($dictionary_item.parameter1a)`n`t`t`t} else {`n`t`t`t`t`$parameter1 = `$$($dictionary_item.parameter1b)`n`t`t`t}`n"
            }else {
                $function_body += "`t`t`t`$parameter1 = `$$($dictionary_item.parameter1a)`n"
            }
            if ($parameter2) {
                if ($dictionary_item.parameter2b) {
                    $function_body += "`t`t`tif (`$psBoundParameters.ContainsKey('$($dictionary_item.parameter2a)')){`n`t`t`t`t`$parameter2 = `$$($dictionary_item.parameter2a)`n`t`t`t} else {`n`t`t`t`t`$parameter2 = `$$($dictionary_item.parameter2b)`n`t`t`t}`n"
                } else{
                    $function_body += "`t`t`t`$parameter2 = `$$($dictionary_item.parameter2a)`n"
                }
                
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
                if ($Property_dict.ContainsKey("$function_name")){
                    Write-Host "`tGET_output_schema.properties name misspelled or wrong" -ForegroundColor Cyan
                    $output_properties_name = $Property_dict.Get_Item("$function_name")
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
        
        $parameter1 = $dictionary_item.parameter1_name
        $parameter1_description = $dictionary_item.parameter1_description
        $parameter2 = $dictionary_item.parameter2_name
        $parameter2_description = $dictionary_item.parameter2_description
        
        $directory_description = Get-isiAPIdescription -directory $directory

        
        if (! $directory_description.DELETE_args) {
            return
        }
        Write-Host "$item - Remove $synopsis"

        

##########        
########## REMOVE
##########
    
### headers

        $function_header = "function $function_name{"

        $function_help_header = "<#`n.SYNOPSIS`n`tRemove $synopsis`n`n.DESCRIPTION`n`t$($directory_description.DELETE_args.description)`n"

        $function_parameter_header = "`t[CmdletBinding(SupportsShouldProcess=`$True,ConfirmImpact='High'"
        $function_body_header = "`tBegin{`n`t}`n`tProcess{`n"

        $function_body = ""
        $function_help_parameters = ""
        $function_parameter = ""
        $pos = 0

        if ($parameter1) {

                # if parameter 1a is like *id* set parameter type to int else to string
                if ($dictionary_item.parameter1a -like '*id*'){
                    $parameter1a_type = 'int'
                }else{
                    $parameter1a_type = 'string'
                }

                $function_help_parameters += ".PARAMETER $($dictionary_item.parameter1a)`n`t$parameter1_description $($dictionary_item.parameter1a)`n`n"
                $function_parameter += "`t`t[Parameter(Mandatory=`$True,ValueFromPipelineByPropertyName=`$True,ValueFromPipeline=`$True,Position=$pos,ParameterSetName='ByID')][ValidateNotNullOrEmpty()][$parameter1a_type]`$$($dictionary_item.parameter1a),`n"               
                if ($dictionary_item.parameter1b){
                    $function_help_parameters += ".PARAMETER $($dictionary_item.parameter1b)`n`t$parameter1_description $($dictionary_item.parameter1b)`n`n"
                    $function_parameter += "`t`t[Parameter(Mandatory=`$True,ValueFromPipelineByPropertyName=`$True,ValueFromPipeline=`$True,Position=$pos,ParameterSetName='ByName')][ValidateNotNullOrEmpty()][string]`$$($dictionary_item.parameter1b),`n"
                }
                $function_parameter_header += ",DefaultParametersetName='ByID'"
                $pos += 1
        }

        if ($parameter2) {

                # if parameter 2a is like *id* set parameter type to int else to string
                if ($dictionary_item.parameter2a -like '*id*'){
                    $parameter2a_type = 'int'
                }else{
                    $parameter2a_type = 'string'
                }
                
                # if parameter2b exists, add ParameterSet
                if ($dictionary_item.parameter2b){
                    $paramterset2a = ",ParameterSetName='ByName'"
                }else{
                    $paramterset2a = ""
                }
                

                $function_help_parameters += ".PARAMETER $($dictionary_item.parameter2a)`n`t$id2_description $($dictionary_item.parameter2a)`n`n"
                $function_parameter += "`t`t[Parameter(Mandatory=`$True,ValueFromPipelineByPropertyName=`$True,ValueFromPipeline=`$True,Position=$pos$paramterset2a)][ValidateNotNullOrEmpty()][$parameter2a_type]`$$($dictionary_item.parameter2a),`n"                
                if ($dictionary_item.parameter2b){
                    $function_help_parameters += ".PARAMETER $($dictionary_item.parameter2b)`n`t$id2_description $($dictionary_item.parameter2b)`n`n"
                    $function_parameter += "`t`t[Parameter(Mandatory=`$True,ValueFromPipelineByPropertyName=`$True,ValueFromPipeline=`$True,Position=$pos,ParameterSetName='ByName')][ValidateNotNullOrEmpty()][string]`$$($dictionary_item.parameter2b),`n"                
                }
                $pos += 1
        }

        $function_parameter_header += ")]`n`t`tparam (`n"

        if ($directory_description.DELETE_args.properties) {
            
            $function_body += "`t`t`t`$queryArguments = @()`n"
            
            foreach ($i in ($directory_description.DELETE_args.properties | Get-Member -MemberType *Property).name){

                #create help parameters
                $parameter = $i
                if ($properties_dict.ContainsKey($i)){
                    $parameter = $properties_dict.Get_Item($i)
                }
                $function_help_parameters += ".PARAMETER $($i)`n`t$($directory_description.DELETE_args.properties.($i).description)`n"

                $mandatory = 'False'
                ### MANDATORY
                if ($directory_description.DELETE_args.properties.($i).required -eq 'True'){
                    $mandatory = 'True'
                }

                #create parameter option
                $function_parameter += "`t`t[Parameter(Mandatory=`$$mandatory,ValueFromPipelineByPropertyName=`$True,ValueFromPipeline=`$False,Position=$pos)][ValidateNotNullOrEmpty()]"
                
                #test for ValidateSet
                if ($directory_description.DELETE_args.properties.($i).enum){
                    $function_help_parameters += "`tValid inputs: $([String]::Join(',',$directory_description.DELETE_args.properties.($i).enum))`n"
                    $function_parameter += "[ValidateSet('$([String]::Join(''',''',$directory_description.DELETE_args.properties.($i).enum))')]"
                }

                $function_help_parameters += "`n"

                #add parameter
                $function_parameter += "[$($DataTypes_dict.Get_Item($directory_description.DELETE_args.properties.($i).type))]"
                $function_parameter += "`$$($parameter),`n"

                #create query argument
                $function_body += "`t`t`tif (`$$parameter){`n"
                $function_body += "`t`t`t`t`$queryArguments += '$i=' + `$$parameter`n"
                $function_body += "`t`t`t}`n"
                $pos += 1
            }
            
        }
        #add force parameter
        $function_parameter += "`t`t[Parameter(Mandatory=`$False,ValueFromPipelineByPropertyName=`$False,ValueFromPipeline=`$False,Position=$pos)][switch]`$Force,`n"
        $function_help_parameters +=  ".PARAMETER Force`n`tForce deletion of object without prompt`n`n"
        $pos += 1

        #add cluster parameter
        $function_parameter += "`t`t[Parameter(Mandatory=`$False,ValueFromPipelineByPropertyName=`$True,ValueFromPipeline=`$False,Position=$pos)][ValidateNotNullOrEmpty()][string]`$Cluster"
        $function_help_parameters +=  ".PARAMETER Cluster`n`tName of Isilon Cluster`n"

        #add footer
        $function_help_footer = ".NOTES`n`n#>"
        $function_parameter_footer = "`n`t`t)"
        
        if ($parameter1) {
            if ($dictionary_item.parameter1b) {
                $function_body += "`t`t`tif (`$psBoundParameters.ContainsKey('$($dictionary_item.parameter1a)')){`n`t`t`t`t`$parameter1 = `$$($dictionary_item.parameter1a)`n`t`t`t} else {`n`t`t`t`t`$parameter1 = `$$($dictionary_item.parameter1b)`n`t`t`t}`n"
            }else {
                $function_body += "`t`t`t`$parameter1 = `$$($dictionary_item.parameter1a)`n"
            }
            if ($parameter2) {
                if ($dictionary_item.parameter2b) {
                    $function_body += "`t`t`tif (`$psBoundParameters.ContainsKey('$($dictionary_item.parameter2a)')){`n`t`t`t`t`$parameter2 = `$$($dictionary_item.parameter2a)`n`t`t`t} else {`n`t`t`t`t`$parameter2 = `$$($dictionary_item.parameter2b)`n`t`t`t}`n"
                } else{
                    $function_body += "`t`t`t`$parameter2 = `$$($dictionary_item.parameter2a)`n"
                }
                
            }
        }

        
            
        if ($directory_description.DELETE_args.properties){
            $function_body += "`t`t`tif (`$queryArguments) {`n"
            $function_body += "`t`t`t`t`$queryArguments = '?' + [String]::Join('&',`$queryArguments)`n"
            $function_body += "`t`t`t}`n"

            $function_body += "`t`t`tif (`$Force -or `$PSCmdlet.ShouldProcess(`"`$parameter1`",'$function_name')){`n"
            $function_body += "`t`t`t`t`$ISIObject = Send-isiAPI -Method DELETE -Resource (`"$directory`" + `"`$queryArguments`") -Cluster `$Cluster`n"

        } else{
            $function_body += "`t`t`tif (`$Force -or `$PSCmdlet.ShouldProcess(`"`$parameter1`",'$function_name')){`n"
            $function_body += "`t`t`t`t`$ISIObject = Send-isiAPI -Method DELETE -Resource `"$directory`" -Cluster `$Cluster`n"

        }

        $function_body += "`t`t`t}`n"
            
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

function New-isiAPIdirectoryNEW{
<#
.SYNOPSIS
    Create New Function for directory
    
.DESCRIPTION
    Create New Function for directory

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
        $Property_dict = @{ 'New-isiSnapshotAliases' = 'aliases'; 'New-isiAuthSettingsKrb5Domains' = 'domain'; 'Get-isiFilesystemAccessTime' = 'access_time'}
    }
    Process{

        $directory = $dictionary_item.directory_new
        $function_name = "New-" + $dictionary_item.function_name
        $synopsis = $dictionary_item.synopsis
        $parameter1 = $dictionary_item.parameter1_name
        $parameter1_description = $dictionary_item.parameter1_description
        $parameter2 = $dictionary_item.parameter2_name
        $parameter2_description = $dictionary_item.parameter2_description
        
        $directory_description = Get-isiAPIdescription -directory $directory

        
        if (! $directory_description.POST_args) {
            return
        }

        Write-Host "$item - New $synopsis"

        

##########        
########## NEW
##########
    
### headers

        $function_header = "function $function_name{"
        $function_body = "`t`t`t`$BoundParameters = `$PSBoundParameters`n"
        $function_body += "`t`t`t`$BoundParameters.Remove('Cluster') | out-null`n"

        $function_help_header = "<#`n.SYNOPSIS`n`tNew $synopsis`n`n.DESCRIPTION`n`t$($directory_description.POST_args.description)`n"

        $function_parameter_header = "`t[CmdletBinding("
        $function_body_header = "`tBegin{`n`t}`n`tProcess{`n"

        $function_help_parameters = ""
        $function_parameter = ""
        $pos = 0

        if ($parameter1) {
                $function_help_parameters += ".PARAMETER $($dictionary_item.parameter1a)`n`t$parameter1_description $($dictionary_item.parameter1a)`n`n"
                $function_parameter += "`t`t[Parameter(Mandatory=`$True,ValueFromPipelineByPropertyName=`$True,ValueFromPipeline=`$True,Position=$pos,ParameterSetName='ByID')][ValidateNotNullOrEmpty()][int]`$$($dictionary_item.parameter1a),`n"               
                if ($dictionary_item.parameter1b){
                    $function_help_parameters += ".PARAMETER $($dictionary_item.parameter1b)`n`t$parameter1_description $($dictionary_item.parameter1b)`n`n"
                    $function_parameter += "`t`t[Parameter(Mandatory=`$True,ValueFromPipelineByPropertyName=`$True,ValueFromPipeline=`$True,Position=$pos,ParameterSetName='ByName')][ValidateNotNullOrEmpty()][string]`$$($dictionary_item.parameter1b),`n"
                }
                $function_parameter_header += "DefaultParametersetName='ByID'"
                $pos += 1
        }

        if ($parameter2) {
                $function_help_parameters += ".PARAMETER $($dictionary_item.parameter2a)`n`t$id2_description $($dictionary_item.parameter2a)`n`n"
                $function_parameter += "`t`t[Parameter(Mandatory=`$True,ValueFromPipelineByPropertyName=`$True,ValueFromPipeline=`$True,Position=$pos,ParameterSetName='ByID')][ValidateNotNullOrEmpty()][int]`$$($dictionary_item.parameter2a),`n"                
                if ($dictionary_item.parameter2b){
                    $function_help_parameters += ".PARAMETER $($dictionary_item.parameter2b)`n`t$id2_description $($dictionary_item.parameter2b)`n`n"
                    $function_parameter += "`t`t[Parameter(Mandatory=`$True,ValueFromPipelineByPropertyName=`$True,ValueFromPipeline=`$True,Position=$pos,ParameterSetName='ByName')][ValidateNotNullOrEmpty()][string]`$$($dictionary_item.parameter2b),`n"                
                }
                $pos += 1
        }

        $function_parameter_header += ")]`n`t`tparam (`n"
        

        if ($directory_description.POST_args.properties) {
            $args_properties = $directory_description.POST_args.properties

            $function_body += "`t`t`t`$queryArguments = @()`n"
            
            foreach ($i in ($args_properties | Get-Member -MemberType *Property).name){

                #create help parameters
                $function_help_parameters += ".PARAMETER $($i)`n`t$($args_properties.($i).description)`n"

                $mandatory = 'False'
                ### MANDATORY
                if ($args_properties.($i).required -eq 'True'){
                    $mandatory = 'True'
                }

                #create parameter option
                $function_parameter += "`t`t[Parameter(Mandatory=`$$mandatory,ValueFromPipelineByPropertyName=`$True,ValueFromPipeline=`$False,Position=$pos)][ValidateNotNullOrEmpty()]"
                
                #test for ValidateSet
                if ($args_properties.($i).enum){
                    $function_help_parameters += "`tValid inputs: $([String]::Join(',',$args_properties.($i).enum))`n"
                    $function_parameter += "[ValidateSet('$([String]::Join(''',''',$args_properties.($i).enum))')]"
                }

                $function_help_parameters += "`n"

                $type = $DataTypes_dict.Get_Item($args_properties.($i).type)
                if (! $type) {
                    $type = 'object'
                }

                $function_parameter += "[$type]"

                #add parameter
                $function_parameter += "`$$($i),`n"

                #create query argument
                $function_body += "`t`t`tif (`$$i){`n"
                $function_body += "`t`t`t`t`$queryArguments += '$i=' + `$$i`n"
                $function_body += "`t`t`t`t`$BoundParameters.Remove('$i') | out-null`n"
                $function_body += "`t`t`t}`n"
                $pos += 1
            }
            
        }

        #smbshare bug with "properties"
        if ($item -eq "/1/protocols/smb/shares"){
            $directory_description.POST_input_schema | Add-Member -NotePropertyName properties -NotePropertyValue $directory_description.POST_input_schema.type.properties
        }

        if ($directory_description.POST_input_schema.properties) { 
            $input_schema = $directory_description.POST_input_schema.properties         

            foreach ($i in ($input_schema | Get-Member -MemberType *Property).name){

                #smbshare bug with zone and nfsalias and nfsexports
                if ($item -eq "/1/protocols/smb/shares" -or $item -eq "/2/protocols/nfs/aliases" -or $item -eq "/2/protocols/nfs/exports" -and $i -eq 'zone'){
                    continue
                }

                #create help parameters
                $function_help_parameters += ".PARAMETER $($i)`n`t$($input_schema.($i).description)`n"

                #create parameters

                $mandatory = 'False'
                ### MANDATORY
                if ($directory_description.POST_input_schema.properties.($i).required -eq 'True'){
                    $mandatory = 'True'
                }
                $function_parameter += "`t`t[Parameter(Mandatory=`$$mandatory,ValueFromPipelineByPropertyName=`$True,ValueFromPipeline=`$False,Position=$pos)]"
                

                if ($input_schema.($i).enum){
                    $function_help_parameters += "`tValid inputs: $([String]::Join(',',$input_schema.($i).enum))`n"
                    $function_parameter += "[ValidateSet('$([String]::Join(''',''',$input_schema.($i).enum))')]"
                }

                $function_help_parameters += "`n"


                $type = $DataTypes_dict.Get_Item($input_schema.($i).type)
                if (! $type) {
                    $type = 'object'
                }

                $function_parameter += "[$type]"
                $function_parameter += "`$$($i),`n"

                $pos += 1
            }
            
        }

        #add cluster parameter
        $function_parameter += "`t`t[Parameter(Mandatory=`$False,ValueFromPipelineByPropertyName=`$True,ValueFromPipeline=`$False,Position=$pos)][ValidateNotNullOrEmpty()][string]`$Cluster"
        $function_help_parameters +=  ".PARAMETER Cluster`n`tName of Isilon Cluster`n"

        #add footer
        $function_help_footer = ".NOTES`n`n#>"
        $function_parameter_footer = "`n`t`t)"

        if ($parameter1) {
            if ($dictionary_item.parameter1b) {
                $function_body += "`t`t`tif (`$psBoundParameters.ContainsKey('$($dictionary_item.parameter1a)')){`n`t`t`t`t`$parameter1 = `$$($dictionary_item.parameter1a)`n"
                $function_body += "`t`t`t`t`$BoundParameters.Remove('$($dictionary_item.parameter1a)') | out-null`n"
                $function_body += "`t`t`t} else {`n`t`t`t`t`$parameter1 = `$$($dictionary_item.parameter1b)`n"
                $function_body += "`t`t`t`t`$BoundParameters.Remove('$($dictionary_item.parameter1b)') | out-null`n"
                $function_body += "`t`t`t}`n"
            }else {
                $function_body += "`t`t`t`$parameter1 = `$$($dictionary_item.parameter1a)`n"
                $function_body += "`t`t`t`$BoundParameters.Remove('$($dictionary_item.parameter1a)') | out-null`n"
            }
            if ($parameter2) {
                if ($dictionary_item.parameter2b) {
                    $function_body += "`t`t`tif (`$psBoundParameters.ContainsKey('$($dictionary_item.parameter2a)')){`n`t`t`t`t`$parameter2 = `$$($dictionary_item.parameter2a)`n"
                    $function_body += "`t`t`t`t`$BoundParameters.Remove('$($dictionary_item.parameter2a)') | out-null`n"
                    $function_body += "`t`t`t} else {`n`t`t`t`t`$parameter2 = `$$($dictionary_item.parameter2b)`n"
                    $function_body += "`t`t`t`t`$BoundParameters.Remove('$($dictionary_item.parameter2b)') | out-null`n"
                    $function_body += "`t`t`t}`n"
                } else{
                    $function_body += "`t`t`t`$parameter2 = `$$($dictionary_item.parameter2a)`n"
                    $function_body += "`t`t`t`$BoundParameters.Remove('$($dictionary_item.parameter2a)') | out-null`n"
                }
                
            }
        }
            
            if ($directory_description.POST_args.properties){
                $function_body += "`t`t`tif (`$queryArguments) {`n"
                $function_body += "`t`t`t`t`$queryArguments = '?' + [String]::Join('&',`$queryArguments)`n"
                $function_body += "`t`t`t}`n" 
                $function_body += "`t`t`t`$ISIObject = Send-isiAPI -Method POST -Resource (`"$directory`" + `"`$queryArguments`") -body (convertto-json -depth 40 `$BoundParameters) -Cluster `$Cluster`n"

            } else{
                $function_body += "`t`t`t`$ISIObject = Send-isiAPI -Method POST -Resource `"$directory`" -body (convertto-json -depth 40 `$BoundParameters) -Cluster `$Cluster`n"

            }
            
            #remove total from output
            if ($directory_description.POST_output_schema.properties.total){
                #Write-Host "`tRemoved 'total' from GET_output_schema" -ForegroundColor Cyan
                $directory_description.POST_output_schema.properties.PSObject.Properties.Remove('total')
            }

            #remove count from output
            if ($directory_description.POST_output_schema.properties.count){
                #Write-Host "`tRemoved 'count' from GET_output_schema" -ForegroundColor Cyan
                $directory_description.POST_output_schema.properties.PSObject.Properties.Remove('count')
            }

            ##BUG misspelling of 'properties' as 'properites'
            if ($directory_description.POST_output_schema.properties) {
                $output_properties = $directory_description.POST_output_schema.properties | Get-Member -MemberType *Property
            }elseif ($directory_description.POST_output_schema.properites) {
                Write-Host "`tPOST_output_schema.properties misspelled as properites" -ForegroundColor Cyan
                $output_properties = $directory_description.POST_output_schema.properites | Get-Member -MemberType *Property
            }

            #remove resume from output
            if ($output_properties.name -like '*resume*') {
                $directory_description.POST_output_schema.properties.PSObject.Properties.Remove('resume')
                $output_properties = $directory_description.POST_output_schema.properties | Get-Member -MemberType *Property
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
                if ($Property_dict.ContainsKey("$function_name")){
                    Write-Host "`tPOST_output_schema.properties name misspelled or wrong" -ForegroundColor Cyan
                    $output_properties_name = $Property_dict.Get_Item("$function_name")
                }
                $function_body += "`t`t`t`$ISIObject.$($output_properties_name)`n"

            } else {
                $function_body += "`t`t`t`$ISIObject`n"
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

function New-isiAPIdirectorySET{
<#
.SYNOPSIS
    Create New Function for directory
    
.DESCRIPTION
    Create New Function for directory

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
        $Property_dict = @{ 'Set-isiSnapshotAliases' = 'aliases'; 'Set-isiAuthSettingsKrb5Domains' = 'domain'; 'Get-isiFilesystemAccessTime' = 'access_time'}
        $arg_properties_dict = @{'force' = 'enforce'}
        $input_properties_dict = @{'current-encoding' = 'current_encoding'}
    }
    Process{

        $directory = $dictionary_item.directory_new
        $function_name = "Set-" + $dictionary_item.function_name
        $synopsis = $dictionary_item.synopsis
        $parameter1 = $dictionary_item.parameter1_name
        $parameter1_description = $dictionary_item.parameter1_description
        $parameter2 = $dictionary_item.parameter2_name
        $parameter2_description = $dictionary_item.parameter2_description
        
        $parameter_array = ($dictionary_item.parameter1a,$dictionary_item.parameter1b,$dictionary_item.parameter2a,$dictionary_item.parameter1b)

        $directory_description = Get-isiAPIdescription -directory $directory

        
        if (! $directory_description.PUT_args) {
            return
        }
        Write-Host "$item - Set $synopsis"

        

##########        
########## SET
##########
    
### headers

        $function_header = "function $function_name{"
        $function_body = "`t`t`t`$BoundParameters = `$PSBoundParameters`n"
        $function_body += "`t`t`t`$BoundParameters.Remove('Cluster') | out-null`n"

        $function_help_header = "<#`n.SYNOPSIS`n`tSet $synopsis`n`n.DESCRIPTION`n`t$($directory_description.PUT_args.description)`n"

        $function_parameter_header = "`t[CmdletBinding(SupportsShouldProcess=`$True,ConfirmImpact='High'"
        $function_body_header = "`tBegin{`n`t}`n`tProcess{`n"

        $function_help_parameters = ""
        $function_parameter = ""
        $pos = 0

        if ($parameter1) {
                $function_help_parameters += ".PARAMETER $($dictionary_item.parameter1a)`n`t$parameter1_description $($dictionary_item.parameter1a)`n`n"
                $function_parameter += "`t`t[Parameter(Mandatory=`$True,ValueFromPipelineByPropertyName=`$True,ValueFromPipeline=`$True,Position=$pos,ParameterSetName='ByID')][ValidateNotNullOrEmpty()][int]`$$($dictionary_item.parameter1a),`n"               
                if ($dictionary_item.parameter1b){
                    $function_help_parameters += ".PARAMETER $($dictionary_item.parameter1b)`n`t$parameter1_description $($dictionary_item.parameter1b)`n`n"
                    $function_parameter += "`t`t[Parameter(Mandatory=`$True,ValueFromPipelineByPropertyName=`$True,ValueFromPipeline=`$True,Position=$pos,ParameterSetName='ByName')][ValidateNotNullOrEmpty()][string]`$$($dictionary_item.parameter1b),`n"
                }
                $function_parameter_header += ",DefaultParametersetName='ByID'"
                $pos += 1
        }

        if ($parameter2) {
                $function_help_parameters += ".PARAMETER $($dictionary_item.parameter2a)`n`t$id2_description $($dictionary_item.parameter2a)`n`n"
                $function_parameter += "`t`t[Parameter(Mandatory=`$True,ValueFromPipelineByPropertyName=`$True,ValueFromPipeline=`$True,Position=$pos,ParameterSetName='ByID')][ValidateNotNullOrEmpty()][int]`$$($dictionary_item.parameter2a),`n"                
                if ($dictionary_item.parameter2b){
                    $function_help_parameters += ".PARAMETER $($dictionary_item.parameter2b)`n`t$id2_description $($dictionary_item.parameter2b)`n`n"
                    $function_parameter += "`t`t[Parameter(Mandatory=`$True,ValueFromPipelineByPropertyName=`$True,ValueFromPipeline=`$True,Position=$pos,ParameterSetName='ByName')][ValidateNotNullOrEmpty()][string]`$$($dictionary_item.parameter2b),`n"                
                }
                $pos += 1
        }

        $function_parameter_header += ")]`n`t`tparam (`n"
        
        if ($parameter1) {
            if ($dictionary_item.parameter1b) {
                $function_body += "`t`t`tif (`$$($dictionary_item.parameter1a)){`n`t`t`t`t`$parameter1 = `$$($dictionary_item.parameter1a)`n"
                $function_body += "`t`t`t`t`$BoundParameters.Remove('$($dictionary_item.parameter1a)') | out-null`n"
                $function_body += "`t`t`t} else {`n`t`t`t`t`$parameter1 = `$$($dictionary_item.parameter1b)`n"
                $function_body += "`t`t`t`t`$BoundParameters.Remove('$($dictionary_item.parameter1b)') | out-null`n"
                $function_body += "`t`t`t}`n"
            }else {
                $function_body += "`t`t`t`$parameter1 = `$$($dictionary_item.parameter1a)`n"
                $function_body += "`t`t`t`$BoundParameters.Remove('$($dictionary_item.parameter1a)') | out-null`n"
            }
            if ($parameter2) {
                if ($dictionary_item.parameter2b) {
                    $function_body += "`t`t`tif (`$$($dictionary_item.parameter2a)){`n`t`t`t`t`$parameter2 = `$$($dictionary_item.parameter2a)`n"
                    $function_body += "`t`t`t`t`$BoundParameters.Remove('$($dictionary_item.parameter2a)') | out-null`n"
                    $function_body += "`t`t`t} else {`n`t`t`t`t`$parameter2 = `$$($dictionary_item.parameter2b)`n"
                    $function_body += "`t`t`t`t`$BoundParameters.Remove('$($dictionary_item.parameter2b)') | out-null`n"
                    $function_body += "`t`t`t}`n"
                } else{
                    $function_body += "`t`t`t`$parameter2 = `$$($dictionary_item.parameter2a)`n"
                    $function_body += "`t`t`t`$BoundParameters.Remove('$($dictionary_item.parameter2a)') | out-null`n"
                }
                
            }
        }

        if ($directory_description.PUT_args.properties) {
            $args_properties = $directory_description.PUT_args.properties
            $args_properties_names = ($args_properties | Get-Member -MemberType *Property).name

            $function_body += "`t`t`t`$queryArguments = @()`n"
            
            foreach ($i in $args_properties_names){

                #create help parameters
                $parameter = $i
                if ($arg_properties_dict.ContainsKey($i)){
                    $parameter = $arg_properties_dict.Get_Item($i)
                }
                

                $args_property = $args_properties.($i)

                

                #create help parameters
                $function_help_parameters += ".PARAMETER $($parameter)`n`t$($args_property.description)`n"

                $mandatory = 'False'
                ### MANDATORY
                if ($args_properties.($i).required -eq 'True'){
                    $mandatory = 'True'
                }

                #create parameter option
                $function_parameter += "`t`t[Parameter(Mandatory=`$$mandatory,ValueFromPipelineByPropertyName=`$True,ValueFromPipeline=`$False,Position=$pos)][ValidateNotNullOrEmpty()]"
                
                #test for ValidateSet
                if ($args_property.enum){
                    $function_help_parameters += "`tValid inputs: $([String]::Join(',',$args_property.enum))`n"
                    $function_parameter += "[ValidateSet('$([String]::Join(''',''',$args_property.enum))')]"
                }

                $function_help_parameters += "`n"

                $type = $DataTypes_dict.Get_Item($args_property.type)
                if (! $type) {
                    $type = 'object'
                }

                $function_parameter += "[$type]"

                #add parameter
                $function_parameter += "`$$($parameter),`n"

                #create query argument
                $function_body += "`t`t`tif (`$$parameter){`n"
                $function_body += "`t`t`t`t`$queryArguments += '$i=' + `$$parameter`n"
                $function_body += "`t`t`t`t`$BoundParameters = `$BoundParameters.Remove('`$$parameter')`n"
                $function_body += "`t`t`t}`n"
                $pos += 1
            }
            
        }

        #smbshare bug with "properties"
        if ($item -eq "/1/protocols/smb/shares"){
            $directory_description.POST_input_schema | Add-Member -NotePropertyName properties -NotePropertyValue $directory_description.POST_input_schema.type.properties
        }

        if ($directory_description.PUT_input_schema.properties) { 

            $input_schemas = $directory_description.PUT_input_schema.properties         

            foreach ($i in ($input_schemas | Get-Member -MemberType *Property).name){
                
                $input_schema = $input_schemas.($i)

                $parameter = $i
                if ($input_properties_dict.ContainsKey($i)){
                    $parameter = $input_properties_dict.Get_Item($i)
                }

                if ($parameter_array -contains $parameter -or $args_properties_names -contains $parameter){
                    $parameter = "new_$i"
                    $function_body += "`t`t`tif (`$new_$i){`n"
                    $function_body += "`t`t`t`t`$BoundParameters.Remove('new_$i') | out-null`n"
                    $function_body += "`t`t`t`t`$BoundParameters.Add('$i',`$new_$i)`n"
                    $function_body += "`t`t`t}`n"
                }

                #bug bug bug...                
                if ($input_schema.type.type.type){
                    $input_schema = $input_schema.type.type

                }elseif ($input_schema.type.type){
                    $input_schema = $input_schema.type

                }

                #create help parameters
                $function_help_parameters += ".PARAMETER $($parameter)`n`t$($input_schema.description)`n"

                #create parameters

                $mandatory = 'False'
                ### MANDATORY
                if ($input_schema.required -eq 'True'){
                    $mandatory = 'True'
                }
                $function_parameter += "`t`t[Parameter(Mandatory=`$$mandatory,ValueFromPipelineByPropertyName=`$True,ValueFromPipeline=`$False,Position=$pos)]"
                

                if ($input_schema.enum -and ! $input_schema.enum -like '*DEFAULT*'){
                    $function_help_parameters += "`tValid inputs: $([String]::Join(',',$input_schema.enum))`n"
                    $function_parameter += "[ValidateSet('$([String]::Join(''',''',$input_schema.enum))')]"
                }

                $function_help_parameters += "`n"

                
                $type = $DataTypes_dict.Get_Item($input_schema.type)

                #bug bug
                if ($input_schemas.($i).type.type -and ! $input_schemas.($i).type.type.type ){
                    $type = $DataTypes_dict.Get_Item($input_schema.type[1])

                }

                if (! $type) {
                    $type = 'object'
                }

                $function_parameter += "[$type]"
                $function_parameter += "`$$($parameter),`n"

                $pos += 1
            }
            
        }

        #add force parameter
        $function_parameter += "`t`t[Parameter(Mandatory=`$False,ValueFromPipelineByPropertyName=`$False,ValueFromPipeline=`$False,Position=$pos)][switch]`$Force,`n"
        $function_help_parameters +=  ".PARAMETER Force`n`tForce update of object without prompt`n`n"
        $pos += 1

        #add cluster parameter
        $function_parameter += "`t`t[Parameter(Mandatory=`$False,ValueFromPipelineByPropertyName=`$True,ValueFromPipeline=`$False,Position=$pos)][ValidateNotNullOrEmpty()][string]`$Cluster"
        $function_help_parameters +=  ".PARAMETER Cluster`n`tName of Isilon Cluster`n"

        #add footer
        $function_help_footer = ".NOTES`n`n#>"
        $function_parameter_footer = "`n`t`t)"
        
            
            if ($directory_description.PUT_args.properties){
                $function_body += "`t`t`tif (`$queryArguments) {`n"
                $function_body += "`t`t`t`t`$queryArguments = '?' + [String]::Join('&',`$queryArguments)`n"
                $function_body += "`t`t`t}`n"
                 
                $function_body += "`t`t`tif (`$Force -or `$PSCmdlet.ShouldProcess(`"`$parameter1`",'$function_name')){`n"
                $function_body += "`t`t`t`t`$ISIObject = Send-isiAPI -Method PUT -Resource (`"$directory`" + `"`$queryArguments`") -body (convertto-json -depth 40 `$BoundParameters)  -Cluster `$Cluster`n"

            } else{
                $function_body += "`t`t`tif (`$Force -or `$PSCmdlet.ShouldProcess(`"`$parameter1`",'$function_name')){`n"
                $function_body += "`t`t`t`$ISIObject = Send-isiAPI -Method PUT -Resource `"$directory`" -body (convertto-json -depth 40 `$BoundParameters) -Cluster `$Cluster`n"

            }
            
            $function_body += "`t`t`t}`n"

            #remove total from output
            if ($directory_description.PUT_output_schema.properties.total){
                #Write-Host "`tRemoved 'total' from GET_output_schema" -ForegroundColor Cyan
                $directory_description.PUT_output_schema.properties.PSObject.Properties.Remove('total')
            }

            #remove count from output
            if ($directory_description.PUT_output_schema.properties.count){
                #Write-Host "`tRemoved 'count' from GET_output_schema" -ForegroundColor Cyan
                $directory_description.PUT_output_schema.properties.PSObject.Properties.Remove('count')
            }

            ##BUG misspelling of 'properties' as 'properites'
            if ($directory_description.PUT_output_schema.properties) {
                $output_properties = $directory_description.PUT_output_schema.properties | Get-Member -MemberType *Property
            }elseif ($directory_description.PUT_output_schema.properites) {
                Write-Host "`tPUT_output_schema.properties misspelled as properites" -ForegroundColor Cyan
                $output_properties = $directory_description.PUT_output_schema.properites | Get-Member -MemberType *Property
            }

            #remove resume from output
            if ($output_properties.name -like '*resume*') {
                $directory_description.PUT_output_schema.properties.PSObject.Properties.Remove('resume')
                $output_properties = $directory_description.PUT_output_schema.properties | Get-Member -MemberType *Property
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
                if ($Property_dict.ContainsKey("$function_name")){
                    Write-Host "`tPOST_output_schema.properties name misspelled or wrong" -ForegroundColor Cyan
                    $output_properties_name = $Property_dict.Get_Item("$function_name")
                }
                $function_body += "`t`t`t`$ISIObject.$($output_properties_name)`n"

            } else {
                $function_body += "`t`t`t`$ISIObject`n"
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
        $file_header = "directory;directory_new;describtion;function_name;synopsis;parameter1_name;parameter1a;parameter1b;parameter1_description;parameter2_name;parameter2a;parameter2b;parameter2_description"

        Add-Content $file $file_header

        foreach ($item in $directory_list) {
            <#
            if($item -like '*/2/*'){
                Write-Host "$item skipped" -ForegroundColor Red
                continue
            }#>

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

        $parameter1_found = $False
        $parameter2_found = $False       

        if ($directory -match '^([\/\w*\-*]*\/)<(\w*)\+*>([\/\w*\-*]*\/*)<*(\w*-*\w*)\+*>*'){
            $parameter1_name = $directory -replace '^([\/\w*\-*]*\/)<(\w*)\+*>([\/\w*\-*]*\/*)<*(\w*-*\w*)\+*>*','$2'
            $parameter2_name = $directory -replace '^([\/\w*\-*]*\/)<(\w*)\+*>([\/\w*\-*]*\/*)<*(\w*-*\w*)\+*>*','$4'
            $parameter1_found = $True

            if($parameter2_name){
                $directory = $directory -replace '^([\/\w*\-*]*\/)<(\w*)\+*>([\/\w*\-*]*\/*)<*(\w*-*\w*)\+*>*','$1$parameter1$3$parameter2'
                $item = $item -replace '^([\/\w*\-*]*\/)<(\w*)\+*>([\/\w*\-*]*\/*)<*(\w*-*\w*)\+*>*','$1X$2Y2'
                $parameter2_found = $True
            }else{
                $directory = $directory -replace '^([\/\w*\-*]*\/)<(\w*)\+*>','$1$parameter1'
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
        if ($parameter1_found){
            $parameter1_description = "$($parameter1_name.substring(0,1).toupper())$($parameter1_name.substring(1).tolower())"
            $parameter1a = 'id'
            $parameter1b = 'name'
        }
        if ($parameter2_found){
            $parameter2_description = "$($parameter2_name.substring(0,1).toupper())$($parameter2_name.substring(1).tolower())"
            $parameter2a = 'id2'
            $parameter2b = 'name2'
            $parameter2_pre = $parameter2_description.ToLower()
        }
        
        Add-Content $file "$directory_origin;$directory;$($directory_description.GET_args.description);isi$function_name;$synopsis;$parameter1_name;$parameter1a;$parameter1b;$parameter1_description;$parameter2_name;$($parameter2_pre)_$parameter2a;$($parameter2_pre)$parameter2b;$parameter2_description"

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
