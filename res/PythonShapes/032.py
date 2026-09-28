linpar("A", 200, 8)
linpar("B", 150, 6)
linpar("C", 60, 2.5)
linpar("D", 70, 3)
linpar("E", 40, 1.5)

def generate():
    
    moveto(E, 0)
    lineto(A, 0)
    lineto(A, D)
    lineto(C, B)
    lineto(0, B)
    lineto(0, E)
    arcto(E, 0, 0, 0, False)
    close()
    
    dimlin("A", 0, 0, A, 0, False)
    dimlin("B", 0, 0, 0, B, True)
    dimlin("C", 0, B, C, B, True)
    dimlin("D", A, 0, A, D, False)
    dimrad("E", 0, 0, E, 45)