<script setup lang="ts">
import { ref, computed, onMounted } from 'vue'
import { useRoute } from 'vue-router'
import { MapPin, Bed, Bath, Square, Car, Check, Phone, ArrowLeft, Maximize2 } from 'lucide-vue-next'
import { Swiper, SwiperSlide } from 'swiper/vue'
import { Parallax, Pagination, Autoplay, Navigation, EffectFade } from 'swiper/modules'
import 'swiper/css'
import 'swiper/css/pagination'
import 'swiper/css/navigation'
import 'swiper/css/effect-fade'

import { useProperties } from '~/composables/useProperties'

const route = useRoute()
const propertyId = route.params.id

const { properties } = useProperties()
const property = computed(() => properties.value.find((p: any) => p.id === propertyId))

const getWhatsAppLink = () => {
  if (!property.value) return ''
  const text = `Olá! Gostaria de agendar uma visita para o imóvel: *${property.value.title}* (Cód: ${property.value.id}).`
  return `https://wa.me/5511999999999?text=${encodeURIComponent(text)}`
}

definePageMeta({
  layout: 'empty'
})
</script>

<template>
  <div class="min-h-screen bg-dark-bg text-white font-sans selection:bg-primary-500/30">
    <div v-if="property">
      <!-- Navbar Minimalista (Sticky over slider) -->
      <header class="absolute top-0 inset-x-0 z-50 bg-gradient-to-b from-black/80 to-transparent">
        <div class="max-w-7xl mx-auto px-6 h-20 flex items-center justify-between">
          <NuxtLink to="/imoveis" class="flex items-center gap-2 text-white hover:text-primary-500 transition-colors uppercase tracking-widest text-xs font-semibold">
            <ArrowLeft class="w-4 h-4" />
            Voltar ao Portfólio
          </NuxtLink>
          <h1 class="text-xl font-bold tracking-widest uppercase font-serif text-white">JRV</h1>
        </div>
      </header>

      <!-- Parallax Hero Slider -->
      <section class="h-[75vh] min-h-[600px] w-full relative">
        <Swiper
          :modules="[Parallax, Pagination, Navigation, EffectFade, Autoplay]"
          :parallax="true"
          :effect="'fade'"
          :pagination="{ clickable: true, renderBullet: (index, className) => `<span class='${className} w-12 h-1 bg-white/50 rounded-none transition-all duration-300 mx-1'></span>` }"
          :navigation="{ nextEl: '.swiper-button-next-custom', prevEl: '.swiper-button-prev-custom' }"
          :autoplay="{ delay: 5000, disableOnInteraction: false }"
          class="w-full h-full"
        >
          <SwiperSlide v-for="(img, idx) in property.images" :key="idx" class="relative overflow-hidden bg-black">
            <div 
              class="absolute inset-0 bg-cover bg-center"
              data-swiper-parallax="50%"
              :style="{ backgroundImage: `url(${img})` }"
            ></div>
            <div class="absolute inset-0 bg-black/40"></div>
          </SwiperSlide>

          <!-- Custom Navigation -->
          <div class="swiper-button-prev-custom absolute left-6 top-1/2 -translate-y-1/2 z-10 w-12 h-12 flex items-center justify-center border border-white/20 text-white rounded-sm hover:bg-white hover:text-black transition-colors cursor-pointer backdrop-blur-md">
            <ChevronRight class="w-6 h-6 rotate-180" />
          </div>
          <div class="swiper-button-next-custom absolute right-6 top-1/2 -translate-y-1/2 z-10 w-12 h-12 flex items-center justify-center border border-white/20 text-white rounded-sm hover:bg-white hover:text-black transition-colors cursor-pointer backdrop-blur-md">
            <ChevronRight class="w-6 h-6" />
          </div>
        </Swiper>
      </section>

      <!-- Content Split Layout -->
      <div class="max-w-7xl mx-auto px-6 py-20 flex flex-col lg:flex-row gap-16 relative">
        
        <!-- Left Column: Details -->
        <div class="lg:w-2/3 space-y-16">
          
          <!-- Headers & Info -->
          <div>
            <div class="flex flex-wrap items-center gap-3 mb-6">
              <span v-for="tag in property.tags" :key="tag" class="bg-primary-500/20 text-primary-400 border border-primary-500/30 text-xs font-semibold uppercase tracking-widest px-3 py-1.5 rounded-sm shadow-luxury">
                {{ tag }}
              </span>
              <span class="text-gray-500 text-sm tracking-widest uppercase ml-auto">Cód: {{ property.id }}</span>
            </div>
            
            <h2 class="text-4xl md:text-5xl font-serif font-bold leading-tight mb-4">
              {{ property.title }}
            </h2>
            
            <div class="flex items-center text-gray-400 text-lg mb-8 gap-2">
              <MapPin class="w-5 h-5 text-primary-500" />
              <span>{{ property.location }}</span>
            </div>

            <!-- Quick Specs Strip -->
            <div class="flex items-center flex-wrap gap-8 py-8 border-y border-white/5 text-gray-300">
              <div class="flex items-center gap-3">
                <Square class="w-6 h-6 text-primary-500" />
                <div>
                  <p class="text-2xl font-light">{{ property.specs.area }}<span class="text-sm">m²</span></p>
                  <p class="text-[10px] uppercase tracking-widest text-gray-500">Área Útil</p>
                </div>
              </div>
              <div class="flex items-center gap-3">
                <Bed class="w-6 h-6 text-primary-500" />
                <div>
                  <p class="text-2xl font-light">{{ property.specs.beds }}</p>
                  <p class="text-[10px] uppercase tracking-widest text-gray-500">Suítes</p>
                </div>
              </div>
              <div class="flex items-center gap-3">
                <Bath class="w-6 h-6 text-primary-500" />
                <div>
                  <p class="text-2xl font-light">{{ property.specs.baths }}</p>
                  <p class="text-[10px] uppercase tracking-widest text-gray-500">Banhos</p>
                </div>
              </div>
              <div class="flex items-center gap-3">
                <Car class="w-6 h-6 text-primary-500" />
                <div>
                  <p class="text-2xl font-light">{{ property.specs.parking }}</p>
                  <p class="text-[10px] uppercase tracking-widest text-gray-500">Vagas</p>
                </div>
              </div>
            </div>
          </div>

          <!-- Description -->
          <div>
             <h3 class="text-2xl font-serif mb-6 text-white border-b border-white/5 pb-4">Sobre o Imóvel</h3>
             <div class="text-lg text-gray-400 space-y-4 font-light leading-relaxed">
               <p v-for="(paragraph, i) in property.description.split('\n\n')" :key="i">
                 {{ paragraph }}
               </p>
             </div>
          </div>

          <!-- Amenities -->
          <div>
             <h3 class="text-2xl font-serif mb-6 text-white border-b border-white/5 pb-4">Diferenciais</h3>
             <div class="grid grid-cols-1 md:grid-cols-2 gap-y-4 gap-x-8">
               <div v-for="amenity in property.amenities" :key="amenity" class="flex items-center gap-3 text-gray-300">
                 <div class="w-6 h-6 rounded-sm bg-primary-500/10 border border-primary-500/20 flex items-center justify-center flex-shrink-0">
                   <Check class="w-4 h-4 text-primary-500" />
                 </div>
                 <span class="font-light">{{ amenity }}</span>
               </div>
             </div>
          </div>
          
        </div>

        <!-- Right Column: Sticky Pricing & CTA -->
        <div class="lg:w-1/3">
          <div class="sticky top-24 bg-dark-surface border border-white/5 p-8 rounded-sm shadow-2xl">
            <p class="text-xs text-gray-500 uppercase tracking-widest mb-2">{{ property.type }}</p>
            <p class="text-4xl font-light text-white mb-6">{{ property.price }} <span class="text-sm text-gray-500">/ mês</span></p>
            
            <div class="space-y-3 mb-8 pb-8 border-b border-white/5">
              <div class="flex justify-between text-gray-400 text-sm">
                <span>Condomínio</span>
                <span>{{ property.condominio }}</span>
              </div>
              <div class="flex justify-between text-gray-400 text-sm">
                <span>IPTU Mensal</span>
                <span>{{ property.iptu }}</span>
              </div>
              <div class="flex justify-between text-white font-semibold pt-3 uppercase tracking-widest text-xs">
                <span>Total Estimado</span>
                <span>R$ 50.700</span>
              </div>
            </div>

            <a :href="getWhatsAppLink()" target="_blank" class="w-full h-14 bg-primary-500 hover:bg-primary-600 text-white flex items-center justify-center gap-3 uppercase tracking-widest text-sm font-semibold rounded-sm transition-all shadow-luxury group">
              <Phone class="w-5 h-5 group-hover:scale-110 transition-transform" />
              Agendar Visita
            </a>
            
            <p class="text-center text-[10px] text-gray-500 uppercase tracking-widest mt-4">Atendimento Exclusivo IMOVEL OS</p>
          </div>
        </div>

      </div>

      <!-- Footer Minimalista -->
      <footer class="bg-black py-12 border-t border-white/5 text-center px-6">
        <h2 class="text-2xl font-serif font-bold tracking-widest uppercase mb-6 text-white">IMOVEL OS</h2>
        <div class="text-xs text-gray-600 uppercase tracking-widest">
          &copy; 2026 IMOVEL OS. Negociações em Alto Padrão.
        </div>
      </footer>
    </div>
    <div v-else class="min-h-screen flex flex-col items-center justify-center p-6 text-center">
      <h2 class="text-2xl font-serif font-bold mb-4">Imóvel não encontrado</h2>
      <NuxtLink to="/imoveis" class="text-primary-500 hover:underline uppercase tracking-widest text-xs font-semibold">
        Voltar ao Portfólio
      </NuxtLink>
    </div>
  </div>
</template>

<style>
/* Custom Swiper Styles */
.swiper-pagination-bullet {
  opacity: 0.5;
}
.swiper-pagination-bullet-active {
  background: white !important;
  opacity: 1;
}
</style>
