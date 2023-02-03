select *
from PortfolioProject1..CovidDeaths
where continent is not null --we had to do this because in the dataset, the continent name is repeated in the location column where the continent is null
order by 3,4;

--select *
--from PortfolioProject1.dbo.CovidVaccinations
--order by 3,4;

--Select data that we are going to be using

select location, date, total_cases, new_cases, total_deaths, population
from PortfolioProject1..CovidDeaths
where continent is not null
order by 1,2;

--Looking at Total Cases vs Total Deaths
--Shows the likelihood of dying if you contracted covid in Germany vs United States during this period
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

--Looking at countries with Highest Infection Rate compared to Population

select location, population, MAX(total_cases) as Highest_Infection_Count, MAX(total_cases/population)*100 AS Max_Percent_Population_Infected
from PortfolioProject1..CovidDeaths
where continent is not null
group by location, population
order by Max_Percent_Population_Infected desc;

--Showing countries with Highest Death Count per Population

select location, MAX(cast(total_deaths as int)) as Total_Death_Count --we had to convert the total_deaths values to int since the nvarchar(255) gave wrong values.
from PortfolioProject1..CovidDeaths
where continent is not null
group by location
order by Total_Death_Count desc;


--LET'S BREAK THINGS DOWN BY CONTINENT
--Showing continents with the Highest Death Count per Population
select continent, MAX(cast(total_deaths as int)) as Total_Death_Count
from PortfolioProject1..CovidDeaths
where continent is not null
group by continent
order by Total_Death_Count desc; --the problem here is that in the dataset for example, where the continent is null, there are other countries which are not included here, but they fall within those continents in real life. But we will use this for Tableau Visualization.

--This might be the solution or correct representation
select location, MAX(cast(total_deaths as int)) as Total_Death_Count
from PortfolioProject1..CovidDeaths
where continent is null
group by location
order by Total_Death_Count desc;

--GLOBAL NUMBERS
--Quering total new cases, total new deaths and new deaths percentage per day worldwide
select date, SUM(new_cases) AS Total_New_Cases, SUM(cast(new_deaths as int)) AS Total_New_Deaths,(SUM(cast(new_deaths as int))/SUM(new_cases))*100 AS New_Deaths_Percentage
from PortfolioProject1..CovidDeaths
where continent is not null
group by date
order by 1,2;
--Quering overall total new cases, total new deaths and new deaths percentage worldwide
select SUM(new_cases) AS Total_New_Cases, SUM(cast(new_deaths as int)) AS Total_New_Deaths,(SUM(cast(new_deaths as int))/SUM(new_cases))*100 AS New_Deaths_Percentage
from PortfolioProject1..CovidDeaths
where continent is not null;


/*** Now lets work with COVID Vaccinations ***/

select *
from PortfolioProject1..CovidVaccinations
where continent is not null;

--Lets join the two tables

select *
from PortfolioProject1..CovidDeaths AS dea
join PortfolioProject1..CovidVaccinations AS vac
	on dea.location=vac.location 
	AND dea.date=vac.date
where dea.continent is not null;

--Looking at Total Population vs Vaccinations

select dea.continent, dea.location, dea.date, dea.population, CONVERT(int, vac.new_vaccinations) AS new_vaccinations
		, SUM(cast(vac.new_vaccinations as int)) OVER(partition by dea.location order by dea.location, dea.date) AS total_daily_new_vaccinations
		/* Here, we add up the daily new vaccinations to find cumulative as a rolling count, and partition by location */
		, 
from PortfolioProject1..CovidDeaths AS dea
join PortfolioProject1..CovidVaccinations AS vac
	on dea.location=vac.location 
	AND dea.date=vac.date
where dea.continent is not null
order by 2,3;


--To find total_daily_new_vaccinations/population directly, we will be using a CTE

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


--Another way::: using a TEMP TABLE
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



/*** Creating Views to store data for Tableau Visualizations ***/


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