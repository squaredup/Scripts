-- Show a breakdown of top 10 group members contributing downtime (healthservice unavailable in hours) over last 30 days,
-- with ID so you can rowlink to the object and drilldown.
SELECT TOP 10 
    me.DisplayName, me.ManagedEntityGuid, result.HealthServiceUnavailableHours 
FROM
(
    SELECT 
        server_in_scope.ManagedEntityRowId, SUM(state_daily.HealthServiceUnavailableMilliseconds) / (1000.0 * 60 * 60) AS 'HealthServiceUnavailableHours' 
    FROM (
        SELECT 
            server_object.* 
        FROM 
            vManagedEntity AS group_object
        JOIN 
            vRelationship AS rel ON rel.SourceManagedEntityRowId = group_object.ManagedEntityRowId
        JOIN 
            vManagedEntity AS server_object ON rel.TargetManagedEntityRowId = server_object.ManagedEntityRowId
        WHERE 
            group_object.ManagedEntityGuid = {{id}}
    ) AS server_in_scope
    JOIN 
        vManagedEntityMonitor AS mem ON mem.ManagedEntityRowId = server_in_scope.ManagedEntityRowId
    JOIN 
        vMonitor AS monitor ON mem.MonitorRowId = monitor.MonitorRowId
    JOIN 
        vStateDailyFull AS state_daily ON state_daily.ManagedEntityMonitorRowId = mem.ManagedEntityMonitorRowId
    WHERE 
        monitor.MonitorSystemName = 'System.Health.EntityState' AND
        state_daily.Date >= DATEADD(d,-30,GETUTCDATE())
    GROUP BY 
        server_in_scope.ManagedEntityRowId
) AS result
JOIN 
    vManagedEntity AS me ON me.ManagedEntityRowId = result.ManagedEntityRowId
ORDER BY
    HealthServiceUnavailableHours DESC
