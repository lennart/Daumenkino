module Graphics.Weltfrieden.Params where

import Sound.Tidal.Params (make')
import Sound.Tidal.Stream
import Sound.Tidal.Pattern
import Sound.OSC.FD
import Sound.OSC.Datum
import Data.Map as Map

shader :: Pattern String -> OscPattern
shader = make' string shader_p
shader_p = S "shader" Nothing

txt :: Pattern String -> OscPattern
txt = make' string txt_p
txt_p = S "txt" Nothing

dur :: Pattern Double -> OscPattern
dur = make' float dur_p
dur_p = F "dur" (Just 0.25)

red :: Pattern Double -> OscPattern
red = make' float red_p
red_p = F "red" (Just 1)

green :: Pattern Double -> OscPattern
green = make' float green_p
green_p = F "green" (Just 1)

blue :: Pattern Double -> OscPattern
blue = make' float blue_p
blue_p = F "blue" (Just 1)

alpha :: Pattern Double -> OscPattern
alpha = make' float alpha_p
alpha_p = F "alpha" (Just 1)

x :: Pattern Double -> OscPattern
x = make' float x_p
x_p = F "x" (Just 0)

y :: Pattern Double -> OscPattern
y = make' float y_p
y_p = F "y" (Just 0)

z :: Pattern Double -> OscPattern
z = make' float z_p
z_p = F "z" (Just 0)

w :: Pattern Double -> OscPattern
w = make' float w_p
w_p = F "w" (Just 1)

size :: Pattern Double -> OscPattern
size = make' float size_p
size_p = F "size" (Just 1)

blend :: Pattern String -> OscPattern
blend = make' string blend_p
blend_p = S "blend" (Just "x")
