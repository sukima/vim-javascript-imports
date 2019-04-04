" Vim plugin for managing JavaScript import statements
" Maintainer: Devin Weaver <suki@tritarget.org>
" Last Change: 2019 Mar 29

" Exit quickly when:
" - this plugin was already loaded
" - when 'compatible' is set
if exists("loaded_vim_javascript_imports") || &cp
  finish
endif
let loaded_vim_javascript_imports = 1

" Settings {{{1
if !exists('g:vim_javascript_imports_use_semicolons')
  let g:vim_javascript_imports_use_semicolons = 1
endif
if !exists('g:vim_javascript_imports_multiline_max_vars')
  let g:vim_javascript_imports_multiline_max_vars = 3
endif
if !exists('g:vim_javascript_imports_multiline_max_col')
  let g:vim_javascript_imports_multiline_max_col = 80
endif
if !exists('g:vim_javascript_imports_map')
  let g:vim_javascript_imports_map = '<Leader>e'
endif

let g:vim_javascript_import_definitions = {}

" JSAddImportDefinition {{{1
function JSAddImportDefinition(definition)
  let g:vim_javascript_import_definitions[a:definition.name] = a:definition
endfunction

" JSAddImport {{{1
function JSAddImport(importString)
  let definitions = jsimports#getDefinitions(a:importString)
  for definition in definitions
    call JSAddImportDefinition(definition)
  endfor
endfunction

" }}}1

if !empty(g:vim_javascript_imports_map)
  execute "nnoremap " . g:vim_javascript_imports_map . " :call jsimports#run()<Cr>"
endif

command -nargs=1 JSAdd call JSAddImport(<f-args>)
command -nargs=* -complete=customlist,jsimports#complete JSImport call jsimports#run(<f-args>)

" vim:sw=2 ts=2 et fdm=marker
