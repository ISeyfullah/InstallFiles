(SETQ pol (POLAR (LIST 0 0 0) (/ (* (- 90 30.0) PI) 180.0) 1))
(majax '(0 0 0) '(0 0 1))   ; rotate around TCP
(minax '(0 0 0) '(0.5591929 0  0.82903757))


;colors used in this model
(setq gray '(0.5 0.5 0.7))
(setq dkgray '(0.2 0.2 0.3))
(setq ltgray '(0.7 0.7 0.7))
(setq ltblue '(0.5 0.5 0.9))

(unit "1" UF-NONE dkgray)
(unit "2" UF-MAJOR ltgray)
(unit "3" UF-MINOR gray)
(unit "JET" (+ UF-MINOR UF-CUTON) ltblue)
