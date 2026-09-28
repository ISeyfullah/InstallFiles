linpar("A",200,8)
linpar("B",150,6)
linpar("C",80,3)
linpar("D",80,3)
linpar("E",50,2)

def generate():
    
    rect(0,0,A,B)
    circle(C,D,E/2)
    
    dimlin("A",0,0,A,0,False,64)
    dimlin("B",0,0,0,B,True,64)
    dimlin("C",0,D,C,D,False,220)
    dimlin("D",C,0,C,D,True,210)
    dimdia("E",C,D,E,45)
    
    
    
