module Effects
    ( Effects, none, task, tick
    , map, batch
    , Never
    , toTask
    , requestAnimationFrame
    )
    where
{-| This module provides all the tools necessary to create modular components
that manage their own effects. **It is very important that you go through
[this tutorial](https://github.com/evancz/elm-components).** It describes a
pattern that is crucial for any of these functions to make sense.

# Basic Effects
@docs Effects, none, task, tick

# Combining Effects
@docs map, batch

# Helpers

There are some common patterns that will show up in folks code a lot, so there
are some helper functions you may want to define in your own code. For example,
the `noFx` function makes it easier to return a model without any effects.

    import Effects exposing (Effects)

    noFx : model -> (model, Effects a)
    noFx model =
        (model, Effects.none)

This way you don't have to add the tuple in, just say something like
`(noFx <| ...)` and get the same result.

If folks find this helpful, we will add it to this library. Let us know your
experience in an issue.


# Running Effects
@docs toTask, Never


# Low-level Functions
@docs requestAnimationFrame
-}


import Native.Effects
import Task
import Time exposing (Time)

-- EFFECTS

{-| Represents some kind of effect. Right now this library supports tasks for
arbitrary effects and clock ticks for animations.
-}
type Effects a
    = Task (Task.Task Never a)
    | Tick (Time -> a)
    | None
    | Batch (List (Effects a))


{-| A type that is "uninhabited". There are no values of type `Never`, so if
something has this type, it is a guarantee that it can never happen. It is
useful for demanding that a `Task` can never fail.
-}
type Never = Never Never


{-| The simplest effect of them all: don’t do anything! This is useful when
some branches of your update function request effects and others do not.

Example 5 in [elm-architecture-tutorial](https://github.com/evancz/elm-architecture-tutorial/)
has a nice example of this with further explanation in the tutorial itself.
-}
none : Effects a
none =
    None


{-| Turn a `Task` into an `Effects` that results in an `a` value.

Normally a `Task` has a error type and a success type. In this case the error
type is `Never` meaning that you must provide a task that never fails. Lots of
tasks can fail (like HTTP requests), so you will want to use `Task.toMaybe`
and `Task.toResult` to move potential errors into the success type so they can
be handled explicitly.

Example 5 in [elm-architecture-tutorial](https://github.com/evancz/elm-architecture-tutorial/)
has a nice example of this with further explanation in the tutorial itself.
-}
task : Task.Task Never a -> Effects a
task =
    Task


{-| Request a clock tick for animations. This function takes a function to turn
the current time into an `a` value that can be handled by the relevant component.

Example 8 in [elm-architecture-tutorial](https://github.com/evancz/elm-architecture-tutorial/)
has a nice example of this with further explanation in the tutorial itself.
-}
tick : (Time -> a) -> Effects a
tick =
    Tick


{-| Create a batch of effects. The following example requests two tasks: one
for the user’s picture and one for their age. You could put a bunch more stuff
in that batch if you wanted!

    init : String -> (Model, Effects Action)
    init userID =
        ( { id = userID
          , picture = Nothing
          , age = Nothing
          }
        , batch [ getPicture userID, getAge userID ]
        )

    -- getPicture : String -> Effects Action
    -- getAge : String -> Effects Action

Example 6 in [elm-architecture-tutorial](https://github.com/evancz/elm-architecture-tutorial/)
has a nice example of this with further explanation in the tutorial itself.
-}
batch : List (Effects a) -> Effects a
batch =
    Batch


{-| Transform the return type of a bunch of `Effects`. This is primarily useful
for adding tags to route `Actions` to the right place in The Elm Architecture.

Example 6 in [elm-architecture-tutorial](https://github.com/evancz/elm-architecture-tutorial/)
has a nice example of this with further explanation in the tutorial itself.
-}
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
toTask : Signal.Address a -> Effects a -> Task.Task Never ()
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
    : Signal.Address a
    -> (Task.Task Never (), List (Time -> a))
    -> Effects a
    -> (Task.Task Never (), List (Time -> a))
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


{-| Returns a task which, when executed, will use the browser's native
`requestAnimationFrame()` method to wait until an animation frame is needed.
The function you provide will then be called, with the `Time` provided by
`requestAnimationFrame()` as its parameter. The `Task` returned by your
function will then be immediately executed.

Note that this is a low-level function, intended as a building block for
higher-level functions. You will typically not need to call this directly.
-}
requestAnimationFrame : (Time -> Task.Task Never ()) -> Task.Task Never ()
requestAnimationFrame =
    Native.Effects.requestAnimationFrame


ignore : Task.Task x a -> Task.Task x ()
ignore task =
  task `Task.andThen` always (Task.succeed ())


sequence_ : List (Task.Task x a) -> Task.Task x ()
sequence_ tasks =
  ignore (Task.sequence tasks)
