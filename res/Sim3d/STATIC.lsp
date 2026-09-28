
; This special head does not rotate, but we still need to define axes
; which is in this case aribityrary
(majax '(0 0 0) '(0 0 1))
(minax '(0 0 0) '(0 1 0))

;colors used in this model
(setq gray '(0.5 0.5 0.7))
(setq ltblue '(0.5 0.5 0.9))

(unit "1" (+ UF-NONE UF-NOCOLLISION) gray)
(unit "JET" UF-CUTON ltblue)

