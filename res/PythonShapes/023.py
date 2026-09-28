linpar("A",140,5)
linpar("B",200,8)

def generate():
    
    moveto(0,0)
    lineto(A,0)
    lineto(0,B)
    lineto(0,0)
    close()
    
    dimlin("A",0,0,A,0,False)
    dimlin("B",0,0,0,B,True)
