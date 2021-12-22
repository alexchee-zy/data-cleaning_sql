-- explore the data
SELECT 
    *
FROM
    housingdata;
---------------------------------------------------------------------------
-- populate property address data
SELECT 
    *
FROM
    housingdata
WHERE
    PropertyAddress IS NULL;

SELECT 
    a.ParcelID, a.PropertyAddress, b.ParcelID, b.PropertyAddress, IFNULL(a.PropertyAddress,b.PropertyAddress)
FROM
    housingdata AS a
        INNER JOIN
    housingdata AS b ON a.ParcelID = b.ParcelID
        AND a.UniqueID <> b.UniqueID
WHERE
    a.PropertyAddress IS NULL;
    
UPDATE housingdata AS a
        INNER JOIN
    housingdata AS b ON a.ParcelID = b.ParcelID
        AND a.UniqueID <> b.UniqueID 
SET 
    a.PropertyAddress = IFNULL(a.PropertyAddress, b.PropertyAddress)
WHERE
    a.PropertyAddress IS NULL;
---------------------------------------------------------------------------
-- Breaking out address into individual columns (address, city, state)
SELECT 
    SUBSTRING(PropertyAddress,
        1,
        LOCATE(',', PropertyAddress) - 1) AS address,
    SUBSTRING(PropertyAddress,
        LOCATE(',', PropertyAddress) + 1) AS City
FROM
    housingdata;

ALTER TABLE housingdata
ADD PropertySplitAddress varchar(255);

UPDATE housingdata 
SET 
    PropertySplitAddress = SUBSTRING(PropertyAddress,
        1,
        LOCATE(',', PropertyAddress) - 1);
        
ALTER TABLE housingdata
ADD PropertySplitCity varchar(255);

UPDATE housingdata 
SET 
    PropertySplitCity = SUBSTRING(PropertyAddress,
        LOCATE(',', PropertyAddress) + 1,
        LENGTH(PropertyAddress));
        
SELECT 
    SUBSTRING_INDEX(OwnerAddress, ',', 1) AS address,
    SUBSTRING_INDEX(SUBSTRING(OwnerAddress,
                LOCATE(',', OwnerAddress) + 1),
            ',',
            1) AS city,
    SUBSTRING_INDEX(OwnerAddress, ',', - 1) AS state
FROM
    housingdata;
    
ALTER TABLE housingdata
ADD OwnerSplitAddress varchar(255);

ALTER TABLE housingdata
ADD OwnerSplitCity varchar(255);

ALTER TABLE housingdata
ADD OwnerSplitStates varchar(255);

UPDATE housingdata 
SET 
    OwnerSplitAddress = SUBSTRING_INDEX(OwnerAddress, ',', 1);
    
UPDATE housingdata 
SET 
    OwnerSplitCity = SUBSTRING_INDEX(SUBSTRING(OwnerAddress,
                LOCATE(',', OwnerAddress) + 1),
            ',',
            1);

UPDATE housingdata 
SET 
    OwnerSplitStates = SUBSTRING_INDEX(OwnerAddress, ',', - 1); 
---------------------------------------------------------------------------
-- Change 'Y' and 'N' into 'Yes' and 'No' in "SoldAsVacant" field
SELECT 
    SoldAsVacant, COUNT(*)
FROM
    housingdata
GROUP BY SoldAsVacant;

SELECT *,
    CASE
        WHEN SoldAsVacant = 'Y' THEN 'Yes'
        WHEN SoldAsVacant = 'N' THEN 'No'
        ELSE SoldAsVacant
    END AS SoldAsVacant
FROM
    housingdata;

UPDATE housingdata 
SET 
    SoldAsVacant = CASE
        WHEN SoldAsVacant = 'Y' THEN 'Yes'
        WHEN SoldAsVacant = 'N' THEN 'No'
        ELSE SoldAsVacant
    END;
---------------------------------------------------------------------------
-- Remove duplicates
WITH randomCTE AS (SELECT *, ROW_NUMBER() over ( -- checking for duplicates (alternate)
	PARTITION BY
		ParcelID,
		PropertyAddress,
        SalePrice,
        SaleDate,
        LegalReference
	ORDER BY UniqueID) as numrow FROM housingdata) 
Select count(*) FROM randomCTE WHERE numrow > 1;

DELETE -- remove duplicates
from housingdata 
WHERE 
UniqueID IN (SELECT a.UniqueID FROM housingdata AS a inner join housingdata as b
			ON a.ParcelID = b.ParcelID
            AND a.PropertyAddress = b.PropertyAddress
            AND a.SaleDate = b.SaleDate
            AND a.SalePrice = b.SalePrice
            AND a.LegalReference = b.LegalReference
            AND a.UniqueID < b.UniqueID);
---------------------------------------------------------------------------
-- Remove unused column(s)
ALTER TABLE housingdata
DROP COLUMN OwnerAddress, 
DROP COLUMN TaxDistrict, 
DROP COLUMN PropertyAddress,
DROP COLUMN SaleDate;
