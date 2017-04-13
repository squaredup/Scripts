-- Select all Open incidents for a CI created in the last 24 hours
SELECT 
    incident.Id_9A505725_E2F2_447F_271B_9B9F4F0D190C  AS ID,
    incident.Title_9691DD10_7211_C835_E3E7_6B38AF8B8104 AS Title,
    incStatus.DisplayName AS Status,
    CONCAT(CONVERT(VARCHAR(24), incident.CreatedDate_6258638D_B885_AB3C_E316_D00782B8F688, 113), ' UTC') As CreatedDate,
    impact.DisplayName As Impact
FROM MT_System$WorkItem$Incident incident
    INNER JOIN fn_EnumerationsView('ENG','ENU') incStatus on incident.Status_785407A9_729D_3A74_A383_575DB0CD50ED = incStatus.id
    INNER JOIN fn_EnumerationsView('ENG','ENU') impact on incident.Impact_276C8DBF_2BC3_2374_665E_77FC76513017 = impact.id    
    INNER JOIN RelationshipView R ON incident.BaseManagedEntityId = R.SourceEntityId
        AND R.TargetEntityId = '00000000-0000-0000-0000-000000000000'
WHERE 
    incStatus.DisplayName NOT IN ('Resolved', 'Closed')
    AND incident.CreatedDate_6258638D_B885_AB3C_E316_D00782B8F688 > DATEADD(HOUR,-24,GETUTCDATE())
