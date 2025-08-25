SELECT *
FROM mech.covideaths c 
WHERE c.continent is not NULL
order BY  3,4

/*
SELECT *
FROM mech.AnyConv_com acc 
order by 3,4*/


ALTER TABLE AnyConv_com  
MODIFY population BIGINT;

/*Select the data we are going to be using*/

SELECT c.location, c.`date` , c.total_cases, c.new_cases, c.total_deaths, c.population 
FROM mech.covideaths c 
order BY  1,2

/*Looking for a Total Cases vs Total Deaths. 
  Shows likelihood of dying if you contract covid in your country*/

SELECT c.location, c.`date` , c.total_cases, c.total_deaths, (c.total_deaths /c.total_cases )*100 as Deathpercentage
FROM mech.covideaths c 
Where c.location like '%states%'
order BY  1,2

/* Looking at Total Cases vs Population
What percentage of population has gotten covid*/


SELECT 
    c.location, 
    c.`date`, 
    c.total_cases, 
    c.population, 
    (c.total_cases / c.population) * 100 AS CasePercentage
FROM mech.covideaths c
WHERE c.location LIKE '%poland%'
ORDER BY 1,2;


/*Lookinf for countries with Highest Infection Rate compared to Population */


SELECT 
    c.location,  c.population,
  MAX(c.total_cases ) 
     AS HighestInfectionCount,
    MAX(c.total_cases / c.population* 100) AS PercentPopulationInfected
FROM mech.covideaths c
Group by c.location, c.population 
ORDER BY PercentPopulationInfected desc

/*This is showing Countries wiht Highest Death Count per Population*/

SELECT 
    c.location, MAX(c.total_deaths) as TotalDeathCount
FROM mech.covideaths c
WHERE c.continent is NULL
Group by c.location
ORDER BY TotalDeathCount desc


/* LET'S BREAK THINGS DOWN BY CONTINENT*/

SELECT c.continent, MAX(c.total_deaths) as TotalDeathCount
FROM mech.covideaths c
WHERE c.continent is not NULL
Group by c.continent   
ORDER BY TotalDeathCount desc


/*Showing continent with the highest DeathCount*/

SELECT c.continent, c.population,
  MAX(c.total_deaths) AS TotalDeathCount,
FROM mech.covideaths c
Where c.continent is not null 
Group by c.continent 
ORDER BY TotalDeathCount desc


/* GLOBAL NUMBERS OF NEW CASES AROUND THE WORLD*/


SELECT c.`date`, SUM(c.new_cases) as total_cases, SUM(c.new_deaths ) as total_deaths, SUM(new_deaths)/SUM(new_cases)*100 as DeathPercentage
FROM mech.covideaths c 
Where c.continent IS NOT NULL
GROUP BY c.`date`
order BY  1,2


/* Looking at Total Population vs Vaccinations*/
SELECT *
FROM mech.covideaths dea
JOIN mech.AnyConv_com vac
  ON dea.location = vac.location
  AND dea.date = vac.date;

SELECT dea.continent, dea.location, dea.date, dea. population, vac.new_vaccinations 
FROM mech.covideaths dea
JOIN mech.AnyConv_com vac
  ON dea.location = vac.location
  AND dea.date = vac.date
  order by 2,3
  
/* partition by location give us only general sum of vaccinations for all time */
  SELECT dea.continent, dea.location, dea.date, dea. population, vac.new_vaccinations,
SUM(vac.new_vaccinations) OVER (Partition by dea.location)
  FROM mech.covideaths dea
JOIN mech.AnyConv_com vac
  ON dea.location = vac.location
  AND dea.date = vac.date
  where dea.continent is not null
  order by 2,3

/*give us separate date and location, will sum every next vac, if its 0 or null it is not going to add anything*/
   
  SELECT dea.continent, dea.location, dea.date, dea. population, vac.new_vaccinations,
SUM(vac.new_vaccinations) OVER (Partition by dea.location order by dea.location, dea.date) as RollingPeopleVaccinated
  FROM mech.covideaths dea
JOIN mech.AnyConv_com vac
  ON dea.location = vac.location
  AND dea.date = vac.date
  where dea.continent is not null
  order by 2,3

  
  /*USE CTE*/
  
  With PopvsVac (continent, location, date, population, new_vaccinations, RollingPeopleVaccinated)
  
 as 
 (
   SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
SUM(vac.new_vaccinations) OVER (Partition by dea.location order by dea.location, dea.date) as RollingPeopleVaccinated
  FROM mech.covideaths dea
JOIN mech.AnyConv_com vac
  ON dea.location = vac.location
  AND dea.date = vac.date
  where dea.continent is not null
  order by 2,3
 
)
SELECT*, (RollingPeopleVaccinated/population)*100
FROM PopvsVac



/*TEMP TABLE*/


DROP TEMPORARY TABLE IF EXISTS PercentPopulationVaccinated;

-- Utwórz tabelę tymczasową z kolumnami
CREATE TEMPORARY TABLE PercentPopulationVaccinated (
    continent VARCHAR(255),
    location VARCHAR(255),
    date DATE,
    population BIGINT,
    new_vaccinations BIGINT,
    RollingPeopleVaccinated BIGINT
);

-- Wypełnij tabelę
INSERT INTO PercentPopulationVaccinated
SELECT dea.continent, 
       dea.location, 
       dea.date, 
       dea.population, 
       vac.new_vaccinations,
       SUM(vac.new_vaccinations) OVER (
           PARTITION BY dea.location 
           ORDER BY dea.date
       ) AS RollingPeopleVaccinated
FROM mech.covideaths dea
JOIN mech.AnyConv_com vac
  ON dea.location = vac.location
 AND dea.date = vac.date
WHERE dea.continent IS NOT NULL;

-- Zapytanie końcowe
SELECT *,
       (RollingPeopleVaccinated / population) * 100 AS PercentVaccinated
FROM PercentPopulationVaccinated;


-- CTE

WITH PercentPopulationVaccinated AS (
   SELECT dea.continent, 
          dea.location, 
          dea.date, 
          dea.population, 
          vac.new_vaccinations,
          SUM(vac.new_vaccinations) OVER (
              PARTITION BY dea.location 
              ORDER BY dea.date
          ) AS RollingPeopleVaccinated
   FROM mech.covideaths dea
   JOIN mech.AnyConv_com vac
     ON dea.location = vac.location
    AND dea.date = vac.date
   WHERE dea.continent IS NOT NULL
)
SELECT *,
       (RollingPeopleVaccinated / population) * 100 AS PercentVaccinated
FROM PercentPopulationVaccinated;


-- Create View To Store data for later visualisations

DROP View IF EXISTS PercentPopulationVaccinated;

CREATE View PercentPopulationVaccinated as

SELECT dea.continent, 
          dea.location, 
          dea.date, 
          dea.population, 
          vac.new_vaccinations,
          SUM(vac.new_vaccinations) OVER (
              PARTITION BY dea.location 
              ORDER BY dea.date) as RollingPeopleVaccinated
          
   FROM mech.covideaths dea
   JOIN mech.AnyConv_com vac
     ON dea.location = vac.location
    AND dea.date = vac.date
   WHERE dea.continent IS NOT NULL;
   
   -- work table 
   
SELECT * FROM PercentPopulationVaccinated;





