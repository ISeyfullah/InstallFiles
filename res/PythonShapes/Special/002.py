import math

linpar("a:A",100,3.9)
linpar("b:B",200,7.9)
intpar("c:N",5)

def generate():
    deltaangle=math.pi*2/c # delta angle per tip
    curang=math.pi/2.0 # first tip at 0.0
    hd=deltaangle/2.0 #half delta angle
    
    moveto(math.cos(curang-hd)*a,math.sin(curang-hd)*a)
    for i in range(0,c):
        lineto(math.cos(curang)*b,math.sin(curang)*b)
        lineto(math.cos(curang+hd)*a,math.sin(curang+hd)*a)
        curang=curang+deltaangle

    close()


    dimlin("B",0,0,0,b,True,0)
    v=math.pi/2.0+deltaangle*3.5
    dimlin("A",0,0,math.cos(v)*a,math.sin(v)*a,True,0)
    dimtxt("1",math.cos(math.pi/2)*b,math.sin(math.pi/2+0)*b)
    dimtxt("2",math.cos(math.pi/2+deltaangle)*b,math.sin(math.pi/2+deltaangle)*b)
    dimtxt("3",math.cos(math.pi/2+deltaangle*2)*(b+10),math.sin(math.pi/2+deltaangle*2)*(b+10))
    dimtxt("4",math.cos(math.pi/2+deltaangle*3)*(b+10),math.sin(math.pi/2+deltaangle*3)*(b+10))
    dimtxt("N",math.cos(math.pi/2+deltaangle*4)*b,math.sin(math.pi/2+deltaangle*4)*b)




