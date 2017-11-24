<#
.SYNOPSIS
    Clones a template perspective and then reassigns the clone to match the specified SCOM object

.DESCRIPTION
    Sample script that shows how to clone a template perspective and then reassigns the clone to match the specified SCOM object

.PARAMETER Id
    The SCOM object Id that the resulting perspective should display against.

.PARAMETER TemplatePath
    Filepath to a .json file which contains a perspective to be cloned.

.PARAMETER OutputPath
    Filepath to a .json file where the resulting JSON should be stored.

.EXAMPLE
    PS > .\Clone-SquaredUpDashboard.ps1 -Id fd1f48fe-b606-4d19-9872-f3f71bfc7069 -TemplatePath .\template.json -OutputPath c:\inetpub\wwwroot\SquaredUpv3\User\Packages\Everyone\Perspectives\opp.json

    Clones the template perspective stored in template.json and the outputs a new perspective in the Everyone pack, modifying the targeting to match a specific SCOM object with Id fd1f48fe-b606-4d19-9872-f3f71bfc7069.

.NOTES 
    Copyright 2017 Squared Up Limited, All Rights Reserved.
.LINK
    https://www.squaredup.com
.LINK
    https://github.com/squaredup
#>
[cmdletbinding()]
param(
    [Parameter(Mandatory=$true)]
    [guid]
    $Id,
    [Parameter(Mandatory=$true)]
    $TemplatePath,
    [Parameter(Mandatory=$true)]
    $OutputPath
)

<#
    .SYNOPSIS
    Formats JSON in a nicer format than the built-in ConvertTo-Json does.
    
    .PARAMETER json
    The JSON string to format
    
#>
function Format-Json {
    param(
        [Parameter(Mandatory=$true, ValueFromPipeline=$true)]
        [String]$json
    )
    $indent = 0;

    $builder = New-Object System.Text.StringBuilder

    foreach ($line in $json -split '\n'){
        
        # if this line starts ] or }, decrement the indentation level
        if ($line -match '^\s*[\}\]]') {                
            $indent--
        }

        $builder.AppendLine((' ' * $indent * 2) + $line.Trim()) | Out-Null

        # If this line ends [ or {, increment the indentation level
        if ($line -match '[\{\[]\s*$') {                
            $indent++
        }
    }
    return $builder.ToString()
}

# Load perspective JSON
$template = Get-Content $TemplatePath -Raw | ConvertFrom-Json

# Replace ID as it must be unique
$template.id = [Guid]::NewGuid().ToString()
Write-Verbose -Message "Set perspective Id to $($template.id)"

# Ensure derivedFrom is empty, just in case..
$template.derivedFrom = [Guid]::Empty.ToString()

# Update rank
$template.rank = 10000

# Update targeted Object ID
$template.match.id = $Id
Write-Verbose -Message "Perspective now targets SCOM Object $($template.match.id)"

# Save perspective out to final destination
$template | ConvertTo-Json -Depth 99 | format-json | Out-File $OutputPath -Encoding Unicode -NoClobber -ErrorAction Stop -Verbose