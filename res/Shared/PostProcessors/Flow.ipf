(SETQ *postinit* 1278)

(IF bevel ;Bevel is a flag set in IGEMS2.lsp $initialize method. It decides which post processor to load.
  (LOAD (STRCAT (GETVAR "PATHSHARED") "PostProcessors/FlowMaster-7_encrypted.ipf"))
  (LOAD (STRCAT (GETVAR "PATHSHARED") "PostProcessors/FlowMaster-6_encrypted.ipf")))