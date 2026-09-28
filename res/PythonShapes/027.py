from math import *

linpar("A",200,8)
linpar("B",50,2)
linpar("C",130,5)
linpar("D",25,1)
linpar("E",50,2)
linpar("F",50,2)


def generate():
    
    circle(B+D,E,F/2)
    
    moveto(B,0)
    lineto(B+A,0)
    lineto(0,C)
    lineto(B,0)
    close()
    
    dimlin("A",B,0,A+B,0,False,64)
    dimlin("B",0,0,B,0,False,0)
    dimlin("C",0,0,0,C,True,0)
    dimlin("D",B,0,B+D,0,False)
    dimlin("E",B+D,0,B+D,E,True,0)
    dimdia("F",B+D,E,F,-45)
    
