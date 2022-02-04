-- 0 Add customer individual
WITH cust_individual AS (
    INSERT INTO Customer (email, phone, street, city, state, postal_code)
    SELECT %s, %s, %s, %s, %s, %s
    WHERE NOT EXISTS (SELECT dl_no FROM Individual WHERE LOWER(dl_no) = LOWER(%s))
    RETURNING customer_id
)
INSERT INTO Individual (customer_id, dl_no, first_name, last_name)
SELECT cust_individual.customer_id, %s AS dl_no, %s AS first_name, %s AS last_name
FROM cust_individual
RETURNING customer_id;


-- 1 Add customer business
WITH cust_business AS (
    INSERT INTO Customer (email, phone, street, city, state, postal_code)
    SELECT %s, %s, %s, %s, %s, %s
    WHERE NOT EXISTS (SELECT tax_id_no FROM Business WHERE LOWER(tax_id_no) = LOWER(%s))
    RETURNING customer_id
)
INSERT INTO Business (customer_id, tax_id_no, business_name, contact_name,contact_title)
SELECT cust_business.customer_id, %s AS tax_id, %s AS business_name, %s AS contact_name, %s AS title
FROM cust_business
RETURNING customer_id;


-- 2 Lookup customer by customerType and IdNo
SELECT cust_type as "Customer Type",
    first_name AS "First Name",
    last_name AS "Last Name",
    business_name AS "Business Name",
    contact_title AS "Contact Title",
    contact_name AS "Contact Name",
    phone AS "Phone",
    email AS "Email",
    street || ', ' || city || ', ' || state || ', ' || postal_code AS "Address",
    Customer.customer_id AS "Customer Id"
FROM
(
    SELECT customer_id, 'Business' AS cust_type, tax_id_no AS "Id"
    FROM Business
    UNION ALL
    SELECT customer_id, 'Individual' AS cust_type, dl_no AS "Id"
    FROM Individual
) cust_types
NATURAL JOIN Customer
LEFT OUTER JOIN Business ON Business.customer_id = Customer.customer_id
LEFT OUTER JOIN Individual ON Individual.customer_id = Customer.customer_id
WHERE cust_type = %s AND LOWER("Id") = LOWER(%s);


-- 3 Lookup customer by customer_id
SELECT cust_type as "Customer Type",
    first_name AS "First Name",
    last_name AS "Last Name",
    business_name AS "Business Name",
    contact_title AS "Contact Title",
    contact_name AS "Contact Name",
    phone AS "Phone",
    email AS "Email",
    street || ', ' || city || ', ' || state || ', ' || postal_code AS "Address"
FROM
(
    SELECT customer_id, 'Business' AS cust_type, tax_id_no AS "Id" FROM Business
    UNION ALL
    SELECT customer_id, 'Individual' AS cust_type, dl_no AS "Id" FROM Individual
) cust_types
NATURAL JOIN Customer
LEFT OUTER JOIN Business ON Business.customer_id = Customer.customer_id
LEFT OUTER JOIN Individual ON Individual.customer_id = Customer.customer_id
WHERE Customer.customer_id = %s;