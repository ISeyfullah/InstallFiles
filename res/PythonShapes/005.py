linpar("A",200,8)
linpar("B",150,6)
linpar("C",20,1)
linpar("D",20,1)
linpar("E",20,1)

def generate():
    
    rect(0,0,A,B)
    circle(C,D,E/2)
    circle(A-C,D,E/2)
    circle(A-C,B-D,E/2)
    circle(C,B-D,E/2)
    
    dimlin("A",0,0,A,0,False)
    dimlin("B",0,0,0,B,True)
    dimlin("C",A-C,B-D,A,B-D,True,60)
    dimlin("D",A-C,B-D,A-C,B,False,80)
    dimdia("E",C,D,E,45,20)
    
    
    
