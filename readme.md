# nop → Dead Simple Notes App

Welcome to **nop**, the no-BS, text-based note taker written in Perl because why the hell not?  

This thing is **stupidly simple**, and that’s the point. No servers, no syncing, no "AI-powered" crap — just you, your terminal, and plain old files in `~/Notes`.

## What the hell does it do?

- Create timestamped notes like a damn ninja  
- Fuzzy find (`fzf`) notes like you’re in the Matrix  
- Export, delete, or read notes without losing your mind  
- All in plain text — because markdown > your favorite database  

## Installation

Clone this repo (or just grab `nop.pl`), then run the setup script:

```bash
perl setup_nop.pl
```

This will:

    * Create ~/Notes/ for your chaos

    * Symlink nop.pl into ~/.local/bin/nop

    * Make sure it’s executable


Now you can just type from anywhere

```bash
nop
```

## Quick Example Session

Here’s how a typical workflow feels:

### 1. Create a note
```bash
nop --create "Buy milk and whiskey"
```

### 2. List notes
```bash
nop --list
```

### 3. Fuzzy find note
```bash
nop --fzf
```

Gives you a pretty list of all your chaos.

### How to tweak it

    Change your $EDITOR if you don’t vibe with vi. Use export EDITOR=nano or whatever.

    Notes are stored in $BASEDIR. By default, it dumps them in ./. Change it in the script if you like clutter elsewhere.

    Each note is a damn directory. Don’t like it? Fork it and fix it. That’s the open source spirit, baby.

### Why the hell should I use this?

Because you’re tired of Electron apps eating your RAM just to write “Buy milk.”

Because Notion doesn’t work offline when you're in the goddamn woods.

Because you like owning your shit.
