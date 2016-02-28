


Ceci n'est pas une %>%: Exploring Your Data with R
========================================================
autosize: true
transition: concave
css: csstestCSStherealCSSSERIOUSLY.css
date: 2016-02-21
font-family: 'Helvetica'
author: Michael Clark 

Consulting for Statistics, Computing & Analytics Research

 Advanced Research Computing





Preliminaries
========================================================
[Link to slides ](www-personal.umich.edu/~micl/mainSlides.html): <br> www-personal.umich.edu/~micl/mainSlides.html

[Link to R package install/load script](www-personal.umich.edu/~micl/installLoadPackages.R):<br> www-personal.umich.edu/~micl/installLoadPackages.R

- Start Rstudio
- Run script (make take a couple minutes)
- Copy, paste, and run or run the following:
- <span style="font-family:monospace; font-size:18pt">source("http://www-personal.umich.edu/~micl/installLoadPackages.R")</span>

YOU WILL GET A POP-UNDER WINDOW (on the Windows lab machines).  Affirm that you want to use a personal library.



The Reference
========================================================
**The Treachery of Images** by <span class='emph'>Rene Magritte</span>

<div style='text-align:center'>
<img src='MagrittePipe.jpg'></img>
</div>



Goals
========================================================
incremental: true

- Introduce newer approaches to data wranging, scrubbing, manipulation etc.

- Show the benefits of <span class='emph'>*piping*</span> code

- Put it all together with some newer visualization packages 



Outline 
========================================================
Newer approaches to data wrangling

- Introduction to <span class='pack'>plyr</span> <span class='pack'>dplyr</span> and <span class='pack'>tidyr</span>
- Subsetting rows
- Subsetting columns
- Reshaping data
- Generating new data
- Grouping and summarizing

Nothin's gonna stop the flow

- More piping with the <span class='pack'>magrittr</span> package

Quick interactive visualizations

- <span class='pack'>ggvis</span>, <span class='pack'>htmlwidgets</span>


Newer approaches to data wrangling
========================================================
type: prompt
transition: fade

Newer approaches to data wrangling
========================================================
A starting example

Let's say we want to select from our data the following variables

- Start with the **ID** variable
- The variables **X1:X10**, which are not all together, and there are many more *X* columns
- The variables **var1** and **var2**, which are the only *var* variables in the data
- Any variable that starts with **XYZ**
    
How might we go about this?


Some base R approaches
========================================================

Tedious, or typically two steps just to get the columns you want.


```r
# numeric indexes; not conducive to readibility or reproducibility
newData = oldData[,c(1,2,3,4, etc.)]

# explicitly by name; fine if only a handful; not pretty
newData = oldData[,c('ID','X1', 'X2', etc.)]

# two step with grep; regex difficult to read/understand
cols = c('ID', paste0('X', 1:10), 'var1', 'var2', grep(colnames(oldData), '^XYZ', value=T))
newData = oldData[,cols]

# or via subset
newData = subset(oldData, select = cols)
```


More
========================================================
What if you also want observations where **Z** is **Yes**, Q is **No**, and only the last 50 of those results, ordered by **var1** (descending)?


```r
# three operations and overwriting or creating new objects if we want clarity
newData = newData[oldData$Z == 'Yes' & oldData$Q == 'No',]
newData = tail(newData, 50)
newData = newdata[order(newdata$var1, decreasing=T),]
```

And this is for fairly straightforward operations.



An alternative
========================================================


```r
newData = oldData %>% 
  filter(Z == 'Yes', Q == 'No') %>% 
  select(num_range('X', 1:10), contains('var'), starts_with('XYZ')) %>% 
  tail(50) %>% 
  arrange(desc(var1))
```



An alternative
========================================================
incremental: true
Even though the initial base R approach depicted is probably more concise than many would do on their own, it still is: 

- noisier
- less legible
- less amenable to additional data changes
- requires esoteric knowledge (e.g. regular expressions)
- often requires new objects (even if we just want to explore**)



Another example...
========================================================
type: prompt

Start with a string, end with a map
========================================================


```r
wikiURL = 'https://en.wikipedia.org/wiki/List_of_United_States_cities_by_population'

# Let's go!
wikiURL %>% 
  read_html %>%                                                                     # parse the html
  html_node(css='.wikitable.sortable') %>%                                          # grab a class of object
  html_table %>%                                                                    # convert table to data.frame
  sapply(function(x) repair_encoding(as.character(x), 'UTF-8')) %>%                 # repair encoding; makes a matrix
  data.frame %>%                                                                    # back to df
  mutate(City = str_replace(City, '\\[(.*?)\\]', ''),                               # remove footnotes
         latlon = sapply(str_split(Location, '/'), last),                           # split up location (3 parts)
         latlon = str_extract_all(latlon, '[-|[0-9]]+\\.[0-9]+'),                   # grab any that start with - or number
         lat = sapply(latlon, first),                                               # grab latitudes
         lon = sapply(latlon, nth, 2),                                              # grab longitude
         population2014 = as.numeric(str_replace_all(X2014.estimate, ',', '')),     # remove commas from numbers (why do people do this?)
         population2010 = as.numeric(str_replace_all(X2010.Census, ',', '')),       # same for 2010
         popDiff  = round(population2014/population2010 - 1, 2)*100) %>%            # create percentage difference
```


Cont'd.
========================================================


```r
  select(-latlon, -Location) %>%                                                    # remove stuff we wouldn't ever use
  filter(as.numeric(as.character(X2014.rank)) <= 50)  %>%                           # top 50
  leaflet %>%                                                                       # map out
  addProviderTiles("CartoDB.DarkMatterNoLabels") %>% 
  setView(-94, 35, zoom = 4) %>% 
  addCircleMarkers(~lon, ~lat,
                   radius=  ~scales::rescale(popDiff, c(1, 10)),
                   fillColor=  ~pal(popDiff), stroke = FALSE, fillOpacity = .85,
                   popup=  ~paste(City, paste0(popDiff, '%')))
```



And the result...
========================================================

<!--html_preserve--><div id="htmlwidget-6988" style="width:504px;height:504px;" class="leaflet"></div>
<script type="application/json" data-for="htmlwidget-6988">{"x":{"calls":[{"method":"addProviderTiles","args":["CartoDB.DarkMatterNoLabels",null,null,{"errorTileUrl":"","noWrap":false,"zIndex":null,"unloadInvisibleTiles":null,"updateWhenIdle":null,"detectRetina":false,"reuseTiles":false}]},{"method":"addCircleMarkers","args":[["40.6643","34.0194","41.8376","29.7805","40.0094","33.5722","29.4724","32.8153","32.7757","37.2969","30.3072","30.3370","37.7751","39.7767","39.9848","32.7795","35.2087","42.3830","31.8484","47.6205","39.7618","38.9041","35.1035","42.3320","36.1718","39.3002","35.4671","45.5370","36.2277","38.1781","43.0633","35.1056","32.1543","36.7827","38.5666","33.8091","39.1252","33.4019","33.7629","36.7793","41.2647","38.8673","35.8302","25.7752","37.7699","44.9633","36.1279","41.4781","37.6907","30.0686"],["-73.9385","-118.4108","-87.6818","-95.3863","-75.1333","-112.0880","-98.5251","-117.1350","-96.7967","-121.8193","-97.7560","-81.6613","-122.4193","-86.1459","-82.9850","-97.3463","-80.8307","-83.1022","-106.4270","-122.3509","-104.8806","-77.0171","-89.9785","-71.0202","-86.7850","-76.6105","-97.5137","-122.6500","-115.2640","-85.6667","-87.9667","-106.6474","-110.8711","-119.7945","-121.4686","-118.1553","-94.5511","-111.7174","-84.4227","-76.0240","-96.0419","-104.7607","-78.6414","-80.2086","-122.2256","-93.2683","-95.9023","-81.6795","-97.3427","-89.9390"],[6.05,6.05,4.7,7.4,5.15,6.95,7.85,6.95,7.4,7.4,11,6.05,6.95,5.6,6.95,8.75,9.2,2,6.5,8.75,9.2,8.75,5.15,6.95,7.4,4.25,7.4,6.95,6.5,5.6,4.7,5.15,5.15,6.05,6.05,5.15,5.15,6.95,8.3,5.6,8.3,7.4,8.3,7.85,6.95,6.95,5.15,3.35,5.15,9.65],null,null,{"lineCap":null,"lineJoin":null,"clickable":true,"pointerEvents":null,"className":"","stroke":false,"color":"#03F","weight":5,"opacity":0.5,"fill":true,"fillColor":["#FFECE5","#FFECE5","#FFB29A","#D4C9E6","#FFC6B2","#EAE4F2","#BFAED9","#EAE4F2","#D4C9E6","#D4C9E6","#000080","#FFECE5","#EAE4F2","#FFD9CB","#EAE4F2","#947BC0","#7E63B3","#FF0000","#FFFFFF","#947BC0","#7E63B3","#947BC0","#FFC6B2","#EAE4F2","#D4C9E6","#FF9E81","#D4C9E6","#EAE4F2","#FFFFFF","#FFD9CB","#FFB29A","#FFC6B2","#FFC6B2","#FFECE5","#FFECE5","#FFC6B2","#FFC6B2","#EAE4F2","#AA95CD","#FFD9CB","#AA95CD","#D4C9E6","#AA95CD","#BFAED9","#EAE4F2","#EAE4F2","#FFC6B2","#FF7352","#FFC6B2","#674BA6"],"fillOpacity":0.85,"dashArray":null},null,null,["New York 4%","Los Angeles 4%","Chicago 1%","Houston 7%","Philadelphia 2%","Phoenix 6%","San Antonio 8%","San Diego 6%","Dallas 7%","San Jose 7%","Austin 15%","Jacksonville 4%","San Francisco 6%","Indianapolis 3%","Columbus 6%","Fort Worth 10%","Charlotte 11%","Detroit -5%","El Paso 5%","Seattle 10%","Denver 11%","Washington 10%","Memphis 2%","Boston 6%","Nashville 7%","Baltimore 0%","Oklahoma City 7%","Portland 6%","Las Vegas 5%","Louisville 3%","Milwaukee 1%","Albuquerque 2%","Tucson 2%","Fresno 4%","Sacramento 4%","Long Beach 2%","Kansas City 2%","Mesa 6%","Atlanta 9%","Virginia Beach 3%","Omaha 9%","Colorado Springs 7%","Raleigh 9%","Miami 8%","Oakland 6%","Minneapolis 6%","Tulsa 2%","Cleveland -2%","Wichita 2%","New Orleans 12%"]]}],"setView":[[35,-94],4,[]],"limits":{"lat":[1,50],"lng":[1,50]}},"evals":[]}</script><!--/html_preserve-->



========================================================

- In the interests of your own code, the previous is not recommended.

- It serves as an illustration of what's possible.



Newer approaches to data wrangling
========================================================
Over the past couple of years, a handful of packages have been put out that make data management within R noticeably easier

We will focus on <span class='pack'>plyr</span>, <span class='pack'>dplyr</span>, and <span class='pack'>tidyr</span>

But others, e.g. <span class='pack'>data.table</span>, take different approaches and may be useful as well

Newer visualization packages take advantage of these approaches to data manipulation

- Makes it easier to explore your data visually



A provocation
========================================================
type: prompt
class: big-code


```r
c('Ceci', "n'est", 'pas', 'une', 'pipe!') %>%
{
  .. <-  . %>%
    if (length(.) == 1)  .
    else paste(.[1], '%>%', ..(.[-1]))
  ..(.)
} 
```


========================================================
class: big-code


```r
c('Ceci', "n'est", 'pas', 'une', 'pipe!') %>%
{
  .. <-  . %>%
    if (length(.) == 1)  .
    else paste(.[1], '%>%', ..(.[-1]))
  ..(.)
} 
```

```
[1] "Ceci %>% n'est %>% pas %>% une %>% pipe!"
```




Your turn
========================================================
type: prompt

Your turn
========================================================
Let's get to it!

>- Use a base R dataset
    - Examples: iris, mtcars, faithful or state.x77; <span style='font-family:monospace'>library(help='datasets')</span>
>- Pipe to something like the <span class='func'>summary</span>, <span class='func'>plot</span> or <span class='func'>cor</span> (if all numeric) as follows:


```r
data %>% 
  function
```

>- If the function you use has additional arguments you want to try, put those arguments in parentheses:


```r
data %>% 
  function(arg='blah')
```
Note that Ctrl+Shft+m is the shortcut to make the %>% pipe.


Example
========================================================

```r
iris %>% summary
```

```
  Sepal.Length    Sepal.Width     Petal.Length    Petal.Width          Species  
 Min.   :4.300   Min.   :2.000   Min.   :1.000   Min.   :0.100   setosa    :50  
 1st Qu.:5.100   1st Qu.:2.800   1st Qu.:1.600   1st Qu.:0.300   versicolor:50  
 Median :5.800   Median :3.000   Median :4.350   Median :1.300   virginica :50  
 Mean   :5.843   Mean   :3.057   Mean   :3.758   Mean   :1.199                  
 3rd Qu.:6.400   3rd Qu.:3.300   3rd Qu.:5.100   3rd Qu.:1.800                  
 Max.   :7.900   Max.   :4.400   Max.   :6.900   Max.   :2.500                  
```



Data Wrangling
========================================================
type: prompt

Generating New Data
========================================================
type: prompt


Generating New Data
========================================================

As is often the case, there are times when we want to calculate new variables based upon existing ones, or perhaps make changes to ones we have.

We can use mutate or transmute for this.

>- <span class='func'>mutate</span> appends to current data
>- <span class='func'>mutate_each</span> will apply a function over multiple columns
>- <span class='func'>transmute</span> will return only the newly created data

First, let's scrape some data:


```r
url = "http://www.basketball-reference.com/leagues/NBA_2015_totals.html?lid=header_seasons"
bball = read_html(url) %>% 
  html_nodes("table#totals") %>% 
  html_table %>% 
  data.frame %>%
  filter(Rk != "Rk")
```



Generating New Data
========================================================
The data is currently all character strings.

We'll use <span class='func'>mutate_each</span> to make every column numeric except for Player, Pos, and Tm.


```r
bball %<>% 
  mutate_each(funs(as.numeric), -Player, -Pos, -Tm)   

glimpse(bball)
```

```
Observations: 651
Variables: 30
$ Rk     (dbl) 1, 2, 3, 4, 5, 5, 5, 6, 7, 8, 9, 10, 11, 12, 13, 13, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23, 24,...
$ Player (chr) "Quincy Acy", "Jordan Adams", "Steven Adams", "Jeff Adrien", "Arron Afflalo", "Arron Afflalo", "Arro...
$ Pos    (chr) "PF", "SG", "C", "PF", "SG", "SG", "SG", "C", "PF", "C", "PF", "PF", "SG", "SF", "PF", "PF", "PF", "...
$ Age    (dbl) 24, 20, 21, 28, 29, 29, 29, 26, 23, 26, 29, 25, 33, 24, 32, 32, 32, 36, 32, 21, 26, 20, 30, 32, 32, ...
$ Tm     (chr) "NYK", "MEM", "OKC", "MIN", "TOT", "DEN", "POR", "NOP", "PHI", "NYK", "POR", "IND", "MEM", "DAL", "T...
$ G      (dbl) 68, 30, 70, 17, 78, 53, 25, 68, 41, 61, 71, 63, 63, 74, 53, 12, 41, 60, 74, 33, 61, 81, 40, 49, 63, ...
$ GS     (dbl) 22, 0, 67, 0, 72, 53, 19, 8, 9, 16, 71, 0, 41, 3, 35, 0, 35, 20, 19, 8, 5, 71, 40, 0, 3, 82, 4, 76, ...
$ MP     (dbl) 1287, 248, 1771, 215, 2502, 1750, 752, 957, 540, 976, 2512, 1070, 1648, 1366, 937, 79, 858, 1132, 17...
$ FG     (dbl) 152, 35, 217, 19, 375, 281, 94, 181, 40, 144, 659, 141, 225, 147, 109, 4, 105, 120, 195, 31, 291, 38...
$ FGA    (dbl) 331, 86, 399, 44, 884, 657, 227, 329, 78, 301, 1415, 299, 455, 357, 255, 12, 243, 207, 440, 89, 729,...
$ FG.    (dbl) 0.459, 0.407, 0.544, 0.432, 0.424, 0.428, 0.414, 0.550, 0.513, 0.478, 0.466, 0.472, 0.495, 0.412, 0....
$ X3P    (dbl) 18, 10, 0, 0, 118, 82, 36, 0, 0, 0, 37, 0, 10, 34, 0, 0, 0, 4, 73, 3, 122, 7, 61, 0, 52, 194, 26, 0,...
$ X3PA   (dbl) 60, 25, 2, 0, 333, 243, 90, 0, 5, 0, 105, 0, 29, 124, 1, 0, 1, 13, 210, 11, 359, 44, 179, 0, 173, 55...
$ X3P.1  (dbl) 0.300, 0.400, 0.000, NA, 0.354, 0.337, 0.400, NA, 0.000, NA, 0.352, NA, 0.345, 0.274, 0.000, NA, 0.0...
$ X2P    (dbl) 134, 25, 217, 19, 257, 199, 58, 181, 40, 144, 622, 141, 215, 113, 109, 4, 105, 116, 122, 28, 169, 37...
$ X2PA   (dbl) 271, 61, 397, 44, 551, 414, 137, 329, 73, 301, 1310, 299, 426, 233, 254, 12, 242, 194, 230, 78, 370,...
$ X2P.1  (dbl) 0.494, 0.410, 0.547, 0.432, 0.466, 0.481, 0.423, 0.550, 0.548, 0.478, 0.475, 0.472, 0.505, 0.485, 0....
$ eFG.   (dbl) 0.486, 0.465, 0.544, 0.432, 0.491, 0.490, 0.493, 0.550, 0.513, 0.478, 0.479, 0.472, 0.505, 0.459, 0....
$ FT     (dbl) 76, 14, 103, 22, 167, 127, 40, 81, 13, 50, 306, 33, 79, 84, 41, 3, 38, 76, 82, 9, 129, 257, 189, 15,...
$ FTA    (dbl) 97, 23, 205, 38, 198, 151, 47, 99, 27, 64, 362, 47, 126, 118, 87, 5, 82, 114, 101, 14, 151, 347, 237...
$ FT.    (dbl) 0.784, 0.609, 0.502, 0.579, 0.843, 0.841, 0.851, 0.818, 0.481, 0.781, 0.845, 0.702, 0.627, 0.712, 0....
$ ORB    (dbl) 79, 9, 199, 23, 27, 21, 6, 104, 78, 101, 177, 123, 103, 114, 94, 5, 89, 76, 31, 5, 108, 100, 72, 32,...
$ DRB    (dbl) 222, 19, 324, 54, 220, 159, 61, 211, 98, 237, 549, 200, 177, 228, 174, 15, 159, 223, 173, 67, 187, 4...
$ TRB    (dbl) 301, 28, 523, 77, 247, 180, 67, 315, 176, 338, 726, 323, 280, 342, 268, 20, 248, 299, 204, 72, 295, ...
$ AST    (dbl) 68, 16, 66, 15, 129, 101, 28, 47, 28, 75, 124, 73, 86, 59, 70, 5, 65, 43, 83, 28, 55, 207, 122, 5, 4...
$ STL    (dbl) 27, 16, 38, 4, 41, 32, 9, 21, 17, 37, 48, 15, 129, 70, 22, 1, 21, 26, 56, 15, 33, 73, 40, 12, 18, 15...
$ BLK    (dbl) 22, 7, 86, 9, 7, 5, 2, 51, 16, 65, 68, 42, 30, 62, 52, 0, 52, 61, 5, 7, 20, 85, 17, 49, 14, 17, 26, ...
$ TOV    (dbl) 60, 14, 99, 9, 116, 83, 33, 69, 17, 59, 122, 40, 86, 55, 62, 5, 57, 40, 60, 10, 62, 173, 89, 12, 49,...
$ PF     (dbl) 147, 24, 222, 30, 167, 108, 59, 151, 96, 122, 125, 102, 166, 137, 126, 11, 115, 88, 148, 28, 113, 25...
$ PTS    (dbl) 398, 94, 537, 60, 1035, 771, 264, 443, 93, 338, 1661, 315, 539, 412, 259, 11, 248, 320, 545, 74, 833...
```



Mutate
========================================================
<div class="columns-2">
<span class='func'>mutate</span> takes a vector and returns a vector of the same dimension

- 'window' function

<br>
We will contrast it with <span class='func'>summarize</span> later

- or <span class='func'>summarise</span> if you prefer
<br>
<br>
<br>
<br>


<img src="window.png" style='height:100px'></img>
<img src="summary.png" style='height:100px'></img>
</div>



Generating New Data
========================================================
A common situation, creating composites of existing variables.


```r
bball = bball %>% 
  mutate(trueShooting = PTS / (2 * (FGA + (.44 * FTA))),
         effectiveFG = (FG + (.5 * X3P)) / FGA, 
         shootingDif = trueShooting - FG.)

summary(select(bball, shootingDif))  # select and others don't have to be piped to use
```

```
  shootingDif      
 Min.   :-0.08645  
 1st Qu.: 0.04193  
 Median : 0.08016  
 Mean   : 0.07855  
 3rd Qu.: 0.11292  
 Max.   : 0.25000  
 NA's   :2         
```



Generating New Data
========================================================
Note how we use the new variables



Generating New Data
========================================================
Sometimes we want to combine (or split) variables...
<span class='func'>unite</span> creates a new variable as the string combination of others.

- essentially <span class='func'>paste</span>


```r
library(tidyr)
bball %>% 
  unite("posTeam", Pos, Tm) %>% 
  select(1:5) %>% 
  head
```

```
  Rk        Player posTeam Age  G
1  1    Quincy Acy  PF_NYK  24 68
2  2  Jordan Adams  SG_MEM  20 30
3  3  Steven Adams   C_OKC  21 70
4  4   Jeff Adrien  PF_MIN  28 17
5  5 Arron Afflalo  SG_TOT  29 78
6  5 Arron Afflalo  SG_DEN  29 53
```


Generating New Data
========================================================
<span class='func'>separate</span> does the opposite.

Separate player into first and last names based on where the space occurs.


```r
bball %>% 
  separate(Player, into=c('firstName', 'lastName'), sep=' ') %>% 
  select(1:5) %>% 
  head
```

```
  Rk firstName lastName Pos Age
1  1    Quincy      Acy  PF  24
2  2    Jordan    Adams  SG  20
3  3    Steven    Adams   C  21
4  4      Jeff   Adrien  PF  28
5  5     Arron  Afflalo  SG  29
6  5     Arron  Afflalo  SG  29
```



Your turn
========================================================
Your turn
========================================================

Data: state.x77

0. Convert to <span class='func'>data.frame</span>
1. Create a variable that's the <span class='func'>log</span> of population (<span class='func'>mutate</span> )
2. Create **curLifeExp** as Life Expectancy (**Life.Exp**) + 5 (<span class='func'>mutate</span> )
3. summarize the data (<span class='func'>summary</span> )



Example
========================================================

```r
state.x77 %>% 
  data.frame %>% 
  mutate(popLog = log(Population),
         curLifeExp = Life.Exp+5) %>% 
  summary
```

```
   Population        Income       Illiteracy       Life.Exp         Murder          HS.Grad          Frost       
 Min.   :  365   Min.   :3098   Min.   :0.500   Min.   :67.96   Min.   : 1.400   Min.   :37.80   Min.   :  0.00  
 1st Qu.: 1080   1st Qu.:3993   1st Qu.:0.625   1st Qu.:70.12   1st Qu.: 4.350   1st Qu.:48.05   1st Qu.: 66.25  
 Median : 2838   Median :4519   Median :0.950   Median :70.67   Median : 6.850   Median :53.25   Median :114.50  
 Mean   : 4246   Mean   :4436   Mean   :1.170   Mean   :70.88   Mean   : 7.378   Mean   :53.11   Mean   :104.46  
 3rd Qu.: 4968   3rd Qu.:4814   3rd Qu.:1.575   3rd Qu.:71.89   3rd Qu.:10.675   3rd Qu.:59.15   3rd Qu.:139.75  
 Max.   :21198   Max.   :6315   Max.   :2.800   Max.   :73.60   Max.   :15.100   Max.   :67.30   Max.   :188.00  
      Area            popLog        curLifeExp   
 Min.   :  1049   Min.   :5.900   Min.   :72.96  
 1st Qu.: 36985   1st Qu.:6.984   1st Qu.:75.12  
 Median : 54277   Median :7.951   Median :75.67  
 Mean   : 70736   Mean   :7.863   Mean   :75.88  
 3rd Qu.: 81163   3rd Qu.:8.511   3rd Qu.:76.89  
 Max.   :566432   Max.   :9.962   Max.   :78.60  
```



Selecting Variables
========================================================
type: prompt

Selecting Variables
========================================================

There are times when you do not want to look at the entire dataset, but instead want to focus on a few key variables.

Although this is easily handled in base R (as shown earlier), it can often more clearly accomplished using select in <span class='pack'>dplyr</span>

The following lets us look at the data clearly, without having to create objects, use quotes etc.


```r
bball %>% 
  select(Player, Tm, Pos, MP, trueShooting, effectiveFG, PTS) %>% 
  summary
```

```
    Player               Tm                Pos                  MP        trueShooting     effectiveFG    
 Length:651         Length:651         Length:651         Min.   :   1   Min.   :0.0000   Min.   :0.0000  
 Class :character   Class :character   Class :character   1st Qu.: 272   1st Qu.:0.4719   1st Qu.:0.4402  
 Mode  :character   Mode  :character   Mode  :character   Median : 896   Median :0.5174   Median :0.4799  
                                                          Mean   :1042   Mean   :0.5060   Mean   :0.4728  
                                                          3rd Qu.:1674   3rd Qu.:0.5555   3rd Qu.:0.5180  
                                                          Max.   :2981   Max.   :1.0638   Max.   :1.0000  
                                                                         NA's   :2        NA's   :2       
      PTS        
 Min.   :   0.0  
 1st Qu.:  90.0  
 Median : 308.0  
 Mean   : 428.1  
 3rd Qu.: 658.0  
 Max.   :2217.0  
                 
```



Selecting Variables
========================================================
That works great, but now we need to drop some of those variables to look at correlations.


```r
scoringDat = bball %>% 
  select(Player, Tm, Pos, MP, trueShooting, effectiveFG, PTS)

scoringDat %>% 
  select(-Player, -Tm, -Pos) %>% 
  cor(use='complete') %>% 
  round(2)
```

```
               MP trueShooting effectiveFG  PTS
MP           1.00         0.34        0.30 0.93
trueShooting 0.34         1.00        0.96 0.33
effectiveFG  0.30         0.96        1.00 0.27
PTS          0.93         0.33        0.27 1.00
```



Selecting Variables
========================================================
Sometimes, we have a lot of variables to select. If they have a common naming scheme, this becomes very easy.


```r
bball %>% 
  select(Player, contains("3P"), ends_with("RB")) %>% 
  arrange(desc(TRB)) %>% 
  head
```

```
          Player X3P X3PA X3P.1 ORB DRB  TRB
1 DeAndre Jordan   1    4 0.250 397 829 1226
2 Andre Drummond   0    2 0.000 437 667 1104
3      Pau Gasol  12   26 0.462 220 699  919
4 Tyson Chandler   0    0    NA 294 570  864
5 Nikola Vucevic   2    6 0.333 238 572  810
6    Rudy Gobert   0    2 0.000 265 510  775
```



Filtering Observations
========================================================
type: prompt

Filtering Observations
========================================================

Recall this bit of code?


```r
bball = html(url) %>% 
  html_nodes("table#totals") %>% 
  html_table %>% 
  data.frame %>% 
  filter(Rk != "Rk")
```

You will notice the filter line at the end.

We sometimes want to see a very specific portion of the data.



Filtering Observations
========================================================
>- <span class='func'>filter</span> returns rows with matching conditions.
>- <span class='func'>slice</span> allows for a numeric indexing approach.

>- Say we want too look at forwards over the age of 35...


```r
bball %>% 
  filter(Age > 35, Pos == "SF" | Pos == "PF")
```

>- or the first 10 rows...


```r
bball %>% 
  slice(1:10)
```



Filtering Observations
========================================================
This can be done with things that are created on the fly...


```r
bball %>% 
  unite("posTeam", Pos, Tm) %>% 
  filter(posTeam == "PF_SAS") %>% 
  arrange(desc(PTS/PF)) %>% 
  select(1:10)
```

```
   Rk         Player posTeam Age  G GS   MP  FG FGA   FG.
1 137     Tim Duncan  PF_SAS  38 77 77 2227 419 819 0.512
2 126     Boris Diaw  PF_SAS  32 81 15 1984 291 632 0.460
3  56    Matt Bonner  PF_SAS  34 72 19  935  94 230 0.409
4  26     Jeff Ayres  PF_SAS  27 51  0  383  55  95 0.579
5 187 JaMychal Green  PF_SAS  24  4  0   25   4   7 0.571
```


Your turn
========================================================
type:prompt

Your turn
========================================================
A brief exercise:

1. <span class='func'>filter</span> the iris data set to only the virginica species (<span class='func'>==</span> )
2. show only **Petal.Length** and **Petal.Width** variables (<span class='func'>select</span> )
3. bonus: redo, but instead, filter if the ratio of **Petal.Length** to **Petal.Width** is greater than 5. Which species do these observations belong to?



Example
========================================================

```r
iris %>% 
  filter(Petal.Length/Petal.Width > 5) %>% 
  summary
```

```
  Sepal.Length    Sepal.Width     Petal.Length    Petal.Width           Species  
 Min.   :4.300   Min.   :2.900   Min.   :1.100   Min.   :0.1000   setosa    :34  
 1st Qu.:4.800   1st Qu.:3.100   1st Qu.:1.400   1st Qu.:0.2000   versicolor: 0  
 Median :5.000   Median :3.400   Median :1.450   Median :0.2000   virginica : 0  
 Mean   :4.982   Mean   :3.382   Mean   :1.456   Mean   :0.1882                  
 3rd Qu.:5.200   3rd Qu.:3.575   3rd Qu.:1.500   3rd Qu.:0.2000                  
 Max.   :5.800   Max.   :4.200   Max.   :1.900   Max.   :0.3000                  
```




Reshaping Data
========================================================
type: prompt


Reshaping Data
========================================================
Depending upon your analytical or visualization needs, sometimes you need to reshape your data.

Reshaping can take many forms. You might need to reshape your data from wide format to long format.

Or, maybe you need to split or combine variables.

Either way, R has you covered.



Wide to Long
========================================================

We are going to use the <span class='pack'>tidyr</span> package to make this data go from wide to long.

The function of note is <span class='func'>gather</span>.

- **key** is the new variable name, a factor whose labels are the variable names of the wide format
- **value** is the name of the variable that will contain their values


```r
bballLong = bball %>% 
  select(Player, Tm, FG., X3P, X2P.1, trueShooting, effectiveFG) %>%
  rename(fieldGoalPerc = FG., threePointPerc = X3P, twoPointPerc = X2P.1) %>% 
  mutate(threePointPerc = threePointPerc/100) %>% 
  gather(key = 'vitalInfo', value = 'value', -Tm, -Player) 

bballLong %>% head
```

```
         Player  Tm     vitalInfo value
1    Quincy Acy NYK fieldGoalPerc 0.459
2  Jordan Adams MEM fieldGoalPerc 0.407
3  Steven Adams OKC fieldGoalPerc 0.544
4   Jeff Adrien MIN fieldGoalPerc 0.432
5 Arron Afflalo TOT fieldGoalPerc 0.424
6 Arron Afflalo DEN fieldGoalPerc 0.428
```


Long to wide
========================================================
Going the reverse direction


```r
bballLong %>%
  spread(vitalInfo, value) %>% 
  head
```

```
        Player  Tm effectiveFG fieldGoalPerc threePointPerc trueShooting twoPointPerc
1   A.J. Price CLE   0.2647059         0.265           0.00    0.3002183        0.391
2   A.J. Price IND   0.5224719         0.438           0.15    0.5416839        0.480
3   A.J. Price PHO   0.2142857         0.214           0.00    0.2142857        0.429
4   A.J. Price TOT   0.4270073         0.372           0.15    0.4506641        0.450
5 Aaron Brooks CHI   0.4951040         0.421           1.21    0.5338198        0.442
6 Aaron Gordon ORL   0.4783654         0.447           0.13    0.5173735        0.500
```



Grouping and Summarizing Data
========================================================
type:prompt

Grouping and Summarizing Data
========================================================

When working with data, a very common task is to look at descriptive statistics for various groups.

We can use <span class='func'>group_by</span> to make this straightforward.


```r
scoringDat %>% 
  group_by(Pos) %>% 
  summarize(meanTrueShooting = mean(trueShooting, na.rm = TRUE))
```

```
Source: local data frame [11 x 2]

     Pos meanTrueShooting
   (chr)            (dbl)
1      C        0.5461368
2     PF        0.5119408
3  PF-SF        0.4561743
4     PG        0.4808936
5  PG-SG        0.5115452
6     SF        0.5083532
7  SF-PF        0.5537975
8  SF-SG        0.5498324
9     SG        0.4956460
10 SG-PG        0.5435740
11 SG-SF        0.4706034
```


Your Turn
========================================================
type:prompt


Putting it all together
========================================================

?state.x77

Using one pipe sequence 

1. convert state.x77 (a base R object) to a data frame (<span class='func'>data.frame</span> )
2. create a new variable called **Region** that is equal to state.region (<span class='func'>mutate</span> )
3. create a new variable called **State** that is equal to state.name
4. <span class='func'>filter</span> only if Population is greater than 1000 (thousands)
5. <span class='func'>select</span> **Region** and variables beginning with I
6. group by **Region**  (<span class='func'>group_by</span> )
7. <span class='func'>summarize</span> **Income**, **Illiteracy** or **Both**, using the mean function


Example
========================================================


```r
state.x77 %>% 
  data.frame %>% 
  mutate(Region = state.region,
         State = state.name) %>% 
  filter(Population > 1000) %>% 
  select(Region, starts_with('I')) %>% 
  group_by(Region) %>% 
  summarize(meanInc=mean(Income),
            meanIll=mean(Illiteracy))
```

```
Source: local data frame [4 x 3]

         Region meanInc  meanIll
         (fctr)   (dbl)    (dbl)
1     Northeast  4731.0 1.066667
2         South  3958.8 1.793333
3 North Central  4607.9 0.710000
4          West  4525.0 1.085714
```



Nothin's gonna stop the flow
========================================================
type:prompt


More with pipes
========================================================
Recap thus far:

<span class='pipe'>%>%</span> : Passes the prior object to the function after the pipe

- x <span class='pipe'>%>%</span> f same as f(x)
- Example:


```r
iris %>% head
```

```
  Sepal.Length Sepal.Width Petal.Length Petal.Width Species
1          5.1         3.5          1.4         0.2  setosa
2          4.9         3.0          1.4         0.2  setosa
3          4.7         3.2          1.3         0.2  setosa
4          4.6         3.1          1.5         0.2  setosa
5          5.0         3.6          1.4         0.2  setosa
6          5.4         3.9          1.7         0.4  setosa
```

```r
head(iris)
```

```
  Sepal.Length Sepal.Width Petal.Length Petal.Width Species
1          5.1         3.5          1.4         0.2  setosa
2          4.9         3.0          1.4         0.2  setosa
3          4.7         3.2          1.3         0.2  setosa
4          4.6         3.1          1.5         0.2  setosa
5          5.0         3.6          1.4         0.2  setosa
6          5.4         3.9          1.7         0.4  setosa
```


More with pipes
========================================================
<span class='pipe'>%\$%</span>  : Exposes the names in the prior to the function after

- x <span class='pipe'>%\$%</span> y(a, b)  same as y(x\$a, x\$b)
- Example:


```r
iris %$% lm(Sepal.Length ~ Sepal.Width)
```

```

Call:
lm(formula = Sepal.Length ~ Sepal.Width)

Coefficients:
(Intercept)  Sepal.Width  
     6.5262      -0.2234  
```


More with pipes
========================================================

<span class='pipe'>%T>%</span> : Passes the prior object to the function after the pipe and what follows

- x <span class='pipe'>%T>%</span> y <span class='pipe'>%>%</span> z is the same as x <span class='pipe'>%>%</span> y & x <span class='pipe'>%>%</span> z

More with pipes
========================================================

Example:


```r
iris %>% select(Sepal.Length, Sepal.Width) %T>% plot %>%summary
```

![plot of chunk Tpipe](mainSlides-figure/Tpipe-1.png)

```
  Sepal.Length    Sepal.Width   
 Min.   :4.300   Min.   :2.000  
 1st Qu.:5.100   1st Qu.:2.800  
 Median :5.800   Median :3.000  
 Mean   :5.843   Mean   :3.057  
 3rd Qu.:6.400   3rd Qu.:3.300  
 Max.   :7.900   Max.   :4.400  
```

More with pipes
========================================================

Unfortunately the T pipe does not allow for printable results.

- Works:

```r
iris %>% select(Sepal.Length, Sepal.Width) %T>% plot %>% summary
```

- Provides no summary:

```r
iris %>% select(Sepal.Length, Sepal.Width) %T>% summary %>% plot
```

- Somewhat limiting in my opinion.


More with pipes
========================================================
<span class='pipe'>%<>%</span> : assigns to former object the operations that follow

- Example:


```r
iris2 = iris
iris2 %<>% rnorm(10)
iris2
```

```
[1] 10.336344 10.223210  8.557989  8.978637  9.093819
```



Piping for Visualization
========================================================
type:prompt

Piping for Visualization
========================================================

One of the advantages to piping is that it's not limited to dplyr style data management functions.

<span class='emph'>*Any*</span> R function can be potentially piped to, and we've seen several examples so far.


```r
data.frame(y=rnorm(100), x=rnorm(100)) %$%
  lm(y ~ x)
```

```

Call:
lm(formula = y ~ x)

Coefficients:
(Intercept)            x  
    0.05921     -0.04505  
```

This facilitates data exploration.



htmlwidgets
========================================================
Many newer visualization packages take advantage of piping as well.

<span class='pack'>htmlwidgets</span> is a package that makes it easy to use R to create javascript visualizations.

- i.e. what you see everywhere on the web.

The packages using it typically are pipe-oriented and produce interactive plots.



Some htmlwidgets packages
========================================================
- <span class='pack'>leaflet</span>
    - maps with OpenStreetMap
- <span class='pack'>dygraphs</span>
    - time series visualization
- <span class='pack'>networkD3</span>
    - Network visualization with D3
- <span class='pack'>DT</span>
    - Tabular data via DataTables
- <span class='pack'>rthreejs</span>
    - 3D graphics


leaflet
========================================================


```r
leaflet() %>% 
  setView(lat=42.2655, lng=-83.7485, zoom=15) %>% 
  addTiles() %>% 
  addPopups(lat=42.2655, lng=-83.7485, 'Hi!')
```

<!--html_preserve--><div id="htmlwidget-4859" style="width:504px;height:504px;" class="leaflet"></div>
<script type="application/json" data-for="htmlwidget-4859">{"x":{"setView":[[42.2655,-83.7485],15,[]],"calls":[{"method":"addTiles","args":["http://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png",null,null,{"minZoom":0,"maxZoom":18,"maxNativeZoom":null,"tileSize":256,"subdomains":"abc","errorTileUrl":"","tms":false,"continuousWorld":false,"noWrap":false,"zoomOffset":0,"zoomReverse":false,"opacity":1,"zIndex":null,"unloadInvisibleTiles":null,"updateWhenIdle":null,"detectRetina":false,"reuseTiles":false,"attribution":"&copy; <a href=\"http://openstreetmap.org\">OpenStreetMap</a> contributors, <a href=\"http://creativecommons.org/licenses/by-sa/2.0/\">CC-BY-SA</a>"}]},{"method":"addPopups","args":[42.2655,-83.7485,"Hi!",null,null,{"maxWidth":300,"minWidth":50,"maxHeight":null,"autoPan":true,"keepInView":false,"closeButton":true,"zoomAnimation":true,"closeOnClick":null,"className":""}]}],"limits":{"lat":[42.2655,42.2655],"lng":[-83.7485,-83.7485]}},"evals":[]}</script><!--/html_preserve-->


dygraphs
========================================================

Dygraphs requires time-series objects


```r
#use current poll data code from home
library(dygraphs)
data(UKLungDeaths)
cbind(ldeaths, mdeaths, fdeaths) %>% 
  dygraph()
```

<!--html_preserve--><div id="htmlwidget-8646" style="width:504px;height:216px;" class="dygraphs"></div>
<script type="application/json" data-for="htmlwidget-8646">{"x":{"attrs":{"labels":["month","ldeaths","mdeaths","fdeaths"],"legend":"auto","retainDateWindow":false,"axes":{"x":{"pixelsPerLabel":60}}},"scale":"monthly","annotations":[],"shadings":[],"events":[],"format":"date","data":[["1974-01-01T00:00:00Z","1974-02-01T00:00:00Z","1974-03-01T00:00:00Z","1974-04-01T00:00:00Z","1974-05-01T00:00:00Z","1974-06-01T00:00:00Z","1974-07-01T00:00:00Z","1974-08-01T00:00:00Z","1974-09-01T00:00:00Z","1974-10-01T00:00:00Z","1974-11-01T00:00:00Z","1974-12-01T00:00:00Z","1975-01-01T00:00:00Z","1975-02-01T00:00:00Z","1975-03-01T00:00:00Z","1975-04-01T00:00:00Z","1975-05-01T00:00:00Z","1975-06-01T00:00:00Z","1975-07-01T00:00:00Z","1975-08-01T00:00:00Z","1975-09-01T00:00:00Z","1975-10-01T00:00:00Z","1975-11-01T00:00:00Z","1975-12-01T00:00:00Z","1976-01-01T00:00:00Z","1976-02-01T00:00:00Z","1976-03-01T00:00:00Z","1976-04-01T00:00:00Z","1976-05-01T00:00:00Z","1976-06-01T00:00:00Z","1976-07-01T00:00:00Z","1976-08-01T00:00:00Z","1976-09-01T00:00:00Z","1976-10-01T00:00:00Z","1976-11-01T00:00:00Z","1976-12-01T00:00:00Z","1977-01-01T00:00:00Z","1977-02-01T00:00:00Z","1977-03-01T00:00:00Z","1977-04-01T00:00:00Z","1977-05-01T00:00:00Z","1977-06-01T00:00:00Z","1977-07-01T00:00:00Z","1977-08-01T00:00:00Z","1977-09-01T00:00:00Z","1977-10-01T00:00:00Z","1977-11-01T00:00:00Z","1977-12-01T00:00:00Z","1978-01-01T00:00:00Z","1978-02-01T00:00:00Z","1978-03-01T00:00:00Z","1978-04-01T00:00:00Z","1978-05-01T00:00:00Z","1978-06-01T00:00:00Z","1978-07-01T00:00:00Z","1978-08-01T00:00:00Z","1978-09-01T00:00:00Z","1978-10-01T00:00:00Z","1978-11-01T00:00:00Z","1978-12-01T00:00:00Z","1979-01-01T00:00:00Z","1979-02-01T00:00:00Z","1979-03-01T00:00:00Z","1979-04-01T00:00:00Z","1979-05-01T00:00:00Z","1979-06-01T00:00:00Z","1979-07-01T00:00:00Z","1979-08-01T00:00:00Z","1979-09-01T00:00:00Z","1979-10-01T00:00:00Z","1979-11-01T00:00:00Z","1979-12-01T00:00:00Z"],[3035,2552,2704,2554,2014,1655,1721,1524,1596,2074,2199,2512,2933,2889,2938,2497,1870,1726,1607,1545,1396,1787,2076,2837,2787,3891,3179,2011,1636,1580,1489,1300,1356,1653,2013,2823,3102,2294,2385,2444,1748,1554,1498,1361,1346,1564,1640,2293,2815,3137,2679,1969,1870,1633,1529,1366,1357,1570,1535,2491,3084,2605,2573,2143,1693,1504,1461,1354,1333,1492,1781,1915],[2134,1863,1877,1877,1492,1249,1280,1131,1209,1492,1621,1846,2103,2137,2153,1833,1403,1288,1186,1133,1053,1347,1545,2066,2020,2750,2283,1479,1189,1160,1113,970,999,1208,1467,2059,2240,1634,1722,1801,1246,1162,1087,1013,959,1179,1229,1655,2019,2284,1942,1423,1340,1187,1098,1004,970,1140,1110,1812,2263,1820,1846,1531,1215,1075,1056,975,940,1081,1294,1341],[901,689,827,677,522,406,441,393,387,582,578,666,830,752,785,664,467,438,421,412,343,440,531,771,767,1141,896,532,447,420,376,330,357,445,546,764,862,660,663,643,502,392,411,348,387,385,411,638,796,853,737,546,530,446,431,362,387,430,425,679,821,785,727,612,478,429,405,379,393,411,487,574]]},"evals":[]}</script><!--/html_preserve-->


networkD3
========================================================




```r
library(networkD3)
forceNetwork(Links = netlinks, Nodes = netnodes, Source = "source",
             Target = "target", Value = "value", NodeID = "name",
             Nodesize = "size", Group = "group", opacity = 0.4, legend = T,
             colourScale = JS("d3.scale.category10()"))
```

<!--html_preserve--><div id="htmlwidget-7480" style="width:504px;height:504px;" class="forceNetwork"></div>
<script type="application/json" data-for="htmlwidget-7480">{"x":{"links":{"source":[0,0,0,1,1,2,2,3,3,3,4,5,5],"target":[3,5,0,1,4,2,2,2,4,0,1,4,0],"value":[8,2,8,2,8,4,8,6,7,8,1,2,4]},"nodes":{"name":["Bobby","Janie","Timmie","Mary","Johnny","Billy"],"group":["friend","frenemy","frenemy","friend","friend","friend"],"nodesize":[14,12,5,15,8,16]},"options":{"NodeID":"name","Group":"group","colourScale":"d3.scale.category10()","fontSize":7,"fontFamily":"serif","clickTextSize":17.5,"linkDistance":50,"linkWidth":"function(d) { return Math.sqrt(d.value); }","charge":-120,"linkColour":"#666","opacity":0.4,"zoom":false,"legend":true,"nodesize":true,"radiusCalculation":" Math.sqrt(d.nodesize)+6","bounded":false,"opacityNoHover":0,"clickAction":null}},"evals":[]}</script><!--/html_preserve-->


data table
========================================================


```r
library(DT)
datatable(select(bball, 1:5), rownames=F)
```

<!--html_preserve--><div id="htmlwidget-7135" style="width:100%;height:auto;" class="datatables"></div>
<script type="application/json" data-for="htmlwidget-7135">{"x":{"data":[[1,2,3,4,5,5,5,6,7,8,9,10,11,12,13,13,13,14,15,16,17,18,19,20,21,22,23,24,25,25,25,26,27,28,29,30,31,32,33,34,35,35,35,36,37,38,39,40,41,42,43,44,45,46,47,48,49,49,49,50,51,52,53,54,55,56,57,58,59,60,61,62,62,62,63,64,65,66,67,68,69,70,70,70,71,72,73,74,75,76,77,78,79,80,81,82,82,82,83,84,85,86,86,86,87,88,89,90,91,92,93,94,94,94,95,96,97,97,97,98,99,100,101,102,103,104,105,106,107,108,108,108,109,110,111,112,113,114,114,114,114,115,115,115,116,116,116,117,118,119,120,121,121,121,122,123,124,125,126,127,128,129,130,131,132,132,132,133,133,133,134,135,136,137,138,139,140,141,142,143,144,144,144,145,146,147,148,149,150,151,152,153,154,155,156,157,158,158,158,159,160,161,162,163,164,165,165,165,166,167,168,169,169,169,170,171,172,173,174,175,176,177,178,179,180,181,182,183,184,185,186,187,187,187,188,188,188,189,190,191,191,191,192,193,194,194,194,195,196,197,198,199,200,201,202,203,204,205,206,207,208,209,210,211,212,213,214,215,216,217,218,219,220,221,222,223,224,225,226,227,228,229,230,231,232,233,233,233,234,235,236,237,238,239,240,241,241,241,242,242,242,243,244,244,244,244,245,246,247,248,249,250,251,252,253,254,255,256,257,258,258,258,259,260,261,262,263,264,265,265,265,266,267,268,269,270,271,272,273,274,275,275,275,276,277,278,279,280,281,282,283,284,285,286,287,288,289,290,291,292,293,294,295,296,297,298,299,300,301,302,303,304,305,306,307,307,307,308,309,310,310,310,311,312,313,314,315,316,317,318,318,318,319,320,321,321,321,322,323,324,325,326,327,328,329,330,331,332,333,334,335,335,335,336,337,337,337,338,339,340,340,340,341,341,341,341,342,343,344,345,346,346,346,347,348,349,350,351,352,353,354,355,356,357,358,359,360,361,362,362,362,363,364,365,365,365,366,367,368,368,368,369,369,369,370,371,371,371,372,373,373,373,373,374,375,375,375,376,376,376,376,377,378,379,379,379,380,381,382,383,384,385,385,385,386,387,388,388,388,389,389,389,390,390,390,391,391,391,392,393,394,395,396,397,398,399,400,401,402,403,404,405,406,406,406,407,407,407,408,408,408,408,409,410,410,410,411,412,413,414,414,414,415,415,415,416,417,417,417,418,418,418,419,420,421,422,423,424,425,426,427,427,427,428,429,430,431,432,433,434,435,436,436,436,437,437,437,438,439,440,441,442,443,444,444,444,445,445,445,446,447,448,449,450,451,452,453,454,455,456,457,458,459,459,459,460,461,462,463,464,465,466,467,468,469,470,471,472,473,474,475,476,477,477,477,478,479,480,480,480,481,482,482,482,483,484,484,484,485,485,485,485,486,487,488,489,490,490,490,491,492],["Quincy Acy","Jordan Adams","Steven Adams","Jeff Adrien","Arron Afflalo","Arron Afflalo","Arron Afflalo","Alexis Ajinca","Furkan Aldemir","Cole Aldrich","LaMarcus Aldridge","Lavoy Allen","Tony Allen","Al-Farouq Aminu","Lou Amundson","Lou Amundson","Lou Amundson","Chris Andersen","Alan Anderson","Kyle Anderson","Ryan Anderson","Giannis Antetokounmpo","Carmelo Anthony","Joel Anthony","Pero Antic","Trevor Ariza","Darrell Arthur","Omer Asik","D.J. Augustin","D.J. Augustin","D.J. Augustin","Jeff Ayres","Luke Babbitt","Cameron Bairstow","Leandro Barbosa","J.J. Barea","Andrea Bargnani","Harrison Barnes","Matt Barnes","Earl Barron","Will Barton","Will Barton","Will Barton","Brandon Bass","Nicolas Batum","Jerryd Bayless","Aron Baynes","Kent Bazemore","Bradley Beal","Michael Beasley","Marco Belinelli","Jerrelle Benimon","Anthony Bennett","Patrick Beverley","Sim Bhullar","Bismack Biyombo","Tarik Black","Tarik Black","Tarik Black","DeJuan Blair","Steve Blake","Eric Bledsoe","Vander Blue","Bojan Bogdanovic","Andrew Bogut","Matt Bonner","Trevor Booker","Carlos Boozer","Chris Bosh","Avery Bradley","Elton Brand","Corey Brewer","Corey Brewer","Corey Brewer","Aaron Brooks","Jabari Brown","Lorenzo Brown","Markel Brown","Shannon Brown","Kobe Bryant","Chase Budinger","Reggie Bullock","Reggie Bullock","Reggie Bullock","Trey Burke","Alec Burks","Caron Butler","Jimmy Butler","Rasual Butler","Dwight Buycks","Will Bynum","Bruno Caboclo","Nick Calathes","Jose Calderon","Kentavious Caldwell-Pope","Isaiah Canaan","Isaiah Canaan","Isaiah Canaan","Clint Capela","DeMarre Carroll","Vince Carter","Michael Carter-Williams","Michael Carter-Williams","Michael Carter-Williams","Omri Casspi","Mario Chalmers","Tyson Chandler","Wilson Chandler","Will Cherry","Patrick Christopher","Earl Clark","Ian Clark","Ian Clark","Ian Clark","Jordan Clarkson","Victor Claver","Norris Cole","Norris Cole","Norris Cole","Darren Collison","Nick Collison","Mike Conley","Jack Cooley","Chris Copeland","Bryce Cotton","DeMarcus Cousins","Robert Covington","Allen Crabbe","Jamal Crawford","Jae Crowder","Jae Crowder","Jae Crowder","Dante Cunningham","Jared Cunningham","Seth Curry","Stephen Curry","Samuel Dalembert","Troy Daniels","Troy Daniels","Troy Daniels","Troy Daniels","Luigi Datome","Luigi Datome","Luigi Datome","Brandon Davies","Brandon Davies","Brandon Davies","Anthony Davis","Ed Davis","Glen Davis","Andre Dawkins","Austin Daye","Austin Daye","Austin Daye","Dewayne Dedmon","Matthew Dellavedova","Luol Deng","DeMar DeRozan","Boris Diaw","Gorgui Dieng","Spencer Dinwiddie","Joey Dorsey","Toney Douglas","Chris Douglas-Roberts","Goran Dragic","Goran Dragic","Goran Dragic","Zoran Dragic","Zoran Dragic","Zoran Dragic","Larry Drew","Andre Drummond","Jared Dudley","Tim Duncan","Mike Dunleavy","Kevin Durant","Cleanthony Early","Wayne Ellington","Monta Ellis","James Ennis","Tyler Ennis","Tyler Ennis","Tyler Ennis","Jeremy Evans","Reggie Evans","Tyreke Evans","Dante Exum","Festus Ezeli","Kenneth Faried","Jordan Farmar","Derrick Favors","Raymond Felton","Landry Fields","Evan Fournier","Randy Foye","Jamaal Franklin","Tim Frazier","Tim Frazier","Tim Frazier","Jimmer Fredette","Joel Freeland","Channing Frye","Danilo Gallinari","Langston Galloway","Francisco Garcia","Kevin Garnett","Kevin Garnett","Kevin Garnett","Marc Gasol","Pau Gasol","Rudy Gay","Alonzo Gee","Alonzo Gee","Alonzo Gee","Paul George","Taj Gibson","Manu Ginobili","Rudy Gobert","Drew Gooden","Archie Goodwin","Aaron Gordon","Ben Gordon","Drew Gordon","Eric Gordon","Marcin Gortat","Danny Granger","Jerami Grant","Danny Green","Draymond Green","Erick Green","Gerald Green","JaMychal Green","JaMychal Green","JaMychal Green","Jeff Green","Jeff Green","Jeff Green","Willie Green","Blake Griffin","Jorge Gutierrez","Jorge Gutierrez","Jorge Gutierrez","P.J. Hairston","Jordan Hamilton","Justin Hamilton","Justin Hamilton","Justin Hamilton","Tyler Hansbrough","Tim Hardaway","James Harden","Maurice Harkless","Devin Harris","Gary Harris","Joe Harris","Tobias Harris","Udonis Haslem","Spencer Hawes","Chuck Hayes","Gordon Hayward","Brendan Haywood","Gerald Henderson","Xavier Henry","John Henson","Roy Hibbert","J.J. Hickson","Nene Hilario","George Hill","Jordan Hill","Solomon Hill","Kirk Hinrich","Jrue Holiday","Justin Holiday","Ryan Hollins","Rodney Hood","Al Horford","Dwight Howard","Lester Hudson","Robbie Hummel","Kris Humphries","Serge Ibaka","Andre Iguodala","Ersan Ilyasova","Joe Ingles","Kyrie Irving","Jarrett Jack","Reggie Jackson","Reggie Jackson","Reggie Jackson","Bernard James","LeBron James","Al Jefferson","Cory Jefferson","Richard Jefferson","John Jenkins","Brandon Jennings","Jonas Jerebko","Jonas Jerebko","Jonas Jerebko","Grant Jerrett","Grant Jerrett","Grant Jerrett","Amir Johnson","Chris Johnson","Chris Johnson","Chris Johnson","Chris Johnson","James Johnson","Joe Johnson","Nick Johnson","Tyler Johnson","Wesley Johnson","Dahntay Jones","James Jones","Perry Jones","Terrence Jones","DeAndre Jordan","Jerome Jordan","Cory Joseph","Chris Kaman","Enes Kanter","Enes Kanter","Enes Kanter","Sergey Karasev","Ryan Kelly","Michael Kidd-Gilchrist","Sean Kilpatrick","Andrei Kirilenko","Alex Kirk","Brandon Knight","Brandon Knight","Brandon Knight","Kyle Korver","Kosta Koufos","Ognjen Kuzmic","Jeremy Lamb","Carl Landry","Shane Larkin","Joffrey Lauvergne","Zach LaVine","Ty Lawson","Ricky Ledo","Ricky Ledo","Ricky Ledo","Courtney Lee","David Lee","Malcolm Lee","Alex Len","Kawhi Leonard","Meyers Leonard","Jon Leuer","Damian Lillard","Jeremy Lin","Shaun Livingston","Brook Lopez","Robin Lopez","Kevin Love","Kyle Lowry","Kalin Lucas","John Lucas III","Shelvin Mack","Ian Mahinmi","Devyn Marble","Shawn Marion","Kendall Marshall","Cartier Martin","Kenyon Martin","Kevin Martin","Wesley Matthews","Jason Maxiell","O.J. Mayo","Luc Mbah a Moute","James Michael McAdoo","Ray McCallum","C.J. McCollum","K.J. McDaniels","K.J. McDaniels","K.J. McDaniels","Doug McDermott","Mitch McGary","JaVale McGee","JaVale McGee","JaVale McGee","Ben McLemore","Jerel McNeal","Josh McRoberts","Jodie Meeks","Gal Mekel","Khris Middleton","C.J. Miles","Andre Miller","Andre Miller","Andre Miller","Darius Miller","Mike Miller","Quincy Miller","Quincy Miller","Quincy Miller","Patrick Mills","Elijah Millsap","Paul Millsap","Nikola Mirotic","Nazr Mohammed","Greg Monroe","E'Twaun Moore","Eric Moreland","Darius Morris","Marcus Morris","Markieff Morris","Anthony Morrow","Donatas Motiejunas","Timofey Mozgov","Timofey Mozgov","Timofey Mozgov","Shabazz Muhammad","Toure' Murry","Toure' Murry","Toure' Murry","Mike Muscala","Shabazz Napier","Gary Neal","Gary Neal","Gary Neal","Jameer Nelson","Jameer Nelson","Jameer Nelson","Jameer Nelson","Andrew Nicholson","Joakim Noah","Nerlens Noel","Lucas Nogueira","Steve Novak","Steve Novak","Steve Novak","Dirk Nowitzki","Jusuf Nurkic","Johnny O'Bryant","Kyle O'Quinn","Victor Oladipo","Kelly Olynyk","Arinze Onuaku","Zaza Pachulia","Kostas Papanikolaou","Jannero Pargo","Jabari Parker","Tony Parker","Chandler Parsons","Patrick Patterson","Chris Paul","Adreian Payne","Adreian Payne","Adreian Payne","Elfrid Payton","Nikola Pekovic","Kendrick Perkins","Kendrick Perkins","Kendrick Perkins","Paul Pierce","Mason Plumlee","Miles Plumlee","Miles Plumlee","Miles Plumlee","Quincy Pondexter","Quincy Pondexter","Quincy Pondexter","Otto Porter","Dwight Powell","Dwight Powell","Dwight Powell","Phil Pressey","A.J. Price","A.J. Price","A.J. Price","A.J. Price","Ronnie Price","Pablo Prigioni","Pablo Prigioni","Pablo Prigioni","Tayshaun Prince","Tayshaun Prince","Tayshaun Prince","Tayshaun Prince","Miroslav Raduljica","Julius Randle","Shavlik Randolph","Shavlik Randolph","Shavlik Randolph","Zach Randolph","J.J. Redick","Glen Rice","Jason Richardson","Luke Ridnour","Austin Rivers","Austin Rivers","Austin Rivers","Andre Roberson","Brian Roberts","Nate Robinson","Nate Robinson","Nate Robinson","Thomas Robinson","Thomas Robinson","Thomas Robinson","Glenn Robinson III","Glenn Robinson III","Glenn Robinson III","Rajon Rondo","Rajon Rondo","Rajon Rondo","Derrick Rose","Terrence Ross","Ricky Rubio","Damjan Rudez","Brandon Rush","Robert Sacre","John Salmons","JaKarr Sampson","Larry Sanders","Dennis Schroder","Luis Scola","Mike Scott","Thabo Sefolosha","Kevin Seraphin","Ramon Sessions","Ramon Sessions","Ramon Sessions","Iman Shumpert","Iman Shumpert","Iman Shumpert","Alexey Shved","Alexey Shved","Alexey Shved","Alexey Shved","Henry Sims","Kyle Singler","Kyle Singler","Kyle Singler","Donald Sloan","Marcus Smart","Greg Smith","Ish Smith","Ish Smith","Ish Smith","J.R. Smith","J.R. Smith","J.R. Smith","Jason Smith","Josh Smith","Josh Smith","Josh Smith","Russ Smith","Russ Smith","Russ Smith","Tony Snell","Marreese Speights","Tiago Splitter","Nik Stauskas","Lance Stephenson","Greg Stiemsma","David Stockton","Jarnell Stokes","Amar'e Stoudemire","Amar'e Stoudemire","Amar'e Stoudemire","Rodney Stuckey","Jared Sullinger","Jeffery Taylor","Jeff Teague","Mirza Teletovic","Sebastian Telfair","Garrett Temple","Jason Terry","Isaiah Thomas","Isaiah Thomas","Isaiah Thomas","Lance Thomas","Lance Thomas","Lance Thomas","Malcolm Thomas","Tyrus Thomas","Hollis Thompson","Jason Thompson","Klay Thompson","Tristan Thompson","Marcus Thornton","Marcus Thornton","Marcus Thornton","Anthony Tolliver","Anthony Tolliver","Anthony Tolliver","P.J. Tucker","Ronny Turiaf","Hedo Turkoglu","Evan Turner","Ekpe Udoh","Beno Udrih","Jonas Valanciunas","Anderson Varejao","Greivis Vasquez","Charlie Villanueva","Noah Vonleh","Nikola Vucevic","Dwyane Wade","Dion Waiters","Dion Waiters","Dion Waiters","Henry Walker","Kemba Walker","John Wall","Gerald Wallace","T.J. Warren","C.J. Watson","David Wear","Travis Wear","Martell Webster","David West","Russell Westbrook","Hassan Whiteside","Shayne Whittington","Andrew Wiggins","C.J. Wilcox","Deron Williams","Derrick Williams","Elliot Williams","Elliot Williams","Elliot Williams","Lou Williams","Marvin Williams","Mo Williams","Mo Williams","Mo Williams","Reggie Williams","Shawne Williams","Shawne Williams","Shawne Williams","Jeff Withey","Nate Wolters","Nate Wolters","Nate Wolters","Brandan Wright","Brandan Wright","Brandan Wright","Brandan Wright","Dorell Wright","Tony Wroten","James Young","Nick Young","Thaddeus Young","Thaddeus Young","Thaddeus Young","Cody Zeller","Tyler Zeller"],["PF","SG","C","PF","SG","SG","SG","C","PF","C","PF","PF","SG","SF","PF","PF","PF","C","SG","SF","PF","SG","SF","C","PF","SF","PF","C","PG","PG","PG","PF","SF","PF","SG","PG","C","SF","SF","C","SG","SG","SG","PF","SF","PG","C","SG","SG","SF","SG","PF","PF","PG","C","C","C","C","C","PF","PG","PG","SG","SF","C","PF","PF","PF","C","SG","PF","SF","SF","SF","PG","SG","PG","SG","SG","SG","SF","SF","SF","SF","PG","SG","SF","SG","SF","PG","SG","SF","SG","PG","SG","PG","PG","PG","C","SF","SG","PG","PG","PG","SF","PG","C","SF","PG","SG","PF","SG","SG","SG","PG","SF","PG","PG","PG","PG","PF","PG","PF","SF","PG","C","SF","SG","SG","SF","SF","SF","PF","SG","PG","PG","C","SG","SG","SG","SG","SF","SF","SF","PF","PF","PF","PF","PF","PF","SG","SF","SF","SF","C","SG","SF","SG","PF","C","PG","PF","PG","SG","SG-PG","SG","PG","SG","SG","SG","PG","C","SG","PF","SF","SF","SF","SG","SG","SF","PG","PG","PG","SF","PF","SF","PG","C","PF","PG","PF","PG","SF","SG","SG","SG","PG","PG","PG","PG","C","PF","SF","PG","SF","PF","PF","PF","C","PF","SF","SF","SF","SF","SF","PF","SG","C","PF","SG","PF","SG","PF","SG","C","SF","SF","SG","PF","PG","SG","PF","PF","PF","SF","SF","SF","SG","PF","PG","PG","PG","SG","SF","C","C","C","PF","SG","SG","SF","PG","SG","SG","SF","PF","PF","C","SF","C","SG","SF","C","C","C","PF","PG","C","SF","SG","PG","SG","C","SG","C","C","SG","SF","PF","PF","SG","PF","SF","PG","PG","PG","PG","PG","C","SF","C","PF","SF","SG","PG","PF","PF","PF","PF","PF","PF","PF","SF","SF","SF","SF","PF","SG","SG","SG","SF","SF","SF","SF","PF","C","C","PG","C","C","C","C","SG","PF","SF","SG","SF","C","PG-SG","PG","SG","SG","C","C","SG","PF","PG","C","PG","PG","SG","SG","SG","SG","PF","SG","C","SF","C","PF","PG","PG","PG","C","C","PF","PG","PG","PG","PG","C","SG","SF","PG","SF","PF","SG","SG","PF","SG","PF","PF","PG","SG","SG","SG","SG","SF","PF","C","C","C","SG","PG","PF","SG","PG","SF","SG","PG","PG","PG","SF","SF","PF","PF","PF","PG","SG","PF","PF","C","PF","SG","PF","PG","PF","PF","SG","PF","C","C","C","SG","SG-PG","PG","SG","PF","PG","SG","SG","SG","PG","PG","PG","PG","PF","C","C","C","SF-PF","SF","PF","PF","C","PF","PF","SG","C","C","C","SF","PG","SF","PG","SF","PF","PG","PF","PF","PF","PG","C","C","C","C","SF","C","C","C","C","SF-SG","SG","SF","SF","PF","PF","PF","PG","PG","PG","PG","PG","PG","PG","PG","PG","SF","SF","SF","SF","C","PF","PF","PF","PF","PF","SG","SG","SG","PG","PG-SG","SG","PG","SG","PG","PG","PG","PG","PF","PF","PF","SG-SF","SG","SF","PG","PG","PG","PG","SF","PG","SF","SG","C","SF","SF","C","PG","PF","PF","SF","C","PG","PG","PG","SG","SG","SG","SG","SG","SG","SG","C","SF","SF","SF","PG","PG","PF","PG","PG","PG","SG","SG","SG","C","PF","PF","PF","PG","PG","PG","SF","PF","C","SG","SG","C","PG","PF","PF","PF","PF","PG","PF","SF","PG","PF","PG","SG","SG","PG","PG","PG","PF-SF","SF","PF","PF","PF","SG","PF","SG","PF","SG","SG","SG","PF","PF","PF","SF","C","SF","SG","PF","PG","C","C","PG","PF","PF","C","SG","SG","SG","SG","SF","PG","PG","SF","SF","PG","PF","SF","SF","PF","PG","C","PF","SG","SG","PG","PF","SG","SG","SG","SG","PF","PG","PG","PG","SF","SF","SF","SF","C","PG","PG","PG","PF","PF","PF","PF","SF","SG","SG","SG","PF","PF","PF","C","C"],[24,20,21,28,29,29,29,26,23,26,29,25,33,24,32,32,32,36,32,21,26,20,30,32,32,29,26,28,27,27,27,27,25,24,32,30,29,22,34,33,24,24,24,29,26,26,28,25,21,26,28,23,21,26,22,22,23,23,23,25,34,25,22,25,30,34,27,33,30,24,35,28,28,28,30,22,24,23,29,36,26,23,23,23,22,23,34,25,35,25,32,19,25,33,21,23,23,23,20,28,38,23,23,23,26,28,32,27,23,26,27,23,23,23,22,26,26,26,26,27,34,27,23,30,22,24,24,22,34,24,24,24,27,23,24,26,33,23,23,23,23,27,27,27,23,23,23,21,25,29,23,26,26,26,25,24,29,25,32,25,21,31,28,28,28,28,28,25,25,25,24,21,29,38,34,26,23,27,29,24,20,20,20,27,34,25,19,25,25,28,23,30,26,22,31,23,24,24,24,25,27,31,26,23,33,38,38,38,30,34,28,27,27,27,24,29,37,22,33,20,19,31,24,26,30,31,20,27,24,23,29,24,24,24,28,28,28,33,25,26,26,26,22,24,24,24,24,29,22,25,21,31,20,23,22,34,26,31,24,35,27,23,24,28,26,32,28,27,23,34,24,25,30,22,28,29,30,25,29,25,31,27,27,22,31,24,24,24,29,30,30,24,34,23,25,27,27,27,21,21,21,27,24,24,24,24,27,33,22,22,27,34,34,23,23,26,28,23,32,22,22,22,21,23,21,25,33,23,23,23,23,33,25,24,22,31,22,23,19,27,22,22,22,29,31,24,21,23,22,25,24,26,29,26,26,26,28,25,32,24,28,22,36,23,30,37,31,28,31,27,28,22,23,23,21,21,21,23,22,27,27,27,21,27,27,27,26,23,27,38,38,38,24,34,22,22,22,26,27,29,23,37,24,25,23,24,25,25,29,24,28,28,28,22,25,25,25,23,23,30,30,30,32,32,32,32,25,29,20,22,31,31,31,36,20,21,24,22,23,27,30,24,35,19,32,26,25,29,23,23,23,20,29,30,30,30,37,24,26,26,26,26,26,26,21,23,23,23,23,28,28,28,28,31,37,37,37,34,34,34,34,27,20,31,31,31,33,30,24,34,33,22,22,22,23,29,30,30,30,23,23,23,21,21,21,28,28,28,26,23,24,28,29,25,35,21,26,21,34,26,30,25,28,28,28,24,24,24,26,26,26,26,24,26,26,26,27,20,24,26,26,26,29,29,29,28,29,29,29,23,23,23,23,27,30,21,24,29,23,21,32,32,32,28,22,25,26,29,29,28,37,25,25,25,26,26,26,26,28,23,28,24,23,27,27,27,29,29,29,29,32,35,26,27,32,22,32,28,30,19,24,33,23,23,23,27,24,24,32,21,30,24,24,28,34,26,25,23,19,24,30,23,25,25,25,28,28,32,32,32,28,28,28,28,24,23,23,23,27,27,27,27,29,21,19,29,26,26,26,22,25],["NYK","MEM","OKC","MIN","TOT","DEN","POR","NOP","PHI","NYK","POR","IND","MEM","DAL","TOT","CLE","NYK","MIA","BRK","SAS","NOP","MIL","NYK","DET","ATL","HOU","DEN","NOP","TOT","DET","OKC","SAS","NOP","CHI","GSW","DAL","NYK","GSW","LAC","PHO","TOT","POR","DEN","BOS","POR","MIL","SAS","ATL","WAS","MIA","SAS","UTA","MIN","HOU","SAC","CHO","TOT","HOU","LAL","WAS","POR","PHO","LAL","BRK","GSW","SAS","UTA","LAL","MIA","BOS","ATL","TOT","MIN","HOU","CHI","LAL","MIN","BRK","MIA","LAL","MIN","TOT","LAC","PHO","UTA","UTA","DET","CHI","WAS","LAL","WAS","TOR","MEM","NYK","DET","TOT","HOU","PHI","HOU","ATL","MEM","TOT","PHI","MIL","SAC","MIA","DAL","DEN","CLE","UTA","BRK","TOT","UTA","DEN","LAL","POR","TOT","MIA","NOP","SAC","OKC","MEM","UTA","IND","UTA","SAC","PHI","POR","LAC","TOT","DAL","BOS","NOP","LAC","PHO","GSW","NYK","TOT","HOU","MIN","CHO","TOT","DET","BOS","TOT","PHI","BRK","NOP","LAL","LAC","MIA","TOT","SAS","ATL","ORL","CLE","MIA","TOR","SAS","MIN","DET","HOU","NOP","LAC","TOT","PHO","MIA","TOT","PHO","MIA","PHI","DET","MIL","SAS","CHI","OKC","NYK","LAL","DAL","MIA","TOT","PHO","MIL","UTA","SAC","NOP","UTA","GSW","DEN","LAC","UTA","DAL","TOR","ORL","DEN","DEN","TOT","PHI","POR","NOP","POR","ORL","DEN","NYK","HOU","TOT","BRK","MIN","MEM","CHI","SAC","TOT","DEN","POR","IND","CHI","SAS","UTA","WAS","PHO","ORL","ORL","PHI","NOP","WAS","MIA","PHI","SAS","GSW","DEN","PHO","TOT","SAS","MEM","TOT","BOS","MEM","ORL","LAC","TOT","BRK","MIL","CHO","LAC","TOT","MIA","MIN","TOR","NYK","HOU","ORL","DAL","DEN","CLE","ORL","MIA","LAC","TOR","UTA","CLE","CHO","LAL","MIL","IND","DEN","WAS","IND","LAL","IND","CHI","NOP","GSW","SAC","UTA","ATL","HOU","LAC","MIN","WAS","OKC","GSW","MIL","UTA","CLE","BRK","TOT","OKC","DET","DAL","CLE","CHO","BRK","DAL","ATL","DET","TOT","DET","BOS","TOT","OKC","UTA","TOR","TOT","PHI","UTA","MIL","TOR","BRK","HOU","MIA","LAL","LAC","CLE","OKC","HOU","LAC","BRK","SAS","POR","TOT","UTA","OKC","BRK","LAL","CHO","MIN","BRK","CLE","TOT","MIL","PHO","ATL","MEM","GSW","OKC","SAC","NYK","DEN","MIN","DEN","TOT","DAL","NYK","MEM","GSW","PHI","PHO","SAS","POR","MEM","POR","LAL","GSW","BRK","POR","CLE","TOR","MEM","DET","ATL","IND","ORL","CLE","MIL","DET","MIL","MIN","POR","CHO","MIL","PHI","GSW","SAC","POR","TOT","PHI","HOU","CHI","OKC","TOT","DEN","PHI","SAC","PHO","MIA","DET","NOP","MIL","IND","TOT","WAS","SAC","NOP","CLE","TOT","SAC","DET","SAS","UTA","ATL","CHI","CHI","DET","CHI","SAC","BRK","PHO","PHO","OKC","HOU","TOT","DEN","CLE","MIN","TOT","UTA","WAS","ATL","MIA","TOT","CHO","MIN","TOT","DAL","BOS","DEN","ORL","CHI","PHI","TOR","TOT","UTA","OKC","DAL","DEN","MIL","ORL","ORL","BOS","MIN","MIL","HOU","CHO","MIL","SAS","DAL","TOR","LAC","TOT","ATL","MIN","ORL","MIN","TOT","OKC","CLE","WAS","BRK","TOT","PHO","MIL","TOT","MEM","NOP","WAS","TOT","BOS","DAL","BOS","TOT","IND","CLE","PHO","LAL","TOT","NYK","HOU","TOT","MEM","BOS","DET","MIN","LAL","TOT","PHO","BOS","MEM","LAC","WAS","PHI","ORL","TOT","NOP","LAC","OKC","CHO","TOT","DEN","LAC","TOT","POR","PHI","TOT","MIN","PHI","TOT","BOS","DAL","CHI","TOR","MIN","IND","GSW","LAL","NOP","PHI","MIL","ATL","IND","ATL","ATL","WAS","TOT","SAC","WAS","TOT","NYK","CLE","TOT","PHI","HOU","NYK","PHI","TOT","DET","OKC","IND","BOS","DAL","TOT","OKC","PHI","TOT","NYK","CLE","NYK","TOT","DET","HOU","TOT","NOP","MEM","CHI","GSW","SAS","SAC","CHO","TOR","SAC","MEM","TOT","NYK","DAL","IND","BOS","CHO","ATL","BRK","OKC","WAS","HOU","TOT","PHO","BOS","TOT","OKC","NYK","PHI","MEM","PHI","SAC","GSW","CLE","TOT","BOS","PHO","TOT","PHO","DET","PHO","MIN","LAC","BOS","LAC","MEM","TOR","CLE","TOR","DAL","CHO","ORL","MIA","TOT","CLE","OKC","MIA","CHO","WAS","BOS","PHO","IND","SAC","NYK","WAS","IND","OKC","MIA","IND","MIN","LAC","BRK","SAC","TOT","UTA","NOP","TOR","CHO","TOT","MIN","CHO","SAS","TOT","MIA","DET","NOP","TOT","MIL","NOP","TOT","DAL","BOS","PHO","POR","PHI","BOS","LAL","TOT","MIN","BRK","CHO","BOS"]],"container":"<table class=\"display\">\n  <thead>\n    <tr>\n      <th>Rk</th>\n      <th>Player</th>\n      <th>Pos</th>\n      <th>Age</th>\n      <th>Tm</th>\n    </tr>\n  </thead>\n</table>","options":{"columnDefs":[{"className":"dt-right","targets":[0,3]}],"order":[],"autoWidth":false,"orderClasses":false},"callback":null,"filter":"none"},"evals":[]}</script><!--/html_preserve-->


ggvis
========================================================
<span class='pack'>ggvis</span> is a general purpose visualization package

  - the successor to <span class='pack'>ggplot2</span> to provide interactivity
  - <span class='pack'>ggplot2</span> is still great for static plots

Reminder of what's in the data:

```r
bballLong %>% head
```

```
         Player  Tm     vitalInfo value
1    Quincy Acy NYK fieldGoalPerc 0.459
2  Jordan Adams MEM fieldGoalPerc 0.407
3  Steven Adams OKC fieldGoalPerc 0.544
4   Jeff Adrien MIN fieldGoalPerc 0.432
5 Arron Afflalo TOT fieldGoalPerc 0.424
6 Arron Afflalo DEN fieldGoalPerc 0.428
```


ggvis
========================================================
<span class='pack'>ggvis</span> works by starting with a base, to which subsequent layers are added, with additional options if needed.


```r
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
```

ggvis
========================================================
<!--html_preserve--><div id="plot_id606827999-container" class="ggvis-output-container">
<div id="plot_id606827999" class="ggvis-output"></div>
<div class="plot-gear-icon">
<nav class="ggvis-control">
<a class="ggvis-dropdown-toggle" title="Controls" onclick="return false;"></a>
<ul class="ggvis-dropdown">
<li>
Renderer: 
<a id="plot_id606827999_renderer_svg" class="ggvis-renderer-button" onclick="return false;" data-plot-id="plot_id606827999" data-renderer="svg">SVG</a>
 | 
<a id="plot_id606827999_renderer_canvas" class="ggvis-renderer-button" onclick="return false;" data-plot-id="plot_id606827999" data-renderer="canvas">Canvas</a>
</li>
<li>
<a id="plot_id606827999_download" class="ggvis-download" data-plot-id="plot_id606827999">Download</a>
</li>
</ul>
</nav>
</div>
</div>
<script type="text/javascript">
var plot_id606827999_spec = {
  "data": [
    {
      "name": ".0_flat",
      "format": {
        "type": "csv",
        "parse": {
          "avg": "number"
        }
      },
      "values": "\"Tm\",\"avg\",\"vitalInfo\"\n\"ATL\",0.504437364669416,\"effectiveFG\"\n\"ATL\",0.4429375,\"fieldGoalPerc\"\n\"ATL\",0.51125,\"threePointPerc\"\n\"ATL\",0.535756461220838,\"trueShooting\"\n\"ATL\",0.4860625,\"twoPointPerc\"\n\"BOS\",0.490115224617262,\"effectiveFG\"\n\"BOS\",0.444727272727273,\"fieldGoalPerc\"\n\"BOS\",0.3,\"threePointPerc\"\n\"BOS\",0.516085800816697,\"trueShooting\"\n\"BOS\",0.481454545454545,\"twoPointPerc\"\n\"BRK\",0.448631113446842,\"effectiveFG\"\n\"BRK\",0.413736842105263,\"fieldGoalPerc\"\n\"BRK\",0.284736842105263,\"threePointPerc\"\n\"BRK\",0.4912462716915,\"trueShooting\"\n\"BRK\",0.451157894736842,\"twoPointPerc\"\n\"CHI\",0.464491719241866,\"effectiveFG\"\n\"CHI\",0.419,\"fieldGoalPerc\"\n\"CHI\",0.460714285714286,\"threePointPerc\"\n\"CHI\",0.504084007931405,\"trueShooting\"\n\"CHI\",0.448071428571429,\"twoPointPerc\"\n\"CHO\",0.467759427058292,\"effectiveFG\"\n\"CHO\",0.419529411764706,\"fieldGoalPerc\"\n\"CHO\",0.292941176470588,\"threePointPerc\"\n\"CHO\",0.506351948590065,\"trueShooting\"\n\"CHO\",0.442470588235294,\"twoPointPerc\"\n\"CLE\",0.466591955010133,\"effectiveFG\"\n\"CLE\",0.4144,\"fieldGoalPerc\"\n\"CLE\",0.413,\"threePointPerc\"\n\"CLE\",0.50135864062509,\"trueShooting\"\n\"CLE\",0.4432,\"twoPointPerc\"\n\"DAL\",0.498378392239502,\"effectiveFG\"\n\"DAL\",0.453157894736842,\"fieldGoalPerc\"\n\"DAL\",0.385263157894737,\"threePointPerc\"\n\"DAL\",0.535417473681989,\"trueShooting\"\n\"DAL\",0.484210526315789,\"twoPointPerc\"\n\"DEN\",0.483099737234545,\"effectiveFG\"\n\"DEN\",0.43135,\"fieldGoalPerc\"\n\"DEN\",0.33,\"threePointPerc\"\n\"DEN\",0.521394519132796,\"trueShooting\"\n\"DEN\",NA,\"twoPointPerc\"\n\"DET\",0.458096150147814,\"effectiveFG\"\n\"DET\",0.407,\"fieldGoalPerc\"\n\"DET\",0.3515,\"threePointPerc\"\n\"DET\",0.486802279480734,\"trueShooting\"\n\"DET\",0.4575,\"twoPointPerc\"\n\"GSW\",0.520372923574431,\"effectiveFG\"\n\"GSW\",0.482066666666667,\"fieldGoalPerc\"\n\"GSW\",0.588666666666667,\"threePointPerc\"\n\"GSW\",0.55040234783225,\"trueShooting\"\n\"GSW\",0.5128,\"twoPointPerc\"\n\"HOU\",0.482111303678833,\"effectiveFG\"\n\"HOU\",0.4208,\"fieldGoalPerc\"\n\"HOU\",0.4665,\"threePointPerc\"\n\"HOU\",0.500758923379487,\"trueShooting\"\n\"HOU\",0.4807,\"twoPointPerc\"\n\"IND\",0.489511732177657,\"effectiveFG\"\n\"IND\",0.4394375,\"fieldGoalPerc\"\n\"IND\",0.3825,\"threePointPerc\"\n\"IND\",0.52466605226745,\"trueShooting\"\n\"IND\",0.469,\"twoPointPerc\"\n\"LAC\",0.492070922375062,\"effectiveFG\"\n\"LAC\",0.42375,\"fieldGoalPerc\"\n\"LAC\",0.4135,\"threePointPerc\"\n\"LAC\",0.525031603333921,\"trueShooting\"\n\"LAC\",0.4525,\"twoPointPerc\"\n\"LAL\",0.449049237475976,\"effectiveFG\"\n\"LAL\",0.411388888888889,\"fieldGoalPerc\"\n\"LAL\",0.295555555555556,\"threePointPerc\"\n\"LAL\",0.489634210223653,\"trueShooting\"\n\"LAL\",0.422944444444444,\"twoPointPerc\"\n\"MEM\",0.486441979790746,\"effectiveFG\"\n\"MEM\",0.458157894736842,\"fieldGoalPerc\"\n\"MEM\",0.222631578947368,\"threePointPerc\"\n\"MEM\",0.526547694383781,\"trueShooting\"\n\"MEM\",0.487315789473684,\"twoPointPerc\"\n\"MIA\",0.487418025330873,\"effectiveFG\"\n\"MIA\",0.430857142857143,\"fieldGoalPerc\"\n\"MIA\",0.264761904761905,\"threePointPerc\"\n\"MIA\",0.517989833341031,\"trueShooting\"\n\"MIA\",NA,\"twoPointPerc\"\n\"MIL\",0.483037654478964,\"effectiveFG\"\n\"MIL\",0.4518,\"fieldGoalPerc\"\n\"MIL\",0.2725,\"threePointPerc\"\n\"MIL\",0.509651526186412,\"trueShooting\"\n\"MIL\",0.48615,\"twoPointPerc\"\n\"MIN\",NaN,\"effectiveFG\"\n\"MIN\",NA,\"fieldGoalPerc\"\n\"MIN\",0.1624,\"threePointPerc\"\n\"MIN\",NaN,\"trueShooting\"\n\"MIN\",NA,\"twoPointPerc\"\n\"NOP\",0.435112477898701,\"effectiveFG\"\n\"NOP\",0.392428571428571,\"fieldGoalPerc\"\n\"NOP\",0.279047619047619,\"threePointPerc\"\n\"NOP\",0.461117441978225,\"trueShooting\"\n\"NOP\",0.414666666666667,\"twoPointPerc\"\n\"NYK\",0.466923349817525,\"effectiveFG\"\n\"NYK\",0.42505,\"fieldGoalPerc\"\n\"NYK\",0.28,\"threePointPerc\"\n\"NYK\",0.502109035117234,\"trueShooting\"\n\"NYK\",0.4478,\"twoPointPerc\"\n\"OKC\",0.458202091372638,\"effectiveFG\"\n\"OKC\",0.414142857142857,\"fieldGoalPerc\"\n\"OKC\",0.300952380952381,\"threePointPerc\"\n\"OKC\",0.487662925136206,\"trueShooting\"\n\"OKC\",0.470380952380952,\"twoPointPerc\"\n\"ORL\",0.482933972400721,\"effectiveFG\"\n\"ORL\",0.439066666666667,\"fieldGoalPerc\"\n\"ORL\",0.369333333333333,\"threePointPerc\"\n\"ORL\",0.508318103414429,\"trueShooting\"\n\"ORL\",0.480933333333333,\"twoPointPerc\"\n\"PHI\",0.429512978032916,\"effectiveFG\"\n\"PHI\",0.38836,\"fieldGoalPerc\"\n\"PHI\",0.2768,\"threePointPerc\"\n\"PHI\",0.457368349158972,\"trueShooting\"\n\"PHI\",0.434,\"twoPointPerc\"\n\"PHO\",0.406316837439652,\"effectiveFG\"\n\"PHO\",0.369304347826087,\"fieldGoalPerc\"\n\"PHO\",0.303478260869565,\"threePointPerc\"\n\"PHO\",0.439395080947798,\"trueShooting\"\n\"PHO\",0.419130434782609,\"twoPointPerc\"\n\"POR\",0.50810052907908,\"effectiveFG\"\n\"POR\",0.446166666666667,\"fieldGoalPerc\"\n\"POR\",0.448333333333333,\"threePointPerc\"\n\"POR\",0.535552324904354,\"trueShooting\"\n\"POR\",0.473277777777778,\"twoPointPerc\"\n\"SAC\",0.474584625008908,\"effectiveFG\"\n\"SAC\",0.446473684210526,\"fieldGoalPerc\"\n\"SAC\",0.242631578947368,\"threePointPerc\"\n\"SAC\",0.518454279416516,\"trueShooting\"\n\"SAC\",0.465263157894737,\"twoPointPerc\"\n\"SAS\",0.507405625418447,\"effectiveFG\"\n\"SAS\",0.463,\"fieldGoalPerc\"\n\"SAS\",0.398235294117647,\"threePointPerc\"\n\"SAS\",0.53963110027729,\"trueShooting\"\n\"SAS\",0.511941176470588,\"twoPointPerc\"\n\"TOR\",0.508475566604701,\"effectiveFG\"\n\"TOR\",0.470066666666667,\"fieldGoalPerc\"\n\"TOR\",0.484,\"threePointPerc\"\n\"TOR\",0.540042894247373,\"trueShooting\"\n\"TOR\",0.4868,\"twoPointPerc\"\n\"TOT\",0.467976856136704,\"effectiveFG\"\n\"TOT\",0.419578947368421,\"fieldGoalPerc\"\n\"TOT\",0.36578947368421,\"threePointPerc\"\n\"TOT\",0.500767133322305,\"trueShooting\"\n\"TOT\",0.458631578947368,\"twoPointPerc\"\n\"UTA\",NaN,\"effectiveFG\"\n\"UTA\",NA,\"fieldGoalPerc\"\n\"UTA\",0.277272727272727,\"threePointPerc\"\n\"UTA\",NaN,\"trueShooting\"\n\"UTA\",NA,\"twoPointPerc\"\n\"WAS\",0.463050997093138,\"effectiveFG\"\n\"WAS\",0.4305,\"fieldGoalPerc\"\n\"WAS\",0.276111111111111,\"threePointPerc\"\n\"WAS\",0.508103206139549,\"trueShooting\"\n\"WAS\",0.454888888888889,\"twoPointPerc\""
    },
    {
      "name": ".0",
      "source": ".0_flat",
      "transform": [
        {
          "type": "treefacet",
          "keys": [
            "data.Tm"
          ]
        }
      ]
    },
    {
      "name": "scale/fill",
      "format": {
        "type": "csv",
        "parse": {}
      },
      "values": "\"domain\"\n\"effectiveFG\"\n\"fieldGoalPerc\"\n\"threePointPerc\"\n\"trueShooting\"\n\"twoPointPerc\""
    },
    {
      "name": "scale/x",
      "format": {
        "type": "csv",
        "parse": {}
      },
      "values": "\"domain\"\n\"ATL\"\n\"BOS\"\n\"BRK\"\n\"CHI\"\n\"CHO\"\n\"CLE\"\n\"DAL\"\n\"DEN\"\n\"DET\"\n\"GSW\"\n\"HOU\"\n\"IND\"\n\"LAC\"\n\"LAL\"\n\"MEM\"\n\"MIA\"\n\"MIL\"\n\"MIN\"\n\"NOP\"\n\"NYK\"\n\"OKC\"\n\"ORL\"\n\"PHI\"\n\"PHO\"\n\"POR\"\n\"SAC\"\n\"SAS\"\n\"TOR\"\n\"TOT\"\n\"UTA\"\n\"WAS\""
    },
    {
      "name": "scale/y",
      "format": {
        "type": "csv",
        "parse": {
          "domain": "number"
        }
      },
      "values": "\"domain\"\n0.141086666666667\n0.60998"
    }
  ],
  "scales": [
    {
      "name": "fill",
      "type": "ordinal",
      "domain": {
        "data": "scale/fill",
        "field": "data.domain"
      },
      "points": true,
      "sort": false,
      "range": "category10"
    },
    {
      "name": "x",
      "type": "ordinal",
      "domain": {
        "data": "scale/x",
        "field": "data.domain"
      },
      "points": true,
      "sort": false,
      "range": "width",
      "padding": 0.5
    },
    {
      "name": "y",
      "domain": {
        "data": "scale/y",
        "field": "data.domain"
      },
      "zero": false,
      "nice": false,
      "clamp": false,
      "range": "height"
    }
  ],
  "marks": [
    {
      "type": "group",
      "from": {
        "data": ".0"
      },
      "marks": [
        {
          "type": "symbol",
          "properties": {
            "update": {
              "size": {
                "value": 50
              },
              "x": {
                "scale": "x",
                "field": "data.Tm"
              },
              "y": {
                "scale": "y",
                "field": "data.avg"
              },
              "fill": {
                "scale": "fill",
                "field": "data.vitalInfo"
              }
            },
            "ggvis": {
              "data": {
                "value": ".0"
              }
            }
          }
        }
      ]
    }
  ],
  "legends": [
    {
      "orient": "right",
      "fill": "fill",
      "title": "vitalInfo"
    }
  ],
  "axes": [
    {
      "type": "x",
      "scale": "x",
      "orient": "bottom",
      "layer": "back",
      "grid": false,
      "properties": {
        "ticks": {
          "stroke": {
            "value": null
          }
        },
        "labels": {
          "angle": {
            "value": 90
          },
          "fill": {
            "value": "gray"
          }
        },
        "axis": {
          "stroke": {
            "value": null
          }
        }
      },
      "title": "Tm"
    },
    {
      "type": "y",
      "scale": "y",
      "orient": "left",
      "layer": "back",
      "grid": false,
      "title": "avg"
    }
  ],
  "padding": null,
  "ggvis_opts": {
    "keep_aspect": false,
    "resizable": true,
    "padding": {},
    "duration": 250,
    "renderer": "svg",
    "hover_duration": 0,
    "width": 504,
    "height": 504
  },
  "handlers": null
};
ggvis.getPlot("plot_id606827999").parseSpec(plot_id606827999_spec);
</script><!--/html_preserve--><!--html_preserve--><div id="htmlwidget-4427" style="width:700px;height:520px;" class="rbokeh"></div>
<script type="application/json" data-for="htmlwidget-4427">{"x":{"elementid":"79dbc49058ee692eed89ded4aa230910","modeltype":"Plot","modelid":"eb5681cba846ef12c419de83b80c6201","docid":"110e7f152d58208bb9914e6221ce2a59","docs_json":{"110e7f152d58208bb9914e6221ce2a59":{"version":"0.11.0","title":"Bokeh Figure","roots":{"root_ids":["eb5681cba846ef12c419de83b80c6201"],"references":[{"type":"Plot","id":"eb5681cba846ef12c419de83b80c6201","attributes":{"title":null,"id":"eb5681cba846ef12c419de83b80c6201","plot_width":690,"plot_height":510,"x_range":{"type":"FactorRange","id":"9e332b17ba14a96aee6522c06c7623d4"},"y_range":{"type":"Range1d","id":"ec37af933b8014037235a256b663185a"},"left":[{"type":"LinearAxis","id":"8c9f45c54c9bf4b8fded04880aa29c31"}],"below":[{"type":"CategoricalAxis","id":"364b803947dbd0849196e469d2ee385d"}],"right":[],"above":[],"renderers":[{"type":"GlyphRenderer","id":"35d611d47cb58a934ae02e424cea97f7"},{"type":"CategoricalAxis","id":"364b803947dbd0849196e469d2ee385d"},{"type":"Grid","id":"10619071f651bb144ed0eda0d4ad2d62"},{"type":"GlyphRenderer","id":"221e5a8e4c451ede57e8a6e6fa579d27"},{"type":"GlyphRenderer","id":"bc0a98d026c41cdc2b546993dc47861e"},{"type":"GlyphRenderer","id":"0abf46eabf2e4d245806cb0a74ef7e41"},{"type":"GlyphRenderer","id":"18228a45efb36c7d44b7705cb74d055f"},{"type":"GlyphRenderer","id":"079732a6dd91896aec84eda47f4c1ec6"},{"type":"Legend","id":"433764f7042167e64a92239478ba1e92"},{"type":"LinearAxis","id":"8c9f45c54c9bf4b8fded04880aa29c31"},{"type":"Grid","id":"55a71072d9d08181d475e5108104795c"}],"tools":[],"tool_events":[],"extra_y_ranges":{},"extra_x_ranges":{},"tags":[],"doc":null,"min_border_left":4,"min_border_right":4,"min_border_top":4,"min_border_bottom":4,"lod_threshold":null,"toolbar_location":null,"background_fill":"#E6E6E6","outline_line_color":"white"},"subtype":"Figure"},{"type":"ColumnDataSource","id":"10895a3d72a3ebda3a622f58efa801d6","attributes":{"id":"10895a3d72a3ebda3a622f58efa801d6","tags":[],"doc":null,"column_names":["x","y","line_color","fill_color"],"selected":[],"discrete_ranges":{},"cont_ranges":{},"data":{"x":["ATL","ATL","ATL","ATL","ATL","BOS","BOS","BOS","BOS","BOS","BRK","BRK","BRK","BRK","BRK","CHI","CHI","CHI","CHI","CHI","CHO","CHO","CHO","CHO","CHO","CLE","CLE","CLE","CLE","CLE","DAL","DAL","DAL","DAL","DAL","DEN","DEN","DEN","DEN","DEN","DET","DET","DET","DET","DET","GSW","GSW","GSW","GSW","GSW","HOU","HOU","HOU","HOU","HOU","IND","IND","IND","IND","IND","LAC","LAC","LAC","LAC","LAC","LAL","LAL","LAL","LAL","LAL","MEM","MEM","MEM","MEM","MEM","MIA","MIA","MIA","MIA","MIA","MIL","MIL","MIL","MIL","MIL","MIN","MIN","MIN","MIN","MIN","NOP","NOP","NOP","NOP","NOP","NYK","NYK","NYK","NYK","NYK","OKC","OKC","OKC","OKC","OKC","ORL","ORL","ORL","ORL","ORL","PHI","PHI","PHI","PHI","PHI","PHO","PHO","PHO","PHO","PHO","POR","POR","POR","POR","POR","SAC","SAC","SAC","SAC","SAC","SAS","SAS","SAS","SAS","SAS","TOR","TOR","TOR","TOR","TOR","TOT","TOT","TOT","TOT","TOT","UTA","UTA","UTA","UTA","UTA","WAS","WAS","WAS","WAS","WAS"],"y":[0.504437364669416,0.4429375,0.51125,0.535756461220838,0.4860625,0.490115224617262,0.444727272727273,0.3,0.516085800816697,0.481454545454545,0.448631113446842,0.413736842105263,0.284736842105263,0.4912462716915,0.451157894736842,0.464491719241867,0.419,0.460714285714286,0.504084007931405,0.448071428571429,0.467759427058292,0.419529411764706,0.292941176470588,0.506351948590065,0.442470588235294,0.466591955010133,0.4144,0.413,0.50135864062509,0.4432,0.498378392239502,0.453157894736842,0.385263157894737,0.535417473681989,0.484210526315789,0.483099737234545,0.43135,0.33,0.521394519132796,null,0.458096150147814,0.407,0.3515,0.486802279480734,0.4575,0.520372923574431,0.482066666666667,0.588666666666667,0.55040234783225,0.5128,0.482111303678833,0.4208,0.4665,0.500758923379487,0.4807,0.489511732177657,0.4394375,0.3825,0.52466605226745,0.469,0.492070922375062,0.42375,0.4135,0.525031603333921,0.4525,0.449049237475976,0.411388888888889,0.295555555555556,0.489634210223653,0.422944444444444,0.486441979790746,0.458157894736842,0.222631578947368,0.526547694383781,0.487315789473684,0.487418025330873,0.430857142857143,0.264761904761905,0.517989833341031,null,0.483037654478964,0.4518,0.2725,0.509651526186412,0.48615,null,null,0.1624,null,null,0.435112477898701,0.392428571428571,0.279047619047619,0.461117441978225,0.414666666666667,0.466923349817525,0.42505,0.28,0.502109035117234,0.4478,0.458202091372638,0.414142857142857,0.300952380952381,0.487662925136206,0.470380952380952,0.482933972400721,0.439066666666667,0.369333333333333,0.508318103414429,0.480933333333333,0.429512978032916,0.38836,0.2768,0.457368349158972,0.434,0.406316837439652,0.369304347826087,0.303478260869565,0.439395080947798,0.419130434782609,0.50810052907908,0.446166666666667,0.448333333333333,0.535552324904354,0.473277777777778,0.474584625008908,0.446473684210526,0.242631578947368,0.518454279416516,0.465263157894737,0.507405625418447,0.463,0.398235294117647,0.53963110027729,0.511941176470588,0.508475566604701,0.470066666666667,0.484,0.540042894247373,0.4868,0.467976856136704,0.419578947368421,0.365789473684211,0.500767133322305,0.458631578947368,null,null,0.277272727272727,null,null,0.463050997093138,0.4305,0.276111111111111,0.508103206139549,0.454888888888889],"line_color":["#F8766D","#A3A500","#00BF7D","#00B0F6","#E76BF3","#F8766D","#A3A500","#00BF7D","#00B0F6","#E76BF3","#F8766D","#A3A500","#00BF7D","#00B0F6","#E76BF3","#F8766D","#A3A500","#00BF7D","#00B0F6","#E76BF3","#F8766D","#A3A500","#00BF7D","#00B0F6","#E76BF3","#F8766D","#A3A500","#00BF7D","#00B0F6","#E76BF3","#F8766D","#A3A500","#00BF7D","#00B0F6","#E76BF3","#F8766D","#A3A500","#00BF7D","#00B0F6","#E76BF3","#F8766D","#A3A500","#00BF7D","#00B0F6","#E76BF3","#F8766D","#A3A500","#00BF7D","#00B0F6","#E76BF3","#F8766D","#A3A500","#00BF7D","#00B0F6","#E76BF3","#F8766D","#A3A500","#00BF7D","#00B0F6","#E76BF3","#F8766D","#A3A500","#00BF7D","#00B0F6","#E76BF3","#F8766D","#A3A500","#00BF7D","#00B0F6","#E76BF3","#F8766D","#A3A500","#00BF7D","#00B0F6","#E76BF3","#F8766D","#A3A500","#00BF7D","#00B0F6","#E76BF3","#F8766D","#A3A500","#00BF7D","#00B0F6","#E76BF3","#F8766D","#A3A500","#00BF7D","#00B0F6","#E76BF3","#F8766D","#A3A500","#00BF7D","#00B0F6","#E76BF3","#F8766D","#A3A500","#00BF7D","#00B0F6","#E76BF3","#F8766D","#A3A500","#00BF7D","#00B0F6","#E76BF3","#F8766D","#A3A500","#00BF7D","#00B0F6","#E76BF3","#F8766D","#A3A500","#00BF7D","#00B0F6","#E76BF3","#F8766D","#A3A500","#00BF7D","#00B0F6","#E76BF3","#F8766D","#A3A500","#00BF7D","#00B0F6","#E76BF3","#F8766D","#A3A500","#00BF7D","#00B0F6","#E76BF3","#F8766D","#A3A500","#00BF7D","#00B0F6","#E76BF3","#F8766D","#A3A500","#00BF7D","#00B0F6","#E76BF3","#F8766D","#A3A500","#00BF7D","#00B0F6","#E76BF3","#F8766D","#A3A500","#00BF7D","#00B0F6","#E76BF3","#F8766D","#A3A500","#00BF7D","#00B0F6","#E76BF3"],"fill_color":["#F8766D","#A3A500","#00BF7D","#00B0F6","#E76BF3","#F8766D","#A3A500","#00BF7D","#00B0F6","#E76BF3","#F8766D","#A3A500","#00BF7D","#00B0F6","#E76BF3","#F8766D","#A3A500","#00BF7D","#00B0F6","#E76BF3","#F8766D","#A3A500","#00BF7D","#00B0F6","#E76BF3","#F8766D","#A3A500","#00BF7D","#00B0F6","#E76BF3","#F8766D","#A3A500","#00BF7D","#00B0F6","#E76BF3","#F8766D","#A3A500","#00BF7D","#00B0F6","#E76BF3","#F8766D","#A3A500","#00BF7D","#00B0F6","#E76BF3","#F8766D","#A3A500","#00BF7D","#00B0F6","#E76BF3","#F8766D","#A3A500","#00BF7D","#00B0F6","#E76BF3","#F8766D","#A3A500","#00BF7D","#00B0F6","#E76BF3","#F8766D","#A3A500","#00BF7D","#00B0F6","#E76BF3","#F8766D","#A3A500","#00BF7D","#00B0F6","#E76BF3","#F8766D","#A3A500","#00BF7D","#00B0F6","#E76BF3","#F8766D","#A3A500","#00BF7D","#00B0F6","#E76BF3","#F8766D","#A3A500","#00BF7D","#00B0F6","#E76BF3","#F8766D","#A3A500","#00BF7D","#00B0F6","#E76BF3","#F8766D","#A3A500","#00BF7D","#00B0F6","#E76BF3","#F8766D","#A3A500","#00BF7D","#00B0F6","#E76BF3","#F8766D","#A3A500","#00BF7D","#00B0F6","#E76BF3","#F8766D","#A3A500","#00BF7D","#00B0F6","#E76BF3","#F8766D","#A3A500","#00BF7D","#00B0F6","#E76BF3","#F8766D","#A3A500","#00BF7D","#00B0F6","#E76BF3","#F8766D","#A3A500","#00BF7D","#00B0F6","#E76BF3","#F8766D","#A3A500","#00BF7D","#00B0F6","#E76BF3","#F8766D","#A3A500","#00BF7D","#00B0F6","#E76BF3","#F8766D","#A3A500","#00BF7D","#00B0F6","#E76BF3","#F8766D","#A3A500","#00BF7D","#00B0F6","#E76BF3","#F8766D","#A3A500","#00BF7D","#00B0F6","#E76BF3","#F8766D","#A3A500","#00BF7D","#00B0F6","#E76BF3"]}}},{"type":"Circle","id":"f1d3ff2d65229667904a9f9a4ba94af7","attributes":{"id":"f1d3ff2d65229667904a9f9a4ba94af7","tags":[],"doc":null,"size":{"units":"screen","value":10},"line_alpha":{"units":"data","value":1},"fill_alpha":{"units":"data","value":0.5},"x":{"units":"data","field":"x"},"y":{"units":"data","field":"y"},"line_color":{"units":"data","field":"line_color"},"fill_color":{"units":"data","field":"fill_color"}}},{"type":"Circle","id":"3bffe4ad048da60111f0811cfc8fba4c","attributes":{"id":"3bffe4ad048da60111f0811cfc8fba4c","tags":[],"doc":null,"size":{"units":"screen","value":10},"line_alpha":{"units":"data","value":1},"fill_alpha":{"units":"data","value":0.5},"x":{"units":"data","field":"x"},"y":{"units":"data","field":"y"},"line_color":{"units":"data","value":"#e1e1e1"},"fill_color":{"units":"data","value":"#e1e1e1"}}},{"type":"GlyphRenderer","id":"35d611d47cb58a934ae02e424cea97f7","attributes":{"id":"35d611d47cb58a934ae02e424cea97f7","tags":[],"doc":null,"selection_glyph":null,"nonselection_glyph":{"type":"Circle","id":"3bffe4ad048da60111f0811cfc8fba4c"},"server_data_source":null,"name":null,"data_source":{"type":"ColumnDataSource","id":"10895a3d72a3ebda3a622f58efa801d6"},"glyph":{"type":"Circle","id":"f1d3ff2d65229667904a9f9a4ba94af7"}}},{"type":"CategoricalAxis","id":"364b803947dbd0849196e469d2ee385d","attributes":{"id":"364b803947dbd0849196e469d2ee385d","tags":[],"doc":null,"plot":{"type":"Plot","id":"eb5681cba846ef12c419de83b80c6201","subtype":"Figure"},"axis_label":"Tm","formatter":{"type":"CategoricalTickFormatter","id":"eb1bf940a25928572e781a8d44cc4273"},"ticker":{"type":"CategoricalTicker","id":"fd1da1c628f503f618eee758794d936e"},"visible":true,"major_label_orientation":-0.785398163397448,"axis_line_color":"white","major_label_text_color":"#7F7F7F","major_tick_line_color":"#7F7F7F","minor_tick_line_alpha":{"units":"data","value":0},"num_minor_ticks":2}},{"type":"CategoricalTickFormatter","id":"eb1bf940a25928572e781a8d44cc4273","attributes":{"id":"eb1bf940a25928572e781a8d44cc4273","tags":[],"doc":null}},{"type":"CategoricalTicker","id":"fd1da1c628f503f618eee758794d936e","attributes":{"id":"fd1da1c628f503f618eee758794d936e","tags":[],"doc":null,"num_minor_ticks":2}},{"type":"Grid","id":"10619071f651bb144ed0eda0d4ad2d62","attributes":{"id":"10619071f651bb144ed0eda0d4ad2d62","tags":[],"doc":null,"dimension":0,"plot":{"type":"Plot","id":"eb5681cba846ef12c419de83b80c6201","subtype":"Figure"},"ticker":{"type":"CategoricalTicker","id":"fd1da1c628f503f618eee758794d936e"},"grid_line_color":"white","minor_grid_line_color":"white","minor_grid_line_alpha":{"units":"data","value":0.4}}},{"type":"ColumnDataSource","id":"11572515e032fa2e2ea3522fbb7ffe57","attributes":{"id":"11572515e032fa2e2ea3522fbb7ffe57","tags":[],"doc":null,"column_names":["x","y"],"selected":[],"discrete_ranges":{},"cont_ranges":{},"data":{"x":["",""],"y":[null,null]}}},{"type":"Circle","id":"42fd670057b54250039a66f192205a7f","attributes":{"id":"42fd670057b54250039a66f192205a7f","tags":[],"doc":null,"size":{"units":"screen","value":0},"line_alpha":{"units":"data","value":1},"fill_alpha":{"units":"data","value":0.5},"line_color":{"units":"data","value":"#F8766D"},"fill_color":{"units":"data","value":"#F8766D"},"x":{"units":"data","field":"x"},"y":{"units":"data","field":"y"}}},{"type":"Circle","id":"b8b7919878141bcc387857c195a81edb","attributes":{"id":"b8b7919878141bcc387857c195a81edb","tags":[],"doc":null,"size":{"units":"screen","value":0},"line_alpha":{"units":"data","value":1},"fill_alpha":{"units":"data","value":0.5},"line_color":{"units":"data","value":"#e1e1e1"},"fill_color":{"units":"data","value":"#e1e1e1"},"x":{"units":"data","field":"x"},"y":{"units":"data","field":"y"}}},{"type":"GlyphRenderer","id":"221e5a8e4c451ede57e8a6e6fa579d27","attributes":{"id":"221e5a8e4c451ede57e8a6e6fa579d27","tags":[],"doc":null,"selection_glyph":null,"nonselection_glyph":{"type":"Circle","id":"b8b7919878141bcc387857c195a81edb"},"server_data_source":null,"name":null,"data_source":{"type":"ColumnDataSource","id":"11572515e032fa2e2ea3522fbb7ffe57"},"glyph":{"type":"Circle","id":"42fd670057b54250039a66f192205a7f"}}},{"type":"Circle","id":"c4f365d88b935c99b96bb761e3d946dd","attributes":{"id":"c4f365d88b935c99b96bb761e3d946dd","tags":[],"doc":null,"size":{"units":"screen","value":0},"line_alpha":{"units":"data","value":1},"fill_alpha":{"units":"data","value":0.5},"line_color":{"units":"data","value":"#A3A500"},"fill_color":{"units":"data","value":"#A3A500"},"x":{"units":"data","field":"x"},"y":{"units":"data","field":"y"}}},{"type":"Circle","id":"928243b0eae6930f2f5afbea347df3d3","attributes":{"id":"928243b0eae6930f2f5afbea347df3d3","tags":[],"doc":null,"size":{"units":"screen","value":0},"line_alpha":{"units":"data","value":1},"fill_alpha":{"units":"data","value":0.5},"line_color":{"units":"data","value":"#e1e1e1"},"fill_color":{"units":"data","value":"#e1e1e1"},"x":{"units":"data","field":"x"},"y":{"units":"data","field":"y"}}},{"type":"GlyphRenderer","id":"bc0a98d026c41cdc2b546993dc47861e","attributes":{"id":"bc0a98d026c41cdc2b546993dc47861e","tags":[],"doc":null,"selection_glyph":null,"nonselection_glyph":{"type":"Circle","id":"928243b0eae6930f2f5afbea347df3d3"},"server_data_source":null,"name":null,"data_source":{"type":"ColumnDataSource","id":"11572515e032fa2e2ea3522fbb7ffe57"},"glyph":{"type":"Circle","id":"c4f365d88b935c99b96bb761e3d946dd"}}},{"type":"Circle","id":"b56f7218ab2cded19809d7c441b21ba3","attributes":{"id":"b56f7218ab2cded19809d7c441b21ba3","tags":[],"doc":null,"size":{"units":"screen","value":0},"line_alpha":{"units":"data","value":1},"fill_alpha":{"units":"data","value":0.5},"line_color":{"units":"data","value":"#00BF7D"},"fill_color":{"units":"data","value":"#00BF7D"},"x":{"units":"data","field":"x"},"y":{"units":"data","field":"y"}}},{"type":"Circle","id":"c4f019cfe9b9cfa8cf6c680818a7d84c","attributes":{"id":"c4f019cfe9b9cfa8cf6c680818a7d84c","tags":[],"doc":null,"size":{"units":"screen","value":0},"line_alpha":{"units":"data","value":1},"fill_alpha":{"units":"data","value":0.5},"line_color":{"units":"data","value":"#e1e1e1"},"fill_color":{"units":"data","value":"#e1e1e1"},"x":{"units":"data","field":"x"},"y":{"units":"data","field":"y"}}},{"type":"GlyphRenderer","id":"0abf46eabf2e4d245806cb0a74ef7e41","attributes":{"id":"0abf46eabf2e4d245806cb0a74ef7e41","tags":[],"doc":null,"selection_glyph":null,"nonselection_glyph":{"type":"Circle","id":"c4f019cfe9b9cfa8cf6c680818a7d84c"},"server_data_source":null,"name":null,"data_source":{"type":"ColumnDataSource","id":"11572515e032fa2e2ea3522fbb7ffe57"},"glyph":{"type":"Circle","id":"b56f7218ab2cded19809d7c441b21ba3"}}},{"type":"Circle","id":"6574cad925c94ad0b688ef96bbeea0ce","attributes":{"id":"6574cad925c94ad0b688ef96bbeea0ce","tags":[],"doc":null,"size":{"units":"screen","value":0},"line_alpha":{"units":"data","value":1},"fill_alpha":{"units":"data","value":0.5},"line_color":{"units":"data","value":"#00B0F6"},"fill_color":{"units":"data","value":"#00B0F6"},"x":{"units":"data","field":"x"},"y":{"units":"data","field":"y"}}},{"type":"Circle","id":"8deddf7935368a982d819c9a694c4f7b","attributes":{"id":"8deddf7935368a982d819c9a694c4f7b","tags":[],"doc":null,"size":{"units":"screen","value":0},"line_alpha":{"units":"data","value":1},"fill_alpha":{"units":"data","value":0.5},"line_color":{"units":"data","value":"#e1e1e1"},"fill_color":{"units":"data","value":"#e1e1e1"},"x":{"units":"data","field":"x"},"y":{"units":"data","field":"y"}}},{"type":"GlyphRenderer","id":"18228a45efb36c7d44b7705cb74d055f","attributes":{"id":"18228a45efb36c7d44b7705cb74d055f","tags":[],"doc":null,"selection_glyph":null,"nonselection_glyph":{"type":"Circle","id":"8deddf7935368a982d819c9a694c4f7b"},"server_data_source":null,"name":null,"data_source":{"type":"ColumnDataSource","id":"11572515e032fa2e2ea3522fbb7ffe57"},"glyph":{"type":"Circle","id":"6574cad925c94ad0b688ef96bbeea0ce"}}},{"type":"Circle","id":"829ed9239c6feb40642c534e27bb95ba","attributes":{"id":"829ed9239c6feb40642c534e27bb95ba","tags":[],"doc":null,"size":{"units":"screen","value":0},"line_alpha":{"units":"data","value":1},"fill_alpha":{"units":"data","value":0.5},"line_color":{"units":"data","value":"#E76BF3"},"fill_color":{"units":"data","value":"#E76BF3"},"x":{"units":"data","field":"x"},"y":{"units":"data","field":"y"}}},{"type":"Circle","id":"71c6fd5c73bca5078c1f944432f02111","attributes":{"id":"71c6fd5c73bca5078c1f944432f02111","tags":[],"doc":null,"size":{"units":"screen","value":0},"line_alpha":{"units":"data","value":1},"fill_alpha":{"units":"data","value":0.5},"line_color":{"units":"data","value":"#e1e1e1"},"fill_color":{"units":"data","value":"#e1e1e1"},"x":{"units":"data","field":"x"},"y":{"units":"data","field":"y"}}},{"type":"GlyphRenderer","id":"079732a6dd91896aec84eda47f4c1ec6","attributes":{"id":"079732a6dd91896aec84eda47f4c1ec6","tags":[],"doc":null,"selection_glyph":null,"nonselection_glyph":{"type":"Circle","id":"71c6fd5c73bca5078c1f944432f02111"},"server_data_source":null,"name":null,"data_source":{"type":"ColumnDataSource","id":"11572515e032fa2e2ea3522fbb7ffe57"},"glyph":{"type":"Circle","id":"829ed9239c6feb40642c534e27bb95ba"}}},{"type":"Legend","id":"433764f7042167e64a92239478ba1e92","attributes":{"id":"433764f7042167e64a92239478ba1e92","tags":[],"doc":null,"plot":{"type":"Plot","id":"eb5681cba846ef12c419de83b80c6201","subtype":"Figure"},"legends":[["vitalInfo",[]],[" effectiveFG",[{"type":"GlyphRenderer","id":"221e5a8e4c451ede57e8a6e6fa579d27"}]],[" fieldGoalPerc",[{"type":"GlyphRenderer","id":"bc0a98d026c41cdc2b546993dc47861e"}]],[" threePointPerc",[{"type":"GlyphRenderer","id":"0abf46eabf2e4d245806cb0a74ef7e41"}]],[" trueShooting",[{"type":"GlyphRenderer","id":"18228a45efb36c7d44b7705cb74d055f"}]],[" twoPointPerc",[{"type":"GlyphRenderer","id":"079732a6dd91896aec84eda47f4c1ec6"}]]],"location":"top_right"}},{"type":"FactorRange","id":"9e332b17ba14a96aee6522c06c7623d4","attributes":{"id":"9e332b17ba14a96aee6522c06c7623d4","tags":[],"doc":null,"factors":["ATL","BOS","BRK","CHI","CHO","CLE","DAL","DEN","DET","GSW","HOU","IND","LAC","LAL","MEM","MIA","MIL","MIN","NOP","NYK","OKC","ORL","PHI","PHO","POR","SAC","SAS","TOR","TOT","UTA","WAS"]}},{"type":"Range1d","id":"ec37af933b8014037235a256b663185a","attributes":{"id":"ec37af933b8014037235a256b663185a","tags":[],"doc":null,"start":0.132561333333333,"end":0.618505333333333}},{"type":"LinearAxis","id":"8c9f45c54c9bf4b8fded04880aa29c31","attributes":{"id":"8c9f45c54c9bf4b8fded04880aa29c31","tags":[],"doc":null,"plot":{"type":"Plot","id":"eb5681cba846ef12c419de83b80c6201","subtype":"Figure"},"axis_label":"avg","formatter":{"type":"BasicTickFormatter","id":"c30f37e0aa7b4b794dd835ab78d37c23"},"ticker":{"type":"BasicTicker","id":"701aaf3e858e3f74009fbeb5de680faf"},"visible":true,"axis_line_color":"white","major_label_text_color":"#7F7F7F","major_tick_line_color":"#7F7F7F","minor_tick_line_alpha":{"units":"data","value":0},"num_minor_ticks":2}},{"type":"BasicTickFormatter","id":"c30f37e0aa7b4b794dd835ab78d37c23","attributes":{"id":"c30f37e0aa7b4b794dd835ab78d37c23","tags":[],"doc":null}},{"type":"BasicTicker","id":"701aaf3e858e3f74009fbeb5de680faf","attributes":{"id":"701aaf3e858e3f74009fbeb5de680faf","tags":[],"doc":null,"num_minor_ticks":2}},{"type":"Grid","id":"55a71072d9d08181d475e5108104795c","attributes":{"id":"55a71072d9d08181d475e5108104795c","tags":[],"doc":null,"dimension":1,"plot":{"type":"Plot","id":"eb5681cba846ef12c419de83b80c6201","subtype":"Figure"},"ticker":{"type":"BasicTicker","id":"701aaf3e858e3f74009fbeb5de680faf"},"grid_line_color":"white","minor_grid_line_color":"white","minor_grid_line_alpha":{"units":"data","value":0.4}}}]}}},"padding":{"type":"figure","y_pad":10,"x_pad":10}},"evals":[]}</script><!--/html_preserve-->


Your turn
========================================================
type:prompt

Your turn
========================================================
Using ggvis and the data set mtcars, we'll create a grouped scatterplot without creating any new objects.

<div style='font-size:18pt'>
1. Make a new variable that called 'amFactor' that is just a factor of the original am, with labels 'auto' and 'manual'
    - factor(am, labels=c('auto', 'manual'))   (<span class='func'>mutate</span> )
2. Create your base ggvis (<span class='func'>ggvis</span> )
2. Group by the transmission factor variable
    - group_by(amFactor)
3. Make a scatterplot (<span class='func'>layer_points</span> ) of horsepower (hp) and miles per gallon (mpg) 
    - fill =~ amFactor 
4. add (<span class='func'>layer_smooths</span> )
    - stroke =~ amFactor
</div>

Example
========================================================

```r
mtcars %>% 
  mutate(amFactor = factor(am, labels=c('auto', 'manual'))) %>% 
  group_by(amFactor) %>%
  ggvis(x=~wt, y=~mpg) %>%
  layer_points(fill=~amFactor) %>%
  layer_smooths(stroke=~amFactor)
```

<!--html_preserve--><div id="plot_id958820192-container" class="ggvis-output-container">
<div id="plot_id958820192" class="ggvis-output"></div>
<div class="plot-gear-icon">
<nav class="ggvis-control">
<a class="ggvis-dropdown-toggle" title="Controls" onclick="return false;"></a>
<ul class="ggvis-dropdown">
<li>
Renderer: 
<a id="plot_id958820192_renderer_svg" class="ggvis-renderer-button" onclick="return false;" data-plot-id="plot_id958820192" data-renderer="svg">SVG</a>
 | 
<a id="plot_id958820192_renderer_canvas" class="ggvis-renderer-button" onclick="return false;" data-plot-id="plot_id958820192" data-renderer="canvas">Canvas</a>
</li>
<li>
<a id="plot_id958820192_download" class="ggvis-download" data-plot-id="plot_id958820192">Download</a>
</li>
</ul>
</nav>
</div>
</div>
<script type="text/javascript">
var plot_id958820192_spec = {
  "data": [
    {
      "name": ".0_flat",
      "format": {
        "type": "csv",
        "parse": {
          "wt": "number",
          "mpg": "number"
        }
      },
      "values": "\"wt\",\"mpg\",\"amFactor\"\n3.215,21.4,\"auto\"\n3.44,18.7,\"auto\"\n3.46,18.1,\"auto\"\n3.57,14.3,\"auto\"\n3.19,24.4,\"auto\"\n3.15,22.8,\"auto\"\n3.44,19.2,\"auto\"\n3.44,17.8,\"auto\"\n4.07,16.4,\"auto\"\n3.73,17.3,\"auto\"\n3.78,15.2,\"auto\"\n5.25,10.4,\"auto\"\n5.424,10.4,\"auto\"\n5.345,14.7,\"auto\"\n2.465,21.5,\"auto\"\n3.52,15.5,\"auto\"\n3.435,15.2,\"auto\"\n3.84,13.3,\"auto\"\n3.845,19.2,\"auto\"\n2.62,21,\"manual\"\n2.875,21,\"manual\"\n2.32,22.8,\"manual\"\n2.2,32.4,\"manual\"\n1.615,30.4,\"manual\"\n1.835,33.9,\"manual\"\n1.935,27.3,\"manual\"\n2.14,26,\"manual\"\n1.513,30.4,\"manual\"\n3.17,15.8,\"manual\"\n2.77,19.7,\"manual\"\n3.57,15,\"manual\"\n2.78,21.4,\"manual\""
    },
    {
      "name": ".0",
      "source": ".0_flat",
      "transform": [
        {
          "type": "treefacet",
          "keys": [
            "data.amFactor"
          ]
        }
      ]
    },
    {
      "name": ".0/model_prediction1_flat",
      "format": {
        "type": "csv",
        "parse": {
          "pred_": "number",
          "resp_": "number"
        }
      },
      "values": "\"pred_\",\"resp_\",\"amFactor\"\n2.465,21.5259708761917,\"auto\"\n2.50245569620253,22.1797924541708,\"auto\"\n2.53991139240506,22.820613414013,\"auto\"\n2.57736708860759,23.4394318150821,\"auto\"\n2.61482278481013,24.0272457167421,\"auto\"\n2.65227848101266,24.5750531783568,\"auto\"\n2.68973417721519,25.0738522592904,\"auto\"\n2.72718987341772,25.5146410189066,\"auto\"\n2.76464556962025,25.8884175165694,\"auto\"\n2.80210126582278,26.1861798116428,\"auto\"\n2.83955696202532,26.3989259634907,\"auto\"\n2.87701265822785,26.5176540314771,\"auto\"\n2.91446835443038,26.5333620749658,\"auto\"\n2.95192405063291,26.4370481533208,\"auto\"\n2.98937974683544,26.219710325906,\"auto\"\n3.02683544303797,25.8723466520855,\"auto\"\n3.06429113924051,25.385955191223,\"auto\"\n3.10174683544304,24.7515340026826,\"auto\"\n3.13920253164557,23.9600811458282,\"auto\"\n3.1766582278481,23.0589628098409,\"auto\"\n3.21411392405063,22.1558816263762,\"auto\"\n3.25156962025316,21.2648213045862,\"auto\"\n3.2890253164557,20.4013358208311,\"auto\"\n3.32648101265823,19.5779474075833,\"auto\"\n3.36393670886076,18.8071782973153,\"auto\"\n3.40139240506329,18.1015507224994,\"auto\"\n3.43884810126582,17.4698836337952,\"auto\"\n3.47630379746835,16.8719280807581,\"auto\"\n3.51375949367089,16.3242556558887,\"auto\"\n3.55121518987342,15.947916963999,\"auto\"\n3.58867088607595,15.7677633216254,\"auto\"\n3.62612658227848,15.7228597580125,\"auto\"\n3.66358227848101,15.7512693395476,\"auto\"\n3.70103797468354,15.791055132618,\"auto\"\n3.73849367088608,15.7874392476776,\"auto\"\n3.77594936708861,15.8191862367278,\"auto\"\n3.81340506329114,15.8484611768538,\"auto\"\n3.85086075949367,15.9024937505066,\"auto\"\n3.8883164556962,15.9437341422714,\"auto\"\n3.92577215189873,15.9710381160921,\"auto\"\n3.96322784810127,15.9849294744464,\"auto\"\n4.0006835443038,15.9859320198118,\"auto\"\n4.03813924050633,15.9745695546661,\"auto\"\n4.07559493670886,15.951365881487,\"auto\"\n4.11305063291139,15.916844802752,\"auto\"\n4.15050632911392,15.8715301209389,\"auto\"\n4.18796202531646,15.8159456385254,\"auto\"\n4.22541772151899,15.7506151579891,\"auto\"\n4.26287341772152,15.6760624818076,\"auto\"\n4.30032911392405,15.5928114124587,\"auto\"\n4.33778481012658,15.5013857524201,\"auto\"\n4.37524050632911,15.4023093041693,\"auto\"\n4.41269620253165,15.296105870184,\"auto\"\n4.45015189873418,15.183299252942,\"auto\"\n4.48760759493671,15.0644132549209,\"auto\"\n4.52506329113924,14.9399716785983,\"auto\"\n4.56251898734177,14.8104983264519,\"auto\"\n4.5999746835443,14.6765170009595,\"auto\"\n4.63743037974684,14.5385515045986,\"auto\"\n4.67488607594937,14.3971256398469,\"auto\"\n4.7123417721519,14.2527632091821,\"auto\"\n4.74979746835443,14.1059880150819,\"auto\"\n4.78725316455696,13.957323860024,\"auto\"\n4.82470886075949,13.8072945464859,\"auto\"\n4.86216455696203,13.6564238769454,\"auto\"\n4.89962025316456,13.5052356538802,\"auto\"\n4.93707594936709,13.3542536797679,\"auto\"\n4.97453164556962,13.2040017570861,\"auto\"\n5.01198734177215,13.0550036883126,\"auto\"\n5.04944303797468,12.907783275925,\"auto\"\n5.08689873417722,12.762864322401,\"auto\"\n5.12435443037975,12.6207706302182,\"auto\"\n5.16181012658228,12.4820260018544,\"auto\"\n5.19926582278481,12.3471542397871,\"auto\"\n5.23672151898734,12.2166791464941,\"auto\"\n5.27417721518987,12.0903645293516,\"auto\"\n5.31163291139241,11.9660291847624,\"auto\"\n5.34908860759494,11.8438675121068,\"auto\"\n5.38654430379747,11.724301010319,\"auto\"\n5.424,11.6077511783331,\"auto\"\n1.513,30.412551978311,\"manual\"\n1.53903797468354,30.5739746335954,\"manual\"\n1.56507594936709,30.7137830266673,\"manual\"\n1.59111392405063,30.8313190880187,\"manual\"\n1.61715189873418,30.9259253466877,\"manual\"\n1.64318987341772,30.9972644004291,\"manual\"\n1.66922784810127,31.0457190232159,\"manual\"\n1.69526582278481,31.0717560123671,\"manual\"\n1.72130379746835,31.0758421652015,\"manual\"\n1.7473417721519,31.0584442790382,\"manual\"\n1.77337974683544,31.020029151196,\"manual\"\n1.79941772151899,30.9610635789939,\"manual\"\n1.82545569620253,30.8820143597507,\"manual\"\n1.85149367088608,30.7827122861922,\"manual\"\n1.87753164556962,30.6614929460222,\"manual\"\n1.90356962025316,30.5190276353507,\"manual\"\n1.92960759493671,30.3562101808713,\"manual\"\n1.95564556962025,30.164444572191,\"manual\"\n1.9816835443038,29.9283808953885,\"manual\"\n2.00772151898734,29.6553227058781,\"manual\"\n2.03375949367089,29.3532717643515,\"manual\"\n2.05979746835443,29.0302298315009,\"manual\"\n2.08583544303797,28.694198668018,\"manual\"\n2.11187341772152,28.3531800345949,\"manual\"\n2.13791139240506,28.0151756919234,\"manual\"\n2.16394936708861,27.6611873607086,\"manual\"\n2.18998734177215,27.2894109031857,\"manual\"\n2.2160253164557,26.9483617252785,\"manual\"\n2.24206329113924,26.6465062742048,\"manual\"\n2.26810126582278,26.3627498777359,\"manual\"\n2.29413924050633,26.0753174537845,\"manual\"\n2.32017721518987,25.7624341842455,\"manual\"\n2.34621518987342,25.4130671474375,\"manual\"\n2.37225316455696,25.0356260517256,\"manual\"\n2.39829113924051,24.6377319717605,\"manual\"\n2.42432911392405,24.2270059821925,\"manual\"\n2.4503670886076,23.8110691576723,\"manual\"\n2.47640506329114,23.3975425728504,\"manual\"\n2.50244303797468,22.9940473023772,\"manual\"\n2.52848101265823,22.6082044209033,\"manual\"\n2.55451898734177,22.2476350030793,\"manual\"\n2.58055696202532,21.9199601235555,\"manual\"\n2.60659493670886,21.6328008569826,\"manual\"\n2.63263291139241,21.3953050331298,\"manual\"\n2.65867088607595,21.2125281236311,\"manual\"\n2.68470886075949,21.0618515551701,\"manual\"\n2.71074683544304,20.9174606488594,\"manual\"\n2.73678481012658,20.7535407258116,\"manual\"\n2.76282278481013,20.5442771071394,\"manual\"\n2.78886075949367,20.3157740034799,\"manual\"\n2.81489873417722,20.16490580258,\"manual\"\n2.84093670886076,20.0618560204079,\"manual\"\n2.8669746835443,19.9133239456073,\"manual\"\n2.89301265822785,19.671425447586,\"manual\"\n2.91905063291139,19.4231192938683,\"manual\"\n2.94508860759494,19.1767314285798,\"manual\"\n2.97112658227848,18.9330623227329,\"manual\"\n2.99716455696203,18.6929124473396,\"manual\"\n3.02320253164557,18.4570822734121,\"manual\"\n3.04924050632911,18.2263722719625,\"manual\"\n3.07527848101266,18.0015829140029,\"manual\"\n3.1013164556962,17.7835146705456,\"manual\"\n3.12735443037975,17.5729680126026,\"manual\"\n3.15339240506329,17.370743411186,\"manual\"\n3.17943037974684,17.1770351489811,\"manual\"\n3.20546835443038,16.9858169059939,\"manual\"\n3.23150632911392,16.7957968866162,\"manual\"\n3.25754430379747,16.6075478786438,\"manual\"\n3.28358227848101,16.4216426698726,\"manual\"\n3.30962025316456,16.2386540480987,\"manual\"\n3.3356582278481,16.0591548011179,\"manual\"\n3.36169620253165,15.8837177167261,\"manual\"\n3.38773417721519,15.7129155827193,\"manual\"\n3.41377215189873,15.5473211868934,\"manual\"\n3.43981012658228,15.3875073170443,\"manual\"\n3.46584810126582,15.234046760968,\"manual\"\n3.49188607594937,15.0875123064603,\"manual\"\n3.51792405063291,14.9484767413173,\"manual\"\n3.54396202531646,14.8175128533347,\"manual\"\n3.57,14.6951934303087,\"manual\""
    },
    {
      "name": ".0/model_prediction1",
      "source": ".0/model_prediction1_flat",
      "transform": [
        {
          "type": "treefacet",
          "keys": [
            "data.amFactor"
          ]
        }
      ]
    },
    {
      "name": "scale/fill",
      "format": {
        "type": "csv",
        "parse": {}
      },
      "values": "\"domain\"\n\"auto\"\n\"manual\""
    },
    {
      "name": "scale/stroke",
      "format": {
        "type": "csv",
        "parse": {}
      },
      "values": "\"domain\"\n\"auto\"\n\"manual\""
    },
    {
      "name": "scale/x",
      "format": {
        "type": "csv",
        "parse": {
          "domain": "number"
        }
      },
      "values": "\"domain\"\n1.31745\n5.61955"
    },
    {
      "name": "scale/y",
      "format": {
        "type": "csv",
        "parse": {
          "domain": "number"
        }
      },
      "values": "\"domain\"\n9.225\n35.075"
    }
  ],
  "scales": [
    {
      "name": "fill",
      "type": "ordinal",
      "domain": {
        "data": "scale/fill",
        "field": "data.domain"
      },
      "points": true,
      "sort": false,
      "range": "category10"
    },
    {
      "name": "stroke",
      "type": "ordinal",
      "domain": {
        "data": "scale/stroke",
        "field": "data.domain"
      },
      "points": true,
      "sort": false,
      "range": "category10"
    },
    {
      "name": "x",
      "domain": {
        "data": "scale/x",
        "field": "data.domain"
      },
      "zero": false,
      "nice": false,
      "clamp": false,
      "range": "width"
    },
    {
      "name": "y",
      "domain": {
        "data": "scale/y",
        "field": "data.domain"
      },
      "zero": false,
      "nice": false,
      "clamp": false,
      "range": "height"
    }
  ],
  "marks": [
    {
      "type": "group",
      "from": {
        "data": ".0"
      },
      "marks": [
        {
          "type": "symbol",
          "properties": {
            "update": {
              "size": {
                "value": 50
              },
              "x": {
                "scale": "x",
                "field": "data.wt"
              },
              "y": {
                "scale": "y",
                "field": "data.mpg"
              },
              "fill": {
                "scale": "fill",
                "field": "data.amFactor"
              }
            },
            "ggvis": {
              "data": {
                "value": ".0"
              }
            }
          }
        }
      ]
    },
    {
      "type": "group",
      "from": {
        "data": ".0/model_prediction1"
      },
      "marks": [
        {
          "type": "line",
          "properties": {
            "update": {
              "strokeWidth": {
                "value": 2
              },
              "x": {
                "scale": "x",
                "field": "data.pred_"
              },
              "y": {
                "scale": "y",
                "field": "data.resp_"
              },
              "stroke": {
                "scale": "stroke",
                "field": "data.amFactor"
              },
              "fill": {
                "value": "transparent"
              }
            },
            "ggvis": {
              "data": {
                "value": ".0/model_prediction1"
              }
            }
          }
        }
      ]
    }
  ],
  "legends": [
    {
      "orient": "right",
      "fill": "fill",
      "title": "amFactor"
    },
    {
      "orient": "right",
      "stroke": "stroke",
      "title": "amFactor"
    }
  ],
  "axes": [
    {
      "type": "x",
      "scale": "x",
      "orient": "bottom",
      "layer": "back",
      "grid": true,
      "title": "wt"
    },
    {
      "type": "y",
      "scale": "y",
      "orient": "left",
      "layer": "back",
      "grid": true,
      "title": "mpg"
    }
  ],
  "padding": null,
  "ggvis_opts": {
    "keep_aspect": false,
    "resizable": true,
    "padding": {},
    "duration": 250,
    "renderer": "svg",
    "hover_duration": 0,
    "width": 432,
    "height": 252
  },
  "handlers": null
};
ggvis.getPlot("plot_id958820192").parseSpec(plot_id958820192_spec);
</script><!--/html_preserve-->

For fun
========================================================
Add a little waggle to your plot.

```r
span = waggle(0.5, 2)
mtcars %>% 
  mutate(amFactor = factor(am, labels=c('auto', 'manual'))) %>% 
  group_by(amFactor) %>%
  ggvis(x=~wt, y=~mpg) %>%
  layer_points(fill=~amFactor) %>%
  layer_smooths(stroke=~amFactor, span=span)
```



Wrap up
========================================================
Note that much of the functionality you see is in base R

- <span class='func'>with</span>, <span class='func'>within</span>, <span class='func'>tapply</span> etc.

What you now have is a more straightforward way to do those operations.

Think of these packages as organizational and exploratory tools.

Use them to bring clarity to code.

Use them to explore your data more easily whether for visualization or modeling.

With more use, the easier it gets, and the more you can do.

Further Resources
========================================================
[Data wrangling cheatsheet](https://www.rstudio.com/wp-content/uploads/2015/02/data-wrangling-cheatsheet.pdf)

[magrittr](https://github.com/smbache/magrittr)

[ggvis](http://ggvis.rstudio.com/)


Thanks!
========================================================
<table class='acknowledge'>
<tr>
<td>
<span style='color:#ffcb05'>Michael Clark</span><br><span style='color:#00274c'>Consulting for Statistics, Computing & Analytics Research<br>Advanced Research Computing<br>University of Michigan</span>

<br>
<span style='color:gray'>With notable assistance from:</span>
<br>

<span style='color:#dcb439'>Seth Berry</span><br><span style='color:#002b5b'>Center for Social Research<br>Notre Dame Research<br>University of Notre Dame</span>
</td>
<td><img src="Rlogo84_2.png" style='size:50%'></img></td>

</table>
