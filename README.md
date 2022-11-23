# Using news data to forecast economic activity

## Summary
This code uses text analysis techniques to construct a news-based indicator of economic activity. 

The script __1_cleaning__ transforms the body of news articles into a bag of words. I create monthly variables using sentiment analysis and topic modeling. For information about topic modeling, please refer to [this website](https://www.tidytextmining.com/topicmodeling.html) on text mining in R.

The script __2_forecast__ (forthcoming) applies machine learning techniques such as Lasso and Random Forest to predict economic activity using news-based variables and firms expectations.

The data folder contains a Spanish sentiment dictionary that builds on [Kaggle's dictionary](https://www.kaggle.com/datasets/rtatman/sentiment-lexicons-for-81-languages).

For questions or comments, please reach out to me at __guillermopalaciosdiaz@gmail.com__.

## References

1. [Text as data](https://web.stanford.edu/~gentzkow/research/text-as-data.pdf)
2. [Text mining in R](https://www.tidytextmining.com/topicmodeling.html)

