<#
.SYNOPSIS
    Test file for Pester that will ensure all non-test scripts are syntactically correct, meet best practices and include detailed comment-based help
.PARAMETER Path
    Optional. A list of folder or file paths that will be examined for scripts to test.  Defaults to the invocation path to support running via Invoke-Pester
#>
[CmdletBinding()]
Param(
    [Parameter(Mandatory = $false)]
    [string[]]$Path = (Split-Path -Parent $MyInvocation.MyCommand.Path)
)
$scripts = Get-ChildItem $Path -Recurse -File -Include '*.ps1' -Exclude '*.Tests.ps1'

foreach ($script in $scripts)
{
    $scriptPath = $script.FullName
    Describe "$scriptPath" {    
        $astErrors = @()
        # Parse the function using AST
        $ast = [System.Management.Automation.Language.Parser]::ParseFile($scriptPath, [ref]$null, [ref]$astErrors)

        Context 'Structure and Syntax' {
            It 'Contains no errors' { $astErrors.Count | Should BeLessThan 1 }
            It 'Has a valid signature (if signed)' {
                $result = Get-AuthenticodeSignature $scriptPath
                if ($result.Status -eq [System.Management.Automation.SignatureStatus]::NotSigned) {
                    $true | Should Be $true
                } else {
                    $result.Status | Should Be ([System.Management.Automation.SignatureStatus]::Valid)
                }
            }
        }

        Context 'Script Analysis Rules' {
            $rules = Get-ScriptAnalyzerRule
            $results = Invoke-ScriptAnalyzer -Path $scriptPath -ErrorAction Stop

            Foreach ($rule in $rules)
            {
                It "Passes the PSScriptAnalyzer rule $($rule.RuleName)" {
                    $violations = $results | Where-Object {$_.RuleName -eq $Rule.RuleName} | Measure-Object
                    $violations.Count | Should Be 0
                }
            }
        }

        Context 'Comment-based help' {
            $help = Get-help $scriptPath -full

            It "Includes a Synopsis" { 
                $help.Synopsis | Should not BeNullOrEmpty 
                $help.Synopsis | Should Not Match (Split-Path -Leaf $scriptPath)
            }
            It "Includes a Description"{ $help.Description | Should not BeNullOrEmpty }
            It "Notes include copyright notice" { $help.alertSet.alert.text | Should Match "Copyright $([DateTime]::Now.Year) Squared Up (Limited|Ltd)" }

            $riskMitigationParameters = 'Whatif', 'Confirm'
            $helpParameters = $help.parameters.parameter | Where-Object name -NotIn $RiskMitigationParameters

            # Get the parameters declared in the AST PARAM() Block
            $scriptParameters = $ast.ParamBlock.Parameters.Name.variablepath.userpath

            It "Has the same number of paramters as the script" {
                $helpParameters.name.count -eq $scriptParameters.count | Should Be $true
            }
                
            # Parameter Description
            foreach ($parameter in $helpParameters) {
                It "Parameter $($parameter.Name) contains description"{
                    $parameter.description | Should not BeNullOrEmpty
                }
            }

            # Examples
            It "Should have at least one example"{
                $helpExamples = $help.examples.example | Measure-Object
                $helpExamples.count | Should BeGreaterthan 0
            }
            
            foreach ($example in $help.examples.example)
            {
                it "Example $($Example.Title.Replace('-','').Trim()) has remarks"{
                    $Example.remarks | Should not BeNullOrEmpty
                }
            }

            # Links
            It "Should have at least one link to SquaredUp.com" {
                $websiteLinks = $help.relatedLinks.navigationLink.uri | Where-Object {$_ -match '^(https?://)?(www\.)?squaredup\.com' } | Measure-Object
                $websiteLinks.Count | Should BeGreaterthan 0
                
            }
        }
    }
}
