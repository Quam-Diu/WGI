
# 1. Required libraries
    library(shiny)
    library(dplyr)
    library(tidyr)
    library(ggplot2)

# 2. Adquiring data and initial processing
    
    # 2.1 Download and unzip the data file
        temp <- tempfile()
        download.file("http://databank.worldbank.org/data/download/WGI_csv.zip", temp)
        con <- unz(temp, "WGI_Data.csv")
    
    #2.2 Data tyding 
        dat <- readLines(con, warn=F)
        dat <- gsub("Bahamas, The","Bahamas", dat)
        dat <- gsub("Congo, Dem. Rep.","Zaire", dat)
        dat <- gsub("Congo, Rep.","Congo", dat)
        dat <- gsub("Egypt, Arab Rep.","Egypt", dat)
        dat <- gsub("Gambia, The","Gambia", dat)
        dat <- gsub("Hong Kong SAR, China","Hong Kong", dat)
        dat <- gsub("Iran, Islamic Rep.","Iran", dat)
        dat <- gsub("Korea, Dem. Rep.","North Korea", dat)
        dat <- gsub("Korea, Rep.","South Korea", dat)
        dat <- gsub("Macao SAR, China","Macao", dat)
        dat <- gsub("Macedonia, FYR","Macedonia", dat)
        dat <- gsub("Micronesia, Fed. Sts.","Micronesia", dat)
        dat <- gsub("Taiwan, China","Taiwan", dat)
        dat <- gsub("Venezuela, RB","Venezuela", dat)
        dat <- gsub("Yemen, Rep.","Yemen", dat)
    
    #2.3 Load data as dataframe
        #2.3.1 Initial loading
        wgi.df <- read.csv(textConnection(paste0(dat, collapse="\n")), header =T, sep = ",", dec=".")
        #2.3.2 Separates the column "Indicator.Name" in two
        wgi.df <- separate(wgi.df, Indicator.Name, c("Indicator.Type", "Indicator.Name"), ":")
        #2.3.3 Aditional formating to column names
        names(wgi.df) <- gsub("X", "Y", colnames(wgi.df))
        names(wgi.df) <- gsub("Indicator.Name.", "", colnames(wgi.df))
    
    #2.4 Creates some lists to fill user input fields
        countries <- as.vector(unique(wgi.df$Country.Name))
        ind.types <- as.vector(unique(wgi.df$Indicator.Type))
        years <- as.vector(colnames(wgi.df[,6:ncol(wgi.df)]))

#3. Server
    shinyServer(function(input, output, session) {
    
    #3.1 User interfaces
        #3.1.1 Countries (Central America and Mexico pre-selected)
            output$countryList <- renderUI({
                selectInput("countryInput", "Countries", choices = countries, multiple = TRUE,
                            selected = c("Panama", "Costa Rica", "Nicaragua", "El Salvador", "Honduras", "Guatemala", "Mexico"))
            })
            
        #3.1.2 Years (bi-annual at first, and annual after 2002) 
            output$yearList <- renderUI({
                selectInput("yearInput", "Years", choices = years, multiple = FALSE, selected = "Y2014")
            })
        
        #3.1.3 Types of indicators
            output$indList <- renderUI({ 
                radioButtons("indType", "Indicator type", ind.types)
            })
    
        #3.1.4 List of countries whose trend can be plotted
            #3.1.4.1 Depends of which countries were selected previously
            countryHis <- reactive({as.vector(input$countryInput)})
            #3.1.4.2 By default, the first element of the list is selected
            output$countryHisList <- renderUI({
                selectInput("countryHisInput", "Historical trend", choices = countryHis(), multiple = FALSE, selected = countryHis()[1])
            })
    
        #3.1.5 Years to be includen in the trend plot (2004 to 2014 by default)
            output$hisYearList <- renderUI({ 
                sliderInput("yearRange", "Range", min=1996, max=2014, value = c(2004, 2014))
            })
    
    #3.2 Outputs
        #3.2.1 Comparative plot of selected countries for the chosen year
            output$comPlot <- renderPlot({
    
            #3.2.1.1 Filters the data to be plotted
            filtered <- wgi.df %>% filter(Country.Name %in% input$countryInput,
                                            Indicator.Type == input$indType,
                                            Indicator.Name == " Estimate"
                                        )    
        
            #3.2.1.2 Barplot
            ggplot(aes_string(x="Country.Name", y=input$yearInput, fill="Country.Name", label = input$yearInput), data = filtered) + 
                    geom_bar(stat = 'identity', position = 'dodge', colour="black") +
                    geom_text(aes_string(label=paste("round(",input$yearInput,",2)"), hjust=0.5, vjust=1)) +
                    xlab("Country") + 
                    ylab("Value") +
                    ggtitle(paste(input$indType,"-", gsub("Y", "", input$yearInput))) + #Listens to selected year
                    coord_cartesian(ylim=c(-1.5,1.5)) + 
                    geom_hline(yintercept = 0) +
                    scale_fill_discrete(name="Country") +
                    theme(plot.title = element_text(size=22, colour ="#458B74", vjust =1.5)
                    )
            })
        
        #3.2.2 Text explaining the selected indicator
            output$indType <- renderText({
                types.en <- c("Control of corruption (CC) - measuring perceptions of the extent to which public power is exercised for private gain, including both petty and grand forms of corruption, as well as 'capture' of the state by elites and private interests.",
                              "Government effectiveness (GE) - measuring the quality of public services, the quality of the civil service and the degree of its independence from political pressures, the quality of policy formulation and implementation, and the credibility of the government's commitment to such policies.",
                              "Political stability and absence of violence (PV) - measuring perceptions of the likelihood that the government will be destabilized or overthrown by unconstitutional or violent means, including political violence and terrorism.",
                              "Regulatory quality (RQ) - measuring perceptions of the ability of the government to formulate and implement sound policies and regulations that permit and promote private sector development.",
                              "Rule of law (RL) - measuring perceptions of the extent to which agents have confidence in and abide by the rules of society, and in particular the quality of contract enforcement, the police and the courts, as well as the likelihood of crime and violence.",
                              "Voice and accountability (VA) - measuring perceptions of the extent to which a country's citizens are able to participate in selecting their government, as well as freedom of expression, freedom of association and a free media.")
        
                ind.types <- as.vector(unique(wgi.df$Indicator.Type))
                paste(types.en[which(ind.types==input$indType)])
            })
    
        #3.2.3 Plot of historical data for the selected country, indicator and year range 
            #3.2.3.1 Depends of the selected year range
            countrySeries <- reactive(input$yearRange)
            
            #3.2.3.2 Line plot of the country and year range
            output$hisPlot <- renderPlot({
                
                #3.2.3.2.1 Filters the data according to selected country
                filtered <- wgi.df %>% filter(Country.Name == input$countryHisInput,
                                          Indicator.Type == input$indType,
                                          Indicator.Name == " Estimate"
                                        )    
                #3.2.3.2.2 Year data is in different columns, we need to know which ones
                initCol <- which(colnames(filtered)==paste("Y",countrySeries()[1], sep = ""))
                endCol <- which(colnames(filtered)==paste("Y",countrySeries()[2], sep = ""))
                
                #3.2.3.2.3 One of the indicator names has the backslash character (/), this produces
                # an error when parsing this name as data source for "y" values
                indName <- gsub("[^A-Za-z0-9]", "_", input$indType)
                
                #3.2.3.2.4 Constructs a simplier dataframe to use in the lineplot
                hisct <- as.data.frame(t(filtered[1,initCol:endCol]))
                hisct <- add_rownames(hisct, "VALUE")
                colnames(hisct) <- c("Year", indName)
                hisct[,1] <- as.numeric(gsub("Y", "", hisct[,1]))
        
                #3.2.3.2.5 Lineplot for selected country, indicator and year range
                ggplot(data=hisct, aes_string(x="factor(Year)", y=indName, group=1)) + 
                    geom_line(colour="red", size=1.5) +
                    geom_point(colour="red", size=4, shape=21, fill="white") +
                    geom_text(aes_string(label=paste("round(",indName,",2)"), hjust=0.5, vjust=1)) +
                    xlab("Year") + 
                    ylab("Value") +
                    ggtitle(paste(input$countryHisInput," - ",input$indType, countrySeries()[1], "-", countrySeries()[2])) + #Listens to year range
                    coord_cartesian(ylim=c(-1.5,1.5)) + 
                    geom_hline(yintercept = 0) +
                    geom_smooth() +
                    theme(plot.title = element_text(size=22, colour ="#458B74", vjust =1.5),
                            axis.text.x=element_text(angle=90, hjust=1, vjust=0.5)
                        )
            })
    
        #3.2.4 Final legend with simple reference stats
        output$indStats <- renderText({
            
            #3.2.4.1 Filters the data
            filtered <- wgi.df %>% filter(Country.Name == input$countryHisInput,
                                          Indicator.Type == input$indType,
                                          Indicator.Name == " Estimate"
                                        )    
        
            #3.2.4.2 Calculates basic stats
            indMean <- mean(t(filtered[1,6:ncol(filtered)]))
            indCV <- sqrt(var(t(filtered[1,6:ncol(filtered)])))[1] / indMean
            
            #3.2.4.3 Concatenates texts
            paste("Mean: ", round(indMean, 2), " - ", "Variation coeficient: ", round(indCV,2), "(Statistics from 1996 to last available data)")
        })
    
})