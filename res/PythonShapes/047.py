from math import *

linpar("A", 200, 8)
linpar("B", 400, 16)
angpar("C", 30)

def generate():
    
    # Center is offset to the left by inner radius A
    center_x = -A
    center_y = 0
    
    # Width is the difference between outer and inner radius
    width = abs(B - A)
    
    # Convert angle C from degrees to radians
    c_rad = C * pi / 180
    
    # Calculate rotated points using polar
    # p3 is point (width, 0) rotated by angle C around center
    p3_x, p3_y = polar(center_x, center_y, c_rad, B)
    
    # p4 is point (0, 0) rotated by angle C around center
    p4_x, p4_y = polar(center_x, center_y, c_rad, A)
    
    moveto(0, 0)
    lineto(width, 0)
    arcto(p3_x, p3_y, center_x, center_y, True)
    lineto(p4_x, p4_y)
    arcto(0, 0, center_x, center_y, False)
    close()
    
    # Calculate midpoint angle for dimensions
    mid_angle = c_rad / 2
    ax, ay = polar(center_x, center_y, mid_angle, A)
    bx, by = polar(center_x, center_y, mid_angle, B)
    c1x, c1y = polar(center_x, center_y, 0, (A+B)/2)
    c2x, c2y = polar(center_x, center_y, c_rad, (A+B)/2)
    
    dimrad("A", ax, ay, 1, C/2)
    dimrad("B", bx, by, 1, C/2)
    dimarc("C",c1x,c1y,c2x,c2y,center_x,center_y,True)
