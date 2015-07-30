module RandomGifPair where

import Components as C exposing (..)
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (..)
import Task
import RandomGif as RG


app =
  C.start
    { init = init "funny cats" "funny dogs"
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
    { left : RG.Model
    , right : RG.Model
    }


init : String -> String -> Transaction Message Model
init leftTopic rightTopic =
  with2
    (tag Left <| RG.init leftTopic)
    (tag Right <| RG.init rightTopic)
    (\left right -> done { left = left, right = right })


-- UPDATE

type Message
    = Left RG.Message
    | Right RG.Message


update : Message -> Model -> Transaction Message Model
update message model =
  case message of
    Left msg ->
      with
        (tag Left <| RG.update msg model.left)
        (\left -> done { model | left <- left })

    Right msg ->
      with
        (tag Right <| RG.update msg model.right)
        (\right -> done { model | right <- right })


-- VIEW

(=>) = (,)


view : Signal.Address Message -> Model -> Html
view address model =
  div [ style [ "display" => "flex" ] ]
    [ RG.view (Signal.forwardTo address Left) model.left
    , RG.view (Signal.forwardTo address Right) model.right
    ]