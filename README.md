# MTM---Mange-Transmission-Model

To model sarcoptic mange transmission between foxes in an urban setting, an individual based model (IBM) was developed using [NetLogo 6.1](https://ccl.northwestern.edu/netlogo/). The MTM is a discrete-time, spatially explicit model containing three main submodels: (1) a within-park movement procedure, (2) a between-park movement procedure, and (3) a disease procedure. Here, I focus only on the effects of movement behaviours and landscape structure on disease spread such that demographic factors (e.g., births and deaths) are not considered in the model. In addition, variation in movement behaviours due to seasonality is also not considered.

--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

The model was replicated 100 times for two landscapes: an artificial landscape and a real region in Scarborough, Ontario using the NetLogo GIS extension.
2 Response variables were assessed: 
- the mean effective R (Re)
- The mean number of effective contact events (i.e., the number of times a successful transmisson event occurred between a susceptible and infected fox) 
- Now translating model into R using [NetLogoR](https://github.com/PredictiveEcology/NetLogoR)
