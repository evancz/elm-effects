module Start ( start, Config, App ) where
{-| When you have created an application following
[these guidelines](https://github.com/evancz/elm-components), this module will
get it all running for you!

# Start your Application
@docs start, Config, App

-}

import Html exposing (Html)
import Task
import Transaction exposing (Transaction)


{-| The configuration of an app follows the basic model / update / view pattern
that you see in every Elm program.

The `init` transaction will give you an initial model and create any tasks that
are needed on start up.

The `update` and `view` fields describe how to step the model and view the
model.

The `inputs` field is for any external signals you might need. If you need to
get values from JavaScript, they will come in through a port as a signal which
you can pipe into your app as one of the `inputs`.
-}
type alias Config msg model =
    { init : Transaction msg model
    , update : msg -> model -> Transaction msg model
    , view : Signal.Address msg -> model -> Html
    , inputs : List (Signal.Signal msg)
    }


{-| An `App` is made up of a couple signals:

  * `html` &mdash; a signal of `Html` representing the current visual
    representation of your app. This should be fed into `main`.

  * `model` &mdash; a signal representing the current model. Generally you
    will not need this one, but it is there just in case. You will know if you
    need this.

  * `tasks` &mdash; a signal of tasks that need to get run. Your app is going
    to be producing tasks in response to all sorts of events, so this needs to
    be hooked up to a `port` to ensure they get run.
-}
type alias App model =
    { html : Signal Html
    , model : Signal model
    , tasks : Signal (Task.Task Never ())
    }


{-| Start an application. It requires a bit of wiring once you have created an
`App`. It should pretty much always look like this:

    app =
        start { init = init, view = view, update = update, inputs = [] }

    main =
        app.html

    port taskRunner : Signal (Task.Task Never ())
    port taskRunner =
        app.tasks

So once we start the `App` we feed the HTML into `main` and feed the resulting
tasks into a `port` that will run them all.
-}
start : Config msg model -> App model
start config =
    let
        -- messages : Signal.Mailbox (Maybe msg)
        messages =
            Signal.mailbox Nothing

        -- address : Signal.Address msg
        address =
            Signal.forwardTo messages.address Just

        -- update : Maybe msg -> Transaction fx model -> Transaction fx model
        update (Just msg) (Transaction _ model) =
            config.update msg model

        -- inputs : Signal (Maybe msg)
        inputs =
            Signal.mergeMany (messages.signal :: List.map Just config.inputs)

        -- transactions : Signal (Transaction fx model)
        transactions =
            Signal.foldp update config.init inputs

        -- split : Transaction fx model -> (model, Task Never ())
        split transaction =
            let
                { model, effect } = Transaction.destruct transaction
            in
                (model, Transaction.effectToTask address effect)

        modelAndTasks =
            Signal.map split transactions

        model =
            Signal.map fst modelAndTasks
    in
        { html = Signal.map (config.view address) model
        , model = model
        , tasks = Signal.map snd modelAndTasks
        }
