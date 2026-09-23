<script setup lang="ts">
import { ref } from 'vue'
import { Filter, Search, MapPin, Bed, Bath, Square, ChevronRight } from 'lucide-vue-next'

import { useProperties } from '~/composables/useProperties'

const { properties } = useProperties()

definePageMeta({
  layout: 'empty' // assuming no sidebar for public catalog
})
</script>

<template>
  <div class="min-h-screen bg-dark-bg text-white font-sans selection:bg-primary-500/30">
    
    <!-- Navbar Minimalista -->
    <header class="fixed top-0 inset-x-0 z-50 bg-dark-bg/80 backdrop-blur-md border-b border-white/5 transition-all duration-300">
      <div class="max-w-7xl mx-auto px-6 h-20 flex items-center justify-between">
        <h1 class="text-2xl font-bold tracking-widest uppercase font-serif">JRV</h1>
        
        <nav class="hidden md:flex items-center gap-8">
          <a href="#" class="text-sm tracking-widest uppercase text-gray-400 hover:text-white transition-colors">Portfólio</a>
          <a href="#" class="text-sm tracking-widest uppercase text-gray-400 hover:text-white transition-colors">Sobre Nós</a>
          <a href="#" class="text-sm tracking-widest uppercase text-gray-400 hover:text-white transition-colors">Contato</a>
          <button class="px-6 py-2 bg-primary-500 text-white text-sm font-semibold tracking-widest uppercase rounded-sm hover:bg-primary-600 transition-colors shadow-luxury">
            Seu Imóvel
          </button>
        </nav>
      </div>
    </header>

    <!-- Hero Section -->
    <section class="relative pt-32 pb-20 px-6 min-h-[50vh] flex flex-col justify-center border-b border-white/5">
      <div class="absolute inset-0 z-0">
         <div class="absolute inset-0 bg-gradient-to-b from-dark-bg via-dark-bg/90 to-dark-bg"></div>
         <!-- Subtle pattern or luxury texture could go here -->
      </div>

      <div class="relative z-10 max-w-7xl mx-auto w-full">
        <div class="max-w-3xl">
          <h2 class="text-5xl md:text-7xl font-serif font-bold leading-tight mb-6">
            O epítome da<br>
            <span class="text-transparent bg-clip-text bg-gradient-to-r from-primary-400 to-primary-600">exclusividade.</span>
          </h2>
          <p class="text-xl text-gray-400 font-light leading-relaxed mb-12 max-w-2xl">
            Descubra uma curadoria impecável de propriedades de alto padrão disponíveis para locação nas localizações mais desejadas.
          </p>
        </div>

        <!-- Search Bar -->
        <div class="flex flex-col md:flex-row gap-4 bg-dark-surface/50 backdrop-blur-md border border-white/10 p-2 rounded-sm w-full max-w-4xl shadow-2xl shadow-black">
          <div class="flex-1 flex items-center px-4 bg-transparent border-none">
            <Search class="w-5 h-5 text-gray-500 mr-3" />
            <input type="text" placeholder="Buscar por região ou condomínio..." class="w-full bg-transparent border-none focus:ring-0 text-white placeholder-gray-500 text-lg h-12 outline-none">
          </div>
          <div class="h-px md:h-8 w-full md:w-px bg-white/10 hidden md:block my-auto"></div>
          <button class="flex items-center justify-center gap-2 px-6 py-3 md:py-0 text-gray-300 hover:text-white transition-colors whitespace-nowrap">
            <Filter class="w-5 h-5" />
            <span class="text-sm uppercase tracking-widest font-semibold">Filtros</span>
          </button>
          <button class="bg-primary-500 text-white px-8 py-3 md:py-0 text-sm font-semibold tracking-widest uppercase rounded-sm hover:bg-primary-600 transition-colors shadow-luxury">
            Buscar
          </button>
        </div>
      </div>
    </section>

    <!-- Catalog Section -->
    <section class="py-24 px-6">
      <div class="max-w-7xl mx-auto">
        <div class="flex items-end justify-between mb-12">
          <div>
            <span class="text-primary-500 text-sm font-semibold tracking-widest uppercase mb-2 block">Nosso Portfólio</span>
            <h3 class="text-3xl font-serif font-bold">Imóveis Disponíveis</h3>
          </div>
          <div class="hidden md:flex gap-4">
             <span class="text-gray-400 text-sm uppercase tracking-widest">Mostrando 6 exclusividades</span>
          </div>
        </div>

        <!-- Grid -->
        <div class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-8">
          <NuxtLink 
            v-for="prop in properties" 
            :key="prop.id" 
            :to="`/imoveis/${prop.id}`"
            class="group block bg-dark-surface border border-white/5 rounded-sm overflow-hidden hover:border-primary-500/30 transition-all duration-500"
          >
            <!-- Image Container -->
            <div class="relative aspect-[4/3] overflow-hidden bg-black">
              <div class="absolute inset-0 bg-black/20 group-hover:bg-transparent transition-colors duration-500 z-10"></div>
              <img :src="prop.image" :alt="prop.title" class="w-full h-full object-cover transform group-hover:scale-105 transition-transform duration-700 ease-in-out" />
              
              <!-- Tags -->
              <div class="absolute top-4 left-4 z-20 flex flex-col gap-2">
                <span class="bg-dark-bg/80 backdrop-blur-md text-white text-[10px] uppercase tracking-widest px-3 py-1.5 rounded-sm border border-white/10">
                  {{ prop.type }}
                </span>
                <span v-for="tag in prop.tags" :key="tag" class="bg-primary-500/90 backdrop-blur-md text-white text-[10px] uppercase tracking-widest px-3 py-1.5 rounded-sm shadow-luxury">
                  {{ tag }}
                </span>
              </div>
            </div>

            <!-- Content -->
            <div class="p-6">
              <div class="flex items-center text-gray-400 text-sm mb-3 gap-1.5">
                <MapPin class="w-4 h-4 text-primary-500" />
                <span>{{ prop.location }}</span>
              </div>
              
              <h4 class="text-xl font-serif font-bold text-white mb-2 line-clamp-1 group-hover:text-primary-400 transition-colors">
                {{ prop.title }}
              </h4>
              
              <p class="text-2xl font-light text-white mb-6">
                {{ prop.price }} <span class="text-sm text-gray-500 font-sans tracking-normal">/ mês</span>
              </p>

              <!-- Specs -->
              <div class="flex items-center justify-between pt-4 border-t border-white/5 text-gray-400 text-sm">
                <div class="flex items-center gap-2">
                  <Square class="w-4 h-4" />
                  <span>{{ prop.specs.area }}m²</span>
                </div>
                <div class="flex items-center gap-2">
                  <Bed class="w-4 h-4" />
                  <span>{{ prop.specs.beds }}</span>
                </div>
                <div class="flex items-center gap-2">
                  <Bath class="w-4 h-4" />
                  <span>{{ prop.specs.baths }}</span>
                </div>
              </div>
            </div>
          </NuxtLink>
        </div>

        <div class="mt-16 text-center">
          <button class="inline-flex items-center justify-center gap-2 px-8 py-4 bg-transparent border border-white/20 text-white text-sm font-semibold tracking-widest uppercase rounded-sm hover:bg-white hover:text-black transition-all duration-300">
            Carregar Mais Portfólio
            <ChevronRight class="w-4 h-4" />
          </button>
        </div>
      </div>
    </section>

    <!-- Footer Minimalista -->
    <footer class="bg-black py-12 border-t border-white/5 text-center px-6">
      <h2 class="text-2xl font-serif font-bold tracking-widest uppercase mb-6 text-white">IMOVEL OS</h2>
      <p class="text-gray-500 text-sm max-w-md mx-auto leading-relaxed mb-8">
        Curadoria das propriedades mais exclusivas para clientes que exigem a excelência.
      </p>
      <div class="text-xs text-gray-600 uppercase tracking-widest">
        &copy; 2026 IMOVEL OS. Todos os direitos reservados.
      </div>
    </footer>
  </div>
</template>
