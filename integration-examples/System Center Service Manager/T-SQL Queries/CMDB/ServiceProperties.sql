-- Get properties of a Business Service
SELECT 
    usr.DisplayName as Owner,
    da.AvailabilitySchedule_0DB3A9F3_2891_A02B_E37B_9EFDAF3B35E6 as 'Availability Schedule',
    enumPriority.DisplayName as Priority,
    da.OwnedByOrganization_489FFC8D_DE2D_3424_EF85_456834AF940E as Organisation,
    da.Notes_5CFC0E2A_AB82_5830_D4BB_0596CBED1984 as Notes,
    enumStatus.DisplayName as Status,
    enumClassification.DisplayName as Classification
FROM MTV_Service_sales$app da
    LEFT OUTER JOIN fn_EnumerationsView('ENG','ENU') enumPriority on da.Priority_C75CD6B5_508A_DDE6_ECD0_EBC2434F5431 = enumPriority.id
    LEFT OUTER JOIN fn_EnumerationsView('ENG','ENU') enumStatus on da.Status_0689C997_03F2_83DE_C0E7_FB8E18574552 = enumStatus.id
    LEFT OUTER JOIN fn_EnumerationsView('ENG','ENU') enumClassification on da.Classification_EE738100_A25A_F850_7195_ADBD21E8D019 = enumClassification.id    
    LEFT OUTER JOIN RelationshipView ownedBy WITH (NOLOCK) on ownedBy.SourceEntityId = da.BaseManagedEntityId
      and ownedBy.RelationshipTypeId='CBB45424-B0A2-72F0-D535-541941CDF8E1' --System.ConfigItemOwnedByUser
      and ownedBy.IsDeleted=0
    LEFT OUTER JOIN MTV_System$Domain$User usr WITH (NOLOCK) on ownedBy.TargetEntityId = usr.BaseManagedEntityId
