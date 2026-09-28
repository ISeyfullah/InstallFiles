(DEFUN OB-GREP (path pattern substring)
    (SETQ lst (FILE-FINDALL path pattern T))
"    (SETQ result ())
    (FOREACH file lst
        (SETQ content (OB-READFILE file))
        (IF (OB-CONTAINS content substring)
            (SETQ result (CONS file result)))
    result))"
    lst)

(DEFUN OB-READFILE (path)
    (SETQ content "")
    (SETQ file (OPEN path "r"))
    (WHILE (SETQ line (READ-LINE file))
        (SETQ content (STRCAT content line "\n")))
    (CLOSE file)
    content)

(DEFUN OB-WRITEFILE (path content)
    (SETQ file (OPEN path "w"))
    (WRITE-LINE content file)
    (CLOSE file))

(DEFUN OB-CONTAINS (parent child)
    (SETQ parentupper (STRCASE parent))
    (SETQ childupper (STRCASE child))
    (SEARCH childupper parentupper))