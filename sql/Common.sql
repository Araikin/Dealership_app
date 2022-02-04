-- 0 Display single column tuples from table
SELECT {} FROM {};

-- 1 Get username
SELECT username
FROM {};

-- 2 Verify password
SELECT password
FROM users
WHERE LOWER(username) = LOWER(%s);