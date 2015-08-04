# Elm Components

Create infinitely nestable components that are easy to write, test, and reuse.

This package is the next step in [The Elm Architecture][arch], making it easy to create components that request JSON, have animations, talk to databases, etc.

[arch]: https://github.com/evancz/elm-architecture-tutorial/


## The General Pattern

The general pattern is a slight extension to [The Elm Architecture][arch]. If you have not read about that, do it now. Come on, here is [the link][arch] again. Go and read it!

...

Alright, now that you know about that, almost everything is the same here. We build up a component as a model, a way to update that model, and a way to view that model. As you look through the following skeleton code, just pretend that `Transaction Message Model` means “a new model”.


```elm
module MyComponent where


-- MODEL

type Model
  -- Represents all the data needed for this component, often a record.

init : options -> Transaction Message Model
  -- Given some options, produce a fresh model. Do not worry about
  -- the `Transaction Message` part yet, we will get into that soon!


-- UPDATE

type Message
  -- All the possible things that can happen to this component.
  -- Data with this type gets sent around whenever someone clicks or
  -- presses keys, whenever an HTTP request completes, when an animation
  -- frame is needed, etc.

update : Message -> Model -> Transaction Message Model
  -- Given a `Message` and a `Model`, produce a new model. Again, pretend
  -- that we are just returning a new `Model`. The full details will be
  -- explained soon!


-- VIEW

view : Signal.Address Message -> Model -> Html
  -- Show the current `Model` on screen. Just describes how the model
  -- should look right at this moment. The address lets the UI send
  -- messages back to our core update logic on user inputs.

```

Overall, this is pretty much the same as [The Elm Architecture][arch], just with that `Transaction` thing added in there.

Let’s look at a simple example to get a feel for how these things work.


## Example 1 - Random GIFs

<p align="center"><a href="http://evancz.github.io/elm-components/examples/random-gifs"><img src ="examples/1/assets/preview.png?raw=true"/></a></p>

This example is a simple component that fetches random gifs from giphy.com with the topic “funny cats”. To follow along you can run the following commands:

```bash
git clone https://github.com/evancz/elm-components.git
cd elm-components/examples/1/
elm-reactor
```

And then open up [http://localhost:8000](http://localhost:8000) in your browser and click on `RandomGif.elm` to try it out.

The next few subsections will be discussing parts of [the code](examples/1/RandomGif.elm), so keep that open so you can look through and contextualize this discussion. The code follows the normal model / update / view pattern that you see in every Elm program, but we will be emphasizing model and update because that’s where the new stuff happens.


### Modeling the Problem

First we have the model of our random GIF finder.

```elm
type alias Model =
    { topic : String
    , image : String
    }
```

We need to know what the `topic` of the finder is and what `image` we are showing right this second. In our case, the topic we want is “funny cats” and the initial image should be loaded from giphy.

Let's start with a simple `init` function and get fancier.

```elm
simpleInit : Transaction Message Model
simpleInit =
  done
    { topic = "funny cats"
    , image = "http://s3.amazonaws.com/giphygifs/media/ldxm2PYf0UDHq/giphy.gif"
    }


-- done : model -> Transaction msg model
```

In this case we always set the "topic" and "image" ourselves. We use `done` to say that this transaction is complete and we just want to give you some data. That's fine, but we really want to take `topic` as an argument. Let's try it.

```elm
betterInit : String -> Transaction Message Model
betterInit topic =
  done
    { topic = topic
    , image = Debug.crash "what do we do here?!?!"
    }
```

So now we can create a GIF viewer for any topic, but we need a way to grab a random image to truly initialize the component. For this we need to introduce the `request` function for creating transactions.

```elm
init : String -> Transaction Message Model
init topic =
  request (getRandomImage topic)
    { topic = topic
    , image = "assets/waiting.gif"
    }


-- request : Task Never msg -> model -> Transaction msg model

-- getRandomImage : String -> Task Never Message
```

Unlike `done`, `request` allows us to give a data result *and* request a certain task. In this case, `getRandomImage` describes how to go to giphy.com and request a random image in the given `topic`. (We will get into the specifics of `getRandomImage` in due time!)

The point is that “initializing” means both providing the current model and asking for some information from the world. The `Transaction` captures both halves of this.

But now we are left wondering what happens when the task described by `getRandomImage model` gets run and has a result to give us. How do we bring that back into our random GIF component? The `elm-component` package is all about routing these events automatically, so it will just show up in our `update` function when it is done!


### Updating the Model

There are events in the world that we want to react to. For our random GIF viewer, we want to react when the user requests more GIFs and when a server somewhere tells us about a new GIF we can show. We model both of those possible events explicitly as a `Message`.

```elm
type Message
    = RequestMore
    | NewImage (Maybe String)
```

So the user can trigger a `RequestMore` message and when the server responds it will give us a `NewImage` message. We handle both these scenarios in our `update` function.

```elm
update : Message -> Model -> Transaction Message Model
update msg model =
  case msg of
    RequestMore ->
      request (getRandomImage model.topic) model

    NewImage maybeUrl ->
      done
        { model |
            image <- Maybe.withDefault model.image maybeUrl
        }


-- request : Task Never msg -> model -> Transaction msg model

-- done : model -> Transaction msg model
```

In the case of `RequestMore` we use the `getRandomImage` function (as seen is the `init` function above) to request a random image in the current topic. We also return the existing model because we do not yet have any new things to show on screen.

When `getRandomImage model.topic` is complete, it will result in a message like this:

```elm
NewImage (Just "http://s3.amazonaws.com/giphygifs/media/ka1aeBvFCSLD2/giphy.gif")
```

It returns a `Maybe` because the request to the server may fail. That `Message` will get fed into our `update` function. So when we take the `NewImage` route we just update the current `image` if possible. If the request failed, we just stick with the current `model.image`.

So now we are able to request and effect and handle the result all from our component, no need to know about anything else in the system.


### Setting Up Effects

One of the crucial aspects of this system is the `getRandomImage` function that actually describes how to get a random GIF. It uses [tasks][] and [the `Http` package][http], but I will try to give an overview of how these things are being used as we go. Let’s look at the definition:

[tasks]: http://elm-lang.org/guide/reactivity#tasks
[http]: http://package.elm-lang.org/packages/evancz/elm-http/latest

```elm
getRandomImage : String -> Task.Task Never Message
getRandomImage topic =
  Http.get decodeImageUrl (randomUrl topic)
    |> Task.toMaybe
    |> Task.map NewImage

-- The first line there created an HTTP GET request. It tries to
-- get some JSON at `randomUrl topic` and decodes the result
-- with `decodeImage`. Both are defined below!
--
-- Next we use `Task.toMaybe` to capture any potential failures.
--
-- Finally we apply the `NewImage` tag to turn the result into
-- a `Message`.


-- Given a topic, construct a URL for the giphy API.
randomUrl : String -> String
randomUrl topic =
  Http.url "http://api.giphy.com/v1/gifs/random"
    [ "api_key" => "dc6zaTOxFJmzC"
    , "tag" => topic
    ]


-- A JSON decoder that takes a big chunk of JSON spit out by
-- giphy and extracts the string at `json.data.image_url` 
decodeImageUrl : Json.Decoder String
decodeImageUrl =
  Json.at ["data", "image_url"] Json.string
```

Once we have written this up, we are able to reuse `getRandomImage` in our `init` and `update` functions.


## More about Transactions

Now that we have seen some of these ideas in action in the random GIF viewer, let’s take a closer look at the details.

At the root of this package is the idea of an `Transaction`.

For the sake of making it concrete we can think of it like this:

```elm
type alias Transaction msg model =
    { model : model
    , desiredEffects : List (Effect msg)
    }
```

This is not strictly true, but it is true enough for learning. A `Transaction` holds:

  - A `model` representing the next state of the world. So when we finally build up a big transaction for our whole application, this new model will get commited and trigger a rerender.

  - A list of effects that need to get run. These effects are the mix of tasks and ticks that were requested in the various `init` and `update` functions. So when we commit to the transaction, we also fire off all these effects. When those effects are complete, they will be fed back into the system, triggering new updates.

So that is a decent conceptual framework for thinking about `Transactions`, but like I said, it is not the true representation. You can create a `Transaction` in a few ways:

```elm
done : model -> Transaction msg model
  -- The simplest way to create a transaction. You just give the new
  -- model. No effects are associated with the new model.

request : Task Never msg -> model -> Transaction msg model
  -- Give a new model AND request that a certain task is run.
  --
  -- Notice that it must be a task that `Never` fails. Another way to
  -- say this is: if the task does fail, that failure *must* be promoted
  -- into the `msg` so that it can be handled explicitly. This ensures
  -- that no tasks are silently failing. This also means you will probably
  -- be wrapping your tasks in `Task.toMaybe` and `Task.toResult` so that
  -- you can handle the error cases explicitly.

requestTick : (Time -> msg) -> model -> Transaction msg model
  -- Give a new model AND request a clock tick for animations
  --
  -- This lets you deal with clock ticks at roughly 60 frames per second.
  -- You can request a bunch of clock ticks to do smooth animations within
  -- your component.
```

These functions are great for a single component, but the real magic is in the helper functions that let us *nest* transactions. The key is the `with` function. Here is a version implemented using our representation of a `Transaction`:

```elm
with
    : Transaction msg submodel
    -> (submodel -> Transaction msg model)
    -> Transaction msg model
with transaction callback =
    let
        {model, desiredEffects} =
            callback transaction.model
    in
        { model = model
        , desiredEffects = transaction.desiredEffects ++ desiredEffects
        }
```

So we use the `model` from the initial `transaction` to run the given `callback`. This gives us a new model and list of desired effects, but the most important detail is that we return a transaction that appends all the desired effects. This means the list of effects keeps building up as we work within this system. When we finally commit to a transaction, all of the effects can be run all at once.

> **Note:** This means that this pattern can be used for query optimization. Since we have all the effects in a big list, we can look at exactly what data they want to fetch and be more clever about it. Maybe that means we can combine queries or grab things out of a local cache. All sorts of clever optimizations become really easy to do! We expect to see this come to `elm-components` as folks start finding cases where the effect manager can be more clever.


Alright, now that we have seen the definition of `with` let’s see it in practice to really see what it can do!


## Example 2 - A Pair of Random GIFs

<p align="center"><a href="http://evancz.github.io/elm-components/examples/random-gifs"><img src ="examples/1/assets/preview.png?raw=true"/></a></p>

In this example we are going to have two random GIF viewers. We will reuse the `RandomGif` module from example 1 without changing the logic at all, just nest it inside of a fancier component.

```elm
module RandomGifPair where

import Components as C exposing (..)
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (..)
import Task
import RandomGif as Gif


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
```