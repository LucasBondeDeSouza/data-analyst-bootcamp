-- Stored Procedures

CREATE PROCEDURE large_salaries()
SELECT *
FROM employee_salary
WHERE salary >= 50000;


DELIMITER $$
CREATE PROCEDURE large_salaries3()
BEGIN
    SELECT *
    FROM employee_salary
    WHERE salary >= 50000;
    SELECT *
    FROM employee_salary
    WHERE salary >= 10000;
END $$
DELIMITER ;


DELIMITER $$
CREATE PROCEDURE large_salaries4(employee_id INT)
BEGIN
    SELECT *
    FROM employee_salary
    WHERE employee_id = employee_id;
END $$
DELIMITER ;