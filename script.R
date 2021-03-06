
##uncommented script. For tutorial instructions, see webpage: http://clarkdatalabs.github.io/mapping_R/

install.packages(c("acs","choroplethr","choroplethrMaps","maptools","rgeos","mapproj","RColorBrewer","maps","geosphere","rgdal","reshape","ggplot2"))

# EXAMPLE 1: Mapping Census Data 

library(acs)
library(choroplethr)
library(choroplethrMaps)

##put key in code below
## http://api.census.gov/data/key_signup.html
api.key.install("api key here")

county_choropleth_acs(tableId="B19301")

##another choropleth example
state_choropleth_acs("B01002", num_colors=1, zoom=c("texas", "louisiana", "mississippi", "alabama", "georgia", "florida"))


# EXAMPLE 2: Working with Shapefiles, Projections, and Visualization

library(maptools)
library(rgdal)
library(RColorBrewer)
library(ggplot2)

##select - county_census/County_2010Census_DP1.shp
counties <- readShapeSpatial(file.choose(),proj4string=CRS("+proj=longlat +datum=WGS84"))

##inspect the data
head(counties@data)

##Florida Plot
florida <- counties[substring(counties$GEOID10,1,2)=="12",]
plot(florida)


##Projection and Layering with RGDAL
library(rgdal)

EPSG <- make_EPSG()

## Find Florida related projections
EPSG[grep("florida", EPSG$note, ignore.case=TRUE), 1:2]

#Use FIPS code to set prj4
subset(EPSG, code==3087)
prjstring <- subset(EPSG, code==3087)$prj4

##choose  ...cultural_centers/gc_culturecenter_oct15.shp.
cultural <- readShapeSpatial(file.choose(),proj4string=CRS(prjstring))

cultural_proj <- spTransform(cultural, CRS("+proj=longlat +datum=WGS84"))

plot(florida)
points(cultural_proj)

##play with plot variables
plot(florida)
points(cultural_proj, cex=.8, pch=24, col=554, bg="grey")

##join polygon data to points
county_data <- over(cultural_proj,florida)
cultural_proj$pop <- county_data$DP0010001

## set colors
library(RColorBrewer)

brks <- c(.5,1,1.5,2) * 1000000
cols <- brewer.pal(5,"Greens")

mapcols <- cols[findInterval(cultural_proj$pop, vec=brks)]
plot(cultural_proj,col=mapcols,pch=20)


##base R instructions for choropleth

brks <- c(25,30,35,40,45,50,55,60,65)
cols <- brewer.pal(8,"Purples")

mapcols <- cols[findInterval(florida$DP0020001, vec=brks)]
plot(florida,col=mapcols,border="white")

legend("bottomleft", legend = levels(cut(florida$DP0020001, brks)), fill = cols, title = "Median Age")

##using ggplot2
library(ggplot2)

fl_shapes <- fortify(florida,region="GEOID10")

ggplot() + geom_map(data=as.data.frame(florida),aes(map_id = GEOID10,fill=DP0020001), map=fl_shapes) + expand_limits(x=fl_shapes$long, y=fl_shapes$lat) + scale_fill_gradient2(low="seagreen",mid="white",high="darkorchid4",midpoint=47,limits=c(29,65)) + coord_map(projection="mercator")

# EXAMPLE 3: Migration Distances Map
library(maps)
library(geosphere)
library(reshape)
library(maptools)

## Import shapefile: `state_shapes/tl_2014_us_state.shp` 
state <- readShapeSpatial(file.choose())

##Import .csv file: `state_migrations_2014.csv`
migration <- read.csv(file.choose())

centrs <- data.frame(as.character(state@data$NAME),coordinates(state))
colnames(centrs) <- c("name","long","lat")

## Reshape data with melt function
migration <- migration[c(1,6:56)]
long_mig <- melt(migration,id.vars="from_state") 

## Create a mapping function
draw_from_state <- function(centrs, migrations, state_name, color=rgb(0,0,0,alpha=0.5)) {
  migrations$variable <- sub("."," ",migrations$variable,fixed=TRUE)
  migrations <- migrations[migrations$variable==state_name & migrations$from_state != state_name,]
  for(i in 1:nrow(migrations)){
    if (nrow(centrs[centrs$name==as.character(migrations[i,]$from_state),]) > 0){
      from_long <- centrs[centrs$name==as.character(migrations[i,]$from_state),]$long
      from_lat <- centrs[centrs$name==as.character(migrations[i,]$from_state),]$lat
      to_long <- centrs[centrs$name==as.character(migrations[i,]$variable),]$long
      to_lat <- centrs[centrs$name==as.character(migrations[i,]$variable),]$lat
      number <- migrations[i,]$value
      lines(gcIntermediate(c(from_long, from_lat), c(to_long, to_lat), n=50, addStartEnd=TRUE),lwd=sqrt(number)/50,col=color)
    }
  }
}


## Using our mapping function: example 1
map("state")

draw_from_state(centrs, long_mig, "Florida", rgb(0,0,1,0.5))


## Using our mapping function: example 2

xlim <- c(-171.738281, -56.601563)
ylim <- c(12.039321, 71.856229)
map("world", col="#f2f2f2", fill=TRUE, bg="white", lwd=0.05, xlim=xlim, ylim=ylim)

draw_from_state(centrs, long_mig, "Wyoming", rgb(1,0,0,.5))
