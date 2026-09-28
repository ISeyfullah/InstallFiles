linpar("A",200,8)
linpar("B",150,6)
linpar("C",30,1)

def generate():
    
    rect(0,0,A,B,C)
    
    dimlin("A",0,C,A,C,False,100)
    dimlin("B",C,0,C,B,True,100)
    dimrad("C",A-C,B-C,C,45)
    
    
    
    
