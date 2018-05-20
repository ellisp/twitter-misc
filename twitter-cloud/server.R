library(shiny)
library(dplyr)
library(wordcloud)

load("hashtags.rda")

# Define server logic required to draw a histogram
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
      par(mai=c(0,0,0,0))
      wordcloud(the_data()$hashtag,
                the_data()$freq)
    
  })
  
})
