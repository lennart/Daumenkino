module Main (main) where

--------------------------------------------------------------------------------

import           Control.Concurrent.STM (TQueue, atomically, newTQueueIO, tryReadTQueue, writeTQueue, tryPeekTQueue, readTQueue)
import           Control.Concurrent
import           Control.Monad (unless, when, void, forever, join)
import           Control.Monad.RWS.Strict (RWST, ask, asks, evalRWST, get, liftIO, modify, put)
import           Control.Monad.Trans.Maybe (MaybeT(..), runMaybeT)
import           Control.Exception
import           Data.List (intercalate)
import           Data.Maybe (catMaybes, fromMaybe, fromJust)
import           Text.PrettyPrint

import           Foreign.Marshal.Array (withArray)
import           Foreign.Storable (sizeOf)
import           Foreign.Ptr (plusPtr, nullPtr, Ptr)

import           Linear.Quaternion
import           Linear.Matrix
import Linear.Vector (scaled)
import qualified Linear.V3 as LV3
import qualified Linear.V4 as LV4

import           Data.Time.Clock
import           Data.Time.Clock.POSIX
import           Sound.OSC.FD

import qualified Graphics.Rendering.OpenGL as GL

import qualified Graphics.UI.GLFW as GLFW

import           System.Environment (getEnv)

import qualified Data.Map.Strict as Map

import           NGL.LoadShaders
import           Gear (makeGear)

type LifeTime = Maybe Double
type V3 = (Double,Double,Double)
type V4 = (Double,Double,Double,Double)

type Tween = (V3,V3)
type Tween4 = (V4,V4)

data Easing = EaseIn | EaseOut | EaseInOut | Linear 

type FluxMap = [Flux]

data Flux = Flux {
  shape :: !GL.DisplayList,
  pos :: !Tween,
  siz :: !Tween,
  rot :: !Tween4,
  col :: !Tween,
  easing :: Easing,
  life :: !LifeTime,
  name :: !String,
  spawned :: UTCTime
  }

data FluxMessage = FluxMessage {
  fpos :: V3,
  fsiz :: V3,
  frot :: V4,
  fcol :: V3,
  flife :: Double,
  fname :: String,
  ftime :: UTCTime
                 }


data Descriptor = Descriptor GL.VertexArrayObject GL.ArrayIndex GL.NumArrayIndices
--------------------------------------------------------------------------------

data Env = Env
    { envEventsChan    :: TQueue Event
    , envOscEvents     :: TQueue Message
    , envWindow        :: !GLFW.Window
    , envZDistClosest  :: !Double
    , envZDistFarthest :: !Double
    , envTriDescriptor :: Descriptor
    , envProgram       :: GL.Program
    }

data State = State
    { stateWindowWidth     :: !Int
    , stateWindowHeight    :: !Int
    , stateFluxes          :: !FluxMap
    , stateXAngle          :: !Double
    , stateYAngle          :: !Double
    , stateZAngle          :: !Double
    , stateGearZAngle      :: !Double
    , stateZDist           :: !Double
    , stateMouseDown       :: !Bool
    , stateDragging        :: !Bool
    , stateDragStartX      :: !Double
    , stateDragStartY      :: !Double
    , stateDragStartXAngle :: !Double
    , stateDragStartYAngle :: !Double
    }

type Demo = RWST Env () State IO

--------------------------------------------------------------------------------

data Event =
    EventError           !GLFW.Error !String
  | EventWindowPos       !GLFW.Window !Int !Int
  | EventWindowSize      !GLFW.Window !Int !Int
  | EventWindowClose     !GLFW.Window
  | EventWindowRefresh   !GLFW.Window
  | EventWindowFocus     !GLFW.Window !GLFW.FocusState
  | EventWindowIconify   !GLFW.Window !GLFW.IconifyState
  | EventFramebufferSize !GLFW.Window !Int !Int
  | EventMouseButton     !GLFW.Window !GLFW.MouseButton !GLFW.MouseButtonState !GLFW.ModifierKeys
  | EventCursorPos       !GLFW.Window !Double !Double
  | EventCursorEnter     !GLFW.Window !GLFW.CursorState
  | EventScroll          !GLFW.Window !Double !Double
  | EventKey             !GLFW.Window !GLFW.Key !Int !GLFW.KeyState !GLFW.ModifierKeys
  | EventChar            !GLFW.Window !Char
  deriving Show

--------------------------------------------------------------------------------

triangle :: [GL.Vertex2 GL.GLfloat]
triangle = [
  GL.Vertex2 (-0.01) (-0.01),
  GL.Vertex2 0.01 (-0.01),
  GL.Vertex2 0 0.01
  ]

square :: [GL.Vertex2 GL.GLfloat]
square = [
  GL.Vertex2 (-0.9) (-0.9),
  GL.Vertex2 0.8 (-0.9),
  GL.Vertex2 (-0.9) 0.8,
  GL.Vertex2 (-0.85) 0.8,
  GL.Vertex2 0.8 (-0.9),
  GL.Vertex2 0.9 0.8
         ]

getEnvDefault :: String -> String -> IO String
getEnvDefault defValue var = do
  res <- try . getEnv $ var
  return $ either (const defValue) id (res :: Either IOException String)

getServerIp :: IO String
getServerIp = getEnvDefault "127.0.0.1" "DAUMENKINO_IP"

getServerPort :: IO Int
getServerPort = fmap read (getEnvDefault "23451" "DAUMENKINO_PORT")

queueOSC :: TQueue Message -> Maybe Message -> IO ()
queueOSC q = maybe (return ()) (atomically . writeTQueue q)

runOSCServer :: String -> Int -> TQueue Message -> IO ()
runOSCServer host port q = do
  putStrLn("Starting OSC Server at " ++ host ++ ":" ++ (show port))
  _ <- forkIO $ withTransport s (\fd -> forever (recvMessage fd >>= queueOSC q))
  return ()
    where
      s = udpServer host port

bufferOffset :: Integral a => a -> Ptr b
bufferOffset = plusPtr nullPtr . fromIntegral

main :: IO ()
main = do
    let width  = 640
        height = 480

    eventsChan <- newTQueueIO :: IO (TQueue Event)
    oscEvents <- newTQueueIO :: IO (TQueue Message)
    host <- getServerIp
    port <- getServerPort
    runOSCServer host port oscEvents
    withWindow width height "GLFW-b-demo" $ \win -> do
        GLFW.setErrorCallback               $ Just $ errorCallback           eventsChan
        GLFW.setWindowPosCallback       win $ Just $ windowPosCallback       eventsChan
        GLFW.setWindowSizeCallback      win $ Just $ windowSizeCallback      eventsChan
        GLFW.setWindowCloseCallback     win $ Just $ windowCloseCallback     eventsChan
        GLFW.setWindowRefreshCallback   win $ Just $ windowRefreshCallback   eventsChan
        GLFW.setWindowFocusCallback     win $ Just $ windowFocusCallback     eventsChan
        GLFW.setWindowIconifyCallback   win $ Just $ windowIconifyCallback   eventsChan
        GLFW.setFramebufferSizeCallback win $ Just $ framebufferSizeCallback eventsChan
        GLFW.setMouseButtonCallback     win $ Just $ mouseButtonCallback     eventsChan
        GLFW.setCursorPosCallback       win $ Just $ cursorPosCallback       eventsChan
        GLFW.setCursorEnterCallback     win $ Just $ cursorEnterCallback     eventsChan
        GLFW.setScrollCallback          win $ Just $ scrollCallback          eventsChan
        GLFW.setKeyCallback             win $ Just $ keyCallback             eventsChan
        GLFW.setCharCallback            win $ Just $ charCallback            eventsChan

        GLFW.swapInterval 1

        GL.position (GL.Light 0) GL.$= GL.Vertex4 5 5 10 0
        GL.light    (GL.Light 0) GL.$= GL.Enabled
        GL.lighting   GL.$= GL.Enabled
        GL.cullFace   GL.$= Just GL.Back
        GL.depthFunc  GL.$= Just GL.Less
        GL.clearColor GL.$= GL.Color4 0.05 0.05 0.05 1
        GL.normalize  GL.$= GL.Enabled

        (fbWidth, fbHeight) <- GLFW.getFramebufferSize win

        tri <- GL.genObjectName
                  
        GL.bindVertexArrayObject GL.$= Just tri

        let vs = triangle
            numVertices = length vs

        vertexBuffer <- GL.genObjectName
        GL.bindBuffer GL.ArrayBuffer GL.$= Just vertexBuffer
        withArray vs $ \ptr -> do
          let size = fromIntegral (numVertices * sizeOf (head vs))
          GL.bufferData GL.ArrayBuffer GL.$= (size, ptr, GL.StaticDraw)

        let firstIndex = 0
            vPosition = GL.AttribLocation 0
        GL.vertexAttribPointer vPosition GL.$=
          (GL.ToFloat, GL.VertexArrayDescriptor 2 GL.Float 0 (bufferOffset firstIndex))
        GL.vertexAttribArray vPosition  GL.$= GL.Enabled

        program <- loadShaders [
          ShaderInfo GL.VertexShader (FileSource "Shaders/shader.vert"),
          ShaderInfo GL.FragmentShader (FileSource "Shaders/shader.frag")
          ]
        GL.currentProgram GL.$= Just program
          
        let zDistClosest  = 1
            zDistFarthest = zDistClosest + 50
            zDist         = zDistClosest + ((zDistFarthest - zDistClosest) / 2)
            env = Env
              { envEventsChan    = eventsChan
              , envOscEvents     = oscEvents
              , envWindow        = win
              , envZDistClosest  = zDistClosest
              , envZDistFarthest = zDistFarthest
              , envTriDescriptor = Descriptor tri firstIndex (fromIntegral numVertices)
              , envProgram       = program
              }
            state = State
              { stateWindowWidth     = fbWidth
              , stateWindowHeight    = fbHeight
              , stateFluxes          = []
              , stateXAngle          = 0
              , stateYAngle          = 0
              , stateZAngle          = 0
              , stateGearZAngle      = 0
              , stateZDist           = zDist
              , stateMouseDown       = False
              , stateDragging        = False
              , stateDragStartX      = 0
              , stateDragStartY      = 0
              , stateDragStartXAngle = 0
              , stateDragStartYAngle = 0
              }
              
        runDemo env state

    putStrLn "ended!"

--------------------------------------------------------------------------------

-- GLFW-b is made to be very close to the C API, so creating a window is pretty
-- clunky by Haskell standards. A higher-level API would have some function
-- like withWindow.

withWindow :: Int -> Int -> String -> (GLFW.Window -> IO ()) -> IO ()
withWindow width height title f = do
    GLFW.setErrorCallback $ Just simpleErrorCallback
    r <- GLFW.init
    when r $ do
        m <- GLFW.createWindow width height title Nothing Nothing
        case m of
          (Just win) -> do
              GLFW.makeContextCurrent m
              f win
              GLFW.setErrorCallback $ Just simpleErrorCallback
              GLFW.destroyWindow win
          Nothing -> return ()
        GLFW.terminate
  where
    simpleErrorCallback e s =
        putStrLn $ unwords [show e, show s]

--------------------------------------------------------------------------------

-- Each callback does just one thing: write an appropriate Event to the events
-- TQueue.

errorCallback           :: TQueue Event -> GLFW.Error -> String                                                            -> IO ()
windowPosCallback       :: TQueue Event -> GLFW.Window -> Int -> Int                                                       -> IO ()
windowSizeCallback      :: TQueue Event -> GLFW.Window -> Int -> Int                                                       -> IO ()
windowCloseCallback     :: TQueue Event -> GLFW.Window                                                                     -> IO ()
windowRefreshCallback   :: TQueue Event -> GLFW.Window                                                                     -> IO ()
windowFocusCallback     :: TQueue Event -> GLFW.Window -> GLFW.FocusState                                                  -> IO ()
windowIconifyCallback   :: TQueue Event -> GLFW.Window -> GLFW.IconifyState                                                -> IO ()
framebufferSizeCallback :: TQueue Event -> GLFW.Window -> Int -> Int                                                       -> IO ()
mouseButtonCallback     :: TQueue Event -> GLFW.Window -> GLFW.MouseButton   -> GLFW.MouseButtonState -> GLFW.ModifierKeys -> IO ()
cursorPosCallback       :: TQueue Event -> GLFW.Window -> Double -> Double                                                 -> IO ()
cursorEnterCallback     :: TQueue Event -> GLFW.Window -> GLFW.CursorState                                                 -> IO ()
scrollCallback          :: TQueue Event -> GLFW.Window -> Double -> Double                                                 -> IO ()
keyCallback             :: TQueue Event -> GLFW.Window -> GLFW.Key -> Int -> GLFW.KeyState -> GLFW.ModifierKeys            -> IO ()
charCallback            :: TQueue Event -> GLFW.Window -> Char                                                             -> IO ()

errorCallback           tc e s            = atomically $ writeTQueue tc $ EventError           e s
windowPosCallback       tc win x y        = atomically $ writeTQueue tc $ EventWindowPos       win x y
windowSizeCallback      tc win w h        = atomically $ writeTQueue tc $ EventWindowSize      win w h
windowCloseCallback     tc win            = atomically $ writeTQueue tc $ EventWindowClose     win
windowRefreshCallback   tc win            = atomically $ writeTQueue tc $ EventWindowRefresh   win
windowFocusCallback     tc win fa         = atomically $ writeTQueue tc $ EventWindowFocus     win fa
windowIconifyCallback   tc win ia         = atomically $ writeTQueue tc $ EventWindowIconify   win ia
framebufferSizeCallback tc win w h        = atomically $ writeTQueue tc $ EventFramebufferSize win w h
mouseButtonCallback     tc win mb mba mk  = atomically $ writeTQueue tc $ EventMouseButton     win mb mba mk
cursorPosCallback       tc win x y        = atomically $ writeTQueue tc $ EventCursorPos       win x y
cursorEnterCallback     tc win ca         = atomically $ writeTQueue tc $ EventCursorEnter     win ca
scrollCallback          tc win x y        = atomically $ writeTQueue tc $ EventScroll          win x y
keyCallback             tc win k sc ka mk = atomically $ writeTQueue tc $ EventKey             win k sc ka mk
charCallback            tc win c          = atomically $ writeTQueue tc $ EventChar            win c

--------------------------------------------------------------------------------

runDemo :: Env -> State -> IO ()
runDemo env state = do
    printInstructions
    void $ evalRWST (adjustWindow >> run) env state

run :: Demo ()
run = do
    win <- asks envWindow

    draw
    liftIO $ do
        GLFW.swapBuffers win
        GL.flush  -- not necessary, but someone recommended it
        GLFW.pollEvents
    decayFluxMap
    processEvents
    processOscEvents

    mt <- liftIO GLFW.getTime
    modify $ \s -> s
      { stateGearZAngle = maybe 0 (realToFrac . (100*)) mt
      }

    q <- liftIO $ GLFW.windowShouldClose win
    unless q run

readTimestamp :: Message -> UTCTime
readTimestamp m = t
  where
    t = posixSecondsToUTCTime frac
    frac = realToFrac $ fromIntegral sec' + (asusec * fromIntegral usec')
    sec' = fromJust $ datum_integral sec :: Integer
    asusec = 0.000001 :: Double
    usec' = fromJust $ datum_integral usec :: Integer
    (sec:usec:_) = messageDatum m

processOscEvents :: Demo ()
processOscEvents = do
  tc <- asks envOscEvents
  me <- liftIO $ atomically $ tryPeekTQueue tc
  case me of
    Just e -> do      
      now <- liftIO getCurrentTime
      case ts <= now of
        True -> do
          _ <- liftIO $ atomically $ readTQueue tc
          processOscEvent e
          -- liftIO $ putStrLn $ show e
          -- liftIO $ putStrLn $ show $ descriptor $ messageDatum e

          processOscEvents
        False ->
          return ()
        where
          ts = readTimestamp e
    Nothing -> return ()

updateFluxMap :: Flux -> FluxMap -> FluxMap
updateFluxMap flux m = m ++ [flux]
  
-- findFlux :: String -> Int -> FluxMap -> Maybe Flux
-- findFlux fluxname idx fluxmap = fluxM
--   where
--     fluxes = Map.lookup fluxname fluxmap
--     fluxM = join $ Map.lookup idx <$> fluxes

fluxAPI :: ASCII
fluxAPI = ascii ",iifsiffffffffffffff"

toFluxMessage :: Message -> Maybe FluxMessage
toFluxMessage m = fluxm
  where
    datems = messageDatum m
    d = descriptor datems
    fluxm = case d == fluxAPI of
      True ->
        Just $ FluxMessage (posx', posy', posz') (width', height', depth') (angle', rotx', roty', rotz') (red', green', blue') life' flux ts
        where
          (_:_:_:dflux:didx:dlife:dposx:dposy:dposz:dwidth:dheight:ddepth:drotx:droty:drotz:dangle:dred:dgreen:[dblue]) = datems
          life' = fromJust $ datum_floating dlife
          posx' = fromJust $ datum_floating dposx
          posy' = fromJust $ datum_floating dposy
          posz' = fromJust $ datum_floating dposz
          width' = fromJust $ datum_floating dwidth
          height' = fromJust $ datum_floating dheight
          depth' = fromJust $ datum_floating ddepth
          rotx' = fromJust $ datum_floating drotx
          roty' = fromJust $ datum_floating droty
          rotz' = fromJust $ datum_floating drotz
          angle' = fromJust $ datum_floating dangle
          red' = fromJust $ datum_floating dred
          green' = fromJust $ datum_floating dgreen
          blue' = fromJust $ datum_floating dblue
          flux = fromJust $ datum_string dflux
          idx = fromJust $ datum_integral didx
          ts = readTimestamp m
      False ->
        Nothing

processOscEvent :: Message -> Demo ()
processOscEvent m = maybe (liftIO $ putStrLn "invalid msg received") processFluxMessage fluxmsgM
  where
    fluxmsgM = toFluxMessage m
  
processFluxMessage :: FluxMessage -> Demo ()
processFluxMessage FluxMessage{fpos=pos'@(x,y,z),
                               fsiz=siz'@(w,h,d),
                               frot=rot'@(angle,phi,psi,xsi),
                               fcol=col'@(r,g,b),
                               fname=fluxname,
                               flife=l, ftime=ts} = do
  state <- get
  let fluxmap = stateFluxes state
  -- create DisplayList if this is a new Flux
  (shape', postween, siztween, rottween, coltween) <- liftIO $ do
      gear <- makeGear 1   4 1   20 0.7 (GL.Color4 (realToFrac r) (realToFrac g) (realToFrac b) 1)
      return (gear,
              (pos', pos'),
              (siz', siz'),
              (rot', rot'),
              (col', col'))

  -- create a new Flux with updated values
  let flux = Flux shape' postween siztween rottween coltween Linear (Just l) fluxname ts
  put state {
    -- FIXME: continue with lifetime reduction an removal of _dead_ fluxes, like this, fluxes live forever
    stateFluxes = updateFluxMap flux fluxmap
            }

decayFluxMap :: Demo ()
decayFluxMap = do
  state <- get
  now <- liftIO getCurrentTime
  let fluxmap = stateFluxes state
      fluxmap' = map (decayFlux now) fluxmap
      fluxmap'' = clearGone fluxmap'

  put state {
    stateFluxes = fluxmap''
            }

clearGone :: FluxMap -> FluxMap
clearGone = filter isGone
  where
    isGone Flux{life=Nothing} = False
    isGone _ = True

decayFluxes :: UTCTime -> Map.Map Int Flux -> Map.Map Int Flux
decayFluxes t = Map.map (decayFlux t)

decayFlux :: UTCTime -> Flux -> Flux
decayFlux _ f@Flux{life=Nothing} = f
decayFlux t f@Flux{life=Just l}
  | diff >= l = f { life = Nothing }
  | otherwise = f
  where
    diff = realToFrac $ diffUTCTime t $ spawned f

processEvents :: Demo ()
processEvents = do
    tc <- asks envEventsChan
    me <- liftIO $ atomically $ tryReadTQueue tc
    case me of
      Just e -> do
          processEvent e
          processEvents
      Nothing -> return ()

processEvent :: Event -> Demo ()
processEvent ev =
    case ev of
      (EventError e s) -> do
          printEvent "error" [show e, show s]
          win <- asks envWindow
          liftIO $ GLFW.setWindowShouldClose win True

      (EventWindowPos _ x y) ->
          printEvent "window pos" [show x, show y]

      (EventWindowSize _ width height) ->
          printEvent "window size" [show width, show height]

      (EventWindowClose _) ->
          printEvent "window close" []

      (EventWindowRefresh _) ->
          printEvent "window refresh" []

      (EventWindowFocus _ fs) ->
          printEvent "window focus" [show fs]

      (EventWindowIconify _ is) ->
          printEvent "window iconify" [show is]

      (EventFramebufferSize _ width height) -> do
          printEvent "framebuffer size" [show width, show height]
          modify $ \s -> s
            { stateWindowWidth  = width
            , stateWindowHeight = height
            }
          adjustWindow

      (EventMouseButton _ mb mbs mk) -> do
          printEvent "mouse button" [show mb, show mbs, showModifierKeys mk]
          when (mb == GLFW.MouseButton'1) $ do
              let pressed = mbs == GLFW.MouseButtonState'Pressed
              modify $ \s -> s
                { stateMouseDown = pressed
                }
              unless pressed $
                modify $ \s -> s
                  { stateDragging = False
                  }

      (EventCursorPos _ x y) -> do
          let x' = round x :: Int
              y' = round y :: Int
          printEvent "cursor pos" [show x', show y']
          state <- get
          when (stateMouseDown state && not (stateDragging state)) $
            put $ state
              { stateDragging        = True
              , stateDragStartX      = x
              , stateDragStartY      = y
              , stateDragStartXAngle = stateXAngle state
              , stateDragStartYAngle = stateYAngle state
              }

      (EventCursorEnter _ cs) ->
          printEvent "cursor enter" [show cs]

      (EventScroll _ x y) -> do
          let x' = round x :: Int
              y' = round y :: Int
          printEvent "scroll" [show x', show y']
          env <- ask
          modify $ \s -> s
            { stateZDist =
                let zDist' = stateZDist s + realToFrac (negate $ y / 2)
                in curb (envZDistClosest env) (envZDistFarthest env) zDist'
            }
          adjustWindow

      (EventKey win k scancode ks mk) -> do
          printEvent "key" [show k, show scancode, show ks, showModifierKeys mk]
          when (ks == GLFW.KeyState'Pressed) $ do
              -- Q, Esc: exit
              when (k == GLFW.Key'Q || k == GLFW.Key'Escape) $
                liftIO $ GLFW.setWindowShouldClose win True
              -- ?: print instructions
              when (k == GLFW.Key'Slash && GLFW.modifierKeysShift mk) $
                liftIO printInstructions
              -- i: print GLFW information
              when (k == GLFW.Key'I) $
                liftIO $ printInformation win

      (EventChar _ c) ->
          printEvent "char" [show c]

adjustWindow :: Demo ()
adjustWindow = do
    state <- get
    let width  = stateWindowWidth  state
        height = stateWindowHeight state
        zDist  = stateZDist        state

    let pos   = GL.Position 0 0
        size  = GL.Size (fromIntegral width) (fromIntegral height)
        h     = fromIntegral height / fromIntegral width :: Double
        znear = 1           :: Double
        zfar  = 40          :: Double
        xmax  = znear * 0.5 :: Double
    liftIO $ do
        GL.viewport   GL.$= (pos, size)
        GL.matrixMode GL.$= GL.Projection
        GL.loadIdentity
        GL.frustum (realToFrac $ -xmax)
                   (realToFrac    xmax)
                   (realToFrac $ -xmax * realToFrac h)
                   (realToFrac $  xmax * realToFrac h)
                   (realToFrac    znear)
                   (realToFrac    zfar)
        GL.matrixMode GL.$= GL.Modelview 0
        GL.loadIdentity
        GL.translate (GL.Vector3 0 0 (negate $ realToFrac zDist) :: GL.Vector3 GL.GLfloat)

-- flattenFluxes :: FluxMap -> [Flux]
-- flattenFluxes fm = concat $ Map.elems $ Map.map Map.elems fm

linear :: Double -> Double -> Double -> Double -> Double
linear start end time timescale = change + start
  where
    change = range * pos
    pos = time / timescale
    range = end - start

tween3 :: Easing -> Double -> Double -> V3 -> V3 -> V3
tween3 Linear t tscale (x,y,z) (xto,yto,zto) = (linear x xto t tscale,
                                                linear y yto t tscale,
                                                linear z zto t tscale)
tween3 _ t tscale from to = tween3 Linear t tscale from to

tween4 :: Easing -> Double -> Double -> V4 -> V4 -> V4
tween4 Linear t tscale (x,y,z,w) (xto,yto,zto,wto) = (linear x xto t tscale,
                                                      linear y yto t tscale,
                                                      linear z zto t tscale,
                                                      linear w wto t tscale)
tween4 _ t tscale from to = tween4 Linear t tscale from to


m44To4V4GL :: M44 Double -> (GL.Vector4 GL.GLfloat, GL.Vector4 GL.GLfloat, GL.Vector4 GL.GLfloat, GL.Vector4 GL.GLfloat)
m44To4V4GL m = (a',b',c',d')
  where
    (LV4.V4 a b c d) = transpose m
    a' = makeGLV4 a
    b' = makeGLV4 b
    c' = makeGLV4 c
    d' = makeGLV4 d
    makeGLV4 (LV4.V4 x y z w) = GL.Vector4
      (realToFrac x)
      (realToFrac y)
      (realToFrac z)
      (realToFrac w)

draw :: Demo ()
draw = do
    ts <- liftIO getCurrentTime
    env   <- ask
    state <- get
    let fluxmap = stateFluxes state
        flatfluxes = fluxmap
        xa = stateXAngle state
        ya = stateYAngle state
        za = stateZAngle state
        ga = stateGearZAngle  state
        (Descriptor tris first num) = envTriDescriptor env
        prog = envProgram env
    liftIO $ do
        GL.clear [GL.ColorBuffer, GL.DepthBuffer]
        

        GL.preservingMatrix $ do
            GL.rotate (realToFrac xa) xunit
            GL.rotate (realToFrac ya) yunit
            GL.rotate (realToFrac za) zunit
        colL <- GL.uniformLocation prog "col"
        posL <- GL.uniformLocation prog "pos"
        tform1L <- GL.uniformLocation prog "mwc1"            
        tform2L <- GL.uniformLocation prog "mwc2"
        tform3L <- GL.uniformLocation prog "mwc3"            
        tform4L <- GL.uniformLocation prog "mwc4"         
        GL.bindVertexArrayObject GL.$= Just tris
        mapM_ (\f -> do
                  let vec = GL.Vector4 (realToFrac x) (realToFrac y) (realToFrac z) 0.0 :: GL.Vector4 GL.GLfloat
                      colV = (GL.Vector4 (realToFrac r) (realToFrac g) (realToFrac b) 1.0 :: GL.Vector4 GL.GLfloat)                      
                      (posfrom,posto) = pos f
                      (sizfrom,sizto) = siz f
                      (rotfrom,rotto) = rot f
                      (colfrom,colto) = col f                          
                      ease = easing f
                      life' = fromJust $ life f -- let's assume we can be sure here this is _Something_
                      t = realToFrac $ diffUTCTime ts $ spawned f
                      (x,y,z) = tween3 ease t life' posfrom posto
                      (w,h,d) = tween3 ease t life' sizfrom sizto
                      scaleM = scaled $ LV4.V4 w h d 1
                      (angle,phi,psi,xsi) = tween4 ease t life' rotfrom rotto
                      (r,g,b) = tween3 ease t life' colfrom colto
                      (tform1,tform2,tform3,tform4) = m44To4V4GL $ (flip (!*!)) scaleM $ mkTransformation (axisAngle (LV3.V3 phi psi xsi) (angle * pi)) (LV3.V3 x y z)


                  GL.uniform tform1L GL.$= tform1
                  GL.uniform tform2L GL.$= tform2
                  GL.uniform tform3L GL.$= tform3
                  GL.uniform tform4L GL.$= tform4                      
                  GL.uniform colL GL.$= colV
                  GL.uniform posL GL.$= vec
                  GL.drawArrays GL.Triangles first num

                 ) flatfluxes
      where
        xunit = GL.Vector3 1 0 0 :: GL.Vector3 GL.GLfloat
        yunit = GL.Vector3 0 1 0 :: GL.Vector3 GL.GLfloat
        zunit = GL.Vector3 0 0 1 :: GL.Vector3 GL.GLfloat

getCursorKeyDirections :: GLFW.Window -> IO (Double, Double)
getCursorKeyDirections win = do
    x0 <- isPress `fmap` GLFW.getKey win GLFW.Key'Up
    x1 <- isPress `fmap` GLFW.getKey win GLFW.Key'Down
    y0 <- isPress `fmap` GLFW.getKey win GLFW.Key'Left
    y1 <- isPress `fmap` GLFW.getKey win GLFW.Key'Right
    let x0n = if x0 then (-1) else 0
        x1n = if x1 then   1  else 0
        y0n = if y0 then (-1) else 0
        y1n = if y1 then   1  else 0
    return (x0n + x1n, y0n + y1n)

getJoystickDirections :: GLFW.Joystick -> IO (Double, Double)
getJoystickDirections js = do
    maxes <- GLFW.getJoystickAxes js
    return $ case maxes of
      (Just (x:y:_)) -> (-y, x)
      _              -> ( 0, 0)

isPress :: GLFW.KeyState -> Bool
isPress GLFW.KeyState'Pressed   = True
isPress GLFW.KeyState'Repeating = True
isPress _                       = False

--------------------------------------------------------------------------------

printInstructions :: IO ()
printInstructions =
    putStrLn $ render $
      nest 4 (
        text "------------------------------------------------------------" $+$
        text "'?': Print these instructions"                                $+$
        text "'i': Print GLFW information"                                  $+$
        text ""                                                             $+$
        text "* Mouse cursor, keyboard cursor keys, and/or joystick"        $+$
        text "  control rotation."                                          $+$
        text "* Mouse scroll wheel controls distance from scene."           $+$
        text "------------------------------------------------------------"
      )

printInformation :: GLFW.Window -> IO ()
printInformation win = do
    version       <- GLFW.getVersion
    versionString <- GLFW.getVersionString
    monitorInfos  <- runMaybeT getMonitorInfos
    joystickNames <- getJoystickNames
    clientAPI     <- GLFW.getWindowClientAPI              win
    cv0           <- GLFW.getWindowContextVersionMajor    win
    cv1           <- GLFW.getWindowContextVersionMinor    win
    cv2           <- GLFW.getWindowContextVersionRevision win
    robustness    <- GLFW.getWindowContextRobustness      win
    forwardCompat <- GLFW.getWindowOpenGLForwardCompat    win
    debug         <- GLFW.getWindowOpenGLDebugContext     win
    profile       <- GLFW.getWindowOpenGLProfile          win

    putStrLn $ render $
      nest 4 (
        text "------------------------------------------------------------" $+$
        text "GLFW C library:" $+$
        nest 4 (
          text "Version:"        <+> renderVersion version $+$
          text "Version string:" <+> renderVersionString versionString
        ) $+$
        text "Monitors:" $+$
        nest 4 (
          renderMonitorInfos monitorInfos
        ) $+$
        text "Joysticks:" $+$
        nest 4 (
          renderJoystickNames joystickNames
        ) $+$
        text "OpenGL context:" $+$
        nest 4 (
          text "Client API:"            <+> renderClientAPI clientAPI $+$
          text "Version:"               <+> renderContextVersion cv0 cv1 cv2 $+$
          text "Robustness:"            <+> renderContextRobustness robustness $+$
          text "Forward compatibility:" <+> renderForwardCompat forwardCompat $+$
          text "Debug:"                 <+> renderDebug debug $+$
          text "Profile:"               <+> renderProfile profile
        ) $+$
        text "------------------------------------------------------------"
      )
  where
    renderVersion (GLFW.Version v0 v1 v2) =
        text $ intercalate "." $ map show [v0, v1, v2]

    renderVersionString =
        text . show

    renderMonitorInfos =
        maybe (text "(error)") (vcat . map renderMonitorInfo)

    renderMonitorInfo (name, (x,y), (w,h), vms) =
        text (show name) $+$
        nest 4 (
          location <+> size $+$
          fsep (map renderVideoMode vms)
        )
      where
        location = int x <> text "," <> int y
        size     = int w <> text "x" <> int h <> text "mm"

    renderVideoMode (GLFW.VideoMode w h r g b rr) =
        brackets $ res <+> rgb <+> hz
      where
        res = int w <> text "x" <> int h
        rgb = int r <> text "x" <> int g <> text "x" <> int b
        hz  = int rr <> text "Hz"

    renderJoystickNames pairs =
        vcat $ map (\(js, name) -> text (show js) <+> text (show name)) pairs

    renderContextVersion v0 v1 v2 =
        hcat [int v0, text ".", int v1, text ".", int v2]

    renderClientAPI         = text . show
    renderContextRobustness = text . show
    renderForwardCompat     = text . show
    renderDebug             = text . show
    renderProfile           = text . show

type MonitorInfo = (String, (Int,Int), (Int,Int), [GLFW.VideoMode])

getMonitorInfos :: MaybeT IO [MonitorInfo]
getMonitorInfos =
    getMonitors >>= mapM getMonitorInfo
  where
    getMonitors :: MaybeT IO [GLFW.Monitor]
    getMonitors = MaybeT GLFW.getMonitors

    getMonitorInfo :: GLFW.Monitor -> MaybeT IO MonitorInfo
    getMonitorInfo mon = do
        name <- getMonitorName mon
        vms  <- getVideoModes mon
        MaybeT $ do
            pos  <- liftIO $ GLFW.getMonitorPos mon
            size <- liftIO $ GLFW.getMonitorPhysicalSize mon
            return $ Just (name, pos, size, vms)

    getMonitorName :: GLFW.Monitor -> MaybeT IO String
    getMonitorName mon = MaybeT $ GLFW.getMonitorName mon

    getVideoModes :: GLFW.Monitor -> MaybeT IO [GLFW.VideoMode]
    getVideoModes mon = MaybeT $ GLFW.getVideoModes mon

getJoystickNames :: IO [(GLFW.Joystick, String)]
getJoystickNames =
    catMaybes `fmap` mapM getJoystick joysticks
  where
    getJoystick js =
        fmap (maybe Nothing (\name -> Just (js, name)))
             (GLFW.getJoystickName js)

--------------------------------------------------------------------------------

printEvent :: String -> [String] -> Demo ()
printEvent cbname fields =
    liftIO $ putStrLn $ cbname ++ ": " ++ unwords fields

showModifierKeys :: GLFW.ModifierKeys -> String
showModifierKeys mk =
    "[mod keys: " ++ keys ++ "]"
  where
    keys = if null xs then "none" else unwords xs
    xs = catMaybes ys
    ys = [ if GLFW.modifierKeysShift   mk then Just "shift"   else Nothing
         , if GLFW.modifierKeysControl mk then Just "control" else Nothing
         , if GLFW.modifierKeysAlt     mk then Just "alt"     else Nothing
         , if GLFW.modifierKeysSuper   mk then Just "super"   else Nothing
         ]

curb :: Ord a => a -> a -> a -> a
curb l h x
  | x < l     = l
  | x > h     = h
  | otherwise = x

--------------------------------------------------------------------------------

joysticks :: [GLFW.Joystick]
joysticks =
  [ GLFW.Joystick'1
  , GLFW.Joystick'2
  , GLFW.Joystick'3
  , GLFW.Joystick'4
  , GLFW.Joystick'5
  , GLFW.Joystick'6
  , GLFW.Joystick'7
  , GLFW.Joystick'8
  , GLFW.Joystick'9
  , GLFW.Joystick'10
  , GLFW.Joystick'11
  , GLFW.Joystick'12
  , GLFW.Joystick'13
  , GLFW.Joystick'14
  , GLFW.Joystick'15
  , GLFW.Joystick'16
  ]
