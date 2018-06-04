# shiny on stream
ui <- fluidPage(

  # App title ----
  titlePanel("Shiny on stream"),

  # Sidebar layout with input and output definitions ----
  sidebarLayout(

    # Sidebar panel for inputs ----
    sidebarPanel(

      p("You can choose which streaming methods are displayed:"),
      # Input: select visualization type ----
      checkboxGroupInput("stream_method",
                         "Streaming alternatives to display:",
                         choices = c(`File tail`                  = "tail_stream",
                                     # `FIFO`                       = "fifo_stream",
                                     `Kafka`                      = "kafka_stream")),
     
      # p("You can also choose which visualizations are displayed:"),
      # # Input: sselect visualization type ----
      # checkboxGroupInput("visu_method",
      #                    "Visualization alternatives to display:",
      #                    choices = c(`base`   = "base_visu",
      #                                `ggplot2` = "ggplot2_visu",
      #                                `textual` = "text_visu")),
     


      # br() element to introduce extra vertical spacing ----
      br(),

      # Input: Slider for the number of observations to generate ----
      sliderInput("rec_per_sec",
                  "Number of records per second:",
                  value = 1,
                  min = 0,
                  max = 1000),
      # extra spacing
      br(),
      # Reference tweet time
      h4("Computer time:"),
      textOutput("clock"),

      h4("Last tweet's time:"),
      textOutput("tweet_time")
      #      p("this work is not - in any manner - in connetction with my work or with my emloyer")
    ),

    # Main panel for displaying outputs ----
    mainPanel(

      # Output: Tabset w/ plot, summary, and table ----
      tabsetPanel(type = "tabs",
                  tabPanel("Visualization with base graphics",
                    fluidRow(
                      column(4,
                        plotOutput("baseplot_tail")
                      ),
                      column(4,
                        plotOutput("baseplot_kafka")
                      )
                  )),

                  tabPanel("Visualization with ggplot",
                    fluidRow(
                      column(4,
                        plotOutput("ggplot_tail")
                      ),
                      column(4,
                        plotOutput("ggplot_kafka")
                      )
                  ))
      )    
    )
  )
)
