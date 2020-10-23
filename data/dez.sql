--1. What range of years for baseball games played does the provided database cover? 

SELECT MIN(yearid), MAX(yearid)
FROM teams;
-- 1871 - 2016

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

-- The avg # of strikeouts increase with each decade.
-- The avg # of Home Runs shows a slight increase across the observation. 

/*11. Is there any correlation between number of wins and team salary? 
Use data from 2000 and later to answer this question.
As you do this analysis, keep in mind that salaries across the whole league 
tend to increase together, so you may want to look on a year-by-year basis.*/

WITH corr_wins_salary AS (SELECT SUM(salaries.salary), SUM(w) as wins, teams
FROM teams 
INNER JOIN salaries USING(teamid)
WHERE teams.yearid >= 2000
GROUP BY teams
ORDER BY sum, wins DESC)
SELECT CORR(sum,wins)
FROM corr_wins_salary;

--0.6592409969492645	

