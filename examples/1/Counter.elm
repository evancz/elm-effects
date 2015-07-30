module Counter where

import Html exposing (..)
import Html.Attributes exposing (style)
import Html.Events exposing (onClick)
import Tea exposing (Transaction, done)


main = output.html

output =
  Tea.start { model = 0, init = [], update = update, view = view }


-- MODEL

type alias Model = Int


-- UPDATE

type Message = Increment | Decrement

update : Message -> Model -> Transaction Message Model
update action model =
  case action of
    Increment ->
      done (model + 1)

    Decrement ->
      done (model - 1)


-- VIEW

view : Signal.Address Message -> Model -> Html
view address model =
  div []
    [ button [ onClick address Decrement ] [ text "-" ]
    , div [ countStyle ] [ text (toString model) ]
    , button [ onClick address Increment ] [ text "+" ]
    ]


countStyle : Attribute
countStyle =
  style
    [ ("font-size", "20px")
    , ("font-family", "monospace")
    , ("display", "inline-block")
    , ("width", "50px")
    , ("text-align", "center")
    ]
