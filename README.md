# automatch
https://cyansprite.github.io/automatch/  
<i>Some things just match</i>

## Things to know

- It *'breaks'* undo, this is intentional, why?  
  I would rather have to do extra undos than to retype something.
- Currently vim doesn't like searchpairpos() flags, only tested on 7.4 will need to handle that more gracefully...
- With visual mode V (line-wise) it will insert the surroundings on the first indent level rather than the first        column.

# Usage 

## Normal Mode
Use `<leader>s` to start a surround command, type in a motion, now it will ask what you want to surround, type a match you have in g:automatch_matchings and it will insert, otherwise throw an error message explaining it's not a key in your dictionary.

##### Example
Cursor ==> |     
|word some other words     
`<leader>se(`    
(word)| some other words    

## Visual mode
Same as above... just whatever is highlighted gets surrounded instead of a motion.

##### Example
Cursor ==> |   
|word some other words   
`ve`  
***word***| some other words   
`<leader>s(`   
(word)| some other words   

## Insert Mode
Cursor ==> |

#### Typing a starting para char
|<br>
`(`<br>
(|)

#### Typing space in a para pair
(|)<br>
`<space>`<br>
( | )

#### Typing carriage return in para pair

##### Note, that the spaces made are based on expandtab and shiftwidth, and ( | ), (|) treated the same.
##### Case 1
(|)<br>
`<cr>`<br>
(<br>
  <br>
)<br>
##### Case 2
 (|) stuff<br>
 `<cr>`<br>
 (<br>
   stuff<br>
 )<br>

#### Typing a ending para char
(|)<br>
`)`<br>
()|<br>

#### Backspace handling cursor ==> \ (table issues with git)
| Sequence         |    Description                            |Result |
| ---------------  | ----------------------------------------- |-------|
|     ()\|         | para in front.                            |Deleted|
|     (\|)         | para inside.                              |Deleted|
|     (\| )        | para space in front (rare case).          |Deleted|
|     ( \| )       | para just expanded.                       |(\|)   |
|     (   )\|      | para just expanded, and in front of.      |Deleted|
|     (\|  )       | para just expanded, and in front of left. |Deleted|

##### NOTE: Cases that might seem valid but aren't
- `(  |) `    : This might be user desire to get rid of spacing by hitting
                 right, then <bs>
- `( |)  `    : This might be user desire to get rid of spacing by hitting
                 delete then <bs>
- `(  | )`    : Some weird amount of space, this seems edge case and maybe
                 the user wanted the weird spacing such as in strings
                 
#### Tab handling
##### Note: Space here doesn't really matter.
##### Case 1
(|)<br>
`<tab>`<br>
()|<br>
##### Case 2
(|)<br>
`<s-tab>`<br>
|()<br>
##### Case 3
|()<br>
`<tab>`<br>
(|)<br>
##### Case 4
()|<br>
`<s-tab>`<br>
(|)<br>
##### Case 5
|(some, random, text)<br>
`<tab>`<br>
(some|, random, text)<br>
`<tab>`<br>
(some, random|, text)<br>
`<tab>`<br>
(some, random, text|)<br>
`<tab>`<br>
(some, random, text)|<br>
##### case 6
(some, random, text)|<br>
`<s-tab>`<br>
(some, random, text|)<br>
`<s-tab>`<br>
(some, random|, text)<br>
`<s-tab>`<br>
(some|, random, text)<br>
`<s-tab>`<br>
|(some, random, text)<br>

#### Python Block Comments

|Case |Description       |Result|
|-----|------------------|------|
|\|"" |para behind       |"""\| |
|"\|" |para inside       |"""\| |
|""\| |para front        |"""\| |
|\|"""|para behind       |"""\| |
|"\|""|para inside behind|"""\| |
|""\|"|para inside front |"""\| |
|"""\||para front        |"""\| |

## Global options

| Flag                        | Default Values Listed | Description                                                                                |
| -------------------         | ---------------------------------                                               | ------------------------------------------------------                                     |
| `g:automatch_matchings`     |  `{ "'" : "'",`<br> `\'"' : '"'`,<br> `\"(" : ")",` <br>`\"[" : "]"`, <br>`\"{" : "}"}`                       | What to auto match.                                                                        |
| `g:automatch_delimeters`    | [ ',' ]                                                                         | Delimeters use to tab with                                                                 |
| `g:autoMatch_useDefaults`   | 1                                                                               | Use the default mappings                    |

## I Don't Like your mappings.
No prob, map these :) after setting g:autoMatch_useDefaults to 0, or optionally map over the ones you don't like, keep the ones you do.
```vim
if g:autoMatch_useDefaults
    imap <silent> <space> <Plug>(automatch-space)
    imap <silent> <bs> <Plug>(automatch-back)
    imap <silent> <cr> <Plug>(automatch-carriage)
    imap <silent> <tab> <Plug>(automatch-tab)
    imap <silent> <s-tab> <Plug>(automatch-stab)
    nmap <silent> <leader>s <Plug>(automatch-surround-normal)
    vmap <silent> <leader>s <Plug>(automatch-surround-visual)
endif
```

##### Todo

- Add some gifs.
- Add vim.help
- Fix tabbing with mulitple delims/paras
- Fix vim issue with searchpairpos()
- Added surroundings for things other than just `<cr>`
- Consider more `IDE` like features such as for some filetypes (java comes to mind)  
  "|"  
  `<cr>`  
  +"|"
