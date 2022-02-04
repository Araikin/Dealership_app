-- 0 Search Results for Available Vehicles
SELECT v.vin AS "VIN",
       v.vtype AS "Vehicle Type",
       v.myear AS "Model Year",
	   v.manufacturer AS "Manufacturer",
       v.mname AS "Model",
       v.vcols AS "Color",
	   cast(v.list_price as money) AS "List Price",
       v.description AS "Description",
	   v.status AS "Status",
       v.desc_match AS "Description Match"
FROM (
	SELECT Vehicle.vin AS vin,
	        vehicle_types.vehicle_type AS vtype,
		    Vehicle.model_year AS myear,
	        Vehicle.manufacturer_name AS manufacturer,
		    Vehicle.model_name AS mname,
	        string_agg(VehicleColors.color, ', ') AS vcols,
		    Vehicle.invoice_price * 1.25 AS list_price,
	        Vehicle.description AS description,
	        CASE
	            WHEN Sale.vin IS NULL THEN 'Available'
	            ELSE 'Sold'
	        END AS status ,
	        CASE
	           WHEN ({} <> '%%' AND {} IS NOT NULL AND Vehicle.description LIKE {})
	                THEN 'YES'
                ELSE 'NO'
	        END AS desc_match
	FROM (
        SELECT vin, 'Car' AS vehicle_type FROM Car
        UNION ALL
		SELECT vin, 'Convertible' AS vehicle_type FROM Convertible
		UNION ALL
		SELECT vin, 'SUV' AS vehicle_type FROM SUV
		UNION ALL
		SELECT vin, 'Truck' AS vehicle_type FROM Truck
		UNION ALL
		SELECT vin, 'Van/Minivan' AS vehicle_type FROM VanMinivan
	) vehicle_types
	NATURAL JOIN Vehicle
	NATURAL JOIN VehicleColors
	FULL OUTER JOIN Sale ON Vehicle.vin = Sale.vin
	WHERE ({} IS NULL OR {} = '' OR Vehicle.vin = {}) AND
            ({} IS NULL OR invoice_price * 1.25 >= cast(coalesce(nullif({},''),'0') as decimal)) AND
            (({} IS NULL) OR invoice_price * 1.25 <= cast(coalesce(nullif({},''),CAST((SELECT max(1.25 * invoice_price) FROM Vehicle) AS varchar)) as decimal)) AND
            ({} IS NULL OR {} = '' OR manufacturer_name = {}) AND
            ({} IS NULL OR CAST({} AS varchar) = '' OR CAST(model_year AS varchar) = {}) AND
            ({} IS NULL OR {} = '' OR vehicle_type = {}) AND
            (manufacturer_name LIKE {} OR model_name LIKE {} OR CAST(model_year AS varchar) LIKE {} OR
             description LIKE {} OR {} IS NULL OR {} = '%%') AND
			(Sale.vin IS NULL)
	GROUP BY 1, 2, 3, 4, 5, 7, 8, 9, 10
	ORDER BY Vehicle.vin
) v
WHERE LOWER(v.vcols) LIKE LOWER({});

-- 1 Get total vehicles available for purchase
SELECT count(*) FROM vehicle v WHERE v.vin NOT IN (SELECT s.vin FROM sale   s);

-- 2 Populate manufacturer and color dropdowns
-- Pass manufacturer_name and vehicle for Manufacturer dropdown
-- Pass color and vehiclecolors for Color dropdown
SELECT DISTINCT {} FROM {} ORDER BY 1;

-- 3 All Search Results
SELECT v.vin AS "VIN",
       v.vtype AS "Vehicle Type",
       v.myear AS "Model Year",
	   v.manufacturer AS "Manufacturer",
       v.mname AS "Model",
       v.vcols AS "Color",
       cast(v.list_price as money) AS "List Price",
       v.description AS "Description",
	   v.status AS "Status",
       v.desc_match AS "Description Match"
FROM (
	SELECT Vehicle.vin AS vin,
	        vehicle_types.vehicle_type AS vtype,
		    Vehicle.model_year AS myear,
	        Vehicle.manufacturer_name AS manufacturer,
		    Vehicle.model_name AS mname,
	        string_agg(VehicleColors.color, ', ') AS vcols,
		    Vehicle.invoice_price * 1.25 AS list_price,
	        Vehicle.description AS description,
	        CASE
	            WHEN Sale.vin IS NULL THEN 'Available'
	            ELSE 'Sold'
	        END AS status,
	        CASE
                WHEN ({} <> '%%' AND {} IS NOT NULL AND Vehicle.description LIKE {})
                    THEN 'YES'
                ELSE 'NO'
	        END AS desc_match
	FROM (
        SELECT vin, 'Car' AS vehicle_type FROM Car
        UNION ALL
		SELECT vin, 'Convertible' AS vehicle_type FROM Convertible
		UNION ALL
		SELECT vin, 'SUV' AS vehicle_type FROM SUV
		UNION ALL
		SELECT vin, 'Truck' AS vehicle_type FROM Truck
		UNION ALL
		SELECT vin, 'Van/Minivan' AS vehicle_type FROM VanMinivan
	) vehicle_types
	NATURAL JOIN Vehicle
	NATURAL JOIN VehicleColors
	FULL OUTER JOIN Sale ON Vehicle.vin = Sale.vin
	WHERE ({} IS NULL OR {} = '' OR Vehicle.vin = {}) AND
            ({} IS NULL OR invoice_price * 1.25 >= cast(coalesce(nullif({},''),'0') as decimal)) AND
            (({} IS NULL) OR invoice_price * 1.25 <= cast(coalesce(nullif({},''),CAST((SELECT max(1.25 * invoice_price) FROM Vehicle) AS varchar)) as decimal)) AND
            ({} IS NULL OR {} = '' OR manufacturer_name = {}) AND
            ({} IS NULL OR CAST({} AS varchar) = '' OR CAST(model_year AS varchar) = {}) AND
            ({} IS NULL OR {} = '' OR vehicle_type = {}) AND
            (manufacturer_name LIKE {} OR model_name LIKE {} OR
                CAST(model_year AS varchar) LIKE {} OR description LIKE {} OR {} IS NULL OR {} = '%%') 
	GROUP BY 1, 2, 3, 4, 5, 7, 8, 9, 10
	ORDER BY Vehicle.vin ASC
) v
WHERE LOWER(v.vcols) LIKE LOWER({});