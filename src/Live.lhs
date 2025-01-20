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

foreign export javascript problems :: JSString -> Int
problems :: JSString -> Int
problems md = case parse article "stdin" (fromJSString md) of
  Left e -> -1
  Right (_, w) -> length w

main :: IO ()
main = do
  return ()
\end{code}
