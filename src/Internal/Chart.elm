module Internal.Chart exposing
  ( Point
  , Container, container
  , Line, line, Label, label, Arrow, arrow
  , position
  , Bar, bar
  , Series, Method, linear, monotone, interpolation, area
  , Dot, circle, triangle, square, diamond, plus, cross
  --, tooltip
  , x, x1, x2, y, y1, y2, xOff, yOff, border, borderWidth, fontSize, color, width, leftAlign, rightAlign
  , rotate, length, roundTop, roundBottom
  )

import Html as H exposing (Html)
import Html.Attributes as HA
import Svg as S exposing (Svg)
import Svg.Attributes as SA
import Svg.Events as SE
import Svg.Coordinates as Coord exposing (Plane, place, toSVGX, toSVGY, toCartesianX, toCartesianY, scaleSVG, scaleCartesian, placeWithOffset)
import Svg.Commands as C exposing (..)
import Internal.Interpolation as Interpolation
import Json.Decode as Json
import DOM


{-| -}
type alias Point =
  { x : Float
  , y : Float
  }


{-| -}
type alias Attribute c =
  c -> c


{-| -}
x : Float -> Attribute { a | x : Float }
x value config =
  { config | x = value }


{-| -}
x1 : Float -> Attribute { a | x1 : Maybe Float }
x1 value config =
  { config | x1 = Just value }


{-| -}
x2 : Float -> Attribute { a | x2 : Maybe Float }
x2 value config =
  { config | x2 = Just value }


{-| -}
y : Float -> Attribute { a | y : Float }
y value config =
  { config | y = value }


{-| -}
y1 : Float -> Attribute { a | y1 : Maybe Float }
y1 value config =
  { config | y1 = Just value }


{-| -}
y2 : Float -> Attribute { a | y2 : Maybe Float }
y2 value config =
  { config | y2 = Just value }


{-| -}
xOff : Float -> Attribute { a | xOff : Float }
xOff value config =
  { config | xOff = value }


{-| -}
yOff : Float -> Attribute { a | yOff : Float }
yOff value config =
  { config | yOff = value }


{-| -}
border : String -> Attribute { a | border : String }
border value config =
  { config | border = value }


{-| -}
borderWidth : Float -> Attribute { a | borderWidth : Float }
borderWidth value config =
  { config | borderWidth = value }


{-| -}
fontSize : Int -> Attribute { a | fontSize : Maybe Int }
fontSize value config =
  { config | fontSize = Just value }


{-| -}
color : String -> Attribute { a | color : String }
color value config =
  { config | color = value }


{-| -}
width : Float -> Attribute { a | width : Float }
width value config =
  { config | width = value }


{-| -}
length : Float -> Attribute { a | length : Float }
length value config =
  { config | length = value }


{-| -}
rotate : Float -> Attribute { a | rotate : Float }
rotate value config =
  { config | rotate = config.rotate + value }


{-| -}
roundTop : Float -> Attribute { a | roundTop : Float }
roundTop value config =
  { config | roundTop = value }


{-| -}
roundBottom : Float -> Attribute { a | roundBottom : Float }
roundBottom value config =
  { config | roundBottom = value }


{-| -}
rightAlign : Attribute { a | anchor : Anchor }
rightAlign config =
  { config | anchor = Start }


{-| -}
leftAlign : Attribute { a | anchor : Anchor }
leftAlign config =
  { config | anchor = End }



-- CONTAINER


{-| -}
type alias Container msg =
  { id : String
  , attrs : List (S.Attribute msg)
  , htmlAttrs : List (H.Attribute msg)
  , responsive : Bool
  , events : List (Event msg)
  }


{-| -}
type alias Event msg =
  { name : String
  , handler : Plane -> Point -> msg
  }


container : Plane -> List (Attribute (Container msg)) -> List (Html msg) -> List (Svg msg) -> List (Html msg) -> Html msg
container plane edits below chartEls above =
  -- TODO seperate plane from container size
  let config =
        apply edits
          { id = "you-should-add-a-unique-id-here"
          , attrs = []
          , htmlAttrs = []
          , responsive = True
          , events = []
          }

      htmlAttrsDef =
        [ HA.class "elm-charts__container"
        , HA.style "position" "relative"
        ]

      htmlAttrsSize =
        if config.responsive then
          []
        else
          [ HA.style "width" (String.fromFloat plane.x.length ++ "px")
          , HA.style "height" (String.fromFloat plane.y.length ++ "px")
          ]

      htmlAttrs =
        config.htmlAttrs ++ htmlAttrsDef ++ htmlAttrsSize

      chart =
        S.svg
          (svgAttrsSize ++ config.attrs)
          ([frame] ++ chartEls ++ [catcher])

      svgAttrsSize =
        if config.responsive then
          [ SA.viewBox ("0 0 " ++ String.fromFloat plane.x.length ++ " " ++ String.fromFloat plane.y.length) ]
        else
          [ SA.width (String.fromFloat plane.x.length)
          , SA.height (String.fromFloat plane.y.length)
          ]

      frame =
        S.defs [] [ S.clipPath [ SA.id config.id ] [ S.rect chartPosition [] ] ]

      catcher =
        S.rect (chartPosition ++ List.map toEvent config.events) []

      toEvent event =
        SE.on event.name (decodePoint plane event.handler)

      chartPosition =
        [ SA.x (String.fromFloat plane.x.marginLower)
        , SA.y (String.fromFloat plane.y.marginUpper)
        , SA.width (String.fromFloat (plane.x.length - plane.x.marginLower - plane.x.marginUpper))
        , SA.height (String.fromFloat (plane.y.length - plane.y.marginLower - plane.y.marginUpper))
        , SA.fill "transparent"
        ]
  in
  H.div htmlAttrs (below ++ [ chart ] ++ above)



-- LINE


{-| -}
type alias Line =
  { x1 : Maybe Float
  , x2 : Maybe Float
  , y1 : Maybe Float
  , y2 : Maybe Float
  , color : String
  , width : Float
  }


{-| -}
line : Plane -> List (Attribute Line) -> Svg msg
line plane edits =
  let config =
        apply edits
          { x1 = Nothing
          , x2 = Nothing
          , y1 = Nothing
          , y2 = Nothing
          , color = "rgb(210, 210, 210)"
          , width = 1
          }

      ( ( x1_, x2_ ), ( y1_, y2_ ) ) =
        case ( ( config.x1, config.x2 ), ( config.y1, config.y2 ) ) of
          -- ONLY X
          ( ( Just a, Just b ), ( Nothing, Nothing ) ) ->
            ( ( a, b ), ( plane.y.min, plane.y.min ) )

          ( ( Just a, Nothing ), ( Nothing, Nothing ) ) ->
            ( ( a, a ), ( plane.y.min, plane.y.max ) )

          ( ( Nothing, Just b ), ( Nothing, Nothing ) ) ->
            ( ( b, b ), ( plane.y.min, plane.y.max ) )

          -- ONLY Y
          ( ( Nothing, Nothing ), ( Just a, Just b ) ) ->
            ( ( plane.x.min, plane.x.min ), ( a, b ) )

          ( ( Nothing, Nothing ), ( Just a, Nothing ) ) ->
            ( ( plane.x.min, plane.x.max ), ( a, a ) )

          ( ( Nothing, Nothing ), ( Nothing, Just b ) ) ->
            ( ( plane.x.min, plane.x.max ), ( b, b ) )

          -- MIXED

          ( ( Nothing, Just c ), ( Just a, Just b ) ) ->
            ( ( c, c ), ( a, b ) )

          ( ( Just c, Nothing ), ( Just a, Just b ) ) ->
            ( ( c, c ), ( a, b ) )

          ( ( Just a, Just b ), ( Nothing, Just c ) ) ->
            ( ( a, b ), ( c, c ) )

          ( ( Just a, Just b ), ( Just c, Nothing ) ) ->
            ( ( a, b ), ( c, c ) )

          -- NEITHER
          ( ( Nothing, Nothing ), ( Nothing, Nothing ) ) ->
            ( ( plane.x.min, plane.x.max ), ( plane.y.min, plane.y.max ) )

          _ ->
            ( ( Maybe.withDefault plane.x.min config.x1
              , Maybe.withDefault plane.x.max config.x2
              )
            , ( Maybe.withDefault plane.y.min config.y1
              , Maybe.withDefault plane.y.max config.y2
              )
            )

      cmds =
        [ C.Move x1_ y1_
        , C.Line x1_ y1_
        , C.Line x2_ y2_
        ]
  in
  S.path
    [ SA.class "elm-charts__line"
    , SA.stroke config.color
    , SA.strokeWidth (String.fromFloat config.width)
    , SA.d (C.description plane cmds)
    ]
    []



-- LABEL


{-| -}
type alias Label =
  { x : Float
  , y : Float
  , xOff : Float
  , yOff : Float
  , border : String
  , borderWidth : Float
  , fontSize : Maybe Int
  , color : String
  , anchor : Anchor
  -- TODO rotate
  }


{-| -}
type Anchor
  = End
  | Start
  | Middle


{-| -}
label : Plane -> List (Attribute Label) -> String -> Svg msg
label plane edits string =
  let config =
        apply edits
          { x = plane.x.min
          , y = plane.y.max
          , xOff = 0
          , yOff = 0
          , border = "white"
          , borderWidth = 0.1
          , fontSize = Nothing
          , color = "rgb(210, 210, 210)"
          , anchor = Middle
          }

      fontStyle =
        case config.fontSize of
          Just size_ -> "font-size: " ++ String.fromInt size_ ++ ";"
          Nothing -> ""

      anchorStyle =
        case config.anchor of
        End -> "text-anchor: end;"
        Start -> "text-anchor: start;"
        Middle -> "text-anchor: middle;"
  in
  S.text_
    [ SA.class "elm-charts__label"
    , SA.stroke config.border
    , SA.strokeWidth (String.fromFloat config.borderWidth)
    , SA.fill config.color
    , position plane config.x config.y config.xOff config.yOff
    , SA.style <| String.join " " [ "pointer-events: none;", fontStyle, anchorStyle ]
    ]
    [ S.tspan [] [ S.text string ] ]



-- ARROW


{-| -}
type alias Arrow =
  { x : Float
  , y : Float
  , xOff : Float
  , yOff : Float
  , color : String
  , width : Float
  , length : Float
  , rotate : Float
  }


{-| -}
arrow : Plane -> List (Attribute Arrow) -> Svg msg
arrow plane edits =
  let config =
        apply edits
          { x = plane.x.min
          , y = plane.y.max
          , xOff = 0
          , yOff = 0
          , color = "rgb(210, 210, 210)"
          , width = 4
          , length = 7
          , rotate = 0
          }

      points_ =
        "0,0 " ++ String.fromFloat config.length ++ "," ++ String.fromFloat config.width ++ " 0, " ++ String.fromFloat (config.width * 2)

      commands =
        "rotate(" ++ String.fromFloat config.rotate ++ ") translate(0 " ++ String.fromFloat -config.width ++ ") "
  in
  S.g
    [ SA.class "elm-charts__arrow"
    , position plane config.x config.y config.xOff config.yOff
    ]
    [ S.polygon
        [ SA.fill config.color
        , SA.points points_
        , SA.transform commands
        ]
        []
    ]



-- BAR


{-| -}
type alias Bar =
  { roundTop : Float
  , roundBottom : Float
  , color : String
  -- TODO , pattern : Pattern
  , x1 : Maybe Float
  , x2 : Maybe Float
  , y1 : Maybe Float
  , y2 : Maybe Float
  , border : String
  , borderWidth : Float
  }


{-| -}
bar : Plane -> List (Attribute Bar) -> Svg msg
bar plane edits =
  -- TODO round via clipPath
  let config =
        apply edits
          { roundTop = 0
          , roundBottom = 0
          , border = "white"
          , borderWidth = 0
          , color = "rgb(5, 142, 218)"
          , x1 = Nothing
          , x2 = Nothing
          , y1 = Nothing
          , y2 = Nothing
          }

      x1_ = Maybe.withDefault plane.x.min config.x1
      x2_ = Maybe.withDefault plane.x.max config.x2
      y1_ = Maybe.withDefault plane.y.max config.y2
      y2_ = Maybe.withDefault (closestToZero plane) config.y1

      x_ = x1_
      y_ = max y1_ y2_
      bs = min y1_ y2_
      w = x2_ - x_
      bT = scaleSVG plane.x w * 0.5 * (clamp 0 1 config.roundTop)
      bB = scaleSVG plane.x w * 0.5 * (clamp 0 1 config.roundBottom)
      ys = abs (scaleSVG plane.y y_)
      rxT = scaleCartesian plane.x bT
      ryT = scaleCartesian plane.y bT
      rxB = scaleCartesian plane.x bB
      ryB = scaleCartesian plane.y bB

      commands =
        if bs == y_ then
          []
        else
          case ( config.roundTop > 0, config.roundBottom > 0 ) of
            ( False, False ) ->
              [ C.Move x_ bs
              , C.Line x_ y_
              , C.Line (x_ + w) y_
              , C.Line (x_ + w) bs
              ]

            ( True, False ) ->
              [ C.Move x_ bs
              , C.Line x_ (y_ + -ryT)
              , C.Arc bT bT -45 False True (x_ + rxT) y_
              , C.Line (x_ + w - rxT) y_
              , C.Arc bT bT -45 False True (x_ + w) (y_ + -ryT)
              , C.Line (x_ + w) bs
              , C.Line x_ bs
              ]

            ( False, True ) ->
              [ C.Move (x_ + rxB) bs
              , C.Arc bB bB -45 False True x_ (bs + ryB)
              , C.Line x_ y_
              , C.Line (x_ + w) y_
              , C.Line (x_ + w) (bs + ryB)
              , C.Arc bB bB -45 False True (x_ + w - rxB) bs
              , C.Line (x_ + rxB) bs
              ]

            ( True, True ) ->
              [ C.Move (x_ + rxB) bs
              , C.Arc bB bB -45 False True x_ (bs + ryB)
              , C.Line x_ (y_ - ryT)
              , C.Arc bT bT -45 False True (x_ + rxT) y_
              , C.Line (x_ + w - rxT) y_
              , C.Arc bT bT -45 False True (x_ + w) (y_ - ryT)
              , C.Line (x_ + w) (bs + ryB)
              , C.Arc bB bB -45 False True (x_ + w - rxB) bs
              , C.Line (x_ + rxB) bs
              ]
  in
  S.path
    [ SA.class "elm-charts__bar"
    , SA.fill config.color
    , SA.stroke config.border
    , SA.strokeWidth (String.fromFloat config.borderWidth)
    , SA.d (C.description plane commands)
    ]
    []



-- SERIES


{-| -}
type alias Series =
  { interpolation : Maybe Method
  , color : String
  , width : Float
  , points : List (List Point)
  , area : Float
  }


{-| -}
type Method
  = Linear
  | Monotone


{-| -}
linear : Method
linear =
  Linear


{-| -}
monotone : Method
monotone =
  Monotone


{-| -}
interpolation : Plane -> List (Attribute Series) -> Svg msg
interpolation plane edits =
  let config =
        apply edits
          { interpolation = Nothing
          , color = "rgb(5, 142, 218)"
          , width = 1
          , points = []
          , area = 0
          }

      view ps cmds =
        withBorder ps <| \first rest ->
          S.path
            [ SA.class "elm-charts__interpolation"
            , SA.fill "transparent"
            , SA.stroke config.color
            , SA.strokeWidth (String.fromFloat config.width)
            , SA.d (C.description plane (Move first.x first.y :: cmds))
            ]
            []

      pieces =
        List.map2 view config.points (seriesCommands config)
  in
  S.g [ SA.class "elm-charts__interpolations" ] (List.filterMap identity pieces)


{-| -}
area : Plane -> Maybe Series -> String -> Series -> Svg msg
area plane nextMaybe id series =
  let clipperId =
        "area-clipper-" ++ id

      defsMaybe =
        case nextMaybe of
          -- TODO make sure missing data doesn't cut wrong
          -- TODO make sure monotone w missing data works correct
          -- TODO don't use clip path
          Just next ->
            let nextPs = List.concat next.points
                nextCmds = List.concat (seriesCommands next)
                startCmds start = [ C.Move plane.x.min plane.y.max, C.Line plane.x.min start.y ]
                endCmds end = [ C.Line plane.x.max end.y, C.Line plane.x.max plane.y.max ]
                toPath start end = C.description plane (startCmds start ++ nextCmds ++ endCmds end)
            in
            withBorder nextPs <| \start end ->
              S.defs []
                [ S.clipPath
                    [ SA.id clipperId ]
                    [ S.path [ SA.d (toPath start end) ] [] ]
                ]

          Nothing ->
            Nothing

      toArea points cmds =
        withBorder points <| \start end ->
          let startCmds = [ C.Move start.x 0, C.Line start.x start.y ]
              endCmds = [ C.Line end.x 0 ]
              path = C.description plane (startCmds ++ cmds ++ endCmds)
          in
          S.path
            [ SA.class "elm-charts__area"
            , SA.clipPath ("url(#" ++ clipperId ++ ")")
            , SA.fill series.color
            , SA.fillOpacity (String.fromFloat series.area)
            , SA.d path
            ]
            []

      areas =
        List.map2 toArea series.points (seriesCommands series)
          |> List.filterMap identity
  in
  S.g [ SA.class "elm-charts__areas" ] <|
    case defsMaybe of
      Just defs -> [ defs, S.g [] areas ]
      Nothing -> areas


seriesCommands : Series -> List (List C.Command)
seriesCommands series =
  case series.interpolation of
    Nothing -> []
    Just Linear -> Interpolation.linear series.points
    Just Monotone -> Interpolation.monotone series.points



-- DOTS


{-| -}
type alias Dot =
  { x : Float
  , y : Float
  , color : String
  , opacity : Float
  , size : Float
  , border : String
  , borderWidth : Float
  -- TODO, auraColor : String
  -- TODO, auraOpacity : Float
  -- TODO, auraWidth : Float
  }


{-| -}
circle : Plane -> Dot -> Svg msg
circle plane dot =
  let x_ = toSVGX plane dot.x
      y_ = toSVGY plane dot.y
      area_ = 2 * pi * dot.size
      radius = sqrt (area_ / pi)
      attrs =
        [ SA.cx (String.fromFloat x_)
        , SA.cy (String.fromFloat y_)
        , SA.r (String.fromFloat radius)
        ]
  in
  S.circle (attrs ++ styleAttrs dot) []


{-| -}
triangle : Plane -> Dot -> Svg msg
triangle plane dot =
  let x_ = toSVGX plane dot.x
      y_ = toSVGY plane dot.y
      area_ = 2 * pi * dot.size
      attrs = [ SA.d (trianglePath area_ x_ y_) ]
  in
  S.path (attrs ++ styleAttrs dot) []


{-| -}
square : Plane -> Dot -> Svg msg
square plane dot =
  let x_ = toSVGX plane dot.x
      y_ = toSVGY plane dot.y
      area_ = 2 * pi * dot.size
      side = sqrt area_
      attrs =
        [ SA.x <| String.fromFloat (x_ - side / 2)
        , SA.y <| String.fromFloat (y_ - side / 2)
        , SA.width (String.fromFloat side)
        , SA.height (String.fromFloat side)
        ]
  in
  S.rect (attrs ++ styleAttrs dot) []


{-| -}
diamond : Plane -> Dot -> Svg msg
diamond plane dot =
  let x_ = toSVGX plane dot.x
      y_ = toSVGY plane dot.y
      area_ = 2 * pi * dot.size
      side = sqrt area_
      rotation = "rotate(45 " ++ String.fromFloat x_ ++ " " ++ String.fromFloat y_ ++ ")"
      attrs =
        [ SA.x <| String.fromFloat (x_ - side / 2)
        , SA.y <| String.fromFloat (y_ - side / 2)
        , SA.width (String.fromFloat side)
        , SA.height (String.fromFloat side)
        , SA.transform rotation
        ]
  in
  S.rect (attrs ++ styleAttrs dot) []

{-| -}
plus : Plane -> Dot -> Svg msg
plus plane dot =
  let x_ = toSVGX plane dot.x
      y_ = toSVGY plane dot.y
      area_ = 2 * pi * dot.size
      attrs = [ SA.d (plusPath area_ x_ y_) ]
  in
  S.path (attrs ++ styleAttrs dot) []


{-| -}
cross : Plane -> Dot -> Svg msg
cross plane dot =
  let x_ = toSVGX plane dot.x
      y_ = toSVGY plane dot.y
      area_ = 2 * pi * dot.size
      rotation = "rotate(45 " ++ String.fromFloat x_ ++ " " ++ String.fromFloat y_ ++ ")"
      attrs = [ SA.d (plusPath area_ x_ y_), SA.transform rotation ]
  in
  S.path (attrs ++ styleAttrs dot) []


trianglePath : Float -> Float -> Float -> String
trianglePath area_ x_ y_ =
  let side = sqrt <| area_ * 4 / (sqrt 3)
      height = (sqrt 3) * side / 2
      fromMiddle = height - tan (degrees 30) * side / 2
  in
  String.join " "
    [ "M" ++ String.fromFloat x_ ++ " " ++ String.fromFloat (y_ - fromMiddle)
    , "l" ++ String.fromFloat (-side / 2) ++ " " ++ String.fromFloat height
    , "h" ++ String.fromFloat side
    , "z"
    ]


plusPath : Float -> Float -> Float ->  String
plusPath area_ x_ y_ =
  let side = sqrt (area_ / 5)
      r3 = side
      r6 = side / 2
  in
  String.join " "
    [ "M" ++ String.fromFloat (x_ - r6) ++ " " ++ String.fromFloat (y_ - r3 - r6)
    , "v" ++ String.fromFloat r3
    , "h" ++ String.fromFloat -r3
    , "v" ++ String.fromFloat r3
    , "h" ++ String.fromFloat r3
    , "v" ++ String.fromFloat r3
    , "h" ++ String.fromFloat r3
    , "v" ++ String.fromFloat -r3
    , "h" ++ String.fromFloat r3
    , "v" ++ String.fromFloat -r3
    , "h" ++ String.fromFloat -r3
    , "v" ++ String.fromFloat -r3
    , "h" ++ String.fromFloat -r3
    , "v" ++ String.fromFloat r3
    ]


styleAttrs : Dot -> List (S.Attribute msg)
styleAttrs dot =
  [ SA.stroke dot.border
  , SA.strokeWidth (String.fromFloat dot.borderWidth)
  , SA.fillOpacity (String.fromFloat dot.opacity)
  , SA.fill dot.color
  ]



-- TOOLTIP

--type alias Tooltip

--tooltip : Tooltip -> Html msg


{-| -}
decodePoint : Plane -> (Plane -> Point -> msg) -> Json.Decoder msg
decodePoint plane toMsg =
  let
    handle mouseX mouseY rect =
      let
        widthPercent = rect.width / plane.x.length
        heightPercent = rect.height / plane.y.length

        xPrev = plane.x
        yPrev = plane.y

        newPlane =
          { x =
              { xPrev | length = rect.width
              , marginLower = plane.x.marginLower * widthPercent
              , marginUpper = plane.x.marginUpper * widthPercent
              }
          , y =
              { yPrev | length = rect.height
              , marginLower = plane.y.marginLower * heightPercent
              , marginUpper = plane.y.marginUpper * heightPercent
              }
          }
      in
      toMsg newPlane { x = mouseX - rect.left, y = mouseY - rect.top }
  in
  Json.map3 handle
    (Json.field "pageX" Json.float)
    (Json.field "pageY" Json.float)
    (DOM.target decodePosition)


decodePosition : Json.Decoder DOM.Rectangle
decodePosition =
  Json.oneOf
    [ DOM.boundingClientRect
    , Json.lazy (\_ -> DOM.parentElement decodePosition)
    ]



-- POSITIONING


position : Plane -> Float -> Float -> Float -> Float -> S.Attribute msg
position plane x_ y_ xOff_ yOff_ =
  SA.transform <| "translate(" ++ String.fromFloat (toSVGX plane x_ + xOff_) ++ "," ++ String.fromFloat (toSVGY plane y_ + yOff_) ++ ")"



-- HELPERS


withBorder : List a -> (a -> a -> b) -> Maybe b
withBorder stuff func =
  case stuff of
    first :: rest ->
      Just (func first (Maybe.withDefault first (last rest)))

    _ ->
      Nothing


last : List a -> Maybe a
last list =
  List.head (List.drop (List.length list - 1) list)


closestToZero : Plane -> Float
closestToZero plane =
  clamp plane.y.min plane.y.max 0


apply : List (a -> a) -> a -> a
apply funcs default =
  let apply_ f a = f a in
  List.foldl apply_ default funcs



