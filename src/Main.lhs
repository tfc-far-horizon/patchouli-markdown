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

--     parse article path file 调用 parse 函数，传入 article、path 和 file 作为参数。
-- article 是解析器的名称或上下文。
-- path 是文件路径。
-- file 是文件内容。
-- case ... of 用于模式匹配，处理 parse 函数的返回值：
-- Left err 表示解析失败，err 是错误信息。
-- print err 打印错误信息到标准输出。
-- Right res 表示解析成功，res 是解析结果。
-- BL.putStrLn \$ encode res 将解析结果编码为 JSON 格式，并输出到标准输出。
\end{code}
