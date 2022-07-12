#### Preparation of file with real people believes for ABM model

## Encoding: windows-1250
## Edited:   2022-07-12 FranCesko


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


# Loading and cleaning data -----------------------------------------------

df = read_csv('ESS9e03_1.csv') %>% 
  # Selection of needed variables:
  select(idno, freehms, gincdif, lrscale, impcntr, euftf) %>% 
  # Filtering the cases -- cases with missing values on believes variables deleted:
  filter(freehms <= 5, gincdif <= 5, impcntr <= 4, 
         lrscale <= 10, euftf <= 10) %>%

  # Scaling data to values within [-1, 1]. 
  # v' = -1 + 2* (v-m)/(M-m), where m is the lowest, M the highest possible answer
  mutate(
    across(c(freehms, gincdif), ~ -1 + (.x - 1)/((5-1) / 2)) , 
    across(c(lrscale, euftf), ~ -1 + (.x - 0)/((10-0) / 2)), 
    impcntr = -1 + (impcntr - 1)/((4-1) / 2)
  ) %>% 
  ## Here is solved the bug from main file -- we just cut the length of scale in half before dividing.
  
  # Flipping some scales:
  # some questions are asked in a "negative" sense: 
  # e.g. -1 --> "more immigrants" and 1 --> "less immigrants"
  # we flip the sign of these questions. 
  mutate(across(c(freehms, gincdif, impcntr), ~ -1 * .x )) %>% 
  
  ## Getting group number:
  # for now it is random, but later we use clustering results here...
  mutate(group = sample(
    c(rep(1, 300), rep(2, 700), rep(3, 300), rep(4, 100), rep(5, 400), rep(6, 400)), 
    nrow(.), replace = TRUE))

## To the first line of the file we have to write the number of agents used for ABM:
write_csv(tibble(N = as.integer(nrow(df))), "agents.csv", col_names = FALSE, append = FALSE)
write_csv(df, append = TRUE, col_names = TRUE, "agents.csv")
  