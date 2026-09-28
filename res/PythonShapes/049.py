from math import *

linpar("A",150,8)
linpar("B",150,8)
linpar("C",70,3)
linpar("D",50,2)

def generate():
    
    moveto(0,0)
    lineto(A,0)
    lineto(A,B)
    arcto(0,B,A/2,B,True)
    lineto(0,0)
    close()
    
    moveto(A/2-C/2,B-D)
    lineto(A/2+C/2,B-D)
    lineto(A/2+C/2,B)
    arcto(A/2-C/2,B,A/2,B,True)
    lineto(A/2-C/2,B-D)
    close()
    
    dimlin("A",0,0,A,0,False)
    dimlin("B",0,0,0,B,True)
    dimlin("C",A/2-C/2,B-D,A/2+C/2,B-D,False)
    dimlin("D",A/2-C/2,B-D,A/2-C/2,B,True)
    
    
    
