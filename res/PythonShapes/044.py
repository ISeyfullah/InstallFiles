from math import *

linpar("A",200,8)
linpar("B",200,8)
linpar("C",100,4)

def generate():
    
    moveto(0,0)
    lineto(A,0)
    arcto(A,B,A,B/2,True)
    lineto(0,B)
    arcto(0,0,0,B/2,True)
    close()
    
    circle(0,B/2,C/2)
    circle(A,B/2,C/2)
    
    dimlin("A",0,B/2,A,B/2,False,160)
    dimlin("B",0,0,0,B,True,160)
    dimdia("C",0,B/2,100,45)
    
    
    
