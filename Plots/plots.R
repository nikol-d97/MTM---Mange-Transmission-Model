library(tidyverse)
library(ggplot2)
library(Ipaper) #package that allows for exclusion of outliers from boxplots 
theme_set(theme_classic())


al_merged_data <- read.csv("al_merged_data.csv")

# al - Mean Re
al_merged_data %>% 
  filter(value == "R0-SEI") %>%
  ggplot(aes(x= factor(scenario, levels = c("equal - low", "equal - medium", "equal - high", "infected biased - low", "infected biased - medium",  "susceptible biased - low", "susceptible biased - medium")), y= mean_val, fill= factor(movement.behaviour, levels= c("Random","Landcover-based")))) + 
  geom_boxplot2(width = 1, width.errorbar = 0.5) + 
  scale_fill_manual( values=c("grey33", "grey75")) +
  theme(axis.text.x = element_text( color="black",  size=9)) + 
  scale_x_discrete(labels = abbreviate) + 
  theme(legend.title = element_text(size = 10), 
        legend.text = element_text(size = 10)) + guides(fill=guide_legend(title="Movement Behaviour")) + 
  labs(x= "Scenario", y= expression('Mean R'['e']))

# al - # of effective contact events 
al_merged_data %>% 
  filter(value == "sum [overall-infection] of turtles") %>%
  ggplot(aes(x= factor(scenario, levels = c("equal - low", "equal - medium", "equal - high", "infected biased - low", "infected biased - medium",  "susceptible biased - low", "susceptible biased - medium")), y= final, fill= factor(movement.behaviour, levels= c("Random","Landcover-based")))) + 
  geom_boxplot2(width = 1, width.errorbar = 0.5) + 
  scale_fill_manual( values=c("grey33", "grey75")) + 
  theme(axis.text.x = element_text( color="black",  size=9)) + 
  scale_x_discrete(labels = abbreviate) + 
  theme(legend.title = element_text(size = 10), 
        legend.text = element_text(size = 10)) + guides(fill=guide_legend(title="Movement Behaviour")) + 
  labs(x= "Scenario", y= "# of effective contact events")


GIS_merged_data <- read.csv("GIS_merged_data.csv")



# GIS - Mean Re
GIS_merged_data %>%
  filter(value == "R0-SEI") %>%
  ggplot(aes(x= factor(scenario, levels = c("equal - low", "equal - medium", "equal - high", "infected biased - low", "infected biased - medium",  "susceptible biased - low", "susceptible biased - medium")), y= mean_val, fill= factor(movement.behaviour, levels= c("Random","Landcover-based")))) + 
  geom_boxplot2(width = 1, width.errorbar = 0.5) + 
  scale_fill_manual( values=c("grey33", "grey75")) +
  theme(axis.text.x = element_text( color="black",    size=9)) + 
  scale_x_discrete(labels = abbreviate) + 
  theme(legend.title = element_text(size = 10), 
        legend.text = element_text(size = 10)) + guides(fill=guide_legend(title="Movement Behaviour")) + 
  labs(x= "Scenario", y= expression('Mean R'['e'])) 

# GIS - # of effective contact events 
GIS_merged_data %>% 
  filter(value == 'sum [overall-infection] of turtles') %>%
  ggplot(aes(x= factor(scenario, levels = c("equal - low", "equal - medium", "equal - high", "infected biased - low", "infected biased - medium",  "susceptible biased - low", "susceptible biased - medium")), y= final, fill= factor(movement.behaviour, levels= c("Random","Landcover-based")))) + 
  geom_boxplot2(width = 1, width.errorbar = 0.5) + 
  scale_fill_manual( values=c("grey33", "grey75")) +
  theme(axis.text.x = element_text( color="black",  size=9)) + 
  scale_x_discrete(labels = abbreviate) + 
  theme(legend.title = element_text(size = 10), 
        legend.text = element_text(size = 10)) + guides(fill=guide_legend(title="Movement Behaviour")) + 
  labs(x= "Scenario", y= "# of effective contact events")