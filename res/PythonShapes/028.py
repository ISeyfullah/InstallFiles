from math import *

linpar("A",200,8)
linpar("B",150,6)
linpar("C",50,2)
linpar("D",50,2)


def generate():
    
    circle(A/2,C,D/2)
    
    moveto(0,0)
    lineto(A,0)
    lineto(A/2,B)
    lineto(0,0)
    close()
    
    dimlin("A",0,0,A,0,False)
    dimlin("B",A/2,0,A/2,B,True,265)
    dimlin("C",A/2,0,A/2,C,True,90)
    dimdia("D",A/2,C,D,45)
    
