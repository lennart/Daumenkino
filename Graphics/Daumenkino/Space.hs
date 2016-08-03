module Graphics.Daumenkino.Space where

import Data.Ratio

import Control.Applicative

import Sound.Tidal.Pattern
import Sound.Tidal.Time

import Sound.Tidal.Stream ((#))

import Graphics.Daumenkino.Params (x,y,z)

type Point = (Double,Double,Double)
type Eye = (Point, Point)

type Volume a = (Eye, Eye, a)

type PatternTransformer a b = Pattern a -> Pattern b
type PatternT2 a b = (PatternTransformer a b, PatternTransformer a b)
--data Space a = Space { eye :: Eye -> [Volume a] }

-- type Time = Double
-- type Arc = (Time,Time)

-- type Event a = (Arc, Arc, a)

-- data Pattern a = Pattern { arc :: Arc -> [Event a] }

-- the generalization on the accessor (Arc/Eye):

type Dir a = (a,a)

type Obj a b = (Dir a, Dir a, b)

data O a b = O { dir :: Dir a -> [Obj a b] }

-- in these terms:

-- type Pattern' a = O Time

type Space a = O Point

-- but, this cannot be easily changed in Tidal, as this would prune the `Pattern` data constructor since it is just a type synonym now.

-- sooo, just do this with the generalization here and do not use `Pattern`



-- instance Functor (O (Double,Double,Double)) where
--   fmap f o = _

  -- no this will not work... maybe this is the wrong track

-- again:

-- x,y,z are the underlying axes for `Space`, just like time is the underlying axis for `Pattern`
-- in order to _hopefully easily_ describe a `Space`, patterns themselv only allow specifying one dimension, e.g.:

-- draw "cube ring knot" "hex" "tri"

-- should produce a `Space` of 9 elements each with 3d coordinates (xyz)

{-

y z       
|/_x      

c+h+t r+h+t k+h+t
-- i cannot draw like this... this is what I am programming this for ;)
-}


-- accepts three patterns for placement of elements in each of the three axes
-- returns a function that produces patterns from an arc
-- arc is interpreted as


{-
(a b c) x (d e f) = stack ((a,d) bd cd
                     ae be ce
                     af bf cf)


-}

join :: Pattern (a, a) -> PatternT2 a b -> Pattern (b,b)
join pv (ax,ay) = pair ((ax pvx),(ay pvy))
  where
    (pvx,pvy) = unpair pv

tesselate :: Integer -> Pattern a -> [Pattern a]
tesselate tes a = map excerpt zipped
  where
    zipped = zip [a] [0..tes]
    excerpt (a', i) = zoom (i%tes,(i+1)%tes) $ a'


pair :: (Pattern a, Pattern a) -> Pattern (a,a)
pair (a,b) = liftA2 (,) a b 

unpair :: Pattern (a,a) -> (Pattern a, Pattern a)
unpair pt = (liftA fst pt, liftA snd pt)
  
expand :: [Pattern a] -> [Pattern a] -> Pattern (a,a)
expand a b = cat pairpats
  where
    pairpats = map (pair) ppairs
    ppairs = zip a b



draw :: Integer -> PatternT2 a b -> Pattern a -> Pattern a -> Pattern (b,b)
draw tes (ax, ay) x y = join (expand x' y') (ax,ay)
  where
    x' = tesselate tes x
    y' = tesselate tes y


 
