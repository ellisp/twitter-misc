

library(shiny)
load("top_ten_lang.rda")


shinyUI(fluidPage(
  tags$style(HTML("@import url('https://fonts.googleapis.com/css?family=Roboto');
@import url('https://fonts.googleapis.com/css?family=Prosto One');
  ")),
  tags$head(
    tags$link(rel = "stylesheet", type = "text/css", href = "my_styles.css")
  ),
  
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
            imageOutput("batches"),
            p("The image above shows the rate at which new data is being 
              sampled from Twitter into the database, in 30 second bursts.
              For example, around 1,000 to 3,000 tweets are loaded in each 
              burst.  Sampling bursts take place once an hour at a random
              time."),
            p("The number of tweets show both daily and weekly periodicity;
              peak time is around 15:30 UTC each day.")
            )
      )
    )
    )
  )
)
