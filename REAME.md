# Load order
vim `:help initialize` shows that `.vimrc` is loaded before pulgins.
Plugins are loaded in `runtimepath` and loaded alphabetatically.


Note that subdirectories will also be loaded,like:
```bash
:runtime! plugin/**/*.vim
```

This is why we name `xlog.vim` as `init0_xlog.vim`,because we want it to be loaded first


# Programming Convertion
- Exported names are uppercase
- Unexported names are lowercase

# Templates
## New Scripts
```
"Class: XFind
"============================

if exists("g:xfind_loaded")
	finish
endif
let g:xfind_loaded= 1
XInfo "load XFind"

let s:Find= {}
let g:XFind= s:Find
```

And execute:
```
%s/\v[Ff]ind/Comment/g
%s/\vxComment_loaded/xcomment_loaded/g
```
Replace Comment with your new script name

## `-bar` option command
When defining command, you can specify a `-bar`,this causes the command disallow `|` as its argument, and it will also check " for comment start.
Thus when executing such command, you must not use "" to quote argument,but ''.
