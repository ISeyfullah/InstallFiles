from math import *

linpar("A",200,8)
linpar("B",200,8)
linpar("C",100,4)

def generate():
    
    moveto(0,0)
    lineto(A,0)
    lineto(A,B)
    arcto(0,B,A/2,B,True)
    lineto(0,0)
    close()
    
    circle(A/2,B,C/2)
    
    dimlin("A",0,0,A,0,False)
    dimlin("B",0,0,0,B,True)
    dimdia("C",A/2,B,100,45)
    
    
    
