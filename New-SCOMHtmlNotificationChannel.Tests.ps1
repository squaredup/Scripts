$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$sut = (Split-Path -Leaf $MyInvocation.MyCommand.Path) -replace '\.Tests\.', '.'
$scriptPath = "$here\$sut"

Describe "$scriptPath" {    
    $astErrors = @()
    # Parse the function using AST
    $ast = [System.Management.Automation.Language.Parser]::ParseFile($scriptPath, [ref]$null, [ref]$astErrors)

    Context 'Script Analysis Rules' {
        $rules = Get-ScriptAnalyzerRule
        $results = Invoke-ScriptAnalyzer -Path $scriptPath

        Foreach ($rule in $rules)
        {
            It "Passes the PSScriptAnalyzer rule $($rule.RuleName)" {
                $violations = $results | Where {$_.RuleName -eq $Rule.RuleName} | Measure-Object
                $violations.Count | Should Be 0
            }
        }
    }

    Context 'Structure and Syntax' {
        It 'Contains no errors' { $astErrors.Count | Should BeLessThan 1 }
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

    Context 'Clone existing channel' {

    }

    Context 'Create new channel' {

    }

    Context 'Format' {

    }

    Context 'SCOM Web Console' {

    }

    Context 'Squared Up Console' {

    }

    Context 'High Importance' {

    }
}