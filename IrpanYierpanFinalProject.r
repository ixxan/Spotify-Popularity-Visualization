#Clear Workspace & Set Up R
dev.off()         # remove any previous devices used to produce graphics or pdfs
cat("\014")       # clear all text in the console
rm(list=ls())     # clear out anything in memory
set.seed(18552)   # set a consistent seed for generating future variables

setwd("~/Desktop/Rice/Classes/2021 Fall/DSCI 304/Projects/Spotify-Popularity-Visualization")

library(reshape2)
library(ggplot2)
library(plotly)
library(caret)
library(fmsb)
library(ggdag)
 
# Popularity index DAG
dag<-dagify(z~a,
            z~b,
            labels=c("z"="Popularity", "a"="# of Plays", "b"="Recency of the Play"))
ggdag(dag, text=FALSE, use_labels="label")+
  theme_dag_blank()+
  ggtitle("The Main Factors that Influence Spotify Popularity Index Calculation")

dag<-dagify(z~a,
            z~b,
            z~c,
            z~d,
            z~e,
            z~f,
            z~g,
            z~h,
            labels=c("z"="Popularity", "a"="Danceability", "b"="Energy", "c"="Loudness", "d"="Speechiness", "e"="Acousticness", "f"="Liveness", "g"="Tempo", "h"="Valence"))
ggdag(dag, text=FALSE, use_labels="label")+
  theme_dag_blank()+
  ggtitle("The Audio Features that may Influence the Popularity of a Song")

# Data set all the songs on the Spotify weekly top 200 chart between Jan. 2020 to Jul. 2021
spotify<-read.csv("spotify_clean.csv")

# Remove NA rows
spotify<-na.omit(spotify) 

# Remove popularity outliers
popularity_outliers<-spotify$Popularity[spotify$Popularity %in% boxplot.stats(spotify$Popularity)$out]
spotify<-subset(spotify, !spotify$Popularity %in%popularity_outliers)
str(spotify)

# Min-max scale numeric audio features since they all have a range
spotify_num_audio <- subset(spotify, select=c("Danceability", "Energy", "Loudness", "Speechiness", "Acousticness", "Liveness", "Tempo", "Valence"))
pp = preProcess(spotify_num_audio, method = "range")
spotify_num_audio_norm<-predict(pp, spotify_num_audio)
spotify[, c("Danceability", "Energy", "Loudness", "Speechiness", "Acousticness", "Liveness", "Tempo", "Valence")]<-spotify_num_audio_norm

# Distribution of popularity of the top songs
p1<-ggplot(spotify, aes(x=Popularity))+
  geom_histogram(fill=rgb(0.2,0.4,0.6), binwidth=1)+
  labs(x="Popularity Index", y="Count", title="The Distributions of the Popularity Index of the Songs on \nthe Spotify Weekly Top 200 Chart (Jan. 2020 to Jul. 2021)")+
  theme(legend.position = "none")
p1


#Features correlations to popularity 
spotify_num <- subset(spotify, select=c("Danceability", "Energy", "Loudness", "Speechiness", "Acousticness", "Liveness", "Tempo", "Valence", "Popularity"))

# Correlation matrix
cormat <- round(cor(spotify_num),2)

# Get upper triangle of the correlation matrix
get_upper_tri <- function(cormat){
  cormat[lower.tri(cormat)]<- NA
  return(cormat)
}
upper_tri <- get_upper_tri(cormat)
melted_cormat <- melt(upper_tri, na.rm = TRUE)

# Create a heatmap
ggheatmap <- ggplot(melted_cormat, aes(Var2, Var1, fill = value))+
  geom_tile(color = "white")+
  ggtitle("Correlations Between the Numeric Audio Features and the Popularity of \nthe Songs on the Spotify Weekly Top 200 Chart (Jan. 2020 to Jul. 2021)")+
  scale_fill_gradient2(low = "blue", high = "red", mid = "white", 
                       midpoint = 0, limit = c(-1,1), space = "Lab", 
                       name="Pearson\nCorrelation") +
  theme_minimal()+ # minimal theme
  theme(axis.text.x = element_text(angle = 45, vjust = 1, 
                                   size = 12, hjust = 1))+
  coord_fixed()

ggheatmap + 
  geom_text(aes(Var2, Var1, label = value), color = "black", size = 4) +
  theme(
    axis.title.x = element_blank(),
    axis.title.y = element_blank(),
    panel.grid.major = element_blank(),
    panel.border = element_blank(),
    panel.background = element_blank(),
    axis.ticks = element_blank(),
    legend.justification = c(1, 0),
    legend.position = c(0.6, 0.7),
    legend.direction = "horizontal")+
  guides(fill = guide_colorbar(barwidth = 7, barheight = 1,
                               title.position = "top", title.hjust = 0.5))


# Interactive Linear models feature vs popularity 
spotify_num<-subset(spotify, select=c("Danceability", "Energy", "Loudness", "Speechiness", "Acousticness", "Liveness", "Tempo", "Valence", "Popularity", "Song.Name", "Artist"))
spotify_num_melt<-melt(spotify_num, id=c("Popularity", "Song.Name", "Artist"))
colnames(spotify_num_melt)<-c("Popularity", "Song", "Artist", "Feature", "x")
p2<-ggplot(spotify_num_melt, aes(x=x, y=Popularity, color=Feature, frame=Feature))+
  geom_point(aes(text=Song, text2=Artist, text3=Popularity))+
  geom_smooth(method=lm)+
  labs(x="Audio Feature Value", y="Popularity Index", title="The Numeric Audio Features vs. the Popularity of the Songs on the Spotify Weekly Top 200 Chart (Jan. 2020 to Jul. 2021)")+
  theme(legend.position = "none")

ggplotly(p2, tooltip = c("text", "text2", "text3"))


# Radar plot of mean features of all songs
mean_audio<-as.data.frame(t(colMeans(spotify_num_audio_norm)))
mean_audio<-rbind(rep(1,8) , rep(0,8) , mean_audio)
# Custom the radarChart !
p3<-ggplot(mean_audio)+
radarchart(mean_audio , axistype=1 , 
            #custom polygon
            pcol=rgb(0.2,0.4,0.6,1) , pfcol=rgb(0.2,0.4,0.6,0.6) , plwd=4 , 
            #custom the grid
            cglcol="grey", cglty=1, axislabcol="grey", caxislabels=seq(0,1,0.2),
           title=paste("Average Numeric Audio Features of \nthe Songs on the Spotify Weekly Top 200 Chart \n(Jan. 2020 to Jul. 2021)")
)

