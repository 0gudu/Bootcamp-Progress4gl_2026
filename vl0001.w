DEFINE BUTTON bt-cidades   LABEL "Cidades".
DEFINE BUTTON bt-filmes    LABEL "Filmes".
DEFINE BUTTON bt-clientes  LABEL "Clientes".
DEFINE BUTTON bt-alugueis  LABEL "Alugueis".
DEFINE BUTTON bt-sair      LABEL "Sair" AUTO-ENDKEY.
DEFINE BUTTON bt-relatCli  LABEL "Relatório de Clientes".
DEFINE BUTTON bt-relatAlg  LABEL "Relatório de Alugueis".

DEFINE FRAME f-menu
    bt-cidades  
    bt-filmes
    bt-clientes
    bt-alugueis
    bt-sair
    bt-relatCli
    bt-relatAlg
    WITH TITLE "Videolocadora VL" VIEW-AS DIALOG-BOX THREE-D WIDTH 50 1 DOWN. 
    
VIEW FRAME f-menu.
ENABLE ALL WITH FRAME f-menu.

ON 'choose':U OF bt-cidades IN FRAME f-menu
DO:
    RUN fonts\vl0010.w.
END.

WAIT-FOR ENDKEY OF bt-sair IN FRAME f-menu.
    
