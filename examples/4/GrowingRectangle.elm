module GrowingRectangle where

import Html exposing (Html, div)
import Html.Attributes exposing (style)
import Html.Events exposing (onClick)
import Color exposing (Color)
import Time exposing (Time, second)
import Easing exposing (linear, Interpolation, point2d, color)
import Signal exposing (Signal, Address)
import Task exposing (Task)

import Components as C exposing (Transaction, done, request, animationFrame, Never)

import Helper exposing (..)

import Debug
--

app =
  C.start
    { init    = init
    , update  = update
    , view    = view
    }

main =
  app.html

port tasks : Signal (Task Never ())
port tasks =
  app.tasks

-- Model

type alias Model =
  Transition
    { offset : Vector
    , size   : Vector
    , color  : Color
    }

init = done <|
  newTransition
    { offset = { x = 0 , y = 0 }
    , size   = { x = 10, y = 10 }
    , color  = Color.red
    }
    { offset = { x = 100 , y = 100 }
    , size   = { x = 200, y = 200 }
    , color  = Color.blue
    }


type alias ModelInterpolation =
  Interpolation
    { offset : Vector
    , size   : Vector
    , color  : Color
    }

modelInterpolation : ModelInterpolation
modelInterpolation from to v =
  { offset = point2d from.offset to.offset v
  , size   = point2d from.size   to.size   v
  , color  = color   from.color  to.color  v
  }


type Message
  = Click
  | NextFrame Time


update : Message -> Model -> Transaction Message Model
update msg model =
  case Debug.log "Message" msg of
    Click ->
      model
      |> request (animationFrame NextFrame)
      -- BUG: THE ANIMATION FRAME IS NOT SENT

    NextFrame frame ->
      if hasReachedGoal model
      then
        model
        |> incrementTime frame
        |> reverse
        |> done
      else
        model
        |> incrementTime frame
        |> animate
        |> request (animationFrame NextFrame)



animate : Model -> Model
animate model =
  applyEasing linear modelInterpolation second model


view : Address Message -> Model -> Html
view address model =
  let
      position =
        translate model.current.offset

      size =
        scale model.current.size

      color =
        toRgbaString model.current.color

      transform =
        position

      containerStyle =
        [ "width" => "100px"
        , "height" => "100px"
        , "transform" => transform
        , "-webkit-transform" => transform
        , "background-color" => color
        , "cursor" => "pointer"
        ]

  in
      div
        [ style containerStyle
        , onClick address Click
        ]
        []
