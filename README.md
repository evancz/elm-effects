# Elm Components

Create infinitely nestable components that are easy to write, test, and reuse.

This package is the next step in [The Elm Architecture][arch], making it easy to create components that request JSON, have animations, talk to databases, etc.

[arch]: https://github.com/evancz/elm-architecture-tutorial/


## The General Pattern

The general pattern is a slight extension to [The Elm Architecture][arch]. If you have not read about that, do it now. Go, do it!

Almost everything is the same here. We build up a component as a model, a way to update that model, and a way to view that model. As you look through the following code, just pretend that `Transaction Message Model` means “a new model”


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

This example is a simple component that fetches random gifs from giphy.com with the topic "funny cats". It lives in `examples/1/`, so to follow along you can run the following commands from the root of this repo.

```bash
cd examples/1/
elm-reactor
```

And then open up [http://localhost:8000](http://localhost:8000) in your browser and click on `RandomGif.elm` to try it out.


### Modeling the Problem

Let's start digging through the code to see how it works. First we have the model.

```elm
type alias Model =
    { topic : String
    , image : String
    }
```

To show our random GIF finder, we need to know what the topic of the finder is and what image we are showing right this second. In our case, the topic we want is “funny cats” and the initial image should be loaded from giphy.

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

In this case we always set the "topic" and "image" ourselves, but we really want to let other people decide on the topic. So lets try again making `topic` an argument.

```elm
betterInit : String -> Transaction Message Model
betterInit topic =
  done
    { topic = topic
    , image = Debug.crash "what do we do here?!?!"
    }
```

So now we let the user set the topic, but we need a way to grab a random image. For this we need to introduce the `request` function for creating transactions.

```elm
init : String -> Transaction Message Model
init topic =
  request (getRandomImage topic)
    { topic = topic
    , image = "assets/waiting.gif"
    }


-- request : Effect msg -> model -> Transaction msg model

-- getRandomImage : String -> Effect Message
```

So in this case we give out the initial model *and* request a certain effect. In particular, `getRandomImage` describes how to go to giphy.com and request a random image in the given `topic`. We will get into the specifics of writing that function in due time. For now, the point is that “initializing” means both providing the current model and asking for some information from the world that will give us a `Message` when it is ready.


### Updating the Model

There are events in the world that we want to react to. For our random GIF viewer, we want to react when the user requests more GIFs and when a server somewhere tells us about a new GIF we can show. We model both of those possible events explicitly as a `Message`.

```
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


-- request : Effect msg -> model -> Transaction msg model

-- done : model -> Transaction msg model
```

In the case of `RequestMore` we use the `getRandomImage` function (as seen is the `init` function above) to request a random image in the current topic. We also return the existing model because we do not yet have any new things to show on screen.

When `getRandomImage model.topic` is complete, it will result in a message like this:

```elm
NewImage (Just "http://s3.amazonaws.com/giphygifs/media/ka1aeBvFCSLD2/giphy.gif")
```

It returns a `Maybe` because the request to the server may fail. That `Message` will get fed into our `update` function. So when we take the `NewImage` route we just update the current `image` if possible. If the request failed, we just stick with the current `model.image`.

So now we are able to request and effect and handle the result all from our component, no need to know about context at all.


### Setting Up Effects

```elm
getRandomImage : String -> C.Effect Message
getRandomImage topic =
  Http.get decodeImageUrl (randomUrl topic)
    |> Task.toMaybe
    |> Task.map NewImage
    |> C.task


randomUrl : String -> String
randomUrl topic =
  Http.url "http://api.giphy.com/v1/gifs/random"
    [ "api_key" => "dc6zaTOxFJmzC"
    , "tag" => topic
    ]


decodeImageUrl : Json.Decoder String
decodeImageUrl =
  Json.at ["data", "image_url"] Json.string
```


## Effects and Transactions

The whole point of this library is to make it easy to work with effects like “talk to that server” and “request an animation frame”. To do that there is an explicit `Effect` type to wrap up these different kinds of effects. We will soon see how this is a core part of a `Transaction`.

```elm
type Effect msg
  -- Represents some computation that will result in a `msg`.


task : Task.Task Never msg -> Effect msg
  -- Given a task that can never fail, create an effect. This means


animationFrame : (Float -> msg) -> Effect msg
```

Okay, so what is a `Transaction`? For the sake of making it concrete we can think of it like this:

```elm
type alias Transaction msg model =
  { model : model
  , desiredEffects : List (Effect msg)
  }
```

This is not the true type, but it is true enough for our purposes here. It holds a new model and a list of effects that need to get run. You can create these transactions in a few ways.

```elm
done : model -> Transaction msg model
  -- The simplest way to create a transaction. You just give the new
  -- model. No effects are associated with the new model.

request : Effect msg -> model -> Transaction msg model
  -- Give a new model AND an effect you would like to run.
```


## Setting up a Project

Run the following commands to create a directory for your project and then download the necessary packages:

```bash
mkdir my-elm-project
cd my-elm-project

elm-package install evancz/elm-html --yes
elm-package install evancz/elm-http --yes
elm-package install evancz/elm-components --yes
```

Your directory structure should now be like this:

```
my-elm-project/
    elm-stuff/
    elm-package.json
```

You should never need to look in `elm-stuff/`, it is entirely managed by the Elm build tool `elm-make` and package manager `elm-package`.

The `elm-package.json` file is interesting though. Open it up and check it out. The most interesting fields for you are probably:

  - `source-directories` &mdash; lists the directories in your project that have Elm source code. I like to set this equal to `[ "src" ]` and put all of my code in a `src/` directory.

  - `dependencies` &mdash; This lists all the packages you need. Depending on what you want to do, you should use these bounds differently:

    - **Creating a product** &mdash; you want to crush those ranges down to things like `3.0.4 <= v <= 3.0.4` such that you can use exact versions.

    - **Creating a package** &mdash; you want to make these ranges exactly as wide as you have tested. Best practice is to start with them within a single major version and then expand as new versions come out and you test that things still work.
