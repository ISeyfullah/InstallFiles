linpar("A",200,8)
linpar("B",70,2.5)
linpar("C",130,6)

def generate():
    
    lineto(0,A)
    arcto(2*C,A,C,A,False)
    lineto(2*C,0)
    lineto(C+B,0)
    lineto(C+B,A)
    arcto(C-B,A,C,A,True)
    lineto(C-B,0)
    lineto(0,0)
    close()
    
    dimlin("A",0,0,0,A,True)
    dimrad("B",C,A,B,125)
    dimrad("C",C,A,C,45)
