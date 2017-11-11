module Graphics.Daumenkino.Shader where

import Data.Ratio
import Sound.Tidal.Transition
import Sound.Tidal.Stream
import Sound.Tidal.OscStream
import Sound.Tidal.Params (speed_p, dur_p)
import Sound.Tidal.Parse (p,ColourD)
import Sound.Tidal.Pattern (Pattern, stack, zoom, density, sliceArc, slow, (<~))

import Data.Colour.SRGB

import Graphics.Daumenkino.Params

shaderSlang = OscSlang {
  path = "/shader",
  timestamp = MessageStamp,
  namedParams = True,
  preamble = []
  }

shaderShape :: Shape
shaderShape = Shape {
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
    level_p
    ],
  cpsStamp = True,
  latency = 0.3
  }

shaderBackend port = do
  s <- makeConnection "127.0.0.1" port shaderSlang
  return $ Backend s (\_ _ _ -> return ())

shaderState port = do
  backend <- shaderBackend port
  Sound.Tidal.Stream.state backend shaderShape

shaderSetters getNow = do ds <- shaderState 7772
                          return (setter ds, transition getNow ds)



color' :: String -> (Double, Double, Double)
color' s =
  let c = toSRGB $ sRGB24read s
  in (channelRed c, channelGreen c, channelBlue c)

color :: Pattern ColourD -> ParamPattern
color s = red (channelRed.toSRGB <$> s) |+| green (channelGreen.toSRGB <$> s) |+| blue (channelBlue.toSRGB <$> s)

size :: Pattern Double -> ParamPattern
size s = width s # height s
