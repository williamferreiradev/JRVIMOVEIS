<script setup lang="ts">
import { computed, ref } from 'vue'
import { Search, UserPlus, Users, X, Eye, EyeOff, RefreshCw, Mail, CalendarDays } from 'lucide-vue-next'
import Sidebar from '~/components/Sidebar.vue'

interface AuthUserItem {
  id: string
  name: string
  email: string
  createdAt: string
}

const { mainMargin } = useSidebarState()
const search = ref('')
const showCreateModal = ref(false)
const showPassword = ref(false)
const isCreating = ref(false)
const formError = ref('')
const successMessage = ref('')
const form = ref({ name: '', email: '', password: '', confirmPassword: '' })

const { data, pending, error, refresh } = await useFetch<{ users: AuthUserItem[] }>('/api/users', {
  default: () => ({ users: [] })
})

const users = computed(() => data.value?.users || [])
const filteredUsers = computed(() => {
  const term = search.value.trim().toLocaleLowerCase('pt-BR')
  if (!term) return users.value

  return users.value.filter(user =>
    user.name.toLocaleLowerCase('pt-BR').includes(term) ||
    user.email.toLocaleLowerCase('pt-BR').includes(term)
  )
})

const initials = (user: AuthUserItem) => {
  const value = user.name || user.email
  return value.split(/\s+/).filter(Boolean).slice(0, 2).map(part => part[0]).join('').toUpperCase()
}

const formatDate = (value: string) => new Intl.DateTimeFormat('pt-BR', {
  dateStyle: 'medium',
  timeStyle: 'short'
}).format(new Date(value))

const getErrorMessage = (err: any) => err?.data?.statusMessage || err?.statusMessage || err?.message || 'Não foi possível concluir a operação.'

const openCreateModal = () => {
  form.value = { name: '', email: '', password: '', confirmPassword: '' }
  formError.value = ''
  showPassword.value = false
  showCreateModal.value = true
}

const closeCreateModal = () => {
  if (isCreating.value) return
  showCreateModal.value = false
}

const createUser = async () => {
  formError.value = ''
  successMessage.value = ''

  if (!form.value.name.trim() || !form.value.email.trim() || !form.value.password) {
    formError.value = 'Preencha nome, e-mail e senha.'
    return
  }

  if (form.value.password.length < 6) {
    formError.value = 'A senha deve ter pelo menos 6 caracteres.'
    return
  }

  if (form.value.password !== form.value.confirmPassword) {
    formError.value = 'As senhas não coincidem.'
    return
  }

  isCreating.value = true
  try {
    await $fetch('/api/users', {
      method: 'POST',
      body: {
        name: form.value.name,
        email: form.value.email,
        password: form.value.password
      }
    })
    await refresh()
    showCreateModal.value = false
    successMessage.value = 'Usuário cadastrado com sucesso.'
    window.setTimeout(() => { successMessage.value = '' }, 4000)
  } catch (err: any) {
    formError.value = getErrorMessage(err)
  } finally {
    isCreating.value = false
  }
}
</script>

<template>
  <div class="min-h-screen bg-gray-50 dark:bg-dark-bg transition-colors duration-300">
    <Sidebar />

    <main :class="[mainMargin, 'min-h-screen pt-16 md:pt-0 transition-all duration-300']">
      <div class="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-6 sm:py-8">
        <div class="flex flex-col sm:flex-row sm:items-center sm:justify-between gap-4 mb-7">
          <div>
            <div class="flex items-center gap-3">
              <div class="w-11 h-11 rounded-xl bg-primary-50 dark:bg-primary-500/10 text-primary-600 dark:text-primary-400 flex items-center justify-center">
                <Users class="w-5 h-5" />
              </div>
              <div>
                <h1 class="text-2xl sm:text-3xl font-bold text-gray-950 dark:text-white tracking-tight">Usuários</h1>
                <p class="text-sm text-gray-500 dark:text-gray-400 mt-1">Gerencie quem pode acessar o sistema.</p>
              </div>
            </div>
          </div>

          <button
            type="button"
            class="min-h-11 inline-flex items-center justify-center gap-2 px-5 py-3 rounded-xl bg-primary-600 hover:bg-primary-700 text-white text-sm font-semibold shadow-lg shadow-primary-600/15 transition-colors focus:outline-none focus:ring-2 focus:ring-primary-500 focus:ring-offset-2"
            @click="openCreateModal"
          >
            <UserPlus class="w-4 h-4" />
            Cadastrar usuário
          </button>
        </div>

        <div v-if="successMessage" role="status" class="mb-5 px-4 py-3 rounded-xl border border-emerald-200 bg-emerald-50 text-emerald-700 dark:border-emerald-500/20 dark:bg-emerald-500/10 dark:text-emerald-300 text-sm font-medium">
          {{ successMessage }}
        </div>

        <section class="bg-white dark:bg-dark-card border border-gray-200 dark:border-white/10 rounded-2xl shadow-sm overflow-hidden">
          <div class="p-4 sm:p-5 border-b border-gray-100 dark:border-white/10 flex flex-col sm:flex-row sm:items-center sm:justify-between gap-3">
            <div>
              <p class="text-sm font-semibold text-gray-900 dark:text-white">Usuários cadastrados</p>
              <p class="text-xs text-gray-500 dark:text-gray-400 mt-1">{{ users.length }} {{ users.length === 1 ? 'usuário' : 'usuários' }} no Supabase Auth</p>
            </div>

            <div class="flex items-center gap-2">
              <label class="relative flex-1 sm:w-72">
                <span class="sr-only">Buscar usuário</span>
                <Search class="absolute left-3 top-1/2 -translate-y-1/2 w-4 h-4 text-gray-400" />
                <input
                  v-model="search"
                  type="search"
                  placeholder="Buscar por nome ou e-mail"
                  class="w-full min-h-11 pl-10 pr-4 rounded-xl border border-gray-200 dark:border-white/10 bg-gray-50 dark:bg-dark-bg text-sm text-gray-900 dark:text-white placeholder:text-gray-400 outline-none focus:border-primary-500 focus:ring-2 focus:ring-primary-500/15"
                >
              </label>
              <button type="button" :disabled="pending" class="w-11 h-11 flex items-center justify-center rounded-xl border border-gray-200 dark:border-white/10 text-gray-500 hover:text-primary-600 hover:border-primary-300 transition-colors disabled:opacity-50" title="Atualizar lista" aria-label="Atualizar lista" @click="refresh()">
                <RefreshCw class="w-4 h-4" :class="{ 'animate-spin': pending }" />
              </button>
            </div>
          </div>

          <div v-if="pending" class="py-20 flex flex-col items-center justify-center text-gray-500 dark:text-gray-400">
            <div class="w-8 h-8 border-4 border-primary-500 border-t-transparent rounded-full animate-spin"></div>
            <p class="mt-3 text-sm font-medium">Carregando usuários...</p>
          </div>

          <div v-else-if="error" class="py-16 px-6 text-center">
            <div class="w-12 h-12 mx-auto rounded-full bg-red-50 dark:bg-red-500/10 text-red-500 flex items-center justify-center">
              <Users class="w-5 h-5" />
            </div>
            <p class="mt-4 font-semibold text-gray-900 dark:text-white">Não foi possível carregar os usuários</p>
            <p class="mt-1 text-sm text-gray-500 dark:text-gray-400">{{ getErrorMessage(error) }}</p>
            <button class="mt-4 text-sm font-semibold text-primary-600 hover:text-primary-700" @click="refresh()">Tentar novamente</button>
          </div>

          <div v-else-if="filteredUsers.length === 0" class="py-16 px-6 text-center">
            <Users class="w-10 h-10 mx-auto text-gray-300 dark:text-gray-600" />
            <p class="mt-4 font-semibold text-gray-900 dark:text-white">Nenhum usuário encontrado</p>
            <p class="mt-1 text-sm text-gray-500 dark:text-gray-400">{{ search ? 'Tente buscar usando outro nome ou e-mail.' : 'Cadastre o primeiro usuário para começar.' }}</p>
          </div>

          <div v-else>
            <div class="hidden md:block overflow-x-auto">
              <table class="w-full text-left">
                <thead class="bg-gray-50/80 dark:bg-white/[0.03] text-[11px] uppercase tracking-wider text-gray-500 dark:text-gray-400">
                  <tr>
                    <th class="px-6 py-3.5 font-semibold">Nome</th>
                    <th class="px-6 py-3.5 font-semibold">E-mail</th>
                    <th class="px-6 py-3.5 font-semibold">Data de cadastro</th>
                  </tr>
                </thead>
                <tbody class="divide-y divide-gray-100 dark:divide-white/10">
                  <tr v-for="user in filteredUsers" :key="user.id" class="hover:bg-gray-50/70 dark:hover:bg-white/[0.025] transition-colors">
                    <td class="px-6 py-4">
                      <div class="flex items-center gap-3">
                        <div class="w-10 h-10 rounded-xl bg-primary-50 dark:bg-primary-500/10 text-primary-700 dark:text-primary-300 flex items-center justify-center text-xs font-bold">{{ initials(user) }}</div>
                        <span class="font-semibold text-sm text-gray-900 dark:text-white">{{ user.name || 'Sem nome informado' }}</span>
                      </div>
                    </td>
                    <td class="px-6 py-4 text-sm text-gray-600 dark:text-gray-300">{{ user.email }}</td>
                    <td class="px-6 py-4 text-sm text-gray-500 dark:text-gray-400">{{ formatDate(user.createdAt) }}</td>
                  </tr>
                </tbody>
              </table>
            </div>

            <div class="md:hidden divide-y divide-gray-100 dark:divide-white/10">
              <article v-for="user in filteredUsers" :key="user.id" class="p-4">
                <div class="flex items-start gap-3">
                  <div class="w-11 h-11 rounded-xl bg-primary-50 dark:bg-primary-500/10 text-primary-700 dark:text-primary-300 flex items-center justify-center text-xs font-bold flex-shrink-0">{{ initials(user) }}</div>
                  <div class="min-w-0 flex-1">
                    <p class="font-semibold text-gray-900 dark:text-white truncate">{{ user.name || 'Sem nome informado' }}</p>
                    <p class="mt-1 text-sm text-gray-500 dark:text-gray-400 truncate flex items-center gap-1.5"><Mail class="w-3.5 h-3.5" />{{ user.email }}</p>
                    <p class="mt-2 text-xs text-gray-400 dark:text-gray-500 flex items-center gap-1.5"><CalendarDays class="w-3.5 h-3.5" />{{ formatDate(user.createdAt) }}</p>
                  </div>
                </div>
              </article>
            </div>
          </div>
        </section>
      </div>
    </main>

    <div v-if="showCreateModal" class="fixed inset-0 z-[100] flex items-end sm:items-center justify-center p-0 sm:p-4" @keydown.esc="closeCreateModal">
      <button class="absolute inset-0 bg-black/60 backdrop-blur-sm cursor-default" aria-label="Fechar cadastro" @click="closeCreateModal"></button>
      <section role="dialog" aria-modal="true" aria-labelledby="new-user-title" class="relative z-10 w-full max-w-lg bg-white dark:bg-dark-card rounded-t-2xl sm:rounded-2xl border border-gray-200 dark:border-white/10 shadow-2xl overflow-hidden">
        <header class="px-5 sm:px-6 py-5 border-b border-gray-100 dark:border-white/10 flex items-center justify-between">
          <div>
            <h2 id="new-user-title" class="text-xl font-bold text-gray-950 dark:text-white">Cadastrar usuário</h2>
            <p class="text-sm text-gray-500 dark:text-gray-400 mt-1">Crie um novo acesso ao sistema.</p>
          </div>
          <button type="button" :disabled="isCreating" class="w-11 h-11 flex items-center justify-center rounded-xl text-gray-400 hover:text-gray-900 dark:hover:text-white hover:bg-gray-100 dark:hover:bg-white/5 transition-colors disabled:opacity-50" aria-label="Fechar" @click="closeCreateModal">
            <X class="w-5 h-5" />
          </button>
        </header>

        <form class="p-5 sm:p-6 space-y-4" @submit.prevent="createUser">
          <div v-if="formError" role="alert" class="px-4 py-3 rounded-xl border border-red-200 bg-red-50 text-red-700 dark:border-red-500/20 dark:bg-red-500/10 dark:text-red-300 text-sm">
            {{ formError }}
          </div>

          <div>
            <label for="user-name" class="block text-sm font-semibold text-gray-700 dark:text-gray-200 mb-2">Nome completo</label>
            <input id="user-name" v-model="form.name" type="text" autocomplete="name" required class="w-full min-h-11 px-4 rounded-xl border border-gray-200 dark:border-white/10 bg-white dark:bg-dark-bg text-gray-900 dark:text-white outline-none focus:border-primary-500 focus:ring-2 focus:ring-primary-500/15" placeholder="Nome do usuário">
          </div>

          <div>
            <label for="user-email" class="block text-sm font-semibold text-gray-700 dark:text-gray-200 mb-2">E-mail</label>
            <input id="user-email" v-model="form.email" type="email" autocomplete="email" required class="w-full min-h-11 px-4 rounded-xl border border-gray-200 dark:border-white/10 bg-white dark:bg-dark-bg text-gray-900 dark:text-white outline-none focus:border-primary-500 focus:ring-2 focus:ring-primary-500/15" placeholder="usuario@empresa.com">
          </div>

          <div>
            <label for="user-password" class="block text-sm font-semibold text-gray-700 dark:text-gray-200 mb-2">Senha inicial</label>
            <div class="relative">
              <input id="user-password" v-model="form.password" :type="showPassword ? 'text' : 'password'" autocomplete="new-password" minlength="6" required class="w-full min-h-11 pl-4 pr-12 rounded-xl border border-gray-200 dark:border-white/10 bg-white dark:bg-dark-bg text-gray-900 dark:text-white outline-none focus:border-primary-500 focus:ring-2 focus:ring-primary-500/15" placeholder="Mínimo de 6 caracteres">
              <button type="button" class="absolute right-1 top-1/2 -translate-y-1/2 w-10 h-10 flex items-center justify-center text-gray-400 hover:text-gray-700 dark:hover:text-white" :aria-label="showPassword ? 'Ocultar senha' : 'Mostrar senha'" @click="showPassword = !showPassword">
                <EyeOff v-if="showPassword" class="w-4 h-4" />
                <Eye v-else class="w-4 h-4" />
              </button>
            </div>
          </div>

          <div>
            <label for="user-confirm-password" class="block text-sm font-semibold text-gray-700 dark:text-gray-200 mb-2">Confirmar senha</label>
            <input id="user-confirm-password" v-model="form.confirmPassword" :type="showPassword ? 'text' : 'password'" autocomplete="new-password" minlength="6" required class="w-full min-h-11 px-4 rounded-xl border border-gray-200 dark:border-white/10 bg-white dark:bg-dark-bg text-gray-900 dark:text-white outline-none focus:border-primary-500 focus:ring-2 focus:ring-primary-500/15" placeholder="Repita a senha">
          </div>

          <footer class="pt-2 flex flex-col-reverse sm:flex-row sm:justify-end gap-3">
            <button type="button" :disabled="isCreating" class="min-h-11 px-5 rounded-xl border border-gray-200 dark:border-white/10 text-sm font-semibold text-gray-700 dark:text-gray-200 hover:bg-gray-50 dark:hover:bg-white/5 transition-colors disabled:opacity-50" @click="closeCreateModal">Cancelar</button>
            <button type="submit" :disabled="isCreating" class="min-h-11 px-5 rounded-xl bg-primary-600 hover:bg-primary-700 text-white text-sm font-semibold inline-flex items-center justify-center gap-2 transition-colors disabled:opacity-60">
              <div v-if="isCreating" class="w-4 h-4 border-2 border-white border-t-transparent rounded-full animate-spin"></div>
              <UserPlus v-else class="w-4 h-4" />
              {{ isCreating ? 'Cadastrando...' : 'Cadastrar usuário' }}
            </button>
          </footer>
        </form>
      </section>
    </div>
  </div>
</template>