packs = c('magrittr','plyr','dplyr','tidyr','ggvis','rvest','stringr','leaflet')
sapply(packs, install.packages, dependencies=T, repos="https://cran.rstudio.com/")
sapply(packs[1:5], library, character.only=T)
