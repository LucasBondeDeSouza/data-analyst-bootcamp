-- Exploratory Data Analysis

-- Exibe todos os dados da tabela para visualização geral
SELECT * FROM layoffs_staging2;

-- Retorna o maior número absoluto de demissões e o maior percentual de demissões registrados
SELECT MAX(total_laid_off), MAX(percentage_laid_off)
FROM layoffs_staging2;

-- Lista todas as empresas que demitiram 100% da força de trabalho (percentual = 1)
-- Ordena da maior para a menor captação de recursos
SELECT * FROM layoffs_staging2 
WHERE percentage_laid_off = 1
ORDER BY funds_raised_millions DESC;

-- Soma total de demissões por empresa
-- Mostra quais empresas demitiram mais pessoas no geral
SELECT company, SUM(total_laid_off)
FROM layoffs_staging2
GROUP BY company
ORDER BY 2 DESC;

-- Encontra a data mais antiga e mais recente de demissões registradas
SELECT MIN(`date`), MAX(`date`)
FROM layoffs_staging2;

-- Soma total de demissões por setor/indústria
-- Indica quais setores foram mais afetados
SELECT industry, SUM(total_laid_off)
FROM layoffs_staging2
GROUP BY industry
ORDER BY 2 DESC;

-- Soma total de demissões por país
-- Mostra quais países tiveram mais demissões registradas
SELECT country, SUM(total_laid_off)
FROM layoffs_staging2
GROUP BY country
ORDER BY 2 DESC;

-- Soma total de demissões por ano
-- Permite análise temporal ao longo dos anos
SELECT YEAR(`date`), SUM(total_laid_off)
FROM layoffs_staging2
GROUP BY YEAR(`date`)
ORDER BY 1 DESC;

-- Soma total de demissões por estágio da empresa (ex: Seed, Series A, Public, etc.)
-- Ajuda a entender em qual fase as empresas mais demitiram
SELECT stage, SUM(total_laid_off)
FROM layoffs_staging2
GROUP BY stage
ORDER BY 1 DESC;

-- Soma total do percentual de demissões por empresa
-- Pode ajudar a entender quem teve maior proporção de cortes, embora a soma de percentuais possa ser confusa
SELECT company, SUM(percentage_laid_off)
FROM layoffs_staging2
GROUP BY company
ORDER BY 2 DESC;

-- Soma total de demissões por mês (usando apenas o número do mês, ex: '01' para janeiro)
-- Pode mostrar sazonalidade, mas agrupa todos os anos juntos
SELECT SUBSTRING(`date`, 6, 2) AS `MONTH`, SUM(total_laid_off)
FROM layoffs_staging2
GROUP BY `MONTH`;

-- Soma total de demissões por mês completo (formato 'YYYY-MM')
-- Agrupa mês a mês com ano, permitindo análise mais precisa de tendências
SELECT SUBSTRING(`date`, 1, 7) AS `MONTH`, SUM(total_laid_off)
FROM layoffs_staging2
WHERE SUBSTRING(`date`, 1, 7) IS NOT NULL
GROUP BY `MONTH`
ORDER BY 1 ASC;

-- Cria uma CTE para calcular o total de demissões por mês
-- Depois calcula o total acumulado (rolling total) mês a mês
WITH Rolling_Total AS
(
SELECT SUBSTRING(`date`, 1, 7) AS `MONTH`, SUM(total_laid_off) AS total_off
FROM layoffs_staging2
WHERE SUBSTRING(`date`, 1, 7) IS NOT NULL
GROUP BY `MONTH`
ORDER BY 1 ASC
)
SELECT `MONTH`, total_off
, SUM(total_off) OVER(ORDER BY `MONTH`) AS rolling_total
FROM Rolling_Total;

-- Soma total de demissões por empresa e ano
-- Mostra o total de cortes por empresa em cada ano
SELECT company, YEAR(`date`), SUM(total_laid_off)
FROM layoffs_staging2
GROUP BY company, YEAR(`date`)
ORDER BY 3 DESC;

-- Cria uma CTE com o total de demissões por empresa e ano (Company_Year)
-- Em seguida, rankeia as empresas por número de demissões em cada ano (Company_Year_Rank)
-- Por fim, seleciona apenas as 5 maiores empresas com mais demissões por ano
WITH Company_Year (company, years, total_laid_off) AS
(
SELECT company, YEAR(`date`), SUM(total_laid_off)
FROM layoffs_staging2
GROUP BY company, YEAR(`date`)
), Company_Year_Rank AS
(
SELECT *, 
DENSE_RANK() OVER (PARTITION BY years ORDER BY total_laid_off DESC) AS Ranking
FROM Company_Year
WHERE years IS NOT NULL
)
SELECT *
FROM Company_Year_Rank
WHERE Ranking <= 5;