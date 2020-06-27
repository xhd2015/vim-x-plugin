"CLASS: Layout
"============================================================
if exists("g:xlayout_loaded")
	finish
endif
let g:xlayout_loaded = 1
XInfo "load XLayout"

let s:Layout= {}
let g:XLayout= s:Layout

" LayoutSet {{{1
let s:LayoutSet = {
\     "file":{
\         "boundary":35,
\ 	"min":30,
\ 	"max":60,
\ 	"type":"width"
\     },
\     "explorer":{
\         "boundary":35,
\ 	"min":30,
\ 	"max":60,
\ 	"type":"width"
\     },
\     "main":{
\         "boundary":110,
\ 	"min":105,
\ 	"max":150,
\ 	"type":"width"
\     },
\     "preview":{
\         "boundary":40,
\ 	"min":35,
\ 	"max":100,
\ 	"type":"width"
\     },
\     "quickfix":{
\         "boundary":20,
\ 	"min":15,
\ 	"max":40,
\ 	"type":"height"
\     },
\     "local":{
\         "boundary":15,
\ 	"min":10,
\ 	"max":40,
\ 	"type":"height"
\     },
\     "remote":{
\         "boundary":20,
\ 	"min":10,
\ 	"max":40,
\ 	"type":"width"
\     }
\ }
let s:Layout["LayoutSet"] = s:LayoutSet
"FUNCTION: Layout.zoomToggle(option) {{{1
" -option a map of property:
"      bundary
"      min
"      max
"      type -> heigth,or width
function! s:Layout.zoomToggle(option)
	let oldValue = a:option.type ==#'height' ? winheight(0) : winwidth(0)
	if oldValue >= a:option.boundary
		let newValue = a:option.min
	else
		let newValue = a:option.max
	endif
	if a:option.type ==# 'height'
		execute "resize ".newValue
	else
		execute "vertical resize ".newValue
	endif
endfunction
" get role of window
" the quickfix has a buftype="quickfix" and filetype="qf", we always use
" buftype
function! s:Layout.GetWinRole()
	if exists("w:role")
		" respect the role option,possible:main,explorer,todo
		return w:role
	elseif &buftype==#'terminal'
		if bufname() ==# 'bash(local)'
			return "local"
		elseif bufname() ==# 'bash(remote)'
			return "remote"
		endif
	elseif exists("b:NERDTree")
			return "file"
	elseif &previewwindow
		return "preview"
	elseif &buftype ==# 'quickfix'
		return "quickfix"
	endif
	return ""
endfunction
function! s:Layout.Zoom()
	let layoutSet = s:LayoutSet
	let role = self.GetWinRole()
	if !has_key(layoutSet,role)
		return
	endif
	let option = layoutSet[role]
	call self.zoomToggle(option)
endfunction

" normal window operation
" switch to nr and enter normal mode
function! s:Layout.SwitchToWindowNormal(windowNR)
	if a:windowNR==-1
		return
	endif
	" note that <C-W> does not get evaluated automatically
	" execute "normal! " . a:windowNR."\<C-W>\<C-W>"
	" should replace normal! with wincmd, because in terminal mode 
	" normal! cannot be used
	execute a:windowNR."wincmd w"
	if has("nvim") && &buftype!=#'terminal'
		stopinsert
	endif
endfunction
function! s:Layout.SwitchQuickFix()
	let curid = win_getid()
	let qfNR = self.GetOrCreateWindow("quickfix",1)
	let qfID = win_getid(qfNR)
	if curid == qfID
		XTrace "quickfix switch out"
		" switch out
		wincmd p
	else
		XTrace "quickfix switch back"
		" switch back
		execute qfNR."wincmd w"
	endif
endfunction

"FUNCTION: Layout.SwitchFileOrCmd(name,cmd) {{{1
" switch to a specific file or open it
function! s:Layout.SwitchFileOrCmd(name,cmd)
	" find a name with vimrc_edit
	" if not found use vsplit to open one
	let exName = expand(a:name)
	let targetNR = -1
	let prevID = win_getid(winnr('#'))
	let lastID = win_getid()
	let winNum= winnr('$')
	let i = 1
	while i<=winNum
		if bufname() ==# exName || bufname() ==# a:name
			let targetNR=winnr() 
			break
		endif
		let i=i+1
	endwhile
	if targetNR == -1
		execute a:cmd 
		if has("nvim") && &buftype!=#'terminal'
			" 		if has("nvim") 
			stopinsert
		endif
		" jump in between to set last window
		let lastNR = win_id2win(lastID)
		execute lastNR."wincmd w"
		execute "wincmd p"
	else
		if targetNR == winnr()
			XTrace "switch out"
			" current nr is the target,so we switch back
			call win_gotoid(prevID)
		else
			execute targetNR."wincmd w"
			" tricky: nvim opens this in insert mode,which is not
			" expected
			if has("nvim") && &buftype!=#'terminal'
				stopinsert
			endif
		endif
	endif
endfunction

"FUNCTION: Layout.GetOrCreateWindow() {{{1
" get different window nr, create specify whether to create one if not exist
function! s:Layout.GetOrCreateWindow(role,create)
	let role = a:role
	let nr = -1
	let lastwinid = win_getid(winnr('#'))
	let curwinid = win_getid(winnr())
	if role==#'preview'
		let winNum= winnr('$')
		let i = 1
		while i<=winNum
			execute i."wincmd w"
			if &previewwindow
				let nr=winnr() 
				break
			endif
			let i=i+1
		endwhile
		if nr==-1 && a:create
			" rel
			let refNR = self.GetOrCreateWindow("main",0)
			if refNR == -1
				let refNR = self.GetOrCreateWindow("file",0)
			endif
			let wincnt = winnr("$")
			if refNR!=-1
				call self.SwitchToWindowNormal(refNR)
			elseif wincnt>0
				call self.SwitchToWindowNormal(1)
			endif
			" vnew create a new window vertically,at left
			vnew	
			if wincnt>0
				" switch position, cursor at left
				wincmd x
				" switch to new window
				wincmd w
			endif
			" set previewwindow option
			set previewwindow
			" set width=40
			vertical resize 40
			let nr=winnr()
		endif
	elseif role==#'quickfix'
		" get the last one with qf
		let winNum= winnr('$')
		let i = 1
		while i<=winNum
			execute i."wincmd w"
			if &filetype==#'qf'
				let nr=winnr() 
				break
			endif
			let i=i+1
		endwhile
		if nr==-1 && a:create
			" should at top of terminal
			" by default copen opens the quickfix window at
			" bottom,just beneath the local terminal,so we can
			" adjust this
			copen
			let upNR = winnr('k')
			let nr = winnr()
			" if  no up window, 'k' returns current window
			if upNR!=-1 && nr!=upNR
				" go to up window,and execute an exchange
				wincmd k
				wincmd x
				let nr = winnr()
			endif
			" this vertical resisze takes effective for all same
			" column windows
			" 			vertical resize 40
		endif
	elseif role==#'file'
		let winNum= winnr('$')
		let i = 1
		while i<=winNum
			execute i."wincmd w"
			if &filetype==#'nerdtree'
				let nr=winnr() 
				break
			endif
			let i=i+1
		endwhile
		if nr==-1 && create
			NERDTreeFocus
			" set width=30
			vertical resize 30
			let nr = winnr()
		endif
	elseif role==#'local'
		let nr = bufwinnr(bufnr("bash(local)"))
		if nr==-1 && a:create
			call g:XTerminal.OpenOrFocusTerminal()
			" set heigth=10
			resize  10
			let nr = winnr()
		endif
	elseif role==#'remote'
		let nr = bufwinnr(bufnr("bash(remote)"))
		if nr==-1 && a:create
			let localOldHeight = winheight(bufwinnr(bufnr("bash(local)")))
			call g:XTerminal.OpenOrFocusTerminalRemote()
			" set width=40
			vertical resize  40
			" the remote had impact on the local terminal heigth,let's fix
			let localNR= bufwinnr(bufnr("bash(local)"))
			let newHeigth = winheight(localNR)
			if localOldHeight>0 && newHeigth!=localOldHeight
				XTrace "remote changed local height,localNR,oldHeight = ".localNR." ".localOldHeight
				" must use feedkeys as there were commands to
				" be executed on remote terminal
				" n -> noremap
				" t -> as if typed
				"   lastNR, curNR  keep history
				"   wincmd w jump to local terminal
				"   resize
				"   wincmd
				"   wincmd   keep history
				call feedkeys("\<C-\>\<C-N>:let lastNR=winnr('#')|let curNR=winnr()|".localNR."wincmd w|resize ".localOldHeight."|execute lastNR.'wincmd w'|execute curNR.'wincmd w'\<CR>","nt")
"  				execute localNR."wincmd w"
"  				resize localOldHeight
			endif
			" it
			let nr = winnr()
		endif
	elseif role==#'main'
		" the first window many be the first unnamed j
		let winNum= winnr('$')
		let i = 1
		let unnamedNR = -1
		while i<=winNum
			execute i."wincmd w"
			if  exists("w:role") && w:role==#'main' 
				let nr=winnr() 
				break
			endif
			if unnamedNR==-1 && bufname()==#''
				let unnamedNR = i
			endif
			let i=i+1
		endwhile
		if nr==-1 && unnamedNR!=-1
			execute unnamedNR."wincmd w"
			let w:role = 'main'
			let nr = unnamedNR
		endif
		if nr==-1 && a:create
			" rel
			let refNR = self.GetOrCreateWindow("file",0)
			let wincnt = winnr("$")
			if refNR!=-1
				call self.SwitchToWindowNormal(refNR)
			elseif wincnt>0
				call self.SwitchToWindowNormal(1)
			endif
			" vnew create a new window vertically,at left
			vnew	
			if wincnt>0
				" switch position, cursor at left
				wincmd x
				" switch to new window
				wincmd w
			endif
			" set width=105
			vertical resize 105
			let w:role = 'main'
			let nr=winnr()
		endif
	elseif role==#'explorer'
		" the first window with b:NERDTree exists and w:role=explorer
		let winNum= winnr('$')
		let i = 1
		while i<=winNum
			execute i."wincmd w"
			if  exists("b:NERDTree") && exists("w:role") && w:role==#'explorer' 
				let nr=winnr() 
				break
			endif
			let i=i+1
		endwhile
		if  nr==-1 && a:create
			" rel
			let refNR = self.GetOrCreateWindow("file",0)
			let wincnt = winnr("$")
			if refNR!=-1
				call self.SwitchToWindowNormal(refNR)
			elseif wincnt>0
				call self.SwitchToWindowNormal(1)
			endif
			" new create a new window up
			new	
			if wincnt>0
				" switch position, cursor at left
				wincmd x
				" switch to new window
				wincmd w
			endif
			" create a new explorer here
			call g:NERDTreeCreator.CreateWindowTree(".")
			" set width=105
			let w:role = 'explorer'
			let nr=winnr()
		endif
	endif
	" keep window history
	let lastwin = win_id2win(lastwinid)
	let curnr = win_id2win(curwinid)
	call self.SwitchToWindowNormal(lastwin)
	call self.SwitchToWindowNormal(curnr)
	return nr
endfunction

"FUNCTION: Layout.SwitchBetweenNerdtree() {{{1
function! s:Layout.SwitchBetweenNerdtree()
	XTrace "switch between nerdtree"
	" check if current window is nerdtree
	if &filetype ==? 'nerdtree'
		XTrace "switch between nerdtree: out"
		" jump to previous window
		wincmd p
	else
		XTrace "switch between nerdtree: in"
		NERDTreeFocus
		" 2 wincmd p triggers the BufEnter
		wincmd p
		wincmd p
	endif
endfunction
function!  s:Layout.SwitchBetweenPreview()
	" check if current window is previewwindow
	if &previewwindow
		" jump to previous window
		wincmd p
	else
		" try to jump to Preview window
		" prohibit error if no Preview window
		" if not successful just do nothing
		silent! wincmd P
	endif
endfunction


"Function: OpenWindowForNameSettingMain(file) {{{1
" open window for a file, first try a named match
" then the main window
" the an unamed window  , will set main role
" the a new window,      will set main role
"
function! s:Layout.OpenWindowForNameSettingMain(file)
	call self.OpenWindowForNameSettingRole(a:file,"main")
endfunction
function! s:Layout.OpenWindowForNameSettingPreview(file)
	call self.OpenWindowForNameSettingRole(a:file,"preview")
endfunction
" the only supported role is "main" "preview", "todo" "quickfix"
function! s:Layout.OpenWindowForNameSettingRole(file,role)
	let cnt=winnr('$')
	let prevNR = winnr('#')
	let lastNR = winnr()
	let exEdit = expand(a:file)
	let targetNR = -1
	let unnamedNR = -1
	let roleNR = -1
	let nameMatch = 0
	let i=1
	while i<=cnt
		execute i."wincmd w"
		if bufname() ==# exEdit || bufname() ==# a:file
			let targetNR=i
			let nameMatch=1
			break
		endif
		if unnamedNR==-1 && bufname() ==# '' 
			let unnamedNR = i
		endif
		if roleNR == -1 && self.GetWinRole() ==# a:role
			let roleNR = i
		endif
		let i=i+1
	endwhile
	" recover the previous status
	execute lastNR."wincmd w"

	"priority targetNR -> roleNR -> unnamedNR
	if targetNR==-1
		let targetNR = roleNR
	endif
	if targetNR==-1
		let targetNR = unnamedNR
	endif

	" edited means if a new file is open
	if targetNR==-1
		XTrace "window for ".a:role."does not exist,create one"
		let targetNR = self.GetOrCreateWindow(a:role,1)
		execute targetNR."wincmd w"
		execute "edit ".a:file
		if has("nvim") | stopinsert | endif
	else
		if targetNR == lastNR 
			if nameMatch
				XTrace "current file in ".a:role." now,switch out"
				execute prevNR."wincmd w"
			else
				XTrace "current file not load,edit it in ".a:role
				execute "edit ".a:file
				if has("nvim") | stopinsert | endif
			endif
		else
			XTrace "another window can be used to edit this file,switch to it"
			execute targetNR."wincmd  w"
			if !nameMatch
				XTrace "name not match,edit it in "
				execute "edit ".a:file
				if has("nvim") | stopinsert | endif
			endif
		endif
		" if the unnamedNR is used to edit the file,meaning the roleNR
		" is empty,so we can set one
		if targetNR == unnamedNR 
			if a:role==#'main' || a:role==#'todo'
				let w:role=a:role
			elseif a:role==#'preview'
				set previewwindow
			endif
		endif
	endif
endfunction


"Function: Layout.OpenFromNerdTo(role) {{{1
" open file from directory,typically by typing <Space>
" if path is a directory,keep the cursor
" otherwise open the file 
" - role: main or preview
function! s:Layout.OpenFromNerdTo(role)
	XTrace "open from nerde to".a:role
	if !exists("b:NERDTree")
		echoerr "not in a NERDTree exploerer"
		return
	endif
	let path = b:NERDTree.ui.getPath(line('.'))
	let pathStr = path.str()
	" mapped from space
	" nerdDirEnterCommand defines what to do when Space is pressed on a directory
	if isdirectory(pathStr) 
		XTrace "trigger on dir, execute a normal choose"
		" behave just if we have clicked enter
		call nerdtree#ui_glue#invokeKeyMap("<CR>")
		"call nerdtree#ui_glue#invokeKeyMap("<C-j>")
		return
	endif
	call self.OpenWindowForNameSettingRole(pathStr,a:role)
endfunction

"FUNCTION: Layout.OpenIn() {{{1
" open file in role (main,preview,peek)
" - dirCmd   if pathStr is a directory,how to handle it
function! s:Layout.OpenIn(role,pathStr,dirCmd)
	if a:role==#'explorer'
		let dir=a:pathStr
		if !isdirectory(dir)
			" head part of name
			let dir=fnamemodify(dir,":h")
		endif
		let roleNR = self.GetOrCreateWindow(a:role,1)
		execute roleNR."wincmd w"
		if !exists("b:NERDTree")
			echoerr "Error: opened explorer is not a NERDTree"
			return
		endif
		let pathNode = g:NERDTreePath.New(dir)
		let newNode=g:NERDTreeDirNode.New(pathNode,b:NERDTree)
		call b:NERDTree.changeRoot(newNode)
		return

	endif
	" directory does not do anything
	if isdirectory(a:pathStr)
		if a:dirCmd!=#""
			execute a:dirCmd
		endif
		return
	endif
" 	if !filereadable(a:pathStr)
" 		" by default if file does not exist, just open a window for it
" 		echoerr "file does not exist:".a:pathStr
" 		return
" 	endif

	let role=a:role
	if role!=#"main" && role!=#"preview" && role!=#"peek" 
		echoerr "role must be main,preview,peek or explorer"
		return
	endif
	call self.SwitchFileOrCmd(a:pathStr,"let roleNR = self.GetOrCreateWindow(\"".a:role."\",1)|execute roleNR.\"wincmd w\"|edit ".a:pathStr)
endfunction
" open file in role (main,preview,peek)
function! s:Layout.NERDOpenIn(role,dirCmd)
	if !exists("b:NERDTree")
		echoerr "not in a NERDTree exploerer"
		return
	endif
	let path = b:NERDTree.ui.getPath(line('.'))
	let pathStr = path.str()
	call self.OpenIn(a:role,pathStr,a:dirCmd)
endfunction


" Function: Layout.ShowQuickFixErrors(type) {{{1
function! s:Layout.ShowQuickFixErrors(type)
	let start = 0
	let end = 0
	if a:type ==? 'v'
		" todo visual mode
		let start = line("'<")
		let end= line("'>")
	else
		" line or char
		"use '[ and '] to get motion range
		let start = line("'[")
		let end = line("']")
	endif
	let lines = getline(start,end)
	if len(lines)==0
		return
	endif
	" cexpr would jump to the first error
	" when current buffer is not modifiable it will be an error
	" so here we open a new window for it
	vsplit
	cexpr lines
	call s:SwitchQuickFix()
	wincmd p
endfunction
"Commands: <Leader>z = zoom{{{1
" define a main command, like edit, open file in main
command! -nargs=1 -complete=file -bar Main call g:XLayout.OpenWindowForNameSettingMain(<q-args>)
command! -nargs=1 -complete=file -bar Preview call g:XLayout.OpenIn("preview",<q-args>,"")
" simply Explorer and E are the same 
command! -nargs=1 -complete=file -bar Explorer call g:XLayout.OpenIn("explorer",<q-args>,"")
command! -nargs=1 -complete=file -bar E call g:XLayout.OpenIn("explorer",<q-args>,"")
" LSend  send keys to local
" RSend  send keys to remote
" TSend  send keys to terminal
command! -nargs=0 -bar Quickfix call g:XLayout.SwitchQuickFix()
command! -bar Zoom call g:XLayout.Zoom()
call NOREMAP_nvit("<Leader>z","call g:XLayout.Zoom()<CR>")
call NOREMAP_nvt("pp", "call g:XLayout.SwitchBetweenPreview()<CR>")
" call NOREMAP_nvit("wf", "call g:XLayout.SwitchBetweenNerdtree()<CR>")
call NOREMAP_nvit("wf", "call g:XLayout.SwitchBetweenNerdtree()<CR>")
call NOREMAP_nvt("<Leader>q","call g:XLayout.SwitchQuickFix()<CR>")
"=======================QUICKFIX WINDOW=====================
"  used to select errors and show in quickfix
nnoremap <silent> <Leader>f :set operatorfunc=g:XLayout.ShowQuickFixErrors<CR>g@
vnoremap <silent> <Leader>f :<C-U>call g:XLayout.ShowQuickFixErrors(visualmode())<CR>


"NERDSetup:autocmds {{{1
" nnoremap <C-g> :NERDTreeToggle<CR>
" nnoremap <C-g> :NERDTreeFocus<CR>
"    file manager
" nnoremap <Leader>m :NERDTreeFocus<CR>

" " open NERDTree at startup
" " prevent toggle nerdtree when sourcing this file again
" function! s:ensureNerdTreeOpen()
" 	if exists("t:myNerdIsOpen") && t:myNerdIsOpen
" 		return
" 	endif
" 	let t:myNerdIsOpen = 1
" 	echo "yes"
" 	 NERDTreeToggle
" 	 " NERDTreeFocus
" endfunction

" augroup VIM_ENTERED
" 	autocmd!
" 	autocmd VimEnter * ++once :call <SID>ensureNerdTreeOpen()<CR>
" augroup END
" 
" call s:ensureNerdTreeOpen()

" close vim if NERDTree is the only window
" nerdDirEnterCommand defines what to do when Space is pressed on a directory
" bydefault and <CR> is enough, but in practice we find that the cursor moves
" ahead, so we get it back by h
function! s:CheckIfOnlyOneEmptyExistsAfterLeave()
" 	let cnt = winnr('$')
" 	if cnt!=2
" 		return
" 	endif
" 	wincmd w
" 	let name=bufname()
" 
" 	if name==#''
" 		close
" 	else
" 		wincmd p
" 	endif
endfunction
" set bufferlocal map for quickfix & NERDTree
augroup XLAYOUT_MAPPINGS
	autocmd!
" 	autocmd BufNew  *  if exists("b:NERDTree") | call s:logtrace("NERDTree BufNew")|endif
" 	autocmd BufNewFile  *  if exists("b:NERDTree") | call s:logtrace("NERDTree BufNewFile")|endif
" 	autocmd BufReadPre *  if exists("b:NERDTree") | call s:logtrace("NERDTree BufReadPre")|endif
" 	autocmd BufFilePost *  if exists("b:NERDTree") | call s:logtrace("NERDTree BufFilePost")|endif
" 	the only left window is NERDTree or an empty name
"	autocmd BufLeave * call s:logtrace("BufLeave winnr=".winnr('$')) | call <SID>CheckIfOnlyOneEmptyExistsAfterLeave()
        autocmd BufEnter * if &buftype==#'quickfix' | nmap <buffer> <silent> <Space> <CR> | endif
	autocmd BufEnter * if (winnr("$") == 1) &&  (exists("b:NERDTree") && b:NERDTree.isTabTree()) | q | endif
	autocmd BufEnter * if !exists("b:nerdTreeMapped") && exists("b:NERDTree") | let b:nerdTreeMapped=1|execute 'XInfo "NERDTree Mapping for buffer"'|nnoremap <buffer> <silent> <Space> :call g:XLayout.OpenFromNerdTo("main")<CR>|nnoremap <buffer> <silent> p :call g:XLayout.OpenFromNerdTo("preview")<CR>| nnoremap <buffer> <silent> pp :call nerdtree#ui_glue#invokeKeyMap("p")<CR> | endif
augroup END

