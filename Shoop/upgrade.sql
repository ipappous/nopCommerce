--upgrade scripts from nopCommerce 3.70 to shoop shoop requested 

--new locale resources
declare @resources xml
--a resource will be deleted if its value is empty
set @resources='
<Language>
  <LocaleResource Name="Admin.Catalog.ProductReviews.Fields.RatePackage">
    <Value>Packaging</Value>
  </LocaleResource>
  <LocaleResource Name="Admin.Catalog.ProductReviews.Fields.RateQuality">
    <Value>Item Quality</Value>
  </LocaleResource>
  <LocaleResource Name="Admin.Catalog.ProductReviews.Fields.RatePrinting">
    <Value>Printing Quality</Value>
  </LocaleResource>
  <LocaleResource Name="Admin.Catalog.ProductReviews.Fields.RateDesign">
    <Value>design</Value>
  </LocaleResource>
  <LocaleResource Name="Reviews.Fields.RatePackage">
    <Value>How did you like our Packaging?</Value>
  </LocaleResource>
  <LocaleResource Name="Reviews.Fields.RatePackage">
    <Value>How did you like our Packaging?</Value>
  </LocaleResource>
  <LocaleResource Name="Reviews.Fields.RateQuality">
    <Value>How is the Quality of YOUR little garment?</Value>
  </LocaleResource>
  <LocaleResource Name="Reviews.Fields.RatePrinting">
    <Value>Is the Printing Ok?</Value>
  </LocaleResource>
  <LocaleResource Name="Reviews.Fields.RateDesign">
    <Value>How about our design?</Value>
  </LocaleResource>
</Language>
'


CREATE TABLE #LocaleStringResourceTmp
	(
		[ResourceName] [nvarchar](200) NOT NULL,
		[ResourceValue] [nvarchar](max) NOT NULL
	)

INSERT INTO #LocaleStringResourceTmp (ResourceName, ResourceValue)
SELECT	nref.value('@Name', 'nvarchar(200)'), nref.value('Value[1]', 'nvarchar(MAX)')
FROM	@resources.nodes('//Language/LocaleResource') AS R(nref)

--do it for each existing language
DECLARE @ExistingLanguageID int
DECLARE cur_existinglanguage CURSOR FOR
SELECT [ID]
FROM [Language]
OPEN cur_existinglanguage
FETCH NEXT FROM cur_existinglanguage INTO @ExistingLanguageID
WHILE @@FETCH_STATUS = 0
BEGIN
	DECLARE @ResourceName nvarchar(200)
	DECLARE @ResourceValue nvarchar(MAX)
	DECLARE cur_localeresource CURSOR FOR
	SELECT ResourceName, ResourceValue
	FROM #LocaleStringResourceTmp
	OPEN cur_localeresource
	FETCH NEXT FROM cur_localeresource INTO @ResourceName, @ResourceValue
	WHILE @@FETCH_STATUS = 0
	BEGIN
		IF (EXISTS (SELECT 1 FROM [LocaleStringResource] WHERE LanguageID=@ExistingLanguageID AND ResourceName=@ResourceName))
		BEGIN
			UPDATE [LocaleStringResource]
			SET [ResourceValue]=@ResourceValue
			WHERE LanguageID=@ExistingLanguageID AND ResourceName=@ResourceName
		END
		ELSE 
		BEGIN
			INSERT INTO [LocaleStringResource]
			(
				[LanguageId],
				[ResourceName],
				[ResourceValue]
			)
			VALUES
			(
				@ExistingLanguageID,
				@ResourceName,
				@ResourceValue
			)
		END
		
		IF (@ResourceValue is null or @ResourceValue = '')
		BEGIN
			DELETE [LocaleStringResource]
			WHERE LanguageID=@ExistingLanguageID AND ResourceName=@ResourceName
		END
		
		FETCH NEXT FROM cur_localeresource INTO @ResourceName, @ResourceValue
	END
	CLOSE cur_localeresource
	DEALLOCATE cur_localeresource


	--fetch next language identifier
	FETCH NEXT FROM cur_existinglanguage INTO @ExistingLanguageID
END
CLOSE cur_existinglanguage
DEALLOCATE cur_existinglanguage

DROP TABLE #LocaleStringResourceTmp
GO


--new column
IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id=object_id('[ProductReview]') and NAME='RatePackage')
BEGIN
  ALTER TABLE [ProductReview] ADD [RatePackage] int NULL, [RateQuality] int NULL, [RatePrinting] int NULL, [RateDesign] int NULL
END
GO