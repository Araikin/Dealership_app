-- 0 Sales by color
SELECT all_colors.color,
		COALESCE(sum(CASE WHEN Sale.sold_date >
		(SELECT max(Sale.sold_date) - INTERVAL '30 day' FROM Sale) THEN 1 ELSE 0 END),0) AS "Sales in Previous 30 Days",
		COALESCE(sum(CASE WHEN Sale.sold_date >
		(SELECT max(Sale.sold_date) - INTERVAL '1 year' FROM Sale) THEN 1 ELSE 0 END),0) AS "Sales in Previous Year",
		COALESCE(count(Sale.sold_date),0) AS "All Sales"
FROM (
	VALUES 	('Aluminum'), ('Beige'), ('Black'), ('Blue'), ('Brown'), ('Bronze'), ('Claret'),
			('Copper'), ('Cream'), ('Gold'), ('Gray'), ('Green'), ('Maroon'), ('Metallic'),
			('Navy'), ('Orange'), ('Pink'), ('Purple'), ('Red'), ('Rose'), ('Rust'),
			('Silver'), ('Tan'), ('Turquoise'), ('White'), ('Yellow')
) all_colors(color)
LEFT OUTER JOIN VehicleColors USING (color)
LEFT OUTER JOIN (
	SELECT vin, sold_date FROM sale
	WHERE vin NOT IN (SELECT vin FROM vehiclecolors GROUP BY vin HAVING count(color) > 1)
) AS Sale ON vehiclecolors.vin = Sale.vin
GROUP BY 1
UNION ALL
(SELECT 'Multiple' AS "color",
		COALESCE(sum(CASE WHEN Sale.sold_date >
		(SELECT max(Sale.sold_date) - INTERVAL '30 day' FROM Sale) THEN 1 ELSE 0 END),0) AS "Sales in Previous 30 Days",
		COALESCE(sum(CASE WHEN Sale.sold_date >
		(SELECT max(Sale.sold_date) - INTERVAL '1 year' FROM Sale) THEN 1 ELSE 0 END),0) AS "Sales in Previous Year",
		count("num") AS "All Sales"
FROM (
	SELECT  VehicleColors.vin, 'Multiple' AS "color",  count(color) AS "num" FROM VehicleColors
	JOIN Sale USING (vin)
	GROUP BY VehicleColors.vin
	HAVING count(color) > 1) AS x
LEFT OUTER JOIN Sale USING (vin)
GROUP BY "color")
ORDER BY 1;


-- 1 Sales by type
SELECT vtypes.vtype,
	COALESCE(sum(CASE WHEN Sale.sold_date >
		(SELECT max(Sale.sold_date) - INTERVAL '30 day' FROM Sale) THEN 1 ELSE 0 END),0) AS prev_30,
	COALESCE(sum(CASE WHEN Sale.sold_date >
		(SELECT max(Sale.sold_date) - INTERVAL '1 year' FROM Sale) THEN 1 ELSE 0 END),0) AS prev_yr,
    COALESCE(count(Sale.sold_date),0) AS all_time
FROM (
	SELECT vin, 'Car' AS vtype FROM Car UNION ALL
	SELECT vin, 'Convertible' AS vtype FROM Convertible UNION ALL
	SELECT vin, 'Truck' AS vtype FROM Truck UNION ALL
	SELECT vin, 'Van/Minivan' AS vtype FROM VanMinivan UNION ALL
	SELECT vin, 'SUV' AS vtype FROM Suv
	UNION ALL (SELECT '', 'Truck' WHERE NOT EXISTS (SELECT vin FROM Truck))
	UNION ALL (SELECT '', 'Car' WHERE NOT EXISTS (SELECT vin FROM Car))
	UNION ALL (SELECT '', 'Convertible' WHERE NOT EXISTS (SELECT vin FROM Convertible))
	UNION ALL (SELECT '', 'SUV' WHERE NOT EXISTS (SELECT vin FROM SUV))
	UNION ALL (SELECT '', 'VanMinivan' WHERE NOT EXISTS (SELECT vin FROM VanMinivan))
) vtypes
LEFT JOIN Vehicle ON Vehicle.vin = vtypes.vin
LEFT JOIN Sale ON Sale.vin = Vehicle.vin
GROUP BY vtypes.vtype
ORDER BY vtypes.vtype;


-- 2 Sales by manufacturer
SELECT manufacturer_name,
	COALESCE(sum(CASE WHEN Sale.sold_date >
		(SELECT max(Sale.sold_date) - INTERVAL '30 day' FROM Sale) THEN 1 ELSE 0 END),0) AS "Sales in Previous 30 Days",
	COALESCE(sum(CASE WHEN Sale.sold_date >
		(SELECT max(Sale.sold_date) - INTERVAL '1 year' FROM Sale) THEN 1 ELSE 0 END),0) AS "Sales in Previous Year",
	COALESCE(count(Sale.sold_date),0) AS "Sales over All Time"
FROM Vehicle
JOIN Sale USING (vin)
GROUP BY manufacturer_name
ORDER BY 1;


-- 3 Gross customer income main
SELECT
    c.customer_id,
    c.customer_name AS "Customer Name",
    LEAST("first sale", "first repair") AS "Date of First Sale or Repair",
    GREATEST("last sale", "last repair") AS "Date of Most Recent Sale or Repair",
    COALESCE("Sales count",0) AS "Number of Sales",
    COALESCE("Repairs count", 0) AS "Number of Repairs",
    CAST(COALESCE("sale income",0) + COALESCE(pr.labor_charges,0) AS money) +
    CAST(COALESCE(pr.parts_cost, 0) AS money) AS "Gross Income"
FROM (
    SELECT customer_id, first_name || ' ' || last_name AS customer_name
    FROM Individual
    UNION ALL
    SELECT customer_id,business_name AS customer_name
    FROM Business
) AS c
LEFT OUTER JOIN (
    SELECT Sale.customer_id, COALESCE(sum(Sale.sold_price),0) AS "sale income",
        COALESCE(Count(Sale.sold_price),0) AS "Sales count",
        MIN(Sale.sold_date) AS "first sale", MAX(Sale.sold_date) AS "last sale"
    FROM Sale
    GROUP BY Sale.customer_id) s ON s.customer_id = c.customer_id
LEFT OUTER JOIN (
    SELECT rp.customer_id, COALESCE(sum(labor_charges),0) AS labor_charges,
        COALESCE(sum(part_cost),0) AS parts_cost,
        COALESCE(count(labor_charges), 0) AS "Repairs count",
        MIN(rp.start_date) AS "first repair", MAX(rp.start_date) AS "last repair"
    FROM (
        SELECT Repair.customer_id,
            Repair.start_date,
            Repair.labor_charges,
            COALESCE (SUM(Part.price * Part.quantity), 0) AS part_cost
        FROM Repair
        LEFT OUTER JOIN Part ON Part.start_date = Repair.start_date AND
        Part.vin = Repair.vin
        GROUP BY (Repair.start_date, Repair.vin)
    ) rp
    GROUP BY rp.customer_id
) pr ON pr.customer_id = c.customer_id
ORDER BY "Gross Income" DESC, "Date of Most Recent Sale or Repair" DESC
LIMIT 15;


-- 4 Gross customer income - drill down Sales
SELECT
    Vehicle.vin AS "VIN",
    Vehicle.manufacturer_name AS "Manufacturer",
    Vehicle.model_name,
    Vehicle.model_year,
    Sale.sold_date AS "Sale Date",
    CAST(COALESCE(Sale.sold_price, 0) as money) AS "Sold Price",
    Users.first_name || ' ' || Users.last_name AS "Salesperson"
FROM Vehicle
INNER JOIN Sale ON Sale.vin = Vehicle.vin
INNER JOIN Users ON Users.username = Sale.username
WHERE Sale.customer_id = %s
ORDER BY "Sale Date" DESC, "VIN";


-- 5 Gross customer income - drill down Repairs
SELECT
    Repair.start_date AS "Repair Start Date",
    Repair.end_date AS "Repair End Date",
    Repair.vin AS "VIN",
    Repair.odometer AS "Odometer",
    CAST(COALESCE(SUM(Part.price * Part.quantity), 0) AS money) AS "Parts Cost",
    CAST(COALESCE(Repair.labor_charges, 0) AS money) AS "Labor Cost",
    CAST(COALESCE(SUM(Part.price * Part.quantity), 0) + COALESCE(Repair.labor_charges, 0) AS money) AS "Total
    Cost",
    Users.first_name || ' ' || Users.last_name AS "Service Writer"
FROM Repair
LEFT OUTER JOIN Part ON Part.start_date = Repair.start_date AND Part.vin = Repair.vin
INNER JOIN Users ON Users.username = Repair.username
WHERE Repair.customer_id = %s
GROUP BY (Repair.start_date, Repair.vin, Users.first_name || ' ' || Users.last_name)
ORDER BY "Repair Start Date" DESC, "Repair End Date" DESC, "VIN";


-- 6 Repairs by Manufacturer
SELECT m.manufacturer_name AS "Manufacturer",
    sum(CASE WHEN m.start_date IS NULL THEN 0 ELSE 1 END) AS "Count of Repairs",
    CAST(COALESCE(sum(m.part_cost), 0) AS money) AS "Sum of all Part costs",
    CAST(COALESCE(SUM(m.labor_charges),0) AS money) AS "Sum of all Labor Costs",
    CAST(COALESCE(SUM(m.labor_charges),0) + COALESCE(sum(m.part_cost), 0) AS money)
AS "Sum of all Total Repair Costs"
FROM (
    SELECT manufacturer.manufacturer_name,
        Repair.start_date,
        Repair.labor_charges,
        COALESCE (SUM(Part.price * Part.quantity), 0) AS part_cost
    FROM manufacturer
    LEFT OUTER JOIN vehicle USING (manufacturer_name)
    FULL OUTER JOIN Repair ON Vehicle.vin = Repair.vin
    LEFT OUTER JOIN Part ON Part.start_date = Repair.start_date AND Part.vin = Repair.vin
    GROUP BY (manufacturer.manufacturer_name, Repair.start_date, Vehicle.vin, Repair.labor_charges)
) m
GROUP BY m.manufacturer_name
ORDER BY m.manufacturer_name;


-- 7 Repairs by Type
SELECT v.vehicle_type AS "Vehicle Type",
    count(v.start_date) AS "Count of Repairs",
    CAST(COALESCE(sum(v.part_cost), 0) AS money) AS "Sum of all Part costs",
    CAST(COALESCE(SUM(v.labor_charges),0) AS money) AS "Sum of all Labor Costs",
    CAST(COALESCE(SUM(v.labor_charges),0) + COALESCE(sum(v.part_cost), 0) AS money) AS "Sum of all Total Repair Costs"
FROM (
    SELECT vehicle_types.vehicle_type, Repair.start_date, Repair.labor_charges,
        COALESCE(sum(Part.price * Part.quantity), 0) AS part_cost
    FROM (
        SELECT vin, 'Car' AS vehicle_type FROM Car
        UNION ALL
        SELECT vin, 'Convertible' AS vehicle_type FROM Convertible
        UNION ALL
        SELECT vin, 'SUV' AS vehicle_type FROM SUV
        UNION ALL
        SELECT vin, 'Truck' AS vehicle_type FROM Truck
        UNION ALL
        SELECT vin, 'VanMinivan' AS vehicle_type FROM VanMinivan
    ) vehicle_types
    NATURAL JOIN Vehicle
    INNER JOIN Repair ON Repair.vin = Vehicle.vin
    LEFT OUTER JOIN Part ON Part.start_date = Repair.start_date AND Part.vin = Repair.vin
    WHERE LOWER(Vehicle.manufacturer_name) = LOWER(%s)
    GROUP BY (vehicle_types.vehicle_type, Vehicle.vin, Repair.start_date, Repair.labor_charges)
) v
GROUP BY v.vehicle_type
ORDER BY 2 DESC;


-- 8 Repairs by Model
SELECT models.model_name AS "Model Name",
    count(models.start_date) AS "Count of Repairs",
    CAST(COALESCE(sum(models.part_cost), 0) AS money) AS "Sum of all Part Costs",
    CAST(COALESCE(SUM(models.labor_charges),0) AS money) AS "Sum of all Labor Costs",
    CAST(COALESCE(SUM(models.labor_charges),0) + COALESCE(sum(models.part_cost), 0) AS money) AS "Sum of all Total Repair Costs"
FROM (
    SELECT vehicle_types.vehicle_type,
        Vehicle.model_name,
        Repair.start_date,
        Repair.labor_charges,
        COALESCE(sum(Part.price * Part.quantity), 0) AS part_cost
    FROM (
        SELECT vin, 'Car' AS vehicle_type FROM Car
        UNION ALL
        SELECT vin, 'Convertible' AS vehicle_type FROM Convertible
        UNION ALL
        SELECT vin, 'SUV' AS vehicle_type FROM SUV
        UNION ALL
        SELECT vin, 'Truck' AS vehicle_type FROM Truck
        UNION ALL
        SELECT vin, 'VanMinivan' AS vehicle_type FROM VanMinivan
    ) vehicle_types
    INNER JOIN Vehicle ON Vehicle.vin = vehicle_types.vin
    INNER JOIN Repair ON Repair.vin = Vehicle.vin
    LEFT OUTER JOIN Part ON Part.start_date = Repair.start_date AND Part.vin = Repair.vin
    WHERE LOWER(Vehicle.manufacturer_name) = LOWER(%s) AND LOWER(vehicle_types.vehicle_type) = LOWER(%s)
    GROUP BY (vehicle_types.vehicle_type, Vehicle.model_name, Vehicle.vin, Repair.start_date, Repair.labor_charges)
    ) models
GROUP BY models.model_name
ORDER BY 2 DESC;


-- 9 Below Cost Sales
SELECT sold_date AS "Sold Date",
        CAST(invoice_price AS money) AS "Invoice Price",
        CAST(sold_price AS money) AS "Sold Price",
        ROUND(((100 * sold_price)/invoice_price),2) AS "Ratio",
        users.first_name || ' ' || users.last_name AS "Salesperson",
        customers.customer_name AS "Customer Name"
FROM Vehicle
INNER JOIN Sale ON Vehicle.vin = Sale.vin
INNER JOIN Salesperson ON Salesperson.username = Sale.username
INNER JOIN Users ON Users.username = Salesperson.username
JOIN (
    (SELECT customer_id, first_name || ' ' || last_name AS customer_name
    FROM Individual
    UNION ALL
    SELECT customer_id, business_name AS customer_name
    FROM Business)) customers ON customers.customer_id = Sale.customer_id
WHERE Sale.sold_price < Vehicle.invoice_price
ORDER BY 1 DESC, "Ratio" DESC;


-- 10 Average Time in Inventory
SELECT vtypes.vtype AS "Vehicle Type",
        CASE
          WHEN (avg(Sale.sold_date - Vehicle.date_added + 1) > 0)
              THEN CAST(round(avg(Sale.sold_date - Vehicle.date_added + 1)) AS varchar)
          ELSE 'N/A'
        END AS "Avg days in inventory"
FROM (
   SELECT vin, 'Car' AS vtype FROM Car UNION ALL
   SELECT vin, 'Convertible' AS vtype FROM Convertible UNION ALL SELECT vin, 'SUV' AS vtype FROM SUV UNION ALL
   SELECT vin, 'Truck' AS vtype FROM Truck UNION ALL
   SELECT vin, 'Van/Minivan' AS vtype FROM VanMinivan
) AS vtypes
NATURAL JOIN Vehicle
LEFT OUTER JOIN Sale ON vtypes.vin = Sale.vin
GROUP BY 1
ORDER BY 1;


-- 11 Parts Statistics
SELECT vendor_name AS "Vendor name",
        count(part_no) AS "Number of parts",
        CAST(sum(price * quantity) AS money) AS "Total amount spent"
FROM Part
GROUP BY vendor_name ORDER BY 3 DESC;


-- 12 Monthly Sales - Main
SELECT to_char(Sale.sold_date, 'YYYY-MM') AS "Year and month",
        count(Sale.vin) AS "Total vehicles sold",
        CAST(sum(Sale.sold_price) AS money) AS "Total sales income",
        CAST(sum(Sale.sold_price - Vehicle.invoice_price) AS money) AS "Total net income",
        round(100 * sum(Sale.sold_price) / sum(Vehicle.invoice_price)) AS "Ratio, %"
FROM Vehicle
INNER JOIN Sale ON Vehicle.vin = Sale.vin
GROUP BY to_char(Sale.sold_date, 'YYYY-MM')
ORDER BY 1 DESC;


-- 13 Monthly Sales - Drill down YYYY-MM
SELECT Users.first_name || ' ' || Users.last_name AS "First, Last name",
       count(Sale.vin) AS "Total vehicles sold",
       CAST(sum(Sale.sold_price) AS money) AS "Total sales"
FROM Sale
NATURAL JOIN Users
WHERE to_char(Sale.sold_date, 'YYYY-MM') LIKE %s
GROUP BY 1
ORDER BY 2 DESC, 3 DESC;