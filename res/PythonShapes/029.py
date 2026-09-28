linpar("A",140,5)
linpar("B",200,8)
linpar("D",50,2)
linpar("C",50,2)
linpar("E",50,2)

def generate():
    
    circle(C,D,E/2)
    
    moveto(0,0)
    lineto(A,0)
    lineto(0,B)
    lineto(0,0)
    close()
    
    dimlin("A",0,0,A,0,False,64)
    dimlin("B",0,0,0,B,True,64)
    dimlin("C",0,D,C,D,False,158)
    dimlin("D",C,0,C,D,True,148)
    dimdia("E",C,D,E,45,5)
