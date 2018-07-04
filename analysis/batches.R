library(tidyverse)
library(RPostgres)
library(rsconnect)
library(scales)
library(ggseas)

con <- dbConnect(RPostgres::Postgres(), dbname = "twitter")

batches <- dbGetQuery(con, "select * from tweets.batches where batch_id > 2 order by batch_id", 
                      stringsAsFactors = FALSE) 

x <- ts(batches$tweets_loaded)
tsdisplay(x)
find.freq(x)

batches %>%
  select(time_collection_started, tweets_loaded:users_followers_counted) %>%
  gather(variable, value, -time_collection_started) %>%
  ggplot(aes(x = time_collection_started, y = value)) +
  facet_wrap(~variable, scales = "free_y") +
  geom_line(colour = "steelblue") +
  stat_rollapplyr(width = 24, colour = "white") +
  scale_y_continuous(label = comma) +
  ggtitle("Summary of Twitter information sampled since May 2018",
          "White line is 24 hour moving average; blue line is original data")

# peak times are generally about 15:33 (UTC)
batches %>%
  filter(tweets_loaded > 2000) %>%
  select(time_collection_started)

# https://stats.stackexchange.com/questions/1207/period-detection-of-a-generic-time-series
find.freq <- function(x)
{
  n <- length(x)
  spec <- spec.ar(c(x),plot=FALSE)
  if(max(spec$spec)>10) # Arbitrary threshold chosen by trial and error.
  {
    period <- round(1/spec$freq[which.max(spec$spec)])
    if(period==Inf) # Find next local maximum
    {
      j <- which(diff(spec$spec)>0)
      if(length(j)>0)
      {
        nextmax <- j[1] + which.max(spec$spec[j[1]:500])
        period <- round(1/spec$freq[nextmax])
      }
      else
        period <- 1
    }
  }
  else
    period <- 1
  return(period)
}
