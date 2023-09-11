open Stockfish_intf


module Engine (T : Engine_config_type) = struct
	(** Submodule for values that should not be used externally. *)
	module Private = struct
		let in_channel, out_channel, err_channel = Unix.open_process_full T.path [||]
		let () = begin 
			output_string out_channel "uci\n";
			flush out_channel;
			let rec loop n acc =	
				if n < 26 then 
					loop (n+1) (input_line in_channel :: acc)
				else String.concat "\n" (List.rev acc) 
			in match loop 0 [] with | _ -> ()  (* to destruct the type. *)
		end
		let default_depth = ref 12
		let ppf = ref ""  (* Previous position fen. *)
		let cpf = ref "rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1"  (* Current position, reference to string. *)
		let default_para = [|Threads 1; Hash 16; Ponder false; MultiPV 1; NNUE true; EvalFile "nn-[SHA256 first 12 digits].nnue";
			UCI_AnalyseMode false; UCI_Chess960 false; UCI_ShowWDL false; UCI_LimitStrength false; UCI_Elo 1320; Skill_Level 20;
			SyzygyPath "<empty>"; SyzygyProbeDepth 1; Syzygy50MoveRule true; SyzygyProbeLimit 7; Move_Overhead 10; 
			Slow_Mover 100; Nodestime 0; Debug_Log_File ""|]
		let para = [|Threads 1; Hash 16; Ponder false; MultiPV 1; NNUE true; EvalFile "nn-[SHA256 first 12 digits].nnue";
			UCI_AnalyseMode false; UCI_Chess960 false; UCI_ShowWDL false; UCI_LimitStrength false; UCI_Elo 1320; Skill_Level 20;
			SyzygyPath "<empty>"; SyzygyProbeDepth 1; Syzygy50MoveRule true; SyzygyProbeLimit 7; Move_Overhead 10; 
			Slow_Mover 100; Nodestime 0; Debug_Log_File ""|]
	end


	let get_response ?(lines = 1) () =
		let rec loop n acc =	
			if n < lines then 
				loop (n+1) (input_line Private.in_channel :: acc)
			else String.concat "\n" (List.rev acc) 
		in loop 0 []


	let send_command c = 
		begin
		output_string Private.out_channel (String.concat "" [c; "\n"]);
		flush Private.out_channel;  (* To be sure that the command is sended. *)
		end


	let wait_ready () = begin
		send_command "isready";
		match get_response () with _ -> ()
	end

	
	let get_full_response () = begin
		wait_ready ();
		let rec loop acc = match input_line Private.in_channel with
			| "readyok" -> acc
			| r -> loop (r :: acc)
		in let response = List.rev (loop [])
		in String.concat "\n" response
	end


	let new_game () = 
		wait_ready ();
		send_command "ucinewgame"


	let update_engine_parameters l = 
		let () = wait_ready () in 
		let conv a = match a with
			  Threads v -> (0, "Threads", string_of_int v)
			| Hash v -> (1, "Hash", string_of_int v)
			| Ponder v -> (2, "Ponder", string_of_bool v)
			| MultiPV v -> (3, "MultiPV", string_of_int v)
			| NNUE v -> (4, "Use NNUE", string_of_bool v)
			| EvalFile v -> (5, "EvalFile", v)
			| UCI_AnalyseMode v -> (6, "UCI_AnalyseMode", string_of_bool v)
			| UCI_Chess960 v -> (7, "UCI_Chess960", string_of_bool v)
			| UCI_ShowWDL v -> (8, "UCI_ShowWDL", string_of_bool v)
			| UCI_LimitStrength v -> (9, "UCI_LimitStrength", string_of_bool v)
			| UCI_Elo v -> (10, "UCI_Elo", string_of_int v)
			| Skill_Level v -> (11, "Skill Level", string_of_int v)
			| SyzygyPath  v -> (12, "SyzygyPath", v)
			| SyzygyProbeDepth v -> (13, "SyzygyProbeDepth", string_of_int v)
			| Syzygy50MoveRule v -> (14, "Syzygy50MoveRule", string_of_bool v)
			| SyzygyProbeLimit v -> (15, "SyzygyProbeLimit", string_of_int v)
			| Move_Overhead v -> (16, "Move Overhead", string_of_int v) 
			| Slow_Mover v -> (17, "Slow Mover", string_of_int v)
			| Nodestime v -> (18, "Nodestime", string_of_int v)
			| Debug_Log_File  v -> (19, "Debug Log File", v) in

		let rec loop l = match l with
			| [] -> ()
			| a :: t -> let i, n, v = conv a in begin 
				Private.para.(i) <- a;
				send_command (String.concat " " ["setoption"; "name"; n; "value"; v]); 
				loop t
			end
		in loop l 


	let reset_engine_parameters () =
		let l = Array.to_list Private.default_para in 
		update_engine_parameters l


	let set_position ?(pos = "startpos") lm = begin
		wait_ready ();
		let position = match pos with 
			| "startpos" -> ["position"; pos]
			| _ -> ["position"; "fen"; pos]
		
		in if List.length lm = 0 then send_command (String.concat " " position)
		else send_command (String.concat " " ("position" :: "fen" :: pos :: "moves" :: lm));

		send_command "d";
		let rec loop () = match String.split_on_char ' ' (get_response ()) with
			| "Fen:" :: t -> (match get_response ~lines:2 () with _ -> (); String.concat " " t)
			| _ -> loop ()
		in Private.ppf := "";
		Private.cpf := loop ()
	end


	let set_skill_level level = 
		if level < 0 || level > 20 then raise (StockfishError (InvalidValue "Skill_level must be between 0 and 20."));
		wait_ready ();
		update_engine_parameters [Skill_Level level]


	let set_elo_level level = 
		if level < 1320 || level > 3190 then raise (StockfishError (InvalidValue "Skill_level must be between 1320 and 3190."));
		if Private.para.(9) <> UCI_LimitStrength true then 
			update_engine_parameters [UCI_LimitStrength true];
		wait_ready ();
		update_engine_parameters [UCI_Elo level];
		wait_ready ()


	let set_depth depth = Private.default_depth := depth


	let full_strength () =
		update_engine_parameters [UCI_LimitStrength false; Skill_Level 20]
	

	let stop = fun () -> send_command "stop"


	let quit = fun () -> begin 
		send_command "quit";
		close_in Private.in_channel;
		close_out Private.out_channel;
		close_in Private.err_channel;
	end


	let get_best_move_with_ponder ?(depth=(!Private.default_depth)) () =
		wait_ready ();
		send_command (String.concat " " ["go"; "depth"; string_of_int depth]);
		let rec loop () =
			match String.split_on_char ' ' (get_response ()) with
			| ["bestmove"; m; "ponder"; p] -> (m, p)
			| ["bestmove"; m] -> (m, "") 
			| _ -> loop ()
		in loop ()


	let get_best_move ?(depth=(!Private.default_depth)) () =
		fst (get_best_move_with_ponder ~depth:depth ())


	let get_best_move_time ?(depth=(!Private.default_depth)) time =
		wait_ready ();
		send_command (
			String.concat " " ["go"; "depth"; string_of_int depth; "movetime"; string_of_int time; ]
		);
		let rec loop () =
			match String.split_on_char ' ' (get_response ()) with
			| ["bestmove"; m; "ponder"; _] -> m
			| ["bestmove"; m] -> m
			| _ -> loop ()
		in loop ()


	let get_fen () =
		!Private.cpf


	let get_board_visual ?(light=false) () = 
		wait_ready ();
		send_command "d";
		match get_response ~lines:1 () with _ -> ();
		let board = get_response ~lines:18 () in
		match get_full_response () with _ -> (* Destruct the type. *)
		if not light then board 
		else begin
			let fen = get_fen () in 
			let a = List.hd (String.split_on_char ' ' fen) in 
			let b = String.split_on_char '/' a in 
			let process s j = 
				let k = String.length s in 
				let rec loop i acc = if i < k then 
					match String.get s i with
						| '1' -> loop (i+1) ("." :: acc)
						| '2' -> loop (i+1) (". ." :: acc)
						| '3' -> loop (i+1) (". . ." :: acc)
						| '4' -> loop (i+1) (". . . ." :: acc)
						| '5' -> loop (i+1) (". . . . ." :: acc)
						| '6' -> loop (i+1) (". . . . . ." :: acc)
						| '7' -> loop (i+1) (". . . . . . ." :: acc)
						| '8' -> loop (i+1) (". . . . . . . ." :: acc)
						| e -> loop (i+1) ((String.make 1 e) :: acc)
					else ["|"] @ List.rev acc @ ["|"; string_of_int (9-j)]
				in String.concat " " (loop 0 [])
		 	in
			let rec loop j l acc = match l with
				| [] -> acc
				| h :: t -> loop (j+1) t ((process h j) :: acc)
			in String.concat "\n" ("+-----------------+" :: List.rev ("  a b c d e f g h" :: "+-----------------+" :: loop 1 b []))
		end


	let is_move_correct m = begin
		send_command ("go depth 1 searchmoves " ^ m);
		match get_response ~lines:2 () with _ -> ();
		get_response () <> "bestmove (none)"
	end


	let move m = begin
		if is_move_correct m then begin
			Private.ppf := !Private.cpf;
			set_position ~pos:!Private.cpf [m];
			wait_ready ()
		end
		else raise (StockfishError (IncorectMove (m ^ " is an invalid move in the curent position.")))
	end


	let get_eval ?(depth=(!Private.default_depth)) () = 
		wait_ready ();
		send_command ("go depth " ^ string_of_int depth);
		let fen = get_fen () in 
		let m = if String.contains fen 'w' then 1 else -1 in 
		let e = ref ("cp", 0) in 
		let rec loop () =
			match String.split_on_char ' ' (get_response ()) with
			| "info" :: "depth" :: _ :: _ :: _ :: _ :: _ :: "score" :: ty :: n :: _ -> 
				(e := (ty, m * int_of_string n) ; loop ())
			| "bestmove" :: _ -> !e
			| _ -> loop ()
		in loop ()


	let get_wdl_stats ?(depth=(!Private.default_depth)) () =
		if Private.para.(8) <> UCI_ShowWDL true then 
			update_engine_parameters [UCI_ShowWDL true];
		wait_ready ();
		send_command ("go depth " ^ string_of_int depth);
		let wdl = ref (0, 0, 0) in 
		let rec loop () =
			match String.split_on_char ' ' (get_response ()) with
			| "info" :: "depth" :: _ :: _ :: _ :: _ :: _ :: "score" :: _ :: _ :: "wdl" :: w :: d :: l :: _ -> 
				(wdl := (int_of_string w, int_of_string d, int_of_string l) ; loop ())
			| "bestmove" :: _ -> !wdl
			| _ -> loop ()
		in loop ()


	let get_engine_parameters () = Array.copy Private.para	

end
