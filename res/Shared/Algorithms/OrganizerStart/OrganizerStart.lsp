(SETQ targetfolder "C:/ERP/") ; Set this variable to the comunication folder
(DEFUN DateToList (datestr / year month day) ; The function convert a datestr example: "2015.3.15" to a list (2015 3 15)
  (SETQ year "" month "" day "" q 0)
  (FOREACH s datestr
    (COND
      ((= s ".") (SETQ q (1+ q)))
      ((= q 0) (SETQ year (STRCAT year s)))
      ((= q 1) (SETQ month (STRCAT month s)))
      ((= q 2) (SETQ day (STRCAT day s)))
    )
  )
  (LIST (ATOI year) (ATOI month) (ATOI day))
)


(IF (FILE-EXISTS (STRCAT targetfolder "ORGANIZERPRODUCE.TXT"))
  (PROGN
    (SETQ fr (OPEN (STRCAT targetfolder "ORGANIZERPRODUCE.TXT") "r"))
    (WHILE
      (SETQ txt (READ-LINE fr))
      (SETQ txtlist (READ (STRCAT "(" txt ")")))
      (SETQ id (CAR txtlist))
      (IF (SETQ name (NTH 1 txtlist)) (SQL-SET id "name" name))
      ; Se if there is a + or - sign
      (SETQ fnuts 0)
      (FOREACH tk name (IF (= tk (CHR 34)) (SETQ fnuts (1+ fnuts))))
      (SETQ tk (ASCII (STRTRIM (STRSUB txt (+ (STRLEN (ITOA id)) (STRLEN name) 4 fnuts)))))
      (SETQ absolut (IF (OR (= tk 43) (= tk 45)) nil T))
      (COND
        ((NOT (NTH 2 txtlist)) nil)
        (absolut
          (SETQ quantity (NTH 2 txtlist))
          (SQL-SET id "quantity" quantity)
          (SQL-SET id "remains" quantity)
          (SQL-SET id "produced" 0))
        ((NOT absolut)
          (SETQ addons (NTH 2 txtlist))
          (SQL-SET id "quantity" (+ (ATOI (SQL-GET id "quantity")) addons))
          (SQL-SET id "remains" (+ (ATOI (SQL-GET id "remains")) addons)))
      )
      (IF (SETQ datum (NTH 3 txtlist))
        (PROGN
          (SETQ datelist (DATETOLIST datum))
          (SQL-SET id "productiondate" (SQL-DATE datelist))))
      (IF (SETQ customer (NTH 4 txtlist)) (SQL-SET id "customer" customer))
      (IF (SETQ material (NTH 5 txtlist)) (SQL-SET id "material" material))
      (IF (SETQ alloy (NTH 6 txtlist)) (SQL-SET id "quality" alloy))
      (IF (SETQ thickness (NTH 7 txtlist)) (SQL-SET id "thickness" thickness))
    )
    (CLOSE fr)
    (FILE-DELETE (STRCAT (STRCAT targetfolder "ORGANIZERPRODUCE.TXT")))
  )
)
