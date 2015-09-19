clean: clean.ml
	ocamlc -o clean str.cma unix.cma clean.ml
