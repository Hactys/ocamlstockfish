# ocamlstockfish
A simple way to use Stockfish engine with OCaml

## Usage
Create a Engine_config module
```ocaml
module Engine_config = struct
	let path = "/path/to/stockfish/executable"
end
```

Launch Stockfish
```ocaml
module Engine = Ocamlstockfish.Stockfish.Engine(Engine_config)
```



**Supplied Functions**

```ocaml
val send_command : string -> unit
val get_response : ?lines:int -> unit -> string
```
Basic functions, if you don't know how Stockfish works, please consult the Stockfish documentation (https://github.com/official-stockfish/Stockfish/wiki/Commands) before using these functions.

```ocaml
val wait_ready : unit -> unit
```
Useful if you use `send_command` and `get_response` to ensure that Stockfish is ready to receive the next command, or to empty Stockfish's `out_channel`.

```ocaml
val new_game : unit -> unit
```
To start a new game.

```ocaml
val update_engine_parameters : parameter list -> unit
```
Update the Stockfish's parameters.
Usage: `update_engine_parameters [Threads 2; Hash 4096; UCI_Chess960 false]`.
Note : The `parameter` type is provide in `stockfish_intf.ml`, to use it, add at the start of the file :
```ocaml
open Ocamlstockfish.Stockfish_intf
```

```ocaml
val reset_engine_parameters : unit -> unit
```
Reset the parameters of the engine to default.

```ocaml
val set_position : ?pos:string -> string list -> unit
```
Set the game position from a fen or 'startpos' follows by a list of moves for this position.
Usage : 
- `set_position []` to set the the game's postion to the standard starting position in chess
- `set_position ["e2e4"]` to set the game's position to the standard starting position in chess and when White has played the e2 pawn to e4.
- `set_position ~pos:"rnbqkbnr/pppppppp/8/8/4P3/8/PPPP1PPP/RNBQKBNR b KQkq e3 0 1" []` to set the the game's position as same as the last example, but using a FEN.

```ocaml
val move : string -> unit
```
Update the current position by playing the givven move, can raise an error : `StockfishError (IncorectMove of string)`.
Usage : 
- `move "e2e4"`

```ocaml
val set_skill_level : int -> unit
val set_elo_level : int -> unit
val set_depth : int -> unit
val full_strength : unit -> unit
```
To set the strength of the engine, the default search depth, back Stockfish to full strength.

```ocaml
val stop : unit -> unit
val quit : unit -> unit
```
To stops Stockfish's computations as soon as possible.
Send the `quit` command and close communication's channels and end the Stockfish process.

```ocaml
val get_best_move : ?depth:int -> unit -> string
val get_best_move_with_ponder : ?depth:int -> unit -> string * string
val get_best_move_time : ?depth:int -> int -> string
val get_fen : unit -> string
val get_eval : ?depth:int -> unit -> string * int
val get_wdl_stats : ?depth:int -> unit -> int * int * int
val get_engine_parameters : unit -> parameter array
val is_move_correct : string -> bool
```
Generic functions to interract with Stockfish.
