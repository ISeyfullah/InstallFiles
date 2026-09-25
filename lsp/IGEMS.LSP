(PRINC "\nLoading IGEMS.LSP [2025.May.15] 14:03..") ;
(SETQ pp_xmod 0 pp_ymod 0) ; Add this value to support special equipment like Drilling, Marking, Inkjet
(SETQ pp_xmodsim 0 pp_ymodsim 0) ; Add this values to simulator to support special equipment like Drilling, Marking, Inkjet
(SETQ pp_xoffset 0 pp_yoffset 0) ; How much X and Y should be changed because of part should be cut with another tool than T1

(SETQ pp_offset 0)
(SETQ PID (* PI 2.0)) ; PIDouble
(SETQ PIH (* PI 0.5)) ; PIHalf
(SETQ $a 0.0 $b 0.0)
(SETQ $slope 0)
(SETQ $initdown T)
(SETQ $vec (LIST 0 0 -1))
(SETQ $vector (LIST 0 0 -1))
(SETQ pp_cutdirection 0)
(SETQ pp_superabinit T)
(SETQ pp_$crel 0.0)
(SETQ *MaxforbiddenTilt* 0.0) ; On heads that only can make positive or negative, can accept little
(SETQ fun nil)
(SETQ funlist nil)
(SETQ pp_$x 0 pp_$y 0 pp_$z 0 pp_$pt (LIST 0 0 0))
(SETQ pp_aold 0.0 pp_bold 0.0)
(SETQ shownext 5000)
(SETQ *SIM-ADDX* 0.0 *SIM-ADDY* 0.0)
(SETQ $probe 0)
(SETQ pp_datefirst 30301224)
(SETQ $datefirst "30301224")
(SETQ *WaterSpeedQuality* (LIST 1.5 1.24 1.0 0.75 0.5))
(SETQ *WaterSpeedFactor* 1.0)
; SIM först
; Text sen

(SETQ ppp_sim1 nil) ; Generate information to 3D-5X
(SETQ ppp_sim2 nil) ; Generate information to 2D
(SETQ ppp_sim3 nil) ; generate information obout vector angle

;(SETQ *Zfrombottom* T)
(SETQ $contains 0)
(SETQ pp_xmax -99999.0 pp_xmin 99999.0 pp_ymax -99999.0 pp_ymin 99999.0)
(SETQ pp_xdmax -99999.0 pp_xdmin 99999.0 pp_ydmax -99999.0 pp_ydmin 99999.0)
;(SETQ ltfspar ltf) (DEFUN ltf (txt) (IF (NOT (MEMBER txt ltflist)) (SETQ ltflist (CONS txt ltflist))) (LTFSPAR txt))
;(DEFUN ltfsave () (ALERT "Saving")(SETQ fw (OPEN (STRCAT (GETVAR  "PATHROOT") "/LSP/TRANS.TXT") "a"))(FOREACH s (REVERSE ltflist) (WRITE-LINE s fw))  (CLOSE fw))

(DEFUN $main ()
  (SETQ fname (STRCAT (GETVAR "PATHDATA") "PROCESS.LIG"))
  (LOAD fname "")
  (IF (FILE-EXISTS fname) (FILE-DELETE fname))
  (IF fun (WRITE "$MAIN"))
  (IF (/= (CHECKSUMCOUNT *PPName*) *PostInit*) (PRINC "\n      ****** This postprocessor is renamed ******\n"))
  (SETQ $maxslope (RADTODEG *Maxslope*))
  (SETQ *Partsboxwidth* (- (CADDR *PartsBox*) (CAR *PartsBox*)))
  (SETQ *Partsboxheight* (- (CADDDR *PartsBox*) (CADR *PartsBox*)))
  (SETQ *Partsboxcenter* (LIST (* (+ (CAR *PartsBox*) (CADDR *PartsBox*)) 0.5) (* (+ (CADR *PartsBox*) (CADDDR *PartsBox*)) 0.5)))
  (IF (= *MaxFeed* 0) (SETQ *MaxFeed* *MarkingSpeed*))
  (COND
    ((NOT *3D-5X*) nil)
    ((> (+ *3D-MaxZ* *3D-5XStock*) (- *ZMaxMovement* *Zstandoff*)) (SETQ pp_thickcheck T) (IF (GP-YESNO "Too thick material for this machine. Stop?" T) (QUIT "*Cancel*")))
    ((AND *3D-5X* (= *ZAxisOption* 1) (= *ZAxisType* 2)) nil) ; CNC-controller, by Z-cordinates
    ((AND *3D-5X* *3D-OnTopPlane*) (SETQ *Thickness* *3D-MaxZ*))
    ((AND *3D-5X* (NOT *3D-OnTopPlane*))
      (IF (GP-YESNO (STRCAT (LTF "Warning!") "\n" (LTF "Z-coordinates differ") " " (RTS (ABS *3D-MaxZDiff*)) " " (LTF "from stock") "\n" (LTF "Continue?")) nil)
        (SETQ *Thickness* *3D-MaxZ*)
        (QUIT "\n\n*Z-Axis mus be handled by Z-coordinates*\n")))
  )

  ;(COND
  ;  ((= *OutputUnit* 1) (SETQ pp_inchout nil))
  ;  ((= *OutputUnit* 2) (SETQ pp_inchout T))
  ;  (*Metric* (SETQ pp_inchout nil)) ; If Auto then use CAD setting
  ;  (T        (SETQ pp_inchout T))   ; If Auto then use CAD setting
  ;)
  ;(SETQ *Ztmp* (CADDR *ZeroPoint*)) ; We will make a more generall solution later
  (SETQ $angleIpo *ControllerAngleInterpolation*)
  (IF *3D-5X*
    (PROGN
      (SETQ *DrillLiftHeight* (+ *DrillLiftHeight* *3D-MaxZ*))
      (SETQ *MarkingLiftHeight* (+ *MarkingLiftHeight* *3D-Maxz*))
      (SETQ *PiercingLiftHeight* (+ *PiercingLiftHeight* *3D-MaxZ*))
      (SETQ *CuttingLiftHeight* (+ *CuttingLiftHeight* *3D-MaxZ*))
      (IF (<= *CuttingLiftHeightParts* 0.1) (SETQ *CuttingLiftHeightParts* 25.0)) ; To get a start valye in 3D-5X
      (SETQ *CuttingLiftHeightParts* (+ *CuttingLiftHeightParts* *3D-MaxZ*)))
  )
  (SETQ pp_zmoved (CADDR *ZeroPoint*)) ; Om man har flyttat nollpunkten i Z så är detta värde inte noll. Värdet läggs på i ZDEF funktionen.
  (SETQ pp_zclear (+ (MAX *3D-5XModelMaxZ* *3D-MaxZ*) *3D-5XStock*)) ; Clearence height for all rapids.
  (SETQ *Ztmp* 0.0) ; This must be to be compatible with postprocessors before we added 3 diferent Z-bases. Not used after 1080
  (SETQ $encoding (NTH *Encoding* (LIST nil "utf-8" "utf-16" "utf-32")))
   ; ***** Handle Z axis ******
  (COND
    (*3D-5X*
      (SETQ pp_zmaxup (- *ZMaxMovement* (+ pp_zmoved *Zstandoff*)))
      (SETQ $zmoveup (+ pp_zmoved *Zstandoff*))
      (SETQ $zmovedown (- (- *ZMaxMovement* (+ pp_zmoved *Zstandoff*)))))
    ((= *ZBase* 0) ; on table
      (SETQ pp_zmaxup *ZMaxMovement*)
      (SETQ $zmoveup 0.0)
      (SETQ $zmovedown (- *ZMaxMovement*)))
    ((= *Zbase* 1) ; on surface
      (SETQ pp_zmaxup (- *ZMaxMovement* *Thickness* *ZStandoff*))
      (SETQ $zmoveup (+ *Thickness* *ZStandoff*))
      (SETQ $zmovedown (- pp_zmaxup)))
    ((= *ZBase* 2) ; on top
      (SETQ pp_zmaxup 0.0)
      (SETQ $zmoveup *ZMaxMovement*)
      (SETQ $zmovedown 0.0))
  )
  (SETQ $zmaxup pp_zmaxup)
  ($BEVELSETUP) ; Setup pp_bevelprim pp_bevelsec unkerfs
  (CHKALL)
  (MAIN)
)

(DEFUN buildver (/ txt s skip)
  (SETQ txt "")
  (FOREACH s (REVERSE *IGEMSVersion*)
    (IF (= s ".") (SETQ skip T))
    (IF (NOT skip) (SETQ txt (STRCAT s txt)))
  )
  (ATOI txt)
)


(DEFUN $initialize (first *TubeMode* bevel editmode / upscale downscale tiptext cutflow)
  (LOADMACMAT)
  ; Convert old waterjet nozzle ON/OFF variables
  ;(SETQ *AWJMarkingAbrasiveOn* *AWJDelayAbrasiveWaterOn*) ; 0.11 till 0.71
  ;(SETQ *AWJMarkingAbrasiveOff* *AWJDelayAbrasiveWaterOff*) ;0.21 till 0.81
  ;(SETQ *AWJMarkingStartDelay* 0.0) ; 0.31 always change to zero
  ; (SETQ *VacuumOnDelay* 0.41) No change
  ;(SETQ *AWJDelayWaterAbrasiveOn* *AWJDelayAbrasiveWaterOn*) ; 0.51 till 0.71
  ;(SETQ *AWJDelayWaterAbrasiveOff* *AWJDelayAbrasiveWaterOff*) ;0.61 får 0.81
  ; (SETQ *AWJDelayAbrasiveWaterOn* 0.71) No change
  ; (SETQ *AWJDelayAbrasiveWaterOff* 0.81) No change
  ;(SETQ *AWJDelayAfterPiercing* *AWJDelayAbrasiveWaterOn*) ; this value is depricated,
  ; (SETQ *AWJDelayAfterCutting* 1.01) No change
  ;(SETQ $JetValveOn *AWJDelayOpenValve*) ; This is new
  ;(SETQ $JetAbrasiveOn *AWJDelayAbrasiveWaterOn*) ; 0.71
  ;(SETQ $JetAbrasiveOff *AWJDelayAbrasiveWaterOff*) ; 0.81
  ;(SETQ $JetValveOff *AWJDelayAfterCutting*) ; 1.01
  (IF *WaterDelayExtra* (SETQ *AWJDelayExtra* *WaterDelayExtra*))

  (IF bevel (SETQ *3D-5X* T))
  (SETQ *SharedFolder* (GETVAR "PATHSHARED"))
  (EVAL (DOSTRING *MachineExtraScript* (ALERT "Error reading Machine Extra script")))
  ;(IF *TubeMode* (LOAD (STRCAT (GETVAR "PATHROOT") "LSP/ITUBE.LSP") nil))
  (SETQ *Metric* (IF (= (GETVAR "UNITS") 0) T nil))
  (COND
    ((= *OutputUnit* 1) (SETQ pp_inchout nil))
    ((= *OutputUnit* 2) (SETQ pp_inchout T))
    (*Metric* (SETQ pp_inchout nil)) ; If Auto then use CAD setting
    (T        (SETQ pp_inchout T))   ; If Auto then use CAD setting
  )
  (IF (NOT editmode) (LOAD (STRCAT (GETVAR "PATHSHARED") "Postprocessors/" *PPName* ".PPI")))
  (SETQ wline 0) ; qounter for viering only 1000 lines
  (SETQ $nadd *LineNumberIncrement*)
  (SETQ $nlines *UseLineNumbers*)
  (SETQ $post (FILE-NAMEONLY *PPName* T))
  (SETQ $build (BUILDVER))
  ;(SETQ $maxslope 0.0 $slope 0.0) moved to $main

  ; ****** Tube settings ******
  (IF (NOT *Tubemode*)
    (SETQ *Tube6AxisPrefere* 0)
    (SETQ *TAC* 0)
  )
  ; ****** Tools settings ******
  (SETQ $mindist *ToolMinDistance*)
  (SETQ $maxdist *ToolMaxDistance*)
  (SETQ $maxtools *ToolQuantity*)
  (SETQ $maxzaxis *ZMovableQuantity*)
  (SETQ $maxtooldiameter *MaxToolDiameter*)
  (IF (> $maxzaxis $maxtools) (SETQ $maxzaxis $maxtools)) ; Number of movable axis cannot be more than the jets
  (SETQ tmp 1 *Toolmaxbit* 1); Check the maximum bitvalue for this number of tool
  (REPEAT (1- *ToolQuantity*)
    (SETQ tmp (* tmp 2))
    (SETQ *ToolMaxBit* (+ *ToolMaxBit* tmp))
  )
  (SETQ $zmaxmove *ZMaxMovement*)
  (IF (NOT *ToolDistanceByController*) (SETQ *ToolMovingSpeed* 999000.0))
  (IF (< *ZMeasureDist* 10) (SETQ *ZMeasureDist* 10))
  (IF (< *ZMeasureDistBevel* 10) (SETQ *ZMeasureDistBevel* 10))
  (COND
    ((= *ZAxisOption* 0) ; Fixed Z-axis from the method window
      (SETQ *DrillLiftZ* 0 *MarkingLiftZ* 0 *PiercingLiftZ* 0 *CuttingLiftZParts* 0 pp_zmode 0))
    ((= *ZAxisOption* 1) ; Up/down no height sensor
      (COND
        ((= *ZAxisType* 0) ; Auto Up/Down
          (SETQ pp_zmode 1)
          (SETQ *DrillLiftZ* 3 *MarkingLiftZ* 3 *PiercingLiftZ* 3 *CuttingLiftZ* 3 *CuttingLiftZParts* 3))
        ((= *ZAxisType* 1) (SETQ pp_zmode 2)) ; Up/Down by M-codes
        ((= *ZAxisType* 2) (SETQ pp_zmode 3)) ; Up/Down by Z-coordinates
      ))
    ((= *ZAxisOption* 2)
      (IF (= *ZSensoringmode* 1) (SETQ *CuttingLiftZParts* 3))
      (COND
        ((= *ZSensorType* 0) ; Auto Sensor
          (SETQ pp_zmode 4)
          (SETQ *DrillLiftZ* 3 *MarkingLiftZ* 3 *PiercingLiftZ* 3 *CuttingLiftZ* 3 *CuttingLiftZParts* 3))
        ((= *ZSensorType* 1) (SETQ pp_zmode 5)) ; Sensor by M-codes
        ((= *ZSensorType* 2) (SETQ pp_zmode 6)) ; Sensor by Z-coordinates
      ))
    ((= *ZAxisOption* 3)
      (SETQ pp_zmode 7))
  )
  ;(SETQ $standoff *ZStandoff*)
  ;(SETQ *ZMaxMovement* (- *ZMaxMovement* *Zstandoff*))
  (SETQ pp_$Zold *Zmaxmovement*)
  (SETQ $zmaxdist *ZMaxMovement*)
  (SETQ $zbase *ZBase*)
    ;(IF (= (STRCASE $post) "STM") (SETQ $zmaxdist (+ $zmaxdist *Zstandoff*))) ;****************** SPECIAL FOR STM ****************
  (SETQ $sensorminlift *ZMinMovement*)
  (SETQ $sensoringtime *ZSensoringTime*)
  (IF (AND (> (+ *Thickness* *ZStandoff*) *ZMaxMovement*) (NOT pp_thickcheck)) (PROGN (SETQ pp_thickcheck T) (IF (GP-YESNO "Too thick material for this machine. Stop?" T) (QUIT "*Cancel*"))))

  ; ***** Handling of piercing ******
  (SETQ $vacuumOndelay *VacuumOnDelay*)
  (IF (OR *AWJAutomaticPiercing* *3D-5X*)
    (PROGN
      (SETQ *AWJCircularPiercing* (CIRCULARPIERCINGTIME *Thickness*))
      (SETQ *AWJCircularPiercingDiameter* (CIRCULARPIERCINGDIAMETER))
      (SETQ *AWJCircularPiercingSpeed* (CIRCULARPIERCINGSPEED))
      (SETQ *AWJStationaryPiercing* (STATIONARYPIERCINGTIME *Thickness*))
      (SETQ *AWJLinearPiercingDistance* (* *Thickness* 0.15))))
  (IF (= *MAchineType* 0) (SETQ *Piercingdiameter* *AWJCircularPiercingDiameter*))


  ; ****** Handling of 5X settings ******
  (SETQ *MasterHeadSecondaryPrefer* *HeadSecondaryPrefer*) ; 0=Use negative, 1= Use positive, 2=Use both side
  (IF (< *HeadMinTilt* 0.01) (SETQ *HeadMinTilt* 0.01))
  (SETQ *HeadMinTilt* (DEGTORAD *HeadminTilt*))
  (SETQ *MaxforbiddenTilt* (DEGTORAD *MaxforbiddenTilt*))
  (IF (NOT *HeadPrimaryAxisLimitations*) (SETQ *HeadPrimaryMin* -400.0 *HeadPrimaryMax* 400.0))
  (IF (= *HeadType* 4) (SETQ *HeadKinematic* 0))
  (SETQ *HeadPrimaryMax* (DEGTORAD *HeadPrimaryMax*)) ; Gör om från grader till radianer
  (SETQ *HeadPrimaryMin* (DEGTORAD *HeadPrimaryMin*)) ; Gör om från grader till radianer
  (SETQ *HeadPrimaryMaxSpeed* (DEGTORAD *HeadPrimaryMaxSpeed*)) ;Gör om från grader till radianer
  (SETQ *HeadSecondaryMaxSpeed* (DEGTORAD *HeadSecondaryMaxSpeed*)) ; Gör om från grader till radianer
  (SETQ $Kinematic (1+ *HeadKinematic*))
  (SETQ $KinematicType *HeadType*)
  (IF (= *HeadType* 0) (SETQ $Kinematic 0))
    ; Om RTCP för headtype 2
  (IF (NOT (MEMBER *Headtype* (LIST 2 4))) (SETQ *RTCPUse* nil))
  (IF (AND *RTCPUse* (= *Headtype* 2))
    (PROGN
      (SETQ xdiff (* (- *RTCPMeasureX* *RTCPExpectX*) 0.5))
      (SETQ ydiff (* (- *RTCPMeasureY* *RTCPExpectY*) 0.5))
      (SETQ *CorrAngle* (ANGLE (LIST 0 0) (LIST xdiff ydiff)))
      (SETQ *CorrDist* (DISTANCE (LIST 0 0) (LIST xdiff ydiff)))
      (IF (< *Corrdist* 0.02) (SETQ *Corrdist* nil *CorrAngle* nil *RTCPUse* nil))))
  ; Om man bara har ett alternativ så fungerar inte checkboxarna.
  (SETQ *HeadMaxTilt* (DEGTORAD *HeadMaxTilt*))
  (IF (= *Headtype* 0) (SETQ *TAC* 0 *LAG* 0))
  (IF (> *Machinetype* 0) (SETQ *TAC* 0 *LAG* 0))


  ; ****** Handling of speed ******
  (SETQ $f *SpeedRapid*)
  (SETQ $fz *Zspeed*)
  (SETQ $fr *SpeedRapid*)


  ;(IF (> *Longestline* *ZMeasureDist*) (SETQ *LongestLine* *ZMeasureDist*))
  (IF (= *AWJAbrasiveFlowCNC* 0)(SETQ *AWJAbrasiveFlowCNC* nil))
  (IF (NOT *PiercingAlways*) (SETQ *PiercingAlways* 1))

  (IF (= *AWJBleedOut* 0) (SETQ *AWJBleedOut* nil))
  ; To be compatible with postprocessors that have this variable (wrong spelled) included in the postprocessor
  ;(IF *HeadSecondaryPrefere* (SETQ *HeadSecondaryPrefer* (IF *HeadSecondaryPrefereMinus* 0 1)))
  ; ****** Six axis cutting ******

  ; ****** Machine dependent things ******
  (COND
    ((= *MachineType* 0) nil)

    ((= *MachineType* 1)
      (SETQ *SerialProduction* 0)
      (SETQ *SkipPressureInit* 0)
      (SETQ *SkipPressureChanges* 0)
      (SETQ *SkipAbrasiveFlowChanges* 0))
    ((= *Machinetype* 2) nil) ; Plasma
  )
  (SETQ pp_oldp (LIST 0.0 0.0))

  (IF *ToolDistanceType* (SETQ *ToolDistanceByController* (IF (= *ToolDistanceType* 0) nil T))) ;KAN TAS BORT SEN..
  (IF (NOT *DrillingTools*) (SETQ *DrillLiftZ* 0))
  ;(IF *DrillingOffsetByController* (SETQ *DrillingXOffset* 0 *DrillingYOffset* 0))
  (SETQ $drillzoffset *DrillingZOffset*)
  (IF (NOT *MarkingType*) (SETQ *MarkingSpecial* nil) (SETQ *MarkingSpecial* T)) ; Machine has equipment for special marking
  (IF (NOT *Inkjet*) (SETQ *DoInkjet* nil)) ; *Inkjet* T, nil from machine settings
  (IF (NOT *Inkjet*) (SETQ *MarkingInkjet* 0)) ; No need to have Yes/No question if no inkjet present.
  (SETQ pp_toolindex 0)
  (SETQ *AWJPressureBMS* *AWJPressure* *AWJAbrasiveFlowBMS* *AWJAbrasiveFlow*) ; This values are saved for Initialization
  (IF (= *AWJPumpPressureCNC* 0) (SETQ *AWJPumpPressureCNC* nil))
  (IF (= *Speedmode* 1) (SETQ *AWJCircularPiercingSpeed* *AWJFixedSpeed* *AWJLinearPiercingSpeed* *AWJFixedSpeed*))
  (SETQ $wacode *AWJWaterAbrasiveSeparate*)
  (SETQ pp_notransnewp (LIST 0 0))
  (IF (NOT (EQUAL *ZMovableQuantity* *ToolQuantity*))(SETQ *ToolDistanceType* 0))
  (IF (NOT *DivideLongObjects*) (SETQ *LongestLine* 99999999.1))
  (SETQ *LargestSegmentAngle* (DEGTORAD *LargestSegmentAngle*))
  ;(IF (< *MachineType* 2) (SETQ *MarkingXOffset* 0 *MarkingYOffset* 0))
  (IF *RightHandRuleStandard* (SETQ *AxisMirroredX* nil *AxisMirroredY* nil *AxisSwapG2G3* nil *AxisSwapXY* nil))
  (IF (NOT *AWJCuttingPressureByMachine*) (SETQ *AWJPressure* *AWJCuttingPressure*))
  (IF (NOT *AWJCuttingAbrasiveFlowByMachine*) (SETQ *AWJAbrasiveFlow* *AWJCuttingAbrasiveFlow*))
  (IF (= *AWJPressure* *AWJMarkingPressure*) (SETQ *AWJMarkingPressureByMachine* T))
  (IF (= *AWJAbrasiveFlow* *AWJMarkingAbrasiveFlow*) (SETQ *AWJMarkingAbrasiveFlowByMachine* T))
  (IF (= *AWJPressure* *AWJPiercingPressure*) (SETQ *AWJPiercingPressureByMachine* T))
  (IF (= *AWJAbrasiveFlow* *AWJPiercingAbrasiveFlow*) (SETQ *AWJPiercingAbrasiveFlowByMachine* T))
  (IF *AWJMarkingPressureByMachine* (SETQ *Markingpressure* *AWJPressure*) (SETQ *Markingpressure* *AWJMarkingPressure*))
  (IF *AWJMarkingAbrasiveFlowByMachine* (SETQ *MarkingAbrasive* *AWJAbrasiveFlow*) (SETQ *MarkingAbrasive* *AWJMarkingAbrasiveFlow*))
  (IF (NOT *AWJMarkingUseAbrasive*) (SETQ *MarkingAbrasive* 0))
  (IF *AWJPiercingPressureByMachine* (SETQ *PiercingPressure* *AWJPressure*) (SETQ *Piercingpressure* *AWJPiercingPressure*))
  (IF *AWJPiercingAbrasiveFlowByMachine* (SETQ *PiercingAbrasive* *AWJAbrasiveFlow*) (SETQ *PiercingAbrasive* *AWJPiercingAbrasiveFlow*))
  (IF (< *CuttingLiftHeightParts* *CuttingLiftHeight*) (SETQ *CuttingLiftHeightParts* *CuttingLiftHeight*))
  (SETQ *CuttingPressure* *AWJPressure* *CuttingAbrasive* *AWJAbrasiveFlow*)
  ; You only have to use *Markingpressure* *MarkingAbrasive* *PiercingPressure* *PiercingAbrasive* and the **ByMachine* variables
  (SETQ *ActualPressure* nil *ActualAbrasive* nil *ActualQuality* nil)

  (SETQ *DrillingToolsActive* (IF *DrillingOnFirst* 1 *ToolMaxbit*))
  (IF (= pp_zmode 0) (SETQ *DrillLiftZ* 0 *MarkingLiftZ* 0 *PiercingLiftZ* 0 *CuttingLiftZ* 0 *CuttingLiftZParts* 0))
  (IF (NOT *ReportCreateAutomatically*) (SETQ *ReportPrint* 0))
  (IF (NOT *ReportCreateAutomaticallyCost*) (SETQ *ReportPrintCost* 0))
  ; Handling of output units
  (IF *3D-5X*
    (PROGN
      ;(SETQ *TiltDownOrder* T)
      ; BELOW: We always ned to lift at leas to the height of the model
      (IF (NOT *DrillLiftZ*) (SETQ *DrillLiftHeight* 0))
      (IF (NOT *MarkingLiftZ*) (SETQ *MarkingLiftHeight* 0))
      (IF (NOT *PiercingLiftZ*) (SETQ *PiercingLiftHeight* 0))
      (IF (NOT *CuttingLiftZ*) (SETQ *CuttingLiftHeight* 0))
      (IF (NOT *CuttingLiftZParts*) (SETQ *CuttingLiftHeightParts* 0))
      (SETQ *DrillLiftZ* 3 *MarkingLiftZ* 3 *PiercingLiftZ* 3 *CuttingLiftZ* 3 *CuttingLiftZParts* 3)))
  (SETQ outlist (LIST
    (LIST (LTF "Skip pressure init") '*SkipPressureInit*)
    (LIST (LTF "Start pump automatically") '*AWJStartPumpAuto*)
    (LIST (LTF "Skip pressure changes") '*SkipPressureChanges*)
    (LIST (LTF "Skip abrasive flow changes") '*SkipAbrasiveFlowChanges*)
    (LIST (LTF "Service position before 5X-cutting") '*PiercingAlways*)
    (LIST (LTF "End with start pressure") '*SerialProduction*)
    (LIST (LTF "Stop pump automatically") '*AWJStopPumpAuto*)
    (LIST (LTF "Skip tool init") '*SkipToolInit*)
    (LIST (LTF "Stop after first cut") '*StopAfterFirstCut*)
    (LIST (LTF "Stop after first part") '*StopAfterFirstPart*)
    (LIST (LTF "Add comments") '*AddComments*)
    (LIST (LTF "View output file") '*ViewOutputFile*)
    (LIST (LTF "Lift Z-axis between drillings") '*DrillLiftZ*)
    (LIST (LTF "Lift Z-axis between markings") '*MarkingLiftZ*)
    (LIST (LTF "Inkjet marking") '*MarkingInkjet*)
    (LIST (LTF "Lift Z-axis between piercings") '*PiercingLiftZ*)
    (LIST (LTF "Lift Z-axis between cuttings") '*CuttingLiftZ*)
    (LIST (LTF "Lift Z-axis between parts") '*CuttingLiftZParts*)
    (LIST (LTF "Stroke between drillings") '*DrillPneumatic*)
    (LIST (LTF "Stroke between markings") '*MarkingPneumatic*)
    (LIST (LTF "Stroke between piercings") '*PiercingPneumatic*)
    (LIST (LTF "Stroke between cuttings") '*CuttingPneumatic*)
    (LIST (LTF "TAC") '*TAC*)
    (LIST (LTF "VOC") '*VOC*)
    (LIST (LTF "LAG") '*LAG*)
    (LIST (LTF "Use rotation axis") '*Tube6AxisPrefere*)
    (LIST (LTF "End with parking position") '*GotoParkPos*)
    (LIST (LTF "Send to IGEMS CNC") '*IgemsCNCSend*)
    (LIST (LTF "Copy to backup folder") '*OutputMakeBackup*)
    (LIST (LTF "Print job report") '*ReportPrint*)
    (LIST (LTF "Print cost report") '*ReportPrintCost*))
  )

  ;(COND
  ;  ((MEMBER *InternalToolCompensation* (LIST 0 1)) (SETQ show T)) ; If in IGEMS and if in IGEMS and Controller
  ;  (bevel (SETQ show T))
  ;  (T  (FOREACH s outlist (IF (MEMBER (EVAL (CADR s)) (LIST 1 2)) (SETQ show T))))
  ;)
  ;(SETQ show nil)
  ;(FOREACH s outlist (IF (MEMBER (EVAL (CADR s)) (LIST 1 2)) (SETQ show T)))
  ;(IF (NOT show) (FOREACH s outlist (IF (= (EVAL (CADR s)) 0) (SET (CADR s) nil) (SET (CADR s) T))))
  (IF (NOT *ShowOptions*)
    (FOREACH s outlist (IF (= (EVAL (CADR s)) 0) (SET (CADR s) nil) (SET (CADR s) T))))
  (IF *ShowOptions*
    (PROGN
      (DEFUN handle (object)
        (COND
          ((= object e:diam)
            (SETQ value (DISTOF (GP-GETQ object VALUE) 0 (* downscale *MaxToolDiameter*)))
            (IF value
              (PROGN
                (SETQ *Tooldiameter* (* upscale value))
                (GP-SETQ l:diam TIP (TIPTEXT))
                (GP-SETQ object TIP (TIPTEXT)))
              (PROGN
                (BEEP)
                (ALERT (STRCAT (LTF "Tool diameter must be between 0 and") " " (RTOS (* downscale *MaxToolDiameter*) (IF *Metric* 3 4))))
                (GP-SETQ object VALUE (RTOS (DISTOF (GP-OLDVALUE)) (IF *Metric* 3 4) T)))))
          ((= object e:underlay)
            (IF (NOT (SETQ *ZStandoff* (DISTOF (GP-GETQ object VALUE) -3 (* downscale 800.0))))
                (GP-SETQ object VALUE (SETQ *ZStandoff* (DISTOF (GP-OLDVALUE)))))
            (SETQ *ZStandoff* (* upscale *ZStandoff*)))

          ((= object dlg) (GP-CLOSE dlg nil)) ; ESC will close
          ((= object b:ok)
            (HANDLE e:diam)
            (HANDLE e:underlay)
            (FOREACH s tgls (SET (CADR s) (GP-GETQ (CAR s) VALUE)))
            (GP-CLOSE dlg T))
          ((= object b:cancel)
            (GP-CLOSE dlg nil))
        )
      )
      (IF *Metric* (SETQ upscale 1.0 downscale 1.0) (SETQ upscale 25.4 downscale 0.039370078))
      (DEFUN tiptext ()
        (IF (= *InternalToolCompensation* 1)
          (STRCAT "IGEMS: " (RTOS (* (- *Tooldiameter* *AWJAdditionalkerf*) downscale) (IF *Metric* 3 4) T) " + "
          (LTF "Machine") ": " (RTOS (* *AWJAdditionalkerf* downscale) (IF *Metric* 3 4) T)) "")
      )
      (SETQ dlg (GP-DIALOG (STRCAT (LTF "Options") " " *MachineName*) ACTION handle))
      (IF (= *Machinetype* 0)
        (PROGN
          (SETQ cutflow (IF *AWJCuttingAbrasiveFlowByMachine* *AWJAbrasiveFlow* *AWJCuttingAbrasiveFlow*))
          (SETQ tip (LTF "General machine speed factor"))
          (SETQ row (GP-FRAME dlg (LTF "Info") EXPANDX T))
          (SETQ col (GP-COLUMN row WRAPCOUNT 2 CHILDEXPANDX nil ALIGN 0))
          (GP-LABEL col (LTF "Factor") ALIGN 4 TIP tip)
          (GP-LABEL col (RTOS *AWJSpeedFactor* 2 T) TIP tip)
          (GP-LABEL col (LTF "Pressure") ALIGN 4)
          (GP-LABEL col (STRCAT (ITOA (IF *Metric* *Cuttingpressure* (FIX (* *Cuttingpressure* 14.50326)))) " " (IF *Metric* (LTF "bar") (LTF "psi"))))
          (GP-LABEL col (LTF "Abrasive") ALIGN 4)
          (GP-LABEL col (STRCAT (IF *Metric* (ITOA cutflow) (RTOS (/ cutflow 453.5924) 2)) " " (IF *Metric* (LTF "g/min") (LTF "lbs/min"))))
          (COND
            ((= *ZAxisOption* 0) (GP-LABEL row "Z-axis: Fixed"))
            ((= *ZAxisOption* 1) (GP-LABEL row "Z-axis: CNC-controlled"))
            ((= *ZAxisOption* 2) (GP-LABEL row "Z-axis: By height sensor"))
            ((= *ZAxisOption* 3) (GP-LABEL row "Z-axis: Measuring in advance"))
          )
          (GP-FILL dlg HEIGHT 10)))
      (SETQ row (GP-ROW dlg TIP (TIPTEXT)))
       ; *InternalToolCompensation* 0=IGEMS, 1=IGEMS and Controller, 2=Controller
      (GP-FILL row EXPANDX T)
      (SETQ l:diam (GP-LABEL row (LTF "Tool diameter") TIP (TIPTEXT)))
      (SETQ e:diam (GP-EDIT row VALUE (RTOS (* *Tooldiameter* downscale) (IF *Metric* 3 4) T) WIDTH 70 EXPANDX nil TIP (TIPTEXT)))
      (SETQ row (GP-ROW dlg EXPANDX T))
      (GP-FILL row EXPANDX T)
      (GP-LABEL row (LTF "Underlay"))
      (SETQ e:underlay (GP-EDIT row VALUE (RTOS (* *ZStandoff* downscale) (IF *Metric* 3 4) T) WIDTH 70 EXPANDX nil))
      (FOREACH s outlist
        (SETQ value (EVAL (CADR s)))
        (SETQ name (CADR s))
        (COND
          ((NOT value) (SET name nil)) ; If the variable is nil
          ((= value 0) (SET name nil))
          ((= value 3) (SET name T))
          (T
            (SETQ tgls (CONS (LIST (GP-TOGGLE dlg (CAR s) VALUE (IF (= value 1) nil T)) name) tgls)))
        )
      )
;      (SETQ *DoInkjet* *MarkingInkjet*)
      (SETQ row (GP-ROW dlg ALIGN GPC-CENTER))
      (SETQ b:ok (GP-BUTTON row (LTF "OK") UNIFORMW T DEFAULT T))
      (SETQ b:cancel (GP-BUTTON row (LTF "Cancel") uniformw T))
      (GP-FOCUS b:ok)
      (SETQ status (GP-SHOWMODAL dlg))
    )
  )
  (SETQ *DoInkjet* *MarkingInkjet*)
  (SETQ $Underlay *ZStandoff*)
  (IF *IS-IGEMS-CNC* (SETQ *ZStandoff* 0.0))
  (SETQ $sendtoCNC *IgemsCNCSend*)
  (SETQ $pumpstart *AWJStartPumpAuto*)
  (SETQ $pumpstop *AWJStopPumpAuto*)
  (IF (AND (> (+ *Thickness* *ZStandoff*) *ZMaxMovement*)(NOT pp_thickcheck)) (PROGN (SETQ pp_thickcheck T) (IF (GP-YESNO "Too thick material for this machine. Stop?") T) (QUIT "*Cancel*")))
  (IF (MINUSP *ZStandoff*)
    (PROGN
      (BEEP)
      (IF (NOT (GP-YESNO (LTF (STRCAT "Warning! Negative underlay. Continue ?")) nil)) (QUIT "Negative underlay"))))
  (SETQ $standoff *ZStandoff*)
  (SETQ *MasterTAC* (OR *TAC* *LAG*))
  (IF (/= *InternalToolCompensation* 1) (SETQ *AWJAdditionalkerf* 0.0))
  (IF *LAB* (ALERT "Warning *LAB* mode activated"))
  (IF *SendToIgemsCnc* (SETQ $SendToCnc T))
  (IF (OR status (NOT *ShowOptions*))
    (PROGN
      (CAM-INITIALIZE (- *ToolDiameter* *AWJAdditionalkerf*) *Tooldiameter* *TAC* *VOC* *LAG* *LAB* *PiercingAlways* *ReportPrint* *ReportPrintCost*) T)
    nil
  )
)

(IF (OR ppp_sim1 ppp_sim2 ppp_sim3)
  (LOAD (STRCAT (GETVAR "PATHROOT")	"LSP/SIMULATOR.LSP")
  (ALERT (STRCAT "Cant find: " (GETVAR "PATHROOT")	"LSP/SIMULATOR.LSP")))
)

; The CHKALL function check all information before the postprocessing starts. The reason is:
; A: To know how many different pressures needed. Some machines do only support 2 different
; B: To calculate a center of a bounding box for the laser measurements. *********** THIS WE DON'T NEED ANY LONGER ******

(DEFUN chkall(/ prog subprogs geometry clline cmd vars mustpierce mustmark maxsortid maxbit dospeedramp exludespeedramp okadd) ; To check how many different pressures that are needed.
  ;(PRINC "CHECKALL START")
  ;(FLowhighUNBROWSER "CHKALL")
  (SETQ maxbit 1)
  (REPEAT *ToolQuantity* (SETQ maxbit (* maxbit 2)))
  (SETQ maxbit (1- maxbit))
  (SETQ maxsortid 0)
  (SETQ $contains 0)
  (SETQ pp_lowhighlist nil) ; this list holds information if the cutting should end in low pressure if the *PiercingByType* variable is set to 3
  (SETQ pp_lowpressurepiercing (ChkIfPiercing))  ; Check if piercing have special settings in Abrasive or Pump pressure
    ;(SETQ pp_lowpressurepiercing T)
  (SETQ $toolchanges 0)
  (FOREACH tset mainprog
    (FOREACH mainline tset
      (SETQ cmdm (CAR mainline))
      (SETQ varsm (CADR mainline))
      (IF (= cmdm '$TOOLSET)
        (PROGN
          (SETQ needdist (CADR varsm))
          (IF (EQUAL needdist 0.0 0.00001) (SETQ needdist *ToolFixDistance*))
          (COND
            ((= (CAR varsm) 1) nil) ; No need to check if only one tool are in use.
            ((> (CAR varsm) maxbit) (PRINC (QUIT (ALERT (STRCAT "Wrong number of tools")))))
            ((AND (> (CAR varsm) 1) (NOT (= (CADDDR varsm) *BarAligned*))) (PRINC (QUIT (ALERT "Wrong table layout"))))
            ((< needdist *ToolMinDistance*) (PRINC (QUIT (ALERT (STRCAT "Min tool distance:" (RTS *ToolMinDistance*) ". Needed distance:" (RTS needdist))))))
            ((> needdist *ToolMaxDistance*) (PRINC (QUIT (ALERT (STRCAT "Max tool distance:" (RTS *ToolMaxDistance*) ". Needed distance:" (RTS needdist))))))
          )
          (IF (NOT $inittools) (SETQ $inittools (CAR varsm) $inittooldist needdist))
          (SETQ $toolchanges (1+ $toolchanges))))
      (IF (= cmdm '$CALL)
        (PROGN
          (SETQ subnr (NTH 0 varsm) pp_basex (NTH 1 varsm) pp_basey (NTH 2 varsm) pp_rotate (NTH 3 varsm) pp_sortid (NTH 4 varsm))
          (IF (> pp_sortid maxsortid) (SETQ maxsortid pp_sortid))
          (SETQ prog (NTH subnr subprogs))
          (SETQ bbox (NTH 6 (CADR (CAR prog))))
          (SETQ bboxcp (LIST (* (+ (CAR bbox) (CADDR bbox)) 0.5) (* (+ (CADR bbox) (CADDDR bbox)) 0.5)))
          (FOREACH geometry (CDR prog) ; CDR remove the initial part information.
            (FOREACH clline geometry
              (SETQ cmd (CAR clline))
              (SETQ vars (CADR clline))
              (IF (= cmd '$FINGER)
                (PROGN
                  (IF (NOT fingerq) (SETQ fingerq 0))
                  (SETQ x (NTH 2 vars) y (NTH 3 vars) z (NTH 4 vars))
                  (SETQ pt (TRANS x y z))
                  (SETQ x (CAR pt) y (CADR pt))
                  (SETQ $fingerdata (CONS (LIST (SETQ fingerq (1+ fingerq)) (NTH 0 vars) (NTH 1 vars) x y z (NTH 5 vars) (NTH 6 vars)) $fingerdata))))
              (IF (= cmd '$CUTON)
                (PROGN
                  (SETQ okadd T)
                  (IF (> (LOGAND (NTH 21 vars) 2) 0) (SETQ $uses5x T)) ;ZOK
                  (IF (> (LOGAND (NTH 21 vars) 128) 0) (SETQ exludedspeedramp T))
                  (IF (= (LOGAND (NTH 21 vars) 128) 0) (SETQ dospeedramp T))
                  (IF (AND (> (LOGAND (NTH 21 vars) 64) 0) *MasterTAC*) (SETQ $uses5x T)))) ; Added 2016.07.07
              (COND
                ((AND (= cmd '$CUTON) pp_lowpressurepiercing)
                  (SETQ okadd T)
                  (COND
                    ((OR (= (NTH 4 vars) 2) (= (NTH 4 vars) 3)) ; If its stationary or cirular piercing
                      (IF (= *PiercingByType* 3)
                        (SETQ lowhigh T)
                        (SETQ mustpierce T)))
                    ((AND (= (NTH 4 vars) 4) *DrillingTools*) ;ZOK
                      (SETQ $usesdrill T))
                    ((AND (= (NTH 4 vars) 4) (NOT *DrillingTools*)) ; If no drilling tool, then use circular piercing
                      (IF (= *PiercingByType* 3)
                        (SETQ lowhigh T)
                        (SETQ mustpierce T)))
                    )
                    (SETQ mustcut T))
                ((= cmd '$CUTON) ; Drilling
                  (IF (AND (= (NTH 4 vars) 4) *DrillingTools*) ;ZOK
                    (SETQ $usesdrill T))
                  (SETQ mustcut T))
                ((= cmd '$HOLE)
                  (SETQ okadd T)
                  (COND
                    ((AND (= (NTH 3 vars) 0) (NOT *DrillingTools*) pp_lowpressurepiercing) ; if no drilling tools then circular piercing ZOK
                      (IF (= *PiercingByType* 3)
                        (SETQ lowhigh T)
                        (SETQ mustpierce T)))
                    ((= (NTH 3 vars) 0) ; The hole should be drilled ZOK
                      (SETQ $usesdrill T))
                    ((= (NTH 3 vars) 1) ; if the hole should be marked ;ZOK
                      (SETQ mustmark T))
                    ((AND (= (NTH 3 vars) 2) pp_lowpressurepiercing) ;if the hole should be circular pierced. ZOK
                      (SETQ mustpierce T))
                    ((= (NTH 3 vars) 3) ; Check if HQCH will be used ZOK
                      (SETQ useHQCH T))
                    ((AND (= (NTH 3 vars) 4) pp_lowpressurepiercing) ; If the hole should be stationary pierced
                      (IF (= *PiercingByType* 3)
                        (SETQ lowhigh T)
                        (SETQ mustpierce T)))
                   ))
                ((= cmd '$MARKON)
                  (SETQ okadd T)
                  (IF (NTH 6 vars)
                    (SETQ pp_specmarking T)
                    (SETQ mustmark T))
                  (IF (NTH 10 vars) (SETQ $uses5x T)))
                ((= cmd '$TEXT)
                  (SETQ mustmark T))
               )
            )
            (IF okadd (SETQ pp_lowhighlist (CONS lowhigh pp_lowhighlist)))
            (SETQ lowhigh nil okadd nil)
          )
        )
      )
    )
  )
  (IF mustmark (IF (= (LOGAND 2 $contains) 0) (SETQ $contains (+ $contains 2))))
  ;(IF (EQUAL *Cuttingpressure* *Markingpressure* 1) (SETQ mustmark nil))
  (IF (AND mustmark mustpierce (= *AWJPumpPressureCNC* 1))
    (PROGN
      (ALERT "Machine support only two different pressures.\nMarking will use piercing pressure")
      (SETQ *MarkingPressure* *PiercingPressure*)
    )
  )
  (IF pp_specmarking (IF (= (LOGAND 256 $contains) 0) (SETQ $contains (+ $contains 256))))
  (COND
    ((AND mustpierce pp_lowpressurepiercing) ; Prepiercing
      (SETQ pp_makeprepiercing T)
      (IF (= (LOGAND 4 $contains) 0) (SETQ $contains (+ $contains 4))))
    (pp_lowhighlist
      (SETQ pp_lowhighlist (CONS (LAST pp_lowhighlist) pp_lowhighlist))
      (SETQ pp_lowhighlist (CDR (REVERSE pp_lowhighlist)))
      (SETQ $lowatend (LAST pp_lowhighlist)))
  )
  (IF (AND $usesdrill (= (LOGAND 8 $contains) 0)) (SETQ $contains (+ $contains 8))) ; 8=Drilling
  (IF (AND useHQCH (= (LOGAND 32 $contains) 0)) (SETQ $contains (+ $contains 32)))
  (IF exludedspeedramp (SETQ $contains (+ $contains 128)))
  (IF dospeedramp (SETQ $contains (+ $contains 64)))
  (SETQ $maxsortid maxsortid)

  (IF (AND mustmark (= *MarkingByType* 0)) (SETQ dosheetwise T))
  (IF (AND mustpierce (= *PiercingByType* 0)) (SETQ dosheetwise T))
  (IF (AND $usesdrill (= *DrillByType* 0)) (SETQ dosheetwise T))

  (IF (AND mustmark (= *MarkingByType* 1)) (SETQ dotoolwise T))
  (IF (AND mustpierce (= *PiercingByType* 1)) (SETQ dotoolwise T))
  (IF (AND $usesdrill (= *DrillByType* 1)) (SETQ dotoolwise T))

  (IF (AND mustmark (= *MarkingByType* 2)) (SETQ dopartwise T))
  (IF (AND mustpierce (= *PiercingByType* 2)) (SETQ dopartwise T))
  (IF (AND $usesdrill (= *DrillByType* 2)) (SETQ dopartwise T))
  ;(PRINC "CHKALL END")
)

(DEFUN $DATAPOINT (vars / pp_x pp_y pp_zmaster pp_vec $attrib)
  (SETQ pp_x (NTH 0 vars) pp_y (NTH 1 vars) pp_zmaster (NTH 2 vars) pp_vec (NTH 3 vars) $attrib (NTH 4 vars))
  (SETQ pp_$pt (TRANS pp_x pp_y pp_zmaster))
  (SETQ pp_$x (CAR pp_$pt) pp_$y (CADR pp_$pt) pp_$z (CADDR pp_$pt))
  (SETQ $vector (TRANSVEC pp_vec))
  (DEFVARS)
  (DATAPOINT)
)

(DEFUN datapoint () nil)


(DEFUN body (/ vars vars2 optype tmp cmdbody)
  ;(IF fun (WRITE "BODY"))
  (SETQ pp_oldtooldata nil)
  (SETQ bySheet (MakeByList 0)) ; Create a list of bySheet operations
  (SETQ byTool (MakeByList 1))  ; Create a list of byTool operations
  (SETQ bypart (MakeByList 2))  ; Create ByPart operations
  (SETQ bystart (MakeByList 3))
  (IF (AND *ZMeasure* (= *ZAxisOption* 3) (= *ZMeasureType* 0)) ($MAKEGRID)); *measuring equipmen, Measuring in strategy, Sheetwise in strategy
  ; To handle the datapoints fucntion
  ($MAKEDATAPOINTS)

  ; To handle the start rapid functions. This will work only for SRAPID

  ; ****************************************************** ALL FUNCTIONS BELOW RUNS ALWAYS FIRST: INITIALRAPIDS, INKJET, SPECIAL-MARKING ******
  (SETQ pp_basex 0 pp_basey 0.0 pp_rotate 0.0)
  (FOREACH mainline (CAR mainprog)
    (SETQ cmd (CAR mainline))
    (SETQ vars (CADR mainline))
    (COND
      ((= cmd '$TOOLSET) (SETQ pp_tooldata vars pp_toolcop vars))
      ((AND (= cmd '$RAPID) (NTH 3 vars))
        (SETQ pp_rapidnative 2)
        ($RAPID vars)
        (SETQ pp_rapidnative nil))
    )
  )
  ; Handling of InkJet and Special marking
  (FOREACH op (LIST 16 32)
    (IF (OR (AND (= op 16) *DoInkJet*)      ; This is InkJet
           (AND (= op 32) pp_specmarking)) ; This is SpecialMarking
      (PROGN
        (SETQ ActivatedTool nil)
        (FOREACH tset mainprog
          (SETQ copies nil first nil pp_toollist nil)
          (FOREACH mainline tset
            (SETQ cmdbody (CAR mainline))
            (SETQ vars (CADR mainline))
            (SETQ svvars vars)
            (IF (= op 16)
              (SETQ ontooloffset (- (* (1- *InkjetOnTool*) *ToolMinDistance*)))
              (SETQ ontooloffset (- (* (1- *MarkingOnTool*) *ToolMinDistance*))) ; Offset between first tool and the tool thats hold the equipment.
            )
            (IF (= cmdbody '$TOOLSET)
              (PROGN
                (SETQ pp_savedtooldata vars)
                (SETQ pp_toollist (REPEAT *ToolQuantity* (SETQ pp_toollist (CONS *ToolMinDistance* pp_toollist))))
                (COND
                  (ActivatedTool nil)
                  ((= op 16) ; Inkjet
                    (SETQ pp_tooldata (LIST (ONETOBIT *InkjetOnTool*) *ToolMinDistance* (CADDR vars) (CADDDR vars)))) ; VALUES:TOOLS(bit), Distance, Index, Align
                  ((= op 32) ; Specialmarking
                    (SETQ pp_tooldata (LIST (ONETOBIT *MarkingOnTool*) *ToolMinDistance* (CADDR vars) (CADDDR vars)))) ; VALUES:TOOLS(bit), Distance, Index, Align
                )
                (SETQ ActivatedTool T)
                (SETQ bit (CAR vars))
                (SETQ dist (CADR vars)); This is the distance between the parts on the drawing
                ;(SETQ copies (CONS 1 copies))
                (IF (> (LOGAND 1 bit) 0) (PROGN (SETQ copies (CONS 1 copies) first 1)))
                (IF (> (LOGAND 2 bit) 0) (PROGN (SETQ copies (CONS 2 copies)) (IF (NOT first) (SETQ first 2))))
                (IF (> (LOGAND 4 bit) 0) (PROGN (SETQ copies (CONS 3 copies)) (IF (NOT first) (SETQ first 3))))
                (IF (> (LOGAND 8 bit) 0) (PROGN (SETQ copies (CONS 4 copies)) (IF (NOT first) (SETQ first 4))))
                (IF (> (LOGAND 16 bit) 0) (PROGN (SETQ copies (CONS 5 copies)) (IF (NOT first) (SETQ first 5))))
                (IF (> (LOGAND 32 bit) 0) (PROGN (SETQ copies (CONS 6 copies)) (IF (NOT first) (SETQ first 6))))
                (IF (> (LOGAND 64 bit) 0) (PROGN (SETQ copies (CONS 7 copies)) (IF (NOT first) (SETQ first 7))))
                (IF (> (LOGAND 128 bit) 0) (PROGN (SETQ copies (CONS 8 copies)) (IF (NOT first) (SETQ first 8))))
              )
            )
            (IF (= cmdbody '$CALL)
              (PROGN
                (FOREACH s (REVERSE copies)
                  (SETQ s (- s first))
                  (COND
                    ((= *BarAligned* 0) (SETQ pp_xoffset (+ (* dist s) ontooloffset) pp_yoffset 0.0))
                    ((= *BarAligned* 1) (SETQ pp_xoffset (- (* dist s) ontooloffset) pp_tooladd 0.0))
                    ((= *BarAligned* 2) (SETQ pp_xoffset 0.0 pp_yoffset (+ (* dist s) ontooloffset)))
                    ((= *BarAligned* 3) (SETQ pp_xoffset 0.0 pp_yoffset (- (* dist s) ontooloffset)))
                  )
                  (DOSUB vars op) ; 16=Inkjet, 32=SpecialMarking
                )
              )
            )
          )
        )
        (SETQ pp_xmod 0.0 pp_ymod 0.0 pp_xmodsim 0.0 pp_ymodsim 0.0) ; Offset between jet and equipment
        (SETQ pp_tooldata pp_savedtooldata)
      )
    )
  )
  ;********************************* END OF ALL OPERATIONS THAT RUNS FIRST IN THE JOB **********************
  (SETQ pp_xoffset 0.0 pp_yoffset 0.0) ; Offset mellan T1-T2-T3 osv
  ; above added 2013-01-29 end
  (FUNBROWSER (STRCAT "IN BODY BYSHEET OPERATIONS:" (TOSTR bysheet)))
  (IF dosheetwise
    (FOREACH bysheet-optype bysheet
      (FOREACH tset mainprog
        (FOREACH mainline tset
          (SETQ cmdbody (CAR mainline))
          (SETQ vars (CADR mainline))
          (SETQ svvars vars)
          (IF (= cmdbody '$TOOLSET) (IF (NOT (EQUAL pp_tooldata vars))(SETQ pp_tooldata vars)))
          (IF (= cmdbody '$CALL) (DOSUB vars bysheet-optype))
        )
      )
    )
  )

  (FOREACH tset mainprog
    (IF (NOT dotoolwise) (SETQ bytool nil))
    (FOREACH bytool-optype bytool
      (FOREACH mainline tset
        (SETQ cmdbody (CAR mainline))
        (SETQ vars (CADR mainline))
        (SETQ svvars vars)
        (IF (= cmdbody '$TOOLSET) (IF (NOT (EQUAL pp_tooldata vars))(SETQ pp_tooldata vars)))
        (IF (= cmdbody '$CALL) (DOSUB vars bytool-optype))
      )
    )
    (FOREACH mainline tset
      (IF (NOT dopartwise) (SETQ bypart nil))
      (FOREACH bypart-optype bypart
        (SETQ cmdbody (CAR mainline))
        (SETQ vars (CADR mainline))
        (SETQ svvars vars)
        (IF (= cmdbody '$TOOLSET) (IF (NOT (EQUAL pp_tooldata vars))(SETQ pp_tooldata vars)))
        (IF (= cmdbody '$CALL) (DOSUB vars bypart-optype))
      )
      (SETQ qtmp 0)
      (FOREACH bystart-optype bystart
        (SETQ cmdbody (CAR mainline))
        (SETQ vars (CADR mainline))
        (SETQ svvars vars)
        (IF (= cmdbody '$TOOLSET) (IF (NOT (EQUAL pp_tooldata vars)) (SETQ pp_tooldata vars)))
        (IF (= cmdbody '$STOP) (SETQ pp_stopdata vars))
        (IF (= cmdbody '$CALL) (DOSUB vars bystart-optype))
        (IF (AND (= cmdbody '$RAPID) (NOT (NTH 3 vars)))  ; NTH 3 var 2
          (PROGN
            (SETQ pp_basex 0 pp_basey 0.0 pp_rotate 0.0)
            (SETQ pp_rapidnative 2)
            ($RAPID vars)
            (SETQ pp_rapidnative nil)))
      )
    )
  )
  (IF drilling-flag ($DRILLING-END))
  (IF ppiercing-flag ($PPIERCING-END))
  (IF marking-flag ($MARKING-END))
  (IF cutting-flag ($CUTTING-END))
)

; The function DOSUB
(DEFUN dosub (vars optype / subnr pp_basex pp_basey pp_rotate pp_sortid sub geometry vars clline nextype vecdirend
                            newgeo cmd tmpp len pp_lmdist pp_lmoldp partoflen pt cent rad ccw stv slv inclv vtmp allpoints)
  ; optype means following: 1=Drilling, 2=Marking, 4=Prepiercing, 8=Cutting, 16=Inkjet, 32=Special marking
  (SETQ subnr (NTH 0 vars) pp_basex (NTH 1 vars) pp_basey (NTH 2 vars) pp_rotate (NTH 3 vars) pp_sortid (NTH 4 vars) $orderattrib (NTH 5 vars))
  (SETQ p_basex pp_basex p_basey pp_basey p_rotate pp_rotate)
  (SETQ sub (NTH subnr subprogs))
  (SETQ $sortid pp_sortid)
  (SETQ $optype optype)
  (SETQ $basex pp_basex $basey pp_basey $rotate pp_rotate)
  (SETQ *HeadSecondaryPrefer* *MasterHeadSecondaryPrefer*)
  (SETQ pp_nrgeometry 10) ; so the value is T and not 0
  (IF (AND (= (CAAR sub) '$PART) (NOT (EQUAL pp_sortid pp_oldsortid)))
    (PROGN
      (SETQ pp_oldsortid pp_sortid)
      (SETQ pp_partdata (CADR (CAR sub)))
      (SETQ bbox (NTH 6 pp_partdata))
      (SETQ bboxcp (LIST (* (+ (CAR bbox) (CADDR bbox)) 0.5) (* (+ (CADR bbox) (CADDDR bbox)) 0.5)))))
  (IF (= optype 16) ; Inkjet marking
    (PROGN
      (FOREACH geometry (CDR sub)
        (FOREACH clline geometry
          (SETQ cmd (CAR clline))
          (SETQ vars (CADR clline))
          (IF (= cmd '$ITEXT) ($ITEXT vars))
        )
      )
    )
  )
  ; added 2017.10.18 to handle special marking
  (IF (= optype 32)
    (PROGN
      (FOREACH geometry (CDR sub)
        (FOREACH clline geometry
          (SETQ cmd (CAR clline))
          (SETQ vars (CADR clline))
          (COND
            ((= cmd '$MARKON)
              (IF (NTH 6 vars)
                (PROGN
                  (IF (NOT specialmarking-flag) ($SPECIALMARKING-BEGIN))
                  ($MARKON vars))))
            ((= cmd '$LINE)
              (IF (> (LOGAND (NTH 3 vars) 128) 0) ($LINE vars)))
            ((= cmd '$ARC)
              (IF (> (LOGAND (NTH 6 vars) 128) 0)
                ($ARC vars))) ; If the marking flag is On
            ((= cmd '$MARKOFF)
              (IF (AND specialmarking-flag (NTH 0 vars)) ($MARKOFF vars)))
          )
        )
      )
    )
  )
  ; Loop all geometry lists in the sub program. It's one geometry list for each cutting start
  ; optype 8=Cutting
  (SETQ pp_nrgeometry (1- (LENGTH sub)))

  (IF (AND *ZMeasure* (= *ZMeasureType* 1) (= *ZAxisOption* 3)) ; If measure, Partwise measuring, measure as strategy
    (PROGN
      (SETQ pp_kdtree nil)
      (IF pp_tooldata ($TOOLSET pp_tooldata))
      (SETQ pp_tooldata nil)
      (FOREACH geometry (CDR sub)
        (MEASUREGEOMETRY geometry) ; all points will be transed in the function.
      )
      (IF pp_kdtree
        (PROGN
          (IF pp_partdata ($PART pp_partdata))
          (FOREACH s (REVERSE pp_kdlist)
            ($MEASURE (CAR s) (CADR s) (CADDR s)) ; X,Y and point number
          )
          (SETQ pp_kdlist nil)))))
  (FOREACH geometry (CDR sub)
    (SETQ pp_nrgeometry (1- pp_nrgeometry))
    (IF (AND *ZMeasure* (= *ZAxisOption* 3) (= *ZMeasureType* 2) (NOT (= (CAAR geometry) '$HOLE)))
      (PROGN
        (SETQ pp_kdtree nil)
        (MEASUREGEOMETRY geometry) ; all points will be transed in the function nil=No holes will be measured
        (IF pp_kdtree
          (PROGN
            (IF pp_tooldata ($TOOLSET pp_tooldata))
            (SETQ pp_tooldata nil)
            (FOREACH s (REVERSE pp_kdlist)
              ($MEASURE (CAR s) (CADR s) (CADDR s)) ; X,Y and pont number
            )
            (SETQ pp_kdlist nil)))))
;    (IF (< *MasterHeadSecondaryPrefer* 2)
;      (PROGN
;        (IF (< pp_maxslope *MaxforbiddenTilt*)
;          (SETQ *HeadSecondaryPrefer* 2)
;          (SETQ *HeadSecondaryPrefer* *MasterHeadSecondaryPrefer*))))
    (IF (OR (> (LOGAND optype 8) 0) (> (LOGAND optype 2) 0)) (PRECHECK-ROTATIONS geometry)) ; Check if marking or cutting
    (SETQ pp_lindex 0)
    (SETQ pp_geolen (LENGTH geometry) pp_geoindex 0)
    (IF geometry (SETQ fast (ARRAY geometry)))
    (FOREACH clline geometry
      (SETQ pp_geoindex (1+ pp_geoindex))
      (SETQ nextype (CAR (NTH (1+ pp_geoindex) fast)))
      (IF (OR (= nextype '$CUTOFF) (= nextype '$MARKOFF)) (SETQ $last T) (SETQ $last nil))
      (SETQ cmd (CAR clline))
      (SETQ $cmd cmd)
      (SETQ vars (CADR clline))
      ;(IF (= cmd '$STOP) (SETQ pp_partstopdata vars)) ; Usprunliga innan Resato
      (IF (AND (= cmd '$STOP) (> (LOGAND optype 8) 0)) (SETQ pp_partstopdata vars))
      ; ****** Handle drilling options ******
      (IF (> (LOGAND optype 1) 0)
        (PROGN
          (IF (= cmd '$HOLE) (SETQ $attrib (NTH 5 vars)))
          (COND
            ((AND (= cmd '$CUTON) (= (NTH 4 vars) 4) (NOT *DrillingTools*) (NOT pp_drillmsg)) ;ZOK
              (SETQ pp_drillmsg (WARNING "No drilling equipment. Using circular piercing")))
            ((AND (= cmd '$HOLE) (= (NTH 3 vars) 0) (NOT *DrillingTools*) (NOT pp_drillmsg)) ;ZOK
              (SETQ pp_drillmsg (WARNING "No drilling equipment. Using circular piercing")))
            ((AND (= cmd '$CUTON) (= (NTH 4 vars) 4) *DrillingTools*) ;ZOK
              (SETQ pp_dinit (NTH 29 vars))
              (SETQ pp_depth (DISTANCE (LIST 0.0 0.0 0.0) (NTH 20 vars)))
              ($DRILLING (LIST (NTH 15 vars) (NTH 16 vars) (NTH 17 vars) 0 "" pp_depth)))
            ((AND (= cmd '$HOLE) (= (NTH 3 vars) 0) *DrillingTools*) ; Vars= X,Y,TYPE,RADIE,ATTRIB ZOK
              ($DRILLING (LIST (NTH 0 vars) (NTH 1 vars) (NTH 2 vars) (NTH 4 vars) (NTH 5 vars) *Thickness*)))
          )
          (SETQ $attrib "")
        )
      )
      ; ****** Handle waterjet marking options ******
      (IF (> (LOGAND optype 2) 0)
        (PROGN
          (IF (= cmd '$HOLE) (SETQ $attrib (NTH 5 vars)))
          (COND
            ((AND (= cmd '$HOLE) (= (NTH 3 vars) 1)) ;ZOK
              (IF (NOT marking-flag) ($MARKING-BEGIN))
              ($MARKON (LIST (NTH 0 vars) (NTH 1 vars) (NTH 2 vars) $attrib 0 0 nil nil 0 0 (NTH 10 vars) T)) ;ZOK LAGT TILL Z NTH 2vars
              ($MARKOFF (LIST 0 0 0 0)))
            ((= cmd '$TEXT) ($TEXT vars))
            ((AND (= cmd '$MARKON) (NOT (NTH 6 vars)))
              (IF (NOT marking-flag) ($MARKING-BEGIN))
              (SETQ $attrib (NTH 3 vars))
              ($MARKON vars))
            ((AND (= cmd '$LINE) (> (LOGAND (NTH 3 vars) 4) 0)) ;ZOK
              ($LINE vars))  ; If the marking flag is On
            ((AND (= cmd '$ROTAX) (> (LOGAND (NTH 6 vars) 4) 0))
              ($ROTAX vars))
            ((AND (= cmd '$ARC) (> (LOGAND (NTH 6 vars) 4) 0)) ;ZOK
              ($ARC vars)) ; If the marking flag is On
            ((AND (= cmd '$MARKOFF) (NOT pp_specialmarking))
              ($MARKOFF vars))
            ((= cmd '$REFPOS)
              (IF (= (NTH 4 vars) 4) (SETQ pp_refposdata vars))) ; Use only if its marking
            ((AND (= cmd '$RAPID)) ; if this is rapid that belongs to marking
              (IF (AND (NTH 5 vars) (MEMBER (NTH 4 vars) (LIST 1 2))) ($RAPID3D vars))) ; IF 3D-5X then collect the list
          )
          (SETQ $attrib "")
        )
      )

      ; ****** Handle piercing options
      ; Om det är Holes med piercing så skall den utföras både om det är pre-piercing eller inte därför även under cutting. Tack
      (IF (AND (> (LOGAND optype 4) 0) pp_makeprepiercing)
        (PROGN
          (IF (= cmd '$HOLE) (SETQ $attrib (NTH 5 vars)))
          (IF (= cmd '$CUTON) (SETQ $maxslope (NTH 22 vars) $attrib (NTH 32 vars)))
          (COND
            ((AND (= cmd '$CUTON) (= (NTH 4 vars) 4) (NOT *DrillingTools*)) ; If its drilled and no drilling tools avaiable in Cuton ZOK
              ($PPIERCING (LIST (NTH 15 vars) (NTH 16 vars) (NTH 17 vars) 3 (NTH 20 vars) 0 (NTH 24 vars) (NTH 29 vars)))); OK
            ((AND (= cmd '$HOLE) (= (NTH 3 vars) 0) (NOT *DrillingTools*)) ; If its drilled and no drilling tools avaiable in Hole ZOK
              ($PPIERCING (LIST (NTH 0 vars) (NTH 1 vars) (NTH 2 vars) 3 (LIST 0 0 -1) 0 (LIST 0 0 -1) 0))) ;OK
            ((AND (= cmd '$CUTON) (= (NTH 4 vars) 2)) ; If Stationary piering in cuton
              ($PPIERCING (LIST (NTH 15 vars) (NTH 16 vars) (NTH 17 vars) 2 (NTH 20 vars) (NTH 21 vars) (NTH 24 vars) (NTH 29 vars)))) ;ZOK
            ((AND (= cmd '$CUTON) (= (NTH 4 vars) 3)) ; If Circular piercing in cuton
              ($PPIERCING (LIST (NTH 15 vars) (NTH 16 vars) (NTH 17 vars) 3 (NTH 20 vars) (NTH 21 vars) (NTH 24 vars) (NTH 29 vars)))) ;ZOK
            ((AND (= cmd '$HOLE)(= (NTH 3 vars) 2)) ;If Circular in hole
              ($PPIERCING (LIST (NTH 0 vars) (NTH 1 vars) (NTH 2 vars) 3 (LIST 0 0 (- *Thickness*)) 0 (LIST 0 0 -1) 0))) ;
            ((AND (= cmd '$HOLE)(= (NTH 3 vars) 4)) ;If Stationary hole
              ($PPIERCING (LIST (NTH 0 vars) (NTH 1 vars) (NTH 2 vars) 2 (LIST 0 0 (- *Thickness*)) 0 (LIST 0 0 -1) 0))) ;ZOK Not changed *** 6 args
            ((= cmd '$REFPOS) (SETQ pp_refposdata vars))
          )
          (SETQ $attrib "")
        )
      )
      ; ****** Handle cutting options ******
      (IF (> (LOGAND optype 8) 0)
        (PROGN
          (IF (= cmd '$HOLE) (SETQ $attrib (NTH 5 vars)))
          (COND
            ((= cmd '$CUTON) ($CUTON vars))
            ((= cmd '$QUALITY) ($QUALITY vars))
            ((AND (= cmd '$HOLE) (= (NTH 3 vars) 0) (NOT pp_makeprepiercing) (NOT *Drillingtools*)) ;ZOK
              (IF (NOT pp_drillmsg) (SETQ pp_drillmsg (WARNING "No drilling equipment. Using circular piercing")))
              ($PPIERCING (LIST (NTH 0 vars) (NTH 1 vars) (NTH 2 vars) 3 (LIST 0 0 -1) 0 (LIST 0 0 -1) 0))) ;OK
            ((AND (= cmd '$HOLE) (= (NTH 3 vars) 2) (NOT pp_makeprepiercing)) ;Circular piercing
              ($PPIERCING (LIST (NTH 0 vars) (NTH 1 vars) (NTH 2 vars) 3 (LIST 0 0 (- *Thickness*)) 0 (LIST 0 0 -1) 0))) ;ZOK (6 args)
            ((AND (= cmd '$HOLE) (= (NTH 3 vars) 3) (= *MachineType* 0)) ; If its AWJ-cutting ZOK
              ($HQCHAWJ (LIST (NTH 0 vars) (NTH 1 vars) (NTH 2 vars) (NTH 3 vars) (NTH 4 vars) (NTH 5 vars) (NTH 6 vars))))
            ((AND (= cmd '$HOLE) (= (NTH 3 vars) 4) (NOT pp_makeprepiercing)) ;Stationary piercing
              ($PPIERCING (LIST (NTH 0 vars) (NTH 1 vars) (NTH 2 vars) 2 (LIST 0 0 (- *Thickness*)) 0 (LIST 0 0 -1) 0))) ;ZOK (6 args)
            ((AND (= cmd '$HOLE) (= (NTH 3 vars) 3) (= *MachineType* 1)) ; If its Pure waterjet-cutting
              ($HQCHWATER (LIST (NTH 0 vars) (NTH 1 vars) (NTH 2 vars) (NTH 3 vars) (NTH 4 vars) (NTH 5 vars) (NTH 6 vars))))
            ((AND (= cmd '$HOLE) (= (NTH 3 vars) 3) (= *MachineType* 2)) ; If its PLASMA cutting ZOK
              ($HQCHPLASMA(LIST (NTH 0 vars) (NTH 1 vars) (NTH 2 vars) (NTH 3 vars) (NTH 4 vars) (NTH 5 vars) (NTH 6 vars))))
            ((AND (= cmd '$HOLE) (= (NTH 3 vars) 5))
              ($EXTSUB (NTH 0 vars) (NTH 1 vars) (NTH 2 vars) (NTH 3 vars) (NTH 4 vars) (NTH 5 vars) (NTH 6 vars)))

            ((AND (= cmd '$LINE) (NOT (MEMBER (NTH 3 vars) (LIST 4 128)))) ; If its not marking
              ($LINE vars))
            ((AND (= cmd '$ROTAX) (NOT (MEMBER (NTH 6 vars) (LIST 4))))
               ($ROTAX vars))
            ((AND (= cmd '$ARC) (NOT (MEMBER (NTH 6 vars) (LIST 4 128))))  ; If it's not marking ZOK
               ($ARC vars))
            ((= cmd '$CUTOFF)
              ($CUTOFF vars))
            ((AND (= cmd '$RAPID) (NOT (NTH 5 vars)))
              (SETQ pp_rapidnative 1)
              (IF (MEMBER (NTH 4 vars) (LIST 1 2)) ($RAPID3D vars) ($RAPID vars)) ; IF 3D-5X then collect the list
              (SETQ pp_rapidnative nil))
            ((= cmd '$5XSTOP)
              (SETQ pp_rapid3dlist nil pp_rapid3dupper nil)
              ($RAPID (LIST (CAR vars) (CADR vars) (CADDDR vars) nil 4 nil pp_cinit))
              (SETQ $reason 7)
              ($STOP (LIST (NTH 3 vars) (NTH 4 vars))))
            ((= cmd '$REFPOS) (SETQ pp_refposdata vars))
          )
          (SETQ $attrib "")
        )
      )
    )
    ;(SETQ pp_refposdata nil)
  )
  (IF pp_rapid3dlist (FOREACH s (REVERSE pp_rapid3dlist) ($RAPID s)))
  (SETQ pp_rapid3dlist nil)
)
(DEFUN extsub ()
  (ALERT "Subrutine")
)

(DEFUN $extsub (pp_x pp_y pp_z typ r attrib qua)
  (IF pp_tooldata ($TOOLSET pp_tooldata))
  (IF pp_partdata ($PART pp_partdata))
  (SETQ pp_pt (LIST pp_x pp_y pp_z)) ; Raw cordinate
  (SETQ pp_$pt (TRANS pp_x pp_y pp_z))
  (SETQ pp_$x (CAR pp_$pt) pp_$y (CADR pp_$pt) pp_zmaster pp_z)
  (SETQ $r r $attrib attrib)
  (DEFVARS)
  (EXTSUB)
)

(DEFUN sim-rotaxis (/ vektor)
  (SETQ vector
    (COND
      ((= *SixAxisDirection* 0) (LIST 1 0 0))
      ((= *SixAxisDirection* 1) (LIST 0 1 0))
      ((= *SixAxisDirection* 2) (LIST -1 0 0))
      ((= *SixAxisDirection* 3) (LIST 0 -1 0))
    )
  )
  (SIM3D-ROTAXIS *SixAxisOrigo* vektor)
)

(DEFUN $refpos (vars / pp_x pp_y pp_z pp_zmaster pp_vec $vector pp_$pt vars)
  (IF funis (WRITE "$REFPOS"))
  (SETQ pp_x (NTH 0 vars) pp_y (NTH 1 vars) pp_zmaster (NTH 2 vars) pp_vec (NTH 3 vars))
  (SETQ pp_$pt (TRANS pp_x pp_y pp_zmaster))
  (SETQ pp_$x (CAR pp_$pt) pp_$y (CADR pp_$pt) pp_$z (CADDR pp_$pt))
  (SETQ pp_$vec (TRANSVEC pp_vec))
  (SETQ $vector pp_$vec)
  (DEFVARS)
  (REFPOS)
)

(DEFUN precheck-rotations (geometry / skip clline cmd vars oldp pp_starttan pp_mintan pp_maxtan pp_vec pp_$vec pp_ab
                                      ccw endp cent endv strv incv vecdir veclen splits splitv vec)
  (COND
    ((NOT *HeadPrimaryAxisLimitations*) nil)
    ((= *Headtype* 0) nil)
    ((> *Headtype* 3) nil)
    (T
      (SETQ skip nil)
      (FOREACH clline geometry
        (SETQ cmd (CAR clline))
        (SETQ vars (CADR clline))
        (COND
          (skip nil)
          ((AND (= cmd '$MARKON) (NTH 6 vars)) (SETQ skip T)) ; If its special marking
          ((AND (= cmd '$MARKON) (NOT (NTH 7 vars))) (SETQ skip T))
          ((AND (= cmd '$MARKON) (= (NTH 9 vars) 0)) (SETQ skip T))
          ((AND (= cmd '$CUTON) (NOT (OR (> (LOGAND (NTH 21 vars) 2) 0) ; If it's not bevel cutting
                    (AND (> (LOGAND (NTH 21 vars) 64) 0) *MasterTAC*)))) (SETQ skip T))
          ((OR (= cmd '$CUTON) (= cmd '$MARKON))
             (SETQ pp_dobevel T)
             (IF (= cmd '$CUTON)
               (PROGN
                 (SETQ pp_maxslope (NTH 22 vars))
                 (IF (< *MasterHeadSecondaryPrefer* 2)
                   (PROGN
                      (IF (< pp_maxslope *MaxforbiddenTilt*)
                      (SETQ *HeadSecondaryPrefer* 2)
                      (SETQ *HeadSecondaryPrefer* *MasterHeadSecondaryPrefer*))))))

             (SETQ oldp (LIST (NTH 0 vars) (NTH 1 vars)))
             ;(SETQ pp_starttan (NTH 11 vars) pp_mintan (NTH 12 vars) pp_maxtan (NTH 13 vars))
             ;(SETQ pp_pathccw (IF (> (ABS (- pp_starttan pp_mintan)) (ABS (- pp_starttan pp_maxtan))) nil T))

             (SETQ pp_abinit T)
             (SETQ pp_precheck T)
             (SETQ pp_vec (IF (= cmd '$CUTON) (NTH 20 vars) (NTH 7 vars)))
             (SETQ pp_maxslope (IF (= cmd '$CUTON) (NTH 22 vars) (NTH 9 vars)))
             (SETQ pp_$vec (TRANSVEC pp_vec)) ; Rotate vector to same as part rotation
             (SETQ pp_ab (TILTDIR pp_$vec)) ; Calculate A and B angles
             (SETQ pp_astart (CAR pp_ab))
             (SETQ pp_amin (CAR pp_ab))
             (SETQ pp_amax (CAR pp_ab)))
          ((= cmd '$LINE) ; If it's cutting
            (SETQ oldp (LIST (NTH 0 vars) (NTH 1 vars)))
            (SETQ pp_vec (NTH 7 vars))
            (SETQ pp_$vec (TRANSVEC pp_vec))
            (SETQ pp_ab (TILTDIR pp_$vec))
            (IF (< (CAR pp_ab) pp_amin) (SETQ pp_amin (CAR pp_ab)))
            (IF (> (CAR pp_ab) pp_amax) (SETQ pp_amax (CAR pp_ab))))

          ((= cmd '$ARC)
            (SETQ pp_vec (NTH 10 vars))
            (SETQ pp_$vec (TRANSVEC pp_vec))
            (SETQ pp_ab (TILTDIR pp_$vec))
            (IF (< (CAR pp_ab) pp_amin) (SETQ pp_amin (CAR pp_ab)))
            (IF (> (CAR pp_ab) pp_amax) (SETQ pp_amax (CAR pp_ab))))
        )
      )
    )
  )
  (SETQ pp_precheck nil)
)

(DEFUN MAIN (/ $rfile txt)
  (IF fun (WRITE "MAIN"))
  (IF (AND $SendToCnc pp_autofilename) (SETQ pp_filename (STRCAT *OutputFolder* "current" *PPFileExtension*)))
  (IF (NOT (AND pp_autofilename pp_filename))
    (SETQ pp_filename (GETFILENAME "Save NC-file as"))
  )
  (IF pp_filename (SETQ $wfile (OPEN (SETQ $filename pp_filename) "w" $encoding)))
  (SSIM-SETUP)
  ($HEADER)
  ($TOOLUP 0)
  (SETQ $REASON 1 $MODE 0 $Z *ZMaxMovement* pp_lift *ZMaxMovement*)
  (BODY)
  (IF (AND (= *MachineType* 0) *SerialProduction* pp_serialpressure)
    (PROGN
      (IF (AND *bleedpoint* (NOT *AWJBleedOut*))
        ($RAPID (LIST (CAR *bleedpoint*) (CADR *bleedpoint*) *Thickness* nil 0 pp_cinit)))
      ($CHBARGRAM pp_serialpressure pp_serialgram)))
  (IF *AWJStopPumpAuto*
    (PROGN
      (SETQ $reason 9)
      (CHBARGRAM)))
  ($FOOTER)
  (IF pp_filename (CLOSE $wfile))
  (IF (AND pp_delfile pp_filename)
    (PROGN
      (FILE-DELETE pp_filename)
      (CLS)
      (SETQ pp_filename nil)))
  (IF pp_filename (FINAL))
  (IF pp_filename
    (PROGN
      (SETOUTFILE pp_filename)
      (PRINC (STRCAT "\nFile " (CHR 34) pp_filename (CHR 34) " created\n"))
      (COND
        ((AND *OutputMakeBackup* (SETQ $wfile (OPEN (STRCAT *OutputBackupFolder* (FILE-NAMEONLY pp_filename)) "w" $encoding)))
          (SETQ $rfile (OPEN pp_filename "r"))
          (WHILE
            (SETQ txt (READ-LINE $rfile))
            (WRITE-LINE txt $wfile)
          )
          (CLOSE $wfile)
          (CLOSE $rfile)
          (PRINC (STRCAT "File copied to "*OutputBackupFolder*)))
        (*OutputMakeBackup*
          (PRINC (STRCAT "*** Could not copy to " *OutputBackupFolder* " ***")))
      )
    )
  )
  ;(FINAL) **************************************FINAL Was Here before
  (SETQ *PreviousTooldist* nil)
  (SETQ *PreviousToolActive* 0)

)
(DEFUN final () nil)

(DEFUN $header (/ $time)
  (FUNBROWSER "$HEADER")
  (SETQ $igems *IGEMSVersion*)
  ;(SETQ $post (FILE-NAMEONLY *PPName* T)) ; This is now in fixvars
  (SETQ $abs T)
  (SETQ $alloy *QualityName*)
  (SETQ $cutparname *CutPar*)
  (SETQ $date *Date*)
  (SETQ $digfile *Digfile*)
  (SETQ $group (IF *UseAlias* *Alias* *Name*))
  (SETQ $density *Density*)
  (SETQ $machine *MachineName*)
  (SETQ $type *MachineType*)
  (SETQ $machinetype *MachineType*)
  (SETQ $thickness *Thickness*)
  (SETQ $matgroup *Name*)
  (SETQ $time *Time*)
  (SETQ $metric (NOT pp_inchout))
  (SETQ $speedrapid *SpeedRapid*)
  (SETQ $speedmarking *MarkingSpeed*)
  (SETQ $speedmode *SpeedMode*)
  (SETQ $name (IF pp_filename (FILE-NAMEONLY pp_filename) ""))
  (SETQ $maxspeed *Maxfeed*)
  (SETQ $maxbar *AWJMaxPumpPressure*)
  (SETQ $minspeed *Minfeed*)
  (SETQ $minbar *AWJMinPumpPressure*)
  (SETQ $sheetx *Sheetx* $sheety *Sheety*)
  (SETQ $sheetname *SheetName*)
  (SETQ $xrough 0 $rough 0 $medium 0 $fine 0 $xfine 0)
  (SETQ $cando5x (IF (> *HeadType* 0) T nil))

  (SETQ $cando6x *HasSixAxis*)
  (SETQ $uses6x *UseSixAxis*)
  (SETQ $6x-direction *SixAxisDirection*) ; 0=100, 1=0-10, 2=-100, 3=010
  (SETQ $6x-reverse *SixAxisReverseRotation*)
  (SETQ $6x-origo *SixAxisOrigo*) ; 3D point of position in 3D-5X
  (SETQ pp_$c 0)

  (SETQ $drillrpm *DrillingRotationSpeed*)
  (SETQ $drillspeed *DrillingSpeed*) ; This should be removed after fixing this in STM postprocessor.
  (SETQ $drillfeed *DrillingSpeed*)
  (SETQ $drillstep *Drillingstep*)
  (SETQ $drillfeed *DrillingSpeed*)
  (SETQ $drillbytype *DrillByType*)
  (SETQ $drillupz *DrillLiftHeight*)
  (SETQ $markupz *MarkingLiftHeight*)
  (SETQ $markbytype *MarkingByType*)
  (SETQ $piercebytype *PiercingByType*)
  (SETQ $piercupz *PiercingLiftHeight*)
  (SETQ $cuttingupz *CuttingLiftHeight*)
  (SETQ $partupz *CuttingLiftHeightParts*)
  (SETQ $maxupz (ZDEF *ZMaxMovement*))
  (SETQ pp_zmaster *ZMaxMovement*)
  (IF (> $drillupz $maxupz) (SETQ $drillupz $maxupz))
  (IF (> $markupz $maxupz) (SETQ $markupz $maxupz))
  (IF (> $piercupz $maxupz) (SETQ $piercupz $maxupz))
  (IF (> $cuttingupz $maxupz) (SETQ $cuttingupz $maxupz))
  (IF (> $partupz $maxupz) (SETQ $partupz $maxupz))

  (COND
    ((= *MachineType* 0) ; AWJ cutting
      (SETQ $abrasive *AWJAbrasiveQuality*)
      (SETQ $cutflow (IF *AWJCuttingAbrasiveFlowByMachine* *AWJAbrasiveFlow* *AWJCuttingAbrasiveFlow*))
      (SETQ $abrasiveflow $cutflow) ; just to be compatible can be removed july 2012
      (SETQ $markflow (IF *AWJMarkingUseAbrasive* *AWJMarkingAbrasiveFlow* 0))
      (SETQ $piercflow (IF *AWJPiercingAbrasiveFlowByMachine* $cutflow *AWJPiercingAbrasiveFlow*))
      (SETQ $orifice *AWJOrifice*)
      (SETQ $tube *AWJMixingTube*)
      (SETQ $markbar *MarkingPressure*)
      (SETQ $piercbar *Piercingpressure*)
      (SETQ $cutbar *Cuttingpressure*)
      (SETQ $highbar (MAX $cutbar $piercbar $markbar))
      (SETQ $lowbar (MIN $cutbar $piercbar $markbar))
      (SETQ $highflow (MAX $cutflow $markflow $piercflow))
      (SETQ $lowflow (MIN $cutflow $markflow $piercflow))
      (SETQ $machinability *Machinability*)
      (SETQ $pstat *AWJStationaryPiercing*)
      (SETQ $cpfeed *AWJCircularPiercingSpeed*)
      (SETQ $cpradius (* *AWJCircularPiercingDiameter* 0.5))
      (SETQ $cpturns (CEIL (/ (* (/ *AWJCircularPiercingSpeed* 60.0) (CEIL *AWJCircularPiercing*)) (* *AWJCircularPiercingDiameter* PI))))
      (SETQ $cptime *AWJCircularPiercing*)
      (SETQ $xrough (CALCAWJFEED 1 *Thickness*))
      (SETQ $rough (CALCAWJFEED 2 *Thickness*))
      (SETQ $medium (CALCAWJFEED 3 *Thickness*))
      (SETQ $fine (CALCAWJFEED 4 *Thickness*))
      (SETQ $xfine (CALCAWJFEED 5 *Thickness*))
      (SETQ $xroughlow (AWJPAR 1 1))
      (SETQ $roughlow (AWJPAR 2 1))
      (SETQ $mediumlow (AWJPAR 3 1))
      (SETQ $finelow (AWJPAR 4 1))
      (SETQ $xfinelow (AWJPAR 4 1))
      (SETQ $f *AWJFixedSpeed*)
      (SETQ $fe $f $fs $f))
    ((= *MachineType* 1) ; Pure water cutting
      (SETQ $abrasive "")
      (SETQ $orifice *ToolDiameter*)
      (SETQ $tube *ToolDiameter*)
      (SETQ $cutflow 0 $markflow 0 $piercflow 0)
      (SETQ $abrasiveflow $cutflow) ; just to be compatible can be removed july 2012
      (SETQ $cutbar *WaterPressure*)
      (SETQ $markbar *WaterPressure*)
      (SETQ $piercbar *WaterPressure*)
      (SETQ $highbar *WaterPressure*)
      (SETQ $lowbar *WaterPressure*)
      (SETQ $bar *WaterPressure*)
      (SETQ $pstat *WaterPiercingTime*)
      (SETQ $cpfeed 0)
      (SETQ $f *WaterCuttingSpeed*)
      (SETQ $fe $f $fs $f))
  )
  (SETQ $zmode pp_zmode)
  (COND
    ((> *Machinetype* 1) ; changed 2012-09-27
      (SETQ $sensormode -1  $sensordist 0 $sensorsec 0))
    ((= *ZAxisOption* 2) ; When the Sensor is selected in the Strategy command.
      (SETQ $sensormode *ZSensoringmode*)
      (SETQ $sensordist 0 $sensorsec 0)
      (IF (AND (= *Zsensoringmode* 3) (> *ZSensoringDistance* 0)); Type odf mode selected in stratey
        (PROGN
          (IF (OR (NOT $medium) (= $medium 0)) (SETQ $medium *MinFeed*))
          (SETQ $sensorsec (/ *ZSensoringDistance* (/ $medium 60)))
          (SETQ $sensordist *ZSensoringDistance*))
      ))
    (T
      (SETQ $sensormode -1  $sensordist 0 $sensorsec 0))
  )
  (IF (= $sensormode 0) (SETQ $initsheetwice T))
  (SETQ $box *PartsBox*)
  (SETQ $z *CuttingLiftHeightParts*)
  (COND
    ((= *InternalToolCompensation* 2) (SETQ $kerfsize (* *Tooldiameter* 0.5)))
    ((= *InternalToolCompensation* 1) (SETQ $kerfsize (* *AWJAdditionalkerf* 0.5)))
    (T (SETQ $kerfsize 0))
  )
  ;(SETQ $kerfsize (IF (= *InternalToolCompensation* 2) (* *ToolDiameter* 0.5) 0.0))
  (IF (MEMBER $zmode (LIST 1 2 4 5))
    (SETQ pp_zmaster (+ *Thickness* *ZAutoDist*)))
  (IF (NOT *TubeMode*) (HEADER))
)


(DEFUN header () nil)

(DEFUN $footer ( / mrapid)
  (SETQ pp_basex p_basex pp_basey p_basey pp_rotate p_rotate)
  (FOREACH s (REVERSE pp_rapid3dlist)
    ($RAPID s)
  )
  (IF (AND (> *HeadType* 0) (NOT *HeadStraight*) pp_headistilt)
    (PROGN
      (SIM3D-TILT 0 0 $a $b)
      ($TILT 0 0 4)))
  (IF (NOT $datefirst) (SETQ $datefirst ""))
  (IF *DangerZoneUse* (SETQ $dangerzone (LIST pp_xdmin pp_ydmin pp_xdmax pp_ydmax)))
  (SETQ $x *ParkPosX* $y *ParkposY* $reason 2)
  (IF (NOT *GotoParkPos*) (DEFUN mrapid () nil))
  (SETQ $runsec (* (SIM-RUNTIME) 0.001))
  (SETQ $runtime (SecToTime $runsec))
  (SETQ $cutlen (SIM-CUTLENGTH))
  (SETQ $lines wline)

  (FOOTER)
  (IF (AND (> *Maxslope* (+ *HeadMaxTilt* 0.0002)) (> *Headmaxtilt* 0.01))
    (PROGN
      (BEEP)
      (SETQ pp_delfile (GP-YESNO (STRCAT "Maximal cutting angle " (ANGTOS *HeadMaxTilt* 2) " exceed by " (ANGTOS (ANGDIFF *HeadMaxTilt* *Maxslope*) 3) "\nDelete file?") T)))
  )
)

(DEFUN secToTime (sec / hour tot minute)
  (SETQ tot sec)
  (SETQ hour (FIX (/ tot 3600)))
  (SETQ tot (- tot (* hour 3600)))
  (SETQ minute (FIX (/ tot 60)))
  (SETQ tot (- tot (* minute 60)))
  (SETQ hour (ITOA hour) minute (ITOA minute) tot (ITOA tot))
  (IF (< (STRLEN hour) 2) (SETQ hour (STRCAT "0" hour)))
  (IF (< (STRLEN minute) 2) (SETQ minute (STRCAT "0" minute)))
  (IF (< (STRLEN tot) 2) (SETQ tot (STRCAT "0" tot)))
  (STRCAT hour ":" minute ":" tot)
)

(DEFUN footer() nil)
(DEFUN mrapid () nil)


(DEFUN ChkIfPiercing (/ show) ; This function check machine and material parameters if Prepiering should be used or not
  (SETQ show nil)
  (SETQ res
    (COND
      ((AND *Piercingalways* (> *HeadType* 0) (= *MachineType* 0)) T)
      ((/= *MachineType* 0) nil)
      ((AND *AWJPiercingPressureByMachine* *AWJPiercingPressureByMachine*)
        (IF show (PRINC "\nPrepiering should NOT be used")) nil)
      ((AND (= *AWJPiercingAbrasiveFlow* *AWJAbrasiveFlow*)
            (= *AWJPiercingPressure* *AWJPressure*))
         (IF show (PRINC "\nPrepiering should NOT be used")) nil)
      (T
        (IF show (PRINC "\nPrepiercing should be used\n"))  T)
    )
  )
  (IF (AND res (= *PiercingByType* 3)) (SETQ pp_lowhigh T)) ;För att hantera lågtryckspiercing utan optimering; Res was nil
  (EVAL res)
)


(DEFUN $measure (pp_x pp_y zref) ;ZOK HAR INTE ÄNDRAT NÅGOT I DENNA FUNKTION
  ;(SETQ pp_measuredata nil)
  (IF drilling-flag ($DRILLING-END))
  (IF marking-flag ($MARKING-END))
  (IF ppiercing-flag ($PPIERCING-END))
  (IF cutting-flag ($CUTTING-END))
  (IF (NOT measure-flag) ($MEASURE-BEGIN))
  (SETQ pp_$pt (LIST pp_x pp_y)) ; The points are already transed
  (SETQ pp_$x (CAR pp_$pt)  pp_$y (CADR pp_$pt))
  (SSIM-RAPID pp_$x pp_$y *Thickness*  *SpeedRapid* *SpeedAcceleration* 0)
  (SIM-MEASURE)
  (DEFVARS)
  (SETQ $zref zref)
  (MEASURE)
  (SETQ pp_oldp (LIST pp_x pp_y))
)

(DEFUN measure ()
  nil
)

(DEFUN $measure-begin ()
  (FUNBROWSER "MEASURE-BEGIN")
  (SETQ pp_mode 0)
  ($CHMODE)
  (SETQ pp_xmodsim *ZMeasureXOffset* pp_ymodsim *ZMeasureYOffset*)
  (IF (NOT *MeasureOffsetbyController*)
    (SETQ pp_xmod *ZMeasureXOffset* pp_ymod *ZMeasureYOffset*)
    (SETQ pp_xmod 0.0 pp_ymod 0.0)
  )
  (IF (NOT pp_toolused) (SSIM-TOOLSET 1 (LIST 300 300 300 300 300 300 300) 2000))
  (SETQ pp_toolused 1)
  (SETQ measure-flag 1)
)

(DEFUN $part (vars / pp_partname pp_customer pp_date $quantity $connected $partid $box p1 p2 p3 p4 d dd)
  (IF fun (WRITE "$PART"))
  (SETQ pp_partname (NTH 0 vars) pp_customer (NTH 1 vars) pp_date (NTH 2 vars)) ; pp_sortid is from the Call
  (IF (SETQ d (DATETOSTR pp_date)) ; str
    (PROGN
      (SETQ dint (ATOI d))
      (IF (< dint pp_datefirst) (SETQ pp_datefirst dint $datefirst d))) )
  (SETQ pp_oldpartdata pp_partdata)
  (SETQ pp_partdata nil)
  (SETQ $quantity (NTH 3 vars) $connected (NOT (NTH 4 vars)) $partid (NTH 5 vars) $box (NTH 6 vars))
  (SETQ p1 (TRANS (CAR $box) (CADR $box) 0) p2 (TRANS (CADDR $box) (CADDDR $box) 0)); P1=Lower left, P2=Upper right
  (SETQ p3 (TRANS (CAR $box) (CADDDR $box) 0) p4 (TRANS (CADDR $box) (CADR $box) 0)) ; P3=Upper left, P4=Lower right
  (SETQ $boxcenter (LIST (* (+ (CAR p1) (CAR p2)) 0.5) (* (+ (CADR p1) (CADR p2)) 0.5)))
  (SETQ $boxrotated (LIST (MIN (CAR p1) (CAR p2) (CAR p3) (CAR p4)) (MIN (CADR p1) (CADR p2) (CADR p3) (CADR p4))
                          (MAX (CAR p1) (CAR p2) (CAR p3) (CAR p4)) (MAX (CADR p1) (CADR p2) (CADR p3) (CADR p4))))
  (SETQ $sortid pp_sortid)
  (SIM-PARTID pp_sortid)
  (SETQ $partname pp_partname $customer pp_customer $partdate pp_date)
  (IF (= $sensormode 1) (SETQ $initpartwice T))
  (PART)
;  (SETQ pp_basex $basex pp_basey $basey pp_rotate $rotate)
)
(DEFUN part ()
  nil
)

(DEFUN $carc (x y r ccw feed / endp hcorda acorda mpcorda height cent)
  (SETQ endp (LIST (+ (CAR pp_oldp) x) (+ (CADR pp_oldp) y)))
  (SETQ hcorda (* (DISTANCE pp_oldp endp) 0.5)) ; half lenght of corda
  (SETQ acorda (ANGLE pp_oldp endp)) ; angle of corda
  (SETQ mpcorda (POLAR pp_oldp acorda hcorda)) ; midpoint of corda
  (SETQ height (SQRT (- (* r r) (ABS (* hcorda hcorda)))))
  (SETQ cent (POLAR mpcorda (IF ccw (+ acorda PIH) (- acorda PIH)) height))
  ;(SETQ pp_skipsim T)
  ($ARC (LIST (CAR endp) (CADR endp) pp_z (CAR cent) (CADR cent) T 64 feed feed 0 pp_vec pp_cutdirection))
  ; pp_endp is updated in the $ARC function
  ;(SETQ pp_skipsim nil)
)

(DEFUN $cline (x y feed / tmpp saveskip $ab) ; Har lagt dit Z
  (SETQ tmpp (LIST (+ (CAR pp_oldp) x) (+ (CADR pp_oldp) y)))
  (SETQ saveskip pp_skipsim)
  (SETQ pp_skipsim T)
  ($LINE (LIST (CAR tmpp) (CADR tmpp) pp_z 64 feed feed)) ;ZOK Har lagt dit Z
  (SETQ pp_skipsim saveskip)
)

(DEFUN $ccircle (i j feed / home cent endp r v $ab) ;ZOK Har lagt dit Z
  (SETQ home pp_oldp)
  (SETQ cent (LIST (+ (CAR home) i) (+ (CADR home) j)))
  (SETQ r (DISTANCE home cent))
  (SETQ v (ANGLE cent home))
  ;(SETQ endp (POLAR cent (+ v 3.31) r))
  (SETQ endp (LIST (+ (CAR cent) i) (+ (CADR cent) j)))
  (SETQ pp_skipsim T)
  ($ARC (LIST (CAR endp) (CADR endp) pp_z (CAR cent) (CADR cent) T 64 feed feed 0 pp_vec pp_cutdirection)) ;ZOK
  ($ARC (LIST (CAR home) (CADR home) pp_z (CAR cent) (CADR cent) T 64 feed feed 0 pp_vec pp_cutdirection)) ;ZOK
  (SETQ pp_skipsim nil)
)

(DEFUN $rotax (vars / a pp_fe)
  (SETQ pp_vec (NTH 0 vars)) ; The vector
  (SETQ pp_ft (NTH 1 vars)) ; Only tube rotation: This means time for movements in minutes. Only AB moves ere means time for movement in seconds
  (SETQ pp_vectordir (NTH 2 vars))
  (SETQ pp_$c (NTH 3 vars))
  (SETQ pp_fe (NTH 4 vars))
  (SETQ pp_len (NTH 5 vars))
  (SETQ $len pp_len)
  (SETQ pp_fs pp_fe)
  (IF (NOT pp_$c) (SETQ pp_$c 0))
  (IF (NOT pp_$cold) (SETQ pp_$cold pp_$c))
  (SETQ pp_$crel (- pp_$cold pp_$c))
  (SETQ pp_$cold pp_$c)
  (SETQ pp_$newp pp_$oldp)
  (SETQ gtype 1)
  (SETQ $ft pp_ft)
  (IF (< $ft 0.00000001) (SETQ $ft 0.00000001))
  (SETQ pp_$vec (TRANSVEC pp_vec)) ; Rotate vector to same as part rotation
  (SETQ pp_ab (TILTDIR pp_$vec)) ; Calculate A and B angles
  (DEFVARS)
  (SSIM-LINE (CAR pp_$newp) (CADR pp_$newp) $fs $fe pp_$c pp_len) ;Xmod and Ymod is for the marking offset
  (ROTAX)
  (SETQ pp_aold (CAR pp_ab) pp_bold (CADR pp_ab))
  (SETQ pp_$oldvec pp_$vec)
  (SETQ pp_abold pp_ab)
)

(DEFUN rotax ()
  (IF (NOT rotaxwarning) (SETQ rotaxwarning (ALERT "Warning!\nNo ROTAX function defined")))
)

(DEFUN $line (vars / pp_x pp_y pp_z pp_flag pp_fs pp_fe pp_pt pp_$pt len loops increment linelen linedir loops pt
                     pp_vec xmod ymod longestline movetop movebottom gtype pp_vectordir)
  (IF funis (WRITE (STRCAT "$LINE:" (TOSTR (NTH 2 vars)))))
  (SETQ pp_x (NTH 0 vars) pp_y (NTH 1 vars) pp_zmaster (NTH 2 vars) pp_flag (NTH 3 vars) pp_fs (NTH 4 vars) pp_fe (NTH 5 vars)) ;ZOK
  (SETQ pp_delta (NTH 6 vars) pp_vec (NTH 7 vars) pp_cutdirection (NTH 8 vars) pp_vectordir (NTH 9 vars)) ;ZOK
  (IF (NTH 10 vars) (SETQ pp_crot (NTH 10 vars)))
  (IF (NOT qline) (SETQ qline 0))
  ;(IF (< qline 5) (PROGN (SETQ qline (1+ qline)) (ALERT (STRCAT "LINE:" (TOSTR pp_zmaster)))))
  ;(IF (> pp_flag 0) (WRITE (STRCAT "\nFLAG:" (TOSTR pp_flag))))
  (SETQ pp_$c pp_crot)
  (IF (NOT pp_$cold) (SETQ pp_$cold pp_$c))
  (SETQ pp_$crel (- pp_$cold pp_$c))
  (SETQ pp_$cold pp_$c)
  (SETQ pp_len (NTH 11 vars)) ; If this is nil then I calculate distance from last point some lines down.
  (SETQ braattha pp_vectordir)
  (IF (NOT pp_cutdirection) (SETQ pp_cutdirection 0))
  (IF (NOT pp_vectordir) (SETQ pp_vectordir 0))
  (IF (NOT pp_oldvectordir) (SETQ pp_oldvectordir pp_vectordir))
  (SETQ ispiercing (IF (OR (> (LOGAND pp_flag 8) 0) (> (LOGAND pp_flag 64) 0)) T nil))
  (SETQ gtype 1) ;behövs för Software RTCP
  ; Set up different speeds
;  (IF (AND (= pp_fs 0) (= pp_fe 0) (= *Machinetype* 2)) (SETQ pp_fs *PlasmaLeadinSpeed* pp_fe *PlasmaLeadinSpeed*))
  ; Set up variables
  (SETQ pp_pt (LIST pp_x pp_y pp_zmaster)) ; Raw cordinate
  (SETQ pp_$pt (TRANS pp_x pp_y pp_zmaster)) ; Transed cordinate
  ;(IF (NOT (CAR pp_$oldp)) (SETQ pp_$oldp (LIST 0 0 0)))
  ;(IF (NOT (CAR pp_$oldp)) (ALERT (TOSTR pp_$oldp)))

  (SETQ pp_$newdir (ANGLE pp_$oldp pp_$pt)) ;-------------------------------------
  (IF (NOT pp_$olddir) (SETQ pp_$olddir pp_$newdir))
  ; Handle loops and headminangle
  (IF (AND (OR pp_dobevel *TAC* *LAG* pp_bevelmarking) pp_vec $ab)
    (PROGN
      (SETQ $slope (ATAN (DISTANCE (LIST 0 0) pp_vec) (ABS (CADDR pp_vec))))
      (SETQ pp_realslope $slope)
      ;(WRITE (STRCAT "$SLOPE:" (ATS $slope)))
      (IF (NOT (= pp_flag 2)) ;not leadout
        (PROGN
          (COND
            ((> *Headtype* 2) ; If it's not a C-axis head
              (SETQ pp_$vec (TRANSVEC pp_vec)))
            ; ((OR (>= $slope *HeadMinTilt*) (> (ABS (ANGDIFF pp_vectordir pp_oldvectordir)) 1.22173)) ; 70 grader
            ((>= $slope *HeadMinTilt*)
              (SETQ pp_$vec (TRANSVEC pp_vec))
              (SETQ pp_vertical nil)
              (SETQ pp_firstvertical nil))
            ((< $slope *HeadMinTilt*)
              (SETQ newveclen (* (TAN *HeadMinTilt*) (ABS (CADDR pp_vec))))
              ;(PRINC (STRCAT "NEWVECLEN:" (TOSTR newveclen) " PP_VECTORDIR:" (ANGTOS pp_vectordir 3) "\n"))
              (SETQ pp_tmpvec (POLAR (LIST 0.0 0.0) pp_vectordir newveclen))
              (SETQ pp_tmpvec (LIST (CAR pp_tmpvec) (CADR pp_tmpvec) (CADDR pp_vec)))
              (SETQ pp_$vec (TRANSVEC pp_tmpvec))
              (SETQ pp_vertical T)
              (SETQ pp_firstvertical T))
          )
          (SETQ pp_ab (TILTDIR pp_$vec))))))

  ; Set up standard variables
  (IF (AND *RTCPUse* (= *Headtype* 4) pp_$vec (NOT ispiercing))
    (PROGN
      (SETQ mod (ICOMP pp_$vec))
      (SETQ pp_$pt (LIST (- (CAR pp_$pt) (CAR mod)) (- (CADR pp_$pt) (CADR mod)) (CADDR pp_$pt)))))
  (IF pp_len
    (SETQ $len pp_len)
    (SETQ $len (DISTANCE pp_$oldp pp_$pt)) ; The lenght of the line
  )
  (SETQ pp_$unkerf (POLAR pp_$pt (ANGLE pp_$oldp pp_$pt) 10))
  (SETQ pp_$x (CAR pp_$pt) pp_$y (CADR pp_$pt))
  (DEFVARS)
  (SETQ $ft (/ $len $fe))
  (TANKSAFE pp_$x pp_$y pp_$vec)
  (IF (= *InternalToolCompensation* 0) (SETQ $kerf 0))
  (IF (= pp_flag 1)  (SETQ $chkerf T))
  (IF (= pp_flag 32) (SETQ $chkerf T $kerf 0))
  ($FMODE $fs $fe)
  (IF (NOT pp_skipsim) (SSIM-LINE pp_$x pp_$y $fs $fe pp_crot $len)) ;Xmod and Ymod is for the marking offset PP_SKIPSIM for CLINE AND CARC
  (IF (NOT pp_skipout)
    (PROGN
      (SETQ $zrel (- (- pp_$zold (SETQ pp_$zold $z))))
      (SETQ aspar $a bspar $b)
      (IF sprewind
      ;(IF (AND sprewind (> *HeadSecondaryPrefer* -1))
        (PROGN
          (SETQ $b *HeadMinTilt*)
          (SIM-OFF)
          (IF (= *Processmode* 4) (SIM-INFOTEXT ""))
          ;(SIM3D-TILT $a (ABS $b) 0.5)
          (REWIND)
          (SIM-ON T pp_fe)
          (IF (= *Processmode* 4) (SIM-INFOTEXT ""))
          (SETQ $b bspar)
          (IF (= *SpeedMode* 3) (SETQ $fe (* $fe 0.25)))
          (SETQ sprewind nil)
          (IF pp_ab (SETQ pp_aold (CAR pp_ab) pp_bold (CADR pp_ab)))
          (DEFVARS)))
      (LINE))) ; PP_SKIPOUT for CIRC-PIERCING in *CustomcircularPiercing* mode
  (IF pp_ab (SETQ pp_aold (CAR pp_ab) pp_bold (CADR pp_ab)))
  (SETQ pp_oldp pp_pt)
  (SETQ pp_$oldp (LIST pp_$x pp_$y pp_zmaster))
  (SETQ pp_$oldvec pp_$vec)
  (SETQ pp_$olddir pp_$newdir)
  (SETQ pp_oldvectordir pp_vectordir)
  (SETQ $chkerf nil)
)

(DEFUN refpos () nil)

(DEFUN line()
  (WRITE (STRCAT (NTXT) "G01 X" (RTS $x) " Y" (RTS $y) " F" (RTF $fe)))
)

(DEFUN rapid ()
  (WRITE (STRCAT (NTXT) "G00 X" (RTS $x) " Y" (RTS $y)))
)

(DEFUN arc ()
  (WRITE (STRCAT (NTXT) (IF $ccw "G03" "G02") " X" (RTS $x) " Y" (RTS $y) " I" (RTS $i) " J" (RTS $j) " F" (RTF $fe)))
)

;(DEFUN *error* (s)
;  (PRINC "*Cancel*")
;)

(DEFUN $toolset (vars / q value distmsg activemsg tnr bnr tmpoffset s show first)
  (FUNBROWSER (STRCAT "$TOOLSET:" (TOSTR vars)))
  (SETQ $chactive nil $chdist nil)
  (SETQ $tooldata vars)
  (SETQ pp_toolused (NTH 0 vars) pp_tooldist (NTH 1 vars) pp_drawalign (NTH 3 vars)) ; pp_drawalign is the alignment on the drawing
  ;(ALERT (STRCAT "VARS:" (TOSTR vars)))
  (IF (= *ProcessMode* 4) (SETQ pp_toolused 1))
  (IF (NOT pp_tooldist) (SETQ pp_tooldist 0))
  (IF (= pp_tooldist 0) (SETQ pp_tooldist *ToolFixDistance*))
  (SETQ pp_toollist nil)
  (SETQ pp_msg "I")
  ; Below it's a packing routine that put the outside tools as closed as possible
  (SETQ tnr 1) ; Used as Tool number
  (SETQ bnr 1) ; Used as Bit number
  (SETQ tmpoffset 0)
  (SETQ pp_offset nil)
  (WHILE (<= tnr 12)
    (IF (>= *ToolQuantity* tnr) ; Check if more tools should be added
      (IF (> (LOGAND pp_toolused bnr) 0)
        (PROGN ; Tool should be used
          ;(PRINC (STRCAT "\nTool nr " (ITOA tnr) " bit " (ITOA bnr) " should be used"))
          (IF (NOT activemsg) (SETQ activemsg (STRCAT "TOOL:" (ITOA tnr))) (SETQ activemsg (STRCAT activemsg "+" (ITOA tnr))))
          (IF (NOT pp_offset)
            (PROGN
              (SETQ pp_offset tmpoffset)
              (IF (> tnr 1) (SETQ pp_toollist (CONS (IF *ToolClosestDistance* *ToolMinDistance* pp_tooldist) pp_toollist))))
            (PROGN
              (IF (> tnr 1)(SETQ pp_toollist (CONS pp_tooldist pp_toollist))))))

        (PROGN ; Tool should not be used
          ;(PRINC (STRCAT "\nTool nr " (ITOA tnr) " bit " (ITOA bnr) " should NOT be used"))
          (IF pp_offset ; if a lower tool are in use
            (IF (AND (> bnr pp_toolused) *Toolclosestdistance*)
              (IF (> tnr 1) (SETQ pp_toollist (CONS *ToolMinDistance* pp_toollist)))
              (IF (> tnr 1) (SETQ pp_toollist (CONS (MAX pp_tooldist *ToolMinDistance*) pp_toollist))) ; ändrad 2013-07-30
            )
            (PROGN
              (IF (> tnr 1) (SETQ pp_toollist (CONS (IF *ToolClosestDistance* *ToolMinDistance* pp_tooldist) pp_toollist)))
              (SETQ tmpoffset (+ tmpoffset (IF *ToolClosestDistance* *ToolMinDistance* pp_tooldist))))))
       )
    )
    (SETQ tnr (1+ tnr))
    (SETQ bnr (* bnr 2))
  )
  (SETQ distmsg "I")
  (IF pp_toollist (SETQ pp_toollist (REVERSE pp_toollist)))
  (FOREACH s pp_toollist (SETQ distmsg (STRCAT distmsg "-" (RTS s) "-I")))
  (SETQ pp_oldtooldata pp_tooldata)
  (SETQ pp_tooldata nil)
  (SETQ $f *ToolMovingSpeed*)
  (IF (NOT (EQUAL pp_toollist *PreviousTooldist* 0.1))
    (PROGN
      (SETQ $chdist T)
      (SETQ *PreviousTooldist* pp_toollist)
    )
  )
  (IF (/= pp_toolused *PreviousToolActive*)
    (PROGN
      (SETQ $tool pp_toolused)
      (SETQ $chactive T)
      (SETQ *PreviousToolActive* pp_toolused)
    )
  )
  (IF (NOT pp_toollist) (SETQ pp_toollist (LIST 0)))
  (COND
    ((= *Baraligned* 0) (SETQ pp_xoffset (- pp_offset) pp_yoffset 0.0))
    ((= *Baraligned* 1) (SETQ pp_xoffset pp_offset pp_yoffset 0.0))
    ((= *Baraligned* 2) (SETQ pp_xoffset 0 pp_yoffset (- pp_offset)))
    ((= *Baraligned* 3) (SETQ pp_xoffset 0 pp_yoffset pp_offset))
  )
  (FUNBROWSER (STRCAT "$TOOLSET EXTRA INFO PP_XOFFSET:" (RTS pp_xoffset) " PP_YOFFSET:" (RTS pp_yoffset)))
  (SETQ pp_xoffsetsim (- pp_xoffset) pp_yoffsetsim (- pp_yoffset))
  (SETQ pp_xoffsetsim 0 pp_yoffsetsim 0)
  (IF (NOT *CoordinateToFirstTool*) (SETQ pp_xoffset 0 pp_yoffset 0))
  (SETQ $offset pp_offset)
  (SETQ pp_offset 0)
  (IF (OR $chactive $chdist) ($CHTOOL pp_toollist pp_toolused))
)


(DEFUN $chtool (dist active / activemsg distmsg pp_x pp_y pp_$pt pp_$x pp_$y
                $mindist $maxdist $maxtools $feed $parking $pack $toollist $tooldist
                $distctrl $activectrl $chdist $chactive $index $skip $reason
                $msg $msgdist $msgactive) ; NOTE $tools must be global, can be used from CUTON and CUTOFF
  (FUNBROWSER (STRCAT "$CHTOOL ACTIVE:" (TOSTR active) " DISTANCE:" (TOSTR dist)))
  (IF (> pp_toolindex 0) (SETQ pp_zmaster *ZMaxMovement*))
  (IF (NOT pp_x) (SETQ pp_x 0.0 pp_y 0.0))
  (SETQ pp_$pt (TRANS pp_x pp_y pp_z))
  (SETQ pp_$x (CAR pp_$pt) pp_$y (CADR pp_$pt))
  (DEFVARS)
  (SETQ $feed *ToolMovingSpeed*)
  (SETQ $parking *ToolPark*)
  (SETQ $pack *ToolClosestDistance*)
  (SETQ $toollist dist)
  (SETQ $tooldist pp_tooldist)
  (IF (AND $pack (MEMBER active (LIST 1 2 4 8 16 32 64 128 256 512 1024 2048))) (SETQ $tooldist *ToolMinDistance*))


  (SETQ $distances dist) ; To be compatibel with some temporary postprocessors, can be removed later
  (SETQ $tools active)

  (SETQ $distctrl *ToolDistanceByController*)
  (SETQ $activectrl *ToolActiveByController*)
  (IF (OR $chdist $chactive)
    (PROGN
      (SSIM-TOOLSET pp_toolused pp_toollist *ToolMovingSpeed*)
      (SETQ pp_toolindex (1+ pp_toolindex))))
  (SETQ $index pp_toolindex)
  (SETQ $skip *SkipToolInit*)
  (SETQ $msgdist distmsg $msgactive activemsg)
  (COND
    ((AND (NOT $chdist) (NOT $chactive)) nil)
    ((= $maxtools 1) nil)
    ((AND $chdist $chactive) ; Distance and Active should always be changed
      (SETQ $msg (STRCAT $msgactive " " $msgdist))
      (COND
        ((AND (= $index 1) (= $tools 1) $skip)
          (SETQ $reason 1)
          (CHTOOL))
        ((AND (NOT $distctrl) (NOT $activectrl)) ; Change distance and active tool manually
          (SETQ $reason 6)
          (CHTOOL))
        ((AND $distctrl $activectrl)  ; Change distance and active tool by CNC
          (SETQ $reason 9)
          (CHTOOL))
        ((AND (NOT $distctrl) $activectrl) ; Change distance manually and avtive tool by CNC
          (SETQ $reason 7)
          (CHTOOL))
        ((AND $distctrl (NOT $activectrl)) ; Change distance by CNC and active tool manually
          (SETQ $reason 8)
          (CHTOOL))
      ))
    ((AND $chdist (NOT $chactive)) ; Distance should be changed
      (SETQ $msg $msgdist $msgactive "")
      (IF $distctrl
        (SETQ $reason 5) ; Change distance by CNC
        (SETQ $reason 4) ; Change distance manually
      )
      (CHTOOL))
    ((AND (NOT $chdist) $chactive) ; Active tool should be changed
      (SETQ $msg $msgactive $msgdist "" )
      (IF $activectrl
        (SETQ $reason 3) ; Change active by CNC
        (SETQ $reason 2) ; Change active manually
      )
      (CHTOOL))
  )
  (IF (OR $chdist $chactive) (SETQ pp_toolisup T))
)

(DEFUN chtool ()
  ($STOP (LIST $msg))
)

(DEFUN $rapid3d (vars)
  (SETQ pp_rapid3dlist (CONS (LIST (NTH 0 vars) (NTH 1 vars) (NTH 2 vars) (NTH 3 vars) (NTH 4 vars)) pp_rapid3dlist))
  (IF (= (NTH 4 vars) 2) (SETQ pp_rapid3dupper (NTH 2 vars)))
)

(DEFUN $rapid (vars /  pp_x pp_y pp_z z $attrib flag untrans pp_pt $reason pp_fe)
  ;Arguments in vars: X, Y, Z, Flag, Untrans
  (SETQ pp_x (NTH 0 vars))
  (SETQ pp_y (NTH 1 vars))
  (SETQ pp_z (NTH 2 vars))
  (SETQ $attribrapid (NTH 3 vars))
  (SETQ flag (NTH 4 vars)) ; Flag values: 0=2D rapid in IGEMS, 1=Rapid in 3D-5X, 2=Rapid in 3D-5X and axis rotation point
  (SETQ untrans (NTH 5 vars))
  (IF (NTH 6 vars) (SETQ pp_crot (NTH 6 vars)))
  (IF (NOT pp_crot) (SETQ pp_crot 0.0))
  (SETQ pp_$c pp_crot)
  (IF (NOT pp_$cold) (SETQ pp_$cold pp_$c))
  (SETQ pp_$crel (- pp_$cold pp_$c))
  (SETQ pp_$cold pp_$c)
  (IF (MEMBER flag (LIST 1 2)) (SETQ pp_zmaster (NTH 2 vars)))
  (IF (= $zmode 0) (SETQ pp_zmaster pp_zclear)) ; Fixed Z-axis The Z value is at material
  (SETQ $reason 0)
  (COND
    (pp_rapidnative (SETQ $reason pp_rapidnative))
    ((= flag 1) (SETQ $reason 4))
    ((= flag 2) (SETQ $reason 4)) ; seems to be the highest point on 5X-rapid, after this the 5X head will rotate
    ((= flag 3) (SETQ $reason 5)) ; The last 5X-rapid to the piercing point in 5X-rapid
    ((= flag 4) (SETQ $reason 6)) ; if there is a 5XSTOP
  )
  (IF pp_tooldata ($TOOLSET pp_tooldata))
  (SETQ pp_tooldata nil)
  (IF untrans
    (PROGN
      (SETQ pp_$x pp_x pp_$y pp_y)) ; drilling points are already transed ZOK
    (PROGN
      (SETQ pp_pt (LIST pp_x pp_y z))
      (SETQ pp_unkerf (POLAR pp_pt (ANGLE pp_oldp pp_pt) 10)) ; This point must be transed and be global --------------------------------------------
      (SETQ pp_$pt (TRANS pp_x pp_y z))
      (SETQ pp_$x (CAR pp_$pt) pp_$y (CADR pp_$pt)))
  )
  (SETQ pp_fe *SpeedRapid* pp_fs *SpeedRapid*)
  (DEFVARS) ; This will also set $z
  (IF (NOT pp_$zold) (SETQ pp_$zold $z))
  (SETQ $zrel (- (- pp_$zold (SETQ pp_$zold $z))))
  ;(IF (= pp_flag 1) (SETQ pp_sim pp_z))
  (IF (AND (= $reason 5) ; This replace the Rapid down with TOOLDOWN if that is possible
           (EQUAL pp_x (CAR pp_oldp) 0.05)
           (EQUAL pp_y (CADR pp_oldp) 0.05))
    ($TOOLDOWN 5)
    (PROGN
      (SSIM-RAPID pp_$x pp_$y pp_zmaster *SpeedRapid* *SpeedAcceleration* pp_crot)
      (IF $attribrapid
        (PROGN
          (SETQ attrib $attrib)
          (SETQ $attrib $attribrapid)
          (SRAPID)
          (SETQ $attrib attrib))
        (RAPID))
    )
  )
  (SIM-INFOTEXT "")
  (IF pp_stopdata (SETQ $reason 2))
  (IF pp_stopdata ($STOP pp_stopdata))
  (SETQ pp_stopdata nil)
  (SETQ pp_oldp (IF untrans (LIST pp_$x pp_$y pp_zmaster) (LIST pp_x pp_y pp_zmaster)))
  (SETQ pp_$oldp (LIST pp_$x pp_$y pp_zmaster))
)


(DEFUN srapid()
  (RAPID)
)

(DEFUN $stop (vars / $msg $cond)
  (SETQ $msg (NTH 0 vars) $cond (NTH 1 vars))
  (SETQ $msg (IF (NOT $msg) "" (STRCASE $msg)))
  ;(SIM-STOP $msg)
  (IF (NOT $MSG) (SETQ $msg ""))
  (STOP)
)

(DEFUN stop (/ a)
  (SETQ a a)
)

(DEFUN cuton () nil)

(DEFUN $cuton (vars / pp_x pp_y pp_side pp_ptype pp_qua pp_geoarea pp_geolen pp_leadname pp_nodename
                      pp_inside pp_xstart pp_ystart pp_nuse pp_fs
                      pp_fe pp_flag pp_endp pp_startp pp_direction leaddist tomove looplen loops dlppt rest ptime)
                      ; pp_mintan pp_maxtan pp_starttan must be global
  ;(IF fun (WRITE "$CUTON"))

  (SETQ pp_x (NTH 0 vars) pp_y (NTH 1 vars) pp_z (NTH 2 vars) pp_side (NTH 3 vars) pp_ptype (NTH 4 vars) pp_qua (NTH 5 vars)) ;ZOK
  (SETQ pp_clen (NTH 6 vars) pp_geoarea (NTH 7 vars) pp_geolen (NTH 8 vars) pp_leadname (NTH 9 vars)) ; ZOK
  (SETQ pp_nodename (NTH 10 vars) pp_starttan (NTH 11 vars) pp_mintan (NTH 12 vars)) ;ZOK
  (SETQ pp_maxtan (NTH 13 vars) pp_inside (NTH 14 vars) pp_xstart (NTH 15 vars) pp_ystart (NTH 16 vars)) ;ZOK
  (SETQ pp_zstart (NTH 17 vars) pp_iskerfed (NTH 18 vars) pp_fe (NTH 19 vars) pp_vec (NTH 20 vars)) ;ZOK
  (SETQ pp_bevelflag (NTH 21 vars) pp_maxslope (NTH 22 vars) pp_cutdirection (NTH 23 vars))
  (SETQ pp_leadplan (NTH 24 vars) pp_vectordir (NTH 25 vars) pp_approatch (NTH 26 vars));ZOK
  (SETQ pp_leadoutplan (NTH 27 vars) pp_flipwindup (NTH 28 vars)) ;NTH 28=Was Retract changed in 2010
  (SETQ pp_cinit (NTH 29 vars) pp_crot (NTH 30 vars))
  (SETQ pp_len (NTH 31 vars)) (SETQ $attrib (NTH 32 vars))
  (SETQ $leadname pp_leadname)
  (SETQ $clen pp_clen)
  (SETQ thick (DISTANCE (LIST 0.0 0.0 0.0) pp_vec))
  (IF (OR *AWJAutomaticPiercing* (AND *3D-5X* pp_vec)) (SETQ *AWJLinearPiercingDistance* (* (DISTANCE (LIST 0.0 0.0 0.0) pp_vec) 0.15)))
  (CUTON)
  (IF (AND (EQUAL pp_bevelprim (LIST 0 0 -1) 0.001) *LAG* (NOT pp_lagwarning))
    (SETQ pp_lagwarning (ALERTHELP "WARNING! Kinematic design not suitable for LAG control!" "lagwarning")))
  (SETQ pp_kerfside pp_side) ; kerfside is never changed of any reason. $side can be used in the future
  (SETQ $side pp_kerfside)
  (SETQ $edge pp_inside)
  ;(ALERT (STRCAT "pp_flipwindup:" (TOSTR pp_flipwindup)))
  (SETQ pp_flipwindup (IF (= pp_flipwindup 1) T nil))
  ;(ALERT (STRCAT "pp_flipwindup:" (TOSTR pp_flipwindup)))
  (IF pp_starttan
    (PROGN
      (SETQ pp_starttan (+ pp_starttan pp_rotate))
      (SETQ pp_mintan (+ pp_mintan pp_rotate))
      (SETQ pp_maxtan (+ pp_maxtan pp_rotate))))
  (SETQ $starttan pp_starttan $mintan pp_mintan $maxtan pp_maxtan)
  (IF (NOT pp_bevelflag) (SETQ pp_bevelflag 0)) ; 1=Tilted piercing, 2=Bevel 16=3D-5X cut, 64=Tacflag
  (IF (AND (= (LOGAND pp_bevelflag 2) 0) *3D-5X* (NOT (EQUAL pp_z *3D-MaxZ* 0.01)) (NOT pp_mix2d3d))
    (SETQ pp_mix2d3d (ALERTHELP "WARNING! 3D and 2D thickness is mismatch" "mix2d3d")))
  (SETQ pp_3d5x (IF (> (LOGAND pp_bevelflag 16) 0) T nil))
  (IF (> (LOGAND pp_bevelflag 128) 0) (SETQ pp_bevelflag (- pp_bevelflag 128) $speedramp nil) (SETQ $speedramp T)) ; If 128 then speedramp nil
  (SETQ pp_fs pp_fe)
  (SETQ $lowatoff (CAR pp_lowhighlist))
  (SETQ pp_lowhighlist (CDR pp_lowhighlist))
  (IF (AND (NOT pp_lowhighlist) *SerialProduction* pp_serialpressure) (SETQ $lowatoff T))

  ; pp_bevelflag: Bit value. 1= Tilted piercing, 2=5X-cutting, 64=TAC (other values will be removed)

  (IF (> (LOGAND pp_bevelflag 2) 0) (SETQ pp_side 0))
  (IF (AND (> *Speedmode* 1)(<= pp_maxslope *HeadMinTilt*) (MEMBER *Headtype* (LIST 1 2))) (SETQ pp_bevelflag 0))
  (SETQ tacflag (IF (> (LOGAND pp_bevelflag 64) 0) T nil))
  (IF (NOT *MasterTac*) (SETQ tacflag nil))
  (SETQ *TAC* tacflag)
  (SETQ $ab (IF (OR (> (LOGAND pp_bevelflag 2) 0) (AND *TAC* (> *Speedmode* 1))) T nil)) ; Generate no AB if TAC are used in fixed speed
  (IF (= *Headtype* 0) (SETQ $ab nil))
  (SETQ $maxslope (IF pp_maxslope (RADTODEG pp_maxslope) 0))
  (SETQ pp_dobevel (IF (> (LOGAND pp_bevelflag 2) 0) T nil))
  (SETQ $usetac (IF pp_dobevel nil (OR *TAC* *LAG*))) ; is only T on 2D geometry with TAC
  (SETQ $usebevel pp_dobevel)
  (SETQ $usebeveltac (IF (AND (OR *TAC* *LAG*) $usebevel) T nil))
  (IF (OR $usebevel $usebeveltac $usetac) (SETQ $ctype 2) (SETQ $ctype 0))
  (IF (> (LOGAND pp_bevelflag 1) 0) (SETQ $ctype (1+ $ctype)))
  (IF drilling-flag ($DRILLING-END))
  (IF measure-flag ($MEASURE-END))
  (IF pp_tooldata ($TOOLSET pp_tooldata))
  (SETQ pp_tooldata nil)
  (IF pp_partdata ($PART pp_partdata))
  (IF ppiercing-flag ($PPIERCING-END))
  (IF marking-flag ($MARKING-END))
  (IF (NOT cutting-flag) ($cutting-begin))


  (SETQ $nodename pp_nodename)
  (IF (AND *PiercingAlways* (> pp_bevelflag 0))
    (PROGN
      (SETQ $x *ServicePosX* $y *ServicePosY* $reason 1)
      (MRAPID)
      (SETQ $reason 5)
      ($STOP (LIST "Service position before 5X-cutting"))
      (SETQ *PiercingAlways* nil))
  )
  (COND
    (pp_rapid3dlist
      (SETQ uprapid T)
      (FOREACH s (REVERSE pp_rapid3dlist)
        (IF uprapid ($RAPID s))
        (IF (EQUAL (CADDR s) pp_rapid3dupper 0.01) (SETQ uprapid nil))
      ))

    ((AND (= pp_ptype 0) (= *BlindLeadOption* 1)); Like Philips CNC G43/G44
      (SETQ len (IF (= *InternalToolCompensation* 2) (* *MaxToolDiameter* 0.5) (* (- *MaxToolDiameter* *ToolDiameter*) 0.5)))
      (COND
        ((= pp_kerfside 0) (SETQ pp_temp (LIST pp_x pp_y)))
        ((= pp_kerfside 1) (SETQ pp_temp (POLAR (LIST pp_x pp_y) (+ pp_cutdirection PIH) len)))
        ((= pp_kerfside 2) (SETQ pp_temp (POLAR (LIST pp_x pp_y) (- pp_cutdirection PIH) len)))
      )
      ($RAPID (LIST (CAR pp_temp) (CADR pp_temp) pp_zmaster nil 0 nil pp_cinit))
      (SETQ pp_ptype 5)) ; Change to airstart
    ((AND (= pp_side 0) (= pp_ptype 0)) ; If side=0 and piercingtype=Blind
      ($RAPID (LIST pp_x pp_y pp_zmaster nil 0 nil pp_crot))) ;ZOK Move to geoemry point
    (pp_refposdata nil) ; ********* REFPOSDATA
    (T
      ($RAPID (LIST pp_xstart pp_ystart pp_zmaster nil 0 nil pp_cinit))) ; ZOK Move to piercing point
  )
  (IF pp_partstopdata (PROGN (SETQ $reason 1) ($STOP pp_partstopdata)))
  (SETQ pp_partstopdata nil)
  ($QUALITY (LIST pp_qua T)) ; ZOK
  (SETQ pp_ab nil)
  (SETQ $ptype pp_ptype)

  (SETQ $a 0 $b 0)
  ;(SETQ pp_pathccw (IF (> (ABS (- pp_starttan pp_mintan)) (ABS (- pp_starttan pp_maxtan))) nil T))
  (SETQ $external (MINUSP pp_inside))

  ; change piercing types depending of machine type
  (SETQ $useabr nil)
  (COND
    ((= *MachineType* 0) (SETQ $useabr T)) ; AWJ cutting
    ((= *MachineType* 1) ; Pure water cutting
      (IF (MEMBER pp_ptype (LIST 1 4 5)) (SETQ pp_ptype 2))) ;listan var tidigare 1,3,4,5
    ((= *MachineType* 2) ; Plasma cutting
      (IF (MEMBER pp_ptype (LIST 0 1 3)) (SETQ pp_ptype 2)))
    ((= *MachineType* 3) ; Oxyfuel
      (IF (MEMBER pp_ptype (LIST 0 1 3 4)) (SETQ pp_ptype 2)))
    ((= *MachineType* 3) ; Laser
      (IF (MEMBER pp_ptype (LIST 0 3 4)) (SETQ pp_ptype 2)))
  )

  (SETQ pp_startslope (IF pp_vec (ATAN (DISTANCE (LIST 0 0) pp_vec) (ABS (CADDR pp_vec))) 0.0))
  (IF (AND (<= pp_startslope *HeadMinTilt*) (> (LOGAND pp_bevelflag 1) 0)) (SETQ pp_bevelflag (- pp_bevelflag 1)))
  (COND
    ((NOT pp_abold) (SETQ alta 0.0))
    (*HeadPrimaryAxisLimitations*  (SETQ alta 0.0))
    ((MEMBER *Headtype* (LIST 1 2 6)) ; använder alta hela tiden för att slippa få onödiga variabler
      (SETQ alta (+ (CAR pp_abold) PI))
      (SETQ alta (- alta (REM alta PID))))
    (T (SETQ alta 0))
  )
  (COND
    ((AND (> *Headtype* 0) (< pp_maxslope 0.0005)) ; If jet will be vertical during whole cut
      (SIM3D-TILT alta 0 0 0)
      ($TILT alta 0 1)) ; $reason var 4 ändrat 2019.05.16 till 1 efter önskan från STM
    ((AND (> *Headtype* 0) (NOT $ab))
      (SIM3D-TILT alta 0 0 0)
      ($TILT alta 0 1)) ;$reason var 4 ändrat 2019.05.16 till 1 efter önskan från STM
    ((NOT pp_vec); if no vec do nothing
      (IF (AND (> *HeadType* 0) (NOT *HeadStraight*) pp_headistilt)
        (PROGN
          (SIM3D-TILT alta 0 0 0)
          ($TILT alta 0 1)))) ;$reason var 4 ändrat 2019.05.16 till 1 efter önskan från STM
    ($hqch
      (IF (AND (> *HeadType* 0) (NOT *HeadStraight*) pp_headistilt)
        (PROGN
          (SIM3D-TILT alta 0 0)
          ($TILT alta 0 1)))) ; $reason var 4 ändrat 2019.05.16 till 1 efter önskan från STM4
    ((AND (NOT pp_dobevel) (NOT *TAC*) (NOT *LAG*)) ; If not using bevel or not using TAC do nothing
      (IF (AND (> *HeadType* 0) (NOT *HeadStraight*))
        (PROGN
          (SETQ pp_$vec (LIST 0 0 -1)) ; la dit 2013-02-07
          (SIM3D-TILT 0 0 0 0)
          ($TILT alta 0 0 0)))) ;$ reason var 4 ändrat 2019.05.16 till 1 efter önskan från STM
    ((> (LOGAND pp_bevelflag 1) 0) ;In this case we should use tilted piercing
      (SETQ pp_abinit T)
      (SETQ pp_vertical nil)
      (SETQ pp_$vec (TRANSVEC pp_vec))
      (SETQ pp_ab (TILTDIR pp_$vec))
      (TANKSAFE pp_$x pp_$y pp_$vec)
      (DEFVARS)
      (SIM3D-TILT (CADDR pp_ab) (CADDDR pp_ab) $arel $brel)
      ($TILT $a $b 2))

    ((OR (= *HeadType* 1) (= *Headtype* 2)); Type milling or Tops
      (SETQ pp_abinit T)
      (SETQ pp_tmplen (DISTANCE (LIST 0.0 0.0) pp_vec))
      (IF (< pp_tmplen 0.01) (SETQ pp_tmplen 0.01))
      (SETQ pp_tmpvec (POLAR (LIST 0.0 0.0) pp_vectordir pp_tmplen))
      (SETQ pp_tmpvec (LIST (CAR pp_tmpvec) (CADR pp_tmpvec) (CADDR pp_vec)))
      (SETQ pp_$vec (TRANSVEC pp_tmpvec))
      (SETQ pp_ab (TILTDIR pp_$vec))
      (DEFVARS)
      (SIM3D-TILT (CADDR pp_ab) 0 $arel $brel)
      ($TILT $a (IF (MINUSP $b) -0.00001 0.00001) 3) ; Så att man kan ta MINUSP för att B skall peka åt rätt håll
      (IF (AND nil (> pp_startslope *HeadMinTilt*))
        (PROGN
          (SETQ pp_vec pp_tmpvec)
          (SETQ pp_$vec (TRANSVEC pp_vec))
          (SETQ pp_ab (TILTDIR pp_$vec))
          (DEFVARS))))
    ((AND (OR (= *HeadType* 3) (= *HeadType* 4) (= *HeadType* 5)) (OR pp_headistilt $uses6x))
      (SETQ pp_$vec (TRANSVEC pp_vec)) ;la dit 2013-02-07
      (DEFVARS)
      (IF (NOT $arel) (SETQ $arel 0))
      (IF (NOT $brel) (SETQ $brel 0))
      (SIM3D-TILT 0 0 $arel $brel)
      ($TILT 0 0 3))
    ((= *HeadType* 6)
      (SETQ pp_abinit T)
      (SETQ pp_$vec (TRANSVEC pp_vec))
      (SETQ pp_ab (TILTDIR pp_$vec))
      (DEFVARS)
      (SIM3D-TILT (CADDR pp_ab) $arel $brel)
      ($TILT $a 0 3))
    (T nil)
  )

  (COND
    (pp_rapid3dlist
      (SETQ downrapid nil)
      (FOREACH s (REVERSE pp_rapid3dlist)
        (IF downrapid ($RAPID s))
        (IF (EQUAL (CADDR s) pp_rapid3dupper 0.01) (SETQ downrapid T))
      )
      (SETQ pp_rapid3dlist nil pp_rapid3dupper nil)
      (SETQ pp_zmaster pp_zstart)
      (IF pp_refposdata ($REFPOS pp_refposdata))
      (SETQ pp_refposdata nil)
      ;(ALERT "YES")
      ($RAPID (LIST pp_xstart pp_ystart pp_zmaster nil 3 nil pp_cinit)))

    (T ;*TiltDownOrder*
      (IF pp_refposdata
        (PROGN
          ($REFPOS pp_refposdata)
          (SETQ pp_refposdata nil)
          ($RAPID (LIST pp_xstart pp_ystart pp_zmaster nil 3 nil pp_cinit))))
      (SETQ pp_zmaster pp_zstart)
      ($TOOLDOWN 4))
  )
    ;(PRINC (STRCAT "**** " (TOSTR pp_fe) " *****"))
  (IF (<= pp_fe 0) (SETQ pp_fe *SpeedMinCutting*))
  (SIM-ON T pp_fe)
  (SETQ pp_fs pp_fe)
  (SETQ pp_cleft pp_clen)
  (SETQ pp_flag 1)
  (SETQ pp_endp (LIST pp_x pp_y pp_z))
  (SETQ pp_startp (LIST pp_xstart pp_ystart pp_zstart))
  (SETQ pp_direction (ANGLE pp_startp pp_endp))
  (COND
    ((AND (= pp_ptype 4) (NOT pp_makeprepiercing) (NOT *DrillingTools*))
      (SETQ pp_ptype 3))               ; If no drillingtool than change to Circular
    ((AND (= pp_ptype 4) (< *DrillByType* 3)) (SETQ pp_ptype 5)) ; If drilling than change to Airstart
  )
  (IF (AND pp_makeprepiercing (OR (= pp_ptype 2) (= pp_ptype 3))) (SETQ pp_ptype 5)) ; If Prepiercing and stat or cirk piercing then airstart
  (SETQ leaddist pp_len); (DISTANCE pp_startp pp_endp))
  (IF (= *InternalToolCompensation* 0) (SETQ pp_side 0)) ; If kerf handled by IGEMS
  (IF pp_iskerfed (SETQ pp_side 0)) ; Temporary solution if TVL is used
  (SETQ pp_leadinspeed (CALCAWJFEED 5 (DISTANCE (LIST 0 0 0) pp_vec)))
  (COND
    ; When using *BlindLeadOption* pp_ptype is changed to 5 Airstart
    ((AND (= pp_ptype 0) (= pp_side 0)) ; Blind lead, start on geometry, this should also be if we using internal compensation.
      (SETQ $ptype 0)
      (SETQ $kerf pp_side)
      (SETQ $chkerf (IF (> $kerf 0) T nil))
      (IF (NOT *TAC*) (SETQ pp_fs *SpeedMaxCutting* pp_fe *SpeedMaxCutting*))
      (SETQ pp_fs *SpeedMaxCutting* pp_fe *SpeedMaxCutting*) ; Changed 2019.05.16 could not se any reason why line above should be used.
      (SETQ pp_fs 600 pp_fe 600)
      (SETQ pp_isleadin T)
      (SETQ pp_z (NTH 2 vars))
      ;(SETQ pp_$vec (TRANSVEC pp_vec))
      ;(SETQ pp_ab (TILTDIR pp_$vec))
      ($LINE (LIST pp_x pp_y pp_z 1 pp_fs pp_fe 0 pp_vec pp_cutdirection pp_vectordir pp_crot)) ;ZOK
      (SETQ pp_isleadin nil)
      ($PIERCING (LIST pp_x pp_y pp_z 0 nil))) ;ZOK
    ((= pp_ptype 0) ; Blind lead
      (SETQ $ptype 0)
      (SETQ $kerf pp_side)
      (SETQ $chkerf (IF (> $kerf 0) T nil))
      (IF (NOT *TAC*)(SETQ pp_fs *SpeedMaxCutting* pp_fe *SpeedMaxCutting*))
      (SETQ pp_fs *SpeedMaxCutting* pp_fe *SpeedMaxCutting*); Changed 2019.05.16 could not se any reason why line above should be used.
      (SETQ pp_isleadin T)
      (SETQ pp_fs 600 pp_fe 600)
      ;(SETQ pp_$vec (TRANSVEC pp_vec))
      ;(SETQ pp_ab (TILTDIR pp_$vec))
      ($LINE (LIST pp_x pp_y pp_z 1 pp_fs pp_fe 0 pp_vec pp_cutdirection pp_vectordir pp_crot)) ;ZOK
      (SETQ pp_isleadin nil)
      ($PIERCING (LIST pp_x pp_y pp_z 0 nil))) ;ZOK
    ((AND (= pp_ptype 1) (> leaddist *AWJLinearPiercingDistance*)) ;We don't need to use DLP in this case
      (SETQ $ptype 1)
      (SETQ $kerf pp_side)
      ($PIERCING (LIST pp_xstart pp_ystart pp_zstart 0 nil)) ;ZOK
      (SETQ $chkerf (IF (> $kerf 0) T nil))
      (IF (AND (= *MachineType* 0) (> *SpeedMode* 1) (> pp_fe pp_leadinspeed)) (SETQ pp_fs pp_leadinspeed pp_fe pp_leadinspeed)) ; Changed December 2014 to be same as airstart
      ;(SETQ pp_z (NTH 2 vars))
      ($LINE (LIST pp_x pp_y pp_z 1 pp_fs pp_fe 0 pp_vec pp_cutdirection pp_vectordir pp_crot))) ;ZOK
    ((= pp_ptype 1)
      (IF (AND (= *MachineType* 0) (> *SpeedMode* 1) (> pp_fe pp_leadinspeed)) (SETQ pp_fs pp_leadinspeed pp_fe pp_leadinspeed)) ; Changed December 2014 to be same as airstart
      (IF (< leaddist *ToolDiameter*)
        (PROGN ; If the leadin is to short then use stationary piercing
          (IF (NOT pp_dlpmsg) (SETQ pp_dlpmsg (ALERT "Lead in to short for linear piercing. Using stationary")))
          (SETQ $kerf pp_side)
          (SETQ $ptype 1)
          ($PIERCING (LIST pp_xstart pp_ystart pp_zstart *AWJStationaryPiercing* nil)) ;ZOK
          (SETQ $chkerf (IF (> $kerf 0) T nil))
          ($LINE (LIST pp_x pp_y pp_z 1 pp_fs pp_fe 0 pp_vec pp_cutdirection pp_vectordir pp_crot)) ;ZOK
          (SETQ $chkerf nil))
        (PROGN
          (SETQ $kerf pp_side)
          ($PIERCING (LIST pp_xstart pp_ystart pp_zstart 0 nil))
          (SETQ tomove (- *AWJLinearPiercingDistance* leaddist)) ; The DLP length minus the standard lead
          (IF (= *InternalToolCompensation* 2) (SETQ looplen (- leaddist *ToolDiameter*)) (SETQ looplen leaddist))
          (IF (AND (> tomove 0.0) (> looplen 0.0)) ; To avoid divition by zero
            (SETQ loops (1+ (FIX (/ tomove (* looplen 2)))))
            (SETQ loops 0))
          (SETQ dlppt (POLAR pp_startp pp_direction looplen))
          (SETQ $kerf 0 $chkerf nil)
          (REPEAT loops
            ($LINE (LIST (CAR dlppt) (CADR dlppt) pp_zstart 16 pp_fs pp_fe 0 pp_vec cutdirection pp_vectordir pp_crot));ZOK
            ($LINE (LIST pp_xstart pp_ystart pp_zstart 16 pp_fs pp_fe 0 pp_vec pp_cutdirection pp_vectordir pp_crot));ZOK
          )
          (SETQ rest (- tomove (* loops (* looplen 2))))
          (IF (> rest 0.2)
            (PROGN
              (SETQ dlppt (POLAR pp_startp pp_direction (* rest 0.5)))
              ($LINE (LIST (CAR dlppt) (CADR dlppt) pp_zstart 16 pp_fs pp_fe 0 pp_vec pp_cutdirection pp_vectordir pp_crot)) ;ZOK
              ($LINE (LIST pp_xstart pp_ystart pp_zstart 16 pp_fs pp_fe 0 pp_vec pp_cutdirection pp_vectordir pp_crot)))) ;ZOK
          (SETQ $chkerf (IF (> $kerf 0) T nil) $kerf pp_side)
          ($LINE (LIST pp_x pp_y pp_z 1 pp_fs pp_fe 0 pp_vec pp_cutdirection pp_vectordir pp_crot))
          (SETQ $chkerf nil))))
    ((= pp_ptype 2) ;Stationary piercing
      (COND
        ((= *MachineType* 0) (SETQ ptime *AWJStationaryPiercing*))
        ((= *MachineType* 1) (SETQ ptime *WaterPiercingTime*))
        ((= *MachineType* 2) (SETQ ptime *PlasmaPiercingTime*))
        ((= *MachineType* 3) (SETQ ptime *OxyfuelPiercingTime*))
        ((= *Machinetype* 4) (SETQ ptime *LaserPiercingTime*))
      )
      (SETQ $kerf pp_side)

      ($PIERCING (LIST pp_xstart pp_ystart pp_zstart ptime nil)) ;ZOK

      (SETQ $chkerf (IF (> $kerf 0) T nil))
      (SETQ pp_isleadin T)
      ;(SETQ pp_z (NTH 2 vars))
      ($LINE (LIST pp_x pp_y pp_z 1 pp_fs pp_fe 0 pp_vec pp_cutdirection pp_vectordir pp_crot)) ;ZOK
      (SETQ pp_isleadin nil))
    ((= pp_ptype 3) ; Circular piercing
      (SETQ $kerf pp_side)
      (SETQ $chkerf nil)
      (SETQ pp_absave pp_ab)
      (SETQ pp_ab nil)
      ($PIERCING (LIST pp_xstart pp_ystart pp_zstart *AWJCircularPiercing* T)) ;ZOK
      (SETQ pp_ab pp_absave)
      (SETQ $chkerf (IF (> $kerf 0) T nil))
      (SETQ pp_isleadin T)
      ;(SETQ pp_z (NTH 2 vars))
      ($LINE (LIST pp_x pp_y pp_z 1 pp_fs pp_fe 0 pp_vec pp_cutdirection pp_vectordir pp_crot)) ;ZOK
      (SETQ pp_isleadin nil))
    ((= pp_ptype 4) ; Drilling. Only when it's not optimized.
      (SETQ $kerf pp_side)
      ($PIERCING (LIST pp_xstart pp_ystart pp_zstart 0 nil)) ;ZOK
      (SETQ $kerf pp_side)
      (SETQ $chkerf (IF (> $kerf 0) T nil))
      (SETQ pp_isleadin T)
      ($LINE (LIST pp_x pp_y pp_z 1 pp_fs pp_fe 0 pp_vec pp_cutdirection pp_vectordir pp_crot));ZOK
      (SETQ pp_isleadin nil))
    ((= pp_ptype 5) ; Airstart
      (IF (AND (= *MachineType* 0) (> *SpeedMode* 1) (> pp_fe pp_leadinspeed)) (SETQ pp_fs pp_leadinspeed pp_fe pp_leadinspeed))
      (SETQ $kerf pp_side)
      ($PIERCING (LIST pp_xstart pp_ystart pp_zstart 0 nil)) ;ZOK
      (SETQ $chkerf (IF (> $kerf 0) T nil))
      (SETQ pp_isleadin T)
      ;(SETQ pp_z (NTH 2 vars))
      ($LINE (LIST pp_x pp_y pp_z 1 pp_fs pp_fe 0 pp_vec pp_cutdirection pp_vectordir pp_crot)) ;ZOK
      (SETQ pp_isleadin nil))
    ((= pp_ptype 6) ; User defined
      (SETQ $kerf pp_side)
      ($PIERCING (LIST pp_xstart pp_ystart pp_zstart 0 nil)) ;ZOK
      (SETQ $chkerf (IF (> $kerf 0) T nil))
      (SETQ pp_isleadin T)
      ;(SETQ pp_z (NTH 2 vars))
      ($LINE (LIST pp_x pp_y pp_z 1 pp_fs pp_fe 0 pp_vec pp_cutdirection pp_vectordir pp_crot)) ;ZOK
      (SETQ pp_isleadin nil))
    (T (PRINC "\n******  Unknownd piercing type ******\n"))
  )
  (IF (AND (> pp_side 0) (OR (= *InternalToolCompensation* 2) (= *InternalToolCompensation* 1)) *AddExtraMovement*) (SETQ $leadout T) (SETQ $leadout nil))
  (IF $ab (SETQ pp_headistilt T))
  (SETQ $chkerf nil)
)

(DEFUN $tilt (a b reason / $reason fun $ab)
  (IF fun (WRITE "$TILT"))
  ;The variables has been handled by defvars
  (SETQ $a a $b b $reason reason $ab T)
  (TILT)
  (SETQ pp_aold $a pp_bold $b)
)
(DEFUN mrapid ()
  nil
)

(DEFUN tilt ()
  nil
)
(DEFUN $quality (vars)
  (SETQ $qua (1+ (NTH 0 vars)))
  (COND
    ((> *MachineType* 0) (SETQ $f 0))
    ((= $qua 1) (SETQ $f $xrough))
    ((= $qua 2) (SETQ $f $rough))
    ((= $qua 3) (SETQ $f $medium))
    ((= $qua 4) (SETQ $f $fine))
    ((= $qua 5) (SETQ $f $xfine))
  )
  (IF (= *Machinetype* 1) (SETQ *WaterSpeedFactor* (NTH (1- $qua) *WaterSpeedQuality*)))
  (SETQ $chqua (IF (NTH 1 vars) nil T))
  (SETQ $initqua (NTH 1 vars))
  (QUALITY)
)

(DEFUN quality () nil)

(DEFUN $cutoff (vars / pt skiptoolup)
  ;Vars= typ, x, y, z
  ;About pp_zmode: 3= by Z-cordinate, 6= Sensor by Z-cordinate, 7=Measuring in advance
  (SETQ pp_5xheight nil)
  (SETQ pp_3xmove nil)
  (SETQ typ (NTH 0 vars))
  (COND
    ((= typ 0) nil); This is a normal 3X toolup from IGEMS
    ((= typ 1)     ; This is a 3D-5X cutoff, and the Z value should be used in toolup
      (SETQ pp_5xheight (NTH 3 vars)))
    ((AND (= typ 2) (MEMBER pp_zmode (LIST 3 6 7)))    ; Not vertical toolup
      (SETQ pp_5xx (NTH 1 vars) pp_5xy (NTH 2 vars) pp_5xz (NTH 3 vars))
      (SETQ pp_3xmove T))
    ((= typ 2)
      (CLS)
      (QUIT (ALERT "Tilted rapids only possible in programmable Z-axis")))
   )
  ;(WRITE (STRCAT "\n\nSKIPTOOLUP:" (TOSTR skiptoolup)))
  (SIM-OFF)
  (SETQ pp_abinit nil)
  (SETQ pp_$x (CAR pp_$oldp) pp_$y (CADR pp_$oldp))

  ; Turn off Jet
  (COND
    ((= *MachineType* 0)  ;AWJ cutting
      (COND
        ((NOT (AND $useabr $wacode)) (SETQ $delay 0))
        (cutting-flag (SETQ $delay *AWJDelayAbrasiveWaterOff*))
        (T (SETQ *AWJDelayWaterAbrasiveOff* 0)) ; The names is swoped in the machine setting (if it may strange).
      )
      (SETQ $time *AWJDelayAfterCutting*)
      (SETQ $marking nil))
    ((= *MachineType* 1) ; Pure Water
      (SETQ $delay 0)
      (SETQ $time *WaterDelayAfterCutting*))
    (T
      (SETQ $delay 0 $time 0))
  )

  ; Cancel tool compensation
  (COND
    ((= $kerf 0)
      (SETQ $chkerf nil)
      (CUTOFF))
    ($leadout
      (SETQ $chkerf nil)
      (CUTOFF)
      (SETQ $chkerf T $kerf 0)
      (SETQ pt (POLAR pp_oldp (- (ANGLE pp_$oldp pp_$unkerf) pp_rotate)  (* *ToolDiameter* 2)))
      ($LINE (LIST (CAR pt) (CADR pt) pp_z 32 *SpeedMaxCutting* *SpeedMaxCutting*))) ;ZOK Maybee we need to calculate Z
    (T
      (SETQ $chkerf T $kerf 0)
      (CUTOFF))
  )
  (SETQ $leadout nil $chkerf nil)

  ; turn off FLIN
  (IF pp_flinactive
    (PROGN
      (SETQ $flin 0)
      (FMODE)
      (SETQ pp_flinactive nil $flin nil)))

  (COND
    (pp_3xmove ($TOOLUP 7)) ; toolup will add 1=8
    ((AND (< pp_nrgeometry 1) *CuttingLiftZParts*)
      ($TOOLUP 5)) ; toolup will add 1=6
    (T
      ($TOOLUP 4)) ; toolup will add 1=5
  )
  (IF (AND *StopAfterFirstPart* (= $edge -1))
    (PROGN
      (SETQ $reason 4 *StopAfterFirstPart* nil $msg "Stop after first part" *StopAfterFirstCut* nil)
      ($STOP (LIST $msg))))
  (IF *StopAfterFirstCut*
    (PROGN
      (SETQ $reason 3 $msg "Stop after first cut" *StopAfterFirstCut* nil)
      ($STOP (LIST $msg))))
  (IF (AND $ab *HeadStraight*)
    (PROGN
      ($TILT 0 0 4)
      (SIM3D-TILT 0 0 $arel $brel)))
  (SETQ $ab nil)
  (SETQ $usetac nil $usebevel nil $usebeveltac nil)
)

(DEFUN cutoff()
  (SETQ a a)
)


; The function will activate FLIN at the first movement where the start and endfeed is different.
; The pp_flinactive variable must be set to nil at the cutoff function.
(DEFUN $FMODE (fstart fend)
  (IF (> fstart *SpeedMaxCutting*) (SETQ fstart *SpeedMaxCutting*))
  (IF (> fend *SpeedMaxCutting*) (SETQ fend *SpeedMaxCutting*))
  (IF funis (WRITE "$FMODE"))
  (IF (NOT pp_lastfeed) (SETQ pp_lastfeed fstart))
  (COND
    ((= *Speedmode* 2) nil) ; Nothing will happen if the ramping will be controlled by the CNC file
    ((AND (NOT pp_flinactive) (EQUAL fstart fend 0.5))       ; If startfeed and endfeed is the same, no reason to activate FLIN.
      (SETQ pp_lastfeed fend))
    ((AND (NOT pp_flinactive) (NOT (EQUAL fstart fend 0.5))) ; First time startfeed and endfeed is different then activate
      (SETQ $flin 1)
      (SETQ $fs fstart $fe fend)
      (FMODE)
      (SETQ pp_lastfeed fend)
      (SETQ pp_flinactive T))
    ((AND pp_flinactive (NOT (EQUAL fstart pp_lastfeed 0.5))) ; Next object has another startfeed then last object endfeed.
      (SETQ $flin 2)
      (SETQ $fs fstart $fe fend)
      (FMODE)
      (SETQ pp_lastfeed fend))
    (pp_flinactive
      (SETQ pp_lastfeed fend))
  )
)

(DEFUN fmode ()
  nil
)

(DEFUN $itext (vars / $txt pp_x pp_y pp_z pp_angle $length $height $attrib $font $fonttype)
  (IF (NOT inkjet-flag)
    (PROGN
      (SETQ pp_xmodsim *InkjetXOffset*  pp_ymodsim *InkjetYOffset*)
      (SETQ pp_xmod *InkjetXOffset* pp_ymod *InkjetYOffset*)
      (IF *InkjetOffsetByController*  (SETQ pp_xmod 0.0 pp_ymod 0.0))
      (SETQ inkjet-flag T)
      (SETQ pp_mode 5 $mode 5)
      (IF pp_tooldata ($TOOLSET pp_tooldata))
      ($CHMODE)
      (SETQ $mold pp_mode)))
  (SETQ pp_tooldata nil)
  (IF pp_partdata ($PART pp_partdata))

  (SETQ $txt (NTH 0 vars) pp_x (NTH 1 vars) pp_y (NTH 2 vars) pp_z (NTH 3 vars) pp_angle (NTH 4 vars) $length (NTH 5 vars)
        $height (NTH 6 vars) $attrib (NTH 7 vars) $font (NTH 8 vars) $fonttype (NTH 9 vars))
  (SETQ pp_$pt (TRANS pp_x pp_y pp_z))
  (SETQ pp_$x (CAR pp_$pt) pp_$y (CADR pp_$pt))
  (DEFVARS)
  (SSIM-RAPID pp_$x pp_$y 100 *SpeedRapid* *SpeedAcceleration* 0)
  (SETQ $angle pp_angle)
  (ITEXT)
)

(DEFUN itext ()
  (PRINC "Undefined InkJet ITEXT function\n")
)

(DEFUN $text (vars / $txt pp_x pp_y pp_angle $length $height $attrib $font $fonttype)
  (IF measure-flag ($MEASURE-END))
  (IF drilling-flag ($DRILLING-END))
  (IF ppiercing-flag ($PPIERCING-END))
  (IF cutting-flag ($CUTTING-END))
  (IF pp_tooldata ($TOOLSET pp_tooldata))
  (SETQ pp_tooldata nil)
  (IF pp_partdata ($PART pp_partdata))
  (IF (NOT marking-flag) ($MARKING-BEGIN))
  (SETQ $txt (NTH 0 vars) pp_x (NTH 1 vars) pp_y (NTH 2 vars) pp_z (NTH 3 vars) pp_angle (NTH 4 vars) $length (NTH 5 vars);ZOK
        $height (NTH 6 vars) $attrib (NTH 7 vars) $font (NTH 8 vars) $fonttype (NTH 9 vars)) ;ZOK
  (SETQ pp_$pt (TRANS pp_x pp_y pp_z))
  (SETQ pp_$x (CAR pp_$pt) pp_$y (CADR pp_$pt) pp_$z (CADDR pp_$pt))
  (SETQ $angle pp_angle)
  (DEFVARS)
  (TEXT)
)

(DEFUN text (/ tlist s cmd vars)
  ;(SETQ tlist (GENTEXT $txt pp_x pp_y pp_angle $height $attrib $font $fonttype))  Last argument is not needed set this to 0
  (SETQ tlist (GENTEXT $txt pp_x pp_y pp_z pp_angle $height $attrib $font 0)) ; Last argument is not needed set this to 0 ZOK
  ;(FOREACH s tlist (WRITE (TOSTR s)))
  (FOREACH s tlist
    (SETQ cmd (CAR s) vars (CADR s))
    ;(PRINC "\nCMD:")(PRINC cmd) (PRINC " VARS:")(PRINC vars) (PRINC "\n")
    (COND
      ((= cmd '$MARKON) ($MARKON vars))
      ((= cmd '$LINE) ($LINE vars))
      ((= cmd '$ARC) ($ARC vars))
      ((= cmd '$MARKOFF) ($MARKOFF vars))
    )
  )
)

(DEFUN $arc (vars / pp_x pp_y pp_z pp_i pp_j pp_ccw pp_flag pp_fs pp_fe pp_endpt pp_centp unkerf pp_$endpt pp_$centp
                    pp_corda pp_radie pp_segment pp_len pp_$i pp_$j pp_$di pp_$dj splits segm vecdir quads endang vlen vdir pt segv nvec vvec
                    splitv tmpang oldp pt r1 r2 newr hcorda kat LargestSegmentAngle skpsim pp_vec xmod ymod ispiercing gtype)
  (IF funis (WRITE "$ARC"))
  ; flags: 1=Belongs to leadin, 2=Belongs to leadout, 4= Belongs to marking 8=To Circular piercing 64 If generated by $ccircle

  ; STEP 1 Set all variables that are needed.
  (SETQ gtype 2)
  (SETQ pp_x (NTH 0 vars) pp_y (NTH 1 vars) pp_zmaster (NTH 2 vars) pp_i (NTH 3 vars) pp_j (NTH 4 vars)) ;ZOK
  (SETQ pp_ccw (NTH 5 vars) pp_flag (NTH 6 vars) pp_fs (NTH 7 vars) pp_fe (NTH 8 vars) pp_delta (NTH 9 vars)) ;ZOK
  (SETQ pp_vec (NTH 10 vars) pp_cutdirection (NTH 11 vars)) ;ZOK
  ;(IF (> pp_flag 0) (WRITE (STRCAT "\nFLAG:" (TOSTR pp_flag))))
  ;(IF pp_rakbevel (SETQ pp_vec nil))
  (SETQ pp_vectordir (NTH 12 vars))
  (IF (NOT pp_crot) (SETQ pp_crot 0.0))
  (IF (NTH 13 vars) (SETQ pp_crot (NTH 13 vars)))
  (SETQ pp_len (NTH 14 vars))
  (SETQ pp_$c pp_crot)
  (IF (NOT pp_$cold) (SETQ pp_$cold pp_$c))
  (SETQ pp_$crel (- pp_$cold pp_$c))
  (SETQ pp_$cold pp_$c)
  (IF (NOT pp_vectordir) (SETQ pp_vectordir 0))
  (IF (NOT pp_oldvectordir) (SETQ pp_oldvectordir pp_vectordir))
  (SETQ pp_$vec nil)
  (IF (AND (= pp_fs 0) (= pp_fe 0) (= *Machinetype* 2)) (SETQ pp_fs *PlasmaLeadinSpeed* pp_fe *PlasmaLeadinSpeed*))
  (IF (OR (= pp_fs 0) (= pp_fe 0)) (SETQ pp_fs 100 pp_fe 100))

  (IF (EQUAL pp_fe 0 0.1) (SETQ pp_fe pp_fs))

   ; STEP 2 Create Untransed points
  (SETQ pp_endpt (LIST pp_x pp_y pp_zmaster))
  (SETQ pp_centp (LIST pp_i pp_j))
  (SETQ pp_radie (DISTANCE pp_centp pp_endpt))
  (SETQ pp_corda (DISTANCE pp_oldp pp_endpt))
  (SETQ pp_segment (SEGMENT (ANGLE pp_centp pp_oldp) (ANGLE pp_centp pp_endpt) pp_ccw)) ; This angle is always positive

  ; STEP 3 Create Transed points
  (SETQ pp_$centp (TRANS (CAR pp_centp) (CADR pp_centp) pp_zmaster))
  (SETQ $ccw pp_ccw)
  (IF (NOT pp_len)
    (SETQ $len (* pp_radie pp_segment))
    (SETQ $len pp_len)
  )
  (SETQ $short (IF (<= pp_segment 3.0) T nil)) ; If segment smaller that 171.88 degree then $short is T
  (SETQ $segment pp_segment)
  (SETQ pp_$endpt (TRANS (CAR pp_endpt) (CADR pp_endpt) pp_zmaster))
  (SETQ pp_$radie (DISTANCE pp_$centp pp_$endpt))
  (IF $ccw
    (SETQ pp_$midp (POLAR pp_$centp (+ (ANGLE pp_$centp pp_$oldp) (* $segment 0.5)) pp_$radie))
    (SETQ pp_$midp (POLAR pp_$centp (- (ANGLE pp_$centp pp_$oldp) (* $segment 0.5)) pp_$radie))
  )
  (SETQ pp_$i (CAR pp_$centp) pp_$j (CADR pp_$centp))
  (SETQ pp_$x (CAR pp_$endpt) pp_$y (CADR pp_$endpt))
  (SETQ pp_$xm (CAR pp_$midp) pp_$ym (CADR pp_$midp))
  (SETQ pp_$di (- pp_$i (CAR pp_$oldp)) pp_$dj (- pp_$j (CADR pp_$oldp)))
  (SETQ pp_$unkerf (POLAR pp_$endpt (+ (ANGLE pp_$centp pp_$endpt) (IF pp_ccw PIH (- PIH))) 10))
  ;(WRITE (STRCAT "PP_FLAG:" (TOSTR pp_flag) " PP_VEC:" (TOSTR pp_vec)))
  (IF (= pp_flag 4) (SETQ pp_vec nil)) ; If it's marking
  (IF (AND (NOT pp_dobevel) (NOT (OR *TAC* *LAG*))) (SETQ pp_vec nil))
  ;(IF (OR (= pp_flag 8) (= pp_flag 64)) (SETQ pp_vec nil)) ; If it's circular piercing or $ccircle
  (IF (NOT pp_vec) (SETQ pp_$vec (LIST 0 0 -1))) ; Note pp_vec are still nil

  (SETQ ispiercing (IF (OR (> (LOGAND pp_flag 8) 0) (> (LOGAND pp_flag 64) 0)) T nil))
  (IF (AND (OR pp_dobevel *TAC* *LAG*) pp_vec)
    (PROGN
      (SETQ $slope (ATAN (DISTANCE (LIST 0 0) pp_vec) (ABS (CADDR pp_vec))))
      (IF (NOT (= pp_flag 2)) ;not leadout
        (PROGN
          (COND
            ((> *Headtype* 2) ; If it's not a C-axis head
              (SETQ pp_$vec (TRANSVEC pp_vec)))
            ((OR (>= $slope *HeadMinTilt*) (> (ABS (ANGDIFF pp_vectordir pp_oldvectordir)) 1.22173)) ; 70 grader
              (SETQ pp_$vec (TRANSVEC pp_vec))
              (SETQ pp_vertical nil)
              (SETQ pp_firstvertical nil))
            ((< $slope *HeadMinTilt*)
              (SETQ newveclen (* (TAN *HeadMinTilt*) (ABS (CADDR pp_vec))))
              (SETQ pp_tmpvec (POLAR (LIST 0.0 0.0) pp_vectordir newveclen))
              (SETQ pp_tmpvec (LIST (CAR pp_tmpvec) (CADR pp_tmpvec) (CADDR pp_vec)))
              (SETQ pp_$vec (TRANSVEC pp_tmpvec) pp_vertical T)
              (SETQ pp_vertical T)
              (SETQ pp_firstvertical T))
          )
          (SETQ pp_ab (TILTDIR pp_$vec))))))
  (DEFVARS)
  (IF (AND *DangerZoneUse* *DangerJetLength* pp_$vec)
    (PROGN
      (SETQ quads (CAD-ARCQUADRANTS pp_$centp pp_$oldp pp_$endpt $ccw))
      (SETQ endang (ANGLE pp_$centp pp_$endpt))
      (SETQ vlen (DISTANCE (LIST 0 0) pp_$vec))
      (SETQ vdir (ANGLE (LIST 0 0) pp_$vec))
      (FOREACH s quads
        (SETQ pt (POLAR pp_$centp s pp_$radie))
        (SETQ segv (SEGMENT endang s pp_ccw))
        (IF (NOT pp_ccw) (SETQ segv (- segv)))
        (SETQ nvec (POLAR (LIST 0 0) (+ vdir segv) vlen))
        (SETQ vvec (LIST (CAR nvec) (CADR nvec) (CADDR pp_$vec)))
        (TANKSAFE (CAR pt) (CADR pt) vvec)
      )
    )
  )
  (TANKSAFE pp_$x pp_$y pp_$vec)
  (SETQ $ft (/ $len $fe))
  ($FMODE $fs $fe)
  (IF (NOT pp_skipsim) (SSIM-ARC pp_$x pp_$y pp_$i pp_$j pp_ccw $fs $fe pp_crot))
  (IF (NOT pp_skipout)
    (PROGN
      (SETQ $zrel (- (- pp_$zold (SETQ pp_$zold $z))))
      (ARC))
    (SIM-INFOTEXT ""))
  (IF pp_ab (SETQ pp_aold (CAR pp_ab) pp_bold (CADR pp_ab)))
  (SETQ pp_oldp pp_endpt)
  (SETQ pp_$oldp pp_$endpt)
  (SETQ pp_$oldvec pp_$vec)
  (SETQ pp_oldvectordir pp_vectordir)
)

(SETQ $$ARC ARC)

(DEFUN segment (starta enda ccw / segm) ; return the absolute segment angle angle
  (SETQ segm (- enda starta))
  (COND
    (ccw
      (IF (< segm 0.0) (SETQ segm (+ segm PID))))
    (T
      (IF (> segm 0.0) (SETQ segm (- segm PID))))
  )
  (ABS segm)
)


(DEFUN linpside (lx0 ly0 lx1 ly1 px py)
  ; returns >0 if point px,py is left of line lx0,ly0-lx1,ly1
  ; return <0 if point px,py is right of line lx0,ly0-lx1,ly1
  ; larger return value means further away (but is not the distance)
  (- (* (- lx0 lx1) (- ly0 py))  (* (- ly0 ly1) (- lx0 px)))
)

(DEFUN intriangle (p0 p1 p2 target / x0 y0 x1 y1 x2 y2 px py sids)
  (SETQ x0 (CAR p0) y0 (CADR p0) x1 (CAR p1) y1 (CADR p1) x2 (CAR p2) y2 (CADR p2) px (CAR target) py (CADR target))
  ; Checks if point px,py is inside the triangle x0,y0-x1,y1-x2,y2
  ; Returns T if so, otherwise nil

  ; Check that point is on same side of all three triangle lines:
  (SETQ sids (LINPSIDE x0 y0 x1 y1 px py))
  (AND
    (>= (* sids (LINPSIDE x1 y1 x2 y2 px py)) 1.0)
    (>= (* sids (LINPSIDE x2 y2 x0 y0 px py)) 1.0))
)

(DEFUN coordswap (pt)
  (COND
    ((= *axisDirection* 0) pt)
    ((= *AxisDirection* 1) (LIST (- (CAR pt)) (CADR pt))) ; Mirror X
    ((= *AxisDirection* 2) (LIST (CAR pt) (- (CADR pt)))) ; Mirror Y
    ((= *AxisDirection* 3) (LIST (- (CAR pt)) (- (CADR pt)))) ; Mirror X and Y
    ((= *AxisDirection* 4) (LIST (CADR pt) (CAR pt)))     ; Swap X and Y
    ((= *AxisDirection* 5) (LIST (CADR pt) (- (CAR pt)))) ; Swap X and Y then mirror Y
    ((= *AxisDirection* 6) (LIST (- (CADR pt)) (CAR pt))) ; Swap X and Y then mirror X
    ((= *AxisDirection* 7) (LIST (- (CADR pt)) (- (CAR pt)))) ; Swap X and Y then mirror X and Y
    (T (ALERT "Impossible option in Coordswap"))
  )
)

(DEFUN tintfacs (p1 p2 p3 target / x1 y1 x2 y2 x3 y3 x4 y4 a b anum aden bnum bden reslt)
   (SETQ x1 (CAR p1) y1 (CADR p1) x2 (CAR p2) y2 (CADR p2))
   (SETQ X3 (CAR p3) y3 (CADR p3) x4 (CAR target) y4 (CADR target))
   ; *** Triangle interpolation factor routine ***
   ; Takes three points of a triangle and x4,y4 of a arbitrary point.
   ; Returns a list of three factors (U V W) so that
   ; the interpolated z4=U*z1+V*z2+W*z3
   (SETQ anum (FLOAT (+ (* x1 (- y4 y3)) (* x3 (- y1 y4)) (* x4 (- y3 y1))))
         aden (FLOAT(+ (* x1 (- y3 y2)) (* x2 (- y1 y3)) (* x3 (- y2 y1))))
         bnum (FLOAT (+ (* x1 (- y4 y2)) (* x2 (- y1 y4)) (* x4 (- y2 y1))))
         bden (FLOAT (+ (* x1 (- y3 y2)) (* x2 (- y1 y3)) (* x3 (- y2 y1)))))
   (IF (< (ABS aden) 0.0001) (SETQ aden 0.0001))
   (IF (< (ABS bden) 0.0001) (SETQ bden 0.0001))
   (SETQ a (- (/ anum aden)) b (/ bnum bden))
   (LIST (- 1 a b) a b)
)

(DEFUN linpdist (p1 p2 target / x1 y1 x2 y2 px py dx dy l2 )
   ; Returns the distance from the point px,py to the infinite line
   ; passing through the line line x1,y1-x2,y2
   (SETQ x1 (CAR p1) y1 (CADR p1) x2 (CAR p2) y2 (CADR p2) px (CAR target) py (CADR target))
   (SETQ dx (- x2 x1) dy (- y2 y1))
   (SETQ l2 (FLOAT (+ (* dx dx) (* dy dy))))

   (IF (< (ABS l2) 0.00001) ; very short line, return distance to startpoint instead
     (DISTANCE (LIST x1 y1) (LIST px py))
       (ABS
         (*
           (/ (- (* (- y1 py) (- x2 x1)) (* (- x1 px) (- y2 y1))) l2)
           (SQRT l2))))
)

(DEFUN linpparam (p1 p2 target / x1 y1 x2 y2 px py dx dy l2 fact res)
   (SETQ x1 (CAR p1) y1 (CADR p1) x2 (CAR p2) y2 (CADR p2) px (CAR target) py (CADR target))
   ; returns the parameter of point px,py on the line x1,y1-x2,y2
   ; If the point is not on the line, the closest point on the line is used.
   ; This function return a parameter between 0.0-1.0 if the point is on the line segment,
   ; but it can return any number if the point is outside the segment.

   (SETQ dx (- x2 x1) dy (- y2 y1))
   (SETQ l2 (FLOAT (+ (* dx dx) (* dy dy))))
   (SETQ fact (IF (< (ABS l2) 0.00001) 0.0 (/ (- (* (- y1 py) (- y1 y2)) (* (- x1 px) (- x2 x1))) l2)))
   (SETQ res (LIST (- 1 fact) fact 0))
   res
)

(DEFUN triarea (p1 p2 p3 / l1 v3 v2 v h tl1 tl2) ; Returns the area of a rectangle
  (SETQ l1 (DISTANCE p1 p2))
  (SETQ l2 (LINPDIST p1 p2 p3))
  (* l1 l2 0.5)
)

(DEFUN zdef (z) ; This function will adjust Z-axis to correct values according to the settings.
  (COND
    ((AND *3D-5X* (= pp_zmode 6) (MEMBER *ZSensoringmode* (LIST 0 1))) ; When using height sensor sheetwise or partwice set zero at surface
      (SETQ z (- z *Thickness*)))
    (*3D-5X*
      (SETQ z (+ (- z pp_zmoved) *Zstandoff*))) ; Always zero at table if the job has a 3D-5X part. pp_zmoved is the origo of Z
    ((= *ZBase* 0) ; Zero at table
      (SETQ z (+ z *ZStandoff*)))
    ((= *ZBase* 1) ; Zero at surface on 2D-parts
      (SETQ z (- z *Thickness*)))
    ((= *ZBase* 2) ; At the top
      (SETQ z (- (- *ZMaxMovement* (+ z *ZStandoff*)))))
  )
  (IF (> z pp_zmaxup) pp_zmaxup z) ; pp_zmaxup it the highest value the tool can get in coordinates, its specified in Initialization
)

(DEFUN tanksafe (x y vec / nvec xtmp ytmp)
  (SETQ xtmp x ytmp y)
  (IF (AND *DangerZoneUse* *DangerJetLength* vec)
    (PROGN
      (SETQ nvec (NORMALIZE vec))
      (SETQ xtmp (+ x (* (CAR nvec) *DangerJetLength*)))
      (SETQ ytmp (+ y (* (CADR nvec) *DangerJetLength*)))))
      ;(CAD-CIRCLE (LIST xtmp ytmp) 2)
      ;(CAD-LINE (LIST x y) (LIST xtmp ytmp))
      ;(CAD-REGEN)
  (IF (< xtmp pp_xdmin) (SETQ pp_xdmin xtmp))
  (IF (> xtmp pp_xdmax) (SETQ pp_xdmax xtmp))
  (IF (< ytmp pp_ydmin) (SETQ pp_ydmin ytmp))
  (IF (> ytmp pp_ydmax) (SETQ pp_ydmax ytmp))
)

(DEFUN defvars (/ tmpx tmpy tmpi tmpj tmpf mmpsek ffac tmpxx tmpyy asek bsek dsek pp_$x pp_$y pp_$i pp_$j nvec pp_fs pp_fe)
  (IF funis (WRITE "DEFVARS"))
  (SETQ $xraw pp_$x $yraw pp_$y)
  (SETQ pp_$x (- pp_$x pp_xmod) pp_$y (- pp_$y pp_ymod)) ; how much the point must be moved because the equipment is offseted from the tool
  (IF pp_$i (SETQ pp_$i (- pp_$i pp_xmod) pp_$j (- pp_$j pp_ymod))) ; must be local
  (IF (AND (NOT (= $mode 0)) pp_kdtree)
    (SETQ pp_kdtreelist (KDTREE-FINDCLOSEST pp_kdtree (LIST pp_$x pp_$y) (* *ZMeasureDist* 2) 3)) (SETQ pp_kdtreelist nil $zreftype nil))
  (IF (AND pp_kdtreelist (NOT (= $mode 0)))
    (PROGN
      (SETQ $zrefs nil)
      (SETQ kd0 (LIST pp_$x pp_$y))
      (SETQ kd1 (CAR pp_kdtreelist))
      (SETQ kd2 (CADR pp_kdtreelist))
      (SETQ kd3 (CADDR pp_kdtreelist))
      (SETQ $zref (CADDAR pp_kdtreelist)) ; Third element in first list
      ;$zreftype: ;0=One point should be used
                  ;1=Two closest measuring points are inline with target point
                  ;2=Using tree measuring points, the target are outside the triangle
                  ;3=Using tree measuring points, the target are outside the triangle
      ;
      (COND
        ((= (LENGTH pp_kdtreelist) 3)
          (SETQ facts (TINTFACS kd1 kd2 kd3 (LIST pp_$x pp_$y)))
          (IF (OR (> (MAX (ABS (CAR facts)) (ABS (CADR facts)) (ABS (CADDR facts))) 4.0) (EQUAL facts (LIST 1.0 0.0 0.0) 0.0000001))
            (PROGN
              (SETQ facts (LINPPARAM kd1 kd2 (LIST pp_$x pp_$y)) intri nil $zreftype 1)
              (SETQ $zreftype 1)
              (SETQ $zrefs (LIST (CADDR kd1) (CAR facts) (CADDR kd2) (CADR facts))))
            (PROGN
              (SETQ intri (INTRIANGLE kd1 kd2 kd3 (LIST pp_$x pp_$y)))
              (SETQ $zreftype (IF intri 3 2))
              (IF (NOT (EQUAL (+ (CAR facts) (CADR facts) (CADDR facts)) 1.0 0.001)) (ALERT (STRCAT "FACTS:" (TOSTR facts))))
              (SETQ $zrefs (LIST (CADDR kd1) (CAR facts) (CADDR kd2) (CADR facts) (CADDR kd3) (CADDR facts))))))
        ((= (LENGTH pp_kdtreelist) 2)
          (SETQ $zreftype 1)
          (SETQ facts (LINPPARAM kd1 kd2 (LIST pp_$x pp_$y)))
          (SETQ $zrefs (LIST (CADDR kd1) (CAR facts) (CADDR kd2) (CADR facts))))
        ((= (LENGTH pp_kdtreelist) 1)
          (SETQ $zreftype 0)
          (SETQ $zrefs (LIST (CADDR kd1))))
      )
    )
  )
  (COND
    (ispiercing nil)
    ((NOT *corrangle*) nil)
    ((NOT pp_ab) nil)
    ((= gtype 1)
      (SETQ corrp1 (POLAR (LIST 0 0) (+ *corrangle* (CAR pp_ab) PI) *corrdist*)) ; calculate a point rotated by the major axis
      (SETQ corrp2 (POLAR (LIST 0 0) *corrangle* *corrdist*)) ; calculate a point that always should be added.
      (SETQ pp_$x (+ pp_$x (CAR corrp1) (CAR corrp2)) pp_$y (+ pp_$y (+ (CADR corrp1) (CADR corrp2)))))
  )
  ;(IF (AND *DangerZoneUse* *DangerJetLength*)
  ;  (PROGN
  ;    (IF (< pp_$x pp_xmin) (SETQ pp_xmin pp_$x))
  ;    (IF (> pp_$x pp_xmax) (SETQ pp_xmax pp_$x))
  ;    (IF (< pp_$y pp_ymin) (SETQ pp_ymin pp_$y))
  ;    (IF (> pp_$y pp_ymax) (SETQ pp_ymax pp_$y))
  ;    (IF pp_$vec
  ;      (PROGN
  ;        (SETQ nvec (NORMALIZE pp_$vec))
  ;        (SETQ xtmp (+ pp_$x (* (CAR nvec) *DangerJetLength*)))
  ;        (SETQ ytmp (+ pp_$y (* (CADR nvec) *DangerJetLength*)))
  ;        (CAD-CIRCLE (LIST xtmp ytmp) 2)
  ;        (CAD-REGEN)
  ;        (IF (< xtmp pp_xdmin) (SETQ pp_xdmin xtmp))
  ;        (IF (> xtmp pp_xdmax) (SETQ pp_xdmax xtmp))
  ;        (IF (< ytmp pp_ydmin) (SETQ pp_ydmin ytmp))
  ;        (IF (> ytmp pp_ydmax) (SETQ pp_ydmax ytmp)))
  ;    )
  ;  )
  ;)
  (SETQ $x pp_$x $y pp_$y $i pp_$i $j pp_$j $CCW pp_ccw)
  ; Handlin Z-values
  (IF *Tubemode*
    (PROGN
      (IF (NOT *TubeAddZ*) (SETQ *TubeAddZ* 0))
      (IF pp_z (SETQ $z (+ pp_z *TubeAddZ* *ZStandoff*))))
    (PROGN
      (SETQ $z (ZDEF pp_zmaster)))
  )


  (SETQ $xm pp_$xm $ym pp_$ym) ; To support robot syntax
  (IF pp_$radie (SETQ $r pp_$radie))
  (SETQ $iabs pp_$i $jabs pp_$j)
  (SETQ $irel pp_$di $jrel pp_$dj)
  (SETQ $flag pp_flag)
  (SETQ $delta pp_delta)
  (IF (NOT $flag) (SETQ $flag 0))
  (IF (NOT $len) (SETQ $len 100))
  (IF *IncrementalCircleCenter* (SETQ $I pp_$di $J pp_$dj))
  (IF pp_$vec (SETQ $vector (NORMALIZE pp_$vec)))
  (SETQ $vec $vector)
  (IF (AND *AWJTACRough* pp_tacperfeed $rough pp_fe) ; This calculation is also done in the TRANSVEC function
    (SETQ $tac (/ (* (- (ABS *AWJTACRough*) (* (- $rough pp_fe) (ABS pp_tacperfeed))) PI) 180))
    (SETQ $tac 0.0)
  )
  (SETQ ffac 1.0) ;Feed factor om A eller B behöver ha mera tid
  (SETQ rotinfostr "")
  (SETQ maxsek nil)
  (IF pp_ab
    (PROGN
      ;(WRITE (STRCAT "DEFVAR pp_abold:" (TOSTR pp_abold)))
      (IF (NOT pp_abold) (SETQ pp_abold (LIST 0 0)))
      (IF (NOT $len) (SETQ $len 1000))
      (SETQ $arel (- (CAR pp_ab) (CAR pp_abold)))
      (SETQ $brel (- (CADR pp_ab)(CADR pp_abold)))
      (IF *HeadPrimaryReversed* (SETQ $arel (- $arel)))
      (IF *HeadSecondaryReversed* (SETQ $brel (- $brel)))
      ;(WRITE (STRCAT "AREL:" (ATS $arel) " BREL:" (ATS $brel)))
      ; Calculate the factor ffac to slow down the XY speed to not overspeed A and/or B
      (SETQ asek (/ (ABS $arel) *HeadPrimaryMaxSpeed*)) ;time in seconds for A (all rotation values are in radians)
      (SETQ bsek (/ (ABS $brel) *HeadSecondaryMaxSpeed*)) ; time in seconds for B (all rotation values are in radians)
      ;(SETQ rotinfostr (STRCAT "Needed rotation time:" (RTOS (MAX asek bsek) 6) "sec" )) ;I have double checked this values and it seems to ne 100% OK 2015.12.18
      ; Finish
      (SETQ maxsek (MAX asek bsek))
      (SETQ $a (CAR pp_ab) $b (CADR pp_ab))
      (SETQ $amotor $a $bmotor $b)
      (IF (NOT pp_ahead) (SETQ pp_ahead 0))
      (SETQ $ahead pp_ahead)
      (IF (NOT pp_realslope) (SETQ pp_realslope $slope))
      (IF *TiltForwardMin* (SETQ $slope pp_realslope))
      (COND
        ; $kinematic 0=No 5X
        ; $kinematic 1=Motor axis
        ((= $kinematic 2) ; Direction of cut
          (COND
            ((EQUAL $slope 0.0 0.001)
              (SETQ $b $slope))
            ((MINUSP $b)
              (SETQ $a (- (+ $a pp_ahead) PIH))
              (SETQ $b (- (ABS $slope))))
            (T
              (SETQ $a (+ (- $a pp_ahead) PIH))
              (SETQ $b (ABS $slope)))))
        ((AND (= $kinematic 3) *dafa*) ; Direction of jet
          (COND
            ((MINUSP $b)
              (SETQ $a (ANGLE (LIST 0.0 0.0) $vec))
              (SETQ $b (ABS $slope)))
            (T
              (SETQ $a (+ (ANGLE (LIST 0.0 0.0) $vec) PI)) ; var minus
              (SETQ $b (- (ABS $slope))))))
        ((= $kinematic 3) ; Direction of jet as it has been done for many versions
          (COND
            ((MINUSP $b)
              (SETQ $a (+ $a pp_ahead))
              (SETQ $b (- (ABS $slope))))
            (T
              (SETQ $a (- $a pp_ahead)) ; var minus
              (SETQ $b (- (ABS $slope))))))
      )
      (IF (AND (NOT *TiltForwardMin*) pp_vertical) (SETQ $b 0.0))
      (IF *HeadPrimaryReversed* (SETQ $a (- $a)))
      (IF *HeadSecondaryReversed* (SETQ $b (- $b)))
      (SETQ pp_abold pp_ab)
    )
  )

  (IF *SixAxisReverseRotation*
    (SETQ $c (- pp_$c) $crel (- pp_$crel))
    (SETQ $c pp_$c $crel pp_$crel)
  )
  ; ***************** Handling all speeds **************
  (IF pp_fe
    (PROGN
      (IF (> pp_fe *SpeedMaxCutting*) (SETQ pp_fe *SpeedMaxCutting*))
      (IF (> pp_fs *SpeedMaxCutting*) (SETQ pp_fe *SpeedMaxCutting*))))
  ;(IF maxsek (WRITE (STRCAT "AREL:" (ATS $arel) " BREL:" (ATS $brel))))
  (IF maxsek ; is onlt T in 5X cutting
    (COND
      ((AND pp_fe (> maxsek 0))
        (SETQ dsek (* (/ $len pp_fe) 60)) ;time in seconds for the XY movement
        (SETQ ffac (IF (> dsek 0) (/ maxsek dsek) 1.0))
        (IF (> ffac 1.0)
          (PROGN
            (SETQ innan pp_fe)
            (SETQ pp_fe (/ pp_fe ffac))
            (IF (> pp_fs pp_fe) (SETQ pp_fs pp_fe)))))
      ((AND pp_ft (> maxsek 0))
        (SETQ ffac (/ pp_ft maxsek))
        (IF (> ffac 1.0)
          (PROGN
            (SETQ pp_tf (/ pp_ft ffac))))
      )
    )
  )
  (IF pp_fe
    (PROGN
      (SETQ pp_fe (* pp_fe *WaterSpeedFactor*) pp_fs (* pp_fs *WaterSpeedFactor*))
      (IF (< pp_fe *SpeedMinCutting*) (SETQ pp_fe *SpeedMinCutting*))
      (IF (< pp_fs *SpeedMinCutting*) (SETQ pp_fe *SpeedMinCutting*))
      (SETQ $fe pp_fe $f $fe $fs pp_fs)))
  (COND
    ((AND (= *MachineType* 2) (= 1 2)) ; If it's Plasma cutting
      (IF pp_isleadin (SETQ tmpf *PlasmaLeadinSpeed*) (SETQ tmpf *PlasmaCuttingSpeed*))
      (IF pp_fs (SETQ $fs (* tmpf $fs 0.01)))
      (IF pp_fe (PROGN (SETQ $fe (* tmpf $fe 0.01)) (SETQ $f $fe))))
  )
  (IF (< $fs *SpeedMinCutting*) (SETQ $fs *SpeedMinCutting*))
  (IF (< $fe *SpeedMinCutting*) (SETQ $fe *SpeedMinCutting*))
  (IF (< $f *SpeedMinCutting*) (SETQ $f *SpeedMinCutting*))

  (IF (AND (< pp_maxslope *HeadMinTilt*) (OR (= *Headtype* 1) (= *Headtype* 2))) (SETQ $ab nil))
  (IF (AND (> *Headtype* 0) pp_bevelmarking) (SETQ $ab T))
  (SETQ xraw $xraw yraw $yraw)
  (IF (>= *Axisdirection* 4)
    (PROGN
      (SETQ tmpx $X tmpy $Y tmpi $I tmpj $J)
      (SETQ $X $Y $I $J)
      (SETQ $Y tmpx $J tmpi)
      (SETQ $xm pp_$ym $ym pp_$xm)
      (SETQ tmpi $irel tmpj $jrel)
      (SETQ $irel tmpj $jrel tmpi)
      (SETQ tmpi $iabs tmpj $jabs)
      (SETQ $iabs tmpj $jabs tmpi)
      (SETQ $xraw yraw $yraw xraw))
  )
  (COND
    ((= *AxisDirection* 0) nil) ; No changes
    ((= *AxisDirection* 1)      ; X is mirrored
      (SETQ $CCW (IF $CCW nil T))
      (IF $X (SETQ $X (- $X)))
      (IF $I (SETQ $I (- $I)))
      (IF $xm (SETQ $xm (- $xm)))
      (IF $irel (SETQ $irel (- $irel)))
      (IF $iabs (SETQ $iabs (- $iabs)))
      (SETQ $xraw (- $xraw)))
    ((= *AxisDirection* 2)      ; Y is mirrored
      (SETQ $CCW (IF $CCW nil T))
      (IF $Y (SETQ $Y (- $Y)))
      (IF $J (SETQ $J (- $J)))
      (IF $ym (SETQ $ym (- $ym)))
      (IF $yy (SETQ $yy (- $yy)))
      (IF $jrel (SETQ $jrel (- $jrel)))
      (IF $jabs (SETQ $jabs (- $jabs)))
      (SETQ $yraw (- $yraw)))
    ((= *AxisDirection* 3)      ; X and Y is mirrored
      (IF $X (SETQ $X (- $X)))
      (IF $I (SETQ $I (- $I)))
      (IF $Y (SETQ $Y (- $Y)))
      (IF $J (SETQ $J (- $J)))
      (IF $xm (SETQ $xm (- $xm)))
      (IF $ym (SETQ $ym (- $ym)))
      (IF $yy (SETQ $yy (- $yy)))
      (IF $irel (SETQ $irel (- $irel)))
      (IF $iabs (SETQ $iabs (- $iabs)))
      (IF $jrel (SETQ $jrel (- $jrel)))
      (IF $jabs (SETQ $jabs (- $jabs)))
      (SETQ $xraw (- $xraw))
      (SETQ $yraw (- $yraw)))
    ; All cases below are already swaped
    ((= *AxisDirection* 4)
      (SETQ $CCW (IF $CCW nil T)))
    ((= *AxisDirection* 5)     ;Y mirror
      (IF $Y (SETQ $Y (- $Y)))
      (IF $J (SETQ $J (- $J)))
      (IF $ym (SETQ $ym (- $ym)))
      (IF $yy (SETQ $yy (- $yy)))
      (IF $jrel (SETQ $jrel (- $jrel)))
      (IF $jabs (SETQ $jabs (- $jabs)))
      (SETQ $yraw (- $yraw)))

    ((= *AxisDirection* 6)     ;Rotated Left Hand Rule (X is mirrored)
      (IF $X (SETQ $X (- $X)))
      (IF $I (SETQ $I (- $I)))
      (IF $xm (SETQ $xm (- $xm)))
      (IF $irel (SETQ $irel (- $irel)))
      (IF $iabs (SETQ $iabs (- $iabs)))
      (SETQ $xraw (- $xraw)))
    ((= *AxisDirection* 7)     ;X and Y mirror
      (SETQ $CCW (IF $CCW nil T))
      (IF $X (SETQ $X (- $X)))
      (IF $I (SETQ $I (- $I)))
      (IF $Y (SETQ $Y (- $Y)))
      (IF $J (SETQ $J (- $J)))
      (IF $xm (SETQ $xm (- $xm)))
      (IF $ym (SETQ $ym (- $ym)))
      (IF $yy (SETQ $yy (- $yy)))
      (IF $irel (SETQ $irel (- $irel)))
      (IF $iabs (SETQ $iabs (- $iabs)))
      (IF $jrel (SETQ $jrel (- $jrel)))
      (IF $jabs (SETQ $jabs (- $jabs)))
      (SETQ $xraw (- $xraw))
      (SETQ $yraw (- $yraw)))
  )
  (IF *AxisSwapG2G3*
    (SETQ $ccw (IF pp_ccw nil T)))
)

(DEFUN normalize (vec / len)
  (SETQ len (DISTANCE (LIST 0 0 0) vec))
  (COND
    ((EQUAL len 1.0 0.001) vec) ; returns the vector unchanged
    ((< len 0.01) (QUIT (ALERT "VECTOR CORRUPT")))
    (T
      (LIST (/ (CAR vec) len) (/ (CADR vec) len) (/ (CADDR vec) len)))
  )
)

(DEFUN circ-piercing (/ pp_x pp_y pp_comp pp_ptype pp_qua pp_clen pp_geoarea pp_geolen pp_leadname pp_nodename
                              pp_inside pp_starttan pp_mintan pp_maxtan pp_xstart pp_ystart pp_ystart pp_side pp_fs
                              pp_fe svtrans pt pp_endp pp_startp pp_oldp omkrets tocut varv svvars pp_vec xx yy rr xv yv zv x1 x2 x3 x4 y1 y2 y3 y4
                              z1 z2 z3 speed diameter stv radtocut segq sega pt)
  (IF *CustomCircularPiercing* (SETQ pp_skipout T) (SETQ pp_skipout nil))
  ;(WRITE "CIRCULAR-PIERCING STARTS")
  ; pp_Skipout: Control if CNC-information should be added or not. If T only simulation
  (IF (NOT pp_leadplan) (SETQ pp_leadplan (LIST 0 0 -1)))
  (IF (NOT (MINUSP (CADDR pp_leadplan))) (SETQ pp_leadplan (LIST (- (CAR pp_leadplan)) (- (CADR pp_leadplan)) (- (CADDR pp_leadplan)))))
  (SETQ xx (CAR pp_$oldp) yy (CADR pp_$oldp) zz (CADDR pp_$oldp))
  (SETQ pp_oldp pp_$oldp)
  (SETQ svtrans trans svvars vars)
  (DEFUN trans (x y z) (LIST x y z))
  (IF (= *MachineType* 0) ; AWJ machine
    (PROGN
      (SETQ speed *AWJCircularPiercingSpeed*)
      (SETQ diameter *AWJCircularPiercingDiameter*))
    (PROGN
      (SETQ speed 200)
      (SETQ diameter *WaterPiercingDiameter*)
      (SETQ $time *WaterPiercingTime*)))
  (SETQ omkrets (* diameter PI))
  (SETQ tocut (* (/ speed 60.0) $time))
  (SETQ varv (/ tocut omkrets)) ; Totaly number of turns to pierce
  (IF (< varv 1) (SETQ varv 1.0))
  (SETQ radtocut (* varv PID)) ; Totaly angle to pierce
  (SETQ segq (CEIL (/ radtocut *LargestSegmentAngle*))) ; Number of LargestSegmentAngle to cut
  (SETQ sega (/ radtocut segq)) ; Segmentangle to cut
  (SETQ stv 0)
  (IF (EQUAL pp_leadplan (LIST 0 0 -1))
    (PROGN
      ($LINE (LIST (+ xx (* diameter 0.5)) yy pp_z 8 speed speed hPI pp_vec pp_cutdirection pp_crot))
      (REPEAT segq
        (SETQ pt (POLAR (LIST xx yy) (SETQ stv (+ stv sega)) (* diameter 0.5)))
        ($ARC (LIST (CAR pt) (CADR pt) pp_z xx yy T 8 speed speed 0 pp_vec pp_cutdirection))
      )
      ($LINE (LIST xx yy pp_z 8 speed speed)))
    (PROGN
      (SETQ rr (* diameter 0.5))
      (SETQ xv (CAR pp_leadplan) yv (CADR pp_leadplan) zv (CADDR pp_leadplan))
      (SETQ x1 (* rr (SQRT (- 1.0 (* xv xv)))))
      (SETQ y1 0.0)
      (SETQ z1 (* rr xv))

      (SETQ x2 0.0)
      (SETQ y2 (* rr (SQRT (- 1.0 (* yv yv)))))
      (SETQ z2 (* rr yv))

      (SETQ x3 (- x1))
      (SETQ y3 0.0)
      (SETQ z3 (- z1))

      (SETQ x4 0.0)
      (SETQ y4 (- y2))
      (SETQ z4 (- z2))
      ($LINE (LIST (+ xx x1) (+ yy y1) (+ zz z1) 8 speed speed 2.35619 pp_vec 0.0))
      (REPEAT (CEIL varv)
        ($LINE (LIST (+ xx x2) (+ yy y2) (+ zz z2) 8 speed speed hPI pp_vec 2.35619))
        ($LINE (LIST (+ xx x3) (+ yy y3) (+ zz z3) 8 speed speed hPI pp_vec 2.35619))
        ($LINE (LIST (+ xx x4) (+ yy y4) (+ zz z4) 8 speed speed hPI pp_vec 2.35619))
        ($LINE (LIST (+ xx x1) (+ yy y1) (+ zz z1) 8 speed speed hPI pp_vec 2.35619))
      )
      ($LINE (LIST xx yy zz 8 speed speed hPI pp_vec pp_cutdirection))
    )
  )
  (SETQ pp_skipout nil)
  (SETQ trans svtrans)
  ;(WRITE "CIRCULAR-PIERCING ENDS")

)

(DEFUN ntxt()
  (IF *UseLineNumbers*
    (PROGN
      (SETQ $ncount *Linenumberstart*)
      (SETQ *LineNumberStart* (+ *LineNumberStart* *LineNumberIncrement*)) ; $nadd sätts i FIXVARS
      (SETQ $nnext *LineNumberStart*)
      (STRCAT "N" (ITOA $ncount) " ")) "")
)


(DEFUN rts (value / txt)
  (IF pp_inchout (SETQ value (* value 0.039370078)))
  (SETQ txt (RTOS value *DecimalsMovement* (IF *SupressTrailingZeroes* nil T)))
  (IF (AND (NOT *SupressTrailingDots*) *SupressTrailingZeroes*)
    (IF (= (ATOF txt) (ATOI txt)) (SETQ txt (STRCAT txt "."))))
  txt
)

(DEFUN ats (value / txt)
  (SETQ txt (RTOS (RADTODEG value) *DecimalsAngle* (IF *SupressTrailingZeroes* nil T)))
  (IF (AND (NOT *SupressTrailingDots*) *SupressTrailingZeroes*)
     (IF (= (ATOF txt) (ATOI txt)) (SETQ txt (STRCAT txt "."))))
  txt
)

(DEFUN rtt (value / txt)
  (RTOS value *DecimalsDelay* (IF *SupressTrailingZeroes* nil T))
)

(DEFUN rtp (value / txt)
  (IF (NOT *DecimalsCost*) (SETQ *DecimalsCost* 2))
  (RTOS value *DecimalsCost* nil)
)

(DEFUN rtf (value / txt)
  (IF pp_inchout (SETQ value (* value 0.039370078)))
  (RTOS value *DecimalsSpeed* (IF *SupressTrailingZeroes* nil T))
)


(DEFUN msg (txt)
  (IF *AddComments* (STRCAT " " txt) "")
)

(DEFUN rti (value)
  (IF (= (TYPE value) 'INT) (ITOA value) (RTOS value 0))
)

(DEFUN write (txt)
  ; (SETQ shownext 2000) is in the beginning of IGEMS.LSP
  ;(IF (NOT timestart) (SETQ timestart (TIMENOW)))
  (COND
    ((= *ProcessMode* -1) T) ; Option for skip add to file
    ((= *ProcessMode* 0) T) ; Option for Cost estimate
    ((= *ProcessMode* 1) T) ; Option for Report
    ((= *ProcessMode* 2)      ; Option for 2D Simulations
      (SIM-INFOTEXT txt))
    ((= *Processmode* 3)
      (IF $wfile (WRITE-LINE txt $wfile))
      (SETQ wline (1+ wline))
      (COND
        ((AND *ViewOutputFile* (< wline 1000)) (PRINC (STRCAT txt "\n")))
        ((= wline 1000) (PRINC "\n\n      ****** Stop viewing file ******\n\n"))
        ((= wline shownext)
          ;(SETQ timeend (TIMENOW))
          (PRINC (STRCAT "\nDone " (ITOA shownext) " lines"))
          (SETQ shownext (+ shownext 5000))
          (WINBREATH)
          T)))

    ((= *Processmode* 4) ; Option for 3D Simulations
      (SIM-INFOTEXT txt))
  )
)

; --------------------------------- Drilling unit ----------------------------

(DEFUN $drilling-begin ()
  (FUNBROWSER "DRILLING BEGIN")
  (SETQ pp_muldpos nil pp_alldpos nil)
  (SETQ addlist nil)
  ;(WRITE (STRCAT "\n\n****** " (TOSTR pp_tooldata) " ******"))
  (IF pp_tooldata (SETQ pp_savedtooldata pp_tooldata))
  (SETQ pp_mode 1)
  (IF (AND (OR (= *DrillbyType* 2) (= *DrillbyType* 3)) pp_partdata) ; 2=Partwise, 3=No optimazion
    ($PART pp_partdata))
  ($CHMODE)
  (SETQ drilling-flag 1)
  (SETQ $drillnum 0)
)

; this function add a value to the drilling position if it's a goust part
; Decription See $DRILLING

(DEFUN $CalcDPos (add / pp_xoffset pp_yoffset pt x y)
  (SETQ pp_xoffset 0 pp_yoffset 0)
  (SETQ pt (TRANS pp_x pp_y pp_z)) ; Transed without tool ofset
  (SETQ x (CAR pt) y (CADR pt))
  (IF (NOT pp_firstdist) (SETQ pp_firstdist add))
  (SETQ add (- add pp_firstdist))
  (COND
    ((= *BarAligned* 0) (SETQ x (+ x add)))
    ((= *BarAligned* 1) (SETQ x (- x add)))
    ((= *BarAligned* 2) (SETQ y (+ y add)))
    ((= *BarAligned* 3) (SETQ y (- y add)))
    (T (ALERT "Strange value of *BarAligned* in $CalcDPos"))
  )

  ;(CAD-CIRCLE pt 10)
  (SETQ pp_alldpos (CONS (LIST x y pp_z pp_holedia pp_attrib pp_depth pp_dinit) pp_alldpos))
)

; this function collect points that will be sorted and evaluated in $Drilling-end
; All positions are global coordinates for each hole on the drawing.
; Since only one tool are in use, the offset for this tool are the same for all holes
(DEFUN $drilling (vars / pp_x pp_y pp_z pt)
  (FUNBROWSER "$DRILLING")
  (IF measure-flag ($MEASURE-END))
  (IF ppiercing-flag  ($PPIERCING-END))
  (IF marking-flag ($MARKING-END))
  (IF cutting-flag ($CUTTING-END))
  (IF (NOT drilling-flag) ($DRILLING-BEGIN))
  (IF *DrillingOnFirst* ; If machine has only one drilling tool
    (PROGN
      (IF pp_tooldata ; we should not change tool, we just collect positions from gousts
        (PROGN
          (SETQ pp_goustuse (CAR pp_tooldata))
          (SETQ pp_goustdist (CADR pp_tooldata))))
      (SETQ pp_tooldata nil)
      (SETQ bitlist nil)
      (SETQ pp_x (NTH 0 vars) pp_y (NTH 1 vars) pp_z (NTH 2 vars) pp_holedia (NTH 3 vars) pp_attrib (NTH 4 vars) pp_depth (NTH 5 vars))

      (SETQ pp_muldpos (CONS (LIST pp_x pp_y pp_z pp_holedia pp_attrib pp_depth pp_dinit) pp_muldpos))
      (SETQ pp_firstdist nil)
      (IF (NOT pp_goustuse)
        (SETQ pp_goustuse $tools pp_goustdist $tooldistance))
      (IF (> (LOGAND 1 pp_goustuse) 0) ($CalcDPos 0))
      (IF (> (LOGAND 2 pp_goustuse) 0) ($CalcDPos pp_goustdist))
      (IF (> (LOGAND 4 pp_goustuse) 0) ($CalcDPos (* pp_goustdist 2)))
      (IF (> (LOGAND 8 pp_goustuse) 0) ($CalcDPos (* pp_goustdist 3)))
      (IF (> (LOGAND 16 pp_goustuse) 0) ($CalcDPos (* pp_goustdist 4)))
      (IF (> (LOGAND 32 pp_goustuse) 0) ($CalcDPos (* pp_goustdist 5)))
      (IF (> (LOGAND 64 pp_goustuse) 0) ($CalcDPos (* pp_goustdist 6)))
      (IF (> (LOGAND 128 pp_goustuse) 0) ($CalcDPos (* pp_goustdist 7))))

    (PROGN ; If drilling tools are located on every jet
      (COND
        (*DrillingOffsetByController*
          (SETQ pp_xmod 0.0 pp_ymod 0.0) ; No addition in CNC
          (SETQ pp_xmodsim *DrillingXOffset* pp_ymodsim *DrillingYOffset*)) ; Addition in Simulation
        (T
          (SETQ pp_xmod *DrillingXOffset* pp_ymod *DrillingYOffset*) ; Addition in simulation
          (SETQ pp_xmodsim *DrillingXOffset* pp_ymodsim *DrillingYOffset*))
      )
      (IF pp_tooldata ($TOOLSET pp_tooldata))
      (SSIM-TOOLSET pp_toolused pp_toollist *ToolMovingSpeed*)
      (SETQ pp_x (NTH 0 vars) pp_y (NTH 1 vars) pp_z (NTH 2 vars) pp_holedia (NTH 3 vars) pp_attrib (NTH 4 vars) pp_depth (NTH 5 vars))
      (SETQ $holediameter (* pp_holedia 2.0))
      ;(SETQ pp_$x (+ pp_$x pp_xoffset) pp_$y (+ pp_$y pp_yoffset)) ; VAR REMARKER *************************
      (SETQ pt (TRANS pp_x pp_y pp_z))
      (SETQ pp_$x (CAR pt) pp_$y (CADR pt))
      (SETQ $reason 3)
      (DEFVARS)
      (SSIM-RAPID pp_$x pp_$y pp_zmaster *SpeedRapid* *SpeedAcceleration* 0)
      (RAPID)
      (SETQ $reason reason)
      (IF (NOT (EQUAL pp_z pp_zclear 0.1)) (SETQ *DrillLiftZ* T))
      (SETQ pp_zmaster pp_z)
      ($TOOLDOWN 1) ; This line has the argument 2 that was wrong. Please check STM and Resato
      (SIM-DRILL 1 pp_zmaster *Drillingspeed* *DrillDiameter* *DrillingExtraDelay*);
      (SETQ $f *DrillingSpeed*)
      (DRILLING)
      (SETQ $drillnum (1+ $drillnum))
      (SIM-OFF)
      ($TOOLUP 1) ; Sets pp_zmaster internally
    )
  )
)

(DEFUN drilling ()
  nil
)


(DEFUN $DRILLING-END (/ pos s pp_$x pp_$y reason xadd yadd drillingxoffset drillingyoffset pp_cinit)
  ; pp_?mod and pp_&xmodsim is handling the internal offset between the nozzle and the center of the drilling equipment.
  (FUNBROWSER "$DRILLING-END STARTS")
  ; This set up the tools one time before the drilling starts.
  (IF *DrillingOnFirst* ; This means only one drill located on optional jet
    (PROGN
      (COND
        (*DrillingOffsetByController*
          (SETQ pp_xmod 0.0 pp_ymod 0.0) ; No addition in CNC
          (SETQ pp_xmodsim *DrillingXOffset* pp_ymodsim *DrillingYOffset*)) ; Addition in Simulation
        (T
          (SETQ pp_xmod *DrillingXOffset* pp_ymod *DrillingYOffset*) ; Addition in simulation
          (SETQ pp_xmodsim *DrillingXOffset* pp_ymodsim *DrillingYOffset*))
      )
      (SETQ pp_tooldata (LIST (ONETOBIT *DrillingOnTool*) (CADR pp_tooldata) (CADDR pp_tooldata) *BarAligned*));new
      ($TOOLSET pp_tooldata)
      (SSIM-TOOLSET (ONETOBIT *DrillingOnTool*) pp_toollist *ToolMovingSpeed*)
      (SETQ pp_drillpos pp_alldpos)
      (IF (AND (OR (= *DrillbyType* 2) (= *DrillbyType* 3)) pp_partdata) ($PART pp_partdata))
      (SETQ pos (IF *DrillingSortPos* (POINTSORT (REVERSE pp_drillpos) -1) (REVERSE pp_drillpos))) ; Sort position if no atribut are used
      ;(SETQ pos (REVERSE pos))
      (SETQ $drillmax (LENGTH pos))
      (SETQ $drillnum 1)
      (IF (= $drillbytype 0) (SETQ $initsheetwice T))
      (IF (= $drillbytype 2) (SETQ $initpartwice T))
      (FOREACH s pos
        (SETQ pp_$x (NTH 0 s) pp_$y (NTH 1 s) pp_z (NTH 2 s) pp_holedia (NTH 3 s) pp_attrib (NTH 4 s) pp_depth (NTH 5 s) pp_cinit (NTH 6 s))
        (SETQ $holediameter (* pp_holedia 2))
        (SETQ pp_$x (+ pp_$x pp_xoffset) pp_$y (+ pp_$y pp_yoffset))
        (SETQ $reason 3)
        (DEFVARS)
        (SSIM-RAPID pp_$x pp_$y pp_zmaster *SpeedRapid* *SpeedAcceleration* 0)
        (RAPID)
        (SETQ $reason reason)
        (IF (NOT (EQUAL pp_z pp_zclear 0.1)) (SETQ *DrillLiftZ* T))
        (SETQ pp_zmaster pp_z)
        ($TOOLDOWN 1) ; This line has the argument 2 that was wrong. Please check STM and Resato
        (SIM-DRILL 1 pp_zmaster *Drillingspeed* *DrillDiameter*);
        (SETQ $f *DrillingSpeed*)
        (DRILLING)
        (SETQ $drillnum (1+ $drillnum))
        (SIM-OFF)
        ($TOOLUP 1) ; Sets pp_zmaster internally
      )
      (IF pp_savedtooldata (SETQ pp_tooldata pp_savedtooldata))
      (SETQ drilling-flag nil)
    )
  )
  (FUNBROWSER "$DRILLING-END FINISH")
)

(DEFUN $chbargram (bar gram / skipbar skipgram barchk)
  (SETQ $msg "")
  (IF (= *Machinetype* 1) (SETQ bar *WaterPressure*))
  (IF (AND *SkipPressureInit* (NOT pp_actualgram))
    (SETQ pp_actualbar *AWJPressureBMS* pp_actualgram *AWJAbrasiveFlowBMS*))
  (IF (NOT pp_actualgram)(SETQ pp_actualgram 0))
  ;(IF (= gram 0) (SETQ gram pp_actualgram))
  (SETQ $bar bar $psi (FIX (* bar 14.50326)))
  (SETQ $gram gram $lbs (/ gram 453.5924))
  (SETQ $gramrel 0)
  (SETQ skipbar *SkipPressureChanges* skipgram *SkipAbrasiveFlowChanges*)
  (SETQ $init nil)
  (SETQ $variable (IF (= *AWJPumpPressureCNC* 2) T nil))
  (IF (> (LOGAND $contains 2) 0) (SETQ barchk (CONS *MarkingPressure* barchk))) ; Marking
  (IF (> (LOGAND $contains 4) 0) (SETQ barchk (CONS *PiercingPressure* barchk))) ; Pre-piercing
  (SETQ barchk (CONS *CuttingPressure* barchk))
  (SETQ barchk (CONS 'MAX barchk))
  (SETQ $high (IF (EQUAL bar (EVAL barchk) 1) T nil))
  (IF (= *Machinetype* 1) (SETQ $high T))
  (IF (AND *SerialProduction* (NOT pp_serialpressure))
    (PROGN
      (SETQ pp_serialpressure bar pp_serialgram gram)
      (SETQ pp_actualbar bar pp_actualgram gram)
    )
  )
  (COND
    ((NOT pp_actualbar) (SETQ $init T))
    ((AND (EQUAL bar pp_actualbar 1) (EQUAL gram pp_actualgram 1))
      (SETQ skipbar T skipgram T))
    (T
      (IF (EQUAL bar pp_actualbar 1) (SETQ skipbar T))
      (IF (EQUAL gram pp_actualgram 1) (SETQ skipgram T)))
  )
  (SETQ $delay 0)
  (COND
    ((NOT pp_actualbar) (SETQ $delay *AWJDelayPressureUp* $barrel bar pp_actualbar bar))
    ((> bar pp_actualbar) (SETQ $delay *AWJDelayPressureUp* $barrel (- bar pp_actualbar)))
    ((< bar pp_actualbar) (SETQ $delay *AWJDelayPressureDown* $barrel (- bar pp_actualbar)))
  )
  (IF (NOT $barrel) (SETQ $barrel bar))
  (IF (AND (MINUSP $barrel) (NOT *AWJBleedOut*)) (SETQ $reduce T) (SETQ $reduce nil))
  (IF (AND (< gram pp_actualgram) (= gram 0)) (SETQ $clean T) (SETQ $clean nil))
  (SETQ $useabr (IF (= gram 0) nil T))
  (IF (AND pp_actualgram gram) (SETQ $gramrel (- gram pp_actualgram)))
  (COND
    ((OR (AND *AWJStartPumpAuto* (= *MachineType* 1)) (AND skipbar *AWJStartPumpAuto* (NOT $chbargramused)))
      (SETQ $msg "START PUMP")
      (COND
        ((NOT *AWJPumpPressureCNC*) (SETQ $reason 1))
        (T (SETQ $reason (IF $variable 3 2)))
      )
      (SETQ $chbar nil $chgram nil)
      (CHBARGRAM))
    ((AND skipbar skipgram) nil)
    ((AND (NOT skipbar) (NOT skipgram)) ; om båda två skall sättas
      (COND
        ((AND *AWJPumpPressureCNC* *AWJAbrasiveFlowCNC*)
          (IF (AND $init *AWJStartPumpAuto*)
            (PROGN
              (SETQ $chbar T $chgram nil)
              (SETQ $msg (STRCAT "PUMP ON " (ITOA bar) " BAR"))
              (SETQ $reason (IF $variable 3 2))
              (CHBARGRAM)
              (SETQ $chbar nil $chgram T)
              (SETQ $reason 8)
              (SETQ $msg (STRCAT "GRAM:" (ITOA gram)))
              (CHBARGRAM))
            (PROGN
              (SETQ $msg (STRCAT "BAR:" (ITOA bar) " GRAM:" (ITOA gram)))
              (SETQ $chbar T $chgram T)
              (SETQ $reason (IF $variable 6 7))
              (CHBARGRAM))))
        ((AND (NOT *AWJPumpPressureCNC*) *AWJAbrasiveFlowCNC*)
          (IF (AND $init *AWJStartPumpAuto*)
            (PROGN
              (SETQ $msg (STRCAT "PUMP ON " (ITOA bar) " BAR"))
              (SETQ $chbar T $chgram nil)
              (SETQ $reason 1)
              (CHBARGRAM))
            (PROGN
              (SETQ $msg (STRCAT "BAR:" (ITOA bar)))
              (SETQ $chbar T $chgram nil)
              (SETQ $reason 11)
              (CHBARGRAM)
            )
          )
          (SETQ $msg (STRCAT "GRAM:" (ITOA gram)))
          (SETQ $chbar nil $chgram T)
          (SETQ $reason 8)
          (CHBARGRAM))
        ((AND *AWJPumpPressureCNC* (NOT *AWJAbrasiveFlowCNC*))
          (IF (AND $init *AWJStartPumpAuto*)
            (PROGN
              (SETQ $msg (STRCAT "PUMP ON " (ITOA bar) " BAR"))
              (SETQ $chbar T $chgram nil)
              (SETQ $reason (IF $variable 3 2))
              (CHBARGRAM))
            (PROGN
              (SETQ $msg (STRCAT "BAR:" (ITOA bar)))
              (SETQ $reason (IF $variable 4 5))
              (SETQ $chbar T $chgram nil)
              (CHBARGRAM)
            )
          )
          (SETQ $msg (STRCAT "GRAM:" (ITOA gram)))
          (SETQ $chbar nil $chgram T)
          (SETQ $reason 12)
          (CHBARGRAM))
        ((AND (NOT *AWJPumpPressureCNC*) (NOT *AWJAbrasiveFlowCNC*))
          (IF (AND $init *AWJStartPumpAuto*)
            (PROGN
              (SETQ $msg (STRCAT "PUMP ON " (ITOA bar) " BAR"))
              (SETQ $chbar T $chgram nil)
              (SETQ $reason 1)
              (CHBARGRAM)
              (SETQ $msg (STRCAT "GRAM:" (ITOA gram)))
              (SETQ $chbar nil $chgram T)
              (SETQ $reason 12)
              (CHBARGRAM))
            (PROGN
              (SETQ $msg (STRCAT "BAR:" (ITOA bar) " GRAM:" (ITOA gram)))
              (SETQ $chbar T $chgram T)
              (SETQ $reason 10)
              (CHBARGRAM))))
        (T (PRINC "\n\n\nUnexpected case in $CHBARGRAME\n\n\n"))
       ))
    (skipgram ; Only Pressure should be set
      (SETQ $chbar T $chgram nil)
      (SETQ $msg (STRCAT "BAR:" (ITOA bar)))
      (SETQ $gramrel 0)
      (IF $init (SETQ $msg (STRCAT "START PUMP " (ITOA $bar))))
      (COND
        ((AND $init (NOT *AWJPumpPressureCNC*))
          (SETQ $reason 1)
          (CHBARGRAM))
        ((AND $init (= *AWJPumpPressureCNC* 1))
          (SETQ $reason 2)
          (CHBARGRAM))
        ((AND $init (= *AWJPumpPressureCNC* 2))
          (SETQ $reason 3)
          (CHBARGRAM))
        ((NOT *AWJPumpPressureCNC*)
          (SETQ $reason 11)
          (CHBARGRAM))
        ($variable
          (SETQ $reason 4)
          (CHBARGRAM))
        ((NOT $variable)
          (SETQ $reason 5)
          (CHBARGRAM))
      ))
    (skipbar ; Only Abrasive flow should be set
      (SETQ $chbar nil $chgram T)
      (SETQ $gramrel (- pp_actualbar bar))
      (SETQ $msg (STRCAT "GRAM:" (ITOA gram)))
      (COND
        ((NOT *AWJAbrasiveFlowCNC*)
          (SETQ $reason 12)
          (CHBARGRAM))
        (T
          (SETQ $reason 8)
          (CHBARGRAM))
      )
    )
  )
  (SETQ pp_actualbar bar)
  (SETQ pp_actualgram gram)
  (SETQ $useabr (IF (> pp_actualgram 0) T nil))
  (SETQ $chbargramused T)
)
(DEFUN cleanAndReduce ()
  (IF *bleedpoint*
    (PROGN
      ($RAPID (LIST (CAR *bleedpoint*) (CADR *bleedpoint*) pp_zmaster nil 0 T pp_crot)); Kanske skall vara pp_cindex
      ($TOOLDOWN 6)
      (SETQ $ptype 5)
      (SETQ $delay *AWJDelayWaterAbrasiveOn*)
      (SETQ $time *AWJDelayPressureDown*)
      (PIERCING)
      (SETQ $time *AWJDelayAfterCutting*)
      (CUTOFF)
      ($TOOLUP 7))
    (PROGN
      (SETQ $reason 6)
      ($STOP (LIST "GOTO CLEANING OR PRESSURE RELEASE POSITION"))
    )
  )
)

(DEFUN chbargram ()
  ($STOP (LIST $msg))
)

(DEFUN $ppiercing-begin (/ pp_ptype vars)
  (FUNBROWSER "$PPIERCING-BEGIN")
  (SETQ pp_xmod 0.0 ymod 0.0) ; Standard equipment, no offset needed.
  (SETQ pp_xmodsim 0.0 pp_ymodsim 0.0) ; Standard equipment, no offset needed.

  (SSIM-TOOLSET pp_toolused pp_toollist *ToolMovingSpeed*)
  (SETQ pp_mode 3)
  ($CHMODE)
  (IF (= *MachineType* 0) ($CHBARGRAM *PiercingPressure* *PiercingAbrasive*))
  ;(SETQ pp_ptype 2)
  ;(SETQ vars (LIST (CAR *Bleedpoint*)(CADR *Bleedpoint*) 10 nil))
  ;($PIERCING vars)
  (SETQ ppiercing-flag 1)
)

(DEFUN $CHMODE()
  (COND
    ((= pp_mode 4) (FUNBROWSER (STRCAT "$MODE:4 (CUTTING)")))
    ((= pp_mode 5) (FUNBROWSER (STRCAT "$MODE:5 (INKJET)")))
    ((= pp_mode 6) (FUNBROWSER (STRCAT "$MODE:6 (SPECIAL MARKING)")))
    (T (FUNBROWSER (STRCAT "$MODE:" (ITOA pp_mode))))
  )
  ;(SSIM-TOOLSET pp_toolused pp_toollist *ToolMovingSpeed*)
  (SETQ $mode pp_mode)
  (IF (NOT (EQUAL $mode $mold))
    (PROGN
      (CHMODE)
      (IF (= pp_mode 1) (SETQ $initdrill T))))
  (SETQ $mold pp_mode)
)

(DEFUN CHMODE() nil)

(DEFUN $ppiercing (vars / pp_x pp_y pp_fs pp_fe pp_ptype docirc HeadPrimaryAxisLimitations beveltype pp_vectordir $vaccumAssist thick)
  (FUNBROWSER "$PPIERCING")
  ; vars is X, Y, Z, piercing type, vector, beveltype leadplan leadoutplan ****** NOT IN USE
  ; vars is X, Y, Z, piercing type, vector, beveltype leadplan cinit******After Aug 24 2017
  (SIM-IAIP nil)
  (SETQ pp_leadplan (NTH 6 vars) pp_cinit (NTH 7 vars))
  (SETQ $ctype 0)
  (IF (NOT pp_makeprepiercing) ; Tidigare stod här: (AND (NOT pp_makeprepiercing) (NOT *DrillingTools*))
    (PROGN
      (IF measure-flag ($MEASURE-END))
      (IF drilling-flag ($DRILLING-END))
      (IF pp_tooldata ($TOOLSET pp_tooldata))
      (SETQ pp_tooldata nil)
      (IF pp_partdata ($PART pp_partdata))
      (IF ppiercing-flag ($PPIERCING-END))
      (IF marking-flag ($MARKING-END))
      (IF (NOT cutting-flag) ($cutting-begin)))
    (PROGN
      (IF drilling-flag ($DRILLING-END))
      (IF pp_tooldata ($TOOLSET pp_tooldata))
      (SETQ pp_tooldata nil)
      (IF pp_partdata ($PART pp_partdata))
      (IF marking-flag ($MARKING-END))
      (IF cutting-flag ($CUTTING-END))
      (IF (NOT ppiercing-flag) ($PPIERCING-BEGIN)))
  )
  (IF (<= $maxslope *MaxForbiddenTilt*)
    (SETQ *HeadSecondaryPrefer* 2)
    (SETQ *HeadSecondaryPrefer* *MasterHeadSecondaryPrefer*)
  )
  (SETQ $vaccumAssist *VacuumAssist*)
  (SETQ $speedramp T)
  (SETQ pp_x (NTH 0 vars) pp_y (NTH 1 vars) pp_z (NTH 2 vars) pp_ptype (NTH 3 vars) pp_vec (NTH 4 vars) beveltype (NTH 5 vars)) ;ZOK
  ;(IF (> (LOGAND beveltype 1) 0) (SETQ *TAC* nil))
  (SETQ thick (DISTANCE (LIST 0 0 0) pp_vec))
  ;(SETQ pp_vec (NORMALIZE pp_vec))
  (SETQ pp_fe *AWJCircularPiercingSpeed*)
  (SETQ pp_fs pp_fe)
  ($RAPID (LIST pp_x pp_y pp_zmaster nil 0 nil pp_cinit)) ;ZOK
  (SETQ pp_zmaster pp_z)
  (SETQ *bleedpoint* pp_$oldp)
  (IF pp_partstopdata (PROGN (SETQ $reason 1) ($STOP pp_partstopdata)))
  (SETQ pp_partstopdata nil)
  (SETQ pp_cleft 10000)
;  (IF (AND (> *Headtype* 0) (> (LOGAND beveltype 2) 0))
  (IF $uses5x
    (PROGN
      (IF (= (LOGAND beveltype 1) 0) (SETQ pp_vec (LIST 0 0 -1)))
      (SETQ $ctype 1)
      (SETQ pp_abinit T)
      ;(SETQ HeadPrimaryAxisLimitations *HeadPrimaryAxisLimitations*)
      ;(SETQ *HeadPrimaryAxisLimitations* nil)
      (SETQ vec (NORMALIZE pp_vec))
      (SETQ pp_$vec (TRANSVEC vec))
      (SETQ pp_ab (TILTDIR pp_$vec))
      (IF (AND (OR (= *Headtype* 1) (= *Headtype* 2)) (EQUAL vec (LIST 0 0 -1)))
        (PROGN
          (SETQ pp_vertical T)
          (DEFVARS)
          (SIM3D-TILT (CADDR pp_ab) 0.0 $arel $brel))
        (PROGN
          (SETQ pp_vertical nil)
          (DEFVARS)
          (SIM3D-TILT (CADDR pp_ab) (CADDDR pp_ab) $arel $brel))

      )
      ($TILT $a $b 2))
  )
  (SETQ $msg "TOOL DOWN")
  ($TOOLDOWN 3)
  ;(IF (NOT $zrel) (SETQ $zrel 0))
  (SIM-Z pp_zmaster *ZSpeed* *ZAcceleration*)
  (SIM-ON T pp_fe)
  (SETQ $kerf 0 $marking nil)
  (SETQ $ptype pp_ptype)

  (COND
    ((= *MachineType* 1) ; Its only stationary piercings
      (SETQ $delay 0.0)
      (SETQ $time *WaterPiercingTime*)
      (IF (> *WaterDelayAfterPiercing* $time) (SETQ $time *WaterDelayAfterPiercing*))
      (SETQ $ptype 2)
      (SETQ $pstat $time))
    ((= pp_ptype 2) ; Stationary piercing on AWJ-machines
      (SETQ $delay *AWJDelayWaterAbrasiveOn*)
      (SETQ $time *AWJStationaryPiercing* $circ nil)
      (IF (OR *AWJAutomaticPiercing* (AND *3D-5X* pp_vec)) (SETQ $time (STATIONARYPIERCINGTIME thick)))
      (IF (> *AWJDelayAfterPiercing* $time) (SETQ $time *AWJDelayAfterPiercing*))
      (SETQ $pstat $time))
    ((= pp_ptype 3) ; Circular piercing on AWJ-machines
      (SETQ $delay *AWJDelayWaterAbrasiveOn*)
      (SETQ $time *AWJCircularPiercing*)
      (IF (OR *AWJAutomaticPiercing* (AND *3D-5X* pp_vec)) (SETQ $time (CIRCULARPIERCINGTIME thick)))
      (SETQ $cpfeed *AWJCircularPiercingSpeed*)
      (SETQ $cpradius (* *PiercingDiameter* 0.5))
      (SETQ $cpturns (CEIL (/ (* (/ $cpfeed 60.0) (CEIL $time)) (* *PiercingDiameter* PI))))
      (SETQ $circ T))
  )
  ;(SETQ $ctype 0)
  (IF (= (LOGAND beveltype 1) 0) (SETQ pp_vec (LIST 0 0 -1)))

  (SIM-PIERCEON)
  (PIERCING)
  (IF (AND $circ *CustomCircularPiercing*) (CIRC-PIERCING))
  (SETQ $leadout nil)
  (SETQ $delay (IF (AND $wacode $useabr) *AWJDelayWaterAbrasiveOff* 0))
  (SETQ $chkerf nil $kerf 0)
  (SETQ $time (IF (= *MachineType* 0) *AWJDelayAfterPiercing* *WaterDelayAfterCutting* ))
  (SETQ $marking nil)
  (SIM-PIERCEOFF)
  (SIM-OFF)
  (CUTOFF)
  ($TOOLUP 3)
  (SETQ *HeadSecondaryPrefer* *MasterHeadSecondaryPrefer*)
  (SIM-IAIP T)
  ; pp_oldp och pp_$oldp sätts genom $RAPID
)

(DEFUN $piercing (vars / pp_x pp_y pp_z pp_time pp_docirc $ptype $time $stat $feed $radie $turn $ab pp_vectordir
                        *AWJCircularPiercing* *AWJCircularPiercingDiameter* *AWJCircularPiercingSpeed* *AWJStationaryPiercing* thick pp_vec)
  (SETQ pp_x (NTH 0 vars) pp_y (NTH 1 vars) pp_z (NTH 2 vars) pp_time (NTH 3 vars) pp_docirc (NTH 4 vars)) ;ZOK
  (SETQ pp_oldp (LIST pp_x pp_y))
  (SETQ $ab nil)
  (SETQ *bleedpoint* pp_$oldp)
  (SETQ $ptype pp_ptype)
  (SETQ $marking nil)
  (SIM-IAIP nil)
  (COND
    ((= *MachineType* 0) ; AWJ cutting
      (SETQ $lowhigh (IF (AND (OR (= $ptype 2) (= $ptype 3)) pp_lowhigh) T nil))
      (SETQ $time pp_time $circ pp_docirc)
      (SETQ $delay (IF (AND $useabr $wacode) *AWJDelayAbrasiveWaterOn* 0))
      (SETQ thick (DISTANCE (LIST 0.0 0.0 0.0) pp_vec))
      (COND
        ((= $ptype 0) ; Blind lead
          (SETQ $time 0)
          (SETQ $time *AWJDelayAfterPiercing*))
        ((= $ptype 1) ; Linearor piercing
          (SETQ $time pp_time)
          (IF (< $time *AWJDelayAfterPiercing*) (SETQ $time *AWJDelayAfterPiercing*)))
        ((= $ptype 2) ; Stationary piercing
          (IF (OR *AWJAutomaticPiercing* (AND *3D-5X* pp_vec)) (SETQ $time (STATIONARYPIERCINGTIME thick)))
          (IF (< $time *AWJDelayAfterPiercing*) (SETQ $time *AWJDelayAfterPiercing*))
          (SETQ $pstat $time))
        ((= $ptype 3) ; Circular piercing
          (IF (OR *AWJAutomaticPiercing* (AND *3D-5X* pp_vec)) (SETQ $time (CIRCULARPIERCINGTIME thick))))
        ((= $ptype 5) ; Airstart
          (SETQ $time *AWJDelayAfterPiercing*))
      )
      (SETQ $cpfeed *AWJCircularPiercingSpeed*)
      (SETQ $cpradius (* *PiercingDiameter* 0.5))
      (SETQ $cpturns (CEIL (/ (* (/ $cpfeed 60.0) (CEIL $time)) (* *PiercingDiameter* PI)))))
    ((= *MachineType* 1) ; Pure Water
      (SETQ $time pp_time $circ nil)
      (IF (= $ptype 3)
        (PROGN
          (SETQ $cpradius (* *WaterPiercingDiameter* 0.5))
          (SETQ $cpfeed 200)
          (SETQ $cpturns (CEIL (/ (* (/ $cpfeed 60.0) (CEIL $time)) (* *WaterPiercingDiameter* PI))))
          (SETQ $circ T)))
      (SETQ $delay 0)
      (SETQ $pstat *WaterPiercingTime*)
      (IF (> *WaterDelayAfterPiercing* $time) (SETQ $time *WaterDelayAfterPiercing*)))

    (T ; All other machinetypesr
      (SETQ $circ nil $delay 0 $time pp_time))
  )
  (IF (< pp_ptype 5) (SIM-PIERCEON))
  (SETQ pp_vec nil)
  (PIERCING)
  (IF (AND $circ *CustomCircularPiercing*) (CIRC-PIERCING))
  (SIM-PIERCEOFF)
  (SIM-IAIP T)
)

(DEFUN piercing ()
  (IF (= pp_ptype 3) (CIRC-PIERCING))
)

(DEFUN $ppiercing-end ()
  (SETQ ppiercing-flag nil)
)

;-------------------------------------Funtions for special marking ---------------------------


(DEFUN $specialmarking-begin () ; Marking with special marking tool

  (IF drilling-flag ($DRILLING-END))
  (IF measure-flag ($MEASURE-END))
  (IF ppiercing-flag ($PPIERCING-END))
  (IF cutting-flag ($CUTTING-END))
  (IF marking-flag ($MARKING-END))
  (SETQ inkjet-flag T)
  (SETQ pp_xmodsim *MarkingXoffset* pp_ymodsim *MarkingYoffset*)
  (SETQ pp_xmod *MarkingXoffset* pp_ymod *MarkingYoffset*)
  (IF *MarkingOffsetByController* (SETQ pp_xmod 0.0 pp_ymod 0.0))
  (IF pp_tooldata ($TOOLSET pp_tooldata))
  (SSIM-TOOLSET pp_toolused pp_toollist *ToolMovingSpeed*)
  (SETQ pp_tooldata nil)
  (SETQ pp_mode 6)
  ($CHMODE)
  (SETQ specialmarking-flag 1)
)

(DEFUN $specialmarking-end ()
  (FUNBROWSER "$SPECIALMARKING-END")
  (SETQ specialmarking-flag nil)
)


;-------------------------------------- Functions for waterjet marking-----------------
(DEFUN $marking-begin ()
  (FUNBROWSER "$MARKING-BEGIN")
  (IF drilling-flag ($DRILLING-END))
  (IF measure-flag ($MEASURE-END))
  (IF ppiercing-flag ($PPIERCING-END))
  (IF cutting-flag ($CUTTING-END))
  (IF specialmarking-flag ($SPECIALMARKING-END))
  (IF pp_tooldata ($TOOLSET pp_tooldata))
  (IF pp_partdata ($PART pp_partdata))
  (SETQ pp_tooldata nil)
  (SETQ pp_xmod 0.0 pp_ymod 0.0)
  (SETQ pp_xmodsim 0.0 pp_ymodsim 0.0)
  (SETQ pp_mode 2)
  (SSIM-TOOLSET pp_toolused pp_toollist *ToolMovingSpeed*)
  ($CHMODE)
  (IF (= *MachineType* 0) ($CHBARGRAM *MarkingPressure* *MarkingAbrasive*))
  (SETQ marking-flag 1)
)

(DEFUN $marking-end ()
;  (SETQ pp_oldmode 2)
  (SETQ pp_xmod 0 pp_ymod 0)
  (SETQ pp_xmodsim 0.0 pp_ymodsim 0.0)
  (SETQ marking-flag nil)
)

;------------------------------------- Common function for marking -------------------------
(DEFUN $markon (vars / pp_x pp_y pp_z pp_atrib ishole)
  (IF pp_rapid3dlist (FOREACH s (REVERSE pp_rapid3dlist) ($RAPID s)))
  (SETQ pp_rapid3dlist nil)
  (SETQ pp_bevelmarking nil)
  (SETQ pp_specialmarking nil)
  (SETQ $speedramp T)
  (SETQ pp_x (NTH 0 vars) pp_y (NTH 1 vars) pp_z (NTH 2 vars) pp_atrib (NTH 3 vars) pp_clen (NTH 4 vars) pp_cinit (NTH 5 vars) special (NTH 6 vars) pp_vec (NTH 7 vars) pp_starttan (NTH 8 vars) $maxslope (NTH 9 vars) from3d5x (NTH 10 vars) ishole (NTH 11 vars))
  ;(IF pp_tooldata (ALERT "PP_TOOLDATA"))
  ;(IF pp_tooldata ($TOOLSET pp_tooldata)) ; Ändrade denna 15/5 2020 innan var den remmad
  (SETQ pp_dobevel nil)
  (SETQ $starttan (+ pp_starttan pp_rotate))
  (IF (NOT special) ; If its waterjet marking
    (PROGN
      (SETQ $circ nil)
      (SETQ $time *AWJMarkingStartDelay*)
      (SETQ $delay (IF (AND $useabr $wacode) *AWJMarkingAbrasiveOn* 0))
      (SETQ $marking T)
      (SETQ $ptype (IF ishole -2 -1))
      (SETQ $kerf 0 $side 0)
      (IF ishole (SETQ $time *AWJPointMarkingDelay*))
      (SETQ $ctype 0)
;      ($RAPID (LIST pp_x pp_y pp_zmaster nil 0 nil pp_cinit))
      (IF pp_partstopdata (PROGN (SETQ $reason 1) ($STOP pp_partstopdata)))
      (IF (NOT pp_$oldvec) (SETQ pp_$oldvec (LIST 0 0 -1)))
      (SETQ pp_partstopdata nil)
      (SETQ pp_cleft pp_clen)
      (SETQ pp_zmaster pp_z) ; Set this after rapid
      (COND
        ((AND pp_vec (> $maxslope 0))
          (SETQ pp_abinit T)
          (SETQ pp_vertical nil)
          (SETQ pp_$vec (TRANSVEC pp_vec))
          (SETQ pp_ab (TILTDIR pp_$vec))
          (IF (= *HeadType* 0)
            (PROGN
              (SETQ $ab nil)
              (SETQ pp_dobevel nil)
              (SETQ pp_bevelmarking nil))
            (PROGN
              (SETQ $ab T)
              (SETQ pp_dobevel T)
              (SETQ pp_bevelmarking T)))
          (DEFVARS)
          (SIM3D-TILT (CADDR pp_ab) (CADDDR pp_ab) $arel $brel)
          (SIM-INFOTEXT "")
          ($TILT $a $b 2)
          (SIM-INFOTEXT "")
          ($RAPID (LIST pp_x pp_y pp_zmaster nil 0 nil pp_cinit))
          ;(ALERT (STRCAT "AV RAPID: " (TOSTR pp_$oldp)))
          ($TOOLDOWN 2))
       ((AND (> *HeadType* 0) (NOT *HeadStraight*) pp_headistilt)
          (SETQ pp_headistilt nil)
          (SETQ pp_ab nil pp_dobevel nil)
          ($TILT 0 0 4)
          (SIM3D-TILT 0 0 0 0)
          ($RAPID (LIST pp_x pp_y pp_zmaster nil 0 nil pp_cinit))
          ($TOOLDOWN 2))
       (T
          (SETQ pp_ab nil)
          ($RAPID (LIST pp_x pp_y pp_zmaster nil 0 nil pp_cinit))
          ($TOOLDOWN 2))
      )
      (SIM-ON nil *Markingspeed*)
      (SETQ $attrib pp_atrib)
      (PIERCING)
      (IF pp_bevelmarking (SETQ $ab T)))
    (PROGN
      (SETQ pp_specialmarking T)
      ($RAPID (LIST pp_x pp_y pp_zmaster nil 0 nil pp_cinit))
      ($TOOLDOWN 2)
      (SETQ $attrib pp_atrib)
      (SIM-ON nil *SpecialMarkingSpeed*)
      (MARKON)
    )
  )
  (SETQ pp_oldp (LIST pp_x pp_y pp_zmaster))
  ;pp_$oldp sätt av $RAPID funkrionen.
)

(DEFUN markon ()
  (SETQ a a)
)

(DEFUN $markoff (vars / specialmarking)
  (FUNBROWSER "$MARKOFF")
  ;(PRINC (STRCAT (ALERT (STRCAT "MARKOFF:" (TOSTR vars))) "\n"))
  (SETQ pp_5xheight nil)
  (SETQ pp_3xmove nil)
  (SETQ typ (NTH 0 vars))
  (COND
    ((= typ 0) nil); This is a normal 3X toolup from IGEMS
    ((= typ 1)     ; This is a 3D-5X cutoff, and the Z value should be used in toolup
      (SETQ pp_5xheight (NTH 3 vars)))
    ((AND (= typ 2) (MEMBER pp_zmode (LIST 3 6 7)))    ; Not vertical toolup
      (SETQ pp_5xx (NTH 1 vars) pp_5xy (NTH 2 vars) pp_5xz (NTH 3 vars))
      (SETQ pp_3xmove T))
    ((= typ 2)
      (CLS)
      (QUIT (ALERT "Tilted rapids only possible in programmable Z-axis")))
   )
  (SIM-OFF)
  (IF pp_specialmarking ;Cutting tool is used as marking tool
    (MARKOFF)
    (PROGN
      (SETQ $delay (IF $useabr *AWJMarkingAbrasiveOff* 0))
      (SETQ $kerf 0 $chkerf nil)
      (SETQ $marking T)
      (SETQ $time *AWJDelayAfterCutting*)
      (CUTOFF))
  )
  (COND
    (pp_3xmove ($TOOLUP 7)) ; toolup will add 1=8
    (T ($TOOLUP 2))
  )
)

(DEFUN markoff()
  (SETQ a a)
)



(DEFUN $specialmarking-end ()
  (SETQ pp_xmod 0 pp_ymod 0)
  (SETQ pp_xmodsim 0.0 pp_ymodsim 0.0)
)
(DEFUN $measure-end()
  (SETQ measure-flag nil)
)

;--------------------------------------- Cutting section --------------------------------------
(DEFUN $cutting-begin ()
  (FUNBROWSER "$CUTTING BEGIN")
  (SETQ pp_xmod 0.0 pp_ymod 0.0) ; Standard equipment, no offset needed.
  (SETQ pp_xmodsim 0.0 pp_ymodsim 0.0) ; Standard equipment, no offset needed.
  (SSIM-TOOLSET pp_toolused pp_toollist *ToolMovingSpeed*)
  (SETQ pp_mode 4)
  ($CHMODE)
  (COND
    ((= *Machinetype* 1)($CHBARGRAM *CuttingPressure* 0.0))
    ((= *MachineType* 0) ($CHBARGRAM *CuttingPressure* *CuttingAbrasive*))
  )
  (SETQ cutting-flag 1)
)

(DEFUN $cutting-end ()
  (FUNBROWSER "$CUTTING-END (cutting flag sets to nil)")
  (SETQ cutting-flag nil)
)

(DEFUN trans (x y z / rx ry)
  ; PP_XOFFSET and PP_YOFFSET holds the distance between T1 position to the first used tool.
  (IF (NOT pp_xoffset) (SETQ pp_xoffset 0.0 pp_yoffset 0.0))
  (SETQ rx (- (* x (COS pp_rotate)) (* y (SIN pp_rotate))))
  (SETQ ry (+ (* y (COS pp_rotate)) (* x (SIN pp_rotate))))
  (IF *CordinateToFirstTool*
    (LIST (+ rx pp_basex pp_xoffset) (+ ry pp_basey pp_yoffset) z)
    (LIST (+ rx pp_basex pp_xoffset) (+ ry pp_basey pp_yoffset) z)
  )
)

(DEFUN getfilename (message / nfile fnumber fpath name n filename)
  ; Return a filename if processmode=3 else function return nil
  ; Quit process if the user Cancel the File dialog

  ; Check if we need to open DAT file to read last number or path
  (IF (AND (MEMBER *ProcessMode* (LIST 0 1 2 4)) *JDE* *TubeMode*) (QUIT (ALERT "Not possible in JDE-mode")))
  (IF (OR (< *Processmode* 3) (= *Processmode* 4) (= *Processmode* 6)) ;0=Cost,1=Report,2=Sim,3=Post,4=5XSim,6=App
    (SETQ filename nil)
    (PROGN
      (IF (OR (= *PPFileByDrawing* 2) (NOT *OutputUseFixedFolder*))
        (PROGN
          (SETQ nfile (OPEN (STRCAT *SharedFolder* *ppname* ".DAT") "r"))
          (IF (NOT nfile)
            (SETQ fnumber "100")
            (PROGN
              (SETQ fnumber (READ-LINE nfile))
              (SETQ fpath (READ-LINE nfile))
              (CLOSE nfile)
            )
          )
          (SETQ fnumber (ATOF fnumber))))
; Set the path of the CNC-file                     ;
        (COND
          (*OutputUseFixedFolder* (SETQ fpath *OutputFolder*))
          (T (SETQ fpath (UC-GET *MachineName* "*OutputFolder*" *OutputFolder*)))
        )
; Suggest the name of the CNC-file
      (COND
        ((AND (= *PPFileByDrawing* 0) (= *SheetQuantity* 1) (FILE-VALIDFILENAME *SheetName*))
          (SETQ name *SheetName*))
        ((= *PPFileByDrawing* 2)
          (SETQ name (RTOS (+ fnumber 1) 0))
          (SETQ prefixlen (- *PPFILELENGTH* (STRLEN name)))
          (SETQ name (STRCAT (STRSUB *PPFILEPREFIX* 1 prefixlen) name))
          (IF (> (STRLEN name) *PPFILELENGTH*) (SETQ name (STRSUB name (- *PPFILELENGTH*)))))

       (T (SETQ name (FILE-NAMEONLY *Digfile* T)))
      )
      (SETQ filename (GETFILED message (STRCAT fpath name *PPFileExtension*) (SUBSTR *PPFileExtension* 2) 1)) ; Skall vara 1
      (IF (NOT filename) (QUIT "*Cancel*"))
; Check if we need to update the DAT file to save last number or path
      (IF (AND (OR (= *PPFileByDrawing* 2) (NOT *OutputUseFixedFolder*)) filename)
        (PROGN
          (IF (SETQ n (GETNR (FILE-NAMEONLY filename T))) (SETQ fnumber n)) ; n skall vara en real
          (SETQ nfile (OPEN (STRCAT *SharedFolder* *ppname* ".DAT") "w"))
          (WRITE-LINE (RTOS fnumber 0) nfile)
          (WRITE-LINE (FILE-DIRONLY filename) nfile)
          (CLOSE nfile)
        )
      )
      (IF (NOT *OutputUseFixedFolder*) (UC-SET *MachineName* "*OutputFolder*" (FILE-DIRONLY filename )))
    )
  )
  (IF (= *Processmode* 6)
    (PROGN
      ;(ALERT (STRCAT "First:" *Processfile*))
      (SETQ *Processmode* 3)
      (IF (MEMBER (FILE-DIRONLY *Processfile*) (LIST "\\" "/"))
        (PROGN
          (SETQ filename (STRCAT *Outputfolder* *Processfile* *PPFileExtension*))
          ;(ALERT (STRCAT "In IGEMS.LSP: "(TOSTR filename)))
          )
        (PROGN
          (SETQ filename *Processfile*)
          ;(ALERT (STRCAT "Out IGEMS.LSP:" (TOSTR filename)))
          ))))
  (IF (NOT fnumber) (SETQ fnumber 1000))
  (SETQ $fnumber fnumber)
  (EVAL filename)
)

(DEFUN GETNR (value / pos len txt tk)
  (SETQ pos 1 len (STRLEN value) txt "")
  (WHILE (<= pos len)
    (SETQ tk (ASCII (SUBSTR value pos 1)))
    (IF (AND (> tk 47) (< tk 58)) (SETQ txt (STRCAT txt (CHR tk))))
    (SETQ pos (+ pos 1))
  )
  (IF (> (ATOF txt) 0) (ATOF txt) nil)
)

;-------------------------------------------------- Simulation pre-defined functions ----------------------------
(DEFUN SSIM-TOOLSET (toolused toollist speed / pp_toollist pp_xmodsim pp_ymodsim)
  (SIM-TOOLSET toolused toollist speed pp_xmodsim pp_ymodsim)
  (SETQ pp_oldtoolused toolused pp_oldtoollist toollist)
)

(DEFUN SSIM-SETUP (/ sizex sizey vector)
  (COND
    ((= *BarAligned* 1) (SETQ sizeX (- *SizeX*) sizeY *Sizey*))
    ((= *BarAligned* 3) (SETQ sizeX *SizeX* sizeY (- *SizeY*)))
    (T (SETQ sizeX *SizeX* sizeY *SizeY*))
  )
  (IF (= *MachineType* 2) ; If its a Plasma machine
    (PROGN
      (SETQ *Maxfeed* (MAX *PlasmaCuttingSpeed* *PlasmaLeadinSpeed*))
      (SETQ *Minfeed* (MIN *PlasmaLeadinSpeed* (* *PlasmaCuttingSpeed* *PlasmaSpeedReduction* 0.01)))
    )
  )
  (COND
    ((NOT *DrillingTools*) (SETQ *DrillingToolsActive* 0))
    (*DrillingOnFirst* (SETQ *DrillingToolsActive* (ONETOBIT *DrillingOnTool*))) ;new
    ((NOT *DrillingOnFirst*) (SETQ *DrillingToolsActive* *ToolMaxbit*))
  )
  (SIM-SETUP 0 0 (CADDR *ZeroPoint*) Sizex SizeY *BarLength* *ToolQuantity* *ToolMinDistance* *ToolMaxDistance*
             *ToolPark* *BarAligned* *Maxfeed* *Minfeed* 0.0 0.0 *Zmaxmovement*) ;

  (SETQ vector
    (COND
      ((= *SixAxisDirection* 0) (LIST 1 0 0))
      ((= *SixAxisDirection* 1) (LIST 0 1 0))
      ((= *SixAxisDirection* 2) (LIST -1 0 0))
      ((= *SixAxisDirection* 3) (LIST 0 -1 0))
    )
  )
  (IF *UseSixAxis* (SIM3D-ROTAXIS *SixAxisOrigo* vector))
  (SIM-COSTMAC *MachineCost*)
  (SIM-COSTMAT *QualityCost*)
  (COND
    ((= *MachineType* 0)
      (SIM-COSTTOOL *AWJCostPerTool*)
      (SIM-COSTABRASIVE *AWJAbrasiveCost*))
    (T
      (SIM-COSTDIST *CostDist*)
      (SIM-COSTPIERCING *CostPiercing*))
  )
)

(DEFUN SSIM-LINE (pp_$x pp_$y $fs $fe crot len / s vec)
  (SETQ s pp_ab)
  ;(ALERT (TOSTR (LIST pp_$x pp_$y $fs $fe crot pp_xmodsim pp_xoffsetsim pp_ymodsim pp_yoffsetsim)))
  (IF pp_ab (SIM3D-TOOLDIR (CADDR pp_ab) (IF pp_vertical 0 (CADDDR pp_ab))))
  (IF (NOT pp_z) (SETQ pp_z 20))
  (SETQ vec (IF pp_vec pp_vec (LIST 0 0 -1)))
  (SETQ vec (TRANSVEC vec))
  (SIM-LINE (- pp_$x pp_xmodsim pp_xoffsetsim *SIM-ADDX*) (- pp_$y pp_ymodsim pp_yoffsetsim *SIM-ADDY*) pp_zmaster $fs $fe crot (CAR vec) (CADR vec) (CADDR vec) len)
  (SETQ pp_ab s)
)

(DEFUN SSIM-ARC (pp_$x pp_$y pp_$i pp_$j pp_ccw $fs $fe crot / s vec)
  (SETQ s pp_ab)
  (IF pp_ab (SIM3D-TOOLDIR (CADDR pp_ab) (CADDDR pp_ab)))
  (IF (NOT pp_z) (SETQ pp_z 20))
  (SETQ vec (IF pp_vec pp_vec (LIST 0 0 -1)))
  (SETQ vec (TRANSVEC vec))
  (SIM-ARC (- pp_$x pp_xmodsim pp_xoffsetsim *SIM-ADDX*)
           (- pp_$y pp_ymodsim pp_yoffsetsim *SIM-ADDY*) pp_zmaster
           (- pp_$i pp_xmodsim pp_xoffsetsim *SIM-ADDX*)
           (- pp_$j pp_ymodsim pp_yoffsetsim *SIM-ADDY*) pp_ccw $fs $fe crot (CAR vec) (CADR vec) (CADDR vec))
  (SETQ pp_ab s)
)

(DEFUN SSIM-RAPID (x y z speedrapid speedacc rot / pp_xoffsetsim pp_yoffsetsim)
  ;(WRITE "(SIMRAPID)")
  (IF (NOT pp_xoffsetsim) (SETQ pp_xoffsetsim 0.0 pp_yoffsetsim 0.0))
  (IF (NOT pp_xmodsim) (SETQ pp_xmodsim 0.0 pp_ymodsim 0.0))
  (SIM-RAPID (- x pp_xmodsim pp_xoffsetsim *SIM-ADDX*) (- y pp_ymodsim pp_yoffsetsim *SIM-ADDY*) z SpeedRapid SpeedAcc rot)
)


(DEFUN $HQCHAWJ (vars / x y r centp toolradius maxtoolradius piercinglen r1 r2 xrapid yrapid offset spiraldata kerf
                     motp lastp radiusout speed vec endp attr qua pt segq sega stv)
  (SETQ x (NTH 0 vars) y (NTH 1 vars) pp_z (NTH 2 vars) r (NTH 4 vars) attr (NTH 5 vars) qua (NTH 6 vars))
  (SETQ pp_cinit 0 pp_crot 0)
  (IF (= qua 0) (SETQ qua 5))
  (IF (NOT *HQCHcorrection*) (SETQ *HQCHcorrection* 0.0))
  (SETQ r (+ r (* *HQCHcorrection* 0.5)))
  (SETQ pp_cutdirection 0)
  (SETQ centp (LIST x y))
  (SETQ toolradius (* *ToolDiameter* 0.5))
  (SETQ maxtoolradius (* *MaxToolDiameter* 0.5))
  (SETQ piercinglen *AWJLinearPiercingDistance*)
  ; (SETQ *InternalToolCompensation* 2) ; to easy test different options
  (IF (< piercinglen *MaxToolDiameter*) (SETQ piercinglen *MaxToolDiameter*))
  ;(SETQ piercinglen (* *Thickness* 0.2))

  (SETQ r2 (- r toolradius))
  (SETQ r1 (- r2 toolradius))
  (IF (< r1 0.01) (SETQ r1 0.01))
  (SETQ xrapid (+ x r1))
  (SETQ yrapid y)
  (SETQ offset 0)
  (SETQ speed $xfine)
  (SETQ kerf 0)
  (SETQ $hqch T)
  ($CUTON (LIST (+ x r1 offset) y pp_z kerf 0 3 9999 9999 9999 "" "" PIH 0 0 1 xrapid yrapid pp_z 0 *SpeedMaxCutting* (LIST 0 0 (- pp_z))
          0 0 0 (LIST 0 0 -1) 0 0 (LIST 0 0 -1) 0 pp_cinit pp_crot)) ;ZOK
  (SETQ $ab nil)
  (SETQ speed $xfine)
  (SETQ segq (CEIL (/ PID *LargestSegmentAngle*)))
  (SETQ sega (/ PID segq))
  (SETQ stv 0)
  (REPEAT segq
    (SETQ pt (POLAR (LIST x y) (SETQ stv (+ stv sega)) r1))
    ($ARC (LIST (CAR pt) (CADR pt) pp_z x y T 1 speed speed 0 vec pp_cutdirection pp_crot))
  )
  ;($ARC (LIST (- x r1) y pp_z x y T 1 speed speed 0 vec pp_cutdirection pp_crot)) ;ZOK
  ;($ARC (LIST (+ x r1) y pp_z x y T 1 speed speed 0 vec pp_cutdirection pp_crot)) ;ZOK
  (SETQ spiraldata (SPIRAL x y r1 r2 piercinglen offset))
  (SETQ lastp (LIST (+ x r1) y))
  (FOREACH s spiraldata
    (SETQ radie (DISTANCE (LIST (CAR s) (CADR s)) (LIST (CADDR s) (CADDDR s))))
    (SETQ npos (LIST (CAR s) (CADR s)))
    ($LINE (LIST (CAR s) (CADR s) pp_z 0 speed speed 0 vec pp_cutdirection pp_crot))
;    ($ARC (LIST (CAR s) (CADR s) (CADDR s) (CADDDR s) T 0 speed speed 0 vec pp_cutdirection))
    (SETQ lastp npos)
  )
  (SETQ stv (ANGLE (LIST x y) lastp))
  (SETQ speed (CALCAWJFEED 9 *Thickness*))
  (REPEAT segq
    (SETQ pt (POLAR (LIST x y) (SETQ stv (+ stv sega)) r2))
    ($ARC (LIST (CAR pt) (CADR pt) pp_z x y T 1 speed speed 0 vec pp_cutdirection pp_crot))
  )
  (SETQ speed (CALCAWJFEED 5 *Thickness*))
  (REPEAT segq
    (SETQ pt (POLAR (LIST x y) (SETQ stv (+ stv sega)) r2))
    ($ARC (LIST (CAR pt) (CADR pt) pp_z x y T 1 speed speed 0 vec pp_cutdirection pp_crot))
  )
  (SETQ radiusout (- r2 0.1))
  (IF (< radiusout r1) (SETQ radiusout r1))
;  (SETQ radiusout (* *MaxToolDiameter* 0.5))
  (SETQ speed (CALCAWJFEED 5 *Thickness*))
  (SETQ centp (POLAR pt (ANGLE pt centp) radiusout))
;  (SETQ endp (POLAR centp (+ (ANGLE centp pt) (* PI 0.5)) radiusout)) ; 0.5 vr 0.25
  (SETQ endp (POLAR centp (+ (ANGLE centp pt) (* PI 0.5)) radiusout)) ; 0.5 vr 0.25

  ($ARC (LIST (CAR endp) (CADR endp) pp_z (CAR centp) (CADR centp) T 0 speed speed 0 vec pp_cutdirection pp_crot)) ;ZOK
  ($CUTOFF (LIST 0))
  (SETQ $hqch nil)
)



(DEFUN hold() nil)
(DEFUN truehole () nil)
(DEFUN $HQCHPLASMA (vars / x y r centp toolradius modmaxtoolradius hqchradie leadradie hup vin leadcp leadstp leadend speed)
  ; Speed rules:
  ; If the hole is smaller then diameter 10: Use 50% of speed.
  ; If the hole is larger then 60: Use 100% of the speed.
  ; If the hole is between 10-60 calculate the speed by a linear function.
  (SETQ x (NTH 0 vars) y (NTH 1 vars) pp_z (NTH 2 vars) r (NTH 4 vars) attr (NTH 5 vars) qua (NTH 6 vars))
  (SETQ pp_cinit 0 pp_crot 0)
  (IF *CustomTrueHole*
    (PROGN
      (SETQ pp_$pt (TRANS x y pp_z))
      (SETQ pp_$x (CAR pp_$pt) pp_$y (CADR pp_$pt))
      (DEFVARS)
      (SETQ $r r)
      (TRUEHOLE))
    (PROGN
      (SETQ $hqch T)
      (COND
        ((<= r 5) (SETQ speed 50))
        ((>= r 30) (SETQ speed 100))
        (T (SETQ speed (+ (* 2 (- r 5)) 50)))
      )
      (SETQ centp (LIST x y))
      (SETQ toolradius (* *ToolDiameter* 0.5))
      (SETQ modmaxtoolradius (+ (* *MaxToolDiameter* 0.5) 1.0))
      (IF (< *InternalToolCompensation* 2) ; IGEMS=0, IGEMS+Machine=1, Machine=2 If IGEMS Tool radius compensation should be used.
        (SETQ hqchradie (- r toolradius))
        (SETQ hqchradie r)
      )
      (SETQ leadradie (* hqchradie 0.25))
      (IF (< leadradie modmaxtoolradius) (SETQ leadradie modmaxtoolradius))
      (SETQ hup (- hqchradie leadradie)) ;huputinusan
      (SETQ vin (ASIN (/ leadradie hup)))
      (SETQ leadcp (POLAR centp 0 hup))
      (SETQ leadstp (POLAR leadcp (- (* PI 1.5) vin) leadradie))
     ; ($CUTON (LIST (CAR leadstp) (CADR leadstp) pp_z 1 2 3 9999 9999 9999 "" "" PIH (* PI 2.5) PIH 1 xrapid yrapid pp_z 0 speed (LIST 0 0 (- pp_z))
     ;     0 0 0 (LIST 0 0 -1) 0 0 (LIST 0 0 -1) 0 pp_cinit pp_crot)) ;ZOK


      ($CUTON (LIST (CAR leadstp) (CADR leadstp) pp_z 1 2 3 9999 9999 9999 "" "" PIH (* PI 2.5) PIH 1 x y pp_z            0 speed (LIST 0 0 (- pp_z))
          0 0 0 (LIST 0 0 -1) 0 0 (LIST 0 0 -1) 0 pp_cinit pp_crot))

      (SETQ leadend (LIST (+ x hqchradie) y))
      ($HOLD)
      ($ARC (LIST (CAR leadend) (CADR leadend) pp_z (CAR leadcp) (CADR leadcp) T 1 speed speed 0 (LIST 0 0 -1) 0)) ;ZOK
      ($ARC (LIST x (- y hqchradie) pp_z x y T 0 speed speed 0 (LIST 0 0 -1) 0)) ;ZOK
      ($ARC (LIST (CAR leadend) (CADR leadend) pp_z x y T 1 speed speed 0 (LIST 0 0 -1) 0))
      ($FLYOFF)
      ($ARC (LIST x (+ y hqchradie) pp_z x y T 0 speed speed 0 (LIST 0 0 -1) 0)) ;OK
      ($CUTOFF (LIST 0))
      (SETQ $hqch nil)
    )
  )
)
(DEFUN $HQCHWATER (vars / x y r centp toolradius maxtoolradius hqchradie strp endp td v slutang addang addfeed oldfeed newfeed pt steps)
  (SETQ x (NTH 0 vars) y (NTH 1 vars) pp_z (NTH 2 vars) r (NTH 4 vars) attr (NTH 5 vars) qua (NTH 6 vars))
  (SETQ pp_cinit 0 pp_crot 0)
  (SETQ centp (LIST x y))
  (SETQ toolradius (* *ToolDiameter* 0.5))
  (SETQ maxtoolradius (* *MaxToolDiameter* 0.5))
  (IF (< *InternalToolCompensation* 2) ; IGEMS=0, IGEMS+Machine=1, Machine=2 If IGEMS Tool radius compensation should be used.
    (SETQ hqchradie (- r toolradius))
    (SETQ hqchradie r)
  )
  (SETQ strp (LIST (- (+ x hqchradie) toolradius) (- y maxtoolradius))) ; Rapid movement to this point
  (SETQ endp (LIST (+ x hqchradie) y))
  ($CUTON (LIST (CAR endp) (CADR endp) pp_z 1 0 3 9999 9999 9999 "" "" PIH (* PI 2.5) PIH 1 (CAR strp) (CADR strp) pp_z 0 *SpeedMaxCutting* (LIST 0 0 -1)
    0 0 0 (LIST 0 0 -1) 0 0 (LIST 0 0 -1) 0 pp_cinit pp_crot))
  (COND
    ((OR (NOT *WaterSlowDownInCorners*) ; If a fix speed should be used for whole circle
         (EQUAL *WaterHighSpeed* *WaterLowSpeed* 1)
          (= *watersteps* 0)
          (EQUAL *WaterAccdist* 0 0.1))
      (SETQ endp (LIST x (- y hqchradie)))
      (SETQ speed *WaterCuttingSpeed*)
      ($ARC (LIST (CAR endp) (CADR endp) pp_z x y T 0 speed speed 0 (LIST 0 0 -1) 0)) ;ZOK
      (SETQ v (/ *WaterPiercingOvercutDistance* hqchradie))
      (IF (> v 4.5379) (SETQ v 4.5379)) ; Max 260 degree overcut
      (SETQ endp (POLAR centp v hqchradie))
      ($ARC (LIST (CAR endp) (CADR endp) pp_z x y T 0 speed speed 0 (LIST 0 0 -1) 0)) ;ZOK
      ($CUTOFF (LIST 0)))
    (T
      (SETQ steps (IF (= *Speedmode* 2) *Watersteps* 1))
      (SETQ startang 0)
      (SETQ slutang (/ *WaterAccDist* hqchradie))
      (IF (> slutang 4.5379) (SETQ slutang 4.5379)) ; Ramping up max 260 degree
      (SETQ addang (/ slutang *Watersteps*))
      (SETQ oldfeed *WaterLowSpeed*)
      (SETQ addfeed (/ (- *WaterHighSpeed* *waterLowSpeed*) steps))
      (REPEAT steps
        (SETQ startang (+ startang addang))
        (SETQ newfeed (+ oldfeed addfeed))
        (SETQ pt (POLAR centp startang hqchradie))
        (IF (= *Speedmode* 2)
          ($ARC (LIST (CAR pt) (CADR pt) pp_z x y T 0 oldfeed oldfeed 0 (LIST 0 0 -1) 0)) ;ZOK
          ($ARC (LIST (CAR pt) (CADR pt) pp_z x y T 0 oldfeed newfeed 0 (LIST 0 0 -1) 0)) ;ZOK
        )
        (SETQ oldfeed newfeed)
      )
      (SETQ pt (LIST x (- y hqchradie)))
      ($ARC (LIST (CAR pt) (CADR pt) pp_z x y T 0 *WaterHighSpeed* *WaterHighSpeed* 0 (LIST 0 0 -1) 0))  ;ZOK
      (SETQ v (/ *WaterPiercingOvercutDistance* hqchradie))
      (IF (> v 4.5379) (SETQ v 4.5379)) ; Max 260 degree overcut
      (SETQ pt (POLAR centp v hqchradie))
      ($ARC (LIST (CAR pt) (CADR pt) pp_z x y T 0 *WaterHighSpeed* *WaterHighSpeed* 0 (LIST 0 0 -1) 0)) ;ZOK
      ($CUTOFF (LIST 0)))
  )
)
(DEFUN $flyoff() (FLYOFF))
(DEFUN flyoff () nil)

(DEFUN $hold () (HOLD))
(DEFUN $unhold () (UNHOLD))
(DEFUN unhold () nil)

(DEFUN checksumcount (text / q a) ; function for the checksum
  (SETQ text (STRCASE text nil))
  (SETQ q 1 a 0)
  (REPEAT (STRLEN text)
    (SETQ a (+ a (ASCII (SUBSTR text q 1))))
    (SETQ q (1+ q))
  )
  (EVAL (* (+ a 114) 3))
)

(DEFUN $TOOLUP (what)
  ;(WRITE (ALERT (STRCAT "\n$TOOLUP:" (TOSTR what))))
  (SETQ $zmode pp_zmode)
  (SETQ fullvarlist (LIST
                    (LIST 0 T *Zmaxmovement* *ZPneumaticStroke* "INITIALIZATION UP")
                    (LIST 1 *DrillLiftZ* *DrillLiftHeight* *DrillPneumatic* "DRILLING UP")
                    (LIST 2 *MarkingLiftZ* *MarkingLiftHeight* *MarkingPneumatic* "MARKING UP")
                    (LIST 3 *PiercingLiftZ* *PiercingLiftHeight* *PiercingPneumatic* "PRE-PIERCING UP")
                    (LIST 4 *CuttingLiftZ* *CuttingLiftHeight* *CuttingPneumatic* "CUTTING UP")
                    (LIST 5 *CuttingLiftZParts* *CuttingLiftHeightParts* *CuttingPneumatic* "PART UP")))
  (SETQ varlist (ASSOC what fullvarlist))
  (SETQ $move (NTH 1 varlist) height  (NTH 2 varlist) $stroke (NTH 3 varlist) $msg (NTH 4 varlist))
  ;(SETQ $move T)
  ;(ALERT (STRCAT "HEIGHT:" (TOSTR height) " MOVE:" (TOSTR $move)))
  (SETQ $reason (1+ what))
  ;(ALERT (STRCAT "REASON:" (TOSTR $reason) " ZMODE:" (TOSTR pp_zmode)))
  ;(ALERT (STRCAT "$REASON:" (TOSTR $reason)))
  (COND
    ;((= $reason 8) nil)

    ((= $zmode 0) ; Fixed Z-axis
      (SETQ pp_zmaster pp_zclear)
      (SETQ $z (ZDEF pp_zmaster))
      (SETQ $move nil)
      (IF $stoke
        (PROGN
          (SETQ pp_zmaster *Zmaxmovement*)
          (SETQ $z (ZDEF pp_zmaster))
          (SETQ $zrel (- pp_$Zold (SETQ pp_$Zold $z)))
          (TOOLUP))))
    ((OR (= pp_zmode 1) (= pp_zmode 4)) ; 1=Auto by water On/Off, 4=Sensor by water On/off
      (SETQ $move T)
      (SETQ pp_zmaster (+ *Thickness* *ZAutoDist*))
      (IF $stroke (SETQ pp_zmaster *ZMaxMovement*))
      (SIM-Z pp_zmaster *ZSpeed* *ZAcceleration*) ;SIMOK
      (SIM-INFOTEXT "")
      (SETQ $z (ZDEF pp_zmaster))
      (SETQ $zrel (- pp_$Zold (SETQ pp_$Zold $z)))
      (TOOLUP))
    ((OR (= pp_zmode 2) (= pp_zmode 5))   ; 2= By M-code Up/Down, Sensor by M-code Up/Down
      (IF (OR $move $stoke)
        (PROGN
          (SETQ pp_zmaster (+ *Thickness* *ZAutoDist*))
          (IF $stroke (SETQ pp_zmaster *ZMaxMovement*))
          (SIM-Z pp_zmaster *ZSpeed* *ZAcceleration*) ;SIMOK
          (SIM-INFOTEXT "")
          (SETQ $z (ZDEF pp_zmaster))
          (SETQ $zrel (- pp_$Zold (SETQ pp_$Zold $z)))
          (TOOLUP))))
    ((OR (= pp_zmode 3) (= pp_zmode 6) (= pp_zmode 7)) ; 3= by Z-cordinate, 6= Sensor by Z-cordinate, 7=Measuring in advance
      ;(PRINC (STRCAT "$MOVE:" (TOSTR $move) "\n"))
      ;(PRINC (STRCAT "PP_ZMASTER:" (TOSTR pp_zmaster) "\n"))
      ;(PRINC (STRCAT "PP_ZCLEAR:" (TOSTR pp_zclear) "\n"))
      ;(PRINC (STRCAT "HEIGHT:" (TOSTR height) "\n"))
      (IF (AND (NOT $move) (< pp_master pp_zclear)) (SETQ height 0 $move T))
      (COND
        (pp_3xmove
          ;(WRITE (ALERT (STRCAT "PP_5XZ:" (TOSTR pp_5xz))))
          (SETQ pp_$newp (TRANS pp_5xx pp_5xy pp_5xz))
          (SETQ pp_$x (CAR pp_$newp) pp_$y (CADR pp_$newp) pp_$z (CADDR pp_$newp))
          ;(WRITE (ALERT (STRCAT "pp_$newp:" (TOSTR pp_$newp)))) ; Z=12.7
          ;(SETQ pp_$z (ZDEF (CADDR pp_$newp)))
          ;(WRITE (ALERT (STRCAT "PP_$z:" (TOSTR pp_$z))))
          (SETQ pp_zmaster (CADDR pp_$newp))
          ;(SETQ $z pp_$z)
          (DEFVARS)
          (SSIM-RAPID pp_$x pp_$y pp_$z *SpeedRapid* *SpeedAcceleration* pp_crot)
          (SIM-INFOTEXT "")
          (SETQ $zrel (- (- pp_$Zold (SETQ pp_$Zold $z))))
          (TOOLUP))
       ((OR $move $stroke)
         (SETQ pp_zmaster (+ pp_zclear height))

         ;(ALERT (STRCAT "PP_5XHEIGHT:" (TOSTR pp_5xheight)))
         (IF pp_5xheight (SETQ pp_zmaster pp_5xheight))
         (IF (= what 0) (SETQ pp_zmaster *Zmaxmovement*)) ; If its initialization
         (SIM-Z pp_zmaster *ZSpeed* *ZAcceleration*) ;SIMOK
         (SIM-INFOTEXT "")
         ;(ALERT (STRCAT "INNAN:" (TOSTR pp_zmaster)))
         (IF (= $reason 1) (SETQ pp_zmaster (IF *3D-5X* *Zmaxmovement* (+ pp_zclear *CuttingLiftHeightParts*))))
         (SETQ $z (ZDEF pp_zmaster))
         ;(ALERT (STRCAT "EFTER:" (TOSTR $z)))
         (SETQ $zrel (- (- pp_$Zold (SETQ pp_$Zold $z))))
         (TOOLUP)
         (IF (= what 0) (SETQ pp_zrapidinit T))))) ; If its initialization
  )
  (SETQ pp_toolisup $move)
  (SETQ pp_strokeisup $stroke)
  (SETQ $newpart nil)
)


(DEFUN $TOOLDOWN (mode / lift NotMove)
  (SETQ $stroke pp_strokeisup)
  (SETQ $move pp_toolisup)
  (SETQ $reason (1+ mode))
  ; ; Reason 1=Init, 2 Between Drillings, 3 Markings, 4 Prepiercings 5 Cuts in part, 6 Between parts,7 Cleaning or Pressure reduce
  (IF (AND (MEMBER $reason (LIST 4 5 6)) (= pp_ptype 0) (= pp_side 0)) (SETQ pp_zstart pp_z))
  (SIM-Z pp_zmaster *ZSpeed* *ZAcceleration*)
  (SETQ $z (ZDEF pp_zmaster))
  (SETQ $zrel (- (- pp_$zold (SETQ pp_$zold $z))))

  (SETQ $zmode pp_zmode)
  (SETQ $msg "TOOL DOWN")
  (COND
    ((AND (= *ZAxisOption* 0) (NOT *ZDownOnFixed*)) nil) ; Fixed Z To support STM they can set a variable that moves the head down first time
    ((AND (NOT $stroke) (NOT $move)) nil)
    ((AND (= $zmode 0) *ZDownOnFixed*) ; Fixed axis special for STM
      (TOOLDOWN)
      (SETQ *ZDownOnFixed* nil))
    ((= $zmode 0) nil) ; Fixed axis
    ((= $zmode 1) nil) ; Automatic, Up/Down controlled by water On/Off.
    ((= $zmode 2)      ; Up/Down with separate M-codes.
      (TOOLDOWN))
    ((= $zmode 3)      ; Up/Down controlled by Z-coordinates..
      (TOOLDOWN)
      (SETQ $initdown nil)
      (SETQ pp_strokeisup nil)
      (SETQ pp_toolisup nil))
    ((= $zmode 4) nil); Automatic Sensor up down controlled by water On/Off
    ((= $zmode 5) ; Heigh sesor that are conroller by d by M-codes
      (TOOLDOWN))
    ((= $zmode 6) ;Height sensor controlled by height sensor
      (TOOLDOWN))
    ((= $zmode 7) ; Measuring in advance
      (TOOLDOWN))
  )
  (SETQ $initdown nil)
  (SETQ pp_strokeisup nil)
  (SETQ pp_toolisup nil)
  (SETQ $initdrill nil)
  (SETQ pp_$oldp (LIST (CAR pp_$oldp) (CADR pp_$oldp) pp_zmaster))
)



(DEFUN TOOLUP () nil)
(DEFUN TOOLDOWN () nil)
(DEFUN flyctrl () nil)

(DEFUN units (value)
  value
)

(DEFUN MakeByList (Struct / a b c bylist txt show nthlist)
  ; Struct handle the structure of the process: bySheet=0, byTool=1, byPart=2, byStart=3 list to create
  ; Operation is a bitvalue of following process types: 1=Drilling, 2=Marking, 4=Pre-piercing, 8=Cutting
  (SETQ show nil)
  (SETQ a 0 b 0 c 0)
  ;(PRINC "\nDRILLBYTYPE=") (PRINC *DrillByType*)
  (IF (= *DrillByType* struct)
    (COND
      ((= *DrillPriority* 1) (SETQ a (+ a 1)))
      ((= *DrillPriority* 2) (SETQ b (+ b 1)))
      ((= *DrillPriority* 3) (SETQ c (+ c 1)))
    )
  )
 ;(PRINC "\nMARKBYTYPE=") (PRINC *MarkingByType*)
  (IF (= *MarkingByType* struct)
    (COND
      ((= *MarkingPriority* 1) (SETQ a (+ a 2)))
      ((= *MarkingPriority* 2) (SETQ b (+ b 2)))
      ((= *MarkingPriority* 3) (SETQ c (+ c 2)))
    )
  )
;  (PRINC "\nPIERCBYTYPE=") (PRINC *PiercingByType*)
  (IF (= *PiercingByType* struct)
    (COND
      ((= *PiercingPriority* 1) (SETQ a (+ a 4)))
      ((= *PiercingPriority* 2) (SETQ b (+ b 4)))
      ((= *PiercingPriority* 3) (SETQ c (+ c 4)))
    )
  )
  (IF (> c 0) (SETQ bylist (CONS c bylist)))
  (IF (> b 0) (SETQ bylist (CONS b bylist)))
  (IF (> a 0) (SETQ bylist (CONS a bylist)))
  (IF (= struct 3) (SETQ bylist (LIST (+ a b c 8))))
  (IF show
    (PROGN
      (COND
        ((= struct 0) (PRINC "\nCreating process list for BySheet\n"))
        ((= struct 1) (PRINC "\nCreating process list for ByTool\n"))
        ((= struct 2) (PRINC "\nCreating process list for ByPart\n"))
        ((= struct 3) (PRINC "\nCreating process list for ByStart\n"))
      )
      (SETQ txt "")
      (FOREACH s bylist (SETQ txt (STRCAT txt (NTH (- s 1) nthlist))))
    ;  (PRINC (STRCAT txt "\n"))
    )
  )
  bylist
)

(DEFUN measuregeometry (geometry / addgrid clline cmd vars flag oldp len ang loops increment pt cp ra ccw stv slv LargestSegmentAngle)
  ; All segments for cutting are already split up in the preparation file.
  (DEFUN addgrid (pt force)
    (COND
      ((NOT pp_kdtree)
        (SETQ pp_kdtree (KDTREE-CREATE (LIST (LIST (CAR pt) (CADR pt) 1))))
        (SETQ pp_kdlist (LIST (LIST (CAR pt) (CADR pt) 1)))
        (SETQ pp_kdmax 1))
      ((AND force nil)
        (SETQ pp_kdmax (1+ pp_kdmax))
        (SETQ pp_kdtree (KDTREE-INSERT pp_kdtree (LIST (CAR pt) (CADR pt) pp_kdmax))))
      ((NOT (KDTREE-FINDCLOSEST pp_kdtree pt (* (IF bevel *ZMeasureDistBevel* *ZMeasureDist*) 0.95) 1))
        (SETQ pp_kdmax (1+ pp_kdmax))
        (SETQ pp_kdtree (KDTREE-INSERT pp_kdtree (LIST (CAR pt) (CADR pt) pp_kdmax)))
        (SETQ pp_kdlist (CONS (LIST (CAR pt) (CADR pt) pp_kdmax) pp_kdlist)))
   )
   (IF (> pp_kdmax *ZMeasureMaxPoints*)
     (PROGN
       (ALERT "To many measurepoints needed")
       (QUIT (STRCAT "Needed point are " (ITOA pp_kdmax) " maximum are " (ITOA *ZMeasureMaxPoints*)))))
  )
  (FOREACH clline geometry
    (SETQ cmd (CAR clline))
    (SETQ vars (CADR clline))
    (COND
      ((AND (= cmd '$MARKON) (OR (> (LOGAND optype 2) 0) (> (LOGAND optype 8) 0)))
         (ADDGRID (TRANS (NTH 0 vars) (NTH 1 vars) (NTH 2 vars)) T)
         (SETQ oldp (LIST (NTH 0 vars) (NTH 1 vars))))
      ((AND (= cmd '$CUTON) (> (LOGAND optype 4) 0) pp_makeprepiercing)
        (COND
          ((AND (= (NTH 4 vars) 4) (NOT *DrillingTools*)) ; If it's drill and no drilling tool avaiable
            (ADDGRID (TRANS (NTH 0 vars) (NTH 1 vars) (NTH 2 vars)) T))
          ((OR (= (NTH 4 vars) 3) (= (NTH 4 vars) 2))
            (ADDGRID (TRANS (NTH 0 vars) (NTH 1 vars) (NTH 2 vars)) T))
        )
        (SETQ oldp (LIST (NTH 0 vars) (NTH 1 vars))))
      ((AND (= cmd '$HOLE) (> (LOGAND optype 4) 0) pp_makeprepiercing)
        (COND
          ((AND (= (NTH 2 vars) 0) (NOT *DrillingTools*)) ; If its drilled and no drilling tools avaiable in Hole
            (ADDGRID (TRANS (NTH 0 vars) (NTH 1 vars) (NTH 2 vars)) T))
          ((AND (= (NTH 2 vars) 2)) ;If Circular in hole
            (ADDGRID (TRANS (NTH 0 vars) (NTH 1 vars) (NTH 2 vars)) T))
        ))
      ((AND (= cmd '$CUTON) (> (LOGAND optype 8) 0)) ; When using cuton for cutting
        (SETQ flag (NTH 21 vars))
        (IF (NOT flag) (SETQ flag 0))
        (SETQ bevel (IF (> (LOGAND flag 2) 0) T nil))
        (ADDGRID (TRANS (NTH 0 vars) (NTH 1 vars) (NTH 2 vars)) T)
        (SETQ oldp (LIST (NTH 0 vars) (NTH 1 vars))))
      ((AND (= cmd '$LINE) (> (LOGAND optype 2) 0)) nil) ;If it's marking
      ((AND (= cmd '$LINE) (> (LOGAND optype 8) 0)) ; If it's cutting
        (SETQ pt (LIST (NTH 0 vars) (NTH 1 vars)))
        (ADDGRID (TRANS (NTH 0 pt) (NTH 1 pt) (NTH 2 vars)) nil)
        (SETQ oldp pt))
      ((AND (= cmd '$ARC) (> (LOGAND optype 2) 0)) nil)
      ((AND (= cmd '$ARC) (> (LOGAND optype 8) 0)) ; If it's cutting
        (SETQ pt (LIST (NTH 0 vars) (NTH 1 vars) (NTH 2 vars)))
        (ADDGRID (TRANS (CAR pt) (CADR pt) (CADDR pt)) nil)
        (SETQ oldp pt))
      ((= cmd '$HOLE) (ADDGRID (TRANS (NTH 0 vars) (NTH 1 vars) (NTH 2 vars)) T))
      ((AND (= cmd '$MARKON) (> (LOGAND optype 4) 0))
        (SETQ oldp (LIST (NTH 0 vars) (NTH 1 vars) (NTH 2 vars)))
        (ADDGRID (TRANS (NTH 0 vars) (NTH 1 vars) (NTH 2 vars)) T))
      ((AND (= cmd '$TEXT) (> (LOGAND optype 2) 0))
        (ADDGRID (TRANS (NTH 1 vars) (NTH 2 vars) (NTH 3 vars)) T))
    )
  )
)

(DEFUN $makegrid (/ cmdm varsm subnr prog pp_basex pp_basey pp_rotate pp_sortid allpoints optype)
   ; optype means following: 1=Drilling, 2=Marking, 4=Prepiercing, 8=Cutting, 16=Inkjet
  (FOREACH optype (LIST 1 2 4 8 16)
    (FOREACH tset mainprog
      (FOREACH mainline tset
        (SETQ cmdm (CAR mainline))
        (SETQ varsm (CADR mainline))
        (IF (= cmdm '$CALL)
          (PROGN
            (SETQ subnr (NTH 0 varsm) pp_basex (NTH 1 varsm) pp_basey (NTH 2 varsm) pp_rotate (NTH 3 varsm) pp_sortid (NTH 4 varsm))
            (SETQ $sortid pp_sortid)
            (SETQ prog (NTH subnr subprogs))
            (FOREACH geometry (CDR prog) ; CDR remove the initial part information.
              (MEASUREGEOMETRY geometry)
            )
          )
        )
      )
    )
  )
  ;(SETQ allpoints (KDTREE-FINDCLOSEST pp_kdtree *Partsboxcenter* (* (MAX *Partsboxwidth* *Partsboxheight*) 0.6) pp_kdmax))
  ;(FOREACH s (CDR (POINTSORT (CONS pp_kdstart allpoints) 4))
  (FOREACH s (REVERSE pp_kdlist)
    ($MEASURE (CAR s) (CADR s) (CADDR s))
  )
  (SETQ pp_kdlist nil)
)

(DEFUN $makedatapoints (/ tset mainprog cmdm varsm subnr pp_basex pp_basey pp_rotate pp_sortid prog geometry cmd vars)
  (FOREACH tset mainprog
    (FOREACH mainline tset
      (SETQ cmdm (CAR mainline))
      (SETQ varsm (CADR mainline))
      (IF (= cmdm '$CALL)
        (PROGN
          (SETQ subnr (NTH 0 varsm) pp_basex (NTH 1 varsm) pp_basey (NTH 2 varsm) pp_rotate (NTH 3 varsm) pp_sortid (NTH 4 varsm))
          (SETQ $sortid pp_sortid)
          (SETQ prog (NTH subnr subprogs))
          (FOREACH geometry (CDR prog) ; CDR remove the initial part information.
            (FOREACH clline geometry
              (SETQ cmd (CAR clline))
              (SETQ vars (CADR clline))
              (IF (= cmd '$DATAPOINT) ($DATAPOINT vars))
            )
          )
        )
      )
    )
  )
)


(DEFUN delay (value)
  (IF (AND (NUMBERP value) (> value 0.1)) (SIM-DELAY value))
)
; $BEVELSETUP: Specify primary and secundary vectors once in the beginning Rad 3298
; TRANSVEC: Rotate the unkerf vec around verical to obtain correct TAC. Not used in Bevels
; TILTDIR: Select best of to solutions of the vector Rad 3448
; BEVELANG: Set the spitup angle for ARCS 3680

(DEFUN $bevelsetup (/ pol name) ; Setup pp_bevelprim pp_bevelsec unkerfs
  (IF (= *HeadName* "") (SETQ *HeadName* nil))
  (COND
    ((= *HeadType* 0)
      (SETQ name "STATIC")
      (IF *HeadName* (SETQ name *HeadName*))
      (SIM3D-SETUP name "0")
      (SETQ pp_bevelprim (LIST 0 1 0))
      (SETQ pp_bevelsec (LIST 1 0 0)))
    ((= *HeadType* 1) ; Typ Vertival Horisontal
      (SETQ pp_bevelprim (LIST 0 0 -1))
      (SETQ name "Z0Y0")
      (IF *HeadName* (SETQ name *HeadName*))
      (COND
        ((= *HeadDir* 0) ; används av Brell och KUKA Robot
          ;(SETQ pp_bevelprim (LIST 0 0 -1)) ; Detta värde var 0 0 -1 BRELL=0 0 1
          (SETQ pp_bevelsec (LIST 0 -1 0)) ; Detta värde var 0 -1 0 BRELL=0 1 0
          (SIM3D-SETUP name "0"))
        ((= *HeadDir* 1)
          (SETQ pp_bevelsec (LIST 1 0 0))
          (SIM3D-SETUP name "90"))
      ))

    ((= *Headtype* 2) ; Same as Tops and Resato
      (SETQ pp_bevelprim (LIST 0 0 -1))
      (SETQ pol (POLAR (LIST 0 0) (/ (* (- 90 *HeadTiltAngle*) PI) 180.0) 1))
      (COND
        ((= *HeadTiltAngle* 30) (SETQ name "Z0ZX30"))
        ((= *HeadTiltAngle* 34) (SETQ name "Z0ZX34")) ; Hette STM
        ((= *HeadTiltAngle* 35) (SETQ name "Z0ZX34")) ; Jag vet inte om detta exempel finns. Kanske hos Artel
        ((= *HeadTiltAngle* 36) (SETQ name "Z0ZX34")) ; TeenKing
        ((= *HeadTiltAngle* 45) (SETQ name "Z0ZX45"))
        ((= *HeadTiltAngle* 60) (SETQ name "Z0ZX60"))
        (T                      (SETQ name "Z0ZX45"))
      )
      (IF *HeadName* (SETQ name *HeadName*))
      (COND
        ((= *HeadDir* 0)
          (SIM3D-SETUP name "0")
          (SETQ pp_bevelsec (LIST (- (CAR pol)) 0 (- (CADR pol)))))
        ((= *Headdir* 1)
          (SIM3D-SETUP name "90")
          (SETQ pp_bevelprim (LIST 0 0 -1))
          (SETQ pp_bevelsec (LIST 0 (- (CAR pol)) (- (CADR pol)))))
        ((= *Headdir* 2)
          (SIM3D-SETUP name "180")
          (SETQ pp_bevelsec (LIST (CAR pol) 0 (- (CADR pol)))))
        ((= *Headdir* 3)
          (SIM3D-SETUP name "270")
          (SETQ pp_bevelsec (LIST 0 (CAR pol) (- (CADR pol)))))
      )
    )
    ((= *Headtype* 3) ; Same as Waterjet Sweden
      (SETQ pol (POLAR (LIST 0 0 0) (/ (* (- 90 *HeadTiltAngle*) PI) 180.0) 1))
      (SETQ name "ZX50Y0")
      (IF *HeadName* (SETQ name *HeadName*))
      (COND
        ((= *HeadDir* 0)
          (SETQ pp_bevelprim (LIST (CAR pol) 0 (- (CADR pol))))
          (SETQ pp_bevelsec (LIST 0 -1 0))
          (SIM3D-SETUP name "0"))
        ((= *HeadDir* 1)
          (SETQ pp_bevelprim (LIST 0 (CAR pol) (- (CADR pol))))
          (SETQ pp_bevelsec (LIST 1 0 0))
          (SIM3D-SETUP name "90"))
        ((= *HeadDir* 2)
          (SETQ pp_bevelprim (LIST (- (CAR pol)) 0 (- (CADR pol))))
          (SETQ pp_bevelsec (LIST 0 1 0))
          (SIM3D-SETUP name "180"))
        ((= *Headdir* 3)
          (SETQ pp_bevelprim (LIST 0 (- (CAR pol)) (- (CADR pol))))
          (SETQ pp_bevelsec (LIST -1 0 0))
          (SIM3D-SETUP name "270"))
      ))
    ((= *HeadType* 4) ; I-HEAD
      (SETQ pol (POLAR (LIST 0 0 0) (/ (* (- 90 *HeadTiltAngle*) PI) 180.0) 1))
      (SETQ name "TILTER")
      (IF *HeadName* (SETQ name *HeadName*))
      (COND
        ((= *HeadDir* 0)
          (SETQ pp_bevelprim (LIST (CAR pol) 0 (CADR pol)))
          (SETQ pp_bevelsec (LIST 0 -1 0))
          (SIM3D-SETUP name "0"))
        ((= *HeadDir* 1)
          (SETQ pp_bevelprim (LIST 0 (CAR pol) (CADR pol)))
          (SETQ pp_bevelsec (LIST 1 0 0))
          (SIM3D-SETUP name "90"))
        ((= *HeadDir* 1) ; ORGINAL
          (SETQ pp_bevelprim (LIST 0 (- (CAR pol)) (- (CADR pol))))
          (SETQ pp_bevelsec (LIST 1 0 0))
          (SIM3D-SETUP name "90"))
        ((= *HeadDir* 2)
          (SETQ pp_bevelprim (LIST (CAR pol) 0 (- (CADR pol))))
          (SETQ pp_bevelsec (LIST 0 1 0))
          (SIM3D-SETUP name "180"))
        ((= *HeadDir* 3) ;Like I-HEAD
          (SETQ pp_bevelprim (LIST 0 (CAR pol) (- (CADR pol))))
          (SETQ pp_bevelsec (LIST 1 0 0))
          (SIM3D-SETUP name "270"))
      ))
    ((= *HeadType* 5) ; PTV-type
      (SETQ name "X0Y0")
      (IF *HeadName* (SETQ name *HeadName*))
      (COND
        ((= *HeadDir* 0)
          (SETQ pp_bevelprim (LIST -1 0 0))
          (SETQ pp_bevelsec (LIST 0 -1 0))
          (SIM3D-SETUP name "0"))
        ((= *Headdir* 1)
          (SETQ pp_bevelprim (LIST 0 -1 0))
          (SETQ pp_bevelsec (LIST 1 0 0))
          (SIM3D-SETUP name "90"))
       ))
   ((= *HeadType* 6)
    ; (SETQ pp_bevelprim (LIST 0 -0.178802215 -0.983885038)) ; 10.3 degree
     (SETQ pp_bevelprim (LIST 0 -0.17364817766693033 -0.98480775301220802)) ; 10 DEGREE TILT SAME FOR 45 and 60 degree
     ;(SETQ pp_bevelsec (LIST 0.70710678118654757 -0.12278780396997285 -0.69636424032001898)); 45 degree construction
     (SETQ pp_bevelsec (LIST 0.86602540378443871 -0.086824088833465152 -0.49240387650610395)) ; 60 degree construction
     (SIM3D-SETUP "XD" "180"))
   ((= *HeadType* 7)
     (SETQ name "ZX38Y0")
     (IF *HeadName* (SETQ name *HeadName*))
     (COND
       ((= *HeadDir* 0)
         (SETQ pp_bevelprim (LIST -0.788 0 0.6157))
         (SETQ pp_bevelsec (LIST 0 1 0))
         (SIM3D-SETUP name "0"))
       ((= *HeadDir* 1)
         (SETQ pp_bevelprim (LIST 0 -0.788 0.6157))
         (SETQ pp_bevelsec (LIST -1 0 0))
         (SIM3D-SETUP name "90"))
       ((= *HeadDir* 2)
         (SETQ pp_bevelprim (LIST 0.788 0 0.6157))
         (SETQ pp_bevelsec (LIST 0 -1 0))
         (SIM3D-SETUP name "180"))
       ((= *HeadDir* 3)
         (SETQ pp_bevelprim (LIST 0 0.788 0.6157))
         (SETQ pp_bevelsec (LIST 1 0 0))
         (SIM3D-SETUP name "270"))
      )
    )
  )
  (SETQ *HeadName* name)
;  (PRINC (STRCAT "(BEVELSEC=" (TOSTR pp_bevelsec) ")\n"))
)

(DEFUN transvec (vec / vecdir veclen speeddiff newveclen tmp fac); Rotate the unkerf vec around verical to obtain correct TAC
  (IF (NOT vec) (SETQ vec (LIST 0 0 -1)))
  (SETQ vecdir (ANGLE (LIST 0 0) vec))    ; vektorns riktning i 2D
  (SETQ veclen (DISTANCE (LIST 0 0) vec)) ; vektorns längd i 2D
  (SETQ $slope (ATAN veclen (ABS (CADDR vec))))
  (IF (AND (NOT pp_precheck) (> $slope $maxslope)) (SETQ $maxslope $slope))
  (SETQ vec (LIST (- (* (CAR vec) (COS pp_rotate)) (* (CADR vec) (SIN pp_rotate)))
        (+ (* (CADR vec) (COS pp_rotate)) (* (CAR vec) (SIN pp_rotate))) (CADDR vec)))
)

(DEFUN tiltdir (vec / tiltvalues a b atest spant average midrotate target olddiff diff slope pp_xmodsim pp_xoffsetsim pp_ymodsim pp_yoffsetsim atmp btmp)
  (SETQ select nil)
  (SETQ pp_ahead 0)
  (COND
    ((NOT vec) nil)
    ((= *HeadType* 0)
      (SETQ vec nil))
    ((= *HeadType* 1) ;type MILL
      (SETQ tiltv (CALCTOOL5X pp_bevelprim pp_bevelsec vec))
      (IF (NOT tiltv) (PROGN (ALERT (LTF "Cutting angle too Large")) (QUIT "*Cancel*")))
      (IF (= (LENGTH tiltv) 2) (SETQ tiltv (LIST (CAR tiltv) (CADR tiltv) (IF (MINUSP (CAR tiltv)) (+ (CAR tiltv) PID) (- (CAR tiltv) PID)) (- (CADR tiltv)))))
      ;(SETQ pp_ahead 0)
      ;(SETQ pp_ahead (* 0.5 (ANGDIFF (CAR tiltv) (CADDR tiltv))))
      (SETQ tiltvall (LIST (LIST (+ (- (CAR tiltv)) PID) (- (CADR tiltv)))
                           (LIST (- (CAR tiltv)) (- (CADR tiltv)))
                           (LIST (- (- (CAR tiltv)) PID) (- (CADR tiltv)))
                           (LIST (+ (- (CADDR tiltv)) PID) (-(CADDDR tiltv)))
                           (LIST (-(CADDR tiltv)) (-(CADDDR tiltv)))
                           (LIST (- (-(CADDR tiltv)) PID) (- (CADDDR tiltv)))))
      (SETQ pp_newvecdir (ANGLE (LIST 0 0) vec)))
    ((= *Headtype* 2) ; Type TOPS and Resato
      (SETQ tiltv (CALCTOOL5X pp_bevelprim pp_bevelsec vec))
      (IF (NOT tiltv) (PROGN (ALERT (STRCAT (LTF "Cutting angle too Large") ":" (TOSTR tiltv) " :" (TOSTR vec))) (QUIT "*Cancel*")))
      (IF (= (LENGTH tiltv) 2) (SETQ tiltv (LIST (CAR tiltv) (CADR tiltv) (CAR tiltv) (CADR tiltv))))
      (SETQ pp_ahead (* 0.5 (ANGDIFF (CAR tiltv) (CADDR tiltv))))
      (SETQ tiltvall (LIST (LIST (+ (- (CAR tiltv)) PID) (- (CADR tiltv))) ; Det var en lista till (- PID)
                           (LIST (- (CAR tiltv)) (- (CADR tiltv)))
                           (LIST (- (- (CAR tiltv)) PID) (- (CADR tiltv)))
                           (LIST (+ (- (CADDR tiltv)) PID) (-(CADDDR tiltv))) ; Det var en lista till (- PID) ; denna list har 3 samt vissa andra oxå
                           (LIST (-(CADDR tiltv)) (-(CADDDR tiltv)))
                           (LIST (- (-(CADDR tiltv)) PID) (- (CADDDR tiltv)))))) ; Det var en tal till PID
    ((<= *HeadType* 5); If WJS,I-HEAD or PTV type where it's only one solution..
      (SETQ tiltv (CALCTOOL5X pp_bevelprim pp_bevelsec vec))
      (IF (< (MAX (ABS (CAR tiltv)) (ABS (CADR tiltv)))
             (MAX (ABS (CADDR tiltv)) (ABS (CADDDR tiltv))))
        (SETQ tiltv (LIST (CAR tiltv) (CADR tiltv)))
        (SETQ tiltv (LIST (CADDR tiltv) (CADDDR tiltv)))))
      ;(WRITE (TOSTR tiltv))
      ;(IF (> (ABS (CAR tiltv)) 2) (SETQ tiltv (LIST (CADDR tiltv) (CADDDR tiltv)))))
    ((= *Headtype* 6) ; Flow XD
      (SETQ tiltv (CALCTOOL5X pp_bevelprim pp_bevelsec vec))
      (IF (= (LENGTH tiltv) 2) (SETQ tiltv (LIST (CAR tiltv) (CADR tiltv) (CAR tiltv) (CADR tiltv))))
      (SETQ tiltvall (LIST (LIST (+ (- (CAR tiltv)) PID) (- (CADR tiltv)))
                           (LIST (- (CAR tiltv)) (- (CADR tiltv)))
                           (LIST (- (- (CAR tiltv)) PID) (- (CADR tiltv)))
                           (LIST (+ (- (CADDR tiltv)) PID) (-(CADDDR tiltv)))
                           (LIST (-(CADDR tiltv)) (-(CADDDR tiltv)))
                           (LIST (- (-(CADDR tiltv)) PID) (- (CADDDR tiltv))))))

    ((= *HeadType* 7) ; TeenKing
      (SETQ tiltv (CALCTOOL5X pp_bevelprim pp_bevelsec vec))
      (IF (> (ABS (CAR tiltv)) 2) (SETQ tiltv (LIST (CADDR tiltv) (CADDDR tiltv)))))
  )

  (COND
    ((NOT vec) (LIST 0 0 0 0))
    ;(pp_rakbevel (LIST 0 0 0 0))
    ((= *Headtype* 0) (LIST 0 0 0 0))
    ((= *HeadType* 3) ; WJS Head old type of head. This has only one valid option
      (COND
        ((= *Headdir* 0)
          (LIST (CAR tiltv) (CADR tiltv) (CAR tiltv) (CADR tiltv)))
        ((= *Headdir* 1)
          (LIST (CAR tiltv) (CADR tiltv) (CAR tiltv) (CADR tiltv)))
        ((= *Headdir* 2)
          (LIST (CAR tiltv) (CADR tiltv) (CAR tiltv) (CADR tiltv)))
        ((= *Headdir* 3)
          (LIST (CAR tiltv) (CADR tiltv) (CAR tiltv) (CADR tiltv)))
      ))
    ((= *Headtype* 4) ; TILTER This head has only one valid option
      (COND
        ((= *Headdir* 0) ; OK
          (LIST (CAR tiltv) (CADR tiltv) (- (CAR tiltv)) (CADR tiltv)))
        ((= *Headdir* 1) ; OK
          (LIST (CAR tiltv) (CADR tiltv) (- (CAR tiltv)) (CADR tiltv)))
        ((= *Headdir* 2)
          (LIST (CAR tiltv) (CADR tiltv) (CAR tiltv) (CADR tiltv)))
        ((= *Headdir* 3)
          (LIST (CAR tiltv) (CADR tiltv) (CAR tiltv) (- (CADR tiltv))))
      ))
    ((= *Headtype* 5) ; PTV. This head has only one valid option

      (LIST (CAR tiltv) (CADR tiltv) (CAR tiltv) (CADR tiltv)))
    ((= *Headtype* 6) ; XD. Flow XD
     (IF (< (ABS (CAR tiltv)) (ABS (CADDR tiltv)))
        (LIST (- (CAR tiltv)) (- (CADR tiltv)) (CAR tiltv) (CADR tiltv))
        (LIST (- (CADDR tiltv)) (- (CADDDR tiltv)) (CADDR tiltv) (CADDDR tiltv))))
    ((= *Headtype* 7) ; TeenKing
      (COND
        ((= *Headdir* 0) ; OK
          (LIST (CAR tiltv) (CADR tiltv) (CAR tiltv) (CADR tiltv)))
        ((= *Headdir* 1) ;OK
          (LIST (CAR tiltv) (CADR tiltv) (CAR tiltv) (CADR tiltv)))
        ((= *Headdir* 2)
          (LIST (CAR tiltv) (CADR tiltv) (CAR tiltv) (CADR tiltv)))
        ((= *Headdir* 3)
          (LIST (CAR tiltv) (CADR tiltv) (CAR tiltv) (CADR tiltv)))
      ))
    ((OR (= *HeadType* 1) (= *HeadType* 2)  (AND (= *HeadType* 6) pp_dobevel)); MILL,TOPS and Resato and XD (if not using TAC ?)
      (IF (OR pp_superabinit (AND pp_abinit *HeadPrimaryAxisLimitations*)) ; Superabinit is set to T in beginning of IGEMS.LSP
        (PROGN
          (SETQ pp_superabinit nil)
          (COND
            (pp_precheck  ; Precheck the start is as close to zero as possible
              (SETQ atest 1000)
              (COND
                ((= *HeadSecondaryPrefer* 0) ; use only negative side of secondary axis
                  (FOREACH s tiltvall (IF (AND (< (ABS (CAR s)) atest) (<= (CADR s) 0.00001)) (SETQ atest (CAR s) select s))))
                ((= *HeadSecondaryPrefer* 1) ; Use only positive side of secondary axis
                  (FOREACH s tiltvall
                    (IF (AND (< (ABS (CAR s)) atest) (>= (CADR s) 0.0)) (SETQ atest (CAR s) select s))))
                ((= *HeadSecondaryPrefer* 2) ; Use both side of secondary axis
                  (FOREACH s tiltvall (IF (< (ABS (CAR s)) atest) (SETQ atest (CAR s) select s))))
              )
            )
            (T ; Select correct start value
              (SETQ select nil)
              (IF (NOT pp_amin) (SETQ pp_amin 0 pp_amax 0 pp_astart 0))
              (SETQ spant (- pp_amin pp_amax))
              (SETQ average (* (+ pp_amin pp_amax) 0.5))
              (SETQ midrotate  (* (+ *HeadPrimaryMin* *HeadPrimaryMax*) 0.5))
              (SETQ target (+ pp_astart (- midrotate average)))
              (SETQ olddiff 1000)
              (FOREACH s tiltvall
                (SETQ diff (ABS (- (CAR s) target)))
                (COND
                  ((OR (< (CAR s) *HeadPrimaryMin*) (> (CAR s) *HeadPrimaryMax*)) nil)
                  ((AND (= *HeadSecondaryPrefer* 0) (< diff olddiff) (<= (CADR s) 0.0001)) ;Use only negative side o secondary axis
                    (SETQ olddiff diff select s))
                  ((AND (= *HeadSecondaryPrefer* 1) (< diff olddiff) (>= (CADR s) 0.0))   ;Use only positive side o secondary axis
                    (SETQ olddiff diff select s))
                  ((AND (= *HeadSecondaryPrefer* 2) (< diff olddiff)) ;Use both side of secondary axis
                    (SETQ olddiff diff select s))
                )
              )
            )
          )
          (SETQ pp_aadd 0.0)
          (IF (AND pp_abinit pp_flipwindup (NOT pp_precheck))
            (PROGN
              ;(WRITE (STRCAT "TILTVALL:" (TOSTR tiltvall)))
              ;(WRITE (STRCAT "SELECT:" (TOSTR select)))
              ;(WRITE (STRCAT "A:" (ATS (CAR select)) " B" (ATS (CADR select))))
              (SETQ aselect (CAR select) bselect (CADR select))
              (SETQ acheck (IF (> atmp 0) 1000 -1000))
              (IF (> aselect 0) ; Check for a value that are as high as possible but lower than aselect
                (PROGN
                  (SETQ anew -1000)
                  (FOREACH s tiltvall
                    (SETQ atest (CAR s))
                    (IF (AND (> atest anew) (< atest aselect)) (SETQ anew atest newselect s))
                  )
                )
                (PROGN
                  (SETQ anew 1000)
                  (FOREACH s tiltvall
                    (SETQ atest (CAR s))
                    (IF (AND (< atest anew) (> atest aselect)) (SETQ anew atest newselect s))))
              )
              (SETQ select newselect)
              ;(WRITE (STRCAT "SELECT:" (TOSTR select)))
            )
          )
          (SETQ pp_abinit nil)
          (SETQ pp_anew (CAR select) pp_bnew (CADR select))
          (SETQ pp_aval pp_anew pp_bval pp_bnew)
          (LIST pp_aval pp_bval (- pp_aval) (- pp_bval))) ; End of pp_abinit


        ; runs select the best choice from all options
        (PROGN
          (SETQ adiffbest 99999.9 bdiffbest 9999.0)
          ; Method 0: Closest B where B must be negative if 2 is almost the same take the closest A
          ; Method 1: Closest B where B must be positive if 2 is almost same take the closest A
          ; Method 2: Closest B. If more than one alterenative is near then take closest A
          ; Method 3: Closest A. If mpre than one alternative is near then take the closest B
          ;(WRITE (STRCAT "ALL:" (TOSTR tiltvall)))
          (SETQ sumdiffbest 10000)
          ;(SETQ lessrot 1000)
          (FOREACH s tiltvall
            (SETQ adiff (- pp_aval (CAR s))) ; pp_aval is the previous used A
            (SETQ bdiff (ANGDIFF pp_bval (CADR s))) ; pp_bval is the previous used B
            (COND
              ((= *HeadSecondaryPrefer* 0) ; Closest B where B must be negative if 2 is almost the same take the closest A.
                ;(SETQ slope (ATAN (DISTANCE (LIST 0 0) vec) (ABS (CADDR vec))))
                (COND
                  ((> (CADR s) 0.00001) nil)
                 ; ((> slope *HeadMinTilt*)
                 ;   (IF (< (ABS (CAR s)) lessrot)
                 ;     (PROGN
                 ;       (SETQ lessrot (ABS (CAR s)) select s))))
                  ((AND (EQUAL (ABS bdiff) (ABS bdiffbest) 0.05) (< (ABS adiff) (ABS adiffbest)))
                    (SETQ bdiffbest bdiff adiffbest adiff select s))
                  ((< (ABS bdiff) (ABS bdiffbest))
                    (SETQ bdiffbest bdiff adiffbest adiff select s))
                ))
              ((= *HeadSecondaryPrefer* 1) ; Closest B where B must be positive if 2 is almost same take the closest A
                ;(WRITE (STRCAT "ALT:" (ATS (CAR s)) " " (ATS (CADR s)) " ADIFF:" (ATS adiff) " BDIFF:" (ATS bdiff)))
                ;(SETQ slope (ATAN (DISTANCE (LIST 0 0) vec) (ABS (CADDR vec))))
                (COND
                  ((MINUSP (CADR s)) nil)
                  ;((> slope *HeadMinTilt*))
                  ;  (IF (< (ABS (CAR s)) lessrot)
                  ;    (PROGN
                  ;      (SETQ lessrot (ABS (CAR s)) select s))))
                  ((AND (EQUAL (ABS bdiff) (ABS bdiffbest) 0.05) (< (ABS adiff) (ABS adiffbest)))
                    (SETQ bdiffbest bdiff adiffbest adiff select s))
                  ((< (ABS bdiff) (ABS bdiffbest))
                    (SETQ bdiffbest bdiff adiffbest adiff select s))
                ))
              ((= *HeadSecondaryPrefer* 2) ; Testing with new algorithm
                (SETQ sumdiff (+ (* (ABS adiff) 2.0) (* (ABS bdiff) 1.0)))
                (IF (< sumdiff sumdiffbest)
                  (PROGN
                    (SETQ sumdiffbest sumdiff)
                    (SETQ select s))))
              (T (WRITE "Unsuported method"))
            )
          )
          (SETQ pp_anew (CAR select) pp_bnew (CADR select))
          ;(WRITE (STRCAT "SELECT:" (ATS (CAR select)) " " (ATS (CADR select))))
          (IF (EQUAL pp_bnew 0 0.001) (SETQ pp_anew pp_aval))
          ;(IF (AND (NOT pp_trecheck) pp_abold) (WRITE (STRCAT (TOSTR (CADR pp_abold)) " " (ATS (CADR pp_abold)))))
          ; Below is to check if Rewind is needed.
          (COND
            ((NOT *HeadPrimaryAxisLimitations*) nil)
            ((NOT *InternalRewind*) nil)
            (pp_precheck nil)
            ((>= (+ pp_anew pp_aadd) *HeadPrimaryMax*)
              (SETQ pp_aadd (- pp_aadd PID))
              ($REWIND (+ pp_aval pp_aadd) pp_bval (- (+ pp_aval pp_aadd)) (- pp_bval)))
            ((<= (+ pp_anew pp_aadd) *HeadPrimaryMin*)
              (SETQ pp_aadd (+ pp_aadd PID))
              ($REWIND (+ pp_aval pp_aadd) pp_bval (- (+ pp_aval pp_aadd)) (- pp_bval)))
          )
          (COND
            ((>= pp_anew PID) (SETQ pp_anew (- pp_anew PID) pp_aadd (+ pp_aadd PID))) ; Adds pp_aadd 360 degree
            ((<= pp_anew (- PID)) (SETQ pp_anew (+ pp_anew PID) pp_aadd (- pp_aadd PID))) ; Subtracts pp_aadd 360 degree
          )
           ; NOTE! Line below is now longer used, (added nil) we don't know how to solve the combination with Singularities and to only use one side of the secodary axis.
          (IF (AND pp_abold (< *HeadSecondaryPrefer* 2) (> (ABS adiffbest) (DEGTORAD 120)) (<= (ABS pp_bold) (DEGTORAD 0.2)) (MEMBER $cmd (LIST '$LINE)))
            (SETQ sprewind T))
          (IF (AND pp_abold nil (< *HeadSecondaryPrefer* 2) (> (ABS adiffbest) (DEGTORAD 120)) (<= (ABS pp_bold) (DEGTORAD 0.2)) (MEMBER $cmd (LIST '$LINE '$ARC))) ; NOTE!!
            (PROGN
              (SETQ slope $slope)
              (SETQ $slope 0.0)
              ($REWIND pp_anew 0.0 pp_anew 0.0)
              (SETQ $slope slope)))
          (SETQ pp_aval pp_anew pp_bval pp_bnew)
          (LIST (+ pp_aval pp_aadd) pp_bval (- (+ pp_aval pp_aadd)) (- pp_bval)))))
  )
)

(DEFUN $rewind (a b aa bb / pp_fe)
  (IF (NOT pp_fe) (SETQ pp_fe 100))
  (SETQ $a a $b b)
  (SETQ $amotor $a $bmotor $b)
  (SETQ $ahead pp_ahead)
  (COND
    ((= $kinematic 2) ; Direction of cut
      (IF (MINUSP $b)
        (PROGN
          (SETQ $a (- (+ $a pp_ahead) PIH))
          (SETQ $b (- (ABS $slope))))
        (PROGN
          (SETQ $a (+ (- $a pp_ahead) PIH))
          (SETQ $b (ABS $slope)))))
    ((= $kinematic 3) ; Direction of jet
      (IF (MINUSP $b)
        (PROGN
          (SETQ $a (+ $a pp_ahead))
          (SETQ $b (- (ABS $slope))))
        (PROGN
          (SETQ $a (- $a pp_ahead))
          (SETQ $b (ABS $slope)))))
  )
  (SETQ pp_abold (LIST $a $b))
  (IF *HeadPrimaryReversed* (SETQ $a (- $a)))
  (IF *HeadSecondaryReversed* (SETQ $b (- $b)))
  (SIM-OFF)
  (IF (= *Processmode* 4) (SIM-INFOTEXT ""))
  (SIM3D-TILT aa bb $arel $brel)
  (REWIND)
  (SIM-ON T pp_fe)
  (IF (= *Processmode* 4) (SIM-INFOTEXT ""))
)

(DEFUN rewind ()
  nil
)

(DEFUN NameTrim (name)
  (FILE-NAMEONLY name T)
)


(DEFUN NameTrim (name / txt pos ch)
  (IF (NOT name) (SETQ name ""))
  (SETQ pos 1 len (STRLEN name) txt "")
  (WHILE (<= pos len)
    (SETQ ch (SUBSTR name pos 1))
    (COND
      ((= ch ":") (SETQ txt ""))
      ((= ch "/") (SETQ txt ""))
      ((= ch (CHR 92))(SETQ txt ""))
      (T          (SETQ txt (STRCAT txt ch)))
    )
    (SETQ pos (+ pos 1))
  )
  (SETQ txt (SUBSTR txt 1 (- (STRLEN txt) (STRLEN (ExtTrim txt)))))
  (EVAL txt)
)

(DEFUN ExtTrim (name / txt pos ch ext)
  (SETQ pos (STRLEN name) txt "" ext "")
  (WHILE (> pos 0)
    (SETQ ch (SUBSTR name pos 1))
    (COND
      ((= ch ".")  (SETQ ext txt pos -1))
      ((= ch "/")  (SETQ ext "" pos -1))
      ((= ch (CHR 92)) (SETQ ext "" pos -1))
      (T           (SETQ txt (STRCAT ch txt)))
    )
    (SETQ pos (- pos 1))
  )
  (IF (> (STRLEN ext) 0) (SETQ ext (STRCAT "." ext)))
  (EVAL ext)
)

(DEFUN onetobit (nr)
  (COND
    ((= nr 1) 1)
    ((= nr 2) 2)
    ((= nr 3) 4)
    ((= nr 4) 8)
    ((= nr 5) 16)
    ((= nr 6) 32)
    ((= nr 7) 64)
    ((= nr 8) 128)
    (T 1)
  )
)

(DEFUN funbrowser (name) (SETQ funlist (CONS name funlist)))(PRINC "..OK\n")
