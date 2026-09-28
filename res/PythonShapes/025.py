from math import *

linpar("A",200,8)
linpar("B",100,4)
linpar("C",20,1)

def angle(x1, y1, x2, y2):
    dx = x2 - x1
    dy = y2 - y1
    angle_rad = atan2(dy,dx)
    return angle_rad

def generate():
    x1,y1=C,C
    x2,y2=C+A,C
    x3,y3=C+A/2,C+B
    
    moveto(C,0)
    lineto(C+A,0)
    p1,p2=polar(x2,y2,angle(x2,y2,x3,y3)-pi/2,C)
    arcto(p1,p2,C+A,C,True)
    p1,p2=polar(x3,y3,angle(x2,y2,x3,y3)-pi/2,C)
    lineto(p1,p2)
    p1,p2=polar(x3,y3,angle(x3,y3,x1,y1)-pi/2,C)
    arcto(p1,p2,C+A/2,C+B,True)
    p1,p2=polar(x1,y1,angle(x3,y3,x1,y1)-pi/2,C)
    lineto(p1,p2)
    arcto(C,0,C,C,True)
    close()
    
    dimlin("A",C,C,A+C,C,False,80)
    dimlin("B",C+A/2,C,C+A/2,B+C,True,280)
    dimrad("C",C,C,C,230)
