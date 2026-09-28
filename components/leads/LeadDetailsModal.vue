<script setup lang="ts">
import { ref, watch, computed } from 'vue'
import { 
  User, 
  Phone, 
  Calendar, 
  Package, 
  X, 
  TrendingUp, 
  Download, 
  FileImage, 
  CreditCard, 
  Briefcase, 
  DollarSign, 
  Clock, 
  Heart, 
  MapPin, 
  CheckCircle2, 
  XCircle, 
  AlertCircle, 
  FileText,
  FileCheck,
  Building,
  Check
} from 'lucide-vue-next'
import type { Cliente } from '@/types/crm'
import { useSupabaseClient } from '#imports'

const props = defineProps<{
  modelValue: boolean
  lead: Cliente | null
  stages?: any[]
}>()

const emit = defineEmits<{
  (e: 'update:modelValue', value: boolean): void
  (e: 'update-status', id: string, status: string): void
  (e: 'save-notes', id: string, notes: string): void
  (e: 'update-statusdoc', id: string, statusdoc: string, motivostatus?: string): void
}>()

const supabase = useSupabaseClient<any>()
const localNotes = ref('')
const isUpdatingDoc = ref(false)
const showRejectReason = ref(false)
const rejectReason = ref('')
const actionSuccessMsg = ref<string | null>(null)
const localModalidade = ref<'agio' | 'aluguel' | null>(null)
const isUpdatingModalidade = ref(false)

// Lista de documentos conhecidos com nome amigável e campos correspondentes
const knownDocuments = computed(() => {
  if (!props.lead) return []
  const l = props.lead as any
  return [
    { title: 'CPF', hasDoc: l.doc_cpf, url: l.url_cpf },
    { title: 'RG / CNH', hasDoc: l.doc_rg, url: l.url_rg },
    { title: 'Certidão', hasDoc: l.doc_certidao, url: l.url_certidao },
    { title: 'Comprovante Residência', hasDoc: l.doc_residencia, url: l.url_residencia },
    { title: 'Contracheque / Holerite', hasDoc: l.doc_contracheque, url: l.url_contracheque },
    { title: 'Carteira de Trabalho', hasDoc: l.doc_carteira_trabalho, url: l.url_carteira_trabalho },
    { title: 'Movimentação / Extrato', hasDoc: l.doc_movimentacao, url: l.url_movimentacao }
  ]
})

const documentUrls = computed(() => {
  if (!props.lead) return []
  const l = props.lead as any
  const urls = [
    { title: 'CPF', url: l.url_cpf },
    { title: 'RG / CNH', url: l.url_rg },
    { title: 'Certidão', url: l.url_certidao },
    { title: 'Comprovante Residência', url: l.url_residencia },
    { title: 'Contracheque', url: l.url_contracheque },
    { title: 'Carteira de Trabalho', url: l.url_carteira_trabalho },
    { title: 'Movimentação Bancária', url: l.url_movimentacao }
  ]
  return urls.filter(item => item.url && typeof item.url === 'string' && item.url.trim().length > 0)
})

const handleDownload = async (url: string, title?: string) => {
  try {
    const response = await fetch(url)
    if (!response.ok) throw new Error('Network response was not ok')
    const blob = await response.blob()
    const blobUrl = window.URL.createObjectURL(blob)
    
    const a = document.createElement('a')
    a.style.display = 'none'
    a.href = blobUrl
    
    const filename = `${title || 'documento'}_${url.split('/').pop()?.split('?')[0] || 'doc'}`
    a.download = filename
    
    document.body.appendChild(a)
    a.click()
    
    window.URL.revokeObjectURL(blobUrl)
    document.body.removeChild(a)
  } catch (error) {
    console.error('Erro ao baixar documento via fetch. Usando fallback:', error)
    window.open(url, '_blank')
  }
}

// Sync state when lead changes
watch(() => props.lead, (newLead) => {
  if (newLead) {
    localNotes.value = newLead.about || ''
    rejectReason.value = newLead.motivostatus || ''
    showRejectReason.value = false
    actionSuccessMsg.value = null
    localModalidade.value = newLead.modalidade === 'agio' || newLead.modalidade === 'aluguel'
      ? newLead.modalidade
      : null
  }
}, { immediate: true })

const close = () => emit('update:modelValue', false)

const isNotesModified = computed(() => {
  return localNotes.value !== (props.lead?.about || '')
})

const handleCancelNotes = () => {
  localNotes.value = props.lead?.about || ''
}

const handleSaveNotes = async () => {
  if (!props.lead) return
  emit('save-notes', props.lead.id, localNotes.value)
}

const toggleModalidade = async (modalidade: 'agio' | 'aluguel') => {
  if (!props.lead || isUpdatingModalidade.value) return

  const previousModalidade = localModalidade.value
  const nextModalidade = previousModalidade === modalidade ? null : modalidade
  localModalidade.value = nextModalidade
  isUpdatingModalidade.value = true

  try {
    const { error } = await supabase
      .from('leads')
      .update({ modalidade: nextModalidade })
      .eq('id', props.lead.id)

    if (error) throw error

    props.lead.modalidade = nextModalidade
    actionSuccessMsg.value = nextModalidade
      ? `Modalidade atualizada para ${nextModalidade === 'agio' ? 'ágio' : 'aluguel'}.`
      : 'Modalidade removida.'
    setTimeout(() => { actionSuccessMsg.value = null }, 3000)
  } catch (error) {
    localModalidade.value = previousModalidade
    console.error('Erro ao atualizar modalidade do lead:', error)
    alert('Não foi possível atualizar a modalidade do lead.')
  } finally {
    isUpdatingModalidade.value = false
  }
}

// Formatação de CPF
const formatCPF = (cpf?: string | null) => {
  if (!cpf) return 'Não informado'
  const clean = cpf.replace(/\D/g, '')
  if (clean.length === 11) {
    return clean.replace(/(\d{3})(\d{3})(\d{3})(\d{2})/, '$1.$2.$3-$4')
  }
  return cpf
}

// Formatação de Moeda
const formatCurrency = (val?: number | bigint | string | null) => {
  if (val === null || val === undefined || val === '') return 'Não informada'
  const num = Number(val)
  if (isNaN(num)) return String(val)
  return num.toLocaleString('pt-BR', { style: 'currency', currency: 'BRL' })
}

const formatOption = (value?: string | null) => {
  if (!value) return 'Não informado'
  const labels: Record<string, string> = {
    a_vista: 'À vista',
    financiamento: 'Financiamento',
    morar: 'Morar',
    investir: 'Investir',
    compra: 'Compra',
    aluguel: 'Aluguel',
    agio: 'Ágio',
    quente: 'Quente',
    morno: 'Morno',
    nutricao: 'Nutrição',
    sem_perfil_definido: 'Sem perfil definido'
  }
  return labels[value] || value.replace(/_/g, ' ').replace(/^\w/, letter => letter.toUpperCase())
}

const formatBoolean = (value?: boolean | null) => {
  if (value === null || value === undefined) return 'Não informado'
  return value ? 'Sim' : 'Não'
}

const complementarySections = computed(() => {
  const lead = props.lead
  if (!lead) return []

  return [
    {
      title: 'Contato & Origem',
      items: [
        { label: 'E-mail', value: lead.email || 'Não informado' },
        { label: 'Origem do lead', value: formatOption(lead.source) },
        { label: 'Situação', value: formatOption(lead.situacao_nome || lead.stage) },
        { label: 'Última mensagem', value: lead.ultima_mensagem_at ? formatDate(lead.ultima_mensagem_at) : 'Não informada' }
      ]
    },
    {
      title: 'Interesse no Imóvel',
      items: [
        { label: 'Modalidade', value: formatOption(lead.modalidade) },
        { label: 'Forma de pagamento', value: formatOption(lead.forma_pagamento) },
        { label: 'Finalidade', value: formatOption(lead.finalidade) },
        { label: 'Quartos', value: lead.quartos ?? 'Não informado' },
        { label: 'Orçamento máximo', value: formatCurrency(lead.orcamento_maximo) },
        { label: 'Prazo de interesse', value: formatOption(lead.prazo_interesse) }
      ]
    },
    {
      title: 'Capacidade Financeira',
      items: [
        { label: 'Renda familiar', value: formatCurrency(lead.renda_familiar) },
        { label: 'Valor de entrada', value: formatCurrency(lead.valor_entrada) },
        { label: 'Possui FGTS', value: formatBoolean(lead.possui_fgts) },
        { label: 'Saldo do FGTS', value: formatCurrency(lead.saldo_fgts) },
        { label: 'Compõe renda', value: formatBoolean(lead.compoe_renda) },
        { label: 'Nº de compradores', value: lead.numero_compradores ?? 'Não informado' },
        { label: 'Tempo de trabalho', value: formatOption(lead.tempo_trabalho) },
        { label: 'Valor esperado', value: formatCurrency(lead.expected_value) }
      ]
    },
    {
      title: 'Acompanhamento Comercial',
      items: [
        { label: 'Temperatura', value: formatOption(lead.temperatura) },
        { label: 'Motivo da temperatura', value: lead.motivo_temperatura || 'Não informado' },
        { label: 'Próxima ação', value: lead.proxima_acao || 'Não informada' },
        { label: 'Melhor horário', value: lead.melhor_horario_contato || 'Não informado' },
        { label: 'Handoff', value: lead.dataHandoff ? formatDate(lead.dataHandoff) : 'Não realizado' },
        { label: 'Último follow-up', value: lead.last_mensagem_followup_at ? formatDate(lead.last_mensagem_followup_at) : 'Não realizado' }
      ]
    }
  ]
})

const formatDate = (dateString?: string) => {
  if (!dateString) return 'Desconhecido'
  return new Date(dateString).toLocaleDateString('pt-BR', {
    day: '2-digit',
    month: '2-digit',
    year: 'numeric',
    hour: '2-digit',
    minute: '2-digit'
  })
}

const formatPhone = (phone?: string | null, remotejid?: string | null) => {
  const raw = phone || remotejid || ''
  const clean = raw.replace('@c.us', '').replace(/\D/g, '')
  if (clean.length === 13 && clean.startsWith('55')) {
    const ddd = clean.slice(2, 4)
    const part1 = clean.slice(4, 9)
    const part2 = clean.slice(9)
    return `+55 (${ddd}) ${part1}-${part2}`
  } else if (clean.length === 12 && clean.startsWith('55')) {
    const ddd = clean.slice(2, 4)
    const part1 = clean.slice(4, 8)
    const part2 = clean.slice(8)
    return `+55 (${ddd}) ${part1}-${part2}`
  } else if (clean.length === 11) {
    const ddd = clean.slice(0, 2)
    const part1 = clean.slice(2, 7)
    const part2 = clean.slice(7)
    return `(${ddd}) ${part1}-${part2}`
  }
  return raw.replace('@c.us', '') || 'Sem telefone'
}

const formatRelativeTime = (dateString?: string) => {
  if (!dateString) return 'Desconhecido'
  const date = new Date(dateString)
  const now = new Date()
  const diffInSeconds = Math.floor((now.getTime() - date.getTime()) / 1000)
  
  if (diffInSeconds < 60) return 'Agora mesmo'
  if (diffInSeconds < 3600) {
    const m = Math.floor(diffInSeconds / 60)
    return `${m} minuto${m > 1 ? 's' : ''} atrás`
  }
  if (diffInSeconds < 86400) {
    const h = Math.floor(diffInSeconds / 3600)
    return `${h} hora${h > 1 ? 's' : ''} atrás`
  }
  if (diffInSeconds < 2592000) {
    const d = Math.floor(diffInSeconds / 86400)
    return `${d} dia${d > 1 ? 's' : ''} atrás`
  }
  if (diffInSeconds < 31536000) {
    const m = Math.floor(diffInSeconds / 2592000)
    return `${m} mês${m > 1 ? 'es' : ''} atrás`
  }
  const y = Math.floor(diffInSeconds / 31536000)
  return `${y} ano${y > 1 ? 's' : ''} atrás`
}

const computedScore = computed(() => {
  if (!props.lead || !props.stages || props.stages.length === 0) {
    const leadStage = props.lead?.stage || props.lead?.estagiokanbam || 'novo'
    switch (leadStage) {
      case 'novo': return 'C'
      case 'qualificando': return 'B'
      case 'qualificado': return 'A'
      case 'agendado': return 'A+'
      case 'fechado':
      case 'convertido': return 'A++'
      case 'perdido': return 'F'
      default: return props.lead?.score || 'C'
    }
  }
  
  const leadStage = props.lead.stage || props.lead.estagiokanbam || 'novo'
  const leadStageId = props.lead.stage_id
  
  const stageIndex = props.stages.findIndex(s => s.estagio === leadStage || s.id === leadStageId)
  if (stageIndex === -1) return props.lead.score || 'C'
  
  const stageObj = props.stages[stageIndex]
  if (stageObj.estagio === 'perdido') return 'F'
  
  const scores = ['C', 'B', 'A', 'A+', 'A++']
  return scores[stageIndex] || 'A++'
})

const currentStageLabel = computed(() => {
  if (!props.lead) return 'Desconhecido'
  const leadStage = props.lead.stage || props.lead.estagiokanbam || 'novo'
  const stageObj = props.stages?.find(s => s.estagio === leadStage || s.id === props.lead?.stage_id)
  if (stageObj) {
    return stageObj.estagio_name || stageObj.descricao || stageObj.estagio
  }
  const fallbackOptions: Record<string, string> = {
    novo: 'Novo',
    qualificando: 'Qualificando',
    qualificado: 'Qualificado',
    agendado: 'Visita',
    fechado: 'Fechado',
    convertido: 'Fechado',
    perdido: 'Perdido'
  }
  return fallbackOptions[leadStage] || leadStage
})

const currentStageBadgeClasses = computed(() => {
  const leadStage = props.lead?.stage || props.lead?.estagiokanbam || 'novo'
  switch (leadStage) {
    case 'novo':
      return 'bg-blue-50 dark:bg-blue-500/10 text-blue-600 dark:text-blue-400 border border-blue-200 dark:border-blue-500/20 shadow-sm'
    case 'em_atendimento':
    case 'qualificando':
      return 'bg-indigo-50 dark:bg-indigo-500/10 text-indigo-600 dark:text-indigo-400 border border-indigo-200 dark:border-indigo-500/20 shadow-sm'
    case 'negociacao':
    case 'qualificado':
      return 'bg-amber-50 dark:bg-amber-500/10 text-amber-600 dark:text-amber-400 border border-amber-200 dark:border-amber-500/20 shadow-sm'
    case 'visita':
    case 'agendado':
      return 'bg-emerald-50 dark:bg-emerald-500/10 text-emerald-600 dark:text-emerald-400 border border-emerald-200 dark:border-emerald-500/20 shadow-sm'
    case 'fechado':
    case 'convertido':
      return 'bg-green-50 dark:bg-green-500/10 text-green-600 dark:text-green-400 border border-green-200 dark:border-green-500/20 shadow-sm'
    case 'perdido':
      return 'bg-red-50 dark:bg-red-500/10 text-red-600 dark:text-red-400 border border-red-200 dark:border-red-500/20 shadow-sm'
    default:
      return 'bg-gray-100 dark:bg-dark-bg text-gray-500 dark:text-gray-400 border border-gray-200 dark:border-dark-border'
  }
})

// Status Documental Helpers
const docStatusConfig = computed(() => {
  const status = props.lead?.statusdoc || 'aguardando'
  switch (status) {
    case 'aguardando':
      return {
        label: 'Aguardando Documentos',
        badgeClass: 'bg-amber-50 dark:bg-amber-500/10 text-amber-600 dark:text-amber-400 border-amber-200 dark:border-amber-500/20',
        icon: Clock
      }
    case 'esperando':
      return {
        label: 'Esperando Aprovação',
        badgeClass: 'bg-blue-50 dark:bg-blue-500/10 text-blue-600 dark:text-blue-400 border-blue-200 dark:border-blue-500/20',
        icon: AlertCircle
      }
    case 'aprovado':
      return {
        label: 'Financiamento Aprovado',
        badgeClass: 'bg-emerald-50 dark:bg-emerald-500/10 text-emerald-600 dark:text-emerald-400 border-emerald-200 dark:border-emerald-500/20',
        icon: CheckCircle2
      }
    case 'rejeitado':
      return {
        label: 'Financiamento Rejeitado',
        badgeClass: 'bg-rose-50 dark:bg-rose-500/10 text-rose-600 dark:text-rose-400 border-rose-200 dark:border-rose-500/20',
        icon: XCircle
      }
    default:
      return {
        label: status,
        badgeClass: 'bg-gray-100 dark:bg-dark-card text-gray-600 dark:text-gray-400 border-gray-200 dark:border-dark-border',
        icon: FileText
      }
  }
})

// Webhook n8n para notificação de status de CPF / Financiamento
const WEBHOOK_URL = 'https://n8n.srv1098076.hstgr.cloud/webhook/statuscpfjrv'

const sendStatusWebhook = async (lead: Cliente, status: 'aprovado' | 'rejeitado', motivo?: string | null) => {
  try {
    const payload = {
      id: lead.id,
      name: lead.name || '',
      phone: lead.phone || lead.remotejid || '',
      cpf: lead.cpf || '',
      status: status,
      motivostatus: motivo || lead.motivostatus || null,
      updated_at: new Date().toISOString()
    }

    await fetch(WEBHOOK_URL, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json'
      },
      body: JSON.stringify(payload)
    })
  } catch (err) {
    console.error('Erro ao enviar webhook de status:', err)
  }
}

// Ações de Aprovar e Rejeitar Financiamento
const handleApproveFinance = async () => {
  if (!props.lead) return
  isUpdatingDoc.value = true
  try {
    const { error } = await supabase.from('leads').update({
      statusdoc: 'aprovado',
      motivostatus: null
    }).eq('id', props.lead.id)

    if (error) throw error

    props.lead.statusdoc = 'aprovado'
    props.lead.motivostatus = null

    // Dispara webhook assíncrono para o n8n
    await sendStatusWebhook(props.lead, 'aprovado')

    actionSuccessMsg.value = 'Financiamento aprovado e notificação enviada com sucesso! Fechando em 5 segundos...'
    emit('update-statusdoc', props.lead.id, 'aprovado')
    
    setTimeout(() => {
      actionSuccessMsg.value = null
      close()
    }, 5000)
  } catch (err: any) {
    console.error('Erro ao aprovar financiamento:', err)
    alert('Erro ao atualizar status: ' + (err.message || err))
  } finally {
    isUpdatingDoc.value = false
  }
}

const handleRejectFinance = async () => {
  if (!props.lead) return
  if (!rejectReason.value.trim()) {
    alert('Por favor, informe o motivo da rejeição.')
    return
  }

  isUpdatingDoc.value = true
  try {
    // 1. Atualiza status no banco
    const { error } = await supabase.from('leads').update({
      statusdoc: 'rejeitado',
      motivostatus: rejectReason.value.trim()
    }).eq('id', props.lead.id)

    if (error) throw error

    // 2. Apaga todos os agendamentos (appointments) deste lead
    const { error: aptError } = await supabase
      .from('appointments')
      .delete()
      .eq('lead_id', props.lead.id)

    if (aptError) {
      console.warn('Aviso ao apagar appointments do lead:', aptError)
    }

    props.lead.statusdoc = 'rejeitado'
    props.lead.motivostatus = rejectReason.value.trim()
    showRejectReason.value = false

    // 3. Dispara webhook assíncrono para o n8n
    await sendStatusWebhook(props.lead, 'rejeitado', rejectReason.value.trim())

    actionSuccessMsg.value = 'Financiamento rejeitado, agendamentos apagados e webhook enviado! Fechando em 5 segundos...'
    emit('update-statusdoc', props.lead.id, 'rejeitado', rejectReason.value.trim())
    
    setTimeout(() => {
      actionSuccessMsg.value = null
      close()
    }, 5000)
  } catch (err: any) {
    console.error('Erro ao rejeitar financiamento:', err)
    alert('Erro ao atualizar status: ' + (err.message || err))
  } finally {
    isUpdatingDoc.value = false
  }
}

const setQuickReason = (reason: string) => {
  rejectReason.value = reason
}

const handleSetPending = async () => {
  if (!props.lead) return
  isUpdatingDoc.value = true
  try {
    const { error } = await supabase.from('leads').update({
      statusdoc: 'esperando'
    }).eq('id', props.lead.id)

    if (error) throw error

    props.lead.statusdoc = 'esperando'
    actionSuccessMsg.value = 'Status alterado para Esperando Aprovação.'
    emit('update-statusdoc', props.lead.id, 'esperando')
    
    setTimeout(() => { actionSuccessMsg.value = null }, 4000)
  } catch (err: any) {
    console.error('Erro ao alterar status:', err)
  } finally {
    isUpdatingDoc.value = false
  }
}
</script>

<template>
  <!-- Teleport to body for true popup behavior -->
  <Teleport to="body">
    <Transition name="modal">
      <div 
        v-if="modelValue && lead" 
        class="fixed inset-0 z-[70] flex items-end sm:items-center justify-center p-0 sm:p-4"
        @click.self="close"
      >
        <!-- Backdrop -->
        <div class="absolute inset-0 bg-gray-900/50 dark:bg-black/85 backdrop-blur-sm"></div>
        
        <!-- Modal Card -->
        <div class="relative bg-white dark:bg-dark-surface border border-gray-200 dark:border-dark-border rounded-t-2xl sm:rounded-2xl shadow-luxury max-w-2xl w-full max-h-[94dvh] sm:max-h-[92vh] overflow-y-auto transition-all">
          
          <!-- Header -->
          <div class="flex items-center justify-between p-5 sm:p-6 border-b border-gray-100 dark:border-dark-border sticky top-0 bg-white/95 dark:bg-dark-surface/95 backdrop-blur-md z-20">
            <div class="flex items-center gap-3 min-w-0">
              <div class="w-10 h-10 rounded-xl bg-primary-50 dark:bg-primary-500/10 flex items-center justify-center text-primary-500 shadow-sm">
                <FileCheck class="w-5 h-5" />
              </div>
              <div class="min-w-0">
                <h2 class="text-base sm:text-lg font-bold text-gray-900 dark:text-white leading-tight">Detalhes do Interessado & Documentação</h2>
                <p class="hidden sm:block text-xs text-gray-400 dark:text-dark-muted">Informações cadastrais, documentos e status de financiamento</p>
              </div>
            </div>
            <button 
              @click="close" 
              class="p-2 text-gray-400 hover:text-gray-900 dark:hover:text-white hover:bg-gray-100 dark:hover:bg-white/10 rounded-xl transition-all"
            >
              <X class="w-5 h-5" />
            </button>
          </div>

          <!-- Body -->
          <div class="p-5 sm:p-6 space-y-6">

            <!-- Success Alert Feedback -->
            <Transition name="fade">
              <div v-if="actionSuccessMsg" class="p-3 bg-emerald-50 dark:bg-emerald-500/10 border border-emerald-200 dark:border-emerald-500/30 rounded-xl text-xs font-semibold text-emerald-700 dark:text-emerald-400 flex items-center gap-2">
                <CheckCircle2 class="w-4 h-4 flex-shrink-0" />
                <span>{{ actionSuccessMsg }}</span>
              </div>
            </Transition>
            
            <!-- Lead Profile Banner -->
            <div class="flex flex-col sm:flex-row sm:items-center justify-between gap-4 p-4 bg-gray-50/70 dark:bg-dark-bg/60 rounded-2xl border border-gray-100 dark:border-dark-border">
              <div class="flex items-center gap-3.5">
                <div v-if="lead.media_url" class="w-14 h-14 rounded-2xl flex-shrink-0 overflow-hidden border border-gray-200 dark:border-dark-border shadow-sm">
                  <img :src="lead.media_url" :alt="lead.name || 'Avatar'" class="w-full h-full object-cover" />
                </div>
                <div v-else class="w-14 h-14 rounded-2xl bg-primary-100 dark:bg-primary-900/40 flex items-center justify-center text-primary-600 dark:text-primary-400 font-black text-xl flex-shrink-0 shadow-sm">
                  {{ (lead.name || 'D').charAt(0).toUpperCase() }}
                </div>
                <div>
                  <h3 class="text-xl font-bold text-gray-900 dark:text-white leading-tight">{{ lead.name || 'Desconhecido' }}</h3>
                  <div class="flex flex-wrap items-center gap-2 mt-1">
                    <span class="text-xs font-mono font-medium text-gray-500 dark:text-gray-300">
                      {{ formatPhone(lead.phone, lead.remotejid) }}
                    </span>
                    <span v-if="lead.created_at" class="text-[11px] text-gray-400 dark:text-dark-muted">
                      • Cadastrado em {{ formatDate(lead.created_at) }}
                    </span>
                  </div>
                </div>
              </div>

              <!-- Status Atual do Financiamento / Documentos -->
              <div class="flex items-center gap-2 sm:self-center">
                <span :class="['inline-flex items-center gap-1.5 px-3 py-1.5 rounded-xl text-xs font-bold border shadow-sm', docStatusConfig.badgeClass]">
                  <component :is="docStatusConfig.icon" class="w-3.5 h-3.5" />
                  {{ docStatusConfig.label }}
                </span>
              </div>
            </div>

            <!-- Modalidade de interesse -->
            <fieldset class="space-y-2">
              <legend class="text-xs font-bold text-gray-400 dark:text-dark-muted uppercase tracking-wider">
                Modalidade de interesse
              </legend>
              <div class="grid grid-cols-1 sm:grid-cols-2 gap-3 min-h-12">
                <Transition name="deal-option">
                  <button
                    v-if="localModalidade !== 'aluguel'"
                    type="button"
                    :disabled="isUpdatingModalidade"
                    :aria-pressed="localModalidade === 'agio'"
                    class="flex min-h-12 items-center gap-3 rounded-xl border px-4 py-3 text-left transition-colors duration-200 focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-primary-500 focus-visible:ring-offset-2 disabled:cursor-wait disabled:opacity-60 dark:focus-visible:ring-offset-dark-surface"
                    :class="localModalidade === 'agio'
                      ? 'border-primary-500 bg-primary-50 text-primary-700 dark:bg-primary-500/15 dark:text-primary-300'
                      : 'border-gray-200 bg-gray-50/70 text-gray-700 hover:border-primary-300 dark:border-dark-border dark:bg-dark-bg/60 dark:text-gray-200 dark:hover:border-primary-500/60'"
                    @click="toggleModalidade('agio')"
                  >
                    <span
                      class="flex h-6 w-6 shrink-0 items-center justify-center rounded-md border transition-colors duration-200"
                      :class="localModalidade === 'agio' ? 'border-primary-500 bg-primary-500 text-white' : 'border-gray-300 bg-white text-transparent dark:border-white/20 dark:bg-dark-surface'"
                      aria-hidden="true"
                    >
                      <Check class="h-4 w-4" />
                    </span>
                    <span class="text-sm font-bold uppercase tracking-wider">É ágio?</span>
                  </button>
                </Transition>

                <Transition name="deal-option">
                  <button
                    v-if="localModalidade !== 'agio'"
                    type="button"
                    :disabled="isUpdatingModalidade"
                    :aria-pressed="localModalidade === 'aluguel'"
                    class="flex min-h-12 items-center gap-3 rounded-xl border px-4 py-3 text-left transition-colors duration-200 focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-primary-500 focus-visible:ring-offset-2 disabled:cursor-wait disabled:opacity-60 dark:focus-visible:ring-offset-dark-surface"
                    :class="localModalidade === 'aluguel'
                      ? 'border-primary-500 bg-primary-50 text-primary-700 dark:bg-primary-500/15 dark:text-primary-300'
                      : 'border-gray-200 bg-gray-50/70 text-gray-700 hover:border-primary-300 dark:border-dark-border dark:bg-dark-bg/60 dark:text-gray-200 dark:hover:border-primary-500/60'"
                    @click="toggleModalidade('aluguel')"
                  >
                    <span
                      class="flex h-6 w-6 shrink-0 items-center justify-center rounded-md border transition-colors duration-200"
                      :class="localModalidade === 'aluguel' ? 'border-primary-500 bg-primary-500 text-white' : 'border-gray-300 bg-white text-transparent dark:border-white/20 dark:bg-dark-surface'"
                      aria-hidden="true"
                    >
                      <Check class="h-4 w-4" />
                    </span>
                    <span class="text-sm font-bold uppercase tracking-wider">É aluguel?</span>
                  </button>
                </Transition>
              </div>
            </fieldset>

            <!-- DECISION ACTION BOX: APROVAR OU REJEITAR FINANCIAMENTO -->
            <div class="p-4 sm:p-5 rounded-2xl border transition-all" :class="[
              lead.statusdoc === 'esperando' 
                ? 'bg-gradient-to-br from-blue-50/70 via-indigo-50/30 to-purple-50/20 dark:from-blue-950/20 dark:via-indigo-950/20 dark:to-dark-surface border-blue-200 dark:border-blue-500/30'
                : lead.statusdoc === 'aprovado'
                ? 'bg-emerald-50/40 dark:bg-emerald-950/10 border-emerald-200 dark:border-emerald-500/20'
                : lead.statusdoc === 'rejeitado'
                ? 'bg-rose-50/40 dark:bg-rose-950/10 border-rose-200 dark:border-rose-500/20'
                : 'bg-gray-50/50 dark:bg-dark-bg/40 border-gray-200 dark:border-dark-border'
            ]">
              <div class="flex flex-col sm:flex-row sm:items-center justify-between gap-3 mb-3">
                <div class="flex items-center gap-2">
                  <FileText class="w-4 h-4 text-primary-500" />
                  <span class="text-xs font-bold uppercase tracking-wider text-gray-700 dark:text-gray-200">
                    Ação de Financiamento & Documentação
                  </span>
                </div>
                <span v-if="lead.statusdoc === 'esperando'" class="text-[11px] font-semibold text-blue-600 dark:text-blue-400 bg-blue-100/60 dark:bg-blue-500/20 px-2 py-0.5 rounded-full">
                  Aguardando sua decisão
                </span>
              </div>

              <!-- When Pending / Esperando: Action Buttons -->
              <div v-if="lead.statusdoc === 'esperando' || !lead.statusdoc || lead.statusdoc === 'aguardando'" class="space-y-3">
                <p class="text-xs text-gray-500 dark:text-dark-muted">
                  Analise a documentação enviada pelo cliente. Você pode aprovar ou rejeitar o financiamento diretamente abaixo:
                </p>

                <div class="flex flex-wrap items-center gap-3 pt-1">
                  <!-- Botão Aprovar -->
                  <button
                    @click="handleApproveFinance"
                    :disabled="isUpdatingDoc"
                    class="flex-1 min-w-[140px] flex items-center justify-center gap-2 px-4 py-2.5 bg-emerald-600 hover:bg-emerald-700 text-white rounded-xl text-xs font-bold shadow-sm transition-all hover:scale-[1.02] active:scale-[0.98] disabled:opacity-50"
                  >
                    <CheckCircle2 class="w-4 h-4" />
                    <span>Aprovar Financiamento</span>
                  </button>

                  <!-- Botão Rejeitar -->
                  <button
                    @click="showRejectReason = !showRejectReason"
                    :disabled="isUpdatingDoc"
                    class="flex-1 min-w-[140px] flex items-center justify-center gap-2 px-4 py-2.5 bg-rose-600 hover:bg-rose-700 text-white rounded-xl text-xs font-bold shadow-sm transition-all hover:scale-[1.02] active:scale-[0.98] disabled:opacity-50"
                  >
                    <XCircle class="w-4 h-4" />
                    <span>Rejeitar Financiamento</span>
                  </button>
                </div>

                <!-- Box de Motivo da Rejeição -->
                <Transition name="fade">
                  <div v-if="showRejectReason" class="mt-3 p-4 bg-white dark:bg-dark-surface border border-rose-200 dark:border-rose-500/30 rounded-xl space-y-3 shadow-sm">
                    <div class="flex items-center justify-between">
                      <label class="text-xs font-bold text-rose-700 dark:text-rose-400">Motivo da Rejeição</label>
                      <span class="text-[10px] text-gray-400">Será salvo no cadastro do lead</span>
                    </div>

                    <!-- Quick suggestions -->
                    <div class="flex flex-wrap gap-1.5">
                      <button
                        v-for="sug in ['Score insuficiente', 'Documento ilegível', 'Margem reprovada', 'Restrição cadastral', 'Renda não comprovada']"
                        :key="sug"
                        type="button"
                        @click="setQuickReason(sug)"
                        class="text-[10px] px-2.5 py-1 rounded-lg bg-gray-100 dark:bg-dark-bg text-gray-600 dark:text-gray-300 hover:bg-rose-50 dark:hover:bg-rose-500/10 hover:text-rose-600 border border-gray-200 dark:border-dark-border transition-colors"
                      >
                        {{ sug }}
                      </button>
                    </div>

                    <textarea
                      v-model="rejectReason"
                      placeholder="Descreva detalhadamente o motivo da reprovação..."
                      rows="2"
                      class="w-full bg-gray-50 dark:bg-dark-bg border border-gray-200 dark:border-dark-border text-gray-900 dark:text-white placeholder-gray-400 rounded-lg p-2.5 text-xs focus:outline-none focus:ring-1 focus:ring-rose-500 resize-none"
                    ></textarea>

                    <div class="flex justify-end gap-2">
                      <button
                        @click="showRejectReason = false"
                        class="px-3 py-1.5 text-xs text-gray-500 dark:text-gray-400 hover:text-gray-700 rounded-lg"
                      >
                        Cancelar
                      </button>
                      <button
                        @click="handleRejectFinance"
                        :disabled="isUpdatingDoc || !rejectReason.trim()"
                        class="px-4 py-1.5 bg-rose-600 hover:bg-rose-700 text-white rounded-lg text-xs font-bold transition-all disabled:opacity-50"
                      >
                        Confirmar Rejeição
                      </button>
                    </div>
                  </div>
                </Transition>
              </div>

              <!-- When already Approved or Rejected: Status Summary + Option to change -->
              <div v-else class="space-y-2">
                <div v-if="lead.statusdoc === 'aprovado'" class="flex items-center justify-between">
                  <div class="flex items-center gap-2 text-xs font-semibold text-emerald-700 dark:text-emerald-400">
                    <CheckCircle2 class="w-4 h-4" />
                    <span>Financiamento aprovado para este cliente.</span>
                  </div>
                  <button
                    @click="handleSetPending"
                    class="text-[11px] text-gray-500 hover:text-primary-500 underline"
                  >
                    Reavaliar status
                  </button>
                </div>

                <div v-else-if="lead.statusdoc === 'rejeitado'" class="space-y-1.5">
                  <div class="flex items-center justify-between">
                    <div class="flex items-center gap-2 text-xs font-semibold text-rose-700 dark:text-rose-400">
                      <XCircle class="w-4 h-4" />
                      <span>Financiamento rejeitado</span>
                    </div>
                    <button
                      @click="handleSetPending"
                      class="text-[11px] text-gray-500 hover:text-primary-500 underline"
                    >
                      Reavaliar status
                    </button>
                  </div>
                  <div v-if="lead.motivostatus" class="p-2.5 bg-rose-100/50 dark:bg-rose-950/30 rounded-lg text-xs text-rose-800 dark:text-rose-300 border border-rose-200/50 dark:border-rose-500/20">
                    <span class="font-bold">Motivo:</span> {{ lead.motivostatus }}
                  </div>
                </div>
              </div>
            </div>
            
            <!-- Dados Cadastrais & Financeiros (Grid Completo) -->
            <div class="space-y-3">
              <label class="text-xs font-bold text-gray-400 dark:text-dark-muted uppercase tracking-wider">
                Dados Cadastrais & Qualificação
              </label>

              <div class="grid grid-cols-2 sm:grid-cols-3 gap-3">
                
                <!-- CPF -->
                <div class="p-3 bg-gray-50/70 dark:bg-dark-bg/60 rounded-xl border border-gray-100 dark:border-dark-border">
                  <div class="flex items-center gap-1.5 text-gray-400 dark:text-dark-muted mb-1">
                    <CreditCard class="w-3.5 h-3.5 text-primary-500" />
                    <span class="text-[10px] font-bold uppercase tracking-wider">CPF</span>
                  </div>
                  <p class="text-xs font-mono font-bold text-gray-900 dark:text-white truncate">
                    {{ formatCPF(lead.cpf) }}
                  </p>
                </div>

                <!-- Renda Mensal -->
                <div class="p-3 bg-gray-50/70 dark:bg-dark-bg/60 rounded-xl border border-gray-100 dark:border-dark-border">
                  <div class="flex items-center gap-1.5 text-gray-400 dark:text-dark-muted mb-1">
                    <DollarSign class="w-3.5 h-3.5 text-emerald-500" />
                    <span class="text-[10px] font-bold uppercase tracking-wider">Renda Mensal</span>
                  </div>
                  <p class="text-xs font-bold text-gray-900 dark:text-white truncate">
                    {{ formatCurrency(lead.renda_mensal) }}
                    <span v-if="lead.tipo_renda" class="text-[10px] text-gray-400 font-normal">({{ lead.tipo_renda }})</span>
                  </p>
                </div>

                <!-- Profissão -->
                <div class="p-3 bg-gray-50/70 dark:bg-dark-bg/60 rounded-xl border border-gray-100 dark:border-dark-border">
                  <div class="flex items-center gap-1.5 text-gray-400 dark:text-dark-muted mb-1">
                    <Briefcase class="w-3.5 h-3.5 text-blue-500" />
                    <span class="text-[10px] font-bold uppercase tracking-wider">Profissão</span>
                  </div>
                  <p class="text-xs font-semibold text-gray-900 dark:text-white truncate">
                    {{ lead.profissao || 'Não informada' }}
                  </p>
                </div>

                <!-- Estado Civil -->
                <div class="p-3 bg-gray-50/70 dark:bg-dark-bg/60 rounded-xl border border-gray-100 dark:border-dark-border">
                  <div class="flex items-center gap-1.5 text-gray-400 dark:text-dark-muted mb-1">
                    <Heart class="w-3.5 h-3.5 text-rose-500" />
                    <span class="text-[10px] font-bold uppercase tracking-wider">Estado Civil</span>
                  </div>
                  <p class="text-xs font-semibold text-gray-900 dark:text-white truncate">
                    {{ lead.estado_civil || 'Não informado' }}
                  </p>
                </div>

                <!-- Imóvel de Interesse -->
                <div class="p-3 bg-gray-50/70 dark:bg-dark-bg/60 rounded-xl border border-gray-100 dark:border-dark-border">
                  <div class="flex items-center gap-1.5 text-gray-400 dark:text-dark-muted mb-1">
                    <Building class="w-3.5 h-3.5 text-amber-500" />
                    <span class="text-[10px] font-bold uppercase tracking-wider">Tipo Imóvel</span>
                  </div>
                  <p class="text-xs font-semibold text-gray-900 dark:text-white truncate">
                    {{ lead.tipo_imovel || 'Não informado' }}
                  </p>
                </div>

                <!-- Endereço Atual (span 2 ou 3) -->
                <div class="col-span-2 sm:col-span-3 p-3 bg-gray-50/70 dark:bg-dark-bg/60 rounded-xl border border-gray-100 dark:border-dark-border">
                  <div class="flex items-center gap-1.5 text-gray-400 dark:text-dark-muted mb-1">
                    <MapPin class="w-3.5 h-3.5 text-red-500" />
                    <span class="text-[10px] font-bold uppercase tracking-wider">Endereço / Localização</span>
                  </div>
                  <p class="text-xs font-semibold text-gray-900 dark:text-white truncate">
                    {{ lead.endereco_atual || lead.localizacao || 'Não informado' }}
                  </p>
                </div>

              </div>
            </div>

            <!-- Informações complementares do cadastro -->
            <div class="space-y-5">
              <div class="flex items-center gap-2">
                <FileText class="h-4 w-4 text-primary-500" />
                <h3 class="text-xs font-bold text-gray-400 dark:text-dark-muted uppercase tracking-wider">
                  Informações completas do lead
                </h3>
              </div>

              <section
                v-for="section in complementarySections"
                :key="section.title"
                class="space-y-2.5"
              >
                <h4 class="text-xs font-bold text-gray-700 dark:text-gray-200">
                  {{ section.title }}
                </h4>
                <dl class="grid grid-cols-1 sm:grid-cols-2 gap-2.5">
                  <div
                    v-for="item in section.items"
                    :key="item.label"
                    class="min-h-16 rounded-xl border border-gray-100 bg-gray-50/70 p-3 dark:border-dark-border dark:bg-dark-bg/60"
                  >
                    <dt class="text-[10px] font-bold uppercase tracking-wider text-gray-400 dark:text-dark-muted">
                      {{ item.label }}
                    </dt>
                    <dd class="mt-1 break-words text-xs font-semibold text-gray-900 dark:text-white">
                      {{ item.value }}
                    </dd>
                  </div>
                </dl>
              </section>
            </div>

            <!-- Checklist & Galeria de Documentos Anexados -->
            <div class="space-y-3">
              <div class="flex items-center justify-between">
                <label class="text-xs font-bold text-gray-400 dark:text-dark-muted uppercase tracking-wider">
                  Documentos & Comprovantes
                </label>
                <span class="text-[11px] text-gray-500 dark:text-dark-muted">
                  {{ documentUrls.length }} {{ documentUrls.length === 1 ? 'arquivo disponível' : 'arquivos disponíveis' }}
                </span>
              </div>

              <!-- Checklist dos documentos requeridos -->
              <div class="grid grid-cols-2 sm:grid-cols-3 gap-2">
                <div 
                  v-for="doc in knownDocuments" 
                  :key="doc.title"
                  :class="[
                    'px-3 py-2 rounded-xl text-xs flex items-center justify-between border transition-all',
                    doc.hasDoc || doc.url
                      ? 'bg-emerald-50/50 dark:bg-emerald-500/10 border-emerald-200 dark:border-emerald-500/20 text-emerald-800 dark:text-emerald-300'
                      : 'bg-gray-50/50 dark:bg-dark-bg/30 border-gray-100 dark:border-dark-border text-gray-400 dark:text-dark-muted'
                  ]"
                >
                  <span class="truncate font-medium">{{ doc.title }}</span>
                  <CheckCircle2 v-if="doc.hasDoc || doc.url" class="w-4 h-4 text-emerald-500 flex-shrink-0" />
                  <span v-else class="text-[10px] text-gray-400">Pendente</span>
                </div>
              </div>

              <!-- Miniaturas dos Documentos para Visualização / Download -->
              <div v-if="documentUrls.length > 0" class="pt-2">
                <div class="grid grid-cols-3 sm:grid-cols-4 gap-3">
                  <div 
                    v-for="(item, index) in documentUrls" 
                    :key="index" 
                    class="relative group rounded-xl border border-gray-200 dark:border-dark-border bg-gray-50 dark:bg-dark-bg/50 overflow-hidden aspect-square flex flex-col items-center justify-center shadow-sm"
                  >
                    <!-- Imagem do documento -->
                    <img 
                      :src="item.url" 
                      :alt="item.title" 
                      class="w-full h-full object-cover transition-transform duration-300 group-hover:scale-105" 
                      @error="(e) => { (e.target as HTMLElement).style.display = 'none'; (e.target as HTMLElement).nextElementSibling?.classList.remove('hidden') }" 
                    />
                    
                    <!-- Fallback se não for imagem ou der erro -->
                    <div class="hidden flex-col items-center justify-center text-gray-400 dark:text-gray-500 w-full h-full p-2 text-center">
                      <FileImage class="w-8 h-8 mb-1 opacity-60 text-primary-500" />
                      <span class="text-[10px] font-semibold truncate max-w-full">{{ item.title }}</span>
                    </div>

                    <!-- Label do documento no rodapé do card -->
                    <div class="absolute bottom-0 inset-x-0 bg-gray-900/70 text-white text-[10px] py-1 px-1.5 text-center truncate backdrop-blur-xs">
                      {{ item.title }}
                    </div>
                    
                    <!-- Overlay hover para o botão de baixar/abrir -->
                    <div class="absolute inset-0 bg-gray-900/50 opacity-0 group-hover:opacity-100 transition-opacity duration-200 flex items-center justify-center gap-2 backdrop-blur-[2px]">
                      <button 
                        @click.prevent="handleDownload(item.url, item.title)" 
                        class="bg-white dark:bg-dark-surface text-gray-900 dark:text-white p-2.5 rounded-full hover:scale-110 shadow-md transition-transform" 
                        :title="'Baixar ' + item.title"
                      >
                        <Download class="w-4 h-4" />
                      </button>
                    </div>
                  </div>
                </div>
              </div>
            </div>

            <!-- Notes / Observações -->
            <div class="space-y-2">
              <label class="text-xs font-bold text-gray-400 dark:text-dark-muted uppercase tracking-wider">
                Observações do Corretor / Analista
              </label>
              <textarea
                v-model="localNotes"
                placeholder="Adicione observações sobre o perfil deste interessado ou histórico do financiamento..."
                rows="3"
                class="w-full bg-gray-50 dark:bg-dark-bg border border-gray-200 dark:border-dark-border text-gray-900 dark:text-white placeholder-gray-400 dark:placeholder-gray-500 rounded-xl px-4 py-3 focus:outline-none focus:ring-2 focus:ring-primary-500/20 focus:border-primary-500 resize-none text-xs shadow-sm transition-all"
              ></textarea>
              
              <!-- Cancel / Save Buttons -->
              <Transition name="fade">
                <div v-if="isNotesModified" class="flex justify-end gap-2 pt-1">
                  <button
                    @click="handleCancelNotes"
                    class="px-4 py-2 text-xs font-semibold text-gray-500 dark:text-gray-400 hover:text-gray-900 dark:hover:text-white transition-colors"
                  >
                    Cancelar
                  </button>
                  <button
                    @click="handleSaveNotes"
                    class="px-4 py-2 text-xs font-semibold text-white bg-primary-500 hover:bg-primary-600 rounded-xl shadow-sm transition-all"
                  >
                    Salvar Observações
                  </button>
                </div>
              </Transition>
            </div>

          </div>

          <!-- Footer -->
          <div class="flex items-center justify-between px-6 py-4 border-t border-gray-100 dark:border-dark-border text-xs text-gray-500 dark:text-dark-muted bg-gray-50/50 dark:bg-dark-bg/50">
            <span class="font-medium">Follow-ups: {{ lead.metadata?.followups || 0 }} tentativas</span>
            <span class="font-medium">Última interação: {{ formatRelativeTime(lead.ultima_mensagem_at || lead.created_at) }}</span>
          </div>

        </div>
      </div>
    </Transition>
  </Teleport>
</template>

<style scoped>
.modal-enter-active,
.modal-leave-active {
  transition: opacity 0.25s ease;
}

.modal-enter-from,
.modal-leave-to {
  opacity: 0;
}

.modal-enter-active .relative,
.modal-leave-active .relative {
  transition: transform 0.25s cubic-bezier(0.16, 1, 0.3, 1);
}

.modal-enter-from .relative,
.modal-leave-to .relative {
  transform: scale(0.96);
}

.fade-enter-active,
.fade-leave-active {
  transition: opacity 0.2s ease;
}

.fade-enter-from,
.fade-leave-to {
  opacity: 0;
}

.deal-option-enter-active,
.deal-option-leave-active {
  transition: opacity 220ms ease, transform 220ms ease;
}

.deal-option-enter-from,
.deal-option-leave-to {
  opacity: 0;
  transform: translateY(-6px) scale(0.98);
}

@media (prefers-reduced-motion: reduce) {
  .deal-option-enter-active,
  .deal-option-leave-active {
    transition-duration: 1ms;
  }
}
</style>
