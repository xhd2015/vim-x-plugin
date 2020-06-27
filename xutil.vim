if exists("g:xutil_loaded")
	finish
endif
let g:xutil_loaded = 1
XInfo "load XUtil"

let s:Util = {}
let g:XUtil = s:Util

" execute a function inside a specified window
" if the windows does not exist
" an error is thrown
" if nr is 0 it means current window
function! s:Util.DoWithinWin(nr,fn)
	if nr < 0 || nr>winnr('$')
		throw "window ".nr." does not exist"
	endif
	let lastID = win_getid(winnr('#'))
	if nr !=0 && nr!=curNR
		let curid = win_getid()
		let curNR = winnr()
		execute nr."wincmd w"
	endif
	call call(fn,nr)
	if nr !=0 && nr!=curNR
		let lastNR = win_id2win(lastID)
		let curNR = win_id2win(curid)
		execute lastNR."wincmd w"
		execute curNR."wincmd w"
	endif
endfunction

" fn - accepts an nr,and returns 1 or 0
" return the first winnr or -1 to indicate not found
function! s:Util.FirstWinWith(fn)
	let cnt = winnr('$')
	let i = 1
	let lastID = win_getid(winnr('#'))
	let curid = win_getid()
	let foundNR = -1
	while  i<=cnt
		execute i."wincmd w"
		if call(fn,i)
			let foundNR=i
			break
		endif
		let i+=1
	endwhile
	let lastNR = win_id2win(lastID)
	let curNR = win_id2win(curid)
	execute lastNR."wincmd w"
	execute curNR."wincmd w"
	return foundNR
endfunction


" do something for each window
function! s:Util.ForeachWin(fn)
	let cnt = winnr('$')
	let i = 1
	let lastID = win_getid(winnr('#'))
	let curid = win_getid()
	while  i<=cnt
		execute i."wincmd w"
		call call(fn,i)
		let i+=1
	endwhile
	let lastNR = win_id2win(lastID)
	let curNR = win_id2win(curid)
	execute lastNR."wincmd w"
	execute curNR."wincmd w"
endfunction
