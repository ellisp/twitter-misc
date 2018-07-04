library(shiny)
library(ggplot2)
library(dplyr)
library(tidyr)
library(scales)
library(wordcloud)
library(RPostgres)
library(viridis)
library(stringr)
library(forcats)

theme_set(theme_dark(base_family = "FreeSans"))

res <- 72

con <- dbConnect(RPostgres::Postgres(), dbname = "twitter")



tweeters_sql <- paste(readLines("sql/tweeters.sql"), collapse = "\n")
hash_sql <- paste(readLines("sql/hash.sql"), collapse = "\n")
batches_sql <- paste(readLines("sql/batches.sql"), collapse = "\n")

shinyServer(function(input, output, session) {
  
  #-------------dynamicall change SQL according to inputs------------
  the_hash_sql <- reactive({
    tmp <- gsub("the_date_1", input$date[1], hash_sql)
    tmp <- gsub("the_date_2", input$date[2], tmp)
    return(tmp)
  })
  
  the_tweeters_sql <- reactive({
    tmp <- gsub("the_date_1", input$date[1], tweeters_sql)
    tmp <- gsub("the_date_2", input$date[2], tmp)
    return(tmp)
  })

  the_batches_sql <- reactive({
    tmp <- gsub("the_date_1", input$date[1], batches_sql)
    tmp <- gsub("the_date_2", input$date[2], tmp)
    return(tmp)
  })
  
  #-----------------download data----------------
  tweeters <- reactive({
    dbGetQuery(con, the_tweeters_sql(), stringsAsFactors = FALSE) %>%
      as_tibble() 
  })

  batches <- reactive({
    dbGetQuery(con, the_batches_sql(), stringsAsFactors = FALSE) %>%
      as_tibble() 
  })
  
  hashtags <- reactive({
    dbGetQuery(con, the_hash_sql(), stringsAsFactors = FALSE) %>%
      as_tibble() %>%
      mutate(lang = str_trim(lang))
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
  
  #----------------define graphics------------------
  tweeters_plot <- reactive({
    p <- tweeters() %>%
      slice(1:20) %>%
      mutate(freq = as.numeric(freq),
             screen_name = fct_reorder(screen_name, freq)) %>%
      ggplot(aes(y = screen_name, x = freq, label = round(inv_prop, -1))) +
      geom_text(colour = "yellow", family = "FreeSans") +
      labs(x = "Count in sample", y = "") +
      ggtitle(paste("Prolific tweeters on", input$date),
              "Numbers on graphic show what proportion (eg 1 in 10,000) of all tweets are from this person ")
    return(p)
  })
  
  batches_plot <- reactive({
    p <- batches() %>%
      select(time_collection_started, tweets_loaded:users_followers_counted) %>%
      gather(variable, value, -time_collection_started) %>%
      mutate(variable = gsub("_loaded$", "", variable),
             variable = gsub("_", " ", variable)) %>%
      ggplot(aes(x = time_collection_started, y = value)) +
      facet_wrap(~variable, scales = "free_y") +
      geom_line(colour = "lightblue", alpha = 0.5) +
      stat_rollapplyr(width = 24, colour = "white") +
      scale_y_continuous(label = comma) +
      labs(x = "") +
      ggtitle("Summary of Twitter information sampled since May 2018",
              "White line is 24 hour moving average; blue line is original data")
    return(p)
  })
  
  #----------------render graphics---------------------
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

  output$batches <- renderImage({
    width  <- session$clientData$output_batches_width
    height <- session$clientData$output_batches_height
    
    pixelratio <- session$clientData$pixelratio
    
    outfile <- tempfile(fileext='.png')
    
    png(outfile, width = width * pixelratio, height = height * pixelratio,
        res = res * pixelratio)
    print(batches_plot())
    dev.off()
    
    # Return a list containing the filename
    list(src = outfile,
         width = width,
         height = height
    )
  }, deleteFile = TRUE)
  
  
  #-------------------render data tables--------------------  
  output$hashn <- renderText(paste0("A sample of ", 
                                    sum(as.numeric(hash_data_full()$freq)),
                                    " hashtags."))
  output$hashes <- renderDataTable(hash_data(), options = list(dom = 't'))
  
   
})
