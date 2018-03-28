-- How long does it take to resolve, on average (all objects)
SELECT 
    AVG(ars.TimeFromRaisedSeconds) / 3600.0 AS 'Average hours before resolution'
FROM 
    Alert.vAlert AS a
JOIN 
    Alert.vAlertResolutionState as ars ON a.AlertGuid = ars.AlertGuid
WHERE 
    ars.ResolutionState = 255 and 
    (
        a.AlertProblemGuid = {{id}} or 
        a.AlertName = {{name}}
    )
