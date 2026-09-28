(SETQ dlg (GP-DIALOG "Radio demo" VERTICAL nil))
(SETQ row1 (GP-COLUMN dlg))
(GP-RADIO row1 "Alfa")
(GP-RADIO row1 "Beta")
(GP-RADIO row1 "Gamma")

(SETQ row2 (GP-COLUMN dlg))
(GP-RADIO row2 "Red")
(GP-RADIO row2 "Green")
(GP-RADIO row2 "Blue")

(GP-TOGGLE dlg "Disabled" ACTION (lambda (s) (GP-SETQ row1 ENABLED (not (GP-GETQ s VALUE)))))

(GP-SHOWMODAL dlg)


