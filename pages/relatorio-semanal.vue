<script setup lang="ts">
import { ref, computed, onMounted } from 'vue'
import { 
  ArrowLeft, BarChart3, Star, Lightbulb, AlertTriangle, 
  Users, Target, Calendar, Clock, MessageSquare
} from 'lucide-vue-next'

const route = useRoute()
const router = useRouter()
const { mainMargin } = useSidebarState()

import { useSupabaseClient } from '#imports'

const supabase = useSupabaseClient<any>()

// State
const loading = ref(true)
const weekKey = ref((route.query.week as string) || '')
const currentMetrics = ref<any>({})
const currentReport = ref<any>({})
const hourlyActivity = ref<{ hour: number; count: number }[]>(
  Array.from({ length: 24 }, (_, hour) => ({ hour, count: 0 }))
)

const metricCards = computed(() => [
  { title: 'Total Leads', value: currentMetrics.value.totalLeads || 0, icon: Users, color: 'text-blue-600 dark:text-blue-400', bg: 'bg-blue-50 dark:bg-blue-500/10' },
  { title: 'Qualificados', value: currentMetrics.value.qualificados || 0, icon: Target, color: 'text-emerald-600 dark:text-emerald-400', bg: 'bg-emerald-50 dark:bg-emerald-500/10' },
  { title: 'Agendamentos', value: currentMetrics.value.agendamentos || 0, icon: Calendar, color: 'text-primary-600 dark:text-primary-400', bg: 'bg-primary-50 dark:bg-primary-500/10' },
  { title: 'Tempo Resposta', value: currentMetrics.value.tempoMedioResposta || '-', icon: Clock, color: 'text-sky-600 dark:text-sky-400', bg: 'bg-sky-50 dark:bg-sky-500/10' },
  { title: 'Novos Contatos', value: currentMetrics.value.novosContatos || 0, icon: Users, color: 'text-cyan-600 dark:text-cyan-400', bg: 'bg-cyan-50 dark:bg-cyan-500/10' },
])

const maxHourlyMessages = computed(() => Math.max(...hourlyActivity.value.map(item => item.count), 0))
const totalMessages = computed(() => hourlyActivity.value.reduce((total, item) => total + item.count, 0))
const busiestHours = computed(() => hourlyActivity.value
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
  const start = new Date(`${weekKey.value}T00:00:00-03:00`)
  if (Number.isNaN(start.getTime())) return
  const end = new Date(start.getTime() + 7 * 24 * 60 * 60 * 1000)

  const { data: history, error: historyError } = await supabase
    .from('leads')
    .select('ultima_mensagem_at')
    .not('ultima_mensagem_at', 'is', null)
    .gte('ultima_mensagem_at', start.toISOString())
    .lt('ultima_mensagem_at', end.toISOString())
  if (historyError) {
    console.warn('Não foi possível carregar os horários das mensagens:', historyError)
    return
  }
  hourlyActivity.value = aggregateHistoryByHour(
    (history || []).map((item: any) => ({ sent_at: item.ultima_mensagem_at })),
    start,
    end
  )
}

function formatCurrency(val: number) {
  if (val >= 1000) return 'R$ ' + (val / 1000).toFixed(val % 1000 === 0 ? 0 : 1) + 'k'
  return 'R$ ' + val
}

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

const fetchData = async () => {
  loading.value = true
  try {
    const mockKeys = ['semana-1', 'semana-2', 'semana-3', 'semana-4']
    
    // Default to the latest week if query is not present
    if (!weekKey.value) {
      const { data: dbData } = await supabase.from('vw_relatorio_semanal').select('*')
      if (dbData && dbData.length > 0) {
        const sorted = [...dbData].sort((a, b) => b.semana_inicio.localeCompare(a.semana_inicio))
        weekKey.value = sorted[0].semana_inicio || ''
      } else {
        const now = new Date()
        const monday = getMonday(now)
        weekKey.value = localYyyymmdd(monday)
      }
    }

    if (mockKeys.includes(weekKey.value)) {
      const { mockWeeklyMetrics, mockWeeklyReports } = useMockData()
      const metric = mockWeeklyMetrics[weekKey.value] || {}
      const report = mockWeeklyReports[weekKey.value] || {}
      currentMetrics.value = {
        totalLeads: metric.totalLeads,
        qualificados: metric.qualificados,
        agendamentos: metric.agendamentos,
        convertidos: metric.convertidos,
        taxaConversao: metric.taxaConversao,
        receita: metric.receita,
        tempoMedioResposta: metric.tempoMedioResposta,
        novosContatos: metric.novosContatos
      }
      currentReport.value = report
    } else {
      // Query from database view
      const { data: dbData, error } = await supabase
        .from('vw_relatorio_semanal')
        .select('*')
        .eq('semana_inicio', weekKey.value)
      
      if (error) throw error
      
      if (dbData && dbData.length > 0) {
        const row = dbData[0]
        currentMetrics.value = {
          totalLeads: Number(row.total_leads || 0),
          qualificados: Number(row.qualificados || 0),
          agendamentos: Number(row.agendamentos || 0),
          convertidos: Number(row.convertidos || 0),
          taxaConversao: Number(row.taxa_conversao || 0),
          receita: Number(row.receita || 0),
          tempoMedioResposta: '5min', // reasonable default
          novosContatos: Number(row.leads_novos_parados !== undefined ? row.leads_novos_parados : (row.total_leads || 0))
        }
        
        const totalLeads = Number(row.total_leads || 0)
        const qualificados = Number(row.qualificados || 0)
        const agendamentos = Number(row.agendamentos || 0)
        const convertidos = Number(row.convertidos || 0)
        const receita = Number(row.receita || 0)

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

        currentReport.value = {
          title: `Semana ${formatWeekPeriod(row.semana_inicio, row.semana_fim)}`,
          resumo,
          destaques,
          conselhos,
          alertas
        }
      } else {
        // Fallback for valid date parameter with no database records yet
        let startStr = weekKey.value
        let endStr = weekKey.value
        try {
          const startDate = new Date(weekKey.value + 'T12:00:00')
          const endDate = new Date(startDate)
          endDate.setDate(startDate.getDate() + 6)
          endStr = localYyyymmdd(endDate)
        } catch (e) {}
        
        currentMetrics.value = {
          totalLeads: 0,
          qualificados: 0,
          agendamentos: 0,
          convertidos: 0,
          taxaConversao: 0,
          receita: 0,
          tempoMedioResposta: '-',
          novosContatos: 0
        }
        
        currentReport.value = {
          title: `Semana ${formatWeekPeriod(startStr, endStr)}`,
          resumo: 'Nenhum lead registrado no pipeline durante esta semana.',
          destaques: ['📭 Aguardando novas oportunidades de captação de leads.'],
          conselhos: [
            'Revise o funcionamento das campanhas de tráfego pago e as integrações de WhatsApp/Site.'
          ],
          alertas: ['🚨 Sem fluxo de leads nesta semana. Verifique o status das suas integrações.']
        }
      }
    }

    await fetchHourlyActivity()
  } catch (e) {
    console.error('Error fetching weekly details:', e)
    // Absolute fallback to mock data on error so UI never crashes
    const { mockWeeklyMetrics, mockWeeklyReports } = useMockData()
    const fallbackKey = 'semana-1'
    const metric = mockWeeklyMetrics[fallbackKey] || {}
    const report = mockWeeklyReports[fallbackKey] || {}
    currentMetrics.value = {
      totalLeads: metric.totalLeads,
      qualificados: metric.qualificados,
      agendamentos: metric.agendamentos,
      convertidos: metric.convertidos,
      taxaConversao: metric.taxaConversao,
      receita: metric.receita,
      tempoMedioResposta: metric.tempoMedioResposta,
      novosContatos: metric.novosContatos
    }
    currentReport.value = report
  } finally {
    loading.value = false
  }
}

onMounted(() => fetchData())
</script>

<template>
  <div class="min-h-screen bg-gray-50 dark:bg-dark-bg text-gray-900 dark:text-white font-sans transition-colors duration-300">
    <Sidebar />
    <main :class="[mainMargin, 'px-4 py-5 sm:px-6 lg:p-8 transition-all duration-300 max-w-5xl']">
      
      <!-- Back + Title -->
      <header class="mb-8">
        <button @click="router.push('/relatorios')" class="flex items-center gap-2 text-sm text-gray-500 hover:text-primary-500 transition-colors mb-4">
          <ArrowLeft class="w-4 h-4" /> Voltar para Relatórios
        </button>
        <div class="flex items-center gap-4">
          <div class="p-2.5 bg-primary-50 dark:bg-primary-500/10 rounded-xl text-primary-500">
            <BarChart3 class="w-6 h-6" />
          </div>
          <div>
            <h1 class="text-2xl font-bold tracking-tight">Relatório Semanal</h1>
            <p class="text-base text-gray-500 dark:text-dark-muted mt-0.5">{{ currentReport.title || weekKey }}</p>
          </div>
        </div>
      </header>

      <div v-if="loading" class="flex items-center justify-center h-40">
        <div class="animate-spin rounded-full h-8 w-8 border-b-2 border-primary-500"></div>
      </div>

      <template v-else>
        <!-- Metrics Grid -->
        <div class="grid grid-cols-2 lg:grid-cols-5 gap-3 sm:gap-4 mb-8">
          <div v-for="card in metricCards" :key="card.title" class="bg-white dark:bg-dark-surface border border-gray-100 dark:border-dark-border rounded-xl p-4">
            <div class="flex items-center gap-2 mb-2">
              <div :class="['p-1.5 rounded-lg', card.bg]">
                <component :is="card.icon" :class="['w-3.5 h-3.5', card.color]" />
              </div>
              <span class="text-[11px] font-semibold text-gray-400 dark:text-dark-muted uppercase tracking-wider">{{ card.title }}</span>
            </div>
            <p class="text-xl font-bold text-gray-900 dark:text-white">{{ card.value }}</p>
          </div>
        </div>

        <!-- Horários com maior volume de mensagens -->
        <section class="bg-white dark:bg-dark-surface border border-gray-100 dark:border-dark-border rounded-xl p-5 sm:p-6 mb-6">
          <div class="flex flex-col sm:flex-row sm:items-start sm:justify-between gap-3 mb-6">
            <div>
              <h2 class="text-base font-bold text-gray-900 dark:text-white flex items-center gap-2">
                <MessageSquare class="w-5 h-5 text-primary-500" /> Horários com mais mensagens
              </h2>
              <p class="text-xs text-gray-500 dark:text-dark-muted mt-1">
                Horário da última mensagem de cada lead durante a semana selecionada.
              </p>
            </div>
            <div class="sm:text-right">
              <p class="text-2xl font-bold tabular-nums text-gray-900 dark:text-white">{{ totalMessages }}</p>
              <p class="text-[10px] font-semibold uppercase tracking-wider text-gray-400">leads com mensagem</p>
            </div>
          </div>

          <div v-if="totalMessages > 0" class="space-y-5">
            <div class="h-48 overflow-x-auto" aria-label="Gráfico de mensagens por hora">
              <div class="h-full min-w-[680px] flex items-end gap-1.5 border-b border-gray-200 dark:border-dark-border px-1">
                <div
                  v-for="item in hourlyActivity"
                  :key="item.hour"
                  class="group relative flex-1 h-full flex flex-col justify-end items-center"
                  :title="`${formatHour(item.hour)}: ${item.count} lead${item.count === 1 ? '' : 's'}`"
                >
                  <span class="mb-1 text-[9px] font-bold tabular-nums text-gray-500 opacity-0 group-hover:opacity-100 transition-opacity">
                    {{ item.count }}
                  </span>
                  <div
                    class="w-full max-w-5 rounded-t bg-primary-500/80 hover:bg-primary-500 transition-[height,background-color] duration-300"
                    :style="{ height: `${maxHourlyMessages ? Math.max((item.count / maxHourlyMessages) * 82, item.count ? 6 : 2) : 2}%` }"
                  ></div>
                  <span class="h-5 mt-1 text-[9px] tabular-nums text-gray-400">
                    {{ item.hour % 2 === 0 ? String(item.hour).padStart(2, '0') + 'h' : '' }}
                  </span>
                </div>
              </div>
            </div>

            <div class="grid grid-cols-1 sm:grid-cols-3 gap-3">
              <div
                v-for="(item, index) in busiestHours"
                :key="item.hour"
                class="flex items-center gap-3 rounded-xl border border-primary-100 bg-primary-50/60 p-3 dark:border-primary-500/20 dark:bg-primary-500/5"
              >
                <span class="flex h-8 w-8 shrink-0 items-center justify-center rounded-lg bg-primary-500 text-xs font-bold text-white">
                  {{ Number(index) + 1 }}
                </span>
                <div>
                  <p class="text-sm font-bold text-gray-900 dark:text-white">{{ formatHour(item.hour) }}</p>
                  <p class="text-xs text-gray-500 dark:text-dark-muted">{{ item.count }} lead{{ item.count === 1 ? '' : 's' }}</p>
                </div>
              </div>
            </div>
          </div>

          <div v-else class="min-h-32 flex flex-col items-center justify-center text-center rounded-xl bg-gray-50/70 dark:bg-dark-bg/50">
            <Clock class="w-8 h-8 text-gray-300 dark:text-gray-600 mb-2" />
            <p class="text-sm font-semibold text-gray-600 dark:text-gray-300">Nenhuma mensagem encontrada nesta semana</p>
            <p class="text-xs text-gray-400 mt-1">O gráfico será preenchido quando houver conversas no período.</p>
          </div>
        </section>

        <!-- Resumo Executivo -->
        <section class="bg-white dark:bg-dark-surface border border-gray-100 dark:border-dark-border rounded-xl p-6 mb-6">
          <h2 class="text-lg font-bold text-gray-900 dark:text-white mb-3">Resumo Executivo</h2>
          <p class="text-sm text-gray-600 dark:text-gray-300 leading-relaxed">{{ currentReport.resumo }}</p>
        </section>

        <!-- Destaques -->
        <section v-if="currentReport.destaques?.length" class="bg-white dark:bg-dark-surface border border-gray-100 dark:border-dark-border rounded-xl p-6 mb-6">
          <h2 class="text-base font-bold text-gray-900 dark:text-white mb-4 flex items-center gap-2">
            <Star class="w-5 h-5 text-amber-500" /> Destaques da Semana
          </h2>
          <div class="space-y-3">
            <div v-for="(d, i) in currentReport.destaques" :key="i" class="bg-gray-50 dark:bg-dark-card/50 p-4 rounded-xl text-sm text-gray-700 dark:text-gray-300">
              {{ d }}
            </div>
          </div>
        </section>

        <!-- Conselhos -->
        <section v-if="currentReport.conselhos?.length" class="bg-white dark:bg-dark-surface border border-gray-100 dark:border-dark-border rounded-xl p-6 mb-6">
          <h2 class="text-base font-bold text-primary-600 dark:text-primary-400 mb-4 flex items-center gap-2">
            <Lightbulb class="w-5 h-5" /> Conselhos para o Vendedor
          </h2>
          <div class="space-y-3">
            <div v-for="(c, i) in currentReport.conselhos" :key="i" class="flex items-start gap-4 bg-primary-50/50 dark:bg-primary-500/5 p-4 rounded-xl border border-primary-100/50 dark:border-primary-500/10">
              <span class="w-8 h-8 rounded-lg bg-primary-500 text-white flex items-center justify-center font-bold text-sm flex-shrink-0">{{ Number(i) + 1 }}</span>
              <p class="text-sm text-gray-700 dark:text-gray-300 leading-relaxed pt-1">{{ c }}</p>
            </div>
          </div>
        </section>

        <!-- Alertas -->
        <section v-if="currentReport.alertas?.length" class="bg-white dark:bg-dark-surface border border-gray-100 dark:border-dark-border rounded-xl p-6 mb-6">
          <h2 class="text-base font-bold text-amber-500 mb-4 flex items-center gap-2">
            <AlertTriangle class="w-5 h-5" /> Alertas e Atenção
          </h2>
          <div class="space-y-3">
            <div v-for="(a, i) in currentReport.alertas" :key="i" class="bg-amber-50/50 dark:bg-amber-500/5 p-4 rounded-xl border border-amber-100/50 dark:border-amber-500/10 text-sm text-amber-700 dark:text-amber-300">
              {{ a }}
            </div>
          </div>
        </section>

        <!-- Base info -->
        <div class="text-center text-[11px] text-gray-400 dark:text-dark-muted py-4">
          Relatório gerado com base em {{ currentMetrics.totalLeads || 0 }} leads · JRV Imóveis
        </div>
      </template>
    </main>
  </div>
</template>
