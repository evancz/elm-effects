module SpinnerPair where

import Components as C exposing (..)
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (..)
import Task
import Spinner


app =
  C.start
    { init = init
    , update = update
    , view = view
    }


main =
  app.html


port tasks : Signal (Task.Task Never ())
port tasks =
  app.tasks


-- MODEL

type alias Model =
    { left : Spinner.Model
    , right : Spinner.Model
    }


init : Transaction Message Model
init =
  with2
    (tag Left Spinner.init)
    (tag Right Spinner.init)
    (\left right -> done { left = left, right = right })


-- UPDATE

type Message
    = Left Spinner.Message
    | Right Spinner.Message


update : Message -> Model -> Transaction Message Model
update message model =
  case message of
    Left msg ->
      with
        (tag Left <| Spinner.update msg model.left)
        (\left -> done { model | left <- left })

    Right msg ->
      with
        (tag Right <| Spinner.update msg model.right)
        (\right -> done { model | right <- right })


-- VIEW

(=>) = (,)


view : Signal.Address Message -> Model -> Html
view address model =
  div [ style [ "display" => "flex" ] ]
    [ Spinner.view (Signal.forwardTo address Left) model.left
    , Spinner.view (Signal.forwardTo address Right) model.right
    ]