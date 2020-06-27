"Class: XTerminal
"============================

if exists("g:xterminal_loaded")
	finish
endif
let g:xterminal_loaded = 1
XInfo "load XTerminal"

let s:Terminal = {}
let g:XTerminal = s:Terminal


" open new terminal in local or remote
call NOREMAP_nvit("<Leader>k","call g:XTerminal.OpenNewLocalTerminal()<CR>")
call NOREMAP_nvit("<Leader>j","call g:XTerminal.OpenNewRemoteTerminal()<CR>")

"Function: Terminal.SendKeysToCurrentTermBuffer(keys) {{{1
" send keys to buffer as if they were typed by the user
function! s:Terminal.SendKeysToCurrentTermBuffer(keys)
	if !has("nvim")
		XInfo "vim sending keys:".a:keys
		call term_sendkeys('%',a:keys)
	else
		" i is th insert mode
		XInfo "nvim sending keys:".a:keys
		" there are sometimes startinsert not
		" work,for exmaple: swtich from a terminal to another
		"  start insert not work,
		" startinsert
		" call feedkeys("i".a:keys,"n")
		" nvim has bug!!!!
		"    if switch from normal mode, just
		"        call feedkeys(a:keys)  
		"   every thing is fine,the keys are sends verbatim
		"
		"   if switched from insert mode
		"        aho!, the buffer is not modifiable!!
		"   so mode issues must be handled before send keys in nvim
		"
		call feedkeys(a:keys)
	endif
endfunction


" local shell
function! s:Terminal.OpenOrFocusTerminal()
	return self.OpenOrFocusTerminalWithName("bash(local)","J","")
endfunction


"  GetNewBufferName create a buffer with given name
"  if the buffer exists alraedy, append a "+" after it and try again
function! s:Terminal.GetNewBufferName(baseName)
	let name = a:baseName
	while 1
		let termbufNR = bufnr(name)
		if termbufNR==-1
			break
		endif
		let name = name . "+"
	endwhile
	return name
endfunction

function! s:Terminal.OpenNewLocalTerminal()
	return self.OpenOrFocusTerminalWithName(self.GetNewBufferName("bash(local)"),"J","")
endfunction

let s:remoteInitCommand="call g:XTerminal.SendKeysToCurrentTermBuffer('ssh $D;exit;\ncd \"'.getcwd().'\"\n\<C-L>pwd\n')"
" remote shell
" by executing ssh $D ->
function! s:Terminal.OpenOrFocusTerminalRemote()
	" # exit when the remote exit
	" ssh $D;exit 
	" cd getcwd()
	" # clear the screen
	" <C-L>
	" # show working direcotry,give you more contextual info
	" pwd
	"
	" <SID> is replaced before the string is interpreted
	return self.OpenOrFocusTerminalWithName("bash(remote)","L",s:remoteInitCommand)
endfunction

"Function: Terminal.OpenNewRemoteTerminal() {{{1
function! s:Terminal.OpenNewRemoteTerminal()
	return self.OpenOrFocusTerminalWithName(self.GetNewBufferName("bash(remote)"),"L",s:remoteInitCommand)
endfunction


"Function: Terminal.OpenOrFocusTerminalWithName(name,winpos,initCommand) {{{1
" switch between current buffer and last buffer
" when the terminal does not exist, create one,and place it to the bottom
" when the terminal already exists,switch to it
" when the terminal already exists and we are at it,switch to the last window
" - winpos  HJKL, defines where to place the window after creation,empty means
"   does not move
" - initCommand:  the initial command to execute after creation
"
" historical problem: if you enter a terminal from insert mode,the new
" terminal will be in --INSERT-- mode, which should be --TERMINAL--
" so currently we do not support swtich from insert mode
"
function! s:Terminal.OpenOrFocusTerminalWithName(name,winpos,initCommand)
	" bufadd add the give nbuffer,if not exists ,create one,if
	" existed,return previous one
	"
	" term bash --login will have name "!bash --login" in vim if not
	" specified
	let termbufNR = bufnr(a:name)

	XInfo "Switch terminal ".a:name.", bufnr = ".termbufNR

	if termbufNR == -1
		" terminal buffer does not exist, create one,and remeber
		" current window id,and switch to new window
		let startFromInsert = 0
		let startFromTerminal = 0
		let tempWinId = -1
		if !has("nvim")
			" ++curwin = open ,not split ,in cur window
			" ++close when shell exit,close it,not wait for :q
			term ++close bash --login 
		else
			let curMode = mode()
			XInfo "Switch terminal ".a:name.", cur mode = ".curMode
			" 			if curMode ==# 't' || curMode==#'i'
			" 				echoerr "you are about to start a terminal from insert or terminal mode,this is not suorted well now,please start from normal mode"
			" " 				return
			" 			endif
			" create a window,and execute bash --login
			" 			echom "new window"
			" it's important that,we should back into normal mode
			" before we go to a new terminal,otherwise we cannot
			" send key laterly(just needed in nvim)
			" 			if curMode ==# 'i'
			" 				XInfo "start from insert mode"
			" 				let startFromInsert = 1
			" " 				call feedkeys("","n")
			" " 				normal! 
			" 			endif
			" 			if &buftype ==# 'terminal'
			" 				XInfo "start from another terminal"
			" 				let startFromTerminal=1
			" 				" says cannot ?
			" " 				get message:
			" " 				     Can't re-enter normal mode from terminal mode
			" " 				use feedkeys to do this
			" " 				normal! 
			" " 				call feedkeys("")
			" 
			" 				XInfo "start from another terminal end"
			" 			endif

			" 			if startFromInsert || startFromTerminal
			" 				" hard to correct the behavior
			" " 				XInfo "create a temporary window to start"
			" " 				new
			" " 				startinsert
			" " 				stopinsert
			" " 				let tempWinId = win_getid()
			" 			endif
			" "  			if curMode ==# 't' || curMode==#'i'
			" " 				new
			" " 				call termopen("bash --login")
			" " 			else
			split term://bash --login
			" " 			endif
		endif
		" change buffer name
		" 		echom "changing buffer name"
		execute "file ".a:name

		" moves it to the bottom to span horizontal
		" note:
		"     normal! <C-W>J<CR>
		" won't work in terminal mode,we should use :wincmd J
		if exists("a:winpos") && a:winpos !=# ""
			execute "wincmd ".a:winpos
		endif
		if exists("a:initCommand") && a:initCommand !=# ""
			XTrace "Executing initial command for terminal:".a:name." - ".a:initCommand
			execute a:initCommand
		endif
		XTrace "Created Terminal:".a:name
		" 		if startFromInsert
		" 			XTrace "Start from insert,it is now should in INSERT mode,change it to terminal mode"
		" 			" call feedkeys("istartinset")
		" 		end
		" 		if startFromInsert || startFromTerminal
		" 			XTrace "Close temporary window because of start mode is insert or terminal"
		" " 			execute win_id2win(tempWinId)."close"
		" 		endif
	else
		" note that when a terminal buffer exists but is hidden(no
		" window),it is closed already,no way to recover it
		" bufwinid get the firstwinid associated to buf,-1 if none

		let wnr = bufwinnr(termbufNR)
		XTrace "buffer present, winnr = ".wnr
		if wnr == -1
			" buffer {bufname} 
			" open a new window to edit the buffer
			new
			execute "buffer ".a:name
			if &buftype !=# 'terminal'
				echoerr "buffer ".a:name." exists but not a terminal,please colse any possible duplicate"
				return
			endif
		else
			" the terminal window is open,check if it is current
			" window, if it is, switch to last window,otherwise
			" switch to terminal window
			let curWinid = win_getid()
			let winid = win_getid(wnr)
			XTrace "curWinid, targetWinid = ". curWinid. ",".winid
			if curWinid == winid
				" # is the last accessed window
				let wnr = winnr('#')
				" we are about to switch out,so we remember
				" the location we were at
				"
				" 				let save_cursor = getcurpos()
				" 				MoveTheCursorAround
				" 				call setpos('.', save_cursor)
				"
				XTrace "About to switch out terminal ".bufname(.", save curosr")
				let b:saved_cursor = getcurpos()
			else
				XTrace "About to switch back to terminal"
			end
			execute wnr."wincmd w"

			" in nvim, after switch to the terminal,it is in
			" normal mode,not terminal mode,so we need to start
			" insert mode
			if curWinid != winid && has("nvim")
				XTrace "terminal switch back,start insert"
				" in nvim
				startinsert
			endif
		endif
	endif
endfunction


