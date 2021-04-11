module Test exposing (..)

import Html as H
import Html.Attributes as HA
import Svg as S exposing (Svg, svg, g, circle, text_, text)
import Svg.Attributes as SA exposing (width, height, stroke, fill, r, transform)
import Svg.Coordinates as Coordinates
import Chart as C
import Svg.Chart as SC
import Browser
import Time
import Data.Iris as Iris
import Data.Salery as Salery
import Data.Education as Education
import Dict
import Chart.Svg as CS
import Chart.Attributes as CA
import Chart.Item as Item


-- TODO
-- labels + ticks + grid automation?
-- clean up Item / Items
-- Title
-- seperate areas from lines + dots to fix opacity


main =
  Browser.sandbox
    { init = init
    , update = update
    , view = view
    }


type alias Model =
  { hoveringSalery : List (Item.BarItem Salery.Datum)
  , hovering : List (Item.BarItem Datum)
  , hoveringNew : List (Item.BarItem Datum)
  , point : Maybe Coordinates.Point
  }


init : Model
init =
  Model [] [] [] Nothing


type Msg
  = OnHoverSalery (List (Item.BarItem Salery.Datum))
  | OnHover (List (Item.BarItem Datum))
  | OnHoverNew (List (Item.BarItem Datum))
  | OnCoords Coordinates.Point -- TODO


update : Msg -> Model -> Model
update msg model =
  case msg of
    OnHoverSalery bs -> { model | hoveringSalery = bs }
    OnHoverNew bs -> { model | hoveringNew = bs }
    OnHover bs -> { model | hovering = bs }
    OnCoords p -> { model | point = Just p }


type alias Datum =
  { x : Float
  , y : Maybe Float
  , z : Maybe Float
  , label : String
  }


data : List Datum
data =
  [ { x = 2, y = Just 6, z = Just 5, label = "DK" }
  , { x = 6, y = Just 5, z = Just 5, label = "SE" }
  , { x = 8, y = Just 3, z = Just 2, label = "FI" }
  , { x = 10, y = Just 4, z = Just 3, label = "IS" }
  ]


view : Model -> H.Html Msg
view model =
  H.div
    [ HA.style "font-size" "12px"
    , HA.style "font-family" "monospace"
    , HA.style "margin" "0 auto"
    , HA.style "padding-top" "50px"
    , HA.style "width" "100vw"
    , HA.style "max-width" "1000px"
    ]
    [ C.chart
      [ C.height 400
      , C.width 1000
      , C.static
      --, C.marginLeft 0
      , C.paddingTop 15
      --, C.range (C.startMin 0 >> C.endMax 6)
      --, C.domain (C.startMax 0 >> C.endMin 19)
      --, C.events
      --    [ C.decoder (\is pl ps -> CS.getNearest Item.center (C.getBars is) pl ps)
      --        |> C.map OnHoverNew
      --        |> C.event "mousemove"
      --    ]
      , C.id "salery-discrepancy"
      ]
      [ C.grid []

      --, C.bars
      --    [ CA.roundTop 0.2
      --    , CA.roundBottom 0.2
      --    , CA.grouped
      --    --, CA.margin 0
      --    --, CA.spacing 0
      --    ]
      --    [ C.stacked
      --        [ C.property .y [] [] (always [])
      --        , C.property .z [] [] (always [])
      --        , C.property (C.just .x) [] [] (always [])
      --        ]
      --    , C.property .z [] [] (always [])
      --    ]
      --    data

      , C.yAxis [ C.noArrow ]
      , C.xTicks []
      , C.xLabels []
      , C.yLabels [ C.ints ]
      , C.yTicks [ C.ints ]


      , C.series .x
          --[ C.monotone ]
          [ C.stacked
              [ C.property .y [] [ CA.circle, CA.linear, CA.area 0.25 ] (always [])
                  --(\d -> if hovered d then [ C.aura 5 0.5 ] else [])
              , C.property .z [] [ CA.circle, CA.linear, CA.area 0.25, CA.color CS.purple ] (always [])
              ]
          ]
          data

      , C.svg <| \p ->
          S.g []
            --I.label p [ I.x 3, I.y 5, I.yOff -5, I.xOff 5, I.border I.blue, I.fontSize 60, I.borderWidth 2, I.color I.pink ] "hello"
            --,
            --[ I.line p [ I.x1 4, I.x2 6, I.color I.blue, I.width 2 ]
            --, I.arrow p [ I.x p.x.max, I.y p.y.min ]

            --, I.bar p .x1 .y1 .x2 .y2
            --      [ I.roundBottom 0.2
            --      , I.roundTop 0.2
            --      --, I.aura 0.3
            --      ]
            --      { x1 = 2.5, y1 = 10, x2 = 2.75, y2 = 13 }

            --, I.dot p .x .y
            --    [ I.border "rgb(5, 142, 218)"
            --    , I.opacity 1
            --    , I.size 10
            --    , I.borderWidth 1
            --    , I.border "white"
            --    --, I.aura 0.5
            --    --, I.auraWidth 5
            --    , I.plus
            --    ]
            --    { x = 2, y = 15 }

            --, I.dot p .x .y
            --    [ I.border "rgb(5, 142, 218)"
            --    , I.opacity 1
            --    , I.size 6
            --    , I.borderWidth 1
            --    , I.border "white"
            --    , I.aura 0.5
            --    , I.auraWidth 5
            --    ]
            --    { x = 1.5, y = 10 }

            [
            --[ Item.toSeriesItems .x
            --    [ Item.stacked
            --        [ Item.property .z { name = "dogs", unit = "km/s" } [] [ CA.area 0.25, CA.color CS.blue, CA.size 2, CA.borderWidth 1, CA.circle ] (always [])
            --        , Item.property .y { name = "cats", unit = "km/s" } [] [ CA.linear, CA.color CS.blue, CA.size 2, CA.borderWidth 1, CA.diamond ] (always [])
            --        ]
            --    ]
            --    [ { x = 0, y = Just 14, z = Just 2 }
            --    , { x = 0.5, y = Just 16, z = Just 3.2 }
            --    , { x = 0.75, y = Just 14, z = Just 3.8 }
            --    , { x = 1, y = Nothing, z = Just 2.3 }
            --    , { x = 1.4, y = Just 13, z = Just 2.1 }
            --    , { x = 2, y = Just 14, z = Just 2.7 }
            --    , { x = 3, y = Just 16, z = Just 3.2 }
            --    , { x = 4, y = Just 13, z = Just 0.9 }
            --    , { x = 5, y = Just 14, z = Just 3.3 }
            --    , { x = 6, y = Just 10, z = Just 3.9 }
            --    ]
            --    |> List.map (Item.render p)
            --    |> S.g []
            --    |> S.map never

            --, I.cross p [ I.x 2, I.y 15, I.border "rgb(5, 142, 218)", I.opacity 1, I.size 40, I.borderWidth 1, I.border "white", I.aura 0.5, I.auraWidth 5 ]
            --,

            --, I.bars p (Just .x1) (Just .x2)
            --    [ I.margin 0.1
            --    , I.spacing 0.01
            --    , I.roundTop 0.15
            --    , I.roundBottom 0.15
            --    , I.grouped
            --    ]
            --    [ I.property .y "cats" "m/s" [] (always [ I.borderWidth 1 ])
            --    , I.property .z "cats" "m/s" [] (always [ I.borderWidth 1 ])
            --    , I.stacked
            --        [ I.property .y "cats" "m/s" [ I.borderWidth 1 ] (always [])
            --        , I.property .z "dogs" "km/s" [ I.borderWidth 1 ] (always [])
            --        ]
            --    ]
            --    [ { x1 = 0, x2 = 1, y = Just 2, z = Just 3 }
            --    , { x1 = 1, x2 = 2, y = Just 3, z = Just 4 }
            --    ]

              --, I.bar [ C.color C.blue ] .x1 .x2 .y1 .y2 datum

            --, [ { x1 = 0, x2 = 1, y = Just 2, z = Just 3 }
            --  , { x1 = 1, x2 = 2, y = Just 1, z = Just 4 }
            --  ]
            --    |> I.toBinsFromVariable (Just .x1) (Just .x2)
            --    |> I.toBinItems p [ I.grouped ]
            --          [ I.property .z "z" "" [ I.color I.pink ] (always [])
            --          , I.property .y "y" "" [ I.color I.blue ] (always [])
            --          ]
            --    |> List.map I.render
            --    |> S.g []
            --    |> S.map never


              --, data
              --    |> I.toSeriesItems .x
              --        [ I.monotone ]
              --        [ C.property .y [ C.color C.blue, C.circle, C.borderWidth 2 ]
              --        , C.property .z [ C.color C.pink, C.circle ]
              --        ]
              --    |> List.map C.render

            ]

      , C.xAxis [ C.noArrow ]

      --, C.when model.hoveringNew <| \first rest ->
      --    C.tooltipOnTop (\_ -> Item.getTop first |> .x) (\_ -> Item.getTop first |> .y) [] [ tooltip first rest ]
      ]
    ]


tooltip : Item.BarItem Datum -> List (Item.BarItem Datum) -> H.Html msg
tooltip hovered _ =
  H.div []
    [ H.h4
        [ HA.style "max-width" "200px"
        , HA.style "margin-top" "5px"
        , HA.style "margin-bottom" "8px"
        , hovered
            |> Item.getItems
            |> List.head
            |> Maybe.map Item.getColor
            |> Maybe.withDefault "blue"
            |> HA.style "color"
        ]
        [ hovered
            |> Item.getItems
            |> List.head
            |> Maybe.map Item.getName
            |> Maybe.withDefault "WHAT"
            |> H.text
        ]
    , H.div []
        [ H.text "X: "
        , H.text <| Debug.toString <| .x <| Item.getDatum hovered
        ]
    , H.div []
        [ H.text "Y: "
        , H.text <| Debug.toString <| .y <| Item.getDatum hovered
        ]
    ]
