module RandomGifViewer where

import Html exposing (..)
import Html.Attributes exposing (style, src)
import Html.Events exposing (onClick)
import Http
import Json.Decode as Json
import Task
import Components as C exposing (Transaction, done, request, Never)


main = output.html

output =
  C.start { init = init "funny cats", update = update, view = view }

port tasks : Signal (Task.Task Never ())
port tasks =
  output.tasks


-- MODEL

type alias Model =
    { topic : String
    , image : String
    }


init : String -> Transaction Message Model
init topic =
  request
    (getRandomImage topic)
    { topic = topic, image = "http://giphy.com/gifs/bored-alice-in-wonderland-meh-ZXKZWB13D6gFO" }


-- UPDATE

type Message
    = Next
    | NewImage (Maybe String)


update : Message -> Model -> Transaction Message Model
update msg model =
  case msg of
    Next ->
      request
        (getRandomImage model.topic)
        model

    NewImage maybeUrl ->
      done
        { model |
            image <- Maybe.withDefault model.image maybeUrl
        }


-- VIEW

(=>) = (,)

view : Signal.Address Message -> Model -> Html
view address model =
  div [ style [ "width" => "200px" ] ]
    [ h2 [headerStyle] [text model.topic]
    , div [imgStyle model.image] []
    , button [ onClick address Next ] [ text "More Please!" ]
    ]


headerStyle : Attribute
headerStyle =
  style
    [ "width" => "200px"
    , "text-align" => "center"
    ]


imgStyle : String -> Attribute
imgStyle url =
  style
    [ "display" => "inline-block"
    , "width" => "200px"
    , "height" => "200px"
    , "background-position" => "center center"
    , "background-size" => "cover"
    , "background-image" => ("url('" ++ url ++ "')")
    ]


-- EFFECTS

randomUrl : String -> String
randomUrl topic =
  Http.url "http://api.giphy.com/v1/gifs/random"
    [ "api_key" => "dc6zaTOxFJmzC"
    , "tag" => topic
    ]


getRandomImage : String -> C.Effect Message
getRandomImage topic =
  Http.get decodeImageUrl (randomUrl topic)
    |> Task.toMaybe
    |> Task.map NewImage
    |> C.task


decodeImageUrl : Json.Decoder String
decodeImageUrl =
  Json.at ["data", "image_url"] Json.string