<script setup lang="ts">
import { ref, computed, onMounted, watch } from 'vue'
import { 
  BarChart3, TrendingUp, Users, Calendar, Download, 
  CheckCircle2, UserPlus, Bot, Handshake, Clock, 
  Target, ChevronLeft, ChevronRight, MessageSquare,
  AlertTriangle, Lightbulb, Star, ExternalLink, ChevronDown
} from 'lucide-vue-next'
import { useSupabaseClient } from '#imports'

const { mainMargin } = useSidebarState()
const supabase = useSupabaseClient<any>()

// State
const loading = ref(true)
const selectedWeek = ref('')
const activityPage = ref(1)
const activityPerPage = 4
const weekDropdownOpen = ref(false)

// Data refs
const weeks = ref<any[]>([])
const activityLog = ref<any[]>([])
const dbActivities = ref<any[]>([])
const hourlyActivity = ref<{ hour: number; count: number }[]>(
  Array.from({ length: 24 }, (_, hour) => ({ hour, count: 0 }))
)
const hourlyLoading = ref(false)


function getMonday(d: Date) {
  const date = new Date(d)
  const day = date.getDay()
  const diff = date.getDate() - day + (day === 0 ? -6 : 1)
  return new Date(date.setDate(diff))
}

function localYyyymmdd(d: Date) {
  const yyyy = d.getFullYear()
  const mm = String(d.getMonth() + 1).padStart(2, '0')
  const dd = String(d.getDate()).padStart(2, '0')
  return `${yyyy}-${mm}-${dd}`
}

function getStartAndEndOfWeek() {
  const now = new Date()
  const monday = getMonday(now)
  const sunday = new Date(monday)
  sunday.setDate(monday.getDate() + 6)
  
  return {
    semana_inicio: localYyyymmdd(monday),
    semana_fim: localYyyymmdd(sunday)
  }
}

function getWeekStartDate(dateStr: string) {
  try {
    const d = new Date(dateStr)
    if (isNaN(d.getTime())) {
      return getStartAndEndOfWeek().semana_inicio
    }
    const monday = getMonday(d)
    return localYyyymmdd(monday)
  } catch (e) {
    return getStartAndEndOfWeek().semana_inicio
  }
}

function formatDateBr(dateStr: string) {
  if (!dateStr) return ''
  try {
    const parts = dateStr.slice(0, 10).split('-')
    if (parts.length === 3) {
      return `${parts[2]}/${parts[1]}/${parts[0]}`
    }
    return dateStr
  } catch (e) {
    return dateStr
  }
}

function formatWeekPeriod(inicioStr: string, fimStr: string) {
  const inicio = new Date(inicioStr + 'T12:00:00')
  const fim = new Date(fimStr + 'T12:00:00')
  const meses = ['Jan', 'Fev', 'Mar', 'Abr', 'Mai', 'Jun', 'Jul', 'Ago', 'Set', 'Out', 'Nov', 'Dez']
  const diaInicio = String(inicio.getDate()).padStart(2, '0')
  const mesInicio = meses[inicio.getMonth()]
  const diaFim = String(fim.getDate()).padStart(2, '0')
  const mesFim = meses[fim.getMonth()]
  
  if (inicio.getMonth() === fim.getMonth()) {
    return `${diaInicio} – ${diaFim} ${mesInicio}`
  } else {
    return `${diaInicio} ${mesInicio} – ${diaFim} ${mesFim}`
  }
}

const currentWeekLabel = computed(() => {
  const w = weeks.value.find(w => w.key === selectedWeek.value)
  return w ? w.label : ''
})

const currentWeekShort = computed(() => {
  const w = weeks.value.find(w => w.key === selectedWeek.value)
  return w ? w.short : ''
})

// Current week metrics
const currentMetrics = computed(() => {
  const active = weeks.value.find(w => w.key === selectedWeek.value)
  if (!active) return {}
  return {
    totalLeads: Number(active.total_leads || 0),
    qualificados: Number(active.qualificados || 0),
    agendamentos: Number(active.agendamentos || 0),
    convertidos: Number(active.convertidos || 0),
    taxaConversao: Number(active.taxa_conversao || 0),
    receita: Number(active.receita || 0)
  }
})
// Current week report content (merging mock data for realism or dynamically generated for future database records)
const currentReport = computed(() => {
  const active = weeks.value.find(w => w.key === selectedWeek.value)
  if (!active) return {}
  
  const { mockWeeklyReports } = useMockData()
  const mockKeys = ['semana-1', 'semana-2', 'semana-3', 'semana-4']
  
  if (mockKeys.includes(selectedWeek.value)) {
    const report = mockWeeklyReports[selectedWeek.value] || mockWeeklyReports['semana-1']
    return {
      ...report,
      title: `Semana ${formatWeekPeriod(active.semana_inicio, active.semana_fim)}`
    }
  }
  
  // Dynamic generated report for database weeks
  const totalLeads = Number(active.total_leads || 0)
  const qualificados = Number(active.qualificados || 0)
  const agendamentos = Number(active.agendamentos || 0)
  const convertidos = Number(active.convertidos || 0)
  const taxaConversao = Number(active.taxa_conversao || 0)
  const receita = Number(active.receita || 0)

  let resumo = ''
  const destaques: string[] = []
  const conselhos: string[] = []
  const alertas: string[] = []

  if (totalLeads === 0) {
    resumo = 'Nenhum lead registrado no pipeline durante esta semana.'
    destaques.push('📭 Aguardando novas oportunidades de captação de leads.')
    conselhos.push('Revise o funcionamento das campanhas de tráfego pago e as integrações de WhatsApp/Site.')
    alertas.push('🚨 Sem fluxo de leads nesta semana. Verifique o status das suas integrações.')
  } else {
    resumo = `Operamos um volume de ${totalLeads} lead(s) esta semana, dos quais ${qualificados} foram qualificado(s). Registramos ${agendamentos} agendamento(s) no período.`
    
    if (convertidos > 0) {
      resumo += ` Tivemos um ótimo desempenho com ${convertidos} conversão(ões) consolidada(s), gerando uma receita de ${formatCurrency(receita)}.`
      destaques.push(`🏆 ${convertidos} venda(s) fechada(s) totalizando ${formatCurrency(receita)} em receita!`)
    } else {
      resumo += ' Ainda não registramos vendas fechadas neste período.'
      alertas.push('⚠️ Nenhuma conversão (fechamento) registrada nesta semana. Acompanhe os agendamentos ativos.')
    }

    if (qualificados > 0) {
      destaques.push(`📈 ${qualificados} lead(s) qualificado(s) avançando no pipeline de vendas.`)
      conselhos.push('Priorize o atendimento dos leads qualificados para não perder o timing.')
    }
    
    if (agendamentos > 0) {
      destaques.push(`📅 ${agendamentos} visita(s) ou agendamento(s) ativo(s).`)
      conselhos.push('Prepare material detalhado do imóvel (fotos, vídeos) antes das visitas agendadas.')
    }

    if (conselhos.length === 0) {
      conselhos.push('Mantenha contato rápido com os novos leads nas primeiras 2 horas.')
    }
  }

  return {
    title: `Semana ${formatWeekPeriod(active.semana_inicio, active.semana_fim)}`,
    resumo,
    destaques,
    conselhos,
    alertas
  }
})

// Filtered activity log mapped to database weeks indices
const filteredActivities = computed(() => {
  if (!selectedWeek.value) return []
  
  const mockKeys = ['semana-1', 'semana-2', 'semana-3', 'semana-4']
  if (mockKeys.includes(selectedWeek.value)) {
    return activityLog.value.filter(a => a.week === selectedWeek.value)
  }
  
  return dbActivities.value.filter(a => a.week === selectedWeek.value)
})

const paginatedActivities = computed(() => {
  const start = (activityPage.value - 1) * activityPerPage
  return filteredActivities.value.slice(start, start + activityPerPage)
})

const totalActivityPages = computed(() => 
  Math.max(1, Math.ceil(filteredActivities.value.length / activityPerPage))
)

// Metric cards config
const metricCards = computed(() => [
  { title: 'Total Leads', value: currentMetrics.value.totalLeads || 0, icon: Users, color: 'text-blue-600 dark:text-blue-400', bg: 'bg-blue-50 dark:bg-blue-500/10', border: 'border-blue-100 dark:border-blue-500/20' },
  { title: 'Qualificados', value: currentMetrics.value.qualificados || 0, icon: Target, color: 'text-emerald-600 dark:text-emerald-400', bg: 'bg-emerald-50 dark:bg-emerald-500/10', border: 'border-emerald-100 dark:border-emerald-500/20' },
  { title: 'Agendamentos', value: currentMetrics.value.agendamentos || 0, icon: Calendar, color: 'text-primary-600 dark:text-primary-400', bg: 'bg-primary-50 dark:bg-primary-500/10', border: 'border-primary-100 dark:border-primary-500/20' },
])

const maxHourlyMessages = computed(() => Math.max(...hourlyActivity.value.map(item => item.count), 0))
const totalMessages = computed(() => hourlyActivity.value.reduce((total, item) => total + item.count, 0))
const busiestHours = computed(() => [...hourlyActivity.value]
  .filter(item => item.count > 0)
  .sort((a, b) => b.count - a.count || a.hour - b.hour)
  .slice(0, 3)
)

const formatHour = (hour: number) => `${String(hour).padStart(2, '0')}:00–${String((hour + 1) % 24).padStart(2, '0')}:00`

const aggregateHistoryByHour = (history: any[], start: Date, end: Date) => {
  const counts = new Map<number, number>()
  const hourFormatter = new Intl.DateTimeFormat('pt-BR', {
    hour: '2-digit', hour12: false, timeZone: 'America/Sao_Paulo'
  })

  for (const row of history) {
    const message = typeof row.message === 'string' ? (() => { try { return JSON.parse(row.message) } catch { return {} } })() : (row.message || {})
    const payload = message.data || message
    const rawDate = row.sent_at || row.created_at || payload.created_at || payload.timestamp || message.created_at || message.timestamp
    if (!rawDate) continue
    const date = new Date(rawDate)
    if (Number.isNaN(date.getTime()) || date < start || date >= end) continue
    const hour = Number(hourFormatter.format(date)) % 24
    counts.set(hour, (counts.get(hour) || 0) + 1)
  }

  return Array.from({ length: 24 }, (_, hour) => ({ hour, count: counts.get(hour) || 0 }))
}

const fetchHourlyActivity = async () => {
  const activeWeek = weeks.value.find(w => w.key === selectedWeek.value)
  if (!activeWeek?.semana_inicio) return

  hourlyLoading.value = true
  try {
    const start = new Date(`${activeWeek.semana_inicio}T00:00:00-03:00`)
    const end = new Date(start.getTime() + 7 * 24 * 60 * 60 * 1000)
    const { data: history, error: historyError } = await supabase
      .from('leads')
      .select('ultima_mensagem_at')
      .not('ultima_mensagem_at', 'is', null)
      .gte('ultima_mensagem_at', start.toISOString())
      .lt('ultima_mensagem_at', end.toISOString())
    if (historyError) throw historyError
    hourlyActivity.value = aggregateHistoryByHour(
      (history || []).map((item: any) => ({ sent_at: item.ultima_mensagem_at })),
      start,
      end
    )
  } catch (error) {
    console.warn('Não foi possível carregar os horários das mensagens:', error)
    hourlyActivity.value = Array.from({ length: 24 }, (_, hour) => ({ hour, count: 0 }))
  } finally {
    hourlyLoading.value = false
  }
}

function formatCurrency(val: number) {
  if (val >= 1000) return 'R$ ' + (val / 1000).toFixed(val % 1000 === 0 ? 0 : 1) + 'k'
  return 'R$ ' + val
}

function getActivityIcon(type: string) {
  switch (type) {
    case 'deal_closed': return Handshake
    case 'meeting_scheduled': return Calendar
    case 'lead_qualified': return CheckCircle2
    case 'ai_action': return Bot
    case 'lead_new': return UserPlus
    default: return Star
  }
}

function getActivityColor(type: string) {
  switch (type) {
    case 'deal_closed': return 'text-green-500 bg-green-50 dark:bg-green-500/10'
    case 'meeting_scheduled': return 'text-primary-500 bg-primary-50 dark:bg-primary-500/10'
    case 'lead_qualified': return 'text-emerald-500 bg-emerald-50 dark:bg-emerald-500/10'
    case 'ai_action': return 'text-cyan-500 bg-cyan-50 dark:bg-cyan-500/10'
    case 'lead_new': return 'text-blue-500 bg-blue-50 dark:bg-blue-500/10'
    default: return 'text-gray-500 bg-gray-50 dark:bg-gray-500/10'
  }
}

function getActivityLabel(type: string) {
  switch (type) {
    case 'deal_closed': return 'Fechamento'
    case 'meeting_scheduled': return 'Agendamento'
    case 'lead_qualified': return 'Qualificação'
    case 'ai_action': return 'IA'
    case 'lead_new': return 'Novo Lead'
    default: return 'Atividade'
  }
}

function timeAgo(dateStr: string) {
  const diff = Date.now() - new Date(dateStr).getTime()
  const mins = Math.floor(diff / 60000)
  if (mins < 60) return `${mins}min atrás`
  const hours = Math.floor(mins / 60)
  if (hours < 24) return `${hours}h atrás`
  const days = Math.floor(hours / 24)
  return `${days}d atrás`
}

// Dynamically generated funnel and weeklyTrend based on database data
const chartData = computed(() => {
  const active = weeks.value.find(w => w.key === selectedWeek.value)
  const funnel = active ? [
    { label: 'Novos', value: Number(active.leads_novos_parados !== undefined ? active.leads_novos_parados : (active.total_leads || 0)), color: '#00539B' },
    { label: 'Qualificados', value: Number(active.qualificados || 0), color: '#0F766E' },
    { label: 'Agendados', value: Number(active.agendamentos || 0), color: '#D97706' },
    { label: 'Convertidos', value: Number(active.convertidos || 0), color: '#059669' },
  ] : []
  
  // Return the last 4 weeks chronologically (oldest to newest)
  const weeklyTrend = [...weeks.value].slice(0, 4).reverse().map((w, idx) => {
    const date = new Date(w.semana_inicio + 'T12:00:00')
    const formattedDate = `${String(date.getDate()).padStart(2, '0')}/${String(date.getMonth() + 1).padStart(2, '0')}`
    return {
      week: formattedDate,
      leads: Number(w.total_leads || 0),
      conversoes: Number(w.convertidos || 0)
    }
  })
  
  return {
    funnel,
    weeklyTrend
  }
})

// Max value for funnel chart
const funnelMax = computed(() => {
  if (!chartData.value.funnel || chartData.value.funnel.length === 0) return 1
  return Math.max(...chartData.value.funnel.map((f: any) => f.value), 1)
})

const selectWeek = (key: string) => {
  selectedWeek.value = key
  weekDropdownOpen.value = false
}

const fetchData = async () => {
  loading.value = true
  try {
    // Keep mock activity log
    const { mockActivityLog } = useMockData()
    activityLog.value = mockActivityLog
    
    // Fetch from Supabase view
    const { data: dbData, error } = await supabase.from('vw_relatorio_semanal').select('*')
    if (error) throw error
    
    if (dbData && dbData.length > 0) {
      const sorted = [...dbData].sort((a, b) => b.semana_inicio.localeCompare(a.semana_inicio))
      weeks.value = sorted.map((row, idx) => {
        let short = `${idx} Sem. Atrás`
        if (idx === 0) short = 'Esta Semana'
        else if (idx === 1) short = 'Sem. Passada'
        else if (idx === 2) short = '2 Sem. Atrás'
        else if (idx === 3) short = '3 Sem. Atrás'
        
        return {
          key: row.semana_inicio || '',
          label: formatWeekPeriod(row.semana_inicio || '', row.semana_fim || ''),
          short: short,
          ...row
        }
      })
      selectedWeek.value = weeks.value[0].key
    } else {
      // Default fallback current week
      const { semana_inicio, semana_fim } = getStartAndEndOfWeek()
      weeks.value = [{
        key: semana_inicio,
        label: formatWeekPeriod(semana_inicio, semana_fim),
        short: 'Esta Semana',
        semana_inicio,
        semana_fim,
        total_leads: 0,
        leads_novos_parados: 0,
        qualificados: 0,
        agendamentos: 0,
        convertidos: 0,
        taxa_conversao: 0,
        receita: 0
      }]
      selectedWeek.value = semana_inicio
    }

    // Fetch dynamic database activities
    try {
      const { data: leadsData } = await supabase
        .from('leads')
        .select('id, name, stage, expected_value, created_at')
        .order('created_at', { ascending: false })
        .limit(100)
        
      const { data: appointmentsData } = await supabase
        .from('appointments')
        .select('id, created_at, status, leads(name)')
        .order('created_at', { ascending: false })
        .limit(100)
        
      const leadActivities: any[] = []
      if (leadsData) {
        leadsData.forEach((lead: any) => {
          const weekStart = getWeekStartDate(lead.created_at)
          // 1. New Lead
          leadActivities.push({
            id: `lead-new-${lead.id}`,
            type: 'lead_new',
            text: `Novo lead recebido: ${lead.name}`,
            time: lead.created_at,
            week: weekStart
          })
          if (['negociacao', 'visita'].includes(lead.stage)) {
            leadActivities.push({
              id: `lead-qual-${lead.id}`,
              type: 'lead_qualified',
              text: `Lead qualificado e avançado no pipeline: ${lead.name}`,
              time: lead.created_at,
              week: weekStart
            })
          }
          // 3. Closed Lead
          if (lead.stage === 'fechado') {
            const valStr = lead.expected_value ? ` no valor de ${formatCurrency(Number(lead.expected_value))}` : ''
            leadActivities.push({
              id: `lead-closed-${lead.id}`,
              type: 'deal_closed',
              text: `Venda fechada com o cliente ${lead.name}${valStr}`,
              time: lead.created_at,
              week: weekStart
            })
          }
        })
      }
      
      const appointmentActivities: any[] = []
      if (appointmentsData) {
        appointmentsData.forEach((apt: any) => {
          const weekStart = getWeekStartDate(apt.created_at)
          const leadName = apt.leads ? (Array.isArray(apt.leads) ? apt.leads[0]?.name : apt.leads.name) || 'Cliente' : 'Cliente'
          appointmentActivities.push({
            id: `apt-${apt.id}`,
            type: 'meeting_scheduled',
            text: `Visita ou agendamento de reunião agendado com o lead: ${leadName}`,
            time: apt.created_at,
            week: weekStart
          })
        })
      }
      
      const allDbActivities = [...leadActivities, ...appointmentActivities]
      allDbActivities.sort((a, b) => b.time.localeCompare(a.time))
      dbActivities.value = allDbActivities
    } catch (dbErr) {
      console.error('Error fetching dbActivities details:', dbErr)
      dbActivities.value = []
    }
  } catch (e) {
    console.error('Error loading weekly report data:', e)
    // Gracious fallback to mock data on error so UI never crashes
    const { mockWeeklyMetrics } = useMockData()
    const fallbackWeeks = [
      { key: 'semana-1', semana_inicio: '2026-02-24', semana_fim: '2026-03-02', label: '24 Fev – 02 Mar', short: 'Esta Semana', total_leads: mockWeeklyMetrics['semana-1'].totalLeads, leads_novos_parados: mockWeeklyMetrics['semana-1'].novosContatos, qualificados: mockWeeklyMetrics['semana-1'].qualificados, agendamentos: mockWeeklyMetrics['semana-1'].agendamentos, convertidos: mockWeeklyMetrics['semana-1'].convertidos, taxa_conversao: mockWeeklyMetrics['semana-1'].taxaConversao, receita: mockWeeklyMetrics['semana-1'].receita },
      { key: 'semana-2', semana_inicio: '2026-02-17', semana_fim: '2026-02-23', label: '17 – 23 Fev', short: 'Sem. Passada', total_leads: mockWeeklyMetrics['semana-2'].totalLeads, leads_novos_parados: mockWeeklyMetrics['semana-2'].novosContatos, qualificados: mockWeeklyMetrics['semana-2'].qualificados, agendamentos: mockWeeklyMetrics['semana-2'].agendamentos, convertidos: mockWeeklyMetrics['semana-2'].convertidos, taxa_conversao: mockWeeklyMetrics['semana-2'].taxaConversao, receita: mockWeeklyMetrics['semana-2'].receita },
      { key: 'semana-3', semana_inicio: '2026-02-10', semana_fim: '2026-02-16', label: '10 – 16 Fev', short: '2 Sem. Atrás', total_leads: mockWeeklyMetrics['semana-3'].totalLeads, leads_novos_parados: mockWeeklyMetrics['semana-3'].novosContatos, qualificados: mockWeeklyMetrics['semana-3'].qualificados, agendamentos: mockWeeklyMetrics['semana-3'].agendamentos, convertidos: mockWeeklyMetrics['semana-3'].convertidos, taxa_conversao: mockWeeklyMetrics['semana-3'].taxaConversao, receita: mockWeeklyMetrics['semana-3'].receita },
      { key: 'semana-4', semana_inicio: '2026-02-03', semana_fim: '2026-02-09', label: '03 – 09 Fev', short: '3 Sem. Atrás', total_leads: mockWeeklyMetrics['semana-4'].totalLeads, leads_novos_parados: mockWeeklyMetrics['semana-4'].novosContatos, qualificados: mockWeeklyMetrics['semana-4'].qualificados, agendamentos: mockWeeklyMetrics['semana-4'].agendamentos, convertidos: mockWeeklyMetrics['semana-4'].convertidos, taxa_conversao: mockWeeklyMetrics['semana-4'].taxaConversao, receita: mockWeeklyMetrics['semana-4'].receita },
    ]
    weeks.value = fallbackWeeks
    selectedWeek.value = 'semana-1'
  } finally {
    loading.value = false
  }
}

// Reset activity page on week change
watch(selectedWeek, () => {
  activityPage.value = 1
  fetchHourlyActivity()
})

onMounted(() => { fetchData() })
</script>

<template>
  <div class="min-h-screen bg-gray-50 dark:bg-dark-bg text-gray-900 dark:text-white font-sans transition-colors duration-300">
    <Sidebar />

    <main :class="[mainMargin, 'px-4 py-5 sm:px-6 lg:p-8 transition-all duration-300']">
      <!-- Header -->
      <header class="mb-8 flex flex-col lg:flex-row lg:items-center lg:justify-between gap-4">
        <div class="flex items-start sm:items-center gap-3 sm:gap-4 min-w-0">
          <div class="p-2.5 bg-primary-50 dark:bg-primary-500/10 rounded-xl text-primary-500">
            <BarChart3 class="w-6 h-6" />
          </div>
          <div class="min-w-0">
            <h1 class="text-lg sm:text-xl font-bold tracking-tight leading-tight">Relatórios & Performance</h1>
            <p class="text-gray-400 dark:text-dark-muted text-xs sm:text-sm mt-1 leading-snug">Análise semanal do pipeline e automação IA</p>
          </div>
        </div>

        <div class="flex flex-col min-[420px]:flex-row gap-3 w-full lg:w-auto">
          <!-- Week Dropdown (scalable) -->
          <div class="relative flex-1 min-w-0 min-[420px]:flex-none">
            <button 
              @click="weekDropdownOpen = !weekDropdownOpen"
              class="flex items-center gap-2 px-4 py-2 bg-white dark:bg-dark-surface border border-gray-100 dark:border-dark-border rounded-xl text-sm font-medium text-gray-700 dark:text-gray-300 hover:bg-gray-50 dark:hover:bg-dark-card transition-all shadow-sm w-full min-[420px]:min-w-[200px] justify-between"
            >
              <Calendar class="w-4 h-4 text-primary-500" />
              <span>{{ currentWeekShort }}</span>
              <ChevronDown class="w-3.5 h-3.5 text-gray-400 transition-transform" :class="{ 'rotate-180': weekDropdownOpen }" />
            </button>
            
            <Transition name="dropdown">
              <div v-if="weekDropdownOpen" class="absolute inset-x-0 min-[420px]:left-auto min-[420px]:w-64 top-full mt-1.5 bg-white dark:bg-dark-surface border border-gray-100 dark:border-dark-border rounded-xl shadow-lg z-20 py-1 max-h-[300px] overflow-y-auto">
                <button
                  v-for="w in weeks"
                  :key="w.key"
                  @click="selectWeek(w.key)"
                  :class="[
                    'w-full flex items-center justify-between px-4 py-2.5 text-left hover:bg-gray-50 dark:hover:bg-dark-card transition-colors',
                    selectedWeek === w.key ? 'bg-primary-50 dark:bg-primary-500/10 text-primary-600 dark:text-primary-400 font-semibold' : 'text-gray-700 dark:text-gray-300'
                  ]"
                >
                  <div>
                    <span class="text-sm block">{{ w.short }}</span>
                    <span class="text-[11px] text-gray-400 dark:text-dark-muted">{{ w.label }}</span>
                  </div>
                  <CheckCircle2 v-if="selectedWeek === w.key" class="w-4 h-4 text-primary-500" />
                </button>
              </div>
            </Transition>
          </div>

          <button class="flex flex-shrink-0 items-center justify-center gap-2 px-3 sm:px-4 py-2 bg-primary-500 text-white rounded-xl shadow-sm text-xs font-semibold hover:bg-primary-600 transition-all">
            <Download class="w-3.5 h-3.5" />
            Exportar
          </button>
        </div>
      </header>

      <!-- Loading -->
      <div v-if="loading" class="flex items-center justify-center h-64">
        <div class="animate-spin rounded-full h-8 w-8 border-b-2 border-primary-500"></div>
      </div>

      <template v-else>
        <!-- Week Title Banner -->
        <div class="mb-6 flex flex-col sm:flex-row sm:items-center gap-2 sm:gap-3 min-w-0">
          <div class="w-full sm:w-auto min-w-0 flex items-start sm:items-center gap-2 bg-white dark:bg-dark-surface border border-gray-100 dark:border-dark-border rounded-xl px-4 sm:px-5 py-3">
            <Calendar class="w-5 h-5 text-primary-500" />
            <span class="min-w-0 text-base sm:text-lg font-bold leading-snug text-gray-900 dark:text-white break-words">{{ currentReport.title || currentWeekLabel }}</span>
          </div>
          <span class="text-xs text-gray-400 dark:text-dark-muted">{{ currentMetrics.totalLeads || 0 }} leads nesta semana</span>
        </div>

        <!-- Metric Cards Grid -->
        <div class="grid grid-cols-1 min-[380px]:grid-cols-2 md:grid-cols-3 gap-3 sm:gap-4 mb-6">
          <div
            v-for="card in metricCards"
            :key="card.title"
            class="bg-white dark:bg-dark-surface border border-gray-100 dark:border-dark-border rounded-xl p-4 hover:shadow-card-hover transition-all group"
          >
            <div class="flex items-center justify-between mb-3">
              <div :class="['p-2 rounded-lg border', card.bg, card.border]">
                <component :is="card.icon" :class="['w-4 h-4', card.color]" />
              </div>
            </div>
            <p class="text-[11px] font-semibold text-gray-400 dark:text-dark-muted uppercase tracking-wider mb-1">{{ card.title }}</p>
            <p class="text-2xl font-bold text-gray-900 dark:text-white">{{ card.value }}</p>
          </div>
        </div>

        <!-- Message activity by hour -->
        <section class="bg-white dark:bg-dark-surface border border-gray-100 dark:border-dark-border rounded-xl p-5 sm:p-6 mb-6">
          <div class="flex flex-col sm:flex-row sm:items-start sm:justify-between gap-3 mb-5">
            <div>
              <h2 class="text-sm font-bold text-gray-900 dark:text-white flex items-center gap-2">
                <MessageSquare class="w-4 h-4 text-primary-500" /> Horários com mais mensagens
              </h2>
              <p class="text-[11px] text-gray-400 dark:text-dark-muted mt-1">Horário da última mensagem de cada lead na semana selecionada, no horário de Brasília.</p>
            </div>
            <div class="sm:text-right">
              <p class="text-2xl font-bold tabular-nums text-gray-900 dark:text-white">{{ totalMessages }}</p>
              <p class="text-[10px] font-semibold uppercase tracking-wider text-gray-400">leads com mensagem</p>
            </div>
          </div>

          <div v-if="hourlyLoading" class="h-44 flex items-center justify-center">
            <div class="animate-spin rounded-full h-7 w-7 border-b-2 border-primary-500"></div>
          </div>

          <div v-else-if="totalMessages > 0" class="grid grid-cols-1 xl:grid-cols-[minmax(0,1fr)_280px] gap-6">
            <div class="h-48 overflow-x-auto" aria-label="Gráfico de mensagens por horário">
              <div class="h-full min-w-[680px] flex items-end gap-1.5 border-b border-gray-200 dark:border-dark-border px-1">
                <div
                  v-for="item in hourlyActivity"
                  :key="item.hour"
                  class="group relative flex-1 h-full flex flex-col justify-end items-center"
                  :title="`${formatHour(item.hour)}: ${item.count} lead${item.count === 1 ? '' : 's'}`"
                >
                  <span class="mb-1 text-[9px] font-bold tabular-nums text-gray-500 opacity-0 group-hover:opacity-100 transition-opacity">{{ item.count }}</span>
                  <div
                    class="w-full max-w-5 rounded-t bg-primary-500/80 hover:bg-primary-500 transition-[height,background-color] duration-300"
                    :style="{ height: `${maxHourlyMessages ? Math.max((item.count / maxHourlyMessages) * 82, item.count ? 6 : 2) : 2}%` }"
                  ></div>
                  <span class="h-5 mt-1 text-[9px] tabular-nums text-gray-400">{{ item.hour % 2 === 0 ? String(item.hour).padStart(2, '0') + 'h' : '' }}</span>
                </div>
              </div>
            </div>

            <div class="space-y-2.5">
              <p class="text-[10px] font-bold uppercase tracking-wider text-gray-400">Picos de atendimento</p>
              <div
                v-for="(item, index) in busiestHours"
                :key="item.hour"
                class="flex items-center gap-3 rounded-xl border border-primary-100 bg-primary-50/60 p-3 dark:border-primary-500/20 dark:bg-primary-500/5"
              >
                <span class="flex h-8 w-8 shrink-0 items-center justify-center rounded-lg bg-primary-500 text-xs font-bold text-white">{{ Number(index) + 1 }}</span>
                <div>
                  <p class="text-sm font-bold text-gray-900 dark:text-white">{{ formatHour(item.hour) }}</p>
                  <p class="text-xs text-gray-500 dark:text-dark-muted">{{ item.count }} lead{{ item.count === 1 ? '' : 's' }}</p>
                </div>
              </div>
            </div>
          </div>

          <div v-else class="h-36 flex flex-col items-center justify-center text-center rounded-xl bg-gray-50/70 dark:bg-dark-bg/50">
            <Clock class="w-8 h-8 text-gray-300 dark:text-gray-600 mb-2" />
            <p class="text-sm font-semibold text-gray-600 dark:text-gray-300">Nenhuma mensagem encontrada nesta semana</p>
          </div>
        </section>

        <!-- Two Column Layout: Report + Charts -->
        <div class="grid grid-cols-1 xl:grid-cols-5 gap-6 mb-6">
          <!-- Weekly Report (3 cols) -->
          <div class="xl:col-span-3 bg-white dark:bg-dark-surface border border-gray-100 dark:border-dark-border rounded-xl overflow-hidden">
            <!-- Report Header -->
            <div class="px-4 sm:px-6 py-4 border-b border-gray-100 dark:border-dark-border flex flex-col sm:flex-row gap-3 sm:items-center sm:justify-between">
              <div class="flex items-center gap-2.5">
                <div class="p-1.5 bg-primary-50 dark:bg-primary-500/10 rounded-lg">
                  <BarChart3 class="w-4 h-4 text-primary-500" />
                </div>
                <div>
                  <h2 class="text-sm font-bold text-gray-900 dark:text-white">Relatório Semanal</h2>
                  <p class="text-[11px] text-gray-400 dark:text-dark-muted">{{ currentReport.title }}</p>
                </div>
              </div>
              <NuxtLink 
                :to="'/relatorio-semanal?week=' + selectedWeek"
                class="flex items-center gap-1.5 text-[11px] font-semibold text-primary-500 hover:text-primary-600 transition-colors"
              >
                Ver completo <ExternalLink class="w-3 h-3" />
              </NuxtLink>
            </div>

            <!-- Report Body -->
            <div class="p-6 space-y-5 max-h-[520px] overflow-y-auto">
              <!-- Resumo -->
              <div>
                <p class="text-sm text-gray-600 dark:text-gray-300 leading-relaxed">{{ currentReport.resumo }}</p>
              </div>

              <!-- Destaques -->
              <div v-if="currentReport.destaques?.length">
                <h3 class="text-[11px] font-semibold text-gray-400 dark:text-dark-muted uppercase tracking-wider mb-2.5 flex items-center gap-1.5">
                  <Star class="w-3 h-3" /> Destaques
                </h3>
                <div class="space-y-2">
                  <div v-for="(d, i) in currentReport.destaques" :key="i" class="flex items-start gap-2 text-sm text-gray-700 dark:text-gray-300 bg-gray-50 dark:bg-dark-card/50 p-3 rounded-lg">
                    {{ d }}
                  </div>
                </div>
              </div>

              <!-- Conselhos para o Vendedor -->
              <div v-if="currentReport.conselhos?.length">
                <h3 class="text-[11px] font-semibold text-primary-500 uppercase tracking-wider mb-2.5 flex items-center gap-1.5">
                  <Lightbulb class="w-3 h-3" /> Conselhos para o Vendedor
                </h3>
                <div class="space-y-2">
                  <div v-for="(c, i) in currentReport.conselhos" :key="i" class="flex items-start gap-3 text-sm text-gray-700 dark:text-gray-300 bg-primary-50/50 dark:bg-primary-500/5 p-3 rounded-lg border border-primary-100/50 dark:border-primary-500/10">
                    <span class="text-primary-500 font-bold text-xs mt-0.5">{{ Number(i) + 1 }}</span>
                    {{ c }}
                  </div>
                </div>
              </div>

              <!-- Alertas -->
              <div v-if="currentReport.alertas?.length">
                <h3 class="text-[11px] font-semibold text-amber-500 uppercase tracking-wider mb-2.5 flex items-center gap-1.5">
                  <AlertTriangle class="w-3 h-3" /> Alertas
                </h3>
                <div class="space-y-2">
                  <div v-for="(a, i) in currentReport.alertas" :key="i" class="text-sm text-amber-700 dark:text-amber-300 bg-amber-50/50 dark:bg-amber-500/5 p-3 rounded-lg border border-amber-100/50 dark:border-amber-500/10">
                    {{ a }}
                  </div>
                </div>
              </div>
            </div>
          </div>

          <!-- Charts (2 cols) -->
          <div class="xl:col-span-2 space-y-6">
            <!-- Funnel Chart -->
            <div class="bg-white dark:bg-dark-surface border border-gray-100 dark:border-dark-border rounded-xl p-5">
              <h3 class="text-sm font-bold text-gray-900 dark:text-white mb-4 flex items-center gap-2">
                <TrendingUp class="w-4 h-4 text-primary-500" /> Funil de Leads
              </h3>
              <div class="space-y-3">
                <div v-for="item in chartData.funnel" :key="item.label" class="flex items-center gap-3">
                  <span class="text-[11px] font-medium text-gray-500 dark:text-dark-muted w-20 text-right">{{ item.label }}</span>
                  <div class="flex-1 bg-gray-100 dark:bg-dark-card rounded-full h-6 overflow-hidden">
                    <div 
                      class="h-full rounded-full flex items-center justify-end pr-2 transition-all duration-700"
                      :style="{ width: (item.value / funnelMax * 100) + '%', backgroundColor: item.color }"
                    >
                      <span class="text-[10px] font-bold text-white">{{ item.value }}</span>
                    </div>
                  </div>
                </div>
              </div>
            </div>

            <!-- Weekly Overview (simplified) -->
            <div class="bg-white dark:bg-dark-surface border border-gray-100 dark:border-dark-border rounded-xl p-5">
              <h3 class="text-sm font-bold text-gray-900 dark:text-white mb-4 flex items-center gap-2">
                <BarChart3 class="w-4 h-4 text-primary-500" /> Resumo por Semana
              </h3>
              <div class="space-y-3">
                <div v-for="item in chartData.weeklyTrend" :key="item.week" class="flex items-center gap-3">
                  <span class="text-[11px] font-medium text-gray-500 dark:text-dark-muted w-12">{{ item.week }}</span>
                  <div class="flex-1 flex items-center gap-2">
                    <div class="flex-1 bg-gray-100 dark:bg-dark-card rounded-full h-3 overflow-hidden">
                      <div class="h-full bg-primary-400 dark:bg-primary-500 rounded-full transition-all duration-500" :style="{ width: Math.max(10, Number(item.leads) * 10) + '%' }"></div>
                    </div>
                    <span class="text-[10px] font-semibold text-gray-500 w-5 text-right">{{ item.leads }}</span>
                  </div>
                  <div class="flex items-center gap-1 w-12">
                    <div class="w-2 h-2 rounded-full bg-emerald-400"></div>
                    <span class="text-[10px] font-semibold text-emerald-500">{{ item.conversoes }}</span>
                  </div>
                </div>
              </div>
              <div class="flex items-center gap-4 mt-3 pt-3 border-t border-gray-100 dark:border-dark-border">
                <div class="flex items-center gap-1.5">
                  <div class="w-2.5 h-2.5 rounded-sm bg-primary-400"></div>
                  <span class="text-[10px] text-gray-400 dark:text-dark-muted font-medium">Leads</span>
                </div>
                <div class="flex items-center gap-1.5">
                  <div class="w-2.5 h-2.5 rounded-full bg-emerald-400"></div>
                  <span class="text-[10px] text-gray-400 dark:text-dark-muted font-medium">Conversões</span>
                </div>
              </div>
            </div>
          </div>
        </div>

        <!-- Activity Log -->
        <div class="bg-white dark:bg-dark-surface border border-gray-100 dark:border-dark-border rounded-xl overflow-hidden">
          <div class="px-6 py-4 border-b border-gray-100 dark:border-dark-border flex items-center justify-between">
            <div class="flex items-center gap-2.5">
              <div class="p-1.5 bg-gray-100 dark:bg-dark-card rounded-lg">
                <Clock class="w-4 h-4 text-gray-500 dark:text-dark-muted" />
              </div>
              <h2 class="text-sm font-bold text-gray-900 dark:text-white">Registro de Atividade</h2>
            </div>
            <span class="text-[11px] text-gray-400 dark:text-dark-muted font-medium px-2.5 py-1 rounded-lg bg-gray-50 dark:bg-dark-card border border-gray-100 dark:border-dark-border">
              {{ filteredActivities.length }} registros
            </span>
          </div>

          <div v-if="filteredActivities.length === 0" class="p-10 text-center text-gray-400 dark:text-dark-muted text-sm">
            Nenhuma atividade registrada nesta semana.
          </div>

          <div v-else class="divide-y divide-gray-50 dark:divide-dark-border">
            <div v-for="item in paginatedActivities" :key="item.id" class="px-6 py-3.5 hover:bg-gray-50/50 dark:hover:bg-white/[0.02] transition-colors flex items-center gap-4">
              <div :class="['p-2 rounded-lg', getActivityColor(item.type)]">
                <component :is="getActivityIcon(item.type)" class="w-4 h-4" />
              </div>
              <div class="flex-1 min-w-0">
                <p class="text-sm text-gray-700 dark:text-gray-300 leading-relaxed">{{ item.text }}</p>
                <div class="flex items-center gap-2 mt-1">
                  <span class="text-[10px] text-gray-400 dark:text-dark-muted">{{ timeAgo(item.time) }}</span>
                  <span :class="['text-[9px] font-semibold px-1.5 py-0.5 rounded-md', getActivityColor(item.type)]">
                    {{ getActivityLabel(item.type) }}
                  </span>
                </div>
              </div>
            </div>
          </div>

          <!-- Pagination -->
          <div v-if="totalActivityPages > 1" class="px-6 py-3 border-t border-gray-100 dark:border-dark-border flex items-center justify-between">
            <p class="text-[11px] text-gray-400 dark:text-dark-muted">
              Página {{ activityPage }} de {{ totalActivityPages }}
            </p>
            <div class="flex gap-1.5">
              <button 
                @click="activityPage = Math.max(1, activityPage - 1)" 
                :disabled="activityPage <= 1" 
                :class="['p-1.5 rounded-lg text-xs transition-all border', activityPage <= 1 ? 'text-gray-300 dark:text-gray-600 border-transparent cursor-not-allowed' : 'text-gray-500 hover:bg-gray-50 dark:hover:bg-dark-card border-gray-100 dark:border-dark-border']"
              >
                <ChevronLeft class="w-3.5 h-3.5" />
              </button>
              <button 
                @click="activityPage = Math.min(totalActivityPages, activityPage + 1)" 
                :disabled="activityPage >= totalActivityPages" 
                :class="['p-1.5 rounded-lg text-xs transition-all border', activityPage >= totalActivityPages ? 'text-gray-300 dark:text-gray-600 border-transparent cursor-not-allowed' : 'text-gray-500 hover:bg-gray-50 dark:hover:bg-dark-card border-gray-100 dark:border-dark-border']"
              >
                <ChevronRight class="w-3.5 h-3.5" />
              </button>
            </div>
          </div>
        </div>
      </template>
    </main>
  </div>
</template>

<style scoped>
.dropdown-enter-active, .dropdown-leave-active {
  transition: all 0.15s ease;
}
.dropdown-enter-from, .dropdown-leave-to {
  opacity: 0;
  transform: translateY(-4px);
}
</style>
