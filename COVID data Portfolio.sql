select * 
from PortfolioProject..CovidDeaths$
where continent is NOT NULL
order by 3,4;

--select * 
--from PortfolioProject..CovidVaccinations$
--order by 3,4;

--Select Data that we are going to be using

Select location, date, total_cases, new_cases, total_deaths, population
from PortfolioProject..CovidDeaths$
where continent is NOT NULL
order by 1,2;

--Looking at Total Cases vs Total Deaths
-- Whats is the % of deaths?
-- Shows likelihood of dying if you contract covid in your country

Select location, date, total_cases, total_deaths, (total_deaths / total_cases)*100 as DeathPercentage
from PortfolioProject..CovidDeaths$
where continent is NOT NULL AND location like '%states%'
order by 1,2;

Select location, date, total_cases, total_deaths, (total_deaths / total_cases)*100 as DeathPercentage
from PortfolioProject..CovidDeaths$
where continent is NOT NULL AND location like '%Kyrgyzstan%'
order by 1,2;

-- Looking at Total Cases vs Population
-- Shows what % of population got covid

Select location, date, population, total_cases, (total_cases / population)*100 as CovidSpreadPercentage
from PortfolioProject..CovidDeaths$
where continent is NOT NULL --AND location LIKE '%states%'
order by 1,2;

--Looking at countries with highest infection rates compared to population

Select location, population, MAX(total_cases) as HighestInfectionCount, MAX((total_cases / population))*100 as PercentageInfectedPopulation
from PortfolioProject..CovidDeaths$
where continent is NOT NULL
Group by location, population
order by PercentageInfectedPopulation desc;

--Showing countries with Highest Death Count per Population

Select location, MAX(cast(total_deaths as int)) as TotalDeathCount
from PortfolioProject..CovidDeaths$
where continent is NOT NULL
Group by location
order by TotalDeathCount desc;

-- LET'S BREAK THINGS DOWN BY CONTINENT
--Showing continents with the Highest Death Count per Population

Select continent, MAX(cast(total_deaths as int)) as TotalDeathCount
from PortfolioProject..CovidDeaths$
-- where continent is not NULL
Group by continent
order by TotalDeathCount desc;

-- Global numbers
-- Numbers of new cases, new deaths grouped by date only

Select date,
			SUM(new_cases) as TotalCases, 
			SUM(cast(new_deaths as int)) as TotalDeaths, 
			SUM(cast(new_deaths as int)) / SUM(new_cases) *100 as DeathPercentage
from PortfolioProject..CovidDeaths$
where continent is NOT NULL
group by date
order by 1;

--Total numbers worldwide

Select SUM(new_cases) as TotalCases, 
			SUM(cast(new_deaths as int)) as TotalDeaths, 
			SUM(cast(new_deaths as int)) / SUM(new_cases) *100 as DeathPercentage
from PortfolioProject..CovidDeaths$
where continent is NOT NULL;

--Let's take a look at CovidVaccinations table

Select * from PortfolioProject..CovidVaccinations$;

--Now we will join 2 tables and assign the aliases

Select * 
from PortfolioProject..CovidDeaths$ as dea
join PortfolioProject..CovidVaccinations$ as vac
on dea.location = vac.location
and dea.date = vac.date;

--Looking at Total Population vs. Vaccinations.

Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
SUM(CAST (vac.new_vaccinations as bigint)) 
OVER (Partition by dea.location ORDER BY dea.location, dea.date) as TotalPeopleVaccinated
--(TotalPeopleVaccinated / population) *100   -We can't use the column we've just created
--Let's take a look at next 2 queries to solve this problem
from PortfolioProject..CovidDeaths$ as dea
join PortfolioProject..CovidVaccinations$ as vac
on dea.location = vac.location
and dea.date = vac.date
where dea.continent is not null
order by 2,3;

--Using CTE

With PopVsVac (Continent, Location, Date, Population, New_vaccinations, TotalPeopleVaccinated)
as (
Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
SUM(CAST (vac.new_vaccinations as bigint)) 
OVER (Partition by dea.location ORDER BY dea.location, dea.date) as TotalPeopleVaccinated
from PortfolioProject..CovidDeaths$ as dea
join PortfolioProject..CovidVaccinations$ as vac
		on dea.location = vac.location
		and dea.date = vac.date
where dea.continent is not null
--order by 2,3
)
Select * , (TotalPeopleVaccinated/Population)*100 as VacPercentage
from PopVsVac


-- TEMP table (Temporary Table)

Drop table if exists #PercentPopulationVaccinated
--Drop table and create it again if you need to do any changes later
Create Table #PercentPopulationVaccinated
(
Continent nvarchar(255), 
Location nvarchar(255),
Date datetime,
Population numeric,
New_vaccinations numeric,
TotalPeopleVaccinated numeric
)

Insert into #PercentPopulationVaccinated
Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
SUM(CAST (vac.new_vaccinations as bigint)) 
OVER (Partition by dea.location ORDER BY dea.location, dea.date) as TotalPeopleVaccinated
from PortfolioProject..CovidDeaths$ as dea
join PortfolioProject..CovidVaccinations$ as vac
		on dea.location = vac.location
		and dea.date = vac.date
where dea.continent is not null
order by 2,3

Select * , (TotalPeopleVaccinated/Population)*100 as VacPercentage
from #PercentPopulationVaccinated

-- Creating View to store data for later visualizations

Create view PercentPopulationVaccinated as
Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
SUM(CAST (vac.new_vaccinations as bigint)) 
OVER (Partition by dea.location ORDER BY dea.location, dea.date) as TotalPeopleVaccinated
from PortfolioProject..CovidDeaths$ as dea
join PortfolioProject..CovidVaccinations$ as vac
		on dea.location = vac.location
		and dea.date = vac.date
where dea.continent is not null
--order by 2,3