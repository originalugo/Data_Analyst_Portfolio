-- data i will be working with
SELECT location, total_cases, new_cases, total_deaths, population 
FROM Portfolio_project.dbo.covid_deaths$
WHERE Continent is NOT NULL
ORDER BY 1,2

-- Total cases vs total deaths
--- Total Percentage Deaths from covid in Nigeria
SELECT location, date, total_cases, total_deaths, (total_deaths/total_cases)*100 AS percentage_deaths
FROM covid_deaths$
WHERE Continent IS NOT NULL -- and location = 'Nigeria'
ORDER BY 1,2

-- Total Cases vs the Population
SELECT location, date, total_cases, population, (total_cases/population)*100 AS percentage_cases
FROM covid_deaths$
WHERE Continent IS NOT NULL -- and location = 'Nigeria'
ORDER BY 1,2

-- What country haS the highest infection rate?
SELECT location, population, Max(total_cases) AS Highest_Infection_Count, Max(total_cases/population)*100 AS Rate_of_infection
FROM covid_deaths$
WHERE Continent IS NOT NULL --and location like 'Nigeria%'
GROUP BY location, population
ORDER BY Rate_of_infection DESC

SELECT location, date, population, Max(total_cases) AS Highest_Infection_Count, Max(total_cases/population)*100 AS Rate_of_infection
FROM covid_deaths$
-- WHERE Continent IS NOT NULL --and location like 'Nigeria%'
GROUP BY location, date, population
ORDER BY Rate_of_infection DESC

-- Which country hAS the highest death count
--- I had to CAST the total_deaths to an integer because the datatypye of that column is a string (varchar)
--- and i wanted to order the results by that column 
SELECT location, population, Max(CAST(total_deaths AS int)) AS Highest_Death_Count, Max(total_deaths/population)*100 AS Rate_of_Death
FROM covid_deaths$
WHERE Continent IS NOT NULL --and location like 'Nigeria%'
GROUP BY location, population
ORDER BY Highest_Death_Count DESC


-- Which continent hAS the highest death count?
SELECT Continent, MAX(CAST(total_deaths AS int)) AS Highest_Death_Count --, MAX(total_deaths/population)*100 AS Rate_of_Death
FROM covid_deaths$
WHERE Continent IS NOT NULL --and location like 'Nigeria%'
GROUP BY continent
ORDER BY Highest_Death_Count DESC

-- Which continent has the
-- Global numbers
--- Total daily cASes and deaths globally
SELECT date, SUM(CAST(new_cases AS int)) AS Total_Daily_Cases, SUM(CAST(new_deaths AS int)) AS Total_New_Deaths
FROM covid_deaths$
WHERE Continent IS NOT NULL AND new_deaths <> 'Null'
GROUP BY date
ORDER BY 1,2,3 DESC

--- Total cASes and total deaths
SELECT SUM(new_cases) AS Total_Daily_Cases, SUM(CAST(new_deaths AS int)) AS Total_New_Deaths,
	(SUM(CAST(new_deaths AS int)) / SUM(new_cases)) * 100 AS Global_Death_Percentage
FROM covid_deaths$
WHERE Continent is NOT NULL and new_deaths <> 'Null'
ORDER BY 1,2 DESC

-- Total CASes vs Total Deaths
SELECT date, SUM(CAST(total_cases AS int)) AS Total_Global_Deaths, SUM(CAST(total_deaths AS int)) AS Total_Global_Deaths
FROM covid_deaths$
WHERE Continent IS NOT NULL --and location like 'Nigeria%'
GROUP BY date
ORDER BY 1,2 DESC

--- Merging the two tables
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
FROM Portfolio_project..covid_deaths$ AS dea
JOIN Portfolio_project..covid_vaccinated$ AS vac
	On dea.location = vac.location
	and dea.date = vac.date
WHERE dea.Continent IS NOT NULL

--- Rolling count of number of people vaccinated per day
SELECT dea.continent, dea.location, dea.date, dea.population, CONVERT(bigint, vac.new_vaccinations) AS New_Vaccinations, 
	SUM(CONVERT(bigint, vac.new_vaccinations)) 
	OVER (PARTITION BY dea.Location ORDER BY dea.location, dea.date)
	AS Rolling_People_Vaccinated
FROM [dbo].[covid_deaths$]  dea
JOIN [dbo].[covid_vaccinated$]  vac
	On dea.location = vac.location
	and dea.date = vac.date
WHERE dea.continent is NOT NULL
ORDER BY 2,3


-- Using a CTE to get the number of people vaccinated per population

WITH PopVsVac (Continent, Location, Date, Population, New_Vaccinations, Rolling_People_Vaccinated)
AS 
(
SELECT dea.continent, dea.location, dea.date, dea.population, CONVERT(bigint, vac.new_vaccinations) AS New_Vaccinations, 
	SUM(CONVERT(bigint, vac.new_vaccinations)) 
	OVER (PARTITION BY dea.Location ORDER BY dea.location, dea.date)
	AS Rolling_People_Vaccinated
FROM [dbo].[covid_deaths$]  dea
JOIN [dbo].[covid_vaccinated$]  vac
	On dea.location = vac.location
	and dea.date = vac.date
WHERE dea.continent IS NOT NULL
--ORDER BY 2,3

)
SELECT *, (Rolling_People_Vaccinated/Population)*100 AS Percent_Vaccinated_per_Populaation
FROM PopvsVac



---OR
---Let's do the same thing we did above but in a slightly different manner: use of the TEMP TABLE

DROP TABLE IF EXISTS Percent_Population_Vaccinated
CREATE TABLE Percent_Population_Vaccinated 
(
    Continent nvarchar(255),
    location nvarchar(255),
    Date datetime,
    Population nvarchar(255),
    New_vaccinations numeric,
    Rolling_People_Vaccinated numeric
    
)

INSERT INTO Percent_Population_Vaccinated
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
        SUM(CONVERT(bigint,vac.new_vaccinations)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS Rolling_People_Vaccinated
FROM [dbo].[covid_deaths$] dea
JOIN [dbo].[covid_vaccinated$] vac
ON dea.location = vac.location AND dea.date = vac.date
WHERE dea.continent IS NOT NULL
--ORDER BY 2,3

SELECT *, (Rolling_People_Vaccinated/CAST(population AS float) )*100
FROM Percent_Population_Vaccinated




-- Views to store data for viz
--- CREATE VIEWs to store in temp tables

CREATE VIEW Percentage_vaccination_per_Population AS
SELECT dea.continent, dea.location, dea.date, dea.population, CONVERT(bigint, vac.new_vaccinations) AS New_Vaccinations, 
	SUM(CONVERT(bigint, vac.new_vaccinations)) 
	Over (Partition by dea.Location ORDER BY dea.location, dea.date)
	AS Rolling_People_Vaccinated
FROM [dbo].[covid_deaths$]  dea
Join [dbo].[covid_vaccinated$]  vac
	On dea.location = vac.location
	and dea.date = vac.date
WHERE dea.continent is NOT NULL
--ORDER BY 2,3


CREATE VIEW Percent_Vaccinated_per_Populaation AS
With PopVsVac (Continent, Location, Date, Population, New_Vaccinations, Rolling_People_Vaccinated)
AS 
(
SELECT dea.continent, dea.location, dea.date, dea.population, CONVERT(bigint, vac.new_vaccinations) AS New_Vaccinations, 
	SUM(CONVERT(bigint, vac.new_vaccinations)) 
	Over (Partition by dea.Location ORDER BY dea.location, dea.date)
	AS Rolling_People_Vaccinated
FROM [dbo].[covid_deaths$]  dea
Join [dbo].[covid_vaccinated$]  vac
	On dea.location = vac.location
	and dea.date = vac.date
WHERE dea.continent is NOT NULL
--ORDER BY 2,3
)
SELECT *, (Rolling_People_Vaccinated/Population)*100 AS Percent_Vaccinated_per_Populaation
FROM PopvsVac


CREATE VIEW Percentage_Deaths AS
SELECT location, date, total_cases, total_deaths, (total_deaths/total_cases)*100 AS percentage_deaths
FROM covid_deaths$
WHERE Continent is NOT NULL -- and location = 'Nigeria'
ORDER BY 1,2

-- Global numbers
--- Total daily cASes and deaths globally
CREATE VIEW Total_Daily_Cases_Vs_Deaths AS
SELECT date, SUM(CAST(new_cASes AS int)) AS Total_Daily_Cases, SUM(CAST(new_deaths AS int)) AS Total_New_Deaths
FROM covid_deaths$
WHERE Continent is NOT NULL and new_deaths <> 'Null'
GROUP BY date
--ORDER BY 1,2,3 DESC

--- Global  Death Percentage
CREATE VIEW Global_Death_Percentage AS
SELECT SUM(new_cases) AS Total_Daily_Cases, SUM(CAST(new_deaths AS int)) AS Total_New_Deaths,
	(SUM(CAST(new_deaths AS int)) / SUM(new_cases)) * 100 AS Global_Death_Percentage
FROM covid_deaths$
WHERE Continent is NOT NULL and new_deaths <> 'Null'
--ORDER BY 1,2 DESC

-- Total CASes vs Total Deaths
CREATE VIEW Total_Global_Cases_Vs_Global_Deaths AS
SELECT date, SUM(CAST(total_cases AS int)) AS Total_Global_Cases, SUM(CAST(total_deaths AS int)) AS Total_Global_Deaths
FROM covid_deaths$
WHERE Continent is NOT NULL --and location like 'Nigeria%'
GROUP BY date
--ORDER BY 1,2 DESC