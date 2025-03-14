
Abstract Syntax Tree (AST) 是一种抽象的、表示文档内容的数据结构。
在本模块中，我们定义了 igem-markdown 所使用的 AST 的数据结构（Haskell 代数数据类型）和 JSON 表示。
使用 Aeson 库进行 JSON 转换，并通过 Data.Text 的 Text 类型完成 JSON 转换。


\begin{code}

module Ast where

import Data.Aeson
import Data.Text (Text)
type CharUnit = (Char, Bool)
\end{code}

我们使用 Aeson 库来进行 JSON 转换，
用 Data.Text 的 Text 类型来在单一同态限定之内完成 JSON 转换。


\begin{code}

class ToJSON a => AstNode a

data Ast = forall a. AstNode a => Ast a

class AstNode a => InlineAstNode a where
  shouldDrop :: a -> Bool


data InlineAst = forall a. InlineAstNode a => InlineAst a

(.::) :: Key -> Text -> (Key, Value)
l .:: r = l .= String r

\end{code}

定义了一个辅助函数 (.::)，用于简化 JSON 键值对的构造。它将一个键和一个 Text 类型的值组合成一个键值对。

在 (.=) 的左右侧都是字符串字面量时，由于单一同态限定，
右侧字符串字面量会被推导为 Text，而不是 (.=) 需要的 Value。

因此，使用辅助函数 (.::) 来规避这一限定。

以下定义了如何将 Ast 转为 JSON

\begin{code}

instance ToJSON InlineAst where
  toJSON (InlineAst a) = toJSON a

instance ToJSON Ast where
  toJSON (Ast a) = toJSON a

instance Show Ast where
  show (Ast a) = show $ encode a
  -- 为 Ast 提供了 Show 实例，通过将 Ast 编码为 JSON 字符串来显示。


\end{code}
