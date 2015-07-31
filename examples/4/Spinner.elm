module Spinner (Model, Message, init, update, view) where

import Debug
import Easing
import Html exposing (Html)
import Http
import Json.Decode as Json
import Svg exposing (svg, rect, g, text, text')
import Svg.Attributes exposing (..)
import Svg.Events exposing (onClick)
import Task
import Components as C exposing (Transaction, done, request, animationFrame, Never)


-- MODEL

type alias Model =
    { angle : Float
    , fraction : Float
    , time : Maybe Float
    }


init : Transaction Message Model
init =
  done { angle = 0, fraction = 0, time = Nothing }


rotateStep = 90


-- UPDATE

type Message
    = Spin
    | Tick Float


update : Message -> Model -> Transaction Message Model
update msg model =
  case msg of
    Spin ->
      request (animationFrame Tick) model

    Tick time ->
      let
        diff =
          case model.time of
            Nothing -> 0
            Just prev ->
              time - prev

        newFraction =
          model.fraction + diff
      in
        if newFraction > 1000 then
          done
            { angle = model.angle + rotateStep
            , fraction = 0
            , time = Nothing
            }
        else
          request (animationFrame Tick)
            { angle = model.angle
            , fraction = newFraction
            , time = Just time
            }


-- VIEW

view : Signal.Address Message -> Model -> Html
view address model =
  let
    angle =
      model.angle + Easing.ease Easing.easeOutBounce Easing.float 0 rotateStep 1000 model.fraction
  in
    svg
      [ width "200", height "200", viewBox "0 0 200 200" ]
      [ g [ transform ("translate(100, 100) rotate(" ++ toString angle ++ ")")
          ]
          [ rect
              [ x "-50"
              , y "-50"
              , width "100"
              , height "100"
              , rx "15"
              , ry "15"
              , style "fill: #60B5CC;"
              , onClick (Signal.message address Spin)
              ]
              []
          , text' [ fill "white", textAnchor "middle" ] [ text "Click me!" ]
          ]
      ]
