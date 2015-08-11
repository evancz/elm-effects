module Effects
    ( Effects, none, task, tick, batch
    , map
    , Never
    , toTask
    )
    where
{-| This module provides all the tools necessary to create modular components
that manage their own effects. **It is very important that you go through
[this tutorial](https://github.com/evancz/elm-components).** It describes a
pattern that is crucial for any of these functions to make sense.

# Basic Effects
@docs Effects, done, task, tick

# Combining Effects
@docs map, batch

# Running Effects
@docs toTask
-}


import Native.Effects
import Task


-- EFFECTS

{-| Represents some kind of effect. Right now this library supports tasks for
arbitrary effects and clock ticks for animations.
-}
type Effects msg
    = Task (Task.Task Never msg)
    | Tick (Float -> msg)
    | None
    | Batch (List (Effects msg))


{-| A type that has no members. There are no values of type `Never`, so if
something has this type, it is a guarantee that it can never happen. It is
useful for demanding that a `Task` can never fail.
-}
type Never = Never Never


none : Effects msg
none =
    None


{-| Turn a `Task` into an `Effects` that results in a `msg`.

Normally a `Task` has a error type and a success type. In this case the error
type is `Never` meaning that you must provide a task that never fails. Lots of
tasks can fail (like HTTP requests), so you will want to use `Task.toMaybe`
and `Task.toResult` to move potential errors into the success type so they can
be handled explicitly.
-}
task : Task.Task Never msg -> Effects msg
task =
    Task


{-| Request a clock tick for animations. This function takes a function to turn
the current time into a `msg` that can be handled by the relevant component.
-}
tick : (Float -> msg) -> Effects msg
tick =
    Tick


{-| Create a batch of effects. The following example requests two tasks: one
for the user’s picture and one for their age. You could put a bunch more stuff
in that batch if you wanted!

    init : String -> Transaction Message Model
    init userID =
        request (batch [ task (getUserPicture userID), task (getAge userID) ])
          { id = userID
          , picture = Nothing
          , age = Nothing
          }
-}
batch : List (Effects msg) -> Effects msg
batch =
    Batch


map : (a -> b) -> Effects a -> Effects b
map func effect =
  case effect of
    Task task ->
        Task (Task.map func task)

    Tick tagger ->
        Tick (tagger >> func)

    None ->
        None

    Batch effectList ->
        Batch (List.map (map func) effectList)


{-| Convert an `Effects` into a task that cannot fail. When run, the resulting
task will send a bunch of messages to the given `Address`.

Generally speaking, you should not need this function, particularly if you are
using [start-app](http://package.elm-lang.org/packages/evancz/start-app/latest).
It is mainly useful at the very root of your program where you actually need to
give all the effects to a port. So in the common case you should use this
function 0 times per project, and if you are doing very special things for
expert reasons, you should probably have either 0 or 1 uses of this per
project.
-}
toTask : Signal.Address msg -> Effects msg -> Task.Task Never ()
toTask address effect =
    let
        (combinedTask, tickMessages) =
            toTaskHelp address (Task.succeed (), []) effect

        animationReport time =
            tickMessages
                |> List.map (\f -> Signal.send address (f time))
                |> sequence_

        animationRequests =
            requestAnimationFrame animationReport
    in
        combinedTask `Task.andThen` always animationRequests


toTaskHelp
    : Signal.Address msg
    -> (Task.Task Never (), List (Float -> msg))
    -> Effects msg
    -> (Task.Task Never (), List (Float -> msg))
toTaskHelp address ((combinedTask, tickMessages) as intermediateResult) effect =
    case effect of
        Task task ->
            let
                reporter =
                    task `Task.andThen` Signal.send address
            in
                ( combinedTask `Task.andThen` always (ignore (Task.spawn reporter))
                , tickMessages
                )

        Tick toMsg ->
            ( combinedTask
            , toMsg :: tickMessages
            )

        None ->
            intermediateResult

        Batch effectList ->
            let
                (tasks, toMsgLists) =
                    List.unzip <| List.map (toTaskHelp address intermediateResult) effectList
            in
                ( sequence_ tasks
                , List.concat toMsgLists
                )


requestAnimationFrame : (Float -> Task.Task Never ()) -> Task.Task Never ()
requestAnimationFrame =
    Native.Effects.requestAnimationFrame


ignore : Task.Task x a -> Task.Task x ()
ignore task =
  task `Task.andThen` always (Task.succeed ())


sequence_ : List (Task.Task x a) -> Task.Task x ()
sequence_ tasks =
  ignore (Task.sequence tasks)

