from __future__ import absolute_import, print_function

import tweepy
from tweepy.streaming import StreamListener
from tweepy import OAuthHandler
from tweepy import Stream

exec(open('credentials.py').read())


auth = OAuthHandler(consumer_key, consumer_secret)
auth.set_access_token(access_key, access_secret)


# see https://stackoverflow.com/questions/47925828/how-to-create-a-pandas-dataframe-using-tweepy
api = tweepy.API(auth, wait_on_rate_limit=True, wait_on_rate_limit_notify=True)

last_20_tweets_of_FC_Barcelona = api.user_timeline('FCBarcelona')
