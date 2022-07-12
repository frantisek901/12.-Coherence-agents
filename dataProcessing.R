#### Script for reading, cleaning and preparing data for other phases of project of Group 12

## Encoding: windows-1250
## Edited:   2022-07-11 FranCesko


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
library(RCA)
library(igraph)
library(ggplot2)

# Loading and cleaning data -----------------------------------------------
raw = read_csv('ESS9e03_1.csv')
#raw = read_csv("ESS9e03_1_complete.csv")
# Reading data 
# from .csv file:
#df <- raw |> 
  #filter(cntry=="DE")

df = read_csv('ESS9e03_1.csv') %>% 
  # Selection of needed variables:
  dplyr::select(idno, freehms, gincdif, lrscale, impcntr, euftf, cntry, ipcrtiv:impfun) %>% 
  # Filtering the cases -- cases with missing values on believes variables deleted:
  filter(freehms <= 5, gincdif <= 5, impcntr <= 4, 
         lrscale <= 10, euftf <= 10) 

df_g <- df |> 
  filter(cntry=="DE")
# %>%
#   # Another filtering -- cases where misses at least one human value are deleted:
#   rowwise() %>% filter(sum(across(ipcrtiv:impfun, ~ .x<=6 )) == 21) %>% ungroup()


# Transform attitude items and calculate correlations -------------------------

# Scaling data to values within [-1, 1]. 
# v' = -1 + 2* (v-m)/(M-m), where m is the lowest, M the highest possible answer
df_s =df_g %>% 
  mutate(
   across(c(freehms, gincdif), ~ -1 + 2*(.x - 1)/(5-1)), 
   across(c(lrscale, euftf), ~ -1 + 2*(.x - 0)/(10-0)), 
   impcntr = -1 + 2*(impcntr - 1)/(4-1)
  )
## BEWARE!!! This code produces scale [-1, 0], not [-1, +1],
## conceptually it makes no difference, we have all at the same scale, 
## but it's not the intended scale.

table(raw$prtclede)

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

glimpse

# Human values computation -----------------------------------------------------

valuenames <- c("ipcrtiv", "imprich", "ipeqopt", "ipshabt", "impsafe", "impdiff", "ipfrule", "ipudrst", 
  "ipmodst", "ipgdtim", "impfree", "iphlppl", "ipsuces", "ipstrgv", "ipadvnt", "ipbhprp",
  "iprspot", "iplylfr", "impenv",  "imptrad", "impfun") 

df_ten <- df |> dplyr::select(idno, ipcrtiv:impfun, cntry) |> #rowwise() |> 
  mutate(Conformity = (!!sym(valuenames[7]) + !!sym(valuenames[16])/2),
         Tradition = (!!sym(valuenames[9]) + !!sym(valuenames[20])/2),
         Benevolence = (!!sym(valuenames[12]) + !!sym(valuenames[18])/2),
         Universalism = (!!sym(valuenames[3]) + !!sym(valuenames[8]) + !!sym(valuenames[19])/3),
         SelfDirection = (!!sym(valuenames[1]) + !!sym(valuenames[11])/2),
         Stimulation = (!!sym(valuenames[6]) + !!sym(valuenames[15])/2),
         Hedonism = (!!sym(valuenames[10]) + !!sym(valuenames[21])/2),
         Achievement = (!!sym(valuenames[4]) + !!sym(valuenames[13])/2),
         Power = (!!sym(valuenames[2]) + !!sym(valuenames[17])/2),
         Security = (!!sym(valuenames[5]) + !!sym(valuenames[14])/2),
         mrat = (ipcrtiv + imprich + ipeqopt + ipshabt + impsafe + impdiff + ipfrule + ipudrst + 
           ipmodst + ipgdtim + impfree + iphlppl + ipsuces + ipstrgv + ipadvnt + ipbhprp +
           iprspot + iplylfr + impenv + imptrad + impfun)/21) |> 
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

##
df_four <- df_ten[sample(nrow(df_ten)),] |> 
  select(idno, Openness:SelfTranscendence) |> 
  pivot_longer(Openness:SelfTranscendence) |> 
  group_by(idno) |> 
  mutate(rank = rank(value)) |> 
  group_by(idno) |> 
  summarize(Value1 = name[value == max(value)][1],
            howmanymaxequal= sum(value==max( value[value!=max(value)] )),
            Value2 = name[value == min(value)][1],
            Consistent =
              str_starts(Value1,"Self") & str_starts(Value2,"Self") |
              Value1 == "Openness" & Value2 == "Conservation" |
              Value2 == "Openness" & Value1 == "Conservation") |> 
   mutate(ValueType = if_else(Consistent, Value1, if_else(howmanymaxequal<2, "Erratic", "2max"))) 

# mutate(ValueType = if_else(howmanymaxequal<2, Value1, "2max")) |>
 

###

table(df_four$howmanymaxequal)
table(df_four$ValueType)

x <- c(0.1,1,2,3,2,3)
sum(x==max( x[x!=max(x)] ))


mds <- df_ten |> select(Conformity:Security) |> t() |> dist() |> 
  cmdscale(eig = TRUE, k =2)
plot(mds$points[,1],mds$points[,2])
text(mds$points[,1],mds$points[,2],labels = row.names(mds$points))
mds <- df_ten |> select(Openness:SelfTranscendence) |> t() |> dist() |> 
  cmdscale(eig = TRUE, k =2)
plot(mds$points[,1],mds$points[,2])
text(mds$points[,1],mds$points[,2],labels = row.names(mds$points))





# Correlations on Subgroups

DF <- df |> left_join(df_four)
DF |> select(attitudenames) |>  cor() |> corrplot(method='number')
matrix1 <- DF |> filter(ValueType == "SelfEnhancement") |> 
  select(attitudenames) |>  cor() |> corrplot(method='number', insig='p-value')
matrix2 <- DF |> filter(ValueType == "Openness") |> 
  select(attitudenames) |>  cor() |> corrplot(method='number')
matrix3 <- DF |> filter(ValueType == "Conservation") |> 
  select(attitudenames) |>  cor() |> corrplot(method='number')
matrix3 <- DF |> filter(ValueType == "Erratic") |> 
  select(attitudenames) |>  cor() |> corrplot(method='number')
# install.packages('gridExtra')
# library(gridExtra)
# grid.arrange(matrix1, matrix2, matrix3)

table(DF$ValueType)


#### Clustering by political party

table(df$prtclede)

matrix1 <- df |> filter(prtclede == 1) |> 
  select(attitudenames) |>  cor() |> corrplot(method='number', insig='p-value')
matrix1 <- df |> filter(prtclede == 2) |> 
  select(attitudenames) |>  cor() |> corrplot(method='number', insig='p-value')
matrix1 <- df |> filter(prtclede == 3) |> 
  select(attitudenames) |>  cor() |> corrplot(method='number', insig='p-value')
matrix1 <- df |> filter(prtclede == 4) |> 
  select(attitudenames) |>  cor() |> corrplot(method='number', insig='p-value')
matrix1 <- df |> filter(prtclede == 5) |> 
  select(attitudenames) |>  cor() |> corrplot(method='number', insig='p-value')
matrix1 <- df |> filter(prtclede == 6) |> 
  select(attitudenames) |>  cor() |> corrplot(method='number', insig='p-value')



DF |> left_join(raw) |> filter(atchctr < 8, atchctr <= 10) |> 
  select(attitudenames) |>  cor() |> corrplot(method='number')
DF |> left_join(raw) |> filter(pray < 6, atchctr <= 7) |> 
  select(attitudenames) |>  cor() |> corrplot(method='number')

# Principal Component Analysis
DF |> select(attitudenames) |>  prcomp()

### RCA:

df_bel <- df_s[1:6]

#x <- RCA(df_bel, alpha = 0.01)
#print(x)
x_five <- RCA(df_bel)
plot(x_five, module = 1, heat_labels = T)
plot(x_five, module = 2, heat_labels = T)
plot(x_five, module = 3, heat_labels = T)
plot(x_five, module = 4, heat_labels = T)
plot(x_five, module = 5, heat_labels = T)
plot(x_five, module = 6, heatmap=F, margin = 0.5, vertex_five_size = 40)
plot(x_five, module = 2, heatmap=F, margin = 0.5, vertex_five_size = 40)
summary(x_five)
plot(x_five, module = 1, heatmap=F, margin = 0.5, vertex_five_size = 40, layout = layout.circle)
plot(x_five, module = 2, heatmap=F, margin = 0.5, vertex_five_size = 40, layout = layout.circle)
plot(x_five, module = 3, heatmap=F, margin = 0.5, vertex_five_size = 40, layout = layout.circle)
plot(x_five, module = 4, heatmap=F, margin = 0.5, vertex_five_size = 40, layout = layout.circle)
plot(x_five, module = 5, heatmap=F, margin = 0.5, vertex_five_size = 40, layout = layout.circle)
plot(x_five, module = 6, heatmap=F, margin = 0.5, vertex_five_size = 40, layout = layout.circle)
print(x_five)

plot_m1 <- recordPlot()

plot(x_five, module = 1, heatmap=F, margin = 0.5, vertex_five_size = 40) |>
  tkplot()

### merging dataframes

# only Germans, all variables
df_g2 <- raw |> 
  filter(cntry=="DE")
df_g4 <- df_g2 |> 
  filter(freehms <= 5, gincdif <= 5, impcntr <= 4, lrscale <= 10, euftf <= 10)
# rescale
df_g3 =df_g4 %>% 
  mutate(
    across(c(freehms, gincdif), ~ -1 + 2*(.x - 1)/(5-1)), 
    across(c(lrscale, euftf), ~ -1 + 2*(.x - 0)/(10-0)), 
    impcntr = -1 + 2*(impcntr - 1)/(4-1)
  )
# flipping
df_g3$freehms <- df_s$freehms * -1
df_g3$gincdif <- df_s$gincdif * -1
df_g3$impcntr <- df_s$impcntr * -1
# create group varible accoring to RCA
df_bel$group <- x_five$membership
df_group <- df_bel[c(1,7)]
# merging 
df_t <- merge(df_g3, df_group, by = 'idno')
df_t$group <- as.factor(df_t$group)


## find out how groups differ

# take group 7 out, because just 2 people
df_t <- df_t |>
  filter(group!='7')

#age
df_t <- df_t |>
  filter(agea<=110)
ggplot(df_t, aes(x=group, y=agea)) + geom_boxplot()

#gender # 1=male, 2=female
table(df_t$gndr, df_t$group)

#beliefs
ggplot(df_t, aes(x=group, y=freehms)) + geom_boxplot()
ggplot(df_t, aes(x=group, y=gincdif)) + geom_boxplot()
ggplot(df_t, aes(x=group, y=impcntr)) + geom_boxplot()
ggplot(df_t, aes(x=group, y=lrscale)) + geom_boxplot()
ggplot(df_t, aes(x=group, y=euftf)) + geom_boxplot()


#Values
df_ten_g <- df_ten |> 
  filter(cntry=="DE")
# merging value and group
df_val <- merge(df_ten, df_group, by = 'idno')
df_val$group <- as.factor(df_val$group)

ggplot(df_val, aes(x=group, y=Openness)) + geom_boxplot()
ggplot(df_val, aes(x=group, y=Conservation)) + geom_boxplot()
ggplot(df_val, aes(x=group, y=SelfTranscendence)) + geom_boxplot()
ggplot(df_val, aes(x=group, y=SelfEnhancement)) + geom_boxplot()

