#### Script for reading, cleaning and preparing data for other phases of procet of Group 12

## Encoding: windows-1250
## Edited:   2022-07-07 FranÈesko


## NOTES:
# 1) selection and filtering is done -- we have 26 vars (21 human values, 5 believes),
#  we have 2,126 observations, i.e. respondents which answer all our 26 questions!
#
# 2) generating of frequency table is not neat -- we might rewrite in more concise way,
#  'rstatix' package, or 'sjmisc' package might help here (Jan would love 'sjmisc', it mimics STATA!)
#
#


# Header ------------------------------------------------------------------

# cleaning the environment:
rm(list=ls())


# Loading packages:
library(readr)
library(tibble)
library(dplyr)
library(forcats)
library(writexl)



# Loading and cleaning data -----------------------------------------------

# Reading data from .csv file:
df = read_csv('ESS9e03_1.csv') %>% 
  
  # Selection of needed variables:
  select(freehms, gincdif, lrscale, impcntr, euftf, ipcrtiv:impfun) %>% 
  
  # Filtering the cases -- cases with missing values on believes variables deleted:
  filter(freehms <= 5, gincdif <= 5, impcntr <= 4, 
         lrscale <= 10, euftf <= 10) %>% 
  
  # Another filtering -- cases where misses at least one human value are deleted:
  rowwise() %>% filter(sum(across(ipcrtiv:impfun, ~ .x<=6 )) == 21) %>% ungroup()


# Quick look at the resulting file:
glimpse(df)


# Frequencies of values -- TODO: Rewrite it in some more inteligent way! 'rstatix' package here might help!
table(df$freehms)
table(df$gincdif)
table(df$lrscale)
table(df$impcntr)
table(df$euftf)
table(df$imprich)
table(df$impfun)
# GREAT! File is clean!