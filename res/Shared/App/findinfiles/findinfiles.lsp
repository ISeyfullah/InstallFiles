(SETQ dlg (GP-DIALOG "Find in files"))

(DEFUN OB-EDIT (parent caption value / row)
    (SETQ row (GP-ROW parent))
    (GP-LABEL row caption EXPANDX T)
    (GP-EDIT row VALUE value WIDTH 150))

(SETQ e:path (OB-EDIT dlg "Path" "C:\\prj\\svn\\GEMS_RX\\src"))
(SETQ e:pattern (OB-EDIT dlg "File pattern" "*.cs"))
(SETQ e:substring (OB-EDIT dlg "Containing" "class"))

(GP-FILL dlg HEIGHT 10)
(SETQ row (GP-ROW dlg CHILDUNIFORMW T ALIGN GPC-CENTER))
(GP-BUTTON row "OK" RESPONSE "OK" DEFAULT T)
(GP-BUTTON row "Cancel" RESPONSE "")

(LOAD "engine.lsp")

;(GP-MESSAGE "test" (OB-READFILE "C:\\temp\\buildlog.txt"))

(SETQ result (GP-SHOWMODAL dlg))
(IF (= result "OK") (PROGN
    (SETQ path (GP-GETQ e:path VALUE))
    (SETQ pattern (GP-GETQ e:pattern VALUE))
    (SETQ substring (GP-GETQ e:substring VALUE))
    
    (SETQ filelst (OB-GREP path pattern substring))

    (SETQ resultdlg (GP-DIALOG "Found files" RESIZABLE T))
    
    (GP-LISTBOX resultdlg filelst WIDTH 400 HEIGHT 500)
    (SETQ row (GP-ROW resultdlg ALIGN GPC-CENTER))
    (GP-BUTTON row "Notepad" RESPONSE "NOTEPAD")
    (GP-BUTTON row "Close" RESPONSE "")

    (SETQ result (GP-SHOWMODAL resultdlg))
    (IF (= result "NOTEPAD") (PROGN
        (PRINC "notepad!")
        (SETQ content "")
        (FOREACH file filelst
            (SETQ content (STRCAT content "\n" file)))
        (SETQ tempfile "C:/temp/filelist.txt")
        (OB-WRITEFILE tempfile content)
        (STARTAPP "notepad.exe" tempfile)))))
(QUIT)

    
