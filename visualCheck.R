#### Visual checking of correlation among belief variables

## Encoding: windows-1250
## Edited:   2022-07-11 FranCesko


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
library(forcats)
library(writexl)
library(corrplot) 
library(tidyverse)
library(PerformanceAnalytics)
library(psych)


# Loading and cleaning data -----------------------------------------------

df = read_csv('ESS9e03_1.csv') %>% 
  # Selection of needed variables:
  select(idno, freehms, gincdif, lrscale, impcntr, euftf,  
         imbgeco, imueclt, imwbcnt, ipcrtiv:impfun) %>% 
  # Filtering the cases -- cases with missing values on believes variables deleted:
  filter(freehms <= 5, gincdif <= 5, impcntr <= 4, 
         lrscale <= 10, euftf <= 10, imbgeco <= 10, imueclt <= 10, imwbcnt <= 10) %>%
  # Another filtering -- cases where misses at least one human value are deleted:
  rowwise() %>% filter(sum(across(ipcrtiv:impfun, ~ .x<=6 )) == 21) %>% ungroup() %>% 
  
  # Scaling data to values within [-1, 1]. 
  # v' = -1 + 2* (v-m)/(M-m), where m is the lowest, M the highest possible answer
  mutate(
    across(c(freehms, gincdif), ~ -1 + (.x - 1)/((5-1) / 2)) , 
    across(c(lrscale, euftf, imbgeco, imueclt, imwbcnt), ~ -1 + (.x - 0)/((10-0) / 2)), 
    impcntr = -1 + (impcntr - 1)/((4-1) / 2)
  ) %>% 
  ## Here is solved the bug from main file -- we just cut the length of scale in half before dividing.
  
  # Flipping some scales:
  # some questions are asked in a "negative" sense: 
  # e.g. -1 --> "more immigrants" and 1 --> "less immigrants"
  # we flip the sign of these questions. 
  mutate(across(c(freehms, gincdif, impcntr), ~ -1 * .x ))
  


# Correletions, just for curiosity ----------------------------------------

# calculate correlation coefficients of the value dimensions
x <- cor(df[,2:9])
corrplot(x, method='number')


# Preparing matrices for p-values and corr-values:
pvm = matrix(rep(0, 64), nrow = 8)
cvm = matrix(rep(0, 64), nrow = 8)
rownames(pvm) = names(df)[2:9]
colnames(pvm) = names(df)[2:9]
rownames(cvm) = names(df)[2:9]
colnames(cvm) = names(df)[2:9]


# Loop for storing the p-values and corr-values of every pair-wise correlation:
for (i in 2:8) {
  for (j in (i + 1):9) {
    r = cor.test(as.vector(as.matrix(df[,i])), as.vector(as.matrix(df[,j])))
    # print(r)
      p = round(r$p.value, 4)
      pvm[i - 1, j - 1] = p 
      pvm[j - 1, i - 1] = p
    if (r$p.value <= 0.001) {
      c = round(r$estimate["cor"], 2)
      cvm[i - 1, j - 1] = c 
      cvm[j - 1, i - 1] = c
    }  
  }
}
# pvm
# cvm
corrplot(cvm, method='number', col.lim = c(min(cvm), max(cvm)), 
         p.mat = pvm, sig.level = 0.001)



# Preparing data for the series of graphs ---------------------------------

dg = df %>% 
  
  # Selection
  select(freehms:imwbcnt) %>% 
  
  # Adding some random noise to make graphs more representative:
  mutate(
    across(c(freehms, gincdif), ~ .x + runif(nrow(df), max = 0.25) - runif(nrow(df), max = 0.25)) , 
    across(c(lrscale, euftf, imbgeco, imueclt, imwbcnt), 
           ~ .x + runif(nrow(df), max = 0.1) - runif(nrow(df), max = 0.1)), 
    impcntr = impcntr  + runif(nrow(df), max = 0.33) - runif(nrow(df), max = 0.33))


# Drawing the graphs ------------------------------------------------------

## Let's start with base R:
pairs(dg)
plot(dg)

## Let's focus on the weak original correlations:
pairs(dg[, c(2, 4, 5)])
plot(dg[, c(2, 4, 5)])

## Let's focus wider -- on all 'gincdif' correlations
pairs(dg[, c(2, 4:8)])
plot(dg[, c(2, 4:8)])

## Fancier graphs with package 'PerformanceAnalytics':
chart.Correlation(dg, histogram = TRUE, method = "pearson")
chart.Correlation(dg[, c(2, 4, 5)], histogram = TRUE, method = "pearson")
chart.Correlation(dg[, c(2, 4:8)], histogram = TRUE, method = "pearson")

## Another fancy graphs with package 'psych':
pairs.panels(dg,
             smooth = TRUE,      # If TRUE, draws loess smooths
             scale = FALSE,      # If TRUE, scales the correlation text font
             density = TRUE,     # If TRUE, adds density plots and histograms
             ellipses = TRUE,    # If TRUE, draws ellipses
             method = "pearson", # Correlation method (also "spearman" or "kendall")
             pch = 21,           # pch symbol
             lm = FALSE,         # If TRUE, plots linear fit rather than the LOESS (smoothed) fit
             cor = TRUE,         # If TRUE, reports correlations
             jiggle = FALSE,     # If TRUE, data points are jittered
             factor = 2,         # Jittering factor
             hist.col = 4,       # Histograms color
             stars = TRUE,       # If TRUE, adds significance level with stars
             ci = TRUE)          # If TRUE, adds confidence intervals
pairs.panels(dg[, c(2, 4, 5)],
             smooth = TRUE,      # If TRUE, draws loess smooths
             scale = FALSE,      # If TRUE, scales the correlation text font
             density = TRUE,     # If TRUE, adds density plots and histograms
             ellipses = TRUE,    # If TRUE, draws ellipses
             method = "pearson", # Correlation method (also "spearman" or "kendall")
             pch = 21,           # pch symbol
             lm = FALSE,         # If TRUE, plots linear fit rather than the LOESS (smoothed) fit
             cor = TRUE,         # If TRUE, reports correlations
             jiggle = FALSE,     # If TRUE, data points are jittered
             factor = 2,         # Jittering factor
             hist.col = 4,       # Histograms color
             stars = TRUE,       # If TRUE, adds significance level with stars
             ci = TRUE)          # If TRUE, adds confidence intervals

pairs.panels(dg[, c(2, 4:8)],
             smooth = TRUE,      # If TRUE, draws loess smooths
             scale = FALSE,      # If TRUE, scales the correlation text font
             density = TRUE,     # If TRUE, adds density plots and histograms
             ellipses = TRUE,    # If TRUE, draws ellipses
             method = "pearson", # Correlation method (also "spearman" or "kendall")
             pch = 21,           # pch symbol
             lm = FALSE,         # If TRUE, plots linear fit rather than the LOESS (smoothed) fit
             cor = TRUE,         # If TRUE, reports correlations
             jiggle = FALSE,     # If TRUE, data points are jittered
             factor = 2,         # Jittering factor
             hist.col = 4,       # Histograms color
             stars = TRUE,       # If TRUE, adds significance level with stars
             ci = TRUE)          # If TRUE, adds confidence intervals


