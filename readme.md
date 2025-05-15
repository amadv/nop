# nop -> Dead Simple Notes App

Welcome to the **Dead Simple Notes App** — a no-BS, text-based note taker written in Perl because why the hell not?

This thing is **stupidly simple**, and that’s the point. No servers, no syncing, no "AI-powered" crap — just you, your terminal, and plain old files.

## What the hell does it do?

- Create timestamped notes like a damn ninja
- Fuzzy find (`fzf`) notes like you’re in the Matrix
- Export, delete, or read notes without losing your mind
- All in plain text — because markdown > your favorite database

## Usage

Run the script with Perl like so:

`perl notes.pl --create "Note1"`

Then just write your shit in vi, nano, or whatever you cursed your $EDITOR with.

### Creating a note

`perl notes.pl --create "My cool ass note"`

It'll pop open your editor and let you scribble brilliance.

### Fuzzy find a note

`perl notes.pl --fzf`

Start typing that vague crap you think you wrote 2 weeks ago — it’ll find it.

### Deleting a note

`perl notes.pl --delete`

It’ll ask, “Are you sure?” like a sane person. Hit y if you really wanna nuke it.

### Export a note

`perl notes.pl --export`

Spits out the raw note into your terminal. Copy-paste that bad boy wherever you want.

### List notes

`perl notes.pl --list`

Gives you a pretty list of all your chaos.

### How to tweak it

    Change your $EDITOR if you don’t vibe with vi. Use export EDITOR=nano or whatever.

    Notes are stored in $BASEDIR. By default, it dumps them in ./. Change it in the script if you like clutter elsewhere.

    Each note is a damn directory. Don’t like it? Fork it and fix it. That’s the open source spirit, baby.

### Why the hell should I use this?

Because you’re tired of Electron apps eating your RAM just to write “Buy milk.”

Because Notion doesn’t work offline when you're in the goddamn woods.

Because you like owning your shit.
