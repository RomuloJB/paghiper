# Como Pegar Informações do Usuário Logado

## 🚀 Guia Rápido

### 1. **Importar o Provider**
```dart
import 'package:provider/provider.dart';
import 'package:flutter_application_1/Services/AuthProvider.dart';
```

---

## 📋 Métodos Disponíveis

### **Informações Básicas (Getters Rápidos)**
```dart
Consumer<AuthProvider>(
  builder: (context, auth, _) {
    // ✅ Informações do usuário
    String nome = auth.userName;           // Nome do usuário
    String email = auth.userEmail;         // Email do usuário
    int? userId = auth.userId;             // ID do usuário
    
    // ✅ Informações da empresa
    String empresa = auth.companyName;     // Nome da empresa
    int? companyId = auth.companyId;       // ID da empresa
    bool temEmpresa = auth.hasCompany;     // Se tem empresa vinculada
    
    // ✅ Status e permissões
    bool estaLogado = auth.isAuthenticated; // Se está autenticado
    bool eAdmin = auth.isAdmin;            // Se é administrador
    bool eUser = auth.isUser;              // Se é usuário comum
    bool loading = auth.isLoading;         // Se está carregando
    
    return Text('Olá, $nome!');
  },
)
```

### **Objetos Completos**
```dart
Consumer<AuthProvider>(
  builder: (context, auth, _) {
    // ✅ Objeto User completo
    User? usuario = auth.currentUser;
    if (usuario != null) {
      print('ID: ${usuario.id}');
      print('Nome: ${usuario.name}');
      print('Email: ${usuario.email}');
      print('Role: ${usuario.role}');
      print('Company ID: ${usuario.companyId}');
      print('Criado em: ${usuario.createdAt}');
    }
    
    // ✅ Objeto Company completo
    Company? empresa = auth.currentCompany;
    if (empresa != null) {
      print('ID: ${empresa.id}');
      print('Nome: ${empresa.name}');
      print('CNPJ: ${empresa.cnpj}');
      print('Criado em: ${empresa.createdAt}');
    }
    
    return Container();
  },
)
```

---

## 🎯 Formas de Usar

### **FORMA 1: Consumer (Recomendado para UI)**
✅ **Quando usar:** Quando o widget precisa rebuildar ao mudar dados  
✅ **Ideal para:** Textos, labels, cards de perfil, badges

```dart
Consumer<AuthProvider>(
  builder: (context, auth, _) {
    return Text('Olá, ${auth.userName}!');
  },
)
```

### **FORMA 2: Provider.of (Para lógica/métodos)**
✅ **Quando usar:** Dentro de métodos, callbacks, validações  
✅ **Ideal para:** Lógica de negócio, validações, chamadas API

```dart
void meuMetodo(BuildContext context) {
  final auth = Provider.of<AuthProvider>(context, listen: false);
  
  if (auth.isAdmin) {
    // Fazer algo apenas para admins
  }
}
```

### **FORMA 3: context.read (Alternativa moderna)**
✅ **Quando usar:** Equivalente ao Provider.of com listen: false  
✅ **Ideal para:** Código mais limpo e moderno

```dart
void meuMetodo(BuildContext context) {
  final auth = context.read<AuthProvider>();
  print(auth.userName);
}
```

### **FORMA 4: context.watch (Alternativa moderna)**
✅ **Quando usar:** Equivalente ao Consumer  
✅ **Ideal para:** Dentro do método build

```dart
@override
Widget build(BuildContext context) {
  final auth = context.watch<AuthProvider>();
  return Text('Olá, ${auth.userName}!');
}
```

---

## 🔒 Verificar Permissões

```dart
final auth = Provider.of<AuthProvider>(context, listen: false);

// Verificar permissão específica
if (auth.hasPermission('manage_users')) {
  // Usuário pode gerenciar outros usuários
}

// Verificar se pode acessar empresa
if (auth.canAccessCompany(empresaId)) {
  // Pode acessar dados dessa empresa
}

// Verificar role
if (auth.isAdmin) {
  // É administrador
}

if (auth.isUser) {
  // É usuário comum
}
```

---

## 💡 Exemplos Práticos

### **1. Mostrar nome no AppBar**
```dart
AppBar(
  title: Consumer<AuthProvider>(
    builder: (context, auth, _) {
      return Text('Olá, ${auth.userName}');
    },
  ),
)
```

### **2. Botão condicional baseado em role**
```dart
Consumer<AuthProvider>(
  builder: (context, auth, _) {
    if (!auth.isAdmin) return SizedBox.shrink();
    
    return ElevatedButton(
      onPressed: () => Navigator.pushNamed(context, '/admin'),
      child: Text('Painel Admin'),
    );
  },
)
```

### **3. Validar antes de executar ação**
```dart
void deletarContrato(BuildContext context, int contratoId) async {
  final auth = Provider.of<AuthProvider>(context, listen: false);
  
  if (!auth.hasPermission('delete_contracts')) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Sem permissão para deletar')),
    );
    return;
  }
  
  // Executar deleção...
}
```

### **4. Filtrar contratos por empresa do usuário**
```dart
Future<List<Contract>> buscarContratos(BuildContext context) async {
  final auth = Provider.of<AuthProvider>(context, listen: false);
  final dao = ContractDao();
  
  if (auth.isAdmin) {
    // Admin vê todos os contratos
    return await dao.findAll();
  } else {
    // Usuário vê apenas da sua empresa
    return await dao.findByCompanyId(auth.companyId!);
  }
}
```

### **5. Card de perfil do usuário**
```dart
Consumer<AuthProvider>(
  builder: (context, auth, _) {
    return Card(
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: auth.isAdmin ? Colors.red : Colors.blue,
          child: Text(auth.userName[0].toUpperCase()),
        ),
        title: Text(auth.userName),
        subtitle: Text(auth.userEmail),
        trailing: Chip(
          label: Text(auth.isAdmin ? 'Admin' : 'Usuário'),
          backgroundColor: auth.isAdmin ? Colors.red : Colors.blue,
        ),
      ),
    );
  },
)
```

---

## 📊 Tabela Resumo - Propriedades do AuthProvider

| Propriedade | Tipo | Descrição |
|------------|------|-----------|
| `userName` | String | Nome do usuário logado |
| `userEmail` | String | Email do usuário logado |
| `userId` | int? | ID do usuário |
| `companyName` | String | Nome da empresa vinculada |
| `companyId` | int? | ID da empresa |
| `isAuthenticated` | bool | Se há usuário logado |
| `isAdmin` | bool | Se o usuário é admin |
| `isUser` | bool | Se o usuário é comum |
| `hasCompany` | bool | Se tem empresa vinculada |
| `isLoading` | bool | Se está carregando dados |
| `currentUser` | User? | Objeto completo do usuário |
| `currentCompany` | Company? | Objeto completo da empresa |

## 🎓 Métodos do AuthProvider

| Método | Retorno | Descrição |
|--------|---------|-----------|
| `hasPermission(String)` | bool | Verifica se tem permissão |
| `canAccessCompany(int?)` | bool | Verifica acesso à empresa |
| `signIn(email, senha)` | Future<void> | Faz login |
| `signOut()` | Future<void> | Faz logout |

---

## 📱 Arquivo de Exemplo Completo

Criamos um arquivo de exemplo completo em:
📁 `lib/Telas/exemplo/ExemploUsuarioLogado.dart`

Para testar, adicione a rota em `lib/Config/app.dart`:
```dart
'/exemplo-usuario': (context) => const ExemploUsuarioLogado(),
```

---

## ⚠️ Dicas Importantes

1. **Sempre use `listen: false`** quando acessar em métodos (não no build)
2. **Use `Consumer`** quando o widget precisa rebuildar
3. **Sempre verifique `isAuthenticated`** antes de acessar dados
4. **Verifique `null`** ao acessar `currentUser` ou `currentCompany`
5. **Use `context.mounted`** ao chamar Navigator após operações async

```dart
// ✅ Correto
if (context.mounted) {
  Navigator.pushNamed(context, '/home');
}

// ❌ Errado (pode causar erro se widget foi desmontado)
Navigator.pushNamed(context, '/home');
```

---

## 🐛 Troubleshooting

**Erro: "Could not find the correct Provider"**
- ✅ Verifique se o `MultiProvider` está no `main.dart`
- ✅ Certifique-se de estar usando o `context` correto

**Dados não atualizam na tela**
- ✅ Use `Consumer` ao invés de `Provider.of`
- ✅ Ou use `listen: true` (mas isso pode causar rebuilds desnecessários)

**currentUser é null**
- ✅ Verifique se o usuário está logado: `auth.isAuthenticated`
- ✅ Aguarde a inicialização: `auth.isInitialized`
