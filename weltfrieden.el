(defun weltfrieden-start-haskell ()
  "Start haskell."
  (interactive)
  (if (comint-check-proc tidal-buffer)
      (error "A tidal/weltfrieden process is already running")
    (apply
     'make-comint
     "tidal"
     tidal-interpreter
     nil
     tidal-interpreter-arguments)
    (tidal-see-output))
  (tidal-send-string ":set prompt \"\"")
  (tidal-send-string "import Sound.Tidal.Context")
  (tidal-send-string "import Graphics.Weltfrieden.Context")
  (tidal-send-string ":set prompt \"\"")
  (tidal-send-string "(cps, getNow) <- cpsUtils")
  (tidal-send-string "(d1,t1) <- dirtSetters getNow")
  (tidal-send-string "(d2,t2) <- dirtSetters getNow")
  (tidal-send-string "(s1, st1) <- shaderSetters getNow")

  (tidal-send-string "let bps x = cps (x/2)")
  (tidal-send-string "let hush = mapM_ ($ silence) [s1,d1,d2]")
  (tidal-send-string "let solo = (>>) hush")
  (tidal-send-string ":set prompt \"tidal> \"")
)


(provide 'weltfrieden)
