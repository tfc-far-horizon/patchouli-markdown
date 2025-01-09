\begin{code}
module Main (parsemd, main) where

import Parsers
import Data.Aeson (encode)
import GHC.Wasm.Prim
import qualified Data.ByteString.Lazy.Char8 as BL

foreign export javascript "parse" parsemd :: JSString -> JSString

parsemd :: JSString -> JSString
parsemd md = case parse article "stdin" (fromJSString md) of
  Left e -> toJSString $ show e
  Right w -> toJSString $ BL.unpack $ encode w

foreign export javascript correct :: JSString -> Bool

correct :: JSString -> Bool
correct md = case parse article "stdin" (fromJSString md) of
  Left e -> False
  Right w -> True

foreign export javascript problems :: JSString -> Int
problems :: JSString -> Int
problems md = case parse article "stdin" (fromJSString md) of
  Left e -> -1
  Right (_, w) -> length w

foreign export javascript consoleLog :: JSString -> IO ()

consoleLog :: JSString -> IO ()
consoleLog v = do
  print $ fromJSString v
  print $ fromJSString v

main :: IO ()
main = do
  return ()
\end{code}
