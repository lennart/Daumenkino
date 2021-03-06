(defun daumenkino-start-haskell ()
  "Start haskell."
  (interactive)
  (if (comint-check-proc tidal-buffer)
      (error "A tidal/daumenkino process is already running")
    (apply
     'make-comint
     "tidal"
     tidal-interpreter
     nil
     tidal-interpreter-arguments)
    (tidal-see-output))
  (tidal-send-string ":set prompt \"\"")
  (tidal-send-string "import Sound.Tidal.Context")
  (tidal-send-string "import Graphics.Daumenkino.Context")
  (tidal-send-string ":set prompt \"\"")
  (tidal-send-string "(cps, getNow) <- cpsUtils")
  (tidal-send-string "(d1,t1) <- dirtSetters getNow")
  (tidal-send-string "(d2,t2) <- dirtSetters getNow")
  (tidal-send-string "(s1, st1) <- shaderSetters getNow")
  (tidal-send-string "(s2, st2) <- shaderSetters getNow")
  (tidal-send-string "(s3, st3) <- shaderSetters getNow")
  (tidal-send-string "(s4, st4) <- shaderSetters getNow")
  (tidal-send-string "(s5, st5) <- shaderSetters getNow")


  (tidal-send-string "let bps x = cps (x/2)")
  (tidal-send-string "let hush = mapM_ ($ silence) [s1,s2,s3,s4,s5,d1,d2]")
  (tidal-send-string "let solo = (>>) hush")
  (tidal-send-string ":set prompt \"tidal> \"")
)


(provide 'daumenkino)
