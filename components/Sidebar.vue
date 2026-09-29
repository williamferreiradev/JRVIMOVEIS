<script setup lang="ts">
import { ref, computed, onMounted, onUnmounted, watch } from 'vue'
import { useSupabaseClient, useSupabaseUser } from '#imports'
import { 
  LayoutDashboard, 
  KanbanSquare, 
  MessageSquare, 
  Users, 
  UserCircle, 
  UserCog,
  BarChart3, 
  LogOut, 
  Building, 
  ChevronsLeft, 
  ChevronsRight, 
  RefreshCw, 
  Globe, 
  Settings, 
  CalendarDays, 
  Clock,
  FileCheck,
  Menu,
  X
} from 'lucide-vue-next'

const { isCollapsed, isMobileOpen, toggleSidebar, toggleMobileSidebar, closeMobileSidebar } = useSidebarState()
const route = useRoute()
const supabase = useSupabaseClient<any>()
const currentUser = useSupabaseUser()
const showLabels = computed(() => !isCollapsed.value || isMobileOpen.value)

const leadsCount = ref(0)
const semCorretorCount = ref(0)
const statusDocCount = ref(0)
const clinicId = ref<string | null>(null)
let realtimeChannel: any

const fetchLeadsCount = async () => {
  try {
    const { count, error } = await supabase
      .from('leads')
      .select('*', { count: 'exact', head: true })
      
    if (!error && count !== null) {
      leadsCount.value = count
    }

    const { count: unassignedCount, error: unassignedError } = await supabase
      .from('leads')
      .select('*', { count: 'exact', head: true })
      .is('corretor_id', null)

    if (!unassignedError && unassignedCount !== null) {
      semCorretorCount.value = unassignedCount
    }

    const { count: docPendingCount, error: docPendingError } = await supabase
      .from('leads')
      .select('*', { count: 'exact', head: true })
      .eq('statusdoc', 'esperando')

    if (!docPendingError && docPendingCount !== null) {
      statusDocCount.value = docPendingCount
    }
  } catch (err) {
    console.error('Error fetching leads count:', err)
  }
}

const fetchClinicId = async () => {
  try {
    const { data: rpcData } = await supabase.rpc('get_auth_clinic_id')
    if (rpcData) { clinicId.value = rpcData; return }

    clinicId.value = null
  } catch (err) {
    console.error('Erro ao buscar clinic_id:', err)
  }
}

onMounted(() => {
  fetchLeadsCount()
  fetchClinicId()
  
  realtimeChannel = supabase.channel('sidebar_leads_changes')
    .on(
      'postgres_changes',
      { event: '*', schema: 'public', table: 'leads' },
      () => {
        fetchLeadsCount()
      }
    )
    .subscribe()
})

onUnmounted(() => {
  if (realtimeChannel) {
    supabase.removeChannel(realtimeChannel)
  }
})

watch(() => route.fullPath, closeMobileSidebar)

const navigation = computed(() => [
  { name: 'PRINCIPAL', items: [
    { name: 'Dashboard', icon: LayoutDashboard, route: '/dashboard' },
    { name: 'Negociações', icon: KanbanSquare, route: '/crm', badge: leadsCount.value > 0 ? String(leadsCount.value) : undefined },
    { name: 'Status Documental', icon: FileCheck, route: '/documentos', badge: statusDocCount.value > 0 ? String(statusDocCount.value) : undefined },
    { name: 'Contatos', icon: Users, route: '/contatos' },
    { name: 'Corretores', icon: UserCircle, route: '/corretores' },
    { name: 'Visitas', icon: CalendarDays, route: '/agenda' },
    { name: 'Leads Espera', icon: Clock, route: '/semcorretor', badge: semCorretorCount.value > 0 ? String(semCorretorCount.value) : undefined },
  ]},
  { name: 'GESTÃO', items: [
    { name: 'Imóveis', icon: Building, route: '/inventario' },
    { name: 'Conversas', icon: MessageSquare, route: '/chats' },
    { name: 'Relatórios', icon: BarChart3, route: '/relatorios' },
    { name: 'Reativar Interessados', icon: RefreshCw, route: '#', badge: 'PRO', disabled: true },
  ]},
  { name: 'ADMINISTRAÇÃO', items: [
    { name: 'Catálogo Público', icon: Globe, route: '#', badge: 'PRO', disabled: true },
    { name: 'Usuários', icon: UserCog, route: '/usuarios' },
    { name: 'Configurações', icon: Settings, route: '/configuracoes' },
  ]}
])

const handleLogout = async () => {
  await supabase.auth.signOut()
  await navigateTo('/login', { replace: true })
}
</script>

<template>
  <!-- Mobile top bar -->
  <header class="fixed inset-x-0 top-0 z-[60] h-16 px-4 flex items-center justify-between border-b border-gray-100 dark:border-dark-border bg-white/95 dark:bg-dark-bg/95 backdrop-blur-xl md:hidden">
    <div class="flex items-center gap-2.5">
      <div class="w-9 h-9 rounded-lg bg-primary-500 flex items-center justify-center shadow-luxury">
        <Building class="w-4 h-4 text-white" />
      </div>
      <div>
        <span class="text-gray-900 dark:text-white font-black text-sm tracking-tight block leading-none">JRV</span>
        <span class="text-[9px] text-gray-400 dark:text-dark-muted font-semibold uppercase tracking-widest">Imóveis</span>
      </div>
    </div>
    <button
      type="button"
      class="w-11 h-11 rounded-xl flex items-center justify-center text-gray-600 dark:text-gray-200 hover:bg-gray-100 dark:hover:bg-white/5 transition-colors"
      :aria-label="isMobileOpen ? 'Fechar menu' : 'Abrir menu'"
      :aria-expanded="isMobileOpen"
      @click="toggleMobileSidebar"
    >
      <X v-if="isMobileOpen" class="w-6 h-6" />
      <Menu v-else class="w-6 h-6" />
    </button>
  </header>

  <button
    v-if="isMobileOpen"
    type="button"
    class="fixed inset-0 z-[51] bg-gray-950/50 backdrop-blur-[2px] md:hidden"
    aria-label="Fechar menu"
    @click="closeMobileSidebar"
  />

  <aside 
    :class="[
      'h-dvh bg-white/95 dark:bg-dark-bg/95 backdrop-blur-2xl border-r border-gray-100 dark:border-dark-border flex flex-col fixed left-0 top-0 overflow-hidden z-[55] sidebar-transition select-none',
      'w-[min(18rem,86vw)] md:translate-x-0',
      isMobileOpen ? 'translate-x-0 shadow-2xl' : '-translate-x-full',
      isCollapsed ? 'md:w-20' : 'md:w-72'
    ]"
  >
    <!-- Header / Logo -->
    <div class="h-14 flex items-center border-b border-gray-100 dark:border-dark-border flex-shrink-0" :class="!showLabels ? 'px-3 justify-center' : 'px-4 justify-between'">
      <div class="flex items-center gap-2.5 group cursor-pointer" :class="!showLabels ? 'justify-center' : ''">
         <div class="w-8 h-8 rounded-lg bg-primary-500 flex items-center justify-center shadow-luxury sidebar-transition group-hover:scale-105 flex-shrink-0">
            <Building class="w-4 h-4 text-white" />
         </div>
         <div v-if="showLabels" class="sidebar-text-transition overflow-hidden">
           <span class="text-gray-900 dark:text-white font-black text-base tracking-tight block whitespace-nowrap leading-none">JRV</span>
           <span class="text-[10px] text-gray-400 dark:text-dark-muted font-semibold whitespace-nowrap uppercase tracking-widest leading-none mt-0.5 block">Imóveis</span>
         </div>
      </div>
      <button 
        @click="toggleSidebar"
        class="hidden md:flex p-2 rounded-lg text-gray-400 hover:text-primary-500 hover:bg-primary-50 dark:hover:bg-primary-500/10 sidebar-transition"
        :title="isCollapsed ? 'Expandir menu' : 'Recolher menu'"
      >
        <ChevronsLeft v-if="!isCollapsed" class="w-4 h-4" />
        <ChevronsRight v-else class="w-4 h-4" />
      </button>
    </div>

    <!-- Navigation -->
    <div class="flex-1 overflow-y-auto hide-scrollbar py-2" :class="!showLabels ? 'px-2' : 'px-2.5'">
      <div v-for="section in navigation" :key="section.name" class="mb-2.5">
        <h3 
          v-if="showLabels"
          class="text-[10px] font-bold text-gray-400 dark:text-dark-muted uppercase tracking-[0.12em] px-3 mb-1 mt-1.5 sidebar-text-transition"
        >
          {{ section.name }}
        </h3>
        <div v-else class="h-px bg-gray-100 dark:bg-dark-border mb-2 mx-1"></div>
        
        <ul class="space-y-0.5">
          <li v-for="item in section.items" :key="item.name">
            <NuxtLink 
              :to="item.route" 
              @click="closeMobileSidebar"
              :class="[
                'flex items-center rounded-lg text-[13px] font-medium text-gray-600 dark:text-gray-300 hover:text-gray-900 dark:hover:text-white hover:bg-gray-100/70 dark:hover:bg-white/5 sidebar-transition group relative border-l-2 border-transparent',
                !showLabels ? 'justify-center p-2.5' : 'gap-2.5 px-3 py-2.5 md:py-1.5',
                (item as any).disabled ? 'opacity-50 pointer-events-none cursor-not-allowed' : ''
              ]"
              active-class="!text-primary-500 !border-primary-500 !font-semibold bg-primary-50/50 dark:bg-primary-500/10"
              :title="isCollapsed ? item.name : undefined"
              :target="(item as any).external ? '_blank' : undefined"
            >
              <component 
                :is="item.icon" 
                class="w-[17px] h-[17px] sidebar-transition flex-shrink-0" 
              />
              
              <span v-if="showLabels" class="flex-1 sidebar-text-transition truncate">{{ item.name }}</span>

              <!-- Badge -->
              <span 
                v-if="(item as any).badge && showLabels"
                class="bg-primary-500 text-white text-[9px] font-bold px-1.5 py-0.2 rounded-full shadow-sm flex-shrink-0"
              >
                {{ (item as any).badge }}
              </span>

              <!-- Collapsed badge dot -->
              <span 
                v-if="(item as any).badge && !showLabels"
                class="absolute top-1.5 right-1.5 w-2 h-2 bg-primary-500 rounded-full"
              ></span>
            </NuxtLink>
          </li>
        </ul>
      </div>
    </div>

    <!-- Footer / User Profile & Actions -->
    <div class="p-2.5 border-t border-gray-100 dark:border-dark-border flex-shrink-0 bg-gray-50/50 dark:bg-dark-card/30">
      <div 
        :class="[
          'flex items-center sidebar-transition',
          !showLabels ? 'flex-col gap-2 justify-center' : 'gap-2 justify-between'
        ]"
      >
        <!-- User Info -->
        <div class="flex items-center gap-2 min-w-0" :class="!showLabels ? 'justify-center' : 'flex-1'">
          <!-- Avatar -->
          <div class="w-8 h-8 rounded-lg bg-primary-50 dark:bg-primary-500/10 border border-primary-100 dark:border-primary-500/20 flex items-center justify-center text-primary-600 dark:text-primary-400 font-bold text-xs flex-shrink-0 uppercase shadow-sm">
            {{ currentUser?.user_metadata?.full_name?.charAt(0) || currentUser?.email?.charAt(0) || 'U' }}
          </div>
          
          <div v-if="showLabels" class="min-w-0 flex-1">
            <p class="text-xs font-semibold text-gray-900 dark:text-white truncate leading-tight">
              {{ currentUser?.user_metadata?.full_name || currentUser?.email?.split('@')[0] || 'Corretor' }}
            </p>
            <p class="text-[10px] text-gray-400 dark:text-dark-muted font-medium leading-none mt-0.5">Admin</p>
          </div>
        </div>

        <!-- Controls: Theme Toggle & Logout -->
        <div class="flex items-center gap-0.5 flex-shrink-0" :class="!showLabels ? 'flex-col' : ''">
          <ThemeToggle :compact="true" />
          <button 
            @click="handleLogout" 
            class="h-8 w-8 rounded-lg flex items-center justify-center text-gray-400 hover:text-red-500 hover:bg-red-50 dark:hover:bg-red-500/10 transition-colors" 
            title="Sair do Sistema"
          >
            <LogOut class="w-4 h-4" />
          </button>
        </div>
      </div>
    </div>
  </aside>
</template>

<style scoped>
.sidebar-transition {
  transition: all 0.2s cubic-bezier(0.4, 0, 0.2, 1);
}

.sidebar-text-transition {
  transition: opacity 0.15s ease, transform 0.15s ease;
}

.hide-scrollbar {
  -ms-overflow-style: none;
  scrollbar-width: none;
}
.hide-scrollbar::-webkit-scrollbar {
  display: none;
}
</style>
