# Dívidas técnicas temporárias

## Remover Modo Demonstração antes da versão final

O StudyFlow possui temporariamente um bypass de autenticação exclusivo para ambiente de desenvolvimento, utilizado para facilitar testes e demonstrações durante a construção do aplicativo.

Antes da versão final/release:

- [ ] remover ou desabilitar definitivamente o endpoint de sessão demo;
- [ ] remover o bypass automático do Flutter;
- [ ] garantir que todo acesso ao aplicativo passe pela autenticação normal;
- [ ] validar que builds release não possuem nenhum caminho de autenticação demo;
- [ ] revisar documentação relacionada ao modo demo.

O usuário demo é compartilhado e comum, sem privilégios administrativos. Nunca usar esse ambiente ou seus dados como conta pessoal/produção. Os guards atuais de debug/development não substituem a remoção desta funcionalidade antes da versão final.
