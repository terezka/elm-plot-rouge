module Examples.Frame.CustomFormat exposing (..)


-- THIS IS A GENERATED MODULE!

import Html as H
import Svg as S
import Chart as C
import Chart.Attributes as CA


view : Model -> H.Html Msg
view model =
  C.chart
    [ CA.height 300
    , CA.width 300
    ]
    [ C.grid []
    , C.xAxis []
    , C.xLabels [ CA.format (\x -> String.fromFloat x ++ " C°"), CA.withGrid ]
    ]


meta =
  { category = "Navigation"
  , categoryOrder = 4
  , name = "Custom formatting"
  , description = "Change how your labels are formatted."
  , order = 9
  }


type alias Model =
  ()


init : Model
init =
  ()


type Msg
  = Msg


update : Msg -> Model -> Model
update msg model =
  model


smallCode : String
smallCode =
  """
  C.chart
    [ CA.height 300
    , CA.width 300
    ]
    [ C.grid []
    , C.xAxis []
    , C.xLabels [ CA.format (\\x -> String.fromFloat x ++ " C°"), CA.withGrid ]
    ]
  """


largeCode : String
largeCode =
  """
import Html as H
import Svg as S
import Chart as C
import Chart.Attributes as CA


view : Model -> H.Html Msg
view model =
  C.chart
    [ CA.height 300
    , CA.width 300
    ]
    [ C.grid []
    , C.xAxis []
    , C.xLabels [ CA.format (\\x -> String.fromFloat x ++ " C°"), CA.withGrid ]
    ]
  """