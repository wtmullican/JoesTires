USE [TirePower-Joes_Tire_OH] --2019_TCS_Inventory_ALL_Report
;with pardata as 
(
	SELECT 
		PAR_PartID                                        
		, dbo.GetREG_SiteName_FN(PSB_SiteID,3) AS Site
		, ISNULL(PAR_PartNumber,'') as PartNumber
		, DTY_Desc as PartType
		, DST_Desc AS PartSubtype
		, dbo.GetMAN_Name_FN(PAR_ManID) as PartBrand
		, ISNULL(PAR_Model,'') as PartModel
		, ISNULL(PAR_QuickSearch,'') as TireSize
		, ISNULL(PAR_Width, '') as Width
		, ISNULL(PAR_Ratio, '') as Ratio
		, ISNULL(PAR_Rim, '') as Rim
		, ISNULL(PAR_Ply,'') as TirePly
		, ISNULL(PAR_Sidewall,'') as SideWall
		, PSB_OnHand AS OnHandQty
		, PSB_KeepOnHand                                
		, PSB_Obligated                                 
		, PSB_ReorderPt                
		, CONVERT(VARCHAR(12),PSB_OnHandDateTime,101) as OnHandDate
		, ISNULL(PAR_FET, 0) as Par_FET
		, ISNULL(PSB_Location,'') as [Location]
	FROM dbo.Parts (NOLOCK)  
	JOIN dbo.Parts_Sub (NOLOCK) ON PSB_PartID = PAR_PartID
	JOIN dbo.DetSubtype (NOLOCK) ON DST_DetSubtypeID = PAR_DetSubtypeID
	JOIN dbo.DetType (NOLOCK) ON DTY_DetTypeID = DST_DetTypeID
	where 1=1
		AND PAR_Active = 1  -- ONLY Active Items ?
		AND (PSB_OnHand != 0
			OR PSB_KeepOnHand > 0
			OR PSB_ReorderPt > 0)
)
SELECT * 
FROM pardata
ORDER BY PartNumber, Site



