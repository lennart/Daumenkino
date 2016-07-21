module Graphics.Daumenkino.Strategies where

import Sound.Tidal.Pattern
import Sound.Tidal.Time
import Sound.Tidal.Stream
import Graphics.Daumenkino.Params

space :: Time -> Time -> Time -> ParamPattern -> ParamPattern -> ParamPattern -> ParamPattern
space w h d x' y' z' = stack $ map (\(s,_,_) -> x' # x (pure $ realToFrac $ fst s)) (arc x' (0,w))
