-- Q1) Extract P_ID,Dev_ID,PName and Difficulty_level of all players 
-- at level 0
SELECT 
	l.P_ID, l.Dev_ID, p.PName, l.Difficulty
FROM 
	level_details2 AS l
JOIN 
	player_details AS p ON l.P_ID = p.P_ID
WHERE 
	l.Level = 0;

-- Q2) Find Level1_code wise Avg_Kill_Count where lives_earned is 2 and atleast
--    3 stages are crossed
SELECT 
	p.L1_Code, AVG(l.Kill_Count) 
FROM 
	player_details AS p
JOIN 
	level_details2 AS l ON p.P_ID = l.P_ID
WHERE 
	l.lives_earned = 2 AND l.stages_crossed > 3
GROUP BY 
	p.L1_Code;

-- Q3) Find the total number of stages crossed at each diffuculty level
-- where for Level2 with players use zm_series devices. Arrange the result
-- in decsreasing order of total number of stages crossed.
SELECT 
	Difficulty, SUM(Stages_crossed) AS total_stages_crossed 
FROM 
	level_details2
WHERE 
	Level = 2 AND Dev_ID IN ('zm_013', 'zm_015', 'zm_017')
GROUP BY 
	Difficulty
ORDER BY 
	total_stages_crossed DESC;

-- Q4) Extract P_ID and the total number of unique dates for those players 
-- who have played games on multiple days.
SELECT 
	P_ID, COUNT(DISTINCT DATE(TimeStamp)) AS total_unique_dates
FROM 
	level_details2
GROUP BY 
	P_ID
HAVING 
	total_unique_dates > 1;

-- Q5) Find P_ID and level wise sum of kill_counts where kill_count
-- is greater than avg kill count for the Medium difficulty.
SELECT 
	P_ID, SUM(Kill_Count) AS total_kill_count, Level
FROM 
	level_details2
WHERE 
	Kill_Count > (
SELECT
	AVG(Kill_Count)
FROM 
	level_details2
WHERE 
	Difficulty = 'Medium'
)
GROUP BY 
	P_ID, Level;

-- Q6)  Find Level and its corresponding Level code wise sum of lives earned 
-- excluding level 0. Arrange in asecending order of level.
SELECT
    l.Level,
    p.L1_Code,
    p.L2_Code,
    SUM(l.Lives_Earned) AS Total_Lives_Earned
FROM
    level_details2 l
JOIN
    player_details p ON l.P_ID = p.P_ID
WHERE
    l.Level <> 0
GROUP BY
    l.Level, p.L1_Code, p.L2_Code
ORDER BY
    l.Level ASC;
    
-- Q7) Find Top 3 score based on each dev_id and Rank them in increasing order
-- using Row_Number. Display difficulty as well.
 WITH Ranked_Scores AS (
    SELECT
        Dev_ID,
        Score,
        Difficulty,
        ROW_NUMBER() OVER (PARTITION BY Dev_ID ORDER BY Score DESC) AS Score_Rank
    FROM
        level_details2
)
SELECT
    Dev_ID,
    Score,
    Difficulty,
    Score_Rank
FROM
    Ranked_Scores
WHERE
    Score_Rank <= 3;

-- Q8) Find first_login datetime for each device id
SELECT
    Dev_ID,
    MIN(TimeStamp) AS first_login
FROM
    level_details2
GROUP BY
    Dev_ID;

-- Q9) Find Top 5 score based on each difficulty level and Rank them in 
-- increasing order using Rank. Display dev_id as well.
 WITH Ranked_Scores AS (
    SELECT
		Difficulty,
		Dev_ID,
        Score,
        RANK() OVER (PARTITION BY Difficulty ORDER BY Score DESC) AS Score_Rank
    FROM
        level_details2
)
SELECT
	Difficulty,
    Dev_ID,
    Score,
	Score_Rank
FROM
    Ranked_Scores
WHERE
    Score_Rank <= 5;

-- Q10) Find the device ID that is first logged in(based on start_datetime) 
-- for each player(p_id). Output should contain player id, device id and 
-- first login datetime.
WITH First_Login_Per_Player AS (
    SELECT
        P_ID,
        Dev_ID,
        MIN(TimeStamp) AS first_login_datetime
    FROM
        level_details2
    GROUP BY
        P_ID, Dev_ID
)

SELECT
    P_ID,
    Dev_ID,
    first_login_datetime
FROM
    First_Login_Per_Player
WHERE
    first_login_datetime = (
        SELECT MIN(first_login_datetime)
        FROM First_Login_Per_Player AS InnerTable
        WHERE InnerTable.P_ID = First_Login_Per_Player.P_ID
    );

-- Q11) For each player and date, how many kill_count played so far by the player. That is, the total number of games played -- by the player until that date.

-- a) window function
SELECT
	P_ID,
    TimeStamp,
    SUM(Kill_Count) OVER (PARTITION BY P_ID ORDER BY TimeStamp) AS total_kills_so_far
FROM
    level_details2;

-- b) without window function
SELECT
    ld.P_ID,
    ld.TimeStamp,
    SUM(ld2.kill_count) AS total_kills_so_far
FROM
    level_details2 ld
JOIN
    level_details2 ld2 ON ld.P_ID = ld2.P_ID AND ld.TimeStamp >= ld2.TimeStamp
GROUP BY
    ld.P_ID, ld.TimeStamp
ORDER BY
    ld.P_ID, ld.TimeStamp;

-- Q12) Find the cumulative sum of an stages crossed over a start_datetime 
-- for each player id but exclude the most recent start_datetime
WITH Ranked_Stages AS (
    SELECT
        P_ID,
        TimeStamp,
        Stages_crossed,
        ROW_NUMBER() OVER (PARTITION BY P_ID ORDER BY TimeStamp DESC) AS row_num
    FROM
        level_details2
)
SELECT
    P_ID,
    TimeStamp,
    SUM(stages_crossed) OVER (PARTITION BY P_ID ORDER BY TimeStamp ASC) AS cumulative_sum_of_stages_crossed
FROM
    Ranked_Stages
WHERE
    row_num > 1;


-- Q13) Extract top 3 highest sum of score for each device id and the corresponding player_id
WITH Ranked_Scores AS (
    SELECT
        Dev_ID,
        P_ID,
        SUM(Score) AS total_scores,
        RANK() OVER (PARTITION BY Dev_ID ORDER BY SUM(Score) DESC) AS Score_Rank
    FROM
        level_details2
    GROUP BY
        Dev_ID, P_ID
)
SELECT
    Dev_ID,
    P_ID,
    total_scores
FROM
    Ranked_Scores
WHERE
    Score_Rank <= 3
ORDER BY
    Dev_ID, Score_Rank;

-- Q14) Find players who scored more than 50% of the avg score scored by sum of 
-- scores for each player_id
WITH sum_of_scores AS (
    SELECT
        P_ID,
        SUM(Score) AS total_score
    FROM
        level_details2
    GROUP BY
        P_ID
)
SELECT
    P_ID,
    total_score 
FROM
    sum_of_scores
WHERE
    total_score > 0.5 * (SELECT AVG(total_score) FROM sum_of_scores);
    
-- Q15) Create a stored procedure to find top n headshots_count based on each dev_id and Rank them in increasing order
-- using Row_Number. Display difficulty as well.
call Get_Top_Headshot_Count(3);

 




						


















  

