module SpinSquare (Model, Message, init, update, view) where

import Easing exposing (ease, easeOutBounce, float)
import Html exposing (Html)
import Http
import Json.Decode as Json
import Svg exposing (svg, rect, g, text, text')
import Svg.Attributes exposing (..)
import Svg.Events exposing (onClick)
import Task
import Time exposing (Time, second)
import Transaction exposing (Transaction, done, requestTick, Never)


-- MODEL

type alias Model =
    { angle : Float
    , animationState : Maybe { prevClockTime : Time,  elapsedTime: Time }
    }


init : Transaction Message Model
init =
  done { angle = 0, animationState = Nothing }


rotateStep = 90
duration = second

-- UPDATE

type Message
    = Spin
    | Tick Time


update : Message -> Model -> Transaction Message Model
update msg model =
  case msg of
    Spin ->
      case model.animationState of
        Nothing ->
          requestTick Tick model

        Just _ ->
          done model

    Tick clockTime ->
      let
        newElapsedTime =
          case model.animationState of
            Nothing ->
              0

            Just {elapsedTime, prevClockTime} ->
              elapsedTime + (clockTime - prevClockTime)
      in
        if newElapsedTime > duration then
          done
            { angle = model.angle + rotateStep
            , animationState = Nothing
            }
        else
          requestTick Tick
            { angle = model.angle
            , animationState = Just { elapsedTime = newElapsedTime, prevClockTime = clockTime }
            }


-- VIEW

rotationAnimation : Time -> Float
rotationAnimation currentTime =
  ease easeOutBounce float 0 rotateStep duration currentTime

view : Signal.Address Message -> Model -> Html
view address model =
  let
    angle =
      case model.animationState of
        Nothing ->
          model.angle

        Just {elapsedTime} ->
          model.angle + rotationAnimation elapsedTime
  in
    svg
      [ width "200", height "200", viewBox "0 0 200 200" ]
      [ g [ transform ("translate(100, 100) rotate(" ++ toString angle ++ ")")
          , onClick (Signal.message address Spin)
          ]
          [ rect
              [ x "-50"
              , y "-50"
              , width "100"
              , height "100"
              , rx "15"
              , ry "15"
              , style "fill: #60B5CC;"
              ]
              []
          , text' [ fill "white", textAnchor "middle" ] [ text "Click me!" ]
          ]
      ]
