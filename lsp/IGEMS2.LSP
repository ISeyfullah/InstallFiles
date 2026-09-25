(PRINC "\nLoading IGEMS2.LSP [2026.June.26] 14:14") ; 

;I did new changes
; Kolla Measuring in advance  New Version 2024-06-26
; Ett sätt att sätta nollan på ovansidan även om man inte har höjdsensor.
(SETQ debug T)
(SETQ pp_xmod 0 pp_ymod 0) ; How much X and Y should be changed because of part should be cut with another tool than T1. Change the coordinates in the CNC file.
(SETQ pp_extrax 0 pp_extray 0) ; Add this value to support special equipment like Drilling, Special marking, Inkjet
(SETQ pp_xmodsim 0 pp_ymodsim 0) ; Add this values to simulator to support special equipment like Drilling, Marking, Inkjet
(SETQ pp_maxpartid -1)
(SETQ pp_pumpoff T) ; The pump is not activated
(SETQ $index 0) ; Counter for toolchange
; Orginal antal rader i IGEMS.LSP: 4953
; June 5: 3089,  3012 (60.1%) June 18: 3017
; Sept 9: 3100, Sept 11: 2989 Sept 18: 2927
; Nov 2: 3049, Nov 11:2921, Nov 13: 2894 March 10: 2998
; Aug 3:3019
; Augusti 2023: 3751
;(SETQ *TiltOnRapid* T) This handle if the simulation should show the tilt during the simulation.
(SETQ pp_extraxsim 0 pp_extraysim 0)
(SETQ $a 0 $b 0 $c 0)
(SETQ $sensor 0)
(SETQ info nil)
(SETQ pp_offset 0)
(SETQ PID (* PI 2.0)) ; PIDouble
(SETQ PIH (* PI 0.5)) ; PIHalf
(SETQ $a 0.0 $b 0.0)
(SETQ $slope 0)
(SETQ $initdown T)
(SETQ $vec (LIST 0 0 -1))
(SETQ $vector (LIST 0 0 -1))
(SETQ *Speedfactor* 1.0) ; This factor should be 1.0 but could be modified from the postprocessor. Note the ircular piercing is currently also affected by this value.
(SETQ pp_cutdirection 0)
(SETQ *MaxforbiddenTilt* 0.0) ; On heads that only can make positive or negative, can accept little
(SETQ pp_shownext 2000)
(SETQ *IGEMS2* T)
(SETQ *SIM-ADDX* 0.0)
(SETQ *SIM-ADDY* 0.0)
(SETQ $toolchanges 0)
(SETQ $startindex 0) ; This value will be increased by 1 for each pre-piercing and piercing and marking
(SETQ pp_allpos (LIST 0.0 0.0 0.0))
(SETQ pp_oldpos (LIST 0 0 0))
(SETQ pp_allrot (LIST 0 0 0))
(SETQ pp_oldrot (LIST 0 0 0))
(SETQ pp_toolcords nil) ; This is an accociation list ((1 (x y z)) (2 (x y z))) with the first coordinate after the toolchange. Created in CHKALL and ised in $toolset
(SETQ $datedue 30301224)
(SETQ *DragStartAt* (DEGTORAD 2.0)) ; Tilt more than this will use dragging sensor else stamping sensor.
(SETQ *HoursOnYear* 1800)
(SETQ totsensor 0.0)
(SETQ first T)
(SETQ *WaterSpeedQuality* (LIST 1.5 1.24 1.0 0.75 0.5)) ;JB
(SETQ *WaterSpeedFactor* 1.0) ;JB

; SIM först
; Text sen
(SETQ ppp_sim1 nil) ; Generate information to 3D-5X
(SETQ ppp_sim2 nil) ; Generate information to 2D
(SETQ ppp_sim3 nil) ; generate information obout vector angle
(SETQ *MACHINEEXTRASCRIPT* "")

(SETQ pp_xdmax -99999.0 pp_xdmin 99999.0 pp_ydmax -99999.0 pp_ydmin 99999.0)

;(SETQ ltfspar ltf) (DEFUN ltf (txt) (IF (NOT (MEMBER txt ltflist)) (SETQ ltflist (CONS txt ltflist))) (LTFSPAR txt))
;(DEFUN ltfsave () (ALERT "Saving")(SETQ fw (OPEN (STRCAT (GETVAR  "PATHROOT") "/LSP/TRANS.TXT") "a"))(FOREACH s (REVERSE ltflist) (WRITE-LINE s fw))  (CLOSE fw))

(DEFUN $init$vars ()
  (SETQ $machine *MachineName*)
  (SETQ $machinetype *MachineType*)
  (SETQ $cando5x *Has5XKinematics*)
  (SETQ $cando6x *HasSixAxis*)
  (SETQ $candodrill *DrillingTools*)
  (SETQ $candomarking *MarkingType*)
  (SETQ $candoinkjet *Inkjet*)
  (SETQ $processmode *Processmode*)
  (SETQ $headname *HeadKinematicName*)
  (SETQ $digfile (GETVAR "DIGFILE"))
)


(DEFUN $initialize (first *TubeMode* bevel editmode / upscale downscale tiptext cutflow a lowz maxz )
  (PRINC "\nLoading strategy, machine and material setting..")
  (LOADMACMAT)
  (PRINC "\n")
  ($INIT$VARS)


  ; Angle for 5-axis head when it is not in use.
  (SETQ pp_parkrot (LIST (DEGTORAD *HeadPrimaryParkingAngle*) 0))
  ;(SETQ pp_park T) ; T if 5-axis head should use parking position above

  ; Convert old waterjet nozzle ON/OFF variables
  (SETQ *AWJMarkingAbrasiveOn* *AWJDelayAbrasiveWaterOn*) ; 0.11 till 0.71
  (SETQ *AWJMarkingAbrasiveOff* *AWJDelayAbrasiveWaterOff*) ;0.21 till 0.81
  (SETQ *AWJMarkingStartDelay* 0.0) ; 0.31 always change to zero
  ; (SETQ *VacuumOnDelay* 0.41) No change
  (SETQ *AWJDelayWaterAbrasiveOn* *AWJDelayAbrasiveWaterOn*) ; 0.51 till 0.71
  (SETQ *AWJDelayWaterAbrasiveOff* *AWJDelayAbrasiveWaterOff*) ;0.61 får 0.81
  ; (SETQ *AWJDelayAbrasiveWaterOn* 0.71) No change
  ; (SETQ *AWJDelayAbrasiveWaterOff* 0.81) No change
  (SETQ *AWJDelayAfterPiercing* 0.0) ; 0.91 till alltid 0.0
  ; (SETQ *AWJDelayAfterCutting* 1.01) No change
  (SETQ $JetValveOn *AWJDelayOpenValve*) ; This is new
  (SETQ $JetAbrasiveOn *AWJDelayAbrasiveWaterOn*) ; 0.71
  (SETQ $JetAbrasiveOn *AWJCuttingArrive*) ;JB
  (SETQ $JetAbrasiveOff *AWJDelayAbrasiveWaterOff*) ; 0.81
  (SETQ $JetAbrasiveOff *AWJCuttingEmpty*)  ; 0.81
  (SETQ $JetValveOff *AWJDelayAfterCutting*) ; 1.01
  
  ;*AWJCuttingEmpty*

  ;(IF bevel (SETQ *3D-5X* T))
  ; software RTCP
  (IF *RTCPUse* (SETQ *rtcptype* (INIFILE-READ *HeadDefIniFile* "global" "RTCP")))
  (SETQ *rtcptype* (IF (MEMBER *rtcptype* (LIST "1" "2")) (ATOI *rtcptype*) nil))
  (IF (= *rtcptype* 2)
    (PROGN
      (SETQ xdiff (* (- *RTCPMeasureX* *RTCPExpectX*) 0.5))
      (SETQ ydiff (* (- *RTCPMeasureY* *RTCPExpectY*) 0.5))
      (SETQ *CorrAngle* (ANGLE (LIST 0 0) (LIST xdiff ydiff)))
      (SETQ *CorrDist* (DISTANCE (LIST 0 0) (LIST xdiff ydiff)))
      (IF (< *Corrdist* 0.02) (SETQ *Corrdist* nil *CorrAngle* nil *rtcptype* nil))))
  (SETQ *SharedFolder* (GETVAR "PATHSHARED"))
  (DOSTRING *MachineExtraScript* (ALERT "Error reading Machine Extra script"))
  (SETQ *Metric* (IF (= (GETVAR "UNITS") 0) T nil))
  (COND
    ((= *OutputUnit* 1) (SETQ pp_inchout nil))
    ((= *OutputUnit* 2) (SETQ pp_inchout T))
    (*Metric* (SETQ pp_inchout nil)) ; If Auto then use CAD setting
    (T        (SETQ pp_inchout T))   ; If Auto then use CAD setting
  )
  (IF (NOT (FILE-EXISTS (STRCAT (GETVAR "PATHSHARED") "Postprocessors/" *PPName* ".IPF"))) (QUIT (ALERT "Go to machine settings, verify post-processor name.")))
  (IF (NOT editmode) (LOAD (STRCAT (GETVAR "PATHSHARED") "Postprocessors/" *PPName* ".IPF")))
  (SETQ wline 0) ; qounter for viering only 1000 lines
  (SETQ $nadd *LineNumberIncrement*)
  (SETQ $nlines *UseLineNumbers*)
  (SETQ $post (FILE-NAMEONLY *PPName* T))
  (SETQ $build (BUILDVER))

  ; ****** Tools settings ******
  (SETQ $mindist *ToolMinDistance*)
  (SETQ $maxdist *ToolMaxDistance*)
  (SETQ $maxtools *ToolQuantity*)
  (SETQ $maxzaxis *ZMovableQuantity*)
  (IF (> $maxzaxis $maxtools) (SETQ $maxzaxis $maxtools)) ; Number of movable axis cannot be more than the jets
  (SETQ tmp 1 *Toolmaxbit* 1); Check the maximum bitvalue for this number of tool
  (REPEAT (1- *ToolQuantity*) ; Inte samma som ONETOBIT eftersom detta ger värdet när alla är på
    (SETQ tmp (* tmp 2))
    (SETQ *ToolMaxBit* (+ *ToolMaxBit* tmp))
  )
  (SETQ $zmaxmove *ZMaxMovement*)
  (IF (< *ZMeasureDist* 10) (SETQ *ZMeasureDist* 10))
  (IF (< *ZMeasureDistBevel* 10) (SETQ *ZMeasureDistBevel* 10))
  (SETQ $ZaxisOption *ZAxisOption*)
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
  (SETQ pp_$Zold *Zmaxmovement*)
  (SETQ $zmaxdist *ZMaxMovement*)
  (IF *MinGeometryOptimization* (SETQ *MaxToolDiameter* *MinGeometryOptimization*))
  (SETQ $maxtooldiameter *MaxToolDiameter*)
  (SETQ $zbase *ZBase*)
    ;(IF (= (STRCASE $post) "STM") (SETQ $zmaxdist (+ $zmaxdist *Zstandoff*))) ;****************** SPECIAL FOR STM ****************
  (SETQ $sensorminlift *ZMinMovement*)
  (SETQ $sensoringtime *ZSensoringTime*)
  ;(IF (> (+ *Thickness* *ZStandoff*) *ZMaxMovement*) (QUIT (STRCAT "\n" (ALERT "Too thick material for this machine"))))

  ; ***** Handling of piercing ******
  (SETQ $vacuumOndelay *VacuumOnDelay*)
  (IF (OR *AWJAutomaticPiercing* *3D-5X*)
    (PROGN
      (SETQ *AWJCircularPiercing* (CIRCULARPIERCINGTIME *Thickness*))
      (SETQ *AWJCircularPiercingDiameter* (CIRCULARPIERCINGDIAMETER))
      (SETQ *AWJCircularPiercingSpeed* (CIRCULARPIERCINGSPEED))
      (SETQ *AWJStationaryPiercing* (STATIONARYPIERCINGTIME *Thickness*))))
  (IF (= *MAchineType* 0) (SETQ *Piercingdiameter* *AWJCircularPiercingDiameter*))

  ; ****** Handling of 5X settings ******
  (SETQ *MasterHeadSecondaryPrefer* *HeadSecondaryPrefer*) ; 0=Use negative, 1= Use positive, 2=Use both side
  (IF (< *HeadMinTilt* 0.01) (SETQ *HeadMinTilt* 0.01))
  (SETQ *HeadMinTilt* (DEGTORAD *HeadminTilt*))
  (SETQ *MaxforbiddenTilt* (DEGTORAD *MaxforbiddenTilt*))
  (IF (NOT *HeadPrimaryAxisLimitations*) (SETQ *HeadPrimaryMin* -400.0 *HeadPrimaryMax* 400.0))
  (SETQ *HeadPrimaryMax* (DEGTORAD *HeadPrimaryMax*)) ; Gör om från grader till radianer
  (SETQ *HeadPrimaryMin* (DEGTORAD *HeadPrimaryMin*)) ; Gör om från grader till radianer
  (SETQ *HeadPrimaryMaxSpeed* (DEGTORAD *HeadPrimaryMaxSpeed*)) ;Gör om från grader till radianer
  (SETQ *HeadSecondaryMaxSpeed* (DEGTORAD *HeadSecondaryMaxSpeed*)) ; Gör om från grader till radianer
  (SETQ $singularity (EQUAL (ABTOVEC PI 0.0) (LIST 0.0 0.0 -1.0) 0.00001)) ; If kinematic has singulatity in vertical direction
  (SETQ $HeadInfinity (NOT *HeadPrimaryAxisLimitations*))
  (SETQ $Kinematic (1+ *HeadKinematic*))
  (IF (NOT *Has5XKinematics*) (SETQ $Kinematic 0))

  (SETQ *HeadMaxTilt* (DEGTORAD *HeadMaxTilt*))
  (IF (NOT *Has5XKinematics* ) (SETQ *TAC* 0 *LAG* 0))
  (IF (> *Machinetype* 0) (SETQ *TAC* 0 *LAG* 0))

  ; ****** Handling of speed ******
  (SETQ $f *SpeedRapid*)
  (SETQ $fz *Zspeed*)
  (SETQ $fr *SpeedRapid*)

  (IF (= *AWJAbrasiveFlowCNC* 0)(SETQ *AWJAbrasiveFlowCNC* nil))
  (IF (NOT *PiercingAlways*) (SETQ *PiercingAlways* 1))
  (SETQ $CNCPressure *AWJPumpPressureCNC*) ; We can probably remove this
  (SETQ $pressurehandle *AWJPumpPressureCNC*)
  (SETQ $abrasivehandle *AWJAbrasiveFlowCNC*)
  (SETQ *AWJBleedOut* (IF (= *AWJBleedOut* 1) T nil)) ;If the pump have a bleed out reduction then T else nil
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
  (SETQ $tooldisthandle (IF *ToolDistanceByController* 1 0))
  (SETQ $toolhandle (IF *ToolActiveByController* 1 0))
;  (IF $tooldisthandle (SETQ *ToolDistanceByController* (IF (= *ToolDistanceType* 0) nil T))) ;KAN TAS BORT SEN..
  (SETQ *DrillingSensoring* (IF (> *DrillingSensoring* 0) T nil))
  (IF (NOT *DrillingTools*) (SETQ *DrillLiftZ* 0))
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
  (IF (NOT *AWJPumpOnOfCNC* ) (SETQ *AWJStartPumpAuto* 0 *AWJStopPumpAuto* 0))
  (SETQ *DrillingToolsActive* (IF *DrillingOnFirst* 1 *ToolMaxbit*))
  (IF (= pp_zmode 0) (SETQ *DrillLiftZ* 0 *MarkingLiftZ* 0 *PiercingLiftZ* 0 *CuttingLiftZ* 0 *CuttingLiftZParts* 0))
  (IF (NOT *ReportCreateAutomatically*) (SETQ *ReportPrint* 0))
  (IF (NOT *ReportCreateAutomaticallyCost*) (SETQ *ReportPrintCost* 0))
  (COND
    ((MEMBER *ZAxisOption* (LIST 0 3)) (SETQ *ZPiercingUse* 0)) ; Fixed or Meauring in advance
    ((AND (= *ZaxisOption* 1) (NOT *ZPiercingCNC*)) (SETQ *ZPiercingUse* 0))
    ((AND (= *ZaxisOption* 2) (NOT *ZPiercingSensor*)) (SETQ *ZPiercingUse* 0))
  )
  ; Handling of output units
  (IF *3D-5X*
    (PROGN
      ; BELOW: We always ned to lift at least to the height of the model
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
    (LIST (LTF "Force pre-piercing") '*PiercingAlways*)
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
    (LIST (LTF "TAC") '*TAC*)
    (LIST (LTF "VOC") '*VOC*)
    (LIST (LTF "LAG") '*LAG*)
    (LIST (LTF "Use increased piercing standoff") '*ZPiercingUse*)
    (LIST (LTF "End with parking position") '*GotoParkPos*)
    (LIST (LTF "Open in CNC") '*IgemsCNCSend*) ; Changed to Only CNC. //SG
    (LIST (LTF "Copy to backup folder") '*OutputMakeBackup*)
    (LIST (LTF "Print job report") '*ReportPrint*)
    (LIST (LTF "Print cost report") '*ReportPrintCost*))
  )
  (SETQ outlist (APPEND outlist pp_outlist))
  (FOREACH s outlist (IF (NOT (MEMBER (EVAL (CADR s)) (LIST 0 1 2 3))) (ALERT (STRCAT "Wrong value of " (TOSTR (CADR s))))))
  (IF (NOT *ShowOptions*)
    (FOREACH s outlist (IF (< (EVAL (CADR s)) 2) (SET (CADR s) nil) (SET (CADR s) T))))
  (SETQ pp_zmoved (IF (= *3D-ZeroLevel* 1) (CADDR (CAM-ZEROPOINT)) (CAM-3DMAXZ))) ; If Showoption dialogen inte visas
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
            (IF c:z
              (PROGN
                (SETQ *3D-ZeroLevel* (GP-GETQ c:z VALUE))
                (CAM-SETMACVAR "*3D-ZeroLevel*" *3D-ZeroLevel*) ; 0=On top, 1==n Table or Used defined
                (CAM-SAVEMAC)
                (SETQ pp_zmoved (IF (= *3D-ZeroLevel* 1) lowz maxz))))
            (GP-CLOSE dlg T))
          ((= object b:cancel)
            (GP-CLOSE dlg nil))
          (T
            (SETQ usrid (GP-GETQ object USERID))
            (IF usrid 
              (PROGN
                (IF (NOT (SETQ v (DISTOF (GP-GETQ object VALUE) -10000 10000))) (GP-SETQ object VALUE (SETQ v (DISTOF (GP-OLDVALUE)))))
                (SET (READ usrid) v))))
        )
      )
      (IF *Metric* (SETQ upscale 1.0 downscale 1.0) (SETQ upscale 25.4 downscale 0.039370078))
      (DEFUN tiptext ()
        (IF (= *InternalToolCompensation* 1)
          (STRCAT "IGEMS: " (RTOS (* (- *Tooldiameter* *AWJAdditionalkerf*) downscale) (IF *Metric* 3 4) T) " + "
          (LTF "Machine") ": " (RTOS (* *AWJAdditionalkerf* downscale) (IF *Metric* 3 4) T)) "")
      )
      (SETQ dlg (GP-DIALOG (STRCAT (LTF "Options") " " *MachineName*) ACTION handle))
      (SETQ pp_zmoved (CADDR (CAM-ZEROPOINT)))
      (IF (= *Machinetype* 0)
        (PROGN
          (SETQ cutflow (IF *AWJCuttingAbrasiveFlowByMachine* *AWJAbrasiveFlow* *AWJCuttingAbrasiveFlow*))
          (SETQ tip (LTF "General machine speed factor"))
          (SETQ row (GP-FRAME dlg (LTF "Info") EXPANDX T))
          (SETQ col (GP-COLUMN row WRAPCOUNT 2 CHILDEXPANDX nil ALIGN 0))
          (GP-LABEL col (LTF "Factor") ALIGN 4 TIP tip)
          (GP-LABEL col (RTOS *AWJSpeedFactor* 2 T) TIP tip)
          (GP-LABEL col (LTF "Pressure") ALIGN 4)
          (GP-LABEL col (STRCAT (ITOA (IF *Metric* *Cuttingpressure* (FIX (* *Cuttingpressure* 14.5038)))) " " (IF *Metric* (LTF "bar") (LTF "psi"))))
          (GP-LABEL col (LTF "Abrasive") ALIGN 4)
          (GP-LABEL col (STRCAT (IF *Metric* (ITOA cutflow) (RTOS (/ cutflow 453.5924) 2)) " " (IF *Metric* (LTF "g/min") (LTF "lbs/min"))))
          (IF extrainfolist
            (FOREACH ei extrainfolist
              (GP-LABEL col (CAR ei) ALIGN 4 TIP tip)
              (GP-LABEL col (TOSTR (CADR ei)) TIP tip )
            )
          )
          (COND
            ((= *ZAxisOption* 0) (GP-LABEL row (LTF "Z-axis: Fixed")))
            ((= *ZAxisOption* 1) ; By Z-coordinates
              (GP-LABEL row (LTF "Z-axis: CNC-controlled"))
              (SETQ maxz (CAM-3DMAXZ))
              (IF maxz
                (PROGN
                  (SETQ lowz (CADDR (CAM-ZEROPOINT)))
                  (CAM-GETMACVAR "*3D-Zerolevel*")
                  (SETQ c:z (GP-CHOICE row (LIST (STRCAT (LTF "Zero at top:") " " (RTOS (IF *Metric* maxz (* maxz 0.03937)) 3 T))
                                       (IF (EQUAL lowz 0.0 0.001) (STRCAT (LTF "Zero at table:") " 0.000") 
                                                                  (STRCAT (LTF "Z-zero at:") (IF *Metric* (RTOS lowz 3 T) (RTOS (* lowz 0.039370078) 3 T))))) EXPANDX T VALUE *3D-Zerolevel*)))))
            ((= *ZAxisOption* 2) (GP-LABEL row (LTF "Z-axis: By height sensor")))
            ((= *ZAxisOption* 3) (GP-LABEL row (LTF "Z-axis: Measuring in advance")))
          )
          (GP-FILL dlg HEIGHT 10)))
      (IF (= *Machinetype* 1) ;Pure Waterjet (For 3D models, we weren’t able to select the Max Z, so added this condition for Pure Waterjet.) //SG
        (PROGN
          (SETQ tip (LTF "General machine speed factor"))
          (SETQ row (GP-FRAME dlg (LTF "Info") EXPANDX T))
          (SETQ col (GP-COLUMN row WRAPCOUNT 2 CHILDEXPANDX nil ALIGN 0))
          (GP-LABEL col (LTF "Pressure") ALIGN 4)
          (GP-LABEL col (STRCAT (ITOA (IF *Metric* *WaterPressure* (FIX (* *WaterPressure* 14.5038)))) " " (IF *Metric* (LTF "bar") (LTF "psi"))))
          (COND
            ((= *ZAxisOption* 0) (GP-LABEL row (LTF "Z-axis: Fixed")))
            ((= *ZAxisOption* 1) ; By Z-coordinates
              (GP-LABEL row (LTF "Z-axis: CNC-controlled"))
              (SETQ maxz (CAM-3DMAXZ))
              (IF maxz
                (PROGN
                  (SETQ lowz (CADDR (CAM-ZEROPOINT)))
                  (CAM-GETMACVAR "*3D-Zerolevel*")
                  (SETQ c:z (GP-CHOICE row (LIST (STRCAT (LTF "Zero at top:") " " (RTOS (IF *Metric* maxz (* maxz 0.03937)) 3 T))
                                       (IF (EQUAL lowz 0.0 0.001) (STRCAT (LTF "Zero at table:") " 0.000") 
                                                                  (STRCAT (LTF "Z-zero at:") (IF *Metric* (RTOS lowz 3 T) (RTOS (* lowz 0.039370078) 3 T))))) EXPANDX T VALUE *3D-Zerolevel*)))))
            ((= *ZAxisOption* 2) (GP-LABEL row (LTF "Z-axis: By height sensor")))
            ((= *ZAxisOption* 3) (GP-LABEL row (LTF "Z-axis: Measuring in advance")))
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
      ;(SETQ outlist-reals (LIST (LIST "Back value" "$back" 3.18) (LIST "Mid value" "$mid" 3.14) (LIST "Front value" "$front" 2.99)))
      (FOREACH s pp_outlist-reals
        (SETQ row (GP-ROW dlg))
        (GP-FILL row EXPANDX T)
        (GP-LABEL row (CAR s))
        (SET (READ (CADR s)) (CADDR s))
        (GP-EDIT row VALUE (RTOS (CADDR s) (IF *Metric* 3 4) T) WIDTH 70 EXPANDX nil USERID (CADR s))
      )  
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
      (SETQ *DoInkjet* *MarkingInkjet*)
      (SETQ row (GP-ROW dlg ALIGN GPC-CENTER))
      (SETQ b:ok (GP-BUTTON row (LTF "OK") UNIFORMW T DEFAULT T))
      (SETQ b:cancel (GP-BUTTON row (LTF "Cancel") uniformw T))
      (GP-FOCUS b:ok)
      (SETQ status (GP-SHOWMODAL dlg))
    )
  )
  (SETQ $Underlay *ZStandoff*)
  ;(IF *IS-IGEMS-CNC* (SETQ *ZStandoff* 0.0)) ******************************** TEST 2023-february-27
  (SETQ *ZStandoff* 0.0)
  (SETQ $sendtoCNC *IgemsCNCSend*)
  (SETQ $pumpstart *AWJStartPumpAuto*)
  (SETQ $pumpstop *AWJStopPumpAuto*)
  (IF (> (+ *Thickness* *ZStandoff*) *ZMaxMovement*) (QUIT (STRCAT "\n" (ALERT "Too thick material for this machine"))))
  (IF (MINUSP *ZStandoff*)
    (PROGN
      (BEEP)
      (IF (NOT (GP-YESNO (LTF (STRCAT "Warning! Negative underlay. Continue ?")) nil)) (QUIT "Negative underlay"))))
  ;(SETQ $standoff *ZStandoff*) ; Change name to $underlay
  (SETQ *MasterTAC* (OR *TAC* *LAG*))
  (IF (/= *InternalToolCompensation* 1) (SETQ *AWJAdditionalkerf* 0.0))
  (IF *SendToIgemsCnc* (SETQ $SendToCnc T))
  (SETQ $tac *tac* $voc *voc* $lag *lag*)
  ;JB(SETQ *DecimalsMovement* DecimalsMovement *SupressTrailingZeroes* SupressTrailingZeroes)
  (IF (= *ZAxisOption* 2) (SETQ pp_noZonrapid T)) ; If height sensor is used, we will not use Z before first sensoring
  (IF status (OPTIONS-SAVE))
  (IF *ForcedToolDiameter* (SETQ *ToolDiameter* *ForcedToolDiameter*)) 
  (IF (OR status (NOT *ShowOptions*))
    (PROGN
      (PRINC "\nCreating preparation file..")
      (CAM-INITIALIZE (- *ToolDiameter* *AWJAdditionalkerf*) *Tooldiameter* *TAC* *VOC* *LAG* *AWJFlyingAbrasive* *PiercingAlways* *ReportPrint* *ReportPrintCost*) T)
    nil
  )
)

(DEFUN $main ()
  (PRINC "\nPreparing..")
  (IF trace (WRITE "$MAIN"))
  (SETQ fname (STRCAT (GETVAR "PATHDATA") "PROCESS.LIG"))
  (LOAD fname "")
  (IF (FILE-EXISTS fname) (FILE-DELETE fname))
  (IF fun (WRITE "$MAIN"))
  (IF (/= (CHECKSUMCOUNT *PPName*) *PostInit*) (PRINC "\n      ****** This postprocessor is renamed ******\n"))
  (SETQ $maxslope (RADTODEG *Maxslope*))
  (SETQ *MasterThickness* *Thickness*) ; The Masterthickness is always the same as the selected material thickness. It's used in 2D-cutting.
  (SETQ *Partsboxwidth* (- (CADDR *PartsBox*) (CAR *PartsBox*)))
  (SETQ *Partsboxheight* (- (CADDDR *PartsBox*) (CADR *PartsBox*)))
  (SETQ *Partsboxcenter* (LIST (* (+ (CAR *PartsBox*) (CADDR *PartsBox*)) 0.5) (* (+ (CADR *PartsBox*) (CADDDR *PartsBox*)) 0.5)))
  (IF (= *MaxFeed* 0) (SETQ *MaxFeed* *SpeedMaxCutting*))
  (SETQ $useflyctrl (IF *AWJFlyingAbrasive* T nil))
  (COND
    ((NOT *3D-5X*) nil)
    ((> (+ *3D-MaxZ* *3D-5XStock*) (- *ZMaxMovement* *Zstandoff*)) (QUIT (STRCAT "\n" (ALERT "Too thick material for this machine"))))
    ((AND *3D-5X* (= *ZAxisOption* 1) (= *ZAxisType* 2)) nil) ; CNC-controller, by Z-cordinates
    ((AND *3D-5X* *3D-OnTopPlane*) (SETQ *Thickness* *3D-MaxZ*))
    (*UseSixAxis* nil)
    ((AND *3D-5X* (= *ZAxisOption* 2) (> (ABS *3D-ToolPosDiff*) 0.01))
      (IF (NOT (YESNO (STRCAT (LTF "Sure to use heigt sensor. Toolpath differ") " " (RTOS *3D-ToolPosDiff* 4) " ?")))
        (QUIT "\n\n*Can't use height sensor*\n")))
  )
  (SETQ $true5x (IF (> (ABS *3D-MaxZDiff*) 1) T nil)) 
  (IF (= *ZSensoringMode* 0) (SETQ $sensor -1))

  (SETQ $angleIpo *ControllerAngleInterpolation*)
  ;(SETQ pp_zmoved (CADDR *ZeroPoint*)) ; Om man har flyttat nollpunkten i Z så är detta värde inte noll. Värdet läggs på i DEFZ funktionen. this is outcommented to not overwrite the dropdown selection.
  (SETQ pp_zclear (+ *3D-MaxZ* *3D-5XStock*)) ; Clearence height for all rapids.
  (SETQ *Ztmp* 0.0) ; This must be to be compatible with postprocessors before we added 3 diferent Z-bases. Not used after 1080
  (SETQ $encoding (NTH *Encoding* (LIST nil "utf-8" "utf-16" "utf-32" "utf-8-nobom")))
   ; ***** Handle Z axis ******
  (IF (= *ZAxisOption* 2) (SETQ *ZBase* 1))
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
  (SETQ $markbar *MarkingPressure*)
  (SETQ $piercbar *Piercingpressure*)
  (SETQ $cutbar *Cuttingpressure*)
  (SETQ $highbar (MAX $cutbar $piercbar $markbar))
  (SETQ $lowbar (MIN $cutbar $piercbar $markbar))
  (SETQ $bar $cutbar)
;  (IF *DangerZoneUse* (SETQ $dangerzone (LIST pp_xdmin pp_ydmin pp_xdmax pp_ydmax)))
  (IF (AND $SendToCnc pp_autofilename) (SETQ pp_filename (STRCAT *OutputFolder* "current" *PPFileExtension*)))
  (IF (NOT (AND pp_autofilename pp_filename))
    (SETQ pp_filename (GETFILENAME "Save NC-file as"))
  )
  (IF pp_filename (SETQ $wfile (OPEN (SETQ $filename pp_filename) "w" $encoding)))
  (PRINC "\nAnalyzing..")
  (CHKALL)
  (PRINC "\nStart postprocessing..\n")
  (IF *DangerZoneUse*
    (PROGN
      (DEFAXIS (LIST pp_xdmin pp_ydmin 0.0) (LIST 0 0 0))
      (SETQ xxx $x yyy $y)
      (DEFAXIS (LIST pp_xdmax pp_ydmax 0.0) (LIST 0 0 0))
      (SETQ $dangerzone (LIST xxx yyy $x $y))))
  (SSIM-SETUP)
  (SIM-IAIP nil)
  ($HEADER)
  ($TOOLUP *ZMaxMovement* 1 "HIGHEST")
  (SETQ $REASON 1 $mode nil $Z *ZMaxMovement* pp_lift *ZMaxMovement*)
  ; PumpOn is turned ON in the $chmode function.
  (IF (NOT *cmdloop*) (SETQ *cmdloop* 1))
  (REPEAT *cmdloop*
    (SETQ pp_cmdindex 0)
    ($CMDLOOP)
    (FOREACH toolrow toolpath
      (SETQ $nextcmd (CAR toolrow))
      (SETQ $nextrow toolrow)
      ;(WRITE (STRCAT "CMD:" (TOSTR cmd)))
      (COND
        ((= cmd '$LINE) (EVAL cmdrow))
        ((= cmd '$ARC) (EVAL cmdrow))
        ((= cmd '$RAPID)  (IF (NOT (MEMBER $mode (LIST 6))) (EVAL cmdrow))) ; Do not use if its special marking
        ((= cmd '$TOOLSET)
          (SETQ pp_toolset cmdrow) ; Save this to be called in $PATHINFO when resetting $TPTOOLSET after the cut
          (EVAL cmdrow))
        ((= cmd '$TPTOOLSET) (EVAL cmdrow))
        ((= cmd '$CHMODE)
          (IF (MEMBER pp_firstmode '(5 6)) ; Inkjet or Special marking
            (PROGN
              ($CHMODE 9)
              ($SENSORING pp_firstpos)))
          (SETQ pp_firstmode nil)
          (EVAL cmdrow))
        ((= cmd '$PART) (EVAL cmdrow))
        ((= cmd '$ROTAX) (EVAL cmdrow))
        ((= cmd '$REWIND) (EVAL cmdrow))
        ((= cmd '$DRILLING) (EVAL cmdrow))
        ((= cmd '$PRE-PIERCING) (EVAL cmdrow))
        ((= cmd '$CUTON) (EVAL cmdrow))
        ((= cmd '$MARKON) (EVAL cmdrow))
        ((= cmd '$MARKOFF) (EVAL cmdrow))
        ((= cmd '$FLYCTRL) (EVAL cmdrow))
        ((= cmd '$CUTOFF) (EVAL cmdrow))
        ((= cmd '$HOLE) (EVAL cmdrow))
        ((= cmd '$STOP) (EVAL cmdrow))
        ((= cmd '$MEASURE) (EVAL cmdrow))
        ((= cmd '$TEXT) (EVAL cmdrow))
        ((= cmd '$ITEXT) (EVAL cmdrow))
        ((= cmd '$DATAPOINT) (EVAL cmdrow))
        ((= cmd '$REFPOS) (EVAL cmdrow))
        ((= cmd '$QUALITY) (EVAL cmdrow))
        ((= cmd '$MEASUREPOINT) (EVAL cmdrow))
        ((= cmd '$PATHINFO) (EVAL cmdrow))
        ((= cmd '$PLASMA) (EVAL cmdrow))
        (cmd (ALERT (STRCAT "Not yet supported option **[" (TOSTR cmdrow) "]**")))
      )
      (IF cmd (SETQ pp_cmdindex (1+ pp_cmdindex)))
      (SETQ cmd $nextcmd)
      (SETQ cmdrow $nextrow)
    )
    (EVAL cmdrow)
    (SETQ *cmdloop* (1- *cmdloop*))
  )
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
  (SETQ *PreviousTooldist* nil)
  (SETQ *PreviousToolActive* 0)
)

(DEFUN $cmdloop ()
  (SETQ $loop *cmdloop*)
  (CMDLOOP)
)

(DEFUN cmdloop () nil)

(DEFUN $sensoring (allpos)
  (IF *DrillingSensoring*
    (PROGN
      ($RAPID allpos nil 3 '(0 0 0) nil 0)
      (SETQ $z (DEFZ (CADDR allpos)))
      (SSIM-Z (CADDR allpos) *ZSpeed* *ZAcceleration*)
      (SETQ $reason 9)
      (TOOLDOWN)
      (SSIM-PROBE (CAR allpos) (CADR allpos) (CADDR allpos) 20 2 4 *ZSensoringTime* *ShowSensoringInSimulation*)
      (SIM-INFOTEXT "")
      (SETQ $z (DEFZ $zmaxup))
      (SSIM-Z $zmaxup *ZSpeed* *ZAcceleration*)
      (TOOLUP)))
)

; The CHKALL function check all information before the postprocessing starts. The reason is:
; A: To know how many different pressures needed. Some machines do only support 2 different

; PP_LOWHIGHLIST --------------------------------------------------------
; The list indicate if the start should be done in low or high pressure. T=Low pressure, nil = high pressure.
; Marking with Lower pressure than cutting pressure = T
; Note only Circular and Stationary piercings will have pre-piercings.
; Drilling operations is not member of the list
; Example '(nil T T nil T T nil nil)

; $CONTAINS
; This is a bit coded value. This value is sometimes used in the header.
; The value is the summary of following:
; 1=Cutting, 2=Marking, 4=Low pressure piercing, 8=Drillings, 16=Not used, 32=Hole cutting, 64=Cut with ramping, 128=Cut with no ramping, 256=Special markings, 512=Inkjet marking

; PP_PARTCONTAINS
; This is a list with a bit coded value for each $part. I store this list. Same values as $CONTAINS
; We store this list to use in the PART function. It describes the operations in the actual part. The variable is the same $CONTAINS.

; PP_TOOLCORDS
; Sometimes it's important to know the next comming position already at the tool changing position.
; This variable is a association list. Example '((4 (80.09599 157.95687 10)) (3 (25.81689 26.70023 10)) (2 (80.09599 157.95687 10)) (1 (25.81689 26.70023 10)))
; In the future it should be easier to have the information at the $TOOLSET like below
; ($TOOLSET 1 120.0 2 3 '(25.816887 26.700 10))
; ($CHMODE 4)
; ($RAPID '(25.816887 26.700226 10) nil 0 '(-0.174743 0.080493 0) nil)

; $DATEDUE
; The value is comming from $PART and it is the oldest date of all parts on the drawing.
; The valus eis in folowing format: "20221212"

; DAMAGE AREA
; We need 4 variable for this. The 4 variables describes the damage area relative the program origin. *XDMIN* *YDMIN* *XDMAX* *YDMAX*
; This can easely be calculated by just taking the point (X Y) and add the vector. Think about that ARCS or circles need to set a theoretical point at every quarter.

; PP_PROBELIST
; Borde byta namn till PP_SENSORLIST
; Är en lista som används när sensoring sätts på Auto.
; Den har följande format: '((9 0) (8 1) (7 0) (6 0) (5 2) (4 2) (3 1) (2 1) (1 1) (0 -1))
; -1=Sensoring måste göras, 0=Sensoring behövs ej, 1=Sätt ny höjd, 2=Stamping, 3=Dragging

; PP_SRAPIDNR
; Is an Integer with how many SRAPIDS it is on actual cutorder. The value is 0 if no SRAPIDS are present.

; PP_PARTMAX
; Är en lista av  hur många skärningar det är innom varje $PART. Exampel '(2 4 1 2). Listan används för att veta om vi skall lyfta between parts eller between cuts i 2D. Last cuts will have $lastcutonpart = T



(DEFUN chkall (/ $datapoint $toolset $quality $measure $chmode $part $pathinfo $rapid $rewind $rotax $drilling $cuton $line $arc $cutoff $markon $markoff
                 $pre-piercing $hole $refpos $itext $stop $text $measurepoint $flyctrl $tptoolset $plasma
                 toolset-new maxbit b1 b2 b4 b8 b16 b32 b64 b128 b256 lc1 lc2 lc4 lc8 lc16 lc32 lc64 lc128 lc256 newtoolidx pp_probedist pp_candist probestart 
                 probechk probecalc pp_maxtilt chkz zmax zmin lastbit counter)

  ;(ALERT "CHKALL")
  (SETQ pp_maxspartid 0 pp_maxpathid 0 pp_maxsortid 0)
  (SETQ pp_boxlist nil) ; Special for WaterJet Corporation belt machine 2023.10.10 saving all bounding boxes for all connected parts and all disconnected paths. Can be used in the postprocessor.
  (SETQ pp_partcontains nil lastbit nil)
  (SETQ pp_probeidx 0 pp_probedist 0.0 pp_candist 0.0 pp_maxz -1000)
  (SETQ pp_probthick *thickness*) ; Latest used thickness
  (SETQ pp_srapidnr 0)
  (COND
    ((/= *Machinetype* 0) (SETQ pp_PiercingBarMayChange nil pp_PiercingGramMayChange nil))
    ((NOT *AWJPiercingPressureByMachine*) (SETQ pp_PiercingBarMayChange T))
  )
  (IF (AND pp_PiercingBarMayChange (= *PiercingByType* 3)) (SETQ pp_lowhigh T))

  (COND
    ((/= *Machinetype* 0) (SETQ pp_MarkingBarMayChange nil))
    ((AND (NOT *AWJMarkingPressureByMachine*) (NOT (EQUAL *AWJMarkingPressure* *AWJPressure* 5))) (SETQ pp_MarkingBarMayChange T))
  )


  (COND  ; Handling abrasive
    ((/= *Machinetype* 0) (SETQ pp_PiercingGramMayChange nil))
    ((AND (NOT *AWJPiercingAbrasiveFlowByMachine*) (NOT (EQUAL *AWJPiercingAbrasiveFlow* *AWJAbrasiveFlow* 5))) (SETQ pp_PiercingGramMayChange T))
  )

  (SETQ maxbit (1- (EXPT 2 *ToolQuantity*)))
  (SETQ b1 0 b2 0 b4 0 b8 0 b16 0 b32 0 b64 0 b128 0 b256 0 b512 0) ;$Contains variable: Cutting=1, Marking=2, Lp-percing=4, Drilling=8, Empty=16, Hole cutting=32, Cut with ramping=64,Cut NO raping=128, Special marking= 256
  (SETQ lc1 0 lc2 0 lc4 0 lc8 0 lc16 0 lc32 0 lc128 0 lc256 0 lc512 0)
  (SETQ pp_lowhighlist nil) ; List of each piercing. If a low pressure piercing is used then the value is T else nil
  (DEFUN $measurepoint  (allpos vector attrib)
    (SETQ $probetype (ATOI attrib))
    (SETQ pp_measurepointvectors (CONS vector pp_measurepointvectors))
  )
  (DEFUN $quality (qua) nil)
  (DEFUN $plasma (edge) nil)
  (DEFUN $toolset (active dist align idx / single)
    (SETQ newtoolidx idx)
    (IF (MEMBER active (LIST 1 2 4 8 16 32 64 128)) (SETQ dist *ToolFixDistance* single T) (SETQ single nil))
    (SETQ toolset-new (LIST active dist align))
    (IF (NOT $inittools) (SETQ $inittools active $inittooldist dist))
    (IF (NOT (EQUAL toolset-new toolset-old 0.01)) (SETQ $toolchanges (1+ $toolchanges)))
    (COND
      ((> active maxbit) (PRINC (QUIT (ALERT (STRCAT "Impossible!\nMax " (ITOA *ToolQuantity*) " tools can be used")))))
      ((= active 1) nil) ; To not check the distance if only T1 are in use
      (Single nil)
      ((NOT (EQUAL align *BarAligned*)) (PRINC (QUIT (ALERTHELP (STRCAT "Impossible!\nTool alignment on drawing and machine are diferent") "toolsetup"))))
      ((< dist *ToolMinDistance*) (PRINC (QUIT (ALERT (STRCAT "Impossible!\nTool distance to short: " (RTS dist) "\nMachine set to: " (RTS *ToolMinDistance*))))))
      ((> dist *ToolMaxDistance*) (PRINC (QUIT (ALERT (STRCAT "Impossible!\nTool distance to wide: " (RTS dist) "\nMachine set to: " (RTS *ToolMaxDistance*))))))
    )
  )
  (DEFUN $tptoolset (tools toollist allpos)
    (IF (NOT pp_firsttptoolset) (SETQ pp_firsttptoolset counter)) ; Variable pp_firsttptoolset can be used in the postprocessor to filterout unneccesary first chtool
  )  
  
  (DEFUN $refpos (allpos allrot vector flag probedir)
    (IF (> (CADDR allpos) pp_maxz) (SETQ pp_maxz (CADDR allpos)))
    (IF newtoolidx (SETQ pp_toolcords (CONS (LIST newtoolidx allpos) pp_toolcords))); Creates an accociation list ((1 (x y z)) (2 (x y z))) with the first coordinate after the toolchange
    (SETQ newtoolidx nil)
  )
  (DEFUN $flyctrl (reason) nil)

  (DEFUN $measure (allpos index) nil)
  (DEFUN $chmode (mode)
    (IF (NOT $modestr) (SETQ $modestr (NTH mode (LIST "MEASURING" "DRILLING" "MARKING" "PRE-PIERCING" "CUTTING" "INKJET" "SPECIAL MARKING" "MEASURE")))) ; Need this in first PART call that comes before mode.
    (COND ; Save variables for the $contains variable
      ((= mode 0) nil) ;(SETQ b1 1 lc1 1)) ; Measuring
      ((= mode 1) (SETQ b8 8 lc8 8 lastbit 8)) ; Drilling
      ((= mode 2) (SETQ b2 2 lc2 2 lastbit 2)) ; Marking
      ((= mode 3) (SETQ b4 4 lc4 4 lastbit 4)) ; Pre-piercing
      ((= mode 4) (SETQ b1 1 lc1 1 lastbit 1)) ; Cutting
      ((= mode 5) (SETQ b512 512  lc512 512 lastbit 512)) ; Inkjet
      ((= mode 6) (SETQ b256 256 lc256 256 lastbit 256)) ; Special marking
    )
    (IF (NOT pp_firstmode) (SETQ pp_firstmode mode))
    ; Lastbit indicate if there is no mode change in a new part.Then we continou with the value from the previous part.
  )
  (DEFUN $itext (allpos $txt $angle $length $height $font $fonttype)
    (IF newtoolidx (SETQ pp_toolcords (CONS (LIST newtoolidx allpos) pp_toolcords)))
    (SETQ newtoolidx nil)
    (IF (NOT pp_firstpos) (SETQ pp_firstpos allpos))
    (SETQ b512 512 lc512 512)
  )


  (DEFUN $part (partname customer datum quantity connected box basex basey rotate partid pathid sortid 3d5x contain color pathattrib geoflag / d summary trans) ; 3d5x is nil on 2D and thickness if 3d5x part
    (IF (> partid $maxpartid) (SETQ $maxpartid partid))
    (IF (> pathid $maxpathid) (SETQ $maxpathid pathid))
    (IF (> sortid $maxsortid) (SETQ $maxsortid sortid))
    (SETQ connected (NOT connected)) ; This is inverted
    (DEFUN trans (pt / rx ry)
      (SETQ rx (- (* (CAR pt) (COS rotate)) (* (CADR pt) (SIN rotate))))
      (SETQ ry (+ (* (CADR pt) (COS rotate)) (* (CAR pt) (SIN rotate))))
      (LIST (+ rx basex) (+ ry basey))
    )
    (SETQ p1 (TRANS (LIST (CAR box) (CADR box))))   ; Lower left corner in angle 0
    (SETQ p2 (TRANS (LIST (CADDR box) (CADR box)))) ; Lower right corner
    (SETQ p3 (TRANS (LIST (CADDR box) (CADDDR box)))) ;Upper right corner in angle 0
    (SETQ p4 (TRANS (LIST (CAR box) (CADDDR box)))) ; Upper Left corner roterad box
    (SETQ $boxcenter (POLAR p1 (ANGLE p1 p3) (* (DISTANCE p1 p3) 0.5))) ; Centrum av roterad box
    (SETQ box (LIST (MIN (CAR p1) (CAR p2) (CAR p3) (CAR p4)) (MIN (CADR p1) (CADR p2) (CADR p3) (CADR p4))
                          (MAX (CAR p1) (CAR p2) (CAR p3) (CAR p4)) (MAX (CADR p1) (CADR p2) (CADR p3) (CADR p4))))
    (IF connected (SETQ pp_boxlist (CONS box pp_boxlist))) ; Adds the box if its the part has connected toolpath
    (IF (SETQ d (DATETOSTR datum))
      (PROGN
        (SETQ d (ATOI d))
        (IF (AND d (< d $datedue)) (SETQ $datedue d)))) ; $Datedue är aldid en integer i CHKALL men görs om i HEADER till ett datum i Svenskt format.
    (COND
      ((AND (NOT 3d5x) (NOT (EQUAL pp_probethick *MasterThickness* 0.01)))
        (SETQ pp_probethick *MasterThickness*)
        (SETQ pp_probeforce T)) ; A 2D part after a 3d5x part.
      ((AND 3d5x (NOT (EQUAL pp_probethick 3d5x 0.01)))
        (SETQ pp_probethick 3d5x)
        (SETQ pp_probeforce T))
    )
    ; Handling the local pp_partcontains list used later in PART
    (SETQ summary (+ lc1 lc2 lc4 lc8 lc16 lc32 lc128 lc256 lc512))
    (COND
      ((AND (NOT lastbit) (= summary 0)) nil) ; This is the first $PART. We don't know anything then
      ((= summary 0) (SETQ pp_partcontains (CONS lastbit pp_partcontains)))
      (T (SETQ pp_partcontains (CONS summary pp_partcontains)))
    )
    (SETQ lc1 0 lc2 0 lc4 0 lc8 0 lc16 0 lc32 0 lc128 0 lc256 0 lc512 0)
    (SETQ pp_partmax (CONS (LENGTH pp_lowhighlist) pp_partmax))
  )
  (DEFUN $pathinfo (box flag)
    (IF (> (LOGAND flag 1) 0) (SETQ pp_boxlist (CONS box pp_boxlist))) ; Adds the box if its an disconnected toolpath
  )
  (DEFUN $rapid (allpos attrib flag allrot tilted flag)
    (IF attrib (SETQ pp_srapidnr (1+ pp_srapidnr)))
    (IF (NOT pp_firstrapid) (SETQ pp_firstrapid toolrow))
    (IF (> (CADDR allpos) pp_maxz) (SETQ pp_maxz (CADDR allpos)))
    (IF newtoolidx (SETQ pp_toolcords (CONS (LIST newtoolidx allpos) pp_toolcords))); Creates an accociation list ((1 (x y z)) (2 (x y z))) with the first coordinate after the toolchange
    (SETQ newtoolidx nil) ;
  )

  (DEFUN $drilling (allpos allrot holedia attrib depth nrmdrill / *FlatZoneRadius*)  ;added last arg normaldrill JB
    (TANKSAFE (CAR allpos) (CADR allpos) (LIST 0 0 -1))
    (IF (NOT pp_firstpos) (SETQ pp_firstpos allpos))
    (IF newtoolidx (SETQ pp_toolcords (CONS (LIST newtoolidx allpos) pp_toolcords))); Creates an accociation list ((1 (x y z)) (2 (x y z))) with the first coordinate after the toolchange
    (SETQ newtoolidx nil)
    (SETQ $usesdrill T)
    (SETQ pp_maxslope 0)
    (SETQ *FlatZoneRadius* *DrillingFlatzone*)
    (IF (NOT pp_probelist)
      (PROGN
        (SETQ pp_probelist (CONS (LIST pp_probeidx -1) probelist))
        (SETQ pp_probeidx (1+ pp_probeidx) pp_probedist 0.0 pp_candist 0.0)
        (SETQ pp_probepos allpos pp_probeforce nil))
      (PROGN
        (PROBESTART)
        (PROBECHK allpos)
        (PROBECALC))
    )
  )

  (DEFUN $pre-piercing (allpos pp_ptype pp_leadname pp_nodename pp_vec flag pp_leadplan allrot attrib)
    (IF (= pp_ptype 4) (QUIT (ALERT "You have selected drilling as piercing method, but no drilling equipment is configured in machine settings.")))
    (CHKZ allpos)
    (COND
      ($startbar nil)
      (*AWJPiercingPressureByMachine* (SETQ $startbar $cutbar))
      (T (SETQ $startbar $piercbar))
    )  
    (SETQ pp_maxslope 0)
    (IF (= pp_ptype 3) (SETQ b16 16)) ;JBTEST
    (IF newtoolidx (SETQ pp_toolcords (CONS (LIST newtoolidx allpos) pp_toolcords))); Creates an accociation list ((1 (x y z)) (2 (x y z))) with the first coordinate after the toolchange
    (SETQ newtoolidx nil)
    (SETQ pp_lowhighlist (CONS (IF pp_PiercingBarMayChange T nil) pp_lowhighlist))
    (TANKSAFE (CAR allpos) (CADR allpos) pp_vec)
    (PROBESTART)
    (PROBECHK allpos)
    (PROBECALC)
  )
  (DEFUN probestart () ; Local function in chkall
    (SETQ pp_candpos allpos)
    (IF (NOT pp_probepos) (SETQ pp_probepos allpos))
  )

  (DEFUN probechk (pos) ; local function in chkall. Check the distance from
    (IF (> (DISTANCE pos pp_probepos T) pp_probedist) (SETQ pp_probedist (DISTANCE pos pp_probepos T)))
    (IF (> (DISTANCE pos pp_candpos T) pp_candist) (SETQ pp_candist (DISTANCE pos pp_candpos T)))
  )
  (DEFUN probecalc (/ prob) ; local function in chkall
    (COND
      ((AND (<= pp_probedist *FlatZoneRadius*) (< pp_candist *FlatZoneRadius*)) (SETQ prob 0))
      ((AND (>= pp_probedist *FlatZoneRadius*) (< pp_candist *FlatZoneRadius*)) (SETQ prob 1 pp_probepos pp_candpos))
      ((>= pp_candist *FlatZoneRadius*) (SETQ prob (IF (> pp_maxslope *DragStartAt*) 3 2) pp_probepos pp_candpos))
      (T (BEEP (ALERT (STRCAT "NOT YET SUPPORTED OPTION\nPROBDIST:" (TOSTR pp_probedist) "<>" (TOSTR *FlatZoneRadius*) "\n"
                        "CANDIST:" (TOSTR pp_candist) "<>" (TOSTR *FlatZoneRadius*)))))
    )
    (COND
      ((AND (NOT pp_probelist) (= prob 0)) (SETQ prob -1))
      ((AND pp_probeforce (= prob 0)) (SETQ prob -1))
      ((AND pp_probeforce (NOT prob)) (SETQ prob -1))
      (pp_probeforce (SETQ prob (- prob)))
    )
    ;(WRITE (STRCAT "Probe:" (TOSTR prob) " FORCE:" (TOSTR pp_probeforce)))
    (SETQ pp_probelist (CONS (LIST pp_probeidx prob) pp_probelist))
    (SETQ pp_probeidx (1+ pp_probeidx) pp_probedist 0.0 pp_candist 0.0)
    (SETQ pp_probeforce nil)

  )

  (DEFUN chkz (pt / z)
    (SETQ z (CADDR pt))
    (COND
      ((NOT zmin) (SETQ zmin z zmax z))
      ((< z zmin) (SETQ zmin z))
      ((> z zmax) (SETQ zmax z))
    )
  )

  (DEFUN $cuton (allpos side ptype qua clen geoarea geolen leadname nodename inside pp_startp iskerfed fe pp_vec bevelflag maxslope cutdirection
               leadplan allrot len attrib / allpos pp_oldpos)
    (SETQ pp_maxslope maxslope)
    (CHKZ pp_startp)
    (CHKZ allpos)
    (IF (NOT $startbar) (SETQ $startbar $cutbar))
    (PROBESTART)
    (TANKSAFE (CAR allpos) (CADR allpos) pp_vec)
    (TANKSAFE (CAR pp_startp) (CADR pp_startp) pp_vec)
    (IF (= ptype 3) (SETQ b16 16))
    (IF (> (LOGAND bevelflag 128) 0) (SETQ b128 128))
    (IF (> (LOGAND bevelflag 64) 0) (SETQ b64 64)) ; Set value for the $contains
    (IF (> (LOGAND bevelflag 2) 0) (SETQ $uses5x T))
    (IF (AND (> (LOGAND bevelflag 64) 0) *MasterTAC*) (SETQ $uses5x T))
    (SETQ pp_lowhighlist (CONS (IF (AND pp_PiercingBarMayChange (MEMBER ptype (LIST 2 3))) T nil) pp_lowhighlist))
    (SETQ pp_oldpos allpos)
  )

  (DEFUN $line (allpos flag fs fe delta pp_vec allrot len)
    (TANKSAFE (CAR allpos) (CADR allpos) pp_vec)
    (PROBECHK allpos)
    (SETQ pp_oldpos allpos)
  )

  (DEFUN $arc (allpos pp_centp ccw flag fs fe delta pp_vec allrot len / r quads endang vlen vdir pt segv nvec vvec)
    (CHKZ allpos)
    (SETQ r (DISTANCE pp_centp allpos))
    (SETQ quads (CAD-ARCQUADRANTS pp_centp pp_oldpos allpos ccw))
    (SETQ endang (ANGLE pp_centp allpos))
    (SETQ vlen (DISTANCE (LIST 0 0) pp_vec))
    (SETQ vdir (ANGLE (LIST 0 0) pp_vec))
    (FOREACH s quads
      (SETQ pt (POLAR pp_centp s r))
      (PROBECHK pt)
      (SETQ segv (SEGMENT endang s $ccw))
      (IF (NOT $ccw) (SETQ segv (- segv)))
      (SETQ nvec (POLAR (LIST 0 0) (+ vdir segv) vlen))
      (SETQ vvec (LIST (CAR nvec) (CADR nvec) (CADDR pp_vec)))
      (TANKSAFE (CAR pt) (CADR pt) vvec)
    )
    (TANKSAFE (CAR allpos) (CADR allpos) pp_vec)
    (PROBECHK allpos)
    (SETQ pp_oldpos allpos)
  )

  (DEFUN $cutoff (typ allpos) (PROBECALC))

  (DEFUN $markon (allpos pp_atrib pp_clen allrot special pp_vec $starttan $maxslope from3d5x)
    (IF (NOT pp_firstpos) (SETQ pp_firstpos allpos))
    (CHKZ allpos)
    (SETQ pp_maxslope 0)
    (IF (AND (NOT special) (NOT $startbar)) (SETQ $startbar $markbar))
    (TANKSAFE (CAR allpos) (CADR allpos) pp_vec)
    (PROBESTART)
    (IF from3d5x (SETQ $uses5x T))
    (IF newtoolidx (SETQ pp_toolcords (CONS (LIST newtoolidx allpos) pp_toolcords))); Creates an accociation list ((1 (x y z)) (2 (x y z))) with the first coordinate after the toolchange
    (SETQ newtoolidx nil)
    (SETQ pp_lowhighlist (CONS (IF pp_MarkingBarMayChange T nil) pp_lowhighlist))
  )
  (DEFUN $text(allpos txt direction xlen ylen attrib font fontype special)
    (IF newtoolidx (SETQ pp_toolcords (CONS (LIST newtoolidx allpos) pp_toolcords)))
    (SETQ newtoolidx nil);
    (IF (NOT $startbar) (SETQ $startbar $markbar))
    (IF (NOT pp_firstpos) (SETQ pp_firtspos allpos))
    (CHKZ allpos)
    (PROBESTART)
    (PROBECHK allpos)
    (PROBECALC)
  )
  (DEFUN $stop ($reason $cond $msg) nil)
  (DEFUN $markoff (typ pp_allpos) (PROBECALC))
  (DEFUN $rewind (allrot) nil)
  (DEFUN $rotax (pp_vec, tid, allrot fe len)
    (TANKSAFE (CAR pp_oldpos) (CADR pp_oldpos) pp_vec)
  )

  (DEFUN $hole (allpos typ radie pp_attrib pp_quality) ;typ: 0=Drilling (Not used), 1=Marking, 2=Circular piercing, 3=HQCH, 4=Stationary piercing. Quality: in HQCH
    (CHKZ allpos)
    (IF (NOT pp_firstpos) (SETQ pp_firtspos allpos))
    (COND
      ((= typ 1) ; Waterjet marking
        (SETQ b2 2 lc2 2)
        (IF (NOT $startbar) (SETQ $startbar $markbar))
        (SETQ pp_lowhighlist (CONS (IF pp_MarkingBarMayChange T nil) pp_lowhighlist))) ; Waterjet marking
      ((= typ 2)
        (SETQ pp_lowhighlist (CONS (IF pp_PiercingBarMayChange T nil) pp_lowhighlist)) ; Circular piercing
        (IF (NOT $startbar) (SETQ $startbar (IF pp_PiercingBarMayChange $piercbar $cutbar))))
      ((= typ 3) ; Hole cutting HQCH
       (SETQ b32 32 lc32 32)
       (IF (NOT $startbar) (SETQ $startbar $cutbar))
       (SETQ pp_lowhighlist (CONS nil pp_lowhighlist))) ; HQCH will always be done in HP
      ((= typ 4)
        (IF (NOT $startbar) (SETQ $startbar $cutbar))
        (SETQ pp_lowhighlist (CONS (IF pp_PiercingBarMayChange T nil) pp_lowhighlist))) ; Stationary piercing
    )
    (TANKSAFE (CAR allpos) (CADR allpos) (LIST 0 0 -1))
    (IF newtoolidx (SETQ pp_toolcords (CONS (LIST newtoolidx allpos) pp_toolcords))); Creates an accociation list ((1 (x y z)) (2 (x y z))) with the first coordinate after the toolchange
    (SETQ newtoolidx nil)
    (PROBESTART)
    (PROBECHK allpos)
    (PROBECALC)
  )
  (SETQ counter 0)
  (FOREACH toolrow toolpath 
    (SETQ counter (1+ counter))
    (IF (AND (= (CAR toolrow) '$TOOLSET) (NOT pp_toolfirst)) (SETQ pp_toolfirst toolrow))
    (EVAL toolrow)
  )  

  (SETQ summary (+ lc1 lc2 lc4 lc8 lc16 lc32 lc128 lc256 lc512))
  (IF (= summary 0)
    (SETQ pp_partcontains (CONS lastbit pp_partcontains))
    (SETQ pp_partcontains (CONS (+ lc1 lc2 lc4 lc8 lc16 lc32 lc128 lc256 lc512) pp_partcontains))
  )
  (SETQ $contains (+ b1 b2 b4 b8 b16 b32 b64 b128 b256 b512))
  (SETQ pp_lowhighlist (REVERSE pp_lowhighlist))
  (SETQ $startmax (LENGTH pp_lowhighlist)) ; Number of starts
  (SETQ pp_probeidx -1)
  (SETQ pp_measurepointvectors (REVERSE pp_measurepointvectors))
  ; *ZAxisOption* 0

  (COND
    ((NOT *UseSixAxis*) nil)
    ((= *ZAxisOption* 2) ; If using height sensor and Z
      (IF (> (ABS (- zmax zmin)) 0.2) ; If Z-is different on tube cutting
        (IF (NOT (GP-YESNO "Do you really want to use height senor on this job?" nil)) (QUIT "*Cancel*"))))
  )
  (SETQ pp_partmax (CONS (LENGTH pp_lowhighlist) pp_partmax))
  (SETQ pp_partmax (CDR (REVERSE pp_partmax))) ;pp_partmax is a list of the last cutton on each part. This to know if we should move in other height in 2D. Last cuts will have $lastcutonpart = T
  ;(ALERT (STRCAT "PP_PARTMAX: " (TOSTR pp_partmax)))
  (SETQ pp_partcontains (REVERSE pp_partcontains))
  (SETQ pp_oldpos (LIST 0.0 0.0 *ZMaxMovement*))
)

(DEFUN buildver (/ txt s skip)
  (SETQ txt "")
  (FOREACH s (REVERSE *IGEMSVersion*)
    (IF (= s ".") (SETQ skip T))
    (IF (NOT skip) (SETQ txt (STRCAT s txt)))
  )
  (ATOI txt)
)

(IF (OR ppp_sim1 ppp_sim2 ppp_sim3)
  (LOAD (STRCAT (GETVAR "PATHROOT") "LSP/SIMULATOR.LSP")
  (ALERT (STRCAT "Cant find: " (GETVAR "PATHROOT")  "LSP/SIMULATOR.LSP")))
)

(DEFUN $extsub (allpos $r $attrib qua)
  (SETQ $z (DEFZ (CADDR allpos)))
  (DEFAXIS allpos pp_oldrot)
  (DEFVARS)
  (EXTSUB)
)
    ;($REFPOS '(324.244258 0 350.080192) '(-1.570796 0.220972 0) '(0.219178 0 0.975685) 0 T)
(DEFUN addpoints (pt1 pt2) ; add the x values, y valus and z valus togeter to a new vector
  (LIST (+ (CAR pt1) (CAR pt2)) (+ (CADR pt1) (CADR pt2)) (+ (CADDR pt1) (CADDR pt2)))
)

(DEFUN subpoints (pt1 pt2) ; subtract the first vector with the second vector
  (LIST (- (CAR pt1) (CAR pt2)) (- (CADR pt1) (CADR pt2)) (- (CADDR pt1) (CADDR pt2)))
)

(DEFUN $header ( / datelist timelist tmp)
  (SETQ $igems *IGEMSVersion*)

  ;(SETQ $post (FILE-NAMEONLY *PPName* T)) ; This is now in fixvars
  (SETQ tmp (CADR (CAR (REVERSE pp_toolcords))))
  (SETQ $xtoolinit (CAR tmp) $ytoolinit (CADR tmp))
  (SETQ $abs T)
  (SETQ $activectrl *ToolActiveByController*)
  (SETQ $alloy *QualityName*)
  (SETQ $cutparname *CutPar*)
  (SETQ $date *Date*)
  (SETQ $datedue (ITOA $datedue))
  (SETQ $datedue (STRCAT (STRSUB $datedue 1 4) "-" (STRSUB $datedue 5 6) "-" (STRSUB $datedue 7 8)))
  (SETQ timelist (TIME))
  (SETQ h (ITOA (NTH 0 timelist)) m (ITOA (NTH 1 timelist)))
  (IF (= (STRLEN h) 1) (SETQ h (STRCAT "0" h)))
  (IF (= (STRLEN m) 1) (SETQ m (STRCAT "0" m)))
  (SETQ $datecreated (STRCAT $date " " h ":" m))
  (SETQ $digfile *Digfile*)
  (SETQ $group (IF *UseAlias* *Alias* *Name*))
  (SETQ $density *Density*)
  (SETQ $distctrl *ToolDistanceByController*)
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
  (IF (= $speedmode 3) (SETQ $speedipo T))
  (SETQ $flyonoff *AWJFlyingAbrasive*)
  (SETQ $name (IF pp_filename (FILE-NAMEONLY pp_filename) ""))
  (SETQ $maxspeed *Maxfeed*)
  (SETQ $maxbar *AWJMaxPumpPressure*)
  (SETQ $minspeed *Minfeed*)
  (SETQ $minbar *AWJMinPumpPressure*)
  (SETQ $pack *ToolClosestDistance*)
  (SETQ $parking *ToolPark*)
  (SETQ $sheetx *Sheetx* $sheety *Sheety*)
  (SETQ $sheetname *SheetName*)
  (SETQ $xrough 0 $rough 0 $medium 0 $fine 0 $xfine 0)
  (SETQ $cando5x (IF *Has5XKinematics* T nil))

  (SETQ $cando6x *HasSixAxis*)
  (SETQ $uses6x *UseSixAxis*)
  (SETQ $6x-direction *SixAxisDirection*) ; 0=100, 1=0-10, 2=-100, 3=010  4= 101 5=011
  (SETQ $6x-reverse *SixAxisReverseRotation*)
  (SETQ $6x-origo *SixAxisOrigo*) ; 3D point of position in 3D-5X
  (SETQ pp_$c 0.0)

  (SETQ $drillrpm *DrillingRotationSpeed*)
  (SETQ $drillspeed *DrillingSpeed*) ; This should be removed after fixing this in STM postprocessor.
  (SETQ $drillfeed *DrillingSpeed*)
  (SETQ $drillstep *Drillingstep*)
  (SETQ $drillfeed *DrillingSpeed*)
  (SETQ $drillbytype *DrillByType*)
  (SETQ $drillupz (IF *DrillLiftZ* *DrillLiftHeight* 0.0))
  (SETQ $markupz (IF *MarkingLiftZ* *MarkingLiftHeight* 0.0))
  (SETQ $markbytype *MarkingByType*)
  (SETQ $piercebytype *PiercingByType*)
  (SETQ $piercupz (IF *PiercingLiftZ* *PiercingLiftHeight* 0.0))
  (SETQ $cuttingupz (IF *CuttingLiftZ* *CuttingLiftHeight* 0.0))
  (SETQ $partupz (IF *CuttingLiftZParts* *CuttingLiftHeightParts* 0.0))
  (SETQ $maxupz (DEFZ *ZMaxMovement*))
  (SETQ pp_zmaster *ZMaxMovement*)
  (IF (> $drillupz $maxupz) (SETQ $drillupz $maxupz))
  (IF (> $markupz $maxupz) (SETQ $markupz $maxupz))
  (IF (> $piercupz $maxupz) (SETQ $piercupz $maxupz))
  (IF (> *InternalToolCompensation* 0) (SETQ $kerfcnc T))
  (COND
    ((= *MachineType* 0) ; AWJ cutting
      (SETQ $abrasive *AWJAbrasiveQuality*)
      (SETQ $cutflow (IF *AWJCuttingAbrasiveFlowByMachine* *AWJAbrasiveFlow* *AWJCuttingAbrasiveFlow*))
      (SETQ $abrasiveflow $cutflow) ; just to be compatible can be removed july 2012
      (SETQ $markflow (IF *AWJMarkingUseAbrasive* *AWJMarkingAbrasiveFlow* 0))
      (SETQ $piercflow (IF *AWJPiercingAbrasiveFlowByMachine* $cutflow *AWJPiercingAbrasiveFlow*))
      (SETQ $orifice *AWJOrifice*)
      (SETQ $tube *AWJMixingTube*)
      ;(SETQ $markbar *MarkingPressure*)
      ;(SETQ $piercbar *Piercingpressure*)
      ;(SETQ $cutbar *Cuttingpressure*)
      ;(SETQ $highbar (MAX $cutbar $piercbar $markbar))
      ;(SETQ $lowbar (MIN $cutbar $piercbar $markbar))
      (SETQ $bar $startbar)
      (IF (NOT $bar) (SETQ $bar 0.0))
      (SETQ $psi (FIX (* $bar 14.5038)))
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
      (SETQ $fe $f $fs $f)
      (SETQ $medium *WaterCuttingSpeed*))
  )
  (SETQ $zmode pp_zmode)
  (COND
    ((> *Machinetype* 1) ; changed 2012-09-27
      (SETQ $sensormode nil  $sensordist 0 $sensorsec 0))
    ((= *ZAxisOption* 2) ; When the Sensor is selected in the Strategy command.
      (SETQ $sensormode *ZSensoringmode*)
      (SETQ $sensordist *ZSensoringDistance*)
      (SETQ $sensorsec (/ *ZSensoringDistance* (/ $medium 60))))
  )
  (SETQ $box *PartsBox*)
  (SETQ $z *CuttingLiftHeightParts*)
  (COND
    ((= *InternalToolCompensation* 2) (SETQ $kerfsize (* *Tooldiameter* 0.5)))
    ((= *InternalToolCompensation* 1) (SETQ $kerfsize (* *AWJAdditionalkerf* 0.5)))
    (T (SETQ $kerfsize 0))
  )
  ;(SETQ $kerfsize (IF (= *InternalToolCompensation* 2) (* *ToolDiameter* 0.5) 0.0))
  (SETQ pp_zupper *ZMaxMovement*)
  (IF (MEMBER $zmode (LIST 1 2 4 5))
    (SETQ pp_zmaster (+ *Thickness* *ZAutoDist*)))
  (HEADER)
)

(DEFUN $measurepoint (allpos $vector attrib / pp_vec $index $offset)
  (SETQ $probetype (ATOI attrib))
  (SETQ $index (ATOI (STRSUB attrib 2)))
  (IF *ProbeTilted* ; This is WJS with telescope probe on secondary axis
    (PROGN
    ;  (SETQ $offset (CAR pp_measurepointvectors)) ;
      (SETQ $offset (TRANSAB *Sensoroffset* (CAR pp_oldrot) (CADR pp_oldrot))) ; Displacement is between the RTCP and the Probe position
      (SETQ p1 allpos) ; P1 and allpos is the raw position of the start of the vector near the model
      (SETQ p2 (ADDPOINTS p1 $offset)) ; P2 is the start of the vector near the model
      (SETQ p3 (ADDPOINTS p2 $vector)) ; P3 is the end of the vector away from the model
      ;(SETQ $vector (NORMALIZE vector))
      ;(SETQ $index (ATOI attrib))
      (SETQ allpos p2)
      (DEFAXIS allpos pp_oldrot)
      (SETQ $z (DEFZ (CADDR allpos)))
      (DEFVARS)
      (MEASUREPOINT)
      (SETQ pp_nextnoabmove T)
      (SETQ pp_measurepointvectors (CDR pp_measurepointvectors)))
    (PROGN
      (SETQ pp_vec $vector)
      (SETQ $len (DISTANCE (LIST 0 0 0) vector))
      (SSIM-LINE allpos 500 500 (LIST 0 0 0))
      (SIM-INFOTEXT "")
      (SSIM-LINE pp_oldpos 500 500 (LIST 0 0 0))
      (SIM-INFOTEXT "")
      ;(SETQ $index (ATOI attrib))
      (DEFAXIS allpos pp_oldrot)
      (SETQ $z (DEFZ (CADDR allpos)))
      (MEASUREPOINT))
  )
)

(DEFUN $refpos (allpos allrot $vector flag $probedir / $offset debug p1 p2 p3)
  (SETQ debug nil)
  (IF debug (WRITE (STRCAT "START OF REFPOS " (TOSTR allpos) " " (TOSTR allrot) " " (TOSTR pp_maxz))))
  (SETQ oldmode $mode)
  ($CHMODE 8)
  ; To a point above end of the vector
  (SETQ $offset (TRANSAB *Sensoroffset* (CAR allrot) (CADR allrot))) ; Displacement is between the RTCP and the Probe position
  (SETQ p1 allpos) ; P1 and allpos is the raw position of the start of the vector near the model
  (SETQ p2 (ADDPOINTS p1 $offset)) ; P2 is the start of the vector near the model for measure stick
  (SETQ p3 (ADDPOINTS p2 $vector)) ; P3 is the end of the vector away from the model for the measure stick
  (DEFAXIS p3 allrot)
  (SETQ $z (DEFZ (CADDR p3)))
  (SSIM-RAPID p3 *SpeedRapid* *SpeedAcceleration* allrot)
  (SIM-INFOTEXT "")
  (SETQ $reason 4)
  (SETQ tid (MAX (/ (ABS $arel) *HeadPrimaryMaxSpeed*) (/ (ABS $brel) *HeadSecondaryMaxSpeed*)))
  (SIM3D-TILT (- (CAR allrot)) (- (CADR allrot)) $arel $brel)
  ($TILT $a $b 1)
  (RAPID)
  (SIM-INFOTEXT "")
  ; Down to vectorend
  (DEFVARS)
  (DEFAXIS p2 allrot)
  (SETQ $z (DEFZ (CADDR p2)))
  (REFPOS)
  (SETQ pp_oldpos p3)
  ($CHMODE oldmode)
  (IF debug (WRITE "END OF $REFPOS"))
)

(DEFUN $footer ( / mrapid datelist timelist $on $off / tid)
  (IF (AND *Has5XKinematics* (NOT *HeadStraight*) pp_headistilt)
    (PROGN
      (SETQ tid (MAX (/ (ABS $a) *HeadPrimaryMaxSpeed*) (/ (ABS $b) *HeadSecondaryMaxSpeed*)))
      (DEFAXIS pp_oldpos (LIST 0 0 0))
      (SIM3D-TILT 0 0 $a $b)
      ($TILT 0 0 4)))
  (IF *GotoParkPos*
    (PROGN
      (SETQ $x *ParkPosX* $y *ParkposY* $reason 2)
      (MRAPID)))
  (DEFUN mrapid () nil) ;to be backward compatible, since we now handle go to park form lsp2
  (SETQ $runsec (* (SIM-RUNTIME) 0.001))
  (SETQ $runtime (SecToTime $runsec))
  (SETQ $cutlen (SIM-CUTLENGTH))
  (SETQ $abrasiveamount (SIM-SANDWEIGHT))
  (SETQ $maxpartid pp_maxpartid)
  (SETQ $lines wline)
  (IF (AND $pumpstop $startbar) ; Startbar is nil if it's only drilling
    (PROGN
      (SETQ $on nil $off T)
      (SETQ $bar $startbar $usehighbar pp_usehighbar)
      (SETQ $psi (FIX (* $bar 14.5038)))
      (SETQ $barunchanged (IF (EQUAL $bar pp_oldbar 1) T nil))
      (SETQ $delay *AWJDelayPressureDown*)
      (IF (NOT *SerialProduction*) (SETQ $barunchanged T))
      (IF $release (SETQ $barunchanged T)) ; The pressure is already released in $cutoff
      (PUMPONOFF))
  )
  (FOOTER)
  (IF (AND (> *Maxslope* (+ *HeadMaxTilt* 0.0002)) (> *Headmaxtilt* 0.01))
    (PROGN
      (BEEP)
      (SETQ pp_delfile (GP-YESNO (STRCAT "Maximal cutting angle " (ANGTOS *HeadMaxTilt* 2) " exceed by " (ANGTOS (ANGDIFF *HeadMaxTilt* *Maxslope*) 3) "\nDelete file?") T)))
  )
)

(DEFUN $plasma (edge)
  (SETQ $edge edge)
  (PLASMA)
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

(DEFUN $measure (allpos zref) ;NOTE! Tpp_allpos is a 2D point
  (SETQ allpos (ZREPLACE allpos *ZMaxMovement*))
  (IF (NOT pp_kdtree)
    (SETQ pp_kdtree (KDTREE-CREATE (LIST (ZREPLACE allpos (SETQ pp_kdmax 1)))))
    (SETQ pp_kdtree (KDTREE-INSERT pp_kdtree (ZREPLACE allpos (SETQ pp_kdmax (1+ pp_kdmax)))))
  )
  (SETQ pp_kdlist (CONS (LIST pp_kdmax (CAR allpos) (CADR allpos)) pp_kdlist))
  (IF (> pp_kdmax *ZMeasureMaxPoints*) (QUIT (ALERT (STRCAT "To many measurepoints. " (ITOA pp_kdmax) " are used"))))
  (SSIM-RAPID allpos *SpeedRapid* *SpeedAcceleration* (LIST 0 0 0))
  (SIM-MEASURE)
  (DEFAXIS allpos (LIST 0 0 0))
  (SETQ $zref zref)
  (MEASURE)
  (SETQ pp_oldpos allpos) ; Ändat från pp_allpos till allpos 23/3-26 BJ
)

(DEFUN measure ()
  nil
)

(DEFUN $part (partname customer datum quantity connected box basex basey rotate partid pathid sortid 3d5x contains color pathattrib geoflag / p1 p2 p3 p4 trans rx ry d dd oldx oldy)
  ; Variables are re-defined to be globals
  ; Note! contains is no longer used as information in the preparation file. It is not comming from the pp_partcontains list fro the chkall function
  ; NOTE $Contains is now valid as long as it not overwritten by next part
  (SETQ $orderattrib pathattrib)
  (SETQ $geoflag geoflag) ;info if part is mirrored
  (IF (> partid pp_maxpartid) (SETQ pp_maxpartid partid))
  (IF (= $mode 0)
    (PROGN
      (SETQ $mode nil $mold 0)
      (CHMODE)
      (SETQ $mode nil $mold nil)))
  (DEFUN trans (pt / rx ry)
    ; PP_XOFFSET and PP_YOFFSET holds the distance between T1 position to the first used tool.
    (SETQ rx (- (* (CAR pt) (COS rotate)) (* (CADR pt) (SIN rotate))))
    (SETQ ry (+ (* (CADR pt) (COS rotate)) (* (CAR pt) (SIN rotate))))
    (LIST (+ rx pp_basex) (+ ry pp_basey))
  )

  (COND
    ((AND (NOT 3d5x) (EQUAL *Thickness* *Masterthickness* 0.01)) nil) ; No thickness changed
    ((NOT 3D5X) ; Thickness is changed because it was a 3D-5X part before.
      (SETQ *Thickness* *Masterthickness*)
      (SETQ pp_initheight T))
    ((EQUAL *Thickness* 3d5x 0.01) nil) ; Same thickness
    (3d5x
      (SETQ *Thickness* 3d5x)
      (SETQ pp_initheight T))
  )
  ;(SETQ $contains contains)
  (SETQ $contains (CAR pp_partcontains))
  (SETQ pp_partcontains (CDR pp_partcontains))

  (SETQ $thickness *Thickness*)
  (SETQ $3d5xpart 3d5x)
  (SETQ $partname partname)
  (SETQ $customer customer)
  (IF (SETQ $partdate (DATETOSTR datum)) nil (SETQ $partdate "20220214"))
  (SETQ $partdate (STRCAT (STRSUB $partdate 1 4) "-" (STRSUB $partdate 5 6) "-" (STRSUB $partdate 7 8)))
  (SETQ $quantity quantity)
  (SETQ $connected (NOT connected))
  (SETQ pp_basex basex)
  (SETQ pp_basey basey)
  (SETQ oldx $x oldy $y)
  (DEFAXIS (LIST basex basey 0.0) (LIST 0 0 0))
  (SETQ $basex $x $basey $y) ; Points are aligned to actual aligment of the cordinate system.
  (SETQ $x oldx $y oldy)
  (SETQ $rotate rotate pp_rotate rotate)
  (SETQ $box box)
  (SETQ p1 (TRANS (LIST (CAR $box) (CADR $box))))   ; Lower left corner in angle 0
  (SETQ p2 (TRANS (LIST (CADDR $box) (CADR $box)))) ; Lower right corner
  (SETQ p3 (TRANS (LIST (CADDR $box) (CADDDR $box)))) ;Upper right corner in angle 0
  (SETQ p4 (TRANS (LIST (CAR $box) (CADDDR $box)))) ; Upper Left corner roterad box
  (SETQ $boxcenter (POLAR p1 (ANGLE p1 p3) (* (DISTANCE p1 p3) 0.5))) ; Centrum av roterad box
  (SETQ $boxrotated (LIST (MIN (CAR p1) (CAR p2) (CAR p3) (CAR p4)) (MIN (CADR p1) (CADR p2) (CADR p3) (CADR p4))
                          (MAX (CAR p1) (CAR p2) (CAR p3) (CAR p4)) (MAX (CADR p1) (CADR p2) (CADR p3) (CADR p4))))
  (SETQ $chpart (IF (EQUAL partid pp_olpartid) nil T))
  (SETQ $partcolor color)
  (SETQ $partid partid)
  (SETQ $pathid pathid)
  (SETQ $sortid sortid)
  (IF (= $sensormode 1) (SETQ $initpartwice T))
  (COND
    ((AND (= $mode 2) *3D-5X*) ; If marking
      ($RAPID (ZREPLACE pp_oldpos (+ pp_zclear $markupz)) nil 4 pp_oldrot tilted flag)
    )
  )
  (SIM-PARTID sortid)
  (PART)
  (IF (= *ZSensoringMode* 1) (SETQ $sensor 1))
)

(DEFUN $pathinfo (box flag / p1 p2)
 (IF pp_toolreset (PROGN (EVAL pp_toolset))) ; Calling last $TOOLSET again after the $TPTOOLSET cut is done.
 (SETQ p1 (LIST (CAR box) (CADR box)) p2 (LIST (CADDR box) (CADDDR box)))
 (SETQ $box box)
 (SETQ $boxcenter (POLAR p1 (ANGLE p1 p2) (* (DISTANCE p1 p2) 0.5)))
 (SETQ $connected (IF (> (LOGAND flag 1) 0) nil T)) ; Flag is 1 if its disconnected
 (PATHINFO)
)

(DEFUN $hole (allpos typ radie pp_attrib pp_quality / *MachineType* ishole );typ: 0=Drilling (Not used), 1=Marking, 2=Circular piercing, 3=HQCH, 4=Stationary piercing. Quality: in HQCH
  (COND
    ((= typ 0) nil) ; Are not using any more prepfile are using $DRILLING
    ((= typ 1) ; Marking
      ;(IF (OR pp_MarkingBarMayChange pp_MarkingGramMayChange) ($CHBARGRAM $markbar $markflow))
      ($CHMODE 2) ; Be sure that marking is activated
      (SETQ ishole T)
        ($MARKON allpos pp_attrib 0.0 (LIST 0 0 0) nil nil 0 0 nil)
      ($MARKOFF 0 (LIST 0 0 0)))
    ((OR (= typ 2) (= typ 4)) ; 2=Circular piercing, 4=Stationary piercing
     (SETQ pp_ptype (IF (= typ 4) 2 3))
     (IF pp_PiercingBarMayChange
        (PROGN
          ($CHMODE 3) ; Be sure that pre-piercing is activated
          ($PRE-PIERCING allpos pp_ptype "HOLE" "HOLE" (LIST 0 0 (- (CADDR allpos))) 0 (LIST 0 0 -1) (LIST 0 0 0) ""))
        (PROGN
          ($CHMODE 4) ; Be sure that cutting is activated
          ($PRE-PIERCING allpos pp_ptype "HOLE" "HOLE" (LIST 0 0 (- (CADDR allpos))) 0 (LIST 0 0 -1) (LIST 0 0 0) ""))
      ))
    ((= typ 3)
      ;(SETQ *MachineType* 1)
      (COND
        ((= *MachineType* 0) ($HQCHAWJ allpos radie pp_attrib pp_quality))
        ((= *MachineType* 1) ($HQCHWATER allpos radie pp_attrib pp_quality))
        ((= *Machinetype* 2) ($HQCHPLASMA allpos radie pp_attrib pp_quality))))
    ((= typ 5) ($EXTSUB allpos radie pp_attrib pp_quality))
  )
)
(DEFUN $carc (x y r ccw feed / endp hcorda acorda mpcorda height cent)
  ;pp_oldpos have the correct current position
  (SETQ endp (LIST (+ (CAR pp_oldpos) x) (+ (CADR pp_oldpos) y) (CADDR pp_oldpos)))
  (SETQ hcorda (* (DISTANCE pp_oldpos endp) 0.5)) ; half lenght of corda
  (SETQ acorda (ANGLE pp_oldpos endp)) ; angle of corda
  (SETQ mpcorda (POLAR pp_oldpos acorda hcorda)) ; midpoint of corda
  (SETQ height (SQRT (- (* r r) (* hcorda hcorda))))
  (SETQ cent (ZREPLACE (POLAR mpcorda (IF ccw (+ acorda PIH) (- acorda PIH)) height) (CADDR pp_oldpos)))
  ($ARC endp cent T 64 feed feed 0 (LIST 0 0 (- $thickness)) (LIST 0 0 0) nil) ; pp_oldpos will be updated in $arc
)

(DEFUN $cline (x y feed / tmpp pp_skipsim dist len) ; Har lagt dit Z
  (SETQ endp (LIST (+ x (CAR pp_oldpos)) (+ y (CADR pp_oldpos)) (CADDR pp_oldpos)))
  (SETQ len (DISTANCE (LIST 0 0) (LIST x y)))
  ;(SETQ pp_skipsim (IF $hqch nil T))
  (SETQ pp_vec (LIST 0 0 (- $thickness)))
  ($LINE endp 64 feed feed 0 pp_vec pp_oldrot len)
)

(DEFUN $ccircle (i j feed / centp radi segs segang segdir pt pp_skipsim) ;ZOK Har lagt dit Z
  (SETQ centp (LIST (+ (CAR pp_oldpos) i) (+ (CADR pp_oldpos) j) (CADDR pp_oldpos)))
  (SETQ radi (DISTANCE (LIST 0 0) (LIST i j)))
  (SETQ segs (CEIL (/ PID *LargestSegmentAngle*)))
  (SETQ segang (/ PID segs))
  (SETQ segdir (ANGLE (LIST 0 0) (LIST (- i) (- j)))) ;Direction from center to actual position.
  (SETQ pp_skipsim (IF $hqch nil T))
  (REPEAT segs
    (SETQ pt (POLAR centp (SETQ segdir (+ segdir segang)) radi))
    (SETQ allpos (LIST (CAR pt) (CADR pt) (CADDR pp_oldpos)))
    ($ARC allpos centp T 64 feed feed 0 pp_vec pp_oldrot 10)
  )
)
(DEFUN cpierc-line (out / ptlist pt pp_skipsim rr)
  ; $piercingpos is the corect piercing position.
  ;(SETQ pp_skipsim T)
  (SETQ rr $cpradius)
  (IF *CustomCircularPiercing* (SETQ rr 0.0))
  (COND
    ((NOT out)
      ($LINE $piercingpos 8 $cpfeed $cpfeed hPI pp_vec pp_oldrot rr))
    ((AND out (NOT $leadtilt))
      ($LINE (LIST (+ (CAR $piercingpos) $cpradius) (CADR $piercingpos) (CADDR $piercingpos)) 8 $cpfeed $cpfeed hPI pp_vec pp_oldrot rr))
    (T
      (SETQ ptlist (CIRCLEPOINTS $leadplan $cpradius 6))
      (SETQ pt (CAR ptlist))
      (SETQ pt (LIST (+ (CAR pt) (CAR $piercingpos)) (+ (CADR pt) (CADR $piercingpos)) (+ (CADDR pt) (CADDR $piercingpos))))
      ($LINE pt 8 $cpfeed $cpfeed hPI pp_vec pp_oldrot rr)
    )
  )
)

(DEFUN cpierc-circle (/ cp ntxt segs segang segdir pt ptlist pp_skipsim rr) ;ZOK Har lagt dit Z
  ; (IF *CustomCircularPiercing* (SETQ pp_skiptxtout T) (SETQ pp_skiptxtout nil))  ; pp_skiptxtout: Control if CNC-information should be added or not. If T only simulation
  ;(SETQ pp_skipsim T)
  (SETQ cp $piercingpos)
  (IF (NOT $leadtilt)
    (PROGN
      (SETQ segs (CEIL (/ PID *LargestSegmentAngle*)))
      (SETQ segang (/ PID segs))
      (SETQ segdir 0.0) ;Direction from center to actual position.
      (SETQ rr (* segang $cpradius))
      (IF *CustomCircularPiercing* (SETQ rr 0.0))
      (REPEAT segs
        (SETQ pt (POLAR $piercingpos (SETQ segdir (+ segdir segang)) $cpradius))
        ;(IF (NOT $hqch) (SETQ pp_skipsim T))
        ($ARC (LIST (CAR pt) (CADR pt) (CADDR $piercingpos)) $piercingpos T 64 $cpfeed $cpfeed 0 pp_vec pp_oldrot rr)
      )
    )
    (PROGN
      (SETQ ptlist (CIRCLEPOINTS $leadplan $cpradius 8))
      (SETQ rr (DISTANCE (CAR ptlist) (CADR ptlist)))
      (IF *CustomCircularPiercing* (SETQ rr 0.0))
      (FOREACH s ptlist
        (SETQ pt (LIST (+ (CAR cp) (CAR s)) (+ (CADR cp) (CADR s)) (+ (CADDR cp) (CADDR s))))
        ($LINE pt 8 $cpfeed $cpfeed 2.35619 pp_vec allrot rr)
      )
    )
  )
)

(DEFUN circ-piercing (/ savepos xx yy zz speed diam omkrets tocut varv radtocut segq sega stv ptlist)
  (IF *CustomCircularPiercing* (SETQ pp_skiptxtout T) (SETQ pp_skiptxtout nil))  ; pp_skiptxtout: Control if CNC-information should be added or not. If T only simulation
  (SETQ savepos $piercingpos)
  (SETQ pp_oldpos $piercingpos)
  (SETQ xx (CAR pp_oldpos) yy (CADR pp_oldpos) zz (CADDR pp_oldpos))
  (IF (= *MachineType* 0) ; AWJ machine
    (PROGN
      (SETQ speed *AWJCircularPiercingSpeed*)
      (SETQ diam *AWJCircularPiercingDiameter*))
    (PROGN
      (SETQ speed 200)
      (SETQ diam *WaterPiercingDiameter*)
      (SETQ $time *WaterPiercingTime*)))
  (SETQ omkrets (* diam PI))
  (SETQ tocut (* (/ speed 60.0) $time)) ; Lenght in mm to go in circular
  (SETQ varv (/ tocut omkrets)) ; Totaly number of turns to pierce
  (IF (< varv 1) (SETQ varv 1.0))
  (SETQ radtocut (* varv PID)) ; Totaly angle to pierce
  (SETQ segq (CEIL (/ radtocut *LargestSegmentAngle*))) ; Number of LargestSegmentAngle to cut
  (SETQ sega (/ radtocut segq)) ; Segmentangle to cut
  (SETQ stv 0)
  (IF (NOT $leadtilt)
    (PROGN
      ($LINE (LIST (+ xx (* diam 0.5)) yy zz) 8 speed speed hPI pp_vec pp_oldrot (* diam 0.5))
      (REPEAT segq
        (SETQ pt (ZREPLACE (POLAR (LIST xx yy) (SETQ stv (+ stv sega)) (* diam 0.5)) zz))
        ($ARC pt (LIST xx yy zz) T 8 speed speed 0 pp_vec pp_oldrot (* sega (* diam 0.5)))
      )
      ($LINE (LIST xx yy zz) 8 speed speed hPI pp_vec pp_oldrot (* diam 0.5)))
    (PROGN
      (SETQ ptlist (CIRCLEPOINTS $leadplan (* diam 0.5) 6))
      (SETQ rr (DISTANCE (CAR ptlist) (CADR ptlist)))
      (REPEAT (CEIL varv)
        (FOREACH s ptlist
          (SETQ pt (LIST (+ xx (CAR s)) (+ yy (CADR s)) (+ zz (CADDR s))))
          ($LINE pt 8 speed speed 2.35619 pp_vec allrot rr)
        )
       )
     ($LINE savepos 8 speed speed 2.35619 pp_vec allrot rr)
    )
  )
  (SETQ pp_skiptxtout nil)
)

(DEFUN $rotax ($vector $ft allrot pp_fe $len / ft $ton $toff)
  ; Only tube rotation: This means time for movements in minutes. Only AB moves ere means time for movement in seconds.
  (IF (NOT *UseSixAxis*)
    (PROGN
      (IF (NOT pp_timemode) (SETQ $ton T pp_timemode T))
      (IF (NOT (= $nextcmd '$ROTAX )) (SETQ $toff T pp_timemode nil))))
  (SETQ gtype 1)
  (SETQ pp_vec $vector)
  (IF (< $ft 0.00000001) (SETQ $ft 0.00000001))
  (SETQ ft $ft)
  (DEFAXIS pp_oldpos allrot)
  (DEFVARS)
  (SETQ $ft ft)
  (SSIM-LINE pp_oldpos $fs $fe allrot) ;Xmod and Ymod is for the marking offset
  (ROTAX)
  (SETQ pp_oldrot allrot)

)

(DEFUN $line3d (allpos allrot / $len pp_fs pp_fe $vertical)
  (IF *ZPiercingUse*
    (PROGN
      (IF (> pp_fe 200) (SETQ pp_fs 200 pp_fe 200))
      (DEFAXIS allpos allrot)
      (DEFVARS)
      (SETQ $z (DEFZ (CADDR allpos)))
      (SETQ $ft (/ *ZPiercingDist* pp_fe))
      (SETQ $len (ABS (- (CADDR pp_oldpos) (CADDR allpos)))) ; Ändrat från pp_allpos till allpos 23/3-26 BJ
      (SSIM-LINE allpos pp_fs pp_fe allrot)
      (IF (EQUAL (CDR (REVERSE allpos)) (CDR (REVERSE pp_oldpos)) 0.0001) (SETQ $vertical T))
      ;(IF (AND (EQUAL $xrel 0.0 0.0001) (EQUAL $yrel 0.0 0.0001)) (SETQ $vertical T))
      (LINE3D)
      (SETQ pp_oldpos allpos)))
)

(DEFUN $line (allpos pp_flag pp_fs pp_fe $delta pp_vec allrot len / pp_pt len loops pt xmod ymod gtype pp_vectordir gtype)
  ; pp_flag: 1=Leadin, 2=Leadout, 4=Marking, 8=Cirular piercing, 64=Custom line 128=belong special marking
  (SETQ pp_fs (* pp_fs *Speedfactor*) pp_fe (* pp_fe *Speedfactor*)) ; Need this for Soitaab to reduce speed whwen using two jets (50%)
  (IF *speedoverride* (SETQ pp_fe *speedoverride* pp_fs *Speedoverride*))
  (SETQ $vector pp_vec)
  (SETQ pp_cutdirection cutdir)
  (SETQ pp_vectordir vectordir)
  (SETQ pp_len len)
  (IF pp_fsuse (SETQ pp_fs pp_fsuse pp_fsuse nil))
  (IF (NOT pp_cutdirection) (SETQ pp_cutdirection 0))
  (IF (NOT pp_vectordir) (SETQ pp_vectordir 0))
  (IF (NOT pp_oldvectordir) (SETQ pp_oldvectordir pp_vectordir))
  (SETQ ispiercing (IF (OR (> (LOGAND pp_flag 8) 0) (> (LOGAND pp_flag 64) 0)) T nil))
;  (IF (AND $useabr (> (LOGAND pp_flag 128) 0))
;    (PROGN
;      (SETQ pp_useabr $useabr)
;      (SETQ $useabr nil)
;      (ABROFF)))

  (SETQ gtype 1) ;behövs för Software RTCP
  ; Set up standard variables
  (IF (AND (= *rtcptype* 1) pp_vec (NOT ispiercing))
    (PROGN
      (SETQ mod (ICOMP pp_vec))
      (SETQ allpos (LIST (- (CAR allpos) (CAR mod)) (- (CADR allpos) (CADR mod)) (CADDR allpos)))))
  (IF pp_len
    (SETQ $len pp_len)
    (SETQ $len (DISTANCE pp_$oldp pp_$pt)) ; The lenght of the line
  )
  (SETQ pp_unkerf (POLAR pp_oldpos (ANGLE pp_oldpos allpos) (* *ToolDiameter* 2)))
  (DEFAXIS allpos allrot)
  (DEFVARS)
  (SETQ $z (DEFZ (CADDR allpos)))
  (SETQ $ft (/ $len (* (+ $fe $fs) 0.5)))
  (IF (= $nextcmd '$CUTOFF) (SETQ $last T))
  (IF (= *InternalToolCompensation* 0) (SETQ $kerf 0))
  (IF (= pp_flag 1)  (SETQ $chkerf T))
  (IF (= pp_flag 32) (SETQ $chkerf T $kerf 0))
  ($FMODE $fs $fe)
  (IF (NOT pp_skipsim) (SSIM-LINE allpos pp_fs pp_fe allrot)) ;Xmod and Ymod is for the marking offset PP_SKIPSIM for CLINE AND CARC
  (IF (AND (NOT pp_skipsim) pp_skiptxtout) (SIM-INFOTEXT ""))
  (IF (NOT pp_skiptxtout)
    (PROGN
      (SETQ $zrel (- (- pp_$zold (SETQ pp_$zold $z))))
      (SETQ aspar $a bspar $b)
      (LINE)))
  (SETQ $chkerf nil)
  (SETQ pp_oldpos allpos)
  (SETQ pp_oldrot allrot)
  (SETQ pp_oldfeed pp_fe)
)

(DEFUN plasma () nil)

(DEFUN line()
  (WRITE (STRCAT (NTXT) "G01 X" (RTS $x) " Y" (RTS $y) " F" (RTF $fe)))
)

(DEFUN measurepoint ()
  (WRITE "(MEASUREPOINT)")
)

(DEFUN rapid ()
  (WRITE (STRCAT (NTXT) "G00 X" (RTS $x) " Y" (RTS $y)))
)

(DEFUN arc ()
  (WRITE (STRCAT (NTXT) (IF $ccw "G03" "G02") " X" (RTS $x) " Y" (RTS $y) " I" (RTS $i) " J" (RTS $j) " F" (RTF $fe)))
)


; Denna funktion måste optimeras för att gå till korrekt position vid simulering när man byter avstånd mellan jettar.
; *ZMovableQuantity* Sim forst text sen.

(DEFUN $tptoolset (tools toollist allpos / modspace simspace lowest)
  (IF pp_tptoolsetlist
    (PROGN
      (IF (EQUAL tools (CAR pp_tptoolsetlist)) (SETQ $toolunchanged T))
      (IF (EQUAL (CADR pp_tptoolsetlist) toollist) (SETQ $tooldistunchanged T))))
  (SETQ $tools tools)
  (COND
    ((= *ToolQuantity* 1) nil)
    ((AND *ToolCenterbase* (= *ToolQuantity* 3)) ; Base in center (T2) and 3 jets
      (COND
        ((= $tools 1) (SETQ simspace 0 modspace (- (CAR toollist)))) ; T1 Simulering OK Coordinates fel
        ((= $tools 2) (SETQ simspace *ToolMinDistance* modspace 0)) ; T2
        ((= $tools 3) (SETQ simspace 0 modspace (- (CAR toollist)))) ; T1+T2
        ((= $tools 4) (SETQ simspace (+ *ToolMinDistance* *ToolMaxDistance*) modspace (CAR toollist))) ; T4
        ((= $tools 5) (SETQ simspace 0 modspace (- (CAR toollist)))) ; T1+T3
        ((= $tools 6) (SETQ simspace *ToolMinDistance* modspace 0)) ; T2+T3
        ((= $tools 7) (SETQ simspace 0 modspace (- (CAR toollist)))) ; T1+T2+T3
      ))
    (*ToolCenterbase*
      (QUIT (ALERT "Only 3 jets are currently avaiable, contact IGEMS")))
    (*ToolClosestDistance* ; Pack unused tools as close as possible
      (COND
        ((NOT *CoordinateToFirstTool*) ; Coordinate to first used tool
          (SETQ modspace 0) ;OK
          (SETQ simspace (* (1- (GETLOWESTTOOL $tools)) *ToolMinDistance*)))
        (T ; Always coordinate to Tool 1 even if it is not used.
          (SETQ modspace (* (1- (GETLOWESTTOOL $tools)) *ToolMinDistance*))
          (SETQ simspace modspace))
      )
    )
    (*ToolPark* (SETQ modspace 0 simspace 0))
    ((NOT *ToolClosestDistance*) ; To be over clear
      (SETQ lowest (GETLOWESTTOOL $tools))
      (COND
        ((= lowest 1) (SETQ modspace 0))
        ((= lowest 2) (SETQ modspace (CAR toollist)))
        ((= lowest 3) (SETQ modspace (+ (CAR toollist) (CADR toollist))))
        ((= lowest 4) (SETQ modspace (+ (CAR toollist) (CADR toollist) (CADDR toollist))))
        ((= lowest 5) (SETQ modspace (+ (CAR toollist) (CADR toollist) (CADDR toollist) (CADDDR toollist))))
        ((= lowest 6) (SETQ modspace (+ (NTH 0 toollist) (NTH 1 toollist)(NTH 2 toollist)(NTH 3 toollist)(NTH 4 toollist))))
        ((= lowest 7) (SETQ modspace (+ (NTH 0 toollist) (NTH 1 toollist)(NTH 2 toollist)(NTH 3 toollist)(NTH 4 toollist) (NTH 5 toollist))))     
        ((= lowest 8) (SETQ modspace (+ (NTH 0 toollist) (NTH 1 toollist)(NTH 2 toollist)(NTH 3 toollist)(NTH 4 toollist) (NTH 5 toollist) (NTH 6 toollist)))) 
      )  
      (SETQ simspace modspace))
  )
  (IF (> *ToolQuantity* 1)
    (PROGN
      (COND ; Detta kopierat från 2022
        ((= *BarAligned* 0) (SETQ pp_xmodsim simspace pp_xmod modspace))
        ((= *BarAligned* 1) (SETQ pp_xmodsim (- simspace) pp_xmod (- modspace)))
        ((= *BarAligned* 2) (SETQ pp_ymodsim simspace pp_ymod modspace))
        ((= *BarAligned* 3) (SETQ pp_ymodsim (- simspace) pp_ymod (- modspace)))
      )
      (SSIM-TOOLSET tools toollist *ToolMovingSpeed*) ; will change the tooldistance and active tools only
      (DEFAXIS allpos pp_oldrot) ; sets X Y of first position
      (SETQ pp_oldpos allpos) ; detta var pp_allpos borde varit allpos BJ 23/3-26
      (SETQ $toollist toollist)
      (CHTOOL)
      (SETQ pp_tptoolsetlist (LIST tools toollist)) ; This is to not have to run CHTOOL if the tools and toollist is the same if $TPTOOLSET is the same and it comes severall after each other.
      (SETQ pp_tptoolset T) ; Flag that we need to restore $toolset
      (SETQ pp_toolreset nil) ; The variable will be set to T in cutoff,

    )
  )
)




(DEFUN GetLowestTool (toolbit / lowbit toolnr) ;returns the first used toolnumber from a toolbit value
  (SETQ lowbit 1 toolnr 1)
  (WHILE (= (LOGAND toolbit lowbit) 0) (SETQ lowbit (* lowbit 2) toolnr (1+ toolnr)))
  (EVAL toolnr)
)
(DEFUN GetHighestTool (toolbit / highbit toolnr) ; Returns the last used toolnumber from a toolbit
  (SETQ highbit 128 toolnr 8)
  (WHILE (= (LOGAND toolbit highbit) 0) (SETQ highbit (/ highbit 2) toolnr (1- toolnr)))
  (EVAL toolnr)
)



(DEFUN $toolset (tools tooldist align idx /  GetLowestTool GetHighestTool info simspace modspace lownr highnr tnr skip activemsg distmsg)

  ; Following variables must be handled
  ; *ToolQuantity* Is the number of
  ; *ToolPark* Is T if external jets should be parked. When using Toolpark the *CoordinateToFirstTool* is always nil. It will use coordinates to the first used tool.
  ; *CoordinateToFirstTool* can be T or nil if there is no possible to park external jets. If the value is nil then we should use the coordinate to the first used tool.
  ; *ToolClosestDistance* If this variable is nil then all jets will have the same distance no matter if its used or not. If the variable is T then the most outside unused jets will be packed as close as possible
  ; *ToolMinDistance* The closest possible distance between jets
  ; *ToolMaxDistance* The largest possible distance between jets.
  (SETQ pp_tptoolsetlist nil)
  (SETQ info nil)
  (DEFUN GetLowestTool (toolbit / lowbit toolnr) ;returns the first used toolnumber from a toolbit value
    (SETQ lowbit 1 toolnr 1)
    (WHILE (= (LOGAND toolbit lowbit) 0) (SETQ lowbit (* lowbit 2) toolnr (1+ toolnr)))
    (EVAL toolnr)
  )

  (DEFUN GetHighestTool (toolbit / highbit toolnr) ; Returns the last used toolnumber from a toolbit
    (SETQ highbit 128 toolnr 8)
    (WHILE (= (LOGAND toolbit highbit) 0) (SETQ highbit (/ highbit 2) toolnr (1- toolnr)))
    (EVAL toolnr)
  )

  (IF (< tooldist *ToolMinDistance*) (SETQ tooldist *ToolMinDistance*))
  (IF (MEMBER tools (LIST 1 2 4 8 16 32 64 128)) (SETQ dist *ToolFixDistance*))
  (IF info (WRITE "\nSTART $TOOLSET ******************************************************************************"))
  (COND
    ((AND *SkipToolInit* (= tools 1) (= idx 1)) ; If the option is selected and only T1 is active and it is the first toolset
      (SETQ $tooldistunchanged T $toolunchanged T skip T))
    ((NOT $tooldist)                               ; We need to do a CHTOOL since it is not done before
       (SETQ $tooldistunchanged nil $toolunchanged nil))
    (T
      (SETQ $tooldistunchanged (IF (EQUAL tooldist $tooldist 0.1) T nil)) ;If the distance is change
      (SETQ $toolunchanged (IF (EQUAL tools $tools) T nil))) ; If number of tool is changed.
  )
  (SETQ $tools tools)
  (SETQ $tooldist tooldist)
  (SETQ $toolindex idx)

  ; Simspace sets pp_xmodsim/pp_ymodsim: Cordinates in SIM-RAPID, SIM-LINE, SIM-ARC is always to first unparked tool. To use another tool than the first then we must modify the coorsinates.
  ; Modspace sets pp_xmod/pp_ymod: This values will modify the final $x $y
  (COND
    ((AND *ToolCenterbase* (= *ToolQuantity* 3)) ; Base in center (T2) and 3 jets
      (COND
        ((= $tools 1) (SETQ $toollist (LIST *ToolMaxDistance* *ToolMinDistance*) simspace 0 modspace (- *ToolMaxDistance*))) ; T1 Simulering OK Coordinates fel
        ((= $tools 2) (SETQ $toollist (LIST *ToolMinDistance* *ToolMinDistance*) simspace *ToolMinDistance* modspace 0)) ; T2
        ((= $tools 3) (SETQ $toollist (LIST tooldist *ToolMinDistance*) simspace 0 modspace (- tooldist))) ; T1+T2
        ((= $tools 4) (SETQ $toollist (LIST *ToolMinDistance* *ToolMaxDistance*) simspace (+ *ToolMinDistance* *ToolMaxDistance*) modspace *ToolMaxDistance*)) ; T4
        ((= $tools 5) (SETQ $toollist (LIST tooldist tooldist) simspace 0 modspace (- tooldist))) ; T1+T3
        ((= $tools 6) (SETQ $toollist (LIST *ToolMinDistance* tooldist) simspace *ToolMinDistance* modspace 0)) ; T2+T3
        ((= $tools 7) (SETQ $toollist (LIST tooldist tooldist) simspace 0 modspace (- tooldist))) ; T1+T2+T3
      )
      (COND
        ((= *BarAligned* 0) (SETQ pp_xmodsim simspace pp_xmod modspace))
        ((= *BarAligned* 1) (SETQ pp_xmodsim (- simspace) pp_xmod (- modspace)))
        ((= *BarAligned* 2) (SETQ pp_ymodsim simspace pp_ymod modspace))
        ((= *BarAligned* 3) (SETQ pp_ymodsim (- simspace) pp_ymod (- modspace))) ;Used for WJC
      ))
    (*ToolCenterbase*
      (QUIT (ALERT "Only 3 jets are currently avaiable, contact IGEMS")))
    ((NOT *ToolClosestDistance*) ; All jets have the same distance even if its not used or not
      (SETQ $toollist nil)
      (REPEAT (1- *ToolQuantity*) (SETQ $toollist (CONS $tooldist $toollist)))
      (COND
        (*ToolPark* (SETQ modspace 0 simspace 0))
        ((NOT *CoordinateToFirstTool*) ; Coordinate to first used tool
          (SETQ modspace 0)
          (SETQ simspace (* (1- (GETLOWESTTOOL $tools)) $tooldist)))
        (T     ; Always coordinate to Tool 1 even if it is not used.
          (SETQ modspace (* (1- (GETLOWESTTOOL $tools)) $tooldist))
          ;(ALERT (STRCAT "MODSPACE:" (TOSTR modspace) " *BarAligned*:" (TOSTR *BarAligned*)))
          (SETQ simspace modspace))
      )
      (COND ; Detta kopierat från 2022
        ((= *BarAligned* 0) (SETQ pp_xmodsim simspace pp_xmod modspace))
        ((= *BarAligned* 1) (SETQ pp_xmodsim (- simspace) pp_xmod (- modspace)))
        ((= *BarAligned* 2) (SETQ pp_ymodsim simspace pp_ymod modspace))
        ((= *BarAligned* 3) (SETQ pp_ymodsim (- simspace) pp_ymod (- modspace)))
      ))
    (*ToolClosestDistance* ; Pack unused tools as close as possible
      (SETQ $toollist nil)
      (SETQ lownr (GETLOWESTTOOL $tools))
      (SETQ highnr (GETHIGHESTTOOL $tools))
      (SETQ tnr 2)
      (REPEAT (1- *ToolQuantity*)
        (COND
          ((<= tnr lownr)  (SETQ $toollist (CONS *ToolMinDistance* $toollist)))
          ((> tnr highnr) (SETQ $toollist (CONS *ToolMinDistance* $toollist)))
          (T              (SETQ $toollist (CONS tooldist $toollist)))
        )
        (SETQ tnr (1+ tnr))
      )
      (SETQ $toollist (REVERSE $toollist))
      (IF (NOT (EQUAL pp_oldtoollist $toollist 0.05)) (SETQ $tooldistunchanged nil))
      (COND
        ((NOT *CoordinateToFirstTool*) ; Coordinate to first used tool
          (SETQ modspace 0) ;OK
          (SETQ simspace (* (1- (GETLOWESTTOOL $tools)) *ToolMinDistance*)))
        (T ; Always coordinate to Tool 1 even if it is not used.

          (SETQ modspace (* (1- (GETLOWESTTOOL $tools)) *ToolMinDistance*))
          (SETQ simspace modspace))
      )
      (COND ; Detta kopierat från 2022
        ((= *BarAligned* 0) (SETQ pp_xmodsim simspace pp_xmod modspace))
        ((= *BarAligned* 1) (SETQ pp_xmodsim (- simspace) pp_xmod (- modspace)))
        ((= *BarAligned* 2) (SETQ pp_ymodsim simspace pp_ymod modspace))
        ((= *BarAligned* 3) (SETQ pp_ymodsim (- simspace) pp_ymod (- modspace)))
      )
    )
  )
  (SETQ $msg "" $msgactive "" $msgdist "")
  
  ;Generate string to $msgactive
  (SETQ tool-num 1)
  (SETQ bit-value 1)
  (REPEAT 8
    (IF (> (LOGAND tools bit-value) 0)
      (IF (NOT activemsg)
        (SETQ activemsg (STRCAT "Tool:" (ITOA tool-num))) ;first 
        (SETQ activemsg (STRCAT activemsg "+" (ITOA tool-num)))
      )
    )
    (SETQ bit-value (* bit-value 2))
    (SETQ tool-num (1+ tool-num))
  )
  (SETQ $msgactive activemsg)   
  
  
  ;generate string to $msgdist
  (SETQ distmsg "I")
  (FOREACH tol $toollist (SETQ distmsg (STRCAT distmsg "-" (TOSTR tol) "-I")))
  (SETQ $msgdist distmsg)
  
  
  (SETQ $feed *ToolMovingSpeed*)
  (SETQ allpos (CADR (ASSOC idx pp_toolcords)))
  (IF pp_toolreset (SETQ allpos pp_oldpos)) ; Added 23/3-26 by BJ
  (DEFAXIS allpos pp_oldrot) ; sets X Y of first position
  (IF (> *ToolQuantity* 0)
    (PROGN
      (SSIM-TOOLSET $tools $toollist *ToolMovingSpeed*) ; will change the tooldistance and active tools only
      ;(SETQ allpos (CADR (ASSOC idx pp_toolcords)))
      (DEFAXIS allpos pp_oldrot) ; sets X Y of first position
      (SETQ pp_oldpos allpos)
      (IF (NOT skip) (CHTOOL)))
  )
  (IF info (WRITE "END $TOOLSET"))
  (IF (AND *3D-5X* pp_firstrapid)  (EVAL pp_firstrapid) (SETQ pp_firstrapid nil))
  (SETQ pp_oldtoollist $toollist)
  (SETQ pp_tptoolsetlist (LIST $tools $toollist))

 )

(DEFUN chtool ()
  ($STOP 0 nil "TOOLSET")
)
(DEFUN point2D (pt) (LIST (CAR pt) (CADR pt)))

(DEFUN $rapid (allpos $attrib $reason allrot tilted flag / pp_z info savepos z vlist diff res test debug tid crapid)

	; ($RAPID '(-34.608805 0.961018 100) "StartRapid" 2 '(0 0 0) nil nil)
  ;(IF (NOT $mode) (SETQ $mode 4))
  (IF (AND pp_firstrapid *3d-5x*) (SETQ allpos (LIST (CAR allpos) (CADR allpos) pp_maxz) $reason -1))
  (SETQ pp_lastrapid (LIST allpos $attrib $reason allrot tilted flag)) ;
  (SETQ debug nil)
  (IF pp_noZonrapid (SETQ $reason 0)) ; Before first Z when using Sensor we should skip Z cordinates in 3D-5X. The pp_noZonrapid will be nil in $tooldown, $tooldown3d
  (IF (AND (NOT $mode) (= *ZBase* 2) (NOT pp_rapidz)) (SETQ pp_rapidz (CADDR allpos))) ;JB
  (IF (NOT pp_rapidz) (SETQ pp_rapidz $zmaxup))
  (IF (NOT flag) (SETQ $speedramp T))
  (IF flag (SETQ $speedramp (IF (> (LOGAND flag 128) 0) nil T)))
  (IF flag (SETQ crapid (IF (> (LOGAND flag 256) 1) T nil)))  ;this is used to see if there is a custom vector added in 3d5x.
  (IF debug (WRITE (STRCAT "$singularity: "(TOSTR $singularity) " TILTED:" (TOSTR tilted))))
  (IF (NOT allrot) (SETQ allrot pp_oldrot)) ; allrot can be nil if the values are the same
  ;(IF (NOT (EQUAL (CADR allrot) 0 0.001)) (SETQ tilted T))
  (COND
    ((AND (= $mode 7) *ProbeTilted*) ; Sensoring
      ;(PRINC (STRCAT "MEASUREPOINTVECTORS:" (TOSTR pp_measurepointvectors) "\n"))
      (SETQ pp_vec (CAR pp_measurepointvectors))
      (IF pp_nextnoabmove
        (SETQ allrot pp_oldrot)
        (PROGN
          (SETQ allrot (VECTOAB (LIST (- (CAR pp_vec)) (- (CADR pp_vec)) (- (CADDR pp_vec)))))
          (SETQ aa (TRANSAB *SensorOffset* (CAR allrot) (CADR allrot)))
          (SETQ allrot (LIST (CAR allrot) (CADR allrot) 0))
          ;(PRINC (STRCAT "ALLROT IN RAPID:" (TOSTR allrot) "\n"))
          (SETQ allpos (LIST (+ (CAR allpos) (CAR aa)) (+ (CADR allpos) (CADR aa)) (+ (CADDR allpos) (CADDR aa))))))
      (SETQ pp_nextnoabmove nil))
    (tilted
      (DEFAXIS allpos allrot))

    ((AND (= $mode 8) *ProbeTilted*)
      (SETQ aa (TRANSAB *Sensoroffset* (CAR allrot) (CADR allrot)))
      (SETQ allpos (LIST (+ (CAR allpos) (CAR aa)) (+ (CADR allpos) (CADR aa)) (+ (CADDR allpos) (CADDR aa))))
      (SETQ pp_nextnoabmove nil)
      (DEFAXIS allpos allrot)
      (SETQ $z (DEFZ (CADDR allpos)))
      (SSIM-RAPID allpos *SpeedRapid* *SpeedAcceleration* allrot)
      (RAPID)
      (SETQ tid (MAX (/ (ABS $arel) *HeadPrimaryMaxSpeed*) (/ (ABS $brel) *HeadSecondaryMaxSpeed*)))
      (SIM3D-TILT (- (CAR allrot)) (- (CADR allrot)) $arel $brel)
      ($TILT $a $b 1)
      (SIM-INFOTEXT ""))
    (crapid
      (SETQ allrot (SETQ allrot (LIST (CAR allrot) (CADR allrot) (CADDR allrot)))))
    ;((AND $singularity (NOT tilted) crapid); if custom rapid vectors are added in 3D5x, not forcing singulaity head straight.
     ; (IF debug (WRITE (STRCAT "D1***********************")))
     ; (SETQ allrot (SETQ allrot (LIST (CAR allrot) (CADR allrot) (CADDR allrot)))))
    ((AND $singularity (NOT tilted)); (NOT tilted)) ; Tops45
      (SETQ allrot (SETQ allrot (LIST (CAR allrot) 0.0 (CADDR allrot)))))

    ((AND (NOT $singularity) (NOT tilted)) ; If Flow XD, APEX 60.  We may windup also on not singularity
      (SETQ vlist '(37.69911 31.41593 25.13274 18.84956 12.56637 6.28319 0.0 -6.28319 -12.56637 -18.84956 -25.13274 -31.41593 -37.69911))
      (SETQ diff 50)
      (FOREACH s vlist (IF (< (SETQ test (ABS (- (CAR allrot) s))) diff) (SETQ res s diff test)))
      (SETQ allrot (LIST res 0.0 (CADDR allrot))))
    (T (ALERT "Uppsamlingsheat"))
  )
  (IF (= $mode 7) (SETQ $reason 4))
    ; $reason values: 0=Noraml rapid, 1=Rapid in a 2D-part, 2=Extra rapids in Order, 3=Rapid to a senoring position, 4=From 3D-5X
    ; This function moves the jet in rapid speed and moves it down to piercing position using $TOOLDOWN or $TOOLDOWN3D
    ; $MODE: 0=Measure, 1=Drilling, 2=Marking, 3=Pre-piercing, 4=Cutting, 5=Inkjet, 6=Special marking
;  (IF (AND (= $reason 0) pp_extraz)  ; Move up as an extra step is not correct Z after $CHMODE at the pp_oldpos position.
  (IF (AND pp_extraz *3D-5X* nil) ; Move up as an extra step is not correct Z after $CHMODE at the pp_oldpos position. ********************************************** ACTION REQUIRED

    (PROGN
      (SETQ extrapos (ZREPLACE pp_oldpos pp_extraz))
      (SSIM-RAPID extrapos *SpeedRapid* *SpeedAcceleration* allrot)
      (SETQ $z (DEFZ pp_extraz))
      (DEFAXIS extrapos pp_oldrot)
      (IF $attrib (SRAPID) (RAPID))
      (SETQ pp_oldpos extrapos)))
  (IF (= $reason 0) (SETQ allpos (ZREPLACE allpos pp_rapidz))) ; Reason 0 is on all 2D cutting
  (COND
  ;((AND (= $reason 0) *ConvertLead*) nil)
    ((MEMBER $reason (LIST -1 0 1 2)) ; $reason 0=From strategy, 1=Extra rapid in 2D, 3 Sensoring, 4=Use this Z, its from 3D-5X, 5=Same as 0 but the Z-value should be used.
      (IF debug (WRITE (STRCAT "Detta är 1 allpos:" (TOSTR allpos) " rapidz:" (TOSTR pp_rapidz))))
      (SSIM-RAPID allpos *SpeedRapid* *SpeedAcceleration* allrot)
      (SETQ $z (DEFZ pp_rapidz))
      (DEFAXIS allpos allrot)
      (IF (= $reason 5) (SETQ $reason 0))
      (IF $attrib ($SRAPID) (RAPID)))
      ;(RAPID))
    ((= $reason 3) ; Rapid to sensoring position
      (SSIM-RAPID allpos *SpeedRapid* *SpeedAcceleration* allrot)
      (SETQ $z (DEFZ pp_rapidz))
      (DEFAXIS allpos allrot)
      (RAPID))
    ((= $mode 8)
       nil)
    ((= $reason 4) ; This is a rapid generated in 3D-5X
      (DEFAXIS allpos allrot)
      (SETQ $ab (LIST $a $b))
      (SETQ $z (DEFZ (CADDR allpos)))
      (SSIM-RAPID allpos *SpeedRapid* *SpeedAcceleration* allrot)
      (IF $attrib (SRAPID) (RAPID)))
    (T (ALERT "Uppsamlingheat"))  
  )
  (IF (AND $mode (NOT (EQUAL allrot pp_oldrot 0.000005))) ; Added (AND $mode to avoid a tilt if no mode is selected.
    (PROGN
      (IF (= $reason 3)
        (PROGN
          (SETQ allrot (LIST 0.0 0.0 0.0))))
      ;    (DEFAXIS allpos allrot)))
      (DEFAXIS allpos allrot)
      (SETQ $ab (LIST $a $b))
      (SETQ tid (MAX (/ (ABS $arel) *HeadPrimaryMaxSpeed*) (/ (ABS $brel) *HeadSecondaryMaxSpeed*)))
      (SIM3D-TILT (- (CAR allrot)) (- (CADR allrot)) $arel $brel)
      ($TILT $a $b (IF tilted 2 1))
      (SIM-INFOTEXT "")))
  (SETQ pp_oldpos allpos pp_oldrot allrot)
  (IF pp_stopdata (SETQ $reason 2))
  (IF pp_stopdata ($STOP pp_stopdata))
  (SETQ pp_stopdata nil)
  (SETQ info nil)
  (SETQ pp_firstrapid nil)
)

(DEFUN tooldown3d ()
  (IF (NOT tooldown3dmsg) (SETQ tooldown3dmsg (BEEP (ALERT "\nWARNING! Undefined function TOOLDOWN3D"))))
  (TOOLDOWN)
)

(DEFUN $srapid (/ $idx)
  (SETQ $idx pp_srapidnr)
  (SETQ pp_srapidnr (1- pp_srapidnr))
  (SRAPID)
)

(DEFUN srapid()
  (RAPID)
)

(DEFUN $stop ($reason $cond $msg)
  ;(IF (AND (= $reason 5) (= $machinetype 3)) nil (SIM-STOP $msg))
  (STOP)
)

(DEFUN ptOnvec (pt1 pt2 dist / vector factor) ; returns a 3D point with the dist from pt1 in the direction pt1 to pt2. This to make a 3D linear piercing
  (SETQ vector (LIST (- (CAR pt2) (CAR pt1)) (- (CADR pt2) (CADR pt1)) (- (CADDR pt2) (CADDR pt1))))
  (SETQ factor (/ dist (DISTANCE pt1 pt2)))
  (LIST (+ (* (CAR vector) factor) (CAR pt1)) (+ (* (CADR vector) factor) (CADR pt1)) (+ (* (CADDR vector) factor) (    pt1)))
)

(DEFUN $tooldown3d (allpos)
  (SETQ pp_noZonrapid nil)
  (DEFAXIS allpos allrot)
  (SETQ $z (DEFZ (CADDR allpos)))
  (DEFVARS)
  (SSIM-RAPID allpos *SpeedRapid* *SpeedAcceleration* allrot)
  (TOOLDOWN3D)
  (SETQ pp_oldpos allpos)
)

(DEFUN $cuton (leadend pp_side pp_ptype pp_qua pp_clen pp_geoarea pp_geolen pp_leadname pp_nodename pp_inside piercpos pp_iskerfed pp_fe pp_vec
               pp_bevelflag pp_maxslope pp_cutdirection pp_leadplan allrot pp_len attrib /
               leadlen loops tmpend ptime maxleadinspeed leadinspeed debug v $jetvalveon $jetabrasiveon piercvec cutvec tmpadd)
 (IF (AND *ConvertLead* (= pp_ptype 0))
    (PROGN
      (SETQ leadrot (ANGLE piercpos leadend))
      (IF (OR (= pp_side 0) (= *InternalToolCompensation* 0))
        (SETQ tmpp leadend)
        (SETQ tmpp (POLAR leadend (IF (= pp_side 1) (+ leadrot 2.0492) (+ leadrot -2.0492)) (* *MaxToolDiameter* 0.5 )))
      )
      ($RAPID (LIST (CAR tmpp) (CADR tmpp) (CADDR (CAR pp_lastrapid))) (NTH 1 pp_lastrapid) (NTH 2 pp_lastrapid) allrot (NTH 4 pp_lastrapid) (NTH 5 pp_lastrapid))
      (SETQ piercpos (LIST (CAR tmpp) (CADR tmpp) (CADDR leadend)))
    )
  )
  (SETQ $jetabrasiveon *AWJCuttingArrive*)  ;JB
  (SETQ pp_extraz nil)
  (SETQ piercvec (IF (> (LOGAND pp_bevelflag 1) 0) pp_vec (LIST 0 0 (CADDR pp_vec)))) ; Use this vector for the piercing. Use also pp_oldrot for the piercing it self
  (SETQ cutvec pp_vec)
  (SETQ debug nil)
  (IF (= *Zsensoringmode* 6) (GETPROBEINT))
  (SETQ $clen pp_clen)
  (SETQ $attrib attrib)
  (SETQ $leadname pp_leadname)
  (SETQ pp_kerfside pp_side) ; kerfside is never changed of any reason. $side can be used in the future
  (SETQ $side pp_kerfside)
  (SETQ $edge pp_inside)
  (SETQ pp_flipwindup (IF (= pp_flipwindup 1) T nil))
  (SETQ $leadtilt (IF (EQUAL pp_leadplan (LIST 0 0 -1) 0.001) nil T))
  (SETQ $leadplan pp_leadplan)
  (SETQ $starttan pp_cutdirection)
  (IF (= *MachineType* 0) (SETQ $useabr T))
  (COND
    ((MEMBER pp_ptype (LIST 2 3)) ($CHBARGRAM 3))
    (T ($CHBARGRAM 4))
  )
  (IF (NOT pp_bevelflag) (SETQ pp_bevelflag 0)) ; 1=Tilted piercing, 2=Bevel 16=3D-5X cut, 64=Tacflag 256= last cutting on part.
  (IF (AND (= (LOGAND pp_bevelflag 2) 0) *3D-5X* (NOT (EQUAL (CADDR leadend) *3D-MaxZ* 0.01)) (NOT pp_mix2d3d))
    (SETQ pp_mix2d3d (ALERTHELP "WARNING! 3D and 2D thickness is mismatch" "mix2d3d")))
  (SETQ pp_3d5x (IF (> (LOGAND pp_bevelflag 16) 0) T nil))
  (IF (> (LOGAND pp_bevelflag 128) 0) (SETQ pp_bevelflag (- pp_bevelflag 128) $speedramp nil) (SETQ $speedramp T)) ; If 128 then speedramp nil
  (SETQ pp_fs pp_fe)
  ;(SETQ pp_park (IF (MEMBER pp_bevelflag (LIST 1 2 64)) nil T))
  ;(SETQ pp_park (IF (OR (> (LOGAND pp_bevelflag 1) 0) (> (LOGAND pp_bevelflag 2) 0) (> (LOGAND pp_bevelflag 16) 0)) T nil))
  ;(WRITE (STRCAT "PP_BEVELFLAG:" (TOSTR pp_bevelflag) " PP_PARK: " (TOSTR pp_park)))
  ; Handling if next piercing should be in low pressure
  (SETQ $startindex (1+ $startindex))
  ;(SETQ $lastcutonpart (IF (MEMBER $startindex pp_partmax) T nil))
  (SETQ $lastcutonpart (IF (> (LOGAND pp_bevelflag 256) 0) T nil))
  (SETQ $lowatoff (NTH $startindex pp_lowhighlist)) ; pp_piercindex starts at 1
  (IF (AND (= $startmax $startindex) *SerialProduction* (CAR pp_lowhighlist))  ;If the first cutting is in low pressure, then we should end in low pressure
    (PROGN
      (SETQ $lowatoff T)
      (IF (NOT *AWJBleedOut*) (SETQ $release T)))) ; Release pressure if it's the last cut and cut shoul start in low pressure. $release is local in $cutoff
  ; pp_bevelflag: Bit value. 1= Tilted piercing, 2=5X-cutting, 64=TAC (other values will be removed)
  (IF (> (LOGAND pp_bevelflag 2) 0) (SETQ pp_side 0))
  (IF (AND (> *Speedmode* 1) (<= (RADTODEG pp_maxslope) *HeadMinTilt*)) (SETQ pp_bevelflag 0))
  (SETQ tacflag (IF (> (LOGAND pp_bevelflag 64) 0) T nil))
  (IF (NOT *MasterTac*) (SETQ tacflag nil))
  (SETQ *TAC* tacflag)
  (SETQ $ab (IF (OR (> (LOGAND pp_bevelflag 2) 0) (AND *TAC* (> *Speedmode* 1))) T nil)) ; Generate no AB if TAC are used in fixed speed
  (SETQ $path5x (IF (OR *TAC* (> (LOGAND pp_bevelflag 2) 0)) T nil)) ; T if 5-axis kinematic will be used on actual geometry
  (IF (NOT *Has5XKinematics*) (SETQ $ab nil))
  (SETQ $maxslope (IF pp_maxslope (RADTODEG pp_maxslope) 0))
  (SETQ pp_dobevel (IF (> (LOGAND pp_bevelflag 2) 0) T nil))
  (SETQ $usetac (IF pp_dobevel nil (OR *TAC* *LAG*))) ; is only T on 2D geometry with TAC
  (SETQ $usebevel pp_dobevel)
  (SETQ $usebeveltac (IF (AND (OR *TAC* *LAG*) $usebevel) T nil))
  (IF (OR $usebevel $usebeveltac $usetac) (SETQ $ctype 2) (SETQ $ctype 0))
  (IF (> (LOGAND pp_bevelflag 1) 0) (SETQ $ctype (1+ $ctype)))
  (SETQ $nodename pp_nodename)
  ;(IF (AND *PiercingAlways* (> pp_bevelflag 0))
  ;  (PROGN
  ;    (SETQ $x *ServicePosX* $y *ServicePosY* $reason 1)
  ;    (MRAPID)
  ;    (SETQ $reason 5)
  ;    ($STOP 5 nil "Service position before 5X-cutting")
  ;    (SETQ *PiercingAlways* nil))
  ;)
  (IF pp_partstopdata (PROGN (SETQ $reason 1) ($STOP pp_partstopdata)))
  (SETQ pp_partstopdata nil)
  (SETQ $initqua T)
  ($QUALITY pp_qua) ; ZOK
  (SETQ pp_ab nil)
  (SETQ $ptype pp_ptype)
  ;(SETQ $a 0.0 $b 0.0)
  (SETQ $external (MINUSP pp_inside))
  ;Calculate increased piercing height
  (SETQ startpos piercpos) ; Startpos är alltid utan IPD (Increased Piercing Distance)
  (SETQ $ipd 0)
  (IF (AND *ZPiercingUse* (> pp_ptype 0) (NOT (= pp_ptype 5))) ; If not blind lead or airstart
    (PROGN
      (SETQ $ipd *ZPiercingDist*)
      (SETQ v (NORMALIZE pp_vec))
      (SETQ v (LIST (* (CAR v) *ZPiercingDist*) (* (CADR v) *ZPiercingDist*) (* (CADDR v) *ZPiercingDist*)))
      (SETQ piercpos (SUBPOINTS piercpos v))
      ($RAPID (LIST (CAR piercpos) (CADR piercpos) (CADDR (CAR pp_lastrapid))) (NTH 1 pp_lastrapid) (NTH 2 pp_lastrapid) allrot (NTH 4 pp_lastrapid) (NTH 5 pp_lastrapid))
    )
  )
  (IF (> (DISTANCE (LIST (CAR pp_oldpos) (CADR pp_oldpos)) piercpos) 0.01) ; If the piercing position is not vertical to actual position.
    ($TOOLDOWN3D piercpos)
    ($TOOLDOWN piercpos 5) ; Reason 1=Init, 2 Between Drillings, 3 Markings, 4 Prepiercings 5 Cuts in part, 6 Between parts,7 Cleaning or Pressure reduce.
  )
  ;(SETQ pp_oldrot allrot)
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
  (IF (<= pp_fe 0) (SETQ pp_fe *SpeedMinCutting*))
  (SIM-ON T pp_fe)
  (SETQ pp_fs pp_fe)
  (SETQ pp_cleft pp_clen)
  (SETQ pp_flag 1)
  (SETQ pp_direction (ANGLE piercpos leadend))
  (COND
    ((AND (= pp_ptype 4) (NOT pp_makeprepiercing) (NOT *DrillingTools*))
      (SETQ pp_ptype 3))               ; If no drillingtool than change to Circular
    ((AND (= pp_ptype 4) (< *DrillByType* 3)) (SETQ pp_ptype 5)) ; If drilling than change to Airstart
  )
  (IF (AND pp_makeprepiercing (OR (= pp_ptype 2) (= pp_ptype 3))) (SETQ pp_ptype 5)) ; If Prepiercing and stat or cirk piercing then airstart
  (SETQ leadlen pp_len)
  (IF (= *InternalToolCompensation* 0) (SETQ pp_side 0)) ; If kerf handled by IGEMS
  (IF pp_iskerfed (SETQ pp_side 0)) ; Temporary solution if TVL is used
  (SETQ $high (IF (= $bar $highbar) T nil))
  (COND
    ((AND *ConvertLead* (= pp_ptype 0))
      (SETQ $ptype 5)
      (SETQ $kerf pp_side)
      (SETQ $chkerf (IF (> $kerf 0) T nil))
      (SETQ $ptype 5)
      ($PIERCING leadend allrot 0 nil)
      (IF (> (DISTANCE piercpos leadend ) 0.01) ($LINE leadend 1 600 600 0 pp_vec allrot pp_len)))
    ((= pp_ptype 0) ; Blind lead
      (SETQ $ptype 0)
      (SETQ $kerf pp_side)
      (SETQ $chkerf (IF (> $kerf 0) T nil))
      (SETQ pp_isleadin T)
      (IF (> (DISTANCE piercpos leadend) 0.01) ($LINE leadend 1 600 600 0 pp_vec allrot pp_len)) ;*****NOTE! Calculate the correct len
      (SETQ pp_isleadin nil)
      ($PIERCING leadend allrot 0 nil)) ;ZOK
    ((= pp_ptype 1) ; Linear piercing
      (SETQ leadinspeed (CALCAWJFEED 5 (DISTANCE (LIST 0.0 0.0 0.0) pp_vec))) ; Speed for 12% long leadin
      (SETQ maxleadinspeed (CALCAWJFEED 2 (DISTANCE (LIST 0.0 0.0 0.0) pp_vec))) ; Max speed for actual material. Changed this to rough speed (from X-rough) depending on problem when cutting plastic
      (SETQ needlen (* (DISTANCE (LIST 0.0 0.0 0.0) pp_vec) 0.15)) ; needed lenght
      (IF (< needlen (* *ToolDiameter* 2)) (SETQ needlen (* *ToolDiameter* 2)))  ;Update to not run to fast if linear lead length is long "enough"
      (SETQ movelen (IF (= *InternalToolCompensation* 0) pp_len (- pp_len (* *ToolDiameter* 0.5)))) ; geometrical lenght of the leadin
      (SETQ leadspeed (* leadinspeed (/ movelen needlen))) ; modified leadin speed
      (COND
        ((<= *SpeedMode* 1) (SETQ leadspeed pp_fe)) ; if it's fix speed
        ((< leadspeed *SpeedMinCutting*) (SETQ leadspeed *SpeedMinCutting*)) ; check that speed is not to low
        ((> leadspeed maxleadinspeed) (SETQ leadspeed maxleadinspeed)) ; check that the speed is not to high
      )
      (IF (NOT *AWJDLPSpeed*) (SETQ leadspeed leadinspeed)) ; ************* TO SUPPORT WJS ***
      (SETQ $chkerf (IF (> $kerf 0) T nil) $kerf pp_side)
      ($PIERCING piercpos allrot 0 nil)
      ($LINE3D startpos allrot)
      (SETQ pp_fsuse leadspeed)
      ($LINE leadend 1 leadspeed leadspeed 0 pp_vec allrot pp_len)
      (SETQ pp_fsuse leadspeed))
    ((= pp_ptype 2) ;Stationary piercing
      (COND
        ((= *MachineType* 0) (SETQ ptime *AWJStationaryPiercing*))
        ((= *MachineType* 1) (SETQ ptime *WaterPiercingTime*))
        ((= *MachineType* 2) (SETQ ptime *PlasmaPiercingTime*))
        ((= *MachineType* 3) (SETQ ptime *OxyfuelPiercingTime*))
        ((= *Machinetype* 4) (SETQ ptime *LaserPiercingTime*))
      )
      (SETQ $kerf pp_side)
      (SETQ pp_vec piercvec)
      ($PIERCING piercpos pp_oldrot ptime nil) ;ZOK
      ($CHBARGRAM 4)
      (SETQ pp_vec cutvec)
      ($LINE3D startpos allrot)
      (SETQ $chkerf (IF (> $kerf 0) T nil))
      (SETQ pp_isleadin T)
      ($LINE leadend 1 pp_fs pp_fe 0 pp_vec allrot pp_len) ;ZOK
      (SETQ pp_isleadin nil))
    ((= pp_ptype 3) ; Circular piercing
      (SETQ $kerf pp_side)
      (SETQ $chkerf nil)
      (SETQ pp_absave pp_ab)
      (SETQ pp_ab nil)
      (SETQ pp_vec piercvec)
      ($PIERCING piercpos pp_oldrot *AWJCircularPiercing* T) ;ZOK
      ($CHBARGRAM 4)
      (SETQ pp_vec cutvec)
      ($LINE3D startpos pp_oldrot)
      (SETQ pp_ab pp_absave)
      (SETQ $chkerf (IF (> $kerf 0) T nil))
      (SETQ pp_isleadin T)
      ($LINE leadend 1 pp_fs pp_fe 0 pp_vec allrot pp_len) ;ZOK
      (SETQ pp_isleadin nil))
    ((= pp_ptype 5) ; Airstart
      ;(IF (AND (= *MachineType* 0) (> *SpeedMode* 1) (> pp_fe ppleadinspeed)) (SETQ pp_fs pp_leadinspeed pp_fe pp_leadinspeed)) ; Changed December 2014 to be same as airstart modified in 2020.2 to get local thickness
      (SETQ $kerf pp_side)
      (SETQ pp_vec piercvec)
      ($PIERCING piercpos allrot 0 nil) ;ZOK
      (SETQ pp_vec cutvec)
      (SETQ $chkerf (IF (> $kerf 0) T nil))
      (SETQ pp_isleadin T)
      ($LINE leadend 1 pp_fs pp_fe 0 pp_vec allrot pp_len) ;ZOK
      (SETQ pp_isleadin nil))
    ((= pp_ptype 6) ; User defined
      (SETQ $kerf pp_side)
      ($PIERCING piercpos allrot 0 nil) ;ZOK
      (SETQ $chkerf (IF (> $kerf 0) T nil))
      (SETQ pp_isleadin T)
      ($LINE leadend 1 pp_fs pp_fe 0 pp_vec allrot pp_len) ;ZOK
      (SETQ pp_isleadin nil))
    (T (PRINC "\n******  Unknownd piercing type ******\n"))
  )
  (IF $angleIpo (SIM-IAIP T))
  (IF (AND (> pp_side 0) (OR (= *InternalToolCompensation* 2) (= *InternalToolCompensation* 1)) *AddExtraMovement*) (SETQ $leadout T) (SETQ $leadout nil))
  (IF $ab (SETQ pp_headistilt T))
  (SETQ $chkerf nil $initqua nil)
)



(DEFUN $tilt ($a $b $reason / $ab)
  (IF (/= *HeadKinematicName* "")
    (PROGN
      (SETQ $ab T)
      (TILT))
    (SETQ $ab nil)
  )
)

(DEFUN $quality (quarg)
  (SETQ $chqua (NOT $initqua))
  (SETQ $qua (1+ quarg))
  (COND
    ((> *MachineType* 0) (SETQ $f 0))
    ((= $qua 1) (SETQ $f $xrough))
    ((= $qua 2) (SETQ $f $rough))
    ((= $qua 3) (SETQ $f $medium))
    ((= $qua 4) (SETQ $f $fine))
    ((= $qua 5) (SETQ $f $xfine))
  )
  (IF (= *Machinetype* 1) (SETQ *WaterSpeedFactor* (NTH (1- $qua) *WaterSpeedQuality*)))
  (QUALITY)
)

(DEFUN quality () nil)

(DEFUN $toolup3d (allpos)
  (DEFAXIS allpos pp_oldrot)
  (SETQ $z (DEFZ (CADDR allpos)))
  (SSIM-RAPID allpos *SpeedRapid* *SpeedAcceleration* pp_oldrot)
  (SIM-INFOTEXT "")
  (TOOLUP3D)
  (SETQ pp_oldpos allpos)
  (SETQ $ipd 0)
)

(DEFUN $flyctrl ($reason)
  (COND
    ((= $reason 3) ; Abrasive off
      (FLYCTRL)
      (SETQ pp_skipabrasiveoff T))
    ((AND (= $reason 4) pp_skipabrasiveoff) ; Turn only off water if abrasive is turned off
      (FLYCTRL)
      (SETQ pp_skipwateroff T))
  )
)

(DEFUN $cutoff (typ allpos / pt skiptoolup debug $JetAbrasiveOff $JetValveOff $release)
  (SETQ debug nil)
  (SETQ $last nil $delay 0)
  (IF (OR (= *MachineType* 1) pp_skipabrasiveoff) (SETQ $JetAbrasiveOff nil))
  (IF pp_skipwateroff (SETQ $JetValveoff nil))
  (IF (AND $lowatoff (NOT *AWJBleedOut*) (EQUAL $bar $highbar 100)) 
    (PROGN
      (SETQ $release T)
      (SETQ $delay *AWJDelayPressureDown*)))
  ;About pp_zmode: 3= by Z-cordinate, 6= Sensor by Z-cordinate, 7=Measuring in advance
  (IF (AND (= typ 2) (NOT (MEMBER pp_zmode (LIST 3 6 7))))
    (PROGN
      (CLS)
      (QUIT (ALERT "Tilted rapids only possible in programmable Z-axis"))))
  (SIM-OFF)

  ; Turn off Jet
  (COND
    ((= *MachineType* 0)  ;AWJ cutting
      (SETQ $time *AWJDelayAfterCutting*)
      (SETQ $marking nil))
    ((= *MachineType* 1) ; Pure Water
      (SETQ $time *WaterDelayAfterCutting*))
    (T
      (SETQ $delay 0 $time 0))
  )
  ; Cancel tool compensation
  (COND
    ((= $kerf 0)
      (SETQ $chkerf nil)
      (CUTOFF))
    ((AND $leadout pp_unkerf)
      (SETQ $chkerf nil)
      (CUTOFF)
      (SETQ $chkerf T $kerf 0 $side 0)
      (SETQ pp_unkerf (ZREPLACE pp_unkerf (CADDR pp_oldpos)))
      ($LINE pp_unkerf 32 600 600 0 $vector pp_oldrot (* *ToolDiameter* 2.0)) ;*****NOTE! Calculate the correct len
      (SETQ allpos (LIST 0 0 0))
      (SETQ pp_oldpos (ZREPLACE pp_unkerf (CADDR pp_oldpos))))
    (T
      (SETQ $chkerf T $kerf 0)
      (CUTOFF))
  )
  (SETQ $leadout nil $chkerf nil)
  ;(ALERT "Klart hit")
  ; turn off FLIN
  (IF pp_flinactive
    (PROGN
      (SETQ $flin 0)
      (FMODE)
      (SETQ pp_flinactive nil $flin nil)))
  ; Lift the tool
  (COND
    ((= typ 1) ($TOOLUP (CADDR allpos) 6 "UP 3D-5X"))
    ((= typ 2) ($TOOLUP3D allpos))
    ($lastcutonpart ($TOOLUP (+ $partupz pp_zclear) 6 "UP BETWEEN PARTS"))
    (T
      ($TOOLUP (+ $cuttingupz pp_zclear) 5 "UP BETWEEN CUTS"))
  )
  ;$markupz, $piercupz, $cuttingupz, $partupz,$maxupz
  ; Stops

  (IF (AND *StopAfterFirstPart* (= $edge -1))
    (PROGN
      (SETQ *StopAfterFirstPart* nil *StopAfterFirstCut* nil)
      ($STOP 4 nil "Stop after first part")))
  (IF *StopAfterFirstCut*
    (PROGN
      (SETQ *StopAfterFirstCut* nil)
      ($STOP 3 nil "Stop after first cut")))
  (IF (AND $ab *HeadStraight*)
    (PROGN
      (SETQ tid (MAX (/ (ABS $a) *HeadPrimaryMaxSpeed*) (/ (ABS $b) *HeadSecondaryMaxSpeed*)))
      ($TILT 0 0 4)
      (SIM3D-TILT 0 0 $a $b)))
  (SIM-IAIP nil)
  (SETQ $usetac nil $usebevel nil $usebeveltac nil)
  ;(SETQ pp_oldpos pp_allpos)
  (SETQ $path5x nil)
  (SETQ $lascutonpart nil)
  (IF debug (WRITE "$CUTOFF ENDS"))
  (SETQ pp_skipabrasiveoff nil pp_skipwateroff nil)
  (IF pp_tptoolset (SETQ pp_toolreset T))
)

(DEFUN cutoff()
  (SETQ a a)
)

; The function will activate FLIN at the first movement where the start and endfeed is different.
; The pp_flinactive variable must be set to nil at the cutoff function.
(DEFUN $fmode (fstart fend)
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

(DEFUN $itext (allpos $txtlist $angle $length $height $font $fonttype / savepos $txt)
  (SETQ $txt (CAR $txtlist))
  (SSIM-RAPID (ZREPLACE allpos $markupz) *SpeedRapid* *SpeedAcceleration* (LIST 0 0 0))
  (SETQ savepos allpos)
  ;(IF (NOT *InkjetOffsetByController*) (SETQ allpos (LIST (+ (CAR allpos) *InkjetXOffset*) (+ (CADR allpos) *InkjetYOffset*) (CADDR allpos)))) ;removed because it already handled in $chmode JB
  (DEFAXIS allpos pp_oldrot)
  (SETQ $z (DEFZ (CADDR allpos)))
  (SETQ $fe *InkjetSpeed* $f *InkjetSpeed*)
  (ITEXT)
  (SETQ pp_oldpos savepos)
)


(DEFUN $text (allpos $txt $angle $length $height $attrib $font $fonttype $special)
  (DEFAXIS allpos pp_oldrot)
  (COND
    ((= $mode 2) (SETQ pp_fs *MarkingSpeed* pp_fe *MarkingSpeed*))
    ((= $mode 6) (SETQ pp_fs *SpecialMarkingSpeed* pp_fe *SpecialMarkingSpeed*))
  )
  (SETQ $z (DEFZ (CADDR allpos)))
  (GETPROBEINT)
  (SETQ pp_SkipProbeChk T)
  (TEXT)
  (SETQ pp_SkipProbeChk nil)
  (SETQ pp_oldpos allpos)
)

(DEFUN text (/ tlist s isgentext)
  (SETQ isgentext T)
  (SETQ tlist (GENTEXT $txt (CAR allpos) (CADR allpos) (CADDR allpos) $angle $height $attrib $font $special)) ; Last argument is fonttype needed set this to 0 ZOK
  (FOREACH s tlist (EVAL s))
)

(DEFUN $arc (allpos pp_centp pp_ccw pp_flag pp_fs pp_fe $delta pp_vec allrot len3d
                  / pp_corda pp_radie pp_segment pp_len pp_i pp_j  pp_$di pp_$dj splits segm vecdir
                    splitv tmpang oldp pt r1 r2 newr hcorda kat LargestSegmentAngle skpsim pp_vec xmod ymod ispiercing gtype)

  (SETQ pp_fs (* pp_fs *Speedfactor*) pp_fe (* pp_fe *Speedfactor*)) ; Need this for Soitaab to reduce speed whwen using two jets (50%)
  (IF *speedoverride* (SETQ pp_fe *speedoverride* pp_fs *Speedoverride*))
   ; STEP 1 Set all variables that are needed.
  (SETQ gtype 2)
  (SETQ $vector pp_vec)
  ; flag: 1=Belongs to leadin, 2=Belongs to leadout, 4= Belongs to marking 8=To Circular piercing 64 If generated by $ccircle
  (SETQ pp_i (CAR pp_centp) pp_j (CADR pp_centp))
  (SETQ pp_di (- pp_i (CAR pp_oldpos)) pp_dj (- pp_j  (CADR pp_oldpos)))
  (SETQ $segment (SEGMENT (ANGLE pp_centp pp_oldpos) (ANGLE pp_centp allpos) pp_ccw)) ; This angle is always positive
  (SETQ $r (DISTANCE allpos pp_centp))
  (SETQ $len (* $r $segment))
  (SETQ $ccw pp_ccw) ;******************************************* Varför inte shämta detta som argument
  (IF $ccw
    (SETQ pp_midp (POLAR pp_centp (+ (ANGLE pp_centp pp_oldpos) (* $segment 0.5)) $r))
    (SETQ pp_midp (POLAR pp_centp (- (ANGLE pp_centp pp_oldpos) (* $segment 0.5)) $r))
  )
  (SETQ pp_xm (CAR pp_midp) pp_ym (CADR pp_midp))
  (IF pp_fsuse (SETQ pp_fs pp_fsuse pp_fsuse nil))
  (IF (AND (= pp_fs 0) (= pp_fe 0) (= *Machinetype* 2)) (SETQ pp_fs *PlasmaLeadinSpeed* pp_fe *PlasmaLeadinSpeed*))
  (IF (OR (= pp_fs 0) (= pp_fe 0)) (SETQ pp_fs 100 pp_fe 100))

  (IF (EQUAL pp_fe 0 0.1) (SETQ pp_fe pp_fs))
   ; STEP 2 Create Untransed points

  (SETQ $corda (DISTANCE pp_oldpos allpos))

  ; STEP 3 Create Transed points

  (SETQ $short (IF (< $segment 3.0) T nil)) ; If segment smaller that 171.88 degree then $short is T
  (SETQ pp_unkerf (POLAR allpos (+ (ANGLE pp_centp allpos) (IF pp_ccw PIH (- PIH))) (* *ToolDiameter* 2.0))) ;
  ;(IF (= pp_flag 4) (SETQ pp_vec nil)) ; If it's marking
  ;(IF (AND (NOT pp_dobevel) (NOT (OR *TAC* *LAG*))) (SETQ pp_vec nil))
  ;(IF (OR (= pp_flag 8) (= pp_flag 64)) (SETQ pp_vec nil)) ; If it's circular piercing or $ccircle
  ;(IF (NOT pp_vec) (SETQ pp_$vec (LIST 0 0 -1))) ; Note pp_vec are still nil

  (SETQ ispiercing (IF (OR (> (LOGAND pp_flag 8) 0) (> (LOGAND pp_flag 64) 0)) T nil))
  (DEFAXIS allpos allrot) ; must come before
  (SETQ $z (DEFZ (CADDR allpos)))
  (DEFVARS)
  (SETQ $ft (/ $len (* (+ $fe $fs) 0.5)))
  ($FMODE $fs $fe)
  (IF (= $nextcmd '$CUTOFF) (SETQ $last T))
  (SIM-INFOTEXT "")
  (IF (NOT pp_skipsim) (SSIM-ARC allpos pp_centp pp_ccw $fs $fe allrot))
  (IF (NOT pp_skiptxtout)
    (PROGN
      (SETQ $zrel (- (CADDR pp_oldpos) (CADDR allpos)))
      (ARC))
    (SIM-INFOTEXT ""))
  (SETQ pp_oldpos allpos) ; Save X, Y and Z as global
  (SETQ pp_oldrot allrot) ; Save rotations for A, B and C as global
  (SETQ pp_oldfeed pp_fe)
)

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
   ; This function return a parameter between 0.0 to 1.0 if the point is on the line segment,
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

(DEFUN defz (z / debug) ; This function will adjust Z-axis to correct values according to the settings.
  (SETQ debug nil)
  (COND
    ((AND *UseSixAxis* (= *ZAxisOption* 2))
      (SETQ z (- z pp_zmoved)))
    ((= *ZAxisOption* 2) ; In all cse when we use height sensor the Z-zero should be at the surface of the part,
      (IF debug (WRITE "A"))
      (SETQ z (- z *Thickness*)))
    (*3D-5X*
      (SETQ z (+ (- z pp_zmoved) *ZStandoff*)))
    ((= *ZBase* 0) ; Zero at table
      (IF debug (WRITE "D"))
      (SETQ z (+ z *ZStandoff*)))
    ((= *ZBase* 1) ; Zero at surface on 2D-parts
      (IF debug (WRITE "E"))
      (SETQ z (- z *Thickness*)))
    ((= *ZBase* 2) ; At the top
      (IF debug (WRITE "F"))
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


(DEFUN defaxis (allpos allrot / tmpx tmpy tmpi tmpj tmpf tmpxx tmpyy pp_x pp_y pp_i pp_j ab addaslope adda slope) ; Sets linear and rotation axis
  (SETQ pp_x (CAR allpos) pp_y (CADR allpos))
  (COND
    (ispiercing nil)
    ((NOT *corrangle*) nil)
    ((NOT $ab) nil)
    ((= gtype 1)
      (SETQ corrp1 (POLAR (LIST 0 0) (+ *corrangle* (CAR allrot) PI) *corrdist*)) ; calculate a point rotated by the major axis
      (SETQ corrp2 (POLAR (LIST 0 0) *corrangle* *corrdist*)) ; calculate a point that always should be added.
      (SETQ pp_x (+ pp_x (CAR corrp1) (CAR corrp2)) pp_y (+ pp_y (+ (CADR corrp1) (CADR corrp2)))))
  )
  (SETQ $xraw pp_x $yraw pp_y)
  
  (SETQ pp_x (- pp_x pp_xmod) pp_y (- pp_y pp_ymod)) ; how much the point must be moved because the equipment is offseted from the tool
  (IF pp_i (SETQ pp_i (- pp_i pp_xmod) pp_j  (- pp_j  pp_ymod))) ; must be local
  (SETQ pp_x (- pp_x pp_extrax) pp_y (- pp_y pp_extray)) ;THIS LINE IN NEW 2026-01-15 BJ
  (IF pp_i (SETQ pp_i (- pp_i pp_extrax) pp_j (- pp_j pp_extray))) ; THIS LINE IN NEW 2026-01-15  BJ  fixed 22jan JB
  

  (SETQ $x pp_x $y pp_y $i pp_i $j pp_j $ccw pp_ccw)
  (SETQ $xrel (- pp_x (CAR pp_oldpos)))
  (SETQ $yrel (- pp_y (CADR pp_oldpos)))
  (SETQ $xm pp_xm $ym pp_ym) ; To support robot syntax
  (IF pp_radie (SETQ $r pp_radie))
  (SETQ $iabs pp_i $jabs pp_j )
  (SETQ $irel pp_di $jrel pp_dj)
  (SETQ $flag pp_flag)
  (IF (NOT $flag) (SETQ $flag 0))
  (IF (NOT $len) (SETQ $len 100))
  (IF *IncrementalCircleCenter* (SETQ $i pp_di $j pp_dj))
  (SETQ xraw $xraw yraw $yraw)
  (IF (>= *Axisdirection* 4)
    (PROGN
      (SETQ tmpx $x tmpy $y tmpi $i tmpj $j)
      (SETQ $x $y $i $j)
      (SETQ $y tmpx $j tmpi)
      (SETQ $xm pp_ym $ym pp_xm)
      (SETQ tmpi $irel tmpj $jrel)
      (SETQ $irel tmpj $jrel tmpi)
      (SETQ tmpi $iabs tmpj $jabs)
      (SETQ $iabs tmpj $jabs tmpi)
      (SETQ $xraw yraw $yraw xraw)
      (SETQ tmp $yrel)
      (SETQ $yrel $xrel)
      (SETQ $xrel tmp))
  )
  (COND
    ((= *AxisDirection* 0) nil) ; No changes
    ((= *AxisDirection* 1)      ; X is mirrored
      (SETQ $ccw (IF $ccw nil T))
      (IF $x (SETQ $x (- $x)))
      (IF $i (SETQ $i (- $i)))
      (IF $xm (SETQ $xm (- $xm)))
      (IF $irel (SETQ $irel (- $irel)))
      (IF $iabs (SETQ $iabs (- $iabs)))
      (SETQ $xraw (- $xraw))
      (SETQ $xrel (- $xrel)))
    ((= *AxisDirection* 2)      ; Y is mirrored
      (SETQ $CCW (IF $CCW nil T))
      (IF $y (SETQ $y (- $Y)))
      (IF $j (SETQ $j (- $J)))
      (IF $ym (SETQ $ym (- $ym)))
      (IF $jrel (SETQ $jrel (- $jrel)))
      (IF $jabs (SETQ $jabs (- $jabs)))
      (SETQ $yraw (- $yraw))
      (SETQ $yrel (- $yrel)))
    ((= *AxisDirection* 3)      ; X and Y is mirrored
      (IF $x (SETQ $x (- $x)))
      (IF $i (SETQ $i (- $i)))
      (IF $y (SETQ $y (- $y)))
      (IF $j (SETQ $j (- $j)))
      (IF $xm (SETQ $xm (- $xm)))
      (IF $ym (SETQ $ym (- $ym)))
      (IF $irel (SETQ $irel (- $irel)))
      (IF $iabs (SETQ $iabs (- $iabs)))
      (IF $jrel (SETQ $jrel (- $jrel)))
      (IF $jabs (SETQ $jabs (- $jabs)))
      (SETQ $xraw (- $xraw))
      (SETQ $yraw (- $yraw))
      (SETQ $xrel (- $xrel))
      (SETQ $yrel (- $yrel)))
    ; All cases below are already swaped
    ((= *AxisDirection* 4)
      (SETQ $CCW (IF $CCW nil T)))
    ((= *AxisDirection* 5)     ;Y mirror
      (IF $y (SETQ $y (- $y)))
      (IF $j (SETQ $j (- $j)))
      (IF $ym (SETQ $ym (- $ym)))
      (IF $jrel (SETQ $jrel (- $jrel)))
      (IF $jabs (SETQ $jabs (- $jabs)))
      (SETQ $yraw (- $yraw)))

    ((= *AxisDirection* 6)     ;Rotated Left Hand Rule (X is mirrored)
      (IF $x (SETQ $x (- $x)))
      (IF $i (SETQ $i (- $i)))
      (IF $xm (SETQ $xm (- $xm)))
      (IF $irel (SETQ $irel (- $irel)))
      (IF $iabs (SETQ $iabs (- $iabs)))
      (SETQ $xraw (- $xraw))
      (SETQ $xrel (- $xrel)))
    ((= *AxisDirection* 7)     ;X and Y mirror
      (SETQ $CCW (IF $CCW nil T))
      (IF $x (SETQ $x (- $x)))
      (IF $i (SETQ $i (- $i)))
      (IF $y (SETQ $y (- $y)))
      (IF $j (SETQ $j (- $j)))
      (IF $xm (SETQ $xm (- $xm)))
      (IF $ym (SETQ $ym (- $ym)))
      (IF $irel (SETQ $irel (- $irel)))
      (IF $iabs (SETQ $iabs (- $iabs)))
      (IF $jrel (SETQ $jrel (- $jrel)))
      (IF $jabs (SETQ $jabs (- $jabs)))
      (SETQ $xraw (- $xraw))
      (SETQ $yraw (- $yraw))
      (SETQ $xrel (- $xrel))
      (SETQ $yrel (- $yrel)))
  )
  (IF *AxisSwapG2G3*
    (SETQ $ccw (IF pp_ccw nil T)))
  ; Rotation axis
  ; The important input to this function is allpos and allrot
  (SETQ $amotor (CAR allrot) $bmotor (CADR allrot) $cmotor (CADDR allrot))
  (COND
    ((NOT *HeadKineMatic*) ; No 5-axis head avaiable
      (SETQ $a 0.0 $b 0.0 $c 0.0))
    ((= *HeadKinematic* 0) ; By motor angles
      (SETQ $a (CAR allrot) $b (CADR allrot) $c (CADDR allrot))
      (SETQ $slope (CADR (AHEAD $bmotor))))
    ((= *HeadKinematic* 1); Direction of cut and cutting angle
      (SETQ addaslope (AHEAD $bmotor))
      (SETQ adda (CAR addaslope) $slope (CADR addaslope))
      (SETQ $c (CADDR allrot)) ;$c was missing under this condition //SG #069 Bug Report
      (COND
        ((EQUAL $slope 0.0 0.001)
          (SETQ $a $amotor $b $slope))
        ((MINUSP $bmotor)
          (SETQ $a (- $amotor adda))
          (SETQ $b (- (ABS $slope))))
       (T
          (SETQ $a (+ $amotor adda))
          (SETQ $b (ABS $slope)))
      ))
    ((= *HeadKinematic* 2) ; Direction of jet and cutting angle
      (SETQ addaslope (AHEAD $bmotor))
      (SETQ adda (CAR addaslope) $slope (CADR addaslope))
      (SETQ $a (CAR allrot) $b (CADR allrot) $c (CADDR allrot))
      ;(WRITE (STRCAT "A:" (ATS $a) " ADDA:" (ATS adda)))
      (COND
        ((EQUAL $slope 0.0 0.001)
          (SETQ $a $amotor $b $slope))
        ((MINUSP $bmotor)
          (SETQ $a (+ (- $amotor adda) PIH))
          (SETQ $b (- (ABS $slope))))
       (T
          (SETQ $a (- (+ $amotor adda) PIH))
          (SETQ $b (ABS $slope)))
      ))
  )
  (SETQ $arel (- $amotor (CAR pp_oldrot))) ; NOTE! Is the Relative angle by motor angle or some other angle?
  (SETQ $brel (- $bmotor (CADR pp_oldrot)))
  (SETQ $crel (- $c (CADDR pp_oldrot)))
  (IF *HeadPrimaryReversed* (SETQ $a (- $a) $arel (- $arel)))
  (IF *HeadSecondaryReversed* (SETQ $b (- $b) $brel (- $brel)))
  (IF *SixAxisReverseRotation* (SETQ $c (- $c) $crel (- $crel)))
)

(DEFUN defvars (/ tmpx tmpy tmpi tmpj tmpf mmpsek tmpxx tmpyy asek bsek dsek pp_xpp_y pp_i pp_j  nvec pp_fs pp_fe)
  (SETQ pp_x (CAR allpos) pp_y (CADR allpos))
  (IF (AND (NOT (= $mode 0)) pp_kdtree)
    (SETQ pp_kdtreelist (KDTREE-FINDCLOSEST pp_kdtree (LIST pp_x pp_y) (* *ZMeasureDist* 4) 3)) ;var 2
    (SETQ pp_kdtreelist nil $zreftype nil))
  (IF (AND pp_kdtreelist (NOT (= $mode 0)))
    (PROGN
      (SETQ $zrefs nil)
      (SETQ kd0 (LIST pp_x pp_y))
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
          (SETQ facts (TINTFACS kd1 kd2 kd3 (LIST pp_x pp_y)))
          (IF (OR (> (MAX (ABS (CAR facts)) (ABS (CADR facts)) (ABS (CADDR facts))) 4.0) (EQUAL facts (LIST 1.0 0.0 0.0) 0.0000001))
            (PROGN
              (SETQ facts (LINPPARAM kd1 kd2 (LIST pp_x pp_y)) intri nil $zreftype 1)
              (SETQ $zreftype 1)
              (SETQ $zrefs (LIST (CADDR kd1) (CAR facts) (CADDR kd2) (CADR facts))))
            (PROGN
              (SETQ intri (INTRIANGLE kd1 kd2 kd3 (LIST pp_x pp_y)))
              (SETQ $zreftype (IF intri 3 2))
              (IF (NOT (EQUAL (+ (CAR facts) (CADR facts) (CADDR facts)) 1.0 0.001)) (ALERT (STRCAT "FACTS:" (TOSTR facts))))
              (SETQ $zrefs (LIST (CADDR kd1) (CAR facts) (CADDR kd2) (CADR facts) (CADDR kd3) (CADDR facts))))))
        ((= (LENGTH pp_kdtreelist) 2)
          (SETQ $zreftype 1)
          (SETQ facts (LINPPARAM kd1 kd2 (LIST pp_x pp_y)))
          (SETQ $zrefs (LIST (CADDR kd1) (CAR facts) (CADDR kd2) (CADR facts))))
        ((= (LENGTH pp_kdtreelist) 1)
          (SETQ $zreftype 0)
          (SETQ $zrefs (LIST (CADDR kd1))))
      )
    )
  )
 ; (COND
 ;   (ispiercing nil)
 ;   ((NOT *corrangle*) nil)
 ;   ((NOT pp_ab) nil)
 ;   ((= gtype 1)
 ;     (SETQ corrp1 (POLAR (LIST 0 0) (+ *corrangle* (CAR pp_ab) PI) *corrdist*)) ; calculate a point rotated by the major axis
 ;     (SETQ corrp2 (POLAR (LIST 0 0) *corrangle* *corrdist*)) ; calculate a point that always should be added.
 ;     (SETQ pp_x (+ pp_x (CAR corrp1) (CAR corrp2)) pp_y (+ pp_y (+ (CADR corrp1) (CADR corrp2)))))
 ; )
  ; Handling Z-values
  (SETQ $flag pp_flag)
  (IF (NOT $flag) (SETQ $flag 0))
  ;(IF *IncrementalCircleCenter* (SETQ $i pp_di $j pp_dj))
  (SETQ $vec $vector)
  (IF (NOT $len) (ALERT "WARNING! $len is nil"))
  ; ***************** Handling all speeds **************
  ;(IF pp_fe
  ;(SETQ $ft (/ $len (* (+ pp_fe pp_fs) 0.5)))
  ;)
    (IF pp_fe                                                                      
    (PROGN                                                                         
      (SETQ pp_fe (* pp_fe *WaterSpeedFactor*) pp_fs (* pp_fs *WaterSpeedFactor*)) 
      (IF (< pp_fe *SpeedMinCutting*) (SETQ pp_fe *SpeedMinCutting*))              
      (IF (< pp_fs *SpeedMinCutting*) (SETQ pp_fe *SpeedMinCutting*))              
      (SETQ $fe pp_fe $f $fe $fs pp_fs)                                            
      (SETQ $ft (/ $len (* (+ pp_fe pp_fs) 0.5)))))                                
  (IF (= *MachineType* 2)  ; If it's Plasma cutting
    (PROGN
      (IF (NOT pp_fe) (SETQ pp_fs *PlasmaLeadinSpeed* pp_fe *PlasmaLeadinSpeed*))
      (IF pp_isleadin (SETQ tmpf *PlasmaLeadinSpeed*) (SETQ tmpf *PlasmaCuttingSpeed*))
      (SETQ pp_fs (* tmpf pp_fs 0.01))
      (SETQ pp_fe (* tmpf pp_fe 0.01))))
  (IF (> pp_fe *SpeedMaxCutting*) (SETQ pp_fe *SpeedMaxCutting*))
  (IF (> pp_fs *SpeedMaxCutting*) (SETQ pp_fs *SpeedMaxCutting*))
  (IF (< pp_fe *SpeedMinCutting*) (SETQ pp_fe *SpeedMinCutting*))
  (IF (< pp_fs *SpeedMinCutting*) (SETQ pp_fs *SpeedMinCutting*))
  (SETQ $fe pp_fe $f $fe $fs pp_fs)
  (IF (AND *Has5XKinematics* pp_bevelmarking) (SETQ $ab T))
)

(DEFUN normalize (vec / len)
  (SETQ len (DISTANCE (LIST 0 0 0) vec))
  (COND
    ((EQUAL len 1.0 0.001) vec) ; returns the vector unchanged
    ((NOT vec) (LIST 0 0 -1))
    ((< len 0.01) (QUIT (ALERT (STRCAT "VECTOR " (TOSTR vec) " CORRUPT"))))
    (T
      (LIST (/ (CAR vec) len) (/ (CADR vec) len) (/ (CADDR vec) len)))
  )
)

;CMESH-INIT
;CMESH-GET

(DEFUN ntxt()
  (IF *UseLineNumbers*
    (PROGN
      (SETQ $ncount *Linenumberstart*)
      (SETQ *LineNumberStart* (+ *LineNumberStart* *LineNumberIncrement*)) ; $nadd sätts i FIXVARS
      (SETQ $nnext *LineNumberStart*)
      (STRCAT "N" (ITOA $ncount) " ")) "")
)

(DEFUN rts (value) ; Real To String
  (IF pp_inchout (SETQ value (* value 0.039370078)))
  (RTOS value *DecimalsMovement* (IF *SupressTrailingZeroes* nil T))
)

(DEFUN ats (value) ; Angle To String
  (RTOS (RADTODEG value) *DecimalsAngle* (IF *SupressTrailingZeroes* nil T))
)

(DEFUN ftt (value) ; Feed To Time for Rotax and Rotation axis
  (RTOS value *3D-6XspeedDecimals* (IF *SupressTrailingZeroes* nil T))
)  

(DEFUN rtt (value) ; Real To Time for delays
  (RTOS value *DecimalsDelay* (IF *SupressTrailingZeroes* nil T))
)

(DEFUN rtp (value) ; Real to Price
  (IF (NOT *DecimalsCost*) (SETQ *DecimalsCost* 2))
  (RTOS value *DecimalsCost* nil)
)

(DEFUN rtf (value) ; Real To Feed
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
        ((= wline pp_shownext) ; Sets in beging of this file.
          (SETQ pp_shownext (+ pp_shownext 5000))
          (PRINC ".")
          (WINBREATH) T)))

    ((= *Processmode* 4) ; Option for 3D Simulations
      (SIM-INFOTEXT txt))
  )
)



(DEFUN $drilling (allpos allrot $holediameter $attrib $depth nrmdrill / z savepoints xmodsim ymodsim $normaldrill)
  ; Alt 1: *DrillingOffsetByController* is T
  ; In the RAPID command the $X and $y values are reduced by the *DrillingXOffset* *DrillingYOffset* values. WRONG WE TURN MACHINE OFFSET ON/OFF BETWEEN MODES
  ; In the DRILLING command the $x and $y values are the position if the hole. The offset between the jet and the drill is handled by the controller.
  ;
  ; Alt 2: *DrillingOffsetByController* is nil
  ; In the RAPID command the $x and $y values are on the correct position of the hole.
  ; In the DRILLING command the $x and $y values are added by the *DrillingXOffset* *DrillingYOffset* values.
  ;(WRITE (STRCAT "PROBELIST:" (TOSTR pp_probelist)))
  (SETQ $normaldrill nrmdrill)
  (SETQ $sensor (GETPROBEINT)) ;
  (SETQ savepos allpos)
  ;(WRITE (STRCAT "\n\n*DrillingSensoring*:" (TOSTR *DrillingSensoring*) " $sensor:" (TOSTR $sensor) " *ZAxisOption*:" (TOSTR *ZAxisOption*) " *ZSensorType*" (TOSTR *ZSensorType*)))
  (SETQ pp_oldrot allrot)
  (IF (AND (= *ZAxisOption* 2)  ; Sensoring is used
           (> *ZSensorType* 0)) ; Sensoring by M-codes or Z-coordinates
    (PROGN
      (COND
        ((OR (= pp_probeidx 0) (AND *DrillingSensoring* (> (ABS $sensor) 0)))
          ($CHMODE 9) ; Change to Sensoring mode
          (DEFAXIS allpos pp_oldrot)
          (SETQ $reason 3)
          (SSIM-RAPID allpos *SpeedRapid* *SpeedAcceleration* pp_oldrot)
          (RAPID)
          (SETQ $reason 9)
          (SETQ $z (DEFZ (CADDR allpos)))
          (SSIM-Z (CADDR allpos) *ZSpeed* *ZAcceleration*)
          (TOOLDOWN)
          (SSIM-PROBE (CAR allpos) (CADR allpos) (CADDR allpos) 20 2 4 *ZSensoringTime* *ShowSensoringInSimulation*)
          (SIM-INFOTEXT "")
          (SETQ $z (DEFZ $zmaxup))
          (SSIM-Z $zmaxup *ZSpeed* *ZAcceleration*)
          (SETQ $reason 2)
          (TOOLUP)
          (SETQ pp_skipfirst T) ; To avoid that the CHMODE 1 dont go in DUMMY MODE
          ($CHMODE 1))
      )
    )
  )
  (SETQ pp_extraxsim *DrillingXOffset* pp_extraysim *DrillingYOffset*)
  ;(IF (NOT *DrillingOffsetByController*) (SETQ pp_extrax *DrillingXOffset* pp_extray *DrillingYOffset*)) ; This is setup by CHMODE
  (DEFAXIS allpos pp_oldrot) ; drilling offset sets in $chmode and handles in defaxis.
  (SETQ $z (DEFZ (CADDR allpos)))
  (IF (NOT pp_rapidz) (SETQ pp_rapidz $zmaxup))
  (SETQ allpos (ZREPLACE allpos (+ $drillupz pp_zclear)))
  (SSIM-RAPID allpos *SpeedRapid* *SpeedAcceleration* pp_oldrot)
  (SIM-INFOTEXT "")
  (SIM-DRILL 1 $depth *Drillingspeed* *DrillDiameter* *DrillingExtraDelay*);$tools depth
  (SIM-INFOTEXT "")
  (SETQ $zclearens (DEFZ (+ $drillupz pp_zclear)))
  (SETQ $zclearence $zclearens)
  (SETQ $f *DrillingSpeed*)
  (IF $drillnum (SETQ $drillnum (1+ $drillnum)))
  (SETQ $reason 2)
  (DRILLING)
  (SETQ pp_oldpos savepos)
)

(DEFUN cleanAndReduce ()
  (IF *bleedpoint*
    (PROGN
      ($RAPID (CAR *bleedpoint*) (CADR *bleedpoint*) pp_zmaster nil 0 (LIST 0 0 pp_crot) tilted flag); Kanske skall vara pp_cindex
      ($TOOLDOWN *bleedpoint* 6)
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

(DEFUN cleanAndReduce () nil)


(DEFUN $chmode (mode / nextcmd cmdindex debug)
  ; 0=Measure, 1=Drilling, 2=Marking, 3=Pre-piercing, 4=Cutting, 5=Inkjet, 6=Special marking, 7=Probe, 8=Refpoints, 9=Sensoring
  ; About pp_rapidz. This rapid value will be used for all 2D rapids
  (IF (AND pp_pumpoff $pumpstart (MEMBER mode (LIST 2 3 4)))
    (PROGN
      (SETQ $usehighbar (IF (= $startbar (MAX $piercbar $markbar $cutbar)) T nil))
      (IF (= $machinetype 1) (SETQ $startbar *WaterPressure*))
      (SETQ $bar $startbar)
      (SETQ $psi (FIX (* $bar 14.5038)))
      (SETQ $barrel $bar)
      (SETQ $on T $off nil)
      (SETQ pp_oldbar $bar)
      (SETQ pp_pumpoff nil)
      (SETQ $delay *AWJDelayPressureUp*)
      (PUMPONOFF)
    )
  )  
  (SETQ debug nil)
  (IF debug (WRITE "$CHMODE START"))
  (SETQ $mode mode)
  (IF (= $mode 0) (SETQ pp_kdtree nil))
  (IF (AND (NOT (EQUAL $mode $mold)) (MEMBER $mold (LIST 0 1 5 6))) ; If 0:Measure, 1:Drilling, 5:Inkjet, 6:Special marking
    (PROGN
      (SETQ pp_extraXsim 0.0 pp_extraYsim 0.0); ;TIDIGARE SÅ VAR PP_XMOD OCH PP_YMOD satta till noll här.
      (SETQ pp_extrax 0.0 pp_extray 0.0)    
      (SETQ pp_extraXsim 0.0 pp_extraYsim 0.0)
      (SIM-TOOLSET $tools $toollist *ToolMovingSpeed* pp_extraXsim pp_extraYsim))) ;De två sista är försjutning av utritning.
  (COND
    ((= $mold 3) ; if prepiercing has been done as last operation
      (SETQ pp_extraz (+ pp_zclear $piercupz)))
    ((= $mold 7)
      (SETQ allpos (ZREPLACE pp_oldpos pp_maxz))
      (SSIM-RAPID allpos *SpeedRapid* *SpeedAcceleration* pp_oldrot)
      (SIM-INFOTEXT "")
      (DEFAXIS allpos pp_oldrot)
      (DEFVARS)
      (SETQ $z (DEFZ (CADDR allpos)))
      (SETQ $reason 4)
      (RAPID)
      (SETQ pp_oldpos allpos))
  )
  (SETQ setmold2nil nil)
  ;(ALERT (STRCAT "$MODE:" (TOSTR $mode)))
  (COND
    ((EQUAL $mode $mold) nil)
    ((= $mode 0) ; Measuring in advance
      (SETQ $mode 0)
      (IF (NOT $tools) (EVAL pp_toolfirst))
      (SETQ pp_extraxsim *ZMeasureXOffset* pp_extraysim *ZMeasureYOffset*)
      (IF (NOT *MeasureOffsetbyController*) (SETQ pp_extrax *ZMeasureXOffset*  pp_extray *ZMeasureYOffset*))
      (SIM-TOOLSET $tools $toollist *ToolMovingSpeed* pp_extraxsim  pp_extraysim)
      (CHMODE))
    ((AND (= $mode 1) (= *ZAxisOption* 2) (> *ZSensorType* 0) (= pp_probeidx -1) (NOT pp_skipfirst)) ; DUMMY MODE Drilling Do not use now. It will be used later in $drilling function
      (SETQ setmold2nil T)) ; To avoid have $mold to drilling of same reason
    ((= $mode 1) ; drilling
    ; Check how many drilling operation it is.
      (SETQ $drillmax 0 $drillnum 0)
      (SETQ cmdindex pp_cmdindex)
      (SETQ pp_rapidz (+ pp_zclear $drillupz))
      (WHILE (MEMBER (SETQ cmd (CAR (NTH (SETQ cmdindex (1+ cmdindex)) toolpath))) (LIST '$DRILLING))
        (SETQ $drillmax (1+ $drillmax))
      )
      (SETQ pp_extraxsim *DrillingXOffset* pp_extraysim *DrillingYOffset*)
      (IF (NOT *DrillingOffsetByController*) (SETQ pp_extrax *DrillingXOffset* pp_extray *DrillingYOffset*))
      (SIM-TOOLSET $tools $toollist *ToolMovingSpeed* pp_extraXsim  pp_extraYsim) ;
      (SETQ $initdrill T)
      (SETQ $rpm *DrillingRotationSpeed*)
      (CHMODE))
    ((= $mode 2) ; Marking
      (SETQ pp_rapidz (+ pp_zclear $markupz))
      (SETQ pp_extraz (+ pp_zclear $markupz))
      (CHMODE))
      ;($CHBARGRAM 2))
    ((= $mode 3) ; Pre-piercing
      (SETQ pp_rapidz (+ pp_zclear $piercupz)) ; This value pp_rapidz can be set in MARKOFF
      (SETQ pp_extraz (+ pp_zclear $piercupz))
      (CHMODE))
;      ($CHBARGRAM *PiercingPressure* (IF *AWJPiercingAbrasiveFlowByMachine* *AWJCuttingAbrasiveFlow* *AWJPiercingAbrasiveFlow*)))
    ((= $mode 4) ;Cutting
      (SETQ pp_rapidz (+ pp_zclear $cuttingupz)) ;This value can also be set in MARKOFF and are used in case of 3D-5X
      (IF (NOT pp_extraz) (SETQ pp_extraz (+ pp_zclear $cuttingupz)))
      (CHMODE))
      ;(SETQ pp_rapidz nil)
      ;(IF (= *MachineType* 0) ($CHBARGRAM *AWJPressure* *AWJAbrasiveFlow*)))
    ((= $mode 5) ; Inkjet
      (IF (NOT *InkjetOffsetByController*) (SETQ pp_extrax *InkjetXOffset* pp_extray *InkjetYOffset*)) ;PP_XMOD OCH PP_YMOD ÄNDRAT TILL PP_EXTRAX och PP_EXTRAY 2026-01-15 av BJ
      (SETQ pp_extraXsim *InkjetXOffset* pp_extraYsim *InkjetYOffset*)
      (SIM-TOOLSET $tools $toollist *ToolMovingSpeed* pp_extraxsim  pp_extraysim)
      (CHMODE))
    ((= $mode 6) ;Special marking
      (IF (NOT *MarkingOffsetByController*) (SETQ pp_extrax *MarkingXOffset* pp_extray *MarkingYOffset*)) ; Handling the coordinate shift in the cnc file.PP_XMOD OCH PP_YMOD ÄNDRAT TILL PP_EXTRAX och PP_EXTRAY 2026-01-15 av BJ
      (SETQ pp_extraxsim *MarkingXOffset* pp_extraysim *MarkingYOffset*)
      (SIM-TOOLSET $tools $toollist *ToolMovingSpeed* pp_extraxsim  pp_extraysim) ; De två sista är försjutning av utritning.
      (SETQ pp_rapidz (+ $markupz pp_zclear))
      (CHMODE))
    ((= $mode 7) ;Probing in XYZ
;      (SETQ $probetype (- 4 (LENGTH (MEMBER *3D-Measurepoints* (LIST 6 8 9 4)))))
      (CHMODE)
      ;(SSIM-Z (CADDR pp_oldpos) *ZSpeed* *ZAcceleration*)
      ;(SIM-INFOTEXT "")
      )
    ((= $mode 8)
      (CHMODE)); 8=Refpoints
    ((= $mode 9) ; Sensor mode
      (SETQ $z (DEFZ $zmaxup))
      (SIM-INFOTEXT "")
      (CHMODE))
    ((AND $mold (NOT $mode))
      (CHMODE))
  )
  (COND
    ((= $zmode 0) (SETQ pp_rapidz pp_zclear)) ; If fixed Z-axis
    ((MEMBER $zmode (LIST  1 2 4 5)) (SETQ pp_rapidz (+ *ZAutoDist* pp_zclear))) ; CNC controlled (1 2): Auto, M-code and on Height sensor (3 4) Auto and M-code move up to *ZAutoDist*
  )
  (SETQ $mold $mode)
  (IF setmold2nil (SETQ $mold nil))
  (IF $mode (SETQ $modestr (NTH $mode (LIST "MEASURING" "DRILLING" "MARKING" "PRE-PIERCING" "CUTTING" "INKJET" "SPECIAL MARKING" "PROBE" "REFPOINTS" "SENSOR"))))
  (IF debug (WRITE "End of chmode"))
)

(DEFUN $chbargram (option / supportfunction)
  (DEFUN supportfunction()
    (IF (OR (NOT pp_oldbar) (> $bar pp_oldbar)) (SETQ $delay *AWJDelayPressureUp*))
    (IF (< $bar pp_oldbar)
      (PROGN
        (SETQ $delay *AWJDelayPressureDown*)
        (IF (AND (= option 3) (NOT *AWJBleedOut*)) (SETQ $delay (- $delay $JetabrasiveOff)))))
    (SETQ $barunchanged (IF (EQUAL $bar pp_oldbar 1) T nil))
    (SETQ $gramunchanged (IF (EQUAL $gram pp_oldgram 1) T nil))
    (IF *SkipPressureChanges* (SETQ $barunchanged T))
    (IF *SkipAbrasiveFlowChanges* (SETQ $gramunchanged T))
    (SETQ $barrel (IF pp_oldbar (- $bar pp_oldbar) $bar))
    (SETQ $useabr (IF (> $gram 0) T nil))
    (COND
      (pp_oldbar (SETQ $init nil))
      ((AND *SkipPressureInit* $usehighbar) (SETQ $barunchanged T $init T))
      ((NOT *SkipPressureInit*) (SETQ $barunchanged nil $init T))
      ((AND *SkipPressureInit* (NOT $usehighbar)) (SETQ $init T))
    )
    (IF (AND (NOT *AWJBleedOut*) (< $bar pp_oldbar)) (SETQ $barunchanged T)) ; When open jet to recuce the pressur in the cutoff function.
  )
  (COND
    ((> $machinetype 1) nil)
    ((= option 1) nil);Turn on the pump
    ((= $machinetype 1) nil)
    ((= $machinetype 1) ; If its pure waterjet cutting
      (SETQ $bar *WaterPressure*)
      (SETQ $psi (FIX (* $bar 14.5038)))
      (SUPPORTFUNCTION)
      (CHBARGRAM))
    ((= option 2) ;waterjet marking
      (SETQ $bar $markbar)
      (SETQ $gram $markflow)
      (SETQ $psi (FIX (* $bar 14.5038)) $lbs (/ $gram 453.5924))
      (SETQ $usehighbar (IF (EQUAL $markbar (MAX $piercbar $markbar $cutbar) 1) T nil))
      (SETQ $usehighflow (IF (EQUAL $markflow (MAX $piercflow $markflow $cutflow) 1) T nil))
      (SUPPORTFUNCTION)
      (CHBARGRAM))
    ((= option 3) ; Piercing Stationary or Circular
      (SETQ $bar $piercbar)
      (SETQ $gram $piercflow)
      (SETQ $psi (FIX (* $bar 14.5038)) $lbs (/ $gram 453.5924))
      (SETQ $usehighbar (IF (EQUAL $piercbar (MAX $piercbar $markbar $cutbar) 1) T nil))
      (SETQ $usehighflow (IF (EQUAL $piercflow (MAX $piercflow $markflow $cutflow) 1) T nil))
      (SUPPORTFUNCTION)
      (CHBARGRAM))
    ((= option 4) ; Cutting
      (SETQ $bar $cutbar)
      (SETQ $gram $cutflow)
      (SETQ $psi (FIX (* $bar 14.5038)) $lbs (/ $gram 453.5924))
      (SETQ $usehighbar (IF (EQUAL $cutbar (MAX $piercbar $markbar $cutbar) 1) T nil))
      (SETQ $usehighbar T) ; We think cutbar always should be the highest pressure
      (SETQ $usehighflow (IF (EQUAL $cutflow (MAX $piercflow $markflow $cutflow) 1) T nil))
      (SUPPORTFUNCTION)
      (CHBARGRAM))
    ((= option 5) ; Turn off pump
     nil)
  )
  (IF (NOT pp_oldbar) (SETQ pp_startbar $bar pp_usehighbar $usehighbar))
  (SETQ pp_oldbar $bar pp_oldgram $gram)
)


(DEFUN chbargram () nil)

(DEFUN $pre-piercing (allpos pp_ptype pp_leadname pp_nodename pp_vec flag pp_leadplan allrot attrib / pp_fs pp_fe docirc beveltype pp_vectordir $vaccumAssist savepos v tilted $jetabrasiveoff)
  (SETQ $ipd 0)
  (IF (AND *ZPiercingUse* (> pp_ptype 0) (NOT (= pp_ptype 5))) ; If not blind lead. This is to handle increased piercing distance
    (PROGN
      (SETQ $ipd *ZPiercingDist*)
      (SETQ v (NORMALIZE pp_vec))
      (SETQ v (LIST (* (CAR v) *ZPiercingDist*) (* (CADR v) *ZPiercingDist*) (* (CADDR v) *ZPiercingDist*)))
      (SETQ allpos (SUBPOINTS allpos v))))
  (SETQ $piercingpos allpos)
  (SETQ $leadtilt (IF (EQUAL pp_leadplan (LIST 0 0 -1) 0.001) nil T))
  (SETQ $leadplan pp_leadplan)
  (SETQ savepos allpos saverot allrot)
  (IF (= *Zsensoringmode* 6) (GETPROBEINT))
  ($CHBARGRAM 3)
  (SETQ $startindex (1+ $startindex))
  (SETQ $lastcutonpart (IF (MEMBER $startindex pp_partmax) T nil))
  (SETQ $lowatoff (NTH $startindex pp_lowhighlist))
  (IF (AND (= $startmax $startindex) *SerialProduction* (CAR pp_lowhighlist)) (SETQ $lowatoff T))
  (SETQ beveltype flag)
  (SETQ $attrib attrib)
  (SETQ $ctype 0)
  (SETQ $vaccumAssist *VacuumAssist*)
  (IF (NOT *AWJUsePreload*) (SETQ $vaccumAssist nil))
  (SETQ $speedramp T)
  (SETQ $leadname pp_leadname)
  (SETQ pp_fe *AWJCircularPiercingSpeed*)
  (SETQ pp_fs pp_fe)
  (SETQ tilted (IF (> (DISTANCE (LIST 0 0) allrot) 0.005) T nil))
  ($RAPID (ZREPLACE allpos (+ $piercupz pp_zclear)) nil 0 allrot tilted flag) ;ZOK
  (SIM3D-TILT (- (CAR allrot)) (- (CADR allrot)) $arel $brel)
  (DEFAXIS allpos allrot)
  (DEFVARS)
  ;($TILT $a $b 1)
  (SIM-INFOTEXT "")
  (SETQ pp_allpos savepos pp_allrot allrot)
  (SETQ pp_oldrot allrot)
  (SETQ allpos savepos)
    ;Calculate increased piercing height
  ;(SETQ $ipd 0)  
  ;(IF (AND *ZPiercingUse* (> pp_ptype 0) (NOT (= pp_ptype 5))) ; If not blind lead or airstart
  ;  (PROGN
  ;    (SETQ $ipd *ZPiercingDist*)
  ;    (SETQ v (NORMALIZE pp_vec))
  ;    (SETQ v (LIST (* (CAR v) *ZPiercingDist*) (* (CADR v) *ZPiercingDist*) (* (CADDR v) *ZPiercingDist*)))
  ;    (SETQ allpos (SUBPOINTS allpos v))
  ;  )
  ;)
  (IF (> (DISTANCE (LIST (CAR pp_oldpos) (CADR pp_oldpos)) allpos) 0.01) ; If the piercing position is not vertical to actual position.
    ($TOOLDOWN3D allpos)
    ($TOOLDOWN allpos 4) ; Reason 1=Init, 2 Between Drillings, 3 Markings, 4 Prepiercings 5 Cuts in part, 6 Between parts,7 Cleaning or Pressure reduce.
  )
  (SETQ *bleedpoint* allpos)
  (IF pp_partstopdata (PROGN (SETQ $reason 1) ($STOP pp_partstopdata)))
  (SETQ pp_partstopdata nil)
  (SIM-ON T pp_fe)
  (SETQ $kerf 0 $marking nil)
  (SETQ $ptype pp_ptype)
  (SETQ $Jetpreload (IF *AWJUsePreload* *AWJDelayPreload* nil))
  (SETQ $JetAbrasiveOn *AWJPiercingArrive*)
  (COND
    ((= *MachineType* 1) ; Pure water Its only stationary piercings
      (SETQ $delay 0.0)
      (SETQ $time *WaterPiercingTime*)
      (IF (> *WaterDelayAfterPiercing* $time) (SETQ $time *WaterDelayAfterPiercing*))
      (SETQ $ptype 2)
      (SETQ $pstat $time))
    ((= pp_ptype 2) ; Stationary piercing on AWJ-machines
      (SETQ $delay *AWJDelayWaterAbrasiveOn*)
      (SETQ $time *AWJStationaryPiercing* $circ nil)
      (IF (OR *AWJAutomaticPiercing* (AND *3D-5X* pp_vec)) (SETQ $time (STATIONARYPIERCINGTIME (DISTANCE (LIST 0 0 0) pp_vec))))
      (IF (> *AWJDelayAfterPiercing* $time) (SETQ $time *AWJDelayAfterPiercing*))
      (SETQ $pstat $time))
    ((= pp_ptype 3) ; Circular piercing on AWJ-machines
      (SETQ $delay *AWJDelayWaterAbrasiveOn*)
      (SETQ $time *AWJCircularPiercing*)
      (SETQ $cpfeed *AWJCircularPiercingSpeed*)
      (SETQ $cpradius (* *PiercingDiameter* 0.5))
      (SETQ $cpturns (CEIL (/ (* (/ $cpfeed 60.0) (CEIL $time)) (* *PiercingDiameter* PI))))
      (SETQ $circ T))
  )
  (SIM-PIERCEON)
  
  (SETQ $JetAbrasiveOff(IF $useabr *AWJPiercingEmpty* nil))
  (PIERCING)
;  (SETQ pp_allpos savepos pp_allrot saverot)
  (IF (AND $circ *CustomCircularPiercing*) (CIRC-PIERCING))
  (SETQ $leadout nil)
  (SETQ $delay (IF $useabr *AWJDelayWaterAbrasiveOff* 0)) ; Before the $delay was set to zero if $wacode was T
  (SETQ $chkerf nil $kerf 0)
  (SETQ $time (IF (= *MachineType* 0) *AWJDelayAfterCutting* *WaterDelayAfterCutting* ))
  (SETQ $marking nil)
  (SIM-PIERCEOFF)
  (SIM-OFF)
  (CUTOFF)
  ($TOOLUP (+ $piercupz pp_zclear) 4 "PIERCING")
  (IF (> (LOGAND flag 16) 0) (SETQ pp_rapidz (+ $piercupz pp_zclear)))
  (SETQ pp_oldpos allpos)
)

(DEFUN $piercing (pp_endp allrot pp_time pp_docirc / $ptype $stat $feed $radie $turn $ab pp_vectordir *CustomCircularPiercing*
                        *AWJCircularPiercing* *AWJCircularPiercingDiameter* *AWJCircularPiercingSpeed* *AWJStationaryPiercing* thick ChangeAbrasiveFlow)
  (SETQ *bleedpoint* pp_endp)
  (SETQ $piercingpos pp_endp)
  (SETQ pp_oldpos pp_endp)
  (SETQ $ptype pp_ptype)
  (SETQ $vector pp_vec)
  (SETQ $marking nil)
  (COND
    ((= *MachineType* 0) ; AWJ cutting
      (SETQ $lowhigh (IF (AND (OR (= $ptype 2) (= $ptype 3)) pp_lowhigh) T nil))
      (SETQ $jetpreload (IF (AND $lowhigh (> *AWJDelayPreload* 0.0)) *AWJDelayPreload* nil))
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
  (SETQ $ab nil)
  (IF (< pp_ptype 5) (SIM-PIERCEON))
  (PIERCING)
  (IF *speedoverride* (SETQ pp_fe *speedoverride*))
  (IF (AND $circ *CustomCircularPiercing*) (CIRC-PIERCING))
  (SIM-PIERCEOFF)
)

(DEFUN piercing ()
  (IF (= pp_ptype 3) (CIRC-PIERCING))
)
(DEFUN getprobeint ()
  ;(WRITE (STRCAT "PROBELIST:" (TOSTR pp_probelist))) ;ÄNDRA
  (SETQ $sensor (CADR (ASSOC (SETQ pp_probeidx (1+ pp_probeidx)) pp_probelist)))
  (IF (NOT $sensor)
    (PROGN
      (SETQ $sensor 0)
      (IF (NOT pp_probewarning) (SETQ pp_probewarning (ALERT "Warning! $sensor is out of index")))))
 ;  (WRITE (STRCAT "GETPROBEINT:" (TOSTR pp_probelist) " IDX:" (TOSTR pp_probeidx) " SENSOR:" (TOSTR $sensor)))
   (EVAL $sensor)
  ;(IF (> (ABS $sensor) 0) (PROGN (SIM-DELAY *ZSensoringTime*)))
)

;------------------------------------- Common function for marking -------------------------
(DEFUN $markon (allpos pp_atrib pp_clen allrot special pp_vec $starttan $maxslope from3d5x / debug $spmark $edge)
  (SETQ $spmark special)
  (SETQ debug nil)
  (SETQ pp_vec (NORMALIZE pp_vec))
  (IF debug (WRITE ";******************* START MARKON"))
  (SETQ pp_extraz nil)
  (IF (AND (= *Zsensoringmode* 6) (NOT pp_skipProbeChk)) (GETPROBEINT))
  (SETQ pp_bevelmarking nil)
  (SETQ pp_specialmarking nil)
  (SETQ $speedramp T)
  (SETQ pp_dobevel nil)
  (SETQ tilted (IF (EQUAL pp_vec (LIST 0 0 -1) 0.001) nil T))
  (SETQ $edge 0) ; Is always on contour no G41/G42
  (IF (NOT special) ; If its waterjet marking
    (PROGN
      (SETQ $JetAbrasiveOn *AWJMarkingArrive*)
      (SETQ pp_fs $speedmarking)
      (SETQ pp_fe $speedmarking)
      (SETQ $startindex (1+ $startindex))
      (SETQ $lowatoff (NTH $startindex pp_lowhighlist)) ; pp_piercindex starts at 1
      (IF (AND (= $startmax $startindex) *SerialProduction* (CAR pp_lowhighlist)) (SETQ $lowatoff T))
      (SETQ $circ nil)
      (SETQ $time *AWJMarkingStartDelay*)
      (SETQ $delay (IF (AND $useabr $wacode) *AWJMarkingAbrasiveOn* 0))
      (SETQ $marking T)
      (SETQ $ptype (IF ishole -2 -1))
      (SETQ $kerf 0 $side 0)
      (IF ishole (SETQ $time *AWJPointMarkingDelay*))
      (SETQ $ctype 0)
      (IF (OR isgentext ishole) ($RAPID allpos nil (IF from3d5x 4 0) allrot tilted flag))
      ;($TOOLDOWN allpos 3) ;jb removed 20260219
      (IF (> (DISTANCE (LIST (CAR pp_oldpos) (CADR pp_oldpos)) allpos) 0.01) ; If the piercing position is not vertical to actual position.    ;jb Added 20260219
        ($TOOLDOWN3D allpos)
        ($TOOLDOWN allpos 3) ; Reason 1=Init, 2 Between Drillings, 3 Markings, 4 Prepiercings 5 Cuts in part, 6 Between parts,7 Cleaning or Pressure reduce.
      )
      ($CHBARGRAM 2)
      (SIM-ON nil *Markingspeed*) ; var nil
      (SETQ $attrib pp_atrib)
      (PIERCING)
      (IF pp_bevelmarking (SETQ $ab T)))
    (PROGN
      (SETQ pp_specialmarking T)
      (SETQ pp_fs *SpecialMarkingSpeed*)
      (SETQ pp_fe *SpecialMarkingSpeed*)
      ($RAPID allpos nil 0 pp_allrot tilted flag)
      ($TOOLDOWN allpos 3) ; Ändrade från 2 till 3 3/4-20
      (SETQ $attrib pp_atrib)
      (SIM-ON nil *SpecialMarkingSpeed*)
      (MARKON)
    )
  )
  (SETQ $sensor 0)
  (SETQ pp_oldpos allpos)
  (SETQ pp_oldrot allrot)
  (IF debug (WRITE ";****************** END MARKON"))
)

(DEFUN $markoff (typ allpos / specialmarking allpos $Jetabrasiveoff)
  (SETQ $Jetabrasiveoff (IF $useabr *AWJMarkingEmpty* nil))
  (SETQ $JetValveOff *AWJDelayAfterCutting*)
  (SETQ $delay (IF $useabr *AWJMarkingAbrasiveOff* 0))
  (SETQ $kerf 0 $chkerf nil)
  (SETQ $marking T)
  (SETQ $time *AWJDelayAfterCutting*)
  (IF (> typ 0) (DEFAXIS allpos pp_oldrot))
  (SIM-OFF)
  (IF pp_specialmarking (MARKOFF) (CUTOFF))
  (COND
    ((= typ 0) ; This is a normal 3X toolup from IGEMS 2D
      ($TOOLUP (+ pp_zclear $markupz) 3 "UP BETWEEN MARKINGS"))
    ((= typ 1) ; This is a 3D-5X cutoff, and the Z value should be used in toolup
      ($TOOLUP (CADDR allpos) 7 "5X-T-TOOLUP")
      (SETQ pp_rapidz (CADDR allpos))) ; If thie is set here it will not be set in $CHMODE
    ((= typ 2) ($TOOLUP3D allpos))  ; Non vertical toolup in 3D-5X
  )
  (SIM-IAIP nil)
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
      ; Set the path of the CNC-file
      (COND
        (*OutputUseFixedFolder* (SETQ fpath *OutputFolder*))
        (T (SETQ fpath (UC-GET *MachineName* "*OutputFolder*" *OutputFolder*)))
      )
      ; Suggest the name of the CNC-file
      (COND
        (CUSTOM-FILENAME (SETQ name (CUSTOM-FILENAME))) ; Define this function in the postprocessor  
        ((AND (= *PPFileByDrawing* 0) (> *SheetQuantity* 0) (FILE-VALIDFILENAME *SheetName*))
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
          (IF (SETQ n (GETNR (FILE-NAMEONLY filename T))) (SETQ fnumber n))
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

(DEFUN getnr (value / pos len txt tk)
  (SETQ pos 1 len (STRLEN value) txt "")
  (WHILE (<= pos len)
    (SETQ tk (ASCII (SUBSTR value pos 1)))
    (IF (AND (> tk 47) (< tk 58)) (SETQ txt (STRCAT txt (CHR tk))))
    (SETQ pos (+ pos 1))
  )
  (IF (> (ATOF txt) 0) (ATOF txt) nil)
)

;-------------------------------------------------- Simulation pre-defined functions ----------------------------
(DEFUN ssim-toolset (toolused toollist speed)
  ; Variables
  ; pp_extraXsim and pp_extraYsim handles the drawing displacement of special equipment as drilling, inkjet and special marking.
  ; pp_xmodsim and pp_pp_ymodsim handles the different offsets depending of which tool are used T1, T2, T3 and so on..
  ; pp_xmod and pp_ymod handles the displacement of the coordinates in the CNC file.
  (SIM-TOOLSET toolused toollist speed pp_extraxsim pp_extraysim) ;Two last arguments are for extra equipments offsets (drilling units, markings and so on)
)

(DEFUN ssim-setup (/ sizex sizey vector *Toolpark*)
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
  ;(SETQ *toolpark* nil) ; det blir inte rätt vid borrning annars.
  (SIM-SETUP 0 0 (CADDR *ZeroPoint*) Sizex SizeY *BarLength* *ToolQuantity* *ToolMinDistance* *ToolMaxDistance*
             *ToolPark* *BarAligned* *Maxfeed* *Minfeed* 0.0 0.0 *ZMaxMovement*)

  (SETQ vector
    (COND
      ((= *SixAxisDirection* 0) (LIST 1 0 0))
      ((= *SixAxisDirection* 1) (LIST 0 1 0))
      ((= *SixAxisDirection* 2) (LIST -1 0 0))
      ((= *SixAxisDirection* 3) (LIST 0 -1 0))
      ((= *SixAxisDirection* 4) (LIST 1 0 1))
      ((= *SixAxisDirection* 5) (LIST 0 1 1))
      ((= *SixAxisDirection* 6) (LIST 0 0 1))
      
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

(DEFUN ssim-line (endp fs fe rot / z)
  (IF pp_park (SETQ rot (APPEND pp_parkrot (LIST (CADDR rot)))))
  (SIM3D-TOOLDIR (- (CAR rot)) (- (CADR rot)))
  (SETQ z (CADDR endp))
  (IF pp_probmod (SETQ z (+ z pp_probmod)))
  (SIM-LINE (- (CAR endp) pp_xmodsim *SIM-ADDX* pp_extraXsim)
            (- (CADR endp) pp_ymodsim *SIM-ADDY* pp_extraYsim) z fs fe (CADDR rot) (CAR pp_vec) (CADR pp_vec) (CADDR pp_vec) $len)
)

(DEFUN ssim-arc (endp centp pp_ccw $fs $fe rot / z)
  (IF pp_park (SETQ rot (APPEND pp_parkrot (LIST (CADDR rot)))))
  (SETQ z (CADDR endp))
  (IF pp_probmod (SETQ z (+ z pp_probmod)))
  (SIM3D-TOOLDIR (- (CAR rot)) (- (CADR rot)))
  (SIM-ARC (- (CAR endp) pp_xmodsim  *SIM-ADDX* pp_extraXsim)
           (- (CADR endp) pp_ymodsim *SIM-ADDY* pp_extraYsim) z
           (- (CAR centp) pp_xmodsim  *SIM-ADDX* pp_extraXsim)
           (- (CADR centp)  pp_ymodsim *SIM-ADDY* pp_extraYsim) pp_ccw $fs $fe (CADDR rot) (CAR pp_vec) (CADR pp_vec) (CADDR pp_vec))
)

(DEFUN ssim-rapid (endp speedrapid speedacc rot /  z)
  (IF pp_park (SETQ rot (APPEND pp_parkrot (LIST (CADDR rot)))))
  (SETQ z (CADDR endp))
  (IF pp_probmod (SETQ z (+ z pp_probmod)))
  (IF (NOT pp_xmodsim) (SETQ pp_xmodsim 0.0 pp_ymodsim 0.0))
  (IF *TiltOnRapid* (SIM3D-TOOLDIR (- (CAR rot)) (- (CADR rot))))
  (SIM-RAPID (- (CAR endp) pp_xmodsim *SIM-ADDX* pp_extraXsim) (- (CADR endp) pp_ymodsim *SIM-ADDY* pp_extraYsim) z SpeedRapid SpeedAcc (CADDR rot))
)

(DEFUN ssim-probe (x y z r color thick tid visable)
  (SIM-PROBE (+ x *SIM-ADDX*) (+ y *SIM-ADDY*) z r color thick tid visable)
)


(DEFUN zreplace (current value) (LIST (CAR current) (CADR current) value)) ; add or replace the third object in the 3 atom list

(DEFUN $hqchawj (centp radie attr qua / x y z stok kerf area len $hqch)
  (SETQ $hqch T)
  (IF (NOT *HQCHcorrection*) (SETQ *HQCHcorrection* 0.0))
  (SETQ radie (+ radie (* *HQCHcorrection* 0.5)))
  (SETQ allrot (LIST 0 0 0))
  (SETQ stock (* *ToolDiameter* 0.25)) ; CHANGE THIS DURING LABS
  (SETQ fineradie (- radie (* *Tooldiameter* 0.5))) ; movement radius for last turn
  (SETQ roughradie (- fineradie stock)) ; movement radius for piercingturn
  (IF (< roughradie 0.1) (SETQ roughradie 0.1))
  (SETQ leadlen (* *Thickness* 0.15))
  (SETQ leadang (- (/ leadlen roughradie))) ; its negative and when the lead is finish it is in zero angle
  (SETQ allpos (ZREPLACE (POLAR centp leadang roughradie) (CADDR centp)))
  (SETQ rappos (ZREPLACE allpos (+ *CuttingLiftHeight* (CADDR centp))))
  (SETQ kerf 0 $hqch T len leadlen area (* radie radie PI) inside 1)
  ($RAPID rappos nil 2 '(0 0 0) nil flag)
  ($CUTON allpos kerf 0 5 len area len "HQCH" "HQCH" inside allpos T $xfine (LIST 0 0 (- *Thickness*)) 0 0 PIH (LIST 0 0 -1) allrot 10 "")
  (SETQ segs (CEIL (/ (ABS leadang) *LargestSegmentAngle*)))
  (SETQ segv (/ (ABS leadang) segs))
  (REPEAT segs
    (SETQ allpos (POLAR centp (SETQ leadang (+ leadang segv)) roughradie))
    ($CARC (- (CAR allpos) (CAR pp_oldpos)) (- (CADR allpos) (CADR pp_oldpos)) roughradie T $xfine)
  )
  ($CCIRCLE (- roughradie) 0.0 $fine)
  ($CLINE (- fineradie roughradie) 0 $xfine)
  ($CCIRCLE (- fineradie) 0.0 $xfine)
  ($CLINE (- stock) 0 $rough)
  ($CUTOFF 0 (LIST 0 0 0))
)

(DEFUN $hqchwater (centp radie attr qua / allrot fineradie allpos kerf len area inside hqch)
  (SETQ allrot (LIST 0 0 0))
  (SETQ fineradie (- radie (* *Tooldiameter* 0.5)))
  (SETQ allpos (ZREPLACE (POLAR centp 0.0 fineradie) z))
  (SETQ kerf 0 $hqch T len (* radie 2 PI) area (* radie radie PI) inside 1)
  ($CUTON allpos kerf 0 5 len area len "HQCH" "HQCH" inside allpos T *WaterHighSpeed* (LIST 0 0 (- *Thickness*)) 0 0 PIH (LIST 0 0 -1) allrot 10 "")


  ($CCIRCLE (- fineradie) 0.0 $xfine)
  ($CUTOFF 0 (LIST 0 0 0))
  (SETQ $hqch nil)
)

(DEFUN $hqchplasma (centp radie attrib qua / area omkr x y z speed hqchradie leadradie hup vin leadstp leadcp leadend $attrib)
  ; Speed rules:
  ; If the hole is smaller then diameter 10: Use 50% of speed.
  ; If the hole is larger then 60: Use 100% of the speed.
  ; If the hole is between 10-60 calculate the speed by a linear function.
  (SETQ area (* radie radie PI) omkr (* (* radie 2) PI))
  (SETQ x (CAR centp) y (CADR centp) z (CADDR centp) $attrib attrib)
  (IF *CustomTrueHole*
    (PROGN
      (DEFAXIS centp pp_oldrot)
      (SETQ $z (DEFZ z))
      (DEFVARS)
      (SETQ $r radie)
      (TRUEHOLE))
    (PROGN
      (SETQ $hqch T)
      (COND
        ((<= radie 5) (SETQ speed 50))
        ((>= radie 30) (SETQ speed 100))
        (T (SETQ speed (+ (* 2 (- radie 5)) 50)))
      )
      (SETQ toolradius (* *ToolDiameter* 0.5))
      (SETQ modmaxtoolradius (+ (* *MaxToolDiameter* 0.5) 1.0))
      (IF (< *InternalToolCompensation* 2) ; IGEMS=0, IGEMS+Machine=1, Machine=2 If IGEMS Tool radius compensation should be used.
        (SETQ hqchradie (- radie toolradius))
        (SETQ hqchradie radie)
      )
      (SETQ leadradie (* hqchradie 0.25))
      (IF (< leadradie modmaxtoolradius) (SETQ leadradie modmaxtoolradius))
      (SETQ hup (- hqchradie leadradie)) ;huputinusan
      (SETQ vin (ASIN (/ leadradie hup)))
      (SETQ leadcp (ZREPLACE (POLAR centp 0 hup) z))
      (SETQ leadstp (ZREPLACE (POLAR leadcp (- (* PI 1.5) vin) leadradie) z))
      ($CUTON leadstp 1 2 qua omkr area omkr "" "" 1 leadstp 0  speed leadstp  0 0 0 (LIST 0 0 -1)  0 (LIST 0 0 -1) (LIST 0 0 -1) nil 0   pp_oldrot 0 "")
      (SETQ leadend (LIST (+ x hqchradie) y z))
      ($HOLD)
      ($ARC leadend leadcp T 1 speed speed 0 (LIST 0 0 -1) pp_oldrot (* (* leadradie 2) PI 0.25)) ;ZOK
      (SETQ allpos (LIST x (- y hqchradie) z))
      ($ARC allpos centp T 0 speed speed 0 (LIST 0 0 -1) pp_oldrot (* omkr 0.75)) ;ZOK
      ($ARC leadend centp T 0 speed speed 0 (LIST 0 0 -1)pp_oldrot (* omkr 0.25))
      ($FLYOFF)
      (SETQ allpos (LIST x (+ y hqchradie) z))
      ($ARC allpos centp T 2 speed speed 0 (LIST 0 0 -1) pp_oldrot (* omkr 0.25)) ;OK
      ($CUTOFF 0 (LIST 0 0 0))
      (SETQ $hqch nil)
    )
  )
)

(DEFUN checksumcount (text / q a) ; function for the checksum
  (SETQ text (STRCASE text nil))
  (SETQ q 1 a 0)
  (REPEAT (STRLEN text)
    (SETQ a (+ a (ASCII (SUBSTR text q 1))))
    (SETQ q (1+ q))
  )
  (EVAL (* (+ a 114) 3))
)

(DEFUN $toolup (z $reason $msg / debug) ; Z always from bottom. ALAWYS CALLED FROM $CUTOFF, $MARKOFF
  (SETQ debug nil)
  (IF debug (WRITE (STRCAT "$TOOLUP Start $Reason:" (TOSTR $reason) " $zmode:" (TOSTR $zmode) " PP_OLDPOS:" (TOSTR pp_oldpos) " Z:" (TOSTR z))))
  (SIM-INFOTEXT "")
  (COND
    ((= $zmode 0) nil) ; Fixed Z-axis no motion at all
    ((MEMBER $reason (LIST 0 1 7 8)) ; From 3D-5X
      (DEFAXIS pp_oldpos pp_oldrot) ; This will make correct XYIJ
      (IF (= $reason 7) (SETQ $msg "3D-5X UP"))
      (SSIM-RAPID (LIST (CAR pp_oldpos) (CADR pp_oldpos) z) *SpeedRapid* *SpeedAcceleration* pp_oldrot)
      (SETQ $z (DEFZ z))
      (SETQ $zrel (- z (CADDR pp_oldpos)))
      (IF (MEMBER $reason (LIST 0 1 7)) (TOOLUP) (TOOLUP3D)))
    ((MEMBER $zmode (LIST 1 4)); 1=Auto by water On/Off, 4=Sensor by water On/off
      (SETQ $move T)
      (SETQ z (+ *ZAutoDist* pp_zclear)) ; Always from bottom
      (SSIM-Z z *ZSpeed* *ZAcceleration*) ;SIMOK
      (SIM-INFOTEXT "")
      (SETQ $z (DEFZ z))
      (SETQ $zrel (- z (CADDR pp_oldpos)))
      (TOOLUP))
    ((OR (= $zmode 2) (= $zmode 5))   ; 2= By M-code Up/Down, Sensor by M-code Up/Down
      (SETQ $move T)
      (SETQ z (+ *ZAutoDist* pp_zclear)) ; Always from bottom
      (SSIM-Z z *ZSpeed* *ZAcceleration*) ;SIMOK
      (SIM-INFOTEXT "")
      (SETQ $z (DEFZ z))
      (SETQ $zrel (- z (CADDR pp_oldpos)))
      (TOOLUP))
    ((OR (= $zmode 3) (= $zmode 6) (= $zmode 7)) ; 3= by Z-cordinate, 6= Sensor by Z-cordinate, 7=Measuring in advance
      (SSIM-Z z *ZSpeed* *ZAcceleration*) ;SIMOK
      (SIM-INFOTEXT "")
      (SETQ $z (DEFZ z))
      (SETQ $zrel (- z (CADDR pp_oldpos)))
      (IF debug (WRITE (STRCAT "Z:" (RTS $z) " $ZREL:" (RTS $zrel))))
      (TOOLUP))
    (T (ALERT "TOOLUP Undefined option"))
  )
  (IF (AND (/= $reason 1) (<= *ZSensoringMode* 1))(SETQ $sensor 0)) ;Moved this from Tooldown to have a longer lifetime when using senoringmode Once Bo 2024.05.10
  (SETQ pp_toolisup $move)
  (SETQ pp_oldpos (ZREPLACE pp_oldpos z))
  (IF debug (WRITE "$TOOLUP end"))
  (SETQ $ipd 0)
)

(DEFUN ssim-z (z speed acc)
  (IF pp_probmod (SETQ z (+ pp_probmod z)))
  (SIM-Z z speed acc)
)

(DEFUN toolup3d ()
  (IF (NOT toolup3dmsg) (BEEP (ALERT "\nWARNING! Undefined function TOOLUP3D")))
  (TOOLUP)
)

(DEFUN $tooldown (allpos $reason / lift NotMove color debug) ; $TOOLDOWN IS ALWAYS CALLED FROM $RAPID FUNCTION
  (SETQ debug nil)
  (SETQ pp_noZonrapid nil)
  (SETQ $move pp_toolisup)
  ; Reason 1=Init, 2 Between Drillings, 3 Markings, 4 Prepiercings 5 Cuts in part, 6 Between parts,7 Cleaning or Pressure reduce. 0=Initially to measure heigh for other equipment than cutting (drilling, inkjet other).
  (IF (NOT pp_zsensorpos) (SETQ pp_zsensorpos (LIST 900000000 900000000)))
  (COND
    ; *ZSensoringMode* 0 = Once, $sensor sets in $HEADER
    ; *ZSensoringMode* 1 = Partwise, $sensor sets in Part
    ((OR (<= $zmode 3) (>= $zmode 7)) (SETQ $sensor 0))
    ((= *ZSensoringMode* 2) (SETQ $sensor 1)) ; Every piercing
    ((= *ZSensoringMode* 3) (SETQ $sensor 2)) ; Stamping
    ((= *ZSensoringmode* 4) (SETQ $sensor 3)) ; Dragging
    ((= *ZSensoringMode* 5) ; Zoon
      (IF (> (DISTANCE pp_zsensorpos allpos) *FlatZoneRadius*)
        (PROGN
          (SETQ pp_zsensorpos allpos)
          (SETQ $sensor 1))
        (SETQ $sensor 0)))
  )
  (SETQ pp_dragpos allpos)
  (IF (> (ABS $sensor) 0)
    (PROGN
      (COND
        (T nil) ; to avoid everything below to happen
        ((= (ABS $sensor) 1) (SIM-TEXT "Sensor Adjusting Z-axis" 1 40))
        ((= (ABS $sensor) 2) (SIM-TEXT "Sensor Stamping" 1 40))
        ((= (ABS $sensor) 3) (SIM-TEXT "Sensor Dragging" 1 40))
      )
      (SIM-INFOTEXT "")))
  (IF (> (ABS $sensor) 0)
    (PROGN
      (SETQ totsensor (+ totsensor *ZSensoringTime*))))
  (SSIM-Z (CADDR allpos) *ZSpeed* *ZAcceleration*)
  (SETQ color (ASSOC (ABS $sensor) '((0 7) (1 7) (2 2) (3 5))))
  (IF (> (ABS $sensor) 0) (SSIM-PROBE (- (CAR allpos) pp_extraXsim) (- (CADR allpos) pp_extraYsim) (CADDR allpos) 20 (CADR color) 4 *ZSensoringTime* *ShowSensoringInSimulation*))
  (SETQ $initheight pp_initheight)
  (SETQ pp_initheight nil)
  (SETQ $z (DEFZ (CADDR allpos)))
  (DEFVARS)
  (SETQ $msg "TOOL DOWN")
  (SSIM-Z (CADDR allpos) *ZSpeed* *ZAcceleration*)
  (COND
    ((AND (= *ZAxisOption* 0) (NOT *ZDownOnFixed*)) nil) ; Fixed Z To support STM they can set a variable that moves the head down first time
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
  (SETQ pp_toolisup nil)
  (SETQ $initdrill nil)
  (SETQ pp_oldpos (ZREPLACE pp_oldpos (CADDR allpos)))
  ;(IF (< (ABS $sensor) 2) (SIM-TEXT "" 1 40))
  ;(IF (<= *ZSensoringMode* 1) (SETQ $sensor 0)) ;Moved this to $toolup to have a longer lifetime when using senoringmode Once 2024.05.10
  (IF debug (WRITE "TOOLDOWN END"))
)
(DEFUN header () nil)
(DEFUN part () nil)
(DEFUN pathinfo () nil)
(DEFUN refpos () nil)
(DEFUN extsub () nil)
(DEFUN mrapid () nil)
(DEFUN itext () nil)
(DEFUN tilt () nil)
(DEFUN fmode () nil)
(DEFUN drilling () nil)
(DEFUN chmode () nil)
(DEFUN markon () nil)
(DEFUN markoff() nil)
(DEFUN toolup () nil)
(DEFUN tooldown () nil)
(DEFUN rewind () nil)
(DEFUN rotax () (IF (NOT rotaxwarning) (SETQ rotaxwarning (ALERT "Warning!\nNo ROTAX function defined"))))
(DEFUN stop () (WRITE (IF $cond "M01" "M00")))
(DEFUN units (value) value)
(DEFUN NameTrim (name) (FILE-NAMEONLY name T))
(DEFUN $hold () (HOLD))
(DEFUN hold() nil)
(DEFUN $unhold () (UNHOLD))
(DEFUN unhold () nil)
(DEFUN truehole () nil)
(DEFUN mrapid () nil)
(DEFUN footer() nil)
(DEFUN final () nil)
(DEFUN flyctrl () nil)
(DEFUN pumponoff () (SETQ pp_oldbar nil))
(DEFUN line3D () (LINE))

(DEFUN delay (value)
  (IF (AND (NUMBERP value) (> value 0.1)) (SIM-DELAY value))
)

(DEFUN $rewind (allrot)
  (DEFAXIS pp_oldpos allrot)
  (SIM-IAIP nil)
  (SIM-OFF)
  (IF (= *Processmode* 4) (SIM-INFOTEXT ""))
  (SETQ tid (MAX (/ (ABS $arel) *HeadPrimaryMaxSpeed*) (/ (ABS $brel) *HeadSecondaryMaxSpeed*)))
  (SIM3D-TILT (- (CAR allrot)) (- (CADR allrot)) $arel $brel)
  (SETQ $time (IF (= *MachineType* 0) *AWJDelayAfterPiercing* *WaterDelayAfterPiercing*))
  (REWIND)
  (IF $angleIpo (SIM-IAIP T))
  (SIM-ON T pp_oldfeed)
  (IF (= *Processmode* 4) (SIM-INFOTEXT ""))
  (SETQ pp_oldrot allrot)
)

(DEFUN onetobit (nr / bit)
  (SETQ bit 1)
  (REPEAT (1- nr) (SETQ bit (* bit 2)))
  (EVAL bit)
)

(DEFUN EXTRAINFO (label val)
 (IF (NOT (= (TYPE label) "STR")) (ALERT "Label is not a string"))
 (SETQ extrainfolist (CONS (LIST label val) extrainfolist))
)



(DEFUN options (caption varname default / value) ; string string default
  (COND
    ((= (TYPE default) "REAL") nil)
    (T (SETQ default (IF default 2 1)))
  )  
  (IF (NOT (= (TYPE caption) "STR")) (ALERT "In Options first argument must be a string"))
  (IF (NOT (= (TYPE varname) "STR")) (ALERT "In Options second argument must be a string"))
  (SETQ value (UC-GET (STRCAT "UserOptions" *MachineName*) (STRCASE varname) default))
  (SET (READ varname) value)
  (COND
    ((= (TYPE default) "REAL")
      (SETQ pp_outlist-reals (CONS (LIST caption varname value) pp_outlist-reals)))
    (T 
      (SETQ pp_outlist (CONS (LIST caption (READ varname)) pp_outlist)))
  )
)  

(DEFUN options-save (/ varname value)
  (FOREACH s pp_outlist
    (SETQ varname (CADR s))
    (SETQ value (IF (EVAL (CADR s)) 2 1))
    (UC-SET (STRCAT "UserOptions" *MachineName*) (STRCASE (TOSTR varname)) value)
  )
  (FOREACH s pp_outlist-reals
    (SETQ varname (CADR s))
    (SETQ value (EVAL (READ (CADR s))))
    (UC-SET (STRCAT "UserOptions" *MachineName*) (STRCASE (TOSTR varname)) value)
  )  
)

(DEFUN cam-sheetgeom (/ translist allreals subpoints s subreals bulg)
  (SETQ translist (CAM-SHEETGEOMRAW))
  (SETQ allreals nil)
  (FOREACH subpoints translist
    (FOREACH s subpoints
      (DEFAXIS s (LIST 0 0 0))
      (SETQ bulg (IF (MEMBER *AxisDirection* (LIST 1 2 4 7)) (- (CADDR s)) (CADDR s)))
      (SETQ subreals (CONS $x subreals))
      (SETQ subreals (CONS $y subreals))
      (SETQ subreals (CONS bulg subreals))
    )
    (SETQ allreals (CONS (REVERSE subreals) allreals))
    (SETQ subreals nil)
  )
  (SETQ allreals (REVERSE allreals))
)

(DEFUN cam-partgeom (id / translist allreals subpoints s subreals bulg)
  (SETQ translist (CAM-PARTGEOMRAW id))
  (SETQ allreals nil)
  (FOREACH subpoints translist
    (FOREACH s subpoints
      (DEFAXIS s (LIST 0 0 0))
      (SETQ bulg (IF (MEMBER *AxisDirection* (LIST 1 2 4 7)) (- (CADDR s)) (CADDR s)))
      (SETQ subreals (CONS $x subreals))
      (SETQ subreals (CONS $y subreals))
      (SETQ subreals (CONS bulg subreals))
    )
    (SETQ allreals (CONS (REVERSE subreals) allreals))
    (SETQ subreals nil)
  )
  (SETQ allreals (REVERSE allreals))
)

;(LOAD (STRCAT (GETVAR "PATHROOT") "LSP/IGEMS2B.LSP") (ALERT (STRCAT "CAN'T LOAD " (GETVAR "PATHROOT") "LSP/IGEMS2B.LSP")))
(PRINC "..IGEMS2.LSP is loaded OK\n")