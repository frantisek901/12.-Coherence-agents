#### Preparation of file with real people believes for ABM model

## Encoding: windows-1250
## Edited:   2022-07-13 FranCesko


## NOTES:
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
library(writexl)
library(RCA)
library(igraph)
library(ggplot2)

# Loading and cleaning data -----------------------------------------------
# There is still some fuss in cleaning line, so for not always reading all data 
# I read them once to 'raw' object and will play with it inside R
raw = read_csv('ESS9e03_1.csv') 
df = raw %>% 
  # We have a full file on wave 9, but now we care on on Germany:
  filter(cntry=="DE") %>% 
  
  # Selection of needed variables:
  select(idno, freehms, gincdif, lrscale, impcntr, euftf) %>% 
  
  # Filtering the cases -- cases with missing values on believes variables deleted:
  filter(freehms <= 5, gincdif <= 5, impcntr <= 4, 
         lrscale <= 10, euftf <= 10) %>%

  # Scaling data to values within [-1, 1]. 
  # v' = -1 + 2* (v-m)/(M-m), where m is the lowest, M the highest possible answer
  mutate(
    across(c(freehms, gincdif), ~ -1 + 2 * (.x - 1)/(5-1)), 
    across(c(lrscale, euftf), ~ -1 + 2 * (.x - 0)/(10-0)), 
    impcntr = -1 + 2* (impcntr - 1)/(4-1)
  ) %>% 
  ## Here is solved the bug from main file -- we just cut the length of scale in half before dividing.
  
  # Flipping some scales:
  # some questions are asked in a "negative" sense: 
  # e.g. -1 --> "more immigrants" and 1 --> "less immigrants"
  # we flip the sign of these questions. 
  mutate(across(c(freehms, gincdif, impcntr), ~ -1 * .x )) 


# CLUSTERING: DONE! (copied from dataProcessing.R)
attitudenames = c("freehms", "gincdif", "lrscale", "impcntr", "euftf")
x_five = RCA(df[attitudenames])


# GROUP assignment: DONE! (copied from dataProcessing.R)
df = df %>% 
  
  # We now assign group membership stored in object 'x_five'  
  mutate(group = x_five$membership) %>% 
  
  # Group 7 has just 2 members we drop it
  filter(group != 7)


# Estimation of coherency matrices:
## Apeksha and Marlene are working on it...








## To the first line of the file we have to write the number of agents used for ABM:
write_csv(tibble(N = as.integer(nrow(df))), "agents.csv", col_names = FALSE, append = FALSE)
write_csv(df, append = TRUE, col_names = TRUE, "agents.csv")
  