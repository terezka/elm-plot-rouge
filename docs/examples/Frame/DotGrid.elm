module Examples.Frame.DotGrid exposing (..)

{-| @LARGE -}
import Html as H
import Svg as S
import Chart as C
import Chart.Attributes as CA


view : Model -> H.Html Msg
view model =
{-| @SMALL -}
  C.chart
    [ CA.height 300
    , CA.width 300
    ]
    [ C.grid [ CA.dotGrid ]
    , C.xAxis []
    , C.xTicks []
    , C.xLabels []
    , C.yAxis []
    , C.yTicks []
    , C.yLabels []
    ]
{-| @SMALL END -}
{-| @LARGE END -}


meta =
  { category = "Navigation"
  , categoryOrder = 4
  , name = "Dotted grid"
  , description = "Use dots instead of grid lines."
  , order = 13
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

