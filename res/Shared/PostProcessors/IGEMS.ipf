(SETQ *postinit* 1461)
(SETQ pp_autofilename T pp_filename "C:/NCDATA/Autoload.icnc")
;(SETQ ladda (GP-YESNO "Load program in CNC" T))
(DEFUN header ()
  (ALERT "This is a demo postprocessor. The result can not be used")
)


(DEFUN line ()
  (SETQ bevstr (IF $ab (STRCAT " C" (ATS $a) " A" (ATS $b)) ""))
  (IF $chkerf (WRITE (STRCAT (NTXT) "G4" (ITOA $kerf))))
  (WRITE (STRCAT (NTXT) "G1 X" (RTS $x) " Y" (RTS $y) bevstr " F" (RTF $fe)))
)

(DEFUN arc (/ newpt)
  (SETQ bevstr (IF $ab (STRCAT " C" (ATS $a) " A" (ATS $b)) ""))
  (COND
    ($ccw
      (WRITE (STRCAT (NTXT) "G3 X" (RTS $X) " Y" (RTS $Y) " I" (RTS $Irel) " J" (RTS $Jrel) bevstr " F" (RTF $f))))
    (T
      (WRITE (STRCAT (NTXT) "G2 X" (RTS $X) " Y" (RTS $Y) " I" (RTS $Irel) " J" (RTS $Jrel) bevstr " F" (RTF $f))))
  )
)


(DEFUN chmode ()
  (COND
    ((NOT $mold) nil)
    ((= $mold 1) (WRITE (STRCAT (NTXT) "(END OF DRILLING SECTION)")))
    ((= $mold 2) (WRITE (STRCAT (NTXT) "(END OF MARKING SECTION)")))
    ((= $mold 3) (WRITE (STRCAT (NTXT) "(END OF PRE-PIERCING SECTION)")))
    ((= $mold 4) (WRITE (STRCAT (NTXT) "(END OF CUTTING SECTION)")))
  )
  (COND
    ((= $mode 1) (WRITE (STRCAT (NTXT) "(START OF DRILLING SECTION)")))
    ((= $mode 2) (WRITE (STRCAT (NTXT) "(START OF MARKING SECTION)")))
    ((= $mode 3) (WRITE (STRCAT (NTXT) "(START OF PRE-PIERCING SECTION)")))
    ((= $mode 4) (WRITE (STRCAT (NTXT) "(START OF CUTTING SECTION)")))
  )
)

(DEFUN chbargram ()
  (COND
    ((= $reason 1) nil) ; Start pump, manual pressure
    ((= $reason 2) nil) ; Start pump, in High/Low pressure
    ((= $reason 3) nil) ; Start pump, in variable pressure
    ((= $reason 4) nil) ; change variable pressure
    ((= $reason 5) nil) ; change high low pressure
    ((= $reason 6) nil) ; change variable pressure and variable abrasive
    ((= $reason 7) nil) ; change high/low pressure and variable abrasive
    ((= $reason 8) nil) ; change variable abrasive
    ((= $reason 9) nil) ; Turn off pump
    ((= $reason 10) nil) ; change pressure and abrasive manually
    ((= $reason 11) nil) ; change pressure manually
    ((= $reason 12) nil) ; change abrasive manually
  )
)

(DEFUN rapid()
  (WRITE (STRCAT (NTXT) "G00 X" (RTS $x) " Y" (RTS $y)))
)

(DEFUN tooldown ()
  (WRITE (STRCAT (NTXT) "G00 Z0.0 (TOOL DOWN)"))
)

(DEFUN piercing()
  (WRITE (STRCAT (NTXT) "(PIERCING TYPE " (ITOA $ptype) ")"))
  (COND
    ((AND $useabr $wacode)
      (WRITE (STRCAT (NTXT) "M4 (WATER ON)"))
      (DELAY $delay)
      (WRITE (STRCAT (NTXT) "M6 (ABRASIVE ON)")))
    ($useabr
      (WRITE (STRCAT (NTXT) "M10 (WATER AND ABRASIVE ON)")))
    (T
      (WRITE (STRCAT (NTXT) "M4 (WATER ON)")))
  )
  (IF $circ (CIRC-PIERCING) (DELAY $time))
)

(DEFUN fmode ()
  (COND
    ((= $flin 0) ; Deactivate FLIN
      (WRITE (STRCAT (NTXT) "FNORM" (MSG " (SPEED INTERPOLATION OFF)"))))
    ((= $flin 1) ; Activate FLIN
      (WRITE (STRCAT (NTXT) "FLIN" (MSG " (SPEED INTERPOLATION ON)"))))
    ((= $flin 2) ; New start value
      (WRITE (STRCAT (NTXT) "F" (ITOA $fs))))
  )
)

(DEFUN cutoff()
  (WRITE (STRCAT "\n($LOWATOFF:" (TOSTR $lowatoff) ")"))
  (WRITE (STRCAT (NTXT) (IF $marking "(MARKING OFF)" "(CUTTING OFF)")))
  (IF (AND $useabr $wacode)
    (PROGN
      (WRITE (STRCAT (NTXT) "M7" (MSG "(ABRASIVE OFF)")))
      (DELAY $delay))
  )
  (WRITE (STRCAT (NTXT) "M5" (MSG "(WATER OFF)")))
  (DELAY $time)
  (IF $chkerf (WRITE (STRCAT (NTXT) "G4" (ITOA $kerf))))
)

(DEFUN toolup ()
  (WRITE (STRCAT (NTXT) "G00 Z" (RTS $z) " (" $msg ")"))
)

(DEFUN delay (value)
  (IF (> value 0.1)
    (PROGN
      (SIM-DELAY value)
      (WRITE (STRCAT (NTXT) "G04 F" (RTT value))))
  )
)



(DEFUN footer()
  (WRITE (STRCAT (NTXT) "M30"))
  (WRITE (STRCAT (NTXT) "(SECONDS " (ITOA $runsec) ")"))
  (WRITE (STRCAT (NTXT) "(USED TIME " $runtime ")"))
  (WRITE (STRCAT (NTXT) "(IGEMS:" $igems " POST:" $post " Date:" ")"))
  (WRITE "%")
)


(DEFUN srapid()
  (WRITE (STRCAT (NTXT) "G00 X" (RTS $x) " Y" (RTS $y)))
)
