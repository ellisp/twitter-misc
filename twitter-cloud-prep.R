library(tidyverse)
library(RPostgres)

con <- dbConnect(RPostgres::Postgres(), dbname = "twitter")

dbGetQuery(con, "select * from tweets.batches order by batch_id") %>% View


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
GROUP BY lang, hashtag"

hashtags <- dbGetQuery(con, sql, stringsAsFactors = FALSE) %>%
  as_tibble() %>%
  mutate(lang = str_trim(lang))

save(hashtags, file = "twitter-cloud/hashtags.rda")

dbDisconnect(con)

top_ten_lang <- hashtags %>%
  group_by(lang) %>%
  summarise(freq = sum(freq)) %>%
  arrange(desc(freq))

top_ten_lang <- top_ten_lang$lang[1:10]
save(top_ten_lang, file = "twitter-cloud/top_ten_lang.rda")

