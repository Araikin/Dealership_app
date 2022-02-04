-- 0 get price before sell vehicle
SELECT invoice_price
FROM Vehicle
WHERE vin = %s;


-- 1 get vehicle status before sell or repair
SELECT vin
FROM Sale
WHERE vin = %s;


-- 2 sell vehicle
INSERT INTO Sale(vin, customer_id, username, sold_price, sold_date)
SELECT %s, %s, %s, %s, %s
WHERE %s IN (
    SELECT vin FROM Vehicle
) and %s NOT IN (
    SELECT vin FROM Sale
);
