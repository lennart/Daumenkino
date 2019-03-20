module Graphics.Daumenkino.Params where

import Sound.Tidal.Params (pI, pF, pS)

style name = pS name

ctx = pS "ctx"
tag = pS "tag"
text = pS "text"
order = pI "order"
rows = pI "rows"
cols = pI "cols"

red = pF "red"
green = pF "green"
blue = pF "blue"

alpha = pF "alpha"

x = pF "x"
y = pF "y"
z = pF "z"
w = pF "w"

width = pF "width"
height = pF "height"

srcblend = pS "srcblend"
blend = pS "blend"
blendeq = pS "blendeq"

level = pI "level"

rot_x = pF "rot_x"
rot_y = pI "rot_y"
rot_z = pI "rot_z"

origin_x = pI "origin_x"
origin_y = pI "origin_y"
origin_z = pI "origin_z"
