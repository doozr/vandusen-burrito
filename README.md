# vandusen-burrito

A collection of additional vandusen plugins for extra chattiness.

Vandusen is an IRC bot framework written in Chicken Scheme and drives the
official Chicken IRC bot. This set of plugins simply enables some more
features to make interacting with the bot more fun.

The plugins give:

* A simple greeter that says hello to people joining a channel
* A simple responder that allows bot-driven actions to be defined
* A MegaHAL AI that lets the bot learn to speak like a real chan member

# Installation

Assuming you already have Chicken installed, run the following command from
within the repository:

```
sudo chicken-install
```

This will build and install the shared libraries.

In addition a simple Makefile is included with just `install` and `clean`
targets. These wrap chicken-install and delete all object files
respectively.

Note that MegaHAL is bundled with this repo so does not need to be
installed prior to this egg. It is statically linked to the
vandusen-megahal plugin.

# Using the plugins

## vandusen-greeter

A simple greeter than accepts a user defined list of greetings. Configured
like this in your vandusen config file:

``` scheme
(use vandusen vandusen-greeter)

($ 'greetings '("hello" "hi" "howdy"))

; rest of configuration
```

Whenever somebody joins a random entry is picked from the list of greetings
and prepended to their nick.

## vandusen-responder

A simple responder that lets bot-driven actions be defined. A command
prefixed with a special character triggers the command. The default
character is ! but it can be any string.

To configure a responder use the `responder` function. It should return a
string or #f. If a string is returned it is sent to the same receiver as
the original command.

``` scheme
(use vandusen vandusen-greeter extras)

($ 'responder-prefix ".")

(responder 'annotate
           (lambda (cmd sender receiver message)
             (sprintf "~A said \"~A\" to ~A with the ~A responder" sender message receiver cmd)))
```

In use this would work as follows:

```
<doozr> .annotate I did it my way!
<burrito> doozr said "I did it my way!" to #burritochan with the annotate responder
```

## vandusen-megahal

A MegaHAL based chatterbot for vandusen. The MegaHAL .brn and .trn file is
loaded from the working directory when the vandusen bot was started. There
is not much configuration possible, with the exception of the duration
between automatic brain-dumps to disk.

The normal operation of the plugin is the learn everything said in channel,
and to produce an "intelligent" response whenever its name is mentioned.

The vandusen-megahal plugin overrides the "fall-through" command handler
so, if no other command matches a message directed at the bot, a response
is produced instead of the default "what?"

``` scheme
(use vandusen vandusen-megahal)

; Optional: set duration in seconds between brain saves
($ 'megahal-save-timeout 1800)
```

In channel this appears as random gibberish spouted by the bot whenever it
is mentioned.

```
*** doozr has joined #burritochan
<burrito> Yo doozr
<doozr> Hey burrito, how are you?
<burrito> You are a human, but I am a bot. How are you?
<doozr> I am well, burrito. Sorry you are a bot.
<burrito> There is nothing of note in the fact that I am a bot. My name is burrito.
```

