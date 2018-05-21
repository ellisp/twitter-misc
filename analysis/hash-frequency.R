library(tidyverse)
library(RPostgres)

con <- dbConnect(RPostgres::Postgres(), dbname = "twitter")

?sprintf

tags <- c("rstats", "nzpol", "green" ,"wishyouwerehere", "Government", "Budget2018", "climatechange")
res <- list()

for(i in 1:length(tags)){
  sql <- sprintf("SELECT COUNT(1) AS freq FROM tweets.hashtags WHERE hashtag = '%s'", tags[i])
  res[i] <- dbGetQuery(con, sql)
}

data.frame(tags, count = unlist(res  ))

# Top 10 hashtags by language
sql <-"
SELECT 
  hashtag,
  COUNT(a.status_id) AS freq,
  lang
FROM
  tweets.hashtags AS a
JOIN
  tweets.tweets AS b
ON a.status_id = b.status_id
GROUP BY lang, hashtag
ORDER BY freq DESC
LIMIT 10"

dbGetQuery(con, sql)


# Top 20 hashtags altogether
sql <-"
SELECT 
  hashtag,
  COUNT(status_id) AS freq
FROM
  tweets.hashtags AS a
GROUP BY hashtag
ORDER BY freq DESC
LIMIT 20"

dbGetQuery(con, sql)

sql <-"
SELECT
  t.text,
  u.screen_name
FROM tweets.tweets AS t
JOIN tweets.users AS u
ON t.user_id = u.user_id
JOIN tweets.hashtags AS h
ON t.status_id = h.status_id
WHERE h.hashtag = 'iVoteBTSBBMAs'
LIMIT 20
"
dbGetQuery(con, sql)


# Top 10 mentions
sql <-"
SELECT 
  b.screen_name,
  COUNT(a.status_id) AS freq
FROM
  tweets.mentions AS a
INNER JOIN
  tweets.users AS b
ON a.mentioned_user_id = b.user_id
GROUP BY b.screen_name
ORDER BY freq DESC
LIMIT 10"
dbGetQuery(con, sql)

# sample size
dbGetQuery(con, "select count(1) as n from tweets.tweets")

data <- dbGetQuery(con, 
"select batch_id, new_users_loaded, tweets_loaded, 
new_users_loaded / collection_seconds as users_per_sec,
tweets_loaded / collection_seconds as tweets_per_sec
from tweets.batches order by batch_id") %>%
  as_tibble()


data
ggplot(data, aes(x = batch_id, y = tweets_per_sec)) +
  geom_line()


dbDisconnect(con)
