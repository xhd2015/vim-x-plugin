"Class: XComment
"============================

if exists("g:xcomment_loaded")
	finish
endif
let g:xcomment_loaded= 1
XInfo "load XComment"

let s:Comment= {}
let g:XComment= s:Comment


"Autocmd: auto set comment prefix for buffer {{{1
" set comment prefix
augroup XCOMMENT_MAKER
	autocmd!
	autocmd BufEnter *.go,*.c,*.c++,*.java let b:commentPrefix="//"
	autocmd BufEnter *.sh,*.zsh,*.csh,*.rb,*.ruby,.bashrc,.profile,.bash_profile,*.py let b:commentPrefix="#"
	autocmd BufEnter *.vim,.vimrc let b:commentPrefix='"'
augroup END



"Function: Comment.ToggleCommentOperator(type) {{{1
function! s:ToggleCommentOperator(type)
	" do not do this when there is no comment prefix
	if !exists("b:commentPrefix") || len(b:commentPrefix)==0
		return
	endif
	let start = 0
	let end = 0
	" v and V uses '<,'> to mark line
	if a:type ==? 'v'
		" todo visual mode
		let start = line("'<")
		let end= line("'>")
	else
		" VISUAL
		" line or char
		"use '[ and '] to get motion range
		let start = line("'[")
		let end = line("']")
	endif
	let lines = getline(start,end)
	if len(lines)==0
		return
	endif

	" judge should we comment or uncomment based on first line's
	" start
	let commentLen = len(b:commentPrefix)
	let firstline = lines[0]
	let commented = 0
	" startswithA commentPrefix
	if len(firstline) >= commentLen && firstline[0:commentLen-1] ==# b:commentPrefix
		let 	commented = 1
	endif
	if commented
		" must all line be commented to be safely uncommented
		let i = 0
		let size = end - start + 1
		while i < size
			let cur = lines[i]
			if len(cur) < commentLen || cur[0:commentLen-1] !=# b:commentPrefix
				echoerr "line ".(i+start)."  does not start with ".b:commentPrefix.", aka not commented"
				return
			endif
			let i=i+1
		endwhile
		let i=0
		while i < size
			let cur = lines[i][commentLen:]
			if len(cur) > 0 && cur[0] ==# " "
				let cur = cur[1:]
			endif
			call setline(start+i,cur)
			let i=i+1
		endwhile
	else
		" all line can be commented
		let i = 0
		let size = end - start + 1
		while i < size
			call setline(start+i,b:commentPrefix . " " .lines[i])
			let i=i+1
		endwhile
	endif
endfunction

"Commands: <Leader>/ {{{1
" NOTE do not use \<SID>, <SID> is replaced by command,not by string
" Usage:  <Leader>/4j   = comment following 5 lines
"         <Leader>/l    = comment current line
nnoremap <silent> <Leader>/ :set operatorfunc=<SID>ToggleCommentOperator<CR>g@
vnoremap <silent> <Leader>/ :<C-U>call <SID>ToggleCommentOperator(visualmode())<CR>
