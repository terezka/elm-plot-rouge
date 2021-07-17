module Examples.Frontpage.BasicLine exposing (..)


-- THIS IS A GENERATED MODULE!

import Html as H
import Chart as C
import Chart.Attributes as CA


view : Model -> H.Html Msg
view model =
  C.chart
    [ CA.height 300
    , CA.width 300
    , CA.margin { top = 0, bottom = 20, left = 0, right = 0 }
    , CA.padding { top = 10, bottom = 5, left = 10, right = 10 }
    ]
    [ C.grid []
    , C.xLabels []
    , C.yLabels []
    , C.series .x
        [ C.interpolated .y [ CA.monotone ] [ CA.circle ]
        , C.interpolated .z [ CA.monotone ] [ CA.square ]
        ]
        [ { x = 1, y = 2, z = 3 }
        , { x = 5, y = 4, z = 1 }
        , { x = 10, y = 2, z = 4 }
        ]
    ]


meta =
  { category = "Basic"
  , categoryOrder = 3
  , name = "Line chart"
  , description = "Make a basic line chart."
  , order = 1
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


type alias Datum =
  { x : Float
  , y : Float
  , z : Float
  , v : Float
  , w : Float
  , p : Float
  , q : Float
  }

data : List Datum
data =
  [ Datum 1  2 1 4.6 6.9 7.3 8.0
  , Datum 2  3 2 5.2 6.2 7.0 8.7
  , Datum 3  4 3 5.5 5.2 7.2 8.1
  , Datum 4  3 4 5.3 5.7 6.2 7.8
  , Datum 5  2 3 4.9 5.9 6.7 8.2
  , Datum 6  4 1 4.8 5.4 7.2 8.3
  , Datum 7  5 2 5.3 5.1 7.8 7.1
  , Datum 8  6 3 5.4 3.9 7.6 8.5
  , Datum 9  5 4 5.8 4.6 6.5 6.9
  , Datum 10 4 3 4.5 5.3 6.3 7.0
  ]



smallCode : String
smallCode =
  """
  C.chart
    [ CA.height 300
    , CA.width 300
    , CA.margin { top = 0, bottom = 20, left = 0, right = 0 }
    , CA.padding { top = 10, bottom = 5, left = 10, right = 10 }
    ]
    [ C.grid []
    , C.xLabels []
    , C.yLabels []
    , C.series .x
        [ C.interpolated .y [ CA.monotone ] [ CA.circle ]
        , C.interpolated .z [ CA.monotone ] [ CA.square ]
        ]
        [ { x = 1, y = 2, z = 3 }
        , { x = 5, y = 4, z = 1 }
        , { x = 10, y = 2, z = 4 }
        ]
    ]
  """


largeCode : String
largeCode =
  """
import Html as H
import Chart as C
import Chart.Attributes as CA


view : Model -> H.Html Msg
view model =
  C.chart
    [ CA.height 300
    , CA.width 300
    , CA.margin { top = 0, bottom = 20, left = 0, right = 0 }
    , CA.padding { top = 10, bottom = 5, left = 10, right = 10 }
    ]
    [ C.grid []
    , C.xLabels []
    , C.yLabels []
    , C.series .x
        [ C.interpolated .y [ CA.monotone ] [ CA.circle ]
        , C.interpolated .z [ CA.monotone ] [ CA.square ]
        ]
        [ { x = 1, y = 2, z = 3 }
        , { x = 5, y = 4, z = 1 }
        , { x = 10, y = 2, z = 4 }
        ]
    ]
  """