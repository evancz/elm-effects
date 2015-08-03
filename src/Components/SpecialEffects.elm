module Components.SpecialEffects
    ( Transaction, done, request, requestList
    , tag, with, with2, with3, andThen
    , App, Output, start
    )
    where
{-|

# Running an App
@docs App, start, Output

# Transactions
@docs Transaction, done, request, requestList

# Nesting Transactions
@docs tag, with, with2, with3, andThen

-}


import Debug
import Html exposing (Html)
import Task exposing (Task)


-- TRANSACTIONS

type Transaction fx model =
    Transaction (EffectTree fx) model


done : model -> Transaction fx model
done model =
    Transaction (Leaf []) model


request : fx -> model -> Transaction fx model
request fx model =
    Transaction (Leaf [fx]) model


requestList : List fx -> model -> Transaction fx model
requestList effects model =
    Transaction (Leaf effects) model


-- EFFECT TREE

type EffectTree fx
    = Leaf (List fx)
    | Branch (List (EffectTree fx))


map : (fx -> fx') -> EffectTree fx -> EffectTree fx'
map func tree =
  case tree of
    Leaf fxs ->
        Leaf (List.map func fxs)

    Branch trees ->
        Branch (List.map (map func) trees)


flatten : EffectTree fx -> List fx
flatten tree =
  flattenHelp tree []


flattenHelp : EffectTree fx -> List fx -> List fx
flattenHelp tree list =
  case tree of
    Leaf fx ->
        fx ++ list

    Branch trees ->
        List.foldr flattenHelp list trees


-- CHAINING

tag : (fx -> fx') -> Transaction fx model -> Transaction fx' model
tag func (Transaction fx model) =
    Transaction (map func fx) model


andThen : Transaction fx a -> (a -> Transaction fx b) -> Transaction fx b
andThen (Transaction fx a) callback =
  let
      (Transaction fx' b) =
          callback a
  in
      Transaction (Branch [fx, fx']) b


with : Transaction fx a -> (a -> Transaction fx model) -> Transaction fx model
with (Transaction fx a) create =
  let
      (Transaction fx' model) =
          create a
  in
      Transaction (Branch [fx, fx']) model


with2
    : Transaction fx a
    -> Transaction fx b
    -> (a -> b -> Transaction fx model)
    -> Transaction fx model
with2 (Transaction fx1 a) (Transaction fx2 b) create =
  let
      (Transaction fx' model) =
          create a b
  in
      Transaction (Branch [fx1, fx2, fx']) model


with3
    : Transaction fx a
    -> Transaction fx b
    -> Transaction fx c
    -> (a -> b -> c -> Transaction fx model)
    -> Transaction fx model
with3 (Transaction fx1 a) (Transaction fx2 b) (Transaction fx3 c) create =
  let
      (Transaction fx' model) =
          create a b c
  in
      Transaction (Branch [fx1, fx2, fx3, fx']) model


-- START

type alias App fx msg model =
    { init : Transaction fx model
    , view : Signal.Address msg -> model -> Html
    , update : msg -> model -> Transaction fx model
    , externalMessages : List (Signal msg)
    }


type alias Output fx msg model =
    { html : Signal Html
    , model : Signal model
    , effects : Signal (List fx)
    , address : Signal.Address msg
    }


start : App fx msg model -> Output fx msg model
start app =
    let
        -- messages : Signal.Mailbox (Maybe msg)
        messages =
            Signal.mailbox Nothing

        -- address : Signal.Address msg
        address =
            Signal.forwardTo messages.address Just

        -- update : Maybe msg -> Transaction fx model -> Transaction fx model
        update (Just msg) (Transaction _ model) =
            app.update msg model

        -- extMessages : Signal msg
        extMessages =
            case app.externalMessages of
                [] ->
                    Signal.constant Nothing

                _ ->
                    Signal.map Just <| Signal.mergeMany app.externalMessages

        -- allMessages : Signal msg
        allMessages =
            Signal.merge messages.signal extMessages

        -- transactions : Signal (Transaction fx model)
        transactions =
            Signal.foldp update app.init allMessages

        -- split : Transaction fx model -> (model, List fx)
        split (Transaction fx model) =
            (model, flatten fx)

        modelAndEffects =
            Signal.map split transactions

        model =
            Signal.map fst modelAndEffects
    in
        { html = Signal.map (app.view address) model
        , model = model
        , effects = Signal.map snd modelAndEffects
        , address = address
        }
