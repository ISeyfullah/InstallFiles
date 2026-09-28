from math import *

linpar("A",85,2)
linpar("B",30,1.2)
linpar("C",10,0.5)
linpar("D",25,1)
linpar("E",15,0.8)

def angle(x1, y1, x2, y2):
    dx = x2 - x1
    dy = y2 - y1
    angle_rad = atan2(dy,dx)
    return angle_rad
    
def offset(x1,y1,x2,y2,dist):
   ang=angle(x1,y1,x2,y2)-pi/2
   px1,px2=polar(x1,y1,ang,dist)
   px3,px4=polar(x2,y2,ang,dist)
   return px1,px2,px3,px4

def generate():
    hypo=sqrt(A*A-(B/2-C/2)*(B/2-C/2))
    
    x1,y1=0,0
    x2,y2=polar(x1,y1,asin((D-E)/A),hypo)
    x3,y3=polar(x1,y1,-asin((D-E)/A),hypo)
    
    l1x1,l1y1,l1x2,l1y2=offset(x2,y2,x1,y1,E)
    l2x1,l2y1,l2x2,l2y2=offset(x1,y1,x3,y3,E)
    
    moveto(l1x1,l1y1)
    lineto(l1x2,l1y2)
    arcto(l2x1,l2y1,x1,y1,True)
    lineto(l2x2,l2y2)
    arcto(l1x1,l1y1,x2,y2,True)
    close()
    
    circle(x1,y1,C/2)
    circle(A,0,B/2)
    
    dimlin("A",x1,y1,A,0,True,120)
    dimdia("B",A,0,B,180)
    dimrad("D",A,0,D,-45)
    dimdia("C",x1,y1,C,0)
    dimrad("E",x1,y1,E,220)
