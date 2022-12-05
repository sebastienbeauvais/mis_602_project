####################################################################
# HOME TEAM WINS
#####################################################################
CREATE OR REPLACE TABLE home_team_wins
SELECT
    EXTRACT(YEAR FROM g.local_date) AS year,
    tr.game_id,
    tr.team_id,
    CASE
        WHEN tr.home_away = 'H' AND tr.win_lose = 'W' THEN 1
        ELSE 0
    END AS HomeTeamWins
FROM
    team_results tr
JOIN game g
ON g.home_team_id = tr.team_id
GROUP BY g.game_id;

#####################################################################
# GETTING HOME TEAM BATTING STATS
#####################################################################
CREATE OR REPLACE TABLE home_batting_stats
SELECT
    EXTRACT(YEAR FROM g.local_date) AS year,
    g.game_id,
    g.home_team_id AS home_team,
    CASE
        WHEN tbc.atBat = 0 THEN 0
        ELSE tbc.Hit/tbc.atBat
    END AS home_batting_avg,
    CASE
        WHEN tbc.Hit = 0 THEN 0
        ELSE tbc.Strikeout/tbc.Hit
    END AS home_soh,
    CASE
        WHEN tbc.Hit = 0 THEN 0
        ELSE tbc.Home_Run/tbc.Hit
    END AS home_hrh,
    CASE
        WHEN tbc.Strikeout = 0 THEN 0
        ELSE tbc.Walk/tbc.Strikeout
    END AS home_bb_k
FROM
    game g
JOIN team_batting_counts tbc
ON tbc.team_id = g.home_team_id
GROUP BY
    g.game_id
ORDER BY
    g.game_id, g.home_team_id DESC;

#####################################################################
# GETTING HOME TEAM PITCHING STATS
#####################################################################
CREATE OR REPLACE TABLE home_pitching_stats
SELECT
    EXTRACT(YEAR FROM g.local_date) AS year,
    g.game_id,
    g.home_team_id AS home_team,
    CASE
        WHEN tpc.Strikeout = 0 THEN 0
        ELSE tpc.Hit/tpc.Strikeout
    END AS home_hso,
    CASE
        WHEN tpc.Walk = 0 THEN 0
        ELSE tpc.Strikeout/tpc.Walk
    END AS home_k_bb,
    CASE
        WHEN (tpc.atBat+tpc.Walk+tpc.Hit_By_Pitch+tpc.Sac_Fly) = 0 THEN 0
        ELSE (tpc.Hit+tpc.Walk+tpc.Hit_By_Pitch)/(tpc.atBat+tpc.Walk+tpc.Hit_By_Pitch+tpc.Sac_Fly)
    END AS home_obp
FROM
    game g
JOIN team_pitching_counts tpc
ON tpc.team_id = g.home_team_id
GROUP BY
    g.game_id
ORDER BY
    g.game_id, g.home_team_id DESC;

#####################################################################
# GETTING AWAY TEAM STATS
#####################################################################
CREATE OR REPLACE TABLE away_batting_stats
SELECT
    EXTRACT(YEAR FROM g.local_date) AS year,
    g.game_id,
    g.away_team_id AS away_team,
    CASE
        WHEN tbc.atBat = 0 THEN 0
        ELSE tbc.Hit/tbc.atBat
    END AS away_batting_avg,
    CASE
        WHEN tbc.Hit = 0 THEN 0
        ELSE tbc.Strikeout/tbc.Hit
    END AS away_soh,
    CASE
        WHEN tbc.Hit = 0 THEN 0
        ELSE tbc.Home_Run/tbc.Hit
    END AS away_hrh,
    CASE
        WHEN tbc.Strikeout = 0 THEN 0
        ELSE tbc.Walk/tbc.Strikeout
    END AS away_bb_k
FROM
    game g
JOIN team_batting_counts tbc
ON tbc.team_id = g.away_team_id
GROUP BY
    g.game_id
ORDER BY
    g.game_id, g.away_team_id DESC;

#####################################################################
# GETTING AWAY TEAM PITCHING STATS
#####################################################################
CREATE OR REPLACE TABLE away_pitching_stats
SELECT
    EXTRACT(YEAR FROM g.local_date) AS year,
    g.game_id,
    g.away_team_id AS away_team,
    CASE
        WHEN tpc.Strikeout = 0 THEN 0
        ELSE tpc.Hit/tpc.Strikeout
    END AS away_hso,
    CASE
        WHEN tpc.Walk = 0 THEN 0
        ELSE tpc.Strikeout/tpc.Walk
    END AS away_k_bb,
    CASE
        WHEN (tpc.atBat+tpc.Walk+tpc.Hit_By_Pitch+tpc.Sac_Fly) = 0 THEN 0
        ELSE (tpc.Hit+tpc.Walk+tpc.Hit_By_Pitch)/(tpc.atBat+tpc.Walk+tpc.Hit_By_Pitch+tpc.Sac_Fly)
    END AS away_obp
FROM
    game g
JOIN team_pitching_counts tpc
ON tpc.team_id = g.away_team_id
GROUP BY
    g.game_id
ORDER BY
    g.game_id, g.away_team_id DESC;

#####################################################################
# HOME TEAM STATS
#####################################################################
CREATE OR REPLACE TABLE home_team_stats
SELECT
    hbs.*,
    hps.home_hso,
    hps.home_k_bb,
    hps.home_obp
FROM
    home_batting_stats hbs
LEFT JOIN home_pitching_stats hps
ON hbs.game_id = hps.game_id;

#####################################################################
# AWAY TEAM STATS
#####################################################################
CREATE OR REPLACE TABLE away_team_stats
SELECT
    abs.*,
    aps.away_hso,
    aps.away_k_bb,
    aps.away_obp
FROM
    away_batting_stats abs
LEFT JOIN away_pitching_stats aps
ON abs.game_id = aps.game_id;

#####################################################################
# FINAL QUERY
#####################################################################
CREATE OR REPLACE TABLE baseball_feats
SELECT
    hts.*,
    ats.away_batting_avg,
    ats.away_soh,
    ats.away_hrh,
    ats.away_bb_k,
    ats.away_hso,
    ats.away_k_bb,
    ats.away_obp,
	AVG(hts.home_batting_avg) OVER (PARTITION BY hts.home_team ORDER BY game_id RANGE BETWEEN
	100 PRECEDING AND CURRENT ROW) AS home_100_day_batting_avg,
	AVG(hts.home_soh) OVER (PARTITION BY hts.home_team ORDER BY game_id RANGE BETWEEN
	100 PRECEDING AND CURRENT ROW) AS home_100_soh_avg,
	AVG(hts.home_hrh) OVER (PARTITION BY hts.home_team ORDER BY game_id RANGE BETWEEN
	100 PRECEDING AND CURRENT ROW) AS home_100_day_hrh_avg,
	AVG(hts.home_bb_k) OVER (PARTITION BY hts.home_team ORDER BY game_id RANGE BETWEEN
	100 PRECEDING AND CURRENT ROW) AS home_100_day_bb_k_avg,
	AVG(hts.home_hso) OVER (PARTITION BY hts.home_team ORDER BY game_id RANGE BETWEEN
	100 PRECEDING AND CURRENT ROW) AS home_100_day_hso_avg,
	AVG(hts.home_k_bb) OVER (PARTITION BY hts.home_team ORDER BY game_id RANGE BETWEEN
	100 PRECEDING AND CURRENT ROW) AS home_100_day_k_bb_avg,
	AVG(hts.home_obp) OVER (PARTITION BY hts.home_team ORDER BY game_id RANGE BETWEEN
	100 PRECEDING AND CURRENT ROW) AS home_100_day_obp_avg,
	AVG(ats.away_batting_avg) OVER (PARTITION BY ats.away_team ORDER BY game_id RANGE BETWEEN
	100 PRECEDING AND CURRENT ROW) AS away_100_day_batting_avg,
	AVG(ats.away_soh) OVER (PARTITION BY ats.away_team ORDER BY game_id RANGE BETWEEN
	100 PRECEDING AND CURRENT ROW) AS away_100_soh_avg,
	AVG(ats.away_hrh) OVER (PARTITION BY ats.away_team ORDER BY game_id RANGE BETWEEN
	100 PRECEDING AND CURRENT ROW) AS away_100_day_hrh_avg,
	AVG(ats.away_bb_k) OVER (PARTITION BY ats.away_team ORDER BY game_id RANGE BETWEEN
	100 PRECEDING AND CURRENT ROW) AS away_100_day_bb_k_avg,
	AVG(ats.away_hso) OVER (PARTITION BY ats.away_team ORDER BY game_id RANGE BETWEEN
	100 PRECEDING AND CURRENT ROW) AS away_100_day_hso_avg,
	AVG(ats.away_k_bb) OVER (PARTITION BY ats.away_team ORDER BY game_id RANGE BETWEEN
	100 PRECEDING AND CURRENT ROW) AS away_100_day_k_bb_avg,
	AVG(ats.away_obp) OVER (PARTITION BY ats.away_team ORDER BY game_id RANGE BETWEEN
	100 PRECEDING AND CURRENT ROW) AS away_100_day_obp_avg,
    htw.HomeTeamWins
FROM
    home_team_stats hts
LEFT JOIN away_team_stats ats
ON hts.game_id = ats.game_id
LEFT JOIN home_team_wins htw
ON htw.team_id = hts.home_team
GROUP BY hts.game_id;

CREATE OR REPLACE TABLE more_baseball_feats
SELECT
    year,
    (home_batting_avg - away_batting_avg) AS batting_avg,
    (home_soh - away_soh) AS soh,
    (home_hrh - away_hrh) AS hrh,
    (home_bb_k - away_bb_k) AS bb_k,
    (home_hso - away_hso) AS hso,
    (home_k_bb - away_k_bb) AS k_bb,
    (home_obp - away_obp) AS obp,
    (home_100_day_batting_avg - away_100_day_batting_avg) AS comp_100_day_batting_avg,
    (home_100_soh_avg - away_100_soh_avg) AS comp_100_day_soh_avg,
    (home_100_day_hrh_avg - away_100_day_hrh_avg) AS comp_100_day_hrh_avg,
    (home_100_day_bb_k_avg - away_100_day_bb_k_avg) AS comp_100_day_bb_k_avg,
    (home_100_day_hso_avg - away_100_day_hso_avg) AS comp_100_day_hso_avg,
    (home_100_day_k_bb_avg - away_100_day_k_bb_avg) AS comp_100_day_k_bb_avg,
    (home_100_day_obp_avg - away_100_day_obp_avg) AS comp_100_day_obp_avg,
    HomeTeamWins
FROM
    baseball_feats;




