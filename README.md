# automatch

<i>Some things just match</i>

### Things to know

- It <i>breaks</i> undo, this is intentional, why?
  I would rather have to do extra undos than to retype something.
- Currently vim doesn't like searchpairpos() flags, only tested on 7.4 will need to handle that more gracefully...

### Usage 
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
| Sequence        |    Description                            |
| --------------- | ----------------------------------------- |
|     ()\         | para in front.                            |
|     (\)         | para inside.                              |
|     (\ )        | para space in front (rare case).          |
|     ( \ )       | para just expanded.                       |
|     (   )\      | para just expanded, and in front of.      |
|     (\  )       | para just expanded, and in front of left. |

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

### Global options

| Flag                        | Default                                                                         | Description                                                                                |
| -------------------         | ---------------------------------                                               | ------------------------------------------------------                                     |
| `g:automatch_matchings`     |  `{ "'" : "'"`<br>`, \'"' : '"'`<br>`, \"(" : ")"`<br>`, \"[" : "]"`<br>`, \"{" : "}"}`                       | What to auto match.                                                                        |
| `g:automatch_delimeters`    | [ ',' ]                                                                         | Delimeters use to tab with                                                                 |
| `g:autoMatch_useDefaults`   | 1                                                                               | Use the default mappings currently anything other than 1 is unsupported                    |

### I Don't Like your mappings... Not supported yet :(

##### Todo

- Add some gifs.
- Add vim.help
- Fix tabbing with mulitple delims/paras
- Fix vim issue with searchpairpos()
- Added surroundings for things other than just `<cr>`
