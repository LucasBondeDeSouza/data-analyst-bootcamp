-- Data Cleaning

-- 1. Remover Duplicado

-- Cria uma nova tabela chamada layoffs_staging com a mesma estrutura da tabela layoffs
CREATE TABLE layoffs_staging
Like layoffs;

-- Copia todos os dados da tabela layoffs original para a nova tabela layoffs_staging
INSERT layoffs_staging
SELECT *
FROM layoffs;

-- Verifica possíveis duplicatas adicionando um número de linha para cada grupo de colunas relevantes
SELECT *,
ROW_NUMBER() OVER(
    PARTITION BY company, industry, total_laid_off, percentage_laid_off, `date`
) AS row_num
FROM layoffs_staging;

-- Cria uma CTE (common table expression) chamada duplicate_cte para identificar duplicatas
-- Usa ROW_NUMBER para numerar linhas com base em colunas que definem uma duplicata
WITH duplicate_cte AS
(
SELECT *,
ROW_NUMBER() OVER(
PARTITION BY company, location,
industry, total_laid_off, percentage_laid_off, `date`, stage,
country, funds_raised_millions) AS row_num
FROM layoffs_staging
)
-- Exibe apenas as duplicatas (ou seja, linhas com row_num > 1)
SELECT *
FROM duplicate_cte
WHERE row_num > 1;

-- Verifica os registros da empresa 'Casper' para confirmar visualmente as duplicatas
SELECT * FROM layoffs_staging WHERE company = 'Casper';

-- Tenta remover duplicatas diretamente da CTE (isso não funciona na maioria dos SGBDs, como MySQL)
WITH duplicate_cte AS
(
SELECT *,
ROW_NUMBER() OVER(
PARTITION BY company, location,
industry, total_laid_off, percentage_laid_off, `date`, stage,
country, funds_raised_millions) AS row_num
FROM layoffs_staging
)
DELETE
FROM duplicate_cte
WHERE row_num > 1;

-- Cria uma nova tabela layoffs_staging2 com os mesmos campos da original + campo row_num
CREATE TABLE `layoffs_staging2` (
    `company` text,
    `location` text,
    `industry` text,
    `total_laid_off` int DEFAULT NULL,
    `percentage_laid_off` text,
    `date` text,
    `stage` text,
    `country` text,
    `funds_raised_millions` int DEFAULT NULL,
    `row_num` int
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

-- Insere os dados da tabela layoffs_staging na nova tabela, adicionando a numeração (row_num)
INSERT INTO layoffs_staging2
SELECT *,
ROW_NUMBER() OVER(
PARTITION BY company, location,
industry, total_laid_off, percentage_laid_off, `date`, stage,
country, funds_raised_millions) AS row_num
FROM layoffs_staging;

-- Remove as duplicatas da tabela layoffs_staging2 mantendo apenas o primeiro registro de cada grupo
DELETE FROM layoffs_staging2 WHERE row_num > 1;

-- Exibe os dados finais da tabela sem duplicatas
SELECT * FROM layoffs_staging2;


-- 2. Padronizar os dados

-- Exibe a coluna "company" original e a mesma coluna com espaços removidos nas extremidades
SELECT company, TRIM(company)
FROM layoffs_staging2;

-- Atualiza os valores da coluna "company" removendo espaços extras à esquerda e à direita
UPDATE layoffs_staging2
SET company = TRIM(company);

-- Exibe todos os valores distintos da coluna "industry"
-- (serve para identificar inconsistências ou variações desnecessárias, como 'Crypto', 'Crypto Company', etc.)
SELECT DISTINCT industry
FROM layoffs_staging2;

-- Atualiza todos os valores que começam com "Crypto" (como 'Crypto Company') para o valor padrão 'Crypto'
UPDATE layoffs_staging2
SET industry = 'Crypto'
WHERE industry LIKE 'Crypto%';

-- Exibe os países distintos e uma versão com ponto final removido, ordenado alfabeticamente
-- Útil para detectar valores como 'United States.' (com ponto) e padronizá-los
SELECT DISTINCT country, TRIM(TRAILING '.' FROM country)
FROM layoffs_staging2
ORDER BY 1;

-- Remove o ponto final de países que terminam com ele (ex: 'United States.')
UPDATE layoffs_staging2
SET country = TRIM(TRAILING '.' FROM country)
WHERE country LIKE 'United States%';

-- Mostra os valores da coluna "date", que provavelmente estão como texto (ex: '03/15/2020')
SELECT `date`
FROM layoffs_staging2;

-- Converte os valores da coluna "date" de texto (string) para o formato de data reconhecido pelo banco
-- O formato '%m/%d/%Y' significa mês/dia/ano (ex: '03/15/2020')
UPDATE layoffs_staging2
SET `date` = STR_TO_DATE(`date`, '%m/%d/%Y');

-- Altera o tipo da coluna "date" para DATE, garantindo que o banco de dados reconheça como um tipo de data
ALTER TABLE layoffs_staging2
MODIFY COLUMN `date` DATE;


-- 3. Valores nulos ou valores em branco

-- Seleciona todos os registros em que ambas as colunas "total_laid_off" e "percentage_laid_off" são nulas
-- Isso pode indicar que o registro está incompleto ou foi inserido incorretamente
SELECT *
FROM layoffs_staging2
WHERE total_laid_off IS NULL
AND percentage_laid_off IS NULL;

-- Atualiza os registros onde o valor da coluna "industry" está em branco ('')
-- Define esses valores como NULL para padronizar o tratamento de dados ausentes
UPDATE layoffs_staging2
SET industry = NULL
WHERE industry = '';

-- Seleciona todos os registros onde "industry" está nula ou ainda está vazia
-- Útil para verificar se ainda existem valores que precisam ser corrigidos
SELECT *
FROM layoffs_staging2
WHERE industry IS NULL
OR industry = '';

-- Seleciona os registros de empresas cujo nome começa com "Bally"
-- Usado aqui provavelmente para investigar inconsistências ou dados incompletos relacionados à empresa
SELECT *
FROM layoffs_staging2
WHERE company LIKE 'Bally%';

-- Realiza um auto-join entre a tabela e ela mesma com base na coluna "company"
-- Retorna pares onde uma linha tem industry NULL e outra linha da mesma empresa tem industry preenchido
-- Isso permite usar a informação válida de uma linha para preencher a outra
SELECT t1.industry, t2.industry
FROM layoffs_staging2 t1
JOIN layoffs_staging2 t2
    ON t1.company = t2.company
WHERE (t1.industry IS NULL OR t1.industry = '')
AND t2.industry IS NOT NULL;

-- Atualiza os registros com "industry" nulo, preenchendo com o valor presente em outro registro da mesma empresa
-- Isso ajuda a completar os dados faltantes sem necessidade de fontes externas
UPDATE layoffs_staging2 t1
JOIN layoffs_staging2 t2
    ON t1.company = t2.company
SET t1.industry = t2.industry
WHERE t1.industry IS NULL
AND t2.industry IS NOT NULL;


-- 4. Remova todas as colunas ou linhas

-- Seleciona todos os registros onde os campos "total_laid_off" e "percentage_laid_off" são nulos
-- Esses registros geralmente não contêm dados úteis sobre demissões, podendo ser removidos
SELECT *
FROM layoffs_staging2
WHERE total_laid_off IS NULL
AND percentage_laid_off IS NULL;

-- Deleta da tabela todos os registros que não possuem nem número total de demitidos nem percentual
-- Essa é uma etapa de limpeza para eliminar dados irrelevantes ou incompletos
DELETE 
FROM layoffs_staging2
WHERE total_laid_off IS NULL
AND percentage_laid_off IS NULL;

-- Seleciona todos os registros restantes após a exclusão
-- Serve para verificar se os registros inválidos foram realmente removidos
SELECT *
FROM layoffs_staging2;

-- 4. Remove a coluna "row_num" da tabela
-- Essa coluna foi usada apenas durante o processo de deduplicação e agora não é mais necessária
ALTER TABLE layoffs_staging2
DROP COLUMN row_num;