module Graphics.Weltfrieden.Shader where

import Sound.Tidal.Transition
import Sound.Tidal.Stream
import Sound.Tidal.Params (speed_p)
import Sound.Tidal.Parse (p)
import Sound.Tidal.Pattern (Pattern)

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
    size_p,
    speed_p,
    blend_p,
    level_p,
    txt_p,
    fontsize_p
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

color' :: String -> (Double, Double, Double)
color' s =
  let c = toSRGB $ sRGB24read s
  in (channelRed c, channelGreen c, channelBlue c)

color :: String -> OscPattern
color s =
  let (r,g,b) = color' s
  in (red (p $ show r) |+| blue (p $ show g) |+| green (p $ show b))
