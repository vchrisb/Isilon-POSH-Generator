# The MIT License
#
# Copyright (c) 2016 Christopher Banck.
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
        [Parameter(Mandatory=$True,ValueFromPipelineByPropertyName=$False,ValueFromPipeline=$False,Position=1)][string]$dictionary,
        [Parameter(Mandatory=$True,ValueFromPipelineByPropertyName=$False,ValueFromPipeline=$False,Position=2)][ValidateSet('Get','Remove','Set','New', 'List')][string]$method,
        [Parameter(Mandatory=$True,ValueFromPipelineByPropertyName=$False,ValueFromPipeline=$False,Position=3)][int]$leading_api
    )

        if(Test-Path -Path $file){
            Remove-Item $file
        }

        $directory_list = Get-isiAPIdirectory
        $onefs_build = (Send-isiAPI -Method GET -Resource "/platform/1/cluster/config").onefs_version.build

        $file_header =
'# The MIT License
#
# Copyright (c) 2016 Christopher Banck.
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
                Get { 
                    #New-isiAPIdirectoryGET -item $item -file $file -dictionary $dictionary -leading_api $leading_api 
                    New-isiAPIdirectory -item $item -method Get -file $file -dictionary $dictionary -leading_api $leading_api 
                }
                Remove {
                    #New-isiAPIdirectoryREMOVE -item $item -file $file -dictionary $dictionary -leading_api $leading_api
                    New-isiAPIdirectory -item $item -method Remove -file $file -dictionary $dictionary -leading_api $leading_api
                }
                New { 
                    #New-isiAPIdirectoryNEW -item $item -file $file -dictionary $dictionary -leading_api $leading_api 
                    New-isiAPIdirectory -item $item -method New -file $file -dictionary $dictionary -leading_api $leading_api 
                }
                Set { 
                    #New-isiAPIdirectorySET -item $item -file $file -dictionary $dictionary -leading_api $leading_api 
                    New-isiAPIdirectory -item $item -method Set -file $file -dictionary $dictionary -leading_api $leading_api 
                }
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

function New-isiAPIdirectory{
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
        [Parameter(Mandatory=$True,ValueFromPipelineByPropertyName=$False,ValueFromPipeline=$False,Position=1)][ValidateSet('Get','Remove','Set','New')][string]$method,
        [Parameter(Mandatory=$True,ValueFromPipelineByPropertyName=$False,ValueFromPipeline=$False,Position=2)][string]$file,
        [Parameter(Mandatory=$True,ValueFromPipelineByPropertyName=$False,ValueFromPipeline=$False,Position=3)][string]$dictionary,
        [Parameter(Mandatory=$True,ValueFromPipelineByPropertyName=$False,ValueFromPipeline=$False,Position=4)][int]$leading_api
    )

    Begin{
        #import item inforamtion from dictionary
        $dictionary_item = Import-Csv -Path $dictionary -Delimiter ';' | where directory -eq $item

        if (!$dictionary_item){
            Write-Host "$item not in CSV" -ForegroundColor Red
            break
        }

        $DataTypes_dict = @{ 'boolean' = 'bool'; 'integer' = 'int'; 'string' = 'string'; 'array' = 'array'}
        $Property_dict = @{ "$method-isiSnapshotAliases" = 'aliases'; "$method-isiAuthSettingsKrb5Domains" = 'domain'; "$method-isiFilesystemAccessTime" = 'access_time'; "$method-isiNetworkInterfaces" = 'interfaces'}
        
        # for Set
        $arg_properties_dict = @{'force' = 'enforce'; 'zone' = 'access_zone' ; 'channel`' = 'channel'}
        $input_properties_dict = @{'current-encoding' = 'current_encoding'}
        $parameter_array = ($dictionary_item.parameter1a,$dictionary_item.parameter1b,$dictionary_item.parameter2a,$dictionary_item.parameter1b)

        $method_dict = @{'Get' = 'GET'; 'Remove' = 'DELETE'; 'Set' = 'PUT'; 'New' = 'POST'}
        $method_json = $method_dict.Get_Item($method)

        $method_args = "$($method_json)_args"
        $method_ouput_schema = "$($method_json)_output_schema"
        $method_input_schema = "$($method_json)_input_schema"
    }
    Process{


        # load modified API directory
        $directory = $dictionary_item.directory_new

        # get api information
        $api = $dictionary_item.api_version -as [int]
        $api_versions = (Import-Csv -Path $dictionary -Delimiter ';' | where directory_noapi -eq $item.Substring(2)).api_version
        $api_highest = ($api_versions | measure -Maximum).Maximum
        $api_count = $api_versions.Count
        
        # add the api version to function if there are multiple api versions for directory
        if ($api_count -eq 1) {
            $function_name = "$method-" + $dictionary_item.function_name
        }else{
            $function_name = "$method-" + $dictionary_item.function_name + "v$api"
        }

        # load infornation
        $synopsis = $dictionary_item.synopsis
        $parameter1 = $dictionary_item.parameter1_name
        $parameter1_description = $dictionary_item.parameter1_description
        $parameter2 = $dictionary_item.parameter2_name
        $parameter2_description = $dictionary_item.parameter2_description
        
        # get the API description for specified directory
        $directory_description = Get-isiAPIdescription -directory "/platform/$item"

        
        if (! $directory_description.($method_args)) {
            Write-Verbose "$item does not have any args - skipping"
            break

        }
        Write-Host "$item - $method $synopsis - $function_name"

           
### headers

        $function_header = "function $function_name{"

        if (("Set", "New") -contains $method){
            $function_body = "`t`t`t`$BoundParameters = `$PSBoundParameters`n"
            $function_body += "`t`t`t`$BoundParameters.Remove('Cluster') | out-null`n"

        }

        if (("Set", "Remove") -contains $method){
            $function_parameter_header = "`t[CmdletBinding(SupportsShouldProcess=`$True,ConfirmImpact='High'"
        } elseif (("New") -contains $method) {
            $function_parameter_header = "`t[CmdletBinding("
        } else {
            $function_parameter_header = "`t[CmdletBinding("
            $function_body = ""
        }

        $function_help_header = "<#`n.SYNOPSIS`n`t$method $synopsis`n`n.DESCRIPTION`n`t$($directory_description.($method_args).description)`n"
        $function_body_header = "`tBegin{`n`t}`n`tProcess{`n"
        $function_help_parameters = ""
        $function_parameter = ""
        $pos = 0

        if ($parameter1) {
                
                # if parameter 1a is like *id* set parameter type to int else to string
                #if ($dictionary_item.parameter1a -like '*id*'){
                #    $parameter1a_type = 'int'
                #}else{
                #    $parameter1a_type = 'string'
                #}
                $parameter1a_type = 'string'

                $function_help_parameters += ".PARAMETER $($dictionary_item.parameter1a)`n`t$parameter1_description $($dictionary_item.parameter1a)`n`n"
                $function_parameter += "`t`t[Parameter(Mandatory=`$True,ValueFromPipelineByPropertyName=`$True,ValueFromPipeline=`$True,Position=$pos,ParameterSetName='ByID')][ValidateNotNullOrEmpty()][$parameter1a_type]`$$($dictionary_item.parameter1a),`n"               
                if ($dictionary_item.parameter1b){
                    $function_help_parameters += ".PARAMETER $($dictionary_item.parameter1b)`n`t$parameter1_description $($dictionary_item.parameter1b)`n`n"
                    $function_parameter += "`t`t[Parameter(Mandatory=`$True,ValueFromPipelineByPropertyName=`$True,ValueFromPipeline=`$True,Position=$pos,ParameterSetName='ByName')][ValidateNotNullOrEmpty()][string]`$$($dictionary_item.parameter1b),`n"
                }
                if (("Set", "Remove") -contains $method){
                    $function_parameter_header += ",DefaultParametersetName='ByID'"
                }else { # ("New", "Get")
                    $function_parameter_header += "DefaultParametersetName='ByID'"
                }
                $pos += 1
        }

        if ($parameter2) {
                
                # if parameter 2a is like *id* set parameter type to int else to string
                #if ($dictionary_item.parameter2a -like '*id*'){
                #    $parameter2a_type = 'int'
                #}else{
                #    $parameter2a_type = 'string'
                #}
                $parameter2a_type = 'string'

                # if parameter2b exists, add ParameterSet
                #if ($dictionary_item.parameter2b){
                #    $paramterset2a = ",ParameterSetName='ByName'"
                #}else{
                #    $paramterset2a = ""
                #}
                
                $paramterset2a = ",ParameterSetName='ByID'"

                $function_help_parameters += ".PARAMETER $($dictionary_item.parameter2a)`n`t$id2_description $($dictionary_item.parameter2a)`n`n"
                $function_parameter += "`t`t[Parameter(Mandatory=`$True,ValueFromPipelineByPropertyName=`$True,ValueFromPipeline=`$True,Position=$pos$paramterset2a)][ValidateNotNullOrEmpty()][$parameter2a_type]`$$($dictionary_item.parameter2a),`n"                
                if ($dictionary_item.parameter2b){
                    $function_help_parameters += ".PARAMETER $($dictionary_item.parameter2b)`n`t$id2_description $($dictionary_item.parameter2b)`n`n"
                    $function_parameter += "`t`t[Parameter(Mandatory=`$True,ValueFromPipelineByPropertyName=`$True,ValueFromPipeline=`$True,Position=$pos,ParameterSetName='ByName')][ValidateNotNullOrEmpty()][string]`$$($dictionary_item.parameter2b),`n"                
                }

                $pos += 1
        }

        $function_parameter_header += ")]`n`t`tparam (`n"


        ### dictinary parameters
        if (("Set", "New") -contains $method){
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
        } else{
        
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
        }

        # parameters
        if (("Set", "New") -contains $method){
            #smbshare bug with "properties"
            if ($item -like "*/protocols/smb/shares"){
                $directory_description.($method_input_schema) | Add-Member -NotePropertyName properties -NotePropertyValue $directory_description.($method_input_schema).type.properties
            }

            if ($function_name -eq 'Set-isiAuditSettingsGlobalv1'){
                Write-Host $function_name
            }

            if ($directory_description.($method_input_schema).properties) { 

                $input_schemas = $directory_description.($method_input_schema).properties.PsObject.Copy()

                foreach ($i in ($input_schemas | Get-Member -MemberType *Property).name){
                
                    $input_schema = $input_schemas.($i).PsObject.Copy()

                    # fixing nested types  
                    if ($input_schema.type.type.type){
                        $input_schema = $input_schema.type.type[1].PsObject.Copy()
                        Write-Verbose ("Line " + (Get-CurrentLineNumber) + ": Fixing for $i `$input_schema.type.type.type to `$input_schema.type.type")

                    }elseif ($input_schema.type.type -and -not $input_schema.description ){
                        if ($input_schema.type[0].description) {
                            $input_schema = $input_schema.type[0].PsObject.Copy()
                        } else {
                            $input_schema = $input_schema.type[1].PsObject.Copy()
                        }
                        Write-Verbose ("Line " + (Get-CurrentLineNumber) + ": Fixing for $i `$input_schema.type.type to `$input_schema.type")

                    }

                    $parameter = $i
                    if ($input_properties_dict.ContainsKey($i)){
                        $parameter = $input_properties_dict.Get_Item($i)
                    }

                    if ($parameter_array -contains $parameter){
                        $parameter = "new_$i"
                        $function_body += "`t`t`tif (`$new_$i){`n"
                        $function_body += "`t`t`t`t`$BoundParameters.Remove('new_$i') | out-null`n"
                        $function_body += "`t`t`t`t`$BoundParameters.Add('$i',`$new_$i)`n"
                        $function_body += "`t`t`t}`n"
                    }

                    ### DEBUG
                    #if ($function_name -eq "Set-isiAuthProviderAdsv1" -and $i -eq "allocate_gids") {
                    #    Write-Verbose (Get-CurrentLineNumber)
                    #}


                    #create help parameters
                    $function_help_parameters += ".PARAMETER $($parameter)`n`t$($input_schema.description)`n"

                    #create parameters

                    $mandatory = 'False'
                    ### MANDATORY
                    if ($input_schema.required -eq 'True'){
                        $mandatory = 'True'
                    }
                    $function_parameter += "`t`t[Parameter(Mandatory=`$$mandatory,ValueFromPipelineByPropertyName=`$True,ValueFromPipeline=`$False,Position=$pos)]"

                    #if ($input_schema.enum -and ! $input_schema.enum -like '*DEFAULT*'){
                    if (Get-Member -InputObject $input_schema -Name 'enum'){
                        $function_help_parameters += "`tValid inputs: $([String]::Join(',',$input_schema.enum))`n"
                        $function_parameter += "[ValidateSet('$([String]::Join(''',''',$input_schema.enum))')]"
                    }

                    $function_help_parameters += "`n"


                    if ($input_schema.type -is [array] -and $input_schema.type[1] -eq 'null'){
                        $input_schema.type[1] = $input_schema.type[0]
                        Write-Verbose ("Line " + (Get-CurrentLineNumber) + ": Fixing BUG for `"type`" being an array and second value is `"null`"")
                    }

                
                    $type = $DataTypes_dict.Get_Item($input_schema.type)

                    #bug for Method SET 
                    if ($input_schemas.($i).type.type -and -not $input_schemas.($i).type.type.type -and -not $input_schemas.($i).description -and $input_schema.type -is [array] ){
                        $type = $DataTypes_dict.Get_Item($input_schema.type[1])
                        Write-Verbose ("Line " + (Get-CurrentLineNumber) + ": Fixing BUG for nested `"type`" and being an array")

                    }elseif ($input_schema.type -is [array]){
                        $type = $DataTypes_dict.Get_Item($input_schema.type[0])
                        Write-Verbose ("Line " + (Get-CurrentLineNumber) + ": Fixing BUG `$input_schema.type being an array")
                    }

                    if (! $type) {
                        $type = 'object'
                    }

                    $function_parameter += "[$type]"
                    $function_parameter += "`$$($parameter),`n"

                    $pos += 1
                }
            
            }
            if (("Set") -contains $method){
                #add force parameter
                $function_parameter += "`t`t[Parameter(Mandatory=`$False,ValueFromPipelineByPropertyName=`$False,ValueFromPipeline=`$False,Position=$pos)][switch]`$Force,`n"
                if (("Set") -contains $method){
                    $function_help_parameters +=  ".PARAMETER Force`n`tForce update of object without prompt`n`n"
                }else{
                    $function_help_parameters +=  ".PARAMETER Force`n`tForce deletion of object without prompt`n`n"
                }
                $pos += 1
            }
        }

        #### Query Arguments

        if ($directory_description.($method_args).properties) {
            
            $args_properties = $directory_description.($method_args).properties
            $args_properties_names = ($args_properties | Get-Member -MemberType *Property).name
            
            $function_body += "`t`t`t`$queryArguments = @()`n"
            
            foreach ($i in $args_properties_names){
                
                #create help parameters and replace if necessary
                $parameter = $i
                if ($arg_properties_dict.ContainsKey($i)){
                    $parameter = $arg_properties_dict.Get_Item($i)
                }
                
                $args_property = $args_properties.($i)

                #create help parameters
                $function_help_parameters += ".PARAMETER $($parameter)`n`t$($args_property.description)`n"
                #$function_help_parameters += "`tThis parameter is a query argument."
                #$function_help_parameters += "`n"

                $mandatory = 'False'
                ### MANDATORY
                if ($args_property.required -eq 'True'){
                    $mandatory = 'True'
                }

                #create parameter option
                $function_parameter += "`t`t[Parameter(Mandatory=`$$mandatory,ValueFromPipelineByPropertyName=`$True,ValueFromPipeline=`$False,Position=$pos)][ValidateNotNullOrEmpty()]"
                
                #test for ValidateSet
                if (Get-Member -InputObject $args_property -Name 'enum'){
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

                # channel bug
                if ( $i -eq  'channel`'){
                    $i = 'channel'
                }

                #create query argument
                $function_body += "`t`t`tif (`$$parameter){`n"
                $function_body += "`t`t`t`t`$queryArguments += '$i=' + `$$parameter`n"
                if (("Set", "New") -contains $method){
                    $function_body += "`t`t`t`t`$BoundParameters.Remove('$parameter') | out-null`n"
                }
                $function_body += "`t`t`t}`n"
                $pos += 1
            }
            
        }
        

        if (("Remove") -contains $method){
            $function_parameter += "`t`t[Parameter(Mandatory=`$False,ValueFromPipelineByPropertyName=`$False,ValueFromPipeline=`$False,Position=$pos)][switch]`$Force,`n"
            $function_help_parameters +=  ".PARAMETER Force`n`tForce deletion of object without prompt`n`n"
            $pos += 1
        }

        #add cluster parameter
        $function_parameter += "`t`t[Parameter(Mandatory=`$False,ValueFromPipelineByPropertyName=`$True,ValueFromPipeline=`$False,Position=$pos)][ValidateNotNullOrEmpty()][string]`$Cluster"
        $function_help_parameters +=  ".PARAMETER Cluster`n`tName of Isilon Cluster`n"

        #add footer
        $function_help_footer = ".NOTES`n`n#>"
        $function_parameter_footer = "`n`t`t)"
        

        #if no Get output schema return plain JSON
        if(-Not $directory_description.($method_ouput_schema) -and $method -eq "Get"){
            Write-Host "`tNo $method_ouput_schema fallback to JSON" -ForegroundColor Cyan
            $function_body += "`t`t`t`$ISIObject = Send-isiAPI -Method GET_JSON -Resource `"$directory`" -Cluster `$Cluster`n"
            $function_body += "`t`t`treturn `$ISIObject`n"

        }else{
            
            if ($directory_description.($method_args).properties){
                $function_body += "`t`t`tif (`$queryArguments) {`n"
                $function_body += "`t`t`t`t`$queryArguments = '?' + [String]::Join('&',`$queryArguments)`n"
                $function_body += "`t`t`t}`n"
                $resource = "(`"$directory`" + `"`$queryArguments`")"
            } else {
                $resource = "`"$directory`""
            }

            if (("Set") -contains $method){
                $function_body += "`t`t`tif (`$Force -or `$PSCmdlet.ShouldProcess(`"`$parameter1`",'$function_name')){`n"
                $function_body += "`t`t`t`t`$ISIObject = Send-isiAPI -Method $method_json -Resource $resource -body (convertto-json -depth 40 `$BoundParameters) -Cluster `$Cluster`n"
                $function_body += "`t`t`t}`n"

            }elseif (("New") -contains $method){
                $function_body += "`t`t`t`$ISIObject = Send-isiAPI -Method $method_json -Resource $resource -body (convertto-json -depth 40 `$BoundParameters) -Cluster `$Cluster`n"

            }elseif (("Remove") -contains $method){
                $function_body += "`t`t`tif (`$Force -or `$PSCmdlet.ShouldProcess(`"`$parameter1`",'$function_name')){`n"
                $function_body += "`t`t`t`t`$ISIObject = Send-isiAPI -Method $method_json -Resource $resource -Cluster `$Cluster`n"
                $function_body += "`t`t`t}`n"
            } else{
                $function_body += "`t`t`t`$ISIObject = Send-isiAPI -Method $method_json -Resource $resource -Cluster `$Cluster`n"
            }                

            
            #remove total from output
            if ($directory_description.($method_ouput_schema).properties.total){
                #Write-Host "`tRemoved 'total' from GET_output_schema" -ForegroundColor Cyan
                $directory_description.($method_ouput_schema).properties.PSObject.Properties.Remove('total')
            }

            #remove count from output
            if ($directory_description.($method_ouput_schema).properties.count){
                #Write-Host "`tRemoved 'count' from GET_output_schema" -ForegroundColor Cyan
                $directory_description.($method_ouput_schema).properties.PSObject.Properties.Remove('count')
            }

            ##BUG misspelling of 'properties' as 'properites'
            if ($directory_description.($method_ouput_schema).properties) {
                $output_properties = $directory_description.($method_ouput_schema).properties | Get-Member -MemberType *Property
            }elseif ($directory_description.($method_ouput_schema).properites) {
                Write-Host "`t$method_ouput_schema.properties misspelled as properites" -ForegroundColor Cyan
                $output_properties = $directory_description.($method_ouput_schema).properites | Get-Member -MemberType *Property
            }

            #remove resume from output
            if ($output_properties.name -like '*resume*') {
                $directory_description.($method_ouput_schema).properties.PSObject.Properties.Remove('resume')
                $output_properties = $directory_description.($method_ouput_schema).properties | Get-Member -MemberType *Property
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
                    Write-Host "`t$method_ouput_schema.properties name misspelled or wrong" -ForegroundColor Cyan
                    $output_properties_name = $Property_dict.Get_Item("$function_name")
                }

                $output_object = ".$($output_properties_name)"

            } else {
                $output_object = ''
            }

            # return resume token if necessary with Get
            if ($directory_description.($method_args).properties.resume -and $method -eq "Get") {
                $function_body += "`t`t`tif (`$ISIObject.PSObject.Properties['resume'] -and (`$resume -or `$limit)){`n"
                $function_body += "`t`t`t`treturn `$ISIObject$output_object,`$ISIObject.resume`n"
                $function_body += "`t`t`t}else{`n"
                $function_body += "`t`t`t`treturn `$ISIObject$output_object`n"
                $function_body += "`t`t`t}`n"
            }elseif (("Set", "New", "Get") -contains $method) {
                $function_body += "`t`t`treturn `$ISIObject$output_object`n"
            }
            
        }
        $function_body_footer = "`t}`n`tEnd{`n`t}"

        $function_footer = "}`n`nExport-ModuleMember -Function $function_name`n"

        $alias_canidates = ($api_versions -gt $api) -le $leading_api
        if ($api_count -gt 1){
            if ($api -eq $leading_api -or (-not $alias_canidates -and $api -lt $leading_api)){
                #Write-Host "Api: $api Highest: $api_highest" -ForegroundColor Green
                $function_footer += "Set-Alias " + "$method-" + $dictionary_item.function_name + " -Value $function_name`n"
                $function_footer += "Export-ModuleMember -Alias $method-" + $dictionary_item.function_name +"`n"

            }
        }

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
        [Parameter(Mandatory=$True,ValueFromPipelineByPropertyName=$False,ValueFromPipeline=$False,Position=0)][string]$file,
        [Parameter(Mandatory=$False,ValueFromPipelineByPropertyName=$False,ValueFromPipeline=$False,Position=1)][string]$fileToCompare
    )

        if(Test-Path -Path $file){
            Remove-Item $file
        }

        if ($fileToCompare) {
            $dictionary = Import-Csv -Path $fileToCompare -Delimiter ';'
        }

        $directory_list = Get-isiAPIdirectory
        $file_header = "directory;directory_new;api_version;directory_noapi;describtion;function_name;synopsis;parameter1_name;parameter1a;parameter1b;parameter1_description;parameter2_name;parameter2a;parameter2b;parameter2_description"

        Add-Content $file $file_header

        foreach ($item in $directory_list) {
            <#
            if($item -like '*/2/*'){
                Write-Host "$item skipped" -ForegroundColor Red
                continue
            }#>
            if ($dictionary) {
                $dictionary_item = $dictionary | where directory -eq $item
                if (!$dictionary_item) {
                    New-isiAPIdirectoryCSV -item $item -file $file
                    Write-Host "$item not in existing csv - adding"
                } else {
                    Write-Host "$item in existing csv - skipping" -ForegroundColor Cyan
                }
            } else {
                New-isiAPIdirectoryCSV -item $item -file $file
            }

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
            $parameter1_name = $directory -replace '^([\/\w*\-*]*\/)<(\w*)\+*>([\/\w*\-*]*\/*)<*(\w*-*\w*)\+*>*([\/\w*\-*]*\/*)','$2'
            $parameter2_name = $directory -replace '^([\/\w*\-*]*\/)<(\w*)\+*>([\/\w*\-*]*\/*)<*(\w*-*\w*)\+*>*([\/\w*\-*]*\/*)','$4'
            $parameter1_found = $True

            if($parameter2_name){
                $directory = $directory -replace '^([\/\w*\-*]*\/)<(\w*)\+*>([\/\w*\-*]*\/*)<*(\w*-*\w*)\+*>*([\/\w*\-*]*\/*)','$1$parameter1$3$parameter2'
                $item = $item -replace '^([\/\w*\-*]*\/)<(\w*)\+*>([\/\w*\-*]*\/*)<*(\w*-*\w*)\+*>*([\/\w*\-*]*\/*)','$1XX$3YY$5'
                $parameter2_found = $True
            }else{
                $directory = $directory -replace '^([\/\w*\-*]*\/)<(\w*)\+*>','$1$parameter1'
                $item = $item -replace '^([\/\w*\-*]*\/)<(\w*)\+*>','$1XX'
            }
            $item = $item -replace '^([\/\w*\-*]*\/)<(\w*)\+*>','$1XX'
            $item = $item -replace '(ies\/XX)','y'
            $item = $item -replace '([^s])(s\/XX)','$1'
            $item = $item -replace '(\/XX)',''

            $item = $item -replace '^([\/\w*\-*]*\/)<(\w*)\+*>','$1YY'
            $item = $item -replace '(ies\/YY)','y'
            $item = $item -replace '([^s])(s\/YY)','$1'
            $item = $item -replace '(\/YY)',''
            
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
            $parameter2_pre = $parameter2_description.ToLower() -replace '(-)',''

        }

        $description = $directory_description.GET_args.description
        if (!$description){
            $description = $directory_description.POST_args.description
        }
        if (!$description){
            $description = $directory_description.PUT_args.description
        }

        $api = $directory_origin.Substring(1,1)
        $directory_noapi = $directory_origin.Substring(2)

        Add-Content $file "$directory_origin;$directory;$api;$directory_noapi;$description;isi$function_name;$synopsis;$parameter1_name;$parameter1a;$parameter1b;$parameter1_description;$parameter2_name;$($parameter2_pre)$parameter2a;$($parameter2_pre)$parameter2b;$parameter2_description"

    }
    End{

    }
	
}

function Get-CurrentLineNumber { 
    $MyInvocation.ScriptLineNumber 
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
