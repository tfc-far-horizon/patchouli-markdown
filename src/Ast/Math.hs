module Ast.Math where

import Ast
import Data.Aeson

data Math = Math
  { formula :: String,
    display :: Bool
  }

instance ToJSON Math where
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

instance AstNode Math

instance InlineAstNode Math where
  shouldDrop _ = False
