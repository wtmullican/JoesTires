DECLARE 
	@pBegDT		date,
	@pEndDT		date
--	--------------------------------------------------------------------------
--	Set your Date Range
--	--------------------------------------------------------------------------
SET @pBegDT = '2023-05-21'
SET @pEndDT = dbo.Get_DatePart_FN(NULL)
--SELECT @pBegDT as BegDate, @pEndDT AS EndDate
--	--------------------------------------------------------------------------
DECLARE @PeoList TABLE 
(
	PeopleID		int,
	CustomerName	varchar(500)
)
INSERT INTO @PeoList (PeopleID, CustomerName)
SELECT PEO_PeopleID, PEO_LastName
FROM dbo.People (NOLOCK) 
WHERE PEO_Type = 1
	AND (PEO_LastName LIKE 'SimpleTire'
		or PEO_LastName LIKE 'Tires-Easy, LLC'
		or PEO_LastName LIKE 'Giga Tires, LLC'
		or PEO_LastName LIKE 'Priority Tire'
		or PEO_LastName LIKE 'Tire Agent Corp.'
		or PEO_LastName LIKE 'Tire Web, LLC')
--SELECT * FROM @PeoList

DECLARE @SalesData TABLE 
(
	TRA_TransID			int,
	TRA_SiteID			int,
	REG_Code			varchar(10),

	TRA_RefNum			varchar(20),
	TRA_TransTypeID		int,
	TTY_Desc			varchar(50),

	TRA_DateAndTime		datetime,
	TRA_Date			varchar(20),
	TRA_Date_Year		int,
	TRA_Date_Qtr		int,
	TRA_Date_Mth		varchar(10),
	TRA_Date_WkNo		int,
	TRA_Date_WkDay		varchar(10),
	TRA_Date_Hr			int,

	TRA_InsertDateTime	datetime,
	TRA_Insert_Date		date,
	TRA_Insert_Year		int,
	TRA_Insert_Mth		varchar(10),
	TRA_Insert_WkNo		int,
	TRA_Insert_WkDay	varchar(10),
	TRA_Insert_Hr		int,

	TRA_PONum			varchar(50),

	TRA_PeopleID		int,
	PCG_Desc			varchar(50),
	PCG_Desc_Overwrite	varchar(50),
	PEO_CustomerName	varchar(255),
	PEO_City			varchar(50),
	PEO_State			varchar(50),
	PEO_InsertDate		varchar(20),

	TRA_AutoID			int,
	AUT_Year			int,
	AUT_Make			varchar(255),
	AUT_Model			varchar(255),
	TRA_MileageOut		int,

	TRA_SalesmanID		int,
	USER_Salesman		varchar(255),

	TRA_OfferCodeID		int,
	OFC_OfferCode		varchar(50),

	DET_DetID			int,
	DET_DetTypeID		int,
	DTY_Desc			varchar(50),
	DST_Desc			varchar(50),
	DET_Desc			varchar(500),
	DET_PartID			int,
	DET_Qty				decimal(19,2),
	DET_Amount			decimal(19,2),
	DET_UnitCostLast	decimal(19,2),
	DET_Profit			decimal(19,2),
	USER_Technician		varchar(255),
	
	PAR_PartNumber		varchar(50),
	MAN_Name			varchar(50),
	PAR_Model			varchar(60),
	PAR_QuickSearch		varchar(20),
	PAR_Ply				varchar(35),

	SER_Code			varchar(20),
	SER_Description		varchar(255),

	BayTime				int

)

INSERT INTO @SalesData (
	TRA_TransID
	, TRA_SiteID, REG_Code
	, TRA_TransTypeID, TTY_Desc
	, TRA_RefNum
	, TRA_DateAndTime, TRA_InsertDateTime
	, TRA_PONum
	, TRA_PeopleID, PCG_Desc, PEO_City, PEO_State, PEO_InsertDate
	, TRA_AutoID
	, TRA_MileageOut
	, TRA_SalesmanID, USER_Salesman
	, TRA_OfferCodeID, OFC_OfferCode
	, DET_DetID
	, DET_DetTypeID, DTY_Desc
	, DST_Desc, DET_Desc
	, DET_PartID
	, DET_Qty
	, DET_Amount, DET_UnitCostLast
	, USER_Technician 
)
SELECT 
	TRA_TransID
	, TRA_SiteID, REG_Code
	, TRA_TransType, dbo.GetTTY_Desc_FN(TRA_TransType, 1, TRA_CheckType)
	, dbo.GetTRA_TransRefNum_FN(TRA_TransID)
	, TRA_DateAndTime, TRA_InsertDateTime
	, ISNULL(TRA_PONum,'')
	, TRA_PeopleID, PCG_Desc, PEO_City, PEO_State, CONVERT(VARCHAR(10),PEO_InsertDateTime,101)
	, TRA_AutoID
	, TRA_MileageOut
	, TRA_SalesmanID, dbo.GetUSE_Name_FN(TRA_SalesmanID,0)
	, TRA_OfferCodeID, dbo.GetOFC_CodeDesc_FN(TRA_OfferCodeID,2)
	, DET_DetID
	, DET_DetTypeID, DTY_Desc
	, DST_Desc, DET_Description
	, DET_PartID
	, CASE TRA_TransType 
		WHEN 17 THEN (DET_Qty * -1)
		ELSE DET_Qty 
	END						
	, DET_Amount, DET_UnitCostLast
	, dbo.GetUSE_Name_FN(DET_MechID,0)
FROM dbo.Transactions (NOLOCK)  
JOIN dbo.Registration (NOLOCK) on REG_SiteID = TRA_SiteID
JOIN dbo.People (NOLOCK) ON PEO_PeopleID = TRA_PeopleID
	AND PEO_Type IN(1,3)
LEFT JOIN dbo.PeopleCategory on PCG_ID = PEO_PeoCatID
	AND PCG_PeopleType = 1
	AND PCG_ID NOT IN (15,16,18)
JOIN dbo.Details (NOLOCK) on DET_TransID = TRA_TransID
JOIN dbo.DetType (NOLOCK) on DTY_DetTypeID = DET_DetTypeID
JOIN dbo.DetSubtype (NOLOCK) on DST_DetSubtypeID = DET_DetSubtypeID
WHERE TRA_VoidDateTime IS NULL
	AND TRA_TransType IN (1,17)
	AND TRA_DateAndTime BETWEEN @pBegDT AND @pEndDT

--	--------------------------------------------------------------------------
--	UPDATE DATA FIELDS FROM RAW DATA.
--	--------------------------------------------------------------------------
--	Handle Field Look-ups and calculations
--	--------------------------------------------------------------------------
UPDATE @SalesData SET
	PEO_CustomerName = dbo.GetPEO_Name_FN(TRA_PeopleID, TRA_SiteID, 1)
	, DET_Profit = ISNULL((DET_Amount - (DET_UnitCostLast * DET_Qty)),0)
	, BayTime = DATEDIFF(N,TRA_InsertDateTime,TRA_DateAndTime) / 60.00	
WHERE 1=1
--	--------------------------------------------------------------------------
--	Handle Vehicle Look-ups
--	--------------------------------------------------------------------------
UPDATE @SalesData SET
	AUT_Year = dbo.GetAUT_Desc_FN(TRA_AutoID,10)
	, AUT_Make = dbo.GetAUT_Desc_FN(TRA_AutoID,11)
	, AUT_Model = dbo.GetAUT_Desc_FN(TRA_AutoID,12)
WHERE TRA_AutoID <> 0

UPDATE @SalesData SET
	AUT_Year = 0
	, AUT_Make = ''
	, AUT_Model = ''
WHERE TRA_AutoID = 0

--	--------------------------------------------------------------------------
--	Handle PCG_Desc_Overwrite
--		SELECT * FROM dbo.PeopleCategory WHERE PCG_PeopleType = 1
--	--------------------------------------------------------------------------
UPDATE @SalesData SET PCG_Desc_Overwrite = '0'	WHERE 1=1	-- DEFAULT

UPDATE @SalesData SET PCG_Desc_Overwrite = 'Non_RTL_Sale'	WHERE PCG_Desc IN ('Employee')

UPDATE @SalesData SET PCG_Desc_Overwrite = 'RTL_Sale'		WHERE PCG_Desc IN ('Retail')
UPDATE @SalesData SET PCG_Desc_Overwrite = 'RTL_Sale'		WHERE PCG_Desc IN ('Commercial')
UPDATE @SalesData SET PCG_Desc_Overwrite = 'RTL_Sale'		WHERE PCG_Desc IN ('Government')
UPDATE @SalesData SET PCG_Desc_Overwrite = 'RTL_Sale'		WHERE PCG_Desc IN ('National Account')
UPDATE @SalesData SET PCG_Desc_Overwrite = 'RTL_Sale'		WHERE PCG_Desc IN ('Out of State National Account')
UPDATE @SalesData SET PCG_Desc_Overwrite = 'RTL_Sale'		WHERE PCG_Desc IN ('Retail - Nailers Promo')

UPDATE @SalesData SET PCG_Desc_Overwrite = 'RTL_Sale'		WHERE PCG_Desc IN ('Wholesale') AND REG_Code IN('0280','6003') 
UPDATE @SalesData SET PCG_Desc_Overwrite = 'Non_RTL_Sale'	WHERE PCG_Desc IN ('Wholesale') AND REG_Code NOT IN('0280','6003')

UPDATE @SalesData SET PCG_Desc_Overwrite = 'Non_RTL_Sale'	WHERE PCG_Desc IN ('Out Of State Wholesale') AND REG_Code NOT IN('0280','6003')

UPDATE @SalesData SET PCG_Desc_Overwrite = 'RTL_Sale'		WHERE PCG_Desc IN ('Out Of State Wholesale') AND REG_Code = '0280'
UPDATE @SalesData SET PCG_Desc_Overwrite = 'RTL_Sale'		WHERE PCG_Desc IN ('Out Of State Wholesale') AND REG_Code = '6003' AND NOT EXISTS (SELECT 1 FROM @PeoList WHERE PeopleID = TRA_PeopleID)
UPDATE @SalesData SET PCG_Desc_Overwrite = 'Online_Sale'	WHERE PCG_Desc IN ('Out Of State Wholesale') AND REG_Code = '6003' AND EXISTS (SELECT 1 FROM @PeoList WHERE PeopleID = TRA_PeopleID)

--	--------------------------------------------------------------------------
--	Handle date fields.
--	--------------------------------------------------------------------------
UPDATE @SalesData SET 
	TRA_Date			= CONVERT(VARCHAR(10),TRA_DateAndTime,101)
	, TRA_Date_Year		= DATENAME(year,TRA_DateAndTime)
	, TRA_Date_Qtr		= DATEPART(qq,TRA_DateAndTime)
	, TRA_Date_Mth		= LEFT(DATENAME(month,TRA_DateAndTime), 3)
	, TRA_Date_WkNo		= DATENAME(week,TRA_DateAndTime)
	, TRA_Date_WkDay	= LEFT(DATENAME (weekday,TRA_DateAndTime), 3)
	, TRA_Date_Hr		= DATENAME(hour,TRA_DateAndTime)
	, TRA_Insert_Date	= CONVERT(VARCHAR(10),TRA_InsertDateTime,101)
	, TRA_Insert_Year	= DATENAME(year,TRA_InsertDateTime)
	, TRA_Insert_Mth	= LEFT(DATENAME(month,TRA_InsertDateTime), 3)
	, TRA_Insert_WkNo	= DATENAME(week,TRA_InsertDateTime)
	, TRA_Insert_WkDay	= LEFT(DATENAME (weekday,TRA_InsertDateTime), 3)
	, TRA_Insert_Hr		= DATENAME(hour,TRA_InsertDateTime)
WHERE 1=1
--	--------------------------------------------------------------------------
--	Handle Parts
--	--------------------------------------------------------------------------
UPDATE sd SET 
	sd.PAR_PartNumber = p.PAR_PartNumber
	, sd.MAN_Name = dbo.GetMAN_Name_FN(PAR_ManID)
	, sd.PAR_Model = p.PAR_Model
	, sd.PAR_QuickSearch = ISNULL(p.PAR_QuickSearch,'')
	, sd.PAR_Ply = ISNULL(p.PAR_Ply,'')
	, sd.SER_Code = ''
	, sd.SER_Description = ''
FROM @SalesData as sd
JOIN dbo.Parts as p ON p.PAR_PartID = sd.DET_PartID
WHERE sd.DET_DetTypeID <> 4 AND sd.DET_PartID <> 0
--	--------------------------------------------------------------------------
--	Handle Services
--	--------------------------------------------------------------------------
UPDATE sd SET 
	sd.SER_Code = s.SER_Code
	, sd.SER_Description = s.SER_Description
	, sd.PAR_PartNumber = ''
	, sd.MAN_Name = ''
	, sd.PAR_Model = ''
	, sd.PAR_QuickSearch = ''
	, sd.PAR_Ply = ''
FROM @SalesData as sd
JOIN dbo.[Service] as s on s.SER_ServiceID = sd.DET_PartID
WHERE sd.DET_DetTypeID = 4 AND sd.DET_PartID <> 0
--	--------------------------------------------------------------------------
--	Return Data
--	--------------------------------------------------------------------------
SELECT *
	--TRA_TransID, REG_Code, TRA_RefNum
	----, TRA_TransTypeID
	--, TTY_Desc
	--, TRA_DateAndTime
	----, TRA_Date, TRA_Date_Year, TRA_Date_Qtr, TRA_Date_Mth, TRA_Date_WkNo, TRA_Date_WkDay, TRA_Date_Hr
	----, TRA_InsertDateTime
	----, TRA_Insert_Date, TRA_Insert_Year, TRA_Insert_Mth, TRA_Insert_WkNo, TRA_Insert_WkDay, TRA_Insert_Hr
	--, TRA_PONum
	--, TRA_PeopleID, TRA_AutoID, TRA_MileageOut
	--, TRA_SalesmanID
	--, TRA_OfferCodeID
	--, DET_DetID, DTY_Desc, DST_Desc, DET_Desc
	--, DET_PartID
	--, DET_Amount
	--, DET_UnitCostLast
	--, USER_Technician
FROM @SalesData
ORDER BY TRA_Date
