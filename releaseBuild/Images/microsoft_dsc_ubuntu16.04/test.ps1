[cmdletbinding(DefaultParameterSetName='default')]
# PowerShell Script to clone, build and package PowerShell from specified fork and branch
param (
    [string] $input = 'hello-dsc'
)

Write-Verbose "input param : $input"

