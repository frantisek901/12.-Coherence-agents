#### Script for reading, cleaning and preparing data for other phases of procet of Group 12

## Encoding: windows-1250
## Edited:   2022-07-07 FranÈesko


## NOTES:
#
#
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
  select(ipcrtiv:impfun, freehms, gincdif, lrscale, impcntr, euftf)


glimpse(df)




