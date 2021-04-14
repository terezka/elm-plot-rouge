module Chart.Item exposing
  ( Item(..), AnySeries(..), Series, Product
  , Collection, toCollection, getBins
  , getBarSeries, getDotSeries, getProducts, getStacked
  , render, getValue, getCenter, getPosition, getDatum, getTop, getItems
  , getColor, getName
  , getBounds
  , getX1, getX2, getY2, getY1
  , Property, Metric
  , Bars, toBarSeries, Bin
  , toDotSeries
  )


import Html as H exposing (Html)
import Html.Attributes as HA
import Svg as S exposing (Svg)
import Svg.Attributes as SA
import Svg.Coordinates as Coord exposing (Point, Position, Plane, scaleCartesian)
import Dict exposing (Dict)
import Internal.Property as P exposing (Property)
import Chart.Svg as S
import Chart.Attributes as CA


-- TODO clean up plane
-- TODO clean up property
-- TODO replace system.id with inline clippath
-- TODO clean up labels / axes etc
-- TODO rename series to scatter
-- TODO add element index


{-| -}
type Item a =
  Item
    { details : a
    , render : Plane -> a -> Position -> Svg Never
    , bounds : a -> Position
    , position : Plane -> a -> Position
    }


{-| -} -- TODO exposed?
type AnySeries datum
  = BarSeries (Series (Bars datum) S.Bar datum)
  | DotSeries (Series S.Interpolation S.Dot datum)


{-| -}
type alias Series inter config datum =
  Item
    { config : inter
    , items : List (Product config datum)
    }


{-| -}
type alias Product config datum =
  Item
    { datum : datum
    , config : config
    , propertyNo : Int
    , propertyNoSub : Int
    , name : String
    , unit : String
    , x1 : Float
    , x2 : Float
    , y : Maybe Float
    }


{-| -}
getDotSeries : AnySeries data -> Maybe (Series S.Interpolation S.Dot data)
getDotSeries item =
  case item of
    DotSeries series -> Just series
    BarSeries _ -> Nothing


{-| -}
getBarSeries : AnySeries data -> Maybe (Series (Bars data) S.Bar data)
getBarSeries item =
  case item of
    DotSeries _ -> Nothing
    BarSeries series -> Just series


{-| -}
type alias Collection inter item =
  Item
    { config : inter
    , items : List item
    }


{-| -}
toCollection : c -> (a -> List (Item x)) -> List a -> Collection c a
toCollection config toProduct items =
  Item
    { details =
        { config = config
        , items = items
        }
    , bounds = \c ->
        { x1 = Coord.minimum [ getBounds >> .x1 >> Just ] (List.concatMap toProduct c.items)
        , x2 = Coord.maximum [ getBounds >> .x2 >> Just ] (List.concatMap toProduct c.items)
        , y1 = Coord.minimum [ getBounds >> .y1 >> Just ] (List.concatMap toProduct c.items)
        , y2 = Coord.maximum [ getBounds >> .y2 >> Just ] (List.concatMap toProduct c.items)
        }
    , position = \plane c ->
        { x1 = Coord.minimum [ getX1 plane >> Just ] (List.concatMap toProduct c.items)
        , x2 = Coord.maximum [ getX2 plane >> Just ] (List.concatMap toProduct c.items)
        , y1 = Coord.minimum [ getY1 plane >> Just ] (List.concatMap toProduct c.items)
        , y2 = Coord.maximum [ getY2 plane >> Just ] (List.concatMap toProduct c.items)
        }
    , render = \plane c _ ->
        S.g [ SA.class "elm-charts__collection" ]
          (List.map (render plane) (List.concatMap toProduct c.items))
    }


{-| -}
getBins : List (Product config data) -> List (List (Product config data))
getBins products =
  let sortBy func (Item prod) =
        Dict.update (func prod.details) <| \prevM ->
          case prevM of
            Just prev -> Just (Item prod :: prev)
            Nothing -> Just [ Item prod ]
  in
  products
    |> List.foldl (sortBy .x1) Dict.empty
    |> Dict.values


{-| -}
getStacked : List (Product config data) -> List (List (List (Product config data)))
getStacked products =
  let sortBy func (Item prod) =
        Dict.update (func prod.details) <| \prevM ->
          case prevM of
            Just prev -> Just (Item prod :: prev)
            Nothing -> Just [ Item prod ]
  in
  products
    |> List.foldl (sortBy .x1) Dict.empty
    |> Dict.values
    |> List.map (Dict.values << List.foldl (sortBy .propertyNo) Dict.empty)


{-| -}
getProducts : Series inter config data -> List (Product config data)
getProducts (Item series) =
  series.details.items


{-| -}
getColor : Product { a | color : String } data -> String
getColor (Item config) =
  config.details.config.color


{-| -}
getName : Product config data -> String
getName (Item config) =
  config.details.name


{-| -}
getPosition : Plane -> Item x -> Position
getPosition plane (Item config) =
  config.position plane config.details


{-| -}
getTop : Plane -> Item x -> Point
getTop plane (Item config) =
  let pos = config.position plane config.details in
  { x = pos.x1 + (pos.x2 - pos.x1) / 2
  , y = pos.y2
  }


{-| -}
getBottom : Plane -> Item x -> Point
getBottom plane (Item config) =
  let pos = config.position plane config.details in
  { x = pos.x1 + (pos.x2 - pos.x1) / 2
  , y = pos.y1
  }


{-| -}
getLeft : Plane -> Item x -> Point
getLeft plane (Item config) =
  let pos = config.position plane config.details in
  { x = pos.x1
  , y = pos.y1 + (pos.y2 - pos.y1) / 2
  }


{-| -}
getRight : Plane -> Item x -> Point
getRight plane (Item config) =
  let pos = config.position plane config.details in
  { x = pos.x2
  , y = pos.y1 + (pos.y2 - pos.y1) / 2
  }


{-| -}
getCenter : Plane -> Item x -> Point
getCenter plane (Item config) =
  let pos = config.position plane config.details in
  { x = pos.x1 + (pos.x2 - pos.x1) / 2
  , y = pos.y1 + (pos.y2 - pos.y1) / 2
  }


getX1 : Plane -> Item x -> Float
getX1 plane (Item config) =
  let pos = config.position plane config.details in
  pos.x1


getX2 : Plane -> Item x -> Float
getX2 plane (Item config) =
  let pos = config.position plane config.details in
  pos.x2


getY1 : Plane -> Item x -> Float
getY1 plane (Item config) =
  let pos = config.position plane config.details in
  pos.y1


getY2 : Plane -> Item x -> Float
getY2 plane (Item config) =
  let pos = config.position plane config.details in
  pos.y2


getBounds : Item x -> Position
getBounds (Item config) =
  config.bounds config.details


{-| -}
getDatum : Item { config | datum : datum } -> datum
getDatum (Item config) =
  config.details.datum


{-| -}
getValue : Item { config | y : value } -> value
getValue (Item config) =
  config.details.y


{-| -}
render : Plane -> Item x -> Svg Never
render plane (Item config) =
  config.render plane config.details (config.position plane config.details)


{-| -}
getItems : Item { x | items : List a } -> List a
getItems (Item config) =
  config.details.items



-- PROPERTY


{-| -}
type alias Metric =
  { name : String
  , unit : String
  }


{-| -}
type alias Property data meta inter deco =
  P.Property data meta inter deco



-- BAR


{-| -}
type alias Bin data =
  { datum : data
  , start : Float
  , end : Float
  }


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


toBarSeries : List (CA.Attribute (Bars data)) -> List (Property data Metric () S.Bar) -> List data -> List (Series (Bars data) S.Bar data)
toBarSeries barsAttrs properties data =
  let barsConfig : Bars data
      barsConfig =
        apply barsAttrs
          { spacing = 0.01
          , margin = 0.1
          , roundTop = 0
          , roundBottom = 0
          , grouped = False
          , x1 = Nothing
          , x2 = Nothing
          }

      toBin : Int -> Maybe data -> data -> Maybe data -> Bin data
      toBin index prevM curr nextM =
        case ( barsConfig.x1, barsConfig.x2 ) of
          ( Nothing, Nothing ) ->
            { datum = curr, start = toFloat (index + 1) - 0.5, end = toFloat (index + 1) + 0.5 }

          ( Just toStart, Nothing ) ->
            case ( prevM, nextM ) of
              ( _, Just next ) ->
                { datum = curr, start = toStart curr, end = toStart next }
              ( Just prev, Nothing ) ->
                { datum = curr, start = toStart curr, end = toStart curr + (toStart curr - toStart prev) }
              ( Nothing, Nothing ) ->
                { datum = curr, start = toStart curr, end = toStart curr + 1 }

          ( Nothing, Just toEnd ) ->
            case ( prevM, nextM ) of
              ( Just prev, _ ) ->
                { datum = curr, start = toEnd prev, end = toEnd curr }
              ( Nothing, Just next ) ->
                { datum = curr, start = toEnd curr - (toEnd next - toEnd curr), end = toEnd curr }
              ( Nothing, Nothing ) ->
                { datum = curr, start = toEnd curr - 1, end = toEnd curr }

          ( Just toStart, Just toEnd ) ->
            { datum = curr, start = toStart curr, end = toEnd curr }


      toSeriesItem : List (Bin data) -> List (P.Config data Metric () S.Bar) -> Int -> Int -> P.Config data Metric () S.Bar -> Series (Bars data) S.Bar data
      toSeriesItem bins sections barIndex sectionIndex section =
        Item
          { details =
              { config = barsConfig
              , items = List.map (toBarItem sections barIndex sectionIndex section) bins
              }
          , bounds = \c ->
              { x1 = Coord.minimum [ getBounds >> .x1 >> Just ] c.items
              , x2 = Coord.maximum [ getBounds >> .x2 >> Just ] c.items
              , y1 = Coord.minimum [ getBounds >> .y1 >> Just ] c.items
              , y2 = Coord.maximum [ getBounds >> .y2 >> Just ] c.items
              }
          , position = \plane c ->
              { x1 = Coord.minimum [ getX1 plane >> Just ] c.items
              , x2 = Coord.maximum [ getX2 plane >> Just ] c.items
              , y1 = Coord.minimum [ getY1 plane >> Just ] c.items
              , y2 = Coord.maximum [ getY2 plane >> Just ] c.items
              }
          , render = \plane config _ ->
              S.g [ SA.class "elm-charts__bar-series" ] (List.map (render plane) config.items)
          }


      toBarItem : List (P.Config data Metric () S.Bar) -> Int -> Int -> P.Config data Metric () S.Bar -> Bin data -> Product S.Bar data
      toBarItem sections barIndex sectionIndex section bin =
        let numOfBars = if barsConfig.grouped then toFloat (List.length properties) else 1
            numOfSections = toFloat (List.length sections)

            start = bin.start
            end = bin.end
            visual = section.visual bin.datum
            value = section.value bin.datum

            length = end - start
            margin = length * barsConfig.margin
            width = (length - margin * 2 - (numOfBars - 1) * barsConfig.spacing) / numOfBars
            offset = toFloat barIndex * width + toFloat barIndex * barsConfig.spacing

            x1 = start + margin + offset
            x2 = start + margin + offset + width
            y1 = Maybe.withDefault 0 visual - Maybe.withDefault 0 value
            y2 = Maybe.withDefault 0 visual

            isFirst = sectionIndex == 0
            isLast = toFloat sectionIndex == numOfSections - 1
            isSingle = numOfSections == 1

            roundTop = if isSingle || isLast then barsConfig.roundTop else 0
            roundBottom = if isSingle || isFirst then barsConfig.roundBottom else 0
            color = toDefaultColor (barIndex + sectionIndex)
            defaultAttrs = [ CA.roundTop roundTop, CA.roundBottom roundBottom, CA.color color ]
            attrs = defaultAttrs ++ section.attrs ++ section.extra bin.datum
        in
        Item
          { details =
              { name = section.meta.name
              , unit = section.meta.unit
              , datum = bin.datum
              , propertyNo = barIndex
              , propertyNoSub = sectionIndex
              , x1 = start
              , x2 = end
              , y = value
              , config =
                  apply attrs
                    { roundTop = 0
                    , roundBottom = 0
                    , color = "blue" -- TODO
                    , border = "white"
                    , borderWidth = 0
                    }
              }
          , bounds = \config ->
              { x1 = x1, x2 = x2, y1 = y1, y2 = y2 }
          , position = \_ config ->
              { x1 = x1, x2 = x2, y1 = y1, y2 = y2 }
          , render = \plane config position ->
              S.bar plane attrs position
          }
  in
  withSurround data toBin |> \bins ->
    List.map P.toConfigs properties
      |> List.indexedMap (\barIndex props -> List.indexedMap (toSeriesItem bins props barIndex) (List.reverse props))
      |> List.concat



-- SERIES


{-| -}
toDotSeries : (data -> Float) -> List (Property data Metric S.Interpolation S.Dot) -> List data -> List (Series S.Interpolation S.Dot data)
toDotSeries toX properties data =
  let toInterConfig attrs =
        apply attrs
          { method = Nothing
          , color = CA.blue
          , width = 1
          , opacity = 0
          }

      toDotConfig attrs =
        apply attrs
          { color = CA.blue
          , opacity = 1
          , size = 6
          , border = "white"
          , borderWidth = 1
          , aura = 0
          , auraWidth = 10
          , shape = Nothing
          }

      toSeriesItem lineIndex sublineIndex prop =
        let dotItems = List.map (toDotItem lineIndex sublineIndex prop interConfig) data
            interAttr = [ CA.color (toDefaultColor lineIndex) ] ++ prop.inter
            interConfig = toInterConfig interAttr
        in
        Item
          { details =
              { items = dotItems
              , config = interConfig
              }
          , render = \plane _ _ ->
              let toBottom datum_ =
                    Maybe.map2 (\real visual -> visual - real) (prop.value datum_) (prop.visual datum_)
              in
              S.g
                [ SA.class "elm-charts__series" ]
                [ S.area plane toX (Just toBottom) prop.visual interAttr data
                , S.interpolation plane toX prop.visual interAttr data
                , S.g [ SA.class "elm-charts__dots" ] (List.map (render plane) dotItems)
                ]
          , bounds = \c ->
              { x1 = Coord.minimum [ getBounds >> .x1 >> Just ] c.items
              , x2 = Coord.maximum [ getBounds >> .x2 >> Just ] c.items
              , y1 = Coord.minimum [ getBounds >> .y1 >> Just ] c.items
              , y2 = Coord.maximum [ getBounds >> .y2 >> Just ] c.items
              }
          , position = \plane c ->
              { x1 = Coord.minimum [ getX1 plane >> Just ] c.items
              , x2 = Coord.maximum [ getX2 plane >> Just ] c.items
              , y1 = Coord.minimum [ getY1 plane >> Just ] c.items
              , y2 = Coord.maximum [ getY2 plane >> Just ] c.items
              }
          }

      toDotItem lineIndex sublineIndex prop interConfig datum_ =
        let defaultAttrs = [ CA.color interConfig.color, if interConfig.method == Nothing then CA.circle else identity ]
            dotAttrs = defaultAttrs ++ prop.attrs ++ prop.extra datum_
            config = toDotConfig dotAttrs
            x_ = toX datum_
            y_ = Maybe.withDefault 0 (prop.visual datum_)
        in
        Item
          { render = \plane _ _ ->
              case prop.value datum_ of
                Nothing -> S.text ""
                Just _ -> S.dot plane .x .y dotAttrs { x = x_, y = y_ }
          , bounds = \_ ->
              { x1 = x_
              , x2 = x_
              , y1 = y_
              , y2 = y_
              }
          , position = \plane _ ->
              let radius = Maybe.withDefault 0 <| Maybe.map (S.toRadius config.size) config.shape
                  radiusX_ = scaleCartesian plane.x radius
                  radiusY_ = scaleCartesian plane.y radius
              in
              { x1 = x_ - radiusX_
              , x2 = x_ + radiusX_
              , y1 = y_ - radiusY_
              , y2 = y_ + radiusY_
              }
          , details =
              { datum = datum_
              , propertyNo = lineIndex
              , propertyNoSub = sublineIndex
              , x1 = x_
              , x2 = x_
              , y = prop.value datum_
              , name = prop.meta.name
              , unit = prop.meta.unit
              , config = config
              }
          }
  in
  List.map P.toConfigs properties
    |> List.indexedMap (\lineIndex ps -> List.indexedMap (toSeriesItem lineIndex) ps)
    |> List.concat



-- TOOLTIP

--type alias Tooltip

--tooltip : Tooltip -> Html msg


-- HELPERS


apply : List (a -> a) -> a -> a
apply funcs default =
  let apply_ f a = f a in
  List.foldl apply_ default funcs


withSurround : List a -> (Int -> Maybe a -> a -> Maybe a -> b) -> List b
withSurround all func =
  let fold index prev acc list =
        case list of
          a :: b :: rest -> fold (index + 1) (Just a) (acc ++ [func index prev a (Just b)]) (b :: rest)
          a :: [] -> acc ++ [func index prev a Nothing]
          [] -> acc
  in
  fold 0 Nothing [] all



-- DEFAULTS


toDefaultColor : Int -> String
toDefaultColor =
  toDefault S.blue [ S.blue, S.pink, S.orange, S.green, S.purple, S.red ]


toDefault : a -> List a -> Int -> a
toDefault default items index =
  let dict = Dict.fromList (List.indexedMap Tuple.pair items)
      numOfItems = Dict.size dict
      itemIndex = remainderBy numOfItems index
  in
  Dict.get itemIndex dict
    |> Maybe.withDefault default

