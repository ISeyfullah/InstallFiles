
(DEFUN inTOmm (in) (* on 25.4))

(SETQ inradius 0 outradius 0 inangle 90 outangle 0 leadout 0 name "AWJ")
(SETQ circularleadin (+ (* *Piercingdiameter* 0.5) *Tooldiameter* 1))
(SETQ airleadin (+ (* *thickness* 0.12) (* *Tooldiameter* 0.5)))
(IF (< airleadin *Tooldiameter*) (SETQ airleadin *Tooldiameter*))
(SETQ altovercut (* *thickness* 0.25))
(SETQ gap 0.5)
(COND
  (*Lead-Hole*
     (SETQ alt 0)
     (SETQ cornerovercut 0)
     (SETQ cornerleadout (* *Tooldiameter* 0.5))
     (SETQ overcut (* *Tooldiameter* 0.5)))
  ((AND *GridHor* (< *Lead-Ysize* (* *GridDist* 1.5))) ; Make a tab if the part is to small in X
     (SETQ alt 1)
     (SETQ overcut (- (+ gap (* *ToolDiameter* 0.5)))) ; Make a negative overcut
     (SETQ cornerleadout 0)
     (SETQ cornerovercut (- (+ gap (* *ToolDiameter* 0.5))))) ;Make a negative overcut

  ((AND (NOT *GridHor*) (< *Lead-Xsize* (* *GridDist* 1.5))) ; Make a tab if the part is to small in Y
     (SETQ alt 2)
     (SETQ overcut (- (+ gap (* *ToolDiameter* 0.5))))
     (SETQ cornerleadout 0)
     (SETQ cornerovercut (- (+ gap (* *ToolDiameter* 0.5)))))
  (T ; No tab needed
     (SETQ alt 3)
     (SETQ overcut (* *Tooldiameter* 0.5))
     (SETQ cornerleadout (* *Tooldiameter* 0.5))
     (SETQ cornerovercut 0))
)
(COND
  ((< *Thickness* 30)
    (SETQ piercingtype 5) ; Airstart
    (SETQ leadin airleadin))
  (T
    (SETQ piercingtype 3) ;Circular piercing
    (SETQ leadin circularleadin))
)
(SETQ piercingtype (IF (< *Thickness* 30) 5 3)) ; 5=Airstart, 3=Circular
(COND
  (*Lead-Hole*
    (IF *Lead-Circle*
      (LEAD-SET 1 name *Tooldiameter* *Tooldiameter* 0 0 0 0 0 altovercut 0)
      (LEAD-SET 1 name leadin leadin inradius inangle leadout outradius outangle overcut piercingtype) ;Internal lead
    )
    (LEAD-SET 2 name leadin leadin inradius 5 cornerleadout 0 0 cornerovercut piercingtype) ;Corner lead
    (LEAD-SET 3 name *Tooldiameter* *Tooldiameter* 0 0 0 0 0 altovercut 0)) ; Alternative lead
  (T
    (LEAD-SET 0 name leadin leadin inradius inangle leadout outradius outangle overcut piercingtype) ; External lead
    (LEAD-SET 2 name leadin leadin inradius 5 cornerleadout 0 0 cornerovercut piercingtype) ;Corner lead
    (LEAD-SET 3 name *Tooldiameter* *Tooldiameter* 0 0 0 0 0 altovercut 0)) ;Alternative lead
)
; (LEAD-SET type name dynmax dynmin inradius inangle outlength outradius outangle overcut piercingtype)

; MACHINE INFORMATION
; *MachineName*
; *GridHor*
; *GridDist*
; *Tooldiameter*
; *MaxToolDiameter*
; *AWJOrifice*
; *AWJAbrasiveQuality*
; *AWJMixingTube*
; *AWJAbrasiveFlow*

; MATERIAL INFORMATION
; *Name*
; *Brittle*
; *Sandwiched*
; *Machinability*
; *Thickness*
; *Density*
; *LinearPiercing*
; *OvercutDistance*
; *MaxLeadLength*
; *MinLeadLength*
; *PiercingDiameter*

;PART INFORMATION
; *Lead-Hole* = T if it's an internal geometry else nil
; *Lead-Ysize* = The size in Y in mm
; *Lead-Xsize* = The size in X in mm
; *Lead-Closed* = T if the geometry is closed else nil
; *Lead-Length* = The perimeter if the geometry in mm
; *Lead-Area* = The area if the hole in the part else the area of the part
; *Lead-Circle* = T If it's a circular hole else nil


; (LEAD-SET type name dynmax dynmin inradius inangle outlength outradius outangle overcut piercingtype)
; Type : 0=Outer 1=Inner 2=Corner 3=Alternative
; If dynmin < dynmax then the lead will dynamic
; piercingtype 0=Blind, 1=Direct,2=Static, 3=Circular, 4=Drilling, 5=Airstart, 6=User
; inangle och outangle are in degree.








































