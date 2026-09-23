<template>
  <div class="min-h-screen flex items-stretch bg-white transition-colors duration-300">
    <!-- Right Side - Branding (Real Estate Layout) -->
    <div class="hidden lg:flex lg:w-1/2 relative bg-gray-50 overflow-hidden order-last">
      <!-- Background Image - Use property/house image (user needs to change this locally) -->
      <img src="/images/login-bg.png" alt="JRV Imóveis CRM" class="absolute inset-0 w-full h-full object-cover object-center mix-blend-multiply opacity-30 grayscale-[50%]" />
      
      <!-- Overlay Gradient - Blue & Yellow aesthetic -->
      <div class="absolute inset-0 bg-gradient-to-tr from-primary-900/90 via-primary-700/80 to-transparent mix-blend-multiply pointer-events-none"></div>
      <div class="absolute inset-0 bg-gradient-to-t from-gray-900/95 via-transparent to-transparent pointer-events-none"></div>

      <!-- Theme Glow -->
      <div class="absolute top-1/2 right-1/4 -translate-y-1/2 w-1/2 h-full bg-primary-500/20 blur-[100px] pointer-events-none"></div>

      <!-- Branding Text -->
      <div class="relative z-10 w-full p-12 flex flex-col justify-between h-full items-end text-right">
        <div>
          <h1 class="text-4xl lg:text-5xl font-black text-white tracking-widest uppercase drop-shadow-md">
            JRV<span class="text-accent ml-2">IMÓVEIS</span>
          </h1>
          <div class="h-1.5 w-32 bg-accent mt-4 rounded-full shadow-[0_0_15px_rgba(200,162,97,0.8)] ml-auto"></div>
        </div>

        <div class="space-y-4">
          <p class="text-gray-100 text-lg max-w-md leading-relaxed ml-auto font-medium drop-shadow-sm">
            Gestão exclusiva da sua Imobiliária. Acesse seu portfólio e domine o mercado.
          </p>
        </div>
      </div>
    </div>

    <!-- Left Side - Registration Form -->
    <div class="w-full lg:w-1/2 flex flex-col justify-center items-center p-8 bg-white relative z-10 shadow-[20px_0_50px_rgba(0,0,0,0.05)]">

      <div class="w-full max-w-md space-y-8 animate-fade-in-up">
        <!-- Feedback Message -->
        <div v-if="feedback.message" 
             :class="[
               'p-4 rounded-md text-center font-bold mb-4 transition-all duration-300 shadow-sm text-sm',
               feedback.type === 'error' ? 'bg-red-50 text-red-600 border border-red-200' : 'bg-green-50 text-green-700 border border-green-200'
             ]">
          {{ feedback.message }}
        </div>

        <!-- Header -->
        <div class="text-center space-y-2 mb-10">
          <h2 class="text-3xl font-black text-gray-900 tracking-tight uppercase">Novo Cadastro</h2>
          <p class="text-gray-500 font-medium">Libere seu acesso à plataforma imobiliária</p>
        </div>

        <!-- Form -->
        <form @submit.prevent="handleRegister" class="space-y-6">
          <div class="space-y-5">
            <BaseInput 
              v-model="form.fullName"
              label="Nome do Corretor"
              placeholder="Ex: João Corretor"
              type="text"
              :disabled="loading"
            />
            
            <BaseInput 
              v-model="form.email"
              label="Endereço de E-mail"
              placeholder="corretor@jrvimoveis.com.br"
              type="email"
              :disabled="loading"
            />
            
            <BaseInput 
              v-model="form.password"
              label="Senha de Acesso"
              placeholder="••••••••"
              type="password"
              :disabled="loading"
            />
          </div>

          <BaseButton variant="primary" class="w-full py-3.5 text-white bg-primary-500 hover:bg-primary-600 text-lg pointer-events-auto rounded-xl shadow-[0_10px_25px_rgba(0,83,155,0.3)] hover:shadow-[0_10px_30px_rgba(0,83,155,0.5)] font-bold tracking-wide transition-all border-none mt-4" :disabled="loading">
            <span v-if="loading">Registrando...</span>
            <span v-else>Criar Minha Conta</span>
          </BaseButton>
        </form>

        <!-- Footer -->
        <div class="text-center text-sm text-gray-500 mt-8 pt-8 border-t border-gray-100">
          Já faz parte da equipe? 
          <NuxtLink to="/login" class="font-bold text-primary-600 hover:text-primary-700 transition-colors">Entrar no Sistema</NuxtLink>
        </div>
      </div>
    </div>
  </div>
</template>

<script setup lang="ts">
definePageMeta({
  layout: false,
  middleware: 'registration-disabled'
})
import { useSupabaseClient } from '#imports'

const router = useRouter()
const supabase = useSupabaseClient()

const form = reactive({
  fullName: '',
  email: '',
  password: ''
})

const loading = ref(false)
const feedback = reactive({
  type: '' as 'error' | 'success' | '',
  message: ''
})

const handleRegister = async () => {
  loading.value = true
  feedback.message = ''
  feedback.type = ''

  try {
    const { data, error } = await supabase.auth.signUp({
      email: form.email,
      password: form.password,
      options: {
        data: {
          full_name: form.fullName
        }
      }
    })

    if (error) {
      throw error
    }

    feedback.type = 'success'
    feedback.message = 'Conta criada com sucesso! Redirecionando ou enviando confirmação...'
    
    // Auto-login flow check based on standard Supabase response
    setTimeout(() => {
      if (data.session) {
        router.push('/dashboard')
      } else {
        // Many Supabase setups require email confirmation
        feedback.message = 'Conta criada! Confirme seu e-mail ou vá para a tela de Login.'
      }
    }, 1500)

  } catch (error: any) {
    console.error('Registration Error:', error)
    feedback.type = 'error'
    feedback.message = error.message || 'Erro ao criar conta. Esse e-mail já existe?'
  } finally {
    loading.value = false
  }
}
</script>

<style scoped>
@keyframes fadeInUp {
  from {
    opacity: 0;
    transform: translateY(20px);
  }
  to {
    opacity: 1;
    transform: translateY(0);
  }
}

.animate-fade-in-up {
  animation: fadeInUp 0.6s ease-out forwards;
}
</style>
