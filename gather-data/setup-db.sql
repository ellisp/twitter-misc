
--Don't uncomment and run this script! it drops all the tables in the database, and with them, all their data.,
/*
 * DROP TABLE IF EXISTS tweets.hashtags;
DROP TABLE IF EXISTS tweets.mentions;
DROP TABLE IF EXISTS tweets.retweeted;
DROP TABLE IF EXISTS tweets.replies;
DROP TABLE IF EXISTS tweets.quoted;
drop table if exists tweets.tweets_rare_characteristics;
DROP TABLE IF EXISTS tweets.tweets;
DROP TABLE IF EXISTS tweets.sources;
DROP TABLE IF EXISTS tweets.users_counts;
DROP TABLE IF EXISTS tweets.users_characteristics;
DROP TABLE IF EXISTS tweets.users;
DROP TABLE IF EXISTS tweets.batches;
*/

CREATE TABLE tweets.batches(
    batch_id                    INT PRIMARY KEY,
    collection_seconds          INT,
    time_collection_started     TIMESTAMP,
    time_collection_finished    TIMESTAMP,
    tweets_downloaded           INT,
    tweets_loaded               INT,
    retweets_loaded             INT,
    quotes_loaded               INT,
    replies_loaded              INT,
    mentions_loaded             INT,
    hashtags_loaded             INT,
    new_sources_loaded          INT,
    new_users_loaded            INT,
    users_followers_counted     INT,
    time_load_completed         TIMESTAMP,
    load_succeeded              BOOLEAN
    );


CREATE TABLE tweets.sources(
    src_id      INT PRIMARY KEY,
    src_name    TEXT NOT NULL,
    batch_id     INT NOT NULL REFERENCES tweets.batches
    
    );

CREATE TABLE tweets.users(
    user_id               BIGINT PRIMARY KEY,
    screen_name           TEXT NOT NULL,
    account_created_at    TIMESTAMP,
    batch_first_observed  INT NOT NULL REFERENCES tweets.batches
);

CREATE TABLE tweets.users_counts(
    user_id          BIGINT REFERENCES tweets.users,
    followers_count  INT,
    friends_count    INT,
    statuses_count   INT,
    favourites_count INT,
    batch_id         INT NOT NULL REFERENCES tweets.batches
);
ALTER TABLE tweets.users_counts ADD PRIMARY KEY (user_id, batch_id);


CREATE TABLE tweets.users_characteristics(
    user_id                      BIGINT NOT NULL REFERENCES tweets.users,
    characteristic               TEXT NOT NULL,
    value                        TEXT NOT NULL,
    batch_first_observed         INT NOT NULL REFERENCES tweets.batches
    );
ALTER TABLE tweets.users_characteristics ADD PRIMARY KEY (user_id, characteristic);


CREATE TABLE tweets.tweets(
    status_id           BIGINT PRIMARY KEY,
    user_id             BIGINT NOT NULL REFERENCES tweets.users,
    text                TEXT NOT NULL,
    number_mentions     INT,
    created_at          TIMESTAMP NOT NULL,
    display_text_width  INT,
    is_quote            BOOLEAN NOT NULL,
    is_retweet          BOOLEAN NOT NULL,
    lang                CHAR(3),   
    is_reply            BOOLEAN NOT NULL,
    src_id              INT NOT NULL REFERENCES tweets.sources,
    batch_id            INT NOT NULL REFERENCES tweets.batches  
);
CREATE INDEX tweeter ON tweets.tweets(user_id);

CREATE TABLE tweets.tweets_rare_characteristics(
	status_id			BIGINT NOT null references tweets.tweets,
	field				TEXT NOT NULL,
	value_sequence		INT NOT NULL,
	value				TEXT NOT NULL
);
ALTER TABLE tweets.tweets_rare_characteristics ADD PRIMARY KEY (status_id, field, value_sequence);


CREATE TABLE tweets.hashtags(
  status_id         BIGINT REFERENCES tweets.tweets,
  hashtag_sequence  INTEGER,
  hashtag           TEXT NOT NULL
);
ALTER TABLE tweets.hashtags ADD PRIMARY KEY (status_id, hashtag_sequence);
CREATE INDEX idx_hash ON tweets.hashtags (hashtag, status_id);

CREATE TABLE tweets.mentions(
    status_id           BIGINT REFERENCES tweets.tweets,
    mentioned_user_id   BIGINT NOT NULL
);
-- it's probably possible for one 'status' (ie tweet) to mention the same user twice so shouldn't make the combination unique, just make an index:
CREATE INDEX idx_men ON tweets.mentions (status_id, mentioned_user_id);
-- Also, we would have a reference from mentioned_user_id to the users table except that we aren't collecting any real information on people
-- who are just metnioned


CREATE TABLE tweets.retweeted(
    status_id           BIGINT REFERENCES tweets.tweets,
    retweet_status_id   BIGINT,
    retweet_user_id     BIGINT REFERENCES tweets.users
);
ALTER TABLE tweets.retweeted ADD PRIMARY KEY (status_id, retweet_status_id);

CREATE TABLE tweets.quoted(
    status_id           BIGINT REFERENCES tweets.tweets,
    quoted_status_id    BIGINT,
    quoted_user_id      BIGINT REFERENCES tweets.users
);
ALTER TABLE tweets.quoted ADD PRIMARY KEY (status_id, quoted_status_id);


CREATE TABLE tweets.replies(
    status_id           BIGINT REFERENCES tweets.tweets,
    reply_to_status_id    BIGINT,
    reply_to_user_id      BIGINT 
);
ALTER TABLE tweets.replies ADD PRIMARY KEY (status_id, reply_to_user_id);

