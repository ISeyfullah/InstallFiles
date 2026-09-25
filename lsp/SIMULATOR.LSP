;SIMULATOR.LSP
; DATE 2016.09.01

(IF ppp_sim1
  (PROGN
    (DEFUN wr (txt) (SETQ outtext (STRCAT outtext txt "\n")))
    (DEFUN rts (value) (RTOS value 4))
    (SETQ q 0)
    (SETQ totdiff 0)
    (SETQ outtext "")
    (DEFUN ppp_cuton (objlist)
      (SETQ oldp (LIST (CAR objlist) (CADR objlist) (CADDR objlist)))

    )

    (DEFUN ppp_line (objlist)
      (SETQ endp (LIST (CAR objlist) (CADR objlist) (CADDR objlist))) ; Startpoint of vector not the line
      (SETQ vec (NTH 7 objlist))
      (SETQ vecendp (LIST (+ (CAR endp) (CAR vec)) (+ (CADR endp) (CADR vec)) (+ (CADDR endp) (CADDR vec))))
      ;(IF (NOT oldp) (SETQ oldp endp))
      (IF (NOT oldvecendp) (SETQ oldvecendp vecendp))
      ;upper line
      (WR (STRCAT (RTS (CAR oldp)) " " (RTS (CADR oldp)) " " (RTS (CADDR oldp)) " " (RTS (CAR endp)) " " (RTS (CADR endp)) " " (RTS (CADDR endp)) " 1.0 7"))
      ; lower line
      (WR (STRCAT (RTS (CAR oldvecendp)) " " (RTS (CADR oldvecendp)) " " (RTS (CADDR oldvecendp)) " " (RTS (CAR vecendp)) " " (RTS (CADR vecendp)) " " (RTS (CADDR vecendp)) " 1.0 2"))
      ;vector
      (WR (STRCAT (RTS (CAR endp)) " " (RTS (CADR endp)) " " (RTS (CADDR endp)) " " (RTS (CAR vecendp)) " " (RTS (CADR vecendp)) " " (RTS (CADDR vecendp)) " 1.0 7"))
      (SETQ oldp endp oldvecendp vecendp)
    )
    (DEFUN ppp_rotax (objlist)
      (SETQ endp oldp)
      (SETQ vec (NTH 0 objlist))
      (SETQ vecendp (LIST (+ (CAR endp) (CAR vec)) (+ (CADR endp) (CADR vec)) (+ (CADDR endp) (CADDR vec))))
      (WR (STRCAT (RTS (CAR oldp)) " " (RTS (CADR oldp)) " " (RTS (CADDR oldp)) " " (RTS (CAR endp)) " " (RTS (CADR endp)) " " (RTS (CADDR endp)) " 1.0 7"))
      ; lower line
      (WR (STRCAT (RTS (CAR oldvecendp)) " " (RTS (CADR oldvecendp)) " " (RTS (CADDR oldvecendp)) " " (RTS (CAR vecendp)) " " (RTS (CADR vecendp)) " " (RTS (CADDR vecendp)) " 1.0 2"))
      ;vector
      (WR (STRCAT (RTS (CAR endp)) " " (RTS (CADR endp)) " " (RTS (CADDR endp)) " " (RTS (CAR vecendp)) " " (RTS (CADR vecendp)) " " (RTS (CADDR vecendp)) " 1.0 7"))
      (SETQ oldp endp oldvecendp vecendp))

    (DEFUN ppp_arc (objlist)
      (SETQ endp (LIST (CAR objlist) (CADR objlist) (CADDR objlist))) ; Startpoint of vector not the line
      (SETQ cen (LIST (NTH 3 objlist) (NTH 4 objlist)))
      (SETQ rad (DISTANCE cen endp))
      (SETQ corp (POLAR oldp (ANGLE oldp endp) (* (DISTANCE oldp endp) 0.5)))
      (SETQ mid (POLAR cen (ANGLE cen corp) rad))
      (SETQ vec (NTH 10 objlist))
      (SETQ vecendp (LIST (+ (CAR endp) (CAR vec)) (+ (CADR endp) (CADR vec)) (+ (CADDR endp) (CADDR vec))))
      (IF (NOT oldp) (SETQ oldp endp))
      (IF (NOT oldvecendp) (SETQ oldvecendp vecendp))
      ; upper arc
      (WR (STRCAT (RTS (CAR oldp)) " " (RTS (CADR oldp)) " " (RTS (CADDR oldp)) " "
                  (RTS (CAR mid)) " " (RTS (CADR mid)) " " (RTS (CADDR oldp)) " "
                  (RTS (CAR endp)) " " (RTS (CADR endp)) " " (RTS (CADDR endp)) " 1.0 7"))
      ; lower arc
      (SETQ rad2 (DISTANCE cen vecendp))
      (SETQ corp (POLAR oldvecendp (ANGLE oldvecendp vecendp) (* (DISTANCE oldvecendp vecendp) 0.5)))
      (SETQ mid (POLAR cen (ANGLE cen corp) rad2))
      (WR (STRCAT (RTS (CAR oldvecendp)) " " (RTS (CADR oldvecendp)) " " (RTS (CADDR oldvecendp)) " "
                  (RTS (CAR mid)) " " (RTS (CADR mid)) " " (RTS (CADDR oldvecendp)) " "
                  (RTS (CAR vecendp)) " " (RTS (CADR vecendp)) " " (RTS (CADDR vecendp)) " 1.0 2"))
      ; vector
      (WR (STRCAT (RTS (CAR endp)) " " (RTS (CADR endp)) " " (RTS (CADDR endp)) " " (RTS (CAR vecendp)) " " (RTS (CADR vecendp)) " " (RTS (CADDR vecendp)) " 1.0 7"))
      (SETQ oldp endp oldvecendp vecendp)
    )


    (DEFUN $main (/ skala)
      (SETQ ppp_list (CADR (CAR subprogs)))
      (FOREACH s ppp_list
        (COND
          ((= (CAR s) '$LINE) (PPP_LINE (CADR s)))
          ((= (CAR s) '$ARC) (PPP_ARC (CADR s)))
          ((= (CAR s) '$ROTAX) (PPP_ROTAX (CADR s)))
          ((= (CAR s) '$CUTON) (PPP_CUTON (CADR s)))
          (T (PRINC (CAR s)) (PRINC "\n"))
        )
      )
      (IF outtext (CLIP-SET outtext))
    )
  )
)

(IF ppp_sim2
  (PROGN
    (SETQ q 0)
    (SETQ totdiff 0)
    (DEFUN ppp_line (objlist)
      (SETQ stp (LIST (CAR objlist) (CADR objlist))) ; Startpoint of vector not the line
      (SETQ vec (NTH 7 objlist))
      (SETQ end (LIST (+ (CAR stp) (* (CAR vec) skala)) (+ (CADR stp) (* (CADR vec) skala))))
      (PRINC (STRCAT "Line " (TOSTR stp) " to " (TOSTR end) "\n"))
      (IF ppp_sim2txt (CAD-TEXT (ITOA (SETQ q (1+ q))) end 0.1 0 1 0 "ARIAL"))
      (CAD-LINE stp end)
    )
    (DEFUN ppp_arc (objlist)
      (SETQ stp (LIST (CAR objlist) (CADR objlist)))
      (SETQ vec (NTH 10 objlist))
      (SETQ end (LIST (+ (CAR stp) (* (CAR vec) skala)) (+ (CADR stp) (* (CADR vec) skala))))
      (PRINC (STRCAT "ARCLine " (TOSTR stp) " to " (TOSTR end) "\n"))
      (IF ppp_sim2txt (CAD-TEXT (ITOA (SETQ q (1+ q))) end 0.1 0 2 0 "ARIAL"))
      (CAD-LINE stp end)
    )
    (DEFUN ppp_cuton (objlist)
      (SETQ stp (LIST (CAR objlist) (CADR objlist)))
      (SETQ vec (NTH 20 objlist))
      (SETQ end (LIST (+ (CAR stp) (* (CAR vec) skala)) (+ (CADR stp) (* (CADR vec) skala))))
      (CAD-LINE stp end)
    )

    (DEFUN $main (/ skala)
      (SETQ skala 1.0)
      (SETQ ppp_list (CADR (CAR subprogs)))
      (FOREACH s ppp_list
        (COND
          ((= (CAR s) '$CUTON) (PPP_CUTON (CADR s)))
          ((= (CAR s) '$LINE) (PPP_LINE (CADR s)))
          ((= (CAR s) '$ARC) (PPP_ARC (CADR s)))
          (T (PRINC (CAR s)) (PRINC "\n"))
        )
      )
    )
  )
)

(IF ppp_sim3
  (PROGN
    (DEFUN ppp_line (objlist)
      (SETQ stp (LIST (CAR objlist) (CADR objlist))) ; Startpoint of vector not the line
      (SETQ dir (NTH 9 objlist))
      (SETQ len (DISTANCE (LIST 0 0) (NTH 7 objlist)))
      (SETQ end (POLAR stp dir len))
      (CAD-LINE stp end)
    )
    (DEFUN $main (/ skala)
      (SETQ skala 1.0)
      (SETQ ppp_list (CADR (CAR subprogs)))
      (FOREACH s ppp_list
        (COND
          ((= (CAR s) '$LINE) (PPP_LINE (CADR s)))
          (T (PRINC (CAR s)) (PRINC "\n"))
        )
      )
    )
  )
)