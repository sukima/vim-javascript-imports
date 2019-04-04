" Vim plugin for managing JavaScript import statements
" Maintainer: Devin Weaver <suki@tritarget.org>
" Last Change: 2019 Mar 29

" TokenizeImportString {{{1
function s:TokenizeImportString(importString)
  let line = substitute(a:importString, '\v[\n\r;,]', ' ', 'g')
  let line = substitute(line, '\v\{', ' !OpenBracket ', 'g')
  let line = substitute(line, '\v\}', ' !CloseBracket ', 'g')
  let line = substitute(line, '\v[''"]', ' !Quote ', 'g')
  return split(line, '\v[[:space:]]+')
endfunction

" ParseAST {{{1
function s:ParseAST(tokens)
  let ast = []
  let isFrom = 0
  let isAlias = 0
  let isDefault = 1
  let foundImport = 0
  let foundDefault = 0
  for token in a:tokens
    if token ==# 'import'
      if foundImport
        throw 'Redundent import statement'
      endif
      let isDefault = 1
      let foundImport = 1
      continue
    endif
    if !foundImport
      throw 'Missing import statement'
    endif
    if token ==# '!OpenBracket'
      if isAlias
        throw 'Missing alias statement argument'
      endif
      let isDefault = 0
      continue
    endif
    if token ==# '!CloseBracket'
      if isAlias
        throw 'Missing value for keyword at'
      endif
      if isDefault
        throw 'Closing bracket found without an opening bracket'
      endif
      let isDefault = 1
      continue
    endif
    if token ==# 'as' && !isAlias
      let isAlias = 1
      continue
    endif
    if token ==# 'from'
      if isAlias
        throw 'Missing value for keyword at'
      endif
      let isFrom = 1
      continue
    endif
    if token ==# '!Quote'
      continue
    endif
    if isFrom
      let ast = ast + [{'type': 'from', 'value': token}]
      break
    endif
    if isAlias
      let ast[-1].alias = token
      let isAlias = 0
    else
      if isDefault && foundDefault
        throw 'Redundent default import for ' . token
      endif
      if isDefault
        let foundDefault = 1
      endif
      let ast = ast + [{'type': 'symbol', 'name': token, 'default': isDefault, 'alias': 0}]
    endif
  endfor
  return ast
endfunction

" CompileDefinitions {{{1
function s:CompileDefinitions(ast)
  let definitions = []
  let nodeStack = []
  for node in a:ast
    if node.type == 'symbol'
      let nodeStack = nodeStack + [node]
    elseif node.type == 'from'
      for item in nodeStack
        if item.alias
          let definitions = definitions + [{'name': item.alias, 'default': item.default, 'from': node.value, 'aliased': item.name}]
        else
          let definitions = definitions + [{'name': item.name, 'default': item.default, 'from': node.value}]
        endif
      endfor
      let nodeStack = []
    else
      throw "Unknown type: " . item.type
    endif
  endfor
  return definitions
endfunction

" IndentChars {{{1
function! s:IndentChars(num)
  let identStr = &expandtab ? repeat(' ', shiftwidth()) : '\t'
  return repeat(identStr, a:num)
endfunction

" RenderImport {{{1
function! s:RenderImport(ast, from)
  let defaultPart = v:null
  let destructureParts = []
  for token in a:ast
    let part = token.name
    if has_key(token, 'alias') && !empty(token.alias)
      let part = part . ' as ' . token.alias
    endif
    if token.default
      let defaultPart = part
    else
      let destructureParts = destructureParts + [part]
    endif
  endfor
  let parts = ['import']
  if !empty(defaultPart)
    let part = defaultPart
    if !empty(destructureParts)
      let part = part . ','
    endif
    let parts = parts + [part]
  endif
  if !empty(destructureParts)
    let destructureParts = map(sort(uniq(destructureParts)), 'v:val . ","')
    let destructureParts[-1] = substitute(destructureParts[-1], '\v,$', '', '')
    let parts = parts + ['{'] + destructureParts + ['}']
  endif
  let semicolon = g:vim_javascript_imports_use_semicolons ? ';' : ''
  let parts = parts + ['from', "'" . a:from . "'" . semicolon]
  let importLine = join(parts, ' ')
  let wrapParts = g:vim_javascript_imports_multiline_max_vars > 0 &&
        \ len(destructureParts) > g:vim_javascript_imports_multiline_max_vars
  let wrapLine = g:vim_javascript_imports_multiline_max_col > 0 &&
        \ strchars(importLine) > g:vim_javascript_imports_multiline_max_col
  if wrapParts
    let sep = s:IndentChars(1)
    let firstBracketIdx = index(parts, '{')
    let lastBracketIdx = index(parts, '}')
    let lines = [join(parts[0:firstBracketIdx], ' ')]
    for part in parts[firstBracketIdx+1:lastBracketIdx-1]
      let lines = lines + [sep . part]
    endfor
    let lines = lines + [join(parts[lastBracketIdx:], ' ')]
  elseif wrapLine
    let fromIdx = index(parts, 'from')
    let lines = [
          \ join(parts[0:fromIdx-1], ' '),
          \ s:IndentChars(1) . join(parts[fromIdx:])
          \ ]
  else
    let lines = [importLine]
  endif
  return lines
endfunction

" DefinitionForToken {{{1
function! s:DefinitionForToken(token)
  if !has_key(g:vim_javascript_import_definitions, a:token)
    throw 'UnknownImport:' . a:token
  endif
  let info = g:vim_javascript_import_definitions[a:token]
  if has_key(info, 'aliased') && !empty(info.aliased)
    return {'name': info.aliased, 'alias': a:token, 'default': info.default, 'from': info.from}
  else
    return {'name': a:token, 'alias': v:null, 'default': info.default, 'from': info.from}
  endif
endfunction

" AppendJavascriptImport {{{1
function! s:AppendJavascriptImport(pos, definition)
  let importStr = s:RenderImport([a:definition], a:definition.from)
  if a:pos == 0
    let importStr = importStr + ['']
  endif
  call append(a:pos, importStr)
  return len(importStr)
endfunction

" UpdateJavascriptImport {{{1
function! s:UpdateJavascriptImport(pos, lines, definition)
  let definitions = jsimports#getDefinitions(a:lines) + [a:definition]
  let importStr = s:RenderImport(definitions, a:definition.from)
  call append(a:pos, importStr)
  return len(importStr)
endfunction

" FindLastImport {{{1
function! s:FindLastImport()
  call cursor(line('$'), 0)
  let pos = search('\v^<import>', 'bcW')
  return pos > 0 ? search('\v<from>', 'cW') : 0
endfunction

" GetImportLines {{{1
function! s:GetImportLines()
  let start = line('.')
  let end = start
  let lines = getline(start)
  if lines !~# '\v^i<import>'
    let start = search('\v^<import>', 'bnW')
    let lines = join(getline(start, end))
  endif
  return {'start': start, 'end': end, 'lines': lines}
endfunction

" AddOrUpdateJavascriptImport {{{1
function! s:AddOrUpdateJavascriptImport(token)
  let prevpos = getcurpos()
  try
    let definition = s:DefinitionForToken(a:token)
  catch /^UnknownImport/
    echohl Error
    echo 'Unknown JavaScript import: ' . a:token
    echohl None
    return
  endtry
  let loc = search('\vfrom\s[''"]' . escape(definition.from, '_.-/@') . '[''"]', 'bcwz')
  if loc == 0
    let adjustment = s:AppendJavascriptImport(s:FindLastImport(), definition)
  else
    let importPos = s:GetImportLines()
    execute importPos.start . ',' . importPos.end . ' delete _'
    let adjustment = s:UpdateJavascriptImport(importPos.start - 1, importPos.lines, definition)
    let adjustment = adjustment - (importPos.end - importPos.start) - 1
  endif
  let curpos = getcurpos()
  let prevpos[1] = prevpos[1] + adjustment
  call setpos('.', prevpos)
  call setpos("''", curpos)
endfunction

" jsimports#getDefinitions {{{1
function jsimports#getDefinitions(importString)
  let tokens = s:TokenizeImportString(a:importString)
  let ast = s:ParseAST(tokens)
  return s:CompileDefinitions(ast)
endfunction

" jsimports#run {{{1
function! jsimports#run(...)
  let tokens = empty(a:000) ? [expand('<cword>')] : a:000
  for token in tokens
    let adjustment = s:AddOrUpdateJavascriptImport(token)
  endfor

  if exists("*JavaScriptImportSort")
    call JavaScriptImportSort()
  endif
endfunction

" jsimports#complete {{{1
function! jsimports#complete(ArgLead, CmdLine, CursorPos)
  return filter(keys(g:vim_javascript_import_definitions), "v:val =~# '^" . a:ArgLead . "'")
endfunction

" vim:sw=2 ts=2 et fdm=marker
