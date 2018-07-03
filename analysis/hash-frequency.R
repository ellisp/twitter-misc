library(tidyverse)
library(RPostgres)

con <- dbConnect(RPostgres::Postgres(), dbname = "twitter")

tags <- c("rstats", "nzpol", "green" ,"wishyouwerehere", "Government", "Budget2018", "climatechange")
res <- list()

for(i in 1:length(tags)){
  sql <- sprintf("SELECT COUNT(1) AS freq FROM tweets.hashtags WHERE hashtag = '%s'", tags[i])
  res[i] <- dbGetQuery(con, sql)
}

data.frame(tags, count = round(unlist(res  )))

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



# top 10 arabic hashtags
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
WHERE lang = 'ar'
GROUP BY lang, hashtag
ORDER BY freq DESC
LIMIT 10"



# Top 10 tweeters
sql <-"
SELECT 
  b.screen_name,
  COUNT(a.status_id) AS freq
FROM
  tweets.tweets AS a
INNER JOIN
  tweets.users AS b
ON a.user_id = b.user_id
GROUP BY b.screen_name
ORDER BY freq DESC
LIMIT 10"
dbGetQuery(con, sql)



# mentions by day
sql <-"
SELECT 
  b.screen_name,
  COUNT(a.status_id) AS freq,
  date_trunc('day', c.created_at) AS day
FROM
  tweets.mentions AS a
INNER JOIN
  tweets.users AS b
ON a.mentioned_user_id = b.user_id
INNER JOIN
  tweets.tweets AS c
ON c.status_id = a.status_id
GROUP BY b.screen_name, date_trunc('day', c.created_at) 
HAVING COUNT(a.status_id)  > 1
ORDER BY freq DESC
"
mentions <- dbGetQuery(con, sql)
head(mentions)
length(unique(mentions$screen_name))

library(forcats)
mentions %>%
  filter(day != max(day)) %>%
  mutate(freq = as.numeric(freq),
         screen_name = fct_reorder(screen_name, -freq),
         screen_name = fct_other(screen_name, keep = levels(screen_name)[1:10] )) %>%
  group_by(screen_name, day) %>%
  summarise(freq = sum(freq)) %>%
  ungroup() %>%
  mutate(screen_name = fct_reorder(screen_name, -freq)) %>%
  ggplot(aes(x = day, y = freq, colour = screen_name)) +
  geom_line() +
    geom_point() +
  scale_y_log10() 

# push those calculations up into the database, and convert them to percentages
# of total mentions
  
dbGetQuery(con, "select * from tweets.batches order by batch_id")    %>% View

dbDisconnect(con)
