

/**

Skills used: join, window function, aggregate function, temp table, case expression, cte

**/

/**Which actors or actresses typically appear in movies with high average ratings? The person must have appeared in more than 10 movies.**/
select person_name, count(md) as 'number of movies' , avg(vote_average) as 'average rating'
from
(select person_name, p.person_id, m.movie_id as md, vote_average
from movies.dbo.movie m
join movies.dbo.movie_cast c
on m.movie_id=c.movie_id
join movies.dbo.person p
on c.person_id=p.person_id) a
group by person_name
having count(md)>10
order by [average rating] desc

/**Which production company made the most money in 2015?

use Temp table to perform calculation**/
drop table if exists #prod_comp_rev
create table #prod_comp_rev
(release_year numeric,
revenue numeric,
movie_id int,
company_name nvarchar(255)
)

insert into #prod_comp_rev
select left(release_date,4) as year, revenue, m.movie_id,
company_name
from movies.dbo.movie m
join movies.dbo.movie_company c
on m.movie_id=c.movie_id
join movies.dbo.production_company p
on c.company_id=p.company_id

select company_name, sum(revenue) as total_rev
from #prod_comp_rev
where release_year=2015
group by company_name
order by total_rev desc

/**Which production company has produced the most highest-grossing movies of the year?

use same Temp table above to perform calculation**/

select company_name, count(*) as 'number of highest-grossing movies of the year'
from
(select release_year, company_name, revenue, rank() over (partition by release_year order by revenue desc) as rank
from #prod_comp_rev) a
where rank=1
group by company_name
order by count(*) desc

/**What actors and actresses have appeared the most times on screen together?**/
select per1.person_name, per2.person_name, the_count
from
(select distinct least(p1,p2) as p1, greatest(p1,p2) as p2, the_count
from (select c1.person_id as p1, c2.person_id as p2, count(*) as the_count
from movies.dbo.movie_cast c1
inner join movies.dbo.movie_cast c2
on c1.movie_id=c2.movie_id
and c1.person_id<>c2.person_id
group by c1.person_id, c2.person_id) a) b
inner join movies.dbo.person per1
on b.p1=per1.person_id
inner join movies.dbo.person per2
on b.p2=per2.person_id
order by the_count desc

/**Calculate the percentage of cast by gender using case expression and converting data types.**/

select cast(sum(case
when gender='Male' then 1
end) as numeric)/cast(count(gender) as numeric)*100 as male_count,
cast(sum(case
when gender='Female' then 1
end) as numeric)/cast(count(gender) as numeric)*100 as female_count,
cast(sum(case
when gender='Unspecified' then 1
end) as numeric)/cast(count(gender) as numeric)*100 as unspecified_count
from movies.dbo.gender g
inner join movies.dbo.movie_cast c
on g.gender_id=c.gender_id

/**Which movies had the largest number of people in each job? There must be more than 10 in the job.

use CTE
**/
with cte as (select movie_id, job, count(*) as num_of_people,
rank() over (partition by job order by count(*) desc) as rank
from movies.dbo.movie_crew
group by movie_id, job)

select title, job, num_of_people
from cte
inner join movies.dbo.movie m
on cte.movie_id=m.movie_id
where rank=1 and num_of_people>10

/**How many total movies did directors direct who directed at least one movie in the '70s, '80s, '90s, and 2000s?**/
select person_name, count(*) as num_movies
from (select person_name, p.person_id
from
(select movie_id,
case
when release_date between '1970-01-01' and '1979-12-31' then '70s'
when release_date between '1980-01-01' and '1989-12-31' then '80s'
when release_date between '1990-01-01' and '1999-12-31' then '90s'
when release_date between '2000-01-01' and '2009-12-31' then '2000s'
end as decade
from movies.dbo.movie) a
join movies.dbo.movie_crew mc
join movies.dbo.person p
on mc.person_id=p.person_id
on a.movie_id=mc.movie_id
where decade is not null
and job='Director'
group by person_name, p.person_id
having count(distinct decade)=4) b
join movies.dbo.movie_crew mc2
on b.person_id=mc2.person_id
where job='Director'
group by person_name
order by num_movies desc
