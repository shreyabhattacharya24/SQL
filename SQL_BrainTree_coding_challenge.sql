use campusx;
select * from per_capita;


/*1. Data Integrity Checking & Cleanup

Alphabetically list all of the country codes in the continent_map table that appear more than once. Display any values where country_code is null as country_code = "FOO" and make this row appear first in the list, even though it should alphabetically sort to the middle. Provide the results of this query as your answer.
*/
Update continent_map 
set country_code=CASE country_code WHEN country_code='' THEN NULL ELSE country_code END;
set continent_code=CASE continent_code WHEN continent_code='' THEN NULL ELSE continent_code END;
select COALESCE(country_code,'FOO') as country_code from continent_map group by country_code 
having count(*)>1 order by country_code;
/*For all countries that have multiple rows in the continent_map table, delete all multiple records leaving only the 1 record per country. The record that you keep should be the first one when sorted by the continent_code alphabetically ascending. Provide the query/ies and explanation of step(s) that you follow to delete these records.
*/
-- continent=AS has 3 rows with null value as country code
create view rowid as (select *,row_number()OVER(order by country_code,continent_code) as 'row_number' from continent_map);
select * from rowid;
create view minenetries as (select MIN(row_number) as 'id' from rowid group by continent_code,country_code order by row_number);
-- final entries required
create table t1 as(select country_code,continent_code from rowid where row_number in(select * from minenetries));
select * from t1;
drop table continent_map;
create table continent_map as(
select * from t1
);
select * from continent_map;

/*2. List the countries ranked 10-12 in each continent by the percent of year-over-year growth descending from 2011 to 2012.

The percent of growth should be calculated as: ((2012 gdp - 2011 gdp) / 2011 gdp)

The list should include the columns:

rank
continent_name
country_code
country_name
growth_percent*/
Create view completeTable as(select pc.country_code,cu.country_name,cm.continent_code,co.continent_name,pc.year,pc.gdp_per_capita from per_capita pc join countries cu
on pc.country_code=cu.country_code
join continent_map cm on pc.country_code=cm.country_code
join continents co on co.continent_code=cm.continent_code);

create view gdp11 as (select DISTINCT country_code,country_name,continent_code,continent_name,gdp_per_capita as 'gdp11' from completeTable where year=2011 order by continent_code,country_code)
create view gdp12 as (select DISTINCT country_code,country_name,continent_code,continent_name,gdp_per_capita as 'gdp12' from completeTable where year=2012 order by continent_code,country_code);
Create view growthperc as (select gdp11.country_code,gdp11.country_name,gdp11.continent_code,gdp11.continent_name,gdp11,gdp12,ROUND((gdp12-gdp11)*100.00/gdp11,2) as 'growth_percent' 
from gdp11 join gdp12 on gdp11.country_code=gdp12.country_code and gdp11.continent_code=gdp12.continent_code)

select rank,continent_name,country_code,country_name,growth_percent from
(select *,RANK()OVER(Partition by continent_code order by growth_percent DESC) as 'rank' from growthperc)t
where t.rank between 10 and 12;


/*
3. For the year 2012, create a 3 column, 1 row report showing the percent share of gdp_per_capita for the following regions:

(i) Asia, (ii) Europe, (iii) the Rest of the World. Your result should look something like

Asia	Europe	Rest of World
25.0%	25.0%	50.0%
*/
select 
(select CONCAT(ROUND(sum(gdp_per_capita)*100.00/(select SUM(gdp_per_capita) from completeTable where year=2012),2),'%') from completeTable where year=2012 and continent_name='Asia') as 'Asia',
(select CONCAT(ROUND(sum(gdp_per_capita)*100.00/(select SUM(gdp_per_capita) from completeTable where year=2012),2),'%') from completeTable where year=2012 and continent_name='Europe') as 'Europe',
(select CONCAT(ROUND(sum(gdp_per_capita)*100.00/(select SUM(gdp_per_capita) from completeTable where year=2012),2),'%') from completeTable where year=2012 and continent_name!='Asia' and continent_name!='Europe'
) as 'Others';

/*
4a. What is the count of countries and sum of their related gdp_per_capita values for the year 2007 where the string 'an' (case insensitive) appears anywhere in the country name?
*/
select count(*),SUM(gdp_per_capita) from completeTable where year='2007' and lower(country_name) like '%an%';
/*
4b. Repeat question 4a, but this time make the query case sensitive.
*/
select count(*),SUM(gdp_per_capita) from completeTable where year='2007' and country_name like BINARY '%an%';

/*
5. Find the sum of gpd_per_capita by year and the count of countries for each year that have non-null gdp_per_capita where (i) the year is before 2012 and (ii) the country has a null gdp_per_capita in 2012. Your result should have the columns:

year
country_count
total
*/
select year,sum(gdp_per_capita) as 'total',count(*) as 'country_count' from per_capita where gdp_per_capita is not null and year<2012
group by year;
select year,sum(gdp_per_capita) as 'total',count(*) as 'country_count' from per_capita where gdp_per_capita is null and year=2012
group by year;
/*
6. All in a single query, execute all of the steps below and provide the results as your final answer:

a. create a single list of all per_capita records for year 2009 that includes columns:

continent_name
country_code
country_name
gdp_per_capita
*/
select continent_name,country_code,country_name,gdp_per_capita from completeTable where year=2009;
/*
b. order this list by:

continent_name ascending
characters 2 through 4 (inclusive) of the country_name descending
*/

select continent_name,country_code,country_name,gdp_per_capita from completeTable where year=2009
order by continent_name,SUBSTRING(country_name,2,3) DESC;

/*
c. create a running total of gdp_per_capita by continent_name
*/
select continent_name,SUM(gdp_per_capita) from completeTable where year=2009
group by continent_name;

/*
d. return only the first record from the ordered list for which each continent's running total of gdp_per_capita meets or exceeds $70,000.00 with the following columns:

continent_name
country_code
country_name
gdp_per_capita
running_total
*/
select continent_name,country_code,country_name,gdp_per_capita,SUM(gdp_per_capita)as 'running_total' from completeTable where year=2009
group by continent_name
having running_total>=70000
order by continent_name;
/*
7. Find the country with the highest average gdp_per_capita for each continent for all years. Now compare your list to the following data set. Please describe any and all mistakes that you can find with the data set below. Include any code that you use to help detect these mistakes.

rank	continent_name	country_code	country_name	avg_gdp_per_capita
1	Africa	SYC	Seychelles	$11,348.66
1	Asia	KWT	Kuwait	$43,192.49
1	Europe	MCO	Monaco	$152,936.10
1	North America	BMU	Bermuda	$83,788.48
1	Oceania	AUS	Australia	$47,070.39
1	South America	CHL	Chile	$10,781.71*/
select rank,Continent_name,country_code,country_name,avg_gdp_per_capita from
(select RANK()OVER(Partition by continent_name order by avg_gdp_per_capita DESC) as 'rank',
Continent_name,country_code,country_name,AVG(gdp_per_capita) as 'avg_gdp_per_capita' from completeTable
group by continent_name,country_code
order by continent_name,avg_gdp_per_capita DESC)t
where t.rank=1;