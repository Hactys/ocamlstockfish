open Ocamlstockfish.Stockfish_intf

module Engine_config = struct
	let path = "stockfish/stockfish-ubuntu-x86-64-avx2"
end


module Engine = Ocamlstockfish.Stockfish.Engine(Engine_config)

let () = Engine.update_engine_parameters [Threads 2; Hash 4096]

let () = Engine.new_game ()

let () = Engine.set_position []

let () = Engine.move (Engine.get_best_move ~depth:20 ())

let () = print_endline (Engine.get_board_visual ~light:true ())

let () = Engine.quit ()
