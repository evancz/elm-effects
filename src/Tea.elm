module Tea
    ( Transaction, done, request
    , Effect, task, animationFrame
    , tag, with, with2, with3, andThen
    , App, Output, start
    ) where
{-|

# Start your App
@docs App, start, Output

# Transactions
@docs Transaction, done, request, requestList

# Effects
@docs Effect, task, animationFrame

# Nesting Transactions
@docs tag, with, with2, with3, andThen

-}


import Debug
import Html exposing (Html)
import Never exposing (Never)
import Task
import Tea.SpecialEffects as SFX


-- TRANSACTIONS

type alias Transaction msg model =
    SFX.Transaction (Effect msg) model


done : model -> Transaction msg model
done =
    SFX.done


request : Effect msg -> model -> Transaction msg model
request =
    SFX.request


requestList : List (Effect msg) -> model -> Transaction msg model
requestList =
    SFX.requestList


-- EFFECTS

type Effect msg
    = Task (Task.Task Never msg)
    | AnimationFrame (Float -> msg)


type Never = Never Never


task : Task.Task Never msg -> Effect msg
task =
    Task


animationFrame : (Float -> msg) -> Effect msg
animationFrame =
    AnimationFrame


-- CHAINING

tag : (msg -> msg') -> Transaction msg model -> Transaction msg' model
tag func transaction =
    SFX.tag (map func) transaction


andThen : Transaction msg a -> (a -> Transaction msg b) -> Transaction msg b
andThen =
  SFX.andThen


with : Transaction msg a -> (a -> Transaction msg model) -> Transaction msg model
with =
  SFX.with


with2 : Transaction msg a -> Transaction msg b -> (a -> b -> Transaction msg model) -> Transaction msg model
with2 =
  SFX.with2


with3 : Transaction msg a -> Transaction msg b -> Transaction msg c -> (a -> b -> c -> Transaction msg model) -> Transaction msg model
with3 =
  SFX.with3


-- START

type alias App options msg model =
    { model : model
    , init : options -> List (Effect msg)
    , view : Signal.Address msg -> model -> Html
    , update : msg -> model -> Transaction msg model
    }


type alias Output model =
    { html : Signal Html
    , model : Signal model
    , tasks : Signal (Task.Task Never ())
    }


start : options -> App options msg model -> Output model
start options app =
    let
        { model, html, effects, address } =
            SFX.start options app
    in
        Output html model (Signal.map (interpreter address) effects)


-- EFFECT INTERPRETER

map : (msg -> msg') -> Effect msg -> Effect msg'
map func effect =
    case effect of
        Task arbitraryTask ->
            Task (Task.map func arbitraryTask)

        AnimationFrame toMsg ->
            AnimationFrame (toMsg >> func)


interpreter : Signal.Address msg -> List (Effect msg) -> Task.Task Never ()
interpreter address effectList =
    let
        (combinedTask, frameMessages) =
            List.foldr (interpreterHelp address) (Task.succeed (), []) effectList

        animationReport time =
          List.reverse frameMessages
            |> List.map (\f -> Signal.send address (f time))
            |> sequence_

        animationRequests =
            requestAnimationFrame animationReport
    in
        sequence_ [ combinedTask, ignore (Task.spawn animationRequests) ]


interpreterHelp
    : Signal.Address msg
    -> Effect msg
    -> (Task.Task Never (), List (Float -> msg))
    -> (Task.Task Never (), List (Float -> msg))
interpreterHelp address effect (combinedTask, frameMessages) =
    case effect of
        Task arbitraryTask ->
            ( sequence_ [ combinedTask, ignore (Task.spawn arbitraryTask) ]
            , frameMessages
            )

        AnimationFrame toMsg ->
            ( combinedTask
            , toMsg :: frameMessages
            )


requestAnimationFrame : (Float -> Task.Task Never ()) -> Task.Task Never ()
requestAnimationFrame callback =
    Debug.crash "TODO"


ignore : Task.Task x a -> Task.Task x ()
ignore task =
  task `Task.andThen` always (Task.succeed ())


sequence_ : List (Task.Task x a) -> Task.Task x ()
sequence_ tasks =
  ignore (Task.sequence tasks)


