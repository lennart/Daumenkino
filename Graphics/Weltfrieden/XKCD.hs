module Graphics.Weltfrieden.XKCD where

import Sound.Tidal.Context
import Graphics.Weltfrieden.Colors
-- (cps, getNow) <- cpsUtils
-- (d1,t1) <- dirtSetters getNow
-- (d2,t2) <- dirtSetters getNow
-- (s1, st1) <- shaderSetters getNow

-- let bps x = cps (x/2)
-- let hush = mapM_ ($ silence) [s1,d1,d2]
-- let solo = (>>) hush

-- colorAt colors 1999

-- colorForName colors (samples "mustard" (run 3))




patForCount patterns i = patterns !! ((i - 1) `mod` (length patterns))

f1 file patterns c = do
  l <- colorPairs file
  let chex = colorForName l
      count = fromIntegral $ syllableCountForName l c
      pat = patForCount patterns count
      pr = preplace (1,1) pat
  return (
    pr (samples ((density $ toRational count) $ p c) (run $ count)),
    chex <$> (pr (p c)),
    pr
    )
