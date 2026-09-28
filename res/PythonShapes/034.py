linpar("A", 200, 8)
linpar("B", 150, 6)
linpar("C", 60, 2.5)
linpar("D", 70, 3)
linpar("E", 40, 1.5)
linpar("F", 50, 2)

def generate():
    
    cx = A - C + E
    cy = B - D + E
    
    moveto(A, 0)
    lineto(A, B - D)
    lineto(cx,cy-E)	
    arcto(cx-E, cy, cx, cy, False)
    lineto(A-C, B)
    lineto(0, B)
    lineto(0, F)
    arcto(F, 0, 0, 0, False)
    close()
    
    dimlin("A", 0, 0, A, 0, False)
    dimlin("B", 0, 0, 0, B, True)
    dimlin("C", A - C, B, A, B, True)
    dimlin("D", A, B-D, A, B, False)
    dimrad("E", cx, cy, E, 225)
    dimrad("F", 0, 0, F, 45)