import math

intpar("N",4)
linpar("D",10,0.4)

def generate():
    moveto(0,0)

    totang = N*math.pi*2.0
    numseg = math.pi/(math.acos(1.0-0.005/(D*N)))
    dang = (2.0*math.pi)/numseg


    i=dang
    while i<totang:
        rad = (i/totang)*N*D
        lineto(rad*math.cos(i),rad*math.sin(i))
        i=i+dang

    rad=N*D
    lineto(rad*math.cos(0),rad*math.sin(0))

    arcfit(0,N*D/1000.0)

    dimlin("A",-35,0,-25,0,True,0)
    dimtxt("1",11,0)
    dimtxt("2",21,0)
    dimtxt("3",31,0)
    dimtxt("N",40,0)