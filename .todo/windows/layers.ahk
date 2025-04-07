#NoEnv
#SingleInstance Ignore
current_layer := "layer_normal"

$CapsLock::
  ; Start layer and wait for tapping term.
  global current_layer
  current_layer := "layer_function"
  keywait, CapsLock, t0.25
  ; Determine tap or hold.
  if (ErrorLevel = 0) {
    ; Tap behavior: If tapped fast enough, cancel layer and send tap code.
    current_layer := "layer_normal"
    send, {Escape}
  } else {
    ; Hold behavior: Wait for hold release, then clear layer.
    keywait, CapsLock
    current_layer := "layer_normal"
  }
  return

$Enter::
  ; Start layer and wait for tapping term.
  global current_layer
  current_layer := "layer_symbols"
  keywait, Enter, t0.25
  ; Determine tap or hold.
  if (ErrorLevel = 0) {
    ; Tap behavior: If tapped fast enough, cancel layer and send tap code.
    current_layer := "layer_normal"
    send, {Enter}
  } else {
    ; Hold behavior: Wait for hold release, then clear layer.
    keywait, Enter
    current_layer := "layer_normal"
  }
  return

#If current_layer="layer_function"
  SC029::return ; `
  1::F1
  2::F2
  3::F3
  4::F4
  5::F5
  6::F6
  7::F7
  8::F8
  9::F9
  0::F10
  -::F11
  =::F12

  q::return
  w::Home
  e::PgUp
  r::PgDn
  t::End
  y::Home
  u::PgDn
  i::PgUp
  o::End
  p::PrintScreen
  [::return
  ]::return
  \::return

  a::return
  s::Left
  d::Up
  f::Down
  g::Right
  h::Left
  j::Down
  k::Up
  l::Right
  `;::return
  '::return

  z::return
  x::return
  c::return
  v::return
  b::return
  n::return
  m::return
  ,::return
  .::return
  /::return

  Space::Media_Play_Pause
  Left::Media_Prev
  Up::Volume_Up
  Down::Volume_Down
  Right::Media_Next

  Volume_Up::Media_Next
  Volume_Down::Media_Prev
  Volume_Mute::Media_Play_Pause


#If current_layer="layer_symbols"
  SC029::return ; `
  1::!
  2::@
  3::#
  4::$
  5::send `%
  6::^
  7::&
  8::*
  9::(
  0::)
  -::_
  =::+

  q::send {Space}&&{Space}
  w::&
  e::/
  r::-
  t::_
  y::=
  u::+
  i::\
  o::|
  p::send {Space}||{Space}
  [::(
  ]::)
  \::|

  a::send {Space}&&{Space}
  s::[
  d::{
  f::(
  g::<
  h::>
  j::)
  k::}
  l::]
  `;::send {Space}||{Space}
  '::"

  z::return
  x::return
  c::return
  v::return
  b::return
  n::return
  m::return
  ,::return
  .::return
  /::return