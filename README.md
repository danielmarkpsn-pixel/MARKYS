# MARKYS — Chamador de pacientes

Clone independente baseado na estrutura do FAVMED, com identidade visual própria em azul moderno e servidor de rede local fixo na porta **TCP 2222**.

## Arquivos
- `index.html`: interface da recepção e painel de chamadas.
- `servidor-markys.ps1`: servidor HTTP local e sincronização da fila.
- `INICIAR-SERVIDOR-MARKYS.bat`: inicia o servidor para compartilhar a fila na rede.
- `ABRIR-MARKYS.bat`: abre a versão simples em um único computador.
- `fila.json`: arquivo inicial da fila; os dados reais permanecem no computador local.

## Início rápido — vários dispositivos
1. No GitHub, abra este repositório e clique em **Code > Download ZIP**.
2. Extraia todos os arquivos para uma pasta no computador da recepção (não execute dentro do ZIP).
3. Execute `INICIAR-SERVIDOR-MARKYS.bat`.
4. Se o Firewall do Windows perguntar, permita somente em redes privadas confiáveis. Se necessário, peça ao suporte de TI para criar uma regra de entrada TCP para a porta **2222**, apenas no perfil Privado.
5. A janela do PowerShell mostrará os endereços da recepção e do painel. Na tela adicional, use o endereço da sala que termina em `/?painel=1`.
6. Mantenha a janela do servidor aberta enquanto o sistema estiver em uso.

## Recursos
- Cadastro manual de pacientes, consultório e tipo de atendimento.
- Chamada por voz, repetição, busca, status de atendimento, remoção e exportação CSV.
- Painel de sala de espera com atualização automática e opção de ativar voz na própria tela.
- Fila compartilhada em arquivo JSON na máquina que executa o servidor.
- Layout responsivo para computador, tablet e tela maior.

## Importante
O servidor usa HTTP sem login ou criptografia. Use apenas em uma rede interna confiável, nunca em Wi-Fi de visitantes, e não encaminhe a porta 2222 para a internet. Não coloque diagnósticos, CPF ou informações clínicas na fila; mostre somente os dados mínimos necessários. Restrinja o acesso à pasta e faça cópias de segurança de acordo com as regras da organização.

A porta é fixa: se a TCP 2222 já estiver ocupada, o servidor não muda automaticamente para outra porta. O suporte de TI deverá liberar ou escolher outra porta e atualizar o script e as instruções em conjunto.

**Crédito:** Desenvolvido por Daniel Marques via IA.


## Atualizações desta versão
- Marca **Chamador de Pacientes Digital** e logotipo original do FAVMED renomeado para `logo-Markys.png`.
- Limite de 10 consultórios e opções de atendimento: cirurgia, consulta, laboratório, raio-X, audiometria, ASO, exames complementares, medicina ocupacional, retorno, teste ergométrico, ultrassom e outros.
- Nomes automaticamente em maiúsculas; edição sem recriar o paciente; prioridade coloca o paciente no topo.
- Registro de hora de saída ao marcar como atendido.
- Relatório em PDF A4 vertical, com posição, atendimento, consultório, status, entrada e saída.
- Tela de espera mostra até cinco chamadas recentes e até cinco próximos pacientes.
- As páginas abertas pelo mesmo servidor sincronizam a fila automaticamente.

## Painéis individuais por tipo de atendimento
O servidor agora disponibiliza `consultorio.html` em `/consultorio`. Cada profissional pode usar o mesmo IP do computador servidor, com um endereço diferente por serviço. Ao iniciar o servidor, a janela PowerShell mostra os links prontos de Cirurgia, Consulta, Laboratório, Raio-X e demais serviços.

Fluxo: o profissional clica em **Chamar na sala**; a tela de espera anuncia o nome e o tipo de atendimento. Ao clicar em **Atender**, o cartão do paciente fica vermelho na tela da sala. Ao clicar em **Liberar**, fica verde. O paciente continua disponível nos painéis dos outros serviços cadastrados até que todos os serviços sejam liberados.

Exemplo de endereço: `http://IP-DO-SERVIDOR:2222/consultorio?servico=Consulta`. Substitua pelo IP real mostrado ao iniciar o servidor. Todos os dispositivos devem usar o mesmo servidor e estar na rede local confiável.
