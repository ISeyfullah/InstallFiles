linpar("A",140,5)
linpar("B",200,8)
linpar("C",30,1.5)

def generate():
    
    moveto(0,0)
    lineto(A,0)
    lineto(C,B)
    lineto(0,0)
    close()
    
    dimlin("A",0,0,A,0,False)
    dimlin("B",0,0,0,B,True,0)
    dimlin("C",0,B,C,B,False,0)
