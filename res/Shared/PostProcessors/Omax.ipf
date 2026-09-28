(SETQ *postinit* 1269)

(IF bevel ;Bevel is a flag set in IGEMS2.lsp $initialize method. It decides which post processor to load.
  (LOAD (STRCAT (GETVAR "PATHSHARED") "PostProcessors/Omax-3D_encrypted.ipf"))
  (LOAD (STRCAT (GETVAR "PATHSHARED") "PostProcessors/Omax-2D_encrypted.ipf")))