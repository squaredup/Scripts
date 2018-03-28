-- Where else is this Alert occurring (most recent 20)
SELECT 
    me.Path, me.DisplayName, COUNT(*) AS 'Count', MAX(a.RaisedDateTime) AS 'Most Recent'
FROM 
    Alert.vAlert AS a
JOIN 
    vManagedEntity AS me ON a.ManagedEntityRowId = me.ManagedEntityRowId
WHERE 
    me.ManagedEntityGuid != {{monitoringObjectId}} and
    (
        a.AlertProblemGuid = {{id}} or 
        a.AlertName = {{name}}
    )
GROUP BY 
    me.DisplayName, me.Path
ORDER BY 
    Count DESC
