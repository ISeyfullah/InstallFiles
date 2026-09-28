linpar("A", 200, 8)
linpar("B", 150, 6)
linpar("C", 60, 2.5)
linpar("D", 70, 3)

def generate():
    
    moveto(0, 0)
    lineto(A, 0)
    lineto(A, D)
    lineto(C, B)
    lineto(0, B)
    close()
    
    dimlin("A", 0, 0, A, 0, False)
    dimlin("B", 0, 0, 0, B, True)
    dimlin("C", 0, B, C, B, True)
    dimlin("D", A, 0, A, D, False)
    dimlinadv("D", A, 0, A, D,A,0,None,None, False)