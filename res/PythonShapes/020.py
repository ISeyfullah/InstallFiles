linpar("A",200,8)
linpar("B",150,6)
linpar("C",130,5)
linpar("D",70,3)

def generate():
    
    moveto(0,0)
    lineto(A,0)
    lineto(A,B-D)
    lineto(A-C,B-D)
    lineto(A-C,B)
    lineto(0,B)
    lineto(0,0)
    close()
    
    dimlin("A",0,0,A,0,False)
    dimlin("B",0,0,0,B,True)
    dimlin("C",A-C,B-D,A,B-D,True)
    dimlin("D",A-C,B-D,A-C,B,False)
