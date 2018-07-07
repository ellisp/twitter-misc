library(tidyverse)
library(RPostgres)

con <- dbConnect(RPostgres::Postgres(), dbname = "twitter")


sql <- "
SELECT
  screen_name, 
  freq,
  CAST(freq AS DECIMAL) / (select count(1) from tweets.tweets) AS prop,
  (select count(1) from tweets.tweets) / CAST(freq AS DECIMAL) AS inv_prop
FROM
  (SELECT
    count(1) AS freq,
    b.screen_name
  FROM 
    tweets.tweets AS a
  LEFT JOIN tweets.users AS b
    ON a.user_id = b.user_id
  GROUP BY b.screen_name
  HAVING count(1) > 1) AS q
ORDER BY freq desc
"

tweeters <- dbGetQuery(con, sql)

dim(tweeters) # 86683 users with > 1 tweet

tweeters %>%
  slice(1:20) %>%
  mutate(freq = as.numeric(freq),
         screen_name = fct_reorder(screen_name, freq)) %>%
  ggplot(aes(y = screen_name, x = freq, label = round(inv_prop, -1))) +
  geom_text() +
  labs(x = "Count in sample", y = "") +
  ggtitle("Most prolific tweeters",
          "Numbers on graphic show what proportion (eg 1 in 10,000) of all tweets are from this person ")

View(x)

x[grepl("venethis", x$screen_name, ignore.case = TRUE), ]
x[grepl("suntory", x$screen_name, ignore.case = TRUE), ]
x[grepl("Love_McD", x$screen_name, ignore.case = TRUE), ]
x[grepl("Sound", x$screen_name, ignore.case = TRUE), ]
x[grepl("scc", x$screen_name, ignore.case = TRUE), ]


# according to https://twittercounter.com/pages/tweets the top 10 twitter users
# are:
top_users <- c("venethis", "akiko_lawson", "Love_McD", "test5f1798", "notiven",
               "Favstar_Bot", "AmexOffers", "BEMANISoundTeam", "__Scc__",
               "ElNacionalWeb")

x[tolower(x$screen_name) %in% tolower(top_users), ]

# so of venethis, AmexOffers BEMANISoundTeam and __Scc___ seem to have gone quiet?
# but;
# venethis still tweeting about 5 times a day. 
# AmexOffers' last tweet Sep 2017, last reply Jan 2018
# bemainsound team silent since March
# __Scc__ tweets are protected, but Twitter Counter says 0 tweets per day

# so from those top 10 we can be pretty confident that I really am sampling the most
# prolific users
