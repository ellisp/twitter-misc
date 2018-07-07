

tweets <- dbGetQuery(con, "select * from tweets.tweets limit 10")
names(tweets)
tweets$text
# see https://spin.atomicobject.com/2016/03/12/select-top-n-per-group-postgresql/
sql <- 
"
SELECT *
FROM
  (SELECT 
    *,
    rank() OVER (
      PARTITION BY lang
      ORDER BY observed_retweets DESC
    )
  FROM
    (SELECT
      c.screen_name AS retweeter,
      q.freq        AS observed_retweets,
      b.text,
      b.lang
    FROM
      (SELECT
        retweet_status_id, 
        count(1) as freq,
        MIN(status_id) as earliest_retweet
      FROM tweets.retweeted
      GROUP BY retweet_status_id
      ORDER by freq DESC
      ) AS q
    INNER JOIN tweets.tweets AS b
      ON q.earliest_retweet = b.status_id
    INNER JOIN tweets.users AS c
      ON b.user_id = c.user_id
    WHERE lang IN ('en', 'ja', 'ko', 'und', 'es', 'th', 'ar', 'fr', 'tr', 'in')) AS a) AS rank_filter 
WHERE rank <= 5
"
x <- dbGetQuery(con, sql)
head(x)

dbGetQuery(con, "select text from tweets.tweets where status_id = '1010180196140322818'")

1    274
