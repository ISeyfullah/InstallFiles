from math import *

linpar("A",130,4)
linpar("B",70,2)
linpar("C",25,1)
linpar("D",55,2)
linpar("E",20,0.8)
 
def generate():
    diff=D-B/2
    
    aa=(A/2)
    bb=(D-E)
    
    
    ang=asin(bb/aa)
    dis=sqrt(aa*aa-bb*bb)
    
    
    x1,y1=polar(0,0,ang+pi/2,D)
    
    
    x2,y2=x1,y1
    x2=-x2
    
    x3,y3=polar(aa,0,pi/2-ang,E)
    
    x4,y4=x3,y3
    y4=-y4
    
    x5,y5=x2,y2
    y5=-y5
    
    x6,y6=x1,y1
    y6=-y6
    
    x7,y7=x4,y4
    x7=-x7
    
    x8,y8=x3,y3
    x8=-x8
    
    moveto(x8,y8)
    arcto(x7,y7,-A/2,0,True)
    lineto(x6,y6)
    arcto(x5,y5,0,0,True)
    lineto(x4,y4)
    arcto(x3,y3,A/2,0,True)
    lineto(x2,y2)
    arcto(x1,y1,0,0,True)
    close()
    
    circle(0,0,B/2)
    circle(A/2,0,C/2)
    circle(-A/2,0,C/2)
    
    dimlin("A",-A/2,0,A/2,0,False,190)
    dimdia("B",0,0,B,200)
    dimdia("C",A/2,0,C,200,12)
    dimrad("D",0,0,D,90)
    dimrad("E",A/2,0,E,0)
    
