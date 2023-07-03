/*
This SQL script contains a series of data cleaning operations on a dataset
of laptop specifications. These operations are intended to transform 
and standardize the data, improving its quality and making it ready for further analysis. 
The operations include handling missing values, removing duplicates, standardizing formats, 
and extracting specific features from complex string values.

Link for the DataSet on Kaggle: https://www.kaggle.com/datasets/ehtishamsadiq/uncleaned-laptop-price-dataset
*/


-- Select all rows in TableName where any of the listed columns are NULL

SELECT * FROM TableName
WHERE (Company IS NULL
OR TypeName IS NULL
OR Inches IS NULL
OR ScreenResolution IS NULL
OR Cpu IS NULL
OR Ram IS NULL
OR Memory IS NULL
OR Gpu IS NULL
OR OpSys IS NULL 
OR Weight IS NULL 
OR Price IS NULL);


-- Delete the duplicate rows from laptops table by comparing all columns

DELETE FROM laptops
WHERE (Company, TypeName, Inches, ScreenResolution, Cpu, Ram, Memory, Gpu, OpSys, Weight, Price) IN (
    SELECT Company, TypeName, Inches, ScreenResolution, Cpu, Ram, Memory, Gpu, OpSys, Weight, Price
    FROM laptops
    GROUP BY Company, TypeName, Inches, ScreenResolution, Cpu, Ram, Memory, Gpu, OpSys, Weight, Price
    HAVING COUNT(*) > 1
);

-- Remove leading and trailing spaces from the specified columns

UPDATE laptops
SET Company = TRIM(Company), TypeName = TRIM(TypeName), Cpu = TRIM(Cpu),
Memory = TRIM(Memory), Gpu = TRIM(Gpu), OpSys = TRIM(OpSys);


-- Extract only the resolution values from ScreenResolution column


UPDATE laptops 
SET ScreenResolution = SUBSTRING(ScreenResolution FROM '[0-9]+x[0-9]+');


-- Delete rows where Inches is '?' and change the data type of Inches to float

DELETE FROM laptops
WHERE Inches = '?';

ALTER TABLE laptops
ALTER COLUMN Inches TYPE float;


-- Extract the CPU speed from Cpu column and convert it to float

UPDATE laptops
SET Cpu = CAST(SUBSTRING(Cpu FROM '[0-9.]+(?=GHz)') AS float);


-- Add new columns StorageType and Rom and split Memory column into them

ALTER TABLE laptops 
ADD COLUMN StorageType varchar(255), 
ADD COLUMN Rom varchar(255);

UPDATE laptops 
SET StorageType = split_part(Memory, ' ', 1),
Rom = CAST(split_part(Memory, ' ', 2) AS varchar);

ALTER TABLE laptops
DROP COLUMN Memory;

-- Drop the Gpu column, because it is not require for analysis

ALTER TABLE laptops
DROP COLUMN gpu;

-- Delete rows where Weight is '?', remove 'kg' from Weight column and convert it to float

DELETE FROM laptops
WHERE Weight = '?';

UPDATE laptops
SET Weight = CAST(REGEXP_REPLACE(Weight, 'kg', '', 'g') AS float);

