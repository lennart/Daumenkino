module Graphics.Daumenkino.XKCD where

import Sound.Tidal.Context
import Graphics.Daumenkino.Colors

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
