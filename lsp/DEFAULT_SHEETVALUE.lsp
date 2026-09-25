(SETQ weights (SHEET-INVENTORY))
(SETQ smallprice (* (CAR weights) *SHEET-COST* *SHEET-SMALL*))
(SETQ mediumprice (* (CADR weights) *SHEET-COST* *SHEET-MEDIUM*))
(SETQ largeprice (* (CADDR weights) *SHEET-COST* *SHEET-LARGE*))
(SETQ scrap (- *SHEET-WEIGHT* (+ (CAR weights) (CADR weights) (CADDR weights)))) ;fixed bug 2018.10.16
(SETQ scrapprice (* scrap *SHEET-COST* *SHEET-SCRAP*))
;(ALERT (STRCAT "WEIGHT:" (TOSTR *Sheet-weight*) " COST:" (TOSTR *sheet-cost*)))
(+ scrapprice smallprice mediumprice largeprice)


;AVAIABLE VARIABLES IN THIS SCRIPT
;*SHEET-WEIGHT* = Weight
;*SHEET-AREA* = Geometry.Area*1e-6;//m2
;*SHEET-DX* = Extents.Width
;*SHEET-DY* = Extents.Height
;*SHEET-ISRECTANGULAR*"= IsRectangular T or nil
;*SHEET-NAME* = Name
;*SHEET-INFO = Info
;*SHEET-REFERENCE* = Reference
;*SHEET-STORAGE* = Storage
;*SHEET-DENSITY* = mat.Density
;*SHEET-QUALITY* = mat.SelectedQuality.Name
;*SHEET-COST* = mat.SelectedQuality.Cost
;*SHEET-GROUP* = mat.Name
;*SHEET-THICKNESS* = mat.Thickness
;*SHEET-SMALLSIZE* = CamAPI.SystemVariables.SheetInventorySmall
;*SHEET-MEDIUMSIZE* = CamAPI.SystemVariables.SheetInventoryMedium;
;*SHEET-LARGESIZE* = CamAPI.SystemVariables.SheetInventoryLarge;

;*SHEET-SMALL* = Value factor from Inventory
;*SHEET-MEDIUM* = Value factor from Inventory
;*SHEET-LARGE* = Value factor from Inventory
;*SHEET-SCRAP* = Value factor from Inventory

