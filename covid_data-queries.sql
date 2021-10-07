SELECT *
FROM `decent-blade-328116.portfolio_project.covid_vaccinations`
WHERE continent IS NOT NUll
ORDER BY 3,4
  
--SELECT *
--FROM `decent-blade-328116.portfolio_project.Covid_deaths`
--ORDER BY 3,4

-- This is the data I will be working with

SELECT Location, Date, total_cases, new_cases, total_deaths, population
FROM `decent-blade-328116.portfolio_project.Covid_deaths`
WHERE continent IS NOT NUll
ORDER BY 1,2

-- Covid cases Vs Total Deaths in Nigeria
SELECT Date, Location, total_cases, total_deaths, (total_deaths/total_cases)*100 AS Percentage_Deaths
FROM `decent-blade-328116.portfolio_project.Covid_deaths`
WHERE location = 'Nigeria' AND continent IS NOT NUll
--GROUP BY total_cases, total_deaths
ORDER BY 1,2

-- Total Covid cases vs Population
SELECT Location, max(total_cases), max(total_deaths), population, (max(total_cases)/population)*100 AS percent_population_infected 
FROM `decent-blade-328116.portfolio_project.Covid_deaths`
WHERE continent IS NOT NUll
--WHERE location LIKE '%Nigeria%'
GROUP BY location, population
ORDER BY percent_population_infected

--Total deaths to population per country
SELECT Location, max(total_deaths) AS Total_deaths, population, (max(total_deaths)/population)*100 AS percent_population_infected 
FROM `decent-blade-328116.portfolio_project.Covid_deaths`
WHERE continent IS NOT NUll
GROUP BY location, population
ORDER BY Total_deaths DESC 


--- BREAKING THINGS DOWN BY CONTINENT
--Continents with highest deaths
SELECT continent, max(total_deaths) AS Total_deaths
FROM `decent-blade-328116.portfolio_project.Covid_deaths`
WHERE continent IS NOT NUll
GROUP BY continent
ORDER BY Total_deaths DESC 

--Global figures per day
SELECT date, SUM(new_cases) AS Total_Cases, SUM(new_deaths) AS Total_deaths, 
    (SUM(new_deaths)/SUM(new_cases))*100 AS Percentage_Deaths
FROM `decent-blade-328116.portfolio_project.Covid_deaths`
WHERE continent IS NOT NUll AND Total_Cases IS NOT NULL
GROUP BY date
ORDER BY date, Total_deaths 

--Total figures as at 4th of Oct 2021
SELECT SUM(new_cases) AS Total_Cases, SUM(new_deaths) AS Total_deaths, 
    (SUM(new_deaths)/SUM(new_cases))*100 AS Percentage_Deaths
FROM `decent-blade-328116.portfolio_project.Covid_deaths`
WHERE continent IS NOT NUll AND Total_Cases IS NOT NULL
--GROUP BY date
--ORDER BY Total_deaths  

--Joining the covid cases and vaccination tables
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
FROM `decent-blade-328116.portfolio_project.Covid_deaths` dea
JOIN `decent-blade-328116.portfolio_project.covid_vaccinations` vac
ON dea.location = vac.location AND dea.date = vac.date
WHERE dea.continent IS NOT NULL
ORDER BY 2,3

--Let's do a rolling sum of the no. of people that get vaccinated in each country
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
        SUM(vac.new_vaccinations) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS RollingPeopleVaccinated
FROM `decent-blade-328116.portfolio_project.Covid_deaths` dea
JOIN `decent-blade-328116.portfolio_project.covid_vaccinations` vac
ON dea.location = vac.location AND dea.date = vac.date
WHERE dea.continent IS NOT NULL
ORDER BY 2,3

--I want to get the percentage number of people vaccinated per country but using the 
--RollingPeopleVaccinated/population won't work cuz you cant use a calculated column 
--in another calculation. Therefore we need to use a CTE (Common Table Expression)

WITH PopVsVac (dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations, RollingPeopleVaccinated) AS --no. of columns in CTE must equal number of columns in query table below
(
    SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
        SUM(vac.new_vaccinations) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS RollingPeopleVaccinated
    FROM `decent-blade-328116.portfolio_project.Covid_deaths` dea
    JOIN `decent-blade-328116.portfolio_project.covid_vaccinations` vac
    ON dea.location = vac.location AND dea.date = vac.date
    WHERE dea.continent IS NOT NULL
    --ORDER BY 2,3
)

SELECT *, (RollingPeopleVaccinated/population)*100
FROM PopVsVac

---OR
---Let's do the same thing we did above but in a slightly different manner: use of the TEMP TABLE

DROP TABLE IF EXISTS PercentPopulationVaccinated
CREATE TABLE PercentPopulationVaccinated 
(
    Continent nvarchar(255)
    Location nvarchar(255)
    Date datetime
    Population nvarchar(255)
    New_vaccinations numeric
    RollingPeopleVaccinated numeric
    
)

INSERT INTO PercentPopulationVaccinated
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
        SUM(vac.new_vaccinations) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS RollingPeopleVaccinated
FROM `decent-blade-328116.portfolio_project.Covid_deaths` dea
JOIN `decent-blade-328116.portfolio_project.covid_vaccinations` vac
ON dea.location = vac.location AND dea.date = vac.date
WHERE dea.continent IS NOT NULL
--ORDER BY 2,3

SELECT *, (RollingPeopleVaccinated/population)*100
FROM PercentPopulationVaccinated



--CREATING VIEW to store data and produce visualizations in Tableau
--View 1

CREATE VIEW PercentPopulationVaccinated AS
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
        SUM(vac.new_vaccinations) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS RollingPeopleVaccinated
FROM `decent-blade-328116.portfolio_project.Covid_deaths` dea
JOIN `decent-blade-328116.portfolio_project.covid_vaccinations` vac
ON dea.location = vac.location AND dea.date = vac.date
WHERE dea.continent IS NOT NULL
--ORDER BY 2,3


--View 2
CREATE VIEW RollingSumVaccinated AS
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
        SUM(vac.new_vaccinations) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS RollingPeopleVaccinated
FROM `decent-blade-328116.portfolio_project.Covid_deaths` dea
JOIN `decent-blade-328116.portfolio_project.covid_vaccinations` vac
ON dea.location = vac.location AND dea.date = vac.date
WHERE dea.continent IS NOT NULL
ORDER BY 2,3

--View 3
CREATE VIEW GlobalFigures AS
SELECT date, SUM(new_cases) AS Total_Cases, SUM(new_deaths) AS Total_deaths, 
    (SUM(new_deaths)/SUM(new_cases))*100 AS Percentage_Deaths
FROM `decent-blade-328116.portfolio_project.Covid_deaths`
WHERE continent IS NOT NUll AND Total_Cases IS NOT NULL
GROUP BY date
ORDER BY date, Total_deaths 
