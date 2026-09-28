linpar("A",200,8)
linpar("B",150,6)

def generate():
    
    moveto(0,0)
    lineto(A,0)
    lineto(A/2,B)
    lineto(0,0)
    close()
    
    dimlin("A",0,0,A,0,False)
    dimlin("B",A/2,0,A/2,B,False,0)
