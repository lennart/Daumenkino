module Graphics.Weltfrieden.Text where

import Sound.Tidal.Transition
import Sound.Tidal.Stream
import Sound.Tidal.Params (speed_p)

import Graphics.Weltfrieden.Params

textShape :: OscShape
textShape = OscShape {
  path="/text",
  params = [
    dur_p,
    txt_p,
    red_p,
    green_p,
    blue_p,
    alpha_p,
    x_p,
    y_p,
    z_p,
    w_p,
    speed_p,
    blend_p,
    level_p
    ],
  cpsStamp = True,
  timestamp = MessageStamp,
  latency = 0.04,
  namedParams = False,
  preamble = [
             ]
  }


textState = state "127.0.0.1" 7772 textShape
textSetters getNow = do ts <- textState
                        return (setter ts, transition getNow ts)
