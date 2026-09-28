linpar("A", 35, 1.4)
linpar("B", 20, 0.8)
linpar("C", 100, 4)
linpar("D", 20, 0.8)
linpar("F", 50, 2)

def generate():
    
    moveto(0, 0)
    lineto(F, 0)
    lineto(F, A+B+C)
    lineto(0, A+B+C)
    lineto(0, B+C)
    lineto(F-D, B+C)
    lineto(F-D, B)
    lineto(0,B)
    close()
    
    dimlin("A", 0,B+C,0,A+B+C)
    dimlin("B", 0,0,0,B)
    dimlin("C", 0,B,0,B+C)
    dimlinadv("D", F-D,0,F,0,None,B,None,None,False)
    dimlin("F", 0,A+B+C,F,A+B+C)