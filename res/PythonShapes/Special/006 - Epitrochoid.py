import math

linpar("a:A",160,6)
linpar("b:B",200,8)
intpar("n:N",5);

def generate():
    # compute parameters of the epitrochoid parametric formula:
    r = 0.5 * ((a + b) / (n + 1.0));
    R = n * r;
    d = abs(a - b) / 2.0;

    #seqang = (math.pi*2.0)/n; #angle of one sequence


    first=True

    for q in range(0,1000):
        t=(math.pi*2.0/1000.0)*q
        x = (R + r) * math.cos(t) + d * math.cos(((r + R) / r) * t)   
        y = (R + r) * math.sin(t) + d * math.sin(((r + R) / r) * t)
        if first:
            cntrindex=moveto(x,y)
        else:
            lineto(x,y)
        first=False


    close()

    arcfit(cntrindex,max(a,b)/1000.0)

