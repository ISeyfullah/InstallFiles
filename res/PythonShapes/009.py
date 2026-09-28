linpar("A",200,8)
linpar("B",150,6)
linpar("C",50,2)
linpar("D",40,1.8)

def generate():
    
    moveto(C,0)
    lineto(A-C,0)
    lineto(A,D)
    lineto(A,B)
    lineto(0,B)
    lineto(0,D)
    lineto(C,0)
    close()
    
    dimlin("A",0,C,A,C,False,180)
    dimlin("B",C,0,C,B,True,180)
    dimlin("C",0,0,C,0,False,40)
    dimlin("D",0,0,0,D,True,25)
