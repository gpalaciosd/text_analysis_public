############################################################################
"Cleaning code                                                      
Goal: Run sentiment analysis & topic modeling
Output: Sentiment and topic variables"
############################################################################

################################################################################
## 1. Transforming the body of the articles into a bag of words
################################################################################

# Install packages
#install.packages("corpus")
#install.packages("tm")
#install.packages("SnowballC")

# Load packages
library(tidyverse)
library(corpus)
library(tm)
library(stringr)
library(stringi)
library(SnowballC)

load('../../text_analysis/data/news_data.Rda')
news_data <- news_data %>%
  mutate(document=row_number()) 
head(news_data)

# Can work with the article's title or body. Working with article's body.
# Can also restrict articles to specific categories. In this case all are econ-related, so I'm keeping all of them
news_data <- news_data %>%
  select(document,month,article)

# Drop duplicates
mean(duplicated(news_data))
news_data <- news_data[!duplicated(news_data),]
dim(news_data)

# Make dataset smaller for testing
#news_data <- news_data[sample(1:nrow(news_data), 1000,replace=FALSE),]
#dim(news_data)

# News into corpus
news_data$article <- as.character(news_data$article)
news_corpus <- VCorpus(VectorSource(news_data$article))
inspect(news_corpus[[1]])

# Cleaning 
news_corpus <- news_corpus %>%
  tm_map(content_transformer(stringi::stri_trans_tolower)) %>%
  tm_map(content_transformer(removePunctuation)) %>%
  tm_map(removeNumbers) %>%
  tm_map(content_transformer(gsub), pattern = "estados unidos", replacement = "eeuu") %>%
  tm_map(content_transformer(gsub), pattern = "epladmmovilm|epladminlined", replacement = "") %>%
  tm_map(stripWhitespace)
inspect(news_corpus[[1]])

# Cleaning for sentiment analysis doesn't require stemming words or removing tildes. Two different datasets.
news_corpus_SA <- news_corpus

# Continue the cleaning for topic modeling
news_corpus <- news_corpus %>%     
  tm_map(content_transformer(gsub), pattern = "á", replacement = "a") %>%
  tm_map(content_transformer(gsub), pattern = "é", replacement = "e") %>%
  tm_map(content_transformer(gsub), pattern = "í", replacement = "i") %>%
  tm_map(content_transformer(gsub), pattern = "ó", replacement = "o") %>%
  tm_map(content_transformer(gsub), pattern = "ú", replacement = "u") %>%
  tm_map(removeWords, stopwords("spanish")) %>%
  #tm_map(PlainTextDocument) %>%
  tm_map(stemDocument, "spanish")
inspect(news_corpus[[222]])

# Convert from corpus to dtm, remove empty columns
news_dtm <- DocumentTermMatrix(news_corpus)
ui = unique(news_dtm$i)
news_dtm <- news_dtm[ui,]
#news_dtm <- removeSparseTerms(news_dtm, 0.97)
#inspect(news_dtm)

################################################################################
## 2. Constructing text variables
################################################################################

### 2.1. Sentiment analysis
################################################################################

library(magrittr) 
library(tidyverse) 
library(tidytext)  
library(ldatuning) 
library(topicmodels) 
library(SentimentAnalysis)
library(readxl)

# Transform data
news_dtm_SA <- DocumentTermMatrix(news_corpus_SA)
ui = unique(news_dtm_SA$i)
news_dtm_SA <- news_dtm_SA[ui,]
inspect(news_dtm_SA)
news_dtm_SA <- removeSparseTerms(news_dtm_SA, 0.97)

# Load dictionary
dictionary <- read_excel("../data/dictionary.xlsx")

# Data as tidy
news_tidy <- tidy(news_dtm_SA) ## Documento, palabra, cuantas veces ## xx puedo ahora agregar a nivel de mes?
head(news_tidy)

# Words frequently used 
news_freq <- news_tidy %>%
  group_by(term) %>%
  summarize(count=sum(count)) %>%
  arrange(desc(count))

# Merge news data with dictionary
news_sentiment <- left_join(news_tidy, dictionary, by = "term")
head(news_sentiment)

# Assume that if can't find the term, the word is neutral. Needs to be checked.
news_sentiment <- news_sentiment %>% 
  replace(., is.na(.), 0)

# Calculate number of positive and negative words in a document. Compare number of positive and negative words
news_sentiment <- news_sentiment %>%
  mutate(pos = count * score_pos,
         neg = count * score_neg) %>%
  select(document,term,pos,neg) %>%
  group_by(document) %>%
  summarize(pos = sum(pos),neg=sum(neg)) %>%
  mutate(pos_dum = pos>neg,neg_dum = neg>pos,document=as.numeric(document))

# Monthly data
sentiment_data <- left_join(news_data,news_sentiment,by="document")
sentiment_data <- sentiment_data %>%
  select(-article) %>%
  group_by(month) %>%
  summarize(pos=sum(pos,na.rm=T),
            neg=sum(neg,na.rm=T),
            pos_dum=mean(pos_dum,na.rm=T),
            neg_dum=mean(neg_dum,na.rm=T))
head(sentiment_data)

# Create index
sentiment_data <- sentiment_data %>%
  mutate(index=((pos-neg)/(pos+neg)+1)*50)
head(sentiment_data)

sentiment_data <- sentiment_data %>%
  mutate(var_index = index - lag(index,1),
         var_pos = pos_dum - lag(pos_dum,1),
         var_neg = neg_dum - lag(neg_dum,1)) %>%
  select(-pos,-neg)
head(sentiment_data)

### 2.2. Topic modeling
################################################################################

#install.packages("tidytext")
#install.packages("ldatuning")
#install.packages("topicmodels")
#install.packages("fastDummies")
library(tidytext)  
library(ldatuning) 
library(topicmodels) 
library(fastDummies)

# Define number of topics. Get topics
k = 8 # Can use LDA tuning to find the optimal number of topics 
news_lda <- LDA(news_dtm, k, control = list(seed = 1234))
news_lda

# Most common words
news_topics <- tidy(news_lda, matrix = "beta")
head(news_topics)
news_top_terms <- news_topics %>%
  group_by(topic) %>%
  top_n(10, beta) %>%
  ungroup() %>%
  arrange(topic, -beta)
news_top_terms %>%
  mutate(term = reorder(term, beta)) %>%
  ggplot(aes(term, beta, fill = factor(topic))) +
  geom_col(show.legend = FALSE) +
  facet_wrap(~ topic, scales = "free") +
  coord_flip()

news_gamma <- tidy(news_lda, matrix = "gamma")
head(news_gamma)

# Stats at the document level: Gamma (how much of each document is topic k)
news_gamma_r <- news_gamma %>%
  pivot_wider(names_from=topic, values_from = gamma, names_prefix = "gamma_") %>%
  mutate(document=as.numeric(document))
head(news_gamma_r)

# Add month information
topics_data <- left_join(news_data,news_gamma_r,by="document")
topics_data <- topics_data %>%
  select(-article)
head(topics_data)

# Assign words to topics
news_assignments <- as.data.frame(augment(news_lda, data = news_dtm))

# For each document, calculate the number of words that can be associated to each topic. Reshape.
counts_data <- aggregate(news_assignments$count, list(news_assignments$.topic,news_assignments$document), sum)
colnames(counts_data)[1] <- "topic"
colnames(counts_data)[2] <- "document"
colnames(counts_data)[3] <- "count"
counts_data <- counts_data[order(counts_data$topic),]
counts_data_r <- reshape(data=counts_data,idvar="document",
                         v.names = "count",
                         timevar = "topic",
                         direction="wide",
                         sep = "_")
head(counts_data_r)

document_data <- news_data %>%
  select(month,document)
document_data <- merge(document_data,counts_data_r,by="document")
head(document_data)

# For each document, identify which topic is more predominant
counts_data_v2 <- counts_data %>%
  group_by(document) %>%
  filter(count==max(count))  %>%
  slice(1) %>%
  select(document,topic)
document_data_v2 <- merge(document_data,counts_data_v2,by="document")
names(document_data_v2)[names(document_data_v2) == 'topic'] <- 'news'
document_data_v2 <- dummy_cols(document_data_v2,select_columns='news')
document_data_v2 <- document_data_v2 %>%
  select(-news)
head(document_data_v2)

# Merge topic variables
all_data <- merge(topics_data,document_data_v2,by=c("document","month"))
head(all_data)

# Stats at the month level
gammas <- all_data %>%
  group_by(month) %>%
  summarise_at(vars(gamma_1:paste("gamma",k,sep="_")), mean, na.rm = TRUE)
counts <- all_data %>%
  group_by(month) %>%
  summarise_at(vars(count_1:paste("news",k,sep="_")), sum, na.rm = TRUE)
topic_variables <- left_join(gammas,counts,by="month")
head(topic_variables)

# Merge all news-based variables.
news_variables <- merge(topic_variables,sentiment_data,by="month")
head(news_variables)
save(news_variables, file = "../../text_analysis/data/news_variables.Rdata")
