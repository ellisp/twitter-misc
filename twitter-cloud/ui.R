

library(shiny)
load("top_ten_lang.rda")


shinyUI(fluidPage(
  
  # Application title
  titlePanel("A representative random sample of tweets"),
  
   
  sidebarLayout(
    sidebarPanel(
      dateInput('date',
                label = 'Choose a day after 17 May 2018:',
                value = Sys.Date() - 1,
                min = "2018-05-17",
                max = Sys.Date()
      ),
      
      radioButtons(
        "langs",
        "Choose a language",
        choices = top_ten_lang,
        selected = "en"),
      dataTableOutput("hashes")
    ),
    
    # Show a plot of the generated distribution
    mainPanel(
       plotOutput("wcp", height = "600px"),
       textOutput("hashn")
    )
  )
))
