#### Script for reading, cleaning and preparing data for other phases of procet of Group 12

## Encoding: windows-1250
## Edited:   2022-07-07 FranĂ?esko


## NOTES:
# 1) selection and filtering is done -- we have 26 vars (21 human values, 5 believes),
#  we have 2,126 observations, i.e. respondents which answer all our 26 questions!
#
# 2) generating of frequency table is not neat -- we might rewrite in more concise way,
#  'rstatix' package, or 'sjmisc' package might help here (Jan would love 'sjmisc', it mimics STATA!)
#
# 3) scaling of the values and finding correlations is done
# 
# 4) Human values are transformed into Schwartz values 


# Header ------------------------------------------------------------------

# cleaning the environment:
rm(list=ls())


# Loading packages:
library(readr)
library(tibble)
library(dplyr)
library(forcats)
library(writexl)
library(corrplot) 
library(tidyverse)

# Loading and cleaning data -----------------------------------------------

# Reading data from .csv file:
df = read_csv('ESS9e03_1.csv') %>% 
  # Selection of needed variables:
  select(idno, freehms, gincdif, lrscale, impcntr, euftf, ipcrtiv:impfun) %>% 
  # Filtering the cases -- cases with missing values on believes variables deleted:
  filter(freehms <= 5, gincdif <= 5, impcntr <= 4, 
         lrscale <= 10, euftf <= 10) 

# %>% 
#   # Another filtering -- cases where misses at least one human value are deleted:
#   rowwise() %>% filter(sum(across(ipcrtiv:impfun, ~ .x<=6 )) == 21) %>% ungroup()


# Transform attitude items and calculate correlations -------------------------

# Scaling data to values within [-1, 1]. 
# v' = -1 + 2* (v-m)/(M-m), where m is the lowest, M the highest possible answer
df_s =df %>% 
  mutate(
   across(c(freehms, gincdif), ~ -1 + (.x - 1)/(5-1)), 
   across(c(lrscale, euftf), ~ -1 + (.x - 0)/(10-0)), 
   impcntr = -1 + (impcntr - 1)/(4-1)
  )

# Flipping some scales:
# some questions are asked in a "negative" sense: 
# e.g. -1 --> "more immigrants" and 1 --> "less immigrants"
# we flip the sign of these questions. 
df_s$freehms <- df_s$freehms * -1
df_s$gincdif <- df_s$gincdif * -1
df_s$impcntr <- df_s$impcntr * -1

# calculate correlation coefficients of the value dimensions
attitudenames = c("freehms", "gincdif", "lrscale", "impcntr", "euftf")
df_cor <- df_s[attitudenames]
x <- cor(df_cor)
corrplot(x, method='number')


# Human values computation -----------------------------------------------------

valuenames <- c("ipcrtiv", "imprich", "ipeqopt", "ipshabt", "impsafe", "impdiff", "ipfrule", "ipudrst", 
  "ipmodst", "ipgdtim", "impfree", "iphlppl", "ipsuces", "ipstrgv", "ipadvnt", "ipbhprp",
  "iprspot", "iplylfr", "impenv",  "imptrad", "impfun")  

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
