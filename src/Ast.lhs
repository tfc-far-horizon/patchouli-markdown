Ast: Abstract Syntax Tree 是一种抽象的、表示文档内容的数据结构，
在这个文件中我们定义 igem-markdown 所使用的 Ast 的数据结构和 JSON 表示。

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

data Ast
  = Paragraph {content :: [Ast]}
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

data EmphasisType
  = UnderLined
  | Italic
  | Bold

instance ToJSON EmphasisType where
  toJSON UnderLined = String "underlined"
  toJSON Italic = String "italic"
  toJSON Bold = String "bold"

(.::) :: Key -> Text -> (Key, Value)
l .:: r = l .= String r

\end{code}

以下定义了如何将 Ast 转为 JSON

\begin{code}

instance ToJSON Ast where
  toJSON (Paragraph asts) =
    object
      [ "type" .:: "paragraph",
        "content" .= filter (\ast -> case ast of
          Plain "" -> False
          _ -> True
        ) asts
      ]
  toJSON (Section title date content) =
    object
      [ "type" .:: "section",
        "title" .= title,
        "date" .= date,
        "content" .= content
      ]
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

\end{code}
