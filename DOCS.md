# 📚 JRV - Documentação Completa

> **Versão:** 1.0.0  
> **Última Atualização:** 07/02/2026  
> **Desenvolvedor Original:** William Ferreira  

---

## 📋 Índice

1. [Visão Geral](#visão-geral)
2. [Tech Stack](#tech-stack)
3. [Estrutura do Projeto](#estrutura-do-projeto)
4. [Instalação e Configuração](#instalação-e-configuração)
5. [Design System](#design-system)
6. [Arquitetura de Páginas](#arquitetura-de-páginas)
7. [Componentes](#componentes)
8. [Database Schema](#database-schema)
9. [Tipos TypeScript](#tipos-typescript)
10. [Funcionalidades Implementadas](#funcionalidades-implementadas)
11. [Funcionalidades Pendentes](#funcionalidades-pendentes)
12. [Guia de Desenvolvimento](#guia-de-desenvolvimento)
13. [Deploy](#deploy)
14. [Troubleshooting](#troubleshooting)

---

## 🎯 Visão Geral

**JRV** é um sistema de gerenciamento de relacionamento com clientes (CRM) imobiliário desenvolvido com Nuxt 4, focado em gestão de leads, conversas via WhatsApp, catálogo de imóveis e análise de métricas de vendas.

### Objetivos do Projeto
- Gerenciar leads em pipeline Kanban
- Visualizar conversas de WhatsApp
- Analisar métricas e relatórios
- Interface Dark Premium com verde neon (#00E096)

---

## 🛠️ Tech Stack

### Core Framework
- **Nuxt 4.3.0** - Framework Vue.js full-stack
- **Vue 3.5.27** - Framework JavaScript reativo
- **TypeScript** - Tipagem estática

### UI & Styling
- **TailwindCSS 6.14.0** - Framework CSS utility-first
- **Lucide Vue Next 0.563.0** - Biblioteca de ícones
- **Vue Draggable Plus 0.6.1** - Drag & drop para Kanban

### Backend & Database
- **Supabase** - Backend as a Service (BaaS)
  - PostgreSQL database
  - Authentication
  - Real-time subscriptions
- **@nuxtjs/supabase 2.0.3** - Módulo Nuxt para Supabase

### Roteamento
- **Vue Router 4.6.4** - Roteamento SPA

---

## 📁 Estrutura do Projeto

```
jrv/
├── .agent/                    # Configurações de agentes AI
├── .env                       # Variáveis de ambiente (Supabase)
├── .git/                      # Controle de versão Git
├── .gitignore                 # Arquivos ignorados pelo Git
├── .nuxt/                     # Build artifacts (gerado)
├── node_modules/              # Dependências npm
├── public/                    # Assets estáticos
│   ├── favicon.ico
│   └── robots.txt
├── app.vue                    # Root component
├── nuxt.config.ts             # Configuração Nuxt
├── package.json               # Dependências e scripts
├── tailwind.config.ts         # Configuração TailwindCSS
├── tsconfig.json              # Configuração TypeScript
│
├── components/                # Componentes Vue reutilizáveis
│   ├── BaseButton.vue         # Botão base
│   ├── BaseInput.vue          # Input base
│   ├── Sidebar.vue            # Sidebar de navegação
│   ├── ThemeToggle.vue        # Toggle dark/light mode
│   ├── crm/
│   │   ├── KanbanBoard.vue    # Board Kanban drag & drop
│   │   └── LeadTable.vue      # Tabela de leads
│   └── leads/
│       └── LeadDetailsModal.vue # Modal de detalhes do lead
│
├── pages/                     # Páginas (auto-roteadas)
│   ├── index.vue              # Página inicial (/)
│   ├── login.vue              # Login (/login)
│   ├── cadastro.vue           # Cadastro (/cadastro)
│   ├── dashboard.vue          # Dashboard (/dashboard)
│   ├── crm.vue                # CRM Kanban (/crm)
│   ├── contatos.vue           # Lista de contatos (/contatos)
│   ├── chats.vue              # Visualização de chats (/chats)
│   ├── relatorios.vue         # Relatórios (/relatorios)
│   └── design-system.vue      # Design system showcase
│
└── types/                     # Definições TypeScript
    ├── crm.ts                 # Tipos CRM (Cliente, CrmStatus)
    └── database.types.ts      # Tipos gerados do Supabase
```

---

## ⚙️ Instalação e Configuração

### 1. Pré-requisitos
- **Node.js** >= 18.x
- **npm** ou **yarn**
- **Git**
- Conta **Supabase** (para database)

### 2. Clone o Repositório
```bash
git clone https://github.com/williamferreiraDev/crmDATAimpetus.git
cd jrv
```

### 3. Instalar Dependências
```bash
npm install
```

### 4. Configurar Variáveis de Ambiente

Crie um arquivo `.env` na raiz do projeto:

```env
SUPABASE_URL=https://seu-projeto.supabase.co
SUPABASE_KEY=sua-chave-anon-publica
```

**Onde encontrar:**
1. Acesse [Supabase Dashboard](https://app.supabase.com)
2. Selecione seu projeto
3. Vá em **Settings** → **API**
4. Copie:
   - **Project URL** → `SUPABASE_URL`
   - **anon public** key → `SUPABASE_KEY`

### 5. Executar Servidor de Desenvolvimento
```bash
npm run dev
```

Acesse: `http://localhost:3000` (ou porta alternativa se 3000 estiver ocupada)

### 6. Build para Produção
```bash
npm run build
npm run preview
```

---

## 🎨 Design System

### Paleta de Cores

#### Cores Principais
```css
--primary-500: #00E096;      /* Verde Neon - Ações principais */
--primary-600: #00B87A;      /* Verde Escuro - Hover states */
```

#### Backgrounds
```css
--bg-page: #050505;          /* Fundo da página */
--bg-card: #0A0A0A;          /* Fundo de cards */
--bg-card-hover: #121212;    /* Hover em cards */
--bg-input: #0D0D0D;         /* Fundo de inputs */
--bg-sidebar: #121212;       /* Fundo da sidebar */
```

#### Borders
```css
--border-primary: #1F1F1F;   /* Borders principais */
--border-secondary: #27272A; /* Borders secundários */
--border-tertiary: #2A2A2A;  /* Borders terciários */
```

#### Text
```css
--text-white: #FFFFFF;       /* Títulos e texto principal */
--text-gray: #9CA3AF;        /* Labels e texto secundário */
--text-gray-dark: #6B7280;   /* Texto desabilitado */
```

### Tipografia

#### Fontes
- **Primary:** System UI (Inter, Roboto, sans-serif)
- **Monospace:** Fira Code, Consolas, monospace

#### Tamanhos
```css
/* Headings */
h1: text-3xl (30px) font-bold
h2: text-2xl (24px) font-bold
h3: text-xl (20px) font-bold
h4: text-lg (18px) font-bold

/* Body */
text-base: 16px
text-sm: 14px
text-xs: 12px
```

### Espaçamento

```css
/* Padding */
p-2: 0.5rem (8px)
p-4: 1rem (16px)
p-6: 1.5rem (24px)
p-8: 2rem (32px)

/* Gap */
gap-2: 0.5rem (8px)
gap-3: 0.75rem (12px)
gap-4: 1rem (16px)
gap-6: 1.5rem (24px)
```

### Componentes Base

#### Botões
```vue
<!-- Botão Primário -->
<button class="px-6 py-3 bg-[#00E096] text-black rounded-lg font-bold hover:bg-[#00B87A] transition-all">
  Texto
</button>

<!-- Botão Secundário -->
<button class="px-6 py-3 bg-[#1F1F1F] text-white rounded-lg font-bold hover:bg-[#2A2A2A] transition-all">
  Texto
</button>
```

#### Cards
```vue
<div class="bg-[#0A0A0A] border border-[#1F1F1F] rounded-2xl p-6 hover:border-[#27272A] transition-all">
  <!-- Conteúdo -->
</div>
```

#### Inputs
```vue
<input 
  type="text"
  class="w-full bg-[#050505] border border-[#1F1F1F] text-white placeholder-gray-500 rounded-lg px-4 py-3 focus:outline-none focus:ring-2 focus:ring-[#00E096]/50 focus:border-[#00E096]/50 transition-all"
  placeholder="Digite aqui..."
/>
```

#### Badges
```vue
<!-- Badge Verde (Ativo) -->
<span class="inline-flex items-center px-3 py-1 rounded-full text-xs font-bold bg-[#00E096]/10 text-[#00E096] border border-[#00E096]/20">
  Ativo
</span>

<!-- Badge Cinza (Inativo) -->
<span class="inline-flex items-center px-3 py-1 rounded-full text-xs font-bold bg-[#1F1F1F] text-gray-400 border border-[#2A2A2A]">
  Inativo
</span>
```

---

## 📄 Arquitetura de Páginas

### 1. **Login** (`/login`)

**Arquivo:** `pages/login.vue`

**Funcionalidade:**
- Autenticação via Supabase
- Validação de email/senha
- Toast notifications para feedback
- Redirecionamento para `/dashboard` após login

**Componentes Usados:**
- `BaseInput.vue`
- `BaseButton.vue`

**Estado:**
```typescript
const email = ref('')
const password = ref('')
const loading = ref(false)
```

**Funções Principais:**
```typescript
const handleLogin = async () => {
  const { data, error } = await supabase.auth.signInWithPassword({
    email: email.value,
    password: password.value
  })
  
  if (error) {
    // Mostrar toast de erro
  } else {
    // Redirecionar para dashboard
    navigateTo('/dashboard')
  }
}
```

---

### 2. **Dashboard** (`/dashboard`)

**Arquivo:** `pages/dashboard.vue`

**Funcionalidade:**
- Exibir métricas principais (Total Leads, Interessados, Novos, Travados)
- Tabela de leads recentes
- Botões de ação (Ver detalhes, Abrir chat, Travar/Destravar)
- Modal de detalhes do lead

**Componentes Usados:**
- `Sidebar.vue`
- `LeadDetailsModal.vue`

**Estado:**
```typescript
const leads = ref<Lead[]>([])
const metrics = reactive({
  total: 0,
  interested: 0,
  newLeads: 0,
  locked: 0
})
const loading = ref(true)
const showModal = ref(false)
const selectedLead = ref<Cliente | null>(null)
```

**Funções Principais:**
```typescript
// Buscar dados do Supabase
const fetchData = async () => {
  const { data, error } = await supabase
    .from('clientes')
    .select('*')
    .order('created_at', { ascending: false })
  
  // Processar dados e calcular métricas
}

// Abrir modal de detalhes
const openLeadDetails = (leadId: string) => {
  const fullLead = fullLeadsData.value.find(l => l.id === leadId)
  if (fullLead) {
    selectedLead.value = fullLead
    showModal.value = true
  }
}

// Navegar para chat
const openChat = (leadId: string) => {
  navigateTo(`/chats?clientId=${leadId}`)
}
```

**Métricas Calculadas:**
- **Total:** Todos os clientes
- **Interessados:** `qualificado === true`
- **Novos:** Criados nos últimos 7 dias
- **Travados:** `trava === true`

---

### 3. **CRM / Kanban** (`/crm`)

**Arquivo:** `pages/crm.vue`

**Funcionalidade:**
- View Kanban com drag & drop
- View Tabela
- Atualização de status de leads
- Modal de detalhes do lead

**Componentes Usados:**
- `Sidebar.vue`
- `KanbanBoard.vue`
- `LeadTable.vue`
- `LeadDetailsModal.vue`

**Estado:**
```typescript
const currentView = ref<'kanban' | 'table'>('kanban')
const leads = ref<Cliente[]>([])
const loading = ref(true)
const showModal = ref(false)
const selectedLead = ref<Cliente | null>(null)
```

**Funções Principais:**
```typescript
// Buscar leads
const fetchLeads = async () => {
  const { data, error } = await supabase
    .from('clientes')
    .select('*')
    .order('created_at', { ascending: false })
  
  leads.value = data || []
}

// Atualizar status (com otimistic update)
const handleStatusUpdate = async (id: string, newStatus: CrmStatus) => {
  // Atualização otimista
  const lead = leads.value.find(l => l.id === id)
  if (lead) {
    lead.status_crm = newStatus
  }
  
  // Atualização no banco
  const { error } = await supabase
    .from('clientes')
    .update({ status_crm: newStatus })
    .eq('id', id)
  
  if (error) {
    // Reverter em caso de erro
    await fetchLeads()
  }
}
```

**Colunas do Kanban:**
1. **Novo** (`novo`) - Azul
2. **Em Contato** (`em_contato`) - Amarelo
3. **Qualificado** (`qualificado`) - Roxo
4. **Convertido** (`convertido`) - Verde
5. **Perdido** (`perdido`) - Vermelho

---

### 4. **Contatos** (`/contatos`)

**Arquivo:** `pages/contatos.vue`

**Funcionalidade:**
- Lista de todos os contatos
- Barra de busca (nome/telefone)
- Header com colunas "Nome" e "Interessado"
- Modal de detalhes ao clicar

**Componentes Usados:**
- `Sidebar.vue`
- `LeadDetailsModal.vue`

**Estado:**
```typescript
const contacts = ref<Cliente[]>([])
const loading = ref(true)
const searchQuery = ref('')
const showModal = ref(false)
const selectedContact = ref<Cliente | null>(null)
```

**Computed:**
```typescript
const filteredContacts = computed(() => {
  if (!searchQuery.value.trim()) {
    return contacts.value
  }
  
  const query = searchQuery.value.toLowerCase()
  return contacts.value.filter(contact => 
    (contact.nome?.toLowerCase().includes(query)) ||
    (contact.whatsapp_id?.toLowerCase().includes(query))
  )
})
```

**Layout:**
- Grid 12 colunas
- **Coluna 8:** Avatar + Nome + Telefone
- **Coluna 4:** Badges de status (Sim/Não, Travado)

---

### 5. **Chats** (`/chats`)

**Arquivo:** `pages/chats.vue`

**Funcionalidade:**
- Sidebar com lista de conversas
- Área de mensagens
- Botão "Gerar Resumo"
- Navegação via query parameter (`?clientId=xxx`)

**Componentes Usados:**
- `Sidebar.vue`

**Estado:**
```typescript
const chats = ref([
  {
    id: '1',
    name: 'William',
    phone: '5561955432398',
    lastMessage: 'Obrigado pelo atendimento!',
    timestamp: '10:30',
    unread: 0,
    avatar: 'W'
  },
  // ... mais chats
])

const selectedChat = ref(chats.value[0])
const searchQuery = ref('')
const messages = ref([...])
```

**Funções Principais:**
```typescript
// Selecionar chat
const selectChat = (chat: any) => {
  selectedChat.value = chat
}

// Auto-selecionar chat via URL
onMounted(() => {
  const route = useRoute()
  const clientId = route.query.clientId as string
  
  if (clientId) {
    const chat = chats.value.find(c => c.id === clientId || c.phone === clientId)
    if (chat) {
      selectChat(chat)
    }
  }
})
```

**Layout:**
- **Sidebar (384px):** Lista de chats com busca
- **Main:** Header do chat + Mensagens + Botão "Gerar Resumo"

**Mensagens:**
- **Enviadas:** Balão verde (`bg-[#00E096]`), alinhado à direita
- **Recebidas:** Balão cinza (`bg-[#1F1F1F]`), alinhado à esquerda

---

### 6. **Relatórios** (`/relatorios`)

**Arquivo:** `pages/relatorios.vue`

**Funcionalidade:**
- Métricas principais (Total Leads, Taxa Conversão, Receita, Ticket Médio)
- Seletor de período (7d, 30d, 90d, 1y)
- Botão "Exportar"
- Placeholders para gráficos
- Tabela de top leads convertidos

**Componentes Usados:**
- `Sidebar.vue`

**Estado:**
```typescript
const metrics = ref([
  {
    title: 'Total de Leads',
    value: '247',
    change: '+12%',
    trend: 'up',
    icon: Users,
    color: 'text-blue-500',
    bgColor: 'bg-blue-500/10'
  },
  // ... mais métricas
])

const selectedPeriod = ref('30d')
```

**Layout:**
- **Grid 4 colunas:** Cards de métricas
- **Grid 2 colunas:** Placeholders de gráficos
- **Tabela:** Top leads convertidos (12 colunas)

---

## 🧩 Componentes

### 1. **Sidebar** (`components/Sidebar.vue`)

**Funcionalidade:**
- Navegação principal
- Logo e branding
- Menu com seções (PRINCIPAL, GESTÃO)
- Botão de logout
- Avatar do usuário

**Estrutura:**
```typescript
const navigation = [
  { 
    name: 'PRINCIPAL', 
    items: [
      { name: 'Dashboard', icon: LayoutDashboard, route: '/dashboard' },
      { name: 'CRM / Kanban', icon: KanbanSquare, route: '/crm', badge: '12+' },
      { name: 'Contatos', icon: Users, route: '/contatos' },
    ]
  },
  { 
    name: 'GESTÃO', 
    items: [
      { name: 'Chats', icon: MessageSquare, route: '/chats' },
      { name: 'Relatórios', icon: BarChart3, route: '/relatorios' },
    ]
  }
]
```

**Estilos:**
- **Width:** 256px (w-64)
- **Background:** `#121212`
- **Border:** `#1F1F1F`
- **Active:** Borda verde à esquerda + fundo verde/10

---

### 2. **KanbanBoard** (`components/crm/KanbanBoard.vue`)

**Funcionalidade:**
- Drag & drop de leads entre colunas
- 5 colunas de status
- Contador de leads por coluna
- Emite evento `update-status` ao mover card

**Props:**
```typescript
interface Props {
  leads: Cliente[]
}

defineProps<Props>()
```

**Emits:**
```typescript
const emit = defineEmits<{
  'update-status': [id: string, status: CrmStatus]
  'view-details': [lead: Cliente]
}>()
```

**Colunas:**
```typescript
const columns = [
  { key: 'novo', label: 'Novo', color: 'bg-blue-500', dot: 'bg-blue-500' },
  { key: 'em_contato', label: 'Em Contato', color: 'bg-yellow-500', dot: 'bg-yellow-500' },
  { key: 'qualificado', label: 'Qualificado', color: 'bg-purple-500', dot: 'bg-purple-500' },
  { key: 'convertido', label: 'Convertido', color: 'bg-green-500', dot: 'bg-green-500' },
  { key: 'perdido', label: 'Perdido', color: 'bg-red-500', dot: 'bg-red-500' }
]
```

**Drag & Drop:**
- Usa `vue-draggable-plus`
- Atualiza status ao soltar card em nova coluna
- Animação suave de transição

---

### 3. **LeadTable** (`components/crm/LeadTable.vue`)

**Funcionalidade:**
- Tabela de leads com colunas: Avatar, Nome, Telefone, Status, Ações
- Botão "Ver Detalhes" (Eye icon)

**Props:**
```typescript
interface Props {
  leads: Cliente[]
}
```

**Emits:**
```typescript
const emit = defineEmits<{
  'view-details': [lead: Cliente]
}>()
```

**Colunas:**
1. Avatar + Nome
2. Telefone
3. Status (badge colorido)
4. Ações (botão Eye)

---

### 4. **LeadDetailsModal** (`components/leads/LeadDetailsModal.vue`)

**Funcionalidade:**
- Modal centralizado com backdrop
- Exibir detalhes completos do lead
- Editar status
- Adicionar/editar notas
- Botão "Salvar Alterações"

**Props:**
```typescript
interface Props {
  modelValue: boolean
  lead: Cliente | null
}
```

**Emits:**
```typescript
const emit = defineEmits<{
  'update:modelValue': [value: boolean]
  'update-status': [id: string, status: string]
  'save-notes': [id: string, notes: string]
}>()
```

**Layout:**
- **Grid 2 colunas:**
  - **Esquerda:** Informações (Nome, Telefone, WhatsApp ID, Data Criação)
  - **Direita:** Status, Qualificado, Travado, Notas

**Componentes:**
- Usa `Teleport` para renderizar no body
- `fixed inset-0 z-50` para overlay
- `bg-black/80 backdrop-blur-sm` para backdrop

---

## 🗄️ Database Schema

### Tabela: `clientes`

**Descrição:** Armazena informações de clientes/leads do CRM.

**Colunas:**

| Coluna | Tipo | Constraints | Descrição |
|--------|------|-------------|-----------|
| `id` | `uuid` | PRIMARY KEY, DEFAULT `uuid_generate_v4()` | ID único do cliente |
| `whatsapp_id` | `varchar(255)` | UNIQUE, NOT NULL | Número do WhatsApp (identificador único) |
| `nome` | `varchar(255)` | NULL | Nome do cliente |
| `status_crm` | `varchar(50)` | DEFAULT `'novo'` | Status no pipeline CRM |
| `stage` | `varchar(50)` | DEFAULT `'INTRO'` | Estágio da conversa |
| `trava` | `boolean` | DEFAULT `false` | Se está travado (manual) ou não (bot) |
| `is_active` | `boolean` | DEFAULT `true` | Se está ativo no board |
| `qualificado` | `boolean` | DEFAULT `false` | Se está qualificado/interessado |
| `created_at` | `timestamp` | DEFAULT `now()` | Data de criação |
| `metadata` | `jsonb` | NULL | Metadados adicionais (JSON) |

**Índices:**
- PRIMARY KEY em `id`
- UNIQUE em `whatsapp_id`
- INDEX em `status_crm` (para queries rápidas)
- INDEX em `created_at` (para ordenação)

**Valores de `status_crm`:**
- `'novo'` - Lead novo
- `'em_contato'` - Em contato
- `'qualificado'` - Qualificado
- `'convertido'` - Convertido (venda fechada)
- `'perdido'` - Perdido (não converteu)

**Exemplo de Query:**
```sql
-- Buscar todos os leads ativos, ordenados por data
SELECT * FROM clientes 
WHERE is_active = true 
ORDER BY created_at DESC;

-- Buscar leads qualificados
SELECT * FROM clientes 
WHERE qualificado = true;

-- Contar leads por status
SELECT status_crm, COUNT(*) as total 
FROM clientes 
GROUP BY status_crm;
```

---

## 📝 Tipos TypeScript

### `types/crm.ts`

```typescript
export type CrmStatus = 'novo' | 'em_contato' | 'qualificado' | 'convertido' | 'perdido';

export interface Cliente {
  id: string;                // uuid
  whatsapp_id: string;       // unique
  nome: string | null;
  status_crm: string;        // default 'novo'
  stage: string;             // default 'INTRO'
  trava: boolean;            // false = Bot, true = Human
  is_active: boolean;        // true = show in board
  qualificado: boolean;      // true = Interested
  created_at: string;        // timestamp
  metadata: any;             // JSON metadata
}
```

### `types/database.types.ts`

```typescript
// Tipos gerados automaticamente pelo Supabase CLI
// Execute: npx supabase gen types typescript --project-id <project-id> > types/database.types.ts
```

---

## ✅ Funcionalidades Implementadas

### Autenticação
- [x] Login com email/senha via Supabase
- [x] Logout
- [x] Toast notifications para feedback

### Dashboard
- [x] Métricas principais (Total, Interessados, Novos, Travados)
- [x] Tabela de leads recentes
- [x] Botão "Ver Detalhes" (abre modal)
- [x] Botão "Abrir Chat" (navega para /chats)
- [x] Botão "Travar/Destravar" (visual apenas)

### CRM / Kanban
- [x] View Kanban com drag & drop
- [x] View Tabela
- [x] Toggle entre views
- [x] Atualização de status (otimistic update)
- [x] Modal de detalhes do lead
- [x] 5 colunas de status

### Contatos
- [x] Lista de todos os contatos
- [x] Barra de busca (nome/telefone)
- [x] Header com colunas
- [x] Badges de status
- [x] Modal de detalhes ao clicar

### Chats
- [x] Sidebar com lista de conversas
- [x] Barra de busca de conversas
- [x] Área de mensagens
- [x] Botão "Gerar Resumo"
- [x] Navegação via query parameter
- [x] Auto-seleção de chat ao navegar do dashboard

### Relatórios
- [x] 4 cards de métricas
- [x] Seletor de período
- [x] Botão "Exportar"
- [x] Placeholders para gráficos
- [x] Tabela de top leads convertidos

### UI/UX
- [x] Design System Dark Premium
- [x] Sidebar de navegação
- [x] Responsividade básica
- [x] Animações e transições
- [x] Hover effects

---

## 🚧 Funcionalidades Pendentes

### Prioridade Alta
- [ ] **Integração real com Supabase nos Chats**
  - Buscar conversas reais do banco
  - Sincronizar mensagens
  - Implementar envio de mensagens
  
- [ ] **Gráficos nos Relatórios**
  - Integrar Chart.js ou ApexCharts
  - Gráfico de linhas (Performance ao longo do tempo)
  - Gráfico de pizza (Distribuição por status)
  
- [ ] **Funcionalidade "Gerar Resumo"**
  - Integrar com API de IA (OpenAI, Claude, etc.)
  - Gerar resumo da conversa
  - Exibir em modal ou card

### Prioridade Média
- [ ] **Filtros Avançados**
  - Filtrar leads por data
  - Filtrar por status
  - Filtrar por qualificado/não qualificado
  
- [ ] **Exportação de Dados**
  - Exportar relatórios em CSV
  - Exportar relatórios em PDF
  - Exportar leads em Excel
  
- [ ] **Notificações em Tempo Real**
  - Usar Supabase Realtime
  - Notificar novos leads
  - Notificar novas mensagens
  
- [ ] **Busca Global**
  - Buscar em todas as páginas
  - Atalho de teclado (Ctrl+K)

### Prioridade Baixa
- [ ] **Temas Customizáveis**
  - Permitir trocar cores primárias
  - Salvar preferências do usuário
  
- [ ] **Modo Claro**
  - Implementar tema light
  - Toggle dark/light mode
  
- [ ] **Internacionalização (i18n)**
  - Suporte para inglês
  - Suporte para espanhol

---

## 🛠️ Guia de Desenvolvimento

### Adicionar Nova Página

1. **Criar arquivo em `pages/`:**
```bash
touch pages/nova-pagina.vue
```

2. **Estrutura básica:**
```vue
<script setup lang="ts">
// Imports
import { ref } from 'vue'

// Estado
const data = ref([])

// Funções
const fetchData = async () => {
  // Lógica
}
</script>

<template>
  <div class="min-h-screen bg-[#050505] text-white">
    <Sidebar />
    
    <main class="ml-64 p-8">
      <header class="mb-8">
        <h1 class="text-3xl font-bold">Título da Página</h1>
        <p class="text-[#9CA3AF] text-sm mt-1">Descrição</p>
      </header>
      
      <!-- Conteúdo -->
    </main>
  </div>
</template>
```

3. **Adicionar rota na Sidebar:**
```typescript
// components/Sidebar.vue
const navigation = [
  { 
    name: 'SEÇÃO', 
    items: [
      { name: 'Nova Página', icon: IconName, route: '/nova-pagina' }
    ]
  }
]
```

### Adicionar Novo Componente

1. **Criar arquivo em `components/`:**
```bash
touch components/MeuComponente.vue
```

2. **Estrutura básica:**
```vue
<script setup lang="ts">
interface Props {
  prop1: string
  prop2?: number
}

const props = defineProps<Props>()

const emit = defineEmits<{
  'event-name': [payload: any]
}>()
</script>

<template>
  <div class="bg-[#0A0A0A] border border-[#1F1F1F] rounded-2xl p-6">
    <!-- Conteúdo -->
  </div>
</template>
```

3. **Usar o componente:**
```vue
<MeuComponente 
  prop1="valor" 
  :prop2="123"
  @event-name="handleEvent"
/>
```

### Integrar com Supabase

#### Buscar Dados
```typescript
const supabase = useSupabaseClient()

const fetchData = async () => {
  const { data, error } = await supabase
    .from('clientes')
    .select('*')
    .order('created_at', { ascending: false })
  
  if (error) {
    console.error('Error:', error)
  } else {
    // Processar dados
  }
}
```

#### Inserir Dados
```typescript
const insertData = async (cliente: Partial<Cliente>) => {
  const { data, error } = await supabase
    .from('clientes')
    .insert([cliente])
    .select()
  
  if (error) {
    console.error('Error:', error)
  } else {
    console.log('Inserted:', data)
  }
}
```

#### Atualizar Dados
```typescript
const updateData = async (id: string, updates: Partial<Cliente>) => {
  const { data, error } = await supabase
    .from('clientes')
    .update(updates)
    .eq('id', id)
    .select()
  
  if (error) {
    console.error('Error:', error)
  } else {
    console.log('Updated:', data)
  }
}
```

#### Deletar Dados
```typescript
const deleteData = async (id: string) => {
  const { error } = await supabase
    .from('clientes')
    .delete()
    .eq('id', id)
  
  if (error) {
    console.error('Error:', error)
  }
}
```

#### Realtime Subscriptions
```typescript
const channel = supabase
  .channel('clientes-changes')
  .on(
    'postgres_changes',
    {
      event: '*',
      schema: 'public',
      table: 'clientes'
    },
    (payload) => {
      console.log('Change received!', payload)
      // Atualizar estado local
    }
  )
  .subscribe()

// Cleanup
onUnmounted(() => {
  supabase.removeChannel(channel)
})
```

### Adicionar Gráficos (Chart.js)

1. **Instalar dependência:**
```bash
npm install chart.js vue-chartjs
```

2. **Criar componente de gráfico:**
```vue
<script setup lang="ts">
import { Line } from 'vue-chartjs'
import {
  Chart as ChartJS,
  CategoryScale,
  LinearScale,
  PointElement,
  LineElement,
  Title,
  Tooltip,
  Legend
} from 'chart.js'

ChartJS.register(
  CategoryScale,
  LinearScale,
  PointElement,
  LineElement,
  Title,
  Tooltip,
  Legend
)

const chartData = {
  labels: ['Jan', 'Fev', 'Mar', 'Abr', 'Mai', 'Jun'],
  datasets: [
    {
      label: 'Leads',
      backgroundColor: '#00E096',
      borderColor: '#00E096',
      data: [40, 39, 10, 40, 39, 80]
    }
  ]
}

const chartOptions = {
  responsive: true,
  maintainAspectRatio: false
}
</script>

<template>
  <div class="h-64">
    <Line :data="chartData" :options="chartOptions" />
  </div>
</template>
```

### Boas Práticas

#### 1. Nomenclatura
- **Componentes:** PascalCase (`LeadDetailsModal.vue`)
- **Páginas:** kebab-case (`nova-pagina.vue`)
- **Variáveis:** camelCase (`selectedLead`)
- **Constantes:** UPPER_SNAKE_CASE (`API_URL`)

#### 2. Organização de Código
```typescript
// 1. Imports
import { ref, computed, onMounted } from 'vue'
import ComponentName from '@/components/ComponentName.vue'

// 2. Composables
const supabase = useSupabaseClient()
const router = useRouter()

// 3. Props & Emits
interface Props {
  prop: string
}
const props = defineProps<Props>()
const emit = defineEmits<{...}>()

// 4. Estado
const data = ref([])
const loading = ref(false)

// 5. Computed
const filteredData = computed(() => {...})

// 6. Funções
const fetchData = async () => {...}
const handleClick = () => {...}

// 7. Lifecycle Hooks
onMounted(() => {
  fetchData()
})
```

#### 3. TypeScript
- Sempre tipar props e emits
- Usar interfaces para objetos complexos
- Evitar `any`, usar `unknown` quando necessário

#### 4. Performance
- Usar `computed` para valores derivados
- Usar `v-memo` para listas grandes
- Lazy load componentes pesados

#### 5. Acessibilidade
- Usar atributos `aria-*`
- Adicionar `title` em botões de ícone
- Garantir contraste de cores adequado

---

## 🚀 Deploy

### Opção 1: Vercel (Recomendado)

1. **Instalar Vercel CLI:**
```bash
npm install -g vercel
```

2. **Login:**
```bash
vercel login
```

3. **Deploy:**
```bash
vercel
```

4. **Configurar variáveis de ambiente:**
- No dashboard da Vercel, vá em **Settings** → **Environment Variables**
- Adicione:
  - `SUPABASE_URL`
  - `SUPABASE_KEY`

### Opção 2: Netlify

1. **Instalar Netlify CLI:**
```bash
npm install -g netlify-cli
```

2. **Login:**
```bash
netlify login
```

3. **Deploy:**
```bash
netlify deploy --prod
```

4. **Configurar variáveis de ambiente:**
- No dashboard da Netlify, vá em **Site settings** → **Environment variables**
- Adicione as mesmas variáveis

### Opção 3: GitHub Pages (Static)

1. **Build:**
```bash
npm run generate
```

2. **Deploy:**
- Commit a pasta `.output/public` para branch `gh-pages`
- Ou use GitHub Actions

---

## 🐛 Troubleshooting

### Erro: "Supabase client not found"

**Solução:**
1. Verifique se `.env` existe e está configurado
2. Reinicie o servidor de desenvolvimento
3. Verifique se `@nuxtjs/supabase` está em `nuxt.config.ts`

### Erro: "Port 3000 already in use"

**Solução:**
```bash
# Windows
netstat -ano | findstr :3000
taskkill /PID <PID> /F

# Linux/Mac
lsof -ti:3000 | xargs kill -9
```

Ou o Nuxt vai usar porta alternativa automaticamente (3001, 3002, etc.)

### Erro: "Module not found"

**Solução:**
```bash
# Limpar cache e reinstalar
rm -rf node_modules .nuxt
npm install
```

### Erro de TypeScript

**Solução:**
1. Verifique se `tsconfig.json` está correto
2. Execute `npm run postinstall` para regenerar tipos
3. Reinicie o TypeScript server no VSCode

### Drag & Drop não funciona

**Solução:**
1. Verifique se `vue-draggable-plus` está instalado
2. Verifique se os arrays estão reativos (`ref` ou `reactive`)
3. Verifique se há erros no console

---

## 📞 Contato e Suporte

**Desenvolvedor:** William Ferreira  
**GitHub:** [williamferreiraDev](https://github.com/williamferreiraDev)  
**Repositório:** [crmDATAimpetus](https://github.com/williamferreiraDev/crmDATAimpetus)

---

## 📜 Licença

Este projeto é privado e proprietário. Todos os direitos reservados.

---

## 🎯 Próximos Passos Recomendados

1. **Integrar gráficos reais** em `/relatorios`
2. **Conectar chats com Supabase** para dados reais
3. **Implementar funcionalidade "Gerar Resumo"** com IA
4. **Adicionar testes** (Vitest + Testing Library)
5. **Melhorar responsividade** para mobile
6. **Adicionar documentação de API** (se houver endpoints customizados)
7. **Configurar CI/CD** com GitHub Actions

---

**Última atualização:** 07/02/2026  
**Versão da documentação:** 1.0.0
