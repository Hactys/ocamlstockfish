module type Engine_config_type = sig
	(** Path to the Stockfish executable. *)
	val path : string
end

type parameter = 
	Threads of int
	| Hash of int
	| Ponder of bool
	| MultiPV of int
	| NNUE of bool 
	| EvalFile of string
	| UCI_AnalyseMode of bool
	| UCI_Chess960 of bool
	| UCI_ShowWDL of bool
	| UCI_LimitStrength of bool
	| UCI_Elo of int
	| Skill_Level of int
	| SyzygyPath of string
	| SyzygyProbeDepth of int
	| Syzygy50MoveRule of bool
	| SyzygyProbeLimit of int
	| Move_Overhead of int 
	| Slow_Mover of int
	| Nodestime of int
	| Debug_Log_File of string


type _error = 
	IncorectMove of string
	| NoMovePlayed of string
	| InvalidValue of string


exception StockfishError of _error


type move_evaluation = Best | Excelent | Good | Inaccuracy | Mistake | Blunder | Mate


module type Engine_type = sig
	(** Returns the Stockfish's response to a command. *)
	val get_response : ?lines:int -> unit -> string


	(* Returns the full string of Stockfish's response from last read to completition. *)
	val get_full_response : unit -> string

	(** Send a command to Stockfish. *)
	val send_command : string -> unit


	(** Wait until stockfish is ready. *)
	val wait_ready : unit -> unit


	(** Start a new game. *)
	val new_game : unit -> unit


	(** Update the engine parameters, go to doc to know all possibilities. *)
	val update_engine_parameters : parameter list -> unit


	(** Reset the parameters of the engine to default. *)
	val reset_engine_parameters : unit -> unit


	(** Set the game position from a fen or 'startpos' follows by a list of moves for this position. *)
	val set_position : ?pos:string -> string list -> unit


	(** Lower the skill level in order to make Stockfish play weaker. Must be between 0 and 20. *)
	val set_skill_level : int -> unit


	(** Aims for an engine strength of the given Elo. This Elo rating has been calibrated at a time control of 60s+0.6s and anchored to CCRL 40/4. Must be between 1320 and 3190. *)
	val set_elo_level : int -> unit


	(** Sets the default engine's depth. *)
	val set_depth : int -> unit


	(** Put the engine back to full strength (if you previously lowered the ELO or skill level). *)
	val full_strength : unit -> unit


	(** Stops Stockfish's computations as soon as possible. *)
	val stop : unit -> unit


	(** Send the 'quit' command and close communication's channels. *)
	val quit : unit -> unit


	(** Returns a visual representation of the current board position. *)
	val get_board_visual : ?light:bool -> unit -> string


	(** Returns best move with current position on the board. *)
	val get_best_move : ?depth:int -> unit -> string


	(** Returns best move with current position on the board and the best ponder fonded, could be "" for ponder. *)
	val get_best_move_with_ponder : ?depth:int -> unit -> string * string


	(** Returns best move with current position on the board after exactly the given time in ms. *)
	val get_best_move_time : ?depth:int -> int -> string


	(** Returns current board position in Forsyth–Edwards notation (FEN). *)
	val get_fen : unit -> string


	(** Evaluates current position. *)
	val get_eval : ?depth:int -> unit -> string * int


	(** Returns Stockfish's win/draw/loss stats for the side to move. *)
	val get_wdl_stats : ?depth:int -> unit -> int * int * int


	(** Retunrs the engine's parameters. *)
	val get_engine_parameters : unit -> parameter array


	(** Update the current position by playing the current move. *)
	val move : string -> unit


	(** Check if the given move is correct. *)
	val is_move_correct : string -> bool
end