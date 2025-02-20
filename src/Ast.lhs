Ast: Abstract Syntax Tree 是一种抽象的、表示文档内容的数据结构，
在这个文件中我们定义 igem-markdown 所使用的 Ast 的数据结构和 JSON 表示。

{-|
  Abstract Syntax Tree (AST) 是一种抽象的、表示文档内容的数据结构。
  在本模块中，我们定义了 igem-markdown 所使用的 AST 的数据结构（Haskell 代数数据类型）和 JSON 表示。
  使用 Aeson 库进行 JSON 转换，并通过 Data.Text 的 Text 类型完成 JSON 转换。
-}

\begin{code}
module Ast
  ( Ast (..),
    EmphasisType (..),
    Day,
    fromGregorian,
  )
where

\end{code}

我们使用 Aeson 库来进行 JSON 转换，
用 Data.Text 的 Text 类型来在单一同态限定之内完成 JSON 转换。

\begin{code}

import Data.Aeson
import Data.Text (Text)
import Data.Time.Calendar (Day, fromGregorian)
-- 导入了以下库：
-- Data.Aeson：用于 JSON 的序列化和反序列化。
-- Data.Text：提供了 Text 类型，用于处理文本数据。
-- Data.Time.Calendar：提供了日期相关的类型和函数，例如 Day 和 fromGregorian。

data Ast = Paragraph {content :: [Ast]}
  | Section
      { title :: String,
        date :: Maybe Day,
        content :: [Ast]
      }
  | Figure
      { path :: String,
        caption :: Ast
      }
  | Link
      { text :: Ast,
        path :: String
      }
  | Itemization [[Ast]]
  | Enumeration [[Ast]]
  | Plain {plaintext :: String}
  | Math
      { formula :: String,
        display :: Bool
      }
  | Emphasis Ast EmphasisType

  -- Ast 是一个代数数据类型，用于表示文档的不同结构：
  -- Paragraph：段落，包含一个 Ast 列表作为内容。
  -- Section：章节，包含标题、日期（可选）和内容。
  -- Figure：图片，包含路径和标题。
  -- Link：链接，包含文本和路径。
  -- Itemization：无序列表，包含一个二维 Ast 列表。
  -- Enumeration：有序列表，包含一个二维 Ast 列表。
  -- Plain：纯文本。
  -- Math：数学公式，包含公式内容和显示模式（display 表示是否为显示模式）。
  -- Emphasis：强调文本，包含内容和强调类型。
data EmphasisType
  = UnderLined
  | Italic
  | Bold

  -- EmphasisType 是一个枚举类型，表示文本的强调方式：
  -- UnderLined：下划线。
  -- Italic：斜体。
  -- Bold：加粗。
instance ToJSON EmphasisType where
  toJSON UnderLined = String "underlined"
  toJSON Italic = String "italic"
  toJSON Bold = String "bold"
  -- 为 EmphasisType 提供了 ToJSON 实例，将枚举值映射为 JSON 字符串。

(.::) :: Key -> Text -> (Key, Value)
l .:: r = l .= String r
-- 定义了一个辅助函数 (.::)，用于简化 JSON 键值对的构造。它将一个键和一个 Text 类型的值组合成一个键值对。
\end{code}

以下定义了如何将 Ast 转为 JSON

\begin{code}

instance ToJSON Ast where--为 Ast 提供了 ToJSON 实例，定义了如何将 Ast 转换为 JSON 格式。
  toJSON (Paragraph asts) =
    object
      [ "type" .:: "paragraph",
        "content" .= filter (\ast -> case ast of
          Plain "" -> False
          _ -> True
        ) asts
      ]
--       类型为 "paragraph"。
-- 内容为 asts，但会过滤掉空的 Plain 节点。
  toJSON (Section title date content) =
    object
      [ "type" .:: "section",
        "title" .= title,
        "date" .= date,
        "content" .= content
      ]
      -- Section：
-- 类型为 "section"。
-- 包含标题、日期（可选）和内容。
  toJSON (Figure path caption) =
    object
      [ "type" .:: "figure",
        "path" .= path,
        "caption" .= caption
      ]
  toJSON (Itemization p's) =
    object
      [ "type" .:: "itemization",
        "items" .= p's
        -- the first paragraph for each list
        -- in list p's will be marked with dot
      ]
  toJSON (Enumeration p's) =
    object
      [ "type" .:: "enumeration",
        "items" .= p's
        -- the first paragraph for each list
        -- in list p's will be marked with number
      ]
  toJSON (Math f d) =
    object
      [ "type" .:: "math",
        "mode"
          .= let mode =
                   if d
                     then "display"
                     else "inline"
              in String mode,
        "content" .= f
      ]
--       类型为 "math"。
-- 包含公式内容和显示模式（display 或 inline）。
  toJSON (Plain t) =
    object
      [ "type" .:: "plain",
        "content" .= t
      ]
  toJSON (Emphasis asts t) =
    object
      [ "type" .= t,
        "content" .= asts
      ]
  toJSON (Link text path) =
    object
      [ "type" .:: "link",
        "text" .= text,
        "link" .= path
      ]

instance Show Ast where
  show ast = show $ encode ast
  -- 为 Ast 提供了 Show 实例，通过将 Ast 编码为 JSON 字符串来显示。

\end{code}
