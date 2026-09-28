realpar("r1:R1",200)
realpar("r2:R2",100)

def generate():
    d1=r1*2.0
    d2=r2*2.0


    moveto(d1+d2,0)
    arcto(0,0,(d1+d2)*0.5,0,True)
    arcto(d1,0,d1*0.5,0,False)
    arcto(d1+d2,0,d1+d2*0.5,0,False)
    close()

    dimrad("R1",r1,0,r1,45)
    dimrad("R2",r1*2+r2,0,r2,45)