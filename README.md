# Elm Components

**NOT FOR DISTRIBUTION - EVERYTHING IN THIS REPO IS A PRIVATE DRAFT**

Create infinitely nestable components that are easy to write, test, and reuse.

This package is the next step in [The Elm Architecture][arch], making it easy to create components that request JSON, have animations, talk to databases, etc.

[arch]: https://github.com/evancz/elm-architecture-tutorial/

<br>

# Examples

  - [Random GIF fetcher](http://evancz.github.io/elm-components/examples/random-gifs.html) &mdash; [code](https://github.com/evancz/elm-components/tree/master/examples/1)
  - [Pair of random GIFs](http://evancz.github.io/elm-components/examples/random-gifs-pair.html) &mdash; [code](https://github.com/evancz/elm-components/tree/master/examples/2)
  - [List of random GIFs](http://evancz.github.io/elm-components/examples/random-gifs-list.html) &mdash; [code](https://github.com/evancz/elm-components/tree/master/examples/3)
  - [Animating Components](http://evancz.github.io/elm-components/examples/animation-pair.html) &mdash; [code](https://github.com/evancz/elm-components/tree/master/examples/4)


<br>

# Tutorial

The rest of the README is dedicated to running through the four examples that come with this package. We will gradually build from a general understanding of [The Elm Architecture][arch] to a good understanding of how `Transaction` works and how it makes it possible to handle effects locally in each component.


## The General Pattern

The general pattern is a slight extension to [The Elm Architecture][arch]. If you have not read about that, do it now. Come on, here is [the link][arch]. Go and read it!

Alright, now that you know about that, almost everything is the same here. We build up a component as a model, a way to update that model, and a way to view that model. As you look through the following skeleton code, read `Transaction Message Model` as “a new model” to get the basic intuition:


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

[**TRY IT OUT!!!**](http://evancz.github.io/elm-components/examples/random-gifs.html)

This example is a simple component that fetches random gifs from giphy.com with the topic “funny cats”. To follow along, run the following commands:

```bash
git clone https://github.com/evancz/elm-components.git
cd elm-components/examples/1/
elm-reactor
```

And then open up [http://localhost:8000](http://localhost:8000) in your browser and click on `RandomGif.elm` to try it out.

Make sure you look through [the implementation](https://github.com/evancz/elm-components/tree/master/examples/1/RandomGif.elm) right now. Notice that it is pretty much the same code as with The Elm Architecture: model, update, view. The only weird parts are that `init` and `update` return a `Transaction` and do a little bit of extra stuff.

Okay, you looked through the code? From now on I am assuming you have!


### Modeling the Problem

As always, the code starts out with a model of our random GIF finder.

```elm
type alias Model =
    { topic : String
    , image : String
    }
```

We need to know what the `topic` of the finder is and what `image` we are showing right this second. What is new about this component is that we want the `image` to be retrieved from giphy.com through an HTTP request. We somehow need to talk about those effects to initialize our model.

So let's start with a simple `init` function and slowly build up to one that does what we want.

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
  requestTask (getRandomImage topic)
    { topic = topic
    , image = "assets/waiting.gif"
    }


-- request : Task Never msg -> model -> Transaction msg model

-- getRandomImage : String -> Task Never Message
```

Unlike `done`, `request` allows us to give a data result *and* request a certain task. In this case, `getRandomImage` describes how to go to giphy.com and request a random image in the given `topic`. (We will get into the specifics of `getRandomImage` in due time!)

The point is that “initializing” means both providing the current model and asking for some information from the world. The `Transaction` captures both halves of this.

But now we are left wondering what happens when the task described by `getRandomImage model` gets run and has a result to give us. How do we bring that back into our random GIF component? The `elm-component` package is all about routing these events automatically, so the results of that HTTP request will just show up in our `update` function!


### Updating the Model

There are events in the world that we want to react to. For our random GIF viewer, we want to react when the user requests more GIFs and when a server somewhere tells us about a new GIF we can show. We model both of those possible events explicitly as a `Message`.

```elm
type Message
    = RequestMore
    | NewImage (Maybe String)
```

So the user can trigger a `RequestMore` message by clicking the “More Please!” button, and when the server responds it will give us a `NewImage` message. We handle both these scenarios in our `update` function.

```elm
update : Message -> Model -> Transaction Message Model
update msg model =
  case msg of
    RequestMore ->
      request (getRandomImage model.topic) model

    NewImage maybeUrl ->
      done { model | image <- Maybe.withDefault model.image maybeUrl }


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

One of the crucial aspects of this system is the `getRandomImage` function that actually describes how to get a random GIF. It uses [tasks][] and [the `Http` package][http], and I will try to give an overview of how these things are being used as we go. Let’s look at the definition:

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

One of the interesting things about the task returned by `getRandomImage` is that it can `Never` fail. The idea is that any potential failure *must* be handled explicitly. We do not want any tasks failing silently.

I am going to try to explain exactly how that works, but it is not crucial to get every piece of this to use things! Okay, so every `Task` has a failure type and a success type. For example, an HTTP task may have a type like this `Task Http.Error String` such that we can fail with an `Http.Error` or succeed with a `String`. This makes it nice to chain a bunch of tasks together without worrying too much about errors. Now lets say our component requests a task, but the task fails. What happens then? Who gets notified? How do we recover? By making the failure type `Never` we force any potential errors into the success type such that they can be handled explicitly by the component. In our case, we use `Task.toMaybe : Task x a -> Task y (Maybe a)` so our `update` function must explicitly handle HTTP failures. This means tasks cannot silently fail, you always handle potential errors explicitly.


## More about Transactions

Now that we have seen some of these ideas in action in the random GIF viewer, let’s take a closer look at the details.

At the root of this package is the idea of an `Transaction`.

For the sake of making it concrete we can think of it like this:

```elm
type alias Transaction msg model =
    { model : model
    , effects : List (Effect msg)
    }
```

This is not strictly true, but it is true enough for learning. A `Transaction` holds:

  - A `model` representing the next state of the world. So when we finally build up a big transaction for our whole application, this new model will get commited and trigger a rerender.

  - A list of effects that need to get run. These effects are the mix of tasks and ticks that were requested in the various `init` and `update` functions. So when we commit to the transaction, we also fire off all these effects. When those effects are complete, they will be fed back into the system, triggering new updates.

This is a decent conceptual framework for understanding `Transactions`, but like I said, the true representation is slightly fancier. You can create a `Transaction` in a few ways:

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
        {model, effects} =
            callback transaction.model
    in
        { model = model
        , effects = transaction.effects ++ effects
        }
```

So we use the `model` from the initial `transaction` to run the given `callback`. This gives us a new model and list of desired effects, but the most important detail is that we return a transaction that appends all the desired effects. This means the list of effects keeps building up as we work within this system. When we finally commit to a transaction, all of the effects can be run all at once.

> **Note:** This means that this pattern can be used for query optimization. Since we have all the effects in a big list, we can look at exactly what data they want to fetch and be more clever about it. Maybe that means we can combine queries or grab things out of a local cache. All sorts of clever optimizations become really easy to do! We expect to see this come to `elm-components` as folks start finding cases where the effect manager can be more clever.

Alright, now that we have seen the definition of `with` let’s see it in practice to really see what it can do!


## Example 2 - A Pair of Random GIFs

[**TRY IT OUT!!!**](http://evancz.github.io/elm-components/examples/random-gifs-pair.html)

In this example we are going to have **two** random GIF viewers. The cool part is that we will reuse the `RandomGif` module from example 1 without changing the logic at all.

To follow along, run the following commands from your `elm-components/` directory:

```bash
cd examples/2/
elm-reactor
```

And then open up [http://localhost:8000](http://localhost:8000) in your browser and click on `RandomGifPair.elm` to try it out.

Take a look through [the implementation](https://github.com/evancz/elm-components/tree/master/examples/2/RandomGifPair.elm) to get a feel for it. Again we have the typical model, update, and view sections. They all hinge upon the `Model` and `Message` type.

```elm
type alias Model =
    { left : Gif.Model
    , right : Gif.Model
    }

type Message
    = Left Gif.Message
    | Right Gif.Message
```

Our model is a pair of `RandomGif` models, and our messages are just routing a `RandomGif` message to the left or right model.

Digging deeper into the code, the only thing that is new is how things work in `init` and `update`. Interestingly, the `view` function actually helps explain what is going on there, so that is where we will start!

```elm
view : Signal.Address Message -> Model -> Html
view address model =
  div [ style [ ("display", "flex") ] ]
    [ Gif.view (Signal.forwardTo address Left) model.left
    , Gif.view (Signal.forwardTo address Right) model.right
    ]
```

So here we are using `Signal.forwardTo` to tag all messages from these subcompononts with `Left` or `Right`. This makes it possible to route messages to the right place without needing to know who owns your particular component. A very similar strategy shows up with transactions. When we look at `init` we see it happening, so lets build up to that from a pseudocode version.

```elm
init : String -> String -> Transaction Message Model
init leftTopic rightTopic =
  -- initialize a random GIF viewer for `leftTopic`
  -- initialize a random GIF viewer for `rightTopic`
  -- put both of these models into our `Model`
```

This means we will want to be using `Gif.init` to initialize each subcomponent, so we will be creating two transactions and trying to put them together. Looking at the real code, we actually put all these pieces together:

```elm
init : String -> String -> Transaction Message Model
init leftTopic rightTopic =
  with2
    (tag Left (Gif.init leftTopic))
    (tag Right (Gif.init rightTopic))
    (\left right -> done { left = left, right = right })


-- Gif.init : String -> Transaction Gif.Message Gif.Model

-- tag : (msg -> msg') -> Transaction msg model -> Transaction msg' model

-- with2
--     : Transaction msg a
--     -> Transaction msg b
--     -> (a -> b -> Transaction msg model)
--     -> Transaction msg model
```

A couple things are going on here. First, we are using `with2` to combine two transactions into one. Whatever model is returned by the two transactions, we can use it to build up a third one, so we put the left and right results into our model. Second, we are doing something with this `tag` function. The new thing about transactions is that they may be associated with some effects, and the results of those effects need to be routed to the right place. So just like with `Signal.forwardTo` in our `view` function, the `tag` function is saying “whatever events are produced from `Gif.init`, route them to the `Left` GIF viewer”.

We see the same thing happening in the `update` function:

```elm
update : Message -> Model -> Transaction Message Model
update message model =
  case message of
    Left msg ->
      with
        (tag Left (Gif.update msg model.left))
        (\left -> done { model | left <- left })

    Right msg ->
      with
        (tag Right (Gif.update msg model.right))
        (\right -> done { model | right <- right })
```

When we get an update for the `Left` GIF viewer, we go call its update function, resulting in a transaction. We use `tag Left` to make sure any effects from that transaction will be routed correctly. Finally we update our model to have the updated left model.

So the key thing here is that we use `with` to put together a bunch of transactions and we use `tag` to make sure effects get routed to the right place.


## Example 3 - A List of Random GIFs

[**TRY IT OUT!!!**](http://evancz.github.io/elm-components/examples/random-gifs-list.html)

This example lets you have a list of random GIF viewers where you can create the topics yourself. Again, we reuse the core `RandomGif` module exactly as is.

To run it on your machine, run following commands from your `elm-components/` directory:

```bash
cd examples/3/
elm-reactor
```

And then open up [http://localhost:8000](http://localhost:8000) in your browser and click on `RandomGifList.elm` to try it out.

When you look through [the implementation](https://github.com/evancz/elm-components/tree/master/examples/3/RandomGifList.elm) you will see that it exactly corresponds to example 3 in [the Elm Architecture tutorial][arch]. We put all of our submodels in a list associated with an ID and do our operatons based on those IDs. The only thing new is that we are using transactions to put things together in the `init` and `update` function.

Open an issue if you have read [this tutorial][arch] and read up to this point, but still think this needs more explanation!


## Example 4 - Animation

Now we have seen components with tasks that can be nested in arbitrary ways, but how does it work for animation?

Interestingly, it is pretty much exactly the same!

[**TRY IT OUT!!!**](http://evancz.github.io/elm-components/examples/animation-pair.html)

This example is a pair of clickable squares. When you click a square, it rotates 90 degrees. Overall the code is an adapted form of example 2 where we keep all the logic for animation lives in `SpinSquare.elm` which we then reuse multiple times in `SpinSquarePair.elm`. 

To run it on your machine, run following commands from your `elm-components/` directory:

```bash
cd examples/4/
elm-reactor
```

And then open up [http://localhost:8000](http://localhost:8000) in your browser and click on `SpinSquarePair.elm` to try it out.

> **Note:** I expect we can build some abstractions on top of the core ideas here. This example does some lower level stuff, but I bet we can find some nice patterns to make this easier as we work with it more. If you find it weird now, try to make something better and tell us about it!


### How does it work?

All the new and interesting stuff is happening in `SpinSquare`, so we are going to focus on that code. The first thing we need there is a model:

```elm
type alias Model =
    { angle : Float
    , animationState : Maybe { prevClockTime : Float, time : Float }
    }


init : Transaction Message Model
init =
  done { angle = 0, animationState = Nothing }


rotateStep = 90
```

So our core model is the `angle` that the square is currently at and then some `animationState` to track what is going on with any ongoing animation. If there is no animation it is `Nothing`, but if something is happening it holds:
  
  * `prevClockTime` &mdash; The most recent clock time which we will use for calculating time diffs. It will help us know exactly how many milliseconds have passed since last frame.
  * `count` &mdash; A number between 0 and 1000 that tells us how far we are in the animation.

The `rotateStep` constant is just declaring how far it turns on each click. You can mess with that and everything should keep working.

Now the interesting stuff all happens in `update`:

```elm
update : Message -> Model -> Transaction Message Model
update msg model =
  case msg of
    Spin ->
      requestTick Tick model

    Tick clockTime ->
      let
        newCount =
          case model.animationState of
            Nothing ->
              0

            Just {count, prevClockTime} ->
              count + (clockTime - prevClockTime)
      in
        if newCount > 1000 then
          done
            { angle = model.angle + rotateStep
            , animationState = Nothing
            }
        else
          requestTick Tick
            { angle = model.angle
            , animationState = Just { count = newCount, prevClockTime = clockTime }
            }
```

There are two kinds of `Message` we need to handle:

  - `Spin` indicates that a user clicked the shape, requesting a spin. When we handle that in the `update` function, we just request a clock tick.
  - `Tick` indicates that we have gotten a clock tick so we need to take an animation step. In the `update` function this means we need to update our `animationState`. So first we check if there is an animation in progress. If so, we just figure out what the `newCount` is by taking the current `count` and adding a time diff to it. If the count is greater than 1000 we stop animating and stop requesting new clock ticks. Otherwise we update the animation state and request another clock tick.

Again, I think we can cut this code down as we write more code like this and start seeing the general pattern. Should be exciting to find!


### Viewing the Animation

Finally we have a somewhat interesting `view` function! This example gets a nice bouncy animation, but we are just counting from 0 to 1000. How is that happening?

We are using the [@Dandandan](https://github.com/Dandandan)’s [easing package](http://package.elm-lang.org/packages/Dandandan/Easing/latest) which makes it to do [all sorts of cool easings](http://easings.net/) on numbers, colors, points, and any other crazy thing you want. We are also using [`elm-svg`](http://package.elm-lang.org/packages/evancz/elm-svg/latest/) to work with fancier shapes.

```elm
-- import Easing exposing (ease, easeOutBounce, float)

view : Signal.Address Message -> Model -> Html
view address model =
  let
    angle =
      case model.animationState of
        Nothing ->
          model.angle

        Just {count} ->
          model.angle + ease easeOutBounce float 0 rotateStep 1000 count
  in
    svg
      [ width "200", height "200", viewBox "0 0 200 200" ]
      [ g [ transform ("translate(100, 100) rotate(" ++ toString angle ++ ")")
          , onClick (Signal.message address Spin)
          ]
          [ rect
              [ x "-50"
              , y "-50"
              , width "100"
              , height "100"
              , rx "15"
              , ry "15"
              , style "fill: #60B5CC;"
              ]
              []
          , text' [ fill "white", textAnchor "middle" ] [ text "Click me!" ]
          ]
      ]
```

The SVG stuff here is pretty typical, just showing some nodes in certain places. The interesting thing is how we calculate `angle` if there is an ongoing animation.

So the `ease` function is taking a number between 0 and 1000. It then turns that into a number between 0 and `rotateStep` which we set to 90 degrees up top. You also provide an easing. In our case we gave `easeOutBounce` which means as we slide from 0 to 1000, we will get a number between 0 and 90 with that easing added. Pretty crazy! Try swapping `easeOutBounce` out for [other easings](http://package.elm-lang.org/packages/Dandandan/Easing/latest/Easing) and see how it looks!

From here, we wire everything together in `SpinSquarePair`, but that code is pretty much exactly the same as in example 2.

Okay, so that is the basics of doing animation with this library! It is not clear if we nailed everything here, so let us know how things go as you get more experience. Hopefully we can make it even easier!