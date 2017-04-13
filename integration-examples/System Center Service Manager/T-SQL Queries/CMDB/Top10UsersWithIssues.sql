-- Displays the top 10 users by incident count raised in the last 30 days
SELECT TOP 10
    COUNT(*) as 'Incidents', 
    usr.DisplayName as Name, 
    usr.Department_312201FE_C1B3_E95A_01DF_E132E9BD3EC9 as Department,
    email.Email
FROM MTV_System$WorkItem$Incident incident
    INNER JOIN RelationshipView affectedUser ON incident.BaseManagedEntityId = affectedUser.SourceEntityId 
        and affectedUser.RelationshipTypeId = 'DFF9BE66-38B0-B6D6-6144-A412A3EBD4CE' -- System.WorkItemAffectedUser
    INNER JOIN MTV_System$Domain$User usr on affectedUser.TargetEntityId = usr.BaseManagedEntityId
    LEFT OUTER JOIN(
        Select 
            r.SourceEntityId,
            email.TargetAddress_F96D8DDF_E33A_40B0_4039_F03C3D292F17 as Email
        from RelationshipView r
            INNER JOIN MTV_System$Notification$Endpoint email on r.TargetEntityId = email.BaseManagedEntityId
        where 
            email.ChannelName_B4672CDC_4B7C_54C9_F140_274DA6D1B56A = 'SMTP'
            and r.RelationshipTypeId = '649E37AB-BF89-8617-94F6-D4D041A05171' -- System.UserHasPreference
            and email.TargetAddress_F96D8DDF_E33A_40B0_4039_F03C3D292F17 IS NOT NULL
            and email.TargetAddress_F96D8DDF_E33A_40B0_4039_F03C3D292F17 != ''
    ) as email on usr.BaseManagedEntityId = email.SourceEntityId
WHERE
    incident.CreatedDate_6258638D_B885_AB3C_E316_D00782B8F688 > DATEADD(DAY,-30,GETUTCDATE())
GROUP BY 
    usr.DisplayName, 
    usr.Department_312201FE_C1B3_E95A_01DF_E132E9BD3EC9,
    usr.FirstName_4424C8D5_9E30_E87D_9124_1816663FAFFC,
    usr.LastName_651E2AAF_6AA9_9423_9D90_4F150DB24C0D,
    email.Email
ORDER BY 
    Incidents Desc
