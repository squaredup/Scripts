-- Select all Changes in any way related to an entity
SELECT 
	change.id,
	change.title, 
	statusString.DisplayName as 'Status',		
	CONCAT(CONVERT(VARCHAR(24), change.CreatedDate, 113), ' UTC') As 'CreatedDate',
	impactString.DisplayName as 'Impact'
FROM ChangeRequestDimvw (NOLOCK) as change
	INNER JOIN EntityRelatesToEntityFactvw as relatedToEntity WITH (NOLOCK) on relatedToEntity.EntityDimKey = change.EntityDimKey
	INNER JOIN EntityDimvw as entity WITH (NOLOCK) on entity.EntityDimKey = relatedToEntity.TargetEntityDimKey
	LEFT OUTER JOIN ChangeStatusvw as changeStatus WITH (NOLOCK) on change.Status_ChangeStatusId = changeStatus.ChangeStatusId
	LEFT OUTER JOIN DisplayStringDimvw as statusString WITH (NOLOCK) on changeStatus.EnumTypeId = statusString.BaseManagedEntityId 
		AND statusString.LanguageCode = 'ENU'
	LEFT OUTER JOIN ChangeImpactvw as impact WITH (NOLOCK)on change.Status_ChangeStatusId = impact.ChangeImpactId
	LEFT OUTER JOIN DisplayStringDimvw as impactString WITH (NOLOCK) on impact.EnumTypeId = impactString.BaseManagedEntityId 
		AND impactString.LanguageCode = 'ENU'
Where 
	change.Status_ChangeStatusId in (2,5,6,8)
	and
	entity.BaseManagedEntityId = '00000000-0000-0000-0000-000000000000'