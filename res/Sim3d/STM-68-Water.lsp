(majax '(0 0 0) '(0 0 1))
(minax '(0 0 0) '(0.5592 0 0.829))

;colors used in this model
(setq gray '(0.5 0.5 0.5))
(setq dkgray '(0.3 0.3 0.3))
(setq ltgray '(0.7 0.7 0.7))
(setq ltblue '(0.5 0.5 0.9))

(unit "1" UF-NONE ltgray)
(unit "2" UF-MAJOR gray)
(unit "3" UF-MINOR dkgray)
(unit "JET" (+ UF-MINOR UF-CUTON) ltblue)