/* Please feel free to modify any content */

/* Definition section */
%{
    #include<limits.h>
    #include "compiler_hw_common.h" //Extern variables that communicate with lex
    // #define YYDEBUG 1
    // int yydebug = 1;

    extern int yylineno;
    extern int yylex();
    extern FILE *yyin;

    int yylex_destroy ();
    void yyerror (char const *s)
    {
        printf("error:%d: %s\n", yylineno, s);
    }

    extern int yylineno;
    extern int yylex();
    extern FILE *yyin;

    /* Used to generate code */
    /* As printf; the usage: CODEGEN("%d - %s\n", 100, "Hello world"); */
    /* We do not enforce the use of this macro */
    #define CODEGEN(...) \
        do { \
            for (int i = 0; i < g_indent_cnt; i++) { \
                fprintf(fout, "\t"); \
            } \
            fprintf(fout, __VA_ARGS__); \
        } while (0)
    int case_condition_list_into_a_switch[100]={0};	//紀錄目前的switch中的所有case的觸發條件數字
    int current_inner_case_num=0;			//目前程式執行到某個switch中的第幾個case
    int without_default=1;				//判斷目前這個switch是否有default
    int switch_label_num=0;				//目前程式中執行到第幾個switch
    int full_for_label=0;
    int is_full_for=0;
    int for_label_num=0;
    int if_label_num=0;
    int TF_label_num=0;
    int assign_lookup_addr=0;
    int not_return=1;
    int scope_level=-1;
    int addr_num=0;
    char function_type[100];
    char function_parameter[100];
    char function_signature[100];
    char function_para_name_list[100];
    char function_para_name[10];
    int function_para_num=0;
    int lookup_Addr;
    char lookup_Type[100];
    int lookup_exist=0;
    int print_without_newline;
    int data_type_for_print;
    struct symbol_table_node
    {
        int index;
        char Name[100];
        char Type[100];
        int Addr;
        int Lineno;
        char Func_sig[100];
        struct symbol_table_node* next;
        struct symbol_table_node* back;
    };
    typedef struct symbol_table_node symbol_table_node;
    typedef struct symbol_table_node* node_ptr;
    node_ptr lookup_result=NULL;

    struct symbol_table_entry
    {
        int scope_level;
        node_ptr entry;
        struct symbol_table_entry* next;
        struct symbol_table_entry* back;
    };
    typedef struct symbol_table_entry symbol_table_entry;
    typedef struct symbol_table_entry* entry_ptr;
    entry_ptr entry_tail=NULL;
    /* Symbol table function - you can add new functions if needed. */
    /* parameters and return type can be changed */
    static void create_symbol(/* ... */);
    static void insert_symbol(/* ... */);
    static void lookup_symbol(/* ... */);
    static void dump_symbol(/* ... */);

    /* Global variables */
    bool g_has_error = false;
    FILE *fout = NULL;
    int g_indent_cnt = 0;
%}

%error-verbose

/* Use variable or self-defined structure to represent
 * nonterminal and token type
 *  - you can add new fields if needed.
 */
%union {
    int i_val;
    float f_val;
    char *s_val;
    bool b_val;
    char *op;

    struct{
        int i_val;
        char *s_val;
    }expr;

    /* ... */
}

/* Token without return */
%token VAR NEWLINE
%token INT FLOAT BOOL STRING TRUE FALSE
%token INC DEC GEQ LEQ EQL NEQ LOR LAND
%token ADD_ASSIGN SUB_ASSIGN MUL_ASSIGN DIV_ASSIGN REM_ASSIGN
%token IF ELSE FOR SWITCH CASE DEFAULT RETURN
%token PRINT PRINTLN
%token id
%token PACKAGE FUNC

/* Token with return, which need to sepcify type */
%token <i_val> INT_LIT
%token <s_val> STRING_LIT
%token <f_val> FLOAT_LIT
//%token <b_val> BOOL_LIT

/* Nonterminal with return, which need to sepcify type */
%type <s_val> Type 
%type <op> binary_op
%type <expr> Expression

/* Yacc will start at this nonterminal */
%start Program

/* Grammar section */
%%

Program
    : 
    {
        create_symbol(); 
    } 
    GlobalStatementList { dump_symbol(); }
;

GlobalStatementList 
    : GlobalStatementList GlobalStatement
    | GlobalStatement
;

GlobalStatement
    : PackageStmt NEWLINE
    | FunctionDeclStmt
    | NEWLINE
;

PackageStmt
    : PACKAGE id { printf("package: %s\n",$<s_val>2); }
;

FunctionDeclStmt
    : FUNC id 
    { 
        not_return=1;
        printf("func: %s\n", $<s_val>2) ;
        memset(function_parameter , 0 , 50);create_symbol();
        memset(function_para_name_list,0,50);
        memset(function_para_name,0,50);
        function_para_num=0;
    } 
    '(' ParameterList ')' ReturnType 
    {
        memset(function_signature , 0 , 50);
        strcat(function_signature,"(");
        strcat(function_signature,function_parameter);
        strcat(function_signature,")");
        strcat(function_signature,function_type);
        CODEGEN(".method public static ");
        if(strcmp($<s_val>2,"main")==0)
        {
            CODEGEN("main([Ljava/lang/String;)V\n");
        }else
        {
            CODEGEN("%s%s\n",$<s_val>2,function_signature);
        }
        CODEGEN(".limit stack 1000\n.limit locals 1000\n");
        // printf("func_signature: %s\n",function_signature);
        if(function_para_num!=0)
        {
            int cnt=0;
            // for(int x=0;x<strlen(function_para_name_list);x++)
            // {
            //     printf("%c",function_para_name_list[x]);
            // }
            // printf("\n");
            for(int i=0;i<function_para_num;i++)
            {
                //printf("%d\n",function_para_num);
                memset(function_para_name,0,50);
                while(function_para_name_list[cnt]!=',')
                {

                    char tp[5];
                    memset(tp,0,4);
                    tp[0]=function_para_name_list[cnt];
                    tp[1]='\0';

                    strcat(function_para_name,tp);
                    cnt++;
                }
                cnt++;
                char tmp_type[100];
                memset(tmp_type,0,50);
                if(function_parameter[i]=='I')
                {
                    strcat(tmp_type,"int32");
                    //CODEGEN("ldc 0\n");
                }else if(function_parameter[i]=='F')
                {
                    strcat(tmp_type,"float32");
                    //CODEGEN("ldc 0.0\n");
                }else if(function_parameter[i]=='S')
                {
                    strcat(tmp_type,"string");
                    //CODEGEN("ldc \"\"\n");
                }else if(function_parameter[i]=='B')
                {
                    strcat(tmp_type,"bool");
                    //CODEGEN("ldc 0\n");
                }                
                yylineno ++;
                insert_symbol(function_para_name,tmp_type,"-");
                yylineno --;
            }
        }
        function_para_num=0;
        printf("func_signature: %s\n",function_signature);
        insert_symbol($<s_val>2,"func",function_signature); 
    } 
    FuncBlock 
    { 
        dump_symbol();
        if(not_return==1)
        {
            CODEGEN("return\n");
        }
        CODEGEN(".end method\n");
    }
;

ReturnType
    : INT {strcpy(function_type, "I"); }
    | FLOAT {strcpy(function_type, "F");}
    | STRING {strcpy(function_type, "S");}
    | BOOL {strcpy(function_type, "B");}
    | {strcpy(function_type, "V");}
;

ParameterList 
    : id Type
    {
        printf("param %s, type: ",$<s_val>1);
        strcat(function_para_name_list,$<s_val>1);
        strcat(function_para_name_list,",");
        function_para_num++;
        if(strcmp($<s_val>2,"int32")==0)
        {
            strcat(function_parameter, "I");
            printf("I\n");
            //CODEGEN("ldc 0\n");
            // strcat(function_para_name_list,$<s_val>1);
            // strcat(function_para_name_list,",");
            // function_para_num++;
 
            
        }
        else if(strcmp($<s_val>2,"float32")==0)
        {
            strcat(function_parameter, "F");
            printf("F\n");
            //CODEGEN("ldc 0.0\n");
            // strcat(function_para_name_list,$<s_val>1);
            // strcat(function_para_name_list,",");
            // function_para_num++;

        }
        if(strcmp($<s_val>2,"string")==0)
        {
            strcat(function_parameter, "S");
            printf("S\n");
            //CODEGEN("ldc \"\"\n");
            // strcat(function_para_name_list,$<s_val>1);
            // strcat(function_para_name_list,",");
            // function_para_num++;

        }
        if(strcmp($<s_val>2,"bool")==0)
        {
            strcat(function_parameter, "B");
            printf("B\n");
            //CODEGEN("ldc 0\n");
            // strcat(function_para_name_list,$<s_val>1);
            // strcat(function_para_name_list,",");
            // function_para_num++;

        }        
        // yylineno ++;
        // insert_symbol($<s_val>1,$<s_val>2,"-");
        // yylineno --;
    }
    | ParameterList ',' id Type
    {
        printf("param %s, type: ",$<s_val>3);
        strcat(function_para_name_list,$<s_val>3);
        strcat(function_para_name_list,",");
        function_para_num++;
        if(strcmp($<s_val>4,"int32")==0)
        {
            strcat(function_parameter, "I");
            printf("I\n");
            //CODEGEN("ldc 0\n");
            // strcat(function_para_name_list,$<s_val>1);
            // strcat(function_para_name_list,",");
            // function_para_num++;
        }
        else if(strcmp($<s_val>4,"float32")==0)
        {
            strcat(function_parameter, "F");
            printf("F\n");
            //CODEGEN("ldc 0.0\n");
            // strcat(function_para_name_list,$<s_val>1);
            // strcat(function_para_name_list,",");
            // function_para_num++;
        }
        if(strcmp($<s_val>4,"string")==0)
        {
            strcat(function_parameter, "S");
            printf("S\n");
            //CODEGEN("ldc \"\"\n");
            // strcat(function_para_name_list,$<s_val>1);
            // strcat(function_para_name_list,",");
            // function_para_num++;
        }
        if(strcmp($<s_val>4,"bool")==0)
        {
            strcat(function_parameter, "B");
            printf("B\n");
            //CODEGEN("ldc 0\n");
            // strcat(function_para_name_list,$<s_val>1);
            // strcat(function_para_name_list,",");
            // function_para_num++;
        }
        // yylineno++;
        // insert_symbol($<s_val>3,$<s_val>4,"-");
        // yylineno--;

    }
    | {}
;

FuncBlock 
    : '{' StatementList '}'
;

ReturnStmt 
    : RETURN ReturnStmtExpr
;

ReturnStmtExpr
    : Expression 
    {
        if(strcmp($<s_val>1 , "int32")== 0)
        {
            printf("ireturn\n");
            CODEGEN("ireturn\n");
        }
        else if(strcmp($<s_val>1 , "float32")== 0)
        {
            printf("freturn\n");
            CODEGEN("freturn\n");
        }
        else if(strcmp($<s_val>1 , "string")== 0)
        {
            printf("sreturn\n");
            CODEGEN("sreturn\n");
        }
        else if(strcmp($<s_val>1 , "bool")== 0)
        {
            printf("breturn\n");
            CODEGEN("breturn\n");
        }
        not_return=0;
    }
    |  
    {
        printf("return\n");
        CODEGEN("return\n");
        not_return=0;
    }
;

PrintStmt 
    : PrintStmts '(' Expression ')'
    {
        char print_type[100];
        memset(print_type,0,50);
        strcpy(print_type,$<s_val>1);
        printf("%s %s\n",$<s_val>1,$<s_val>3);
        if(strcmp($<s_val>3,"string")==0)
        {
            CODEGEN("getstatic java/lang/System/out Ljava/io/PrintStream;\nswap\ninvokevirtual java/io/PrintStream/%s(Ljava/lang/String;)V\n",print_type);
        }else if(strcmp($<s_val>3,"float32")==0)
        {
            CODEGEN("getstatic java/lang/System/out Ljava/io/PrintStream;\nswap\ninvokevirtual java/io/PrintStream/%s(F)V\n",print_type); 
        }else if(strcmp($<s_val>3,"int32")==0)
        {
            CODEGEN("getstatic java/lang/System/out Ljava/io/PrintStream;\nswap\ninvokevirtual java/io/PrintStream/%s(I)V\n",print_type); 
        }else if(strcmp($<s_val>3,"bool")==0)
        {
            CODEGEN("ifne L_cmp_%d\n",TF_label_num);
            CODEGEN("ldc \"false\"\n");
            CODEGEN("goto L_cmp_%d\n",TF_label_num+1);
            CODEGEN("L_cmp_%d:\n",TF_label_num);
            CODEGEN("\tldc \"true\"\n");
            CODEGEN("L_cmp_%d:\n",TF_label_num+1);
            CODEGEN("\tgetstatic java/lang/System/out Ljava/io/PrintStream;\n\tswap\n\tinvokevirtual java/io/PrintStream/%s(Ljava/lang/String;)V\n",print_type); 
            TF_label_num+=2;
        }
    }
;

PrintStmts
    : PRINT {$<s_val>$="print";}
    | PRINTLN {$<s_val>$="println";}

Type
    : INT {$<s_val>$="int32";}
    | FLOAT {$<s_val>$="float32";}
    | STRING {$<s_val>$="string";}
    | BOOL {$<s_val>$="bool";}
;

Expression  
    : LANDExpr {$<s_val>$=$<s_val>1;}
    | Expression LOR LANDExpr
    {
        $<s_val>$="bool";
        if(strcmp($<s_val>1,"bool")!=0)
        {
            printf("error:%d: invalid operation: (operator LOR not defined on %s)\n",yylineno,$<s_val>1);
            g_has_error=true;
        }
        if(strcmp($<s_val>3,"bool")!=0)
        {
            printf("error:%d: invalid operation: (operator LOR not defined on %s)\n",yylineno,$<s_val>3);
            g_has_error=true;
        }
        printf("LOR\n");
        CODEGEN("\tior\n");
    }
    | FuncCallStmt
;

LANDExpr
    :CmpExpr {$<s_val>$=$<s_val>1;}
    |LANDExpr LAND CmpExpr
    {
        $<s_val>$="bool";
        if(strcmp($<s_val>1,"bool")!=0)
        {
            printf("error:%d: invalid operation: (operator LAND not defined on %s)\n",yylineno,$<s_val>1);
            g_has_error=true;
        }
        if(strcmp($<s_val>3,"bool")!=0)
        {
            printf("error:%d: invalid operation: (operator LAND not defined on %s)\n",yylineno,$<s_val>3);
            g_has_error=true;
        }
        printf("LAND\n");
        CODEGEN("\tiand\n");
    }
;


CmpExpr
    :AddExpr {$<s_val>$=$<s_val>1;}
    |CmpExpr cmp_op AddExpr
    {
        $<s_val>$="bool";
        if(strcmp($<s_val>1,$<s_val>3)!=0)
        {
            printf("error:%d: invalid operation: %s (mismatched types %s and %s)\n",yylineno+1,$<s_val>2,$<s_val>1,$<s_val>3);
            g_has_error=true;
        }
        if(strcmp($<s_val>1,"int32")==0)
        {
            CODEGEN("isub\n");
            //CODEGEN("iconst_0\n");
        }else
        {
            CODEGEN("fcmpl\n");
        }
        
        if(strcmp($<s_val>2,"EQL")==0)
        {
            
            CODEGEN("ifeq L_cmp_%d\n",TF_label_num);
            CODEGEN("iconst_0\n");
            CODEGEN("goto L_cmp_%d\n",TF_label_num+1);
            CODEGEN("L_cmp_%d:\n",TF_label_num);
            CODEGEN("\ticonst_1\n");
            CODEGEN("L_cmp_%d:\n",TF_label_num+1);
            TF_label_num+=2;

        }else if(strcmp($<s_val>2,"NEQ")==0)
        {
            
            CODEGEN("ifne L_cmp_%d\n",TF_label_num);
            CODEGEN("iconst_0\n");
            CODEGEN("goto L_cmp_%d\n",TF_label_num+1);
            CODEGEN("L_cmp_%d:\n",TF_label_num);
            CODEGEN("\ticonst_1\n");
            CODEGEN("L_cmp_%d:\n",TF_label_num+1);
            TF_label_num+=2;

        }else if(strcmp($<s_val>2,"LSS")==0)
        {
            
            CODEGEN("iflt L_cmp_%d\n",TF_label_num);
            CODEGEN("iconst_0\n");
            CODEGEN("goto L_cmp_%d\n",TF_label_num+1);
            CODEGEN("L_cmp_%d:\n",TF_label_num);
           CODEGEN("\ticonst_1\n");
            CODEGEN("L_cmp_%d:\n",TF_label_num+1);
            TF_label_num+=2;
        }else if(strcmp($<s_val>2,"LEQ")==0)
        {
            
            CODEGEN("ifle L_cmp_%d\n",TF_label_num);
            CODEGEN("iconst_0\n");
            CODEGEN("goto L_cmp_%d\n",TF_label_num+1);
            CODEGEN("L_cmp_%d:\n",TF_label_num);
            CODEGEN("\ticonst_1\n");
            CODEGEN("L_cmp_%d:\n",TF_label_num+1);
            TF_label_num+=2;

        }else if(strcmp($<s_val>2,"GTR")==0)
        {
            
            CODEGEN("ifgt L_cmp_%d\n",TF_label_num);
            CODEGEN("iconst_0\n");
            CODEGEN("goto L_cmp_%d\n",TF_label_num+1);
            CODEGEN("L_cmp_%d:\n",TF_label_num);
            CODEGEN("\ticonst_1\n");
            CODEGEN("L_cmp_%d:\n",TF_label_num+1);
            TF_label_num+=2;

        }else if(strcmp($<s_val>2,"GEQ")==0)
        {
            
            CODEGEN("ifge L_cmp_%d\n",TF_label_num);
            CODEGEN("iconst_0\n");
            CODEGEN("goto L_cmp_%d\n",TF_label_num+1);
            CODEGEN("L_cmp_%d:\n",TF_label_num);
            CODEGEN("\ticonst_1\n");
            CODEGEN("L_cmp_%d:\n",TF_label_num+1);
            TF_label_num+=2;

        }
        printf("%s\n", $<s_val>2);
    }
;


AddExpr
    :MulExpr {$<s_val>$=$<s_val>1;}
    |AddExpr add_op MulExpr
    {
        if(strcmp($<s_val>1,$<s_val>3)!=0)
        {
            printf("error:%d: invalid operation: %s (mismatched types %s and %s)\n",yylineno,$<s_val>2,$<s_val>1,$<s_val>3);
            g_has_error=true;
        }else if(strcmp($<s_val>1,$<s_val>3)==0)
        {
            if(strcmp($<s_val>1,"bool")==0 ||strcmp($<s_val>1,"string")==0)
            {
                printf("error:%d: invalid operation: (operator %s not defined on %s)\n",yylineno,$<s_val>2,$<s_val>1);
                g_has_error=true;
            }
        }
        if(strcmp($<s_val>1,"int32")==0)
        {
            if(strcmp($<s_val>2,"ADD")==0)
            {
                CODEGEN("iadd\n");
            }else if(strcmp($<s_val>2,"SUB")==0)
            {
                CODEGEN("isub\n");
            }
            
        }else if(strcmp($<s_val>1,"float32")==0)
        {
            if(strcmp($<s_val>2,"ADD")==0)
            {
                CODEGEN("fadd\n");
            }else if(strcmp($<s_val>2,"SUB")==0)
            {
                CODEGEN("fsub\n");
            }
        }
        $<s_val>$=$<s_val>1;
        printf("%s\n", $<s_val>2);
    }
;


MulExpr
    :UnaryExpr {$<s_val>$=$<s_val>1;}
    |MulExpr mul_op UnaryExpr
    {
        $<s_val>$=$<s_val>1;
        if(strcmp($<s_val>2,"REM")==0)
        {
            if(strcmp($<s_val>1,"int32")!=0)
            {
                printf("error:%d: invalid operation: (operator REM not defined on %s)\n",yylineno+1,$<s_val>1);
                g_has_error=true;
            }
            if(strcmp($<s_val>3,"int32")!=0)
            {
                printf("error:%d: invalid operation: (operator REM not defined on %s)\n",yylineno+1,$<s_val>3);
                g_has_error=true;
            }


        }else if(strcmp($<s_val>2,"MUL")==0 ||strcmp($<s_val>2,"QUO")==0)
        {
            if(strcmp($<s_val>1,"bool")==0)
            {
                printf("error:%d: invalid operation: (operator REM not defined on %s)\n",yylineno+1,$<s_val>1);
                g_has_error=true;
            }
            if(strcmp($<s_val>3,"bool")==0)
            {
                printf("error:%d: invalid operation: (operator REM not defined on %s)\n",yylineno+1,$<s_val>3);
                g_has_error=true;
            }
            if(strcmp($<s_val>1,"string")==0)
            {
                printf("error:%d: invalid operation: (operator REM not defined on %s)\n",yylineno+1,$<s_val>1);
                g_has_error=true;
            }
            if(strcmp($<s_val>3,"string")==0)
            {
                printf("error:%d: invalid operation: (operator REM not defined on %s)\n",yylineno+1,$<s_val>3);
                g_has_error=true;
            }

        }
        if(strcmp($<s_val>1,"int32")==0)
        {
            if(strcmp($<s_val>2,"MUL")==0)
            {
                CODEGEN("imul\n");
            }else if(strcmp($<s_val>2,"QUO")==0)
            {
                CODEGEN("idiv\n");
            }else if(strcmp($<s_val>2,"REM")==0)
            {
                CODEGEN("irem\n");
            }
            
        }else if(strcmp($<s_val>1,"float32")==0)
        {
            if(strcmp($<s_val>2,"MUL")==0)
            {
                CODEGEN("fmul\n");
            }else if(strcmp($<s_val>2,"QUO")==0)
            {
                CODEGEN("fdiv\n");
            }else if(strcmp($<s_val>2,"REM")==0)
            {
                CODEGEN("frem\n");
            }
        }
        // if(strcmp($<s_val>2,"MUL")==0)
        // {
        //     CODEGEN("")
        // }
        printf("%s\n", $<s_val>2);
    }
;
UnaryExpr
    : PrimaryExpr
    {
        $<s_val>$=$<s_val>1;
    }
    | unary_op UnaryExpr
    {
        printf("%s\n",$<s_val>1);
        $<s_val>$=$<s_val>2;
        if($<s_val>1[0]=='N' && $<s_val>1[1]=='O' && $<s_val>1[2]=='T')
        {
            if($<s_val>2[0]!='b')
            {
                printf("error:%d: invalid operation: (operator %s not defined on %s)\n" , yylineno+1, $<s_val>1, $<s_val>2);
                g_has_error = 1;

            }
            $<s_val>$="bool";
        }

        if($<s_val>1[0]!='P' || $<s_val>1[1]!='O' || $<s_val>1[2]!='S')
        {
            if($<s_val>2[0]=='i')
            {
                if($<s_val>1[0]=='N' && $<s_val>1[1]=='E' && $<s_val>1[2]=='G')
                {
                    CODEGEN("\tineg\n");
                }else if($<s_val>1[0]=='N' && $<s_val>1[1]=='O' && $<s_val>1[2]=='T')
                {
                    CODEGEN("\tiixor\n");
                }
            }else if($<s_val>2[0]=='f')
            {
                if($<s_val>1[0]=='N' && $<s_val>1[1]=='E' && $<s_val>1[2]=='G')
                {
                    CODEGEN("\tfneg\n");
                }else if($<s_val>1[0]=='N' && $<s_val>1[1]=='O' && $<s_val>1[2]=='T')
                {
                    CODEGEN("\tfixor\n");
                }
            }
        }
    }

;



cmp_op
    : EQL { $<s_val>$ = "EQL";}
    | NEQ { $<s_val>$ = "NEQ";}
    | '<' { $<s_val>$ = "LSS";}
    | LEQ { $<s_val>$ = "LEQ";}
    | '>' { $<s_val>$ = "GTR";}
    | GEQ { $<s_val>$ = "GEQ";}
;

add_op
    : '+'       { $<s_val>$ = "ADD";}
    | '-'       { $<s_val>$ = "SUB";}
;
mul_op 
    : '*'       { $<s_val>$ = "MUL";}
    | '/'       { $<s_val>$ = "QUO";}
    | '%'       { $<s_val>$ = "REM";}
;

unary_op 
    : '+'       { $<s_val>$ = "POS";} 
    | '-'       { $<s_val>$ = "NEG";}
    | '!'       {
                    $<s_val>$ = "NOT";
                    CODEGEN("\ticonst_1\n");
                }
;

PrimaryExpr
    : Operand 
    | ConversionExpr
;

Operand
    : Literal {$<s_val>$=$<s_val>1;} 
    | id
    {
        lookup_symbol($<s_val>1);

        if(lookup_exist==1)
        {
            printf("IDENT (name=%s, address=%d)\n", $<s_val>1, lookup_Addr);
            if(strcmp(lookup_Type , "int32") == 0)
            {
                $<s_val>$ = "int32";
                data_type_for_print=0;
                CODEGEN("iload %d\n",lookup_Addr);
            }else if(strcmp(lookup_Type , "float32") == 0)
            {
                $<s_val>$ = "float32";
                data_type_for_print=1;
                CODEGEN("fload %d\n",lookup_Addr);
            }else if(strcmp(lookup_Type , "string") == 0)
            {
                $<s_val>$ = "string";
                data_type_for_print=2;
                CODEGEN("aload %d\n",lookup_Addr);
            }else if(strcmp(lookup_Type , "bool") == 0)
            {
                $<s_val>$ = "bool";
                data_type_for_print=3;
                CODEGEN("iload %d\n",lookup_Addr);
            }
            

        }else
        {
            printf("error:%d: undefined: %s\n", yylineno+1 , $<s_val>1);
            fflush(stdout);
            $<s_val>$ = "ERROR";
            g_has_error=true;
        }

    }
    | '(' Expression ')' { $<s_val>$ = $<s_val>2;}
    
    
;

Literal 
    : INT_LIT 
    {
        printf("INT_LIT %d\n",$<i_val>1);$<s_val>$="int32";
        CODEGEN("ldc %d\n",$<i_val>1);
    }
    | FLOAT_LIT 
    {
        printf("FLOAT_LIT %f\n",$<f_val>1);$<s_val>$="float32";
        CODEGEN("ldc %f\n",$<f_val>1);
    }
    | TRUE 
    {
        printf("TRUE %d\n",1);$<s_val>$="bool";
        CODEGEN("ldc %d\n",1);
    }
    | FALSE 
    {
        printf("FALSE %d\n",0);$<s_val>$="bool";
        CODEGEN("ldc %d\n",0);
    }
    | STRING_LIT 
    {
        printf("STRING_LIT %s\n",$<s_val>1);$<s_val>$="string";
        CODEGEN("ldc \"%s\"\n",$<s_val>1);
    }
;


ConversionExpr
    : Type '(' Expression ')'
    {
        if(strcmp($<s_val>3,"int32")==0 && strcmp($<s_val>1,"float32")==0)
        {
            CODEGEN("i2f\n");
            printf("i2f\n");
        }
        else if(strcmp($<s_val>3,"float32")==0 && strcmp($<s_val>1,"int32")==0)
        {
            CODEGEN("f2i\n");
            printf("f2i\n");
        }
        $<s_val>$=$<s_val>1;
    }  
;

Statement 
    :DeclarationStmt NEWLINE
    | SimpleStmt NEWLINE
    | Block
    | IfStmt
    | ForStmt
    | SwitchStmt
    | CaseStmt 
    | PrintStmt NEWLINE
    | ReturnStmt NEWLINE
    | FuncCallStmt 
    | NEWLINE
;

FuncCallStmt
    : id '(' ParaInputList ')'
    {
        lookup_symbol($<s_val>1);
        if(lookup_result != NULL)
        {
            printf("call: %s%s\n",$<s_val>1 , lookup_result->Func_sig  );
            CODEGEN("invokestatic Main/%s%s\n", $<s_val>1 , lookup_result->Func_sig);
        }
            
    }
;

ParaInputList
    : Expression 
    | ParaInputList ',' Expression
    | 
;

SimpleStmt 
    : AssignmentStmt 
    | ExpressionStmt 
    | IncDecStmt
;

DeclarationStmt 
    : VAR id Type
    {
        if(strcmp($<s_val>3,"int32")==0)
        {
            CODEGEN("ldc 0\n");
        }else if(strcmp($<s_val>3,"float32")==0)
        {
            CODEGEN("ldc 0.0\n");
        }else if(strcmp($<s_val>3,"string")==0)
        {
            CODEGEN("ldc \"\"\n");
        }else if(strcmp($<s_val>3,"bool")==0)
        {
            CODEGEN("ldc 0\n");
        }
    } 
    DeclarationInit 
    {
        

        insert_symbol($<s_val>2,$<s_val>3,"-");
    }
;

DeclarationInit
    : '=' Expression {} 
    |
;

AssignmentStmt 
    : Expression{assign_lookup_addr=lookup_Addr;} assign_op Expression 
    {
        if(strcmp($<s_val>3,"ASSIGN")==0)
        {
            if(strcmp($<s_val>1,"int32")==0)
            {
                CODEGEN("istore %d\n",assign_lookup_addr);
            }else if(strcmp($<s_val>1,"float32")==0)
            {
                CODEGEN("fstore %d\n",assign_lookup_addr);
            }else if(strcmp($<s_val>1,"string")==0)
            {
                CODEGEN("astore %d\n",assign_lookup_addr);
            }else if(strcmp($<s_val>1,"bool")==0)
            {
                CODEGEN("istore %d\n",assign_lookup_addr);
            }
        }else if(strcmp($<s_val>3,"ADD")==0)
        {
            if(strcmp($<s_val>1,"int32")==0)
            {
                CODEGEN("iadd\n");
                CODEGEN("istore %d\n",assign_lookup_addr);
            }else if(strcmp($<s_val>1,"float32")==0)
            {
                CODEGEN("fadd\n");
                CODEGEN("fstore %d\n",assign_lookup_addr);
            }
        }else if(strcmp($<s_val>3,"SUB")==0)
        {
            if(strcmp($<s_val>1,"int32")==0)
            {
                CODEGEN("isub\n");
                CODEGEN("istore %d\n",assign_lookup_addr);
            }else if(strcmp($<s_val>1,"float32")==0)
            {
                CODEGEN("fsub\n");
                CODEGEN("fstore %d\n",assign_lookup_addr);
            }
        }else if(strcmp($<s_val>3,"MUL")==0)
        {
            if(strcmp($<s_val>1,"int32")==0)
            {
                CODEGEN("imul\n");
                CODEGEN("istore %d\n",assign_lookup_addr);
            }else if(strcmp($<s_val>1,"float32")==0)
            {
                CODEGEN("fmul\n");
                CODEGEN("fstore %d\n",assign_lookup_addr);
            }
        }else if(strcmp($<s_val>3,"QUO")==0)
        {
            if(strcmp($<s_val>1,"int32")==0)
            {
                CODEGEN("idiv\n");
                CODEGEN("istore %d\n",assign_lookup_addr);
            }else if(strcmp($<s_val>1,"float32")==0)
            {
                CODEGEN("fdiv\n");
                CODEGEN("fstore %d\n",assign_lookup_addr);
            }
        }else if(strcmp($<s_val>3,"REM")==0)
        {
            if(strcmp($<s_val>1,"int32")==0)
            {
                CODEGEN("irem\n");
                CODEGEN("istore %d\n",assign_lookup_addr);
            }else if(strcmp($<s_val>1,"float32")==0)
            {
                CODEGEN("frem\n");
                CODEGEN("fstore %d\n",assign_lookup_addr);
            }
        }

        if(strcmp($<s_val>1,$<s_val>4)!=0)
        {
            printf("error:%d: invalid operation: %s (mismatched types %s and %s)\n",yylineno,$<s_val>3,$<s_val>1,$<s_val>4);
            g_has_error=true;
        }
        printf("%s\n",$<s_val>3);
    }
;
assign_op
    : '=' {$<s_val>$="ASSIGN";}
    | ADD_ASSIGN {$<s_val>$="ADD";}
    | SUB_ASSIGN {$<s_val>$="SUB";}
    | MUL_ASSIGN {$<s_val>$="MUL";}
    | DIV_ASSIGN {$<s_val>$="QUO";}
    | REM_ASSIGN {$<s_val>$="REM";}
;

ExpressionStmt 
    : Expression
;

IncDecStmt 
    : Expression INCxDEC
    {

        if(strcmp($<s_val>2,"INC")==0)
        {
            if(strcmp($<s_val>1,"int32")==0)
            {
                CODEGEN("ldc 1\n");
                CODEGEN("iadd\n");
                CODEGEN("istore %d\n",lookup_Addr);
            }else if(strcmp($<s_val>1,"float32")==0)
            {
                CODEGEN("ldc 1.0\n");
                CODEGEN("fadd\n");
                CODEGEN("fstore %d\n",lookup_Addr);
            }
        }else if(strcmp($<s_val>2,"DEC")==0)
        {
            if(strcmp($<s_val>1,"int32")==0)
            {
                CODEGEN("ldc 1\n");
                CODEGEN("isub\n");
                CODEGEN("istore %d\n",lookup_Addr);
            }else if(strcmp($<s_val>1,"float32")==0)
            {
                CODEGEN("ldc 1.0\n");
                CODEGEN("fsub\n");
                CODEGEN("fstore %d\n",lookup_Addr);
            }
        }
    }
;

INCxDEC
    : INC {printf("INC\n");$<s_val>$="INC";}
    | DEC {printf("DEC\n");$<s_val>$="DEC";}
;

Block 
    : '{'{create_symbol();} StatementList '}' {dump_symbol();}
;

StatementList 
    : StatementList Statement
    |
;

IfStmt 
    : IF Condition
    {
        CODEGEN("\tifeq L_if_false_%d\n",if_label_num);
        if_label_num++;

    } Block
    {
        CODEGEN("\tgoto L_if_exit_%d\n",if_label_num-1);
        CODEGEN("L_if_false_%d:\n",if_label_num-1);
    } elsestmt
    {
        CODEGEN("L_if_exit_%d:\n",if_label_num-1); 
        if_label_num--;
    }
;

elsestmt
    : ELSE elifstmt
    |
;

elifstmt
    : IfStmt 
    | Block 
;

Condition 
    : Expression
    {
        if(strcmp($<s_val>1,"bool"))
        {
            printf("error:%d: non-bool (type %s) used as for condition\n",yylineno+1,$<s_val>1);
            g_has_error=true;
        }
    }
;

ForStmt 
    : FOR
    {
        CODEGEN("L_for_begin_%d:\n",for_label_num);
    } 
    ForCondition 
    {
        if(is_full_for==0)
        {
            CODEGEN("ifeq L_for_exit_%d\n",for_label_num);
        }
        else
        {
            CODEGEN("full_for_label_%d:\n",full_for_label+1);
        }
    }
    Block
    {
        if(is_full_for==0)
        {
            CODEGEN("goto L_for_begin_%d\n",for_label_num);
        }else
        {
            CODEGEN("\tgoto full_for_label_%d\n",full_for_label+2);            
        }
        
        CODEGEN("L_for_exit_%d:\n",for_label_num);
        is_full_for=0;
        for_label_num++;
        full_for_label+=3;
    }
;

ForCondition
    : Condition
    | ForClause
;

ForClause 
    :InitStmt ';' 
    {
        is_full_for=1;
        CODEGEN("full_for_label_%d:\n",full_for_label);
    }Condition  ';'
    {
        CODEGEN("ifeq L_for_exit_%d\n",for_label_num);
        CODEGEN("\tgoto full_for_label_%d\n",full_for_label+1);
        CODEGEN("full_for_label_%d:\n",full_for_label+2);
    } PostStmt
    {
        CODEGEN("\tgoto full_for_label_%d\n",full_for_label);
    }

;
InitStmt 
    : SimpleStmt
;
PostStmt 
    : SimpleStmt
;

SwitchStmt
    : SWITCH
    {
        without_default=1;
        current_inner_case_num=0;
    }
    Expression
    {
        CODEGEN("\tgoto L_switch_begin_%d\n",switch_label_num);
    }
    Block
    {
        CODEGEN("L_switch_begin_%d:\n",switch_label_num);
        CODEGEN("lookupswitch\n");
        for(int i=0;i<current_inner_case_num;i++)
        {
            if(case_condition_list_into_a_switch[i]==INT_MIN)
            {
                CODEGEN("\tdefault: L_case_%d_%d\n",switch_label_num,i);
            }else
            {
                CODEGEN("\t%d: L_case_%d_%d\n",case_condition_list_into_a_switch[i],switch_label_num,i);
            }
        }
        CODEGEN("L_switch_end_%d:\n",switch_label_num);
        switch_label_num++;

    }
;

CaseStmt 
    : CaseStmtlist ':' Block
    {
        CODEGEN("\tgoto L_switch_end_%d\n",switch_label_num);
    }
;

CaseStmtlist
    : CASE INT_LIT 
    {
        printf("case %d\n",$<i_val>2);
        CODEGEN("L_case_%d_%d:\n",switch_label_num,current_inner_case_num);
        case_condition_list_into_a_switch[current_inner_case_num]=$<i_val>2;
        current_inner_case_num++;
    
    }

    | DEFAULT
    {
        without_default=0;
        CODEGEN("L_case_%d_%d:\n",switch_label_num,current_inner_case_num);
        case_condition_list_into_a_switch[current_inner_case_num]=INT_MIN;
        current_inner_case_num++;
    }
;

%%

/* C code section */
int main(int argc, char *argv[])
{
    if (argc == 2) {
        yyin = fopen(argv[1], "r");
    } else {
        yyin = stdin;
    }
    if (!yyin) {
        printf("file `%s` doesn't exists or cannot be opened\n", argv[1]);
        exit(1);
    }

    /* Codegen output init */
    char *bytecode_filename = "hw3.j";
    fout = fopen(bytecode_filename, "w");
    CODEGEN(".source hw3.j\n");
    CODEGEN(".class public Main\n");
    CODEGEN(".super java/lang/Object\n");

    /* Symbol table init */
    // Add your code

    yylineno = 0;
    yyparse();

    /* Symbol table dump */
    // Add your code

    printf("Total lines: %d\n", yylineno);
    fclose(fout);
    fclose(yyin);

    if (g_has_error) {
        remove(bytecode_filename);
    }
    yylex_destroy();
    return 0;
}

static void create_symbol() {
    scope_level++;
    entry_ptr tmp=(entry_ptr)malloc(sizeof(symbol_table_entry));
    tmp->scope_level=scope_level;
    tmp->entry=NULL;
    tmp->next=NULL;
    tmp->back=NULL;
    if(entry_tail==NULL)
    {
        entry_tail=tmp;
    }else
    {
        entry_tail->next=tmp;
        tmp->back=entry_tail;
        entry_tail=tmp;
    }
    
    printf("> Create symbol table (scope level %d)\n", scope_level);

}

static void insert_symbol(char Name[], char Type[], char Func_sig[]) {
    node_ptr tmp=(node_ptr)malloc(sizeof(symbol_table_node));
    tmp->next=NULL;
    tmp->back=NULL;
    if(strcmp(Type,"func")==0)
    {
        
        if(entry_tail->back->entry==NULL)
        {
            tmp->index=0;
            strcpy(tmp->Name,Name);
            strcpy(tmp->Type,Type);
            strcpy(tmp->Func_sig,Func_sig);
            tmp->Addr=-1;
            tmp->Lineno=yylineno+1;
            entry_tail->back->entry=tmp;
        }else
        {
            node_ptr check=entry_tail->back->entry;
            while(check!=NULL)
            {
                if(strcmp(check->Name,Name)==0)
                {
                    printf("error:%d: %s redeclared in this block. previous declaration at line %d\n" , yylineno , Name, check->Lineno);
                    /* return; */
                    g_has_error=true;
                }
                check=check->back;
            }
            entry_tail->back->entry->next=tmp;
            tmp->back=entry_tail->back->entry;
            tmp->index=(tmp->back->index)+1;
            strcpy(tmp->Name,Name);
            strcpy(tmp->Type,Type);
            strcpy(tmp->Func_sig,Func_sig);
            tmp->Addr=-1;
            tmp->Lineno=yylineno+1;
            entry_tail->back->entry=entry_tail->back->entry->next;
        }
        printf("> Insert `%s` (addr: %d) to scope level %d\n", Name, -1, scope_level-1);

    }else
    {
        if(entry_tail->entry==NULL)
        {
            tmp->index=0;
            strcpy(tmp->Name,Name);
            strcpy(tmp->Type,Type);
            strcpy(tmp->Func_sig,Func_sig);
            tmp->Addr=addr_num;
            tmp->Lineno=yylineno;
            entry_tail->entry=tmp;
        }else
        {
            node_ptr check=entry_tail->entry;
            while(check!=NULL)
            {
                if(strcmp(check->Name,Name)==0)
                {
                    printf("error:%d: %s redeclared in this block. previous declaration at line %d\n" , yylineno , Name, check->Lineno);
                    //return;
                    g_has_error=true;
                }
                check=check->back;
            }
            entry_tail->entry->next=tmp;
            tmp->back=entry_tail->entry;
            tmp->index=(tmp->back->index)+1;
            strcpy(tmp->Name,Name);
            strcpy(tmp->Type,Type);
            strcpy(tmp->Func_sig,Func_sig);
            tmp->Addr=addr_num;
            tmp->Lineno=yylineno;
            entry_tail->entry=entry_tail->entry->next;
        }
        if(function_para_num==0)
        {
            if(strcmp(Type,"int32")==0)
            {
                CODEGEN("istore %d\n",addr_num);
            }else if(strcmp(Type,"float32")==0)
            {
                CODEGEN("fstore %d\n",addr_num);
            }else if(strcmp(Type,"string")==0)
            {
                CODEGEN("astore %d\n",addr_num);
            }else if(strcmp(Type,"bool")==0)
            {
                CODEGEN("istore %d\n",addr_num);
            }

        }

        printf("> Insert `%s` (addr: %d) to scope level %d\n", Name, addr_num++, scope_level);

    }

}

static void lookup_symbol(char ID[]) {
    lookup_exist=0;
    lookup_result = NULL;
    if(entry_tail==NULL)
    {
        lookup_exist=0;
        return;
    }else
    {
        entry_ptr outer_current_ptr=entry_tail;
        while(outer_current_ptr!=NULL)
        {
            node_ptr inner_current_ptr=outer_current_ptr->entry;
            while(inner_current_ptr!=NULL)
            {
                if(strcmp(inner_current_ptr->Name,ID)==0)
                {
                    lookup_result = inner_current_ptr;
                    lookup_exist=1;
                    lookup_Addr=inner_current_ptr->Addr;
                    strcpy(lookup_Type,inner_current_ptr->Type);
                    return;
                }


                inner_current_ptr=inner_current_ptr->back;
            }
            outer_current_ptr=outer_current_ptr->back;

        }
    }

}

static void dump_symbol() {

    printf("\n> Dump symbol table (scope level: %d)\n", scope_level);
    printf("%-10s%-10s%-10s%-10s%-10s%-10s\n",
           "Index", "Name", "Type", "Addr", "Lineno", "Func_sig");
    if(entry_tail->entry==NULL)
    {
        entry_ptr temp=entry_tail;
        entry_tail=entry_tail->back;
        temp->next=NULL;
        temp->back=NULL;
        free(temp);
        printf("\n");
        scope_level--;
        return;
    }
    
    node_ptr current=entry_tail->entry;
    node_ptr traceback=entry_tail->entry->back;
    while(traceback!=NULL)
    {
        current=traceback;
        traceback=traceback->back;
    }

    while(current!=NULL)
    {
        node_ptr temp2=current;
        printf("%-10d%-10s%-10s%-10d%-10d%-10s\n",current->index, current->Name, current->Type, current->Addr, current->Lineno, current->Func_sig);
        current=current->next;
        temp2->next=NULL;
        temp2->back=NULL;
        free(temp2);
    }
    entry_ptr tmp=entry_tail;
    entry_tail=entry_tail->back;
    tmp->next=NULL;
    tmp->back=NULL;
    free(tmp);


    printf("\n");
    scope_level--;
    
}