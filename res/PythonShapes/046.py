from math import *

linpar("A", 200, 8)
linpar("B", 460, 18)
linpar("C", 500, 20)

def harc(p1_x, p1_y, width, rad):
    # This function calculates the center of an arc that begins at p1
    # and has start and endpoint on a horizontal line. The radius of the arc
    # is rad and the distance between points is 'width'
    h1 = width / 2.0
    h2 = abs(rad)
    h = sqrt(h2 * h2 - h1 * h1)
    return (p1_x + h1, p1_y - h)

def generate():
    
    c1_x, c1_y = harc(0, 0, A, B)
    he = abs(C - B)
    c2_x, c2_y = harc(0, he, A, C)

    moveto(0, 0)
    arcto(A, 0, c1_x, c1_y, False)
    lineto(A, he)
    arcto(0, he, c2_x, c2_y, True)
    close()

    mid_x_1, mid_y_1 = polar(c1_x, c1_y, pi / 2, B)
    mid_x_2, mid_y_2 = polar(c2_x, c2_y, pi / 2, C)
    
    dimlin("A", 0, 0, A, 0, False)
    dimrad("B", mid_x_1, mid_y_1, 1, 135)
    dimrad("C", mid_x_2, mid_y_2, 1, 45)

