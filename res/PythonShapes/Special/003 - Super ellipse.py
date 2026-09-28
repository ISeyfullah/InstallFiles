
from math import *

linpar("A",200,8)
linpar("B",150,6)
realpar("C",2.5)

def generate():
    #rect(0,0,A,B)
   
    #dimlin("A",0,0,A,0,False)
    #dimlin("B",0,0,0,B,True)

    moveto(0,B)

    for p in range(0,1000):
        x=p/1000.0
        y=pow(1-pow(x,C),1.0/C)*B
        lineto(x*A,y)

    for p in range(1000,0,-1):
        x=p/1000.0
        y=pow(1-pow(x,C),1/C)*B
        lineto(x*A,-y)

    for p in range(0,1000):
        x=p/1000.0
        y=pow(1-pow(x,C),1/C)*B
        lineto(-x*A,-y)

    for p in range(1000,0,-1):
        x=p/1000.0
        y=pow(1-pow(x,C),1/C)*B
        lineto(-x*A,y)

    

    close()

    arcfit(0,max(A,B)/1000.0)
  
    dimlin("A",0,0,A,0,True,0)
    dimlin("B",0,0,0,B,True,0)
    dimtxt("C",160,110)
    dimtxt("(X/A)^C + (Y/B)^C = 1",0,-180)