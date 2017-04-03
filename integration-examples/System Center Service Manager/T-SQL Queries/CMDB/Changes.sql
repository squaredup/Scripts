-- Select open Change requests for a CI created in the last 7 days
SELECT 
    change.Id_9A505725_E2F2_447F_271B_9B9F4F0D190C  AS ID,
    change.Title_9691DD10_7211_C835_E3E7_6B38AF8B8104 AS Title,
    changeStatus.DisplayName AS Status,
    CONCAT(CONVERT(VARCHAR(24), change.CreatedDate_6258638D_B885_AB3C_E316_D00782B8F688, 113), ' UTC') As CreatedDate,
    risk.DisplayName As Risk,
    CONCAT(CONVERT(VARCHAR(24), change.ScheduledStartDate_89429D01_365C_366D_FCDA_3198102B180C, 113), ' UTC') As Scheduled
FROM MTV_System$WorkItem$ChangeRequest (NOLOCK) change
    JOIN fn_EnumerationsView('ENG','ENU') changeStatus on change.Status_72C1BC70_443C_C96F_A624_A94F1C857138 = changeStatus.id
    JOIN fn_EnumerationsView('ENG','ENU') risk on change.Risk_B9DCB168_B698_6864_E562_08F986C1D4E0 = risk.id
    JOIN RelationshipView aboutItem with (NOLOCK) ON change.BaseManagedEntityId = aboutItem.SourceEntityId 
        AND aboutItem.RelationshipTypeId = 'B73A6094-C64C-B0FF-9706-1822DF5C2E82' -- System.WorkItemAboutConfigItem
        AND aboutItem.TargetEntityId = '00000000-0000-0000-0000-000000000000'
WHERE 
    changeStatus.DisplayName NOT IN ('Closed', 'Cancelled')
    and change.CreatedDate_6258638D_B885_AB3C_E316_D00782B8F688 > DATEADD(DAY,-7,GETUTCDATE())