# Data was downloaded (by hand, API was not found) from 
# [VMI laskentapalvelu](https://vmilapa.luke.fi/#/compute) (Valtakunnallinen mets??inventaari),
# and the data was from years 2009-2013. Parameters for the data download: forest area, tree volume,
# and tree number were searchded for 20-year age groups, areas categorised by the main tree species,
# seach including both forests and kitumaa (poorly growing areas), and using district levels.

# library(devtools)
# install_github("rOpenGov/statfi") # If not installed yet
# library(statfi) statfi is outdated. Use package pxweb instead for Statistics Finland data.

library(quiltr)

parms <- data.frame(
  File = c(
    "ID1557142456655.csv",
    "ID1557142551382.csv",
    "ID1557142710762.csv"
  ),
  Variable = c("Pintaala","Runkoluku","Tilavuus"),
  Unit= c("km2","1000kpl","1000m3")
)
dat <- data.frame()
for(i in 1:nrow(parms)) {
  tmp <- read.csv(paste0("C:/Users/jtue/AppData/Local/Temp/Data-",parms$File[i]),
                  header=TRUE, sep=";", skip=3,encoding = "UTF-8")
  colnames(tmp) <- c("Maakunta","Ikaluokka","Paapuulaji","Tulos","Keskivirhe","Suht_keskivirhe")
  for(j in 4:6) {tmp[[j]][is.na(tmp[[j]])] <- 0}
  dat <- rbind(dat, cbind(tmp, parms[i, 2:3]))
}  
dat$Ikaluokka <- factor(dat$Ikaluokka, levels=c("Puuton","1-20","21-40","41-60","61-80","81-100",
                                                "101-120","121-140","141-160","161+"))
dat$Maakunta <- factor(dat$Maakunta, levels=unique(dat$Maakunta))
dat$Alue <- ifelse(as.numeric(dat$Maakunta) %in% 15:18, "Pohjois-Suomi", "Etel??-Suomi")
dat$Vuosi <- 2013

qbuild <- function(pkg, ...) {
  quilt <- reticulate::import("quilt")
  quilt$build(pkg, ...)
}

qload <- function(pkg, file) {
  pkg_pythonic <- stringr::str_replace_all(pkg, "/", "\\.")
  pkg_name <- paste0("quilt.data.", pkg_pythonic)
  data <- reticulate::import(module = pkg_name)
  file <- stringr::str_replace_all(file, "/", "$")
  
  df <- eval(parse(text = paste0("data$", file, "()")))
  df
}

qbuild("jtuomsto/luketest/forests", dat)
#qload("jtuomsto/luketest","forests")

qlogin()
qpush("jtuomsto/luketest", public=TRUE)
qlogout()
