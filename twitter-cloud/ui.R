

library(shiny)
load("top_ten_lang.rda")


shinyUI(fluidPage(
  
  # Application title
  titlePanel("Some Twitter Data"),
  
  # Sidebar with a slider input for number of bins 
  sidebarLayout(
    sidebarPanel(
      checkboxGroupInput(
        "langs",
        "Choose one or more languages",
        choices = top_ten_lang,
        selected = "en")
    ),
    
    # Show a plot of the generated distribution
    mainPanel(
       plotOutput("wcp", height = "600px")
    )
  )
))
