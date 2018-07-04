SELECT * 
FROM tweets.batches
WHERE batch_id > 2 and
       date_trunc('day', time_collection_started) >= 'the_date_1' AND
       date_trunc('day', time_collection_started) <= 'the_date_2'
ORDER BY batch_id;
