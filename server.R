#---------------------------------------------------------------------------#
#                                                                           #
# Managing tweet flow and visualization                                     #
#                                                                           #
#---------------------------------------------------------------------------#


get_timestamp <- function(tweet_string){
  tweet_chars <- nchar(tweet_string)
  twtime <- as.numeric(substr(tweet_string, tweet_chars - 14, tweet_chars - 2))/1000
  return(twtime)
}

server <- function(input, output, session) {


  file_data <- reactiveFileReader(
                 intervalMillis = 1000,
                 session        = session, 
                 filePath       = '../poor_mans_version/final_storage/tweets.json',
                 readFunc       = read_tail,
                 n              = 1000
  )

  clock_data <- reactive({
    invalidateLater(1000)
    as.character(Sys.time())
  })


  output$clock <- renderText(clock_data())
  
  

  output$tweet_time <- renderText({
    send_tweets <- reactiveTimer(1000/input$rec_per_sec)
    send_tweets()
     
    tweet_nr <<- tweet_nr + 1

    tweet_to_send <- json_strings[tweet_nr %% length(json_strings)]

    cat(tweet_to_send,
        file = tweet_file,
        sep = "\n",
        append = TRUE)
    
    rkafka::rkafka.send(kafka_producer,
                        kafka_topic,
                        kafka_host,
                        tweet_to_send)
    print(paste0("sent ", tweet_nr, "th tweet to Kafka"))
    tweet_nr <- tweet_nr + 1
    
    return(substr(json_strings[tweet_nr %% length(json_strings)],
                  16, 34))
  })


  json_data_tail <- reactive({
    if("tail_stream" %in% input$stream_method){
        invalidateLater(100000)
        tweet_strings <- read_tail(tweet_file, n = 10000)
        tweet_list <- tweet_strings
        twtimes <- sapply(tweet_list, get_timestamp)
        tweet_time_data <- data.table(tweet_times = as.POSIXct(twtimes, origin = "1970-01-01"))
        tweet_time_data_hour <- tweet_time_data[, .(count=.N), by = .(minute = as.character(round(tweet_times, "mins")))][!is.na(minute)]
        if(!nrow(tweet_time_data_hour)){
          tweet_time_data_hour <- data.table(count=0, minute="1970-01-01 00:00:00")
        }
    
        return(tweet_time_data_hour)
        } else {
          return(data.table(count=0, minute="1970-01-01 00:00:00"))
        }
  })

  json_data_kafka <- reactive({
    if("kafka_stream" %in% input$stream_method){
      invalidateLater(10000)
      new_res <- rkafka.readPoll(kafka_consumer)
      kafka_results <<- c(kafka_results,
                         new_res)
      if(length(kafka_results) > 10000){
        kafka_results <<- kafka_results[length(kafka_results) - c(10000, 0)]
      }
      tweet_list <- kafka_results

      twtimes <- sapply(tweet_list, get_timestamp)
      print("json_data_kafka")
      str(twtimes)
      if(length(twtimes)){
        tweet_time_data <- data.table(tweet_times = as.POSIXct(twtimes, origin = "1970-01-01"))
        tweet_time_data_hour <- tweet_time_data[, .(count=.N), by = .(minute = as.character(round(tweet_times, "mins")))][!is.na(minute)]
      } else {
        tweet_time_data_hour <- data.table(count = 0, minute = "1970-01-01 00:00:00")
      }
      return(tweet_time_data_hour)
    } else {
      return(data.table(count = 0, minute = "1970-01-01 00:00:00"))
    }
  })


  output$ggplot_tail <- renderPlot({

   
   tweet_time_data <- json_data_tail()
   print("AGGREG DAT TAIL")
   str(tweet_time_data)
    ggplot(data = tweet_time_data) +
      geom_bar(aes(x = as.POSIXct(minute), y = count), stat = "identity") +
      theme(axis.text.x = element_text(angle = 90))  +
      ggtitle("gglot from fread('tail file')") +
      xlab("Time of tweet")
  })

  output$baseplot_tail <- renderPlot({

   
   tweet_time_data <- json_data_tail()
   str(tweet_time_data)
   barplot(tweet_time_data$count,
           as.numeric(as.POSIXct(tweet_time_data$minute)),
           main = "Record count in the file")
  })


  output$ggplot_kafka <- renderPlot({

   isolate({kafka_data <- json_data_kafka()})
   print("AGGREG DAT KAFKA")
   str(kafka_data)

    ggplot(data = kafka_data) +
        geom_bar(aes(x = as.POSIXct(minute), y = count), stat = "identity") +
        theme(axis.text.x = element_text(angle = 90))  +
        ggtitle("gglot from fread('tail file')") +
        xlab("Time of tweet")

  })


  output$baseplot_kafka <- renderPlot({

   
   isolate({tweet_time_data <- json_data_kafka()})
   barplot(tweet_time_data$count,
           as.numeric(as.POSIXct(tweet_time_data$minute)),
           main = "Count of records collected from Kafka")
  })


}

