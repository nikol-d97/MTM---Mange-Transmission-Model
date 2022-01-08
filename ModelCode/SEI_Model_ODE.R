beta <- 0.03
gamma <- 0.0083 
theta <- 0.0333  
N <- 16
S0 <- 15
E0 <- 0
I0 <- 1 

library(deSolve)

SEI_model <- function(t,y,p){ 
  beta<- p[1]; gamma<- p[2]; theta<- p[3]; 
  
  S<- y[1]; E<- y[2]; I<- y[3]
  
  dS= -beta*S*I/N + gamma*I
  dE= beta*S*I/N - theta*E
  dI= theta*E - gamma*I
  
  return(list(c(dS, dE,dI)))
}

beta<- 0.03; gamma<- 0.0083; theta<- 0.0333; N<-16
parms<- c(beta, gamma, theta, N)

S0<- 15; E0<- 0; I0<- 1; 
N0<- c(S0,E0,I0)

TT<-seq(0.1,1500,0.1)

results<-lsoda(N0,TT, SEI_model,parms)

S<-results[,2]; E<- results[,3]; I<-results[,4]; 

plot(TT,S,type="l", ylim=c(0,25), xlab= "Time (days)", ylab= "Number of foxes", 
     col= "orange", sub=
       "SEI Model for sarcoptic mange",
     cex.sub=0.55)
lines(TT, E, lty= 4, col= "grey")
lines(TT,I,lty=2, col= "blue")
legend(x=1200,y=25,
       c("S","E", "I"),
       cex=.8,col=c("orange", "grey", "blue"), lty=c(1,4,2), lwd=1.5)

Re<- (beta*S)/(gamma*N)

plot(Re, type= "l", xlim= c(0,1500))
