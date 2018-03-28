-- When has this Alert occured in the past on this object (most recent 20)
SELECT TOP 20 
    a.RaisedDateTime, a.AlertName, me.DisplayName as ObjectName, me.Path, a.AlertDescription
FROM 
    Alert.vAlert AS a
JOIN 
    vManagedEntity AS me ON a.ManagedEntityRowId = me.ManagedEntityRowId
WHERE 
    me.ManagedEntityGuid = {{monitoringObjectId}} and 
    (
        a.AlertProblemGuid = {{id}} or 
        a.AlertName = {{name}}
    )
ORDER BY 
    a.RaisedDateTime DESC
