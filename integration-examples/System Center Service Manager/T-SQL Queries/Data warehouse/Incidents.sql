-- Select all incidents in any way related to an entity
SELECT 
	incident.id,
	incident.title, 
	statusString.DisplayName as 'Status',		
	CONCAT(CONVERT(VARCHAR(24), incident.CreatedDate, 113), ' UTC') As 'CreatedDate',
	impactString.DisplayName as 'Impact',
	affectedUser.DisplayName as 'Affected User'
FROM IncidentDimvw as incident (NOLOCK)
	INNER JOIN EntityRelatesToEntityFactvw as relatedTo WITH (NOLOCK) on relatedTo.EntityDimKey = incident.EntityDimKey
	INNER JOIN EntityDimvw as entity WITH (NOLOCK) on entity.EntityDimKey = relatedTo.TargetEntityDimKey
    INNER JOIN WorkItemDimvw as wi WITH (NOLOCK) on incident.EntityDimKey = wi.EntityDimKey
    LEFT JOIN WorkItemAffectedUserFactvw as WIAU WITH (NOLOCK) on wi.WorkItemDimKey = wiau.WorkItemDimKey
    LEFT JOIN UserDimvw as affectedUser WITH (NOLOCK) on wiau.WorkItemAffectedUser_UserDimKey = affectedUser.UserDimKey
	LEFT OUTER JOIN IncidentStatusvw as status WITH (NOLOCK) on incident.Status_IncidentStatusId = status.IncidentStatusId
	LEFT OUTER JOIN DisplayStringDimvw as statusString WITH (NOLOCK) on status.EnumTypeId = statusString.BaseManagedEntityId 
		AND statusString.LanguageCode = 'ENU'
	LEFT OUTER JOIN IncidentImpactvw as impact WITH (NOLOCK) on incident.Status_IncidentStatusId = impact.IncidentImpactId
	LEFT OUTER JOIN DisplayStringDimvw as impactString WITH (NOLOCK) on impact.EnumTypeId = impactString.BaseManagedEntityId 
		AND impactString.LanguageCode = 'ENU'
Where 
	incident.Status_IncidentStatusId NOT in (3,4)
	and
	entity.BaseManagedEntityId = '00000000-0000-0000-0000-000000000000'