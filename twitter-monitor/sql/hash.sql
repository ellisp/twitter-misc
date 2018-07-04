SELECT 
  hashtag,
  COUNT(a.status_id) AS freq,
  lang
FROM
  tweets.hashtags AS a
JOIN
  tweets.tweets AS b
ON a.status_id = b.status_id
WHERE date_trunc('day', b.created_at) >= 'the_date_1' AND
      date_trunc('day', b.created_at) <= 'the_date_2'
GROUP BY lang, hashtag
ORDER BY freq DESC;
