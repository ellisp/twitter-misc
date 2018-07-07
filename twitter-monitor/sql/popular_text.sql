-- method of selecting top n from each group taken from
-- https://spin.atomicobject.com/2016/03/12/select-top-n-per-group-postgresql/
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
      c.screen_name AS example_retweeter,
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
    WHERE date_trunc('day', b.created_at) >= 'the_date_1' AND
          date_trunc('day', b.created_at) <= 'the_date_2' AND
          lang IN ('en', 'ja', 'ko', 'und', 'es', 'th', 'ar', 'fr', 'tr', 'in')) AS a) AS rank_filter 
WHERE rank <= 5;
