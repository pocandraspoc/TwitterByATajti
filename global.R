
library(ggplot2)
library(data.table)
library(rkafka)
json_strings <- readRDS("/home/vagrant/repos/shiny_on_stream/data_source/tweets100.RDS")
tweet_file <- "/home/vagrant/repos/shiny_on_stream/data_interface/base.json"
tweet_nr <- 1L
kafka_host <- "10.2.4.18:29092"
zookeeper <- "10.2.4.18:32181"
kafka_topic <- "tweet"
kafka_producer <- rkafka::rkafka.createProducer(kafka_host)
kafka_consumer <- rkafka.createConsumer(zookeeper, kafka_topic, autoCommitInterval=100)
kafka_results <- NULL


# # read the tail of a file
read_tail <- function(path, n){
    data.table::fread(paste0("tail ",
                             path, " -n ",
                             n),
                      sep = "\n",
                      blank.lines.skip = TRUE)[[1]]
}

# dissect json strings
no_wrong_jsons <- function(json_str, file, method = "C", unexpected.escape = "error"){
  suppressWarnings(
    tryCatch({rjson::fromJSON(json_str, file, method, unexpected.escape)},
      warning = function(w){NULL},
      error   = function(e){NULL})
    )
}
