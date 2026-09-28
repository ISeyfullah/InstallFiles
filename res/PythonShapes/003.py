linpar("A",200,8)
linpar("B",100,6)
linpar("C",20,1)
linpar("D",20,1)
linpar("E",160,6)
linpar("F",60,4)

def generate():
    
    rect(0,0,A,B)
    rect(C,D,C+E,D+F)
    
    dimlin("A",0,0,A,0,False,64)
    dimlin("B",0,0,0,B,True,70)
    dimlin("C",0,D,C,D,False,74)
    dimlin("D",C,0,C,D,True,70)
    dimlin("E",C,D,C+E,D,False,74)
    dimlin("F",C,D,C,D+F,True,70)
    
    
    
