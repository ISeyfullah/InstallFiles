(SETQ *postinit* 2706)
(SETQ datum "2023.January.21") ; Cleaning up the postprocessor and remove things not longer used.
(SETQ datum "2023.May.02") ; Added warnings if not important options are activated.
(SETQ datum "2023.October.18") ;fistrun and lastrun support added
(SETQ datum "2023.December.13") ; added check for dangerzone
(SETQ datum "2023.December.20" ) ; if measure in advance is used, we set Zbase to table.
(SETQ datum "2024.January.03") ; added rotax check.
(SETQ datum "2024.Januray.05") ; added  P0 in T3.
(SETQ datum "2024.January.12") ; Added CAM-PARTGEOM a test for colored parts
(SETQ datum "2024.February.09") ; Added metric/imperial metadata.
(SETQ datum "2024.February.13") ;Part geometry and sheet geometry is now encoded as a base64 string.
(SETQ datum "2024.April.02"); Added M01 with P values. P1=After each geometry, P2=Before new part, P4=Used defined in CNC
(SETQ datum "2024.April.24") ; CHTOOL is now always called even if the machine has one jet. In the footer $ENDPART is changed to $PARTEND
(SETQ datum "2024.October.01") ;MeasureInAdvenge Updated (SETG/GETG/MEASURE-CLEAR)
(SETQ datum "2024.November.13") ;Pump Off Code Changed from M51 to M49.

(PRINC (STRCAT "Loading IGEMS CNC V5.IPF Date [" datum "].."))
(SETQ *IS-IGEMS-CNC* T)
(SETQ $stopbit 0) ; Handle the optional stop 1=Stop after geometry, 2=Stop after part, 4=User stop




(DEFUN header()
  (IF $AngleIpo
    (QUIT "Quit Angle IPO not allowed."))

  (IF (NOT $ZAxisOption) (SETQ $ZAxisOption* *ZAxisOption*)) ; To support older versions off IGEMS (Before 2023.1)
  (IF (= *zaxisoption 3) (SETQ *zbase 0))

  (WRITE (STRCAT "$METRIC: " (IF $metric "1" "0")))
  (WRITE (STRCAT "$INFO: DATE: " $date))
  (IF (= $machinetype 0)
    (PROGN
      (WRITE (STRCAT "$ORIFICE: " (RTS $orifice)))
      (WRITE (STRCAT "$TUBE: " (RTS $tube)))
      (WRITE (STRCAT "$ABRFLOW: " (RTS $cutflow)))
    )
  )
  (WRITE (STRCAT "$CAMPOS: " (RTS (CAR *ZeroPoint*)) " " (RTS (CADR *ZeroPoint*))))
  (WRITE (STRCAT "$MATERIAL: " $group))
  (WRITE (STRCAT "$THICKNESS: " (RTS $thickness)))
  (WRITE (STRCAT "$DENSITY: " (RTS $density)))
  (WRITE (STRCAT "$UNDERLAY: " (RTS $underlay)))
  (WRITE (STRCAT "$DIGFILE: " $digfile))
  (WRITE (STRCAT "$FEEDROUGH: " (RTF $rough)))
  (WRITE (STRCAT "$COMPMODE: " (IF *3D-5X* "0" (ITOA *InternalToolCompensation*))))
  (WRITE (STRCAT "$SHEETNAME: " $sheetname))
  (WRITE (STRCAT "$MAXTOOLDIAM: " (RTS *MaxToolDiameter*)))
  (WRITE (STRCAT "$SHEETGEOMETRY: " (TOSTR (CAM-SHEETGEOMB64))))
  (IF $dangerzone (WRITE (STRCAT "$TILTZONE:" (RTS (NTH 0 $dangerzone)) " " (RTS (NTH 1 $dangerzone)) " " (RTS (NTH 2 $dangerzone)) " " (RTS (NTH 3 $dangerzone)))))
  (IF *UseSixAxis* (WRITE (STRCAT "$SENSORFORBIDDEN:")))
  (SETQ msgstr (STRCAT (IF (NOT $SpeedIpo) " FIPO" "")(IF (NOT $tac) " TAC" "") (IF (NOT $voc) " VOC" "") (IF (NOT $lag) " LAG" "") (IF (NOT $flyonoff) " FLYCTR" "") (IF (NOT $kerfcnc) " KERF" "")))
  (IF (AND *IGEMSLAB* (> (STRLEN msgstr) 0))
    (PROGN
      (WRITE (ALERT (STRCAT "$INFO:" msgstr " is off")))
      (WRITE (STRCAT "(ALERT " (STRCAT (CHR 34) msgstr " is off" (CHR 34)) ")"))))
  (IF *UseSixAxis*
    (PROGN
      (WRITE (STRCAT (NTXT) "G93 ; Speed in seconds"))
      (SETQ invtime T))
    (PROGN
      (WRITE (STRCAT (NTXT) "G94 ; Speed in mm/min"))
      (SETQ invtime nil))
  )
  (COND
    ((= *ZAxisOption* 2) nil) ;Using height sensor
    (T  (WRITE (STRCAT "$SENSORFORBIDDEN:")))
  )
  (WRITE (STRCAT (NTXT) "G100 G90"))
  (WRITE (STRCAT (NTXT) "G100 " (IF $metric "G21" "G20")))
  (WRITE "(IF #FIRSTRUN (CNC G100 M51))")
  (IF (NOT $xtoolinit) (SETQ $xtoolinit 0.0 $ytoolinit 0.0))
  (COND
  ;(T nil)
    ((NOT *IGEMSLAB*) nil)
    ((NOT $singularity) ; Using Tilter
      (WRITE (STRCAT (NTXT) "G700 P2 X" (RTS $xtoolinit) " Y" (RTS $ytoolinit) " T1")))
    (T
      (WRITE (STRCAT (NTXT) "G700 P1 X" (RTS $xtoolinit) " Y" (RTS $ytoolinit) "T2")))
  )
)

(DEFUN measure ()
  (IF *MeasureOffsetbyController*
    (WRITE (STRCAT (NTXT) "G0 X" (RTS $x) " Y" (RTS $y)))
    (WRITE (STRCAT (NTXT) "G0 X" (RTS (+ $x *ZMeasureXOffset*)) " Y" (RTS (+ $y *ZMeasureYOffset*))))
  )
  (WRITE (STRCAT (NTXT) "G4 S0.1"))
  (WRITE (STRCAT (NTXT) "(SETG " (ITOA $zref) " (MEASUREHEIGHT))"))
  (SIM-DELAY 1)
)

(DEFUN measureoriginal ()
  (IF *MeasureOffsetbyController*
    (WRITE (STRCAT (NTXT) "G0 X" (RTS $x) " Y" (RTS $y)))
    (WRITE (STRCAT (NTXT) "G0 X" (RTS (+ $x *ZMeasureXOffset*)) " Y" (RTS (+ $y *ZMeasureYOffset*))))
  )
  (WRITE (STRCAT (NTXT) "G4 S0.1"))
  (WRITE (STRCAT (NTXT) "(SETQ R" (ITOA $zref) " (MEASUREHEIGHT))"))
  (SIM-DELAY 1)
)

(DEFUN chtool ()
  (COND
    ((= $maxtools 1) (WRITE (STRCAT (NTXT) "G700 P0 T1")))
    ((= $tools 1) (WRITE (STRCAT (NTXT) "G700 P2 X" (RTS $x) " Y" (RTS $y) " T1"))) ; Park head P2 use T1
    ((= $tools 2) (WRITE (STRCAT (NTXT) "G700 P1 X" (RTS $x) " Y" (RTS $y) " T2"))) ; Park head P1 use T2
    ((= $tools 3) (WRITE (STRCAT (NTXT) "G700 P0 L" (RTS (CAR $toollist)) " X" (RTS $x) " Y" (RTS $y) " T3"))) ; Use T1 and T2

  )
)

(DEFUN refpos () nil)

(DEFUN rapid()
  (SETQ bevstr (IF $ab (STRCAT " A" (ATS $a) " B" (ATS $b)) ""))
  (SETQ rotstr (IF $uses6x (STRCAT " C" (ATS $c)) ""))
  (COND
    ((= $reason 3)
      (WRITE (STRCAT (NTXT) "G0 X" (RTS $x) " Y" (RTS $y) " ;TO SENSOR POSITION")))
    ((MEMBER $reason (LIST 4 5)) ; Include Z in the movement
      (WRITE (STRCAT (NTXT) "G0 X" (RTS $x) " Y" (RTS $y) " Z" (RTS $z) bevstr rotstr))
      (IF (NOT breakon) (WRITE (STRCAT (NTXT) "M01 P"(ITOA (+ 1 $stopbit)))))
      (SETQ breakon T))
    (T
      (WRITE (STRCAT (NTXT) "G0 X" (RTS $x) " Y" (RTS $y) bevstr rotstr))
      (IF (NOT breakon) (WRITE (STRCAT (NTXT) "M01 P"(ITOA (+ 1 $stopbit)))))
      (SETQ breakon T))
  )
  (SETQ $stopbit 0)
)

(DEFUN tilt()
  (IF (= $reason 4) (SETQ $arel $a $brel $b))
  (SETQ rotstr (IF $uses6x (STRCAT " C" (ATS $c)) ""))
  (IF (< $tools 3) (WRITE (STRCAT (NTXT) "G0 A" (ATS $a) " B" (ATS $b) rotstr)))
  (IF (< $a mina)(SETQ mina $a)) (IF (> $a maxa) (SETQ maxa $a))
)

(DEFUN drilling ()
  (WRITE (STRCAT "G83 X" (RTS $x) " Y" (RTS $y) " Z" (RTS $z) " U" (RTS $depth) " V" (RTS $drillstep) " P" (RTS $zclearens) " Q2" " F" (RTF $f)))
)

(DEFUN tooldown ()
  (SETQ zstr (ZREFSTR $z))
  (COND
    ( *usesixaxis*
       (WRITE (STRCAT (NTXT) "G0" zstr)))
    ((= $reason 2) ; Do a separate probing before drilling
      (IF (MINUSP $sensor) (WRITE (STRCAT (NTXT) "M63" (MSG "FORCE SENSORING"))))
      (WRITE (STRCAT (NTXT) "M64 P" (ITOA (ABS $sensor)) zstr (MSG "Z-Probe"))))
    ((> $zmode 3) ;Sensor should be used
      (IF (MINUSP $sensor)
        (PROGN
           (WRITE (STRCAT (NTXT) "M63" (MSG "FORCE SENSORING")))))
      (WRITE (STRCAT (NTXT) "M64 P" (ITOA (ABS $sensor)) zstr  (MSG "CONTOUR ON")))
      (SETQ sensoron T))
    (T           ; Z-cordinates No sensor
      (WRITE (STRCAT (NTXT) "M62" (MSG "CONTOUR ON")))
      (WRITE (STRCAT (NTXT) "G0" zstr)))
  )
  (SETQ breakon T)
)


(DEFUN tooldown3d ()
  (WRITE (STRCAT (NTXT) "M62" (MSG "CONTOUR ON")))
  (SETQ zstr (ZREFSTR $z))
  (WRITE (STRCAT (NTXT) "G0 X" (RTS $x) " Y" (RTS $y) zstr (MSG "(TOOLDOWN 3D)")))
)


(SETQ orginaltext text)

(DEFUN text ()
  (SETQ plats (STRFIND "#" $txt))
  (IF plats
    (PROGN
      (SETQ txtlist (CONS $txt txtlist))
      (SETQ q 0)
      (FOREACH s txtlist
        (IF (EQUAL s $txt) (SETQ q (1+ q)))
      )
      (SETQ $txt (STRCAT (STRSUB $txt 1 plats) (ITOA q)))
    )
  )
  (ORGINALTEXT)
)

(SETQ *CustomCircularPiercing* T)

(DEFUN piercing()
  (IF (= $ptype 0) (SETQ $time 0)) ;If blind lead, no delays.
  (WRITE (STRCAT (NTXT) ";" (NTH $ptype (LIST "BLIND LEAD" "LINEAR PIERCING" "STATIC PIERCING" "CIRCULAR PIERCING" "DRILLING" "AIR START" "USER START"))))
  (COND
    ($jetpreload
      (WRITE (STRCAT (NTXT) "M7" (MSG "ABRASIVE ON")))
      (DELAY $jetpreload)
      (WRITE (STRCAT (NTXT) "M3" (MSG "WATER ON")))
      (DELAY $JetValveOn))
    ((AND $useabr $wacode)
      (WRITE (STRCAT (NTXT) "M3" (MSG "WATER ON")))
      (DELAY $JetValveOn)
      (WRITE (STRCAT (NTXT) "M7" (MSG "ABRASIVE ON")))
      (DELAY $JetAbrasiveOn))
    (T
      (WRITE (STRCAT (NTXT) "M3" (MSG "WATER ON")))
      (DELAY $jetValveOn))
  )
  (IF $circ
    (PROGN
      (CPIERC-LINE T);
      (WRITE (STRCAT "(REPEAT " (ITOA $cpturns)))
      (WRITE (STRCAT "  (CNC"))
      (CPIERC-CIRCLE)
      (WRITE (STRCAT "  )"))
      (WRITE (STRCAT ")"))
      (CPIERC-LINE nil))
    (PROGN
      (DELAY $time))
  )
  ;(WRITE (STRCAT (NTXT) "G4 P0"))
  ;(WRITE (STRCAT (NTXT) "(STOPWATCH-START)"))   By Horst
  (SETQ breakon nil)
)

(DEFUN fmode ()
  (COND
    ((= $flin 0) ; Deactivate time mode
      (WRITE (STRCAT (NTXT) "G193" (MSG "SPEED IPO OFF"))))
    ((= $flin 1) ; Activate FLIN
      (WRITE (STRCAT (NTXT) "G194 F" (RTS $fs) (MSG "SPEED IPO ON"))))
    ((= $flin 2) ; New start value
      (WRITE (STRCAT (NTXT) "G1 F" (RTF $fs))))
  )
)


(DEFUN zrefstr ($z)
  (COND
    ((NOT $zreftype)
      (STRCAT " Z" (RTS $z)))
    ((= $zreftype 0) ; Use one measure point
      (STRCAT " Z(" (ITOA (CAR (+ $zrefs 100))) ")"))
    ((= $zreftype 1) ; Use two measure points
    (STRCAT " Z(+(* (GETG " (ITOA (NTH 0 $zrefs)) ") " (RTOS (NTH 1 $zrefs) 3)")(* (GETG " (ITOA (NTH 2 $zrefs)) ") " (RTOS (NTH 3 $zrefs) 3) "))"))
    ((OR (= $zreftype 2) (= $zreftype 3))
    (STRCAT " Z(+(* (GETG " (ITOA (NTH 0 $zrefs)) ") " (RTOS (NTH 1 $zrefs) 3)")(* (GETG " (ITOA (NTH 2 $zrefs)) ") " (RTOS (NTH 3 $zrefs) 3) ")(* (GETG " (ITOA (NTH 4 $zrefs)) ") " (RTOS (NTH 5 $zrefs) 3) "))"))
  )
)

(DEFUN line3D ()
  (WRITE (STRCAT "G1 X" (RTS $x) " Y" (RTS $y) " Z" (RTS $z) " F" (RTF $fe) " (LINE3D)"))
)

(DEFUN line ()
  (SETQ bevstr (IF $ab (STRCAT " A" (ATS $a) " B" (ATS $b)) ""))
  (SETQ rotstr (IF $uses6x (STRCAT " C" (ATS $c)) ""))
  (SETQ feedstr (STRCAT " F" (RTF $fe)))
  (SETQ zstr (ZREFSTR $z))
  (IF invtime (SETQ feedstr (STRCAT " F" (FINV $ft) " ;" (RTF $fe) " mm/min")))
  (IF (= $tools 3) (SETQ bevstr ""))
  (COND
    ($chkerf
      (WRITE (STRCAT (NTXT) "G1 G4" (ITOA $kerf) " X" (RTS $x) " Y" (RTS $y) zstr bevstr rotstr feedstr)))
    (T
      (WRITE (STRCAT (NTXT) "G1 X" (RTS $x) " Y" (RTS $y) zstr bevstr rotstr feedstr)))
  )
)

(DEFUN arc (/ newpt)
  (SETQ bevstr (IF $ab (STRCAT " A" (ATS $a) " B" (ATS $b)) ""))
  (IF (= $tools 3) (SETQ bevstr ""))
  (SETQ rotstr (IF $uses6x (STRCAT " C" (ATS $c)) ""))
  (SETQ feedstr (STRCAT " F" (RTF $fe)))
  (SETQ zstr (ZREFSTR $z))
  (IF invtime (SETQ feedstr (STRCAT " F" (FINV $ft) " ;" (RTF $fe) " mm/min")))
  (COND
    ($ccw
      (WRITE (STRCAT (NTXT) "G3 X" (RTS $X) " Y" (RTS $Y) " I" (RTS $I) " J" (RTS $J) zstr bevstr rotstr feedstr)))
    (T
      (WRITE (STRCAT (NTXT) "G2 X" (RTS $X) " Y" (RTS $Y) " I" (RTS $I) " J" (RTS $J) zstr bevstr rotstr feedstr)))
  )
)

(DEFUN flyctrl ()
  (COND
    ((= $reason 1) (WRITE (STRCAT (NTXT) "M3" (MSG "FLYING WATER ON")))) ; Not yet implemented
    ((= $reason 2) (WRITE (STRCAT (NTXT) "M7" (MSG "FLYING ABRASIVE ON")))) ; Not yet implemanted
    ((= $reason 3) (WRITE (STRCAT (NTXT) "M9" (MSG "FLYING ABRASIVE OFF"))))
    ((= $reason 4) (WRITE (STRCAT (NTXT) "M5" (MSG "FLYING WATER OFF"))))
  )
)

(DEFUN cutoff ()
  (IF $Jetabrasiveoff
    (PROGN
      (WRITE (STRCAT (NTXT) "M9" (MSG "ABRASIVE OFF")))
      (DELAY $JetabrasiveOff)))
  (IF $JetValveOff
    (PROGN
      (WRITE (STRCAT (NTXT) "M5" (MSG "WATER OFF")))
      (DELAY $jetvalveoff)))
  (IF $chkerf (WRITE (STRCAT (NTXT) "G4" (ITOA $kerf))))
 )

(DEFUN toolup ()
  (IF (/= $reason 1) (WRITE (STRCAT (NTXT) "M65" (MSG "CONTOUR OFF"))))
  (COND
    ((= $reason 1) nil) ; In the beginning of the file
    ((= $reason 2) nil) ; Not used in drilling
    (T
      (WRITE (STRCAT (NTXT) "G0 Z" (RTS $z))))
  )
  (SETQ sensoron nil)
)

(DEFUN toolup3D ()
  (WRITE (STRCAT (NTXT) "M65" (MSG "CONTOUR OFF")))
  (WRITE (STRCAT (NTXT) "G0 X" (RTS $x) " Y" (RTS $y) " Z" (RTS $z)))
  (SETQ sensoron nil)
)

(DEFUN delay (value)
  (IF (> value 0.04) (WRITE (STRCAT (NTXT) "G4 S" (RTT value))))
)

(DEFUN part()
  (WRITE "")
  (SETQ $stopbit (+ $stopbit 2))
  (WRITE (STRCAT "$PARTINFO: "(ITOA $sortid) " " (ITOA $partid) " "(ITOA $pathid) " " (CHR 34)$partname(CHR 34) " " (CHR 34)$customer(CHR 34) " " (ITOA $quantity) " " (CHR 34) $partdate (CHR 34) " " (RTS $basex) " " (RTS $basey) " " (RTOS $rotate 6) " " (ITOA $partcolor) " " (TOSTR $geoflag)))
)

(DEFUN rotax (/ drot)
  (IF (= $ft 0) (SETQ $ft 0.0001))
  (IF invtime (SETQ feedstr (STRCAT " F" (FINV $ft) " ;" (RTF $fe) " mm/min")))
  (SETQ rotstr (IF $uses6x (STRCAT " C" (ATS $c)) ""))
  (WRITE (STRCAT (NTXT) "G1 A" (ATS $a) " B" (ATS $b) rotstr feedstr))
)

(DEFUN rewind ()
  (IF (AND $useabr $wacode)
    (PROGN
      (WRITE (STRCAT (NTXT) "M9" (MSG "ABRASIVE OFF")))
      (DELAY $delay))
  )
  (WRITE (STRCAT (NTXT) "M5" (MSG "WATER OFF")))
  (DELAY 1.0)

  (WRITE (STRCAT (NTXT) "G0 A" (ATS $a) " B" (ATS $b)))
  (COND
    ((AND $useabr $wacode)
      (WRITE (STRCAT (NTXT) "M3" (MSG "WATER ON")))
      (WRITE (STRCAT (NTXT) "M7" (MSG "ABRASIVE ON"))))
    (T
      (WRITE (STRCAT (NTXT) "M3" (MSG "WATER ON"))))
  )
  (DELAY 0.5)
)

(DEFUN stop ()
  (IF $cond
    (WRITE (STRCAT (NTXT) "M01 P4 (MSG " (STRS $msg) ")"))
    (WRITE (STRCAT (NTXT) "M00 ;" $msg " REASON:" (TOSTR $reason)))
  )
  (SETQ breakon nil $stopbit 0)
)

(DEFUN mrapid ()
  (COND
    ((= $reason 1)
      (WRITE (STRCAT (NTXT) "M81" (MSG "SERVICE POS"))))
    (T
      (WRITE (STRCAT (NTXT) "M80" (MSG "PARKING POS"))))
  )
)

(DEFUN msg (txt)
  (IF *AddComments* (STRCAT " ;" txt) "")
)

(DEFUN pumpOnOff ()
  (IF $on (WRITE (STRCAT (NTXT) "G100 M50 ; PUMP START")))
  (IF $off (WRITE (STRCAT (NTXT) "(IF #LASTRUN (CNC G100 M49)) ;PUMP OFF")))
  (COND
    ($barunchanged nil)
    ((= $pressurehandle 0) nil) ; Manual handle of pressure
    ((= $pressurehandle 1) ; M-codes handle pressure
      (IF $usehighbar
        (WRITE (STRCAT (NTXT) "M77 ;HIGH PRESSURE"))
        (WRITE (STRCAT (NTXT) "M76 ;LOW PRESSURE"))))
    ((= $pressurehandle 2) ; Variable pressure control
      (IF $metric
        (PROGN
          (WRITE (STRCAT (NTXT) "M47 P" (ITOA $bar) " ;SET PRESSURE"))
          (WRITE (STRCAT (NTXT) "M46 Q" (ITOA (- $bar 200)) " S" (ITOA (+ $bar 200)))))
        (PROGN
          (WRITE (STRCAT (NTXT) "M47 P" (ITOA $psi) " ;SET PRESSURE"))
          (WRITE (STRCAT (NTXT) "M46 Q" (ITOA (- $psi 30000)) " S" (ITOA (+ $psi 3000)))))))
  )
)

(DEFUN chbargram ()
  (COND
    ($barunchanged nil)
    ((= $pressurehandle 0)
      (IF $metric
        (WRITE (STRCAT (NTXT) "M00 ;CHANGE PRESSURE TO " (ITOA $bar) " BAR"))
        (WRITE (STRCAT (NTXT) "M00 ;CHANGE PRESSURE TO " (ITOA $psi) " PSI"))))
    ((= $pressurehandle 1)
      (IF $usehighbar
        (WRITE (STRCAT (NTXT) "M77 ;HIGH PRESSURE "))
        (WRITE (STRCAT (NTXT) "M76 ;LOW PRESSURE "))))
    ((= $pressurehandle 2)
      (IF $metric
        (PROGN
          (IF $init nil
            (IF (> $barrel 2000)
              (PROGN
                (WRITE (STRCAT (NTXT) "M9" (MSG "ABRASIVE OFF")))
                (DELAY 0.5)
                (WRITE (STRCAT (NTXT) "M5" (MSG "WATER OFF")))
                (DELAY 0.5)
               )
            )
          )
          (WRITE (STRCAT (NTXT) "M47 P" (ITOA $bar) " ;SET PRESSURE"))
          (WRITE (STRCAT (NTXT) "M46 Q" (ITOA (- $bar 200)) " S" (ITOA (+ $bar 200))))
          (IF $init nil
            (IF (> $barrel 2000)
              (PROGN
                (WRITE (STRCAT (NTXT) "M7" (MSG "ABRASIVE ON")))
                (DELAY 0.5)
                (WRITE (STRCAT (NTXT) "M3" (MSG "WATER ON")))
                (DELAY 0.5)
               )
            )
          )
          )
        (PROGN
          (WRITE (STRCAT (NTXT) "M47 P" (ITOA $psi) " ;SET PRESSURE"))
          (WRITE (STRCAT (NTXT) "M46 Q" (ITOA (- $psi 30000)) " S" (ITOA (+ $psi 3000)))))))
  )
  (COND
    ($gramunchanged nil)
    ((= $abrasivehandle 0)
      (IF $metric
        (WRITE (STRCAT (NTXT) "M00 ;CHANGE ABRASIVE TO " (ITOA $gram) " GRAM"))
        (WRITE (STRCAT (NTXT) "M00 ;CHANGE ABRASIVE TO " (ITOA $lbs) " LBS"))))
    ((= $abrasivehandle 1)
      (IF $usehighflow
        (WRITE (STRCAT (NTXT) "M46 ;NORMAL ABRASIVE FLOW"))
        (WRITE (STRCAT (NTXT) "M47 ;REDUCED ABRASIVE FLOW"))))
    ((= $abrasivehandle 2)
      (IF $metric
        (WRITE (STRCAT (NTXT) "M44 P" (ITOA $gram) " ;SET ABRASIVE FLOW"))
        (WRITE (STRCAT (NTXT) "M44 P" (RTOS $lbs 2) " ;SET ABRASIVE FLOW"))))
  )
)

(DEFUN chmode ()
  (COND
    ((= $mold 0) (WRITE (STRCAT (NTXT) "(MEASURE-OFF)")))
    ((= $mold 1) (WRITE (STRCAT (NTXT) "G89 ;END OF DRILLING SECTION")))
    ((= $mold 2) (WRITE (STRCAT (NTXT) "; END OF MARKING SECTION")))
    ((= $mold 3) (WRITE (STRCAT (NTXT) "; END OF PRE-PIERCING SECTION")))
    ((= $mold 4) (WRITE (STRCAT (NTXT) "; END OF CUTTING SECTION")))
  )
  (COND
    ((= $mode 0) (WRITE (STRCAT (NTXT) "(MEASURE-ON)")))
    ((= $mode 1) (WRITE (STRCAT (NTXT) "G80 ;DRILLING SECTION")))
    ((= $mode 2) (WRITE (STRCAT (NTXT) "; MARKING SECTION")))
    ((= $mode 3) (WRITE (STRCAT (NTXT) "; PRE-PIERCING SECTION")))
    ((= $mode 4) (WRITE (STRCAT (NTXT) "; CUTTING SECTION")))
  )
)

(DEFUN finv (ft / txt)
  (IF (< ft 0.00001) (SETQ ft 0.00001))
  (SETQ invt (* ft 60))
  (SUBSTR (RTOS invt 5) 1 7)
)

(DEFUN footer (/ xmin xmax ymin ymax test)
  (IF (= $zmode 7)
    (WRITE (STRCAT "(MEASURE-CLEAR)"))
  )
  (WRITE (STRCAT (NTXT) "G4 P0"))
  ;(WRITE (STRCAT (NTXT) "(ALERT (TOSTR (/ tid 1000)))"))
  (WRITE (STRCAT (NTXT) "$PARTEND:"))
  (WRITE (STRCAT (NTXT) "G193" (MSG "SPEED IPO OFF")))

  (MRAPID)
  (WRITE (STRCAT (NTXT) "G0 A0 B0"))
  (WRITE "(IF #LASTRUN (CNC G100 M52 P1))")
  ;(WRITE (STRCAT (NTXT) "M52 P1" (MSG "FRONT SHIELD DOWN")))
  (WRITE (STRCAT (NTXT) "G701" (MSG "RESTORE WCS!")))
  (IF (NOT $lines) (SETQ $lines wline))
  (IF (NOT $datefirst) (SETQ datefirst ""))
  (SETQ id 0)
  (REPEAT (1+ $maxpartid)
    (WRITE (STRCAT "$PARTGEOMETRY: " (TOSTR (CAM-PARTGEOMB64 id))))
    (SETQ id (1+ id))
  )
  (WRITE (STRCAT "$ABRASIVEAMOUNT: " (TOSTR $abrasiveamount)))
  (WRITE (STRCAT "$CUTSECONDS: " (ITOA $runsec)))
  (WRITE (STRCAT "$DATEDUE: " $datedue ))
  (WRITE (STRCAT "$DATECREATED: " $datecreated))
  (WRITE (STRCAT "$INFO: NUMBER OF LINES: " (ITOA $lines)))
  ;(WRITE (STRCAT "(DONEFILE)"))
  (WRITE ";EOF")
)

(DEFUN final ()
  (IF $SendToCnc
    (STARTAPP (GETVAR "IGEMSCNC") (STRS $filename) T)
  )
)

(PRINC "...Loaded\n")



