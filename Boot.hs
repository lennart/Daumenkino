import Sound.Tidal.Context
import Graphics.Daumenkino.Params

shader :: Pattern String -> ControlPattern
shader = pS "shader"

anotherTarget :: OSCTarget
anotherTarget = OSCTarget {oName = "Another one",
                           oAddress = "127.0.0.1",
                           oPort = 7772,
                           oPath = "/shader",
                           oShape = Just [("sec", Just $ VI 0),
                                          ("usec", Just $ VI 0),
                                          ("cps", Just $ VF 0),
                                          ("dur", Just $ VF 0.2),
                                          ("shader", Nothing),
                                          ("r", Just $ VF 1.0),
                                          ("g", Just $ VF 1.0),
                                          ("b", Just $ VF 1.0),
                                          ("a", Just $ VF 1.0),
                                          ("x", Just $ VF 0.5),
                                          ("y", Just $ VF 0.5),
                                          ("z", Just $ VF 0.0),
                                          ("w", Just $ VF 1.0),
                                          ("rot_x", Just $ VI 0),               
                                          ("rot_y", Just $ VI 0),               
                                          ("rot_z", Just $ VI 0),               
                                          ("origin_x", Just $ VI 0),               
                                          ("origin_y", Just $ VI 0),               
                                          ("origin_z", Just $ VI 0),
                                          ("width", Just $ VF 1.0),
                                          ("height", Just $ VF 1.0),
                                          ("speed", Just $ VF 1.0),
                                          ("srcblend", Just $ VS "a"),
                                          ("blend", Just $ VS "x"),
                                          ("blendeq", Just $ VS "a"),            
                                          ("level", Just $ VI 0)
                                         ],
                           oLatency = 0.02,
                           oPreamble = [],
                           oTimestamp = MessageStamp
                          }

