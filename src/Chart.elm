module Chart exposing
    ( chart, Element, bars, bar, just, series
    , Bounds, lowestShouldBe, highestShouldBe, orLower, orHigher, exactly, more, less, window
    , zero, middle
    , xAxis, yAxis, xTicks, yTicks, xLabels, yLabels, grid
    , Event, events, event, Decoder, getCoords, getNearest, getNearestX, getWithin, getWithinX, map, map2, map3, map4

    , tooltip, when
    , svgAt, htmlAt, svg, html, none, label
    , width, height
    , marginTop, marginBottom, marginLeft, marginRight
    , paddingTop, paddingBottom, paddingLeft, paddingRight
    , range, domain, topped
    , start, end, pinned
    , dotted, noArrow, center
    , filterX, filterY, only
    , blue, orange, pink, green, red, purple
    , stacked, property, variation, Property
    , binned

    , amount, floatsCustom, ints, intsCustom, times, timesCustom

    , each, eachBin, eachStack, eachProduct
    , withPlane, withBins, withStacks, withProducts
    )


{-| Make a chart! Documentation is still unfinished!

# Elements
@docs chart, Element
@docs series, scatter, linear, monotone, just
@docs bars, histogram, bar

## Work with bounds
@docs Bounds, startMin, startMax, endMin, endMax, startPad, endPad, zero, middle

# Axis
@docs xAxis, yAxis, xTicks, yTicks, xLabels, yLabels, grid
@docs amount, floats, ints, times, values, format, noArrow, start, end, pinned, only, filterX, filterY

# Events
@docs Event, event, Decoder, getCoords, getNearest, getNearestX, getWithin, getWithinX, map, map2, map3, map4
@docs Metric, Item, Single, Group
@docs getBars, getGroups, getDots, withoutUnknowns
@docs tooltip, tooltipOnTop, when, formatTimestamp

# Attributes
@docs width, height
@docs marginTop, marginBottom, marginLeft, marginRight
@docs paddingTop, paddingBottom, paddingLeft, paddingRight
@docs center
@docs range, domain, topped, static, id, events, htmlAttrs
@docs binWidth, binLabel, topLabel, barColor, tickLength, tickWidth, margin, spacing, rounded, roundBottom
@docs dotted, color, label, unit, dot, area, attrs

# Interop
@docs svgAt, htmlAt, svg, html, none

# Colors
@docs blue, orange, pink, green, red

-}


import Svg.Coordinates as C
import Svg as S
import Svg.Attributes as SA
import Svg.Events as SE
import Html as H
import Html.Attributes as HA
import Intervals as I
import Internal.Property as P
import Time
import Dict exposing (Dict)
import Chart.Item as Item
import Chart.Svg as CS
import Chart.Attributes as CA


-- ATTRS


{-| -}
type alias Attribute c =
  c -> c


{-| -}
width : x -> Attribute { a | width : Maybe x }
width value config =
  { config | width = Just value }


{-| -}
height : Float -> Attribute { a | height : Float }
height value config =
  { config | height = value }


{-| -}
marginTop : Float -> Attribute { a | marginTop : Float }
marginTop value config =
  { config | marginTop = value }


{-| -}
marginBottom : Float -> Attribute { a | marginBottom : Float }
marginBottom value config =
  { config | marginBottom = value }


{-| -}
marginLeft : Float -> Attribute { a | marginLeft : Float }
marginLeft value config =
  { config | marginLeft = value }


{-| -}
marginRight : Float -> Attribute { a | marginRight : Float }
marginRight value config =
  { config | marginRight = value }


{-| -}
paddingTop : Float -> Attribute { a | paddingTop : Float }
paddingTop value config =
  { config | paddingTop = value }


{-| -}
paddingBottom : Float -> Attribute { a | paddingBottom : Float }
paddingBottom value config =
  { config | paddingBottom = value }


{-| -}
paddingLeft : Float -> Attribute { a | paddingLeft : Float }
paddingLeft value config =
  { config | paddingLeft = value }


{-| -}
paddingRight : Float -> Attribute { a | paddingRight : Float }
paddingRight value config =
  { config | paddingRight = value }


{-| -}
range : List (Attribute Bounds) -> Attribute { a | range : Maybe (Bounds -> Bounds) }
range fs config =
  { config | range = Just (\i -> List.foldl (\f b -> f b) i fs) }


{-| -}
domain : List (Attribute Bounds) -> Attribute { a | domain : Maybe (Bounds -> Bounds) }
domain fs config =
  { config | domain = Just (\i -> List.foldl (\f b -> f b) i fs) }


{-| -}
start : x -> Attribute { a | start : Maybe x }
start value config =
  { config | start = Just value }


{-| -}
end : x -> Attribute { a | end : Maybe x }
end value config =
  { config | end = Just value }


{-| -}
pinned : x -> Attribute { a | pinned : x }
pinned value config =
  { config | pinned = value }


{-| -}
dotted : Attribute { a | dotted : Bool }
dotted config =
  { config | dotted = True }


{-| -}
noArrow : Attribute { a | arrow : Bool }
noArrow config =
  { config | arrow = False }


{-| -}
filterX : x -> Attribute { a | filterX : x }
filterX value config =
  { config | filterX = value }


{-| -}
filterY : x -> Attribute { a | filterY : x }
filterY value config =
  { config | filterY = value }


{-| -}
only : x -> Attribute { a | only : x }
only value config =
  { config | only = value }


{-| -}
floats : Attribute { a | produce : Int -> Bounds -> List CS.TickValue }
floats config =
  { config | produce = \a -> CS.produce a CS.floats >> CS.toTickValues identity String.fromFloat }


{-| -}
floatsCustom : (Float -> String) -> Attribute { a | produce : Int -> Bounds -> List CS.TickValue }
floatsCustom formatter config =
  { config | produce = \a -> CS.produce a CS.floats >> CS.toTickValues identity formatter }


{-| -}
ints : Attribute { a | produce : Int -> Bounds -> List CS.TickValue }
ints =
  intsCustom String.fromInt


{-| -}
intsCustom : (Int -> String) -> Attribute { a | produce : Int -> Bounds -> List CS.TickValue }
intsCustom formatter config =
  { config | produce = \a -> CS.produce a CS.ints >> CS.toTickValues toFloat formatter }


{-| -}
times : Time.Zone -> Attribute { a | produce : Int -> Bounds -> List CS.TickValue }
times zone config =
  timesCustom zone (CS.formatTime zone) config


{-| -}
timesCustom : Time.Zone -> (I.Time -> String) -> Attribute { a | produce : Int -> Bounds -> List CS.TickValue }
timesCustom zone formatter config =
  { config | produce = \a -> CS.produce a (CS.times zone) >> CS.toTickValues (toFloat << Time.posixToMillis << .timestamp) formatter }


{-| -}
amount : Int -> Attribute { a | amount : Int }
amount value config =
  { config | amount = value }


{-| -}
topped : Int -> Attribute { a | topped : Maybe Int }
topped value config =
  { config | topped = Just value }


{-| -}
center : Attribute { a | center : Bool }
center config =
  { config | center = True }


{-| -}
events : a -> Attribute { x | events : a }
events value config =
  { config | events = value }




-- ELEMENTS


{-| -}
type alias Container data msg =
    { width : Maybe Float
    , height : Float
    , marginTop : Float
    , marginBottom : Float
    , marginLeft : Float
    , marginRight : Float
    , paddingTop : Float
    , paddingBottom : Float
    , paddingLeft : Float
    , paddingRight : Float
    , responsive : Bool
    , range : Maybe (Bounds -> Bounds)
    , domain : Maybe (Bounds -> Bounds)
    , events : List (Event data msg)
    , htmlAttrs : List (H.Attribute msg)
    , topped : Maybe Int
    , attrs : List (S.Attribute msg)
    }


{-| -}
chart : List (Container data msg -> Container data msg) -> List (Element data msg) -> H.Html msg
chart edits elements =
  let config =
        applyAttrs edits
          { width = Nothing
          , height = 200
          , marginTop = 10
          , marginBottom = 30
          , marginLeft = 30
          , marginRight = 10
          , paddingTop = 10
          , paddingBottom = 0
          , paddingLeft = 0
          , paddingRight = 10
          , responsive = True
          , range = Nothing
          , domain = Nothing
          , topped = Nothing
          , events = []
          , attrs = [ SA.style "overflow: visible;" ]
          , htmlAttrs = []
          }

      plane =
        definePlane config elements

      items =
        getItems plane elements

      tickValues =
        getTickValues plane items elements

      ( beforeEls, chartEls, afterEls ) =
        viewElements config plane tickValues items elements

      toEvent (Event event_) =
        let (Decoder decoder) = event_.decoder in
        CS.Event event_.name (decoder items)
  in
  CS.container plane
    [ CA.attrs config.attrs
    , CA.htmlAttrs config.htmlAttrs
    , if config.responsive then CA.static else identity
    , CA.events (List.map toEvent config.events)
    ]
    beforeEls
    chartEls
    afterEls



-- ELEMENTS


{-| -}
type Element data msg
  = SeriesElement
      (Maybe XYBounds -> Maybe XYBounds)
      (List (Item.Product Item.General data))
      (C.Plane -> S.Svg msg)
  | BarsElement
      (Maybe XYBounds -> Maybe XYBounds)
      (List (Item.Product Item.General data))
      (C.Plane -> TickValues -> TickValues)
      (C.Plane -> S.Svg msg)
  | AxisElement
      (C.Plane -> S.Svg msg)
  | TicksElement
      (C.Plane -> TickValues -> TickValues)
      (C.Plane -> S.Svg msg)
  | LabelsElement
      (C.Plane -> TickValues -> TickValues)
      (C.Plane -> S.Svg msg)
  | GridElement
      (C.Plane -> TickValues -> S.Svg msg)
  | SubElements
      (C.Plane -> List (Item.Product Item.General data) -> List (Element data msg))
  | ListOfElements
      (List (Element data msg))
  | SvgElement
      (C.Plane -> S.Svg msg)
  | HtmlElement
      (C.Plane -> H.Html msg)


type alias XYBounds =
  { x : Bounds
  , y : Bounds
  }


definePlane : Container data msg -> List (Element data msg) -> C.Plane
definePlane config elements =
  let foldBounds el acc =
        case el of
          SeriesElement func _ _ -> func acc
          BarsElement func _ _ _ -> func acc
          AxisElement _ -> acc
          TicksElement _ _ -> acc
          LabelsElement _ _ -> acc
          GridElement _ -> acc
          SubElements _ -> acc
          ListOfElements _ -> acc
          SvgElement _ -> acc
          HtmlElement _ -> acc

      bounds =
        List.foldl foldBounds Nothing elements
          |> Maybe.map (\{ x, y } -> { x = fixSingles x, y = fixSingles y })
          |> Maybe.withDefault { x = { min = 0, max = 10 }, y = { min = 0, max = 10 } }

      fixSingles bs =
        if bs.min == bs.max then { bs | max = bs.min + 10 } else bs

      calcRange =
        case config.range of
          Just edit -> edit bounds.x
          Nothing -> bounds.x

      calcDomain =
        case config.domain of
          Just edit -> edit bounds.y
          Nothing -> lowestShouldBe 0 orLower bounds.y

      scalePadX =
        C.scaleCartesian
          { marginLower = config.marginLeft
          , marginUpper = config.marginRight
          , length = max 1 (Maybe.withDefault 500 config.width - config.paddingLeft - config.paddingRight)
          , data = calcRange
          , min = calcRange.min
          , max = calcRange.max
          }

      scalePadY =
        C.scaleCartesian
          { marginUpper = config.marginTop
          , marginLower = config.marginBottom
          , length = max 1 (config.height - config.paddingBottom - config.paddingTop)
          , data = calcDomain
          , min = calcDomain.min
          , max = calcDomain.max
          }
  in
  { x =
      { marginLower = config.marginLeft
      , marginUpper = config.marginRight
      , length = Maybe.withDefault 500 config.width
      , data = bounds.x
      , min = calcRange.min - scalePadX config.paddingLeft
      , max = calcRange.max + scalePadX config.paddingRight
      }
  , y =
      { marginUpper = config.marginTop
      , marginLower = config.marginBottom
      , length = config.height
      , data = bounds.y
      , min = calcDomain.min - scalePadY config.paddingBottom
      , max = calcDomain.max + scalePadY config.paddingTop
      }
  }


getItems : C.Plane -> List (Element data msg) -> List (Item.Product Item.General data)
getItems plane elements =
  let toItems el acc =
        case el of
          SeriesElement _ items _ -> acc ++ items
          BarsElement _ items _ _ -> acc ++ items
          AxisElement _ -> acc
          TicksElement _ _ -> acc
          LabelsElement _ _ -> acc
          GridElement _ -> acc
          SubElements _ -> acc -- TODO add phantom type to only allow decorative els in this
          ListOfElements _ -> acc
          SvgElement _ -> acc
          HtmlElement _ -> acc
  in
  List.foldl toItems [] elements


{-| -}
type alias TickValues =
  { xs : List Float
  , ys : List Float
  }


getTickValues : C.Plane -> List (Item.Product Item.General data) -> List (Element data msg) -> TickValues
getTickValues plane items elements =
  let toValues el acc =
        case el of
          SeriesElement _ _ _ -> acc
          BarsElement _ _ func _ -> func plane acc
          AxisElement _ -> acc
          TicksElement func _ -> func plane acc
          LabelsElement func _ -> func plane acc
          GridElement _ -> acc
          SubElements func -> List.foldl toValues acc (func plane items)
          ListOfElements _ -> acc
          SvgElement _ -> acc
          HtmlElement _ -> acc
  in
  List.foldl toValues (TickValues [] []) elements


viewElements : Container data msg -> C.Plane -> TickValues -> List (Item.Product Item.General data) -> List (Element data msg) -> ( List (H.Html msg), List (S.Svg msg), List (H.Html msg) )
viewElements config plane tickValues allItems elements =
  let viewOne el ( before, chart_, after ) =
        case el of
          SeriesElement _ _ view  -> ( before, view plane :: chart_, after )
          BarsElement _ _ _ view  -> ( before, view plane :: chart_, after )
          AxisElement view        -> ( before, view plane :: chart_, after )
          TicksElement _ view     -> ( before, view plane :: chart_, after )
          LabelsElement _ view    -> ( before, view plane :: chart_, after )
          GridElement view        -> ( before, view plane tickValues :: chart_, after )
          SubElements func        -> List.foldr viewOne ( before, chart_, after ) (func plane allItems)
          ListOfElements els      -> List.foldr viewOne ( before, chart_, after ) els
          SvgElement view         -> ( before, view plane :: chart_, after )
          HtmlElement view        ->
            ( if List.length chart_ > 0 then before else view plane :: before
            , chart_
            , if List.length chart_ > 0 then view plane :: after else after
            )
  in
  List.foldr viewOne ([], [], []) elements



-- BOUNDS


{-| -}
type alias Bounds =
    { min : Float, max : Float }


{-| -}
fromData : List (data -> Maybe Float) -> List data -> Bounds
fromData toValues data =
  { min = C.minimum toValues data
  , max = C.maximum toValues data
  }


{-| -}
lowestShouldBe : Float -> (Float -> Float -> Float) -> Attribute Bounds
lowestShouldBe x edit bounds =
  { bounds | min = edit x bounds.min }


{-| -}
highestShouldBe : Float -> (Float -> Float -> Float) -> Attribute Bounds
highestShouldBe x edit bounds =
  { bounds | max = edit x bounds.max }


{-| -}
window : Float -> Float -> Attribute Bounds
window min_ max_ x =
  { min = min_, max = max_ }


{-| -}
exactly : Float -> Float -> Float
exactly exact _ =
  exact


{-| -}
orLower : Float -> Float -> Float
orLower least real =
  if real > least then least else real


{-| -}
orHigher : Float -> Float -> Float
orHigher most real =
  if real < most then most else real


{-| -}
more : Float -> Float -> Float
more v x =
  x + v


{-| -}
less : Float -> Float -> Float
less v x =
  x - v


{-| -}
zero : Bounds -> Float
zero bounds =
  clamp bounds.min bounds.max 0


{-| -}
middle : Bounds -> Float
middle bounds =
    bounds.min + (bounds.max - bounds.min) / 2


stretch : Maybe Bounds -> Bounds -> Maybe Bounds
stretch ma b =
  Just <|
    case ma of
      Just a -> { min = min a.min b.min, max = max a.max b.max }
      Nothing -> b



-- EVENT / DECODER


{-| -}
type Event data msg =
  Event
    { name : String
    , decoder : Decoder data msg
    }


{-| -}
event : String -> Decoder data msg -> Event data msg
event name_ decoder =
  Event { name = name_, decoder = decoder }


{-| -}
type Decoder data msg =
  Decoder (List (Item.Product Item.General data) -> C.Plane -> C.Point -> msg)


{-| -}
map : (a -> msg) -> Decoder data a -> Decoder data msg
map f (Decoder a) =
  Decoder <| \ps s p -> f (a ps s p)


{-| -}
map2 : (a -> b -> msg) -> Decoder data a -> Decoder data b -> Decoder data msg
map2 f (Decoder a) (Decoder b) =
  Decoder <| \ps s p -> f (a ps s p) (b ps s p)


{-| -}
map3 : (a -> b -> c -> msg) -> Decoder data a -> Decoder data b -> Decoder data c -> Decoder data msg
map3 f (Decoder a) (Decoder b) (Decoder c) =
  Decoder <| \ps s p -> f (a ps s p) (b ps s p) (c ps s p)


{-| -}
map4 : (a -> b -> c -> d -> msg) -> Decoder data a -> Decoder data b -> Decoder data c -> Decoder data d -> Decoder data msg
map4 f (Decoder a) (Decoder b) (Decoder c) (Decoder d) =
  Decoder <| \ps s p -> f (a ps s p) (b ps s p) (c ps s p) (d ps s p)



{-| -}
getCoords : Decoder data C.Point
getCoords =
  Decoder <| \_ plane searched ->
    { x = C.toCartesianX plane searched.x
    , y = C.toCartesianY plane searched.y
    }


{-| -}
getNearest : (C.Plane -> a -> C.Point) -> (List (Item.Product Item.General data) -> List a) -> Decoder data (List a)
getNearest toPoint filterItems =
  Decoder <| \items plane ->
    CS.getNearest (toPoint plane) (filterItems items) plane


{-| -}
getWithin : Float -> (C.Plane -> a -> C.Point) -> (List (Item.Product Item.General data) -> List a) -> Decoder data (List a)
getWithin radius toPoint filterItems =
  Decoder <| \items plane ->
    CS.getWithin radius (toPoint plane) (filterItems items) plane


{-| -}
getNearestX : (C.Plane -> a -> C.Point) -> (List (Item.Product Item.General data) -> List a) -> Decoder data (List a)
getNearestX toPoint filterItems =
  Decoder <| \items plane ->
    CS.getNearestX (toPoint plane) (filterItems items) plane



{-| -}
getWithinX : Float -> (C.Plane -> a -> C.Point) -> (List (Item.Product Item.General data) -> List a) -> Decoder data (List a)
getWithinX radius toPoint filterItems =
  Decoder <| \items plane ->
    CS.getWithinX radius (toPoint plane) (filterItems items) plane



 -- TOOLTIP


type alias Tooltip =
  { direction : Maybe CA.Direction
  , height : Float
  , width : Float
  , offset : Float
  , pointer : Bool
  , border : String
  , background : String
  }


{-| -}
tooltip : Item.Item a -> List (Attribute Tooltip) -> List (H.Attribute Never) -> List (H.Html Never) -> Element data msg
tooltip i edits attrs_ content =
  html <| \p ->
    let pos = Item.getBounds i in
    if CS.isWithinPlane p pos.x1 pos.y2
    then CS.tooltip p (Item.getPosition p i) edits attrs_ content
    else H.text ""


{-| -}
when : List a -> (a -> List a -> Element data msg) -> Element data msg
when maybeA view =
  case maybeA of
    a :: rest -> view a rest
    [] -> none



-- AXIS


{-| -}
type alias Axis =
    { start : Bounds -> Float
    , end : Bounds -> Float
    , pinned : Bounds -> Float
    , arrow : Bool
    , color : String -- TODO use Color
    }


{-| -}
xAxis : List (CA.Attribute Axis) -> Element item msg
xAxis edits =
  let config =
        applyAttrs edits
          { start = .min
          , end = .max
          , pinned = zero
          , color = ""
          , arrow = True
          }
  in
  AxisElement <| \p ->
    S.g
      [ SA.class "elm-charts__x-axis" ]
      [ CS.line p
          [ CA.color config.color
          , CA.y1 (config.pinned <| toBounds .y p)
          , CA.x1 (config.start <| toBounds .x p)
          , CA.x2 (config.end <| toBounds .x p)
          ]
      , if config.arrow then
          CS.arrow p [ CA.color config.color ]
            { x = config.end <| toBounds .x p
            , y = config.pinned <| toBounds .y p
            }
        else
          S.text ""
      ]


{-| -}
yAxis : List (Axis -> Axis) -> Element item msg
yAxis edits =
  let config =
        applyAttrs edits
          { start = .min
          , end = .max
          , pinned = zero
          , color = ""
          , arrow = True
          }
  in
  AxisElement <| \p ->
    S.g
      [ SA.class "elm-charts__y-axis" ]
      [ CS.line p
          [ CA.color config.color
          , CA.x1 (config.pinned <| toBounds .x p)
          , CA.y1 (config.start <| toBounds .y p)
          , CA.y2 (config.end <| toBounds .y p)
          ]
      , if config.arrow then
          CS.arrow p [ CA.color config.color, CA.rotate -90 ]
            { x = config.pinned <| toBounds .x p
            , y = config.end <| toBounds .y p
            }
        else
          S.text ""
      ]


type alias Ticks =
    { color : String -- TODO use Color -- TODO allow custom color by tick value
    , height : Float
    , width : Float
    , pinned : Bounds -> Float
    , start : Bounds -> Float
    , end : Bounds -> Float
    , only : Float -> Bool
    , amount : Int
    , produce : Int -> Bounds -> List CS.TickValue
    }


{-| -}
xTicks : List (Attribute Ticks) -> Element item msg
xTicks edits =
  let config =
        applyAttrs ([ floats ] ++ edits)
          { color = ""
          , start = .min
          , end = .max
          , pinned = zero
          , amount = 5
          , only = \_ -> True
          , produce = \a b -> []
          , height = 5
          , width = 1
          }

      xBounds p =
        let b = toBounds .x p in
        { min = config.start b
        , max = config.end b
        }

      toTicks p =
        config.produce config.amount (xBounds p)
          |> List.map .value
          |> List.filter config.only

      addTickValues p ts =
        { ts | xs = ts.xs ++ toTicks p }
  in
  TicksElement addTickValues <| \p ->
    let toTick x =
          CS.xTick p
            [ CA.color config.color
            , CA.length config.height
            , CA.width config.width
            ]
            { x = x
            , y = config.pinned (toBounds .y p)
            }
    in
    S.g [ SA.class "elm-charts__x-ticks" ] <| List.map toTick (toTicks p)


{-| -}
yTicks : List (Attribute Ticks) -> Element item msg
yTicks edits =
  let config =
        applyAttrs ([ floats ] ++ edits)
          { color = ""
          , start = .min
          , end = .max
          , pinned = zero
          , only = \_ -> True
          , amount = 5
          , produce = \a b -> []
          , height = 5
          , width = 1
          }

      yBounds p =
        let b = toBounds .y p in
        { min = config.start b
        , max = config.end b
        }

      toTicks p =
        config.produce config.amount (yBounds p)
          |> List.map .value
          |> List.filter config.only

      addTickValues p ts =
        { ts | ys = ts.ys ++ toTicks p }
  in
  TicksElement addTickValues <| \p ->
    let toTick y =
          CS.yTick p
            [ CA.color config.color
            , CA.length config.height
            , CA.width config.width
            ]
            { x = config.pinned (toBounds .x p)
            , y = y
            }
    in
    S.g [ SA.class "elm-charts__y-ticks" ] <| List.map toTick (toTicks p)



type alias Labels =
    { color : String -- TODO use Color
    , pinned : Bounds -> Float
    , start : Bounds -> Float
    , end : Bounds -> Float
    , only : Float -> Bool
    , xOff : Float
    , yOff : Float
    , amount : Int
    , produce : Int -> Bounds -> List CS.TickValue
    }


{-| -}
xLabels : List (Attribute Labels) -> Element item msg
xLabels edits =
  let config =
        applyAttrs ([ floats ] ++ edits)
          { color = "#808BAB"
          , start = .min
          , end = .max
          , only = \_ -> True
          , pinned = zero
          , amount = 5
          , produce = \a b -> []
          , xOff = 0
          , yOff = 20
          }

      xBounds p =
        let b = toBounds .x p in
        { min = config.start b
        , max = config.end b
        }

      toTicks p =
        config.produce config.amount (xBounds p)
          |> List.filter (config.only << .value)

      toTickValues p ts =
        { ts | xs = ts.xs ++ List.map .value (toTicks p) }
  in
  LabelsElement toTickValues <| \p ->
    let toLabel item =
          CS.label p
            [ CA.color config.color
            , CA.xOff config.xOff
            , CA.yOff config.yOff
            ]
            item.label
            { x = item.value
            , y = config.pinned (toBounds .y p)
            }
    in
    S.g [ SA.class "elm-charts__x-labels" ] (List.map toLabel (toTicks p))


{-| -}
yLabels : List (Attribute Labels) -> Element item msg
yLabels edits =
  let config =
        applyAttrs ([ floats ] ++ edits)
          { color = "#808BAB"
          , start = .min
          , end = .max
          , pinned = zero
          , only = \_ -> True
          , amount = 5
          , produce = \a b -> []
          , xOff = -8
          , yOff = 3
          }

      yBounds p =
        let b = toBounds .y p in
        { min = config.start b
        , max = config.end b
        }

      toTicks p =
        config.produce config.amount (yBounds p)
          |> List.filter (config.only << .value)

      toTickValues p ts =
        { ts | ys = ts.ys ++ List.map .value (toTicks p) }
  in
  LabelsElement toTickValues <| \p ->
    let toLabel item =
          CS.label p
            [ CA.color config.color
            , CA.xOff config.xOff
            , CA.yOff config.yOff
            , CA.rightAlign
            ]
            item.label
            { x = config.pinned (toBounds .x p)
            , y = item.value
            }
    in
    S.g [ SA.class "elm-charts__y-labels" ] (List.map toLabel (toTicks p))



type alias Grid msg =
    { color : String -- TODO use Color
    , width : Float
    , dotted : Bool
    , filterX : Bounds -> List Float
    , filterY : Bounds -> List Float
    , attrs : List (S.Attribute msg)
    }


{-| -}
grid : List (Grid msg -> Grid msg) -> Element item msg
grid edits =
  let config =
        applyAttrs edits
          { color = "#EFF2FA"
          , filterX = zero >> List.singleton
          , filterY = zero >> List.singleton
          , width = 1
          , attrs = []
          , dotted = False
          }

      notTheseX p =
        config.filterX (toBounds .x p)

      notTheseY p =
        config.filterY (toBounds .y p)

      toXGrid p v =
        if List.member v (notTheseX p)
        then Nothing else Just <|
          CS.line p [ CA.color config.color, CA.width config.width, CA.x1 v ]

      toYGrid p v =
        if List.member v (notTheseY p)
        then Nothing else Just <|
          CS.line p [ CA.color config.color, CA.width config.width, CA.y1 v ]

      toDot p x y =
        if List.member x (notTheseX p) || List.member y (notTheseY p)
        then Nothing
        else Just <| CS.dot p .x .y [ CA.color config.color, CA.size config.width, CA.circle ] { x = x, y = y }
  in
  GridElement <| \p vs ->
    S.g [ SA.class "elm-charts__grid" ] <|
      if config.dotted then
        List.concatMap (\x -> List.filterMap (toDot p x) vs.ys) vs.xs
      else
        [ S.g [ SA.class "elm-charts__x-grid" ] (List.filterMap (toXGrid p) vs.xs)
        , S.g [ SA.class "elm-charts__y-grid" ] (List.filterMap (toYGrid p) vs.ys)
        ]




-- BARS


{-| -}
type alias Property data meta inter deco =
  P.Property data meta inter deco


{-| -}
property : (data -> Maybe Float) -> String -> String -> List (Attribute inter) -> List (Attribute deco) -> Property data Item.Metric inter deco
property y_ name_ unit_ =
  P.property y_ { name = name_, unit = unit_ }


{-| -}
bar : (data -> Maybe Float) -> String -> String -> List (Attribute deco) -> Property data Item.Metric inter deco
bar y_ name_ unit_ =
  P.property y_ { name = name_, unit = unit_ } []


{-| -}
variation : (data -> List (Attribute deco)) -> Property data Item.Metric inter deco -> Property data Item.Metric inter deco
variation =
  P.variation


{-| -}
stacked : List (Property data meta inter deco) -> Property data meta inter deco
stacked =
  P.stacked


{-| -}
just : (data -> Float) -> (data -> Maybe Float)
just toY =
  toY >> Just


{-| -}
type alias Bars data =
  { spacing : Float
  , margin : Float
  , roundTop : Float
  , roundBottom : Float
  , grouped : Bool
  , x1 : Maybe (data -> Float)
  , x2 : Maybe (data -> Float)
  }


{-| -}
type alias Bar =
  { roundTop : Float
  , roundBottom : Float
  , color : String
  , border : String
  , borderWidth : Float
  -- TODO pattern
  -- TODO aura
  }


{-| -}
bars : List (Attribute (Bars data)) -> List (Property data Item.Metric () Bar) -> List data -> Element data msg
bars edits properties data =
  let items =
        Item.toBarSeries edits properties data

      generalized =
        items
          |> List.concatMap Item.getProducts
          |> List.map (Item.toGeneral Item.BarConfig)

      bins =
        items
          |> List.concatMap Item.getProducts
          |> Item.groupBy Item.isSameBin

      toTicks plane acc =
        { acc | xs = List.concatMap (\i -> [ Item.getX1 plane i, Item.getX2 plane i ]) bins }

      toXYBounds =
        makeBounds
          [ Item.getBounds >> .x1 >> Just
          , Item.getBounds >> .x2 >> Just
          ]
          [ Item.getBounds >> .y1 >> Just
          , Item.getBounds >> .y2 >> Just
          ]
          bins
  in
  BarsElement toXYBounds generalized toTicks <| \ plane ->
    S.g [ SA.class "elm-charts__bar-series" ] (List.map (Item.render plane) items)
      |> S.map never



-- SERIES


{-| -}
series : (data -> Float) -> List (Property data Item.Metric CS.Interpolation CS.Dot) -> List data -> Element data msg
series toX properties data =
  let items =
        Item.toDotSeries toX properties data

      generalized =
        items
          |> List.concatMap Item.getProducts
          |> List.map (Item.toGeneral Item.DotConfig)

      toXYBounds =
        makeBounds
          [ Item.getBounds >> .x1 >> Just
          , Item.getBounds >> .x2 >> Just
          ]
          [ Item.getBounds >> .y1 >> Just
          , Item.getBounds >> .y2 >> Just
          ]
          items
  in
  SeriesElement toXYBounds generalized <| \p ->
    S.g [ SA.class "elm-charts__dot-series" ] (List.map (Item.render p) items)
      |> S.map never



-- OTHER


{-| -}
withPlane : (C.Plane -> List (Element data msg)) -> Element data msg
withPlane func =
  SubElements <| \p is -> func p


{-| -}
withBins : (C.Plane -> List (Item.Group (Item.Bin data) Item.General data) -> List (Element data msg)) -> Element data msg
withBins func =
  SubElements <| \p is -> func p (Item.groupBy Item.isSameBin is)


{-| -}
withStacks : (C.Plane -> List (Item.Group (Item.Stack data) Item.General data) -> List (Element data msg)) -> Element data msg
withStacks func =
  SubElements <| \p is -> func p (Item.groupBy Item.isSameStack is)


{-| -}
withProducts : (C.Plane -> List (Item.Product Item.General data) -> List (Element data msg)) -> Element data msg
withProducts func =
  SubElements <| \p is -> func p is


{-| -}
each : (C.Plane -> List a) -> (C.Plane -> a -> List (Element data msg)) -> Element data msg
each toItems func =
  SubElements <| \p _ -> List.concatMap (func p) (toItems p)


{-| -}
eachBin : (C.Plane -> Item.Group (Item.Bin data) Item.General data -> List (Element data msg)) -> Element data msg
eachBin func =
  SubElements <| \p is -> List.concatMap (func p) (Item.groupBy Item.isSameBin is)


{-| -}
eachStack : (C.Plane -> Item.Group (Item.Stack data) Item.General data -> List (Element data msg)) -> Element data msg
eachStack func =
  SubElements <| \p is -> List.concatMap (func p) (Item.groupBy Item.isSameStack is)


{-| -}
eachProduct : (C.Plane -> Item.Product Item.General data -> List (Element data msg)) -> Element data msg
eachProduct func =
  SubElements <| \p is -> List.concatMap (func p) is


{-| -}
label : List (Attribute CS.Label) -> String -> C.Point -> Element data msg
label attrs string point =
  SvgElement <| \p -> CS.label p attrs string point


{-| -}
svg : (C.Plane -> S.Svg msg) -> Element data msg
svg func =
  SvgElement <| \p -> func p


{-| -}
html : (C.Plane -> H.Html msg) -> Element data msg
html func =
  HtmlElement <| \p -> func p


{-| -}
svgAt : (Bounds -> Float) -> (Bounds -> Float) -> Float -> Float -> List (S.Svg msg) -> Element data msg
svgAt toX toY xOff yOff view =
  SvgElement <| \p ->
    S.g [ CS.position p (toX <| toBounds .x p) (toY <| toBounds .y p) xOff yOff ] view


{-| -}
htmlAt : (Bounds -> Float) -> (Bounds -> Float) -> Float -> Float -> List (H.Attribute msg) -> List (H.Html msg) -> Element data msg
htmlAt toX toY xOff yOff att view =
  HtmlElement <| \p ->
    CS.positionHtml p (toX <| toBounds .x p) (toY <| toBounds .y p) xOff yOff att view


{-| -}
none : Element data msg
none =
  HtmlElement <| \_ -> H.text ""



-- HELPERS


makeBounds : List (a -> Maybe Float) -> List (a -> Maybe Float) -> List a -> Maybe XYBounds -> Maybe XYBounds
makeBounds xs ys data prev =
  let fold vs datum bounds =
        { min = min (getMin vs datum) bounds.min
        , max = max (getMax vs datum) bounds.max
        }

      getMin toValues datum =
        List.minimum (getValues toValues datum)
          |> Maybe.withDefault 0

      getMax toValues datum =
        List.maximum (getValues toValues datum)
          |> Maybe.withDefault 1

      getValues toValues datum =
        List.filterMap (\v -> v datum) toValues
  in
  case data of
    [] -> prev
    first :: rest ->
      case prev of
        Just { x, y } ->
          Just
            { x = List.foldl (fold xs) x data
            , y = List.foldl (fold ys) y data
            }

        Nothing ->
          Just
            { x = List.foldl (fold xs)
                    { min = getMin xs first
                    , max = getMax xs first
                    }
                    rest
            , y = List.foldl (fold ys)
                    { min = getMin ys first
                    , max = getMax ys first
                    }
                    rest
            }


toBounds : (C.Plane -> C.Axis) -> C.Plane -> Bounds
toBounds toA plane =
  let { min, max } = toA plane
  in { min = min, max = max }


toDataBounds : (C.Plane -> C.Axis) -> C.Plane -> Bounds
toDataBounds toA plane =
  let axis = toA plane
  in axis.data


mapWithPrev : (Maybe a -> a -> b) -> List a -> List b
mapWithPrev =
  let fold prev acc func ds =
        case ds of
          a :: rest -> fold (Just a) (func prev a :: acc) func rest
          [] -> acc
  in
  fold Nothing []


mapSurrounding : (Maybe a -> a -> Maybe a -> b) -> List a -> List b
mapSurrounding =
  let fold prev acc func ds =
        case ds of
          a :: b :: rest -> fold (Just a) (func prev a (Just b) :: acc) func rest
          a :: rest -> fold (Just a) (func prev a Nothing :: acc) func rest
          [] -> acc
  in
  fold Nothing []


applyAttrs : List (a -> a) -> a -> a
applyAttrs funcs default =
  let apply f a = f a in
  List.foldl apply default funcs



-- DEFAULTS / COLOR


toDefaultColor : Int -> String
toDefaultColor index =
  let numOfColors = Dict.size colors
      colorIndex = remainderBy numOfColors index
  in
  Dict.get colorIndex colors
    |> Maybe.withDefault blue


colors : Dict Int String
colors =
  [ blue, orange, green, pink, purple, red ]
    |> List.indexedMap Tuple.pair
    |> Dict.fromList


{-| -}
blue : String
blue =
  "rgb(5,142,218)"


{-| -}
orange : String
orange =
  "rgb(244, 149, 69)"


{-| -}
pink : String
pink =
  "rgb(253, 121, 168)"


{-| -}
green : String
green =
  "rgb(68, 201, 72)"


{-| -}
red : String
red =
  "rgb(215, 31, 10)"


{-| -}
purple : String
purple =
  "rgb(170, 80, 208)"



-- HELPERS


binned : Float -> (data -> Float) -> List data -> List { bin : Float, data : List data }
binned w func =
  let fold datum acc =
        Dict.update (ceiling (func datum)) (Maybe.map (\ds -> datum :: ds) >> Maybe.withDefault [datum] >> Just) acc

      ceiling b =
        let floored = toFloat (floor (b / w)) * w in
        b - (b - floored) + w
  in
  List.foldr fold Dict.empty
    >> Dict.toList
    >> List.map (\(bin, ds) -> { bin = bin, data = ds })

