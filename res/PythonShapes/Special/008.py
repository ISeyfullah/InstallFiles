import clr
from math import *

clr.AddReference("IGEMS")

from IGS.IGEMS.ParamPartsPython import SpurGear


realpar("M:Module", 10)
intpar("N", 12)
angpar("A", 20)
realpar("AD", 1.0)
realpar("DD", 1.25)
linpar("D",20,0.8)


def generate():
    profile=SpurGear.Generate(M,N,A,AD,DD)
    polygeom(profile)
    circle(0,0,D*0.5) #center hole

    dang=radians(15)
    dimtxt("1",cos(dang*0.5)*55,sin(dang*0.5)*55+4)
    dimtxt("2",cos(dang*2.5)*55-4,sin(dang*2.5)*55+4)
    dimtxt("3",cos(dang*4.5)*55-6,sin(dang*4.5)*55+4)
    dimtxt("4",cos(dang*6.5)*55-8,sin(dang*6.5)*55)
    dimtxt("N",cos(dang*8.5)*55-8,sin(dang*8.5)*55-6)
    dimdia("D",0,0,D,45)
    dimtxt("A=Pressure angle",0,-18)
    dimtxt("AD=Addendum factor",0,-28)
    dimtxt("DD=Dedentum factor",0,-38)
    
    #string txt, double xc, double yc, double dia, double ang


