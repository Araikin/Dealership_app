-- 0 Vehicle details
SELECT Vehicle.vin AS "VIN",
	vehicle_types.vehicle_type AS "Vehicle Type",
	Vehicle.model_year AS "Year",
	Vehicle.manufacturer_name AS "Manufacturer",
	Vehicle.model_name AS "Model",
	string_agg(VehicleColors.color, ', ') AS "Color"
FROM (
	SELECT vin, 'Car' AS vehicle_type FROM Car
	UNION ALL
	SELECT vin, 'Convertible' AS vehicle_type  FROM Convertible
	UNION ALL
	SELECT vin, 'SUV' as vehicle_type FROM Suv
	UNION ALL
	SELECT vin, 'Truck' AS vehicle_type FROM Truck
	UNION ALL
	SELECT vin, 'Van/Minivan' AS  vehicle_type FROM VanMinivan
) vehicle_types
NATURAL JOIN Vehicle
NATURAL JOIN VehicleColors
WHERE vehicle_types.vin = UPPER(%s)
GROUP BY 1,2,3,4,5;


-- 1 Get open repair
SELECT
	Repair.start_date,
	Repair.end_date,
	COALESCE(sum(Part.price * Part.quantity), 0) AS "Parts Cost",
	Repair.labor_charges AS "Labor Charges",
	COALESCE(sum(Part.price * Part.quantity), 0) + Repair.labor_charges AS "Total Cost",
	customers.customer_name AS "Customer Name",
	Users.first_name || ' ' || Users.last_name AS "Service Writer Name"
FROM Vehicle
INNER JOIN Repair ON Vehicle.vin = Repair.vin
LEFT OUTER JOIN Part ON Part.start_date = Repair.start_date AND Part.vin = Repair.vin
JOIN(
    SELECT customer_id, first_name || ' ' || last_name AS customer_name
    FROM Individual
	UNION ALL
	SELECT customer_id, business_name AS customer_name
    FROM Business
) AS customers ON Repair.customer_id = customers.customer_id
JOIN Users ON Users.username = Repair.username
WHERE Vehicle.vin = UPPER(%s) AND
      Repair.end_date IS NULL
GROUP BY Repair.start_date,
         Repair.end_date,
         labor_charges,
         customer_name,
         Users.first_name || ' ' || Users.last_name;


-- 2 Get labor charge
SELECT labor_charges, description
FROM repair
WHERE vin = %s AND
      end_date IS NULL
ORDER BY start_date DESC
LIMIT 1;


-- 3 Add repair
INSERT INTO repair(start_date, vin, customer_id, username, odometer)
VALUES (%s, %s, %s, %s, %s);


-- 4 Update repair
UPDATE repair
SET labor_charges = %s, description = %s
WHERE start_date = %s AND
      end_date IS NULL AND
      vin = %s;


-- 5 Add part
INSERT INTO part(part_no, start_date, vin, vendor_name, price, quantity)
VALUES (%s, %s, %s, %s, %s, %s);


-- 6 Get start_date
SELECT max(start_date)
FROM repair
WHERE vin = %s;


-- 7 Get current price
SELECT price AS current_price
FROM Part
WHERE part_no = %s AND
      vendor_name = %s;


-- 8 Complete repair
UPDATE repair SET end_date = %s
WHERE vin = %s AND start_date = %s;
