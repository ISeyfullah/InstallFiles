(setq images (list (GP-IMAGE "fish.png") (GP-IMAGE "duck.png") (GP-IMAGE "lion.png") (GP-IMAGE "rabbit.png") (GP-IMAGE "shark.png")))
(setq imageindex 0)
(setq i:close (GP-IMAGE "close.png"))


(defun closeclick(sender)
    (GP-CLOSE dlg "")
)

(defun nextanimal(sender)
    (setq imageindex (+ imageindex 1))
    (if (>= imageindex (length images)) (setq imageindex 0))
    (GP-SETQ b:animal IMAGE (nth imageindex images))
)


(setq dlg (GP-DIALOG "Animal demo"))
(GP-LABEL dlg "Click on animal!" ALIGN GPC-CENTER EXPANDX nil)
(setq b:animal (GP-BUTTON dlg "" IMAGE (nth 0 images) FLAT T ACTION nextanimal))
(setq btn (GP-BUTTON dlg "Close" IMAGE i:close ACTION closeclick))



(GP-SHOWMODAL dlg)


