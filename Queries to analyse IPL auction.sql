--creating table IPL_Ball
create table IPL_Ball(
id int,
inning int,
over int,
ball int,
batsman varchar,
non_strike varchar,
bowler varchar,
batsman_runs int,
extra_runs int,
total_runs int,
is_wicket int,
dismissal_kind varchar,
player_dismissed varchar,
fielder varchar,
extra_type varchar,
batting_team varchar,
bowling_team varchar
);

copy IPL_Ball from 'C:\Program Files\PostgreSQL\15\data\ipl auction\IPL_Ball.csv' delimiter ',' csv header;

select * from IPL_Ball;


--creating table IPL_Matches
create table IPL_Matches(
id int,
city varchar,
date date,
player_of_match varchar,
venue varchar,
neutral_venue int,
team1 varchar,
team2 varchar,
toss_winner varchar,
toss_decision varchar,
winner varchar,
result varchar,
result_margin int,
eliminator varchar,
method varchar,
umpire1 varchar,
umpire2 varchar);

copy IPL_Matches from 'C:\Program Files\PostgreSQL\15\data\ipl auction\IPL_matches.csv' delimiter ',' csv header;

select * from IPL_Matches;

--------------------------------------task 1------------------------------------
/*Your first priority is to get 2-3 players with high S.R who have faced at least 500 balls.
And to do that you have to make a list of 10 players you want to bid in the auction so that when 
you try to grab them in auction you should not pay the amount greater than you have in the purse 
for a particular player. 
(strike rate is total runs scored by batsman divided by number of balls faced but remember 
when extras_type is 'wides' it is not counted as a ball faced neither counted as batsmen runs)*/

create table aggresive_batsman as (select batsman,count(ball) as balls_faced,sum(batsman_runs) as runs_scored, cast(sum(batsman_runs) as float)*100/count(ball) as strike_rate 
from IPL_Ball where not extra_type = 'wide' 
group by batsman 
order by strike_rate desc);

select * from aggresive_batsman where balls_faced>=500 limit 10;

---------------------------------------task 2--------------------------------------------------
/*Now you need to get 2-3 players with good Average who have played more than 2 ipl seasons. 
And to do that you have to make a list of 10 players you want to bid in the auction so that when 
you try to grab them in auction you should not pay the amount greater than you have in the purse 
for a particular player.*/

----creating table to add date column in IPL_Ball
create table Ball_Matches_Merged as (select a.id,
		a.batsman,
		a.batsman_runs,
		a.is_wicket,
		b.date
from IPL_Ball as a
inner join IPL_Matches as b
on a.id=b.id);

--creating a table to fetch batsman' average score
select batsman, 
sum(batsman_runs) runs_scored,
sum(is_wicket) as times_dismissed, 
count(distinct extract (year from date)) as seasons_played,
cast(sum(batsman_runs)as float)/sum(is_wicket) as average
from Ball_Matches_Merged 
group by batsman 
having sum(is_wicket)>=1 and count(distinct extract (year from date))>2
order by average desc
limit 10;

-----------------------------------task 3-------------------------------------
/*Now you need to get 2-3 Hard-hitting players who have scored most runs in boundaries and have 
played more the 2 ipl season. To do that you have to make a list of 10 players you want to bid 
in the auction so that when you try to grab them in auction you should not pay the amount greater 
than you have in the purse for a particular player.*/

----creating table of hard_hitting_batsman

create table hard_hitting_batsman as (select 
    batsman,
    sum(case when batsman_runs = 4 or batsman_runs = 6 then 1 else 0 end) as BoundaryCount,
    sum(case when batsman_runs = 4 or batsman_runs = 6 then batsman_runs else 0 end) as BoundaryRuns,
    sum(batsman_runs) as TotalRuns,
    (cast(sum(case when batsman_runs = 4 or batsman_runs = 6 then batsman_runs else 0 end) as float) / nullif(sum(batsman_runs), 0)) * 100 as BoundaryPercentage,
	count(distinct extract (year from date)) as season			
from
    Ball_Matches_Merged
group by batsman
);

select * from hard_hitting_batsman where season>2 order by BoundaryPercentage desc limit 10;


----------------------------------------task 4 Bidding on bowlers------------------------------------------
/*Your first priority is to get 2-3 bowlers with good economy who have bowled at least 500 balls 
in IPL so far.To do that you have to make a list of 10 players you want to bid in the auction so 
that when you try to grab them in auction you should not pay the amount greater than you have in 
the purse for a particular player.(economy can be calculated by dividing total runs conceded with
total overs bowled)*/
select bowler,count(ball) as balls_bowled,count(ball)/6 as overs_bowled,sum(total_runs) as runs_conceded,cast(sum(total_runs) as float)*6/count(ball) as economy 
from IPL_Ball 
group by bowler 
having count(ball)>=500
order by economy asc
limit 10;


------------------------task4
/*Now you need to get 2-3 bowlers with the best strike rate and who have bowled at least
500 balls in IPL so far.To do that you have to make a list of 10 players you want to bid in
the auction so that when you try to grab them in auction you should not pay the amount
greater than you have in the purse for a particular player.
(strike rate of a bowler can be calculated by number of balls bowled divided by total wickets
taken )*/


select bowler,sum(is_wicket) as total_wickets,count(ball) as balls_bowled, cast(count(ball) as float)/sum(is_wicket) as bowling_strike_rate 
	from IPL_Ball
	where not dismissal_kind in ('run out', 'retired hurt','obstructing the field')
	group by bowler
	having count(ball)>=500
	order by bowling_strike_rate asc
	limit 10;

------------------------------all rounders--------------------
/*Now you need to get 2-3 All_rounders with the best batting as well as bowling strike rate and 
who have faced at least 500 balls in IPL so far and have bowled minimum 300 balls.To do that you
have to make a list of 10 players you want to bid in the auction so that when you try to grab them
in auction you should not pay the amount greater than you have in the purse for a particular player. 
( strike rate of an all rounder can be calculated using the same criteria of batsman similarly the
bowling strike rate can be calculated using the criteria of a bowler)*/

create table batters_on_strike_rate as (
	select batsman,sum(batsman_runs) as total_runs,cast(sum(batsman_runs) as float)*100/count(ball) as batting_strike_rate 
	from IPL_Ball group by batsman 
	having count(ball)>=500 and sum(ball)>=300
	order by batting_strike_rate desc)
	
create table bowlers_on_strike_rate as (
	select bowler,sum(is_wicket) as total_wickets,count(ball)/cast(sum(is_wicket) as float) as bowling_strike_rate 
	from IPL_Ball
	where not dismissal_kind in ('run out', 'retired hurt','obstructing the field')
	group by bowler
	having count(ball)>=500 and sum(ball)>=300
	order by bowling_strike_rate asc)

select batsman as player,total_runs,batting_strike_rate,total_wickets,bowling_strike_rate from (select * from bowlers_on_strike_rate) as b join
(select * from batters_on_strike_rate) as c 
 on c.batsman=b.bowler
order by batting_strike_rate desc,bowling_strike_rate asc
limit 10
;	


-------------------------------wicket_keepers--------------------------------
create table wicket_keeper as (select fielder as wicket_keeper,count(dismissal_kind) as number_of_wickets
from IPL_Ball
where is_wicket>0 and not fielder='NA' and dismissal_kind in ('stumped','caught','run out')
group by fielder
order by number_of_wickets desc)

create table wickets_by_fielder as (select fielder as wicket_keeper,count(dismissal_kind) as number_of_wickets
from IPL_Ball
where is_wicket>0 and not fielder='NA' and dismissal_kind in ('stumped')
group by fielder
order by number_of_wickets desc);
							   
select a.wicket_keeper,a.number_of_wickets,b.runs_scored,b.strike_rate from wickets_by_fielder as a inner join aggresive_batsman as b on a.wicket_keeper=b.batsman
order by number_of_wickets desc
limit 10;

select fielder as wicket_keeper,
count(dismissal_kind) as number_of_wickets,
sum(total_runs) as runs_scored,
cast(sum(total_runs) as float)*100/count(ball) as strike_rate
from IPL_Ball
where is_wicket>0 and not fielder='NA' and dismissal_kind in ('stumped','caught') and not extra_type = 'wide'
group by fielder
order by number_of_wickets desc

select * from wicket_keeper;
------------------------additional questions---------------------
---question 1----
select city,count(city) as number_of_matches_hosted from IPL_Matches 
group by city
order by number_of_matches_hosted desc
limit 10;

select count(distinct city) as total_cities from IPL_Matches;
---question 2----
create table deliveries_v02 as (select *,case when total_runs>=4 then 'boundary' 
when total_runs=0 then 'dot' 
else 'other' end as ball_result 
from IPL_Ball)

select * from deliveries_v02 limit 10;
---question 3----
select ball_result,count(*) from deliveries_v02 where not ball_result='other' group by ball_result;

---question 4----
select batting_team,sum(case when total_runs=4 then 1 else 0 end) as four_runs,sum(case when total_runs=6 then 1 else 0 end) as six_runs,count(*) as Number_of_boundary_runs 
from deliveries_v02
where ball_result='boundary'
group by batting_team
order by total_boundary_runs desc


---question 5----
select bowling_team,count(ball) as total_balls_bowled,count(*) as number_of_dot_balls from deliveries_v02
where ball_result='dot' and not bowling_team='NA'
group by bowling_team
order by number_of_dot_balls desc


---question 6----
select dismissal_kind,count(*) from IPL_Ball
where not dismissal_kind = 'NA'
group by dismissal_kind
order by count(*) desc;


---question 7----
select bowler,sum(extra_runs) as runs_conceded
from IPL_Ball
group by bowler
order by total_runs desc
limit 5;

---question 8----
create table deliveries_v03 as (select a.*,b.venue,b.match_date
from IPL_Ball as a
left join (select id,max(date) as match_date,max(venue) as venue from IPL_Matches group by id) as b
on a.id=b.id);

select * from deliveries_v03 limit 10;
---question 9----
select venue, sum(total_runs) as total_runs
from deliveries_v03 
group by venue
order by total_runs desc;

---question 10----
select extract(year from match_date) as Year, sum(total_runs) as runs
from deliveries_v03
where venue='Eden Gardens'
group by year
order by runs desc
