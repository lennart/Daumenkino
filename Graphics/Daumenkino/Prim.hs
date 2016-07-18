module Graphics.Daumenkino.Prim where

import Sound.Tidal.Transition
import Sound.Tidal.Time
import Sound.Tidal.Stream
import Sound.Tidal.OscStream
import Control.Concurrent.MVar

import Sound.Tidal.Params (s_p, n_p, dur_p)
import Graphics.Daumenkino.Params

primShape :: Shape
primShape = Shape {

  params = [
    s_p,
    n_p,
    dur_p,
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

primBackend :: String -> Int -> IO (Backend a)
primBackend host port = do
  s <- makeConnection host port primSlang
  return $ Backend s (\_ _ _ -> return ())

primState :: String -> Int -> IO (MVar (ParamPattern, [ParamPattern]))
primState host port = do
  backend <- primBackend host port
  Sound.Tidal.Stream.state backend primShape

primSetters :: IO Time -> IO (ParamPattern -> IO (), (Time -> [ParamPattern] -> ParamPattern) -> ParamPattern -> IO ())
primSetters getNow = do ss <- primState "127.0.0.1" 12345 
                        return (setter ss, transition getNow ss)


primSetters' :: String -> Int -> IO Time -> IO (ParamPattern -> IO (), (Time -> [ParamPattern] -> ParamPattern) -> ParamPattern -> IO ())
primSetters' host port getNow = do ss <- primState host port
                                   return (setter ss, transition getNow ss)
