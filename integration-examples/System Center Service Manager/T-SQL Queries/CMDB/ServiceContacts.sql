-- Select service contacts from a Business Service
Select usr.DisplayName,
	usr.Department_312201FE_C1B3_E95A_01DF_E132E9BD3EC9 as Department,
	email.email as Email,
	BusinessPhone_DF56B912_F9E0_3565_4228_086CEABE35C2 as Phone
FROM MTV_System$Domain$User usr (NOLOCK)
    Inner JOIN RelationshipView contact WITH (NOLOCK) on contact.TargetEntityId = usr.BaseManagedEntityId
        and contact.RelationshipTypeId = 'DD01FC9B-20CE-EA03-3EC1-F52B3241B033' -- System.ConfigItemServicedByUser
        and contact.SourceEntityId = '00000000-0000-0000-0000-000000000000'
    LEFT OUTER JOIN(
        Select 
            r.SourceEntityId,
            email.TargetAddress_F96D8DDF_E33A_40B0_4039_F03C3D292F17 as Email
        from RelationshipView (NOLOCK) r
            INNER JOIN MTV_System$Notification$Endpoint email WITH (NOLOCK) on r.TargetEntityId = email.BaseManagedEntityId
        where 
            email.ChannelName_B4672CDC_4B7C_54C9_F140_274DA6D1B56A = 'SMTP'
            and r.RelationshipTypeId = '649E37AB-BF89-8617-94F6-D4D041A05171' -- System.UserHasPreference
            and email.TargetAddress_F96D8DDF_E33A_40B0_4039_F03C3D292F17 IS NOT NULL
            and email.TargetAddress_F96D8DDF_E33A_40B0_4039_F03C3D292F17 != ''
    ) as email on usr.BaseManagedEntityId = email.SourceEntityId
