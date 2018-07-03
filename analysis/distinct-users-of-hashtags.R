library(tidyverse)
library(RPostgres)
library(rsconnect)

con <- dbConnect(RPostgres::Postgres(), dbname = "twitter")

dbGetQuery(con, "select * from tweets.batches order by batch_id") %>% View


sql <- "
SELECT 
  hashtag,
  CAST(COUNT(a.status_id) AS DECIMAL)     AS freq,
  CAST(COUNT(DISTINCT(b.user_id)) AS DECIMAL)   AS users
FROM
  tweets.hashtags AS a
JOIN
  tweets.tweets AS b
ON a.status_id = b.status_id
WHERE date_trunc('day', b.created_at) >= '2018/06/01' AND
      date_trunc('day', b.created_at) <= '2018/06/30'
GROUP BY hashtag
HAVING COUNT(a.status_id) > 1
ORDER BY freq DESC;"

hashes <- dbGetQuery(con, sql)
head(hashes, 20)

# interesting inference question - to estimate number of usses of the hashtag, just
# multiply by 120,000 (we are sampling 1/120th of the time ie 30 seconds per hour,
# and have a 1/100 sample).  But how to estimate the number of unique users?

ggplot(hashes, aes(x = freq, y = users)) +
  geom_point() +
  scale_x_log10() +
  scale_y_log10()


model <- lm(users ~ freq + I(freq ^ 2), data = hashes)
summary(model)
