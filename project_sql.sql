-- tabulka č. 1:

CREATE TABLE t_kristyna_grouslova_project_SQL_primary_final
WITH table_payroll AS (SELECT cp.payroll_year, 
							cp.industry_branch_code, 
							cpib.name AS branch, 
							round(avg(cp.value), 2) AS average_salary_czk  
						FROM czechia_payroll cp
						JOIN czechia_payroll_industry_branch cpib
							ON cp.industry_branch_code = cpib.code
							AND cp.value_type_code = 5958
							AND cp.payroll_year BETWEEN 2006 AND 2018
							AND cp.calculation_code = 100
						GROUP BY cp.payroll_year, cp.industry_branch_code),
table_price AS (SELECT YEAR(cp2.date_from) AS price_year, 
						cp2.category_code, 
						cpc.name, 
						cpc.price_value, 
						cpc.price_unit, 
						round(avg(cp2.value), 2) AS average_price_czk
				FROM czechia_price cp2
				JOIN czechia_price_category cpc
					ON cp2.category_code = cpc.code
					AND category_code IN (SELECT code
											FROM czechia_price_category cpc
											WHERE name NOT IN ('Jakostní víno bílé'))
					GROUP BY cp2.category_code, YEAR(cp2.date_from))
SELECT *
	FROM table_payroll
	JOIN table_price 
		ON table_payroll.payroll_year = table_price.price_year;


-- tabulka č. 2:

CREATE TABLE t_kristyna_grouslova_project_SQL_secondary_final
SELECT country, 
		`year` AS GDP_year, 
		GDP, 
		population, 
		ROUND(GDP / population, 2) AS GDP_per_capita, 
		gini
	FROM economies e
	WHERE country IN (
		SELECT country
			FROM countries c
			WHERE continent = 'Europe')
		AND `year` BETWEEN 2006 AND 2018;


-- otázka č. 1:

SELECT tkg.payroll_year, 
		tkg.industry_branch_code, 
		tkg.branch, tkg.average_salary_czk, 
		tkg2.average_salary_czk AS prev_year_average_salary_czk,
		ROUND((tkg.average_salary_czk - tkg2.average_salary_czk) / tkg2.average_salary_czk * 100, 2) AS salary_growth_percent
	FROM t_kristyna_grouslova_project_sql_primary_final tkg
	JOIN t_kristyna_grouslova_project_sql_primary_final tkg2
		ON tkg.payroll_year = tkg2.payroll_year + 1
		AND tkg.industry_branch_code = tkg2.industry_branch_code
	GROUP BY tkg.payroll_year, tkg.industry_branch_code
	HAVING salary_growth_percent < 0
	ORDER BY industry_branch_code;


-- otázka č. 2:

SELECT price_year, 
		ROUND(AVG(average_salary_czk), 2) AS total_average_salary, 
		category_code,
		name, 
		price_value, 
		price_unit, 
		average_price_czk,
		ROUND((ROUND(AVG(average_salary_czk), 2) / average_price_czk), 0) AS sum_of_food
	FROM t_kristyna_grouslova_project_sql_primary_final tkg
	WHERE price_year IN (2006, 2018)
		AND category_code IN (114201, 111301)
	GROUP BY price_year, category_code;


-- otázka č. 3:

WITH table_growth_rate AS (SELECT tkg.price_year, 
									tkg.category_code, 
									tkg.name, 
									tkg.average_price_czk,
									tkg2.average_price_czk AS prev_year_average_price_czk,
									ROUND((tkg.average_price_czk - tkg2.average_price_czk) / tkg2.average_price_czk * 100, 2) AS price_growth_percent
								FROM t_kristyna_grouslova_project_sql_primary_final tkg
								JOIN t_kristyna_grouslova_project_sql_primary_final tkg2
									ON tkg.price_year = tkg2.price_year + 1
									AND tkg.category_code = tkg2.category_code
								GROUP BY tkg.price_year, tkg.category_code)
SELECT category_code, 
		name, 
		ROUND(avg(price_growth_percent), 2) AS average_growth_rate
	FROM table_growth_rate
	GROUP BY category_code
	ORDER BY average_growth_rate;


-- otázka č. 4:

WITH table_comparison AS (SELECT tkg.price_year, 
									tkg.category_code, 
									tkg.name, 
									tkg.average_price_czk, 
									tkg2.average_price_czk AS prev_year_average_price_czk,
									ROUND((tkg.average_price_czk - tkg2.average_price_czk) / tkg2.average_price_czk * 100, 2) AS price_growth_percent,
									tkg.industry_branch_code, 
									tkg.branch, 
									tkg.average_salary_czk, 
									tkg2.average_salary_czk AS prev_year_average_salary_czk,
									ROUND((tkg.average_salary_czk - tkg2.average_salary_czk) / tkg2.average_salary_czk * 100, 2) AS salary_growth_percent
							FROM t_kristyna_grouslova_project_sql_primary_final tkg
							JOIN t_kristyna_grouslova_project_sql_primary_final tkg2
								ON tkg.price_year = tkg2.price_year + 1
								AND tkg.category_code = tkg2.category_code
								AND tkg.industry_branch_code = tkg2.industry_branch_code
							GROUP BY tkg.price_year, tkg.category_code, tkg.industry_branch_code),
table_comparison_2 AS (SELECT price_year, 
							ROUND(avg(price_growth_percent), 2) AS average_growth_price, 
							ROUND(avg(salary_growth_percent), 2) AS average_growth_salary
						FROM table_comparison
						GROUP BY price_year)
SELECT price_year AS years, 
					average_growth_price, 
					average_growth_salary,
	CASE 
		WHEN (average_growth_price - average_growth_salary) > 10 THEN 'over 10 %'
		WHEN (average_growth_price - average_growth_salary) = 10 THEN 'is 10 %'
		ELSE 'below 10 %'
	END AS price_salary_difference
	FROM table_comparison_2;


-- otázka č. 5:

WITH table_GDP AS (SELECT *
	FROM t_kristyna_grouslova_project_sql_primary_final tkg1
	JOIN t_kristyna_grouslova_project_sql_secondary_final tkg2
		ON tkg1.payroll_year = tkg2.GDP_year
		AND tkg2.country = 'Czech republic'),
table_GDP2 AS (SELECT tg1.payroll_year AS years, 
		tg1.GDP_per_capita - tg2.GDP_per_capita AS GDP_growth_czk,
		ROUND(avg(tg1.average_salary_czk), 2) - ROUND(avg(tg2.average_salary_czk), 2) AS salary_growth_czk,
		ROUND(avg(tg1.average_price_czk), 2) - ROUND(avg(tg2.average_price_czk), 2) AS price_growth_czk,
		ROUND((tg1.GDP_per_capita - tg2.GDP_per_capita) / tg2.GDP_per_capita * 100, 2) AS GDP_growth_percent, 
		ROUND((tg1.average_price_czk - tg2.average_price_czk) / tg2.average_price_czk * 100, 2) AS price_growth_percent,
		ROUND((tg1.average_salary_czk - tg2.average_salary_czk) / tg2.average_salary_czk * 100, 2) AS salary_growth_percent
				FROM table_GDP tg1
				JOIN table_GDP tg2
					ON tg1.payroll_year = tg2.payroll_year + 1
					AND tg1.category_code = tg2.category_code
	AND tg1.industry_branch_code = tg2.industry_branch_code
	AND tg1.category_code = tg2.category_code
	GROUP BY tg1.payroll_year)
SELECT years, GDP_growth_czk,
		CASE
			WHEN  GDP_growth_czk >= 1000 THEN 'výrazný růst HDP'
			WHEN  GDP_growth_czk BETWEEN 0 AND 999 THEN 'mírný růst HDP'
			ELSE 'pokles HDP'
		END AS GDP_status,
			salary_growth_czk,
		CASE
			WHEN salary_growth_czk >= 1000 THEN 'výrazný růst mezd'
			WHEN salary_growth_czk BETWEEN 0 AND 999 THEN 'mírný růst mezd'
			ELSE 'pokles mezd'
		END AS salary_status,
			price_growth_czk,
		CASE
			WHEN price_growth_czk >= 3 THEN 'výrazný růst ceny potravin'
			WHEN price_growth_czk BETWEEN 0 AND 2.99 THEN 'mírný růst ceny potravin'
			ELSE 'pokles ceny potravin'
		END AS price_status,
			GDP_growth_percent,
			price_growth_percent,
			salary_growth_percent
	FROM table_GDP2;


			


	
	







