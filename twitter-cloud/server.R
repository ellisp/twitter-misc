library(shiny)
library(dplyr)
library(shiny)
library(wordcloud)

load("hashtags.rda")

# Define server logic required to draw a histogram
shinyServer(function(input, output) {
  
  
   
    the_data <- reactive({
      hashtags %>%
        filter(lang %in% input$langs) %>%
        group_by(hashtag) %>%
        summarise(freq = sum(freq))
    })  
    
    output$wcp <- renderPlot({
      wordcloud(the_data()$hashtag,
                the_data()$freq)
    
  })
  
})
