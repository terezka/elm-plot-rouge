module Examples.BarCharts.VariableWidth exposing (..)

{-| @LARGE -}
import Html as H
import Svg as S
import Chart as C
import Chart.Attributes as CA
import Time


view : Model -> H.Html Msg
view model =
{-| @SMALL -}
  C.chart
    [ CA.height 300
    , CA.width 300
    ]
    [ C.grid []
    , C.xLabels []
    , C.yLabels [ CA.withGrid ]
    , C.bars
        [ CA.x1 .start
        , CA.x2 .end
        , CA.margin 0
        ]
        [ C.bar .y [ CA.borderWidth 0.3, CA.opacity 0.5 ] ]
        data
    ]
{-| @SMALL END -}


type alias Datum =
  { start : Float
  , end : Float
  , y : Float
  }


data : List Datum
data =
  [ Datum 1 2 2
  , Datum 2 3 3
  , Datum 3 6 4
  , Datum 6 7 6
  ]


{-| @LARGE END -}

meta =
  { category = "Bar charts"
  , categoryOrder = 1
  , name = "Variable width"
  , description = "Bars with varying widths."
  , order = 2
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

