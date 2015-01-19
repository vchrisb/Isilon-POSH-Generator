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
    Get Isilon SMB Shares
    
.DESCRIPTION
    Returns Isilon SMB Shares

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
    Get Isilon SMB Shares
    
.DESCRIPTION
    Returns Isilon SMB Shares

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
    Get Isilon SMB Shares
    
.DESCRIPTION
    Returns Isilon SMB Shares

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

            <#skip specifics
            if($item -like '*<*'){
                Write-Host "$item skipped" -ForegroundColor Red
                continue
            }
            #>
            #skip V2 API for now
            if($item -like '*/2/*'){
                Write-Host "$item skipped" -ForegroundColor Red
                continue
            }

            New-isiAPIdirectory -item $item -file $file

        }

}




function New-isiAPIdirectory{
<#
.SYNOPSIS
    Get Isilon SMB Shares
    
.DESCRIPTION
    Returns Isilon SMB Shares

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
        $Property_dict = @{ 'Get-isiSnapshotAliases' = 'aliases'; 'Get-isiAuthSettingsKrb5Domains' = 'domain'}
        $Child_dict = @{'jid' = 'id';'eid' = 'id';'qid' = 'id';'rid' = 'id';'nid' = 'id';'sid' = 'id';'tid' = 'id';'aid' = 'id'}
    }
    Process{

        Write-Host $item
        $directory = "/platform$($item)"     
        $directory_description = Get-isiAPIdescription -directory $directory

        #get child item
        $directory_child = Get-isiAPIdescription -directory $directory -child
        if ($directory_child){
            #if multiple childs get only first
            if ($directory_child.GetType().Name -eq 'Object[]') {
                $directory_child = $directory_child[0]
            }
            $directory_child = $directory_child | Select-String '^[\/\w*\-*]*\/<(\w*)\+*>$' | ForEach-Object { ($_.Matches.groups[1].value).tolower() }

            if ($directory_child -and $Child_dict.ContainsKey($directory_child)){
                $directory_child = $Child_dict.Get_Item($directory_child)
            }
        }
        #Write-Host $directory_child -ForegroundColor Yellow

##########        
########## GET
##########
    
        if (! $directory_description.GET_args) {
            return
        }


        $item_list = $item.Substring(3).Split('/') | ForEach-Object{ $_.Split('-')} | ForEach-Object {$_.substring(0,1).toupper() + $_.substring(1).tolower()}
        $function_name = [String]::Join('',$item_list)

        foreach ($replacement in $Replace_dict.Keys){
            if ($function_name -like "*$replacement*"){
                $function_name = $function_name.Replace($replacement,$Replace_dict.Get_Item($replacement))
            }
        }
        
### headers

        $function_header = "function Get-isi$($function_name){"

        $function_help_header =
"<#
.SYNOPSIS
    Get $([String]::Join(' ',$item_list))
    
.DESCRIPTION
    $($directory_description.GET_args.description)
"

        $function_parameter_header = "`t[CmdletBinding()]`n`t`tparam (`n"

        $function_body_header = "`tBegin{`n`t}`n`tProcess{`n"
        $function_body = ""
        $function_help_parameters = ""
        $function_parameter = ""
        $pos = 0

        if ($directory_description.GET_args.properties) {
            
            $function_body += "`t`t`t`$queryArguments = @()`n"
            
            foreach ($i in ($directory_description.GET_args.properties | Get-Member -MemberType *Property).name){
                #create help parameters
                $function_help_parameters += ".PARAMETER $($i)`n`t$($directory_description.GET_args.properties.($i).description)`n"

                #create parameters
                $function_parameter += "`t`t[Parameter(Mandatory=`$False,ValueFromPipelineByPropertyName=`$True,ValueFromPipeline=`$False,Position=$pos)][ValidateNotNullOrEmpty()]"
                

                if ($directory_description.GET_args.properties.($i).enum){
                    $function_help_parameters += "`tValid inputs: $([String]::Join(',',$directory_description.GET_args.properties.($i).enum))`n"
                    $function_parameter += "[ValidateSet('$([String]::Join(''',''',$directory_description.GET_args.properties.($i).enum))')]"
                }

                $function_help_parameters += "`n"


                $function_parameter += "[$($DataTypes_dict.Get_Item($directory_description.GET_args.properties.($i).type))]"
                $function_parameter += "`$$($i),`n"

                $function_body += "`t`t`tif (`$$i){`n"
                $function_body += "`t`t`t`t`$queryArguments += '$i=' + `$$i`n"
                $function_body += "`t`t`t}`n"
                $pos += 1
            }

            #add resume token parameter
            if ($directory_description.GET_args.properties.resume) {

                $function_help_parameters += ".PARAMETER resumeToken`n`tIf using the parameter 'limit' enter a variable name without the dollar sign ($) to save the resume token`n"

                $function_parameter += "`t`t[Parameter(Mandatory=`$False,ValueFromPipelineByPropertyName=`$True,ValueFromPipeline=`$False,Position=$pos)][ValidateNotNullOrEmpty()]"                
                $function_help_parameters += "`n"


                $function_parameter += "[string]"
                $function_parameter += "`$resumeToken,`n"

                $pos += 1
            }

            
            
        }

        $function_parameter += "`t`t[Parameter(Mandatory=`$False,ValueFromPipelineByPropertyName=`$True,ValueFromPipeline=`$False,Position=$pos)][ValidateNotNullOrEmpty()][string]`$Cluster"
        $function_help_parameters +=  ".PARAMETER Cluster`n`tName of Isilon Cluster`n"

        $function_help_footer = ".NOTES`n`n#>"

        $function_parameter_footer = "`n`n)"
        


        #if no output schena return plain JSON
        if(! $directory_description.GET_output_schema){
            Write-Host "`tNo GET_output_schema fallback to JSON" -ForegroundColor Cyan
            $function_body += "`t`t`t`$ISIObject = Send-isiAPI -Method GET_JSON -Resource '$($directory)'`n"
            $function_body += "`t`t`t`$ISIObject`n"

        }else{
            
            if ($directory_description.GET_args.properties){
                $function_body += "`t`t`tif (`$queryArguments) {`n"
                $function_body += "`t`t`t`t`$queryArguments = '?' + [String]::Join('&',`$queryArguments)`n"
                $function_body += "`t`t`t}`n" 
                $function_body += "`t`t`t`$ISIObject = Send-isiAPI -Method GET -Resource ('$directory' + `"`$queryArguments`")`n"

            } else{
                $function_body += "`t`t`t`$ISIObject = Send-isiAPI -Method GET -Resource '$directory' `n"

            }
            
            #remove total
            if ($directory_description.GET_output_schema.properties.total){
                #Write-Host "`tRemoved 'total' from GET_output_schema" -ForegroundColor Cyan
                $directory_description.GET_output_schema.properties.PSObject.Properties.Remove('total')
            }

            #remove count
            if ($directory_description.GET_output_schema.properties.count){
                #Write-Host "`tRemoved 'count' from GET_output_schema" -ForegroundColor Cyan
                $directory_description.GET_output_schema.properties.PSObject.Properties.Remove('count')
            }

            #BUG misspelling of 'properties' as 'properites'
            if ($directory_description.GET_output_schema.properties) {
                $output_properties = $directory_description.GET_output_schema.properties | Get-Member -MemberType *Property
            }elseif ($directory_description.GET_output_schema.properites) {
                Write-Host "`tGET_output_schema.properties misspelled as properites" -ForegroundColor Cyan
                $output_properties = $directory_description.GET_output_schema.properites | Get-Member -MemberType *Property
            }
            #BUG remove 'resume' from GET_output_schema if not in properties
            if (! $item.GET_args.properties -and $output_properties.name -like '*resume*') {
                Write-Host "`tRemoved 'resume' from GET_output_schema because GET_args.properties does not include this property " -ForegroundColor Cyan
                $directory_description.GET_output_schema.properties.PSObject.Properties.Remove('resume')
                $output_properties = $directory_description.GET_output_schema.properties | Get-Member -MemberType *Property
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
        $function_body_footer =
"    }
    End{
    }"

        $function_footer =
"}

Export-ModuleMember -Function Get-isi$($function_name)`n"
        
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
    Get Isilon SMB Shares
    
.DESCRIPTION
    Returns Isilon SMB Shares

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

function Test-variablepass {
	param (
    [Parameter(Mandatory=$True,ValueFromPipelineByPropertyName=$True,ValueFromPipeline=$True,Position=0)][string]$resumevar)

        Set-Variable -Name $resumevar -scope global -Value 'test'

}

Export-ModuleMember -Function Get-isiAPIdirectory
Export-ModuleMember -Function Get-isiAPIdescription
Export-ModuleMember -Function New-isiAPI
Export-ModuleMember -Function New-isiAPIdirectory
Export-ModuleMember -Function Test-isiAPI
Export-ModuleMember -Function Test-variablepass