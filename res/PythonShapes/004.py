linpar("A",200,8)
linpar("B",100,6)
linpar("C",20,1)
linpar("D",20,1)
linpar("E",160,6)
linpar("F",60,4)
linpar("G",20,1)
linpar("H",10,1)

def generate():
    
    rect(0,0,A,B,G)
    rect(C,D,C+E,D+F,H)
    
    dimlin("A",0,G,A,G,False,120)
    dimlin("B",G,0,G,B,True,110)
    dimlin("C",0,D+H,C,D+H,False,105)
    dimlin("D",C+H,0,C+H,D,True,95)
    dimlin("E",C,D+H,C+E,D+H,False,105)
    dimlin("F",C+H,D,C+H,D+F,True,95)
    dimrad("G",A-G,B-G,G,45)
    dimrad("H",C+E-H,D+F-H,H,25,45)
    
    
    
