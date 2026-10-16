# MARKYS — SISTEMA DE GESTÃO DE ATENDIMENTOS

SGA independente, com identidade visual própria em azul moderno e servidor de rede local fixo na porta **TCP 2222**.

## Acessos na rede local
- Recepção: `http://IP-DO-SERVIDOR:2222/`
- Sala de espera: `http://IP-DO-SERVIDOR:2222/?painel=1`
- Profissional: `http://IP-DO-SERVIDOR:2222/consultorio`
- Atendimento médico geral: `http://IP-DO-SERVIDOR:2222/atendimento`

Os quatro acessos compartilham o servidor local e a porta TCP **2222**; `/atendimento` é uma nova página, não uma nova porta TCP. O prontuário está apenas como protótipo visual: ainda não armazena dados. Não inserir informações reais de pacientes até concluir autenticação, banco clínico, permissões, auditoria e proteção dos dados.

## Arquivos
- `index.html`: interface da recepção e painel de chamadas.
- `servidor-markys.ps1`: servidor HTTP local e sincronização da fila.
- `INICIAR-SERVIDOR-MARKYS.bat`: inicia o servidor para compartilhar a fila na rede.
- `ABRIR-MARKYS.bat`: abre a versão simples em um único computador.
- `fila.json`: dados da fila, no computador local.
- `profissionais.json`: cadastro local dos profissionais.
- `prontuarios.json`: consultas clínicas locais.

## Início rápido — vários dispositivos
1. No GitHub, abra este repositório e clique em **Code > Download ZIP**.
2. Extraia todos os arquivos para uma pasta no computador da recepção (não execute dentro do ZIP).
3. Execute `INICIAR-SERVIDOR-MARKYS.bat`.
4. Se o Firewall do Windows perguntar, permita somente em redes privadas confiáveis. Se necessário, peça ao suporte de TI para criar uma regra de entrada TCP para a porta **2222**, apenas no perfil Privado.
5. A janela do PowerShell mostrará somente três endereços: Recepção, Sala de espera e Consultório. O profissional seleciona o tipo de serviço dentro do próprio painel.
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
- Marca **Chamador de Pacientes Digital** e logotipo original  renomeado para `logo-Markys.png`.
- Limite de 10 consultórios e opções de atendimento: cirurgia, consulta, laboratório, raio-X, audiometria, ASO, exames complementares, medicina ocupacional, retorno, teste ergométrico, ultrassom e outros.
- Nomes automaticamente em maiúsculas; edição sem recriar o paciente; prioridade coloca o paciente no topo.
- Registro de hora de saída ao marcar como atendido.
- Relatório em PDF A4 vertical, com posição, atendimento, consultório, status, entrada e saída.
- Tela de espera mostra até cinco chamadas recentes e até cinco próximos pacientes.
- As páginas abertas pelo mesmo servidor sincronizam a fila automaticamente.

## Três endereços de acesso
O MARKYS usa apenas três endereços, todos com o mesmo IP do computador servidor:
- **Recepção:** `http://IP-DO-SERVIDOR:2222/`
- **Sala de espera:** `http://IP-DO-SERVIDOR:2222/?painel=1`
- **Consultório:** `http://IP-DO-SERVIDOR:2222/consultorio`

No painel único de Consultório, cada profissional seleciona seu tipo de serviço no menu. O fluxo continua: **Chamar na sala**, **Atender** (cartão vermelho) e **Liberar** (cartão verde). O paciente continua disponível para os demais serviços cadastrados até que todos sejam liberados. Substitua `IP-DO-SERVIDOR` pelo IP real exibido na janela do PowerShell.


## Regras de chamada e atendimento por serviço
- Na recepção, o operador deve selecionar explicitamente um consultório e pelo menos um tipo de atendimento.
- A recepção não chama pacientes nem finaliza atendimentos; a chamada só começa quando o profissional clica em **Chamar na sala** no painel Consultório.
- O profissional escolhe se o chamado exibirá o tipo de atendimento ou o consultório.
- Ao liberar um serviço, o paciente permanece na fila enquanto houver outros serviços pendentes. O status geral só muda para Atendido quando todos os serviços estiverem liberados.


## Funcionalidades alinhadas
- O MARKYS compartilha a fila e o painel profissional com o mesmo fluxo de chamadas.
- A tela de espera mostra todas as chamadas ativas, inclusive chamadas do mesmo paciente para atendimentos diferentes, na ordem dos cliques.
- A voz é enfileirada para não cancelar anúncios anteriores.
- O painel de recepção permite gerenciar a apresentação de fotos e vídeos na sala de espera. Cada foto permanece por 20 segundos; cada vídeo avança quando termina.
- A identidade visual permanece MARKYS, com logo próprio e paleta azul. O servidor local usa a porta TCP 2222.
