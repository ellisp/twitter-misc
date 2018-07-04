

library(shiny)
load("top_ten_lang.rda")


shinyUI(fluidPage(
  
  # Application title
  titlePanel("A representative random sample of tweets"),
  
   
  sidebarLayout(
    sidebarPanel(
      dateRangeInput('date',
                label = 'Choose a date range:',
                start = Sys.Date() - 2,
                end = Sys.Date() - 1,
                min = "2018-05-17",
                max = Sys.Date()
      ),
      
      conditionalPanel("input.tabs == 'Hashtags'",
        radioButtons(
          "langs",
          "Choose a language",
          choices = top_ten_lang,
          selected = "en"),
        dataTableOutput("hashes")
      )
    ),
    
    # Show a plot of the generated distribution
    mainPanel(
      tabsetPanel(id = "tabs",
        tabPanel("Hashtags",
           imageOutput("wcp", height = "600px"),
           textOutput("hashn")
        ),
        tabPanel("Tweeters",
            imageOutput("tweeters")   
                 ),
        tabPanel("Sampling",
            imageOutput("batches")
            )
      )
    )
    )
  )
)
