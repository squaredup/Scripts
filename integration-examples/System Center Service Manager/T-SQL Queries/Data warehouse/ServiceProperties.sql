-- Select Service properties that are in the DW.  Notes is not synced into the DW, and Service Desc and Detailed Desc aren't exposed in SM forms by default.
-- Sample MP to add those fields to the standard form https://www.concurrency.com/blog/w/how-to-add-a-description-to-a-service-manager-busi
Select
service.DisplayName,
service.BaseManagedEntityId,
	owner.DisplayName as Owner,
	service.AvailabilitySchedule,
	prioritystring.DisplayName as Priority,
	classificationstring.DisplayName as Classification,
	statusString.DisplayName as Status,
	service.OwnedByOrganization,
	service.ServiceDescription,
	service.BusinessDetailedDescription
FROM ServiceDimvw as service 
	INNER JOIN ConfigItemDimvw as ci on service.EntityDimKey = ci.EntityDimKey
	LEFT OUTER JOIN ConfigItemOwnedByUserFactvw as ownedBy  on ownedby.ConfigItemDimKey = ci.ConfigItemDimKey
	LEFT OUTER JOIN UserDimvw as owner on ownedBy.ConfigItemOwnedByUser_UserDimKey = owner.UserDimKey
	LEFT OUTER JOIN ServiceStatusvw as status ON status.ServiceStatusId = service.Status_ServiceStatusId
	LEFT OUTER JOIN DisplayStringDimvw as statusString on status.EnumTypeId = statusString.BaseManagedEntityId 
		AND statusString.LanguageCode = 'ENU'
	LEFT OUTER JOIN ServicePriorityvw as priority ON priority.ServicePriorityId = service.Priority_ServicePriorityId
	LEFT OUTER JOIN DisplayStringDimvw as priorityString on priority.EnumTypeId = priorityString.BaseManagedEntityId 
		AND priorityString.LanguageCode = 'ENU'
	LEFT OUTER JOIN ServiceClassificationvw as classification ON classification.ServiceClassificationId = service.Classification_ServiceClassificationId
	LEFT OUTER JOIN DisplayStringDimvw as classificationString on classification.EnumTypeId = classificationString.BaseManagedEntityId 
		AND classificationString.LanguageCode = 'ENU'
WHERE
	service.BaseManagedEntityId = '00000000-0000-0000-0000-000000000000'
