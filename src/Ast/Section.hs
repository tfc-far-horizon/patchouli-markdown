module Ast.Section where

import Ast
import Ast.Paragraph
import Data.Aeson
import Data.Time.Calendar (Day)

data Section = Section
  { title :: Paragraph
  , date :: Maybe Day
  , content :: [Ast]
  }

instance ToJSON Section where
  toJSON (Section title date content) =
    object
      [ "type" .:: "section"
      , "title" .= title
      , "date" .= date
      , "content" .= content
      ]

instance AstNode Section
