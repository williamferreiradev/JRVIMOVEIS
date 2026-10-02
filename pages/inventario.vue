<script setup lang="ts">
import { ref, onMounted, computed, watch } from 'vue'
import { Plus, Edit, Trash2, Search, Building, X, Save, UploadCloud, Check, ChevronLeft, ChevronRight } from 'lucide-vue-next'
import { useSupabaseClient } from '#imports'
import Sidebar from '~/components/Sidebar.vue'

const { mainMargin } = useSidebarState()
const supabase = useSupabaseClient<any>()

// State
const properties = ref<any[]>([])
const loadingList = ref(true)
const searchQuery = ref('')

// Modal state
const showModal = ref(false)
const isSaving = ref(false)
const modalMode = ref<'create' | 'edit'>('create')
const editingId = ref<number | null>(null)

const formData = ref({
  nome: '',
  valor: '',
  descricao: '',
  url: '',
  agio: false,
  aluguel: false
})

const selectedFile = ref<File | null>(null)
const previewImage = ref<string | null>(null)
const fileInput = ref<HTMLInputElement | null>(null)

const fetchProperties = async () => {
  loadingList.value = true
  try {
    const { data, error } = await supabase.from('imoveis').select('*').order('created_at', { ascending: false })
    if (error) throw error
    properties.value = data || []
  } catch (error) {
    console.error('Erro ao listar imóveis:', error)
  } finally {
    loadingList.value = false
  }
}

onMounted(() => {
  fetchProperties()
})

const filteredProperties = computed(() => {
  if (!searchQuery.value) return properties.value
  const query = searchQuery.value.toLowerCase()
  return properties.value.filter(p => 
    p.nome?.toLowerCase().includes(query) || 
    p.descricao?.toLowerCase().includes(query)
  )
})

const currentPage = ref(1)
const itemsPerPage = 5

watch(searchQuery, () => {
  currentPage.value = 1
})

const paginatedProperties = computed(() => {
  const start = (currentPage.value - 1) * itemsPerPage
  return filteredProperties.value.slice(start, start + itemsPerPage)
})

const totalPages = computed(() => {
  return Math.ceil(filteredProperties.value.length / itemsPerPage)
})

const nextPage = () => {
  if (currentPage.value < totalPages.value) currentPage.value++
}

const prevPage = () => {
  if (currentPage.value > 1) currentPage.value--
}

const openCreateModal = () => {
  modalMode.value = 'create'
  editingId.value = null
  formData.value = { nome: '', valor: '', descricao: '', url: '', agio: false, aluguel: false }
  selectedFile.value = null
  previewImage.value = null
  showModal.value = true
}

const formatCurrency = (value: string | number) => {
  if (value === null || value === undefined || value === '') return ''
  if (typeof value === 'number') {
    value = value.toFixed(2)
  }
  const numericString = String(value).replace(/\D/g, '')
  if (!numericString) return ''
  const numericValue = Number(numericString) / 100
  return new Intl.NumberFormat('pt-BR', {
    style: 'decimal',
    minimumFractionDigits: 2,
    maximumFractionDigits: 2
  }).format(numericValue)
}

const handlePriceInput = (event: Event) => {
  const target = event.target as HTMLInputElement
  formData.value.valor = formatCurrency(target.value)
}

const openEditModal = (property: any) => {
  modalMode.value = 'edit'
  editingId.value = property.id
  formData.value = {
    nome: property.nome || '',
    valor: property.valor ? formatCurrency(property.valor) : '',
    descricao: property.descricao || '',
    url: property.url || '',
    agio: Boolean(property.agio),
    aluguel: Boolean(property.aluguel)
  }
  selectedFile.value = null
  previewImage.value = property.url || null
  showModal.value = true
}

const closeModal = () => {
  if (isSaving.value) return
  showModal.value = false
}

const handleFileSelect = (event: Event) => {
  const target = event.target as HTMLInputElement
  const file = target.files?.[0]
  if (file) {
    selectedFile.value = file
    previewImage.value = URL.createObjectURL(file)
  }
}

const parseNumericPrice = (value: string | number) => {
  if (!value) return 0
  if (typeof value === 'number') return value
  const cleaned = String(value).replace(/\./g, '').replace(',', '.')
  return parseFloat(cleaned) || 0
}

const handleSave = async () => {
  if (!formData.value.nome || !formData.value.valor) {
    alert('Preencha o título e o valor!')
    return
  }
  
  isSaving.value = true
  try {
    let finalImageUrl = previewImage.value && !previewImage.value.startsWith('blob:') ? previewImage.value : null
    
    // Upload da imagem se houver novo arquivo
    if (selectedFile.value) {
      const fileExt = selectedFile.value.name.split('.').pop()
      const fileName = `${Date.now()}_${Math.random().toString(36).substring(2)}.${fileExt}`
      
      const { data: uploadData, error: uploadError } = await supabase.storage
        .from('imgs')
        .upload(`uploads/${fileName}`, selectedFile.value, {
           cacheControl: '3600',
           upsert: false
         })
         
      if (uploadError) throw uploadError
      
      // Coletar URL pública
      const { data: publicUrlData } = supabase.storage.from('imgs').getPublicUrl(uploadData.path)
      finalImageUrl = publicUrlData.publicUrl
    }

    const payload: any = {
      nome: formData.value.nome,
      valor: parseNumericPrice(formData.value.valor),
      descricao: formData.value.descricao,
      url: finalImageUrl,
      agio: formData.value.agio,
      aluguel: formData.value.aluguel
    }

    if (modalMode.value === 'create') {
      payload.id_local = Date.now()
      const { error } = await supabase.from('imoveis').insert(payload)
      if (error) throw error
    } else if (modalMode.value === 'edit' && editingId.value) {
      const { error } = await supabase.from('imoveis').update(payload).eq('id', editingId.value)
      if (error) throw error
    }
    
    await fetchProperties()
    isSaving.value = false 
    closeModal()
  } catch (err: any) {
    console.error('Erro ao salvar imóvel:', err)
    alert('Erro ao salvar: ' + err.message)
    isSaving.value = false
  }
}

const confirmDelete = async (id: number) => {
  if (confirm('Tem certeza que deseja excluir este imóvel? Esta ação não pode ser desfeita.')) {
    try {
      const { error } = await supabase.from('imoveis').delete().eq('id', id)
      if (error) throw error
      properties.value = properties.value.filter(p => p.id !== id)
    } catch (e) {
      console.error(e)
      alert('Erro ao deletar imóvel.')
    }
  }
}
</script>

<template>
  <div class="min-h-screen bg-gray-50 dark:bg-dark-bg text-gray-900 dark:text-white font-sans transition-colors duration-300">
    <Sidebar />

    <main :class="[mainMargin, 'px-4 py-5 sm:px-6 lg:p-10 min-h-screen flex flex-col transition-all duration-300']">
      <!-- Header -->
      <div class="flex flex-col md:flex-row md:items-center justify-between gap-4 mb-8">
        <div>
          <h1 class="text-3xl font-bold font-serif text-gray-900 dark:text-white tracking-wide">Inventário de Imóveis</h1>
          <p class="text-gray-500 dark:text-gray-400 mt-1">Gerencie os imóveis cadastrados no sistema.</p>
        </div>
        <button @click="openCreateModal" class="flex items-center gap-2 bg-primary-500 text-white px-5 py-2.5 rounded-sm hover:bg-primary-600 transition-colors shadow-luxury">
          <Plus class="w-4 h-4" />
          <span class="font-semibold uppercase tracking-widest text-xs">Novo Imóvel</span>
        </button>
      </div>

      <!-- Search / Filter bar -->
      <div class="flex flex-col md:flex-row gap-4 mb-6">
        <div class="relative flex-1">
          <div class="absolute inset-y-0 left-0 pl-3 flex items-center pointer-events-none">
            <Search class="h-5 w-5 text-gray-400 dark:text-gray-500" />
          </div>
          <input 
            v-model="searchQuery" 
            type="text" 
            placeholder="Buscar imóvel (Nome ou Descrição)..." 
            class="block w-full pl-10 pr-3 py-2.5 border border-gray-200 dark:border-white/10 rounded-sm leading-5 bg-white dark:bg-dark-surface/50 backdrop-blur-md text-gray-900 dark:text-white placeholder-gray-400 dark:placeholder-gray-500 focus:outline-none focus:ring-1 focus:ring-primary-500 focus:border-primary-500 sm:text-sm transition-colors shadow-sm dark:shadow-none"
          >
        </div>
      </div>

      <!-- Table -->
      <div class="bg-white dark:bg-dark-surface/50 backdrop-blur-md border border-gray-200 dark:border-white/5 rounded-sm overflow-hidden shadow-card dark:shadow-2xl">
        <div class="overflow-x-auto relative min-h-[300px]">
          
          <div v-if="loadingList" class="absolute inset-0 z-10 flex flex-col items-center justify-center bg-white/50 dark:bg-dark-bg/50 backdrop-blur-sm">
             <div class="w-8 h-8 border-4 border-primary-500 border-t-transparent flex-shrink-0 animate-spin rounded-full"></div>
             <p class="mt-3 text-sm font-semibold text-gray-500">Sincronizando com a base de dados...</p>
          </div>

          <table class="w-full text-left border-collapse">
            <thead>
              <tr class="bg-gray-50 dark:bg-white/5 text-gray-500 dark:text-gray-400 text-xs uppercase tracking-wider border-b border-gray-200 dark:border-white/5">
                <th class="py-4 px-6 font-semibold">Imóvel & Foto</th>
                <th class="py-4 px-6 font-semibold">Descrição</th>
                <th class="py-4 px-6 font-semibold">Valor</th>
                <th class="py-4 px-6 font-semibold text-right">Ações</th>
              </tr>
            </thead>
            <tbody class="divide-y divide-gray-200 dark:divide-white/5 text-gray-600 dark:text-gray-300 text-sm">
              <tr v-for="property in paginatedProperties" :key="property.id" class="hover:bg-gray-50 dark:hover:bg-white/5 transition-colors group">
                <td class="py-4 px-6">
                  <div class="flex items-center gap-4">
                    <div class="w-16 h-12 rounded-sm overflow-hidden border border-gray-200 dark:border-white/10 shrink-0 bg-gray-100 flex items-center justify-center text-gray-400">
                      <img v-if="property.url" :src="property.url" :alt="property.nome" class="w-full h-full object-cover" />
                      <Building v-else class="w-5 h-5 opacity-50" />
                    </div>
                    <div>
                      <p class="text-gray-900 dark:text-white font-medium">{{ property.nome }}</p>
                    </div>
                  </div>
                </td>
                <td class="py-4 px-6">
                  <p class="max-w-xs md:max-w-md truncate text-gray-500 dark:text-gray-400">
                    {{ property.descricao || 'Sem descrição' }}
                  </p>
                </td>
                <td class="py-4 px-6 font-medium text-gray-900 dark:text-white">
                  R$ {{ property.valor ? Number(property.valor).toLocaleString('pt-BR', { minimumFractionDigits: 2 }) : '0,00' }}
                </td>
                <td class="py-4 px-6 text-right">
                  <div class="flex items-center justify-end gap-2 opacity-0 group-hover:opacity-100 transition-opacity">
                    <button @click="openEditModal(property)" class="p-2 text-gray-400 hover:text-primary-500 transition-colors rounded-sm hover:bg-gray-100 dark:hover:bg-white/5" title="Editar">
                      <Edit class="w-4 h-4" />
                    </button>
                    <button @click="confirmDelete(property.id)" class="p-2 text-gray-400 hover:text-red-500 transition-colors rounded-sm hover:bg-gray-100 dark:hover:bg-white/5" title="Excluir">
                      <Trash2 class="w-4 h-4" />
                    </button>
                  </div>
                </td>
              </tr>
              <tr v-if="!loadingList && paginatedProperties.length === 0">
                <td colspan="4" class="py-12 text-center text-gray-400 dark:text-gray-500">
                  <Building class="w-12 h-12 mx-auto mb-4 opacity-20" />
                  <p>Nenhum imóvel cadastrado ou encontrado.</p>
                </td>
              </tr>
            </tbody>
          </table>
        </div>
      </div>

      <!-- Pagination -->
      <div v-if="totalPages > 1" class="flex items-center justify-between mt-4 px-2">
        <p class="text-sm text-gray-500 dark:text-gray-400">
          Mostrando {{ ((currentPage - 1) * itemsPerPage) + 1 }} a {{ Math.min(currentPage * itemsPerPage, filteredProperties.length) }} de {{ filteredProperties.length }} imóveis
        </p>
        <div class="flex items-center gap-2">
          <button @click="prevPage" :disabled="currentPage === 1" class="p-2 border border-gray-200 dark:border-white/10 rounded-sm hover:bg-gray-50 dark:hover:bg-white/5 disabled:opacity-50 transition-colors text-gray-600 dark:text-gray-300">
            <ChevronLeft class="w-4 h-4" />
          </button>
          <span class="text-sm font-medium text-gray-700 dark:text-gray-300">
            Página {{ currentPage }} de {{ totalPages }}
          </span>
          <button @click="nextPage" :disabled="currentPage === totalPages" class="p-2 border border-gray-200 dark:border-white/10 rounded-sm hover:bg-gray-50 dark:hover:bg-white/5 disabled:opacity-50 transition-colors text-gray-600 dark:text-gray-300">
            <ChevronRight class="w-4 h-4" />
          </button>
        </div>
      </div>
    </main>

    <!-- Modal CRUD -->
    <div v-if="showModal" class="fixed inset-0 z-50 flex items-center justify-center p-4">
      <div class="absolute inset-0 bg-black/60 backdrop-blur-sm" @click="closeModal"></div>
      
      <div class="relative z-10 pointer-events-auto bg-white dark:bg-dark-card w-full max-w-2xl rounded-sm shadow-2xl border border-gray-200 dark:border-white/10 flex flex-col max-h-[90vh] overflow-hidden">
        
        <!-- Modal Header -->
        <div class="px-6 py-4 border-b border-gray-200 dark:border-white/10 flex items-center justify-between sticky top-0 bg-white dark:bg-dark-card z-10">
          <h2 class="text-xl font-serif font-bold text-gray-900 dark:text-white">
            {{ modalMode === 'create' ? 'Cadastrar Imóvel' : 'Atualizar Imóvel' }}
          </h2>
          <button @click="closeModal" :disabled="isSaving" class="p-2 text-gray-400 hover:text-gray-900 dark:hover:text-white transition-colors disabled:opacity-50">
            <X class="w-5 h-5" />
          </button>
        </div>

        <!-- Modal Body -->
        <div class="p-6 overflow-y-auto flex-1 space-y-6">
          <div class="grid grid-cols-1 md:grid-cols-2 gap-6">
            
            <!-- Imagem do Imóvel (Upload via Storage) -->
             <div class="md:col-span-2">
              <label class="block text-xs font-semibold uppercase tracking-widest text-gray-500 dark:text-gray-400 mb-2">Foto do Imóvel</label>
              
              <div 
                 @click="fileInput?.click()" 
                 class="w-full flex justify-center px-6 pt-5 pb-6 border-2 border-gray-300 dark:border-white/10 border-dashed rounded-md cursor-pointer hover:border-primary-500 hover:bg-primary-50 dark:hover:bg-primary-500/10 transition-colors"
               >
                <div class="space-y-1 text-center">
                  <div v-if="previewImage" class="mb-4">
                     <img :src="previewImage" alt="Visualização do imóvel" class="mx-auto h-32 w-auto object-cover rounded-sm shadow-sm" />
                  </div>
                  <UploadCloud v-else class="mx-auto h-12 w-12 text-gray-400" />
                  <div class="flex text-sm text-gray-600 dark:text-gray-400 justify-center">
                    <span class="relative cursor-pointer bg-transparent rounded-md font-medium text-primary-500 hover:text-primary-600 focus-within:outline-none focus-within:ring-2 focus-within:ring-offset-2 focus-within:ring-primary-500">
                      <span>Clique aqui para selecionar uma foto</span>
                      <input ref="fileInput" type="file" accept="image/*" class="sr-only" @change="handleFileSelect">
                    </span>
                  </div>
                </div>
              </div>
            </div>

            <!-- Nome/Título -->
            <div class="md:col-span-2">
              <label class="block text-xs font-semibold uppercase tracking-widest text-gray-500 dark:text-gray-400 mb-2">Título do Imóvel</label>
              <input v-model="formData.nome" type="text" placeholder="Ex: Apartamento duplex no Jardins" class="w-full bg-gray-50 dark:bg-dark-surface border border-gray-200 dark:border-white/10 rounded-sm px-4 py-2 text-gray-900 dark:text-white focus:outline-none focus:border-primary-500">
            </div>

            <!-- Valor -->
            <div class="md:col-span-2">
              <label class="block text-xs font-semibold uppercase tracking-widest text-gray-500 dark:text-gray-400 mb-2">Preço (R$)</label>
              <div class="relative">
                <div class="absolute inset-y-0 left-0 pl-3 flex items-center pointer-events-none">
                  <span class="text-gray-500 dark:text-gray-400 sm:text-sm">R$</span>
                </div>
                <input :value="formData.valor" @input="handlePriceInput" type="text" placeholder="0,00" class="w-full pl-9 bg-gray-50 dark:bg-dark-surface border border-gray-200 dark:border-white/10 rounded-sm px-4 py-2 text-gray-900 dark:text-white focus:outline-none focus:border-primary-500">
              </div>
            </div>

            <!-- Tipo de negociação -->
            <fieldset class="md:col-span-2">
              <legend class="block text-xs font-semibold uppercase tracking-widest text-gray-500 dark:text-gray-400 mb-2">
                Tipo de negociação
              </legend>
              <div class="grid grid-cols-1 sm:grid-cols-2 gap-3 min-h-12">
                <Transition name="option-fade">
                  <label
                    v-if="!formData.aluguel"
                    class="group relative flex min-h-12 cursor-pointer items-center gap-3 rounded-sm border px-4 py-3 transition-colors duration-200 focus-within:ring-2 focus-within:ring-primary-500 focus-within:ring-offset-2 dark:focus-within:ring-offset-dark-card"
                    :class="formData.agio
                      ? 'border-primary-500 bg-primary-50 text-primary-700 dark:bg-primary-500/15 dark:text-primary-300'
                      : 'border-gray-200 bg-gray-50 text-gray-700 hover:border-primary-300 dark:border-white/10 dark:bg-dark-surface dark:text-gray-200 dark:hover:border-primary-500/60'"
                  >
                    <input v-model="formData.agio" type="checkbox" class="sr-only" aria-label="É ágio?">
                    <span
                      class="flex h-6 w-6 shrink-0 items-center justify-center rounded border transition-colors duration-200"
                      :class="formData.agio ? 'border-primary-500 bg-primary-500 text-white' : 'border-gray-300 bg-white text-transparent dark:border-white/20 dark:bg-dark-card'"
                      aria-hidden="true"
                    >
                      <Check class="h-4 w-4" :class="formData.agio ? 'scale-100' : 'scale-75'" />
                    </span>
                    <span class="text-sm font-semibold uppercase tracking-wider">É ágio?</span>
                  </label>
                </Transition>

                <Transition name="option-fade">
                  <label
                    v-if="!formData.agio"
                    class="group relative flex min-h-12 cursor-pointer items-center gap-3 rounded-sm border px-4 py-3 transition-colors duration-200 focus-within:ring-2 focus-within:ring-primary-500 focus-within:ring-offset-2 dark:focus-within:ring-offset-dark-card"
                    :class="formData.aluguel
                      ? 'border-primary-500 bg-primary-50 text-primary-700 dark:bg-primary-500/15 dark:text-primary-300'
                      : 'border-gray-200 bg-gray-50 text-gray-700 hover:border-primary-300 dark:border-white/10 dark:bg-dark-surface dark:text-gray-200 dark:hover:border-primary-500/60'"
                  >
                    <input v-model="formData.aluguel" type="checkbox" class="sr-only" aria-label="É aluguel?">
                    <span
                      class="flex h-6 w-6 shrink-0 items-center justify-center rounded border transition-colors duration-200"
                      :class="formData.aluguel ? 'border-primary-500 bg-primary-500 text-white' : 'border-gray-300 bg-white text-transparent dark:border-white/20 dark:bg-dark-card'"
                      aria-hidden="true"
                    >
                      <Check class="h-4 w-4" :class="formData.aluguel ? 'scale-100' : 'scale-75'" />
                    </span>
                    <span class="text-sm font-semibold uppercase tracking-wider">É aluguel?</span>
                  </label>
                </Transition>
              </div>
            </fieldset>

            <!-- Descrição -->
            <div class="md:col-span-2">
              <label class="block text-xs font-semibold uppercase tracking-widest text-gray-500 dark:text-gray-400 mb-2">Descrição do Imóvel</label>
              <textarea v-model="formData.descricao" rows="3" placeholder="Descrição detalhada do imóvel, número de quartos, banheiros, vagas, etc..." class="w-full bg-gray-50 dark:bg-dark-surface border border-gray-200 dark:border-white/10 rounded-sm px-4 py-2 text-gray-900 dark:text-white focus:outline-none focus:border-primary-500"></textarea>
            </div>

          </div>
        </div>

        <!-- Modal Footer -->
        <div class="px-6 py-4 border-t border-gray-200 dark:border-white/10 bg-gray-50 dark:bg-dark-surface/50 flex justify-end gap-3 sticky bottom-0">
          <button @click="closeModal" :disabled="isSaving" class="px-5 py-2.5 text-sm font-semibold text-gray-600 dark:text-gray-300 hover:bg-gray-200 dark:hover:bg-white/5 rounded-sm transition-colors uppercase tracking-widest disabled:opacity-50">
            Cancelar
          </button>
          <button @click="handleSave" :disabled="isSaving" class="flex items-center gap-2 px-5 py-2.5 bg-primary-500 hover:bg-primary-600 text-white text-sm font-semibold rounded-sm transition-colors shadow-luxury uppercase tracking-widest disabled:opacity-50">
            <template v-if="isSaving">
               <div class="w-4 h-4 border-2 border-white border-t-transparent flex-shrink-0 animate-spin rounded-full"></div>
               Salvando...
            </template>
            <template v-else>
               <Save class="w-4 h-4" />
               Salvar Imóvel
            </template>
          </button>
        </div>
      </div>
    </div>
  </div>
</template>

<style scoped>
.option-fade-enter-active,
.option-fade-leave-active {
  transition: opacity 220ms ease, transform 220ms ease;
}

.option-fade-enter-from,
.option-fade-leave-to {
  opacity: 0;
  transform: translateY(-6px) scale(0.98);
}

@media (prefers-reduced-motion: reduce) {
  .option-fade-enter-active,
  .option-fade-leave-active {
    transition-duration: 1ms;
  }
}
</style>
