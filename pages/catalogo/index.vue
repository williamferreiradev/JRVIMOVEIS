<script setup lang="ts">
import { ref, computed, onMounted } from 'vue'
import { Search, ChevronRight, Building } from 'lucide-vue-next'
import { useSupabaseClient } from '#imports'

definePageMeta({ layout: 'empty' })

const supabase = useSupabaseClient()

const properties = ref<any[]>([])
const loading = ref(true)
const searchQuery = ref('')

const filteredProperties = computed(() => {
  if (!searchQuery.value) return properties.value
  const query = searchQuery.value.toLowerCase()
  return properties.value.filter(p => 
    (p.nome || '').toLowerCase().includes(query) ||
    (p.descricao || '').toLowerCase().includes(query)
  )
})

const formatPrice = (value: number) => {
  return new Intl.NumberFormat('pt-BR', {
    style: 'currency',
    currency: 'BRL'
  }).format(value)
}

const fetchProperties = async () => {
  loading.value = true
  try {
    const { data, error } = await supabase
      .from('fotos_pneus')
      .select('*')
      .order('created_at', { ascending: false })

    if (error) throw error
    properties.value = data || []
  } catch (err) {
    console.error('Erro ao buscar imóveis do catálogo:', err)
  } finally {
    loading.value = false
  }
}

onMounted(() => {
  fetchProperties()
})
</script>

<template>
  <div class="min-h-screen bg-[#0a0a0a] text-white font-sans selection:bg-primary-500/30">

    <!-- Navbar -->
    <header class="fixed top-0 inset-x-0 z-50 bg-[#0a0a0a]/80 backdrop-blur-md border-b border-white/5">
      <div class="max-w-7xl mx-auto px-6 h-20 flex items-center justify-between">
        <h1 class="text-2xl font-bold tracking-widest uppercase shadow-sm">JRV<span class="text-accent">IMÓVEIS</span></h1>
        <nav class="hidden md:flex items-center gap-8">
          <a href="#showroom" class="text-sm tracking-widest uppercase text-gray-400 hover:text-white transition-colors">Showroom</a>
          <a href="#contato" class="text-sm tracking-widest uppercase text-gray-400 hover:text-white transition-colors">Contato</a>
        </nav>
      </div>
    </header>

    <!-- Hero -->
    <section class="relative pt-40 pb-20 px-6 border-b border-white/5">
      <div class="absolute inset-0 bg-gradient-to-b from-primary-900/10 via-transparent to-transparent pointer-events-none" />
      <div class="relative z-10 max-w-7xl mx-auto">
        <p class="text-primary-500 text-sm tracking-widest uppercase font-semibold mb-4">Catálogo Exclusivo</p>
        <h2 class="text-5xl md:text-7xl font-bold leading-tight mb-6">
          Conquiste o seu<br>
          <span class="text-transparent bg-clip-text bg-gradient-to-r from-primary-400 to-primary-600">espaço.</span>
        </h2>
        <p class="text-xl text-gray-400 font-light leading-relaxed mb-12 max-w-2xl">
          Descubra uma curadoria impecável de imóveis de alto padrão selecionados para você.
        </p>

        <!-- Search Bar -->
        <div class="flex flex-col md:flex-row gap-2 bg-white/5 backdrop-blur-md border border-white/10 p-2 rounded-sm w-full max-w-3xl shadow-2xl shadow-black">
          <div class="flex-1 flex items-center px-4">
            <Search class="w-5 h-5 text-gray-500 mr-3 flex-shrink-0" />
            <input
              v-model="searchQuery"
              type="text"
              placeholder="Buscar por nome, descrição..."
              class="w-full bg-transparent border-none focus:ring-0 text-white placeholder-gray-500 text-base h-10 outline-none"
            >
          </div>
          <button class="bg-primary-500 text-white px-8 py-3 md:py-0 text-sm font-semibold tracking-widest uppercase rounded-sm hover:bg-primary-600 transition-colors">
            Encontrar
          </button>
        </div>
      </div>
    </section>

    <!-- Catalog -->
    <section id="showroom" class="py-24 px-6">
      <div class="max-w-7xl mx-auto">

        <!-- Header count -->
        <div class="flex items-end justify-between mb-12">
          <div>
            <span class="text-primary-500 text-sm font-semibold tracking-widest uppercase mb-2 block">Nosso Showroom</span>
            <h3 class="text-3xl font-bold tracking-tight">Imóveis Disponíveis</h3>
          </div>
          <span class="hidden md:block text-gray-400 text-sm uppercase tracking-widest">
            {{ filteredProperties.length }} imóvel(is)
          </span>
        </div>

        <!-- Loading -->
        <div v-if="loading" class="flex flex-col items-center justify-center py-32 gap-4">
          <div class="w-10 h-10 border-4 border-primary-500 border-t-transparent rounded-full animate-spin"></div>
          <p class="text-gray-400 text-sm">Carregando catálogo...</p>
        </div>

        <!-- Empty -->
        <div v-else-if="!loading && filteredProperties.length === 0" class="flex flex-col items-center justify-center py-32 gap-4 text-center">
          <Building class="w-16 h-16 text-gray-700" />
          <p class="text-gray-400 text-lg">Nenhum imóvel disponível no showroom.</p>
        </div>

        <!-- Grid -->
        <div v-else class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-8">
          <div
            v-for="property in filteredProperties"
            :key="property.id"
            class="group bg-white/5 border border-white/5 rounded-sm overflow-hidden hover:border-primary-500/40 transition-all duration-500 flex flex-col"
          >
            <!-- Image -->
            <div class="relative aspect-[4/3] overflow-hidden bg-black flex items-center justify-center">
              <div class="absolute inset-0 bg-black/20 group-hover:bg-transparent transition-colors duration-500 z-10" />
              
              <img
                v-if="property.url"
                :src="property.url"
                :alt="property.nome"
                class="w-full h-full object-cover transform group-hover:scale-105 transition-transform duration-700 ease-in-out"
              />
              <Building v-else class="w-16 h-16 text-gray-600 absolute" />

              <div class="absolute top-4 left-4 z-20">
                 <span class="bg-black/50 backdrop-blur-md text-white text-[10px] uppercase tracking-widest px-3 py-1.5 rounded-sm border border-white/10">
                   Exclusivo
                 </span>
              </div>
            </div>

            <!-- Content -->
            <div class="p-6 flex flex-col flex-1">
              <h4 class="text-xl font-bold text-white mb-2 group-hover:text-primary-400 transition-colors line-clamp-1">
                {{ property.nome }}
              </h4>

              <p v-if="property.descricao" class="text-sm text-gray-400 leading-relaxed mb-4 line-clamp-3 flex-1 break-words">
                {{ property.descricao }}
              </p>
              <div v-else class="flex-1" />

              <div class="flex items-end justify-between mt-4">
                 <p class="text-2xl font-light text-white">
                   {{ formatPrice(property.valor || 0) }}
                 </p>
              </div>
            </div>
          </div>
        </div>

        <div v-if="!loading && filteredProperties.length > 0" class="mt-16 text-center">
          <a
            href="#contato"
            class="inline-flex items-center justify-center gap-2 px-8 py-4 bg-transparent border border-white/20 text-white text-sm font-semibold tracking-widest uppercase rounded-sm hover:bg-white hover:text-black transition-all duration-300"
          >
            Falar com Corretor
            <ChevronRight class="w-4 h-4" />
          </a>
        </div>
      </div>
    </section>

    <!-- Footer -->
    <footer id="contato" class="bg-black py-12 border-t border-white/5 text-center px-6">
      <h2 class="text-2xl font-bold tracking-widest uppercase mb-6">JRV<span class="text-accent">IMÓVEIS</span></h2>
      <p class="text-gray-500 text-sm max-w-md mx-auto leading-relaxed mb-8">
        Plataforma premium entregando excelência e sofisticação.
      </p>
      <div class="text-xs text-gray-600 uppercase tracking-widest">
        &copy; 2026 JRV Imóveis. Todos os direitos reservados.
      </div>
    </footer>
  </div>
</template>
