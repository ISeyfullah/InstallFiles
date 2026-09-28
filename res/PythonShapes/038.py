
linpar("A",200,8)
linpar("B",150,6)
linpar("C",30,1)
linpar("D",100,3)

def generate():
    moveto(0,0)
    lineto(A,0)
    lineto(D+C,B)
    lineto(C,B)
    close()
   
    dimlin("A",0,0,A,0,False)
    dimlinadv("B",0,0,0,B,None,None,C,B,True)
    dimlin("C",0,B,C,B,True)
    dimlin("D",C,B,C+D,B,True)
