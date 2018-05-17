/*
This script is for moving the data in tables in the public schema, where they have been dumped by R, to the tweets schema

*/

-------------------------------Sources--------------
-- These need to be added first
INSERT INTO tweets.sources(src_id, src_name, batch_id)
SELECT
    CAST(src_id AS INT),
    src_name,
    batch_id
FROM public.sources;



----------------------------Users------------------------------
-- will first need to reduce public.users to just those rows not already in there
-- (or create a temporary table that does it, probably easier than DELETE)
--DROP TABLE IF EXISTS public.users2;
--DROP TABLE IF EXISTS public.users3;

SELECT 
    CAST(user_id AS BIGINT) AS user_id,
    screen_name, account_created_at, batch_id
INTO public.users2
FROM public.users; 

SELECT a.*
INTO public.users3
FROM public.users2    AS a
LEFT JOIN tweets.users AS b
ON a.user_id = b.user_id
WHERE b.user_id IS NULL;



INSERT INTO tweets.users(user_id, screen_name, account_created_at, batch_first_observed) 
SELECT
    CAST(user_id AS BIGINT),
    screen_name,
    account_created_at,
    batch_id
FROM public.users3; 

UPDATE tweets.batches
SET new_users_loaded = (SELECT COUNT(1) FROM public.users3)
WHERE batch_id = (SELECT batch_id FROM public.users LIMIT 1);


INSERT INTO tweets.users_counts(user_id, followers_count, friends_count, statuses_count, favourites_count, batch_id)
SELECT
    CAST(user_id AS BIGINT),
    followers_count,
    friends_count,
    statuses_count,
    favourites_count,
    batch_id
FROM public.users_counts;


INSERT INTO tweets.users_characteristics(user_id, characteristic, value, batch_first_observed)
SELECT
    CAST(a.user_id AS BIGINT),
    a.characteristic,
    a.value,
    a.batch_first_observed
FROM public.users_characteristics AS a
INNER JOIN public.users3 AS b
ON CAST(a.user_id AS BIGINT) = b.user_id;


DROP TABLE public.users2;
DROP TABLE public.users3;

-----------------------Tweets-------------------------
INSERT INTO tweets.tweets(
    status_id,
    user_id,
    text,
    number_mentions,
    created_at,
    display_text_width,
    is_quote,
    is_retweet,
    lang,
    is_reply,
    src_id,
    batch_id)
SELECT
    CAST(status_id AS BIGINT),
    CAST(user_id AS BIGINT),
    text,
    number_mentions,
    created_at,
    display_text_width,
    is_quote,
    is_retweet,
    lang,
    is_reply,
    src_id,
    batch_id
FROM public.tweets;


INSERT INTO tweets.tweets_rare_characteristics(status_id, field, value_sequence, value)
SELECT
	CAST(status_id AS BIGINT),
	field,
	value_sequence,
	VALUE
FROM public.tweets_rare_characteristics;


---------------------------Mentions and hashtags------------------------
INSERT INTO tweets.mentions(status_id, mentioned_user_id)
SELECT
    CAST(status_id AS BIGINT),
    CAST(mentioned_user_id AS BIGINT)
FROM public.mentions;



INSERT INTO tweets.hashtags(status_id, hashtag_sequence, hashtag)
SELECT
    CAST(status_id AS BIGINT),
    hashtag_sequence,
    hashtag
FROM public.hashtags;

-------------------------------retweets, quoted and replies--------------------------
INSERT INTO tweets.retweeted(status_id, retweet_status_id, retweet_user_id)
SELECT
    CAST(status_id AS BIGINT),
    CAST(retweet_status_id AS BIGINT),
    CAST(retweet_user_id AS BIGINT)
FROM public.retweeted;

INSERT INTO tweets.quoted(status_id, quoted_status_id, quoted_user_id)
SELECT
    CAST(status_id AS BIGINT),
    CAST(quoted_status_id AS BIGINT),
    CAST(quoted_user_id AS BIGINT)
FROM public.quoted;


INSERT INTO tweets.replies(status_id, reply_to_status_id, reply_to_user_id)
SELECT
    CAST(status_id AS BIGINT),
    CAST(reply_to_status_id AS BIGINT),
    CAST(reply_to_user_id AS BIGINT)
FROM public.replies;


DROP TABLE public.sources;
DROP TABLE public.users;
DROP TABLE public.users_counts;
DROP TABLE public.users_characteristics;
DROP TABLE public.retweeted;
DROP TABLE public.quoted;
DROP TABLE public.tweets;
DROP TABLE public.mentions;
DROP TABLE public.hashtags;
DROP TABLE public.replies;
DROP TABLE public.tweets_rare_characteristics;

