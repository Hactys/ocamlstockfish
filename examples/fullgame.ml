open Ocamlstockfish.Stockfish_intf


module Engine_config = struct
	let path = "/path/to/stockfish"
end
	

module Engine = Ocamlstockfish.Stockfish.Engine(Engine_config)


let () = begin
	Engine.update_engine_parameters [Threads 2; Hash 4096];
	Engine.set_elo_level 1320;
	Engine.new_game ();
	Engine.set_position []
	end	


let () = print_endline (Engine.get_board_visual ~light:true ())


let rec get_user_move () = 
	print_string "your move >>> ";
	let user_move = read_line () in 
	if Engine.is_move_correct user_move then user_move 
	else (print_endline "Please enter a valid move"; get_user_move ())


let game () = try 
	while Engine.get_best_move ~depth:1 () <> "(none)" do 
		let user_move = get_user_move () in
		Engine.move user_move;
		let t, v  = Engine.get_eval () in 
		Printf.printf "%s : %d\n" t v;
		Engine.move (Engine.get_best_move ());
		let t, v  = Engine.get_eval () in 
		Printf.printf "%s : %d\n" t v;
		print_endline (Engine.get_board_visual ~light:true ())
	done 
	with Exit -> ();
	print_endline "End of the game !"


let () = game ()


let () = Engine.quit ()  (* Don't forget to close Stockfish *)

