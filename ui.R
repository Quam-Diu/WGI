
# 1. Required libraries
library(shiny)

# 2. User interface definition
shinyUI(
        
    fluidPage(
        # 2.1 Main title
        titlePanel("World Government Index"),
        sidebarLayout(
                # 2.2 User input
                sidebarPanel(
                    uiOutput("countryList"),
                    uiOutput("yearList"),
                    uiOutput("indList"),
                    uiOutput("countryHisList"),
                    uiOutput("hisYearList")
                ),
                # 2.3 Graphs and other outputs
                mainPanel(
                    plotOutput("comPlot"),
                    textOutput("indType"),
                    plotOutput("hisPlot"),
                    textOutput("indStats")
                )
            )
        )
)