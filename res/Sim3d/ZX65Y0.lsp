(SETQ pol (POLAR (LIST 0 0 0) (/ (* (- 90 65.0) PI) 180.0) 1))
(majax '(0 0 0) '(  (CAR pol) 0 (CADR pol)))


(minax '(0 0 0) '(0 1 0))   ; IHEAD can rotate around its TCP
(minax2 '(160.89 0 97.64) '(0 1 0))
(minax3 '(124.88 0 80.85) '(0 1 0))



;colors used in this model
(setq gray '(0.8 0.8 0.8))
(setq dkgray '(0.7 0.7 0.7))
(setq black '(0 0 0))
(setq ltblue '(0.5 0.5 0.9))


(unit "1" UF-MINOR dkgray)
(unit "2" UF-NONE dkgray)
(unit "3" UF-MAJOR gray)
(unit "4" UF-MINOR2 gray)
(unit "5" UF-MINOR3 gray)
(unit "6" (+ UF-POSROT UF-MINOR2) '(132.84 0 174.70) gray)
(unit "7" (+ UF-POSROT UF-MINOR2) '(110.02 0 223.63) gray)
(unit "JET" (+ UF-MINOR UF-CUTON) ltblue) ;water
(unit "9" UF-NONE black) ;packbox



