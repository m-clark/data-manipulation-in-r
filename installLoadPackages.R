packs = c('magrittr', 'plyr','dplyr', 'tidyr','rvest', 'stringr' ,'leaflet', 'ggvis')
sapply(packs, install.packages, dependencies=T, repos="https://cran.rstudio.com/")
sapply(packs[1:4], library, character.only=T)