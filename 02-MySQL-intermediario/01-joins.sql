-- Joins

SELECT dem.employee_id, age, occupation  -- Seleciona colunas específicas da tabela 'employee_demographics'
FROM employee_demographics AS dem        -- Usa a tabela 'employee_demographics' com o alias 'dem'
INNER JOIN employee_salary AS sal        -- Realiza um INNER JOIN com a tabela 'employee_salary', usando o alias 'sal'
ON dem.employee_id = sal.employee_id;    -- Condição de junção: relaciona os registros que têm o mesmo 'employee_id'


-- Outros Joins

SELECT *                               -- Seleciona todas as colunas de ambas as tabelas
FROM employee_demographics AS dem      -- Define a tabela 'employee_demographics' com o alias 'dem'
LEFT JOIN employee_salary AS sal       -- Faz um LEFT JOIN com a tabela 'employee_salary', usando o alias 'sal'
ON dem.employee_id = sal.employee_id;  -- Condição de junção: relaciona os registros que têm o mesmo 'employee_id'


SELECT *                               -- Seleciona todas as colunas de ambas as tabelas
FROM employee_demographics AS dem      -- Define a tabela 'employee_demographics' com o alias 'dem'
RIGHT JOIN employee_salary AS sal      -- Faz um RIGHT JOIN com a tabela 'employee_salary', usando o alias 'sal'
ON dem.employee_id = sal.employee_id;  -- Condição de junção: relaciona os registros que têm o mesmo 'employee_id'


-- Self Join

SELECT emp1.employee_id AS emp_santa,
emp1.first_name AS first_name_santa,
emp1.last_name AS last_name_santa,
emp2.employee_id AS emp_santa,
emp2.first_name AS first_name_santa,
emp2.last_name AS last_name_santa
FROM employee_salary emp1
JOIN employee_salary emp2
ON emp1.employee_id + 1 = emp2.employee_id;


-- Jutando multiplas tabelas juntas

SELECT *
FROM employee_demographics AS dem       
INNER JOIN employee_salary AS sal        
ON dem.employee_id = sal.employee_id
INNER JOIN parks_departments pd
ON sal.dept_id = pd.department_id;