module Graphics.Weltfrieden.Colors (colorPairs, colorAt, colorForName, syllableCountForName) where

import Data.Colour.SRGB
import Sound.Tidal.Parse (p, ColourD)


data Spectrum = Ray { name :: String, syllables :: Int, rgb :: String }


splitBy delimiter = foldr f [[]]
      where f c l@(x:xs) | c == delimiter = []:l
                         | otherwise = (c:x):xs

asTuple [] = Ray "no name" 0 "#000000"
asTuple [name] = Ray name 0  "#000000"
asTuple [name, sylls] = Ray name (read sylls) "#000000"
asTuple [name, sylls, color] = Ray name (read sylls) color


colorPairs file = do
  let colors' = map (splitBy ' ') (lines file)
  return $ map asTuple colors'

-- colorNameSyllablePairs file = do
--   let colors' = map (splitBy ' ') (lines file)
--   return $ map (\x -> (read $ (x !! 0) :: Int , x !! 1)) colors'

colorListForName list n = filter (\x -> n == (name x)) list

syllableCountForName list name = case (colorListForName list name) of
  [] -> 0
  [Ray{syllables=n}] -> n

colorForName :: [Spectrum] -> String -> ColourD
colorForName list name = case (colorListForName list name) of
  [] -> sRGB24read "#000000"
  [Ray{rgb=c}] -> sRGB24read c

colorAt :: [Spectrum] -> Int -> ColourD
colorAt list i = sRGB24read $ rgb $ list !! (i `mod` (length list))
