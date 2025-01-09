\begin{code}
module Main where

import Data.Aeson (encode)
import qualified Data.ByteString.Lazy.Char8 as BL
import Parsers
import System.Environment (getArgs)

main :: IO ()
main = do
  path <- head <$> getArgs
  file <- readFile path
  case parse
    article
    path
    file of
    Left err -> print err
    Right res -> BL.putStrLn $ encode res
\end{code}
