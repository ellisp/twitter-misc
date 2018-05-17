#!/bin/bash
# don't forget to do chmod -x import-stream.sh
cd ~/twitter-misc/
Rscript gather-data/import-stream.R > gather-data/twitter_log.txt
