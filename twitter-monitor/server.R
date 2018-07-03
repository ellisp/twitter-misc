library(shiny)
library(dplyr)
library(wordcloud)
library(RPostgres)
library(viridis)
library(stringr)
library(ggplot2)
library(forcats)

theme_set(theme_dark(base_family = "FreeSans"))

res <- 72

con <- dbConnect(RPostgres::Postgres(), dbname = "twitter")

tweeters_sql <- "
SELECT
  screen_name, 
  freq,
  (SELECT COUNT(1) 
     FROM tweets.tweets 
     WHERE date_trunc('day', created_at) = 'the_date') / 
   CAST(freq AS DECIMAL) AS inv_prop
FROM
(SELECT
  count(1) AS freq,
  b.screen_name
 FROM 
  tweets.tweets AS a
 LEFT JOIN tweets.users AS b
 ON a.user_id = b.user_id
 WHERE date_trunc('day', a.created_at) = 'the_date'
 GROUP BY b.screen_name
 HAVING count(1) > 1) AS q
ORDER BY freq desc
"


hash_sql <-"
SELECT 
  hashtag,
  COUNT(a.status_id) AS freq,
  lang
FROM
  tweets.hashtags AS a
JOIN
  tweets.tweets AS b
ON a.status_id = b.status_id
WHERE date_trunc('day', b.created_at) = 'the_date'
GROUP BY lang, hashtag
ORDER BY freq DESC"


shinyServer(function(input, output, session) {
  
  the_hash_sql <- reactive({
    gsub("the_date", input$date, hash_sql)
  })
  
  the_tweeters_sql <- reactive({
    gsub("the_date", input$date, tweeters_sql)
  })
  
  hashtags <- reactive({
    dbGetQuery(con, the_hash_sql(), stringsAsFactors = FALSE) %>%
      as_tibble() %>%
      mutate(lang = str_trim(lang))
  })
  
  tweeters <- reactive({
    dbGetQuery(con, the_tweeters_sql(), stringsAsFactors = FALSE) %>%
      as_tibble() 
  })
  
    hash_data_full <- reactive({
      hashtags() %>%
        filter(lang %in% input$langs) %>%
        group_by(hashtag) %>%
        summarise(freq = sum(freq)) %>%
        arrange(desc(freq))
    })  
    
    hash_data <- reactive({
      hash_data_full() %>%
        slice(1:80)
    })
    
    tweeters_plot <- reactive({
      p <- tweeters() %>%
        slice(1:20) %>%
        mutate(freq = as.numeric(freq),
               screen_name = fct_reorder(screen_name, freq)) %>%
        ggplot(aes(y = screen_name, x = freq, label = round(inv_prop, -1))) +
        geom_text() +
        labs(x = "Count in sample", y = "") +
        ggtitle(paste("Prolific tweeters on", input$date),
                "Numbers on graphic show what proportion (eg 1 in 10,000) of all tweets are from this person ")
      return(p)
    })
    output$wcp <- renderImage({
      # This could be done with just renderPlot() but that doesn't work for fonts.
      # See https://stackoverflow.com/questions/31859911/r-shiny-server-not-rendering-correct-ggplot-font-family
      # So unfortunately we need all this palava
      
      # Read myImage's width and height. These are reactive values, so this
      # expression will re-run whenever they change.
      width  <- session$clientData$output_wcp_width
      height <- session$clientData$output_wcp_height
      
      # For high-res displays, this will be greater than 1
      pixelratio <- session$clientData$pixelratio
      
      # A temp file to save the output.
      outfile <- tempfile(fileext='.png')
      
      # Generate the image file
      png(outfile, width = width * pixelratio, height = height * pixelratio,
          res = res * pixelratio)
      par(mai=c(0,0,0,0), bg = "grey50", family = "FreeSans")
      n <- nrow(hash_data())
      wordcloud(hash_data()$hashtag,
                hash_data()$freq,
                random.order = FALSE,
                ordered.colors = TRUE,
                colors = inferno(n, direction = -1))
      dev.off()
      
      # Return a list containing the filename
      list(src = outfile,
           width = width,
           height = height
           )
    }, deleteFile = TRUE)
    
    output$tweeters <- renderImage({
      width  <- session$clientData$output_tweeters_width
      height <- session$clientData$output_tweeters_height
      
      pixelratio <- session$clientData$pixelratio
      
      outfile <- tempfile(fileext='.png')
      
      png(outfile, width = width * pixelratio, height = height * pixelratio,
          res = res * pixelratio)
      print(tweeters_plot())
      dev.off()
      
      # Return a list containing the filename
      list(src = outfile,
           width = width,
           height = height
      )
    }, deleteFile = TRUE)
    
    output$hashn <- renderText(paste0("A sample of ", 
                                      sum(as.numeric(hash_data_full()$freq)),
                                      " hashtags."))
   output$hashes <- renderDataTable(hash_data(), options = list(dom = 't'))
  
   output
   
})
