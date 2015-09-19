let process_output_to_list2 = fun command ->
  let chan = Unix.open_process_in command in
  let res = ref ([] : string list) in
  let rec process_otl_aux () =
    let e = input_line chan in
    res := e::!res;
    process_otl_aux() in
  try process_otl_aux ()
  with End_of_file ->
    let stat = Unix.close_process_in chan in (List.rev !res,stat)
let cmd_to_list command =
  let (l,_) = process_output_to_list2 command in l
let process_output_to_list = cmd_to_list
let cmd_to_list_and_status = process_output_to_list2

let rec incomment i =
  let line = input_line i in
  match Str.split_delim (Str.regexp_string "*/") line with
    [l] -> incomment i
  | [] -> incomment i
  | l -> List.hd (List.rev l)

let ctr = ref 0

let rec process i =
  let line = input_line i in
  let rec loop line =
    match Str.split_delim (Str.regexp "[ \t]*") line with
      ["";""] -> ()
    | [] -> ()
    | _ ->
	(match Str.split_delim (Str.regexp_string "//") line with
	  l::r::_ -> loop l
	| _ ->
	    (match Str.split_delim (Str.regexp_string "/*") line with
	      l::((r::_) as last) ->
		let ender =
		  Str.split_delim (Str.regexp_string "*/")
		    (List.hd (List.rev last)) in
		(match ender with
		  [_;r] ->
		    let old = !ctr in
		    loop l;
		    (if old = !ctr then loop r)
		| _ -> loop l; loop(incomment i))
	    | _ -> ctr := !ctr + 1)) in
  loop line;
  process i

let _ =
  let file = Array.get Sys.argv 1 in
  let i = open_in file in
  (try process i with End_of_file -> ());
  close_in i;
  let ansic =
    cmd_to_list
      (Printf.sprintf "cp %s /tmp/file.c; sloccount /tmp/file.c | grep ansic:"
	 file) in
  Printf.printf "ctr: %d, %s\n" !ctr (List.hd ansic)

