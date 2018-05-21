library(shiny)
library(dplyr)
library(wordcloud)
library(RPostgres)
library(viridis)

con <- dbConnect(RPostgres::Postgres(), dbname = "twitter")

sql <-"
SELECT 
  hashtag,
  COUNT(a.status_id) AS freq,
  lang
FROM
  tweets.hashtags AS a
JOIN
  tweets.tweets AS b
ON a.status_id = b.status_id
GROUP BY lang, hashtag
ORDER BY freq DESC"

hashtags <- dbGetQuery(con, sql, stringsAsFactors = FALSE) %>%
  as_tibble() %>%
  mutate(lang = str_trim(lang))

shinyServer(function(input, output) {
  
  
   
    the_data <- reactive({
      hashtags %>%
        filter(lang %in% input$langs) %>%
        group_by(hashtag) %>%
        summarise(freq = sum(freq)) %>%
        arrange(desc(freq)) %>%
        slice(1:40)
    })  
    
    output$wcp <- renderPlot({
      par(mai=c(0,0,0,0), bg = "grey50")
      wordcloud(the_data()$hashtag,
                the_data()$freq,
                random.order = FALSE,
                ordered.colors = TRUE,
                colors = inferno(40, direction = -1))
    
  })
  
})
