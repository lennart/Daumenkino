module Graphics.Weltfrieden.Colors where

colorFile = do
  readFile "/home/pi/Weltfrieden/Data/rgb.txt"

splitBy delimiter = foldr f [[]]
      where f c l@(x:xs) | c == delimiter = []:l
                         | otherwise = (c:x):xs

asTuple [] = ("no name", "#000000")
asTuple [name] = (name,"#000000")
asTuple [name, color] = (name, color)
asTuple [name, color, _] = (name, color)
