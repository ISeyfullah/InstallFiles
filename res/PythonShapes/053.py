linpar("A", 35, 1.4)
linpar("C", 100, 4)
linpar("D", 20, 0.8)
linpar("F", 50, 2)

def generate():
    
    moveto(F-D, 0)
    lineto(F, 0)
    lineto(F, A+C)
    lineto(0, A+C)
    lineto(0, C)
    lineto(F-D, C)
    close()
    
    dimlin("A", 0,C,0,A+C)
    dimlinadv("C", 0,0,0,C,F-D,None,None,None)
    dimlin("D", F-D,0,F,0,False)
    dimlin("F", 0,A+C,F,A+C)