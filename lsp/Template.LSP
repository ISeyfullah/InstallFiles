;# HEADER Will be executed executed first
(DEFUN header()
  (WRITE (STRCAT (NTXT) "(FILE: " $name ")"))
  (WRITE (STRCAT (NTXT) "(MATR: " $Group "/" $alloy "/" (RTS $thickness) ")"))
  (WRITE (STRCAT (NTXT) "(DRAWING: " $digfile ")"))
  (WRITE (STRCAT (NTXT) "(DATE: " $date ")"))
  (WRITE (STRCAT (NTXT) "(MACHINE: " $machine ")"))
  (WRITE (STRCAT (NTXT) (IF $metric "G71" "G70")))
  (WRITE (STRCAT (NTXT) (IF $abs "G90" "G91")))
  (WRITE (STRCAT (NTXT) "G40 G0"))
)

;# Measure function
; Variables: $x $y $zref
(DEFUN measure ()
  (WRITE (STRCAT (NTXT) "G00 X" (RTS $x) " Y" (RTS $y)))
  (WRITE (STRCAT (NTXT) "MEASURE(" (ITOA $zref) ")"))
  (SIM-DELAY 0.2)
)

;# Function to add a stop
(DEFUN stop ()
  (COND
    ((= $REASON 1)
      (WRITE (STRCAT (NTXT) "M00 (STOP IN EDIT PART MESSAGE: " $msg ")")))
    ((= $REASON 2)
      (WRITE (STRCAT (NTXT) "M00 (STOP IN ORDER MESSAGE: " $msg ")")))
    ((= $REASON 3)
      (WRITE (STRCAT (NTXT) "M00 (STOP AFTER FIRST CUT)")))
    ((= $reason 4)
      (WRITE (STRCAT (NTXT) "M00 (STOP AFTER FIRST PART)")))
    ((= $reason 5)
      (WRITE (STRCAT (NTXT) "M00 (STOP BEFORE 5X-CUTTING)")))
  )
)


;# Change tool distance or active tool
(DEFUN chtool (/ txt adress dist count)
  (COND
    ((= $reason 1)
      (WRITE (STRCAT "(TOOL INITIALIZON IS SKIPPED)")))
    ((= $reason 2) ; Change acive tools manually
      (WRITE (STRCAT (NTXT) "M00 (" $msgactive ")"))) 
    ((= $reason 3) ; Change active tools by CNC
      (WRITE (STRCAT (NTXT) "T" (ITOA $tools) " (" $msgactive ")"))) 
    ((= $reason 4) ; Change distance between tools manually
      (WRITE (STRCAT (NTXT) "M00 (" $msgdist ")"))) 
    ((= $reason 5) ; Change distance between tools by CNC
      (SETQ txt "M50")
      (SETQ adress (LIST " #100=" " #101=" " #102=" " #103="))
      (SETQ count 0)
      (WHILE (SETQ dist (NTH count $toollist))
        (SETQ txt (STRCAT txt (NTH count adress) (RTS dist)))
        (SETQ count (1+ count))
      )
      (WRITE (STRCAT (NTXT) txt " (" $msgdist ")")))
    ((= $reason 6) ; Change distance and active tools manually
      (WRITE (STRCAT (NTXT) "M00 (" $msg ")")))
    ((= $reason 7) ; Change distance manually and active tool by CNC
      (WRITE (STRCAT (NTXT) "M00 (" $msgdist ")"))
      (WRITE (STRCAT (NTXT) "T" (ITOA $tools) " (" $msgactive ")")))
    ((= $reason 8) ; Change distance by CNC and active tool manually
      (SETQ $reason 5)
      (CHTOOL)
      (SETQ $reason 2)
      (CHTOOL))
    ((= $reason 9)
      (SETQ $reason 5)
      (CHTOOL)
      (SETQ $reason 3)
      (CHTOOL))
  )    
)

;# Function for change the working mode
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


;# Function for change pressure and abrasive amount
(DEFUN chbargram ()
  (COND
    ((= $reason 1)
      (WRITE (STRCAT (NTXT) "M70 (START PUMP)")))
    ((= $reason 2)
      (WRITE (STRCAT (NTXT) (IF $high "M75 (SET HIGH PRESSURE)" "M74 (SET LOW PRESSURE)")))
      (WRITE (STRCAT (NTXT) "M70 (START PUMP)")))
    ((= $reason 3)
      (WRITE (STRCAT (NTXT) "P" (ITOA $bar) " (SET " (ITOA $bar) " BAR)"))
       (WRITE (STRCAT (NTXT) "M70 (START PUMP)")))
    ((= $reason 4) 
      (WRITE (STRCAT (NTXT) "P" (ITOA $bar) " (SET " (ITOA $bar) " BAR)"))
      (WRITE (STRCAT (NTXT) (IF (MINUSP $barrel) "M72 (DECREASE PRESSURE)" "M73 (INCREASE PRESSURE)")))
      (DELAY $delay))
    ((= $reason 5)
      (WRITE (STRCAT (NTXT) (IF $high "M75 (SET HIGH PRESSURE)" "M74 (SET LOW PRESSURE)")))
      (DELAY $delay))
    ((= $reason 6)
      (WRITE (STRCAT (NTXT) "S" (ITOA $gram) " (SET " (ITOA $gram) " GRAM)"))
      (WRITE (STRCAT (NTXT) "P" (ITOA $bar) " (SET " (ITOA $bar) " BAR)"))
      (WRITE (STRCAT (NTXT) (IF (MINUSP $barrel) "M72 (DECREASE PRESSURE)" "M73 (INCREASE PRESSURE)")))
      (DELAY $delay))
    ((= $reason 7)
      (WRITE (STRCAT (NTXT) "S" (ITOA $gram) " (SET " (ITOA $gram) " GRAM)"))
      (WRITE (STRCAT (NTXT) (IF $high "M75 (SET HIGH PRESSURE)" "M74 (SET LOW PRESSURE)")))
      (DELAY $delay))
    ((= $reason 8)
      (WRITE (STRCAT (NTXT) "S" (ITOA $gram) " (SET " (ITOA $gram) " GRAM)")))
    ((= $reason 9)
      (WRITE (STRCAT (NTXT) "M71 (TURN OFF PUMP)")))
    ((= $reason 10)
      (WRITE (STRCAT (NTXT) "M00 (SET " (ITOA $bar) " BAR " (ITOA $gram) " GRAM)")))
    ((= $reason 11)
      (WRITE (STRCAT (NTXT) "M00 (SET " (ITOA $bar) " BAR)")))
    ((= $reason 12)
      (WRITE (STRCAT (NTXT) "M00 (SET " (ITOA $gram) " GRAM)")))
  )
)

;# Function to handle the cutting quality event
(DEFUN quality ()
  (IF $chqua
    (WRITE (STRCAT (NTXT) "(QUALITY CHANGED TO " (ITOA $qua) " DURING CUTTING)"))
    (WRITE (STRCAT (NTXT) "(QUALITY INITIALIZED TO " (ITOA $qua) " BEFORE CUTTING START)"))
  )
)

;# Function to handle the Start Rapid event
(DEFUN srapid()
  (WRITE (STRCAT (NTXT) "G00 X" (RTS $x) " Y" (RTS $y)))
  (COND
    ((= $attrib "PROBE")
      (WRITE (STRCAT (NTXT) "M900 (PROBE MEASURING)\n")))
    (T
      (WRITE (STRCAT (NTXT) "M00 (UNKNOWND EVENT: " $attrib ")\n")))
  )    
)

;# Add rapid Moves
(DEFUN rapid()
  (WRITE (STRCAT (NTXT) "G00 X" (RTS $x) " Y" (RTS $y)))
)

;# Event for Tool Down
(DEFUN tooldown ()
  (WRITE (STRCAT (NTXT) "G00 Z0.0 (TOOL DOWN)"))
)

;# Add function for Cut on and piercing
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


;# Function to handle cutting speed interpolation
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

;# LINE The basic movement function
(DEFUN line () 
  (IF $chkerf
    (WRITE (STRCAT (NTXT) "G01 G4" (ITOA $kerf) " X" (RTS $x) " Y" (RTS $y) " F" (RTF $f))) 
    (WRITE (STRCAT (NTXT) "G01 X" (RTS $x) " Y" (RTS $y) " F" (RTF $f)))  
  )  
)

;# ARC Make CW and CCW movement 
(DEFUN arc ()
  (IF $ccw
    (WRITE (STRCAT (NTXT) "G03 X" (RTS $X) " Y" (RTS $Y) " I" (RTS $I) " J" (RTS $J) " F" (RTF $f)))
    (WRITE (STRCAT (NTXT) "G02 X" (RTS $X) " Y" (RTS $Y) " I" (RTS $I) " J" (RTS $J) " F" (RTF $f)))
  )
)

;# CUTOFF Turn of jet f�r cutting and marking processes
(DEFUN cutoff()
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

;# Text function to support special text engraving equipment
(DEFUN text ()
  (WRITE (STRCAT (NTXT) "G00 X" (RTS $x) " Y" (RTS $y)))
  (WRITE (STRCAT (NTXT) "INKJET(SETUP:" $font "," (RTS $height) ")"))
  (WRITE (STRCAT (NTXT) "INKJET(ROTATE:" (RTS (* (/ 180 PI) $angle)) ")" ))
  (WRITE (STRCAT (NTXT) "INKJET(PRINT:" $text ")"))
) 
  
;#Event for Tool Up
(DEFUN toolup ()
  (WRITE (STRCAT (NTXT) "G00 Z" (RTS $z) " (" $msg ")"))
)

;#Delay
(DEFUN delay (value)
  (IF (> value 0.1)
    (PROGN
      (SIM-DELAY value)
      (WRITE (STRCAT (NTXT) "G04 F" (RTT value))))
  )
)

;# Footer function to be at the end og the postprocessor
(DEFUN footer()
  (WRITE (STRCAT (NTXT) "M30"))
  (WRITE (STRCAT (NTXT) "(SECONDS " (ITOA $runsec) ")"))
  (WRITE (STRCAT (NTXT) "(USED TIME " $runtime ")"))
  (WRITE (STRCAT (NTXT) "(IGEMS:" $igems " POST:" $post " Date:" ")"))  
  (WRITE "%")  
)