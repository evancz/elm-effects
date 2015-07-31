module Helper where

import Color exposing (Color)
import Easing exposing (Easing, Interpolation, ease)
import Time exposing (Time)

type alias Vector =
  { x : Float
  , y : Float
  }

-------------------
-- Transition Type

type alias Transition a =
  { from      : a
  , current   : a
  , to        : a
  , curTime   : Time
  }

newTransition : a -> a -> Transition a
newTransition from to =
  { from    = from
  , current = from
  , to      = to 
  , curTime = 0
  }

incrementTime : Time -> Transition a -> Transition a
incrementTime frame transition =
  { transition | curTime <- transition.curTime + frame }

reverse : Transition a -> Transition a
reverse transition =
  { transition | from <- transition.to
               , to   <- transition.from
  }

hasReachedGoal : Transition a -> Bool
hasReachedGoal transition =
  transition.current == transition.to


applyEasing : Easing -> Interpolation a -> Time -> Transition a -> Transition a
applyEasing easing interpolation duration transition =
  { transition | current <- ease easing interpolation transition.from transition.to duration transition.curTime }

---------------------

toRgbaString : Color -> String
toRgbaString color =
  let {red, green, blue, alpha} = Color.toRgb color
  in
      "rgba(" ++ toString red ++ ", " ++ toString green ++ ", " ++ toString blue ++ ", " ++ toString alpha ++ ")"


translate {x, y} =
  "translate3d(" ++ toString x ++ "px, " ++ toString y ++ "px, 0px)"

scale s =
  "scale(" ++ toString s ++ ")"

infixl 2 =>
(=>) = (,)
