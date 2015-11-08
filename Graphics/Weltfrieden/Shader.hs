module Graphics.Weltfrieden.Shader where


import Data.Ratio
import Sound.Tidal.Transition
import Sound.Tidal.Stream
import Sound.Tidal.Params (speed_p)
import Sound.Tidal.Parse (p,ColourD)
import Sound.Tidal.Pattern (Pattern, stack, zoom, density, sliceArc, slow, (<~))

import Data.Colour.SRGB

import Graphics.Weltfrieden.Params

shaderShape :: OscShape
shaderShape = OscShape {
  path="/shader",
  params = [
    dur_p,
    shader_p,
    red_p,
    green_p,
    blue_p,
    alpha_p,
    x_p,
    y_p,
    z_p,
    w_p,
    rot_x_p,
    rot_y_p,
    rot_z_p,
    origin_x_p,
    origin_y_p,
    origin_z_p,
    width_p,
    height_p,
    speed_p,
    srcblend_p,
    blend_p,
    blendeq_p,
    level_p,
    txt_p,
    fontsize_p,
    char_p
    ],
  cpsStamp = True,
  timestamp = MessageStamp,
  latency = 0.04,
  namedParams = False,
  preamble = [
             ]
  }

shaderState = state "127.0.0.1" 7772 shaderShape
shaderSetters getNow = do ss <- shaderState
                          return (setter ss, transition getNow ss)




-- zoomer :: Ratio Integer -> Ratio Integer -> Pattern a -> Pattern a
-- zoomer i n = slow n . ((i'/n') <~) . sliceArc ( (i'/n'), (i'+1/n') )
--   where i' = i
--         n' = n

--layout :: OscPattern -> (OscPattern -> OscPattern) -> Int -> OscPattern -> OscPattern
-- place num g p1 p2 i =
--   zoomer i num $ (p2 (density num $ p1)) -- (square g i num))
--     where
--       square pat index count = pat (divider index count) # sizer (index) (count)
--       divider index count = (density num $ p $ show $ realToFrac ( (index/count) + (1/(count*2) ) ) )
--       sizer index count = size (density num $ p $ show $ realToFrac ( 1 / ( count + (1/count*count) ) ) )

-- layout p'' g num p' = stack (map (place num g p' p'') [0..(num-1)])


-- row' p'' num p' = layout p'' (x) num p'

-- col' p'' num p' = layout p'' (y) num p'

-- grid' p'' size = col' p'' size . row' p'' size



color' :: String -> (Double, Double, Double)
color' s =
  let c = toSRGB $ sRGB24read s
  in (channelRed c, channelGreen c, channelBlue c)

color :: Pattern ColourD -> OscPattern
color s = red (channelRed.toSRGB <$> s) |+| green (channelGreen.toSRGB <$> s) |+| blue (channelBlue.toSRGB <$> s)

size :: Pattern Double -> OscPattern
size s = width s # height s
