用于解析 Markdown 文件并生成 JSON 格式的 AST（抽象语法树），同时导出为 JavaScript 函数以便在 WebAssembly 环境中使用。
\begin{code}
module Main (parsemd, main) where
import Parsers
-- 导入解析器模块
import Data.Aeson (encode, ToJSON)
-- 导入 Aeson 库，用于 JSON 编码
import GHC.Wasm.Prim
-- 导入 WebAssembly 相关的 GHC 函数
import Data.Aeson.Text (encodeToTextBuilder)
import qualified Data.Text.Lazy as TL
import qualified Data.Text.Lazy.Builder as TB

toJSONString :: ToJSON a => a -> String
toJSONString = TL.unpack . TB.toLazyText . encodeToTextBuilder

  -- 为 WebAssembly 模块导出名为 ``parse'' 的 JavaScript 函数，
  -- 用于解析 Markdown 文件。
  -- 输入是 JavaScript 字符串，返回值也是 JavaScript 字符串。

foreign export javascript "parse" parsemd :: JSString -> JSString


  --解析 Markdown 文件的函数。
  --如果解析成功，返回 JSON 编码的 AST；如果解析失败，返回错误信息。

parsemd :: JSString -> JSString
parsemd md = case parse article "stdin" (fromJSString md) of
  Left e -> toJSString $ show e  -- 解析失败，返回错误信息
  Right w ->                         -- 解析成功
    toJSString $ toJSONString w  -- 将 AST 编码为 JSON 并返回


  -- 导出名为 ``problems'' 的 JavaScript 函数，
  -- 用于计算解析结果中出现的警告数。
  -- 如果解析失败，返回 -1；否则返回出现的警告数。

foreign export javascript problems :: JSString -> Int

problems :: JSString -> Int
problems md = case parse article "stdin" (fromJSString md) of
  Left e -> -1  -- 解析失败，返回 -1
  Right (_, w) -> length w  -- 解析成功，返回 warning 的数量

  -- 主函数，被 ghc 的 wasm 后端在编译时舍弃。

foreign export javascript returns :: JSString -> JSString
returns x = toJSString $ toJSONString $ fromJSString $ x

main :: IO ()
main = do
  return ()
\end{code}
