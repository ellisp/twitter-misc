library(rtweet)
library(tidyverse)
library(scales)
load("twitter_token.rda")

the_user <- "economissive"
# the_user <- "mbiegovtnz"

# I have liked/favorited about 7,700 tweets but we can only get up to 3000
likes <- get_favorites(the_user, token = twitter_token, n = 3000)

n <- 30
likes %>%
  group_by(screen_name) %>%
  summarise(freq = n()) %>%
  arrange(desc(freq)) %>%
  slice(1:n) %>%
  mutate(screen_name = fct_reorder(screen_name, freq)) %>%
  ggplot(aes(x = screen_name, weight = freq)) +
  geom_bar() +
  coord_flip() +
  ggtitle(paste("Top", n, "authors of tweets 'liked' by", the_user))

names(likes)

friends <- get_friends(the_user, token = twitter_token)
friends_df <- lookup_users(friends$user_id, token = twitter_token)


friends_df %>%
  filter(!user_id %in% likes$user_id) %>%
  mutate(description = substring(description, 1, 70)) %>%
  select(user_id, screen_name, description) %>%
  # filter(description == "") %>%
  as.data.frame() %>%
  sample_n(30)
