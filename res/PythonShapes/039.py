from math import *

linpar("A", 200, 8)
linpar("B", 150, 6)
linpar("C", 60, 2)
linpar("D", 80, 3)

def generate():
    
    # Center of the arc/circle at top-left
    center_x = C
    center_y = B
    
    # Distance from bottom-right corner (A, 0) to center (C, B)
    p1c = distance(A,0,C,B)
    
    # Angle from center to bottom-right corner
    ang = angle(A,0,C,B) - asin(C / p1c)

    # Distance along the line from (A, 0) to tangent point
    di = sqrt(p1c * p1c - C * C)
    
    # Tangent point on the angled line
    q2_x,q2_y=polar(A,0,ang,di)
    
    moveto(0, 0)
    lineto(A, 0)
    lineto(q2_x, q2_y)
    arcto(0, B, C, B, True)
    close()
    
    circle(C,B,D/2)
    
    dimlin("A", 0, 0, A, 0, False)
    dimlin("B", 0, 0, 0, B, True)
    dimrad("C", C, B, C, 135)
    dimdia("D", C, B, D, 45)