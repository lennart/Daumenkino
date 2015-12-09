module Graphics.Daumenkino.Params where

import Sound.Tidal.Params (make')
import Sound.Tidal.Stream
import Sound.Tidal.Pattern
import Sound.OSC.FD
import Sound.OSC.Datum
import Data.Map as Map

shader :: Pattern String -> OscPattern
shader = make' string shader_p
shader_p = S "shader" Nothing

dur :: Pattern Double -> OscPattern
dur = make' float dur_p
dur_p = F "dur" (Just 1)

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
x_p = F "x" (Just 0.5)

y :: Pattern Double -> OscPattern
y = make' float y_p
y_p = F "y" (Just 0.5)

z :: Pattern Double -> OscPattern
z = make' float z_p
z_p = F "z" (Just 0)

w :: Pattern Double -> OscPattern
w = make' float w_p
w_p = F "w" (Just 1)

width :: Pattern Double -> OscPattern
width = make' float width_p
width_p = F "width" (Just 1)

height :: Pattern Double -> OscPattern
height = make' float height_p
height_p = F "height" (Just 1)

srcblend :: Pattern String -> OscPattern
srcblend = make' string srcblend_p
srcblend_p = S "srcblend" (Just "a")

blend :: Pattern String -> OscPattern
blend = make' string blend_p
blend_p = S "blend" (Just "x")

blendeq :: Pattern String -> OscPattern
blendeq = make' string blendeq_p
blendeq_p = S "blendeq"  (Just "a")

level :: Pattern Int -> OscPattern
level = make' int32 level_p
level_p = I "level" (Just 0)

rot_x :: Pattern Double -> OscPattern
rot_x = make' float rot_x_p
rot_x_p = F "rot_x" (Just 0)

rot_y :: Pattern Double -> OscPattern
rot_y = make' float rot_y_p
rot_y_p = F "rot_y" (Just 0)

rot_z :: Pattern Double -> OscPattern
rot_z = make' float rot_z_p
rot_z_p = F "rot_z" (Just 0)

origin_x :: Pattern Double -> OscPattern
origin_x = make' float origin_x_p
origin_x_p = F "origin_x" (Just 0)

origin_y :: Pattern Double -> OscPattern
origin_y = make' float origin_y_p
origin_y_p = F "origin_y" (Just 0)

origin_z :: Pattern Double -> OscPattern
origin_z = make' float origin_z_p
origin_z_p = F "origin_z" (Just 0)
