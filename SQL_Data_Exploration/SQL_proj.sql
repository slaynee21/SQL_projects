--Calculate the total revenue generated per product type

SELECT producttype as ProductType, sum(revenuegenerated) as TotalRevenuePerType
FROM sales_data
group by producttype;


--Rank SKUs within each product type based on the revenue generated

SELECT producttype, sku, revenuegenerated,
RANK() OVER(PARTITION BY producttype ORDER BY revenuegenerated DESC) as RevenueRank
FROM sales_data;


--Select SKUs and their suppliers where the shipping costs are greater than the average shipping cost for the same shipping carrier

SELECT s1.sku, s1.suppliername
FROM shipping_data s1
WHERE s1.shippingcosts > (SELECT AVG(s2.shippingcosts) 
                        FROM shipping_data s2 
                        WHERE s1.shippingcarriers = s2.shippingcarriers);


--Select SKUs and their product types where the revenue generated is greater than the 10% of revenue

SELECT sku, producttype
FROM sales_data
WHERE revenuegenerated > (
    SELECT revenuegenerated 
    FROM sales_data 
    ORDER BY revenuegenerated DESC 
    LIMIT 1 OFFSET (SELECT COUNT(*) FROM sales_data)*10/100
);

--Select the supplier with the shortest average lead time

WITH LeadTime_CTE AS (
    SELECT suppliername, AVG(leadtimes) AS AverageLeadTime
    FROM shipping_data
    GROUP BY suppliername
)
SELECT suppliername, AverageLeadTime
FROM LeadTime_CTE
WHERE AverageLeadTime = (SELECT MIN(AverageLeadTime) FROM LeadTime_CTE)
	
	
--Categorize SKUs into 'High cost' and 'Low cost' based on their manufacturing costs for SKUs that have revenue above average

SELECT sku,
    CASE 
        WHEN manufacturingcosts > (SELECT AVG(manufacturingcosts) FROM shipping_data) THEN 'High cost'
        ELSE 'Low cost'
    END as CostCategory
FROM shipping_data
WHERE sku IN (SELECT sku FROM sales_data WHERE revenuegenerated > (SELECT AVG(revenuegenerated) FROM sales_data))


--Rank SKUs within each product type based on the revenue they generated and calculate the average shipping cost for each SKU

SELECT sd.producttype, sd.sku,
    RANK() OVER (PARTITION BY sd.producttype ORDER BY SUM(sd.revenuegenerated) DESC) as RevenueRank,
    ROUND(AVG(shd.shippingcosts)) as AverageRoundedShippingCost
FROM sales_data sd
JOIN shipping_data shd ON sd.sku = shd.sku
GROUP BY sd.producttype, sd.sku


--Select the product type with maximum total revenue

WITH Revenue_CTE AS (
    SELECT producttype, SUM(revenuegenerated) AS TotalRevenue
    FROM sales_data
    GROUP BY producttype
),
MaxRev AS (
    SELECT producttype, MAX(TotalRevenue) as MaxRevenue
    FROM Revenue_CTE
    GROUP BY producttype
)
SELECT r.producttype, r.TotalRevenue, m.MaxRevenue
FROM Revenue_CTE r
JOIN MaxRev m ON r.producttype = m.producttype
WHERE r.TotalRevenue = m.MaxRevenue
	

--Function to calculate the average manufacturing cost

CREATE OR REPLACE FUNCTION CalculateAverageManufacturingCost()
RETURNS FLOAT AS $$
DECLARE AverageCost FLOAT;
BEGIN
    SELECT AVG(manufacturingcosts) INTO AverageCost FROM shipping_data;
    RETURN AverageCost;
END;
$$ LANGUAGE plpgsql;

SELECT CalculateAverageManufacturingCost();

--Trigger to log an entry in AuditLog table every time an update operation is performed on sales_data table

CREATE OR REPLACE FUNCTION log_update() RETURNS TRIGGER AS $$
BEGIN
  INSERT INTO AuditLog (TableName, Operation, DateTime)
  VALUES ('sales_data', 'UPDATE', CURRENT_TIMESTAMP);
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER UpdateSalesDataTrigger
AFTER UPDATE ON sales_data	
FOR EACH ROW EXECUTE PROCEDURE log_update();


--Function to calculate the total revenue generated from a given product type

CREATE OR REPLACE FUNCTION CalculateTotalRevenue(p_producttype varchar)
RETURNS TABLE(TotalRevenue NUMERIC) AS $$
BEGIN
  RETURN QUERY 
  SELECT SUM(revenuegenerated) AS TotalRevenue
  FROM sales_data
  WHERE producttype = p_producttype
  GROUP BY producttype;
END;
$$ LANGUAGE plpgsql;

SELECT * FROM CalculateTotalRevenue('haircare');





