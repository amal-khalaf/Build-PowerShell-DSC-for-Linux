[cmdletbinding(DefaultParameterSetName='Build')]
param(
    [Parameter(ParameterSetName='packageSigned')]
    [Parameter(ParameterSetName='Build')]
    [ValidatePattern("^v\d+\.\d+\.\d+(-\w+(\.\d+)?)?$")]
    [string]$ReleaseTag,

    # full paths to files to add to container to run the build
    [Parameter(Mandatory,ParameterSetName='packageSigned')]
    [string]
    $BuildPath,

    [Parameter(Mandatory,ParameterSetName='packageSigned')]
    [string]
    $SignedFilesPath
)

DynamicParam {
    # Add a dynamic parameter '-Name' which specifies the name of the build to run

    # Get the names of the builds.
    $buildJsonPath = (Join-Path -path $PSScriptRoot -ChildPath 'build.json')
    $build = Get-Content -Path $buildJsonPath | ConvertFrom-Json
    $names = @($build.Windows.Name)
    foreach($name in $build.Linux.Name)
    {
        $names += $name
    }

    # Create the parameter attributs
    $ParameterAttr = New-Object "System.Management.Automation.ParameterAttribute"
    $ValidateSetAttr = New-Object "System.Management.Automation.ValidateSetAttribute" -ArgumentList $names
    $Attributes = New-Object "System.Collections.ObjectModel.Collection``1[System.Attribute]"
    $Attributes.Add($ParameterAttr) > $null
    $Attributes.Add($ValidateSetAttr) > $null

    # Create the parameter
    $Parameter = New-Object "System.Management.Automation.RuntimeDefinedParameter" -ArgumentList ("Name", [string], $Attributes)
    $Dict = New-Object "System.Management.Automation.RuntimeDefinedParameterDictionary"
    $Dict.Add("Name", $Parameter) > $null
    return $Dict
}

Begin {
    $Name = $PSBoundParameters['Name']
}

End {
    $ErrorActionPreference = 'Stop'

    $additionalFiles = @()
    $buildPackageName = $null
    # If specified, Add package file to container
    if ($BuildPath)
    {
        Import-Module (Join-Path -path $PSScriptRoot -childpath '..\..\build.psm1')
        Import-Module (Join-Path -path $PSScriptRoot -childpath '..\packaging')

        # Use temp as destination if not running in VSTS
        $destFolder = $env:temp
        if($env:BUILD_STAGINGDIRECTORY)
        {
            # Use artifact staging if running in VSTS
            $destFolder = $env:BUILD_STAGINGDIRECTORY
        }

        $BuildPackagePath = New-PSSignedBuildZip -BuildPath $BuildPath -SignedFilesPath $SignedFilesPath -DestinationFolder $destFolder
        Write-Host "##vso[artifact.upload containerfolder=results;artifactname=$name-singed.zip]$BuildPackagePath"
        $buildPackageName = Split-Path -Path $BuildPackagePath -Leaf
        $additionalFiles += $BuildPackagePath
    }
    
    $unresolvedRepoRoot = Join-Path -Path $PSScriptRoot '..'
    $resolvedRepoRoot = (Resolve-Path -Path $unresolvedRepoRoot).ProviderPath

    try
    {
        Write-Verbose "Starting build at $PSScriptRoot " -Verbose
        Import-Module "$PSScriptRoot/vstsBuild" -Force
        Import-Module "$PSScriptRoot/dockerBasedBuild" -Force
        Clear-VstsTaskState

        $buildParameters = @{
            ReleaseTag = $ReleaseTag
            BuildPackageName = $buildPackageName
        }

        Invoke-Build -RepoPath $resolvedRepoRoot -BuildJsonPath './releaseBuild/build.json' -Name $Name -Parameters $buildParameters -AdditionalFiles $AdditionalFiles
    }
    catch
    {
        Write-VstsError -Error $_
    }
    finally{
        Write-VstsTaskState
        exit 0
    }
}