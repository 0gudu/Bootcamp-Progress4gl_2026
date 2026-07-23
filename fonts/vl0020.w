USING PROGRESS.json.ObjectModel.JsonObject.
USING PROGRESS.json.ObjectModel.JsonArray.

DEFINE BUFFER bf-filmes FOR filmes.

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
DEFINE VARIABLE lg-edit    AS LOGICAL   NO-UNDO INITIAL NO.
DEFINE VARIABLE lg-add     AS LOGICAL   NO-UNDO INITIAL NO.
DEFINE VARIABLE l-choise AS LOGICAL     NO-UNDO.

DEFINE VARIABLE c-erros AS CHARACTER   NO-UNDO.

DEFINE QUERY q-query FOR filmes SCROLLING.

DEFINE FRAME f-filmes
  bt-first  AT ROW 1 COL 5
  bt-prev   AT ROW 1 COL 9
  bt-prox   AT ROW 1 COL 12
  bt-last   AT ROW 1 COL 15
  bt-edit   AT ROW 1 COL 20
  bt-cancel AT ROW 1 COL 27
  bt-delete AT ROW 1 COL 36
  bt-add    AT ROW 1 COL 45
  bt-relat  AT ROW 1 COL 90
  bt-sair   AT ROW 1 COL 100
  SKIP(0.5)
  WITH TITLE "filmes" CENTERED SIDE-LAB WIDTH 110 THREE-D VIEW-AS DIALOG-BOX.

OPEN QUERY q-query FOR EACH filmes NO-LOCK. 

GET FIRST q-query.
                
RUN pi-habilita.
RUN pi-mostra.

DEFINE VARIABLE hand-frame AS WIDGET-HANDLE NO-UNDO.
DEFINE VARIABLE h-handle AS HANDLE NO-UNDO.

ASSIGN hand-frame = FRAME f-filmes:HANDLE.

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
        IF AVAIL filmes THEN
        DO:
            ASSIGN bt-edit:LABEL        = "save".
            RUN pi-habilita-campos.
            DISABLE bt-first bt-prox bt-prev bt-last bt-add bt-delete WITH FRAME f-filmes.
            ASSIGN lg-edit = YES.     
        END.
    END.
END.

ON 'choose':U OF bt-delete
DO:
    IF AVAIL filmes THEN
    DO:
        MESSAGE "Deseja deletar o registro?"
            VIEW-AS ALERT-BOX INFORMATION BUTTONS YES-NO UPDATE l-choise.
        IF l-choise THEN
        DO:
            FIND FIRST bf-filmes EXCLUSIVE-LOCK
                 WHERE bf-filmes.codFilme = filmes.codFilme.
            DELETE bf-filmes.
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
    DISABLE bt-first bt-prox bt-prev bt-last bt-add bt-delete WITH FRAME f-filmes.        
    
    FIND LAST bf-filmes NO-LOCK NO-ERROR.
    IF NOT AVAIL bf-filmes THEN
            DISPLAY 1 @ filmes.codFilme WITH FRAME f-filmes.       
    ELSE
        DISPLAY (bf-filmes.codFilme + 1) @ filmes.codFilme WITH FRAME f-filmes.

    RUN pi-esvaziavalores.
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
            IF NOT AVAIL filmes THEN
            DO:
                APPLY 'choose':U TO bt-last IN FRAME f-filmes.
            END.       
        END.
        
        WHEN "next" THEN
        DO:
            GET NEXT q-query.
            IF NOT AVAIL filmes THEN
            DO:
                APPLY 'choose':U TO bt-first IN FRAME f-filmes. 
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
    IF AVAIL filmes THEN
    DO:
        DISPLAY filmes WITH CENTERED 1 COL  FRAME f-filmes.    
    END.
    ELSE DO:
        OPEN QUERY q-query FOR EACH filmes NO-LOCK.
        GET FIRST q-query.
        IF AVAIL filmes THEN
             DISPLAY 
                filmes
             WITH CENTERED 1 COL  FRAME f-filmes.
        ELSE
             DISPLAY 
                "" @ filmes.codFilme
                "" @ filmes.nomFilme
                "" @ filmes.valFilme
             WITH CENTERED 1 COL  FRAME f-filmes.
        
    END.
END PROCEDURE.

PROCEDURE pi-habilita-campos:
    ENABLE bt-cancel WITH FRAME f-filmes.
    RUN pi-campos-sensitive(INPUT YES).
END PROCEDURE.

PROCEDURE pi-esconde-campos:
    ENABLE  bt-first bt-prev bt-prox bt-last bt-add bt-delete WITH FRAME f-filmes.
    DISABLE bt-cancel WITH FRAME f-filmes.
    RUN pi-campos-sensitive(INPUT NO).
END PROCEDURE.
            
PROCEDURE pi-habilita:
    ENABLE bt-first bt-prev bt-prox bt-last bt-edit bt-add bt-delete bt-relat bt-sair WITH FRAME f-filmes.
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
        CREATE bf-filmes.
        ASSIGN bf-filmes.codFilme = int(filmes.codFilme:SCREEN-VALUE IN FRAME f-filmes). 
    END.
    ELSE 
        FIND FIRST bf-filmes EXCLUSIVE-LOCK
             WHERE bf-filmes.codFilme = filmes.codFilme.
    
             
    ASSIGN  bf-filmes.codFilme     =  integer(filmes.codFilme:SCREEN-VALUE IN FRAME f-filmes)
            bf-filmes.nomFilme     =  filmes.nomFilme:screen-value in frame f-filmes
            bf-filmes.valFilme     =  decimal(filmes.valFilme:screen-value in frame f-filmes).  

END PROCEDURE.

PROCEDURE pi-exporta:
    DEFINE VARIABLE oObj  AS JsonObject  NO-UNDO.
    DEFINE VARIABLE aList AS JsonArray   NO-UNDO.
    DEFINE VARIABLE c-arq AS CHARACTER   NO-UNDO.
    
    ASSIGN c-arq = SESSION:TEMP-DIRECTORY + "filmes."
           aList = NEW JsonArray().
           
    OUTPUT TO VALUE(c-arq + "csv").
        PUT UNFORMATTED "Codigo;"
                        "Nome;"
                        "Valor;"
                        SKIP.
    FOR EACH bf-filmes NO-LOCK:
        PUT UNFORMATTED string(filmes.codFilme)  ";"
                        filmes.nomfilme              ";"
                        string(filmes.valfilme)          ";"
                        SKIP. 
        oObj = NEW JsonObject().
        oObj:ADD('Codigo', filmes.codFilme).
        oObj:ADD('Nome', filmes.nomfilme).
        oObj:ADD('Valor', filmes.valfilme).
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

    ASSIGN hand-frame = FRAME f-filmes:HANDLE.
    ASSIGN h-objeto   = hand-frame:FIRST-CHILD.

    DO WHILE VALID-HANDLE (h-objeto):
        IF h-objeto:TYPE = "FILL-IN" AND h-objeto:NAME <> "codFilme" THEN DO:
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

    ASSIGN hand-frame = FRAME f-filmes:HANDLE.
    ASSIGN h-objeto   = hand-frame:FIRST-CHILD.

    DO WHILE VALID-HANDLE (h-objeto):
        IF h-objeto:TYPE = "FILL-IN" AND h-objeto:NAME <> "codFilme" THEN DO:
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

    ASSIGN hand-frame = FRAME f-filmes:HANDLE.
    ASSIGN h-objeto   = hand-frame:FIRST-CHILD.

    DO WHILE VALID-HANDLE (h-objeto):
       IF h-objeto:TYPE = "FILL-IN" THEN DO:
                
            FIND FIRST _file NO-LOCK
                 WHERE _file._file-name = "filmes".
            FIND FIRST _field OF _file NO-LOCK
                 WHERE _field._field-name = h-objeto:NAME.
            
            IF _field._mandatory AND h-objeto:SCREEN-VALUE = "" THEN
            DO:
                IF c-erros = "" THEN
                    ASSIGN c-erros = h-objeto:LABEL.
                ELSE 
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

WAIT-FOR ENDKEY OF bt-sair IN FRAME f-filmes.


