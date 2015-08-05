module Transaction
    ( Transaction, done, requestTask, requestTick
    , Never
    , tag, with, with2, with3, list
    , request, Effect, task, tick, batch
    , destruct, effectToTask
    )
    where
{-| This module provides all the tools necessary to create modular components
that manage their own effects. **It is very important that you go through
[this tutorial](https://github.com/evancz/elm-components).** It describes a
pattern that is crucial for any of these functions to make sense.

# Transactions
@docs Transaction, done, requestTask, requestTick

# Nesting Transactions
@docs tag, with, with2, with3, list

# Fancy Transactions
@docs request, Effect, task, tick, batch

# Advanced Functions For Package Writers

This is stuff that is used by the `Start` module to actually make things go.
Generally speaking, these are functions you should never use.

@docs destruct, effectToTask
-}


import Native.Transaction
import Task


-- TRANSACTIONS

type Transaction msg model =
    Transaction (Effect msg) model


done : model -> Transaction msg model
done model =
    Transaction Empty model


requestTask : Task.Task Never msg -> model -> Transaction msg model
requestTask task model =
    Transaction (Task task) model


requestTick : (Float -> msg) -> model -> Transaction msg model
requestTick tagger model =
    Transaction (Tick tagger) model


{-| This lets you request multiple tasks and ticks.
-}
request : Effect msg -> model -> Transaction msg model
request effect model =
    Transaction effect model


-- EFFECTS

{-| Represents some kind of effect. Right now this library supports tasks for
arbitrary effects and clock ticks for animations.
-}
type Effect msg
    = Task (Task.Task Never msg)
    | Tick (Float -> msg)
    | Empty
    | Branch (List (Effect msg))


{-| A type that has no members. There are no values of type `Never`, so if
something has this type, it is a guarantee that it can never happen. It is
useful for demanding that a `Task` can never fail.
-}
type Never = Never Never


{-| Turn a `Task` into an `Effect` that results in a `msg`.

Normally a `Task` has a error type and a success type. In this case the error
type is `Never` meaning that you must provide a task that never fails. Lots of
tasks can fail (like HTTP requests), so you will want to use `Task.toMaybe`
and `Task.toResult` to move potential errors into the success type so they can
be handled explicitly.
-}
task : Task.Task Never msg -> Effect msg
task =
    Task


{-| Request a clock tick for animations. This function takes a function to turn
the current time into a `msg` that can be handled by the relevant component.
-}
tick : (Float -> msg) -> Effect msg
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
batch : List (Effect msg) -> Effect msg
batch =
    Branch


map : (a -> b) -> Effect a -> Effect b
map func effect =
  case effect of
    Task task ->
        Task (Task.map func task)

    Tick tagger ->
        Tick (tagger >> func)

    Empty ->
        Empty

    Branch effectList ->
        Branch (List.map (map func) effectList)


-- CHAINING

tag : (msg -> msg') -> Transaction msg model -> Transaction msg' model
tag func (Transaction effect model) =
    Transaction (map func effect) model


with : Transaction msg a -> (a -> Transaction msg model) -> Transaction msg model
with (Transaction fx a) callback =
  let
      (Transaction fx' model) =
          callback a
  in
      Transaction (Branch [fx, fx']) model


with2
    : Transaction msg a
    -> Transaction msg b
    -> (a -> b -> Transaction msg model)
    -> Transaction msg model
with2 (Transaction fx1 a) (Transaction fx2 b) callback =
  let
      (Transaction fx' model) =
          callback a b
  in
      Transaction (Branch [fx1, fx2, fx']) model


with3
    : Transaction msg a
    -> Transaction msg b
    -> Transaction msg c
    -> (a -> b -> c -> Transaction msg model)
    -> Transaction msg model
with3 (Transaction fx1 a) (Transaction fx2 b) (Transaction fx3 c) callback =
  let
      (Transaction fx' model) =
          callback a b c
  in
      Transaction (Branch [fx1, fx2, fx3, fx']) model


list : List (Transaction msg a) -> Transaction msg (List a)
list transactionList =
  case transactionList of
    [] ->
        done []

    transaction :: rest ->
        with2
          transaction
          (list rest)
          (\head tail -> done (head :: tail))


-- EFFECT INTERPRETER

{-| **Note:** This is a very advanced feature. Unless you are writing a package
for `Transactions` with additional features and want to keep backwards
compatability, you do not need this.

Tear apart a `Transaction` so that you can use this information in other
systems.

    type MyTransaction msg model =
        MyTransaction (MyEffect msg) model

    type MyEffect msg
        = BasicEffect (Effect msg)
        | GraphQL Query
        | ...

    toMyTransaction : Transaction msg model -> MyTransaction msg model
    toMyTransaction transaction =
        let
            {model, effect} = destruct transaction
        in
            MyTransaction (BasicEffect effect) model

Again, this is a very advanced feature. Ask around the Elm community if you are
thinking of using it for some reason.
-}
destruct : Transaction msg model -> { model : model, effect : Effect msg }
destruct (Transaction effect model) =
    { effect = effect
    , model = model
    }


{-| **Note:** This is a very advanced feature. If you are writing normal code
for a project of your own, you almost certainly do not want this. It is meant
to be used with `destruct` to create custom transactions and effect managers.

Convert an `Effect` into a task that cannot fail. When run, the resulting
task will send a bunch of messages to the given `Address`.
-}
effectToTask : Signal.Address msg -> Effect msg -> Task.Task Never ()
effectToTask address effect =
    let
        (combinedTask, tickMessages) =
            effectToTaskHelp address (Task.succeed (), []) effect

        animationReport time =
            tickMessages
                |> List.map (\f -> Signal.send address (f time))
                |> sequence_

        animationRequests =
            requestAnimationFrame animationReport
    in
        combinedTask `Task.andThen` always animationRequests


effectToTaskHelp
    : Signal.Address msg
    -> (Task.Task Never (), List (Float -> msg))
    -> Effect msg
    -> (Task.Task Never (), List (Float -> msg))
effectToTaskHelp address ((combinedTask, tickMessages) as intermediateResult) effect =
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

        Empty ->
            intermediateResult

        Branch effectList ->
            let
                (tasks, toMsgLists) =
                    List.unzip <| List.map (effectToTaskHelp address intermediateResult) effectList
            in
                ( sequence_ tasks
                , List.concat toMsgLists
                )


requestAnimationFrame : (Float -> Task.Task Never ()) -> Task.Task Never ()
requestAnimationFrame =
    Native.Transaction.requestAnimationFrame


ignore : Task.Task x a -> Task.Task x ()
ignore task =
  task `Task.andThen` always (Task.succeed ())


sequence_ : List (Task.Task x a) -> Task.Task x ()
sequence_ tasks =
  ignore (Task.sequence tasks)


