USE baseball;

ALTER TABLE inning MODIFY COLUMN game_id INT UNSIGNED NOT NULL;

DROP TABLE IF EXISTS temp_stats;
DROP TABLE IF EXISTS hist_bat_avg;
DROP TABLE IF EXISTS temp_year;
DROP TABLE IF EXISTS yearly_bat_avg;
DROP TABLE IF EXISTS temp_rolling;
DROP TABLE IF EXISTS temp_game_stats;
DROP TABLE IF EXISTS temp_game_stats_and_batting_avg;
DROP TABLE IF EXISTS overall_rolling_avg;


CREATE TABLE IF NOT EXISTS hist_bat_avg(batter INT, hit INT, at_bat INT, batting_avg FLOAT(4,3)) ENGINE=MyISAM
SELECT bc.batter, bc.Hit, bc.atBat, 
	SUM(bc.Hit)/SUM(bc.atBat) AS batting_avg
FROM
	batter_counts bc
GROUP BY 
	bc.batter;

CREATE TABLE yearly_bat_avg (year INT, batter INT, total_hits INT, total_atBats INT, yearly_batting_avg FLOAT (4,3)) ENGINE=MyISAM
SELECT YEAR(g.local_date) AS year, bc.batter, 
	SUM(bc.Hit) AS total_hits,
	SUM(bc.atBat) AS total_atBats,
	SUM(bc.Hit)/SUM(atBat) AS yearly_batting_avg
FROM 
	batter_counts bc
JOIN 
	game g
ON g.game_id = bc.game_id
GROUP BY bc.batter, YEAR(g.local_date);

CREATE TEMPORARY TABLE temp_rolling(game_id INT, total_hits INT, total_atBats, batting_avg FLOAT(4,3), game_date DATE)
SELECT g.game_id, 
	SUM(bc.Hit) AS total_hits, 
	SUM(bc.atBat) AS total_atBats, 
	SUM(bc.hit)/SUM(bc.atBat) AS batting_avg,
	DATE(g.local_date) AS date
FROM 
	batter_counts bc
JOIN 
	game g
ON 
	g.game_id = bc.game_id
GROUP BY
	g.game_id
ORDER BY 
	DATE(g.local_date)
;

CREATE TABLE overall_rolling_avg
SELECT *,
	AVG(batting_avg) OVER (ORDER BY date ROWS BETWEEN
	100 PRECEDING AND 1 PRECEDING) AS total_rolling_avg
FROM temp_rolling;

SELECT *
FROM overall_rolling_avg
LIMIT 0,20;
