\begin{code}
module Main (parsemd, main) where
-- 用于解析 Markdown 文件并生成 JSON 格式的 AST（抽象语法树），同时导出为 JavaScript 函数以便在 WebAssembly 环境中使用。
import Parsers  -- 导入解析器模块
import Data.Aeson (encode)  -- 导入 Aeson 库，用于 JSON 编码
import GHC.Wasm.Prim        -- 导入 WebAssembly 相关的 GHC 函数
import qualified Data.ByteString.Lazy.Char8 as BL  -- 导入 Lazy ByteString 模块

{-|
  导出名为 "parse" 的 JavaScript 函数，用于解析 Markdown 文件。
  输入是 JavaScript 字符串，返回值也是 JavaScript 字符串。
-}
foreign export javascript "parse" parsemd :: JSString -> JSString

{-|
  解析 Markdown 文件的函数。
  如果解析成功，返回 JSON 编码的 AST；如果解析失败，返回错误信息。
-}
parsemd :: JSString -> JSString
parsemd md = case parse article "stdin" (fromJSString md) of
  Left e -> toJSString $ show e  -- 解析失败，返回错误信息
  Right w ->                         -- 解析成功
    toJSString $ BL.unpack $ encode w  -- 将 AST 编码为 JSON 并返回

{-|
  导出名为 "problems" 的 JavaScript 函数，用于计算解析结果中 ".content" 的长度。
  如果解析失败，返回 -1；否则返回 ".content" 的长度。
-}
foreign export javascript problems :: JSString -> Int

problems :: JSString -> Int
problems md = case parse article "stdin" (fromJSString md) of
  Left e -> -1  -- 解析失败，返回 -1
  Right (_, w) -> length w  -- 解析成功，返回 ".content" 的长度

{-|
  主函数，目前内容为空。
-}
main :: IO ()
main = do
  return ()
\end{code}
