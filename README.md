# Elm Effects

A package for working with effects like HTTP and animation within [The Elm Architecture][arch].

[arch]: https://github.com/evancz/elm-architecture-tutorial/


## Examples

These small examples are set up to clarify the key ideas by progressively introducing new stuff. Read [the Elm Architecture tutorial][arch] for a full walk through of these examples.

  - [Random GIF fetcher](http://evancz.github.io/elm-architecture-tutorial/examples/5) &mdash; [code](https://github.com/evancz/elm-architecture-tutorial/tree/master/examples/5)
  - [Pair of random GIFs](http://evancz.github.io/elm-architecture-tutorial/examples/6) &mdash; [code](https://github.com/evancz/elm-architecture-tutorial/tree/master/examples/6)
  - [List of random GIFs](http://evancz.github.io/elm-architecture-tutorial/examples/7) &mdash; [code](https://github.com/evancz/elm-architecture-tutorial/tree/master/examples/7)
  - [Animating Components](http://evancz.github.io/elm-architecture-tutorial/examples/8) &mdash; [code](https://github.com/evancz/elm-architecture-tutorial/tree/master/examples/8)


## Older Browsers

Elm Effects uses [`requestAnimationFrame`](https://developer.mozilla.org/en-US/docs/Web/API/window/requestAnimationFrame) for animations. To use Elm Effects with browsers which do not have `requestAnimationFrame`, such as Internet Explorer 9, you should polyfill it with something like [`cagosta/requestAnimationFrame`](https://github.com/cagosta/requestAnimationFrame)
