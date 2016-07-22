module Graphics.Daumenkino.Params where

import Sound.Tidal.Params (make', pI, pF, pS)
import Sound.Tidal.Stream
import Sound.Tidal.Pattern
import qualified Data.Map as Map

(shader, shader_p) = pS "shader" Nothing

(red, red_p) = pF "red" (Just 1)
(green, green_p) = pF "green" (Just 1)
(blue, blue_p) = pF "blue" (Just 1)

(alpha, alpha_p) = pF "alpha" (Just 1)

(x, x_p) = pF "x" (Just 0.5)
(y, y_p) = pF "y" (Just 0.5)
(z, z_p) = pF "z" (Just 0)
(w, w_p) = pF "w" (Just 1)

(width, width_p) = pF "width" (Just 1)
(height, height_p) = pF "height" (Just 1)
(depth, depth_p) = pF "depth" (Just 1)

(srcblend, srcblend_p) = pS "srcblend" (Just "a")
(blend, blend_p) = pS "blend" (Just "x")
(blendeq, blendeq_p) = pS "blendeq" (Just "a")

(level, level_p) = pI "level" (Just 0)

(rot_x, rot_x_p) = pF "rot_x" (Just 0)
(rot_y, rot_y_p) = pF "rot_y" (Just 0)
(rot_z, rot_z_p) = pF "rot_z" (Just 0)

(origin_x, origin_x_p) = pI "origin_x" (Just 0)
(origin_y, origin_y_p) = pI "origin_y" (Just 0)
(origin_z, origin_z_p) = pI "origin_z" (Just 0)

