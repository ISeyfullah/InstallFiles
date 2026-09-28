from math import *

linpar("A", 200, 8)
linpar("B", 160, 6.3)
linpar("C", 60, 2.4)
linpar("D", 70, 2.8)

def generate():
    
    # Center of the arc/circle at top center
    center_x = A / 2
    center_y = B
    
    # Distance from bottom corner (0, 0) to center
    hyp = distance(0, 0, center_x, center_y)
    
    # Angle offset for tangent points
    v = asin(C / hyp)
    
    # Angle of left leg from (0,0) to center
    leftang = angle(0, 0, center_x, center_y) + v
    
    # Angle of right leg from (A,0) to center
    rightang = angle(A, 0, center_x, center_y) - v
    
    # Calculate tangent points
    right_tangent_x, right_tangent_y = polar(center_x, center_y, rightang - pi / 2, C)
    left_tangent_x, left_tangent_y = polar(center_x, center_y, leftang + pi / 2, C)
    
    moveto(0, 0)
    lineto(A, 0)
    lineto(right_tangent_x, right_tangent_y)
    arcto(left_tangent_x, left_tangent_y, center_x, center_y, True)
    close()
    
    circle(center_x, center_y, D / 2)
    
    dimlin("A", 0, 0, A, 0, False)
    dimlinadv("B", 0, 0, 0, B, None,None,A/2,B,True)
    dimrad("C", center_x, center_y, C, 135)
    dimdia("D", center_x, center_y, D, 45)