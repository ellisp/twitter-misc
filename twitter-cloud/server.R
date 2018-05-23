library(shiny)
library(dplyr)
library(wordcloud)
library(RPostgres)
library(viridis)
library(stringr)

res <- 72

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

shinyServer(function(input, output, session) {
  
  
   
    the_data <- reactive({
      hashtags %>%
        filter(lang %in% input$langs) %>%
        group_by(hashtag) %>%
        summarise(freq = sum(freq)) %>%
        arrange(desc(freq)) %>%
        slice(1:40)
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
      wordcloud(the_data()$hashtag,
                the_data()$freq,
                random.order = FALSE,
                ordered.colors = TRUE,
                colors = inferno(40, direction = -1))
      dev.off()
      
      # Return a list containing the filename
      list(src = outfile,
           width = width,
           height = height
           )
    }, deleteFile = TRUE)
    
      
    
  
  
})
