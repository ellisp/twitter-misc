library(rtweet)
library(tidyverse)
library(RPostgres)

load("twitter_token.rda")
st <- stream_tweets(token = twitter_token, timeout = 30)

# caution the 0.6.0 version of rtweet on CRAN imports quite a bit less information than does the  0.6.3 on GitHub

# Things to think about:
#    * status_id is the primary key for tweets
#    * one user_id per tweet.  An obvious dimension table is user_id with "latest screen name" and "last observed"
#      columns
#    * mentions_user_id can be NA, a number, or a vector of numbers
#    * mentions_screen_name matches to mentions_user_id but I think it cna change
#    * need a table of user_id, screen_name, observation_time and other things we observed about that user at 
#      that time including followers_count, statuses_count, favourites_count, profile_url, etc,
#    * a better thought - one user_slow_moving with things like screen name and profile; one user_fast_moving
#      with things like statustses_count, favourites_coutn, that change all the time
#    * many things are quite sparse eg media, geo_coords, bbox_coords
#    * relatively small number of source (Tweet Deck, Android, etc) - should be coded

# Tables for:
#   tweets
#   sources
#   mentions
#   hasttags
#   users and their latest screen name
#   users_slow_characteristics (long and thin)
#   users_fast_characteristics (wide)
#   retweet and quote details
#   tweet locations


# TODO - first pull the existing sources down, and remove dupes from the below
# and make sure using the same src_id code
con <- dbConnect(RPostgres::Postgres(), dbname = "twitter")

# for some reason don't have permission to tweets.sources
current_sources <- dbGetQuery(con, "select * from tweets.sources")
sourcen <- max(current_sources$src_id) + 1


sources <- data_frame(src_name = unique(st$source)) %>%
  left_join(current_sources, by = "src_name")

new_sources <- sources %>%
  filter(is.na(src_id)) 

new_sources$src_id <- sourcen:(nrow(new_sources) - 1 + sourcen)

all_sources <- rbind(current_sources, new_sources)
rm(sources)

tweets <- st %>%
  # number of other users mentioned in this tweet:
  mutate(number_mentions = sapply(mentions_user_id, length)) %>%
  select(status_id, user_id, text, number_mentions, source, created_at, display_text_width,
         reply_to_status_id, is_quote, is_retweet, lang) %>%
  mutate(is_reply = !is.na(reply_to_status_id)) %>%
  left_join(all_sources, by = c("source" = "src_name")) %>%
  select(-source, -reply_to_status_id) 

mentions <- st %>%
  select(status_id, mentions_user_id) %>%
  group_by(status_id) %>%
  mutate(mentions_user = paste(unlist(lapply(mentions_user_id, c)), collapse=","),
         mentions_user = ifelse(mentions_user == "NA", NA, mentions_user)) %>%
  filter(!is.na(mentions_user)) %>%
  select(-mentions_user_id) %>%
  separate(mentions_user, sep = ",", into = as.character(1:25), fill = "right") %>%
  gather(mention_sequence, mentioned_user_id, -status_id) %>%
  filter(!is.na(mentioned_user_id)) %>%
  select(-mention_sequence) 

hashtags  <- st %>%
  select(status_id, hashtags) %>%
  group_by(status_id) %>%
  mutate(hash_string = paste(unlist(lapply(hashtags, c)), collapse=","),
         hash_string = ifelse(hash_string == "NA", NA, hash_string)) %>%
  filter(!is.na(hash_string)) %>%
  select(-hashtags) %>%
  separate(hash_string, sep = ",", into = as.character(1:25), fill = "right") %>%
  gather(hashtag_sequence, hashtag, -status_id) %>%
  filter(!is.na(hashtag)) %>%
  mutate(hashtag_sequence = as.integer(hashtag_sequence))


# users' slow characteristics
tweeters_slow <- st %>%
  select(user_id, name, location, description, url, protected,
         verified,
         profile_url, profile_expanded_url, account_lang,
         profile_banner_url, profile_background_url, profile_image_url, created_at) %>%
  rename(observed_at = created_at) %>%
  distinct() %>%
  gather(characteristic, value, -user_id, -observed_at)

tweeters_counts <- st %>%
  select(user_id, followers_count, friends_count, statuses_count, favourites_count, created_at) %>%
  rename(observed_at = created_at) %>%
  distinct() 

quoted_counts <- st %>%
  filter(is_quote) %>%
  select(quoted_user_id, quoted_followers_count, quoted_friends_count, quoted_statuses_count, 
         quoted_favorite_count, created_at) %>%
  rename(
    user_id = quoted_user_id,
    followers_count = quoted_followers_count,
    friends_count = quoted_friends_count,
    favourites_count = quoted_favorite_count,
    statuses_count = quoted_statuses_count,
    observed_at = created_at)

retweet_counts <- st %>%
  filter(is_retweet) %>%
  select(retweet_user_id, retweet_followers_count, retweet_friends_count, retweet_statuses_count, 
         retweet_favorite_count, created_at) %>%
  rename(
    user_id = retweet_user_id,
    followers_count = retweet_followers_count,
    favourites_count = retweet_favorite_count,
    friends_count = retweet_friends_count,
    statuses_count = retweet_statuses_count,
    observed_at = created_at)


users1 <- st %>%
  select(user_id, screen_name, account_created_at, created_at) %>%
  rename(observed_at = created_at) %>%
  distinct(user_id, screen_name, .keep_all = TRUE)

users2 <- st %>%
  filter(is_quote) %>%
  select(quoted_user_id, quoted_screen_name, created_at) %>%
  rename(user_id = quoted_user_id,
         screen_name = quoted_screen_name,
         observed_at = created_at) %>%
  mutate(account_created_at = NA) %>%
  filter(!user_id %in% users1$user_id) %>%
  distinct(user_id, screen_name, .keep_all = TRUE)

users3 <- st %>%
  filter(is_retweet) %>%
  select(retweet_user_id, retweet_screen_name, created_at) %>%
  rename(user_id = retweet_user_id,
         screen_name = retweet_screen_name,
         observed_at = created_at) %>%
  mutate(account_created_at = NA) %>%
  filter(!user_id %in% c(users1$user_id, users2$user_id)) %>%
  distinct(user_id, screen_name, .keep_all = TRUE)


users <- rbind(users1, users2, users3)

users_counts <- rbind(tweeters_counts, retweet_counts, quoted_counts) %>%
  distinct(user_id, observed_at, .keep_all = TRUE)

retweeted <- st %>%
  filter(is_retweet) %>% 
  select(status_id, retweet_status_id, retweet_user_id)

quoted <- st %>%
  filter(is_quote) %>%
  select(status_id, quoted_status_id, quoted_user_id)

replies <- st %>%
  filter(!is.na(reply_to_status_id)) %>%
  select(status_id, reply_to_status_id, reply_to_user_id)

#========================write to staging schema (public) in db=================


dbWriteTable(con, "sources", new_sources, row.names = FALSE, overwrite= TRUE)
dbWriteTable(con, "users", users, row.names = FALSE, overwrite = TRUE)
dbWriteTable(con, "users_counts", users_counts, row.names = FALSE, overwrite = TRUE)
dbWriteTable(con, "retweeted", retweeted, row.names = FALSE, overwrite= TRUE)
dbWriteTable(con, "quoted", quoted, row.names = FALSE, overwrite= TRUE)
dbWriteTable(con, "tweets", tweets, row.names = FALSE, overwrite= TRUE)
dbWriteTable(con, "mentions", mentions, row.names = FALSE, overwrite= TRUE)
dbWriteTable(con, "hashtags", hashtags, row.names = FALSE, overwrite= TRUE)
dbWriteTable(con, "replies", replies, row.names = FALSE, overwrite= TRUE)
