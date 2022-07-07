#### Script for reading, cleaning and preparing data for other phases of procet of Group 12

## Encoding: windows-1250
## Edited:   2022-07-07 Fran»esko


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

df = read_csv('ESS9e03_1.csv')

glimpse(df)





# Human values computation

valuenames <- c("ipcrtiv", "imprich", "ipeqopt", "ipshabt", "impsafe", "impdiff", "ipfrule", "ipudrst", 
  "ipmodst", "ipgdtim", "impfree", "iphlppl", "ipsuces", "ipstrgv", "ipadvnt", "ipbhprp",
  "iprspot", "iplylfr", "impenv",  "imptrad", "impfun")  

library(tidyverse)
df_ten <- df |> select(ipcrtiv:impfun) |> rowwise() |> 
  mutate(Conformity = mean(c_across(valuenames[c(7,16)])),
         Tradition = mean(c_across(valuenames[c(9,20)])),
         Benevolence = mean(c_across(valuenames[c(12,18)])),
         Universalism = mean(c_across(valuenames[c(3,8,19)])),
         SelfDirection = mean(c_across(valuenames[c(1,11)])),
         Stimulation = mean(c_across(valuenames[c(6,15)])),
         Hedonism = mean(c_across(valuenames[c(10,21)])),
         Achievement = mean(c_across(valuenames[c(4,13)])),
         Power = mean(c_across(valuenames[c(2,17)])),
         Security = mean(c_across(valuenames[c(5,14)])),
         mrat = mean(c_across(ipcrtiv:impfun)),
         mrat_median = median(c_across(ipcrtiv:impfun))) |> 
  ungroup()
df_ten |> 
  mutate(across(Conformity:Security, function(x) x - mrat)) 



# Conformity       7,16
# Tradition        9,20
# Benevolence      12,18
# Universalism     3,8,19
# Self-Direction   1,11
# Stimulation      6,15
# Hedonism         10,21
# Achievement      4,13
# Power            2,17
# Security         5,14



