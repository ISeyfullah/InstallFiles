linpar("A",200,8)
linpar("B",50,2)
linpar("C",130,5)

def generate():
    
    moveto(B,0)
    lineto(A+B,0)
    lineto(0,C)
    lineto(B,0)
    close()
    
    dimlin("A",B,0,B+A,0,False)
    dimlin("B",0,0,B,0,False,0)
    dimlin("C",0,0,0,C,True)
