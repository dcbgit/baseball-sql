SELECT * FROM people;

--1. What range of years for baseball games played does the provided database cover? 

SELECT MIN(yearid), MAX(yearid)
FROM teams;
-- 1871 - 2016

/* 2. Find the name and height of the shortest player in the database. 
How many games did he play in? 
What is the name of the team for which he played?*/

WITH shortest_player AS (SELECT *
						FROM people
						ORDER BY height
						LIMIT 1),
sp_total_games AS (SELECT *
				  FROM shortest_player
				  LEFT JOIN appearances
				  USING(playerid))
SELECT DISTINCT(name), namelast, namefirst, height, g_all as games_played, sp_total_games.yearid
FROM sp_total_games
LEFT JOIN teams
USING(teamid);

--
Select namefirst, namelast, height, MIN(appearances.g_all), teams.name
FROM people
	JOIN appearances
	ON people.playerid = appearances.playerid
	JOIN teams
	ON teams.teamid = appearances.teamid
	WHERE height = 43
  GROUP BY people.namefirst, people.namelast, people.height, appearances.teamid, teams.name;
---

SELECT DISTINCT teams.name, namelast, namefirst, height, appearances.g_all as games_played, appearances.yearid as year
FROM people
INNER JOIN appearances
ON people.playerid = appearances.playerid
INNER JOIN teams
ON appearances.teamid = teams.teamid
WHERE height IS NOT null
ORDER BY height, namelast
LIMIT 1;

--St. Louis Browns, Eddie Gaedel, 43", 1 game play in 1951

/*3. Find all players in the database who played at Vanderbilt University. 
Create a list showing each player’s first and last names as well as the total salary they earned in the major leagues. 
Sort this list in descending order by the total salary earned. 
Which Vanderbilt player earned the most money in the majors?*/

SELECT concat(people.namefirst,' ', people.namelast) as player, CAST(SUM(salaries.salary::numeric) as money)
FROM collegeplaying
INNER JOIN schools on collegeplaying.schoolid = schools.schoolid
INNER JOIN people on people.playerid = collegeplaying.playerid
INNER JOIN salaries on people.playerid = salaries.playerid
WHERE schoolname LIKE 'Vanderbilt%'
GROUP BY player
ORDER BY sum DESC;

--
SELECT distinct concat(p.namefirst, ' ', p.namelast) as name, sc.schoolname,
  sum(sa.salary)
  OVER (partition by concat(p.namefirst, ' ', p.namelast)) as total_salary
  FROM (people p JOIN collegeplaying cp ON p.playerid = cp.playerid)
  JOIN schools sc ON cp.schoolid = sc.schoolid
  JOIN salaries sa ON p.playerid = sa.playerid
  where cp.schoolid = 'vandy'
  group by name, schoolname, sa.salary, sa.yearid
  ORDER BY total_salary desc


--David Price, Vandy, 81,851,296.00

/* Question # 4
Using the fielding table, group players into three groups based on their position: 
label players with position OF as "Outfield", those with position "SS", "1B", "2B", and "3B" as "Infield", 
and those with position "P" or "C" as "Battery".
Determine the number of putouts made by each of these three groups in 2016.*/

SELECT 
	CASE WHEN pos LIKE 'OF' THEN 'Outfield'
		WHEN pos LIKE 'C' THEN 'Battery'
		WHEN pos LIKE 'P' THEN 'Battery'
		ELSE 'Infield' END AS fielding_group,
	SUM(po) AS putouts
FROM fielding
WHERE yearid = 2016
GROUP BY fielding_group;

--Battery 41424
--Infield 58394
--Outfield 29560

/*5. Find the average number of strikeouts per game by decade since 1920. 
Round the numbers you report to 2 decimal places. Do the same for home runs per game. 
Do you see any trends?*/

SELECT ROUND(AVG(so/g),2), yearid/10*10 as decade
FROM pitching 
WHERE yearid BETWEEN '1920' AND '2016' 
GROUP by decade
ORDER BY decade DESC;
	  
SELECT ROUND(AVG(HR/g),2), yearid/10*10 as decade
FROM pitching 
WHERE yearid BETWEEN '1920' AND '2016' 
GROUP by decade
ORDER BY decade DESC;


--Tonya -- rework to show 2nd part of question regarding HR/g
SELECT yearid/10 * 10 AS decade, 
	ROUND(((SUM(so)::float/SUM(g))::numeric), 2) AS avg_so_per_game,
	ROUND(((SUM(so)::float/SUM(ghome))::numeric), 2) AS avg_so_per_ghome
FROM teams
WHERE yearid >= 1920 
GROUP BY decade

--reworked Tonyas to show 2nd part of question WRT HR/g
SELECT yearid/10 * 10 AS decade, 
	ROUND(((SUM(so)::float/SUM(g))::numeric), 2) AS avg_so_per_game,
	ROUND(((SUM(hr)::float/SUM(g))::numeric), 2) AS avg_hr_per_ghome
FROM teams
WHERE yearid >= 1920 
GROUP BY decade
ORDER BY decade

--dj
SELECT yearid/10*10 as decade, ROUND(AVG(HR/g), 2) as avg_HR_per_game,ROUND(AVG(so/g), 2) as avg_so_per_game
FROM teams
WHERE yearid>=1920
GROUP BY decade
ORDER BY decade

--mahesh
WITH decades as (	
	SELECT 	generate_series(1920,2010,10) as low_b,
			generate_series(1929,2019,10) as high_b)
			
SELECT 	low_b as decade,
		--SUM(so) as strikeouts,
		--SUM(g)/2 as games,  -- used last 2 lines to check that each step adds correctly
		ROUND(SUM(so::numeric)/(sum(g::numeric)/2),2) as SO_per_game,  -- note divide by 2, since games are played by 2 teams
		ROUND(SUM(hr::numeric)/(sum(g::numeric)/2),2) as hr_per_game
FROM decades LEFT JOIN teams
	ON yearid BETWEEN low_b AND high_b
GROUP BY decade
ORDER BY decade
--https://www.postgresql.org/docs/9.1/functions-math.html

-- The avg # of strikeouts increase with each decade.
-- The avg # of Home Runs shows a slight increase across the observation. 

/*6. Find the player who had the most success stealing bases in 2016, 
where success is measured as the percentage of stolen base attempts which are successful. 
(A stolen base attempt results either in a stolen base or being caught stealing.) 
Consider only players who attempted at least 20 stolen bases.*/

SELECT concat(people.namefirst,' ', people.namelast) as player, ROUND((SB::decimal/(SB+CS)::decimal)*100) as sb_success
FROM batting
INNER JOIN people on people.playerid = batting.playerid
WHERE yearid = 2016
AND (SB+CS)>20
ORDER BY sb_success DESC;

--Chris Owings, 91

/* Question #7
From 1970 – 2016, what is the largest number of wins for a team that did not win the world series? 
What is the smallest number of wins for a team that did win the world series? 
Doing this will probably result in an unusually small number of wins for a world series champion – determine why this is the case. 
Then redo your query, excluding the problem year. 
How often from 1970 – 2016 was it the case that a team with the most wins also won the world series? What percentage of the time?*/

SELECT teamid, w, yearid
FROM teams
WHERE yearid BETWEEN 1970 AND 2016
AND wswin = 'N'
GROUP BY teamid, yearid, w
ORDER BY w DESC
LIMIT 1;

-- 116 wins without winning the World Series (Seattle in 2001)

SELECT teamid, w, yearid
FROM teams
WHERE yearid BETWEEN 1970 AND 2016
AND yearid != 1981
AND wswin = 'Y'
GROUP BY teamid, yearid, w
ORDER BY w
LIMIT 1;

-- There was a player's strike in 1981 that shortened the season. 
-- The 2006 season had 83 wins for World Series Winner (St Louis).

SELECT yearid,
	MAX(w)
FROM teams
WHERE yearid BETWEEN 1970 and 2016
AND wswin = 'Y'
GROUP BY yearid
INTERSECT
SELECT yearid,
	MAX(w)
FROM teams
WHERE yearid BETWEEN 1970 and 2016
GROUP BY yearid
ORDER BY yearid;

-- The team with the highest number of wins won the world series 12 times between 1970 and 2016.

WITH ws_winners AS (SELECT yearid,
						MAX(w)
					FROM teams
					WHERE yearid BETWEEN 1970 and 2016
					AND wswin = 'Y'
					GROUP BY yearid
					INTERSECT
					SELECT yearid,
						MAX(w)
					FROM teams
					WHERE yearid BETWEEN 1970 and 2016
					GROUP BY yearid
					ORDER BY yearid)
SELECT (COUNT(ws.yearid)/COUNT(t.yearid)::float) AS percentage
FROM teams as t LEFT JOIN ws_winners AS ws ON t.yearid = ws.yearid
WHERE t.wswin IS NOT NULL
AND t.yearid BETWEEN 1970 AND 2016;

-- The team with the highest number of wins won the World Series 26% of the time between 1970 and 2016.

/*8. Using the attendance figures from the homegames table, find the teams and parks which had the 
top 5 average attendance per game in 2016 (where average attendance is defined as total attendance 
divided by number of games). 
Only consider parks where there were at least 10 games played. 
Report the park name, team name, and average attendance. 
Repeat for the lowest 5 average attendance.*/

SELECT DISTINCT p.park_name, h.team,
	(h.attendance/h.games) as avg_attendance, t.name		
FROM homegames as h JOIN parks as p ON h.park = p.park
LEFT JOIN teams as t on h.team = t.teamid AND t.yearid = h.year
WHERE year = 2016
AND games >= 10
ORDER BY avg_attendance DESC
LIMIT 5;

/*9.Which managers have won the TSN Manager of the Year award in both the National League (NL) and the American League (AL)? 
Give their full name and the teams that they were managing when they won the award.*/
--https://en.wikipedia.org/wiki/Sporting_News_Manager_of_the_Year_Award - 1936-1985 only one manager in either league was given the award

WITH winners AS (SELECT playerID
			FROM awardsmanagers
			WHERE awardID LIKE 'TSN Man%'
			AND lgID LIKE 'AL'
			INTERSECT
			SELECT playerID
			FROM awardsmanagers
			WHERE awardID LIKE 'TSN Man%'
			AND lgID LIKE 'NL')
SELECT concat(people.namefirst,' ', people.namelast) as manager, teams.name
FROM awardsmanagers
	INNER JOIN winners on  awardsmanagers.playerid = winners.playerid
	INNER JOIN people on winners.playerid = people.playerid
	INNER JOIN managers on winners.playerid = managers.playerid
	INNER JOIN teams on managers.teamid = teams.teamid
GROUP BY teams.name, concat(people.namefirst,' ', people.namelast)
ORDER BY manager;

---

WITH manager_both AS (SELECT playerid, al.lgid AS al_lg, nl.lgid AS nl_lg,
					  al.yearid AS al_year, nl.yearid AS nl_year,
					  al.awardid AS al_award, nl.awardid AS nl_award
	FROM awardsmanagers AS al INNER JOIN awardsmanagers AS nl
	USING(playerid)
	WHERE al.awardid LIKE 'TSN%'
	AND nl.awardid LIKE 'TSN%'
	AND al.lgid LIKE 'AL'
	AND nl.lgid LIKE 'NL')
	
SELECT DISTINCT(people.playerid), namefirst, namelast, managers.teamid,
		managers.yearid AS year, managers.lgid
FROM manager_both AS mb LEFT JOIN people USING(playerid)
LEFT JOIN salaries USING(playerid)
LEFT JOIN managers USING(playerid)
WHERE managers.yearid = al_year OR managers.yearid = nl_year;

-- mashesh
WITH mngr_list AS (SELECT playerid, awardid, COUNT(DISTINCT lgid) AS lg_count
				   FROM awardsmanagers
				   WHERE awardid = ‘TSN Manager of the Year’
				   		 AND lgid IN (‘NL’, ‘AL’)
				   GROUP BY playerid, awardid
				   HAVING COUNT(DISTINCT lgid) = 2),
	 mngr_full AS (SELECT playerid, awardid, lg_count, yearid, lgid
				   FROM mngr_list INNER JOIN awardsmanagers USING(playerid, awardid))
SELECT namegiven, namelast, name AS team_name
FROM mngr_full INNER JOIN people USING(playerid)
	 INNER JOIN managers USING(playerid, yearid, lgid)
	 INNER JOIN teams ON mngr_full.yearid = teams.yearid AND mngr_full.lgid = teams.lgid AND managers.teamid = teams.teamid
GROUP BY namegiven, namelast, name;


--Marlins, Pirates, Nationals & Orioles

/*10. Analyze all the colleges in the state of Tennessee. 
Which college has had the most success in the major leagues. 
Use whatever metric for success you like - number of players, number of games, 
salaries, world series wins, etc.*/





/*11. Is there any correlation between number of wins and team salary? 
Use data from 2000 and later to answer this question.
As you do this analysis, keep in mind that salaries across the whole league 
tend to increase together, so you may want to look on a year-by-year basis.*/

WITH corr_wins_salary AS (SELECT SUM(salaries.salary), SUM(w) as wins, teams
						FROM teams 
						INNER JOIN salaries USING(teamid)
						WHERE teams.yearid >= 2000
						GROUP BY teams)
SELECT CORR(sum,wins)
FROM corr_wins_salary;

--0.6592409969492645 (a positive relationship)	


/*12. In this question, you will explore the connection between number of wins and attendance.

 i.   Does there appear to be any correlation between attendance at home games and number of wins?
ii.    Do teams that win the world series see a boost in attendance the following year? What about 
teams that made the playoffs? Making the playoffs means either being a division winner or a wild
card winner.*/




--mahesh opend ended questions:
-- Open-ended questions
​
-- 10. Analyze all the colleges in the state of Tennessee.
-- Which college has had the most success in the major leagues.
-- Use whatever metric for success you like - number of players, number of games, salaries, world series wins, etc.
​
WITH tn_schools AS (SELECT schoolname, schoolid
					FROM schools
					WHERE schoolstate = 'TN'
					GROUP BY schoolname, schoolid)
SELECT schoolname, COUNT(DISTINCT playerid) AS player_count, SUM(salary)::text::money AS total_salary, (SUM(salary)/COUNT(DISTINCT playerid))::text::money AS money_per_player
FROM tn_schools INNER JOIN collegeplaying USING(schoolid)
	 INNER JOIN people USING(playerid)
	 INNER JOIN salaries USING(playerid)
GROUP BY schoolname
ORDER BY money_per_player DESC;
​
​
--11.  Is there any correlation between number of wins and team salary?
-- Use data from 2000 and later to answer this question.
-- As you do this analysis, keep in mind that salaries across the whole league tend to increase together, so you may want to look on a year-by-year basis.
​
WITH team_year_sal_w AS (SELECT teamid, yearid, SUM(salary) AS total_team_sal, AVG(w)::integer AS w
						 FROM salaries INNER JOIN teams USING(yearid, teamid)
						 WHERE yearid >= 2000
						 GROUP BY yearid, teamid)
SELECT yearid, CORR(total_team_sal, w) AS sal_win_corr
FROM team_year_sal_w
GROUP BY yearid
ORDER BY yearid;
​
​
-- 12. In this question, you will explore the connection between number of wins and attendance.
-- Does there appear to be any correlation between attendance at home games and number of wins?
-- Do teams that win the world series see a boost in attendance the following year?
-- What about teams that made the playoffs?
-- Making the playoffs means either being a division winner or a wild card winner.
​
SELECT CORR(homegames.attendance, w) AS corr_attend_w --COUNT(DISTINCT playerid)
FROM teams INNER JOIN homegames ON teamid = team AND yearid = year
WHERE homegames.attendance IS NOT NULL
​
SELECT AVG(hg_2.attendance - hg_1.attendance) AS avg_attend_inc, stddev_pop(hg_2.attendance - hg_1.attendance) AS stdev_attend_inc 
--DISTINCT name, yearid, hg_1.attendance, hg_2.year, hg_2.attendance, hg_2.attendance - hg_1.attendance AS attend_inc
FROM teams INNER JOIN homegames AS hg_1 ON teams.yearid = hg_1.year AND teams.teamid = hg_1.team
	 INNER JOIN homegames AS hg_2 ON teams.yearid + 1 = hg_2.year AND teams.teamid = hg_2.team
WHERE wswin = 'Y'
	  AND hg_1.attendance > 0
	  AND hg_2.attendance > 0;
​
SELECT AVG(hg_2.attendance - hg_1.attendance) AS avg_attend_inc, stddev_pop(hg_2.attendance - hg_1.attendance) AS stdev_attend_inc
--DISTINCT name, yearid, hg_1.attendance, hg_2.year, hg_2.attendance, hg_2.attendance - hg_1.attendance AS attend_inc
FROM teams INNER JOIN homegames AS hg_1 ON teams.yearid = hg_1.year AND teams.teamid = hg_1.team
	 INNER JOIN homegames AS hg_2 ON teams.yearid + 1 = hg_2.year AND teams.teamid = hg_2.team
WHERE (divwin = 'Y' OR wcwin = 'Y')
	  AND hg_1.attendance > 0
	  AND hg_2.attendance > 0;
​
​
​
-- 13. It is thought that since left-handed pitchers are more rare, causing batters to face them less often, that they are more effective.
-- Investigate this claim and present evidence to either support or dispute this claim.
-- First, determine just how rare left-handed pitchers are compared with right-handed pitchers.
-- Are left-handed pitchers more likely to win the Cy Young Award?
-- Are they more likely to make it into the hall of fame?
​
SELECT *
FROM halloffame
​
WITH pitchers AS (SELECT *
				  FROM people INNER JOIN pitching USING(playerid)
				 	   INNER JOIN awardsplayers USING(playerid)
				 	   INNER JOIN halloffame USING(playerid))
SELECT (SELECT COUNT(DISTINCT playerid)::float FROM pitchers WHERE throws = 'L')/COUNT(DISTINCT playerid)::float AS pct_left_pitch,
	   (SELECT COUNT(DISTINCT playerid)::float FROM pitchers WHERE awardid = 'Cy Young Award')/COUNT(DISTINCT playerid)::float AS pct_cy_young,
	   ((SELECT COUNT(DISTINCT playerid)::float FROM pitchers WHERE awardid = 'Cy Young Award')/COUNT(DISTINCT playerid)::float) * ((SELECT COUNT(DISTINCT playerid)::float FROM pitchers WHERE throws = 'L')/COUNT(DISTINCT playerid)::float) AS calc_pct_left_cy_young,
	   (SELECT COUNT(DISTINCT playerid)::float FROM pitchers WHERE awardid = 'Cy Young Award' AND throws = 'L')/COUNT(DISTINCT playerid)::float AS actual_pct_left_cy_young,
	   (SELECT COUNT(DISTINCT playerid)::float FROM pitchers WHERE inducted = 'Y')/COUNT(DISTINCT playerid)::float AS pct_hof,
	   ((SELECT COUNT(DISTINCT playerid)::float FROM pitchers WHERE inducted = 'Y')/COUNT(DISTINCT playerid)::float) * ((SELECT COUNT(DISTINCT playerid)::float FROM pitchers WHERE throws = 'L')/COUNT(DISTINCT playerid)::float) AS calc_pct_left_hof,
	   (SELECT COUNT(DISTINCT playerid)::float FROM pitchers WHERE inducted = 'Y' AND throws = 'L')/COUNT(DISTINCT playerid)::float AS actual_pct_left_hof
FROM pitchers;
Collapse



