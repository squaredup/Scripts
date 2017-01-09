$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$scripts = Get-ChildItem $here -Recurse -File -Include '*.ps1' -Exclude '*.Tests.ps1'

foreach ($script in $scripts)
{
    $scriptPath = $script.FullName
    Describe "$scriptPath" {    
        $astErrors = @()
        # Parse the function using AST
        $ast = [System.Management.Automation.Language.Parser]::ParseFile($scriptPath, [ref]$null, [ref]$astErrors)

        Context 'Structure and Syntax' {
            It 'Contains no errors' { $astErrors.Count | Should BeLessThan 1 }
            It 'Has a valid signiture (if signed)' {
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

            It "Includes a Synopsis"{ $help.Synopsis | Should not BeNullOrEmpty }
            It "Includes a Description"{ $help.Description | Should not BeNullOrEmpty }
            It "Notes include copyright notice" { $help.alertSet.alert.text | Should Match 'Copyright \d{4} Squared Up (Limited|Ltd)' }

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
                $help.examples.example.count | Should BeGreaterthan 0
            }
            
            foreach ($example in $help.examples.example)
            {
                it "Example $($Example.Title.Replace('-','').Trim()) has remarks"{
                    $Example.remarks | Should not BeNullOrEmpty
                }
            }

            # Links
            It "Should have at least one link to SquaredUp.com" {
                $websiteLinks = $help.relatedLinks.navigationLink.uri -match '^(https?://)?(www\.)?squaredup\.com'| Measure-Object
                $websiteLinks.Count | Should BeGreaterthan 0
            }
        }
    }
}