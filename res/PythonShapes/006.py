linpar("A",200,8)
linpar("B",150,6)
linpar("C",20,1)
linpar("D",20,1)
linpar("E",30,1)
linpar("F",20,1)

def generate():
    
    rect(0,0,A,B,E)
    circle(C,D,F/2)
    circle(A-C,D,F/2)
    circle(A-C,B-D,F/2)
    circle(C,B-D,F/2)
    
    dimlin("A",0,E,A,E,False,100)
    dimlin("B",E,0,E,B,True,100)
    dimlin("C",A-C,B-D,A,B-D,True,70)
    dimlin("D",A-C,B-D,A-C,B,False,85)
    dimrad("E",A-C,D,E,-45)
    dimdia("F",C,B-D,F,-45)
    
    
    
    
