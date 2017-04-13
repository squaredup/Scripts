-- Select all incidents in any way related to an entity
SELECT 
	incident.id,
	incident.title, 
	statusString.DisplayName as 'Status',		
	CONCAT(CONVERT(VARCHAR(24), incident.CreatedDate, 113), ' UTC') As 'CreatedDate',
	impactString.DisplayName as 'Impact',
	affectedUser.DisplayName as 'Affected User'
FROM IncidentDimvw as incident
	INNER JOIN EntityRelatesToEntityFactvw as relatedTo on relatedTo.EntityDimKey = incident.EntityDimKey
	INNER JOIN EntityDimvw as entity on entity.EntityDimKey = relatedTo.TargetEntityDimKey
    INNER JOIN WorkItemDimvw as wi on incident.EntityDimKey = wi.EntityDimKey
    LEFT JOIN WorkItemAffectedUserFactvw as WIAU on wi.WorkItemDimKey = wiau.WorkItemDimKey
    LEFT JOIN UserDimvw as affectedUser on wiau.WorkItemAffectedUser_UserDimKey = affectedUser.UserDimKey
	LEFT OUTER JOIN IncidentStatusvw as status on incident.Status_IncidentStatusId = status.IncidentStatusId
	LEFT OUTER JOIN DisplayStringDimvw as statusString on status.EnumTypeId = statusString.BaseManagedEntityId 
		AND statusString.LanguageCode = 'ENU'
	LEFT OUTER JOIN IncidentImpactvw as impact on incident.Status_IncidentStatusId = impact.IncidentImpactId
	LEFT OUTER JOIN DisplayStringDimvw as impactString on impact.EnumTypeId = impactString.BaseManagedEntityId 
		AND impactString.LanguageCode = 'ENU'
Where 
	incident.Status_IncidentStatusId NOT in (3,4)
	and
	entity.BaseManagedEntityId = '00000000-0000-0000-0000-000000000000'
