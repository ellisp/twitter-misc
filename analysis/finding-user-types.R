library(tidyverse)
library(RPostgres)

con <- dbConnect(RPostgres::Postgres(), dbname = "twitter")

sql <- "
select 
  b.screen_name, 
  a.value AS description 
FROM tweets.users_characteristics  AS a
LEFT JOIN tweets.users AS b
ON a.user_id = b.user_id
WHERE (value LIKE '%datascience%' OR value LIKE '%statistic%') AND
      characteristic = 'description';
"

x <- dbGetQuery(con, sql)
View(x)
