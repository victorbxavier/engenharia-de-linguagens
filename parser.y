%{
	#include <stdio.h>
	#include <stdlib.h>
	#include <string.h>
	#include <ctype.h>
	#include "./lib/record.h"

	int yylex(void);
	int yyerror(char *s);
	int yywrad();

	extern int yylineno;
	extern char * yytext;
	extern FILE * yyin, * yyout;

	char * cat(char *, char *, char *, char *, char *);

	void add(char symbol, char * id_name);
	void addWithScope(char symbol, char * id_name, int value_scope, char * function_name);
	void insert_type(char * type_text);
	void insert_tag_text(char * text);
	int search(char *c);
	void insert_value(char * id, char * value);
	int verificar_valor_tipo_valido(char * valor, char * tipo);
	int isInteger(const char *str);
	int isFloat(const char *str);
	char * tipo_resultado_operacao(char * type1, char * type2);
	int verificar_calculo_numero_float_int(char * type1, char * type2);
	int verificar_variavel_existe(char * name, char * tag);
	int verificar_ids_validos(char * ids, char * tag);
	char ** separarIDs(char * texto, int * tamanho);
	void processarTexto(char * texto);

	struct dataType {
		char * id_name;
		char * data_type;
		char * type;
		int line_no;
		int scope;
		char * tag;
	} symbol_table[40];

	int count = 0;
	int q;
	char type[10];
	char tag_text[50];
	int count_label = 0;
	extern int countn;
	extern int count_block;
%}

%union {
	int    iValue; 	/* integer value */
	char   cValue; 	/* char value */
	char * sValue;  /* string value */
	float  fValue;  /* float value */
	double dvalue;  /* double value */ 
	struct record * rec;
};

%token <sValue> ID
%token <sValue> INT_NUMBER
%token <sValue> FLOAT_NUMBER
%token <sValue> STRING_VALUE
%token INT DOUBLE FLOAT CHAR STRING BOOLEAN NULL_VALUE VOID STRUCT ENUM TRUE FALSE
%token WHILE DO SWITCH CASE DEFAULT IF ELSE ELSE_IF FOR CONTINUE BREAK CONST STATIC RETURN MAIN SCAN PRINT MALLOC FREE
%token OPEN_PAREN CLOSE_PAREN OPEN_BRACK CLOSE_BRACK BLOCK_BEGIN BLOCK_END SEMI COLON DOT COMMA AMPERSAND
%token PLUS MINUS DIV MULT INCREMENT DECREMENT MODULE ASSIGN ADD_ASSIGN SUB_ASSIGN 
%token EQ NEQ LT GT LE GE
%token AND OR NOT

%type <rec> decs_var subprograms principal dec_var assigns type ids p_values dims type_modifiers
%type <rec> type_modifier atomo value expr term factor function_call assign_def assign_mat
%type <rec> subprogram proc function params stmts param stmt conditional_stmt iteration_stmt
%type <rec> if_stmt switch_stmt logic_expr else_if_stmt logic_op c_term comp comp_op 
%type <rec> switch_cases while_stmt for_stmt dowhile_stmt args arg print_content print_stmt scan_stmt fre_stmt

%start prog


%% /* Inicio da segunda seção, onde colocamos as regras BNF */

prog : decs_var subprograms principal { fprintf(yyout, "#include <stdio.h>\n#include <stdlib.h>\n#include <string.h>\n#include <stdbool.h>\n%s\n%s\n%s", $1->code, $2->code, $3->code);
	 									freeRecord($1);
										freeRecord($2);
										freeRecord($3);
	 								  }
	 | subprograms principal {
								fprintf(yyout, "#include <stdio.h>\n#include <stdlib.h>\n#include <string.h>\n#include <stdbool.h>\n%s\n%s\n%s", $1->code, $2->code, "");
								freeRecord($1);
								freeRecord($2);
							 }
	 | principal {
					fprintf(yyout, "#include <stdio.h>\n#include <stdlib.h>\n#include <string.h>\n#include <stdbool.h>\n%s\n%s\n%s", $1->code, "", "");
					freeRecord($1);
				 }
	 | decs_var principal { fprintf(yyout, "#include <stdio.h>\n#include <stdlib.h>\n#include <string.h>\n#include <stdbool.h>\n%s\n%s", $1->code, $2->code);
							freeRecord($1);
	 						freeRecord($2);
	 					  }
	 ;

decs_var : 				 	{$$ = createRecord("","");}
		 | dec_var decs_var {char *s = cat($1->code, $2->code,"","","");
							 $$ = createRecord(s, $1->type);
							 freeRecord($1);
							 freeRecord($2);
							 free(s);
		 					}
		 | assigns {char *s = cat($1->code, "", "", "","");
					$$ = createRecord(s, $1->type);
					freeRecord($1);
					free(s);
		 		   }
		 ;

dec_var : type ids SEMI {	add('V', $2->code);
							char *s = cat($1->code, " ", $2->code, ";","");
						  	
						  	$$ = createRecord(s, $1->code);
							freeRecord($1);
						  	freeRecord($2);
						  	free(s);
						}
		| type ID ASSIGN p_values SEMI  { 	add('V', $2);
											char *s1 = cat($1->code, " ", $2, "=", $4->code);
											char *s2 = cat(s1, ";", "", "", "");

											if(strcmp($1->code, "string") == 0 && strcmp($4->type, "string") == 0){
												$$ = createRecord(s2, $1->code);
											}else if(strcmp($1->code, "boolean") == 0 && strcmp($4->type, "boolean") == 0){
												$$ = createRecord(s2, $1->code);
											}
											else if(verificar_calculo_numero_float_int($1->code, $4->type)){
												$$ = createRecord(s2, $1->code);
											}else {
												yyerror("Tipos incompativeis");
											}

											$$ = createRecord(s2, $1->code);
											freeRecord($1);
											freeRecord($4);
											free(s2);
											free(s1);
										}
		| type ID dims ASSIGN BLOCK_BEGIN p_values BLOCK_END SEMI { add('V', $2);
																	char *s1 = cat($1->code, " ", $2, $3->code, "=");
																	char *s2 = cat(s1, "{", $6->code, "}", ";");
																  	

																	if(strcmp($1->code, "string") == 0 && strcmp($6->type, "string") == 0){
																		$$ = createRecord(s2, $1->code);
																	} else if(verificar_calculo_numero_float_int($1->code, $6->type)){
																		$$ = createRecord(s2, $1->code);
																	}else {
																		yyerror("Tipos incompativeis");
																	}

																	freeRecord($1);
																	freeRecord($3);
																	freeRecord($6);
																	free(s2);
																	free(s1);
																  }
		| type ID dims SEMI {	add('V', $2);
								char *s = cat($1->code, " ", $2, $3->code, ";");
								
								$$ = createRecord(s, $1->code);
								freeRecord($1);
								freeRecord($3);
								free(s);
							}
		| type_modifiers type ids SEMI {	add('V', $3->code);
											char *s1 = cat($1->code, " ", $2->code, " ", $3->code);
											char *s2 = cat(s1, ";", "", "", "");
											
											$$ = createRecord(s2, $2->code);
											freeRecord($1);
											freeRecord($2);
											freeRecord($3);
											free(s2);
											free(s1);
									   }
        | type_modifiers type ID ASSIGN p_values SEMI {	add('V', $3);
														char *s1 = cat($1->code, " ", $2->code, " ", $3);
														char *s2 = cat(s1, "=", $5->code, ";", "");
														
														if(strcmp($2->code, "string") == 0 && strcmp($5->type, "string") == 0){
															$$ = createRecord(s2, $2->code);
														} else if(verificar_calculo_numero_float_int($2->code, $5->type)){
															$$ = createRecord(s2, $2->code);
														}else {
															yyerror("Tipos incompativeis");
														}

														freeRecord($1);
														freeRecord($2);
														freeRecord($5);
														free(s2);
														free(s1);
													  }
		| type_modifiers type ID dims ASSIGN BLOCK_BEGIN p_values BLOCK_END SEMI {	add('V', $3);
																					char *s1 = cat($1->code, " ", $2->code, "", $3);
																					char *s2 = cat(s1, $4->code, "=", "{", $7->code);
																					char *s3 = cat(s2, "}", ";", "", "");
																					
																					if(strcmp($2->code, "string") == 0 && strcmp($7->type, "string") == 0){
																						$$ = createRecord(s3, $2->code);
																					} else if(verificar_calculo_numero_float_int($2->code, $7->type)){
																						$$ = createRecord(s3, $2->code);
																					}else {
																						yyerror("Tipos incompativeis");
																					}

																					freeRecord($1);
																					freeRecord($2);
																					freeRecord($4);
																					freeRecord($7);
																					free(s3);
																					free(s2);
																					free(s1);
																				 }
		| type_modifiers type ID dims SEMI {	add('V', $3);
												char *s1 = cat($1->code, " ", $2->code, " ", $3);
												char *s2 = cat(s1, $4->code, ";", "", "");
												
												$$ = createRecord(s2, $2->code);
												freeRecord($1);
												freeRecord($2);
												freeRecord($4);
												free(s2);
												free(s1);
										   }
		| type MULT ID ASSIGN p_values SEMI {	add('V', $3);
												char *s1 = cat($1->code, " *", $3, "=", $5->code);
												char *s2 = cat(s1, ";", "", "", "");

												if(strcmp($1->code, "string") == 0 && strcmp($5->type, "string") == 0){
													$$ = createRecord(s2, $1->code);
												} else if(verificar_calculo_numero_float_int($1->code, $5->type)){
													$$ = createRecord(s2, $1->code);
												}else {
													yyerror("Tipos incompativeis");
												}
												
												freeRecord($1);
												freeRecord($5);
												free(s2);
												free(s1);
											}
		| type MULT ID dims ASSIGN BLOCK_BEGIN p_values BLOCK_END SEMI {add('V', $3);
																		char *s1 = cat($1->code, " *", $3, $4->code, "=");
																		char *s2 = cat(s1, "{", $7->code, "}", ";");
																		
																		$$ = createRecord(s2, $1->code);
																		freeRecord($1);
																		freeRecord($4);
																		freeRecord($7);
																		free(s2);
																		free(s1);
																	   }
		| type MULT ID dims SEMI {	add('V', $3);
									char *s = cat($1->code, " *", $3, $4->code, ";");
									
									$$ = createRecord(s, $1->code);
									freeRecord($1);
									freeRecord($4);
									free(s);
								 }
		| type_modifiers type MULT ID ASSIGN p_values SEMI {	add('V', $4);
																char *s1 = cat($1->code, " ", $2->code, " *", $4);
																char *s2 = cat(s1, "=", $6->code, ";", "");
																
																if(strcmp($2->code, "string") == 0 && strcmp($6->type, "string") == 0){
																	$$ = createRecord(s2, $2->code);
																} else if(verificar_calculo_numero_float_int($2->code, $6->type)){
																	$$ = createRecord(s2, $2->code);
																}else {
																	yyerror("Tipos incompativeis");
																}

																freeRecord($1);
																freeRecord($2);
																freeRecord($6);
																free(s2);
																free(s1);
														   }
		| type_modifiers type MULT ID dims ASSIGN BLOCK_BEGIN p_values BLOCK_END SEMI {	add('V', $4);
																						char *s1 = cat($1->code, " ", $2->code, " *", $4);
																						char *s2 = cat(s1, $5->code, "=", "{", $8->code);
																						char *s3 = cat(s2, "}", ";", "", "");
																						
																						if(strcmp($2->code, "string") == 0 && strcmp($8->type, "string") == 0){
																							$$ = createRecord(s2, $2->code);
																						} else if(verificar_calculo_numero_float_int($2->code, $8->type)){
																							$$ = createRecord(s2, $2->code);
																						}else {
																							yyerror("Tipos incompativeis");
																						}

																						freeRecord($1);
																						freeRecord($2);
																						freeRecord($5);
																						freeRecord($8);
																						free(s3);
																						free(s2);
																						free(s1);
																					  }
		| type_modifiers type MULT ID dims SEMI {	add('V', $4);
													char *s1 = cat($1->code, " ", $2->code, " *", $4);
													char *s2 = cat(s1, $5->code, ";", "", "");
													$$ = createRecord(s2, $2->code);
													freeRecord($1);
													freeRecord($2);
													freeRecord($5);
													free(s2);
													free(s1);
												}
		| type_modifier STRUCT ID BLOCK_BEGIN decs_var BLOCK_END SEMI {	insert_type("struct");
																		add('V', $3);
																		char *s1 = cat($1->code, " struct ", $3, " {\n", $5->code);
																		char *s2 = cat(s1, "\n};", "", "", "");
																		freeRecord($1);
																		freeRecord($5);
																		$$ = createRecord(s2, "struct");
																		free(s2);
																		free(s1);
																	  }
		| STRUCT ID BLOCK_BEGIN decs_var BLOCK_END SEMI {	insert_type("struct");
															add('V', $2);
															char *s = cat("struct ", $2, " {\n", $4->code, "\n};");
															freeRecord($4);
															$$ = createRecord(s, "struct");
															free(s);
														}
		| type_modifier STRUCT ID BLOCK_BEGIN BLOCK_END SEMI {	insert_type("struct");
																add('V', $3);
																char *s = cat($1->code ," struct ", $3 ," {", "};");
																freeRecord($1);
																$$ = createRecord(s, "struct");
																free(s);
															 }
		| STRUCT ID BLOCK_BEGIN BLOCK_END SEMI {insert_type("struct");
												add('V', $2);
												char *s = cat("struct", $2 ,"{};", "", "");
												$$ = createRecord(s, "struct");
												free(s);
											   }
		| STRUCT ID ID SEMI { 	insert_type("struct");
								add('V', $3);
								char * s = cat("struct ", $2, " ", $3, ";");
								$$ = createRecord(s, $2);
								free(s);
							}
		| STRUCT ID MULT ID SEMI { 	insert_type("struct");
									add('V', $4);
									char * s = cat("struct ", $2, " * ", $4, ";");
									$$ = createRecord(s, $2);
									free(s);
		}
		| type_modifier STRUCT ID ID SEMI { insert_type("struct");
											add('V', $4);
											char * s1 = cat( $1->code, " struct ", $3, " ", $4);
											char * s2 = cat(s1, ";", "", "", "");
											freeRecord($1);
											$$ = createRecord(s2, $3);
											free(s2);
											free(s1);
										}
		| STRUCT ID ID ASSIGN expr SEMI { 	insert_type("struct");
											add('V', $3);
											char * s1 = cat("struct ", $2, " ", $3, "=");
											char * s2 = cat(s1, $5->code, ";", "", "");
											$$ = createRecord(s2, $2);
											freeRecord($5);
											free(s2);
											free(s1);
										}
		| STRUCT ID MULT ID ASSIGN expr SEMI { 	insert_type("struct");
												add('V', $4);
												char * s1 = cat("struct ", $2, " * ", $4, "=");
												char * s2 = cat(s1, $6->code, ";", "", "");
												$$ = createRecord(s2, $2);
												freeRecord($6);
												free(s2);
												free(s1);
											 }
		| type_modifier STRUCT ID ID ASSIGN expr SEMI { 	insert_type("struct");
															add('V', $4);
															char * s1 = cat($1->code ," struct ", $3, " ", $4);
															char * s2 = cat(s1, "=", $6->code, ";", "");
															$$ = createRecord(s2, $3);
															freeRecord($6);
															freeRecord($1);
															free(s2);
															free(s1);
													  }
		;

type_modifiers : type_modifier {	char *s = cat($1->code, "", "", "", "");
									freeRecord($1);
									$$ = createRecord(s, "");
									free(s);
							   }
			   | type_modifier type_modifier {	char *s = cat($1->code, " ", $2->code, "", "");
												freeRecord($1);
												freeRecord($2);
												$$ = createRecord(s, "");
												free(s);
			   								 }
			   ;

type_modifier : CONST {	$$ = createRecord("const", "");
					  }
              | STATIC {$$ = createRecord("static", "");
			  		  }
			  | ENUM {	$$ = createRecord("enum", "");
			  		 }
			  ;

type : INT {insert_type("int");
			$$ = createRecord("int", "");
		   }
     | DOUBLE {	insert_type("double");
				$$ = createRecord("double", "");
	 		  }
	 | FLOAT {	insert_type("float");
				$$ = createRecord("float", "");
	 		 }
	 | CHAR {	insert_type("char");
				$$ = createRecord("char", "");
	 		}
	 | STRING {	insert_type("string");
				$$ = createRecord("string", "");
	 		  }
	 | BOOLEAN {insert_type("boolean");
				$$ = createRecord("bool", "");
	 		   }
	 ;

ids : atomo {	char *s = cat($1->code, "", "", "", "");
				$$ = createRecord(s, $1->type);
				freeRecord($1);
				free(s);
			}
	| ids COMMA atomo {	
						char *s = cat($1->code, ",", $3->code, "", "");

						$$ = createRecord(s, $1->type);
						freeRecord($1);
						freeRecord($3);
						free(s);
					  }
    | atomo COMMA p_values {
							char *s = cat($1->code, ",", $3->code, "", "");
							
							$$ = createRecord(s, $1->type);
							freeRecord($1);
							freeRecord($3);
							free(s);
						   }
	;

atomo : ID {
			int index = search($1);

			if(index == -1){
				$$ = createRecord($1, "");
			}else{
				$$ = createRecord($1, symbol_table[index].data_type);
			}
			free($1);
		   }
      | ID dims {	
					int index = search($1);

					char *s = cat($1, $2->code, "", "", "");

	  				if(index == -1){
						$$ = createRecord(s, "");
					}else{
						$$ = createRecord(s, symbol_table[index].data_type);
					}

					freeRecord($2);
					free(s);
	  		    }
	  | AMPERSAND ID {	
						int index = search($2);
						
						char *s = cat("&", $2, "", "", "");

						if(index == -1){
							$$ = createRecord(s, "");
						}else{
							$$ = createRecord(s, symbol_table[index].data_type);
						}
						free(s);
	  				 }
	  | MULT ID {	
					int index = search($2);

					char *s = cat("*", $2, "", "", "");

					if(index == -1){
						$$ = createRecord(s, "");
					}else{
						$$ = createRecord(s, symbol_table[index].data_type);
					}
					free(s);
	  			}
	  | ID DOT ID {	
					int index = search($3);
					char *s = cat($1, ".", $3, "", "");

					if(index == -1){
						$$ = createRecord(s, "");
					}else{
	  					$$ = createRecord(s, symbol_table[index].data_type);
					}
					free(s);
	  			  }
	  | MULT ID DOT ID {int index = search($4);
						char *s = cat("", $2, "->", $4, "");

						if(index == -1){
							$$ = createRecord(s, "");
						}else{
							$$ = createRecord(s, symbol_table[index].data_type);
						}
						free(s);
	  				   }
	  ;

dims : OPEN_BRACK CLOSE_BRACK {	char *s = cat("[", "]", "", "", "");
								$$ = createRecord(s, "");
								free(s);
							  }
	 | OPEN_BRACK CLOSE_BRACK dims {char *s = cat("[", "]", $3->code, "", "");
									freeRecord($3);
									$$ = createRecord(s, "");
									free(s);
	 							   }
	 | OPEN_BRACK value CLOSE_BRACK {	
										if(strcmp($2->type,"int") != 0){
											yyerror("O valor do tamanho de uma matriz tem que ser um inteiro");
										}

										char *s = cat("[", $2->code, "]", "", "");
										freeRecord($2);
										$$ = createRecord(s, "");
										free(s);
	 								}
     | OPEN_BRACK value CLOSE_BRACK dims {	
											if(strcmp($2->type,"int") != 0){
												yyerror("O valor do tamanho de uma matriz tem que ser um inteiro");
											}
											
											char *s = cat("[", $2->code, "]", $4->code, "");
											freeRecord($2);
											freeRecord($4);
											$$ = createRecord(s, "");
											free(s);
						 				 }
	 | OPEN_BRACK expr CLOSE_BRACK {
									if(strcmp($2->type,"int") != 0){
										yyerror("O valor do tamanho de uma matriz tem que ser um inteiro");
									}
									
									char *s = cat("[", $2->code, "]", "", "");
									freeRecord($2);
									$$ = createRecord(s, "");
									free(s);
	 							   }
     | OPEN_BRACK expr CLOSE_BRACK dims {	
											if(strcmp($2->type,"int") != 0){
												yyerror("O valor do tamanho de uma matriz tem que ser um inteiro");
											}

											char *s = cat("[", $2->code, "]", $4->code, "");
											freeRecord($2);
											freeRecord($4);
											$$ = createRecord(s, "");
											free(s);
	 									}
	 | OPEN_BRACK ID CLOSE_BRACK {	char *s = cat("[", $2, "]", "", "");
									$$ = createRecord(s, "");
									free(s);
	 							 }
     | OPEN_BRACK ID CLOSE_BRACK dims {	char *s = cat("[", $2, "]", $4->code, "");
										freeRecord($4);
										$$ = createRecord(s, "");
										free(s);
	 								  }
	 ;

p_values : expr {	char *s = cat($1->code, "", "", "", "");
					$$ = createRecord(s, $1->type);
					freeRecord($1);
					free(s);
				}
		 | expr COMMA p_values {
								if(strcmp($1->type, $3->type) !=  0){
									yyerror("Não pode ter ids juntos com tipos diferentes");
								}

								char *s = cat($1->code, ",", $3->code, "", "");
								
								$$ = createRecord(s, $1->type);
								freeRecord($1);
								freeRecord($3);
								free(s);
		 					   }
		 ;

expr : expr PLUS term {	
						if(!verificar_calculo_numero_float_int($1->type, $3->type)){
							yyerror("Não é possivel realizar operações matematicas entre esses tipos");
						}

						char *s = cat($1->code, "+", $3->code,"", "");
						
						$$ = createRecord(s, tipo_resultado_operacao($1->type, $3->type));
						freeRecord($1);
						freeRecord($3);
						free(s);
					  }
	 | expr MINUS term {

						if(!verificar_calculo_numero_float_int($1->type, $3->type)){
							yyerror("Não é possivel realizar operações matematicas entre esses tipos");
						}

						char *s = cat($1->code, "-", $3->code,"", "");
						
						$$ = createRecord(s, tipo_resultado_operacao($1->type, $3->type));
						freeRecord($1);
						freeRecord($3);
						free(s);	
	 				   }
	 | expr ADD_ASSIGN term {	
								if(!verificar_calculo_numero_float_int($1->type, $3->type)){
									yyerror("Não é possivel realizar operações matematicas entre esses tipos");
								}

								char *s = cat($1->code, "+=", $3->code,"", "");
							
								$$ = createRecord(s, tipo_resultado_operacao($1->type, $3->type));
								freeRecord($1);
								freeRecord($3);
								free(s);
	 					    }
	 | expr SUB_ASSIGN term {	
								if(!verificar_calculo_numero_float_int($1->type, $3->type)){
									yyerror("Não é possivel realizar operações matematicas entre esses tipos");
								}

								char *s = cat($1->code, "-=", $3->code,"", "");
								$$ = createRecord(s, tipo_resultado_operacao($1->type, $3->type));
								freeRecord($1);
								freeRecord($3);
								free(s);
	 						}
	 | term {	char *s = cat($1->code, "", "", "", "");
				$$ = createRecord(s, $1->type);
				freeRecord($1);
				free(s);
	 		}
	 ;

term : term MULT factor {	
							if(!verificar_calculo_numero_float_int($1->type, $3->type)){
								yyerror("Não é possivel realizar operações matematicas entre esses tipos");
							}
							
							char *s = cat($1->code, "*", $3->code, "", "");
							$$ = createRecord(s, tipo_resultado_operacao($1->type, $3->type));
							freeRecord($1);
							freeRecord($3);
							free(s);
						}
     | term DIV factor {
						if(!verificar_calculo_numero_float_int($1->type, $3->type)){
							yyerror("Não é possivel realizar operações matematicas entre esses tipos");
						}

						char *s = cat($1->code, "/", $3->code, "", "");
						$$ = createRecord(s, tipo_resultado_operacao($1->type, $3->type));
						freeRecord($1);
						freeRecord($3);
						free(s);
	 				   }
	 | term MODULE factor {	

							if(!verificar_calculo_numero_float_int($1->type, $3->type)){
								yyerror("Não é possivel realizar operações matematicas entre esses tipos");
							}
		
							char *s = cat($1->code, "%", $3->code, "", "");
							$$ = createRecord(s, tipo_resultado_operacao($1->type, $3->type));
							freeRecord($1);
							freeRecord($3);
							free(s);
	 					  }
	 | factor { char *s = cat($1->code, "", "", "", "");
				$$ = createRecord(s, $1->type);
				freeRecord($1);
				free(s);
			  }
	 ;

factor : OPEN_PAREN expr CLOSE_PAREN {	char *s = cat("(", $2->code, ")", "", "");
										$$ = createRecord(s, $2->type);
										freeRecord($2);
										free(s);
									 }
       | atomo {	verificar_ids_validos($1->code, tag_text);
					$$ = createRecord($1->code, $1->type);
	   				freeRecord($1);
	   		   }
	   | TRUE {
				$$ = createRecord("true", "boolean");
	   		  }
	   | FALSE {
				$$ = createRecord("false", "boolean");
	   		   }
	   | ID INCREMENT{ 	
						int index = search($1);

						if(index == -1){
							yyerror("Variavel não encontrada");
						}

						verificar_ids_validos($1, tag_text);

						if(strcmp(symbol_table[index].data_type, "int") != 0 &&
								strcmp(symbol_table[index].data_type,"float") != 0 ){
							yyerror("Essa operação só é permitida para int ou float");	
						}

						char *s = cat($1,"++","","","");
						free($1);
						$$ = createRecord(s, symbol_table[index].data_type);
						free(s);
	   				 }
	   | ID DECREMENT{ 	
						int index = search($1);

						verificar_ids_validos($1, tag_text);

						if(index == -1){
							yyerror("Variavel não encontrada");
						}

						if(strcmp(symbol_table[index].data_type, "int") != 0 &&
								strcmp(symbol_table[index].data_type,"float") != 0 ){
							yyerror("Essa operação só é permitida para int ou float");	
						}

						char *s = cat($1,"--","","","");
						$$ = createRecord(s, symbol_table[index].data_type);
						free($1);
						free(s);
	   				 }
	   | function_call {char *s = cat($1->code, "", "", "", "");
						if(strcmp($1->type, "")==0){
							$$ = createRecord(s, "null");
						}else{
							$$ = createRecord(s, $1->type);
						}
						freeRecord($1);	 
						free(s);
	   				   }
	   | value {char *s = cat($1->code, "", "", "", "");
				$$ = createRecord(s, $1->type);
				freeRecord($1);
				free(s);
	   		   }
	   | OPEN_PAREN type CLOSE_PAREN MALLOC OPEN_PAREN type CLOSE_PAREN {	char *s = cat( "(", $2->code ,") malloc(sizeof(", $6->code, "))");
	   																		$$ = createRecord(s, $2->type);
																			freeRecord($2);
																			freeRecord($6);
																			free(s);
	   																	}
	   | OPEN_PAREN STRUCT ID MULT CLOSE_PAREN MALLOC OPEN_PAREN STRUCT ID CLOSE_PAREN {	char * s = cat("struct ", $3, " *", "", "");
																							char *s1 = cat("(struct ", $3, " *) malloc(sizeof(struct ", $9, "))");
																							$$ = createRecord(s1, "");
																							free(s);
																							free(s1);
																					   }
	   ;
value : INT_NUMBER {char *s = cat($1,"","","","");
					$$ = createRecord(s, "int");
					free(s);	
				   }
      | FLOAT_NUMBER {	char *s = cat($1,"","","","");
						$$ = createRecord(s, "float");
						free(s);
	  				 }
	  | STRING_VALUE {	char *s = cat($1,"","","","");
						$$ = createRecord(s, "string");
						free(s);
	  				 }
	  | NULL_VALUE {char *s = cat("NULL","","","","");
					$$ = createRecord(s, "null");
					free(s);
	  			   }
	  ;

assigns : assign_def {	char *s = cat($1->code, "", "", "", "");
						
						$$ = createRecord(s, $1->type);
						freeRecord($1);	 
						free(s);
					 }
        | assign_mat {	char *s = cat($1->code, "", "", "", "");
						freeRecord($1);	 
						$$ = createRecord(s, "");
						free(s);
					 }
		| assign_def assigns {	char *s = cat($1->code, $2->code, "", "", "");
								
								$$ = createRecord(s, $1->type);
								freeRecord($1);
								freeRecord($2);
								free(s);
							 }
		;

assign_def : ID ASSIGN expr SEMI {	
									
									int index = search($1);

									if(index == -1){
										yyerror("Variavel não encontrada");
									}
									
									char *s = cat($1, "=", $3->code, ";", "");

									if(strcmp(symbol_table[index].data_type, "string") == 0 && strcmp($3->type, "string") == 0){
										$$ = createRecord(s, "string");
									}else if(strcmp(symbol_table[index].data_type, $3->type) == 0){
										$$ = createRecord(s, symbol_table[index].data_type);
									}else if(strcmp($3->type, "null")==0){
										$$ = createRecord(s, symbol_table[index].data_type);
									}
									else if(strcmp(symbol_table[index].data_type, "boolean") == 0 && strcmp($3->type, "boolean") == 0){
										$$ = createRecord(s, "boolean");
									} else if(verificar_calculo_numero_float_int(symbol_table[index].data_type, $3->type)){
										$$ = createRecord(s, tipo_resultado_operacao(symbol_table[index].data_type, $3->type));
									}else {
										yyerror("Tipos incompativeis");
									}

									freeRecord($3);
									free(s);
								 }
			|	MULT ID ASSIGN expr SEMI {	
										int index = search($2);

										if(index == -1){
											yyerror("Variavel não encontrada");
										}
										
										char *s = cat("*", $2, "=", $4->code, ";");

										if(strcmp(symbol_table[index].data_type, $4->type) == 0){
											$$ = createRecord(s, symbol_table[index].data_type);
										}else if(strcmp($4->type, "null")==0){
											$$ = createRecord(s, symbol_table[index].data_type);
										}else if(strcmp(symbol_table[index].data_type, "string") == 0 && strcmp($4->type, "string") == 0){
											$$ = createRecord(s, "string");
										}
										else if(strcmp(symbol_table[index].data_type, "boolean") == 0 && strcmp($4->type, "boolean") == 0){
											$$ = createRecord(s, "boolean");
										} else if(verificar_calculo_numero_float_int(symbol_table[index].data_type, $4->type)){
											$$ = createRecord(s, tipo_resultado_operacao(symbol_table[index].data_type, $4->type));
										}else {
											yyerror("Tipos incompativeis");
										}

										freeRecord($4);
										free(s);
								 	}
			|	ID DOT ID ASSIGN expr SEMI {	
									
									int index = search($3);

									if(index == -1){
										yyerror("Variavel não encontrada");
									}
									char *s1 = cat($1, ".", $3, "=", $5->code);
									char *s2 = cat(s1, ";", "", "", "");

									if(strcmp(symbol_table[index].data_type, $5->type) == 0){
										$$ = createRecord(s2, symbol_table[index].data_type);
									}else if(strcmp($5->type, "null")==0){
										$$ = createRecord(s2, symbol_table[index].data_type);
									}else if(strcmp(symbol_table[index].data_type, "string") == 0 && strcmp($5->type, "string") == 0){
										$$ = createRecord(s2, "string");
									}
									else if(strcmp(symbol_table[index].data_type, "boolean") == 0 && strcmp($5->type, "boolean") == 0){
										$$ = createRecord(s2, "boolean");
									} else if(verificar_calculo_numero_float_int(symbol_table[index].data_type, $5->type)){
										$$ = createRecord(s2, tipo_resultado_operacao(symbol_table[index].data_type, $5->type));
									}else {
										yyerror("Tipos incompativeis");
									}

									freeRecord($5);
									free(s2);
									free(s1);
								 }
			|	MULT ID DOT ID ASSIGN expr SEMI {	int index = search($4);

													if(index == -1){
														yyerror("Variavel não encontrada");
													}
													char *s1 = cat("", $2, "->", $4, "=");
													char *s2 = cat(s1, $6->code, ";", "", "");

													if(strcmp(symbol_table[index].data_type, $6->type) == 0){
														$$ = createRecord(s2, symbol_table[index].data_type);
													}else if(strcmp($6->type, "null")==0){
														$$ = createRecord(s2, symbol_table[index].data_type);
													}
													else if(strcmp(symbol_table[index].data_type, "string") == 0 && strcmp($6->type, "string") == 0){
														$$ = createRecord(s2, "string");
													}
													else if(strcmp(symbol_table[index].data_type, "boolean") == 0 && strcmp($6->type, "boolean") == 0){
														$$ = createRecord(s2, "boolean");
													} else if(verificar_calculo_numero_float_int(symbol_table[index].data_type, $6->type)){
														$$ = createRecord(s2, tipo_resultado_operacao(symbol_table[index].data_type, $6->type));
													}else {
														yyerror("Tipos incompativeis");
													}

													freeRecord($6);
													free(s2);
													free(s1);
												}
           ;	

assign_mat : ID dims ASSIGN expr SEMI {	char *s = cat($1, $2->code, "=", $4->code, ";");
										freeRecord($2);
										freeRecord($4);
										$$ = createRecord(s, "");
										free(s);
									  }
		   | ID dims ASSIGN ID dims SEMI {	char *s1 = cat($1, $2->code, "=", $4, $5->code);
											char *s2 = cat(s1, ";", "", "", "");
											freeRecord($2);
											freeRecord($5);
											$$ = createRecord(s2, "");
											free(s2);
											free(s1);
		   								 }
           ;

subprograms : subprogram { 	char *s = cat($1->code, "", "", "", "");
							freeRecord($1);
							$$ = createRecord(s, "");
							free(s);
						}
			| subprogram subprograms {	char *s = cat($1->code, "", $2->code, "", "");
										freeRecord($1);
										freeRecord($2);
										$$ = createRecord(s, "");
										free(s);
									 }
			;

subprogram : proc { char *s = cat($1->code, "", "", "", "");
					freeRecord($1);
					$$ = createRecord(s, "");
					free(s);
				  }
		   | function {	char *s = cat($1->code, "", "", "", "");
						$$ = createRecord(s, $1->type);
						freeRecord($1);
						free(s);
		   			  }
		   ;

proc : VOID ID OPEN_PAREN params CLOSE_PAREN BLOCK_BEGIN stmts BLOCK_END {	add('P', $2);
																			insert_tag_text($2);
																			char *s1 = cat("void ", $2, "(", $4->code, ")");
																			char *s2 = cat(s1, "{\n", $7->code, "\n}", "");
																			freeRecord($4);
																			freeRecord($7);
																			$$ = createRecord(s2, "");
																			free(s2);
																			free(s1);
																		 }
	 | VOID ID OPEN_PAREN CLOSE_PAREN BLOCK_BEGIN stmts BLOCK_END {	add('P', $2);
																	insert_tag_text($2);
																	char *s = cat("void ", $2, "(){\n", $6->code, "\n}");
	 																freeRecord($6);
																	$$ = createRecord(s, "");
																	free(s);
	 															  }
	 ;
	 
	
function : type ID OPEN_PAREN params CLOSE_PAREN BLOCK_BEGIN stmts RETURN factor SEMI BLOCK_END {	add('F', $2);
																									insert_tag_text($2);
																									int index = search($2);

																									if(strcmp(symbol_table[index].data_type, $9->type)!=0){
																										if(verificar_calculo_numero_float_int(symbol_table[index].data_type, $9->type) == 0){
																											yyerror("Retorn incompativel com o tipo da funcao");
																										}
																									}

																									char *s1 = cat($1->code, " ", $2, "(", $4->code);
																									char *s2 = cat(s1, "){\n", $7->code, "\nreturn ", $9->code);
																									char *s3 = cat(s2, ";\n}", "", "", "");
																									
																									$$ = createRecord(s3, $1->code);
																									freeRecord($1);
																									freeRecord($4);
																									freeRecord($7);
																									freeRecord($9);
																									free(s3);
																									free(s2);
																									free(s1);
																									
																								}
		 | type ID OPEN_PAREN CLOSE_PAREN BLOCK_BEGIN stmts RETURN factor SEMI BLOCK_END {	add('F', $2);
		 																					insert_tag_text($2);
																							int index = search($2);
																							if(strcmp(symbol_table[index].data_type, $8->type)!=0){
																								if(verificar_calculo_numero_float_int(symbol_table[index].data_type, $8->type) == 0){
																									yyerror("Retorn incompativel com o tipo da funcao");
																								}
																							}


																							char *s1 = cat($1->code, " ", $2, "(){\n", $6->code);
																							char *s2 = cat(s1, "\nreturn ", $8->code, ";\n}", "");
																							
																							$$ = createRecord(s2, $1->code);
																							freeRecord($1);
																							freeRecord($6);
																							freeRecord($8);
																							free(s2);
																							free(s1);
																						 }
		 | STRUCT ID ID OPEN_PAREN params CLOSE_PAREN BLOCK_BEGIN stmts RETURN factor SEMI BLOCK_END {
																										insert_tag_text($3);

																										char * s = cat("struct ", $2, "", "", "");
																										insert_type("struct");
																										add('F', $3);
																										int index = search($3);
																										if(strcmp(symbol_table[index].data_type, $10->type)!=0){
																											if(verificar_calculo_numero_float_int(symbol_table[index].data_type, $10->type) == 0){
																												yyerror("Retorn incompativel com o tipo da funcao");
																											}
																										}


																										char *s1 = cat("struct ", $2, " ", $3, "(");
																										char *s2 = cat(s1, $5->code, "){\n", $8->code, "\nreturn ");
																										char *s3 = cat(s2, $10->code, ";\n}", "", "");
																										
																										$$ = createRecord(s3, s);
																										freeRecord($5);
																										freeRecord($8);
																										freeRecord($10);
																										free(s3);
																										free(s2);
																										free(s1);
																										free(s);
																									 }
		 | STRUCT ID ID OPEN_PAREN CLOSE_PAREN BLOCK_BEGIN stmts RETURN factor SEMI BLOCK_END {	
																								insert_tag_text($3);
																								char * s = cat("struct ", $2, "", "", "");
																								insert_type("struct");
																								add('F', $3);
																								int index = search($3);
																								if(strcmp(symbol_table[index].data_type, $9->type)!=0){
																									if(verificar_calculo_numero_float_int(symbol_table[index].data_type, $9->type) == 0){
																										yyerror("Retorn incompativel com o tipo da funcao");
																									}
																								}
																								char *s1 = cat("struct ", $2, " ", $3, "(");
																								char *s2 = cat(s1, "", "){\n", $7->code, "\nreturn ");
																								char *s3 = cat(s2, $9->code, ";\n}", "", "");
																								
																								$$ = createRecord(s3, s);
																								freeRecord($7);
																								freeRecord($9);
																								free(s3);
																								free(s2);
																								free(s1);
																								free(s);
																							  }
		 | STRUCT ID MULT ID OPEN_PAREN params CLOSE_PAREN BLOCK_BEGIN stmts RETURN factor SEMI BLOCK_END {	
																											insert_tag_text($4);
																											char * s = cat("struct ", $2, "", "", "");
																											insert_type("struct");
																											add('F', $4);
																											int index = search($4);
																											if(strcmp(symbol_table[index].data_type, $11->type)!=0){
																												if(verificar_calculo_numero_float_int(symbol_table[index].data_type, $11->type) == 0){
																													yyerror("Retorn incompativel com o tipo da funcao");
																												}
																											}
																											char *s1 = cat("struct ", $2, " * ", $4, "(");
																											char *s2 = cat(s1, $6->code, "){\n", $9->code, "\nreturn ");
																											char *s3 = cat(s2, $11->code, ";\n}", "", "");
																											
																											$$ = createRecord(s3, s);
																											freeRecord($6);
																											freeRecord($9);
																											freeRecord($11);
																											free(s3);
																											free(s2);
																											free(s1);
																											free(s);
																										  }
		 | STRUCT ID MULT ID OPEN_PAREN CLOSE_PAREN BLOCK_BEGIN stmts RETURN factor SEMI BLOCK_END {
																									insert_tag_text($4);	
																									char * s = cat("struct ", $2, "", "", "");
																									insert_type("struct");
																									add('F', $4);
																									int index = search($4);
																									if(strcmp(symbol_table[index].data_type, $10->type)!=0){
																										if(verificar_calculo_numero_float_int(symbol_table[index].data_type, $10->type) == 0){
																											yyerror("Retorn incompativel com o tipo da funcao");
																										}
																									}
																									char *s1 = cat("struct ", $2, " * ", $4, "(");
																									char *s2 = cat(s1, "", "){\n", $8->code, "\nreturn ");
																									char *s3 = cat(s2, $10->code, ";\n}", "", "");
																									
																									$$ = createRecord(s3, s);
																									freeRecord($8);
																									freeRecord($10);
																									free(s3);
																									free(s2);
																									free(s1);
																									free(s);
																								   }
	     ;

params : param {char *s = cat($1->code, "", "", "", "");
				freeRecord($1);
				$$ = createRecord(s, "");
				free(s);
			   }
	   | param COMMA params {	char *s = cat($1->code, ",", $3->code, "", "");
								freeRecord($1);
								freeRecord($3);
								$$ = createRecord(s, "");
								free(s);
			   				}
	   ;

param : type dims ID {	
						add('V', $3);
						char *s = cat($1->code, " ", $2->code, $3, "");
						
						$$ = createRecord(s, $1->code);
						freeRecord($1);
						freeRecord($2);
						free(s);
					 }
	  | type ID dims {	
						add('V', $2);
						char *s = cat($1->code, " ", $2, $3->code, "");
						
						$$ = createRecord(s, $1->code);
						freeRecord($1);
						freeRecord($3);
						free(s);
					 }
	  | type ID {	add('V', $2);
					char *s = cat($1->code, " ", $2, "", "");
					
					$$ = createRecord(s, $1->code);
					freeRecord($1);
					free(s);
			    }
	  |	STRUCT ID ID {	char * s = cat("struct", " ", $2, " ", $3);	
						insert_type("struct");
						add('V', $3);
						$$ = createRecord(s, $2);
						free(s);
					 }
	  |	STRUCT ID MULT ID {	char * s = cat("struct", " ", $2, " * ", $4);	
							insert_type("struct");
							add('V', $4);
							$$ = createRecord(s, $2);
							free(s);
						  }
	  | type MULT ID {	char *s = cat($1->code, " *", $3, "", "");
						add('V', $3);
						$$ = createRecord(s, $1->code);
						freeRecord($1);
						free(s);
	 				 }
	  ;

stmts : stmt {	char *s = cat($1->code, "", "", "", "");
				freeRecord($1);
				$$ = createRecord(s, "");
				free(s);
			 }
      | stmt stmts {char *s = cat($1->code, "\n", $2->code, "", "");
					freeRecord($1);
					freeRecord($2);
					$$ = createRecord(s, "");
					free(s);
				   }
	  ;

stmt : dec_var {char *s = cat($1->code, "", "", "", "");
				freeRecord($1);
				$$ = createRecord(s, "");
				free(s);
			   }
     | assigns {char *s = cat($1->code, "", "", "", "");
				freeRecord($1);
				$$ = createRecord(s, "");
				free(s);
	 		   }
	 | function_call {	char *s = cat($1->code, "", "", "", "");
						freeRecord($1);
						$$ = createRecord(s, "");
						free(s);
	 				 }
     | conditional_stmt {	char *s = cat($1->code, "", "", "", "");
							freeRecord($1);
							$$ = createRecord(s, "");
							free(s);
	 					}
	 | iteration_stmt {	char *s = cat($1->code, "", "", "", "");
						freeRecord($1);
						$$ = createRecord(s, "");
						free(s);
	 				  }
	 | scan_stmt {	char *s = cat($1->code, "", "", "", "");
					freeRecord($1);
					$$ = createRecord(s, "");
					free(s);

	 			 }
	 | print_stmt {	char *s = cat($1->code, "", "", "", "");
					freeRecord($1);
					$$ = createRecord(s, "");
					free(s);
	 			  }
	 | fre_stmt {	char *s = cat($1->code, "", "", "", "");
	 				freeRecord($1);
					$$ = createRecord(s, "");
					free(s);
	 			}
	 ;

fre_stmt: FREE OPEN_PAREN atomo CLOSE_PAREN SEMI {
													char * s = cat("free(", $3->code, ");", "", "");
													freeRecord($3);
													$$ = createRecord(s, "");
													free(s);
												 }

scan_stmt: SCAN OPEN_PAREN atomo CLOSE_PAREN SEMI {
												char *s;

												if(strcmp($3->type, "int") == 0){
													s = cat("scanf(\"%d\",&", $3->code, ");", "", "");
												}else if(strcmp($3->type, "float") == 0){
													s = cat("scanf(\"%f\",&", $3->code, ");", "", "");
												}else if(strcmp($3->type, "string") == 0){
													s = cat("scanf(\"%s\",", $3->code, ");", "", "");
												}else{
													s = "";
													yyerror("Tipo invalido para o print");
												}
												freeRecord($3);
												$$ = createRecord(s, "");
												free(s);
											   }
		 ;

print_stmt: PRINT OPEN_PAREN print_content CLOSE_PAREN SEMI {	
																char * s;
																if(strcmp($3->type, "int") == 0){
																	s = cat("printf(\"%i\\n\",", $3->code, ");", "", "");
																}else if(strcmp($3->type, "float") == 0){
																	s = cat("printf(\"%f\\n\",", $3->code, ");", "", "");
																}else if(strcmp($3->type, "string") == 0){
																	s = cat("printf(", $3->code, ");", "", "");
																}else{
																	s = "";
																	yyerror("Tipo invalido para o print");
																}
																
																freeRecord($3);
																$$ = createRecord(s, "");
																free(s);
															}
		  | PRINT OPEN_PAREN CLOSE_PAREN SEMI {	char *s = cat("printf(\"\\n\");", "", "", "", "");
		  										$$ = createRecord(s, "");
												free(s);
		  									  }
		  ;

print_content: expr { 	char *s = cat($1->code, "", "", "", "");
						$$ = createRecord(s, $1->type);
						freeRecord($1);
						free(s);
					}
			 | print_content PLUS expr {char *s = cat($1->code, " + ", $3->code, "", "");
										freeRecord($1);
										freeRecord($3);
										$$ = createRecord(s, "");
										free(s);
			 						   }
			 | STRING_VALUE PLUS print_content {char *s = cat($1, " + ", $3->code, "", "");
												freeRecord($3);
												$$ = createRecord(s, "");
												free(s);
			 								   }
			 ;

conditional_stmt : if_stmt {char *s = cat($1->code, "", "", "", "");
							freeRecord($1);
							$$ = createRecord(s, "");
							free(s);	
						   }
				 | switch_stmt {char *s = cat($1->code, "", "", "", "");
								freeRecord($1);
								$$ = createRecord(s, "");
								free(s);
				 			   }
				 ;

if_stmt : IF OPEN_PAREN logic_expr CLOSE_PAREN BLOCK_BEGIN stmts BLOCK_END {char *s = cat("if(", $3->code, "){\n", $6->code, "\n}");
																			freeRecord($3);
																			freeRecord($6);
																			$$ = createRecord(s, "");
																			count_label++;
																			free(s);
																		   }
		| IF OPEN_PAREN logic_expr CLOSE_PAREN BLOCK_BEGIN stmts BLOCK_END ELSE BLOCK_BEGIN stmts BLOCK_END { 
																												char str[20];
																												sprintf(str, "%d", count_label);

																												char * label = cat("conditionOk", str, "", "", "");
																												char *s1 = cat("if(", $3->code, "){\n", $6->code, "goto ");
																												char *s2 = cat(s1, label, "; \n}", $10->code, "\n");
																												char *s3 = cat(s2, label, ":", "", "");
																												freeRecord($3);
																												freeRecord($6);
																												freeRecord($10);
																												$$ = createRecord(s3, "");
																												count_label++;
																												free(s3);
																												free(s2);
																												free(s1);
																											}
		| IF OPEN_PAREN logic_expr CLOSE_PAREN BLOCK_BEGIN stmts BLOCK_END else_if_stmt ELSE BLOCK_BEGIN stmts BLOCK_END {	
																															char str[20];
																															sprintf(str, "%d", count_label);

																															char * label = cat("conditionOk", str, "", "", "");

																															char *s1 = cat("if(", $3->code, "){\n", $6->code, "goto ");
																															char *s2 = cat(s1, label, ";\n} ", $8->code, "\n");	
																															char *s3 = cat(s2, $11->code, "\n ", label, ":");
																															freeRecord($3);
																															freeRecord($6);
																															freeRecord($8);
																															freeRecord($11);
																															$$ = createRecord(s3, "");
																															count_label++;
																															free(s3);
																															free(s2);
																															free(s1);
																														 }
		| IF OPEN_PAREN logic_expr CLOSE_PAREN BLOCK_BEGIN stmts BLOCK_END else_if_stmt {	
																							char str[20];
																							sprintf(str, "%d", count_label);

																							char * label = cat("conditionOk", str, "", "", "");
			
																							char *s1 = cat("if(", $3->code, "){\n", $6->code, "goto ");
																							char *s2 = cat(s1, label, ";\n}", $8->code, " ");
																							char *s3 = cat(s2, label, ":", "", "");
																							freeRecord($3);
																							freeRecord($6);
																							freeRecord($8);
																							$$ = createRecord(s3, "");
																							count_label++;
																							free(s3);
																							free(s2);
																							free(s1);
																						}
		;

else_if_stmt : ELSE_IF OPEN_PAREN logic_expr CLOSE_PAREN BLOCK_BEGIN stmts BLOCK_END {	char str[20];
																						sprintf(str, "%d", count_label);

																						char * label = cat("conditionOk", str, "", "", "");

																						char *s1 = cat("if(", $3->code, "){\n", $6->code, " goto ");
																						char *s2 = cat(s1, label, ";", " \n}", "");
																						freeRecord($3);
																						freeRecord($6);
																						$$ = createRecord(s2, "");
																						free(s2);
																						free(s1);
																					 }
			 | else_if_stmt else_if_stmt {	char *s = cat($1->code, $2->code, "", "", "");
			 								freeRecord($1);
											freeRecord($2);
											$$ = createRecord(s, "");
											free(s);
			 							 }
			 ;

logic_expr : logic_expr logic_op c_term {	char *s = cat($1->code, $2->code, $3->code, "", "");
											freeRecord($1);
											freeRecord($2);
											freeRecord($3);
											$$ = createRecord(s, "");
											free(s);
										}
		   | c_term {	char *s = cat($1->code, "", "", "", "");
		   				freeRecord($1);
						$$ = createRecord(s, "");
						free(s);
		   			}
		   ;

c_term : ID {	$$ = createRecord($1, "");
				free($1);
			}
	   | ID dims {char *s= cat($1,$2->code,"","","");
					freeRecord($2);
					$$ = createRecord(s,"");
					free(s);
	   			}
	   | TRUE {		char *s= cat("true","","","","");
					$$ = createRecord(s,"");
					free(s);
			}
	   | FALSE {	char *s= cat("false","","","","");
					$$ = createRecord(s,"");
					free(s);

	   }
	   | comp {	char *s= cat($1->code,"","","","");
					freeRecord($1);
					$$ = createRecord(s,"");
					free(s);

	   }
	   ;

comp: expr comp_op expr {	char *s = cat($1->code, $2->code, $3->code, "", "");
							freeRecord($1);
							freeRecord($2);
							freeRecord($3);
							$$ = createRecord(s, "");
							free(s);
						}
	;

comp_op : EQ {	char *s = cat("==", "", "", "", "");
				$$ = createRecord(s, "");
				free(s);
			 }
		| NEQ {	char *s = cat("!=", "", "", "", "");
				$$ = createRecord(s, "");
				free(s);
			  }
		| GE {	char *s = cat(">=", "", "", "", "");
				$$ = createRecord(s, "");
				free(s);
			 }
		| LE {	char *s = cat("<=", "", "", "", "");
				$$ = createRecord(s, "");
				free(s);
			 }
		| GT {	char *s = cat(">", "", "", "", "");
				$$ = createRecord(s, "");
				free(s);
			 }
		| LT {	char *s = cat("<", "", "", "", "");
				$$ = createRecord(s, "");
				free(s);
			 }
		;

logic_op : AND {char *s = cat("&&", "", "", "", "");
				$$ = createRecord(s, "");
				free(s);
			   }
		 | OR {	char *s = cat("||", "", "", "", "");
				$$ = createRecord(s, "");
				free(s);
		 	  }
		 | NOT {char *s = cat("!", "", "", "", "");
				$$ = createRecord(s, "");
				free(s);
		 	   }
		 ;

switch_stmt : SWITCH COLON OPEN_PAREN ID CLOSE_PAREN BLOCK_BEGIN switch_cases DEFAULT COLON stmts BLOCK_END {	char *s1 = cat("switch: (", $4, "){\n", $7->code, "	default:\n");
																												char *s2 = cat(s1, $10->code, "\n}", "", "");
																												freeRecord($7);
																												freeRecord($10);
																												$$ = createRecord(s2, "");
																												free(s2);
																												free(s1);
													  														}
		    ;

switch_cases : {$$ = createRecord("","");}
			 | CASE value COLON stmts BREAK switch_cases {	char *s1 = cat("case ", $2->code, ":\n", $4->code, "\n");
			 												char *s2 = cat(s1, $6->code, "", "", "");
															freeRecord($2);
															freeRecord($4);
															freeRecord($6);
															$$ = createRecord(s2, "");
															free(s2);
															free(s1);
			 											 }
			 ;

iteration_stmt : while_stmt {	char *s = cat($1->code, "", "", "", "");
		   						freeRecord($1);
								$$ = createRecord(s, "");
								free(s);
							}
			   | for_stmt {	char *s = cat($1->code, "", "", "", "");
		   					freeRecord($1);
							$$ = createRecord(s, "");
							free(s);
			   			  }
			   | dowhile_stmt {	char *s = cat($1->code, "", "", "", "");
		   						freeRecord($1);
								$$ = createRecord(s, "");
								free(s);
			   				  }
			   ;

while_stmt : WHILE OPEN_PAREN logic_expr CLOSE_PAREN BLOCK_BEGIN stmts BLOCK_END {	char *s = cat("whileLoop: if(", $3->code, "){\n", $6->code, "goto whileLoop;\n}");
																					freeRecord($3);
																					freeRecord($6);
																					$$ = createRecord(s, "");
																					free(s);
																				 }
		   ;

for_stmt : FOR OPEN_PAREN dec_var logic_expr SEMI expr CLOSE_PAREN BLOCK_BEGIN stmts BLOCK_END {
																								char str[20];
																								sprintf(str, "%d", count_label);

																								char * label = cat("forLoop", str, "", "", "");

																								char *s1 = cat($3->code, label, ":\nif(", $4->code, "){\n");
																								char *s2 = cat(s1, $6->code, ";\n", $9->code, "goto ");
																								char *s3 = cat(s2, label, ";\n}", "", "");
																								freeRecord($3);
																								freeRecord($4);
																								freeRecord($6);
																								freeRecord($9);
																								$$ = createRecord(s3, "");
																								free(label);
																								free(s3);
																								free(s2);
																								free(s1);
																								count_label++;
																							   }
		 ;

dowhile_stmt : DO BLOCK_BEGIN stmts BLOCK_END WHILE OPEN_PAREN logic_expr CLOSE_PAREN SEMI {char *s1 = cat($3->code, "doWhile: if(", $7->code, "){", $3->code);
																							char *s2 = cat("} goto doWhile;", "", "", "", "");
																							freeRecord($3);
																							freeRecord($7);
																							$$ = createRecord(s2, "");
																							free(s1);
																							free(s2);
																						   }
             ;

function_call : ID OPEN_PAREN args CLOSE_PAREN {	
												int index = search($1);

												char *s = cat($1, "(", $3->code, ")", "");

												freeRecord($3);
												if(index != -1){
													$$ = createRecord(s, symbol_table[index].data_type);
												}else {
													$$ = createRecord(s, "");
												}
												free(s);
											}
			| ID OPEN_PAREN CLOSE_PAREN {	
										int index = search($1);

										char *s = cat($1, "()", "", "", "");

										if(index != -1){
											$$ = createRecord(s, symbol_table[index].data_type);
										}else {
											$$ = createRecord(s, "");
										}
										free(s);
										}


			| ID OPEN_PAREN args CLOSE_PAREN SEMI {	
														int index = search($1);

														char *s = cat($1, "(", $3->code, ");", "");

														freeRecord($3);
														if(index != -1){
															$$ = createRecord(s, symbol_table[index].data_type);
														}else {
															$$ = createRecord(s, "");
														}
														free(s);
													}
             | ID OPEN_PAREN CLOSE_PAREN SEMI {	
												int index = search($1);

												char *s = cat($1, "();", "", "", "");

												if(index != -1){
													$$ = createRecord(s, symbol_table[index].data_type);
												}else {
													$$ = createRecord(s, "");
												}
												free(s);
											  }
			 ;

args : arg {char *s = cat($1->code,"","","","");
			freeRecord($1);
			$$ = createRecord(s, "");
			free(s);
	 	   }
	 ;

arg : ids {	char *s = cat($1->code,"","","","");
			freeRecord($1);
			$$ = createRecord(s, "");
			free(s);
	 	  }
	;

principal : MAIN OPEN_PAREN params CLOSE_PAREN BLOCK_BEGIN stmts BLOCK_END {
																			insert_tag_text("main");
																			add('M', "main");
																			char *s = cat("int main(", $3->code, "){\n", $6->code, "\nreturn 0;\n}");
																			freeRecord($3);
																			freeRecord($6);
																			$$ = createRecord(s, "");
																			free(s);
																		   }
		  | MAIN OPEN_PAREN CLOSE_PAREN BLOCK_BEGIN stmts BLOCK_END	{	insert_tag_text("main");
																		add('M', "main");
																		char *s = cat("int main(){\n", $5->code, "\nreturn 0;\n}", "", "");
		  																freeRecord($5);
																		$$ = createRecord(s, "");
																		free(s);
		  															}
          ;

%% /* Fim da segunda seção */

int main (int argc, char ** argv) {
 	int codigo;

    if (argc != 3) {
       printf("Usage: $./compiler input.txt output.txt\nClosing application...\n");
       exit(0);
    }
    
    yyin = fopen(argv[1], "r");
    yyout = fopen(argv[2], "w");

    codigo = yyparse();

    fclose(yyin);
    fclose(yyout);

	printf("\nSymble Table \n");
	printf("\nSYMBOL	DATATYPE	TYPE	LINE NUMBER 	SCOPE		TAG\n");
	printf("________________________________________________________________\n\n");
	int i = 0;
	for(i = 0; i < count; i++){
		printf("%s\t%s\t\t%s\t%d\t%d\t%s\t\n", 
			symbol_table[i].id_name, 
			symbol_table[i].data_type, 
			symbol_table[i].type,
			symbol_table[i].line_no,
			symbol_table[i].scope,
			symbol_table[i].tag);
	}

	for(i = 0; i < count; i++){
		free(symbol_table[i].id_name);
		free(symbol_table[i].type);
	}

	return codigo;
}

int yyerror (char *msg) {
	fprintf (stderr, "%d: %s at '%s'\n", yylineno, msg, yytext);
	return 0;
}

char * cat(char * s1, char * s2, char * s3, char * s4, char * s5){
  int tam;
  char * output;

  tam = strlen(s1) + strlen(s2) + strlen(s3) + strlen(s4) + strlen(s5)+ 1;
  output = (char *) malloc(sizeof(char) * tam);
  
  if (!output){
    printf("Allocation problem. Closing application...\n");
    exit(0);
  }
  
  sprintf(output, "%s%s%s%s%s", s1, s2, s3, s4, s5);
  
  return output;
}

int search(char *type) {
	int i;
	for(i=count-1; i>=0; i--) {
		if(strcmp(symbol_table[i].id_name, type) == 0) {
			if(strcmp(symbol_table[i].type, "Variable") == 0){
				if((strcmp(symbol_table[i].tag, tag_text) == 0) || (strcmp(symbol_table[i].tag, "global") == 0)){
					return i;
				}else {
					return -1;
				}
			}
			return i;
			break;
		}
	}

	return -1;
}

int verificar_variavel_existe(char * name, char * tag) {
	int i;
	for(i=count-1; i>=0; i--) {
		if(strcmp(symbol_table[i].id_name, name) == 0	
			&& (strcmp(symbol_table[i].tag, tag) == 0 || strcmp(symbol_table[i].tag, "global") == 0)) {
				return i;
				break;
				
		}
	}

	return -1;
}

void add(char symbol, char * id_name){
	q=search(id_name);
	if(q == -1) {
		if(symbol == 'H'){
			symbol_table[count].id_name = strdup(id_name);
			symbol_table[count].data_type = strdup(type);
			symbol_table[count].line_no = countn;
			symbol_table[count].type = strdup("Header");
			symbol_table[count].scope = count_block;
			symbol_table[count].tag = strdup("N/A");
			count++;
		} else if(symbol == 'K'){
			symbol_table[count].id_name = strdup(id_name);
			symbol_table[count].data_type = strdup("N/A");
			symbol_table[count].line_no = countn;
			symbol_table[count].type = strdup("Keyword\t");
			symbol_table[count].scope = count_block;
			symbol_table[count].tag = strdup("N/A");
			count++;
		} else if(symbol == 'V'){
			symbol_table[count].id_name = strdup(id_name);
			symbol_table[count].data_type = strdup(type);
			symbol_table[count].line_no = countn;
			symbol_table[count].type = strdup("Variable");
			symbol_table[count].scope = count_block;
			if(strcmp(tag_text,"")!=0){
				symbol_table[count].tag = strdup(tag_text);
			}else {
				insert_tag_text("global");
				symbol_table[count].tag = strdup(tag_text);
			}
			count++;
		} else if(symbol == 'F'){
			symbol_table[count].id_name = strdup(id_name);
			symbol_table[count].data_type = strdup(type);
			symbol_table[count].line_no = countn;
			symbol_table[count].type = strdup("Function");
			symbol_table[count].scope = count_block;
			symbol_table[count].tag = strdup("N/A");
			count++;
		} else if(symbol == 'P'){
			symbol_table[count].id_name = strdup(id_name);
			symbol_table[count].data_type = strdup("N/A");
			symbol_table[count].line_no = countn;
			symbol_table[count].type = strdup("Procedure");
			symbol_table[count].scope = count_block;
			symbol_table[count].tag = strdup("N/A");
			count++;
		} else if(symbol == 'M'){
			symbol_table[count].id_name = strdup(id_name);
			symbol_table[count].data_type = strdup("N/A");
			symbol_table[count].line_no = countn;
			symbol_table[count].type = strdup("Main");
			symbol_table[count].scope = count_block;
			symbol_table[count].tag = strdup("N/A");
			count++;
		}
	}
}

void addWithScope(char symbol, char * id_name, int value_scope, char * function_name){
	q=search(id_name);
	if(q == -1) {
		if(symbol == 'H'){
			symbol_table[count].id_name = strdup(id_name);
			symbol_table[count].data_type = strdup(type);
			symbol_table[count].line_no = countn;
			symbol_table[count].type = strdup("Header");
			symbol_table[count].scope = value_scope;
			symbol_table[count].tag = strdup("N/A");
			count++;
		} else if(symbol == 'K'){
			symbol_table[count].id_name = strdup(id_name);
			symbol_table[count].data_type = strdup("N/A");
			symbol_table[count].line_no = countn;
			symbol_table[count].type = strdup("Keyword\t");
			symbol_table[count].scope = value_scope;
			symbol_table[count].tag = strdup("N/A");
			count++;
		} else if(symbol == 'V'){
			symbol_table[count].id_name = strdup(id_name);
			symbol_table[count].data_type = strdup(type);
			symbol_table[count].line_no = countn;
			symbol_table[count].type = strdup("Variable");
			symbol_table[count].scope = value_scope;
			if(strcmp(tag_text,"")!=0){
				symbol_table[count].tag = strdup(tag_text);
			}else {
				insert_tag_text("global");
				symbol_table[count].tag = strdup(tag_text);
			}
			count++;
		} else if(symbol == 'F'){
			symbol_table[count].id_name = strdup(id_name);
			symbol_table[count].data_type = strdup(type);
			symbol_table[count].line_no = countn;
			symbol_table[count].type = strdup("Function");
			symbol_table[count].scope = value_scope;
			symbol_table[count].tag = strdup("N/A");
			count++;
		} else if(symbol == 'P'){
			symbol_table[count].id_name = strdup(id_name);
			symbol_table[count].data_type = strdup("N/A");
			symbol_table[count].line_no = countn;
			symbol_table[count].type = strdup("Procedure");
			symbol_table[count].scope = value_scope;
			symbol_table[count].tag = strdup("N/A");
			count++;
		} else if(symbol == 'M'){
			symbol_table[count].id_name = strdup(id_name);
			symbol_table[count].data_type = strdup("N/A");
			symbol_table[count].line_no = countn;
			symbol_table[count].type = strdup("Main");
			symbol_table[count].scope = value_scope;
			symbol_table[count].tag = strdup("N/A");
			count++;
		}
	}
}

void insert_type(char * type_text){
	strcpy(type, type_text);
}

void insert_tag_text(char * text){
	strcpy(tag_text, text);
}

int verificar_valor_tipo_valido(char * valor, char * tipo){
	
	if((strcmp(tipo,"int") == 0 || strcmp(tipo,"float") == 0 || strcmp(tipo,"string") == 0) && isInteger(valor)){
		return 1;
	}else if((strcmp(tipo,"float") == 0 || strcmp(tipo,"string") == 0) && isFloat(valor)){
		return 1;
	}else if(strcmp(tipo,"string") == 0){
		return 1;
	}else {
		return 0;
	}
}

int isInteger(const char *str) {
	if(str == NULL || *str == '\0') {
		return 0;
	}

	char *endptr;
	strtol(str, &endptr, 10);

	if(*endptr != '\0') {
		return 0;
	}

	return 1;
}

int isFloat(const char *str) {
	if(str == NULL || *str == '\0') {
		return 0;
	}

	char *endptr;
	strtof(str, &endptr);

	if(*endptr != '\0') {
		return 0;
	}

	return 1;
}

int verificar_calculo_numero_float_int(char * type1, char * type2){
	if((strcmp(type1, "int") == 0 && strcmp(type2, "int") == 0)
		|| (strcmp(type1, "int") && strcmp(type2, "float") == 0)
		|| (strcmp(type1, "float") == 0 && strcmp(type2, "int") == 0)
		|| (strcmp(type1, "float") == 0 && strcmp(type2, "float") == 0)){
			return 1;
	}
	return 0;
}

char * tipo_resultado_operacao(char * type1, char * type2){
	if((strcmp(type1, "int") == 0 && strcmp(type2, "int") == 0)){
		return "int";
	}else if((strcmp(type1, "int") == 0 && strcmp(type2, "float") == 0)){
		return "float";
	} else if((strcmp(type1, "float") == 0 && strcmp(type2, "int") == 0)){
		return "float";
	} else if((strcmp(type1, "float") == 0 && strcmp(type2, "float") == 0)){
		return "float";
	} else {
		return "";
	}
}

int verificar_ids_validos(char * ids, char * tag){

	int tamanho;

	char** idsEncontrados = separarIDs(ids, &tamanho);

	for(int i = 0; i<tamanho; i++){
		processarTexto(idsEncontrados[i]);
		if(verificar_variavel_existe(idsEncontrados[i], tag_text) == -1){
			yyerror("Variavel não encontrada nesse escopo");
		}
	}

	for(int i = 0; i<tamanho; i++){
		free(idsEncontrados[i]);
	}
	free(idsEncontrados);

	return 0;
}

char ** separarIDs(char * texto, int * tamanho){
	int tamanhoMaximo = 10;
	char ** vetorIDs = (char**) malloc(tamanhoMaximo * sizeof(char*));

	char * tokenID = strtok(texto, ",");
	int contador = 0;

	while(tokenID != NULL) {
		vetorIDs[contador] = strdup(tokenID);
		contador++;

		if(contador >= tamanhoMaximo) {
			tamanhoMaximo *= 2;
			vetorIDs = (char**) realloc(vetorIDs, tamanhoMaximo * sizeof(char*));
		}

		tokenID = strtok(NULL, ",");
	}

	*tamanho = contador;

	return vetorIDs;
}

void processarTexto(char * texto){
	char * removerChars = "*&()";
	char * ptr = texto;
	int idx = 0;

	while(*ptr){
		if(strchr(removerChars, *ptr) == NULL){
			texto[idx++] = *ptr;
		}
		ptr++;
	}
	texto[idx] = '\0';

	char* seta = strstr(texto, "->");
	
	if(seta != NULL){
		*seta = '\0';
	}

	char * ponto = strstr(texto, ".");
	if(ponto != NULL){
		*ponto = '\0';
	}

	char * abertura = strchr(texto, '[');

	while (abertura != NULL) {
		char * fechamento = strchr(abertura, ']');
		if(fechamento != NULL) {
			memmove(abertura, fechamento + 1, strlen(fechamento));
		}
		abertura = strchr(texto, '[');
	}
}
