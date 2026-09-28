from math import *

linpar("A",200,8)
linpar("B",100,4)
linpar("C",50,2)
linpar("D",20,1)

def angle(x1, y1, x2, y2):
    dx = x2 - x1
    dy = y2 - y1
    angle_rad = atan2(dy,dx)
    return angle_rad

def generate():
    x1,y1=D,D
    x2,y2=D+A,D
    x3,y3=D+C,D+B
    
    moveto(D,0)
    lineto(D+A,0)
    p1,p2=polar(x2,y2,angle(x2,y2,x3,y3)-pi/2,D)
    arcto(p1,p2,D+A,D,True)
    p1,p2=polar(x3,y3,angle(x2,y2,x3,y3)-pi/2,D)
    lineto(p1,p2)
    p1,p2=polar(x3,y3,angle(x3,y3,x1,y1)-pi/2,D)
    arcto(p1,p2,D+C,D+B,True)
    p1,p2=polar(x1,y1,angle(x3,y3,x1,y1)-pi/2,D)
    lineto(p1,p2)
    arcto(D,0,D,D,True)
    close()
    
    dimlin("A",D,D,A+D,D,False,80)
    dimlin("B",D+C,D,D+C,B+D,True,0)
    dimlin("C",D,D,D+C,D,False,0)
    dimrad("D",D,D,D,230)
