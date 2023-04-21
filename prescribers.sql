
-- 1. a. Which prescriber had the highest total number of claims (totaled over all drugs)?
        --Report the npi and the total number of claims.

SELECT p1.npi, 
       sum(total_claim_count) as total_claims
FROM prescriber as p1
INNER JOIN prescription as p2
ON p1.npi = p2.npi
GROUP BY p1.npi
ORDER BY total_claims DESC
LIMIT 1;

--Using CTE
WITH sum_claims AS (
SELECT npi, SUM(total_claim_count) AS total_claims
FROM prescription
GROUP BY npi
ORDER BY total_claims DESC
LIMIT 5
)
SELECT sum_claims.npi,
 nppes_provider_first_name AS first_name,
 nppes_provider_last_org_name AS last_name,
 specialty_description,
 total_claims
FROM sum_claims
INNER JOIN prescriber AS p
ON sum_claims.npi = p.npi
ORDER BY total_claims DESC;


-- b. Repeat the above, but this time report the nppes_provider_first_name, nppes_provider_last_org_name,  specialty_description, and the total number of claims.

SELECT p1.npi,
       nppes_provider_first_name,
	   nppes_provider_last_org_name, 
	   specialty_description, 
	   sum(total_claim_count) as total_claims
FROM prescriber as p1
INNER JOIN prescription as p2
ON p1.npi = p2.npi
GROUP BY p1.npi, p1.nppes_provider_first_name, p1.nppes_provider_last_org_name, p1.specialty_description
ORDER BY total_claims DESC
LIMIT 1;

-- 2. 
-- a. Which specialty had the most total number of claims (totaled over all drugs)?

SELECT specialty_description, 
       SUM(sub.total_claims) AS total_number_claims
FROM
    (SELECT specialty_description, 
            SUM(total_claim_count) as total_claims
     FROM prescription as p1
     INNER JOIN prescriber as p2
     USING(npi)
     GROUP BY p1.npi, p2.specialty_description
     ORDER BY total_claims) AS sub
GROUP BY specialty_description
ORDER BY total_number_claims DESC;


-- b. Which specialty had the most total number of claims for opioids?

SELECT specialty_description, 
       SUM(sub.total_claim) AS total_number_claims
FROM
    (SELECT drug_name, 
            specialty_description, 
     SUM(total_claim_count) AS total_claim
     FROM prescriber as p1
     INNER JOIN prescription as p2
     ON p1.npi = p2.npi
     GROUP BY drug_name, specialty_description) AS sub
INNER JOIN drug
USING(drug_name)
WHERE opioid_drug_flag = 'Y' 
GROUP BY specialty_description
ORDER BY total_number_claims DESC;


-- Micheal code to take care of multiple generic name
/*
SELECT specialty_description, SUM(total_claim_count) AS total_claims
FROM prescription 
INNER JOIN prescriber
USING(npi)
INNER JOIN 
(
SELECT DISTINCT drug_name,
 opioid_drug_flag
FROM drug
) sub
USING(drug_name)
WHERE opioid_drug_flag = 'Y'
GROUP BY specialty_description
ORDER BY total_claims DESC
*/



-- code to check the multiple generic name
/*
SELECT drug_name
FROM drug
GROUP BY drug_name
HAVING COUNT (DISTINCT opioid_drug_flag) = 2
*/


--     c. **Challenge Question:** Are there any specialties that appear in the prescriber table that have no associated prescriptions in
--the prescription table?

SELECT 
      specialty_description, 
	  COUNT(total_claim_count)
FROM prescriber
FULL JOIN prescription
USING(npi)
GROUP BY specialty_description
HAVING COUNT (total_claim_count) = 0;

(
SELECT DISTINCT specialty_description
FROM prescriber
)
EXCEPT
(
SELECT DISTINCT specialty_description
FROM prescriber
INNER JOIN prescription
USING(npi)
);


SELECT DISTINCT specialty_description  
FROM prescriber
WHERE specialty_description NOT IN
		(
			select distinct specialty_description  
			from prescriber pr
			inner join prescription pn 
			on pr.npi= pn.npi 
		)
ORDER BY specialty_description


SELECT *
FROM (SELECT DISTINCT specialty_description
	  FROM prescriber -- There are 107 specialites here
	 ) AS all_specialties
WHERE specialty_description NOT IN (SELECT DISTINCT specialty_description
									FROM prescription as rx
									LEFT JOIN prescriber as doc
									USING(npi) -- There are 92 specialites here
								   )


--     d. **Difficult Bonus:** *Do not attempt until you have solved all other problems!* For each specialty, report the percentage of total claims by that specialty which are for opioids. Which specialties have a high percentage of opioids?
SELECT t1.specialty_description, t1.total_opioid_claim, t2.total_specialty, ROUND(t1.total_opioid_claim * 100.0 / t2.total_specialty, 1) AS Percent
FROM 
  (SELECT specialty_description, SUM(total_claim_count) AS total_opioid_claim
 FROM prescription 
 LEFT JOIN prescriber 
 USING(npi)
 LEFT JOIN drug 
 USING(drug_name)
 WHERE opioid_drug_flag = 'Y'
 GROUP BY specialty_description) AS t1
LEFT JOIN
    (SELECT specialty_description, SUM(total_claim_count) AS total_specialty
 FROM prescription 
 LEFT JOIN prescriber 
 USING(npi)
 LEFT JOIN drug 
 USING(drug_name)
 GROUP BY specialty_description) AS t2
ON (t1.specialty_description = t2.specialty_description)
ORDER BY Percent DESC;


-- 3. 
-- a. Which drug (generic_name) had the highest total drug cost?

SELECT 
       generic_name, 
       SUM(total_drug_cost):: money AS total_cost
FROM prescription AS p2
INNER JOIN drug AS p3
ON p2.drug_name = p3.drug_name
GROUP BY generic_name
ORDER BY total_cost DESC;


-- b. Which drug (generic_name) has the hightest total cost per day? **Bonus: Round your cost per day column to 2 decimal places. Google ROUND to see how this works.**

SELECT generic_name, 
       ROUND(SUM(total_drug_cost)/SUM(total_day_supply), 2) AS total_cost_per_day
FROM prescription AS p2
INNER JOIN drug AS p3
ON p2.drug_name = p3.drug_name
GROUP BY generic_name
ORDER BY total_cost_per_day DESC

-- 4. 
-- a. For each drug in the drug table, return the drug name and then a column named 'drug_type' which says 'opioid' for drugs which have opioid_drug_flag = 'Y', says 'antibiotic' for those drugs which have antibiotic_drug_flag = 'Y', and says 'neither' for all other drugs.

SELECT drug_name, 
       CASE WHEN opioid_drug_flag = 'Y' THEN 'opioid'
            WHEN antibiotic_drug_flag = 'Y' THEN 'antibiotic'
	   ELSE 'neither'
	   END AS drug_type   
FROM drug;


-- b. Building off of the query you wrote for part a, determine whether more was spent (total_drug_cost) on opioids or on antibiotics. Hint: Format the total costs as MONEY for easier comparision.
SELECT SUM(CASE WHEN opioid_drug_flag = 'Y' THEN total_drug_cost END)::MONEY AS opioid_drug_cost,
	   SUM(CASE WHEN antibiotic_drug_flag = 'Y' THEN total_drug_cost END):: MONEY AS antibiotic_drug_cost
FROM drug
	 INNER JOIN prescription
	 USING(drug_name);


-- 5. 
--     a. How many CBSAs are in Tennessee? **Warning:** The cbsa table contains information for all states, not just Tennessee.

SELECT COUNT(DISTINCT cbsaname)
FROM cbsa
	 INNER JOIN fips_county
	 USING(fipscounty)
WHERE state = 'TN'


--     b. Which cbsa has the largest combined population? Which has the smallest? Report the CBSA name and total population.

SELECT 
       cbsaname,
       SUM(population) AS total_population
	   FROM cbsa
	   INNER JOIN population
	   USING (fipscounty)
	   GROUP by cbsaname
	   ORDER BY total_population DESC;
	   
--     c. What is the largest (in terms of population) county which is not included in a CBSA? Report the county name and population.
SELECT *
	   FROM fips_county
	   INNER JOIN population AS p
	   USING (fipscounty)
	   LEFT JOIN cbsa AS c
	   USING(fipscounty)   
	   WHERE c.fipscounty IS NULL
       ORDER BY population DESC
	   LIMIT 1;
	   
-- 6. 
--     a. Find all rows in the prescription table where total_claims is at least 3000. Report the drug_name and the total_claim_count.

SELECT drug_name, total_claim_count
FROM prescription 
WHERE total_claim_count >= 3000

--     b. For each instance that you found in part a, add a column that indicates whether the drug is an opioid.

SELECT drug_name, 
       total_claim_count,
	   opioid_drug_flag
FROM prescription 
INNER JOIN drug
USING(drug_name)
WHERE total_claim_count >= 3000;

--     c. Add another column to you answer from the previous part which gives the prescriber first and last name associated with each row.
SELECT drug_name, 
       total_claim_count,
	   opioid_drug_flag,
	   nppes_provider_first_name,
	   nppes_provider_last_org_name	   
FROM prescription 
INNER JOIN drug
USING(drug_name)
INNER JOIN prescriber
USING(npi)
WHERE total_claim_count >= 3000;


-- 7. The goal of this exercise is to generate a full list of all pain management specialists in Nashville and the number of claims they had for each opioid. **Hint:** The results from all 3 parts will have 637 rows.

--     a. First, create a list of all npi/drug_name combinations for pain management specialists (specialty_description = 'Pain Managment') in the city of Nashville (nppes_provider_city = 'NASHVILLE'), where the drug is an opioid (opiod_drug_flag = 'Y'). **Warning:** Double-check your query before running it. You will only need to use the prescriber and drug tables since you don't need the claims numbers yet.

SELECT p.npi, d.drug_name
FROM prescriber AS p
CROSS JOIN drug AS d
WHERE p.specialty_description = 'Pain Management' AND
      p.nppes_provider_city = 'NASHVILLE' AND
	  d.opioid_drug_flag = 'Y';
	  
--     b. Next, report the number of claims per drug per prescriber. Be sure to include all combinations, whether or not the prescriber had any claims. You should report the npi, the drug name, and the number of claims (total_claim_count).
SELECT 
	npi, 
	drug_name,
	total_claim_count
FROM prescriber
CROSS JOIN drug
LEFT JOIN prescription
	USING(npi, drug_name)
WHERE specialty_description = 'Pain Management'
AND nppes_provider_city = 'NASHVILLE'
AND opioid_drug_flag = 'Y';

--     c. Finally, if you have not done so already, fill in any missing values for total_claim_count with 0. Hint - Google the COALESCE function.

SELECT 
	npi, 
	drug_name,
	total_claim_count,
	COALESCE(total_claim_count, 0)
FROM prescriber
CROSS JOIN drug
LEFT JOIN prescription
	USING(npi, drug_name)
WHERE specialty_description = 'Pain Management'
AND nppes_provider_city = 'NASHVILLE'
AND opioid_drug_flag = 'Y';

--Bonus Questions
-- -- In this set of exercises you are going to explore additional ways to group and organize the output of a query when using postgres. 

-- -- For the first few exercises, we are going to compare the total number of claims from Interventional Pain Management Specialists compared to those from Pain Managment specialists.

-- -- 1. Write a query which returns the total number of claims for these two groups. Your output should look like this: 

SELECT specialty_description, SUM(total_claim_count) AS total_claims
FROM prescription AS p1
INNER JOIN prescriber AS p2
USING(npi)
WHERE p2.specialty_description IN ('Interventional Pain Management', 'Pain Management')
GROUP BY p2.specialty_description


-- -- specialty_description         |total_claims|
-- -- ------------------------------|------------|
-- -- Interventional Pain Management|       55906|
-- -- Pain Management               |       70853|


-- -- 2. Now, let's say that we want our output to also include the total number of claims between these two groups. Combine two queries with the UNION keyword to accomplish this. Your output should look like this:

SELECT specialty_description, SUM(total_claims)
FROM
UNION
( SELECT specialty_description, SUM(total_claim_count) AS total_claims
FROM prescription AS p1
INNER JOIN prescriber AS p2
USING(npi)
WHERE p2.specialty_description IN ('Interventional Pain Management', 'Pain Management')
GROUP BY p2.specialty_description
 ) AS sub


-- -- specialty_description         |total_claims|
-- -- ------------------------------|------------|
-- --                               |      126759|
-- -- Interventional Pain Management|       55906|
-- -- Pain Management               |       70853|

