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
  select(idno, freehms, gincdif, lrscale, impcntr, euftf, ipcrtiv:impfun) %>% 
  
  # Filtering the cases -- cases with missing values on believes variables deleted:
  filter(freehms <= 5, gincdif <= 5, impcntr <= 4, 
         lrscale <= 10, euftf <= 10) %>% 
  
  # Another filtering -- cases where misses at least one human value are deleted:
  rowwise() %>% filter(sum(across(ipcrtiv:impfun, ~ .x<=6 )) == 21) %>% ungroup()


# Quick look at the resulting file:
glimpse(df)

# Human values computation

valuenames <- c("ipcrtiv", "imprich", "ipeqopt", "ipshabt", "impsafe", "impdiff", "ipfrule", "ipudrst", 
  "ipmodst", "ipgdtim", "impfree", "iphlppl", "ipsuces", "ipstrgv", "ipadvnt", "ipbhprp",
  "iprspot", "iplylfr", "impenv",  "imptrad", "impfun")  

library(tidyverse)
df_ten <- df |> select(idno, ipcrtiv:impfun) |> rowwise() |> 
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
  ungroup() |> 
  mutate(across(Conformity:Security, function(x) x - mrat)) |> 
  mutate(Openness = (SelfDirection + Stimulation)/2,
         SelfEnhancement = (Hedonism + Achievement + Power)/3,
         Conservation = (Security + Conformity + Tradition)/3,
         SelfTranscendence = (Benevolence + Universalism)/2)
df_four <- df_ten[sample(nrow(df_ten)),] |> 
  select(idno, Openness:SelfTranscendence) |> 
  pivot_longer(Openness:SelfTranscendence) |> 
  group_by(idno) |> 
  mutate(rank = rank(value)) |> 
  group_by(idno) |> 
  summarize(Value1 = name[value == max(value)][1], 
            Value2 = name[value == min(value)][1],
            Consistent =
              str_starts(Value1,"Self") & str_starts(Value2,"Self") |
              Value1 == "Openness" & Value2 == "Conservation" |
              Value2 == "Openness" & Value1 == "Conservation") |> 
  mutate(ValueType = if_else(Consistent, Value1, "Erratic"))

mds <- df_ten |> select(Conformity:Security) |> t() |> dist() |> 
  cmdscale(eig = TRUE, k =2)
plot(mds$points[,1],mds$points[,2])
text(mds$points[,1],mds$points[,2],labels = row.names(mds$points))
mds <- df_ten |> select(Openness:SelfTranscendence) |> t() |> dist() |> 
  cmdscale(eig = TRUE, k =2)
plot(mds$points[,1],mds$points[,2])
text(mds$points[,1],mds$points[,2],labels = row.names(mds$points))




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



=======
# Frequencies of values -- TODO: Rewrite it in some more inteligent way! 'rstatix' package here might help!
table(df$freehms)
table(df$gincdif)
table(df$lrscale)
table(df$impcntr)
table(df$euftf)
table(df$imprich)
table(df$impfun)
# GREAT! File is clean!
>>>>>>> 88339e351a989f61831ba4742b76067c51fc838f
