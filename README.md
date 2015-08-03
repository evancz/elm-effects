# Elm Components

Create infinitely nestable components that are easy to write, test, and reuse.

This package is the next step in [The Elm Architecture][arch], making it easy to create components that request JSON, have animations, talk to databases, etc.

[arch]: https://github.com/evancz/elm-architecture-tutorial/

This README is going to describe:

  - HTTP Examples
      1. Component that fetches random GIFs
      2. A pair of random GIF components
      3. A list of random GIFs where you can add new topics

  - Animation Examples
      1. A pair of animating shapes

  - Setting up a project from scratch


## Components that make HTTP Requests


## Components with Animations


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
