USING PROGRESS.json.ObjectModel.JsonObject.
USING PROGRESS.json.ObjectModel.JsonArray.

DEFINE BUFFER bf-clientes FOR clientes.

DEFINE BUTTON bt-first     LABEL "<<".
DEFINE BUTTON bt-prev      LABEL "<".
DEFINE BUTTON bt-prox      LABEL ">".
DEFINE BUTTON bt-last      LABEL ">>".
DEFINE BUTTON bt-edit      LABEL "Edit".
DEFINE BUTTON bt-add       LABEL "Adicionar".
DEFINE BUTTON bt-cancel    LABEL "Cancel".
DEFINE BUTTON bt-delete    LABEL "Deletar".
DEFINE BUTTON bt-relat     LABEL "Exportar".
DEFINE BUTTON bt-sair      LABEL "Sair" AUTO-ENDKEY.

DEFINE VARIABLE c-nomCidade AS CHARACTER   NO-UNDO.
DEFINE VARIABLE lg-edit    AS LOGICAL   NO-UNDO INITIAL NO.
DEFINE VARIABLE lg-add     AS LOGICAL   NO-UNDO INITIAL NO.
DEFINE VARIABLE l-choise AS LOGICAL     NO-UNDO.

DEFINE VARIABLE c-erros AS CHARACTER   NO-UNDO.

DEFINE QUERY q-query FOR clientes, cidades SCROLLING.

DEFINE FRAME f-clientes
  bt-first   AT ROW 1 COL 5 
  bt-prev    AT ROW 1 COL 9 
  bt-prox    AT ROW 1 COL 12 
  bt-last    AT ROW 1 COL 15 
  bt-edit    AT ROW 1 COL 20 
  bt-cancel  AT ROW 1 COL 27
  bt-delete  AT ROW 1 COL 36
  bt-add     AT ROW 1 COL 45
  bt-relat   AT ROW 1 COL 90
  bt-sair    AT ROW 1 COL 100
  SKIP(0.5)
  clientes.codCliente  COLON 15
  clientes.nomCliente  COLON 15
  clientes.codEndereco COLON 15
  clientes.codCidade   COLON 15 LABEL "Cidade" cidades.nomCidade NO-LABELS
  clientes.observacao  COLON 15
  WITH TITLE "clientes" SIDE-LAB WIDTH 110 THREE-D VIEW-AS DIALOG-BOX.

OPEN QUERY q-query FOR EACH clientes NO-LOCK, 
                       FIRST cidades NO-LOCK 
                       WHERE cidades.codCidade = clientes.codCidade. 

GET FIRST q-query.
                
RUN pi-habilita.
RUN pi-mostra.

DEFINE VARIABLE hand-frame AS WIDGET-HANDLE NO-UNDO.
DEFINE VARIABLE h-handle AS HANDLE NO-UNDO.

ASSIGN hand-frame = FRAME f-clientes:HANDLE.

ON CHOOSE OF bt-first  DO:
    RUN pi-navega(INPUT "first"). 
END.

ON CHOOSE OF bt-prev  DO:
    RUN pi-navega(INPUT "prev").
END.

ON CHOOSE OF bt-prox  DO:
    RUN pi-navega(INPUT "next").
END.

ON CHOOSE OF bt-last  DO:
    RUN pi-navega(INPUT "last").
END.

ON CHOOSE OF bt-edit  DO:
    IF lg-edit THEN
    DO:
        RUN pi-atualizadados(OUTPUT c-erros).
        IF c-erros <> "" THEN
            RETURN.
        RUN pi-esconde-campos.
        
        IF lg-add THEN
            RUN pi-navega(INPUT "last").
            
        ASSIGN bt-edit:LABEL        = "edit"
               lg-edit = NO
               lg-add  = NO.
    END.
    ELSE DO:
        IF AVAIL clientes THEN
        DO:
            ASSIGN bt-edit:LABEL        = "save".
            RUN pi-habilita-campos.
            DISABLE bt-first bt-prox bt-prev bt-last bt-add bt-delete WITH FRAME f-clientes.
            ASSIGN lg-edit = YES.     
        END.
    END.
END.

ON 'choose':U OF bt-delete
DO:
    IF AVAIL clientes THEN
    DO:
        MESSAGE "Deseja deletar o registro?"
            VIEW-AS ALERT-BOX INFORMATION BUTTONS YES-NO UPDATE l-choise.
        IF l-choise THEN
        DO:
            FIND FIRST bf-clientes EXCLUSIVE-LOCK
                 WHERE bf-clientes.codCliente = clientes.codCliente.
            DELETE bf-clientes.
            RUN pi-navega(INPUT "next").
        END.    
    END.
END.

ON CHOOSE OF bt-cancel  DO:
        ASSIGN bt-edit:LABEL        = "edit". 
        RUN pi-esconde-campos.
        RUN pi-mostra.
     ASSIGN lg-edit = NO
            lg-add  = NO.    
END.

ON CHOOSE OF bt-add  DO:
    ASSIGN bt-edit:LABEL        = "save"
           lg-edit              = YES
           lg-add               = YES.
           
    RUN pi-habilita-campos.
    DISABLE bt-first bt-prox bt-prev bt-last bt-add bt-delete WITH FRAME f-clientes.        
    
    FIND LAST bf-clientes NO-LOCK NO-ERROR.
    IF NOT AVAIL bf-clientes THEN
            DISPLAY 1 @ clientes.codCliente WITH FRAME f-clientes.       
    ELSE
        DISPLAY (bf-clientes.codCliente + 1) @ clientes.codCliente WITH FRAME f-clientes.

    RUN pi-esvaziavalores.
END.


ON 'leave':U OF clientes.codCidade IN FRAME f-clientes
DO:
    FIND FIRST cidades NO-LOCK
         WHERE cidades.codCidade = int(clientes.codCidade:SCREEN-VALUE IN FRAME f-clientes) NO-ERROR.
         
    IF NOT AVAIL cidades THEN DO:
        MESSAGE "Cidade não encontrada!"
            VIEW-AS ALERT-BOX INFORMATION BUTTONS OK.
        RETURN NO-APPLY. 
    END.
    
    DISPLAY cidades.nomCidade 
        WITH FRAME f-clientes. 
          
END.

ON CHOOSE OF bt-relat  DO:
    RUN pi-exporta.
END.

//PROCEDURES INTERNAS
PROCEDURE pi-navega:
    DEFINE INPUT PARAM c-tipo AS CHARACTER.
    
    CASE c-tipo:
        WHEN "first" THEN
        DO:
            GET FIRST q-query.
        END.
        
        WHEN "prev" THEN
        DO:
            GET PREV q-query.
            IF NOT AVAIL clientes THEN
            DO:
                APPLY 'choose':U TO bt-last IN FRAME f-clientes.
            END.       
        END.
        
        WHEN "next" THEN
        DO:
            GET NEXT q-query.
            IF NOT AVAIL clientes THEN
            DO:
                APPLY 'choose':U TO bt-first IN FRAME f-clientes. 
            END.
        END.
        
        WHEN "last" THEN
        DO:
            GET LAST q-query.
        END.
    END CASE.
    
    RUN pi-mostra.
    
END PROCEDURE.

PROCEDURE pi-mostra:
    IF AVAIL clientes THEN
    DO:
        DISPLAY clientes WITH FRAME f-clientes.
        DISPLAY cidades.nomCidade WITH FRAME f-clientes.
    END.
    ELSE DO:
        OPEN QUERY q-query FOR EACH clientes NO-LOCK, 
                       FIRST cidades NO-LOCK 
                       WHERE cidades.codCidade = clientes.codCidade. 
        GET FIRST q-query.
        IF AVAIL clientes THEN DO:
            DISPLAY 
                clientes
             WITH FRAME f-clientes.
             DISPLAY cidades.nomCidade WITH FRAME f-clientes.
        END.
             
        ELSE
             DISPLAY 
                "" @ clientes.codCliente
                "" @ clientes.nomCliente
                "" @ clientes.codEndereco
                "" @ clientes.codCidade
                "" @ clientes.observacao
                "" @ cidades.nomCidade
             WITH FRAME f-clientes.
        
    END.
END PROCEDURE.

PROCEDURE pi-habilita-campos:
    ENABLE bt-cancel WITH FRAME f-clientes.
    RUN pi-campos-sensitive(INPUT YES).
END PROCEDURE.

PROCEDURE pi-esconde-campos:
    ENABLE  bt-first bt-prev bt-prox bt-last bt-add bt-delete WITH FRAME f-clientes.
    DISABLE bt-cancel WITH FRAME f-clientes.
    RUN pi-campos-sensitive(INPUT NO).
END PROCEDURE.
            
PROCEDURE pi-habilita:
    ENABLE bt-first bt-prev bt-prox bt-last bt-edit bt-add bt-delete bt-relat bt-sair WITH FRAME f-clientes.
END.

PROCEDURE pi-atualizadados:
    DEFINE OUTPUT PARAMETER c-erros AS CHARACTER.
    
    RUN pi-checavazios(OUTPUT c-erros).
    IF c-erros <> "" THEN
    DO:
        MESSAGE "Os campos abaixo são mandatórios e estão vazios!" SKIP c-erros
            VIEW-AS ALERT-BOX ERROR BUTTONS OK.
        RETURN.    
    END.
    
    IF lg-add THEN
    DO:
        CREATE bf-clientes.
        ASSIGN bf-clientes.codCliente = int(clientes.codCliente:SCREEN-VALUE IN FRAME f-clientes). 
    END.
    ELSE 
        FIND FIRST bf-clientes EXCLUSIVE-LOCK
             WHERE bf-clientes.codCliente = clientes.codCliente.
    
             
    ASSIGN  bf-clientes.codCliente     =  integer(clientes.codCliente:SCREEN-VALUE IN FRAME f-clientes)
            bf-clientes.nomCliente     =  clientes.nomCliente:screen-value in frame f-clientes
            bf-clientes.codEndereco    =  clientes.codEndereco:screen-value in frame f-clientes
            bf-clientes.codCidade      =  integer(clientes.codCidade:screen-value in frame f-clientes)
            bf-clientes.observacao     =  clientes.observacao:screen-value in frame f-clientes.  

END PROCEDURE.

PROCEDURE pi-exporta:
    DEFINE VARIABLE oObj  AS JsonObject  NO-UNDO.
    DEFINE VARIABLE aList AS JsonArray   NO-UNDO.
    DEFINE VARIABLE c-arq AS CHARACTER   NO-UNDO.
    
    ASSIGN c-arq = SESSION:TEMP-DIRECTORY + "clientes."
           aList = NEW JsonArray().
           
    OUTPUT TO VALUE(c-arq + "csv").
        PUT UNFORMATTED "Codigo;"
                        "Nome;"
                        "Endereco;"
                        "Codigo_Cidade;"
                        "Observacao;"
                        SKIP.
    FOR EACH bf-clientes NO-LOCK:
        PUT UNFORMATTED string(clientes.codCliente)  ";"
                        clientes.nomCliente          ";"
                        clientes.codEndereco         ";"
                        string(clientes.codcidade)   ";"
                        clientes.observacao          ";"
                        SKIP. 
        oObj = NEW JsonObject().
        oObj:ADD('Codigo', clientes.codCliente).
        oObj:ADD('Nome', clientes.nomCliente).
        oObj:ADD('Endereco', clientes.codEndereco).
        oObj:ADD('Codigo_Cidade', clientes.codCidade).
        oObj:ADD('Observacao', clientes.observacao).
        aList:ADD(oObj).
    END.
    OUTPUT CLOSE.
    
    aList:WriteFile((c-arq + "json"), YES).
    OS-COMMAND NO-WAIT VALUE(c-arq + "csv").
    OS-COMMAND NO-WAIT VALUE(c-arq + "json").
END PROCEDURE.

//MANIPULAÇÃO DE CAMPOS EM MASSA
PROCEDURE pi-campos-sensitive:
    DEFINE INPUT PARAM lg-enable AS LOGICAL NO-UNDO.

    DEFINE VARIABLE hand-frame AS WIDGET-HANDLE NO-UNDO.
    DEFINE VARIABLE h-objeto   AS WIDGET-HANDLE NO-UNDO.

    ASSIGN hand-frame = FRAME f-clientes:HANDLE.
    ASSIGN h-objeto   = hand-frame:FIRST-CHILD.

    DO WHILE VALID-HANDLE (h-objeto):
        IF h-objeto:TYPE = "FILL-IN" AND h-objeto:NAME <> "codCliente" AND h-objeto:NAME <> "nomCidade" THEN DO:
            ASSIGN h-objeto:SENSITIVE = lg-enable.
        END.

        IF h-objeto:TYPE = "field-group" THEN
        DO:
            ASSIGN h-objeto = h-objeto:FIRST-CHILD.        
        END.
        ELSE
            ASSIGN h-objeto = h-objeto:NEXT-SIBLING.
        
    END.
    RETURN "NOK":U.
END PROCEDURE.

PROCEDURE pi-esvaziavalores:
    DEFINE VARIABLE hand-frame AS WIDGET-HANDLE NO-UNDO.
    DEFINE VARIABLE h-objeto   AS WIDGET-HANDLE NO-UNDO.

    ASSIGN hand-frame = FRAME f-clientes:HANDLE.
    ASSIGN h-objeto   = hand-frame:FIRST-CHILD.

    DO WHILE VALID-HANDLE (h-objeto):
        IF h-objeto:TYPE = "FILL-IN" AND h-objeto:NAME <> "codCliente" THEN DO:
            ASSIGN h-objeto:SCREEN-VALUE = "".
        END.

        IF h-objeto:TYPE = "field-group" THEN
        DO:
            ASSIGN h-objeto = h-objeto:FIRST-CHILD.        
        END.
        ELSE
            ASSIGN h-objeto = h-objeto:NEXT-SIBLING.
        
    END.
    RETURN "NOK":U.
END PROCEDURE.

PROCEDURE pi-checavazios:
    DEFINE VARIABLE hand-frame AS WIDGET-HANDLE NO-UNDO.
    DEFINE VARIABLE h-objeto   AS WIDGET-HANDLE NO-UNDO.
    DEFINE OUTPUT PARAMETER c-erros    AS CHARACTER   INIT "".

    ASSIGN hand-frame = FRAME f-clientes:HANDLE.
    ASSIGN h-objeto   = hand-frame:FIRST-CHILD.

    DO WHILE VALID-HANDLE (h-objeto):
       IF h-objeto:TYPE = "FILL-IN" AND h-objeto:NAME <> "nomCidade" THEN DO:
                
            FIND FIRST _file NO-LOCK
                 WHERE _file._file-name = "clientes".
            FIND FIRST _field OF _file NO-LOCK
                 WHERE _field._field-name = h-objeto:NAME.
            
            IF _field._mandatory AND h-objeto:SCREEN-VALUE = "" THEN
            DO:
                IF c-erros = "" THEN
                    ASSIGN c-erros = h-objeto:LABEL.
                ELSE 
                    ASSIGN c-erros = c-erros + ", " + h-objeto:LABEL.
            END.
            ELSE IF h-objeto:NAME = "codCidade" THEN
            DO:
                //FAZ A VALIDAÇÃO SE O CODIGO DA CIDADE É VALIDO PARA SALVAR
                FIND FIRST cidades NO-LOCK
                     WHERE cidades.codCidade = int(h-objeto:SCREEN-VALUE) NO-ERROR.
                     
                IF NOT AVAIL cidades THEN
                    ASSIGN c-erros = c-erros + ", " + h-objeto:LABEL.
            END.
                
        END.

        IF h-objeto:TYPE = "field-group" THEN
        DO:
            ASSIGN h-objeto = h-objeto:FIRST-CHILD.        
        END.
        ELSE
            ASSIGN h-objeto = h-objeto:NEXT-SIBLING.
        
    END.
    RETURN.
END PROCEDURE.

WAIT-FOR ENDKEY OF bt-sair IN FRAME f-clientes.


