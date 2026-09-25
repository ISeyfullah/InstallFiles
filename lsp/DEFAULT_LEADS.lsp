; Default_leads Date: 2024.June.18 by Bo Johansson

; 2023.April.26
; 2023.May.02
; 2024.Jan.15
; 2024.June 18 Change: *MaxLeadLength* is no longer used. Max lead length for dynamic leads are now 1.5* Thickness. But max 20.0 (used in brittle material)
; 2024 November 3. Added the variable below *Shortlead* that can be used for testing blind lead on machines that don't accept blind leads.
; 2024 November 11, Using the variable *ConvertLead* instead of *Shortlead* This is now handled from the Geometry tab in the postprocessor.
; 2025 March 25,

; Variables from the dialog box
;*TAB*= Tab size
;*TabMode*: 0=No tab, 1=Add tab, 2=Auto tab
;*Tabx* T if X size should be checked for Auto tab
;*Taby* T if Y size should be checked for auto tab
;*TabXSize* = Place tabs if X is smaller than this
;*TabYSize* = Place tab is Y is smaller than this
;*Lead-fac*= Lenght of Lead-in in relation to material thicknes (100=Material thickness)
; *Lead-prefereblind* = If this checkbox is activated


(IF (= *Revision* 1)
  (SETQ $jetAbrasiveOn *AWJDelayAfterPiercing*)
  (SETQ $JetAbrasiveOn *AWJDelayAbrasiveWaterOn*)
)
(SETQ tab *Tab*)
;Default values
(SETQ $maxtoolradie (* *MaxToolDiameter* 0.5))
(SETQ $cphole (IF *AWJAutomaticPiercing* (+ 1.4 *maxtooldiameter*) (+ *Piercingdiameter* *maxtooldiameter*))) ; The visual size of a circular piercing

; $ptype = Piercingtype: 0=Blind, 1=Linear, 2=Stationary, 3=Circular 4=Drilling, 5=Airstart
(SETQ $ptype (IF *Brittle* 3 1)) ; Set piercingtype to 3 if brittle else 1
; leadin
(SETQ $inlen (+ (* *thickness* (* *Lead-fac* 0.01)) $maxtoolradie))
(IF (< $inlen (* *Maxtooldiameter* 2)) (SETQ $inlen (* *Maxtooldiameter* 2.0)))
(IF *Brittle* (SETQ $inlen (+ $cphole 1)))
(SETQ $inlenmax (IF *brittle* *MaxLeadLength* $inlen))
(IF (< $inlenmax $inlen) (SETQ $inlenmax $inlen))
(SETQ $inlenblind (+ $maxtoolradie 0.1))

(SETQ $inradi 0) ; Leadin radius
(SETQ $inang 90) ; Leadin angle

(SETQ $outang 90) ;Leadout angle
(SETQ $outradi 0) ; Leadout radius
(SETQ $outlen (+ $maxtoolradie 0.05)) ;leadout length
(SETQ $overcut 0) ; Overcut distance

; Calculating the overcut-blind
; *Lead-Length* is the perimeter of the actual geometry. It is the same no matter of *InternalToolCompensation*
(SETQ fakediameter (/ *Lead-Length* PI)) ; Convert geometry length to fake circle diameter
(SETQ pathdiameter (- fakediameter *Tooldiameter*))
(SETQ factor (/ fakediameter pathdiameter))
(SETQ $overcutblind (* (* *Lead-fac* 0.01) *Thickness*))
(SETQ $overcutblind (* $overcutblind factor))

(SETQ $overcutcorner 0.0)
(SETQ $inangcorner (RADTODEG (ATAN (/ $maxtoolradie $inlen))))

(DEFUN showvars ()
  (ALERT (STRCAT "$INLENMAX: " (TOSTR $inlenmax) "\n$INLEN: " (TOSTR $inlen) "\n$INRADI: " (TOSTR $inradi) "\n$INANG: " (TOSTR $inang) "\n"
                 "\n$OUTLEN: " (TOSTR $outlen) "\n$OUTRADI: " (TOSTR $outradi) "\n$OUTANG: " (TOSTR $outang) "\n$OVERCUT: " (TOSTR $overcut) "\n$PTYPE: " (TOSTR $ptype)))
)
(COND
  (*Lead-Hole* ; ****** INTERNAL GEOMETRY ******
    (SETQ rot (ATAN $maxtoolradie $inlen))
    (SETQ mod (* (TAN rot) $maxtoolradie))
    (SETQ $inang (+ 90 (RADTODEG rot)))
    (SETQ $overcut (- *MaxToolDiameter* mod))
    (COND
      (*Sandwiched* ; In this case use a drill as piecing type
        (SETQ $ptype 4)
        (SETQ $inlen (+ (* *DrillDiameter* 0.5) 0.4))
        (SETQ $inlenmax (+ $inlen 4))
        (SETQ $inangcorner 15)
        (LEAD-SET 1 "Smart-internal" $inlenmax $inlen $inradi 90 $outlen $outradi $outang $overcut $ptype) ; Set internal
        (LEAD-SET 2 "Smart-corner" $inlenmax $inlen $inradi $inangcorner (* *Maxtooldiameter* 1.5) $outradi 0 (- $Maxtoolradie) $ptype) ; Set corner
        (LEAD-SET 3 "Smart-blind" $inlenblind $inlenblind $inradi $inang $outlen $outradi $outang $overcutblind 0)) ; Set internal
      (*Brittle* ; Make circular piercings
        (IF (AND *Lead-Pip* (OR (AND *tabx* (<= *Lead-Xsize* *tabxsize*)) (AND *taby* (<= *Lead-Ysize* *tabysize*))))
          (PROGN
            (SETQ rot (ASIN (/ $maxtoolradie $inlen)))
            (SETQ mod (* (TAN rot) $maxtoolradie))
            (SETQ $inang (+ 90 (RADTODEG rot)))
            (SETQ $overcut (+ (- *tab*) mod))))
        (SETQ $ptype 3) ; Circular
        (SETQ $inlen (+ (* $cphole 0.5) 1)) ; 1 mm from the edge
        (SETQ $inlenmax (* *Thickness* 1.5)) ; This was before *MaxLeadLength* but that variable is not used any more.
        (IF (> $inlenmax 20) (SETQ $inlenmax 20.0))
        (SETQ $ptype 3) ; Circular
        (SETQ $inangcorner 15)
        (SETQ $outlen (+ $maxtoolradie 0.15))
        (LEAD-SET 1 "Smart-internal" $inlenmax $inlen $inradi $inang $outlen $outradi $outang $overcut $ptype) ; Set internal
        (LEAD-SET 2 "Smart-corner" $inlenmax $inlen $inradi $inangcorner (* *Maxtooldiameter* 1.5) $outradi 0 (- $Maxtoolradie) $ptype) ; Set corner
        (LEAD-SET 3 "Smart-blind" $inlenblind $inlenblind $inradi $inang $outlen $outradi $outang $overcutblind 0) ; Set internal
        (PRIN "ALT: 1"))
      ((> *Thickness* 30)
        (SETQ $ptype 3) ; Allways circular because thickness > 30
        (SETQ $inlen (+ (* $cphole 0.5) 1)) ; 1mm from the edge
        (SETQ $inlenmax $inlen)
        (LEAD-SET 1 "Smart-internal" $inlenmax $inlen $inradi $inang $outlen $outradi $outang $overcut $ptype) ; Set internal
        (SETQ $outlen $maxtoolradie $overcut 0.0 $outang 0.0)
        ;(SHOWVARS)
        (LEAD-SET 2 "Smart-corner" $inlenmax $inlen $inradi $inangcorner $outlen $outradi $outang $overcut $ptype); Set corner
        (SETQ $inradi $maxtoolradie $inang 110)
        (SETQ $outlen 0 $outang 0)
        (SETQ $inlenmax $inlenblind $inlen $inlenblind $overcut $overcutblind)
        (SETQ $ptype 0)
        ;(SHOWVARS)
        (LEAD-SET 3 "Smart-blind" $inlenmax $inlen $inradi $inang $outlen $outradi $outang $overcut $ptype) ; Set alternative
        (PRIN "ALT:2"))
      ((NOT *Lead-PreferBlind*) ; Linear piercing
        (IF (AND *Lead-Pip* (OR (AND *tabx* (<= *Lead-Xsize* *tabxsize*)) (AND *taby* (<= *Lead-Ysize* *tabysize*))))
          (PROGN
            (SETQ rot (ASIN (/ $maxtoolradie $inlen)))
            (SETQ mod (* (TAN rot) $maxtoolradie))
            (SETQ $inang (+ 90 (RADTODEG rot)))
            (SETQ $overcut (+ (- *tab*) mod))))
        (SETQ $ptype 1) ; Linear piercing
        (SETQ $inlen (+ (* *thickness* (* *Lead-fac* 0.01)) $maxtoolradie))
        (IF (< $inlen (* *Maxtooldiameter* 2)) (SETQ $inlen (* *Maxtooldiameter* 2.0)))
        (SETQ $inlenmax $inlen)
        (LEAD-SET 1 "Smart-internal" $inlenmax $inlen $inradi $inang $outlen $outradi $outang $overcut $ptype) ; Set internal
        (SETQ $outlen $maxtoolradie $overcut 0.0 $outang 0.0)
        ;(SHOWVARS)
        (LEAD-SET 2 "Smart-corner" $inlenmax $inlen $inradi $inangcorner $outlen $outradi $outang $overcut $ptype); Set corner
        (SETQ $inradi $maxtoolradie $inang 110)
        (SETQ $outlen 0 $outang 0)
        (SETQ $inlenmax $inlenblind $inlen $inlenblind $overcut $overcutblind)
        (SETQ $ptype 0)
        ;(SHOWVARS)
        ;(IF *ConvertLead* (SETQ $inradi 0))
        ;(SETQ $inang 120)
        (LEAD-SET 3 "Smart-blind" $inlenmax $inlen $inradi $inang $outlen $outradi $outang $overcut $ptype) ; Set alternative
        (PRIN "ALT:3"))
      (*Lead-PreferBlind*
        (SETQ $outlen $maxtoolradie $overcut 0.0 $outang 0.0)
        ;(SHOWVARS)
        (LEAD-SET 2 "Smart-corner" $inlenmax $inlen $inradi $inangcorner (* *Maxtooldiameter* 1.5) $outradi 0 (- $Maxtoolradie) $ptype); Set corner
        (SETQ $inradi $maxtoolradie $inang 110)
        ;(IF *ConvertLead* (SETQ $inradi 0.0))
        (SETQ $outlen 0 $outang 0)
        (SETQ $inlenmax $inlenblind $inlen $inlenblind $overcut $overcutblind)
        (SETQ $ptype 0)
        (LEAD-SET 1 "Smart-blind" $inlenblind $inlenblind $inradi $inang $outlen $outradi $outang $overcutblind $ptype) ; Set internal
        (LEAD-SET 3 "Smart-blind" $inlenblind $inlenblind $inradi $inang $outlen $outradi $outang $overcutblind $ptype) ; Set alternative
        (PRIN "ALT:4"))
    )
  )

  ((NOT *Lead-Hole*) ; ****** EXTERNAL GEOMETRY ******
    (COND
      ((= *tabmode* 0) (SETQ dotab nil))
      ((= *tabmode* 1) (SETQ dotab T))
      ((OR (AND *tabx* (<= *Lead-Xsize* *tabxsize*)) (AND *taby* (<= *Lead-Ysize* *tabysize*)))
        (SETQ dotab T))
      (T (SETQ dotab nil))
    )
    (IF dotab
      (PROGN
        (SETQ rot (ASIN (/ $maxtoolradie $inlen)))
        (SETQ mod (* (TAN rot) $maxtoolradie))
        (SETQ $inang (+ 90 (RADTODEG rot)))
        (SETQ $overcut (+ (- *tab*) mod)))
      (PROGN
        (SETQ rot (ATAN $maxtoolradie $inlen))
        (SETQ mod (* (TAN rot) $maxtoolradie))
        (SETQ $inang (+ 90 (RADTODEG rot)))
        (SETQ $overcut (- *MaxToolDiameter* mod)))
    )
    ;(ALERT (STRCAT "TABMODE:" (TOSTR *tabmode*) " TABX:" (TOSTR *tabx*) " TABXSIZE:" (TOSTR (TOSTR *tabxsize*)) " TABY:" (TOSTR *taby*) " TABYSIZE:" (TOSTR *tabysize*) " SIZEX:" (TOSTR *Lead-xsize*) " SIZEY:" (TOSTR *Lead-ysize*)))
    (COND
      (*Sandwiched* ; In this case use a drill as piecing type
        (SETQ $ptype 4)
        (SETQ $inlen (+ (* *DrillDiameter* 0.5) 2))
        (SETQ $inlenmax $inlen)
        (SETQ $inangcorner 15)
        (LEAD-SET 0 "Smart-external" $inlenmax $inlen $inradi $inang $outlen $outradi $outang $overcut $ptype) ; Set internal
        (LEAD-SET 2 "Smart-corner" $inlenmax $inlen $inradi $inangcorner (* *Maxtooldiameter* 1.5) $outradi 0 (- $Maxtoolradie) $ptype) ; Set corner
        (LEAD-SET 3 "Smart-blind" $inlenblind $inlenblind $inradi $inang $outlen $outradi $outang $overcutblind 0)) ; Set internal

      (*Brittle* ; Make circular piercings
        (SETQ $ptype 3) ; Circular
        (SETQ $inlen (+ (* $cphole 0.5) 1)) ; 1 mm from the edge
        (SETQ $inlenmax 10)
        (SETQ $inangcorner 15)
        (SETQ $ptype 3) ; Circular
        (LEAD-SET 0 "Smart-external" $inlenmax $inlen $inradi $inang $outlen $outradi $outang $overcut $ptype) ; Set internal
        (LEAD-SET 2 "Smart-corner" $inlenmax $inlen $inradi $inangcorner (* *Maxtooldiameter* 1.5) $outradi 0 (- $Maxtoolradie) $ptype) ; Set corner
        (LEAD-SET 3 "Smart-blind" $inlenblind $inlenblind $inradi $inang $outlen $outradi $outang $overcutblind 0) ; Set internal
        (PRIN "ALT: A"))

      ((> *Thickness* 30)
        (SETQ $ptype 3) ; Allways circular because thickness > 30
        (SETQ $inlen (+ (* $cphole 0.5) 1)) ; 1mm from the edge
        (IF dotab (SETQ $inlen (+ $inlen 1.0))) ; To avoid that tab measure to piercing hole
        (SETQ $inlenmax $inlen)
        (LEAD-SET 0 "Smart-external" $inlenmax $inlen $inradi $inang $outlen $outradi $outang $overcut $ptype) ; Set internal
        (SETQ $outlen $maxtoolradie $outang 0.0)
        (IF dotab (SETQ $outang 90))
        ;(SHOWVARS)

        (LEAD-SET 2 "Smart-corner" $inlenmax $inlen $inradi $inangcorner $outlen $outradi $outang $overcut $ptype); Set corner
        (SETQ $inradi $maxtoolradie $inang 90)
        (SETQ $outlen 0 $outang 0)
        (SETQ $inlenmax $inlenblind $inlen $inlenblind $overcut $overcutblind)
        (SETQ $ptype 0)
        ;(SHOWVARS)
        (LEAD-SET 3 "Smart-blind" $inlenmax $inlen $inradi $inang $outlen $outradi $outang $overcut $ptype) ; Set alternative
        (PRIN "ALT:B"))
      ((NOT *Lead-PreferBlind*) ; Linear piercing
        (SETQ $ptype 1) ; Linear piercing
        (SETQ $inlen (+ (* *thickness* (* *Lead-fac* 0.01)) $maxtoolradie))
        (IF (< $inlen (* *Maxtooldiameter* 2)) (SETQ $inlen (* *Maxtooldiameter* 2.0)))
        (SETQ $inlenmax $inlen)
        (LEAD-SET 0 "Smart-external" $inlenmax $inlen $inradi $inang $outlen $outradi $outang $overcut $ptype) ; Set internal
        (SETQ $outlen $maxtoolradie $overcut 0.0 $outang 0.0)
        ;(SHOWVARS)
        (IF dotab
          (SETQ $outlen $Maxtoolradie $outang 90 $overcut (- *tab*))
          (SETQ $outlen $maxtoolradie $outang 0 $overcut 0)
        )
        (LEAD-SET 2 "Smart-corner" $inlenmax $inlen $inradi $inangcorner $outlen $outradi $outang $overcut $ptype); Set corner
        (SETQ $inradi $maxtoolradie $inang 90)
        (SETQ $outlen 0 $outang 0)
        (SETQ $inlenmax $inlenblind $inlen $inlenblind $overcut $overcutblind)
        (SETQ $ptype 0)
        ;(SHOWVARS)
        (LEAD-SET 3 "Smart-blind" $inlenmax $inlen $inradi $inang $outlen $outradi $outang $overcut $ptype) ; Set alternative
        (PRIN "ALT:C"))
      (*Lead-PreferBlind*
        (SETQ $inangcorner 15 $outlen $maxtoolradie $overcut 0.0 $outang 0.0)
        ;(SHOWVARS)
        (LEAD-SET 2 "Smart-corner" $inlenmax $inlen $inradi $inang (* *Maxtooldiameter* 1.5) $outradi 0 (- $Maxtoolradie) $ptype); Set corner
        (SETQ $inradi $maxtoolradie $inang 90)
        (SETQ $outlen 0 $outang 0)
        (SETQ $inlenmax $inlenblind $inlen $inlenblind $overcut $overcutblind)
        (SETQ $ptype 0)
        (LEAD-SET 0 "Smart-blind" $inlenblind $inlenblind $inradi $inangcorner $outlen $outradi $outang $overcutblind $ptype) ; Set internal
        (LEAD-SET 3 "Smart-blind" $inlenblind $inlenblind $inradi $inang $outlen $outradi $outang $overcutblind $ptype) ; Set alternative
        (PRIN "ALT:D"))
    )
  )
)



; (LEAD-SET type name dynmax dynmin inradius inangle outlength outradius outangle overcut piercingtype)

; MACHINE INFORMATION
; *InternalToolCompensation* 0=Calculate in IGEMS, 1=Mixed, 2=Calculated in Controller
; *MachineName*
; *GridHor*
; *GridDist*
; *Tooldiameter*
; *MaxToolDiameter*
; *AWJOrifice*
; *AWJAbrasiveQuality*
; *AWJMixingTube*
; *AWJAbrasiveFlow*
; *Revision* Can be 1 or 2
; *ConvertLead* 


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
; *Lead-Ysize* = The size in Y in mm of the toolpath
; *Lead-Xsize* = The size in X in mm of the toolpath
; *Lead-Closed* = T if the geometry is closed else nil
; *Lead-Length* = The perimeter if the geometry in mm
; *Lead-Area* = The area if the hole in the part else the area of the part
; *Lead-Circle* = T If it's a circular hole else nil
; *Lead-Quality* 1=Xrough, 2=Rough, 3=Medium, 4=Fine, 5=X-fine
; *Lead-*Pip* = Is T if ther is a part inside the hole.


; (LEAD-SET type name dynmax dynmin inradius inangle outlength outradius outangle overcut piercingtype)
; Type : 0=Outer 1=Inner 2=Corner 3=Alternative
; If dynmin < dynmax then the lead will dynamic
; piercingtype 0=Blind, 1=Linear,2=Static, 3=Circular, 4=Drilling, 5=Airstart, 6=User
; inangle och outangle are in degree.








































