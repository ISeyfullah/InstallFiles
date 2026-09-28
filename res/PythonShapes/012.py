linpar("A",200,8)
linpar("B",150,6)
linpar("C",40,2)

def generate():
    
    moveto(0,B)
    lineto(0,C)
    arcto(C,0,C,C,True)
    lineto(A-C,0)
    arcto(A,C,A-C,C,True)
    lineto(A,B)
    lineto(0,B)
    close()
    
    dimlin("A",0,C,A,C,False,140)
    dimlin("B",C,0,C,B,True,140)
    dimrad("C",C,C,C,225,90)
