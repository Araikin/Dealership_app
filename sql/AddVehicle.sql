-- 0 Insert vehicle
INSERT INTO Vehicle (vin, manufacturer_name, model_name, model_year, invoice_price, description, date_added, username)
 SELECT %s, %s, %s, %s, %s, %s, %s, %s
 WHERE NOT EXISTS (SELECT vin FROM vehicle WHERE vin = %s);

-- 1 Insert vehicle colors
INSERT INTO VehicleColors VALUES (%s, %s);

-- 2 Insert into vanminivan
INSERT INTO VanMinivan VALUES (%s, %s);

-- 3 Insert into car
INSERT INTO Car VALUES (%s, %s);

-- 4 Insert into suv
INSERT INTO SUV VALUES (%s, %s, %s);

-- 5 Insert into truck
INSERT INTO Truck VALUES (%s, %s, %s, %s);

-- 6 Insert into convertible
INSERT INTO Convertible VALUES (%s, %s, %s);

-- 7 Check if vin exists
SELECT vin FROM vehicle WHERE vin = %s;