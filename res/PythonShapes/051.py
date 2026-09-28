from math import *

linpar("A",200,9)
linpar("B",150,7)
linpar("C",30,1)
linpar("D",100,4)
intpar("N",8)

def generate():
    
    angle = 360.0 / N

    for i in range(N):
        angle_deg = 90 + angle * i
        angle_rad = pi * angle_deg / 180

        x = round(A/2 + B/2 * cos(angle_rad), 3)
        y = round(A/2 + B/2 * sin(angle_rad), 3)
        
        circle(x,y,C/2)
        strcrc = str(i+1)
        if i == N-1:
            strcrc = "N"
        dimtxt(strcrc,x,y)
    
    circle(A/2,A/2,D/2)
    circle(A/2,A/2,A/2)
    
    dimlin("A",0,A/2,A,A/2,False,350)
    dimlin("B",(A-B)/2,A/2,A-(A-B)/2,A/2,False,310)
    dimlin("D",(A-D)/2,A/2,A-(A-D)/2,A/2,False,270)
    dimlin("C",A/2-C/2,(A-B)/2,A/2+C/2,(A-B)/2,False,80)
    
    
    
    
