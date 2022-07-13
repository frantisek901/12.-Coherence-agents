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
library(ggplot2)
library(tidyverse)
library(RCA)
library(igraph)
library(ggplot2)

# Loading and cleaning data -----------------------------------------------
raw = read_csv('ESS9e03_1.csv')
#raw = read_csv("ESS9e03_1_complete.csv")


# Transform attitude items and calculate correlations -------------------------
# Scaling data to values within [-1, 1]. 
# v' = -1 + 2 * (v-m)/(M-m), where m is the lowest, M the highest possible answer
dffull <-  raw %>% 
  # Filtering the cases -- cases with missing values on believes variables deleted:
  filter(freehms <= 5, gincdif <= 5, impcntr <= 4, 
         lrscale <= 10, euftf <= 10)%>%
  mutate(
  across(c(freehms, gincdif), ~ -1 + 2 * (.x - 1)/(5-1)), 
  across(c(lrscale, euftf), ~ -1 + 2 * (.x - 0)/(10-0)), 
  impcntr = -1 + 2* (impcntr - 1)/(4-1)
)
# Flipping some scales:
# some questions are asked in a "negative" sense: 
# e.g. -1 --> "more immigrants" and 1 --> "less immigrants"
# we flip the sign of these questions. 
dffull$freehms <- dffull$freehms * -1
dffull$gincdif <- dffull$gincdif * -1
dffull$impcntr <- dffull$impcntr * -1

dfsel <- dffull %>%
  select(idno,cntry, prtclede, freehms, gincdif, lrscale, impcntr, euftf, ipcrtiv:impfun)

# filter out GERMANY
dffull_g = dffull   |> 
  filter(cntry=="DE")
dfsel_g = dfsel |> 
  filter(cntry=="DE")

table(dfsel$prtclede)
dfsel_gp <- dfsel_g %>%
  filter(prtclede<10)

# calculate correlation coefficients of the value dimensions
attitudenames = c("freehms", "gincdif", "lrscale", "impcntr", "euftf")
columns = append(attitudenames, "idno", after=0)
df_cor <- dfsel[columns]
x <- cor(df_cor[attitudenames])
corrplot(x, method='number')



# Human values computation -----------------------------------------------------

valuenames <- c("ipcrtiv", "imprich", "ipeqopt", "ipshabt", "impsafe", "impdiff", "ipfrule", "ipudrst", 
  "ipmodst", "ipgdtim", "impfree", "iphlppl", "ipsuces", "ipstrgv", "ipadvnt", "ipbhprp",
  "iprspot", "iplylfr", "impenv",  "imptrad", "impfun") 

df_ten <- dffull |> dplyr::select(idno, ipcrtiv:impfun, cntry) |> #rowwise() |> 
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

# Old version: here, when two max values are equally large, one is chosen randomly.
#df_four <- df_ten[sample(nrow(df_ten)),] |> 
#  select(idno, Openness:SelfTranscendence) |> 
#  pivot_longer(Openness:SelfTranscendence) |> 
#  group_by(idno) |> 
#  mutate(rank = rank(value)) |> 
#  group_by(idno) |> 
#  summarize(Value1 = name[value == max(value)][1], 
#            Value2 = name[value == min(value)][1],
#            Consistent =
#              str_starts(Value1,"Self") & str_starts(Value2,"Self") |
#              Value1 == "Openness" & Value2 == "Conservation" |
#              Value2 == "Openness" & Value1 == "Conservation") |> 
#  mutate(ValueType = if_else(Consistent, Value1, "Erratic"))

# New version: here, when two max values are equally large, the observation is discarded
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

###
table(df_four$howmanymaxequal)
table(df_four$ValueType)


mds <- df_ten |> select(Conformity:Security) |> t() |> dist() |> 
  cmdscale(eig = TRUE, k =2)
plot(mds$points[,1],mds$points[,2])
text(mds$points[,1],mds$points[,2],labels = row.names(mds$points))
mds <- df_ten |> select(Openness:SelfTranscendence) |> t() |> dist() |> 
  cmdscale(eig = TRUE, k =2)
plot(mds$points[,1],mds$points[,2])
text(mds$points[,1],mds$points[,2],labels = row.names(mds$points))


# Correlations on Subgroups

DF <- dfsel |> left_join(df_four)
DF |> select(attitudenames) |>  cor() |> corrplot(method='number')
matrixS<- DF |> filter(ValueType == "SelfEnhancement") |> 
  select(attitudenames) |>  cor() |> corrplot(method='number', insig='p-value')
matrixO <- DF |> filter(ValueType == "Openness") |> 
  select(attitudenames) |>  cor() |> corrplot(method='number')
matrixC <- DF |> filter(ValueType == "Conservation") |> 
  select(attitudenames) |>  cor() |> corrplot(method='number')
matrixE <- DF |> filter(ValueType == "Erratic") |> 
  select(attitudenames) |>  cor() |> corrplot(method='number')


table(DF$ValueType)


#### Clustering by political party

table(dfsel$prtclede)

matrixALL <- dfsel_gp |> 
  select(attitudenames) |>  cor() |> corrplot(method='number', insig='p-value', title="all parties", mar=c(0,0,1,0))
matrixCDU <- dfsel_gp |> filter(prtclede == 1) |> 
  select(attitudenames) |>  cor() |> corrplot(method='number', insig='p-value', title="CDU/CSU", mar=c(0,0,1,0))
matrixSPD <- dfsel_gp |> filter(prtclede == 2) |> 
  select(attitudenames) |>  cor() |> corrplot(method='number', insig='p-value', title="SPD", mar=c(0,0,1,0))
matrixLEFT <- dfsel_gp |> filter(prtclede == 3) |> 
  select(attitudenames) |>  cor() |> corrplot(method='number', insig='p-value', title="Left", mar=c(0,0,1,0))
matrixGREEN <- dfsel_gp |> filter(prtclede == 4) |> 
  select(attitudenames) |>  cor() |> corrplot(method='number', insig='p-value', title="Greens", mar=c(0,0,1,0))
matrixFDP <- dfsel_gp |> filter(prtclede == 5) |> 
  select(attitudenames) |>  cor() |> corrplot(method='number', insig='p-value', title="Liberals FDP", mar=c(0,0,1,0))
matrixAFD <- dfsel_gp |> filter(prtclede == 6) |> 
  select(attitudenames) |>  cor() |> corrplot(method='number', insig='p-value', title="AfD", mar=c(0,0,1,0))



# Evaluate goodness of clustering for values!
table(DF$ValueType)
for (j in 1:3) {
  groupname = list("SelfEnhancement", "Openness", "Conservation")[[j]]
  group = DF |> filter(ValueType==groupname)
  print(paste(groupname, nrow(group), sep=": "))
  nr_good = matrix(nrow=length(attitudenames),ncol=length(attitudenames))
  for (a in 1:(length(attitudenames))){
    name = attitudenames[a]
    for (b in 1:a){
      name2=attitudenames[b]
      print(paste(a,b, name, name2))
      
      group_corr = cor(group[name], group[name2])[1] #GroupCorrmatrix$corr[name, name2]
      
      random_corrs = c()
      for (i in 1: 1000){
          random_group <- DF[sample(nrow(DF), nrow(group)),]
          random_corrs[i] = cor(random_group[name], random_group[name2])[1]
        }
        mean_rand_corr = mean(random_corrs)
        std_rand_corr = sd(random_corrs)
        if (abs(group_corr-mean_rand_corr) > 2 * std_rand_corr){
          col="green"
          nr_good[a,b]=1
        }else{
            col="red"
            nr_good[a,b]=0
          }
        if (name==name2){xlimval=1.05}else{xlimval=0.4}
        p1 <- qplot(random_corrs, geom="histogram", binwidth=0.01)+ 
                xlim(-xlimval, xlimval) + 
                geom_vline(aes(xintercept=group_corr), col=col) 
        print(p1)
        ggsave(
          paste(paste("figs/", groupname, name, name2, sep="_"),".png", sep=""),
          plot = last_plot(),
        )
    }
  }
}

# EXAMPLE
# name="euftf"
# name2 ="freehms"
# random_corrs = c()
# for (i in 1: 10000){
#   random_group <- df_cor[sample(nrow(df_cor), n_group),]
#   random_corrs[i] = cor(random_group[name], random_group[name2])[1]
# }

parties = c("CDUCSU", "SPD", "Left", "Green", "FDP", "AfD")
for (j in 1:length(parties)) {
  groupname = parties[[j]]
  group = dfsel_gp |>  filter(prtclede==j)
  print(paste(groupname, nrow(group), sep=": "))
  nr_good = matrix(nrow=length(attitudenames),ncol=length(attitudenames))
  for (a in 1:(length(attitudenames))){
    name = attitudenames[a]
    for (b in 1:a){
      name2=attitudenames[b]
      print(paste(a,b, name, name2))
      
      group_corr = cor(group[name], group[name2])[1] #GroupCorrmatrix$corr[name, name2]
      
      random_corrs = c()
      for (i in 1: 1000){
        random_group <- dfsel_gp[sample(nrow(dfsel_gp), nrow(group)),]
        random_corrs[i] = cor(random_group[name], random_group[name2])[1]
      }
      mean_rand_corr = mean(random_corrs)
      std_rand_corr = sd(random_corrs)
      if (abs(group_corr-mean_rand_corr) > 2 * std_rand_corr){
        col="green"
        nr_good[a,b]=1
      }else{
        col="red"
        nr_good[a,b]=0
      }
      if (name==name2){xlimval=1.05}else{xlimval=0.8}
      p1 <- qplot(random_corrs, geom="histogram", binwidth=0.01)+ 
        xlim(-xlimval, xlimval) + 
        geom_vline(aes(xintercept=group_corr), col=col) 
      print(p1)
      ggsave(
        paste(paste("figs/", groupname, name, name2, sep="_"),".png", sep=""),
        plot = last_plot(),
      )
    }
  }
}


DF |> left_join(raw) |> filter(atchctr < 8, atchctr <= 10) |> 
  select(attitudenames) |>  cor() |> corrplot(method='number')
DF |> left_join(raw) |> filter(pray < 6, atchctr <= 7) |> 
  select(attitudenames) |>  cor() |> corrplot(method='number')

# Principal Component Analysis
DF |> select(attitudenames) |>  prcomp()






# Jan

filterbasics <- raw |> select(idno, cntry, gndr)
DF |> left_join(filterbasics) |> filter(cntry == "AT") |> pull(ValueType) |> table() |> plot()
DF |> left_join(filterbasics) |> filter(cntry == "CH") |> pull(ValueType) |> table() |> plot()
DF |> left_join(filterbasics) |> filter(cntry == "DE") |> pull(ValueType) |> table() |> plot()
DF |> left_join(filterbasics) |> filter(cntry == "NL") |> pull(ValueType) |> table() |> plot()
DF |> left_join(filterbasics) |> filter(cntry == "GB") |> pull(ValueType) |> table() |> plot()
DF |> left_join(filterbasics) |> filter(cntry == "FR") |> pull(ValueType) |> table() |> plot()
DF |> left_join(filterbasics) |> filter(cntry == "SE") |> pull(ValueType) |> table() |> plot()
DF |> left_join(filterbasics) |> filter(cntry == "PL") |> pull(ValueType) |> table() |> plot()
DF |> left_join(filterbasics) |> filter(cntry == "CZ") |> pull(ValueType) |> table() |> plot()
DF |> left_join(filterbasics) |> filter(cntry == "EE") |> pull(ValueType) |> table() |> plot()






### RCA:

# NOTE: use df_s_g for Germany. or dffull for whole 

df_bel <- dfsel_g[columns]

#x <- RCA(df_bel, alpha = 0.01)
#print(x)
x_five <- RCA(df_bel[attitudenames])
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


### merging dataframes

# create group varible accoring to RCA
df_bel$group <- x_five$membership
df_group <- df_bel[c("idno","group")]
# merging 
dfgRCA <- merge(dffull_g, df_group, by = 'idno')
dfgRCA$group <- as.factor(dfgRCA$group)


## find out how groups differ

# take group 7 out, because just 2 people
dfgRCA <- dfgRCA |>
  filter(group!='7')

#age
dfgRCA <- dfgRCA |>
  filter(agea<=110)
ggplot(dfgRCA, aes(x=group, y=agea)) + geom_boxplot()

#gender # 1=male, 2=female
table(dfgRCA$gndr, dfgRCA$group)

#beliefs
ggplot(dfgRCA, aes(x=group, y=freehms)) + geom_boxplot()
ggplot(dfgRCA, aes(x=group, y=gincdif)) + geom_boxplot()
ggplot(dfgRCA, aes(x=group, y=impcntr)) + geom_boxplot()
ggplot(dfgRCA, aes(x=group, y=lrscale)) + geom_boxplot()
ggplot(dfgRCA, aes(x=group, y=euftf)) + geom_boxplot()


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








df_bel |> mutate(group = x_five$membership) |> 
  pivot_longer(attitudenames) |>
  ggplot(aes(value)) + geom_histogram() + facet_wrap(name~group, ncol=9)


#     ASSESS



matrix1 <- df_bel |> filter(group == "1") |> 
  select(attitudenames) |>  cor() |> corrplot(method='number', insig='p-value', title="RCAgroup1", mar=c(0,0,1,0))
matrix2 <-df_bel |> filter(group == "2") |> 
  select(attitudenames) |>  cor() |> corrplot(method='number', insig='p-value', title="RCAgroup2", mar=c(0,0,1,0))
matrix3 <- df_bel |> filter(group == "3") |> 
  select(attitudenames) |>  cor() |> corrplot(method='number', insig='p-value', title="RCAgroup3", mar=c(0,0,1,0))
matrix4 <-df_bel |> filter(group == "4")|> 
  select(attitudenames) |>  cor() |> corrplot(method='number', insig='p-value', title="RCAgroup4", mar=c(0,0,1,0))
matrix5 <- df_bel |> filter(group == "5") |> 
  select(attitudenames) |>  cor() |> corrplot(method='number', insig='p-value', title="RCAgroup5", mar=c(0,0,1,0))
matrix6 <- df_bel |> filter(group == "6") |> 
  select(attitudenames) |>  cor() |> corrplot(method='number', insig='p-value', title="RCAgroup6", mar=c(0,0,1,0))

table(dfgRCA$group)

groups = c("RCAgroup1","RCAgroup2","RCAgroup3","RCAgroup4","RCAgroup5","RCAgroup6")
for (j in 1:length(groups)) {
  groupname = groups[[j]]
  group = dfgRCA |>  filter(group==j)
  print(paste(groupname, nrow(group), sep=": "))
  nr_good = matrix(nrow=length(attitudenames),ncol=length(attitudenames))
  for (a in 2:(length(attitudenames))){
    name = attitudenames[a]
    for (b in 1:(a-1)){
      name2=attitudenames[b]
      print(paste(a,b, name, name2))
      
      group_corr = cor(group[name], group[name2])[1] #GroupCorrmatrix$corr[name, name2]
      
      random_corrs = c()
      for (i in 1: 1000){
        random_group <- dfgRCA[sample(nrow(dfgRCA), nrow(group)),]
        random_corrs[i] = cor(random_group[name], random_group[name2])[1]
      }
      mean_rand_corr = mean(random_corrs)
      std_rand_corr = sd(random_corrs)
      if (abs(group_corr-mean_rand_corr) > 2 * std_rand_corr){
        col="green"
        nr_good[a,b]=1
      }else{
        col="red"
        nr_good[a,b]=0
      }
      if (name==name2){xlimval=1.05}else{xlimval=1}
      p1 <- qplot(random_corrs, geom="histogram", binwidth=0.01)+ 
        xlim(-xlimval, xlimval) + 
        geom_vline(aes(xintercept=group_corr), col=col) 
      print(p1)
      ggsave(
        paste(paste("figs/", groupname, name, name2, sep="_"),".png", sep=""),
        plot = last_plot(),
      )
    }
  }
}
