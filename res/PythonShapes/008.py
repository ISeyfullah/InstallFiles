linpar("A",200,8)
linpar("B",150,6)
linpar("C",80,3)
linpar("D",80,3)
linpar("E",50,2)
linpar("F",20,1)

def generate():
    
    rect(0,0,A,B,F)
    circle(C,D,E/2)
    
    dimlin("A",0,F,A,F,False,105)
    dimlin("B",F,0,F,B,True,105)
    dimlin("C",0,D,C,D,False,207)
    dimlin("D",C,0,C,D,True,195)
    dimdia("E",C,D,E,45)
    dimrad("F",A-F,B-F,F,45)
    
    
    
