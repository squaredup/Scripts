-- Service Contacts.  Note that Email address is not in the DW by default, you'll need to create a dimension via an MP if you want that
-- see: http://www.scsm.se/?p=1310 by Alexander Axberg (includes sample MP)
SELECT
    contact.DisplayName,
    contact.BusinessPhone,
    contact.Mobile,
    Concat(contact.FirstName,'.',contact.LastName,'@squaredup.com') as Email
FROM UserDimvw as contact (NOLOCK)
	INNER JOIN ConfigItemServicedByUserFactvw as servicedBy with (NOLOCK) on contact.UserDimKey = servicedBy.ConfigItemServicedByUser_UserDimKey
    INNER JOIN ConfigItemDimvw as ci with (NOLOCK) on servicedBy.ConfigItemDimKey = ci.ConfigItemDimKey 
    INNER JOIN ServiceDimvw as service with (NOLOCK) on service.BaseManagedEntityId = ci.BaseManagedEntityId
WHERE 
    service.BaseManagedEntityId = '00000000-0000-0000-0000-000000000000'
    AND     
    servicedBy.DeletedDate IS NULL
