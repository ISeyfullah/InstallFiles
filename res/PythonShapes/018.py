linpar("A",200,8)
linpar("B",150,6)
linpar("C",30,1.5)
linpar("D",30,1.5)

def generate():
    
    moveto(C,0)
    lineto(A-C,0)
    lineto(A-C,D)
    lineto(A,D)
    lineto(A,B)
    lineto(0,B)
    lineto(0,D)
    lineto(C,D)
    lineto(C,0)
    close()
    
    dimlin("A",0,D,A,D,False,140)
    dimlin("B",C,0,C,B,True,140)
    dimlin("C",0,0,C,0,False,40)
    dimlin("D",0,0,0,D,True)
