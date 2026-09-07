# Screenshots para o relatorio

Mapeamento de prints de validação do sistema:

| Arquivo | Conteudo |
|---------|----------|
| `01-initial-configs` | Clone do projeto, instalação do k3s via script e teste inicial de deploy (que falhou). Git pull novamente após correções no arquivo para funcionar no killercoda |
| `02-starting-deploy` | Deploy iniciado via script |
| `03-successfull-deploy-and-monitoring` | Deploy finalizado e visualização dos pods OK |
| `04-wordpress-login` | Tela de login do wordpress, após configurar adequadamente um usuario na tela inicial |
| `05-add-persistence-check-post` | Tela de posts do wordpress, no qual adicionei um post de teste de persistencia |
| `06-delete-pods-to-check-persistence` | Verificação e deleção dos pods do wordpress e mysql, com verificação pós restart |
| `07-persisted-successfully` | Validação da persistencia pós deleção do pod via wordpress - Post de "Persistence check" continua lá |
