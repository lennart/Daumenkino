# Daumenkino
Live code visuals - A Tidal interface to graphics

_Daumenkino_ is the german word for _flip-book_, it serves as an analogy for what you can do with this. Make your own flip-books in real-time from single frames of a video or completely from scratch using geometric shapes. Think of animated gifs combined with a plot, you decide, in realtime.

## Installation

A requirement for _Daumenkino_ is [weltfrieden](https://github.com/fortmeier/weltfrieden), a simple opengl renderer. To install it run this in terminal:

```
git clone https://github.com/fortmeier/weltfrieden
cd weltfrieden
make
```

To install _Daumenkino_ run:

```
git clone https://github.com/lennart/Daumenkino
cd Daumenkino
cabal install
```

Place `daumenkino.el` in an emacs load-path and start a session in a `.tidal` file via:

`M-x daumenkino-start-haskell`

## Usage

the simplest thing is to show a plane that fades from white to transparent:

```
s1 $ shader "plane"
```

Available shaders are:

* plane
* tri
* circle

other shader names will be read as imagefile names similar to how [Dirt](https://github.com/tidalcycle/Dirt) does.

Available params are:

* width
* height
* x
* y
* speed
* ...

