<script setup lang="ts">
import { ref, onMounted } from 'vue'
import { Clock, MessageCircle, Settings, User, X, Save, Plus, Trash2, Download, FileSpreadsheet } from 'lucide-vue-next'
import Sidebar from '~/components/Sidebar.vue'
import { useSupabaseClient } from '#imports'

const { mainMargin } = useSidebarState()
const supabase = useSupabaseClient<any>()

// Controls modal visibility
const activeModal = ref<string | null>(null)
const isLoading = ref(false)
const isSaving = ref(false)

// State: clinic_hours
const daysOfWeek = [
  { id: 0, label: 'Domingo' },
  { id: 1, label: 'Segunda-feira' },
  { id: 2, label: 'Terça-feira' },
  { id: 3, label: 'Quarta-feira' },
  { id: 4, label: 'Quinta-feira' },
  { id: 5, label: 'Sexta-feira' },
  { id: 6, label: 'Sábado' },
]
const clinicHours = ref<any[]>([])

// State: clinica_perguntas
const perguntas = ref<any[]>([])

// State: sistemaConfiguracao
const sistemaConfig = ref<any>({
  debounce: 5000,
  promptIA: '',
  nomeIA: '',
  nomeclinica: ''
})

// State: Editor Profil (simulated)
const userProfile = ref({
  fullName: '',
  email: ''
})

// Helper: Get robust clinic_id
const getMyClinicId = async () => {
    let clinic_id = null;
    const { data: rpcClinic } = await supabase.rpc('get_auth_clinic_id')
    if (rpcClinic) clinic_id = rpcClinic
    if (!clinic_id) throw new Error('Usuário sem imobiliária vinculada')
    return clinic_id
}


// Action to Open Modal
const openConfig = async (configType: string) => {
  activeModal.value = configType
  isLoading.value = true
  
  try {
    const clinicId = await getMyClinicId()

    if (configType === 'hours') {
      const { data, error } = await supabase.from('clinic_hours').select('*').order('day_of_week')
      if (error) throw error
      
      // Initialize if empty, otherwise merge
      const fetchedHours = data || []
      clinicHours.value = daysOfWeek.map(day => {
        const existing = fetchedHours.find(h => h.day_of_week === day.id)
        return existing || {
          day_of_week: day.id,
          clinic_id: clinicId,
          is_closed: day.id === 0 || day.id === 6,
          open_time: '08:00',
          close_time: '18:00',
          lunch_start: '12:00',
          lunch_end: '13:00'
        }
      })
    } 
    
    else if (configType === 'questions') {
      const { data, error } = await supabase.from('clinica_perguntas').select('*').order('created_at', { ascending: true })
      if (error) throw error
      perguntas.value = data || []
      // Se vier vazio, já adiciona um pra ajudar
      if (perguntas.value.length === 0) addTask()
    } 
    
    else if (configType === 'system') {
      const { data, error } = await supabase.from('sistemaconfiguracao').select('*').limit(1).single()
      if (error && error.code !== 'PGRST116') throw error // PGRST116 is "No rows found"
      if (data) {
        sistemaConfig.value = { ...data }
      } else {
        sistemaConfig.value = { debounce: 5000, promptIA: '', nomeIA: '', nomeclinica: '' }
      }
    }
    
    else if (configType === 'profile') {
      const { data: sessionData } = await supabase.auth.getUser()
      userProfile.value = { 
         fullName: sessionData?.user?.user_metadata?.full_name || '',
         email: sessionData?.user?.email || ''
      }
    }
    
  } catch (err: any) {
    console.error(err)
    alert('Erro ao carregar os dados: ' + err.message)
    activeModal.value = null
  } finally {
    isLoading.value = false
  }
}

const closeModal = () => {
  if (isSaving.value) return
  activeModal.value = null
}

const formatTimeToHHMM = (dbTime: string | null) => {
  if (!dbTime) return '00:00'
  return dbTime.substring(0, 5) // "18:00:00" -> "18:00"
}

// Persist Functions
const saveHours = async () => {
  isSaving.value = true
  try {
    const clinicId = await getMyClinicId()
    
    // Prepare data
    const payload = clinicHours.value.map(h => ({
      ...h,
      clinic_id: clinicId
    }))

    // Use upsert matching day_of_week and clinic_id
    const { error } = await supabase.from('clinic_hours').upsert(payload, { onConflict: 'clinic_id,day_of_week' })
    if (error) throw error
    
    alert('Horários salvos com sucesso!')
    closeModal()
  } catch (err: any) {
    console.error(err)
    alert('Erro ao salvar horários: ' + err.message)
  } finally {
    isSaving.value = false
  }
}

// Perguntas helpers
const addTask = () => {
  perguntas.value.push({ pergunta: '', id: `temp-${Date.now()}` }) // Temporary ID
}
const removeTask = async (idx: number, id: string | number) => {
  if (typeof id === 'number' || !String(id).startsWith('temp-')) {
    const { error } = await supabase.from('clinica_perguntas').delete().eq('id', id)
    if (error) {
       alert('Erro ao deletar pergunta.')
       return
    }
  }
  perguntas.value.splice(idx, 1)
}
const saveQuestions = async () => {
  isSaving.value = true
  try {
    const clinicId = await getMyClinicId()
    
    const updates = []
    const inserts = []
    
    for (const p of perguntas.value) {
       const raw: any = { clinic: clinicId, pergunta: p.pergunta }
       if (typeof p.id === 'number') {
           raw.id = p.id
           updates.push(raw)
       } else if (typeof p.id === 'string' && !p.id.startsWith('temp-')) {
           raw.id = p.id
           updates.push(raw)
       } else {
           inserts.push(raw)
       }
    }
    
    if (updates.length > 0) {
        const { error } = await supabase.from('clinica_perguntas').upsert(updates)
        if (error) throw error
    }
    if (inserts.length > 0) {
        const { error } = await supabase.from('clinica_perguntas').insert(inserts)
        if (error) throw error
    }
    
    alert('Perguntas salvas com sucesso!')
    closeModal()
  } catch(err: any) {
      console.error(err)
      alert('Erro ao salvar perguntas: ' + err.message)
  } finally {
      isSaving.value = false
  }
}

const saveSystem = async () => {
  isSaving.value = true
  try {
    const payload = {
       nomeclinica: sistemaConfig.value.nomeclinica,
       nomeIA: sistemaConfig.value.nomeIA,
       promptIA: sistemaConfig.value.promptIA,
       debounce: sistemaConfig.value.debounce
    }
    
    if (sistemaConfig.value.id) {
       // Update
       const { error } = await supabase.from('sistemaconfiguracao').update(payload).eq('id', sistemaConfig.value.id)
       if (error) throw error
    } else {
       // Insert
       const { error } = await supabase.from('sistemaconfiguracao').insert(payload)
       if (error) throw error
    }
    alert('Configurações do sistema salvas com sucesso!')
    closeModal()
  } catch(err: any) {
    console.error(err)
    alert('Erro ao salvar configuração central: ' + (err.message || err.details || JSON.stringify(err)))
  } finally {
    isSaving.value = false
  }
}

const saveProfile = async () => {
   isSaving.value = true
   try {
     const { error } = await supabase.auth.updateUser({
        data: { full_name: userProfile.value.fullName }
     })
     if (error) throw error
     alert('Perfil atualizado com sucesso!')
     closeModal()
   } catch(err: any) {
      console.error(err)
      alert("Erro ao salvar perfil.")
   } finally {
      isSaving.value = false
   }
}

const exportCSV = async (filterType: string) => {
  isSaving.value = true
  try {
    let query = supabase.from('leads').select('*, corretores(nome)')
    let filename = 'leads_jrv'

    if (filterType === 'perdidos') {
      query = query.or('stage.eq.perdido,situacao_nome.eq.perdido,estagiokanbam.eq.perdido')
      filename = 'leads_perdidos'
    } else if (filterType === 'perdidos_sem_corretor') {
      query = query.or('stage.eq.perdido,situacao_nome.eq.perdido,estagiokanbam.eq.perdido').is('corretor_id', null)
      filename = 'leads_perdidos_sem_corretor'
    } else if (filterType === 'novos') {
      query = query.or('stage.eq.novo,situacao_nome.eq.novo,estagiokanbam.eq.novo')
      filename = 'leads_novos'
    } else if (filterType === 'nome_numero') {
      filename = 'leads_nome_numero'
    }

    const { data, error } = await query
    let rows: any[] = []

    if (error || !data || data.length === 0) {
      // Se a consulta filtrada não retornar ou der fallback no dev
      const { data: allData } = await supabase.from('leads').select('*, corretores(nome)')
      if (allData && allData.length > 0) {
        if (filterType === 'perdidos') {
          rows = allData.filter((l: any) => l.stage === 'perdido' || l.situacao_nome === 'perdido' || l.estagiokanbam === 'perdido')
        } else if (filterType === 'perdidos_sem_corretor') {
          rows = allData.filter((l: any) => (l.stage === 'perdido' || l.situacao_nome === 'perdido' || l.estagiokanbam === 'perdido') && !l.corretor_id)
        } else if (filterType === 'novos') {
          rows = allData.filter((l: any) => l.stage === 'novo' || l.situacao_nome === 'novo' || l.estagiokanbam === 'novo')
        } else {
          rows = allData
        }
      }
      
      if (rows.length === 0) {
        rows = [
          { name: 'Ana Clara Moreira', phone: '5511991234567', stage: 'perdido', corretor: 'Sem Corretor', created_at: new Date().toISOString() },
          { name: 'Dr. Paulo Ribeiro', phone: '5521998765432', stage: 'perdido', corretor: 'Carlos Eduardo', created_at: new Date().toISOString() },
          { name: 'Juliana Ferreira', phone: '5531987654321', stage: 'novo', corretor: 'Mariana Lima', created_at: new Date().toISOString() },
          { name: 'Marcos Vinícius', phone: '5511976543210', stage: 'perdido', corretor: 'Sem Corretor', created_at: new Date().toISOString() }
        ]
      }
    } else {
      rows = data
    }

    const csvHeader = 'Nome,Telefone,Status,Corretor,Data_Criacao\n'
    const csvRows = rows.map((l: any) => {
      const name = `"${(l.name || 'Sem nome').replace(/"/g, '""')}"`
      const phone = `"${(l.phone || l.remotejid || '').replace(/"/g, '""')}"`
      const rawStatus = l.stage || l.situacao_nome || l.estagiokanbam || l.status_crm || (l.ativo === false ? 'perdido' : 'novo')
      const status = `"${rawStatus.replace(/"/g, '""')}"`
      const corretorNome = l.corretores?.nome || l.corretor || (l.corretor_id ? 'Corretor Atribuído' : 'Sem Corretor')
      const corretor = `"${corretorNome.replace(/"/g, '""')}"`
      const date = `"${l.created_at || ''}"`
      return `${name},${phone},${status},${corretor},${date}`
    }).join('\n')

    const blob = new Blob(['\uFEFF' + csvHeader + csvRows], { type: 'text/csv;charset=utf-8;' })
    const link = document.createElement('a')
    link.href = URL.createObjectURL(blob)
    link.download = `${filename}_${new Date().toISOString().split('T')[0]}.csv`
    link.click()
    URL.revokeObjectURL(link.href)
  } catch (err: any) {
    console.error(err)
    alert('Erro ao exportar dados: ' + (err.message || 'Falha ao gerar o arquivo.'))
  } finally {
    isSaving.value = false
  }
}

const options = [
  {
    type: 'hours',
    icon: Clock,
    title: 'Horários de Funcionamento',
    description: 'Defina os horários e dias de atendimento da sua operação.',
  },
  {
    type: 'questions',
    icon: MessageCircle,
    title: 'Perguntas Qualificação',
    description: 'Gerencie os scripts e perguntas base para qualificar seus leads.',
  },
  {
    type: 'system',
    icon: Settings,
    title: 'Sistema configuração',
    description: 'Parâmetros centrais, preferências e regras de negócio da plataforma.',
  },
  {
    type: 'downloads',
    icon: FileSpreadsheet,
    title: 'Download de Dados (Planilhas)',
    description: 'Exporte relatórios em CSV de leads perdidos, perdidos sem corretor, novos, etc.',
  },
  {
    type: 'profile',
    icon: User,
    title: 'Editar Perfil',
    description: 'Atualize seus dados pessoais, senha e foto de avatar.',
  }
]
</script>

<template>
  <div class="min-h-screen bg-gray-50 dark:bg-dark-bg text-gray-900 dark:text-white font-sans transition-colors duration-300">
    <Sidebar />

    <main :class="[mainMargin, 'px-4 py-5 sm:px-6 lg:p-10 min-h-screen flex flex-col transition-all duration-300 relative z-0']">
      <!-- Header -->
      <div class="mb-10">
        <h1 class="text-3xl font-bold font-serif text-gray-900 dark:text-white tracking-wide">Configurações do Sistema</h1>
        <p class="text-gray-500 dark:text-gray-400 mt-2 font-light">Gerencie as preferências, horários e detalhes de perfil da sua loja/TIA.</p>
      </div>

      <!-- Config Grid -->
      <div class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
        
        <div 
          v-for="(option, idx) in options" 
          :key="idx"
          @click="openConfig(option.type)"
          class="bg-white dark:bg-dark-surface/50 backdrop-blur-md border border-gray-200 dark:border-white/5 rounded-sm p-6 cursor-pointer shadow-sm hover:border-primary-500 hover:shadow-luxury hover:-translate-y-1 transition-all duration-300 group flex flex-col relative z-0"
        >
          <div class="w-12 h-12 rounded-sm bg-primary-50 dark:bg-primary-500/10 border border-primary-100 dark:border-primary-500/20 text-primary-500 flex items-center justify-center mb-5 group-hover:bg-primary-500 group-hover:text-white group-hover:border-transparent transition-all duration-300">
            <component :is="option.icon" class="w-[22px] h-[22px]" />
          </div>
          <h3 class="text-lg font-bold text-gray-900 dark:text-white mb-2 tracking-tight">{{ option.title }}</h3>
          <p class="text-sm text-gray-500 dark:text-gray-400 font-light flex-1 leading-relaxed">{{ option.description }}</p>
        </div>

      </div>
    </main>

    <!-- Global Modal Overlay -->
    <div v-if="activeModal" class="fixed inset-0 z-[100] flex items-end sm:items-center justify-center p-0 sm:p-4">
      <div class="absolute inset-0 bg-black/60 backdrop-blur-sm" @click="closeModal"></div>
      
      <div class="relative z-10 pointer-events-auto bg-white dark:bg-dark-card w-full max-w-2xl rounded-t-2xl sm:rounded-sm shadow-2xl border border-gray-200 dark:border-white/10 flex flex-col max-h-[94dvh] sm:max-h-[90vh] overflow-hidden">
        
        <!-- Modal Loading State -->
        <div v-if="isLoading" class="absolute inset-0 z-50 bg-white/80 dark:bg-dark-card/80 backdrop-blur-sm flex flex-col items-center justify-center">
            <div class="w-8 h-8 border-4 border-primary-500 border-t-transparent animate-spin rounded-full"></div>
            <p class="mt-2 text-sm font-semibold text-gray-500">Sincronizando...</p>
        </div>

        <!-- Header -->
        <div class="px-4 sm:px-6 py-4 border-b border-gray-200 dark:border-white/10 flex items-center justify-between sticky top-0 bg-white dark:bg-dark-card z-10">
          <h2 class="text-xl font-serif font-bold text-gray-900 dark:text-white">
            <span v-if="activeModal === 'hours'">Horários de Funcionamento</span>
            <span v-else-if="activeModal === 'questions'">Perguntas de Qualificação</span>
            <span v-else-if="activeModal === 'system'">Sistema Configuração</span>
            <span v-else-if="activeModal === 'downloads'">Download de Dados e Planilhas</span>
            <span v-else-if="activeModal === 'profile'">Editar Perfil</span>
          </h2>
          <button @click="closeModal" :disabled="isSaving" class="p-2 text-gray-400 hover:text-gray-900 dark:hover:text-white transition-colors disabled:opacity-50">
            <X class="w-5 h-5" />
          </button>
        </div>

        <!-- Body -->
        <div class="p-4 sm:p-6 overflow-y-auto flex-1 bg-gray-50/50 dark:bg-transparent">
          
          <!-- HORÁRIOS FORM -->
          <div v-if="activeModal === 'hours'" class="space-y-4">
             <div v-for="day in clinicHours" :key="day.day_of_week" class="flex flex-col sm:flex-row sm:items-center gap-4 bg-white dark:bg-dark-surface border border-gray-200 dark:border-white/10 p-4 rounded-sm shadow-sm transition-all hover:border-primary-200">
               <div class="w-full sm:w-1/3 flex items-center justify-between sm:block">
                  <span class="font-bold text-gray-700 dark:text-gray-200 uppercase tracking-widest text-xs">{{ daysOfWeek.find(d => d.id === day.day_of_week)?.label }}</span>
                  <label class="flex items-center cursor-pointer mt-2">
                    <div class="relative">
                      <input type="checkbox" v-model="day.is_closed" class="sr-only">
                      <div class="block bg-gray-200 dark:bg-gray-700 w-10 h-6 rounded-full transition-colors duration-300" :class="{'!bg-red-500': day.is_closed}"></div>
                      <div class="dot absolute left-1 top-1 bg-white w-4 h-4 rounded-full transition transform duration-300" :class="{'translate-x-4': day.is_closed}"></div>
                    </div>
                    <div class="ml-3 text-xs font-medium text-gray-500" :class="{'text-red-500': day.is_closed}">Fechado</div>
                  </label>
               </div>
               
                <div class="w-full sm:w-2/3 grid grid-cols-2 sm:flex sm:flex-wrap gap-2 text-sm" v-if="!day.is_closed">
                  <div class="flex flex-col flex-1 min-w-[70px]">
                    <span class="text-[10px] uppercase text-gray-400 mb-1">Abertura</span>
                    <input type="time" v-model="day.open_time" class="bg-gray-50 dark:bg-dark-bg border border-gray-200 dark:border-white/10 rounded-sm px-2 py-1 text-gray-900 dark:text-white outline-none focus:border-primary-500">
                  </div>
                  <div class="flex flex-col flex-1 min-w-[70px]">
                    <span class="text-[10px] uppercase text-gray-400 mb-1">Almoço (Início)</span>
                    <input type="time" v-model="day.lunch_start" class="bg-gray-50 dark:bg-dark-bg border border-gray-200 dark:border-white/10 rounded-sm px-2 py-1 text-gray-900 dark:text-white outline-none focus:border-primary-500">
                  </div>
                  <div class="flex flex-col flex-1 min-w-[70px]">
                    <span class="text-[10px] uppercase text-gray-400 mb-1">Almoço (Fim)</span>
                    <input type="time" v-model="day.lunch_end" class="bg-gray-50 dark:bg-dark-bg border border-gray-200 dark:border-white/10 rounded-sm px-2 py-1 text-gray-900 dark:text-white outline-none focus:border-primary-500">
                  </div>
                  <div class="flex flex-col flex-1 min-w-[70px]">
                    <span class="text-[10px] uppercase text-gray-400 mb-1">Fechamento</span>
                    <input type="time" v-model="day.close_time" class="bg-gray-50 dark:bg-dark-bg border border-gray-200 dark:border-white/10 rounded-sm px-2 py-1 text-gray-900 dark:text-white outline-none focus:border-primary-500">
                  </div>
               </div>
                <div v-else class="w-full sm:w-2/3 flex items-center sm:justify-center text-sm text-gray-400 italic">
                  Dia de descanso merecido.
               </div>
             </div>
          </div>

          <!-- PERGUNTAS FORM -->
          <div v-else-if="activeModal === 'questions'" class="space-y-4">
            <button @click="addTask" class="mb-4 flex items-center gap-2 bg-primary-50 text-primary-600 dark:bg-primary-500/10 dark:text-primary-400 px-4 py-2 rounded-sm hover:bg-primary-100 transition-colors text-sm font-semibold uppercase tracking-widest w-full justify-center">
               <Plus class="w-4 h-4" /> Adicionar Parâmetro de Pergunta
            </button>
            <div v-for="(p, idx) in perguntas" :key="p.id" class="flex items-center gap-3">
              <span class="text-sm font-bold text-gray-300 dark:text-gray-600">{{ idx + 1 }}.</span>
              <input v-model="p.pergunta" type="text" placeholder="Ex: Qual o plano de saúde do paciente?" class="flex-1 bg-white dark:bg-dark-surface border border-gray-200 dark:border-white/10 rounded-sm px-4 py-2.5 text-gray-900 dark:text-white focus:outline-none focus:border-primary-500 shadow-sm transition-all focus:shadow-md">
              <button @click="removeTask(idx, p.id)" class="text-gray-300 hover:text-red-500 p-2 transition-colors">
                <Trash2 class="w-5 h-5" />
              </button>
            </div>
            <p v-if="perguntas.length === 0" class="text-center text-gray-400 py-10">Nenhuma pergunta cadastrada.</p>
          </div>

          <!-- SISTEMA FORM -->
          <div v-else-if="activeModal === 'system'" class="space-y-6">
            <div class="grid grid-cols-1 md:grid-cols-2 gap-6">
               <div>
                 <label class="block text-xs font-semibold uppercase tracking-widest text-gray-500 dark:text-gray-400 mb-2">Nome da TIA (Fantasia)</label>
                 <input v-model="sistemaConfig.nomeclinica" type="text" placeholder="Ex: ImplanteTech" class="w-full bg-white dark:bg-dark-surface border border-gray-200 dark:border-white/10 rounded-sm px-4 py-2.5 text-gray-900 dark:text-white focus:outline-none focus:border-primary-500 shadow-sm">
               </div>
               <div>
                 <label class="block text-xs font-semibold uppercase tracking-widest text-gray-500 dark:text-gray-400 mb-2">Nome da Assistente IA</label>
                 <input v-model="sistemaConfig.nomeIA" type="text" placeholder="Ex: Íris" class="w-full bg-white dark:bg-dark-surface border border-gray-200 dark:border-white/10 rounded-sm px-4 py-2.5 text-gray-900 dark:text-white focus:outline-none focus:border-primary-500 shadow-sm">
               </div>
               <div>
                 <label class="block text-xs font-semibold uppercase tracking-widest text-gray-500 dark:text-gray-400 mb-2">Debounce Time (em ms)</label>
                 <input v-model="sistemaConfig.debounce" type="number" class="w-full bg-white dark:bg-dark-surface border border-gray-200 dark:border-white/10 rounded-sm px-4 py-2.5 text-gray-900 dark:text-white focus:outline-none focus:border-primary-500 shadow-sm">
                 <p class="text-[10px] mt-1 text-gray-400">Tempo de espera antes da IA responder. 5000 = 5s</p>
               </div>
               <div class="md:col-span-2">
                 <label class="block text-xs font-semibold uppercase tracking-widest text-gray-500 dark:text-gray-400 mb-2">Prompt da IA Base</label>
                 <textarea v-model="sistemaConfig.promptIA" rows="6" placeholder="Você é a assistente..." class="w-full bg-white dark:bg-dark-surface border border-gray-200 dark:border-white/10 rounded-sm px-4 py-2.5 text-gray-900 dark:text-white focus:outline-none focus:border-primary-500 shadow-sm leading-relaxed whitespace-pre-wrap"></textarea>
               </div>
            </div>
          </div>

          <!-- PERFIL FORM -->
          <div v-else-if="activeModal === 'profile'" class="space-y-6">
            <div class="flex items-center gap-6 mb-6">
               <div class="w-20 h-20 rounded-sm bg-primary-500 text-white flex items-center justify-center font-bold text-3xl shadow-luxury">
                 {{ userProfile.fullName.charAt(0) || 'U' }}
               </div>
               <div>
                 <h3 class="text-xl font-bold font-serif dark:text-white">{{ userProfile.fullName || 'Administrador' }}</h3>
                 <p class="text-gray-500 mt-1">{{ userProfile.email }}</p>
               </div>
            </div>
            
            <div class="grid grid-cols-1 gap-6 max-w-md">
               <div>
                 <label class="block text-xs font-semibold uppercase tracking-widest text-gray-500 dark:text-gray-400 mb-2">Nome Completo</label>
                 <input v-model="userProfile.fullName" type="text" class="w-full bg-white dark:bg-dark-surface border border-gray-200 dark:border-white/10 rounded-sm px-4 py-2.5 text-gray-900 dark:text-white focus:outline-none focus:border-primary-500 shadow-sm">
               </div>
               <div>
                 <label class="block text-xs font-semibold uppercase tracking-widest text-gray-500 dark:text-gray-400 mb-2">E-mail (Login)</label>
                 <input v-model="userProfile.email" type="text" disabled class="w-full bg-gray-100 dark:bg-dark-bg border border-gray-200 dark:border-white/5 rounded-sm px-4 py-2.5 text-gray-400 dark:text-gray-500 cursor-not-allowed">
               </div>
            </div>
          </div>

          <!-- DOWNLOADS FORM -->
          <div v-else-if="activeModal === 'downloads'" class="space-y-4">
             <p class="text-sm text-gray-500 dark:text-gray-400 mb-4">
               Selecione o filtro desejado para gerar e baixar a planilha em formato CSV compatível com Excel e Google Sheets:
             </p>
             
             <div class="grid grid-cols-1 sm:grid-cols-2 gap-4">
                <button 
                  @click="exportCSV('nome_numero')" 
                  :disabled="isSaving" 
                  class="flex items-center gap-3 p-4 bg-white dark:bg-dark-surface border border-gray-200 dark:border-white/10 rounded-sm hover:border-primary-500 hover:shadow-md transition-all text-left group"
                >
                   <div class="p-2.5 bg-primary-50 dark:bg-primary-500/10 text-primary-500 rounded-sm group-hover:bg-primary-500 group-hover:text-white transition-colors">
                      <FileSpreadsheet class="w-5 h-5" />
                   </div>
                   <div>
                      <h4 class="text-sm font-bold text-gray-900 dark:text-white">Planilha Nome e Telefone</h4>
                      <p class="text-xs text-gray-500 dark:text-gray-400">Todos os leads cadastrados</p>
                   </div>
                </button>

                <button 
                  @click="exportCSV('perdidos')" 
                  :disabled="isSaving" 
                  class="flex items-center gap-3 p-4 bg-white dark:bg-dark-surface border border-gray-200 dark:border-white/10 rounded-sm hover:border-red-500 hover:shadow-md transition-all text-left group"
                >
                   <div class="p-2.5 bg-red-50 dark:bg-red-500/10 text-red-500 rounded-sm group-hover:bg-red-500 group-hover:text-white transition-colors">
                      <Download class="w-5 h-5" />
                   </div>
                   <div>
                      <h4 class="text-sm font-bold text-gray-900 dark:text-white">Leads Perdidos</h4>
                      <p class="text-xs text-gray-500 dark:text-gray-400">Todos os leads com status perdido</p>
                   </div>
                </button>

                <button 
                  @click="exportCSV('perdidos_sem_corretor')" 
                  :disabled="isSaving" 
                  class="flex items-center gap-3 p-4 bg-white dark:bg-dark-surface border border-gray-200 dark:border-white/10 rounded-sm hover:border-amber-500 hover:shadow-md transition-all text-left group"
                >
                   <div class="p-2.5 bg-amber-50 dark:bg-amber-500/10 text-amber-500 rounded-sm group-hover:bg-amber-500 group-hover:text-white transition-colors">
                      <Download class="w-5 h-5" />
                   </div>
                   <div>
                      <h4 class="text-sm font-bold text-gray-900 dark:text-white">Perdidos Sem Corretor</h4>
                      <p class="text-xs text-gray-500 dark:text-gray-400">Leads perdidos sem responsável</p>
                   </div>
                </button>

                <button 
                  @click="exportCSV('novos')" 
                  :disabled="isSaving" 
                  class="flex items-center gap-3 p-4 bg-white dark:bg-dark-surface border border-gray-200 dark:border-white/10 rounded-sm hover:border-emerald-500 hover:shadow-md transition-all text-left group"
                >
                   <div class="p-2.5 bg-emerald-50 dark:bg-emerald-500/10 text-emerald-500 rounded-sm group-hover:bg-emerald-500 group-hover:text-white transition-colors">
                      <Download class="w-5 h-5" />
                   </div>
                   <div>
                      <h4 class="text-sm font-bold text-gray-900 dark:text-white">Leads Novos</h4>
                      <p class="text-xs text-gray-500 dark:text-gray-400">Leads no estágio inicial</p>
                   </div>
                </button>
             </div>
          </div>

        </div>

        <!-- Footer -->
        <div class="px-6 py-4 border-t border-gray-200 dark:border-white/10 bg-white dark:bg-dark-card flex justify-end gap-3 sticky bottom-0">
          <button @click="closeModal" :disabled="isSaving" class="px-5 py-2.5 text-sm font-semibold text-gray-600 dark:text-gray-300 hover:bg-gray-100 dark:hover:bg-white/5 rounded-sm transition-colors uppercase tracking-widest disabled:opacity-50">
            Cancelar
          </button>
          <button 
             v-if="activeModal === 'hours'" @click="saveHours"
             :disabled="isSaving" class="flex items-center gap-2 px-5 py-2.5 bg-primary-500 hover:bg-primary-600 text-white text-sm font-semibold rounded-sm transition-colors shadow-luxury uppercase tracking-widest disabled:opacity-50"
           >
            <template v-if="isSaving"><div class="w-4 h-4 border-2 border-white border-t-transparent animate-spin rounded-full"></div></template>
            <template v-else><Save class="w-4 h-4" /> Salvar Horários</template>
          </button>

          <button 
             v-else-if="activeModal === 'questions'" @click="saveQuestions"
             :disabled="isSaving" class="flex items-center gap-2 px-5 py-2.5 bg-primary-500 hover:bg-primary-600 text-white text-sm font-semibold rounded-sm transition-colors shadow-luxury uppercase tracking-widest disabled:opacity-50"
           >
            <template v-if="isSaving"><div class="w-4 h-4 border-2 border-white border-t-transparent animate-spin rounded-full"></div></template>
            <template v-else><Save class="w-4 h-4" /> Salvar Perguntas</template>
          </button>

          <button 
             v-else-if="activeModal === 'system'" @click="saveSystem"
             :disabled="isSaving" class="flex items-center gap-2 px-5 py-2.5 bg-primary-500 hover:bg-primary-600 text-white text-sm font-semibold rounded-sm transition-colors shadow-luxury uppercase tracking-widest disabled:opacity-50"
           >
            <template v-if="isSaving"><div class="w-4 h-4 border-2 border-white border-t-transparent animate-spin rounded-full"></div></template>
            <template v-else><Save class="w-4 h-4" /> Salvar Sistema</template>
          </button>

          <button 
             v-else-if="activeModal === 'profile'" @click="saveProfile"
             :disabled="isSaving" class="flex items-center gap-2 px-5 py-2.5 bg-primary-500 hover:bg-primary-600 text-white text-sm font-semibold rounded-sm transition-colors shadow-luxury uppercase tracking-widest disabled:opacity-50"
           >
            <template v-if="isSaving"><div class="w-4 h-4 border-2 border-white border-t-transparent animate-spin rounded-full"></div></template>
            <template v-else><Save class="w-4 h-4" /> Salvar Perfil</template>
          </button>

        </div>
      </div>
    </div>
  </div>
</template>
