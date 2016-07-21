module Graphics.Daumenkino.Strategies where

import Sound.Tidal.Pattern
import Sound.Tidal.Time
import Sound.Tidal.Stream
import Sound.Tidal.Params (n)
import Graphics.Daumenkino.Params

space :: Time -> (Pattern Double -> ParamPattern) -> Pattern String -> ParamPattern
space t p_p x' = stack $
  map (\(i, (s,_,_)) ->
         p_p (pure $ realToFrac $ fst s) # n (pure i)) $ zip [0..] (arc x' (0,t))
