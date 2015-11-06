knitr::opts_chunk$set(echo = TRUE, message = FALSE, warning=FALSE, R.options=list(width=120))
library(dplyr); library(magrittr)
## # numeric indexes; not conducive to readibility or reproducibility
## newData = oldData[,c(1,2,3,4, etc.)]
## 
## # explicitly by name; fine if only a handful; not pretty
## newData = oldData[,c('ID','X1', 'X2', etc.)]
## 
## # two step with grep; regex difficult to read/understand
## cols = c('ID', paste0('X', 1:10), 'var1', 'var2', grep(colnames(oldData), '^XYZ', value=T))
## newData = oldData[,cols]
## 
## # or via subset
## newData = subset(oldData, select = cols)
## # three operations and overwriting or creating new objects if we want clarity
## newData = newData[oldData$Z == 'Yes' & oldData$Q == 'No',]
## newData = tail(newData, 50)
## newData = newdata[order(newdata$var1, decreasing=T),]
## newData = oldData %>%
##   filter(Z == 'Yes', Q == 'No') %>%
##   select(num_range('X', 1:10), contains('var'), starts_with('XYZ')) %>%
##   tail(50) %>%
##   arrange(desc(var1))
## wikiURL = 'https://en.wikipedia.org/wiki/List_of_United_States_cities_by_population'
## 
## # Let's go!
## wikiURL %>%
##   read_html %>%                                                                     # parse the html
##   html_node(css='.wikitable.sortable') %>%                                          # grab a class of object
##   html_table %>%                                                                    # convert table to data.frame
##   sapply(function(x) repair_encoding(as.character(x), 'UTF-8')) %>%                 # repair encoding; makes a matrix
##   data.frame %>%                                                                    # back to df
##   mutate(City = str_replace(City, '\\[(.*?)\\]', ''),                               # remove footnotes
##          latlon = sapply(str_split(Location, '/'), last),                           # split up location (3 parts)
##          latlon = str_extract_all(latlon, '[-|[0-9]]+\\.[0-9]+'),                   # grab any that start with - or number
##          lat = sapply(latlon, first),                                               # grab latitudes
##          lon = sapply(latlon, nth, 2),                                              # grab longitude
##          population2014 = as.numeric(str_replace_all(X2014.estimate, ',', '')),     # remove commas from numbers (why do people do this?)
##          population2010 = as.numeric(str_replace_all(X2010.Census, ',', '')),       # same for 2010
##          popDiff  = round(population2014/population2010 - 1, 2)*100) %>%            # create percentage difference
##   select(-latlon, -Location) %>%                                                    # remove stuff we wouldn't ever use
##   filter(as.numeric(as.character(X2014.rank)) <= 50)  %>%                           # top 50
##   leaflet %>%                                                                       # map out
##   addProviderTiles("CartoDB.DarkMatterNoLabels") %>%
##   setView(-94, 35, zoom = 4) %>%
##   addCircleMarkers(~lon, ~lat,
##                    radius=  ~scales::rescale(popDiff, c(1, 10)),
##                    fillColor=  ~pal(popDiff), stroke = FALSE, fillOpacity = .85,
##                    popup=  ~paste(City, paste0(popDiff, '%')))
# packs = c('magrittr', 'rvest', 'dplyr', 'stringr' ,'leaflet', 'ggvis')
# sapply(packs, library, character.only=T); DONT USE
library(magrittr); library(rvest); library(dplyr); library(stringr);
library(leaflet)

'https://en.wikipedia.org/wiki/List_of_United_States_cities_by_population' %>% 
  read_html %>% 
  html_node(css='.wikitable.sortable') %>% 
  html_table %>% 
  sapply(function(x) repair_encoding(as.character(x), 'UTF-8'), simplify=F) %>%
  data.frame %>%  
  mutate(City = str_replace(City, '\\[(.*?)\\]', ''),
         latlon = sapply(str_split(Location, '/'), last), 
         latlon = str_extract_all(latlon, '[-|[0-9]]+\\.[0-9]+'), 
         lat = sapply(latlon, first),
         lon = sapply(latlon, nth, 2), 
         population2014 = as.numeric(str_replace_all(X2014.estimate, ',', '')),
         population2010 = as.numeric(str_replace_all(X2010.Census, ',', '')),
         popDiff  = round(population2014/population2010 - 1, 2)*100) %T>% 
  select(-latlon, -Location) %>% 
  filter(as.numeric(as.character(X2014.rank)) <= 50)  %>% 
  leaflet %>% 
  addProviderTiles("CartoDB.DarkMatterNoLabels") %>% 
  setView(-94, 35, zoom = 4) %>% 
  addCircleMarkers(~lon, ~lat,
                   radius=  ~scales::rescale(popDiff, c(2, 11)),
                   fillColor=  ~colorNumeric(palette = c('Red', 'White', 'Navy'), popDiff)(popDiff), 
                   stroke = FALSE, fillOpacity = .85,
                   popup=  ~paste(City, paste0(popDiff, '%')))
## c('Ceci', "n'est", 'pas', 'une', 'pipe!') %>%
## {
##   .. <-  . %>%
##     if (length(.) == 1)  .
##     else paste(.[1], '%>%', ..(.[-1]))
##   ..(.)
## }
c('Ceci', "n'est", 'pas', 'une', 'pipe!') %>%
{
  .. <-  . %>%
    if (length(.) == 1)  .
    else paste(.[1], '%>%', ..(.[-1]))
  ..(.)
} 
## data %>%
##   function
## data %>%
##   function(arg='blah')
iris %>% summary
library(rvest); library(dplyr); library(magrittr); library(tidyr)
url = "http://www.basketball-reference.com/leagues/NBA_2015_totals.html?lid=header_seasons"
bball = read_html(url) %>% 
  html_nodes("table#totals") %>% 
  html_table %>% 
  data.frame %>%
  filter(Rk != "Rk")
bball %<>% 
  mutate_each(funs(as.numeric), -Player, -Pos, -Tm)   

glimpse(bball)
bball = bball %>% 
  mutate(trueShooting = PTS / (2 * (FGA + (.44 * FTA))),
         effectiveFG = (FG + (.5 * X3P)) / FGA, 
         shootingDif = trueShooting - FG.)

summary(select(bball, shootingDif))  # select and others don't have to be piped to use
library(tidyr)
bball %>% 
  unite("posTeam", Pos, Tm) %>% 
  select(1:5) %>% 
  head
bball %>% 
  separate(Player, into=c('firstName', 'lastName'), sep=' ') %>% 
  select(1:5) %>% 
  head
state.x77 %>% 
  data.frame %>% 
  mutate(popLog = log(Population),
         curLifeExp = Life.Exp+5) %>% 
  summary
bball %>% 
  select(Player, Tm, Pos, MP, trueShooting, effectiveFG, PTS) %>% 
  summary
scoringDat = bball %>% 
  select(Player, Tm, Pos, MP, trueShooting, effectiveFG, PTS)

scoringDat %>% 
  select(-Player, -Tm, -Pos) %>% 
  cor(use='complete') %>% 
  round(2)
bball %>% 
  select(Player, contains("3P"), ends_with("RB")) %>% 
  arrange(desc(TRB)) %>% 
  head
## bball = html(url) %>%
##   html_nodes("table#totals") %>%
##   html_table %>%
##   data.frame %>%
##   filter(Rk != "Rk")
## bball %>%
##   filter(Age > 35, Pos == "SF" | Pos == "PF")
## bball %>%
##   slice(1:10)
bball %>% 
  unite("posTeam", Pos, Tm) %>% 
  filter(posTeam == "PF_SAS") %>% 
  arrange(desc(PTS/PF)) %>% 
  select(1:10)
iris %>% 
  filter(Petal.Length/Petal.Width > 5) %>% 
  summary
library(tidyr)
bballLong = bball %>% 
  select(Player, Tm, FG., X3P, X2P.1, trueShooting, effectiveFG) %>%
  rename(fieldGoalPerc = FG., threePointPerc = X3P, twoPointPerc = X2P.1) %>% 
  mutate(threePointPerc = threePointPerc/100) %>% 
  gather(key = 'vitalInfo', value = 'value', -Tm, -Player) 

bballLong %>% head
bballLong %>%
  spread(vitalInfo, value) %>% 
  head
scoringDat %>% 
  group_by(Pos) %>% 
  summarize(meanTrueShooting = mean(trueShooting, na.rm = TRUE))
state.x77 %>% 
  data.frame %>% 
  mutate(Region = state.region,
         State = state.name) %>% 
  filter(Population > 1000) %>% 
  select(Region, starts_with('I')) %>% 
  group_by(Region) %>% 
  summarize(meanInc=mean(Income),
            meanIll=mean(Illiteracy))
iris %>% head
head(iris)
iris %$% lm(Sepal.Length ~ Sepal.Width)
# par(mai=c(.1,.1,.1,.1), pch=19, byt='n')
iris %>% select(Sepal.Length, Sepal.Width) %T>% plot %>%summary
## iris %>% select(Sepal.Length, Sepal.Width) %T>% plot %>% summary
## iris %>% select(Sepal.Length, Sepal.Width) %T>% summary %>% plot
iris2 = iris
iris2 %<>% rnorm(10)
iris2
data.frame(y=rnorm(100), x=rnorm(100)) %$%
  lm(y ~ x)
library(leaflet)
leaflet() %>% 
  setView(lat=42.2655, lng=-83.7485, zoom=15) %>% 
  addTiles() %>% 
  addPopups(lat=42.2655, lng=-83.7485, 'Hi!')
#use current poll data code from home
library(dygraphs)
data(UKLungDeaths)
cbind(ldeaths, mdeaths, fdeaths) %>% 
  dygraph()
set.seed(1352)
netlinks = data.frame(source = c(0,0,0,1,1,2,2,3,3,3,4,5,5),
                   target = sample(0:5, 13, replace = T),
                   value = sample(1:10, 13, replace = T))


netnodes = data.frame(name = c('Bobby', 'Janie','Timmie', 'Mary', 'Johnny', 'Billy'),
                      group = c('friend', 'frenemy','frenemy', rep('friend', 3)),
                      size = sample(1:20, 6))
library(networkD3)
forceNetwork(Links = netlinks, Nodes = netnodes, Source = "source",
             Target = "target", Value = "value", NodeID = "name",
             Nodesize = "size", Group = "group", opacity = 0.4, legend = T,
             colourScale = JS("d3.scale.category10()"))
library(DT)
datatable(select(bball, 1:5), rownames=F)
bballLong %>% head
## bballLong %>%
##   group_by(Tm, vitalInfo) %>%
##   summarize(avg = mean(value)) %>%
##   ggvis(x=~Tm, y=~avg) %>%
##   layer_points(fill = ~vitalInfo) %>%
##   add_axis("x", grid=F, properties = axis_props(labels=list(angle=90, fill='gray'),
##                                                 axis=list(stroke=NA),
##                                                 ticks=list(stroke=NA))
##            ) %>%
##   add_axis('y', grid=F)
library(ggvis)
bballLong %>% 
  group_by(Tm, vitalInfo) %>%
  summarize(avg = mean(value)) %>% 
  ggvis(x=~Tm, y=~avg) %>% 
  layer_points(fill = ~vitalInfo) %>% 
  add_axis("x", grid=F, properties = axis_props(labels=list(angle=90, fill='gray'),
                                                axis=list(stroke=NA),
                                                ticks=list(stroke=NA))
           ) %>% 
  add_axis('y', grid=F)
mtcars %>% 
  mutate(amFactor = factor(am, labels=c('auto', 'manual'))) %>% 
  group_by(amFactor) %>%
  ggvis(x=~wt, y=~mpg) %>%
  layer_points(fill=~amFactor) %>%
  layer_smooths(stroke=~amFactor)
## span = waggle(0.5, 2)
## mtcars %>%
##   mutate(amFactor = factor(am, labels=c('auto', 'manual'))) %>%
##   group_by(amFactor) %>%
##   ggvis(x=~wt, y=~mpg) %>%
##   layer_points(fill=~amFactor) %>%
##   layer_smooths(stroke=~amFactor, span=span)
