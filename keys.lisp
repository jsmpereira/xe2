;;; keys.lisp --- key symbols for sdl/xe2

;; Copyright (C) 2010  David O'Toole

;; Author: David O'Toole <dto1138@gmail.com>
;; Keywords: 

;; This program is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation, either version 3 of the License, or
;; (at your option) any later version.

;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with this program.  If not, see <http://www.gnu.org/licenses/>.

(in-package :xe2)

(defparameter *key-identifiers*
  '((UNKNOWN 0)
  (:FIRST 0)
  (:BACKSPACE 8)
  (:TAB 9)
  (:CLEAR 12)
  (:RETURN 13)
  (:PAUSE 19)
  (:ESCAPE 27)
  (:SPACE 32)
  (:EXCLAIM 33)
  (:QUOTEDBL 34)
  (:HASH 35)
  (:DOLLAR 36)
  (:AMPERSAND 38)
  (:QUOTE 39)
  (:LEFTPAREN 40)
  (:RIGHTPAREN 41)
  (:ASTERISK 42)
  (:PLUS 43)
  (:COMMA 44)
  (:MINUS 45)
  (:PERIOD 46)
  (:SLASH 47)
  (:0 48)
  (:1 49)
  (:2 50)
  (:3 51)
  (:4 52)
  (:5 53)
  (:6 54)
  (:7 55)
  (:8 56)
  (:9 57)
  (:COLON 58)
  (:SEMICOLON 59)
  (:LESS 60)
  (:EQUALS 61)
  (:GREATER 62)
  (:QUESTION 63)
  (:AT 64)
  (:LEFTBRACKET 91)
  (:BACKSLASH 92)
  (:RIGHTBRACKET 93)
  (:CARET 94)
  (:UNDERSCORE 95)
  (:BACKQUOTE 96)
  (:a 97)
  (:b 98)
  (:c 99)
  (:d 100)
  (:e 101)
  (:f 102)
  (:g 103)
  (:h 104)
  (:i 105)
  (:j 106)
  (:k 107)
  (:l 108)
  (:m 109)
  (:n 110)
  (:o 111)
  (:p 112)
  (:q 113)
  (:r 114)
  (:s 115)
  (:t 116)
  (:u 117)
  (:v 118)
  (:w 119)
  (:x 120)
  (:y 121)
  (:z 122)
  (:DELETE 127)
  (:WORLD-0 160)
  (:WORLD-1 161)
  (:WORLD-2 162)
  (:WORLD-3 163)
  (:WORLD-4 164)
  (:WORLD-5 165)
  (:WORLD-6 166)
  (:WORLD-7 167)
  (:WORLD-8 168)
  (:WORLD-9 169)
  (:WORLD-10 170)
  (:WORLD-11 171)
  (:WORLD-12 172)
  (:WORLD-13 173)
  (:WORLD-14 174)
  (:WORLD-15 175)
  (:WORLD-16 176)
  (:WORLD-17 177)
  (:WORLD-18 178)
  (:WORLD-19 179)
  (:WORLD-20 180)
  (:WORLD-21 181)
  (:WORLD-22 182)
  (:WORLD-23 183)
  (:WORLD-24 184)
  (:WORLD-25 185)
  (:WORLD-26 186)
  (:WORLD-27 187)
  (:WORLD-28 188)
  (:WORLD-29 189)
  (:WORLD-30 190)
  (:WORLD-31 191)
  (:WORLD-32 192)
  (:WORLD-33 193)
  (:WORLD-34 194)
  (:WORLD-35 195)
  (:WORLD-36 196)
  (:WORLD-37 197)
  (:WORLD-38 198)
  (:WORLD-39 199)
  (:WORLD-40 200)
  (:WORLD-41 201)
  (:WORLD-42 202)
  (:WORLD-43 203)
  (:WORLD-44 204)
  (:WORLD-45 205)
  (:WORLD-46 206)
  (:WORLD-47 207)
  (:WORLD-48 208)
  (:WORLD-49 209)
  (:WORLD-50 210)
  (:WORLD-51 211)
  (:WORLD-52 212)
  (:WORLD-53 213)
  (:WORLD-54 214)
  (:WORLD-55 215)
  (:WORLD-56 216)
  (:WORLD-57 217)
  (:WORLD-58 218)
  (:WORLD-59 219)
  (:WORLD-60 220)
  (:WORLD-61 221)
  (:WORLD-62 222)
  (:WORLD-63 223)
  (:WORLD-64 224)
  (:WORLD-65 225)
  (:WORLD-66 226)
  (:WORLD-67 227)
  (:WORLD-68 228)
  (:WORLD-69 229)
  (:WORLD-70 230)
  (:WORLD-71 231)
  (:WORLD-72 232)
  (:WORLD-73 233)
  (:WORLD-74 234)
  (:WORLD-75 235)
  (:WORLD-76 236)
  (:WORLD-77 237)
  (:WORLD-78 238)
  (:WORLD-79 239)
  (:WORLD-80 240)
  (:WORLD-81 241)
  (:WORLD-82 242)
  (:WORLD-83 243)
  (:WORLD-84 244)
  (:WORLD-85 245)
  (:WORLD-86 246)
  (:WORLD-87 247)
  (:WORLD-88 248)
  (:WORLD-89 249)
  (:WORLD-90 250)
  (:WORLD-91 251)
  (:WORLD-92 252)
  (:WORLD-93 253)
  (:WORLD-94 254)
  (:WORLD-95 255)
  (:KP0 256)
  (:KP1 257)
  (:KP2 258)
  (:KP3 259)
  (:KP4 260)
  (:KP5 261)
  (:KP6 262)
  (:KP7 263)
  (:KP8 264)
  (:KP9 265)
  (:KP-PERIOD 266)
  (:KP-DIVIDE 267)
  (:KP-MULTIPLY 268)
  (:KP-MINUS 269)
  (:KP-PLUS 270)
  (:KP-ENTER 271)
  (:KP-EQUALS 272)
  (:UP 273)
  (:DOWN 274)
  (:RIGHT 275)
  (:LEFT 276)
  (:INSERT 277)
  (:HOME 278)
  (:END 279)
  (:PAGEUP 280)
  (:PAGEDOWN 281)
  (:F1 282)
  (:F2 283)
  (:F3 284)
  (:F4 285)
  (:F5 286)
  (:F6 287)
  (:F7 288)
  (:F8 289)
  (:F9 290)
  (:F10 291)
  (:F11 292)
  (:F12 293)
  (:F13 294)
  (:F14 295)
  (:F15 296)
  (:NUMLOCK 300)
  (:CAPSLOCK 301)
  (:SCROLLOCK 302)
  (:RSHIFT 303)
  (:LSHIFT 304)
  (:RCTRL 305)
  (:LCTRL 306)
  (:RALT 307)
  (:LALT 308)
  (:RMETA 309)
  (:LMETA 310)
  (:LSUPER 311)
  (:RSUPER 312)
  (:MODE 313)
  (:COMPOSE 314)
  (:HELP 315)
  (:PRINT 316)
  (:SYSREQ 317)
  (:BREAK 318)
  (:MENU 319)
  (:POWER 320)
  (:EURO 321)
  (:UNDO 322)))

(defparameter *sdl-key-identifiers*
  '((:SDL-KEY-FIRST 0)
  (:SDL-KEY-BACKSPACE 8)
  (:SDL-KEY-TAB 9)
  (:SDL-KEY-CLEAR 12)
  (:SDL-KEY-RETURN 13)
  (:SDL-KEY-PAUSE 19)
  (:SDL-KEY-ESCAPE 27)
  (:SDL-KEY-SPACE 32)
  (:SDL-KEY-EXCLAIM 33)
  (:SDL-KEY-QUOTEDBL 34)
  (:SDL-KEY-HASH 35)
  (:SDL-KEY-DOLLAR 36)
  (:SDL-KEY-AMPERSAND 38)
  (:SDL-KEY-QUOTE 39)
  (:SDL-KEY-LEFTPAREN 40)
  (:SDL-KEY-RIGHTPAREN 41)
  (:SDL-KEY-ASTERISK 42)
  (:SDL-KEY-PLUS 43)
  (:SDL-KEY-COMMA 44)
  (:SDL-KEY-MINUS 45)
  (:SDL-KEY-PERIOD 46)
  (:SDL-KEY-SLASH 47)
  (:SDL-KEY-0 48)
  (:SDL-KEY-1 49)
  (:SDL-KEY-2 50)
  (:SDL-KEY-3 51)
  (:SDL-KEY-4 52)
  (:SDL-KEY-5 53)
  (:SDL-KEY-6 54)
  (:SDL-KEY-7 55)
  (:SDL-KEY-8 56)
  (:SDL-KEY-9 57)
  (:SDL-KEY-COLON 58)
  (:SDL-KEY-SEMICOLON 59)
  (:SDL-KEY-LESS 60)
  (:SDL-KEY-EQUALS 61)
  (:SDL-KEY-GREATER 62)
  (:SDL-KEY-QUESTION 63)
  (:SDL-KEY-AT 64)
  (:SDL-KEY-LEFTBRACKET 91)
  (:SDL-KEY-BACKSLASH 92)
  (:SDL-KEY-RIGHTBRACKET 93)
  (:SDL-KEY-CARET 94)
  (:SDL-KEY-UNDERSCORE 95)
  (:SDL-KEY-BACKQUOTE 96)
  (:SDL-KEY-a 97)
  (:SDL-KEY-b 98)
  (:SDL-KEY-c 99)
  (:SDL-KEY-d 100)
  (:SDL-KEY-e 101)
  (:SDL-KEY-f 102)
  (:SDL-KEY-g 103)
  (:SDL-KEY-h 104)
  (:SDL-KEY-i 105)
  (:SDL-KEY-j 106)
  (:SDL-KEY-k 107)
  (:SDL-KEY-l 108)
  (:SDL-KEY-m 109)
  (:SDL-KEY-n 110)
  (:SDL-KEY-o 111)
  (:SDL-KEY-p 112)
  (:SDL-KEY-q 113)
  (:SDL-KEY-r 114)
  (:SDL-KEY-s 115)
  (:SDL-KEY-t 116)
  (:SDL-KEY-u 117)
  (:SDL-KEY-v 118)
  (:SDL-KEY-w 119)
  (:SDL-KEY-x 120)
  (:SDL-KEY-y 121)
  (:SDL-KEY-z 122)
  (:SDL-KEY-DELETE 127)
  (:SDL-KEY-WORLD-0 160)
  (:SDL-KEY-WORLD-1 161)
  (:SDL-KEY-WORLD-2 162)
  (:SDL-KEY-WORLD-3 163)
  (:SDL-KEY-WORLD-4 164)
  (:SDL-KEY-WORLD-5 165)
  (:SDL-KEY-WORLD-6 166)
  (:SDL-KEY-WORLD-7 167)
  (:SDL-KEY-WORLD-8 168)
  (:SDL-KEY-WORLD-9 169)
  (:SDL-KEY-WORLD-10 170)
  (:SDL-KEY-WORLD-11 171)
  (:SDL-KEY-WORLD-12 172)
  (:SDL-KEY-WORLD-13 173)
  (:SDL-KEY-WORLD-14 174)
  (:SDL-KEY-WORLD-15 175)
  (:SDL-KEY-WORLD-16 176)
  (:SDL-KEY-WORLD-17 177)
  (:SDL-KEY-WORLD-18 178)
  (:SDL-KEY-WORLD-19 179)
  (:SDL-KEY-WORLD-20 180)
  (:SDL-KEY-WORLD-21 181)
  (:SDL-KEY-WORLD-22 182)
  (:SDL-KEY-WORLD-23 183)
  (:SDL-KEY-WORLD-24 184)
  (:SDL-KEY-WORLD-25 185)
  (:SDL-KEY-WORLD-26 186)
  (:SDL-KEY-WORLD-27 187)
  (:SDL-KEY-WORLD-28 188)
  (:SDL-KEY-WORLD-29 189)
  (:SDL-KEY-WORLD-30 190)
  (:SDL-KEY-WORLD-31 191)
  (:SDL-KEY-WORLD-32 192)
  (:SDL-KEY-WORLD-33 193)
  (:SDL-KEY-WORLD-34 194)
  (:SDL-KEY-WORLD-35 195)
  (:SDL-KEY-WORLD-36 196)
  (:SDL-KEY-WORLD-37 197)
  (:SDL-KEY-WORLD-38 198)
  (:SDL-KEY-WORLD-39 199)
  (:SDL-KEY-WORLD-40 200)
  (:SDL-KEY-WORLD-41 201)
  (:SDL-KEY-WORLD-42 202)
  (:SDL-KEY-WORLD-43 203)
  (:SDL-KEY-WORLD-44 204)
  (:SDL-KEY-WORLD-45 205)
  (:SDL-KEY-WORLD-46 206)
  (:SDL-KEY-WORLD-47 207)
  (:SDL-KEY-WORLD-48 208)
  (:SDL-KEY-WORLD-49 209)
  (:SDL-KEY-WORLD-50 210)
  (:SDL-KEY-WORLD-51 211)
  (:SDL-KEY-WORLD-52 212)
  (:SDL-KEY-WORLD-53 213)
  (:SDL-KEY-WORLD-54 214)
  (:SDL-KEY-WORLD-55 215)
  (:SDL-KEY-WORLD-56 216)
  (:SDL-KEY-WORLD-57 217)
  (:SDL-KEY-WORLD-58 218)
  (:SDL-KEY-WORLD-59 219)
  (:SDL-KEY-WORLD-60 220)
  (:SDL-KEY-WORLD-61 221)
  (:SDL-KEY-WORLD-62 222)
  (:SDL-KEY-WORLD-63 223)
  (:SDL-KEY-WORLD-64 224)
  (:SDL-KEY-WORLD-65 225)
  (:SDL-KEY-WORLD-66 226)
  (:SDL-KEY-WORLD-67 227)
  (:SDL-KEY-WORLD-68 228)
  (:SDL-KEY-WORLD-69 229)
  (:SDL-KEY-WORLD-70 230)
  (:SDL-KEY-WORLD-71 231)
  (:SDL-KEY-WORLD-72 232)
  (:SDL-KEY-WORLD-73 233)
  (:SDL-KEY-WORLD-74 234)
  (:SDL-KEY-WORLD-75 235)
  (:SDL-KEY-WORLD-76 236)
  (:SDL-KEY-WORLD-77 237)
  (:SDL-KEY-WORLD-78 238)
  (:SDL-KEY-WORLD-79 239)
  (:SDL-KEY-WORLD-80 240)
  (:SDL-KEY-WORLD-81 241)
  (:SDL-KEY-WORLD-82 242)
  (:SDL-KEY-WORLD-83 243)
  (:SDL-KEY-WORLD-84 244)
  (:SDL-KEY-WORLD-85 245)
  (:SDL-KEY-WORLD-86 246)
  (:SDL-KEY-WORLD-87 247)
  (:SDL-KEY-WORLD-88 248)
  (:SDL-KEY-WORLD-89 249)
  (:SDL-KEY-WORLD-90 250)
  (:SDL-KEY-WORLD-91 251)
  (:SDL-KEY-WORLD-92 252)
  (:SDL-KEY-WORLD-93 253)
  (:SDL-KEY-WORLD-94 254)
  (:SDL-KEY-WORLD-95 255)
  (:SDL-KEY-KP0 256)
  (:SDL-KEY-KP1 257)
  (:SDL-KEY-KP2 258)
  (:SDL-KEY-KP3 259)
  (:SDL-KEY-KP4 260)
  (:SDL-KEY-KP5 261)
  (:SDL-KEY-KP6 262)
  (:SDL-KEY-KP7 263)
  (:SDL-KEY-KP8 264)
  (:SDL-KEY-KP9 265)
  (:SDL-KEY-KP-PERIOD 266)
  (:SDL-KEY-KP-DIVIDE 267)
  (:SDL-KEY-KP-MULTIPLY 268)
  (:SDL-KEY-KP-MINUS 269)
  (:SDL-KEY-KP-PLUS 270)
  (:SDL-KEY-KP-ENTER 271)
  (:SDL-KEY-KP-EQUALS 272)
  (:SDL-KEY-UP 273)
  (:SDL-KEY-DOWN 274)
  (:SDL-KEY-RIGHT 275)
  (:SDL-KEY-LEFT 276)
  (:SDL-KEY-INSERT 277)
  (:SDL-KEY-HOME 278)
  (:SDL-KEY-END 279)
  (:SDL-KEY-PAGEUP 280)
  (:SDL-KEY-PAGEDOWN 281)
  (:SDL-KEY-F1 282)
  (:SDL-KEY-F2 283)
  (:SDL-KEY-F3 284)
  (:SDL-KEY-F4 285)
  (:SDL-KEY-F5 286)
  (:SDL-KEY-F6 287)
  (:SDL-KEY-F7 288)
  (:SDL-KEY-F8 289)
  (:SDL-KEY-F9 290)
  (:SDL-KEY-F10 291)
  (:SDL-KEY-F11 292)
  (:SDL-KEY-F12 293)
  (:SDL-KEY-F13 294)
  (:SDL-KEY-F14 295)
  (:SDL-KEY-F15 296)
  (:SDL-KEY-NUMLOCK 300)
  (:SDL-KEY-CAPSLOCK 301)
  (:SDL-KEY-SCROLLOCK 302)
  (:SDL-KEY-RSHIFT 303)
  (:SDL-KEY-LSHIFT 304)
  (:SDL-KEY-RCTRL 305)
  (:SDL-KEY-LCTRL 306)
  (:SDL-KEY-RALT 307)
  (:SDL-KEY-LALT 308)
  (:SDL-KEY-RMETA 309)
  (:SDL-KEY-LMETA 310)
  (:SDL-KEY-LSUPER 311)
  (:SDL-KEY-RSUPER 312)
  (:SDL-KEY-MODE 313)
  (:SDL-KEY-COMPOSE 314)
  (:SDL-KEY-HELP 315)
  (:SDL-KEY-PRINT 316)
  (:SDL-KEY-SYSREQ 317)
  (:SDL-KEY-BREAK 318)
  (:SDL-KEY-MENU 319)
  (:SDL-KEY-POWER 320)
  (:SDL-KEY-EURO 321)
  (:SDL-KEY-UNDO 322)))
  
(defparameter *key-modifiers*
  '((:NONE #x0000)
    (:LSHIFT #x0001)
    (:RSHIFT #x0002)
    (:LCTRL #x0040)
    (:RCTRL #x0080)
    (:LALT #x0100)
    (:RALT #x0200)
    (:LMETA #x0400)
    (:RMETA #x0800)
    (:NUM #x1000)
    (:CAPS #x2000)
    (:MODE #x4000)
    (:RESERVED #x8000)))

(defparameter *sdl-key-modifiers*
  '((:SDL-KEY-MOD-NONE #x0000)
    (:SDL-KEY-MOD-LSHIFT #x0001)
    (:SDL-KEY-MOD-RSHIFT #x0002)
    (:SDL-KEY-MOD-LCTRL #x0040)
    (:SDL-KEY-MOD-RCTRL #x0080)
    (:SDL-KEY-MOD-LALT #x0100)
    (:SDL-KEY-MOD-RALT #x0200)
    (:SDL-KEY-MOD-LMETA #x0400)
    (:SDL-KEY-MOD-RMETA #x0800)
    (:SDL-KEY-MOD-NUM #x1000)
    (:SDL-KEY-MOD-CAPS #x2000)
    (:SDL-KEY-MOD-MODE #x4000)
    (:SDL-KEY-MOD-RESERVED #x8000)))

;;; keys.lisp ends here
