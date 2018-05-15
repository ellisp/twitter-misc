library(rtweet)
library(tidyverse)

load("twitter_token.rda")
st <- stream_tweets(token = twitter_token, timeout = 100)
print(nrow(st))
head(st)
str(st)
class(st)
dim(st)
#View(st)
# 
names(st)

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

sources <- data_frame(src_name = unique(st$source)) %>% mutate(src_id = 1:n())  



tweets <- st %>%
  # number of other users mentioned in this tweet:
  mutate(number_mentions = sapply(mentions_user_id, length)) %>%
  select(status_id, user_id, text, number_mentions, source, created_at, display_text_width,
         reply_to_status_id, reply_to_user_id, is_quote, is_retweet, lang) %>%
  left_join(sources, by = c("source" = "src_name")) %>%
  select(-source) 

mentions <- st %>%
  select(status_id, mentions_user_id) %>%
  group_by(status_id) %>%
  mutate(mentions_user = paste(unlist(lapply(mentions_user_id, c)), collapse=","),
         mentions_user = ifelse(mentions_user == "NA", NA, mentions_user)) %>%
  filter(!is.na(mentions_user)) %>%
  select(-mentions_user_id) %>%
  separate(mentions_user, sep = ",", into = as.character(1:25), fill = "right") %>%
  gather(mention_number, mentioned_user_id, -status_id) %>%
  filter(!is.na(mentioned_user_id)) %>%
  mutate(mention_number = as.integer(mention_number)) 

hashtags  <- st %>%
  select(status_id, hashtags) %>%
  group_by(status_id) %>%
  mutate(hash_string = paste(unlist(lapply(hashtags, c)), collapse=","),
         hash_string = ifelse(hash_string == "NA", NA, hash_string)) %>%
  filter(!is.na(hash_string)) %>%
  select(-hashtags) %>%
  separate(hash_string, sep = ",", into = as.character(1:25), fill = "right") %>%
  gather(hashtag_number, hashtag, -status_id) %>%
  filter(!is.na(hashtag)) %>%
  mutate(hashtag_number = as.integer(hashtag_number))


# users' slow characteristics
users_slow <- st %>%
  select(user_id, name, location, description, url, protected,
         verified,
         profile_url, profile_expanded_url, account_lang,
         profile_banner_url, profile_background_url, profile_image_url, created_at) %>%
  rename(observed_at = created_at) %>%
  distinct() %>%
  gather(characteristic, value, -user_id, -observed_at)

users_fast <- st %>%
  select(user_id, followers_count, friends_count, listed_count, statuses_count, favourites_count, created_at) %>%
  rename(observed_at = created_at) %>%
  distinct() 


users <- st %>%
  select(user_id, screen_name, account_created_at, created_at) %>%
  rename(first_observed = created_at)

# optional - add users who were mentioned or retweeted to this table too and enforce referential integrity
# but this will slow down both this stage, and then later on in the database too.  So decided not to.
# we will only store in the database users that have actually done a tweet (or retweet)

'#---------------------emoticons--------------------------
# https://lyons7.github.io/portfolio/2017-10-04-emoji-dictionary/


download.file("https://raw.githubusercontent.com/lyons7/emojidictionary/master/emoji_dictionary.csv",
              destfile = "assets/emoji_dictionary.csv")

emoticons <- read_csv("assets/emoji_dictionary.csv")

st[1,]
geoDF$text <- iconv(geoDF$text, from = "latin1", to = "ascii", 
                    sub = "byte")


emojireplace <- FindReplace(data = geoDF, Var = "text", 
                            replaceData = emoticons,
                            from = "R_Encoding", to = "Name", 
                            exact = FALSE)

