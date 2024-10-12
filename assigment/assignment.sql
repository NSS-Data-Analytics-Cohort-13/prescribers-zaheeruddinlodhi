
--Q1, a. Which prescriber had the highest total number of claims (totaled over all drugs)? Report the npi and the total number of claims.

SELECT p.npi, SUM(total_claim_count) AS total_count
From prescription AS p
Group By p.npi
ORDER BY Total_count DESC
LIMIT 1;

--

--Q1, b. Repeat the above, but this time report the nppes_provider_first_name, nppes_provider_last_org_name,  specialty_description, and the total number of claims.


SELECT 
		  p.nppes_provider_first_name
		, p.nppes_provider_last_org_name
		, p.specialty_description
		, SUM(pp.total_claim_count) AS total_num_of_claims
FROM prescriber AS p 
INNER JOIN prescription AS pp
USING(npi)
GROUP BY p.nppes_provider_first_name
		, p.nppes_provider_last_org_name
		, p.specialty_description
ORDER BY total_num_of_claims DESC
LIMIT 1;


---

--Q2, a. Which specialty had the most total number of claims (totaled over all drugs)?

SELECT 
		  p.specialty_description
		, SUM(pp.total_claim_count) AS total_claims
FROM prescriber AS p 
INNER JOIN prescription AS pp
USING(npi)
WHERE p.npi = pp.npi
GROUP BY p.specialty_description
ORDER BY total_claims DESC
LIMIT 1;

--Q2, b: Which specialty had the most total number of claims for opioids?

SELECT
          p.specialty_description
		, SUM(pp.total_claim_count) AS total_claims
FROM prescriber AS p 
INNER JOIN prescription AS pp
USING(npi)
INNER JOIN drug AS d
USING(drug_name)
WHERE d.opioid_drug_flag = 'Y'
GROUP BY p.specialty_description
ORDER BY total_claims DESC
LIMIT 1;


--

--Q2, c): **Challenge Question:** Are there any specialties that appear in the prescriber table that have no associated prescriptions in the prescription table?


SELECT DISTINCT specialty_description
FROM prescriber AS p 
LEFT JOIN prescription AS pp
ON p.npi = pp.npi
WHERE pp.npi IS NULL;



--3, a); Which drug (generic_name) had the highest total drug cost?

SELECT 
		  d.generic_name
		, SUM(pp.total_drug_cost) AS total_cost
FROM drug AS d
INNER JOIN prescription AS pp
USING(drug_name)
GROUP BY d.generic_name
ORDER BY total_cost DESC
LIMIT 1;

--3, b): b. Which drug (generic_name) has the hightest total cost per day? **Bonus: Round your cost per day column to 2 decimal places. Google ROUND to see how this works.**

SELECT 
		  d.generic_name
		, CAST(ROUND(SUM(pp.total_drug_cost)/SUM(total_day_supply),2) AS money) AS total_cost_per_day
FROM drug AS d
INNER JOIN prescription AS pp
USING(drug_name)
GROUP BY d.generic_name
ORDER BY total_cost_per_day DESC
LIMIT 1;



-- 4, a. For each drug in the drug table, return the drug name and then a column named 'drug_type' which says 'opioid' for drugs which have opioid_drug_flag = 'Y', says 'antibiotic' for those drugs which have antibiotic_drug_flag = 'Y', and says 'neither' for all other drugs. **Hint:** You may want to use a CASE expression for this. See https://www.postgresqltutorial.com/postgresql-tutorial/postgresql-case/ 

SELECT 
		DISTINCT drug_name,
		CASE 
		WHEN opioid_drug_flag ='Y' THEN 'opioid'
		WHEN antibiotic_drug_flag = 'Y' THEN 'antibiotic'
		ELSE 'niether' END AS drug_type
FROM drug;

--4, b) Building off of the query you wrote for part a, determine whether more was spent (total_drug_cost) on opioids or on antibiotics. Hint: Format the total costs as MONEY for easier comparision.

SELECT
		CASE 
		WHEN opioid_drug_flag ='Y' THEN 'opioid'
		WHEN antibiotic_drug_flag = 'Y' THEN 'antibiotic'
		END AS drug_type,
		CAST(SUM(CASE 
		WHEN opioid_drug_flag ='Y' THEN TOTAL_drug_cost
		WHEN antibiotic_drug_flag = 'Y' THEN total_drug_cost
		END) AS money) AS total_drug_cost
FROM drug AS d
INNER JOIN prescription AS pp
USING(drug_name)
WHERE CASE 
		WHEN opioid_drug_flag ='Y' THEN 'opioid'
		WHEN antibiotic_drug_flag = 'Y' THEN 'antibiotic'
		END  IS NOT NULL
GROUP BY CASE 
		WHEN opioid_drug_flag ='Y' THEN 'opioid'
		WHEN antibiotic_drug_flag = 'Y' THEN 'antibiotic'
		END
ORDER BY total_drug_cost DESC;

--5, a. How many CBSAs are in Tennessee? **Warning:** The cbsa table contains information for all states, not just Tennessee.

SELECT 
		COUNT(state) AS cbsa_tn
FROM cbsa AS c 
INNER JOIN fips_county AS f
USING(fipscounty)
WHERE state = 'TN'
ORDER BY cbsa_tn DESC

--5, B): Which cbsa has the largest combined population? Which has the smallest? Report the CBSA name and total population.

-- -- SELECT 
-- 		  c.cbsaname
-- 		, SUM(population) AS total_population
-- FROM cbsa AS c
-- INNER JOIN fips_county AS f
-- USING(fipscounty)
-- INNER JOIN population AS p 
-- USING(fipscounty)
-- WHERE state = 'TN'
-- GROUP BY c.cbsaname
-- ORDER BY total_population DESC

(
SELECT cbsaname, SUM(population) AS total_population, 'largest' as flag
FROM cbsa 
INNER JOIN population
USING(fipscounty)
GROUP BY cbsaname
ORDER BY total_population DESC
limit 1
)
UNION
(
SELECT cbsaname, SUM(population) AS total_population, 'smallest' as flag
FROM cbsa 
INNER JOIN population
USING(fipscounty)
GROUP BY cbsaname
ORDER BY total_population 
limit 1
) order by total_population desc


--5, C): What is the largest (in terms of population) county which is not included in a CBSA? Report the county name and population.

SELECT   f.county,  SUM(population) AS Total_Population
FROM cbsa AS c
RIGHT JOIN fips_county AS f
ON c.fipscounty = f.fipscounty
RIGHT JOIN population pop
ON pop.fipscounty = f.fipscounty
WHERE state = 'TN' AND c.cbsaname IS NULL
GROUP BY f.county
ORDER BY Total_Population DESC
LIMIT 1;

--6, a) Find all rows in the prescription table where total_claims is at least 3000. Report the drug_name and the total_claim_count.

SELECT 
		  drug_name
		, total_claim_count
FROM prescription
WHERE total_claim_count >= '3000'


--6, b): For each instance that you found in part a, add a column that indicates whether the drug is an opioid.

SELECT 
		  a.drug_name, total_claim_count
		, CASE WHEN opioid_drug_flag = 'Y' THEN 'opioid' ELSE NULL END AS opioidFlag
FROM prescription AS a 
INNER JOIN drug AS b 
ON a.drug_name = b.drug_name
WHERE total_claim_count >= '3000'


--6, C); Add another column to you answer from the previous part which gives the prescriber first and last name associated with each row.

SELECT
		  a.drug_name, total_claim_count
		, CASE WHEN opioid_drug_flag = 'Y' THEN 'opioid' 
		  ELSE NULL END AS opioidFlag
		, CONCAT (c.nppes_provider_first_name, ' ', c.nppes_provider_last_org_name) AS full_name
from prescription a 
INNER JOIN drug b 
ON a.drug_name = b.drug_name
INNER JOIN prescriber c 
USING(npi)
WHERE total_claim_count >= '3000'


--7,  The goal of this exercise is to generate a full list of all pain management specialists in Nashville and the number of claims they had for each opioid. **Hint:** The results from all 3 parts will have 637 rows.

--7a:  a. First, create a list of all npi/drug_name combinations for pain management specialists (specialty_description = 'Pain Management) in the city of Nashville (nppes_provider_city = 'NASHVILLE'), where the drug is an opioid (opiod_drug_flag = 'Y'). **Warning:** Double-check your query before running it. You will only need to use the prescriber and drug tables since you don't need the claims numbers yet.

SELECT 
		  p.npi
		, d.drug_name
FROM drug AS d
CROSS JOIN prescriber AS p
WHERE p.specialty_description = 'Pain Management' AND p.nppes_provider_city = 'NASHVILLE' AND d.opioid_drug_flag = 'Y'


--7b); Next, report the number of claims per drug per prescriber. Be sure to include all combinations, whether or not the prescriber had any claims. You should report the npi, the drug name, and the number of claims (total_claim_count).

-- SELECT 
-- 		    p.npi
-- 		  , d.drug_name
-- 		  , p.specialty_description
-- 		  , p.nppes_provider_city
-- 		  , d.opioid_drug_flag
-- FROM drug AS d
-- CROSS JOIN prescriber AS p
-- WHERE p.specialty_description = 'Pain Management' AND p.nppes_provider_city = 'NASHVILLE' AND d.opioid_drug_flag = 'Y'

SELECT prescriber.npi
		,	drug.drug_name
		,	SUM(prescription.total_claim_count) AS sum_total_claims
	FROM prescriber
		CROSS JOIN drug
		LEFT JOIN prescription
			USING (drug_name)
	WHERE prescriber.specialty_description = 'Pain Management'
		AND prescriber.nppes_provider_city = 'NASHVILLE'
		AND drug.opioid_drug_flag = 'Y'
	GROUP BY prescriber.npi
		,	drug.drug_name
	ORDER BY prescriber.npi;


--7, c. Finally, if you have not done so already, fill in any missing values for total_claim_count with 0. Hint - Google the COALESCE function.__


SELECT prescriber.npi
		,	drug.drug_name
		,	COALESCE(SUM(prescription.total_claim_count), 0) AS sum_total_claims
	FROM prescriber
		CROSS JOIN drug
		LEFT JOIN prescription
			USING (drug_name)
	WHERE prescriber.specialty_description = 'Pain Management'
		AND prescriber.nppes_provider_city = 'NASHVILLE'
		AND drug.opioid_drug_flag = 'Y'
	GROUP BY prescriber.npi
		,	drug.drug_name
	ORDER BY prescriber.npi;

---



-- SELECT DISTINCT npi
-- 		,	SUM(total_claim_count) as total_claims
-- 	FROM prescription
-- 	GROUP BY npi
-- 	ORDER BY total_claims DESC
-- 	LIMIT 1;


-- SELECT *
-- FROM zip_fips
-- --
-- SELECT *
-- FROM cbsa

-- SELECT *
-- FROM drug

-- SELECT *
-- FROM fips_county

-- SELECT *
-- FROM overdose_deaths

-- SELECT *
-- FROM prescriber

-- SELECT *
-- FROM prescription
