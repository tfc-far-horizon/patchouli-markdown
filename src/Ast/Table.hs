module Ast.Table where

import Ast
import Ast.Paragraph (Paragraph)
import Data.Aeson

data Align = Align'Left | Align'Right | Align'Center deriving (Show)

instance ToJSON Align where
  toJSON Align'Left = String "left"
  toJSON Align'Right = String "right"
  toJSON Align'Center = String "center"

data Table'Cell = Table'Cell
  { isHeader :: Bool
  , align :: Align
  , content :: Paragraph
  }

instance ToJSON Table'Cell where
  toJSON (Table'Cell isHeader align content) =
    object $
      [ "type" .:: "table-cell"
      , "isHeader" .= isHeader
      , "align" .= align
      , "content" .= content
      ]

data Table = Table
  { header :: [Table'Cell]
  , rows :: [[Table'Cell]]
  }

instance ToJSON Table where
  toJSON (Table header rows) =
    object $
      [ "type" .:: "table"
      , "header" .= header
      , "rows" .= rows
      ]

instance AstNode Table
