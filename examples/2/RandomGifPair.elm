module RandomGifPair where

import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (..)
import Start
import Task
import Transaction exposing (..)

import RandomGif as Gif


app =
  Start.start
    { init = init "funny cats" "funny dogs"
    , update = update
    , view = view
    , inputs = []
    }


main =
  app.html


port tasks : Signal (Task.Task Never ())
port tasks =
  app.tasks


-- MODEL

type alias Model =
    { left : Gif.Model
    , right : Gif.Model
    }


init : String -> String -> Transaction Message Model
init leftTopic rightTopic =
  with2
    (tag Left <| Gif.init leftTopic)
    (tag Right <| Gif.init rightTopic)
    (\left right -> done { left = left, right = right })


-- UPDATE

type Message
    = Left Gif.Message
    | Right Gif.Message


update : Message -> Model -> Transaction Message Model
update message model =
  case message of
    Left msg ->
      with
        (tag Left <| Gif.update msg model.left)
        (\left -> done { model | left <- left })

    Right msg ->
      with
        (tag Right <| Gif.update msg model.right)
        (\right -> done { model | right <- right })


-- VIEW

(=>) = (,)


view : Signal.Address Message -> Model -> Html
view address model =
  div [ style [ "display" => "flex" ] ]
    [ Gif.view (Signal.forwardTo address Left) model.left
    , Gif.view (Signal.forwardTo address Right) model.right
    ]