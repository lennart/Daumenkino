module Graphics.Daumenkino.Prim where

import Sound.Tidal.Transition
import Sound.Tidal.Time
import Sound.Tidal.Stream
import Sound.Tidal.OscStream
import Control.Concurrent.MVar

import Graphics.Daumenkino.Params

primShape :: Shape
primShape = Shape {

  params = [
    x_p,
    y_p
    ],
  cpsStamp = True,
  latency = 0.04
  }

primSlang :: OscSlang
primSlang = OscSlang {
  path="/prim",
  namedParams = False,
  timestamp = MessageStamp,    
  preamble = [
             ]
  }

primBackend :: IO (Backend a)
primBackend = do
  s <- makeConnection "127.0.0.1" 12345 primSlang
  return $ Backend s (\_ _ _ -> return ())

primState :: IO (MVar (ParamPattern, [ParamPattern]))
primState = do
  backend <- primBackend
  Sound.Tidal.Stream.state backend primShape

primSetters :: IO Time -> IO (ParamPattern -> IO (), (Time -> [ParamPattern] -> ParamPattern) -> ParamPattern -> IO ())
primSetters getNow = do ss <- primState
                        return (setter ss, transition getNow ss)

