<script setup lang="ts">
import { ref, computed, watch, onMounted, onUnmounted } from 'vue'
import { 
  X, 
  Search, 
  User, 
  Phone, 
  Mail, 
  Calendar, 
  Clock, 
  Building, 
  Check, 
  AlertCircle, 
  Sparkles,
  Plus
} from 'lucide-vue-next'
import { useSupabaseClient } from '#imports'

const props = defineProps<{
  modelValue: boolean
}>()

const emit = defineEmits<{
  (e: 'update:modelValue', value: boolean): void
  (e: 'created'): void
}>()

const supabase = useSupabaseClient<any>()

// State
const searchQuery = ref('')
const isSearching = ref(false)
const searchResults = ref<any[]>([])
const isDropdownOpen = ref(false)
const selectedLead = ref<any | null>(null)

// Form fields
const appointmentDate = ref('')
const startTime = ref('09:00')
const procedureOrAbout = ref('')

const isSubmitting = ref(false)
const errorMessage = ref<string | null>(null)
const successMessage = ref<string | null>(null)

// Default hours available
const availableHours = [
  '08:00', '08:30', '09:00', '09:30', '10:00', '10:30',
  '11:00', '11:30', '12:00', '12:30', '13:00', '13:30',
  '14:00', '14:30', '15:00', '15:30', '16:00', '16:30',
  '17:00', '17:30', '18:00'
]

// Computed End Time (always +1 hour)
const calculatedEndTime = computed(() => {
  if (!startTime.value) return ''
  const [h, m] = startTime.value.split(':').map(Number)
  if (isNaN(h) || isNaN(m)) return ''
  const endHour = (h + 1) % 24
  const endHourStr = String(endHour).padStart(2, '0')
  const endMinStr = String(m).padStart(2, '0')
  return `${endHourStr}:${endMinStr}`
})

// Initialize default date (today)
const resetForm = () => {
  const today = new Date()
  const y = today.getFullYear()
  const m = String(today.getMonth() + 1).padStart(2, '0')
  const d = String(today.getDate()).padStart(2, '0')
  appointmentDate.value = `${y}-${m}-${d}`
  startTime.value = '09:00'
  procedureOrAbout.value = ''
  selectedLead.value = null
  searchQuery.value = ''
  searchResults.value = []
  isDropdownOpen.value = false
  errorMessage.value = null
  successMessage.value = null
}

watch(() => props.modelValue, (newVal) => {
  if (newVal) {
    resetForm()
  }
})

// Search leads with debounce
let debounceTimer: any = null
const onSearchInput = () => {
  clearTimeout(debounceTimer)
  const q = searchQuery.value.trim()
  if (!q) {
    searchResults.value = []
    isDropdownOpen.value = false
    return
  }

  isSearching.value = true
  isDropdownOpen.value = true

  debounceTimer = setTimeout(async () => {
    try {
      // Query leads filtering by name, email, phone or remotejid
      const { data, error } = await supabase
        .from('leads')
        .select('id, name, phone, remotejid, email, clinic_id, tipo_imovel')
        .or(`name.ilike.%${q}%,email.ilike.%${q}%,phone.ilike.%${q}%,remotejid.ilike.%${q}%`)
        .limit(10)

      if (error) throw error
      searchResults.value = data || []
    } catch (err: any) {
      console.error('Erro ao buscar leads:', err)
      searchResults.value = []
    } finally {
      isSearching.value = false
    }
  }, 250)
}

const selectLead = (lead: any) => {
  selectedLead.value = lead
  isDropdownOpen.value = false
  searchQuery.value = ''
  if (lead.tipo_imovel && !procedureOrAbout.value) {
    procedureOrAbout.value = `Visita / Interesse: ${lead.tipo_imovel}`
  }
}

const removeSelectedLead = () => {
  selectedLead.value = null
}

const formatDisplayPhone = (lead: any) => {
  const phone = lead.phone || lead.remotejid || ''
  const clean = phone.replace(/\D/g, '')
  if (clean.length === 13 && clean.startsWith('55')) {
    return `+55 (${clean.slice(2, 4)}) ${clean.slice(4, 9)}-${clean.slice(9)}`
  }
  if (clean.length === 11) {
    return `(${clean.slice(0, 2)}) ${clean.slice(2, 7)}-${clean.slice(7)}`
  }
  return phone
}

// Close dropdown on outside click
const searchContainer = ref<HTMLElement | null>(null)
const handleClickOutside = (e: MouseEvent) => {
  if (searchContainer.value && !searchContainer.value.contains(e.target as Node)) {
    isDropdownOpen.value = false
  }
}

onMounted(() => {
  document.addEventListener('click', handleClickOutside)
})

onUnmounted(() => {
  document.removeEventListener('click', handleClickOutside)
  clearTimeout(debounceTimer)
})

// Resolve clinic_id helper
const resolveClinicId = async (leadClinicId?: string) => {
  if (leadClinicId) return leadClinicId
  try {
    const { data: rpcClinic } = await supabase.rpc('get_auth_clinic_id')
    if (rpcClinic) return rpcClinic
  } catch {}
  return null
}

// Submit manual appointment
const handleSubmit = async () => {
  errorMessage.value = null
  successMessage.value = null

  if (!selectedLead.value) {
    errorMessage.value = 'Por favor, selecione um cliente para o agendamento.'
    return
  }

  if (!appointmentDate.value) {
    errorMessage.value = 'Por favor, selecione a data do agendamento.'
    return
  }

  if (!startTime.value) {
    errorMessage.value = 'Por favor, selecione o horário de início.'
    return
  }

  isSubmitting.value = true

  try {
    const clinicId = await resolveClinicId(selectedLead.value.clinic_id)

    const formattedStartTime = startTime.value.length === 5 ? `${startTime.value}:00` : startTime.value
    const formattedEndTime = calculatedEndTime.value.length === 5 ? `${calculatedEndTime.value}:00` : calculatedEndTime.value

    const payload: any = {
      lead_id: selectedLead.value.id,
      clinic_id: clinicId,
      appointment_date: appointmentDate.value,
      start_time: formattedStartTime,
      end_time: formattedEndTime,
      status: 'agendado',
      about: procedureOrAbout.value.trim() || 'Visita / Atendimento Agendado',
      created_by_ia: false
    }

    const { data, error } = await supabase
      .from('appointments')
      .insert(payload)
      .select()

    if (error) throw error

    successMessage.value = 'Agendamento cadastrado com sucesso!'
    
    emit('created')

    setTimeout(() => {
      emit('update:modelValue', false)
    }, 900)
  } catch (err: any) {
    console.error('Erro ao salvar agendamento:', err)
    errorMessage.value = err?.message || 'Ocorreu um erro ao cadastrar o agendamento.'
  } finally {
    isSubmitting.value = false
  }
}

const closeModal = () => {
  emit('update:modelValue', false)
}
</script>

<template>
  <Transition name="modal-fade">
    <div 
      v-if="modelValue" 
      class="fixed inset-0 z-[70] flex items-end sm:items-center justify-center p-0 sm:p-6 overflow-y-auto"
      role="dialog"
      aria-modal="true"
    >
      <!-- Backdrop -->
      <div 
        class="fixed inset-0 bg-gray-900/60 dark:bg-black/80 backdrop-blur-sm transition-opacity" 
        @click="closeModal"
      />

      <!-- Modal Card -->
      <div class="relative w-full max-w-lg max-h-[94dvh] sm:max-h-[90vh] bg-white dark:bg-dark-surface border border-gray-200/80 dark:border-dark-border rounded-t-2xl sm:rounded-2xl shadow-2xl overflow-y-auto sm:my-auto z-10 transition-all">
        
        <!-- Header with generous padding -->
        <div class="px-4 sm:px-6 py-4 sm:py-5 border-b border-gray-100 dark:border-dark-border flex items-center justify-between bg-gray-50/80 dark:bg-dark-card/60 rounded-t-2xl sticky top-0 z-20">
          <div class="flex items-center gap-3.5">
            <div class="p-2.5 bg-primary-50 dark:bg-primary-500/10 text-primary-600 dark:text-primary-400 rounded-xl border border-primary-100 dark:border-primary-500/20 shadow-sm">
              <Calendar class="w-5 h-5" />
            </div>
            <div>
              <h2 class="text-base font-bold text-gray-900 dark:text-white leading-tight">
                Novo Agendamento Manual
              </h2>
              <p class="text-xs text-gray-500 dark:text-dark-muted mt-0.5">
                Vincule um cliente e defina o horário do compromisso
              </p>
            </div>
          </div>
          
          <button 
            @click="closeModal" 
            class="p-2 rounded-xl text-gray-400 hover:text-gray-700 dark:hover:text-white hover:bg-gray-100 dark:hover:bg-dark-card transition-colors"
            aria-label="Fechar"
          >
            <X class="w-5 h-5" />
          </button>
        </div>

        <!-- Body Form with spacious padding and clear structure -->
        <form @submit.prevent="handleSubmit" class="p-6 sm:p-7 flex flex-col gap-5">
          
          <!-- Alert feedback -->
          <div 
            v-if="errorMessage" 
            class="flex items-start gap-3 p-3.5 rounded-xl bg-red-50 dark:bg-red-500/10 border border-red-200 dark:border-red-500/20 text-red-700 dark:text-red-300 text-xs"
          >
            <AlertCircle class="w-4 h-4 flex-shrink-0 mt-0.5" />
            <span>{{ errorMessage }}</span>
          </div>

          <div 
            v-if="successMessage" 
            class="flex items-center gap-3 p-3.5 rounded-xl bg-emerald-50 dark:bg-emerald-500/10 border border-emerald-200 dark:border-emerald-500/20 text-emerald-700 dark:text-emerald-300 text-xs"
          >
            <Check class="w-4 h-4 flex-shrink-0" />
            <span>{{ successMessage }}</span>
          </div>

          <!-- Section: Client Selection / SearchBox -->
          <div ref="searchContainer" class="relative">
            <label class="block text-xs font-semibold text-gray-700 dark:text-gray-300 mb-2">
              Cliente / Lead <span class="text-primary-500">*</span>
            </label>

            <!-- State 1: Lead Already Selected -->
            <div 
              v-if="selectedLead" 
              class="flex items-center justify-between p-4 bg-primary-50/50 dark:bg-primary-500/5 border border-primary-200 dark:border-primary-500/30 rounded-xl shadow-sm"
            >
              <div class="flex items-center gap-3.5 min-w-0">
                <div class="w-10 h-10 rounded-full bg-primary-500 text-white flex items-center justify-center font-bold text-sm flex-shrink-0 shadow-sm">
                  {{ selectedLead.name?.charAt(0)?.toUpperCase() || 'C' }}
                </div>
                <div class="min-w-0">
                  <div class="text-sm font-bold text-gray-900 dark:text-white truncate">
                    {{ selectedLead.name || 'Cliente Sem Nome' }}
                  </div>
                  <div class="flex flex-wrap items-center gap-x-3 gap-y-1 text-xs text-gray-500 dark:text-dark-muted mt-0.5">
                    <span v-if="selectedLead.phone || selectedLead.remotejid" class="flex items-center gap-1.5">
                      <Phone class="w-3.5 h-3.5 text-primary-500 flex-shrink-0" />
                      {{ formatDisplayPhone(selectedLead) }}
                    </span>
                    <span v-if="selectedLead.email" class="flex items-center gap-1.5 truncate">
                      <Mail class="w-3.5 h-3.5 text-primary-500 flex-shrink-0" />
                      {{ selectedLead.email }}
                    </span>
                  </div>
                </div>
              </div>

              <button 
                type="button" 
                @click="removeSelectedLead"
                class="px-3 py-1.5 text-xs font-semibold text-gray-700 dark:text-gray-300 hover:text-red-600 dark:hover:text-red-400 bg-white dark:bg-dark-card hover:bg-red-50 dark:hover:bg-red-500/10 border border-gray-200 dark:border-dark-border rounded-lg transition-colors flex-shrink-0 ml-3 shadow-sm"
              >
                Trocar
              </button>
            </div>

            <!-- State 2: Search Input & Dropdown -->
            <div v-else class="relative">
              <div class="relative">
                <input 
                  type="text"
                  v-model="searchQuery"
                  @input="onSearchInput"
                  @focus="onSearchInput"
                  placeholder="Pesquisar por nome, telefone ou e-mail..."
                  class="w-full pl-11 pr-11 py-3 bg-white dark:bg-dark-card border border-gray-200 dark:border-dark-border rounded-xl text-sm text-gray-900 dark:text-white placeholder-gray-400 focus:outline-none focus:ring-2 focus:ring-primary-500/40 focus:border-primary-500 transition-all shadow-sm"
                  autocomplete="off"
                />
                <div class="absolute inset-y-0 left-0 pl-3.5 flex items-center pointer-events-none text-gray-400">
                  <Search class="w-4 h-4" />
                </div>
                <div v-if="isSearching" class="absolute inset-y-0 right-0 pr-3.5 flex items-center pointer-events-none text-primary-500">
                  <div class="animate-spin w-4 h-4 border-2 border-primary-500 border-t-transparent rounded-full" />
                </div>
              </div>

              <!-- Dropdown Results -->
              <Transition name="dropdown-fade">
                <div 
                  v-if="isDropdownOpen && searchQuery.trim().length > 0" 
                  class="absolute left-0 right-0 top-full mt-2 bg-white dark:bg-dark-surface border border-gray-200 dark:border-dark-border rounded-xl shadow-xl z-30 max-h-64 overflow-y-auto divide-y divide-gray-100 dark:divide-dark-border/50"
                >
                  <div v-if="searchResults.length === 0 && !isSearching" class="p-4 text-center text-xs text-gray-400 dark:text-dark-muted">
                    Nenhum cliente encontrado com "{{ searchQuery }}"
                  </div>
                  <button
                    v-for="lead in searchResults"
                    :key="lead.id"
                    type="button"
                    @click="selectLead(lead)"
                    class="w-full text-left px-4 py-3 hover:bg-primary-50/50 dark:hover:bg-dark-card transition-colors flex items-center justify-between gap-3 group"
                  >
                    <div class="flex items-center gap-3 min-w-0">
                      <div class="w-8 h-8 rounded-full bg-gray-100 dark:bg-dark-bg text-gray-700 dark:text-gray-300 flex items-center justify-center font-bold text-xs flex-shrink-0 group-hover:bg-primary-500 group-hover:text-white transition-colors">
                        {{ lead.name?.charAt(0)?.toUpperCase() || 'C' }}
                      </div>
                      <div class="min-w-0">
                        <div class="text-sm font-semibold text-gray-900 dark:text-white truncate">
                          {{ lead.name || 'Cliente Sem Nome' }}
                        </div>
                        <div class="text-xs text-gray-400 dark:text-dark-muted flex items-center gap-2 mt-0.5 truncate">
                          <span v-if="lead.phone || lead.remotejid">{{ formatDisplayPhone(lead) }}</span>
                          <span v-if="lead.email">· {{ lead.email }}</span>
                        </div>
                      </div>
                    </div>
                    <span class="text-xs font-semibold text-primary-500 opacity-0 group-hover:opacity-100 transition-opacity flex-shrink-0">
                      Selecionar
                    </span>
                  </button>
                </div>
              </Transition>
            </div>
          </div>

          <!-- Section: Date & Time Schedule -->
          <div class="grid grid-cols-1 sm:grid-cols-2 gap-4">
            
            <!-- Date Field -->
            <div>
              <label class="block text-xs font-semibold text-gray-700 dark:text-gray-300 mb-2">
                Data do Agendamento <span class="text-primary-500">*</span>
              </label>
              <div class="relative">
                <input 
                  type="date"
                  v-model="appointmentDate"
                  required
                  class="w-full px-4 py-3 bg-white dark:bg-dark-card border border-gray-200 dark:border-dark-border rounded-xl text-sm text-gray-900 dark:text-white focus:outline-none focus:ring-2 focus:ring-primary-500/40 focus:border-primary-500 transition-all shadow-sm"
                />
              </div>
            </div>

            <!-- Start Time -->
            <div>
              <label class="block text-xs font-semibold text-gray-700 dark:text-gray-300 mb-2">
                Horário de Início <span class="text-primary-500">*</span>
              </label>
              <div class="relative">
                <select 
                  v-model="startTime"
                  required
                  class="w-full px-4 py-3 bg-white dark:bg-dark-card border border-gray-200 dark:border-dark-border rounded-xl text-sm text-gray-900 dark:text-white focus:outline-none focus:ring-2 focus:ring-primary-500/40 focus:border-primary-500 transition-all shadow-sm appearance-none"
                >
                  <option v-for="h in availableHours" :key="h" :value="h">
                    {{ h }}
                  </option>
                </select>
                <div class="pointer-events-none absolute inset-y-0 right-0 flex items-center px-3.5 text-gray-400">
                  <Clock class="w-4 h-4" />
                </div>
              </div>
            </div>
          </div>

          <!-- Duration / End Time Box (Automatic 1 hour) -->
          <div class="bg-gray-50 dark:bg-dark-card/60 px-4 py-3.5 rounded-xl border border-gray-100 dark:border-dark-border flex items-center justify-between">
            <div class="flex items-center gap-2.5 text-xs text-gray-600 dark:text-gray-300">
              <Clock class="w-4 h-4 text-primary-500 flex-shrink-0" />
              <span>Intervalo: <strong>{{ startTime }}</strong> às <strong>{{ calculatedEndTime }}</strong></span>
            </div>
            <span class="inline-flex items-center px-2.5 py-1 rounded-full text-[11px] font-bold bg-primary-50 dark:bg-primary-500/10 text-primary-600 dark:text-primary-400 border border-primary-200 dark:border-primary-500/20">
              1 hora padrão
            </span>
          </div>

          <!-- Procedure / Imóvel / Observações -->
          <div>
            <label class="block text-xs font-semibold text-gray-700 dark:text-gray-300 mb-2">
              Assunto / Imóvel / Observação <span class="text-gray-400 text-[11px] font-normal">(Opcional)</span>
            </label>
            <input 
              type="text"
              v-model="procedureOrAbout"
              placeholder="Ex: Visita ao Imóvel Reserva Real, Reunião de proposta..."
              class="w-full px-4 py-3 bg-white dark:bg-dark-card border border-gray-200 dark:border-dark-border rounded-xl text-sm text-gray-900 dark:text-white placeholder-gray-400 focus:outline-none focus:ring-2 focus:ring-primary-500/40 focus:border-primary-500 transition-all shadow-sm"
            />
          </div>

          <!-- Footer Actions -->
          <div class="pt-4 flex items-center justify-end gap-3 border-t border-gray-100 dark:border-dark-border mt-1">
            <button 
              type="button" 
              @click="closeModal"
              :disabled="isSubmitting"
              class="px-5 py-2.5 text-xs font-semibold text-gray-600 dark:text-gray-300 hover:bg-gray-100 dark:hover:bg-dark-card rounded-xl transition-colors disabled:opacity-50"
            >
              Cancelar
            </button>
            <button 
              type="submit"
              :disabled="isSubmitting || !selectedLead"
              class="flex items-center gap-2 px-6 py-2.5 bg-primary-500 hover:bg-primary-600 text-white font-semibold text-xs rounded-xl shadow-md hover:shadow-lg disabled:opacity-50 disabled:cursor-not-allowed transition-all transform active:scale-95"
            >
              <div v-if="isSubmitting" class="animate-spin w-3.5 h-3.5 border-2 border-white border-t-transparent rounded-full" />
              <Plus v-else class="w-4 h-4" />
              <span>{{ isSubmitting ? 'Salvando...' : 'Confirmar Agendamento' }}</span>
            </button>
          </div>

        </form>

      </div>
    </div>
  </Transition>
</template>

<style scoped>
.modal-fade-enter-active,
.modal-fade-leave-active {
  transition: all 0.25s ease-out;
}
.modal-fade-enter-from,
.modal-fade-leave-to {
  opacity: 0;
  transform: scale(0.96);
}

.dropdown-fade-enter-active,
.dropdown-fade-leave-active {
  transition: all 0.15s ease-out;
}
.dropdown-fade-enter-from,
.dropdown-fade-leave-to {
  opacity: 0;
  transform: translateY(-4px);
}
</style>
