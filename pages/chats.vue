<script setup lang="ts">
import { ref, computed, onMounted, onUnmounted, nextTick } from 'vue'
import { useSupabaseClient } from '#imports'
import { MessageSquare, Phone, Search, FileText, Menu, X, BotOff, Bot, PhoneForwarded, ArrowLeft } from 'lucide-vue-next'

const route = useRoute()
const { mainMargin } = useSidebarState()
const supabase = useSupabaseClient<any>()

// State
const chats = ref<any[]>([])
const selectedChat = ref<any>(null)
const messages = ref<any[]>([])
const loading = ref(true)
const messagesLoading = ref(false)
const searchQuery = ref('')
const isSidebarOpen = ref(false)
const messagesContainer = ref<HTMLElement | null>(null)

// Filtragem de conversas por nome, telefone (com ou sem formatação) e mensagem
const filteredChats = computed(() => {
  if (!searchQuery.value.trim()) return chats.value

  const q = searchQuery.value.toLowerCase().trim()
  const qDigits = q.replace(/\D/g, '')

  return chats.value.filter(chat => {
    const name = (chat.name || '').toLowerCase()
    const phone = (chat.phone || '')
    const phoneLower = phone.toLowerCase()
    const phoneDigits = phone.replace(/\D/g, '')
    const lastMsg = (chat.lastMessage || '').toLowerCase()

    const nameMatch = name.includes(q)
    const phoneMatch = phoneLower.includes(q)
    const phoneDigitsMatch = qDigits.length > 0 && phoneDigits.includes(qDigits)
    const lastMsgMatch = lastMsg.includes(q)

    return nameMatch || phoneMatch || phoneDigitsMatch || lastMsgMatch
  })
})

const stages = ref<any[]>([
  { id: 1, estagio: 'novo', estagio_name: 'Novo Contato' },
  { id: 2, estagio: 'em_atendimento', estagio_name: 'Em Atendimento' },
  { id: 3, estagio: 'agendamento', estagio_name: 'Agendamento' },
  { id: 4, estagio: 'visita', estagio_name: 'Visita' },
  { id: 5, estagio: 'negociacao', estagio_name: 'Em Negociação' },
  { id: 6, estagio: 'fechado', estagio_name: 'Venda Fechada' },
  { id: 7, estagio: 'perdido', estagio_name: 'Perdido' }
])


// Summary state
const summaryText = ref('')
const summaryLoading = ref(false)
const showSummary = ref(false)

// Handoff state
const handoffNumber = ref('+55 11 99999-0000')
const editingHandoff = ref(false)
const globalHandoffNumber = ref('+55 11 98888-0000')
const editingGlobalHandoff = ref(false)

const formatStageName = (stage: string) => {
  if (!stage) return 'novo'
  const map: Record<string, string> = {
    novo: 'novo',
    em_atendimento: 'atendimento',
    agendamento: 'agendamento',
    visita: 'visita',
    negociacao: 'negociação',
    fechado: 'fechado',
    perdido: 'perdido'
  }
  return map[stage] || stage
}

// Parse message object to extract text content
const parseMessage = (msgObj: any) => {
  if (!msgObj) return { text: '', isSystem: false, systemAction: '', type: 'text' }
  
  // Se for um objeto com a estrutura output (e.g. LangChain output object)
  if (msgObj.output && typeof msgObj.output.content === 'string') {
    return { text: msgObj.output.content, isSystem: false, systemAction: '', type: 'text' }
  }
  
  let text = msgObj.content || msgObj.text || ''
  const msgType = msgObj.type || ''
  
  const additional = msgObj.additional_kwargs || msgObj.kwargs?.additional_kwargs || {}
  const toolCalls = msgObj.tool_calls || additional.tool_calls || []
  
  if (toolCalls && toolCalls.length > 0) {
     let toolNames = toolCalls.map((t: any) => {
       if (typeof t.function?.name === 'string') return t.function.name
       if (typeof t.name === 'string') return t.name
       if (typeof t === 'string') return t
       return 'ferramenta'
     }).join(', ')
     
     const niceName = toolNames.replace(/_/g, ' ')
     return { text: `IA ativou a(s) tool(s): ${niceName}`, isSystem: true, systemAction: `A IA ativou a tool: ${niceName}`, type: 'tool' }
  }
  
  if (msgType === 'tool') {
     return { text: typeof text === 'string' ? text : JSON.stringify(text), isSystem: true, systemAction: 'Consultou o banco de dados', type: 'tool' }
  }
  
  if (!text) return { text: '', isSystem: false, systemAction: '', type: 'text' }
  
  const trimmed = typeof text === 'string' ? text.trim() : JSON.stringify(text)
  
  if (trimmed.startsWith('Calling ') && trimmed.includes('with input:')) {
     const functionName = trimmed.split(' ')[1] || 'ferramenta_interna'
     const niceName = functionName.replace(/_/g, ' ')
     return { text: trimmed, isSystem: true, systemAction: `A IA ativou a tool: ${niceName}`, type: 'tool' }
  }
  
  if ((trimmed.startsWith('[') && trimmed.endsWith(']')) || (trimmed.startsWith('{') && trimmed.endsWith('}'))) {
    try {
      const parsed = JSON.parse(trimmed)

      // O n8n/LangChain pode serializar um bloco de conteúdo dentro de
      // message.content, por exemplo: { type: 'text', content: 'Olá' }.
      // Esse formato é uma mensagem normal da IA, não uma saída de tool.
      if (parsed?.type === 'text' && typeof parsed.content === 'string') {
        return { text: parsed.content, isSystem: false, systemAction: '', type: 'text' }
      }

      // Payload JSON do WhatsApp via Evolution/Z-API (tem content_type e message)
      if (typeof parsed?.message === 'string') {
        return { text: parsed.message, isSystem: false, systemAction: '', type: 'text' }
      }

      // Também suporta o formato de content blocks usado por algumas
      // versões do LangChain/OpenAI.
      if (Array.isArray(parsed)) {
        const contentBlocks = parsed
          .filter(block => block?.type === 'text' && typeof block.content === 'string')
          .map(block => block.content)

        if (contentBlocks.length > 0) {
          return { text: contentBlocks.join('\n'), isSystem: false, systemAction: '', type: 'text' }
        }
      }

      if (parsed.output && typeof parsed.output.content === 'string') {
         return { text: parsed.output.content, isSystem: false, systemAction: '', type: 'text' }
      }
      if (typeof parsed === 'object') {
         return { text: trimmed, isSystem: true, systemAction: 'Consultou o banco de dados', type: 'tool' }
      }
    } catch(e) {}
  }
  
  return { text: trimmed, isSystem: false, systemAction: '', type: 'text' }
}

// Fetch Clients to populate chat list
const fetchChats = async () => {
  loading.value = true
  try {
    // Fetch stages from DB
    try {
      const { data: stagesData } = await supabase.from('stage').select('*').order('id')
      if (stagesData && stagesData.length > 0) {
        stages.value = stagesData
      }
    } catch (e) {
      console.error('Error fetching stages:', e)
    }

    const { data: leadsData, error } = await supabase.from('leads').select('*').order('created_at', { ascending: false })
    if (error) throw error

    // Fetch latest messages for sidelist
    const { data: allChats, error: chatHistoryError } = await supabase.rpc('get_secure_chat_histories', { p_session_id: null })
    if (chatHistoryError) throw chatHistoryError
    
    const latestMsgs: Record<string, any> = {}
    if (allChats) {
       for(const c of allChats) {
          if (c.session_id && !latestMsgs[c.session_id]) {
             latestMsgs[c.session_id] = c;
          }
       }
    }

    chats.value = (leadsData || []).map(c => {
      let lastMsgText = 'Conversa iniciada...'
      let lastSender = 'user'
      
      if (latestMsgs[c.id]) {
        let rawMsg = latestMsgs[c.id].message || {}
        if (typeof rawMsg === 'string') {
          try { rawMsg = JSON.parse(rawMsg) } catch(e) {}
        }
        const realData = rawMsg.data || rawMsg
        const parsed = parseMessage(realData)
        lastMsgText = parsed.text || 'Conversa iniciada...'
        lastSender = (realData.type === 'ai' || realData.id?.includes('AIMessage')) ? 'me' : 'user'
      } else if (c.notes) {
        lastMsgText = c.notes
      }

      return {
        id: c.id,
        name: c.name || 'Sem nome',
        phone: c.phone || c.remotejid || 'Sem telefone',
        lastMessage: lastMsgText,
        lastSender: lastSender,
        timestamp: c.created_at ? new Date(c.created_at).toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' }) : '',
        avatar: (c.name || 'U').charAt(0).toUpperCase(),
        media_url: undefined,
        Ativado: c.agent_active || false,
        is_qualified: c.is_qualified || ['qualificado', 'convertido', 'agendado', 'negociacao', 'visita', 'fechado'].includes(c.stage) || false,
        estagiokanbam: c.stage || 'novo'
      }
    })

    const clientId = route.query.clientId as string
    if (clientId) {
      const chat = chats.value.find(c => c.id === clientId || c.phone === clientId)
      if (chat) selectChat(chat)
    } else if (chats.value.length > 0) {
      selectChat(chats.value[0])
    }
  } catch (error) {
    console.error('Error fetching chats:', error)
  } finally {
    loading.value = false
  }
}

// Fetch Messages for selected chat
const fetchMessages = async (chatId: string, silent = false) => {
  if (!silent) messagesLoading.value = true
  showSummary.value = false
  summaryText.value = ''
  try {
    const { data, error } = await supabase.rpc('get_secure_chat_histories', { p_session_id: chatId })
      
    if (error) throw error
    


    messages.value = (data || []).map(m => {
      let rawMsg = m.message || {}
      if (typeof rawMsg === 'string') {
        try { rawMsg = JSON.parse(rawMsg) } catch(e) {}
      }
      
      // No LangChain as vezes a mensagem vem dentro de "data"
      const realData = rawMsg.data || rawMsg
      const parsed = parseMessage(realData)
      
      return {
        id: m.id,
        sender: (realData.type === 'ai' || realData.id?.includes('AIMessage')) ? 'me' : 'user', 
        text: parsed.text,
        isSystem: parsed.isSystem,
        systemAction: parsed.systemAction,
        timestamp: '', 
        type: parsed.type
      }
    })
    
    scrollToBottom()
  } catch (e) {
    console.error('Error fetching messages', e)
  } finally {
    if (!silent) messagesLoading.value = false
  }
}

const selectChat = (chat: any) => {
  selectedChat.value = chat
  isSidebarOpen.value = false
  fetchMessages(chat.id)
}

const scrollToBottom = async () => {
  await nextTick()
  if (messagesContainer.value) {
    messagesContainer.value.scrollTop = messagesContainer.value.scrollHeight + 100
  }
  // Fallback garantido pro final caso renderize algo pesado
  setTimeout(() => {
    if (messagesContainer.value) {
      messagesContainer.value.scrollTop = messagesContainer.value.scrollHeight + 100
    }
  }, 150)
}

let chatPollingTimer: ReturnType<typeof setInterval> | null = null
let latestMessageId: number | null = null

const playNotificationSound = () => {
    try {
       const audio = new window.Audio('https://assets.mixkit.co/active_storage/sfx/2869/2869-preview.mp3')
       audio.volume = 0.5
       audio.play().catch(() => {})
    } catch(e) {}
}

const setupSecurePolling = () => {
  chatPollingTimer = setInterval(async () => {
    if (!selectedChat.value || document.visibilityState !== 'visible') return
    const previousId = messages.value.length ? Number(messages.value[messages.value.length - 1]?.id) : null
    await fetchMessages(selectedChat.value.id, true)
    const currentId = messages.value.length ? Number(messages.value[messages.value.length - 1]?.id) : null
    if (latestMessageId !== null && currentId && currentId > latestMessageId && currentId !== previousId) {
      playNotificationSound()
      scrollToBottom()
    }
    latestMessageId = currentId
  }, 5000)
}

// Generate Summary
const generateSummary = async () => {
  if (!selectedChat.value) return
  summaryLoading.value = true
  showSummary.value = true

  // Simulate AI processing
  await new Promise(resolve => setTimeout(resolve, 1500))

  const { mockSummaries } = useMockData()
  const summary = (mockSummaries as any)[selectedChat.value.id]
  
  if (summary) {
    summaryText.value = summary
  } else {
    let statusText = 'Em análise'
    let temperaturaText = '⚪ Frio — aguardando mais interação'
    let proxPassoText = 'Continuar qualificação via IA'

    switch (selectedChat.value.estagiokanbam) {
      case 'novo':
        statusText = 'Aguardando contato inicial'
        temperaturaText = '⚪ Frio — lead recém-chegado'
        proxPassoText = 'Iniciar qualificação'
        break
      case 'em_atendimento':
        statusText = 'Em conversação'
        temperaturaText = '🟡 Morno — demonstrando interesse inicial'
        proxPassoText = 'Qualificar e direcionar para agendamento/visita'
        break
      case 'agendamento':
        statusText = 'Tentando agendar'
        temperaturaText = '🟡 Morno — em processo de agendamento'
        proxPassoText = 'Confirmar data e horário'
        break
      case 'visita':
        statusText = 'Esperando a visita'
        temperaturaText = '🔴 Quente — visita agendada'
        proxPassoText = 'Análise de documentos pessoalmente'
        break
      case 'negociacao':
        statusText = 'Proposta em análise'
        temperaturaText = '🔥 Muito Quente — em negociação financeira'
        proxPassoText = 'Fechar valores e encaminhar contrato'
        break
      case 'fechado':
        statusText = 'Negócio Fechado'
        temperaturaText = '🏆 Convertido'
        proxPassoText = 'Pós-venda e assinatura final'
        break
      case 'perdido':
        statusText = 'Contato encerrado'
        temperaturaText = '🧊 Congelado — sem interesse atual'
        proxPassoText = 'Adicionar à lista de reativação futura'
        break
    }

    summaryText.value = `📋 **Resumo da Conversa — ${selectedChat.value.name}**\n\n• Interesse: ${formatStageName(selectedChat.value.estagiokanbam)}\n• Status: ${statusText}\n• Temperatura: ${temperaturaText}\n• Próximo passo: ${proxPassoText}`
  }

  summaryLoading.value = false
}



// Actions
const toggleAI = async () => {
  if (!selectedChat.value) return
  const newVal = !selectedChat.value.Ativado
  selectedChat.value.Ativado = newVal
  await supabase.from('leads').update({ agent_active: newVal }).eq('id', selectedChat.value.id)
}

const updateStatus = async () => {
  if (!selectedChat.value) return
  const isQual = ['qualificado', 'convertido', 'agendado', 'negociacao', 'visita', 'fechado'].includes(selectedChat.value.estagiokanbam)
  selectedChat.value.is_qualified = isQual
  
  const stageObj = stages.value.find(s => s.estagio === selectedChat.value.estagiokanbam)
  const updateData: any = {
    stage: selectedChat.value.estagiokanbam
  }
  if (stageObj) {
    updateData.stage_id = stageObj.id
  }
  
  const { error: updateError } = await supabase.from('leads').update(updateData).eq('id', selectedChat.value.id)
  if (updateError) {
    console.error('Error updating status in DB:', updateError)
  }
}

onMounted(() => {
  fetchChats()
  setupSecurePolling()
})

onUnmounted(() => {
  if (chatPollingTimer) clearInterval(chatPollingTimer)
})
</script>

<template>
  <div class="h-dvh w-full bg-gray-50 dark:bg-dark-bg text-gray-900 dark:text-white font-sans flex overflow-hidden transition-colors duration-300">
    <Sidebar />

    <!-- Chat Sidebar (Left) -->
    <aside :class="[mainMargin, selectedChat ? 'hidden md:flex' : 'flex', 'w-full md:w-80 border-r border-gray-100 dark:border-dark-border flex-col bg-white dark:bg-dark-surface flex-shrink-0 transition-all duration-300']">
      <!-- Header -->
      <div class="p-5 border-b border-gray-100 dark:border-dark-border">
        <div class="flex items-center justify-between mb-3">
          <h2 class="text-lg font-bold text-gray-900 dark:text-white">Conversas</h2>

        </div>
        

        <div class="relative">
          <Search class="absolute left-3 top-1/2 -translate-y-1/2 w-4 h-4 text-gray-400" />
          <input
            v-model="searchQuery"
            type="text"
            placeholder="Buscar conversas..."
            class="w-full bg-gray-50 dark:bg-dark-card border border-gray-100 dark:border-dark-border rounded-xl py-2.5 pl-10 pr-4 text-sm focus:outline-none focus:ring-2 focus:ring-primary-200 dark:focus:ring-primary-500/30 transition-all"
          />
        </div>
      </div>

      <!-- Chat List -->
      <div class="flex-1 overflow-y-auto">
        <div v-if="loading" class="p-8 text-center text-gray-400 dark:text-dark-muted text-sm">
          Carregando...
        </div>
        <div v-else-if="filteredChats.length === 0" class="p-8 text-center text-gray-400 dark:text-dark-muted text-sm">
          Nenhuma conversa encontrada.
        </div>
        <button
          v-for="chat in filteredChats"
          :key="chat.id"
          @click="selectChat(chat)"
          :class="[
            'w-full p-4 flex gap-3 border-b border-gray-50 dark:border-dark-border transition-all hover:bg-gray-50 dark:hover:bg-white/5',
            selectedChat?.id === chat.id ? 'bg-primary-50/50 dark:bg-primary-500/5 border-l-2 border-l-primary-500' : ''
          ]"
        >
          <div class="w-10 h-10 rounded-xl bg-primary-50 dark:bg-primary-500/10 text-primary-600 dark:text-primary-400 flex items-center justify-center font-bold text-sm flex-shrink-0">
            {{ chat.avatar }}
          </div>
          <div class="flex-1 min-w-0 text-left">
            <div class="flex items-center justify-between mb-1">
              <div class="flex items-center gap-1.5">
                <h3 class="font-semibold text-gray-900 dark:text-white truncate text-sm">{{ chat.name }}</h3>
                <span class="text-[9px] font-medium bg-emerald-50 dark:bg-emerald-500/10 text-emerald-600 dark:text-emerald-400 px-1.5 py-0.5 rounded-md border border-emerald-100 dark:border-emerald-500/20 flex-shrink-0 whitespace-nowrap">{{ formatStageName(chat.estagiokanbam) }}</span>
              </div>
              <span class="text-[10px] text-gray-400 dark:text-dark-muted flex-shrink-0">{{ chat.timestamp }}</span>
            </div>
            <p class="text-xs text-gray-400 dark:text-dark-muted truncate flex items-center gap-1">
              <span v-if="chat.lastSender === 'me'" class="text-[12px] font-bold text-gray-400 mb-0.5">•</span>
              <span class="truncate">{{ chat.lastMessage }}</span>
            </p>
          </div>
        </button>
      </div>
    </aside>

    <!-- Chat Content (Middle) -->
    <section :class="[selectedChat ? 'flex' : 'hidden md:flex', 'flex-1 flex-col bg-gray-50 dark:bg-dark-bg relative min-w-0 pt-16 md:pt-0 transition-colors duration-300']">
      <div v-if="selectedChat" class="flex-1 flex flex-col overflow-hidden relative">
        <!-- Header -->
        <header class="px-3 sm:px-6 py-3 sm:py-4 border-b border-gray-100 dark:border-dark-border bg-white dark:bg-dark-surface flex items-center justify-between gap-2 z-20">
          <div class="flex items-center gap-2 sm:gap-3 min-w-0">
            <button type="button" class="w-10 h-10 -ml-1 rounded-xl flex md:hidden items-center justify-center text-gray-500 hover:bg-gray-100 dark:hover:bg-dark-card" aria-label="Voltar para conversas" @click="selectedChat = null; isSidebarOpen = false">
              <ArrowLeft class="w-5 h-5" />
            </button>
            <div class="w-10 h-10 rounded-xl bg-primary-50 dark:bg-primary-500/10 text-primary-600 dark:text-primary-400 flex items-center justify-center font-bold">
              {{ selectedChat.avatar }}
            </div>
            <div class="min-w-0">
              <h2 class="font-semibold text-gray-900 dark:text-white text-sm truncate">{{ selectedChat.name }}</h2>
              <p class="text-xs text-gray-400 dark:text-dark-muted flex items-center gap-1">
                <Phone class="w-3 h-3" />
                {{ selectedChat.phone }}
              </p>
            </div>
          </div>
          
          <div class="flex items-center gap-2">
            <NuxtLink 
              :to="`/crm?clientId=${selectedChat.id}`"
              class="hidden sm:flex items-center gap-2 px-3 py-1.5 bg-gray-50 dark:bg-dark-card text-gray-600 dark:text-gray-300 rounded-lg text-xs font-medium hover:bg-gray-100 dark:hover:bg-dark-border transition-all border border-gray-100 dark:border-dark-border"
            >
              <FileText class="w-3 h-3" /> Ver no CRM
            </NuxtLink>

            <button 
              @click="isSidebarOpen = !isSidebarOpen"
              class="p-2 text-gray-400 hover:text-gray-600 dark:hover:text-white transition-colors hover:bg-gray-50 dark:hover:bg-dark-card rounded-lg"
              title="Ações"
            >
              <Menu class="w-5 h-5" v-if="!isSidebarOpen" />
              <X class="w-5 h-5" v-else />
            </button>
          </div>
        </header>

        <!-- Messages Area -->
        <div ref="messagesContainer" class="flex-1 overflow-y-auto overflow-x-hidden px-3 py-4 sm:p-6 flex flex-col gap-4 relative custom-scrollbar pb-24">
          <div v-if="messagesLoading" class="flex-1 flex items-center justify-center">
             <div class="animate-spin rounded-full h-6 w-6 border-b-2 border-primary-500"></div>
          </div>
          <div v-else-if="messages.length === 0" class="flex-1 flex items-center justify-center">
             <p class="text-gray-400 dark:text-dark-muted text-sm">Nenhuma mensagem encontrada nesta sessão.</p>
          </div>
          <div
            v-else
            v-for="message in messages"
            :key="message.id"
            :class="[
              'flex',
              message.isSystem ? 'justify-center my-2' : (message.sender === 'me' ? 'justify-end' : 'justify-start')
            ]"
          >
            <!-- Renderização das chamadas de Banco/Ferramentas do N8N -->
            <div
              v-if="message.isSystem"
              class="px-3 py-1.5 bg-gray-100 dark:bg-dark-surface border border-gray-200 dark:border-dark-border rounded-full text-[10px] text-gray-500 dark:text-dark-muted shadow-sm flex items-center gap-1.5"
            >
               <Bot class="w-3.5 h-3.5 text-primary-500" />
               <span class="font-medium tracking-wide">Ação de IA:</span> {{ message.systemAction }}
            </div>

            <!-- Balão de conversa normal -->
            <div
              v-else
              :class="[
                'max-w-[88%] sm:max-w-md px-4 py-3 rounded-2xl shadow-sm overflow-hidden shrink-0',
                message.sender === 'me' 
                  ? 'bg-primary-500 text-white rounded-br-none' 
                  : 'bg-white dark:bg-dark-surface text-gray-800 dark:text-gray-200 border border-gray-100 dark:border-dark-border rounded-bl-none'
              ]"
            >
              <p class="text-sm leading-relaxed whitespace-pre-wrap break-words">{{ message.text }}</p>
              <p v-if="message.timestamp" :class="['text-[10px] mt-1 text-right', message.sender === 'me' ? 'text-white/70' : 'text-gray-400 dark:text-dark-muted']">
                {{ message.timestamp }}
              </p>
            </div>
          </div>

          <!-- Summary Result -->
          <Transition name="fade">
            <div v-if="showSummary" class="bg-white dark:bg-dark-surface border border-primary-100 dark:border-primary-500/20 rounded-xl p-5 shadow-card">
              <div class="flex items-center gap-2 mb-3">
                <FileText class="w-4 h-4 text-primary-500" />
                <h4 class="text-sm font-semibold text-gray-900 dark:text-white">Resumo Gerado pela IA</h4>
              </div>
              <div v-if="summaryLoading" class="flex items-center gap-2 text-sm text-gray-400">
                <div class="animate-spin rounded-full h-4 w-4 border-b-2 border-primary-500"></div>
                Analisando conversa...
              </div>
              <p v-else class="text-sm text-gray-700 dark:text-gray-300 leading-relaxed whitespace-pre-wrap">{{ summaryText }}</p>
            </div>
          </Transition>
        </div>

        <!-- Floating Action: Generate Summary -->
        <div class="absolute bottom-20 right-3 sm:right-6 z-30">
           <button 
             @click="generateSummary"
             :disabled="summaryLoading"
             class="bg-white dark:bg-dark-surface hover:bg-gray-50 dark:hover:bg-dark-card border border-gray-200 dark:border-dark-border shadow-card-hover text-gray-900 dark:text-white px-5 py-2.5 rounded-xl flex items-center gap-2 text-sm font-medium transition-all hover:-translate-y-0.5 disabled:opacity-50"
           >
             <FileText class="w-4 h-4 text-primary-500" /> 
             {{ summaryLoading ? 'Gerando...' : 'Gerar Resumo' }}
           </button>
        </div>

        <!-- Footer -->
        <footer class="p-4 border-t border-gray-100 dark:border-dark-border bg-white dark:bg-dark-surface z-20">
          <div class="bg-primary-50 dark:bg-primary-500/5 border border-primary-100 dark:border-primary-500/20 text-primary-600 dark:text-primary-400 px-4 py-2.5 rounded-xl text-xs text-center font-medium">
            O envio de mensagens deve ser feito via WhatsApp ou automação externa.
          </div>
        </footer>
      </div>

      <!-- Empty State -->
      <div v-else class="flex-1 flex flex-col items-center justify-center text-gray-400 dark:text-dark-muted p-12">
        <div class="w-16 h-16 bg-gray-100 dark:bg-dark-surface border border-gray-200 dark:border-dark-border rounded-xl flex items-center justify-center mb-5">
          <MessageSquare class="w-8 h-8 opacity-30" />
        </div>
        <h2 class="text-lg font-semibold text-gray-900 dark:text-white mb-1">Selecione uma conversa</h2>
        <p class="text-center max-w-xs text-sm">Escolha um lead à esquerda para visualizar o histórico da conversa.</p>
      </div>
    </section>

    <!-- Side Actions Drawer (Right) -->
    <aside 
      v-if="isSidebarOpen && selectedChat" 
       class="fixed inset-x-0 bottom-0 top-16 z-40 w-full md:static md:w-72 border-l border-gray-100 dark:border-dark-border bg-white dark:bg-dark-surface flex flex-col flex-shrink-0 transition-colors"
    >
      <div class="p-4 sm:p-5 border-b border-gray-100 dark:border-dark-border flex items-center justify-between">
        <h2 class="font-bold text-gray-900 dark:text-white text-base">Ações</h2>
        <button type="button" class="w-10 h-10 rounded-xl flex items-center justify-center hover:bg-gray-100 dark:hover:bg-dark-card" aria-label="Fechar ações" @click="isSidebarOpen = false">
          <X class="w-5 h-5" />
        </button>
      </div>

      <div class="p-5 flex flex-col gap-6 flex-1 overflow-y-auto">
        <!-- AI Toggle -->
        <div>
          <label class="text-[10px] uppercase tracking-wider text-gray-400 dark:text-dark-muted mb-2 block font-semibold">IA Automática</label>
          <button 
            @click="toggleAI"
            :class="[
              'w-full py-2.5 rounded-xl flex items-center justify-center gap-2 font-medium transition-all border text-sm',
              selectedChat.Ativado 
                ? 'bg-primary-50 dark:bg-primary-500/10 text-primary-600 dark:text-primary-400 hover:bg-primary-100 border-primary-100 dark:border-primary-500/20'
                : 'bg-amber-50 dark:bg-amber-500/10 text-amber-600 dark:text-amber-500 hover:bg-amber-100 border-amber-100 dark:border-amber-500/20' 
            ]"
          >
            <BotOff class="w-4 h-4" v-if="!selectedChat.Ativado" />
            <Bot class="w-4 h-4" v-else />
            {{ selectedChat.Ativado ? 'Ativada' : 'Desativada' }}
          </button>
        </div>

        <!-- Status -->
        <div>
          <label class="text-[10px] uppercase tracking-wider text-gray-400 dark:text-dark-muted mb-2 block font-semibold">Status CRM</label>
          <div class="relative">
            <select 
              v-model="selectedChat.estagiokanbam" 
              @change="updateStatus"
              class="w-full bg-gray-50 dark:bg-dark-card border border-gray-100 dark:border-dark-border rounded-xl p-3 text-gray-900 dark:text-white text-sm font-medium focus:outline-none focus:ring-2 focus:ring-primary-200 dark:focus:ring-primary-500/30 appearance-none"
            >
              <option 
                v-for="s in stages" 
                :key="s.id" 
                :value="s.estagio"
              >
                {{ s.estagio_name || s.descricao || s.estagio }}
              </option>
            </select>
            <div class="pointer-events-none absolute inset-y-0 right-0 flex items-center px-4 text-gray-400">
               <svg class="h-4 w-4" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                 <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M19 9l-7 7-7-7" />
               </svg>
            </div>
          </div>
        </div>

        <!-- Handoff Number -->
        <div>
          <label class="text-[10px] uppercase tracking-wider text-gray-400 dark:text-dark-muted mb-2 block font-semibold">
            <PhoneForwarded class="w-3 h-3 inline mr-1" /> Número de Handoff
          </label>
          <div v-if="editingHandoff" class="flex gap-2">
            <input 
              v-model="handoffNumber" 
              type="text"
              class="flex-1 bg-gray-50 dark:bg-dark-card border border-gray-100 dark:border-dark-border rounded-xl px-3 py-2.5 text-sm focus:outline-none focus:ring-2 focus:ring-primary-200 dark:focus:ring-primary-500/30"
              placeholder="+55 11 99999-0000"
            />
            <button 
              @click="editingHandoff = false"
              class="px-3 py-2 bg-primary-500 text-white rounded-xl text-xs font-medium hover:bg-primary-600 transition-colors"
            >
              OK
            </button>
          </div>
          <button 
            v-else
            @click="editingHandoff = true"
            class="w-full bg-gray-50 dark:bg-dark-card border border-gray-100 dark:border-dark-border rounded-xl p-3 text-sm text-left font-mono text-gray-700 dark:text-gray-300 hover:border-primary-200 dark:hover:border-primary-500/30 transition-colors flex items-center justify-between"
          >
            <span>{{ handoffNumber }}</span>
            <span class="text-[10px] text-primary-500 font-sans font-medium">Editar</span>
          </button>
          <p class="text-[10px] text-gray-400 dark:text-dark-muted mt-1.5">Número para transferência quando IA finalizar qualificação.</p>
        </div>

        <!-- Generate Summary -->
        <div>
          <label class="text-[10px] uppercase tracking-wider text-gray-400 dark:text-dark-muted mb-2 block font-semibold">Resumo</label>
          <button 
            @click="generateSummary"
            :disabled="summaryLoading"
            class="w-full bg-white dark:bg-dark-card hover:bg-gray-50 dark:hover:bg-dark-border border border-gray-100 dark:border-dark-border text-gray-900 dark:text-white py-3 rounded-xl flex items-center justify-center gap-2 font-medium transition-all text-sm disabled:opacity-50"
          >
            <FileText class="w-4 h-4 text-primary-500" /> 
            {{ summaryLoading ? 'Gerando...' : 'Gerar Resumo' }}
          </button>
        </div>
      </div>
    </aside>
  </div>
</template>

<style scoped>
.custom-scrollbar {
  scrollbar-width: thin;
  scrollbar-color: #E5E7EB #F9FAFB;
}
:global(.dark) .custom-scrollbar {
  scrollbar-color: #1F2937 #0B0F1A;
}

.custom-scrollbar::-webkit-scrollbar {
  width: 6px;
}
.custom-scrollbar::-webkit-scrollbar-track {
  background: #F9FAFB;
}
:global(.dark) .custom-scrollbar::-webkit-scrollbar-track {
  background: #0B0F1A;
}
.custom-scrollbar::-webkit-scrollbar-thumb {
  background-color: #E5E7EB;
  border-radius: 4px;
}
:global(.dark) .custom-scrollbar::-webkit-scrollbar-thumb {
  background-color: #1F2937;
}

.fade-enter-active,
.fade-leave-active {
  transition: opacity 0.3s ease;
}
.fade-enter-from,
.fade-leave-to {
  opacity: 0;
}
</style>
