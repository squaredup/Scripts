<#
.SYNOPSIS
    Creates SCOM notification channels with HTML formatting enabled.
.DESCRIPTION
    This script will create SCOM notification channels with HTML formatting options enabled. This allows for significantly richer notification templates.

    Channels can either be created from scratch or clone their settings from an existing channel (and will therefore use it's predefined endpoints).

    By default notification bodies will include appropriate links to the SCOM Web console, but by specifying the SquaredUpUrl parameter links will use Squared Up instead.

    Please ensure that a management group connection exists prior to running the script - either run this from the Operations Manager shell or run New-SCOMManagementGroupConnection.
.PARAMETER SquaredUpURL
    The root URL of the Squared Up web console.  If a protocol is not specified, http:// will be prepended.  If this value is not specified, link will use the SCOM Web console instead.
.PARAMETER BaseSmtpChannel
    Specifies the Id or Displayname of an existing Notification Channel from which to clone settings.  You can get a list of IDs by running Get-SCOMNotificationChannel | select -ExpandProperty Action | fl DisplayName,Id
.PARAMETER SMTPServerFQDN
    The FQDN of the SMTP relay you want to send notification emails to.
.PARAMETER SMTPFromAddress
    The email address notification emails will be sent from, and the reply-to address.
.PARAMETER SMTPServerPort
    The port number your SMTP relay is listening on.  Defaults to 25 if unspecified.
.PARAMETER SMTPRetryMins
    The number of minutes between retries should the SMTP server not respond.
.PARAMETER SMTPAuthentication
    The authentication mechanism used by the SMTP relay.  Valid values are 'Anonymous' (the default if unspecified) or 'Ntlm'.
.PARAMETER HighImportance
    Controls whether channels are created with the High Importance mail flag.  Default value is false.
.PARAMETER PlainText
    Controls whether channels with a Plaintext format are created rather than HTML.  Default value is false.
.EXAMPLE
    C:\PS> .\New-SCOMHtmlNotificationChannel.ps1 -SquaredUpURL 'SQUP.contoso.com/SquaredUpv3' -SMTPServerFQDN "mail.contoso.com" -SMTPFromAddress "SCOM@contoso.com" -HighImportance
    Creates High Importance HTML channels in SCOM using the specified SMTP relay settings.
.EXAMPLE
    C:\PS> .\New-SCOMHtmlNotificationChannel.ps1 -SquaredUpURL "SQUP.contoso.com/SquaredUpv3" -BaseSmtpChannelGuid 2149e02e-6bb2-661a-1535-17d1dba162ab -PlainText
    Creates Plaintext channels with normal importance, taking all SMTP settings from an existing SMTP notification channel.
.INPUTS
    None
.OUTPUTS
    Microsoft.EnterpriseManagement.Administration.SmtpNotificationAction
.NOTES 
    Copyright 2016 Squared Up Limited, All Rights Reserved.
.Link
    https://www.squaredup.com
    https://github.com/squaredup
#>
[CmdletBinding(SupportsShouldProcess=$true)]
Param(
    [Parameter(
        ParameterSetName = 'Clone',
        Mandatory = $false       
    )]
    [Parameter(
        ParameterSetName = 'New',
        Mandatory = $false
    )]
    [string]$SquaredUpURL,

    [Parameter(
        ParameterSetName = 'Clone',
        Mandatory = $true
    )]
    [ValidateNotNullOrEmpty()]
    [string]$BaseSmtpChannel,
    
    [Parameter(
        ParameterSetName = 'New',
        Mandatory = $true
    )]
    [ValidateNotNullOrEmpty()]
    [string]$SMTPServerFQDN,

    [Parameter(
        ParameterSetName = 'New',
        Mandatory = $true
    )]
    [ValidateNotNullOrEmpty()]
    [string]$SMTPFromAddress,

    [Parameter(
        ParameterSetName = 'New',
        Mandatory = $false
    )]
    [ValidateRange(0,[int]::MaxValue)]
    [int]$SMTPServerPort = 25,

    [Parameter(
        ParameterSetName = 'New',
        Mandatory = $false
    )]
    [ValidateRange(1,[int]::MaxValue)]
    [int]$SMTPRetryMins = 5,

    [Parameter(
        ParameterSetName = 'New',
        Mandatory = $false
    )]
    [ValidateSet('Anonymous', 'Ntlm')]
    [string]$SMTPAuthentication = 'Anonymous',
    
    [Parameter(
        ParameterSetName = 'New',
        Mandatory = $false        
    )]
    [Parameter(
        ParameterSetName = 'Clone',
        Mandatory = $false        
    )]
    [Switch]$HighImportance,
    
    [Parameter(
        ParameterSetName = 'New',
        Mandatory = $false        
    )]
    [Parameter(
        ParameterSetName = 'Clone',
        Mandatory = $false        
    )]
    [Switch]$PlainText
)

function Get-NotificationActionBody {
    [CmdletBinding()]
    [OutputType([String])]
    Param(
        [Switch]$Html,
        [string]$SquaredUpURL
    )

    if ([string]::IsNullOrEmpty($SquaredUpURL)) {
        Write-Verbose -Message 'Links in the notification body will use the SCOM Web Console' -Verbose:$VerbosePreference
        $AlertUrl = '$Target/Property[Type="Notification!Microsoft.SystemCenter.AlertNotificationSubscriptionServer"]/WebConsoleUrl$?DisplayMode=Pivot&AlertID=$UrlEncodeData/Context/DataItem/AlertId$'
        $ObjectUrl = '$Target/Property[Type="Notification!Microsoft.SystemCenter.AlertNotificationSubscriptionServer"]/WebConsoleUrl$?DisplayMode=Pivot&ViewType=DiagramView&PmoID=$UrlEncodeData/Context/DataItem/ManagedEntity$'
    }
    else {
        Write-Verbose -Message "Links in the notification body will use the Squared Up server '$SquaredUpURL'" -Verbose:$VerbosePreference
        $AlertUrl = $SquaredUpURL + '/drilldown/scomalert?id=$UrlEncodeData/Context/DataItem/AlertId$'    
        $ObjectUrl = $SquaredUpURL + '/drilldown/scomobject?id=$UrlEncodeData/Context/DataItem/ManagedEntity$'
    }
    $Severity = '$Data/Context/DataItem/Severity$'
    $CreatedByMonitor = '$Data/Context/DataItem/CreatedByMonitor$'
    $ResolutionStateName = '$Data/Context/DataItem/ResolutionStateName$'
    $AlertName = '$Data/Context/DataItem/AlertName$'
    $AlertDescription = '$Data/Context/DataItem/AlertDescription$'
    $ManagedEntityDisplayName = '$Data/Context/DataItem/ManagedEntityDisplayName$'
    $ManagedEntityPath = '$Data/Context/DataItem/ManagedEntityPath$'
    $NotificationSubId = '$MPElement$'

    if ($Html) 
    {
        return [string]::Join("`n", @(
            "<!DOCTYPE html>",
            "<html><head>",
            "<!-- (c) Squared Up Ltd 2016 -->",
            "<style>div span{{display:none;text-decoration:line-through;}}.y{{display:inline;text-decoration:none;}}.s-$Severity{{display:inline;text-decoration:none;}}.m-$CreatedByMonitor{{display:inline;text-decoration:none;}}.t{{font-weight:bold;}}.b{{background:#f1f1f1;}}.b-2-New{{background:#FF3E3E;}}.b-1-New{{background:#FDC700;}}.b-0-New{{background:#5F9ECA;}}</style>",
            "</head>",
            "<body style='font-size:0.8em;font-family:arial;line-height:1.5em;color:#444444;'>",
            "<div>",
            "<div class='b'><div class='b-$Severity-$ResolutionStateName'>&nbsp;</div></div>",
            "<div class='t'><span class='y'>$ResolutionStateName | </span><span class='s-2'>Critical</span><span class='s-1'>Warning</span><span class='s-0'>Info</span> | <span class='m-true'>Monitor</span><span class='m-false'>Rule</span></div>",
            "<h2 style='margin-bottom:0;line-height:1em;'>$AlertName</h2>",
            "on<br />",
            "<b>$ManagedEntityDisplayName</b><br/>",
            "<b>$ManagedEntityPath</b><br/>",
            "<br />",
            "<i>$AlertDescription</i><br />",
            "<br/>",
            "<a href='$AlertUrl'>view alert</a> | <a href='$ObjectUrl'>view object</a><br />",
            "Notification Subscription ID: $NotificationSubId",
            "</div>",
            "</body>",
            "</html>"            
        ))
    }
    else 
    {
        return [string]::Join("`n", @(
            "$ResolutionStateName | Severity:$Severity | Monitor:$CreatedByMonitor",
            "",
            "$AlertName",
            "on:",
            "$ManagedEntityDisplayName",
            "$ManagedEntityPath",
            "",
            "$AlertDescription",
            "",
            "View alert:",
            "$AlertUrl",
            "",
            "View object:",
            "$ObjectUrl",
            "",
            "Notification Subscription ID:",
            "$NotificationSubId"
        ))
    }
}

function Get-NotificationActionDisplayName {
    [CmdletBinding()]
    [OutputType([String])]
    Param(
        [Switch]$Html,
        [Switch]$HighImportance,
        [Switch]$SquaredUp
    )

    $emailFormat = "Plain text"
    $importance = "Normal importance"
    $console = "SCOM Web Console"

    if ($Html) {
        $emailFormat = "HTML"
    }

    if ($HighImportance) {
        $importance = "High importance"
    }

    if ($SquaredUp) {
        $console = "Squared Up Console"
    }

    return "$emailFormat Notifications - $console - $importance"
}

function Get-NotificationActionSubject {
    [CmdletBinding()]
    [OutputType([String])]
    Param()
    return 'Alert ($Data/Context/DataItem/ResolutionStateName$): $Data/Context/DataItem/AlertName$'
}

function Get-NotificationActionDescription {
    [CmdletBinding()]
    [OutputType([String])]
    Param(
        [Parameter(
            ParameterSetName = 'Clone',
            Mandatory = $true
        )]
        [string]$BaseDisplayName,
        
        [Parameter(
            ParameterSetName = 'New',
            Mandatory = $true
        )]
        [Microsoft.EnterpriseManagement.ManagementGroup]$mg
    )
    if ($PSCmdlet.ParameterSetName -eq "Clone"){
        return "This is a modified copy of the '$BaseDisplayName' channel.  Any changes to the connection details of the original channel will be used automatically by this channel."
    } else {
        return "Created on $([Datetime]::Now) by $($mg.ConnectionSettings.Domain)\$($mg.ConnectionSettings.UserName)"
    }
}

function New-SmtpChannel {
    [CmdletBinding(SupportsShouldProcess=$true)]
    Param(
        [string]$SquaredUpURL,
        $ChannelSettings,
        [Microsoft.EnterpriseManagement.ManagementGroup]$mg,
        [switch]$PlainText,
        [switch]$HighImportance
    )

    $action = New-Object -typename 'Microsoft.EnterpriseManagement.Administration.SmtpNotificationAction' -ArgumentList "SMTPHTMLNotificationChannel$([guid]::NewGuid().Guid.replace('-','_'))"

    #Configure
    $action.Subject = Get-NotificationActionSubject
    $action.Body = Get-NotificationActionBody -Html:(!$PlainText) -SquaredUpURL $SquaredUpURL
    $action.Description = $ChannelSettings.Description
    $action.DisplayName = Get-NotificationActionDisplayName -Html:(!$PlainText) -HighImportance:$HighImportance -SquaredUp:(![string]::IsNullOrEmpty($SquaredUpURL))
    $action.BodyEncoding = $ChannelSettings.BodyEncoding;
    $action.Endpoint = $ChannelSettings.Endpoint;
    $action.From = $ChannelSettings.From;
    $action.IsBodyHtml = !$PlainText;
    $action.ReplyTo = $ChannelSettings.ReplyTo;
    $action.SubjectEncoding = $ChannelSettings.SubjectEncoding;

    if ($HighImportance) {
        $action.Headers.Add((New-Object -Typename Microsoft.EnterpriseManagement.Administration.SmtpNotificationActionHeader -ArgumentList "Importance", "High"))
        $action.Headers.Add((New-Object -Typename Microsoft.EnterpriseManagement.Administration.SmtpNotificationActionHeader -ArgumentList "X-Priority", "1" ))
        $action.Headers.Add((New-Object -Typename Microsoft.EnterpriseManagement.Administration.SmtpNotificationActionHeader -ArgumentList "X-MSMail-Priority", "High" ))
    }

    #Save
    if ($null -eq $ChannelSettings.EndPoint.Id -and $pscmdlet.ShouldProcess("$($ChannelSettings.EndPoint.PrimaryServer.Address) on port $($ChannelSettings.EndPoint.PrimaryServer.PortNumber) using $($ChannelSettings.EndPoint.PrimaryServer.AuthenticationType) authentication","Create SMTP Endpoint"))
    {
        Write-Verbose -Message "Creating SMTP Endpoint '$($ChannelSettings.EndPoint.PrimaryServer.Address)' on port $($ChannelSettings.EndPoint.PrimaryServer.PortNumber) using $($ChannelSettings.EndPoint.PrimaryServer.AuthenticationType) authentication" -Verbose:$VerbosePreference
        $mg.InsertNotificationEndpoint($ChannelSettings.EndPoint)
    }  

    if ($pscmdlet.ShouldProcess($action.DisplayName,"Create SMTP Notification channel"))
    {
        Write-Verbose -Message "Creating SMTP notification channel '$($action.DisplayName)'" -Verbose:$VerbosePreference
        $mg.InsertNotificationAction($action)
        return $action
    }    
}

function New-SmtpEndpoint {
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSUseShouldProcessForStateChangingFunctions", "")]
    [CmdletBinding()]
    [OutputType([Microsoft.EnterpriseManagement.Administration.SmtpNotificationEndpoint])]
    Param(
        [string]$Name,
        [int]$RetryIntervalMins,
        [string]$FQDN,
        [int]$Port,
        [string]$Authentication,
        [string]$Description
    )

    $primaryServer = New-Object -TypeName 'Microsoft.EnterpriseManagement.Administration.SmtpServer' -ArgumentList $FQDN
    $primaryServer.AuthenticationType = $Authentication
    $primaryServer.PortNumber = $Port

    $endpoint = New-Object -TypeName 'Microsoft.EnterpriseManagement.Administration.SmtpNotificationEndpoint' -ArgumentList "SMTPEndpoint$([guid]::NewGuid().Guid.replace('-','_'))",'Smtp',$primaryServer
    $endpoint.PrimaryServerSwitchBackIntervalSeconds = $RetryIntervalMins * 60
    $endpoint.DisplayName = "SMTPEndpoint for $Name"
    $endpoint.Description = $Description

    return $endpoint
}

# Normalise SquaredUpURL
if ([string]::IsNullOrEmpty($SquaredUpURL) -eq $false) {
    $SquaredUpURL  = $SquaredUpURL.TrimEnd('/')
    if ($SquaredUpURL -notmatch '^https?://') {    
        $SquaredUpURL = "http://$SquaredUpURL"
        Write-Verbose -Message "Set base url to '$SquaredUpURL'" -Verbose:$VerbosePreference
    }
}

# Main block
try{

    # Get SCOM SDK connection for use when creating/modifying actions.
    $mg = Get-SCOMManagementGroup -ErrorAction Stop

    # Construct Endpoint Settings
    $channelSettings = $null
    if ($PSCmdlet.ParameterSetName -eq "New") {

        $description = Get-NotificationActionDescription -mg $mg
        $channelSettings = [PSCustomObject]@{
            "Description" = $description;
            "BodyEncoding" = "utf-8";   
            "Endpoint" = New-SmtpEndpoint -Name "Advanced Notifications" -RetryIntervalMins $SMTPRetryMins -FQDN $SMTPServerFQDN -Port $SMTPServerPort -Authentication $SMTPAuthentication -Description $description;
            "From" = $SMTPFromAddress;            
            "ReplyTo" = $SMTPFromAddress;
            "SubjectEncoding" = "utf-8";
        }

    } elseif ($PSCmdlet.ParameterSetName -eq "Clone") {

        # Test if we have a GUID or a displayname specified for the base channel
        $baseSmtpChannelGuid = [guid]::Empty
        if ([guid]::TryParse($BaseSmtpChannel, [ref] $baseSmtpChannelGuid)) {
            $baseSmtpAction = $mg.GetNotificationAction($baseSmtpChannelGuid)
        }
        else {
            $baseSmtpAction = (Get-SCOMNotificationChannel -DisplayName $BaseSmtpChannel).Action
        }

        if ($null -eq $baseSmtpAction)
        {
            Throw "The notification channel '$BaseSmtpChannel' could not be found."
        }
        
        Write-Verbose "Using '$($baseSmtpAction.DisplayName)' as a template"

        $channelSettings = [PSCustomObject]@{
            "Description" = Get-NotificationActionDescription -BaseDisplayName $baseSmtpAction.DisplayName;
            "BodyEncoding" = $baseSmtpAction.BodyEncoding;
            "Endpoint" = $baseSmtpAction.Endpoint;
            "From" = $baseSmtpAction.From;            
            "ReplyTo" = $baseSmtpAction.ReplyTo;
            "SubjectEncoding" = $baseSmtpAction.SubjectEncoding;
        }
    } else {
        Throw "Unable to determine source of SMTP endpoint settings"
    }

    # Create Channel
    New-SmtpChannel -SquaredUpURL $SquaredUpURL -ChannelSettings $channelSettings -mg $mg -HighImportance:$HighImportance -PlainText:$PlainText

}
catch
{
    throw
}