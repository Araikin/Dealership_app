-- 0 Get vehicle details joined with sales
SELECT 		p.vin, vehicle_type, p.manufacturer_name, p.model_name,
            p.model_year, col.color, p.date_added, cast(p.invoice_price as money),
            cast(list_price as money),
			roof_type, back_seat_count, doors_count,
			has_back_door, drivetrain_type, cupholders_count,
			cargo_capacity, cover_type, rear_axles_count,
			"Inventory Clerk", cast(p.sold_price as money), p.sold_date, "Salesperson",
			"Sale Customer type", "Sale Customer Phone",
            "Sale Customer Email", "Sale Customer Address",
			"Sale Business Name", "Sale Business Contact Name",
            "Sale Business Title",  "Sale Individual"
FROM (
	SELECT v.vin, vtypes.vtype AS vehicle_type, v.manufacturer_name, v.model_name,
                                   v.model_year, v.date_added, v.invoice_price,
			v.invoice_price * 1.25 AS list_price,
			co.roof_type, co.back_seat_count, c.doors_count,
			va.has_back_door, s.drivetrain_type, s.cupholders_count,
			t.cargo_capacity, t.cover_type, t.rear_axles_count,
			ic.first_name || ' ' || ic.last_name AS "Inventory Clerk",
			sale.sold_price, sale.sold_date,
			sp.first_name || ' ' || sp.last_name AS "Salesperson",
			sale_ctypes.ctype AS "Sale Customer type",
			sale_cust.phone AS "Sale Customer Phone",
                                   sale_cust.email AS "Sale Customer Email",
			sale_cust.street || ', ' || sale_cust.city || ', ' || sale_cust.state || ', ' || sale_cust.postal_code AS "Sale Customer Address",
			sale_business.business_name AS "Sale Business Name", sale_business.contact_name AS "Sale Business Contact Name", sale_business.contact_title AS "Sale Business Title",
			sale_individual.first_name || ' ' || sale_individual.last_name AS "Sale Individual"
	FROM Vehicle AS v
	LEFT OUTER JOIN Convertible AS co ON co.vin=v.vin
	LEFT OUTER JOIN Car AS c ON c.vin=v.vin
	LEFT OUTER JOIN Truck AS t ON t.vin=v.vin
	LEFT OUTER JOIN Suv AS s ON s.vin=v.vin
	LEFT OUTER JOIN VanMinivan AS va ON va.vin=v.vin
	LEFT OUTER JOIN (
		SELECT vin, 'Car' AS vtype FROM Car
		UNION ALL
		SELECT vin, 'Convertible' AS vtype FROM Convertible
		UNION ALL
		SELECT vin, 'SUV' as vtype FROM Suv
        UNION ALL
		SELECT vin, 'Truck' AS vtype FROM Truck
		UNION ALL
		SELECT vin, 'Van/Minivan' AS vtype FROM VanMinivan
	) vtypes ON vtypes.vin = v.vin
	INNER JOIN Users AS ic ON ic.username = v.Username
	LEFT OUTER JOIN Sale ON Sale.vin = v.vin
	LEFT OUTER JOIN Users AS sp ON sp.username = Sale.username
	LEFT OUTER JOIN Customer AS sale_cust ON sale_cust.customer_id = sale.customer_id
	LEFT OUTER JOIN (
		SELECT customer_id, 'Business' AS ctype FROM Business
		UNION ALL
		SELECT customer_id, 'Individual' AS ctype FROM Individual
	) sale_ctypes ON sale_ctypes.customer_id = Sale.customer_id
	LEFT OUTER JOIN Business AS sale_business ON sale_business.customer_id = Sale.customer_id
	LEFT OUTER JOIN Individual AS sale_individual ON sale_individual.customer_id = Sale.customer_id
	WHERE v.vin = {}
) AS p
INNER JOIN (
	SELECT vin, string_agg(vc.color, ', ') AS color FROM VehicleColors vc
	GROUP BY vin
) AS col ON col.vin = p.vin;


-- 1 Get repairs info for manager and owner
SELECT
	Repair.start_date,
	Repair.end_date,
	cast(COALESCE(sum(Part.price * Part.quantity), 0) as money) AS "Parts Cost",
	cast(COALESCE(Repair.labor_charges, 0) as money) AS "Labor Charges",
	cast(COALESCE(sum(Part.price * Part.quantity), 0) as money) + cast(COALESCE(Repair.labor_charges, 0) as money) AS "Total Cost",
	customers.customer_name AS "Customer Name",
	Users.first_name || ' ' || Users.last_name AS "Service Writer Name"
FROM Vehicle
INNER JOIN Repair ON Vehicle.vin = Repair.vin
LEFT OUTER JOIN Part ON Part.start_date = Repair.start_date AND Part.vin = Repair.vin
JOIN
	(SELECT customer_id, first_name || ' ' || last_name AS customer_name FROM Individual
	UNION ALL
	SELECT customer_id, business_name AS customer_name FROM Business
	) AS customers ON Repair.customer_id = customers.customer_id
JOIN Users ON Users.username = Repair.username
WHERE Vehicle.vin = %s
GROUP BY Repair.start_date,
		Repair.end_date,
		labor_charges,
		customer_name,
		Users.first_name || ' ' || Users.last_name;