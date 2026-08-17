; Keep normal structural folds, but only expose actual docstrings as string folds.
[
  (function_definition)
  (class_definition)
  (while_statement)
  (for_statement)
  (if_statement)
  (with_statement)
  (try_statement)
  (match_statement)
  (import_from_statement)
  (parameters)
  (argument_list)
  (parenthesized_expression)
  (generator_expression)
  (list_comprehension)
  (set_comprehension)
  (dictionary_comprehension)
  (tuple)
  (list)
  (set)
  (dictionary)
] @fold

[
  (import_statement)
  (import_from_statement)
]+ @fold

(module
  . (expression_statement
    [(string) (concatenated_string)] @fold))

(function_definition
  body: (block
    . (expression_statement
      [(string) (concatenated_string)] @fold)))

(class_definition
  body: (block
    . (expression_statement
      [(string) (concatenated_string)] @fold)))
