-- Script para criar usuários de teste no sistema de autenticação
-- Execute este script após inicializar o banco de dados

-- Criar empresa de teste
INSERT OR IGNORE INTO companies (id, name, cnpj, created_at)
VALUES 
  (1, 'Empresa Teste LTDA', '12.345.678/0001-90', datetime('now')),
  (2, 'Outra Empresa ME', '98.765.432/0001-10', datetime('now'));

-- Criar usuário administrador
INSERT OR IGNORE INTO users (id, name, email, password, role, created_at)
VALUES (1, 'Admin Sistema', 'admin@paghiper.com', 'admin123', 'admin', datetime('now'));

-- Criar usuário comum vinculado à empresa 1
INSERT OR IGNORE INTO users (id, name, email, password, role, company_id, created_at)
VALUES (2, 'João Silva', 'joao@paghiper.com', 'senha123', 'user', 1, datetime('now'));

-- Criar usuário comum vinculado à empresa 2
INSERT OR IGNORE INTO users (id, name, email, password, role, company_id, created_at)
VALUES (3, 'Maria Santos', 'maria@paghiper.com', 'senha123', 'user', 2, datetime('now'));

-- Criar usuário comum sem empresa
INSERT OR IGNORE INTO users (id, name, email, password, role, created_at)
VALUES (4, 'Pedro Costa', 'pedro@paghiper.com', 'senha123', 'user', datetime('now'));

-- Verificar usuários criados
SELECT 
  u.id,
  u.name,
  u.email,
  u.role,
  u.company_id,
  c.name as company_name
FROM users u
LEFT JOIN companies c ON u.company_id = c.id
ORDER BY u.id;

/*
CREDENCIAIS DE TESTE:

ADMIN:
  Email: admin@paghiper.com
  Senha: admin123
  Acesso: TOTAL (todas as empresas e funcionalidades)

USUÁRIO 1:
  Email: joao@paghiper.com
  Senha: senha123
  Empresa: Empresa Teste LTDA
  Acesso: Limitado (apenas dados da própria empresa)

USUÁRIO 2:
  Email: maria@paghiper.com
  Senha: senha123
  Empresa: Outra Empresa ME
  Acesso: Limitado (apenas dados da própria empresa)

USUÁRIO 3:
  Email: pedro@paghiper.com
  Senha: senha123
  Empresa: Nenhuma
  Acesso: Limitado (sem acesso a dados de empresas)

NOTA: Em produção, as senhas devem ser criptografadas (hash)!
Este script é apenas para desenvolvimento/teste.
*/
