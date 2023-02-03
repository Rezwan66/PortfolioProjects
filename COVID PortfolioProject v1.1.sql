/*
Covid 19 Data Exploration 
Skills used: Joins, CTE's, Temp Tables, Windows Functions, Aggregate Functions, Creating Views, Converting Data Types
*/

select *
from PortfolioProject1..CovidDeaths
where continent is not null --we had to do this because the continent name is repeated in the location column where the continent is null
order by 3,4;


-- Select data that we are going to be starting with

select location, date, total_cases, new_cases, total_deaths, population
from PortfolioProject1..CovidDeaths
where continent is not null
order by 1,2;


-- Total Cases vs Total Deaths
-- Shows the likelihood of dying if you contracted covid in Germany vs United States during this period

select location, date, total_cases, total_deaths, (total_deaths/total_cases)*100 AS Death_Percentage
from PortfolioProject1..CovidDeaths
where (location='Germany' OR location like '%states%') AND continent is not null
order by 1,2;


--Looking at Total Cases vs Population
--Shows the percentage of the total population who got covid in Germany vs United States during this period

select location, date, population, total_cases, (total_cases/population)*100 AS Percent_Population_Infected
from PortfolioProject1..CovidDeaths
where (location='Germany' OR location like '%states%') AND continent is not null
order by 1,2;


-- Countries with Highest Infection Rate compared to Population

select location, population, MAX(total_cases) as Highest_Infection_Count, MAX(total_cases/population)*100 AS Max_Percent_Population_Infected
from PortfolioProject1..CovidDeaths
where continent is not null
group by location, population
order by Max_Percent_Population_Infected desc;


-- Countries with Highest Death Count per Population

select location, MAX(cast(total_deaths as int)) as Total_Death_Count --we had to convert the total_deaths values from nvarchar(255) to int.
from PortfolioProject1..CovidDeaths
where continent is not null
group by location
order by Total_Death_Count desc;


-- BREAKING THINGS DOWN BY CONTINENT
-- Continents with the Highest Death Count per Population

select continent, MAX(cast(total_deaths as int)) as Total_Death_Count
from PortfolioProject1..CovidDeaths
where continent is not null
group by continent
order by Total_Death_Count desc;


--GLOBAL NUMBERS
--Quering overall total new cases, total new deaths and new deaths percentage worldwide

select SUM(new_cases) AS Total_New_Cases, SUM(cast(new_deaths as int)) AS Total_New_Deaths,(SUM(cast(new_deaths as int))/SUM(new_cases))*100 AS New_Deaths_Percentage
from PortfolioProject1..CovidDeaths
where continent is not null
order by 1,2;


/*** Joining with COVID Vaccinations Table ***/

select *
from PortfolioProject1..CovidDeaths AS dea
join PortfolioProject1..CovidVaccinations AS vac
	on dea.location=vac.location 
	AND dea.date=vac.date
where dea.continent is not null;


-- Total Population vs Vaccinations
-- Shows Percentage of Population that has recieved at least one Covid Vaccine

select dea.continent, dea.location, dea.date, dea.population, CONVERT(int, vac.new_vaccinations) AS new_vaccinations
		, SUM(cast(vac.new_vaccinations as int)) OVER(partition by dea.location order by dea.location, dea.date) AS total_daily_new_vaccinations
		/* Here, we add up the daily new vaccinations to find cumulative as a rolling count, and partition by location */
from PortfolioProject1..CovidDeaths AS dea
join PortfolioProject1..CovidVaccinations AS vac
	on dea.location=vac.location 
	AND dea.date=vac.date
where dea.continent is not null
order by 2,3;


-- Using CTE to perform Calculation on Partition By in previous query to find percent_vaccinated

with PopvsVac as (
		select dea.continent, dea.location, dea.date, dea.population, CONVERT(int, vac.new_vaccinations) AS new_vaccinations
			, SUM(cast(vac.new_vaccinations as int)) OVER(partition by dea.location order by dea.location, dea.date) AS total_daily_new_vaccinations
			/* Here, we add up the daily new vaccinations to find cumulative as a rolling count, and partition by location */
		from PortfolioProject1..CovidDeaths AS dea
		join PortfolioProject1..CovidVaccinations AS vac
			on dea.location=vac.location 
			AND dea.date=vac.date
		where dea.continent is not null )

select *, (total_daily_new_vaccinations/population)*100 AS percent_vaccinated
from PopvsVac;


-- ::Another way:: 
-- Using Temp Table to perform Calculation on Partition By in previous query

drop table if exists #percent_pop_vac
create table #percent_pop_vac(
	continent nvarchar(255),
	location nvarchar(255),
	date datetime,
	population numeric,
	new_vaccinations numeric,
	total_daily_new_vaccinations numeric
)
insert into #percent_pop_vac 
	select dea.continent, dea.location, dea.date, dea.population, CONVERT(int, vac.new_vaccinations) AS new_vaccinations
			, SUM(cast(vac.new_vaccinations as int)) OVER(partition by dea.location order by dea.location, dea.date) AS total_daily_new_vaccinations
			/* Here, we add up the daily new vaccinations to find cumulative as a rolling count, and partition by location */
		from PortfolioProject1..CovidDeaths AS dea
		join PortfolioProject1..CovidVaccinations AS vac
			on dea.location=vac.location 
			AND dea.date=vac.date
		where dea.continent is not null

select *, (total_daily_new_vaccinations/population)*100 AS percent_vaccinated
from #percent_pop_vac;


-- Creating Views to store data for Tableau Visualizations 

create view percent_population_vaccinated as 
select dea.continent, dea.location, dea.date, dea.population, CONVERT(int, vac.new_vaccinations) AS new_vaccinations
			, SUM(cast(vac.new_vaccinations as int)) OVER(partition by dea.location order by dea.location, dea.date) AS total_daily_new_vaccinations
			/* Here, we add up the daily new vaccinations to find cumulative as a rolling count, and partition by location */
		from PortfolioProject1..CovidDeaths AS dea
		join PortfolioProject1..CovidVaccinations AS vac
			on dea.location=vac.location 
			AND dea.date=vac.date
		where dea.continent is not null;

select *
from percent_population_vaccinated;