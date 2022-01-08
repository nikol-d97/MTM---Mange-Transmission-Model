
library(NetLogoR)

dataWorld <- read.table("landscape-border-new.txt", header = FALSE, col.names = c("xcor", "ycor", "land_type", "resistance", "index", "movement_index"), sep = "")


##### MTM - NetLogo Mange Transmission Model translated into R 

### global variables (i.e. Model paramters): 
numFoxLeft <- 8 #num foxes in left patch 
numFoxRight <- 8 #num foxes in right patch 
intInfectedFox <- 1 #initial number of infected foxes
transmissionProb <- 0.03 #probability of disease transmission 
avgLatentPeriod <- 30 #average latent period 
avgInfectionsPeriod <- 100 #average infectious period
movementProbSusceptible <- 0.5 #probability of leaving of susceptible fox 
movementProbInfected <- 0.5 #probability of leaving of infected fox 
meanMoveLength <- 1 #mean movement length for CRW 
corr <- 0.9 #correlation in movement for CRW 
meanTurnAngle <- 180 #mean angle of turning at given timestep 
XC <- 95 #x coordinate for right forest patch 
YC <- -5 #y coordiante for right forest patch 
XC2 <- 10 #x coordinate for left forest patch 
YC2 <- -40 #y coordiante for left forest patch 

##  World setup procedure 

urbanWorld <- createWorld(minPxcor = 0, maxPxcor = 99, minPycor = -73, maxPycor = 0)

# set patch attribure function - takes one argument 'value' which is the column in the dataWorld matrix. Reads in the diffrent patch attributes by taking each X and Y coordinate 

setPatchAttributes <- function(value) {
  NLset(world = urbanWorld, agents = patch(urbanWorld, dataWorld[,1], dataWorld[,2]), val = dataWorld[,value])
}

landcover <- setPatchAttributes(3)
resistance <- setPatchAttributes(4)
index<- setPatchAttributes(5)
movement_index <- setPatchAttributes(6)

set.seed(1)
resistance <- resistance + runif(7400, min= 0, max= 0.8)
# stack all the different patch layers together into one world 

stackedWorld <- stackWorlds(landcover, resistance, index, movement_index)


## foxes

foxes <- createTurtles(n = numFoxLeft, coords = randomXYcor(world = stackedWorld$landcover, n = numFoxLeft), color = "red")

bbox(foxes) <- bbox(stackedWorld)


library(quickPlot)
dev() 
Plot(stackedWorld) # all the layers
Plot(foxes, addTo = "stackedWorld$landcover", pch = 16)