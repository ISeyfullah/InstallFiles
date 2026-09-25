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

(DEFUN itext ()
  (WRITE (STRCAT (NTXT) "G00 X" (RTS $x) " Y" (RTS $y) " Z" (RTS $z))) 
  (WRITE (STRCAT (NTXT) "A:" (ATS $angle) " (ANGLE OF TEXT)"))
  (WRITE (STRCAT (NTXT) "L:" (RTS $length) " (LENGTH OF TEXT)"))
  (WRITE (STRCAT (NTXT) "H:" (RTS $height) " (HEIGHT OF TEXT)"))
  (WRITE (STRCAT (NTXT) "F:" $font " (TEXT FONT)"))
  (SETQ $txt "")
  (FOREACH s $txtlist (SETQ $txt (STRCAT $txt s "/")))
  (SETQ $txt (STRSUB $txt 1 -2))
  (WRITE (STRCAT (NTXT) "T:" $txt)) ; text to print
  (WRITE (STRCAT (NTXT) "M100 (PRINT)"))
  (WRITE "")
)

;# Add rapid Moves
(DEFUN rapid (/ zstr bevstr rotstr)
  (SETQ zstr (IF (MEMBER $reason (LIST 4 5 6)) (STRCAT " Z" (RTS $z)) ""))
  (SETQ bevstr (IF $ab (STRCAT " A" (ATS $a) " B" (ATS $b)) ""))
  (SETQ rotstr (IF $uses6x (STRCAT " C" (ANGTOS $c 3 nil)) ""))
  (WRITE (STRCAT (NTXT) "G00 X" (RTS $x) " Y" (RTS $y) zstr bevstr rotstr))
  (SETQ skiptilt T)
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
(DEFUN chtool (/ toolstr toolvar)
  (COND
    ($tooldistunchanged nil) ; No change of tool distance needed
    ((= $tooldisthandle 0) ; Manual handling of tool distance
      (WRITE (STRCAT (NTXT) "M00 (" $msgdist ")")))
    ((= $tooldisthandle 1) ; Automatic adjustment of tool distance
      (SETQ toolstr "" toolvar 22) ; R22 just anexample of cnc variable
      (FOREACH s $toollist
        (SETQ toolstr (STRCAT toolstr "R" (ITOA toolvar) "=" (RTS s) " "))
        (SETQ toolvar (1+ toolvar))
      )
      (WRITE (STRCAT (NTXT) "M50 " toolstr " (USING " $msgdist ")")))
  )
  (COND
    ($toolunchanged nil); No change of active tool needed
    ((= $toolhandle 0) ; Tools are activated manually
      (WRITE (STRCAT (NTXT) "M00 (" $msgactiv ")")))
    ((= $toolhandle 1) ; Tools are handled from the CNC code
      (WRITE (STRCAT (NTXT) "T" (ITOA $tools) "(" $msgactive ")" )))
  )
)

;# Function for change the working mode
(DEFUN chmode ()
  (COND
    ((NOT $mold) nil)
    ((= $mold 0) (WRITE (STRCAT (NTXT) "(END OF MEASURE SECTION)")))
    ((= $mold 1) (WRITE (STRCAT (NTXT) "(END OF DRILLING SECTION)")))
    ((= $mold 2) (WRITE (STRCAT (NTXT) "(END OF MARKING SECTION)")))
    ((= $mold 3) (WRITE (STRCAT (NTXT) "(END OF PRE-PIERCING SECTION)")))
    ((= $mold 4) (WRITE (STRCAT (NTXT) "(END OF CUTTING SECTION)")))
    ((= $mold 5) (WRITE (STRCAT (NTXT) "(END OF INKJET MARKING SECTION)")))
    ((= $mold 6) (WRITE (STRCAT (NTXT) "(END OF SPECIAL MARKING SECTION)")))
  )
  (COND
    ((= $mode 0) (WRITE (STRCAT (NTXT) "(START OF MEASURE SECTION)")))
    ((= $mode 1) (WRITE (STRCAT (NTXT) "(START OF DRILLING SECTION)")))
    ((= $mode 2) (WRITE (STRCAT (NTXT) "(START OF MARKING SECTION)")))
    ((= $mode 3) (WRITE (STRCAT (NTXT) "(START OF PRE-PIERCING SECTION)")))
    ((= $mode 4) (WRITE (STRCAT (NTXT) "(START OF CUTTING SECTION)")))
    ((= $mode 5) (WRITE (STRCAT (NTXT) "(START OF INKJET MARKING SECTION)")))
    ((= $mode 6) (WRITE (STRCAT (NTXT) "(START OF SPECIAL MARKING SECTION)")))
  )
)


;# Function for change pressure and abrasive amount
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
          (WRITE (STRCAT (NTXT) "M47 P" (ITOA $bar) " ;SET PRESSURE"))
          (WRITE (STRCAT (NTXT) "M46 Q" (ITOA (- $bar 200)) " S" (ITOA (+ $bar 200)))))
        (PROGN
          (WRITE (STRCAT (NTXT) "M47 P" (ITOA $psi) " ;SET PRESSURE")))
          (WRITE (STRCAT (NTXT) "M46 Q" (ITOA (- $psi 30000)) " S" (ITOA (+ $psi 3000))))))
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
        (WRITE (STRCAT (NTXT) "M44 P" (RTOS $lbs 2)) " ;SET ABRASIVE FLOW")))
  )
)

;# Function to handle the cutting quality event
(DEFUN quality ()
  (IF $chqua
    (WRITE (STRCAT (NTXT) "(QUALITY CHANGED TO " (ITOA $qua) " DURING CUTTING)"))
    (WRITE (STRCAT (NTXT) "(QUALITY INITIALIZED TO " (ITOA $qua) " BEFORE CUTTING START)"))
  )
)
;# Function to handle pump on and off
(DEFUN pumponoff ()
  (COND
    ((= $pressurehandle 0) nil) ; Manual handling of pressure = do nothing
    ((= $pressurehandle 1) ; M-codes handle pressure
      (IF $usehighbar 
        (WRITE (STRCAT (NTXT) "M77 ;HIGH PRESSURE"))
        (WRITE (STRCAT (NTXT) "M76 ;LOW PRESSURE"))))
    ((= $pressurehandle 2) ; Variable pressure control
      (IF $metric
        (WRITE (STRCAT (NTXT) "M47 P" (ITOA $bar) " ;SET PRESSURE")))
        (WRITE (STRCAT (NTXT) "M47 P" (ITOA $psi) " ;SET PRESSURE")))
  )
  (IF $on
    (WRITE (STRCAT (NTXT) "G100 M50 ; Pump start"))
    (WRITE (STRCAT (NTXT) "M51 ; Pump off"))
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

;# Event for Tool Down

(DEFUN tooldown ()
  (IF $sensor 
    (WRITE (STRCAT (NTXT) "M44 (SENSOR ON, TOOL DOWN)"))
    (WRITE (STRCAT (NTXT) "G0 Z0")))
)

;# Add function for Cut on and piercing
(DEFUN piercing()
  (IF $jetpreload
    (PROGN
      (WRITE (STRCAT (NTXT) "M06" (MSG "ABRASIVE ON")))
      (DELAY $jetpreload)
      (WRITE (STRCAT (NTXT) "M04" (MSG "WATER ON")))
      (DELAY $jetvalveon))
    (PROGN
      (WRITE (STRCAT (NTXT) "M04" (MSG "WATER ON")))
      (DELAY $jetvalveon)
      (IF $useabr
        (PROGN
          (WRITE (STRCAT (NTXT) "M06" (MSG "ABRASIVE ON")))
          (DELAY $JetAbrasiveOn)))
    )   
  )  
  (COND
    ((NOT $circ)     ; If it's a non circular piercing, wait $time seconds
      (DELAY $time)) 
    ((NOT $leadtilt) ; Circular piercing on flat material. CNC have a macro for circular piercing
      (SETQ *CustomCircularPiercing* T) ; Activate simulation
      (WRITE (STRCAT (NTXT) "M12 S" (RTT $time)))); Call a fantasy "M12" inbuild macro CNC function
    (nil  ; Create long file without variables and logical conditions 
      (SETQ *CustomCircularPiercing* nil)
      (CPIERC-LINE T)
      (REPEAT $cpturns (CPIERC-CIRCLE))
      (CPIERC-LINE nil))
    (T ; Create short file useing variables and logical conditions
      (SETQ *CustomCircularPiercing* T)
      (CPIERC-LINE T)
      (WRITE (STRCAT (NTXT) "R20=" (ITOA $cpturns)))      
      (WRITE (STRCAT (NTXT) "$WHILE R20"))
      (WRITE (STRCAT (NTXT) "R20=R20-1"))
      (CPIERC-CIRCLE)
      (WRITE (STRCAT (NTXT) "$ENDWHILE"))
      (CPIERC-LINE nil))
  )
)

;# Function that will be used everytime the part is changed
(DEFUN part()
  (WRITE (STRCAT "$PARTINFO: "(ITOA $sortid) " " (ITOA $partid) " "(ITOA $pathid) " " (CHR 34)$partname(CHR 34) " " (CHR 34)$customer(CHR 34) " " (ITOA $quantity) " " (CHR 34) $partdate (CHR 34) " " (RTS $basex) " " (RTS $basey) " " (RTOS $rotate 3) " " (ITOA $partcolor)))
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
  (SETQ bevstr (IF $ab (STRCAT " C" (ATS $a) " A" (ATS $b)) ""))
  (IF $chkerf (WRITE (STRCAT (NTXT) "G4" (ITOA $kerf))))
  (WRITE (STRCAT (NTXT) "G1 X" (RTS $x) " Y" (RTS $y) bevstr " F" (RTF $fe)))
)

;# ARC Make CW and CCW movement
(DEFUN arc (/ bevstr rotstr feedstr)
  (SETQ bevstr (IF $ab (STRCAT " A" (ATS $a) " B" (ATS $b)) ""))
  (SETQ rotstr (IF $uses6x (STRCAT " C" (ANGTOS $c 3 nil)) ""))
  (SETQ feedstr (IF (NOT (EQUAL $fe oldfeed 0.5)) (STRCAT " F" (RTF (SETQ oldfeed $fe))) ""))
  (IF $ccw
    (WRITE (STRCAT (NTXT) "G03 X" (RTS $x) " Y" (RTS $y) " I" (RTS $i) " J" (RTS $j) bevstr rotstr feedstr))
    (WRITE (STRCAT (NTXT) "G02 X" (RTS $x) " Y" (RTS $y) " I" (RTS $i) " J" (RTS $j) bevstr rotstr feedstr))
  )
)

;# CUTOFF Turn of jet f r cutting and marking processes
(DEFUN cutoff ()
  (IF $Jetabrasiveoff
    (PROGN
      (WRITE (STRCAT (NTXT) "M7" (MSG "ABRASIVE OFF")))
      (DELAY $JetabrasiveOff)))
  (IF $JetValveOff
    (PROGN
      (IF $release 
        (PROGN
          (WRITE (STRCAT (NTXT) "M76 ;LOW PRESSURE"))
          (DELAY $delay)))
      (WRITE (STRCAT (NTXT) "M5" (MSG "WATER OFF")))
      (DELAY $jetvalveoff)))
  (IF $chkerf (WRITE (STRCAT (NTXT) "G4" (ITOA $kerf))))
)


;# Text function to support special text engraving equipment
(DEFUN text ()
  (WRITE (STRCAT (NTXT) "G00 X" (RTS $x) " Y" (RTS $y)))
  (WRITE (STRCAT (NTXT) "INKJET(SETUP:" $font "," (RTS $height) ")"))
  (WRITE (STRCAT (NTXT) "INKJET(ROTATE:" (RTS (* (/ 180 PI) $angle)) ")" ))
  (WRITE (STRCAT (NTXT) "INKJET(PRINT:" $text ")"))
)

;# Event for Tool Up
(DEFUN toolup()
  (IF $sensor (WRITE (STRCAT (NTXT) "M45 (SENSOR OFF, TOOL UP)")))
  (COND
    ($sensor nil)
    ((= $reason 1)
       (WRITE (STRCAT (NTXT) "G0 Z" (RTS $z) " (TOOL UP IN BEGINNING OF FILE)")))
    ((= $reason 2)
       (WRITE (STRCAT (NTXT) "G0 Z" (RTS $z) " (TOOL UP BETWEEN DRILLINGS)")))
    ((= $reason 3)
       (WRITE (STRCAT (NTXT) "G0 Z" (RTS $z) " (TOOL UP BETWEEN MARKINGS)")))
    ((= $reason 4)
       (WRITE (STRCAT (NTXT) "G0 Z" (RTS $z) " (TOOL UP BETWEEN PRE PIERCINGS)")))
    ((= $reason 5)
       (WRITE (STRCAT (NTXT) "G0 Z" (RTS $z) " (TOOL UP BETWEEN CUTS)")))
    ((= $reason 6)
       (WRITE (STRCAT (NTXT) "G0 Z" (RTS $z) " (TOOL UP AFTER LAST CUT ON PART)")))
  )
)

;# TILT used to tilt tool before cutting
(DEFUN tilt (/ bevstr rotstr)
  (SETQ bevstr (IF $ab (STRCAT " A" (ATS $a) " B" (ATS $b)) ""))
  (SETQ rotstr (IF $uses6x (STRCAT " C" (ANGTOS $c 3 nil)) ""))
  (IF (NOT skiptilt) (WRITE (STRCAT (NTXT) "G0" bevstr rotstr)))
  (SETQ skiptilt nil)
)


;#Function that will Rewind major axis if needed
(DEFUN rewind ()
  (WRITE (STRCAT (NTXT) "M5" (MSG " (JET OFF)")))
  (DELAY 0.5)
  (WRITE (STRCAT (NTXT) "G0 C" (ATS $a) " A" (ATS b) (MSG " (TILT)")))
  (WRITE (STRCAT (NTXT) "M3" (MSG " (JET ON)")))
  (DELAY 0.5)
)

;#Delay
(DEFUN delay (value)
  (IF (> value 0.1)
    (PROGN
      (SIM-DELAY value)
      (WRITE (STRCAT (NTXT) "G04 F" (RTT value))))
  )
)
;#Function that will be executed before FOOTER if the machine should go to parking position.
(DEFUN mrapid ()
  (WRITE (STRCAT (NTXT) "G53 G0 X" (RTS $x) " Y" (RTS $y) " (PARKING POSITION)"))
)

;# Footer function to be at the end of the postprocessor
(DEFUN footer()
  (WRITE (STRCAT (NTXT) "M30"))
  (WRITE (STRCAT (NTXT) "(SECONDS " (ITOA $runsec) ")"))
  (WRITE (STRCAT (NTXT) "(USED TIME " $runtime ")"))
  (WRITE (STRCAT (NTXT) "(IGEMS:" $igems " POST:" $post " Date:" ")"))
  (WRITE "%")
)