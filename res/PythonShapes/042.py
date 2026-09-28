from math import *

linpar("A", 200, 8)
linpar("B", 160, 6.3)
linpar("C", 40, 1.6)
linpar("D", 60, 2.4)
linpar("E", 50, 2)
linpar("F", 160, 6.3)

def generate():
    
    # Calculate the rack width (shoulder width on each side)
    rackwidth = (A - F) / 2
    
    # Important points
    p1_x = A - rackwidth
    p1_y = E
    
    center_x = A / 2
    center_y = B
    
    # Distance from p1 to center
    p1c = distance(p1_x, p1_y, center_x, center_y)
    
    # Tangent points on the arc
    p2_x, p2_y = polar(center_x, center_y, asin(C / p1c), C)
    p3_x, p3_y = polar(center_x, center_y, pi - asin(C / p1c), C)
    
    p4_x = (A - F) / 2
    p4_y = E
    
    # Generate the part
    moveto(0, 0)
    lineto(A, 0)
    lineto(A, E)
    lineto(p1_x, p1_y)
    lineto(p2_x, p2_y)
    arcto(p3_x, p3_y, center_x, center_y, True)
    lineto(p4_x, p4_y)
    lineto(0, E)
    close()
    
    # Generate the hole
    circle(center_x, center_y, D / 2)
    
    dimlin("A", 0, 0, A, 0, False)
    dimlinadv("B", 0, 0, 0, B,None,None,center_x,B, True)
    dimrad("C", center_x, center_y, C, 135)
    dimdia("D", center_x, center_y, D, 45)
    dimlin("E", 0, 0, 0, E, True)
    dimlin("F", (A - F) / 2, E, A - (A - F) / 2, E, False)