linpar("A",140,5)
linpar("B",200,8)
linpar("C",30,1.5)
linpar("D",50,2)
linpar("E",50,2)
linpar("F",50,2)

def generate():
    
    circle(D,E,F/2)
    
    moveto(0,0)
    lineto(A,0)
    lineto(C,B)
    lineto(0,0)
    close()
    
    dimlin("A",0,0,A,0,False)
    dimlin("B",0,0,0,B,True,0)
    dimlin("C",0,B,C,B,False,0)
    dimlin("D",0,E,D,E,True,70)
    dimlin("E",D,0,D,E,True,75)
    dimdia("F",D,E,F,-45)
