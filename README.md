# vim-javascript-imports

Tired of always looking up module names in the browser? Sick of copy/pasting
JavaScript import lines? Fear not, with this addon you can add and update
import statements with on mapping or command. It can fill in missing import
statements based on the word under the cursor.

It will properly format the import statements even when updating existing ones
and it can wrap long lines--oh and it sorts the variables too.

![animated screen shot](https://sukima.github.io/vim-ember-imports/vim-ember-imports.gif)

**Out of the box the addon does not add any imports.** It is the job of *other*
plugins to define imports you can use in code. See [the documentation][txt-doc]
for information on adding your own.

## Commands, Mappings and Configuration

Read the [help][txt-doc] to know more.

## Installation

### Using [Vundle][vundle]:

Just add this line to your `~/.vimrc`:

```vim
Plugin 'sukima/vim-javascript-imports'
```

And run `:PluginInstall` inside Vim.

### Using [pathogen.vim][pathogen]:

Copy and paste in your shell:

```bash
cd ~/.vim/bundle
git clone https://github.com/sukima/vim-javascript-imports.git
```

### Using [vpm][vpm]:

Run this command in your shell:

```bash
vpm insert sukima/vim-javascript-imports
```

### Using [Plug][plug]:

Just add this line to your `~/.vimrc` inside plug call:

```vim
Plug 'sukima/vim-javascript-imports'
```

And run `:PlugInstall` inside Vim or `vim +PlugInstall +qa` from shell.

## License

MIT

[pathogen]: https://github.com/tpope/vim-pathogen
[txt-doc]: https://raw.githubusercontent.com/sukima/vim-javascript-imports/master/doc/vim-javascript-imports.txt
[vpm]: https://github.com/KevinSjoberg/vpm
[vundle]: https://github.com/gmarik/vundle
[plug]: https://github.com/junegunn/vim-plug
