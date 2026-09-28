from math import *

linpar("A", 200, 8)
linpar("B", 160, 6.3)
linpar("C", 40, 1.6)
linpar("D", 60, 2.4)
linpar("E", 50, 2)

def generate():
    
    # Adjust B to account for straight base section
    b_adjusted = B - E
    
    # Center of the arc/circle at top center (adjusted for E offset)
    center_x = A / 2
    center_y = b_adjusted
    
    # Distance from bottom corner (0, 0) to adjusted center
    hyp = distance(0, 0, center_x, center_y)
    
    # Angle offset for tangent points
    v = asin(C / hyp)
    
    # Angle of left leg from (0,0) to center
    leftang = angle(0, 0, center_x, center_y) + v
    
    # Angle of right leg from (A,0) to center
    rightang = angle(A, 0, center_x, center_y) - v
    
    # Calculate tangent points (relative to adjusted center)
    right_tangent_x, right_tangent_y = polar(center_x, center_y, rightang - pi / 2, C)
    left_tangent_x, left_tangent_y = polar(center_x, center_y, leftang + pi / 2, C)
    
    # Shift tangent points up by E to account for base
    right_tangent_y_actual = right_tangent_y + E
    left_tangent_y_actual = left_tangent_y + E
    
    moveto(0, E)
    lineto(0, 0)
    lineto(A, 0)
    lineto(A, E)
    lineto(right_tangent_x, right_tangent_y_actual)
    arcto(left_tangent_x, left_tangent_y_actual, center_x, center_y + E, True)
    close()
    
    # Circle center is also shifted up by E
    circle(center_x, center_y + E, D / 2)
    
    dimlin("A", 0, 0, A, 0, False)
    dimlinadv("B", 0, 0, 0, B,None,None,center_x,B, True,64)
    dimrad("C", center_x, center_y + E, C, 135)
    dimdia("D", center_x, center_y + E, D, 45)
    dimlin("E", 0, 0, 0, E, True)