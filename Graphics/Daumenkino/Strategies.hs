module Graphics.Daumenkino.Strategies where

import Sound.Tidal.Pattern
import Sound.Tidal.Time
import Sound.Tidal.Stream
import Sound.Tidal.Params (n, grp)
import Graphics.Daumenkino.Params


siz :: Pattern String -> ParamPattern
siz = grp [width_p,height_p,depth_p]


-- if used twice , this will always override `n`




space :: Time -> (Pattern Double -> ParamPattern) -> Pattern String -> ParamPattern
space t p_p x' = stack $
  map (\(s,_,_) ->
         p_p (pure $ realToFrac $ fst s)) $ arc x' (0,t)
